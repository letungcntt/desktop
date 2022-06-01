#define _CRT_SECURE_NO_WARNINGS
#include "win32_window.h"

#include <flutter_windows.h>
#include <flutter/method_channel.h>

#include "resource.h"
#include <ShlObj_core.h>
#include <codecvt>
#include <runner/flutter_window.h>

NOTIFYICONDATA notifiIconData;
HMENU systemtray_menu;

namespace {

constexpr const wchar_t kWindowClassName[] = L"FLUTTER_RUNNER_WIN32_WINDOW";

// The number of Win32Window objects that currently exist.
static int g_active_window_count = 0;

using EnableNonClientDpiScaling = BOOL __stdcall(HWND hwnd);

// Scale helper to convert logical scaler values to physical using passed in
// scale factor
int Scale(int source, double scale_factor) {
  return static_cast<int>(source * scale_factor);
}

// Dynamically loads the |EnableNonClientDpiScaling| from the User32 module.
// This API is only needed for PerMonitor V1 awareness mode.
void EnableFullDpiSupportIfAvailable(HWND hwnd) {
  HMODULE user32_module = LoadLibraryA("User32.dll");
  if (!user32_module) {
    return;
  }
  auto enable_non_client_dpi_scaling =
      reinterpret_cast<EnableNonClientDpiScaling*>(
          GetProcAddress(user32_module, "EnableNonClientDpiScaling"));
  if (enable_non_client_dpi_scaling != nullptr) {
    enable_non_client_dpi_scaling(hwnd);
    FreeLibrary(user32_module);
  }
}

}  // namespace

// Manages the Win32Window's window class registration.
class WindowClassRegistrar {
 public:
  ~WindowClassRegistrar() = default;

  // Returns the singleton registar instance.
  static WindowClassRegistrar* GetInstance() {
    if (!instance_) {
      instance_ = new WindowClassRegistrar();
    }
    return instance_;
  }

  // Returns the name of the window class, registering the class if it hasn't
  // previously been registered.
  const wchar_t* GetWindowClass();

  // Unregisters the window class. Should only be called if there are no
  // instances of the window.
  void UnregisterWindowClass();

 private:
  WindowClassRegistrar() = default;

  static WindowClassRegistrar* instance_;

  bool class_registered_ = false;
};

WindowClassRegistrar* WindowClassRegistrar::instance_ = nullptr;

const wchar_t* WindowClassRegistrar::GetWindowClass() {
  if (!class_registered_) {
    WNDCLASS window_class{};
    window_class.hCursor = LoadCursor(nullptr, IDC_ARROW);
    window_class.lpszClassName = kWindowClassName;
    window_class.style = CS_HREDRAW | CS_VREDRAW;
    window_class.cbClsExtra = 0;
    window_class.cbWndExtra = 0;
    window_class.hInstance = GetModuleHandle(nullptr);
    window_class.hIcon =
        LoadIcon(window_class.hInstance, MAKEINTRESOURCE(IDI_APP_ICON));
    window_class.hbrBackground = 0;
    window_class.lpszMenuName = nullptr;
    window_class.lpfnWndProc = Win32Window::WndProc;
    RegisterClass(&window_class);
    class_registered_ = true;
  }
  return kWindowClassName;
}

void WindowClassRegistrar::UnregisterWindowClass() {
  UnregisterClass(kWindowClassName, nullptr);
  class_registered_ = false;
}

Win32Window::Win32Window() {
  ++g_active_window_count;
}

Win32Window::~Win32Window() {
  --g_active_window_count;
  Destroy();
}

void Win32Window::InitSystemtrayIcon()
{
  memset(&notifiIconData, 0, sizeof(NOTIFYICONDATA));
  notifiIconData.cbSize = sizeof(NOTIFYICONDATA);
  notifiIconData.hWnd = window_handle_;
  notifiIconData.uID = ID_SYSTEMTRAY_APP_ICON;
  notifiIconData.uFlags = NIF_ICON | NIF_MESSAGE | NIF_TIP;
  notifiIconData.uCallbackMessage = VM_SYSTEMTRAY;
  notifiIconData.hIcon = (HICON)LoadImage(NULL, TEXT("Logo.ico"), IMAGE_ICON, 0, 0, LR_LOADFROMFILE);
  wcscpy(notifiIconData.szTip, TEXT("Pancake Chat"));
}

