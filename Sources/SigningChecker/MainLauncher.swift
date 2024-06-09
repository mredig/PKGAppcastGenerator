import AppKit

@available(macOS 14.0, *)
@main
@MainActor
struct MainLauncher {
	static func main() async {
		let app = NSApplication.shared
		let delegate = AppDelegate()
		app.delegate = delegate
		app.run()
	}
}
