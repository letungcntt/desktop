#define _CRT_SECURE_NO_WARNINGS
#define getURL URLOpenBlockingStreamA
#include "flutter_window.h"
#include "resource.h"
#include <optional>
#include <flutter/method_channel.h>
#include <shlobj_core.h>
#include <optional>
#include <wincrypt.h>
#include <locale>
#include <codecvt>
#include <flutter/standard_method_codec.h>
#include <urlmon.h>
#include <windows.h>
#include <objidl.h>
#include <gdiplus.h>
#pragma comment(lib,"../../../windows/runner/WinSparkle.lib")
#pragma comment(lib, "crypt32.lib")
#pragma comment(lib, "urlmon.lib")
#pragma comment (lib,"Gdiplus.lib")

#include "flutter/generated_plugin_registrant.h"
#include "winsparkle.h"
using namespace std;

FlutterWindow::FlutterWindow(const flutter::DartProject& project)
    : project_(project) {}

FlutterWindow::~FlutterWindow() {}

const char kChannelName[] = "drop_zone";
const char updateChannelName[] = "update";
const char notifyChannelName[] = "notify";
const char systemChannelName[] = "system";
const char copyImageChannelName[] = "copy";
const char windowManagerChannelName[] = "window_manager";
std::unique_ptr<flutter::MethodChannel<>> channel;
std::unique_ptr<flutter::MethodChannel<>> updateChannel;
std::unique_ptr<flutter::MethodChannel<>> notifyChannel;
std::unique_ptr<flutter::MethodChannel<>> systemChannel;
std::unique_ptr<flutter::MethodChannel<>> copyChannel;
std::unique_ptr<flutter::MethodChannel<>> windowManagerChannel;
void getUpdate();
void onCopyImage();
static BOOL OpenClipboard_ButTryABitHarder(HWND ClipboardOwner);
static DWORD GetPixelDataOffsetForPackedDIB(const BITMAPINFOHEADER* BitmapInfoHeader);

bool FlutterWindow::OnCreate() {
  if (!Win32Window::OnCreate()) {
    return false;
  }

  RECT frame = GetClientArea();

  // The size here must match the window dimensions to avoid unnecessary surface
  // creation / destruction in the startup path.
  flutter_controller_ = std::make_unique<flutter::FlutterViewController>(
      frame.right - frame.left, frame.bottom - frame.top, project_);
  // Ensure that basic setup of the controller was successful.
  if (!flutter_controller_->engine() || !flutter_controller_->view()) {
    return false;
  }
  RegisterPlugins(flutter_controller_->engine());
  SetChildContent(flutter_controller_->view()->GetNativeWindow());

  //DnD: Initialize OLE
  OleInitialize(nullptr);

  //DnD: Register Drag & Drop
  if (SUCCEEDED(RegisterDragDrop(flutter_controller_->view()->GetNativeWindow(), this)))
  {
      _hwndRegistered = flutter_controller_->view()->GetNativeWindow();
  }

  FlutterWindow::initMethodChannel();
  getUpdate();
  listenSystem();
  listenNotify();
  onCopyImage();
  windowManager();

  return true;
}

void FlutterWindow::OnDestroy() {
  if (flutter_controller_) {
    flutter_controller_ = nullptr;
  }

  //DnD: Unregister Drag & Drop
  if (_hwndRegistered)
  {
      RevokeDragDrop(_hwndRegistered);
      _hwndRegistered = NULL;
  }

  //DnD: Uninitialize OLE
  OleUninitialize();

  Win32Window::OnDestroy();
}

LRESULT
FlutterWindow::MessageHandler(HWND hwnd, UINT const message,
                              WPARAM const wparam,
                              LPARAM const lparam) noexcept {
  // Give Flutter, including plugins, an opportunity to handle window messages.
  if (flutter_controller_) {
    std::optional<LRESULT> result =
        flutter_controller_->HandleTopLevelWindowProc(hwnd, message, wparam,
                                                      lparam);
    if (result) {
      return *result;
    }
  }

  switch (message) {
    case WM_COMMAND:
    switch (LOWORD(wparam))
    {
        case ID_PASTE:
            onPaste();
            break;
        case ID_CLOSE:
            Destroy();
            PostQuitMessage(0);
            break;
        default:
            break;
    }
    case WM_FONTCHANGE:
      flutter_controller_->engine()->ReloadSystemFonts();
      break;
    case WM_ACTIVATEAPP:
    {
        bool value = static_cast<bool>(wparam);
        if (channel != nullptr) {
            channel.get()->InvokeMethod("is_focused", std::make_unique<flutter::EncodableValue>(value));
        }
        break;
    }

  }

  return Win32Window::MessageHandler(hwnd, message, wparam, lparam);
}