BOOL AddSystemtrayIcon()
{
    return Shell_NotifyIcon(NIM_ADD, &notifiIconData);
}

BOOL DeleteSystemtrayIcon()
{
    return Shell_NotifyIcon(NIM_DELETE, &notifiIconData);
}


BOOL PushNotifyToSystemtray()
{
    notifiIconData.uFlags = NIF_MESSAGE | NIF_INFO;
    wcscpy(notifiIconData.szInfoTitle, TEXT("Notification"));
    wcscpy(notifiIconData.szInfo, TEXT("Pancake Chat still running in system"));
    notifiIconData.dwInfoFlags = NIIF_USER | NIIF_LARGE_ICON;
    notifiIconData.hBalloonIcon = (HICON)LoadImage(NULL, TEXT("Logo.ico"), IMAGE_ICON, 0, 0, LR_LOADFROMFILE);
    return Shell_NotifyIcon(NIM_MODIFY, &notifiIconData);
}

BOOL PushNewNotification(const wchar_t* title, const wchar_t* message)
{
    notifiIconData.uFlags = NIF_MESSAGE | NIF_INFO;
    wcscpy(notifiIconData.szInfoTitle, title);
    wcscpy(notifiIconData.szInfo, message);
    notifiIconData.dwInfoFlags = NIIF_USER | NIIF_LARGE_ICON;
    notifiIconData.hBalloonIcon = (HICON)LoadImage(NULL, TEXT("Logo.ico"), IMAGE_ICON, 0, 0, LR_LOADFROMFILE);
    return Shell_NotifyIcon(NIM_MODIFY, &notifiIconData);
}

void CreateContextMenu()
{
    systemtray_menu = CreatePopupMenu();
    AppendMenu(systemtray_menu, MF_STRING, ID_SYSTEMTRAY_OPEN, TEXT("Pancake Chat"));
    AppendMenu(systemtray_menu, MF_STRING, ID_SYSTEMTRAY_EXIT, TEXT("Exit App"));
}

void HandleWindowClose(HWND window_handle)
{
    bool _isToTray = SystemCommand::getCheckTray();
    if (_isToTray) {
        PushNotifyToSystemtray();
        ShowWindow(window_handle, SW_HIDE);
    }
    else {
        PostQuitMessage(0);
    }
}

bool Win32Window::CreateAndShow(const std::wstring& title,
                                const Point& origin,
                                const Size& size, int ShowCommand) {
  Destroy();
  HWND window = FindWindow(kWindowClassName, NULL);
  if (window) {
      PostMessage(window, VM_SYSTEMTRAY, 0, WM_LBUTTONDBLCLK);
      return TRUE;
  }

  const wchar_t* window_class =
      WindowClassRegistrar::GetInstance()->GetWindowClass();

  const POINT target_point = {static_cast<LONG>(origin.x),
                              static_cast<LONG>(origin.y)};
  HMONITOR monitor = MonitorFromPoint(target_point, MONITOR_DEFAULTTONEAREST);
  UINT dpi = FlutterDesktopGetDpiForMonitor(monitor);
  double scale_factor = dpi / 96.0;

  window = CreateWindow(
      window_class, title.c_str(), WS_OVERLAPPEDWINDOW,
      Scale(origin.x, scale_factor), Scale(origin.y, scale_factor),
      Scale(size.width, scale_factor), Scale(size.height, scale_factor),
      nullptr, nullptr, GetModuleHandle(nullptr), this);
  RestoreWindowPlacement(window);
  ShowWindow(window, ShowCommand);

  if (!window) {
    return false;
  }

  return OnCreate();
}

// static
LRESULT CALLBACK Win32Window::WndProc(HWND const window,
                                      UINT const message,
                                      WPARAM const wparam,
                                      LPARAM const lparam) noexcept {
  if (message == WM_NCCREATE) {
    auto window_struct = reinterpret_cast<CREATESTRUCT*>(lparam);
    SetWindowLongPtr(window, GWLP_USERDATA,
                     reinterpret_cast<LONG_PTR>(window_struct->lpCreateParams));

    auto that = static_cast<Win32Window*>(window_struct->lpCreateParams);
    EnableFullDpiSupportIfAvailable(window);
    that->window_handle_ = window;
  } else if (Win32Window* that = GetThisFromHandle(window)) {
    return that->MessageHandler(window, message, wparam, lparam);
  }

  return DefWindowProc(window, message, wparam, lparam);
}

