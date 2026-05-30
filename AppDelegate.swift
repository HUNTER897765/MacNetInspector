import AppKit
import SwiftUI

class AppDelegate: NSObject, NSApplicationDelegate {
    var statusItem: NSStatusItem?
    var popover: NSPopover?

    func applicationDidFinishLaunching(_ notification: Notification) {
        // Optional: set activation policy to regular so Dock icon shows
        NSApp.setActivationPolicy(.regular)
    }
}
