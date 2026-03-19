import Foundation

enum DeviceMovement: String, Codable, CaseIterable, Identifiable {
	case returnedToStorage = "Returned to Storage"
	case assignedOut = "Assigned Out"

	var id: String { rawValue }
}

enum AppColorScheme: String, Codable, CaseIterable, Identifiable {
	case system
	case light
	case dark

	var id: String { rawValue }
}

struct DeviceLogEntry: Codable, Identifiable, Equatable {
	var id: UUID
	var createdAt: Date
	var serialNumber: String
	var movement: DeviceMovement
	var personName: String?
	var notes: String?

	init(
		id: UUID = UUID(),
		createdAt: Date = Date(),
		serialNumber: String,
		movement: DeviceMovement,
		personName: String? = nil,
		notes: String? = nil
	) {
		self.id = id
		self.createdAt = createdAt
		self.serialNumber = serialNumber
		self.movement = movement
		self.personName = personName
		self.notes = notes
	}
}

struct DeviceLogExportRow: Identifiable {
	let id: UUID
	let csvLine: String
}

