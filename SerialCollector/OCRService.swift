import Foundation
import UIKit
import Vision

enum OCRService {
	static func recognizeText(in image: UIImage) async throws -> String {
		guard let cg = image.cgImage else { return "" }

		let handler = VNImageRequestHandler(cgImage: cg, orientation: cgImageOrientation(from: image.imageOrientation))

		return try await withCheckedThrowingContinuation { continuation in
			let request = VNRecognizeTextRequest { req, err in
				if let err {
					continuation.resume(throwing: err)
					return
				}
				let observations = (req.results as? [VNRecognizedTextObservation]) ?? []
				let lines: [String] = observations.compactMap { obs in
					obs.topCandidates(1).first?.string
				}
				continuation.resume(returning: lines.joined(separator: "\n"))
			}

			request.recognitionLevel = .accurate
			request.usesLanguageCorrection = true
			request.minimumTextHeight = 0.02

			DispatchQueue.global(qos: .userInitiated).async {
				do {
					try handler.perform([request])
				} catch {
					continuation.resume(throwing: error)
				}
			}
		}
	}

	private static func cgImageOrientation(from orientation: UIImage.Orientation) -> CGImagePropertyOrientation {
		switch orientation {
		case .up: return .up
		case .down: return .down
		case .left: return .left
		case .right: return .right
		case .upMirrored: return .upMirrored
		case .downMirrored: return .downMirrored
		case .leftMirrored: return .leftMirrored
		case .rightMirrored: return .rightMirrored
		@unknown default: return .up
		}
	}
}