//DnD: Implement IUnknown
HRESULT STDMETHODCALLTYPE
FlutterWindow::QueryInterface(REFIID riid, _COM_Outptr_ void** ppvObject)
{

    return S_OK;
}

//DnD: Implement IUnknown
ULONG STDMETHODCALLTYPE FlutterWindow::AddRef()
{
    return 0;
}

//DnD: Implement IUnknown
ULONG STDMETHODCALLTYPE FlutterWindow::Release()
{
    return 0;
}

//DnD: Implement IDropTarget
HRESULT __stdcall FlutterWindow::DragEnter(IDataObject* pDataObject, DWORD grfKeyState,
    POINTL pt, DWORD* pdwEffect)
{
    flutter::EncodableList list = {};
    POINT cursor = getCursor(pt);
    list.push_back(flutter::EncodableValue(std::to_string(cursor.x) + ":" + std::to_string(cursor.y)));
    channel.get()->InvokeMethod("entered", std::make_unique<flutter::EncodableValue>(list));
    // TODO: Implement
    return S_OK;
}

//DnD: Implement IDropTarget
HRESULT __stdcall FlutterWindow::DragOver(DWORD grfKeyState, POINTL pt, DWORD* pdwEffect)
{
    flutter::EncodableList list = {};
    POINT cursor = getCursor(pt);
    list.push_back(flutter::EncodableValue(std::to_string(cursor.x) + ":" + std::to_string(cursor.y)));
    channel.get()->InvokeMethod("updated", std::make_unique<flutter::EncodableValue>(list));
    // TODO: Implement
    return S_OK;
}

//DnD: Implement IDropTarget
HRESULT __stdcall FlutterWindow::DragLeave(void)
{
    // TODO: Implement
    channel.get()->InvokeMethod("exited", nullptr);
    return S_OK;
}

//DnD: Implement IDropTarget
HRESULT __stdcall FlutterWindow::Drop(IDataObject* pDataObject, DWORD grfKeyState, POINTL pt, DWORD* pdwEffect)
{
    //wchar_t caFileName[MAX_PATH];
    FORMATETC fmte = { CF_HDROP, NULL, DVASPECT_CONTENT,
                      -1, TYMED_HGLOBAL };
    STGMEDIUM stgm;
    if (SUCCEEDED(pDataObject->GetData(&fmte, &stgm)))
    {
        HDROP hDropInfo = reinterpret_cast<HDROP>(stgm.hGlobal);

        // Get the number of files
        UINT nNumOfFiles = DragQueryFileW(hDropInfo, 0xFFFFFFFF, NULL, 0);

        flutter::EncodableList list = {};
        POINT cursor = getCursor(pt);
        list.push_back(flutter::EncodableValue(std::to_string(cursor.x) + ":" + std::to_string(cursor.y)));
        wchar_t sItem[MAX_PATH];
        for (UINT nIndex = 0; nIndex < nNumOfFiles; ++nIndex)
        {
            //fetch the length of the path
            UINT cch = DragQueryFileW(hDropInfo, nIndex, NULL, 0);

            //fetch the path and store it in 16bit wide char
            DragQueryFileW(hDropInfo, nIndex, (LPWSTR)sItem, cch + 1);

            std::wstring pathInfoUtf16(sItem, cch);
            std::string pathInfoUtf8 = FlutterWindow::utf8_encode(pathInfoUtf16);
            list.push_back(flutter::EncodableValue(pathInfoUtf8));
        }

        DragFinish(hDropInfo);

        ReleaseStgMedium(&stgm);

        channel.get()->InvokeMethod("dropped", std::make_unique<flutter::EncodableValue>(list));
    }
    return S_OK;
}

// helper function to convert 16-bit wstring to utf-8 encoded string
std::string FlutterWindow::utf8_encode(const std::wstring& wstr)
{
    if (wstr.empty())
        return std::string();
    int size_needed = WideCharToMultiByte(CP_UTF8, 0, &wstr[0], (int)wstr.size(), NULL, 0, NULL, NULL);
    std::string strTo(size_needed, 0);
    WideCharToMultiByte(CP_UTF8, 0, &wstr[0], (int)wstr.size(), &strTo[0], size_needed, NULL, NULL);
    return strTo;
}

