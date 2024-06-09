import AppKit
import SwiftUI

@available(macOS 14.0, *)
@MainActor
class AppDelegate: NSObject, NSApplicationDelegate {
	let window = NSWindow()
	let windowDelegate = WindowDelegate()

	let vm = SignatureCheckerViewModel()

	func applicationDidFinishLaunching(_ notification: Notification) {
		let appMenu = NSMenuItem()
		appMenu.submenu = NSMenu()
		appMenu.submenu?.addItem(NSMenuItem(title: "Quit", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q"))

		let fileMenu = NSMenuItem()
		fileMenu.submenu = NSMenu()
		fileMenu.title = "File"
		let openItem = NSMenuItem(title: "Open", action: #selector(openMenuItemSelected), keyEquivalent: "o")
		fileMenu.submenu?.addItem(openItem)

		let editMenu = NSMenuItem()
		editMenu.submenu = NSMenu()
		editMenu.title = "Edit"

		let selectAllItem = NSMenuItem(title: "Select All", action: #selector(NSResponder.selectAll), keyEquivalent: "a")
		editMenu.submenu?.addItem(selectAllItem)
		let copyItem = NSMenuItem(title: "Copy", action: #selector(NSResponder.copy), keyEquivalent: "c")
		editMenu.submenu?.addItem(copyItem)
		let pasteItem = NSMenuItem(title: "Paste", action: #selector(NSText.paste), keyEquivalent: "v")
		editMenu.submenu?.addItem(pasteItem)

		let mainMenu = NSMenu(title: "Signing Checker")
		mainMenu.addItem(appMenu)
		mainMenu.addItem(fileMenu)
		mainMenu.addItem(editMenu)
		NSApplication.shared.mainMenu = mainMenu

		let size = CGSize(width: 480, height: 270)
		window.setContentSize(size)
		window.styleMask = [.closable, .miniaturizable, .resizable, .titled]
		window.delegate = windowDelegate
		window.title = "Signing Checker"

		let view = NSHostingView(rootView: MainSignatureCheckerView(viewModel: vm, delegate: self))
		view.frame = CGRect(origin: .zero, size: size)
		view.autoresizingMask = [.height, .width]
		window.contentView!.addSubview(view)
		window.center()
		window.makeKeyAndOrderFront(window)

		NSApp.setActivationPolicy(.regular)
		NSApp.activate(ignoringOtherApps: true)
	}

	@IBAction
	private func openMenuItemSelected(_ sender: Any) {
		let openModal = NSOpenPanel()

		let response = openModal.runModal()
		guard
			response == .OK,
			let url = openModal.url
		else { return }

		vm.selectedFile = url
	}
}

@available(macOS 14.0, *)
extension AppDelegate: MainSignatureCheckerViewdDelegate {
	func mainView(_ mainView: MainSignatureCheckerView, didEncounterError error: any Error) {
		let alert = NSAlert(error: error)

		alert.runModal()
	}
}
