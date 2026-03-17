import SwiftUI

struct ContentView: View {
	var body: some View {
		TabView {
			ScanView()
				.tabItem { Label("Scan", systemImage: "camera.viewfinder") }

			HistoryView()
				.tabItem { Label("History", systemImage: "clock") }

			ExportView()
				.tabItem { Label("Export", systemImage: "square.and.arrow.up") }
		}
	}
}

