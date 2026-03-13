//
//  OCRResult.swift
//  OCRDetection_Arpit_Practical
//
//  Created by Claude on 13/03/26.
//

import Foundation
import Vision

/// Result from OCR text recognition containing the detected text,
/// its bounding box location in the image, and confidence score.
struct OCRResult: Identifiable, Equatable {

    // MARK: - Properties

    let id: UUID
    let text: String
    let boundingBox: CGRect
    let confidence: Float

    // MARK: - Init

    init(id: UUID = UUID(), text: String, boundingBox: CGRect, confidence: Float) {
        self.id = id
        self.text = text.trimmingCharacters(in: .whitespacesAndNewlines)
        self.boundingBox = boundingBox
        self.confidence = confidence
    }

    // MARK: - Helpers

    /// Initialize from Vision framework's VNRecognizedTextObservation
    init?(from observation: VNRecognizedTextObservation, topLevelCandidateIndex: Int = 0) {
        guard topLevelCandidateIndex < observation.topCandidates(1).count else {
            return nil
        }

        let candidate = observation.topCandidates(1)[topLevelCandidateIndex]
        let text = candidate.string
        let confidence = candidate.confidence

        // Convert normalized bounding box to image coordinates (0-1 range)
        // Note: Vision framework uses bottom-left origin, UIKit uses top-left
        let boundingBox = observation.boundingBox

        self.init(text: text, boundingBox: boundingBox, confidence: confidence)
    }

    /// Check if the OCR result meets minimum confidence threshold
    func meetsConfidenceThreshold(_ threshold: Float = 0.5) -> Bool {
        confidence >= threshold
    }

    /// Check if the text is likely a mathematical expression
    func isLikelyMathematical() -> Bool {
        // Check for mathematical operators or variables
        let mathIndicators = CharacterSet(charactersIn: "+-×÷^=xyzn()")
        return text.rangeOfCharacter(from: mathIndicators) != nil
    }

    /// Check if the text is likely a number only (not a polynomial)
    func isPureNumber() -> Bool {
        // Remove whitespace and check if it's a valid number
        let trimmed = text.replacingOccurrences(of: " ", with: "")
        return Double(trimmed) != nil && !text.contains("x")
    }

    /// Check if text contains common false positives (dates, emails, etc.)
    func isFalsePositive() -> Bool {
        let lowercased = text.lowercased()

        // Email pattern
        if lowercased.contains("@") && lowercased.contains(".") {
            return true
        }

        // URL pattern
        if lowercased.hasPrefix("http") || lowercased.hasPrefix("www") {
            return true
        }

        // Phone number pattern (simple check)
        let digits = text.filter { $0.isNumber }
        if digits.count >= 7 && digits.count <= 15 {
            // Check if mostly digits with some separators
            let separators = CharacterSet(charactersIn: "+-(). ")
            let separatorCount = text.unicodeScalars.filter { separators.contains($0) }.count
            if separatorCount > 0 && separatorCount <= 5 {
                return true
            }
        }

        // Date pattern (YYYY-MM-DD, DD/MM/YYYY, etc.)
        let dateSeparators = CharacterSet(charactersIn: "-/.")
        let separatorCount = text.unicodeScalars.filter { dateSeparators.contains($0) }.count
        if separatorCount == 2 && digits.count >= 4 {
            return true
        }

        return false
    }

    /// Check if text length is within acceptable bounds
    func hasValidLength(minLength: Int = 2, maxLength: Int = 100) -> Bool {
        text.count >= minLength && text.count <= maxLength
    }

    /// Check if this result could be a polynomial expression
    func isPotentialPolynomial() -> Bool {
        hasValidLength() &&
        isLikelyMathematical() &&
        !isPureNumber() &&
        !isFalsePositive()
    }
}
