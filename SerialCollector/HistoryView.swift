import SwiftUI

struct HistoryView: View {
	@EnvironmentObject private var store: DeviceLogStore
	@State private var searchText: String = ""
	@State private var showConfirmDeleteAll = false

	var body: some View {
		NavigationStack {
			List {
				ForEach(filteredEntries) { e in
					VStack(alignment: .leading, spacing: 6) {
						HStack {
							Text(e.serialNumber)
								.font(.system(.headline, design: .monospaced))
							Spacer()
							Text(shortDate(e.createdAt))
								.font(.subheadline)
								.foregroundStyle(.secondary)
						}

						HStack(spacing: 8) {
							Text(e.movement.rawValue)
								.font(.subheadline)
							if e.movement == .assignedOut, let p = e.personName, !p.isEmpty {
								Text("→ \(p)")
									.font(.subheadline)
									.foregroundStyle(.secondary)
							}
						}

						if let n = e.notes, !n.isEmpty {
							Text(n)
								.font(.footnote)
								.foregroundStyle(.secondary)
						}
					}
					.padding(.vertical, 4)
				}
				.onDelete(perform: store.delete)
			}
			.navigationTitle("History")
			.searchable(text: $searchText, placement: .navigationBarDrawer(displayMode: .always), prompt: "Search serial / name / notes")
			.toolbar {
				ToolbarItem(placement: .topBarTrailing) {
					if !store.entries.isEmpty {
						Button(role: .destructive) {
							showConfirmDeleteAll = true
						} label: {
							Image(systemName: "trash")
						}
						.accessibilityLabel("Delete all")
					}
				}
			}
			.confirmationDialog(
				"Delete all history?",
				isPresented: $showConfirmDeleteAll,
				titleVisibility: .visible
			) {
				Button("Delete all", role: .destructive) { store.deleteAll() }
			}
		}
	}

	private var filteredEntries: [DeviceLogEntry] {
		let q = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
		guard !q.isEmpty else { return store.entries }

		return store.entries.filter { e in
			let haystack = [
				e.serialNumber,
				e.movement.rawValue,
				e.personName ?? "",
				e.notes ?? "",
			].joined(separator: " ").lowercased()
			return haystack.contains(q.lowercased())
		}
	}

	private func shortDate(_ d: Date) -> String {
		let df = DateFormatter()
		df.dateStyle = .short
		df.timeStyle = .short
		return df.string(from: d)
	}
}

