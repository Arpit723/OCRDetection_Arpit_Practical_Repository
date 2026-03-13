//
//  PolynomialFilterService.swift
//  OCRDetection_Arpit_Practical
//
//  Created by Claude on 13/03/26.
//

import Foundation

/// Service for filtering OCR results to identify polynomial-like strings.
/// Filters out false positives like dates, phone numbers, emails, etc.
final class PolynomialFilterService {

    // MARK: - Singleton

    static let shared = PolynomialFilterService()

    // MARK: - Properties

    private let minimumLength: Int = 2
    private let maximumLength: Int = 100

    // MARK: - Init

    private init() {}

    // MARK: - Public Methods

    /// Filter OCR results to extract only polynomial-like strings.
    /// - Parameter ocrResults: Array of OCRResult from OCR service
    /// - Returns: Array of strings that appear to be polynomial expressions
    func filterPolynomials(from ocrResults: [OCRResult]) -> [String] {
        print("🔍 [DEBUG] Filter: Filtering \(ocrResults.count) OCR results")

        var passedCount = 0
        var failedCount = 0

        let result = ocrResults
            .filter { result in
                let passes = isPotentialPolynomial(result)
                if passes {
                    passedCount += 1
                } else {
                    failedCount += 1
                    // Log why it failed (basic logging)
                    if !result.hasValidLength() {
                        print("    ❌ Filter out: '\(result.text.prefix(30))' - invalid length")
                    } else if !result.isLikelyMathematical() {
                        print("    ❌ Filter out: '\(result.text.prefix(30))' - not mathematical")
                    } else if result.isPureNumber() {
                        print("    ❌ Filter out: '\(result.text.prefix(30))' - pure number")
                    } else if result.isFalsePositive() {
                        print("    ❌ Filter out: '\(result.text.prefix(30))' - false positive (date/email/phone)")
                    } else if !hasMathematicalStructure(result.text) {
                        print("    ❌ Filter out: '\(result.text.prefix(30))' - no math structure")
                    } else {
                        print("    ❌ Filter out: '\(result.text.prefix(30))' - unknown reason")
                    }
                }
                return passes
            }
            .map { $0.text }
            .uniqued()

        print("  ✅ [DEBUG] Filter: \(passedCount) passed, \(failedCount) filtered out")
        print("  📊 [DEBUG] Filter: Returning \(result.count) unique polynomial expressions")

        return result
    }

    /// Filter OCR results with custom thresholds.
    /// - Parameters:
    ///   - ocrResults: Array of OCRResult from OCR service
    ///   - minConfidence: Minimum confidence level (0.0 - 1.0)
    /// - Returns: Array of strings that appear to be polynomial expressions
    func filterPolynomials(from ocrResults: [OCRResult], minConfidence: Float) -> [String] {
        return ocrResults
            .filter { $0.meetsConfidenceThreshold(minConfidence) }
            .filter { isPotentialPolynomial($0) }
            .map { $0.text }
            .uniqued()
    }

    /// Check if a single string could be a polynomial expression.
    /// - Parameter text: The text to check
    /// - Returns: True if the text appears to be a polynomial expression
    func isPolynomialExpression(_ text: String) -> Bool {
        let result = OCRResult(text: text, boundingBox: .zero, confidence: 1.0)
        return isPotentialPolynomial(result)
    }

    // MARK: - Private Methods

    /// Check if an OCR result represents a potential polynomial expression.
    private func isPotentialPolynomial(_ result: OCRResult) -> Bool {
        // Use OCRResult's built-in checks
        guard result.isPotentialPolynomial() else {
            return false
        }

        let text = result.text

        // Additional polynomial-specific checks
        return hasMathematicalStructure(text) &&
               !isDate(text) &&
               !isTime(text) &&
               !isVersionNumber(text) &&
               !isPercentage(text)
    }

    /// Check if the text has mathematical structure (variables, operators, powers).
    private func hasMathematicalStructure(_ text: String) -> Bool {
        let lowercased = text.lowercased()

        // Must have at least one mathematical component
        let hasVariable = lowercased.contains("x") || lowercased.contains("y") || lowercased.contains("z") || lowercased.contains("n")
        let hasOperator = containsMathOperator(text)
        let hasPower = text.contains("^") || containsSuperscriptNumbers(text)

        // A valid polynomial expression should have:
        // - A variable AND (an operator OR a power)
        // OR
        // - An operator AND numbers/variables

        if hasVariable && (hasOperator || hasPower) {
            return true
        }

        // Expressions like "x^2" or "x2" (implicit multiplication)
        if hasVariable && hasPower {
            return true
        }

        // Expressions with operators and numbers/variables
        if hasOperator && (containsDigit(text) || hasVariable) {
            return true
        }

        return false
    }

    /// Check if text contains mathematical operators.
    private func containsMathOperator(_ text: String) -> Bool {
        let operators = "+-×÷*/=()"
        return text.unicodeScalars.contains { operators.unicodeScalars.contains($0) }
    }

    /// Check if text contains digits.
    private func containsDigit(_ text: String) -> Bool {
        text.rangeOfCharacter(from: .decimalDigits) != nil
    }

    /// Check if text contains superscript numbers (used in exponents).
    private func containsSuperscriptNumbers(_ text: String) -> Bool {
        let superscripts = CharacterSet(charactersIn: "⁰¹²³⁴⁵⁶⁷⁸⁹")
        return text.unicodeScalars.contains { superscripts.contains($0) }
    }

    /// Check if text looks like a date.
    private func isDate(_ text: String) -> Bool {
        // Common date patterns: YYYY-MM-DD, DD/MM/YYYY, MM-DD-YYYY
        let datePattern = #"^\d{1,4}[/-]\d{1,2}[/-]\d{1,4}$"#
        let regex = try? NSRegularExpression(pattern: datePattern)
        let range = NSRange(location: 0, length: text.utf16.count)
        return regex?.firstMatch(in: text, range: range) != nil
    }

    /// Check if text looks like a time.
    private func isTime(_ text: String) -> Bool {
        let timePattern = #"^\d{1,2}:\d{2}(:\d{2})?$"#
        let regex = try? NSRegularExpression(pattern: timePattern)
        let range = NSRange(location: 0, length: text.utf16.count)
        return regex?.firstMatch(in: text, range: range) != nil
    }

    /// Check if text looks like a version number (e.g., "v1.2.3", "1.0.0").
    private func isVersionNumber(_ text: String) -> Bool {
        let trimmed = text.lowercased().trimmingCharacters(in: .whitespaces)
        guard trimmed.hasPrefix("v") || trimmed.hasPrefix("ver") || trimmed.hasPrefix("version") else {
            return false
        }

        // Count dots - version numbers typically have 2-3 dots
        let dotCount = trimmed.filter { $0 == "." }.count
        return dotCount >= 1 && dotCount <= 3
    }

    /// Check if text is just a percentage.
    private func isPercentage(_ text: String) -> Bool {
        let trimmed = text.trimmingCharacters(in: .whitespaces)
        guard trimmed.hasSuffix("%") else { return false }

        // Remove % and check if it's a valid number
        let numberPart = String(trimmed.dropLast())
        return Double(numberPart) != nil
    }
}

// MARK: - Array Extension for Unique Elements

private extension Array where Element: Hashable {

    /// Return array with unique elements, preserving order.
    func uniqued() -> [Element] {
        var seen = Set<Element>()
        return filter { seen.insert($0).inserted }
    }
}
