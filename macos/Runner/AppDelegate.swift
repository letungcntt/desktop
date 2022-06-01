import Cocoa
import FlutterMacOS
import Sparkle
import Foundation
import AppKit


extension String {
    func matchingStrings(regex: String) -> [[String]] {
        guard let regex = try? NSRegularExpression(pattern: regex, options: []) else { return [] }
        let nsString = self as NSString
        let results  = regex.matches(in: self, options: [], range: NSMakeRange(0, nsString.length))
        return results.map { result in
            (0..<result.numberOfRanges).map {
                result.range(at: $0).location != NSNotFound
                    ? nsString.substring(with: result.range(at: $0))
                    : ""
            }
        }
    }
}

extension String {
    func versionCompare(_ otherVersion: String) -> ComparisonResult {
        return self.compare(otherVersion, options: .numeric)
    }
}

@NSApplicationMain
class AppDelegate: FlutterAppDelegate, SPUUpdaterDelegate, SPUStandardUserDriverDelegate {
    var updaterController: SPUStandardUpdaterController?
    override func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return false
    }
    
    override func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        if let window = sender.windows.first {
            if flag {
                window.orderFront(nil)
            } else {
                window.makeKeyAndOrderFront(nil)
            }
        }

        return true
    }
    override func applicationDidResignActive(_ notification: Notification) {
        let controller = mainFlutterWindow.contentViewController as? FlutterViewController
        let name = "drop_zone"
        let r = controller?.registrar(forPlugin: name)
        let channel = FlutterMethodChannel(name: name, binaryMessenger: r!.messenger as FlutterBinaryMessenger)
        channel.invokeMethod("is_focused", arguments: false)
    }
    
    override func applicationDidBecomeActive(_ notification: Notification) {
        let controller = mainFlutterWindow.contentViewController as? FlutterViewController
        let name = "drop_zone"
        let r = controller?.registrar(forPlugin: name)
        let channel = FlutterMethodChannel(name: name, binaryMessenger: r!.messenger as FlutterBinaryMessenger)
        channel.invokeMethod("is_focused", arguments: true)
    }

    override func applicationDidFinishLaunching(_ notification: Notification) {
        UserDefaults.standard.set(true, forKey: "SUAutomaticallyUpdate")
        if updaterController == nil {
            updaterController = SPUStandardUpdaterController(startingUpdater: false, updaterDelegate: self, userDriverDelegate: self)
            updaterController?.startUpdater()
        }
        getUpdate()
        // autoCheckUpdateInstart()
        copyImageToClipboard()
        windowManager()
        Timer.scheduledTimer(withTimeInterval: 3600.0, repeats: true) {[self] timers in
            updaterController?.userDriver.showUpdateInFocus()
        }
    }

    override func applicationWillTerminate(_ notification: Notification) {
        let frame = mainFlutterWindow.frame
        let data = try? NSKeyedArchiver.archivedData(withRootObject: frame, requiringSecureCoding: false)
        UserDefaults.standard.set(data, forKey: "PancakeChat")
    }

    func autoCheckUpdateInstart() -> Void {
        var appVersion = Bundle.main.object(forInfoDictionaryKey:"CFBundleShortVersionString") as! String
        appVersion = String(appVersion)
        var getVersion = ""
        Timer.scheduledTimer(withTimeInterval: 5.0, repeats: true){ [self] timer in
            let url = URL(string: "https://statics.pancake.vn/panchat-dev/pancake_chat.xml")!
            let task = URLSession.shared.dataTask(with: url) {(data, response, error) in
                guard let data = data else { return }
                let stringData = String(decoding: data, as: UTF8.self)
                let match = stringData.matchingStrings(regex: "<sparkle:shortVersionString>[0-9][.][0-9][.][0-9]")
                getVersion = match[0][0].components(separatedBy: ">")[1]

            }
            task.resume()

            if(appVersion.versionCompare(getVersion) == ComparisonResult.orderedAscending){
                updaterController?.checkForUpdates(self)
                timer.invalidate()
            }
        }
    }

    func getUpdate() -> Void {
        let controller = mainFlutterWindow.contentViewController as? FlutterViewController
        let name = "update"
        let r = controller?.registrar(forPlugin: name)
        let channel = FlutterMethodChannel(name: name, binaryMessenger: r!.messenger as FlutterBinaryMessenger)
        channel.setMethodCallHandler { [self] (call: FlutterMethodCall,result: @escaping FlutterResult) in
            if call.method == "get_update"{
                let arg = call.arguments as! Bool
                if arg {
                    updaterController?.checkForUpdates(self)
                } else {
                    autoCheckUpdateInstart()
                }
            }
        }
    }

    func copyImageToClipboard() -> Void {
        let controller = mainFlutterWindow.contentViewController as? FlutterViewController
        let name = "copy"
        let r = controller?.registrar(forPlugin: name)
        let channel = FlutterMethodChannel(name: name, binaryMessenger: r!.messenger as FlutterBinaryMessenger)
        channel.setMethodCallHandler { (call: FlutterMethodCall, result: @escaping FlutterResult) in
            if call.method == "copy_image" {
                do {
                    var urlImage = call.arguments as! String
                    if (urlImage.hasPrefix("https:")) {
                        urlImage = urlImage.replacingOccurrences(of: " ", with: "%20")
                        let data:NSData = try NSData.init(contentsOf: URL(string: urlImage)!)
                        NSPasteboard.general.clearContents()
                        NSPasteboard.general.setData(data as Data, forType: NSPasteboard.PasteboardType.tiff)
                        result(true)
                    } else {
                        let data = FileManager.default.contents(atPath: urlImage)
                        NSPasteboard.general.clearContents()
                        NSPasteboard.general.setData(data! as Data, forType: NSPasteboard.PasteboardType.tiff)
                        result(true)
                    }
                } catch  {
                    result(false)
                }
            }
        }
    }

    func windowManager() -> Void {
        let controller = mainFlutterWindow.contentViewController as? FlutterViewController
        let name = "window_manager"
        let r = controller?.registrar(forPlugin: name)
        let channel = FlutterMethodChannel(name: name, binaryMessenger: r!.messenger as FlutterBinaryMessenger)
        channel.setMethodCallHandler { (call: FlutterMethodCall, result: @escaping FlutterResult) in
            switch (call.method) {
            case "wakeUp":
                self.mainFlutterWindow.setIsVisible(true)
                DispatchQueue.main.async {
                    self.mainFlutterWindow.makeKeyAndOrderFront(nil)
                    NSApp.activate(ignoringOtherApps: true)
                }
                result(nil)
                break
            case "restore":
                self.mainFlutterWindow.deminiaturize(nil)
                result(nil)
            case "isMinimized":
                result(self.mainFlutterWindow.isMiniaturized)
                break
            case "isMaximized":
                result(self.mainFlutterWindow.isZoomed)
                break
            default:
                result(FlutterMethodNotImplemented)
            }
        }
    }

    @IBAction func checkForUpdates(_ sender: Any) {
        updaterController?.checkForUpdates(self)
    }
}
