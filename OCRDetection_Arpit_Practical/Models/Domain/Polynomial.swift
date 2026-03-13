//
//  Polynomial.swift
//  OCRDetection_Arpit_Practical
//
//  Created by Arpit Parekh on 13/03/26.
//

import Foundation

/// Domain model for a polynomial.
struct Polynomial: Identifiable, Equatable {

    // MARK: - Properties

    let id: UUID
    let originalExpression: String
    let simplifiedExpression: String?
    let derivative: String?
    let valueAt1: Double?
    let valueAt2: Double?
    let imagePath: String?
    let createdAt: Date

    // MARK: - Init

    init(
        id: UUID = UUID(),
        originalExpression: String,
        simplifiedExpression: String? = nil,
        derivative: String? = nil,
        valueAt1: Double? = nil,
        valueAt2: Double? = nil,
        imagePath: String? = nil,
        createdAt: Date = Date()
    ) {
        // Validate input
        let trimmed = originalExpression.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            fatalError("Original expression cannot be empty")
        }

        self.id = id
        self.originalExpression = trimmed
        self.simplifiedExpression = simplifiedExpression?.isEmpty == true ? nil : simplifiedExpression
        self.derivative = derivative?.isEmpty == true ? nil : derivative
        self.valueAt1 = valueAt1
        self.valueAt2 = valueAt2
        self.imagePath = imagePath?.isEmpty == true ? nil : imagePath
        self.createdAt = createdAt
    }

    // MARK: - Helpers

    var hasSimplified: Bool {
        simplifiedExpression != nil && !simplifiedExpression!.isEmpty
    }

    var hasDerivative: Bool {
        derivative != nil && !derivative!.isEmpty
    }

    var hasImage: Bool {
        imagePath != nil && !imagePath!.isEmpty
    }

    var hasValueAt1: Bool {
        valueAt1 != nil
    }

    var hasValueAt2: Bool {
        valueAt2 != nil
    }

    var valueAt1Display: String {
        valueAt1.map { String(format: "%.2f", $0) } ?? "N/A"
    }

    var valueAt2Display: String {
        valueAt2.map { String(format: "%.2f", $0) } ?? "N/A"
    }

    // MARK: - Validation

    /// Validate polynomial has minimum required data
    var isValid: Bool {
        !originalExpression.isEmpty
    }
}
