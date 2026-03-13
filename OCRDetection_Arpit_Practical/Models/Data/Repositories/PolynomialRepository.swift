//
//  PolynomialRepository.swift
//  OCRDetection_Arpit_Practical
//
//  Created by Arpit Parekh on 13/03/26.
//

import Foundation

/// Protocol for polynomial data access.
protocol PolynomialRepository {

    /// Fetch all polynomials, sorted by newest first.
    func fetchAll() async throws -> [Polynomial]

    /// Fetch a polynomial by ID.
    func fetchById(_ id: UUID) async throws -> Polynomial?

    /// Save a polynomial.
    func save(_ polynomial: Polynomial) async throws

    /// Delete a polynomial by ID.
    func delete(id: UUID) async throws

    /// Delete all polynomials.
    func deleteAll() async throws
}
