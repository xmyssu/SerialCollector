import SwiftUI
import MessageUI

struct MailComposeView: UIViewControllerRepresentable {
	typealias UIViewControllerType = MFMailComposeViewController

	let to: [String]
	let subject: String
	let body: String
	let isHTML: Bool
	let onFinish: (Result<MFMailComposeResult, Error>) -> Void

	func makeUIViewController(context: Context) -> MFMailComposeViewController {
		let vc = MFMailComposeViewController()
		vc.mailComposeDelegate = context.coordinator
		vc.setToRecipients(to.isEmpty ? nil : to)
		vc.setSubject(subject)
		vc.setMessageBody(body, isHTML: isHTML)
		return vc
	}

	func updateUIViewController(_ uiViewController: MFMailComposeViewController, context: Context) {}

	func makeCoordinator() -> Coordinator {
		Coordinator(onFinish: onFinish)
	}

	final class Coordinator: NSObject, MFMailComposeViewControllerDelegate {
		private let onFinish: (Result<MFMailComposeResult, Error>) -> Void

		init(onFinish: @escaping (Result<MFMailComposeResult, Error>) -> Void) {
			self.onFinish = onFinish
		}

		func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
			controller.dismiss(animated: true)
			if let error {
				onFinish(.failure(error))
			} else {
				onFinish(.success(result))
			}
		}
	}
}

