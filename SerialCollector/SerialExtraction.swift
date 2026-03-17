import Foundation

struct SerialCandidate: Identifiable, Hashable {
	let id = UUID()
	let value: String
	let score: Int
}

enum SerialExtractor {
	/// Default: captures typical serial-like tokens (alphanumeric, 8-20 chars).
	/// You can adjust this in-app if your org has a known format.
	static let defaultPattern = #"(?i)\b[A-Z0-9]{8,20}\b"#

	static func extract(from recognizedText: String, pattern: String) -> [SerialCandidate] {
		let normalized = recognizedText
			.replacingOccurrences(of: "\u{00A0}", with: " ")
			.replacingOccurrences(of: "\t", with: " ")

		let regex: NSRegularExpression
		do {
			regex = try NSRegularExpression(pattern: pattern, options: [])
		} catch {
			return []
		}

		let range = NSRange(normalized.startIndex..<normalized.endIndex, in: normalized)
		let matches = regex.matches(in: normalized, options: [], range: range)

		var byValue: [String: Int] = [:]
		for m in matches {
			guard let r = Range(m.range, in: normalized) else { continue }
			let raw = String(normalized[r]).trimmingCharacters(in: .whitespacesAndNewlines)
			let value = cleanup(raw)
			guard value.count >= 6 else { continue }
			byValue[value, default: 0] += score(value)
		}

		return byValue
			.map { SerialCandidate(value: $0.key, score: $0.value) }
			.sorted {
				if $0.score == $1.score { return $0.value < $1.value }
				return $0.score > $1.score
			}
	}

	private static func cleanup(_ v: String) -> String {
		// Common OCR confusions: we don't auto-substitute (could be wrong),
		// but we trim punctuation and normalize case.
		let trimmed = v.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
		return trimmed.uppercased()
	}

	private static func score(_ v: String) -> Int {
		var s = 0
		if v.rangeOfCharacter(from: .decimalDigits) != nil { s += 2 }
		if v.rangeOfCharacter(from: .letters) != nil { s += 2 }
		if v.count >= 8 { s += 1 }
		if v.count >= 10 { s += 1 }
		// Penalize all-digits or all-letters (often false positives)
		if v.rangeOfCharacter(from: .letters) == nil { s -= 2 }
		if v.rangeOfCharacter(from: .decimalDigits) == nil { s -= 2 }
		return s
	}
}

