import Cocoa
import Sparkle
final class AppUpdates: NSObject {
 private var controller: SPUStandardUpdaterController?
 func startIfConfigured() {
  guard let feed = Bundle.main.object(forInfoDictionaryKey:"SUFeedURL") as? String,
        URL(string:feed)?.scheme == "https",
        let key = Bundle.main.object(forInfoDictionaryKey:"SUPublicEDKey") as? String,!key.isEmpty else{return}
  controller = SPUStandardUpdaterController(startingUpdater:true,updaterDelegate:nil,userDriverDelegate:nil)
 }
 var status:String {controller == nil ? "Update service will start when the app launches." : "Stable channel · GitHub Releases"}
 var automaticallyChecks:Bool {get {controller?.updater.automaticallyChecksForUpdates ?? true} set {controller?.updater.automaticallyChecksForUpdates = newValue}}
 @objc func check(_ sender:Any?) {
  if let controller = controller {controller.checkForUpdates(sender)}
  else {let alert = NSAlert();alert.messageText = "Updates are not configured yet";alert.informativeText = "This local preview has the updater installed. A signed release and HTTPS update feed are required before updates can be offered.";alert.runModal()}
 }
}
