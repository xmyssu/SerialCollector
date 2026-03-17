import SwiftUI

@main
struct SerialCollectorApp: App {
	@StateObject private var store = DeviceLogStore()

	var body: some Scene {
		WindowGroup {
			ContentView()
				.environmentObject(store)
				.onAppear { store.load() }
		}
	}
}

