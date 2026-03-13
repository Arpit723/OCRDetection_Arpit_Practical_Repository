//
//  PolynomialParserService.swift
//  OCRDetection_Arpit_Practical
//
//  Created by Claude on 13/03/26.
//

import Foundation

/// Protocol for polynomial mathematical processing service.
/// Handles parsing, simplification, derivative calculation, and evaluation.
protocol PolynomialParserService {

    /// Parse and process a polynomial expression.
    /// - Parameter expression: The mathematical expression string
    /// - Returns: PolynomialMathResult with computed values
    /// - Throws: MathError if parsing fails
    func parse(_ expression: String) async throws -> PolynomialMathResult

    /// Simplify a polynomial expression.
    /// - Parameter expression: The mathematical expression string
    /// - Returns: Simplified expression string, or nil if simplification fails
    func simplify(_ expression: String) throws -> String?

    /// Calculate the derivative of a polynomial expression.
    /// - Parameter expression: The mathematical expression string
    /// - Returns: Derivative expression string, or nil if calculation fails
    func derivative(_ expression: String) throws -> String?

    /// Evaluate an expression at a specific value of x.
    /// - Parameters:
    ///   - expression: The mathematical expression string
    ///   - x: The value to substitute for x
    /// - Returns: The calculated value, or nil if evaluation fails
    func evaluate(_ expression: String, at x: Double) throws -> Double?

    /// Evaluate an expression at multiple x values.
    /// - Parameters:
    ///   - expression: The mathematical expression string
    ///   - values: Array of x values to evaluate
    /// - Returns: Dictionary of x: result pairs
    func evaluate(_ expression: String, at values: [Double]) throws -> [Double: Double]
}
