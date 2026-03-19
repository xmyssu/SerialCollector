import Foundation
import Combine

@MainActor
final class DeviceLogStore: ObservableObject {
	@Published private(set) var entries: [DeviceLogEntry] = []
	@Published var serialRegexPattern: String = SerialExtractor.defaultPattern {
		didSet { persistSettings() }
	}
	@Published var appColorScheme: AppColorScheme = .system {
		didSet { persistSettings() }
	}

	@Published var emailTo: String = "" {
		didSet { persistSettings() }
	}
	@Published var emailSubject: String = "Seadmete liikumised" {
		didSet { persistSettings() }
	}
	@Published var emailGreetingLine: String = "Tere!" {
		didSet { persistSettings() }
	}
	@Published var emailReturnedTemplate: String = "Seade {serial} liikus tagasi IT lattu." {
		didSet { persistSettings() }
	}
	@Published var emailAssignedTemplate: String = "Seade {serial} liikus kasutaja {person} kasutusse." {
		didSet { persistSettings() }
	}
	@Published var recentEmailRecipients: [String] = [] {
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

	func exportEmailBody() -> String {
		// Layout:
		// Tere!
		//
		// Seade X liikus ...
		//
		let greeting = emailGreetingLine.trimmingCharacters(in: .whitespacesAndNewlines)
		let lines = entries
			.sorted(by: { $0.createdAt < $1.createdAt })
			.map { emailLine(for: $0) }
			.filter { !$0.isEmpty }

		var out: [String] = []
		out.append(greeting.isEmpty ? "Tere!" : greeting)
		out.append("")
		out.append(contentsOf: lines)
		out.append("")
		return out.joined(separator: "\n")
	}

	private func emailLine(for entry: DeviceLogEntry) -> String {
		switch entry.movement {
		case .returnedToStorage:
			return applyTemplate(emailReturnedTemplate, serial: entry.serialNumber, person: entry.personName)
		case .assignedOut:
			return applyTemplate(emailAssignedTemplate, serial: entry.serialNumber, person: entry.personName)
		}
	}

	private func applyTemplate(_ template: String, serial: String, person: String?) -> String {
		let s = serial.trimmingCharacters(in: .whitespacesAndNewlines)
		let p = (person ?? "").trimmingCharacters(in: .whitespacesAndNewlines)

		return template
			.replacingOccurrences(of: "{serial}", with: s)
			.replacingOccurrences(of: "{person}", with: p)
			.trimmingCharacters(in: .whitespacesAndNewlines)
	}

	func rememberRecipient(_ raw: String) {
		let r = raw.trimmingCharacters(in: .whitespacesAndNewlines)
		guard !r.isEmpty else { return }
		var set = Array([r] + recentEmailRecipients)
		// De-dup while preserving order
		var seen: Set<String> = []
		set = set.filter { item in
			let key = item.lowercased()
			if seen.contains(key) { return false }
			seen.insert(key)
			return true
		}
		recentEmailRecipients = Array(set.prefix(10))
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
		var appColorScheme: AppColorScheme
		var emailTo: String
		var emailSubject: String
		var emailGreetingLine: String
		var emailReturnedTemplate: String
		var emailAssignedTemplate: String
		var recentEmailRecipients: [String]
	}

	private func loadSettings() {
		do {
			let data = try Data(contentsOf: settingsURL)
			let s = try decoder.decode(Settings.self, from: data)
			serialRegexPattern = s.serialRegexPattern
			appColorScheme = s.appColorScheme
			emailTo = s.emailTo
			emailSubject = s.emailSubject
			emailGreetingLine = s.emailGreetingLine
			emailReturnedTemplate = s.emailReturnedTemplate
			emailAssignedTemplate = s.emailAssignedTemplate
			recentEmailRecipients = s.recentEmailRecipients
		} catch {
			serialRegexPattern = SerialExtractor.defaultPattern
			appColorScheme = .system
			emailTo = ""
			emailSubject = "Seadmete liikumised"
			emailGreetingLine = "Tere!"
			emailReturnedTemplate = "Seade {serial} liikus tagasi IT lattu."
			emailAssignedTemplate = "Seade {serial} liikus kasutaja {person} kasutusse."
			recentEmailRecipients = []
		}
	}

	private func persistSettings() {
		do {
			let data = try encoder.encode(Settings(
				serialRegexPattern: serialRegexPattern,
				appColorScheme: appColorScheme,
				emailTo: emailTo,
				emailSubject: emailSubject,
				emailGreetingLine: emailGreetingLine,
				emailReturnedTemplate: emailReturnedTemplate,
				emailAssignedTemplate: emailAssignedTemplate,
				recentEmailRecipients: recentEmailRecipients
			))
			try data.write(to: settingsURL, options: [.atomic])
		} catch {
			// Best-effort.
		}
	}
}