POINT FlutterWindow::getCursor(POINTL pt) {
    WINDOWPLACEMENT wp;
    HWND hwnd = Win32Window::GetHandle();
    GetWindowPlacement(hwnd, &wp);
    POINT window;
    if (wp.showCmd == SW_MAXIMIZE) {
        window = wp.ptMaxPosition;
    }
    else {
        window = { wp.rcNormalPosition.left, wp.rcNormalPosition.top };
    }
    POINT cursor = { pt.x - window.x - 8, pt.y - window.y - 38 };
    return cursor;
}

void FlutterWindow::onPaste() {
    if (IsClipboardFormatAvailable(CF_DIB)) {
        if (OpenClipboard_ButTryABitHarder(NULL)) {
            HGLOBAL handleClipboard = (HGLOBAL)GetClipboardData(CF_DIB);
            if (handleClipboard) {
                BITMAPINFOHEADER* bitmapInfoHeader = (BITMAPINFOHEADER*)GlobalLock(handleClipboard);
                assert(bitmapInfoHeader);
                SIZE_T clipboardDataSize = GlobalSize(handleClipboard);
                assert(clipboardDataSize >= sizeof(BITMAPINFOHEADER));

                DWORD bitOffset = GetPixelDataOffsetForPackedDIB(bitmapInfoHeader);
                DWORD totalClipboardSize = sizeof(BITMAPFILEHEADER) + static_cast<DWORD> (clipboardDataSize);
                BITMAPFILEHEADER bitmapFileHeader = {};
                bitmapFileHeader.bfType = 0x4D42;
                bitmapFileHeader.bfSize = (DWORD)totalClipboardSize;
                bitmapFileHeader.bfOffBits = sizeof(BITMAPFILEHEADER) + bitOffset;

                const BYTE* bytes = (const BYTE*)malloc(totalClipboardSize);
                // bytes = reinterpret_cast<BYTE*>(&bitmapFileHeader);

                memcpy((void*)bytes, &bitmapFileHeader, sizeof(BITMAPFILEHEADER));
                memcpy((void*)(bytes + sizeof(BITMAPFILEHEADER)), bitmapInfoHeader, clipboardDataSize);

                DWORD nDestinationSize;
                if (CryptBinaryToStringA(bytes, totalClipboardSize, CRYPT_STRING_BASE64 | CRYPT_STRING_NOCRLF, nullptr, &nDestinationSize))
                {
                    LPSTR pszDestination = static_cast<LPSTR> (HeapAlloc(GetProcessHeap(), HEAP_NO_SERIALIZE, nDestinationSize));
                    if (pszDestination)
                    {
                        flutter::EncodableList list = {};
                        if (CryptBinaryToStringA(bytes, totalClipboardSize, CRYPT_STRING_BASE64 | CRYPT_STRING_NOCRLF, pszDestination, &nDestinationSize))
                        {
                            list.push_back(flutter::EncodableValue(std::string("paste_bytes")));
                            list.push_back(flutter::EncodableValue(std::string(pszDestination)));
                        }
                        GlobalUnlock(handleClipboard);
                        CloseClipboard();
                        channel.get()->InvokeMethod("dropped", std::make_unique<flutter::EncodableValue>(list));
                        HeapFree(GetProcessHeap(), HEAP_NO_SERIALIZE, pszDestination);
                    }
                }
            }
        }
    }

    if (IsClipboardFormatAvailable(CF_HDROP)) {
        if (OpenClipboard(NULL)) {
            HGLOBAL hGlobal = (HGLOBAL)GetClipboardData(CF_HDROP);
            if (hGlobal) {
                HDROP hDrop = (HDROP)GlobalLock(hGlobal);
                if (hDrop) {
                    UINT nNumOfFiles = DragQueryFileW(hDrop, 0xFFFFFFFF, NULL, 0);
                    wchar_t sItem[MAX_PATH];
                    flutter::EncodableList list = {};
                    list.push_back(flutter::EncodableValue(std::string("paste")));
                    for (UINT nIndex = 0; nIndex < nNumOfFiles; ++nIndex)
                    {
                        //fetch the length of the path
                        UINT cch = DragQueryFileW(hDrop, nIndex, NULL, 0);

                        //fetch the path and store it in 16bit wide char
                        DragQueryFileW(hDrop, nIndex, (LPWSTR)sItem, cch + 1);

                        std::wstring pathInfoUtf16(sItem, cch);
                        std::string pathInfoUtf8 = FlutterWindow::utf8_encode(pathInfoUtf16);
                        list.push_back(flutter::EncodableValue(pathInfoUtf8));

                        GlobalUnlock(hGlobal);
                        CloseClipboard();
                    }
                    channel.get()->InvokeMethod("dropped", std::make_unique<flutter::EncodableValue>(list));
                }
            }
        }
    }
}

