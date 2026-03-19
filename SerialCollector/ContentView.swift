import SwiftUI

struct ContentView: View {
	@EnvironmentObject private var store: DeviceLogStore

	var body: some View {
		TabView {
			ScanView()
				.tabItem { Label("Scan", systemImage: "camera.viewfinder") }

			HistoryView()
				.tabItem { Label("History", systemImage: "clock") }

			ExportView()
				.tabItem { Label("Export", systemImage: "square.and.arrow.up") }

			SettingsView()
				.tabItem { Label("Settings", systemImage: "gearshape") }
		}
		.preferredColorScheme(preferredScheme)
	}

	private var preferredScheme: ColorScheme? {
		switch store.appColorScheme {
		case .system:
			return nil
		case .light:
			return .light
		case .dark:
			return .dark
		}
	}
}

