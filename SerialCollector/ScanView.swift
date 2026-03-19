import SwiftUI
import PhotosUI

struct ScanView: View {
	@EnvironmentObject private var store: DeviceLogStore

	@State private var pickedItem: PhotosPickerItem?
	@State private var pickedImage: UIImage?
	@State private var recognizedText: String = ""
	@State private var candidates: [SerialCandidate] = []

	@State private var isProcessing = false
	@State private var errorMessage: String?

	@State private var showCamera = false
	@State private var selectedSerial: String = ""

	@State private var movement: DeviceMovement = .returnedToStorage
	@State private var personName: String = ""
	@State private var notes: String = ""
	@State private var showSaveSheet = false

	var body: some View {
		NavigationStack {
			Form {
				Section {
					HStack(spacing: 12) {
						PhotosPicker(selection: $pickedItem, matching: .images) {
							Label("Pick Photo", systemImage: "photo.on.rectangle")
						}
						.buttonStyle(.bordered)

						Button {
							showCamera = true
						} label: {
							Label("Camera", systemImage: "camera")
						}
						.buttonStyle(.bordered)
					}

					if isProcessing {
						HStack {
							ProgressView()
							Text("Looking for serial numbers…")
						}
					}

					if let errorMessage {
						Text(errorMessage)
							.foregroundStyle(.red)
					}
				}

				if let pickedImage {
					Section("Image") {
						Image(uiImage: pickedImage)
							.resizable()
							.scaledToFit()
							.frame(maxHeight: 220)
					}
				}

				Section("Serial candidates") {
					if candidates.isEmpty {
						Text("No serial numbers detected yet.")
							.foregroundStyle(.secondary)
					} else {
						ForEach(candidates) { c in
							Button {
								selectedSerial = c.value
								showSaveSheet = true
							} label: {
								HStack {
									Text(c.value)
										.font(.system(.body, design: .monospaced))
									Spacer()
									Text("\(c.score)")
										.foregroundStyle(.secondary)
								}
							}
						}
					}

					Button("Enter serial manually…") {
						selectedSerial = ""
						showSaveSheet = true
					}
				}

				Section("Detection settings") {
					Button("Re-run detection") {
						Task { await runOCRAndExtract() }
					}
					.disabled(pickedImage == nil || isProcessing)
				}

				if !recognizedText.isEmpty {
					Section("Recognized text (debug)") {
						Text(recognizedText)
							.font(.footnote)
							.textSelection(.enabled)
					}
				}
			}
			.navigationTitle("Serial Collector")
			.sheet(isPresented: $showCamera) {
				CameraPicker { img in
					pickedImage = img
					Task { await runOCRAndExtract() }
				}
			}
			.sheet(isPresented: $showSaveSheet) {
				NavigationStack {
					Form {
						Section("Serial number") {
							TextField("Serial", text: $selectedSerial)
								.textInputAutocapitalization(.characters)
								.autocorrectionDisabled()
								.font(.system(.body, design: .monospaced))
						}

						Section("Movement") {
							Picker("Status", selection: $movement) {
								ForEach(DeviceMovement.allCases) { m in
									Text(m.rawValue).tag(m)
								}
							}
							.pickerStyle(.segmented)

							if movement == .assignedOut {
								TextField("Person's name", text: $personName)
									.textContentType(.name)
							}
						}

						Section("Notes (optional)") {
							TextField("Notes", text: $notes, axis: .vertical)
								.lineLimit(3...6)
						}
					}
					.navigationTitle("Save entry")
					.toolbar {
						ToolbarItem(placement: .cancellationAction) {
							Button("Cancel") { showSaveSheet = false }
						}
						ToolbarItem(placement: .confirmationAction) {
							Button("Save") { saveEntry() }
								.disabled(!canSave)
						}
					}
					.onAppear {
						// Reset form defaults each time.
						movement = .returnedToStorage
						personName = ""
						notes = ""
					}
				}
			}
			.onChange(of: pickedItem) { newItem in
				guard let newItem else { return }
				Task {
					do {
						if let data = try await newItem.loadTransferable(type: Data.self),
						   let img = UIImage(data: data) {
							pickedImage = img
							await runOCRAndExtract()
						}
					} catch {
						errorMessage = error.localizedDescription
					}
				}
			}
		}
	}

	private var canSave: Bool {
		let serialOK = !selectedSerial.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
		if !serialOK { return false }
		if movement == .assignedOut {
			return !personName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
		}
		return true
	}

	private func saveEntry() {
		let serial = selectedSerial.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
		let person = personName.trimmingCharacters(in: .whitespacesAndNewlines)
		let noteValue = notes.trimmingCharacters(in: .whitespacesAndNewlines)

		let entry = DeviceLogEntry(
			serialNumber: serial,
			movement: movement,
			personName: movement == .assignedOut ? (person.isEmpty ? nil : person) : nil,
			notes: noteValue.isEmpty ? nil : noteValue
		)
		store.add(entry: entry)
		showSaveSheet = false
	}

	private func runOCRAndExtract() async {
		guard let pickedImage else { return }
		isProcessing = true
		errorMessage = nil
		recognizedText = ""
		candidates = []

		do {
			let text = try await OCRService.recognizeText(in: pickedImage)
			recognizedText = text
			candidates = SerialExtractor.extract(from: text, pattern: store.serialRegexPattern)
		} catch {
			errorMessage = error.localizedDescription
		}

		isProcessing = false
	}
}

