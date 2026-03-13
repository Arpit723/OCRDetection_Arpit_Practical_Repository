//
//  PolynomialMathResult.swift
//  OCRDetection_Arpit_Practical
//
//  Created by Claude on 13/03/26.
//

import Foundation

/// Result of polynomial mathematical processing including
/// simplification, derivative calculation, and evaluation.
struct PolynomialMathResult: Equatable {

    // MARK: - Types

    enum MathError: Error, Equatable {
        case invalidSyntax
        case unsupportedOperator(String)
        case divisionByZero
        case overflow
        case unknown(String)

        var localizedDescription: String {
            switch self {
            case .invalidSyntax:
                return "Invalid mathematical expression syntax"
            case .unsupportedOperator(let op):
                return "Unsupported operator: \(op)"
            case .divisionByZero:
                return "Division by zero"
            case .overflow:
                return "Numeric overflow occurred"
            case .unknown(let message):
                return "Unknown error: \(message)"
            }
        }
    }

    // MARK: - Properties

    let original: String
    let simplified: String?
    let derivative: String?
    let valueAt1: Double?
    let valueAt2: Double?
    let error: MathError?

    // MARK: - Init

    init(
        original: String,
        simplified: String? = nil,
        derivative: String? = nil,
        valueAt1: Double? = nil,
        valueAt2: Double? = nil,
        error: MathError? = nil
    ) {
        self.original = original.trimmingCharacters(in: .whitespacesAndNewlines)
        self.simplified = simplified?.isEmpty == true ? nil : simplified
        self.derivative = derivative?.isEmpty == true ? nil : derivative
        self.valueAt1 = valueAt1
        self.valueAt2 = valueAt2
        self.error = error
    }

    /// Initialize with an error state
    init(original: String, error: MathError) {
        self.init(original: original, error: error)
    }

    // MARK: - Computed Properties

    var hasSimplified: Bool {
        simplified != nil
    }

    var hasDerivative: Bool {
        derivative != nil
    }

    var hasValueAt1: Bool {
        valueAt1 != nil
    }

    var hasValueAt2: Bool {
        valueAt2 != nil
    }

    var hasError: Bool {
        error != nil
    }

    var isSuccess: Bool {
        error == nil
    }

    // MARK: - Display Helpers

    var valueAt1Display: String {
        guard let value = valueAt1 else { return "N/A" }
        // Handle special values
        if value.isInfinite { return "∞" }
        if value.isNaN { return "Undefined" }
        // Check if it's effectively an integer
        if value.truncatingRemainder(dividingBy: 1) == 0 {
            return String(format: "%.0f", value)
        }
        return String(format: "%.2f", value)
    }

    var valueAt2Display: String {
        guard let value = valueAt2 else { return "N/A" }
        if value.isInfinite { return "∞" }
        if value.isNaN { return "Undefined" }
        if value.truncatingRemainder(dividingBy: 1) == 0 {
            return String(format: "%.0f", value)
        }
        return String(format: "%.2f", value)
    }

    var simplifiedDisplay: String {
        simplified ?? "Unable to simplify"
    }

    var derivativeDisplay: String {
        derivative ?? "Unable to calculate"
    }

    var errorDisplay: String {
        error?.localizedDescription ?? "No error"
    }

    // MARK: - Validation

    /// Check if the original expression is not empty
    var isValid: Bool {
        !original.isEmpty
    }
}

// MARK: - Polynomial Conversion Helper

extension PolynomialMathResult {

    /// Convert to Polynomial domain model for storage
    func toPolynomial(imagePath: String? = nil) -> Polynomial {
        Polynomial(
            originalExpression: original,
            simplifiedExpression: simplified,
            derivative: derivative,
            valueAt1: valueAt1,
            valueAt2: valueAt2,
            imagePath: imagePath
        )
    }
}
