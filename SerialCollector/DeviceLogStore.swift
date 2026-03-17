import Foundation
import Combine

@MainActor
final class DeviceLogStore: ObservableObject {
	@Published private(set) var entries: [DeviceLogEntry] = []
	@Published var serialRegexPattern: String = SerialExtractor.defaultPattern {
		didSet { persistSettings() }
	}

	private let encoder: JSONEncoder = {
		let e = JSONEncoder()
		e.outputFormatting = [.prettyPrinted, .sortedKeys]
		e.dateEncodingStrategy = .iso8601
		return e
	}()

	private let decoder: JSONDecoder = {
		let d = JSONDecoder()
		d.dateDecodingStrategy = .iso8601
		return d
	}()

	private var entriesURL: URL {
		let dir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
		return dir.appendingPathComponent("device-log.json")
	}

	private var settingsURL: URL {
		let dir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
		return dir.appendingPathComponent("settings.json")
	}

	func load() {
		loadSettings()
		do {
			let data = try Data(contentsOf: entriesURL)
			entries = try decoder.decode([DeviceLogEntry].self, from: data).sorted { $0.createdAt > $1.createdAt }
		} catch {
			entries = []
		}
	}

	func add(entry: DeviceLogEntry) {
		entries.insert(entry, at: 0)
		persistEntries()
	}

	func delete(at offsets: IndexSet) {
		entries.remove(atOffsets: offsets)
		persistEntries()
	}

	func deleteAll() {
		entries.removeAll()
		persistEntries()
	}

	func exportCSV() -> String {
		var lines: [String] = []
		lines.append("timestamp,serial,movement,person,notes")
		for e in entries.sorted(by: { $0.createdAt < $1.createdAt }) {
			let ts = ISO8601DateFormatter().string(from: e.createdAt)
			let person = e.personName ?? ""
			let notes = e.notes ?? ""
			lines.append([
				csvEscape(ts),
				csvEscape(e.serialNumber),
				csvEscape(e.movement.rawValue),
				csvEscape(person),
				csvEscape(notes),
			].joined(separator: ","))
		}
		return lines.joined(separator: "\n")
	}

	func exportSeparatedText() -> String {
		// Easy to paste into email/chat: each device entry separated.
		let df = DateFormatter()
		df.dateStyle = .short
		df.timeStyle = .short

		return entries
			.sorted(by: { $0.createdAt < $1.createdAt })
			.map { e in
				var parts: [String] = []
				parts.append("Serial: \(e.serialNumber)")
				parts.append("When: \(df.string(from: e.createdAt))")
				parts.append("Status: \(e.movement.rawValue)")
				if let p = e.personName, !p.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
					parts.append("Person: \(p)")
				}
				if let n = e.notes, !n.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
					parts.append("Notes: \(n)")
				}
				return parts.joined(separator: "\n")
			}
			.joined(separator: "\n\n---\n\n")
	}

	private func csvEscape(_ value: String) -> String {
		if value.contains(",") || value.contains("\"") || value.contains("\n") {
			return "\"\(value.replacingOccurrences(of: "\"", with: "\"\""))\""
		}
		return value
	}

	private func persistEntries() {
		do {
			let data = try encoder.encode(entries)
			try data.write(to: entriesURL, options: [.atomic])
		} catch {
			// Best-effort persistence.
		}
	}

	private struct Settings: Codable {
		var serialRegexPattern: String
	}

	private func loadSettings() {
		do {
			let data = try Data(contentsOf: settingsURL)
			let s = try decoder.decode(Settings.self, from: data)
			serialRegexPattern = s.serialRegexPattern
		} catch {
			serialRegexPattern = SerialExtractor.defaultPattern
		}
	}

	private func persistSettings() {
		do {
			let data = try encoder.encode(Settings(serialRegexPattern: serialRegexPattern))
			try data.write(to: settingsURL, options: [.atomic])
		} catch {
			// Best-effort.
		}
	}
}

