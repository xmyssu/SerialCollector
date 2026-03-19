import SwiftUI
import MessageUI

struct EmailDraftView: View {
	@Environment(\.dismiss) private var dismiss
	@EnvironmentObject private var store: DeviceLogStore

	@State private var to: String = ""
	@State private var subject: String = ""
	@State private var messageBody: String = ""

	@State private var showMailComposer = false
	@State private var showContactPicker = false
	@State private var showCannotSendAlert = false

	var body: some View {
		NavigationStack {
			Form {
				Section("To") {
					TextField("email@example.com", text: $to)
						.textInputAutocapitalization(.never)
						.autocorrectionDisabled()
						.keyboardType(.emailAddress)

					if !store.recentEmailRecipients.isEmpty {
						ScrollView(.horizontal, showsIndicators: false) {
							HStack {
								ForEach(store.recentEmailRecipients, id: \.self) { r in
									Button(r) { to = r }
										.buttonStyle(.bordered)
								}
							}
						}
					}

					Button {
						showContactPicker = true
					} label: {
						Label("Pick from Contacts", systemImage: "person.crop.circle.badge.plus")
					}
				}

				Section("Subject") {
					TextField("Subject", text: $subject)
				}

				Section("Message") {
					TextEditor(text: $messageBody)
						.font(.system(.body, design: .monospaced))
						.frame(minHeight: 260)
				}
			}
			.navigationTitle("Email")
			.toolbar {
				ToolbarItem(placement: .cancellationAction) {
					Button("Close") { dismiss() }
				}
				ToolbarItem(placement: .confirmationAction) {
					Button("Send") {
						guard MFMailComposeViewController.canSendMail() else {
							showCannotSendAlert = true
							return
						}
						store.rememberRecipient(to)
						showMailComposer = true
					}
					.disabled(messageBody.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
				}
			}
			.onAppear {
				to = store.emailTo
				subject = store.emailSubject
				messageBody = store.exportEmailBody()
			}
			.alert("Mail is not available", isPresented: $showCannotSendAlert) {
				Button("OK", role: .cancel) {}
			} message: {
				Text("To send email from the app, set up a Mail account on this iPhone (Settings → Mail → Accounts). You can still copy/share the text from Export.")
			}
			.sheet(isPresented: $showMailComposer) {
				MailComposeView(
					to: recipients(from: to),
					subject: subject,
					body: messageBody,
					isHTML: false,
					onFinish: { _ in
						// Remember last used recipient + keep defaults convenient
						store.emailTo = to.trimmingCharacters(in: .whitespacesAndNewlines)
						store.emailSubject = subject
					}
				)
			}
			.sheet(isPresented: $showContactPicker) {
				ContactEmailPicker { email in
					if let email {
						to = email
					}
					showContactPicker = false
				}
			}
		}
	}

	private func recipients(from raw: String) -> [String] {
		raw
			.split(separator: ",")
			.map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
			.filter { !$0.isEmpty }
	}
}