LRESULT
Win32Window::MessageHandler(HWND hwnd,
                            UINT const message,
                            WPARAM const wparam,
                            LPARAM const lparam) noexcept {
  switch (message) {
    case WM_GETMINMAXINFO:
    {
        LPMINMAXINFO lpMMI = (LPMINMAXINFO)lparam;
        lpMMI->ptMinTrackSize.x = 1250;
        lpMMI->ptMinTrackSize.y = 750;
        break;
    }
     case WM_CREATE:
      InitSystemtrayIcon();
      AddSystemtrayIcon();
      CreateContextMenu();
      break;
    case WM_DESTROY:
      window_handle_ = nullptr;
      Destroy();
      if (quit_on_close_) {
        PostQuitMessage(0);
      }
      return 0;

    case WM_DPICHANGED: {
      auto newRectSize = reinterpret_cast<RECT*>(lparam);
      LONG newWidth = newRectSize->right - newRectSize->left;
      LONG newHeight = newRectSize->bottom - newRectSize->top;

      SetWindowPos(hwnd, nullptr, newRectSize->left, newRectSize->top, newWidth,
                   newHeight, SWP_NOZORDER | SWP_NOACTIVATE);

      return 0;
    }
    case WM_SIZE: {
      RECT rect = GetClientArea();
      if (child_content_ != nullptr) {
        // Size and position the child window.
        MoveWindow(child_content_, rect.left, rect.top, rect.right - rect.left,
                   rect.bottom - rect.top, TRUE);
      }
      return 0;
    }

    case WM_ACTIVATE:
      if (child_content_ != nullptr) {
        SetFocus(child_content_);
      }
      return 0;
    case WM_SYSCOMMAND:
        switch (wparam & 0xfff0)
        {
        case SC_CLOSE:
            SaveWindowPlacement(hwnd);
            HandleWindowClose(window_handle_);
            return 0;
        }
        break;
    case VM_SYSTEMTRAY:
    {
        switch (wparam)
        {
        case ID_SYSTEMTRAY_APP_ICON:
            break;
        case MS_NOTIFY:
            wchar_t* title = Notify::getTitle();
            wchar_t* messages = Notify::getMessage();
            PushNewNotification(title, messages);
            break;
        }
        if (lparam == WM_LBUTTONDBLCLK) {
            if (IsIconic(window_handle_)) {
                ShowWindow(window_handle_, SW_RESTORE);
            }
            else {
                ShowWindow(window_handle_, SW_SHOW);
            }
        }
        else if (lparam == WM_RBUTTONUP) {
            POINT cursor;
            GetCursorPos(&cursor);

            UINT clicked = TrackPopupMenu(
                systemtray_menu,
                TPM_RETURNCMD | TPM_NONOTIFY,
                cursor.x,
                cursor.y,
                0,
                hwnd,
                NULL
            );
            if (clicked == ID_SYSTEMTRAY_EXIT) {
                PostQuitMessage(0);
            }
            else if (clicked == ID_SYSTEMTRAY_OPEN) {
                ShowWindow(window_handle_, SW_SHOW);
            }
        }
        break;
    }
    
  }

  return DefWindowProc(window_handle_, message, wparam, lparam);
}

void Win32Window::Destroy() {
  OnDestroy();
  Shell_NotifyIcon(NIM_DELETE, &notifiIconData);

  if (window_handle_) {
    DestroyWindow(window_handle_);
    window_handle_ = nullptr;
  }
  if (g_active_window_count == 0) {
    WindowClassRegistrar::GetInstance()->UnregisterWindowClass();
  }
}

Win32Window* Win32Window::GetThisFromHandle(HWND const window) noexcept {
  return reinterpret_cast<Win32Window*>(
      GetWindowLongPtr(window, GWLP_USERDATA));
}

