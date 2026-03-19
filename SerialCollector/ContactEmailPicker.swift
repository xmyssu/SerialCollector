import SwiftUI
import ContactsUI

struct ContactEmailPicker: UIViewControllerRepresentable {
	let onPick: (String?) -> Void

	func makeCoordinator() -> Coordinator {
		Coordinator(onPick: onPick)
	}

	func makeUIViewController(context: Context) -> CNContactPickerViewController {
		let picker = CNContactPickerViewController()
		picker.delegate = context.coordinator
		picker.displayedPropertyKeys = [CNContactEmailAddressesKey]
		return picker
	}

	func updateUIViewController(_ uiViewController: CNContactPickerViewController, context: Context) {}

	final class Coordinator: NSObject, CNContactPickerDelegate {
		let onPick: (String?) -> Void

		init(onPick: @escaping (String?) -> Void) {
			self.onPick = onPick
		}

		func contactPicker(_ picker: CNContactPickerViewController, didSelect contactProperty: CNContactProperty) {
			if contactProperty.key == CNContactEmailAddressesKey,
			   let emailValue = contactProperty.value as? NSString {
				onPick(emailValue as String)
			} else {
				onPick(nil)
			}
		}

		func contactPickerDidCancel(_ picker: CNContactPickerViewController) {
			onPick(nil)
		}
	}
}

