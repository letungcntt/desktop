import Cocoa
import FlutterMacOS

class MainFlutterWindow: NSWindow, NSWindowDelegate {
    var customToolbar: NSToolbar?
    var boolIsFullScreen = false
    override func awakeFromNib() {
        
        let flutterViewController = FlutterViewController.init()
        let windowFrame = self.frame
        self.contentViewController = flutterViewController
        self.setFrame(windowFrame, display: true)
        self.delegate = self
    

        RegisterGeneratedPlugins(registry: flutterViewController)
        DropZone.attach(to: flutterViewController)
        super.awakeFromNib()
        
        customToolbar = NSToolbar()
        customToolbar?.showsBaselineSeparator = false
        self.titlebarAppearsTransparent = true
        self.titleVisibility = .hidden
        self.toolbar = customToolbar
        
        guard let data = UserDefaults.standard.data(forKey: "PancakeChat"),
              let frame = try? NSKeyedUnarchiver.unarchiveTopLevelObjectWithData(data) as? NSRect
        else {
            print("Get data from local fail")
            return
        }
        self.setFrame(frame, display: true)
    }
    func windowWillEnterFullScreen(_ notification: Notification) {
        boolIsFullScreen = true
    }
    func windowWillExitFullScreen(_ notification: Notification) {
        boolIsFullScreen = false
    }
    override func layoutIfNeeded() {
        if boolIsFullScreen {
            self.toolbar?.isVisible = false
        } else {
            self.toolbar?.isVisible = true
        }
    }
}

class DropZone: NSView{
    static func attach(to flutterViewController: FlutterViewController){
        let n = "drop_zone"
        let r = flutterViewController.registrar(forPlugin: n)
        let channel = FlutterMethodChannel(name: n, binaryMessenger: r.messenger)
        let d = DropZone(frame: flutterViewController.view.bounds, channel: channel)
        d.autoresizingMask = [.width, .height]
        d.registerForDraggedTypes([.fileURL])
        flutterViewController.view.addSubview(d)
        
    }
    private let channel: FlutterMethodChannel
    init(frame: NSRect, channel: FlutterMethodChannel) {
        self.channel = channel
        super.init(frame: frame)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    private let commandKey = NSEvent.ModifierFlags.command.rawValue
    private var appearanceObserver: NSKeyValueObservation?
    override func performKeyEquivalent(with event: NSEvent) -> Bool {
        if event.type == NSEvent.EventType.keyDown {
            if (event.modifierFlags.rawValue & NSEvent.ModifierFlags.deviceIndependentFlagsMask.rawValue) == commandKey {
                switch event.charactersIgnoringModifiers! {
                 case "v":
                    var datas = [Any]()
                    datas.append("paste_bytes")
                    if let items = NSPasteboard.general.pasteboardItems {
                        for item in items {
                            if let alias = item.string(forType: .fileURL) {
                                do {
                                    let data:NSData = try NSData.init(contentsOfFile: String(alias.dropFirst(7).removingPercentEncoding!))
                                    datas.append(data)
                                } catch let error {
                                    print(error)
                                }
                            }
                            else{
                                let pb = NSPasteboard.general
                                let type = NSPasteboard.PasteboardType.tiff
                                if pb.data(forType: type) != nil {
                                    guard let imgData = pb.data(forType: type) else { return false }
                                    datas.append(imgData)
                                }
                            }
                        }
                    }
                    channel.invokeMethod("dropped", arguments: datas)
                default:
                    break
                }
            }
            if (event.keyCode == 53) {
                return true
            }
        }
        return super.performKeyEquivalent(with: event)
    }
    override func draggingEntered(_ sender: NSDraggingInfo) -> NSDragOperation {
        channel.invokeMethod("entered", arguments: nil)
        self.layer?.borderColor = NSColor.controlAccentColor.cgColor
        self.layer?.borderWidth = 0.0
        return .copy
    }
    override func draggingUpdated(_ sender: NSDraggingInfo) -> NSDragOperation {
        let location = sender.draggingLocation
        channel.invokeMethod("updated", arguments: [String(format: "%f", location.x) + ":" + String(format: "%f", bounds.height - location.y)])
        return .copy
    }
    override func draggingExited(_ sender: NSDraggingInfo?) {
        channel.invokeMethod("exited", arguments: nil)
        self.layer?.borderColor = NSColor.clear.cgColor
        self.layer?.borderWidth = 0.0
    }
    override func draggingEnded(_ sender: NSDraggingInfo) {
        self.layer?.borderColor = NSColor.clear.cgColor
        self.layer?.borderWidth = 0.0
    }
    override func performDragOperation(_ sender: NSDraggingInfo) -> Bool {
        let location = sender.draggingLocation
        var urls = [Any]()
        let cursor = String(format: "%f", location.x) + ":" + String(format: "%f", bounds.height - location.y)
        urls.append(cursor)
        if let items = sender.draggingPasteboard.pasteboardItems {
            for item in items {
                if let alias = item.string(forType: .fileURL) {
                    urls.append(URL(fileURLWithPath: alias).standardized.absoluteString)
                }
            }
        }
        channel.invokeMethod("dropped", arguments: urls)
        return true
    }
     override func viewWillMove(toWindow newWindow: NSWindow?) {
        super.viewWillMove(toWindow: newWindow)
        if let window = newWindow {
            appearanceObserver = window.observe(\.effectiveAppearance) {
                [weak self] (window, change) in
                self?.viewDidChangeEffectiveAppearance()
                let appearance = NSApp.effectiveAppearance
                var currentTheme = ""
                switch appearance.bestMatch(from: [.aqua, .darkAqua]) {
                  case .aqua?:
                    currentTheme = "NSAppearanceNameAqua"
                  case .darkAqua?:
                    currentTheme = "NSAppearanceNameDarkAqua"
                  default:
                    currentTheme = "NSAppearanceNameAqua"
                }
                self?.channel.invokeMethod("change_theme", arguments: currentTheme)
            }
       } else {
        appearanceObserver = nil
       }
    }
}