void Win32Window::SetChildContent(HWND content) {
  child_content_ = content;
  SetParent(content, window_handle_);
  RECT frame = GetClientArea();

  MoveWindow(content, frame.left, frame.top, frame.right - frame.left,
             frame.bottom - frame.top, true);

  SetFocus(child_content_);
}

RECT Win32Window::GetClientArea() {
  RECT frame;
  GetClientRect(window_handle_, &frame);
  return frame;
}

HWND Win32Window::GetHandle() {
  return window_handle_;
}

void Win32Window::SetQuitOnClose(bool quit_on_close) {
  quit_on_close_ = quit_on_close;
}

bool Win32Window::OnCreate() {
  // No-op; provided for subclasses.
  return true;
}

void Win32Window::OnDestroy() {
  // No-op; provided for subclasses.
}
void Win32Window::SaveWindowPlacement(HWND hWnd) {
    wchar_t appName[100];
    DWORD lpSize = sizeof(appName) / sizeof(wchar_t);
    int r = GetUserNameW(appName, &lpSize);
    if (r == 0) {
        wprintf(L"Failed to get username %ld", GetLastError());
        return;
    }
    wchar_t pathRoot[100] = L"C:\\Users\\";
    wchar_t pathTail[100] = L"\\AppData\\Roaming\\vn.pancake\\workcake\\pancake_chat_data";
    wchar_t* pathApp;
    pathApp = wcscat(pathRoot, appName);
    pathApp = wcscat(pathApp, pathTail);

    if (SHCreateDirectory(hWnd, pathApp) != ERROR_SUCCESS) {
        printf("Create Directory Failed: %ld", GetLastError());
    }
    pathApp = wcscat(pathApp, L"\\size.bin");

    if (!CreateDirectory(pathApp, NULL)) {
        printf("Create Directory Failed: %ld", GetLastError());
    }

    WINDOWPLACEMENT wp;
    GetWindowPlacement(hWnd, &wp);
    DWORD dwByteWrite = 0;

    HANDLE wFile = CreateFile(pathApp, GENERIC_WRITE, FILE_SHARE_READ, NULL, CREATE_ALWAYS, FILE_ATTRIBUTE_NORMAL, NULL);
    if (wFile == INVALID_HANDLE_VALUE) {
        printf("open file to write error: %d\n", GetLastError());
        return;
    }

    bool WriteResult = WriteFile(wFile, &wp, sizeof(wp), &dwByteWrite, NULL);
    if (!WriteResult) {
        printf("Write Fail: %d\n", GetLastError());
        return;
    }
    if (!CloseHandle(wFile)) {
        printf("Error close file: %d\n", GetLastError());
        system("pause");
    }

}
void Win32Window::RestoreWindowPlacement(HWND hWnd) {
    wchar_t appName[100];
    DWORD lpSize = sizeof(appName) / sizeof(wchar_t);
    int r = GetUserNameW(appName, &lpSize);
    if (r == 0) {
        wprintf(L"Failed to get username %ld", GetLastError());
        return;
    }
    wchar_t pathRoot[100] = L"C:\\Users\\";
    wchar_t pathTail[100] = L"\\AppData\\Roaming\\vn.pancake\\workcake\\pancake_chat_data\\size.bin";
    wchar_t* pathApp;
    pathApp = wcscat(pathRoot, appName);
    pathApp = wcscat(pathApp, pathTail);

    DWORD dwByteRead = 0;
    WINDOWPLACEMENT wp_read;
    HANDLE rFile = CreateFile(pathApp, GENERIC_READ, 0, NULL, OPEN_ALWAYS, FILE_ATTRIBUTE_NORMAL, NULL);
    if (rFile == INVALID_HANDLE_VALUE) {
        printf("open file to read error: %d\n", GetLastError());
        return;
    }

    memset(&wp_read, 0, sizeof(wp_read));
    bool ReadResult = ReadFile(rFile, &wp_read, sizeof(wp_read), &dwByteRead, NULL);
    if (!ReadResult) {
        printf("Read Fail: %d\n", GetLastError());
        return;
    }
    SetWindowPlacement(hWnd, &wp_read);

    if (!CloseHandle(rFile)) {
        printf("Error close file: %d\n", GetLastError());
        return;
    };
}