void FlutterWindow::initMethodChannel() {
  channel = std::make_unique<flutter::MethodChannel<flutter::EncodableValue>>(
    flutter_controller_->engine()->messenger(),
    kChannelName,
    &flutter::StandardMethodCodec::GetInstance()
  );
  updateChannel = std::make_unique<flutter::MethodChannel<flutter::EncodableValue>>(
    flutter_controller_->engine()->messenger(),
    updateChannelName,
    &flutter::StandardMethodCodec::GetInstance()
  );
  systemChannel = std::make_unique<flutter::MethodChannel<flutter::EncodableValue>>(
    flutter_controller_->engine()->messenger(),
    systemChannelName,
    &flutter::StandardMethodCodec::GetInstance()
  );
  notifyChannel = std::make_unique<flutter::MethodChannel<flutter::EncodableValue>>(
      flutter_controller_->engine()->messenger(),
      notifyChannelName,
      &flutter::StandardMethodCodec::GetInstance()
  );
  copyChannel = std::make_unique<flutter::MethodChannel<flutter::EncodableValue>>(
      flutter_controller_->engine()->messenger(),
      copyImageChannelName,
      &flutter::StandardMethodCodec::GetInstance()
  );
  windowManagerChannel = std::make_unique<flutter::MethodChannel<flutter::EncodableValue>>(
      flutter_controller_->engine()->messenger(),
      windowManagerChannelName,
      &flutter::StandardMethodCodec::GetInstance()
  );
}

void FlutterWindow::listenSystem()
{
    systemChannel.get()->SetMethodCallHandler([](const auto& call, auto result) {
        if (call.method_name().compare("system_to_tray") == 0) {
            const auto* argument = std::get_if<flutter::EncodableList>(call.arguments());
            SystemCommand::setSystemTray(std::get<bool>(argument->at(0)));
        }
    });
}

void FlutterWindow::listenNotify()
{
    HWND hwnd = Win32Window::GetHandle();
    notifyChannel.get()->SetMethodCallHandler([hwnd](const auto& call, auto result) {
        if (call.method_name().compare("push_notify") == 0) {
            const auto* argument = std::get_if<flutter::EncodableList>(call.arguments());
            auto title = argument->at(0);
            auto message = argument->at(1);

            Notify::setTitle(std::get<std::string>(title));
            Notify::setMessage(std::get<std::string>(message));
            if (!PostMessage(hwnd, VM_SYSTEMTRAY, MS_NOTIFY, 0)) {
                return;
            }
        }
        });
}

void getUpdate() {
  updateChannel.get()->SetMethodCallHandler([](const auto& call, auto result) {
    if (call.method_name().compare("get_update") == 0) {
      win_sparkle_set_appcast_url("https://statics.pancake.vn/panchat-dev/pake.xml");
      win_sparkle_init();
      win_sparkle_check_update_with_ui();
      win_sparkle_set_shutdown_request_callback([]() {
        exit(0);
      });
      result->Success();
    }
  });
}

void FlutterWindow::windowManager() {
    HWND hwnd = Win32Window::GetHandle();
    windowManagerChannel.get()->SetMethodCallHandler([hwnd](const auto& call, auto result) {
        if (call.method_name().compare("wakeUp") == 0) {
            ShowWindowAsync(hwnd, SW_SHOW);
            SetForegroundWindow(hwnd);
            
        } else if (call.method_name().compare("isMinimized") == 0) {
            WINDOWPLACEMENT windowPlacement;
            GetWindowPlacement(hwnd, &windowPlacement);
            result->Success(flutter::EncodableValue(windowPlacement.showCmd == SW_SHOWMINIMIZED));
        } else if (call.method_name().compare("isMaximized") == 0) {
            WINDOWPLACEMENT windowPlacement;
            GetWindowPlacement(hwnd, &windowPlacement);
            result->Success(flutter::EncodableValue(windowPlacement.showCmd == SW_MAXIMIZE));
        } else if (call.method_name().compare("restore") == 0) {
            WINDOWPLACEMENT windowPlacement;
            GetWindowPlacement(hwnd, &windowPlacement);
            if (windowPlacement.showCmd != SW_NORMAL) {
                PostMessage(hwnd, WM_SYSCOMMAND, SC_RESTORE, 0);
            }
        }
    });
}

