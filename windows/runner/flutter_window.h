#ifndef RUNNER_FLUTTER_WINDOW_H_
#define RUNNER_FLUTTER_WINDOW_H_

#include <flutter/dart_project.h>
#include <flutter/flutter_view_controller.h>

#include <memory>

#include "win32_window.h"

class Notify {
private:
    static wchar_t* _title;
    static wchar_t* _message;
public:
    static void setTitle(std::string title);
    static void setMessage(std::string message);
    static wchar_t* getTitle();
    static wchar_t* getMessage();

};
class SystemCommand {
    private:
        static bool _tray;
    public:
        static void setSystemTray(bool _check);
        static bool getCheckTray();
};
// A window that does nothing but host a Flutter view.
class FlutterWindow : public Win32Window, public IDropTarget {
 public:
  // Creates a new FlutterWindow hosting a Flutter view running |project|.
  explicit FlutterWindow(const flutter::DartProject& project);
  virtual ~FlutterWindow();

 protected:
  // Win32Window:
  bool OnCreate() override;
  void OnDestroy() override;
  LRESULT MessageHandler(HWND window, UINT const message, WPARAM const wparam,
                         LPARAM const lparam) noexcept override;
  // IUnknown implementation
  HRESULT __stdcall QueryInterface(REFIID iid, void** ppvObject);
  ULONG __stdcall AddRef(void);
  ULONG __stdcall Release(void);

  // IDropTarget implementation
  HRESULT __stdcall DragEnter(IDataObject* pDataObject, DWORD grfKeyState, POINTL pt, DWORD* pdwEffect);
  HRESULT __stdcall DragOver(DWORD grfKeyState, POINTL pt, DWORD* pdwEffect);
  HRESULT __stdcall DragLeave(void);
  HRESULT __stdcall Drop(IDataObject* pDataObject, DWORD grfKeyState, POINTL pt, DWORD* pdwEffect);

 private:
  // The project to run.
  flutter::DartProject project_;

  // The Flutter instance hosted by this window.
  std::unique_ptr<flutter::FlutterViewController> flutter_controller_;


  // the D&D registered object
  HWND _hwndRegistered;
  // helper function to convert 16-bit wstring to utf-8 encoded string
  std::string utf8_encode(const std::wstring& wstr);
  virtual POINT getCursor(POINTL);
  virtual void onPaste();
  void initMethodChannel();
  virtual void listenSystem();
  virtual void listenNotify();
  virtual void onCopyImage();
  virtual void windowManager();
};

#endif  // RUNNER_FLUTTER_WINDOW_H_
