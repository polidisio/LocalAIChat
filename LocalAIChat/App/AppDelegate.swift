import AppKit
import SwiftUI

@MainActor
class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem?
    private var popover: NSPopover?
    private var mainWindow: NSWindow?
    private var menuBarViewModel: MenuBarViewModel!

    nonisolated func applicationDidFinishLaunching(_ notification: Notification) {
        Task { @MainActor in
            setupMenuBar()
            setupMainWindow()
            showMainWindow()
        }
    }

    private func setupMenuBar() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)

        if let button = statusItem?.button {
            button.image = NSImage(systemSymbolName: "brain.head.side", accessibilityDescription: "MindChat")
        }

        menuBarViewModel = MenuBarViewModel(
            onShowWindow: { [weak self] in self?.showMainWindow() },
            onNewChat: { [weak self] in self?.newChat() },
            onQuit: { NSApp.terminate(nil) }
        )

        let menuBarView = MenuBarPopoverView(viewModel: menuBarViewModel)
        let hostingController = NSHostingController(rootView: menuBarView)

        popover = NSPopover()
        popover?.contentViewController = hostingController
        popover?.behavior = .transient
        popover?.animates = true

        statusItem?.button?.action = #selector(togglePopover)
        statusItem?.button?.target = self
    }

    @objc private func togglePopover() {
        guard let popover = popover, let button = statusItem?.button else { return }
        if popover.isShown {
            popover.performClose(nil)
        } else {
            popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
        }
    }

    private func setupMainWindow() {
        let contentView = MainContentView()
        let hostingController = NSHostingController(rootView: contentView)

        mainWindow = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 1024, height: 800),
            styleMask: [.titled, .closable, .miniaturizable, .resizable],
            backing: .buffered,
            defer: false
        )
        mainWindow?.title = "MindChat"
        mainWindow?.contentViewController = hostingController
        mainWindow?.center()
        mainWindow?.minSize = NSSize(width: 900, height: 700)
    }

    func showMainWindow() {
        mainWindow?.makeKeyAndOrderFront(nil)
        popover?.performClose(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    private func newChat() {
        NotificationCenter.default.post(name: .newChatRequested, object: nil)
        showMainWindow()
    }

    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        if !flag {
            showMainWindow()
        }
        return true
    }
}

extension Notification.Name {
    static let newChatRequested = Notification.Name("newChatRequested")
}