void streamToClipboard(
    IStream* pStreamIn, BSTR wszOutputMimeType)
{
    namespace G = Gdiplus;
    G::Image imageSrc(pStreamIn);
    G::Bitmap* gdiBitmap = (G::Bitmap*)imageSrc.Clone();

    if (gdiBitmap) {
        HBITMAP hbitmap;
        gdiBitmap->GetHBITMAP(0, &hbitmap);
        if (OpenClipboard(NULL)) {
            EmptyClipboard();
            DIBSECTION ds;
            if (GetObject(hbitmap, sizeof(DIBSECTION), &ds)) {
                HDC hdc = GetDC(HWND_DESKTOP);
                HBITMAP hbitmap_ddb = CreateDIBitmap(hdc, &ds.dsBmih, CBM_INIT,
                    ds.dsBm.bmBits, (BITMAPINFO*)&ds.dsBmih, DIB_RGB_COLORS);
                ReleaseDC(HWND_DESKTOP, hdc);
                SetClipboardData(CF_BITMAP, hbitmap_ddb);
                DeleteObject(hbitmap_ddb);
            }
            CloseClipboard();
        }
        DeleteObject(hbitmap);
        delete gdiBitmap;
    }
}

void FlutterWindow::onCopyImage() {
    Gdiplus::GdiplusStartupInput gdiplusStartupInput;
    ULONG_PTR gdiplusToken;
    Gdiplus::GdiplusStartup(&gdiplusToken, &gdiplusStartupInput, NULL);
    
    copyChannel.get()->SetMethodCallHandler([](const auto& call, auto result) {
        if (call.method_name().compare("copy_image") == 0) {
            auto arg = call.arguments();
            string urlString = std::get<string>(*arg);

            const char* URL = urlString.c_str();
            IStream* stream;
            if (getURL(0, URL, &stream, 0, 0)) {
                std::cout << "Error occured.";
                return;
            }
            streamToClipboard(stream, L"image/jpeg");
        }
        });
}




static BOOL OpenClipboard_ButTryABitHarder(HWND hWnd)
{
    for (int i = 0; i < 20; ++i)
    {
        if (OpenClipboard(hWnd)) return true;
        Sleep(10);
    }
    return false;
}
static DWORD GetPixelDataOffsetForPackedDIB(const BITMAPINFOHEADER* BitmapInfoHeader)
{
    INT OffsetExtra = 0;

    if (BitmapInfoHeader->biSize == sizeof(BITMAPINFOHEADER))
    {
        if (BitmapInfoHeader->biBitCount > 8)
        {
            if (BitmapInfoHeader->biCompression == BI_BITFIELDS)
            {
                OffsetExtra += 3 * sizeof(RGBQUAD);
            }
            else if (BitmapInfoHeader->biCompression == 6)
            {
                OffsetExtra += 4 * sizeof(RGBQUAD);
            }
        }
    }

    if (BitmapInfoHeader->biClrUsed > 0)
    {
        OffsetExtra += BitmapInfoHeader->biClrUsed * sizeof(RGBQUAD);
    }
    else
    {
        if (BitmapInfoHeader->biBitCount <= 8) {
            OffsetExtra += sizeof(RGBQUAD) << BitmapInfoHeader->biBitCount;
        }
    }

    return BitmapInfoHeader->biSize + OffsetExtra;
}


wchar_t* Notify::_title = new wchar_t[1000];
wchar_t* Notify::_message = new wchar_t[1000];
wchar_t* StringToWchar(std::string src);
bool SystemCommand::_tray = true;

void Notify::setTitle(std::string title)
{
    wcscpy(_title, StringToWchar(title));
}

void Notify::setMessage(std::string message)
{
    wcscpy(_message, StringToWchar(message));
}

wchar_t* Notify::getTitle()
{
    return _title;
}

wchar_t* Notify::getMessage()
{
    return _message;
}

wchar_t* StringToWchar(std::string src)
{
    int wcSize = MultiByteToWideChar(CP_UTF8, 0, src.c_str(), -1, NULL, 0);
    wchar_t* wstr = new wchar_t[wcSize];
    MultiByteToWideChar(CP_UTF8, 0, src.c_str(), -1, wstr, wcSize);
    return wstr;
}
bool SystemCommand::getCheckTray()
{
  return _tray;
}
void SystemCommand::setSystemTray(bool _check)
{
  _tray = _check;
}