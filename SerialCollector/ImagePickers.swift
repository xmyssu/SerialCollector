import SwiftUI
import UIKit

struct CameraPicker: UIViewControllerRepresentable {
	@Environment(\.dismiss) private var dismiss
	var onImage: (UIImage) -> Void

	func makeUIViewController(context: Context) -> UIImagePickerController {
		let picker = UIImagePickerController()
		picker.sourceType = .camera
		picker.delegate = context.coordinator
		picker.allowsEditing = false
		return picker
	}

	func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

	func makeCoordinator() -> Coordinator {
		Coordinator(onDismiss: { dismiss() }, onImage: onImage)
	}

	final class Coordinator: NSObject, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
		let onDismiss: () -> Void
		let onImage: (UIImage) -> Void

		init(onDismiss: @escaping () -> Void, onImage: @escaping (UIImage) -> Void) {
			self.onDismiss = onDismiss
			self.onImage = onImage
		}

		func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
			if let img = info[.originalImage] as? UIImage {
				onImage(img)
			}
			onDismiss()
		}

		func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
			onDismiss()
		}
	}
}

