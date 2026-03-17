import SwiftUI
import UIKit

struct ExportView: View {
	@EnvironmentObject private var store: DeviceLogStore
	@State private var exportMode: ExportMode = .csv
	@State private var showShare = false
	@State private var lastCopiedBanner = false

	enum ExportMode: String, CaseIterable, Identifiable {
		case csv = "CSV"
		case separated = "Separated"

		var id: String { rawValue }
	}

	var body: some View {
		NavigationStack {
			Form {
				Section("Format") {
					Picker("Export format", selection: $exportMode) {
						ForEach(ExportMode.allCases, id: \.self) { m in
							Text(m.rawValue).tag(m)
						}
					}
					.pickerStyle(.segmented)
				}

				Section("Preview") {
					Text(exportText)
						.font(.footnote.monospaced())
						.textSelection(.enabled)
						.lineLimit(12)
						.frame(maxWidth: .infinity, alignment: .leading)
				}

				Section {
					Button {
						UIPasteboard.general.string = exportText
						lastCopiedBanner = true
						DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
							lastCopiedBanner = false
						}
					} label: {
						Label("Copy to Clipboard", systemImage: "doc.on.doc")
					}
					.disabled(store.entries.isEmpty)

					Button {
						showShare = true
					} label: {
						Label("Share…", systemImage: "square.and.arrow.up")
					}
					.disabled(store.entries.isEmpty)
				}

				Section("Notes") {
					if exportMode == .csv {
						Text("CSV is easiest to paste into Excel/Sheets.")
							.foregroundStyle(.secondary)
					} else {
						Text("Separated format is easiest to paste into email/chat; each device entry is separated by a divider.")
							.foregroundStyle(.secondary)
					}
				}
			}
			.navigationTitle("Export")
			.overlay(alignment: .top) {
				if lastCopiedBanner {
					Text("Copied")
						.padding(.horizontal, 12)
						.padding(.vertical, 8)
						.background(.thinMaterial)
						.clipShape(Capsule())
						.padding(.top, 10)
				}
			}
			.sheet(isPresented: $showShare) {
				ShareSheet(items: [exportText])
			}
		}
	}

	private var exportText: String {
		switch exportMode {
		case .csv:
			return store.exportCSV()
		case .separated:
			return store.exportSeparatedText()
		}
	}
}

