import SwiftUI
import MessageUI

struct EmailDraftView: View {
	@Environment(\.dismiss) private var dismiss
	@Environment(\.openURL) private var openURL
	@EnvironmentObject private var store: DeviceLogStore

	@State private var to: String = ""
	@State private var subject: String = ""
	@State private var messageBody: String = ""

	@State private var showMailComposer = false
	@State private var showContactPicker = false
	@State private var showCannotSendAlert = false
	@State private var showOutlookUnavailableAlert = false

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

				Section("Send") {
					Button {
						sendViaOutlook()
					} label: {
						Label("Send via Outlook", systemImage: "envelope.badge")
					}
					.disabled(messageBody.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)

					Button {
						guard MFMailComposeViewController.canSendMail() else {
							showCannotSendAlert = true
							return
						}
						store.rememberRecipient(to)
						showMailComposer = true
					} label: {
						Label("Send via Apple Mail", systemImage: "envelope")
					}
					.disabled(messageBody.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
				}
			}
			.navigationTitle("Email")
			.toolbar {
				ToolbarItem(placement: .cancellationAction) {
					Button("Close") { dismiss() }
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
			.alert("Outlook is not available", isPresented: $showOutlookUnavailableAlert) {
				Button("OK", role: .cancel) {}
			} message: {
				Text("Install Microsoft Outlook on this iPhone to send directly from Outlook.")
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

	private func sendViaOutlook() {
		let recipientString = recipients(from: to).joined(separator: ";")
		let encodedTo = recipientString.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
		let encodedSubject = subject.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
		let encodedBody = messageBody.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""

		guard let url = URL(string: "ms-outlook://compose?to=\(encodedTo)&subject=\(encodedSubject)&body=\(encodedBody)") else {
			showOutlookUnavailableAlert = true
			return
		}

		if UIApplication.shared.canOpenURL(url) {
			store.rememberRecipient(to)
			store.emailTo = to.trimmingCharacters(in: .whitespacesAndNewlines)
			store.emailSubject = subject
			openURL(url)
		} else {
			showOutlookUnavailableAlert = true
		}
	}
}

