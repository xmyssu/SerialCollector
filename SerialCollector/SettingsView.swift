import SwiftUI

struct SettingsView: View {
	@EnvironmentObject private var store: DeviceLogStore

	var body: some View {
		NavigationStack {
			Form {
				Section("Appearance") {
					Picker("Theme", selection: $store.appColorScheme) {
						Text("System").tag(AppColorScheme.system)
						Text("Light").tag(AppColorScheme.light)
						Text("Dark").tag(AppColorScheme.dark)
					}
				}

				Section("Serial detection") {
					TextField("Serial regex pattern", text: $store.serialRegexPattern)
						.textInputAutocapitalization(.never)
						.autocorrectionDisabled()
					Text("If your serials start with CN/PF/etc, you can tighten the regex (example: `\\b(?:CN|PF)[A-Z0-9]{6,18}\\b`).")
						.font(.footnote)
						.foregroundStyle(.secondary)
				}

				Section("Email defaults") {
					TextField("Default recipient (To)", text: $store.emailTo)
						.textInputAutocapitalization(.never)
						.autocorrectionDisabled()
						.keyboardType(.emailAddress)

					TextField("Default subject", text: $store.emailSubject)
				}

				Section("Email template") {
					TextField("Greeting line", text: $store.emailGreetingLine)

					TextField("Returned template", text: $store.emailReturnedTemplate, axis: .vertical)
						.lineLimit(2...4)

					TextField("Assigned template", text: $store.emailAssignedTemplate, axis: .vertical)
						.lineLimit(2...4)

					Text("Use placeholders: `{serial}` and `{person}`.")
						.font(.footnote)
						.foregroundStyle(.secondary)
				}
			}
			.navigationTitle("Settings")
		}
	}
}

