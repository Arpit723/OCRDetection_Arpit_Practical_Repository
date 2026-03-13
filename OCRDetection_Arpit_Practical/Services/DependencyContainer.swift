//
//  DependencyContainer.swift
//  OCRDetection_Arpit_Practical
//
//  Created by Claude on 13/03/26.
//

import Foundation
import UIKit
import CoreData

/// Centralized dependency injection container.
/// Provides access to all services and repositories following the singleton pattern.
final class DependencyContainer {

    // MARK: - Singleton

    static let shared = DependencyContainer()

    // MARK: - Services (Lazy Initialization)

    /// OCR text recognition service
    lazy var ocrService: OCRService = OCRServiceImpl.shared

    /// Polynomial filtering service
    lazy var polynomialFilterService: PolynomialFilterService = PolynomialFilterService.shared

    /// Polynomial parsing and math service
    lazy var polynomialParserService: PolynomialParserService = PolynomialParserServiceImpl.shared

    /// PDF export service
    lazy var pdfExportService: PDFExportService = PDFExportServiceImpl.shared

    /// Image file management service
    lazy var imageFileManager: ImageFileManager = .shared

    // MARK: - Repositories

    /// Polynomial data repository
    lazy var polynomialRepository: PolynomialRepository = {
        PolynomialRepositoryImpl(
            persistentContainer: persistentContainer,
            imageFileManager: imageFileManager
        )
    }()

    // MARK: - Core Data Stack

    /// Core Data persistent container from AppDelegate
    var persistentContainer: NSPersistentContainer {
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else {
            fatalError("Unable to access AppDelegate for Core Data container")
        }
        return appDelegate.persistentContainer
    }

    // MARK: - Convenience Accessors

    /// Get a view model for the main list screen
    func makePolynomialListViewModel() -> PolynomialListViewModel {
        PolynomialListViewModel(
            repository: polynomialRepository,
            ocrService: ocrService,
            filterService: polynomialFilterService,
            parserService: polynomialParserService,
            imageManager: imageFileManager
        )
    }

    /// Get a view model for the detail screen
    func makePolynomialDetailViewModel(polynomial: Polynomial) -> PolynomialDetailViewModel {
        PolynomialDetailViewModel(
            polynomial: polynomial,
            pdfService: pdfExportService,
            imageManager: imageFileManager
        )
    }

    // MARK: - Init

    private init() {}

    // MARK: - Reset (for testing)

    /// Reset all singleton instances (for testing only)
    static func resetForTesting() {
        // This would be implemented for testing purposes
        // to ensure clean state between tests
    }
}

// MARK: - View Models (Lightweight Coordination Layer)

/// ViewModel for coordinating polynomial list operations
struct PolynomialListViewModel {

    let repository: PolynomialRepository
    let ocrService: OCRService
    let filterService: PolynomialFilterService
    let parserService: PolynomialParserService
    let imageManager: ImageFileManager

    /// Process an image through the complete OCR pipeline
    func processImage(_ image: UIImage) async throws -> [Polynomial] {
        print("📸 [DEBUG] ViewModel.processImage starting")
        print("  Image size: \(image.size.width) x \(image.size.height)")

        // Step 1: Run OCR
        print("🔍 [DEBUG] Step 1: Running OCR...")
        let ocrResults = try await ocrService.processImage(image)
        print("✅ [DEBUG] OCR found \(ocrResults.count) text regions")

        for (index, result) in ocrResults.enumerated() {
            let confidencePercent = String(format: "%.1f%%", result.confidence * 100)
            print("  - [\(index)] '\(result.text)' (confidence: \(confidencePercent))")
        }

        // Step 2: Filter to polynomial expressions
        print("🔍 [DEBUG] Step 2: Filtering polynomials from \(ocrResults.count) OCR results...")
        let polynomialStrings = filterService.filterPolynomials(from: ocrResults)
        print("✅ [DEBUG] Filtered to \(polynomialStrings.count) potential polynomial expressions")

        for (index, expr) in polynomialStrings.enumerated() {
            print("  - [\(index)] '\(expr)'")
        }

        guard !polynomialStrings.isEmpty else {
            print("⚠️ [DEBUG] No polynomials found after filtering - returning empty array")
            return []
        }

        // Step 3: Save image
        print("💾 [DEBUG] Step 3: Saving image to file system...")
        let imagePath = imageManager.saveImage(image)
        print("✅ [DEBUG] Image saved to: \(imagePath ?? "nil (save failed)")")

        // Step 4: Parse each expression
        print("🧮 [DEBUG] Step 4: Parsing \(polynomialStrings.count) polynomial expressions...")
        var results: [Polynomial] = []

        for (index, expression) in polynomialStrings.enumerated() {
            do {
                print("  - [\(index)] Parsing '\(expression)'...")
                let mathResult = try await parserService.parse(expression)

                print("    ✓ Original: \(mathResult.original)")
                print("    ✓ Simplified: \(mathResult.simplified ?? "N/A")")
                print("    ✓ Derivative: \(mathResult.derivative ?? "N/A")")
                print("    ✓ f(1): \(mathResult.valueAt1?.description ?? "N/A")")
                print("    ✓ f(2): \(mathResult.valueAt2?.description ?? "N/A")")

                if let error = mathResult.error {
                    print("    ⚠️ Error: \(error.localizedDescription)")
                }

                let polynomial = Polynomial(
                    id: UUID(),
                    originalExpression: mathResult.original,
                    simplifiedExpression: mathResult.simplified,
                    derivative: mathResult.derivative,
                    valueAt1: mathResult.valueAt1,
                    valueAt2: mathResult.valueAt2,
                    imagePath: imagePath
                )

                // Step 5: Save to repository
                print("    💾 Saving to Core Data...")
                try await repository.save(polynomial)
                results.append(polynomial)
                print("    ✅ Polynomial saved successfully (ID: \(polynomial.id))")
            } catch {
                print("    ❌ Parse failed for '\(expression)': \(error.localizedDescription)")
            }
        }

        print("✅ [DEBUG] ViewModel.processImage completed with \(results.count) polynomials saved")
        return results
    }

    /// Fetch all saved polynomials
    func fetchAllPolynomials() async throws -> [Polynomial] {
        try await repository.fetchAll()
    }

    /// Delete a polynomial
    func deletePolynomial(id: UUID) async throws {
        try await repository.delete(id: id)
    }

    /// Delete all polynomials
    func deleteAllPolynomials() async throws {
        try await repository.deleteAll()
    }
}

/// ViewModel for polynomial detail operations
struct PolynomialDetailViewModel {

    let polynomial: Polynomial
    let pdfService: PDFExportService
    let imageManager: ImageFileManager

    /// Load the image for this polynomial
    func loadImage() -> UIImage? {
        guard let imagePath = polynomial.imagePath else { return nil }
        return imageManager.loadImage(from: imagePath)
    }

    /// Export polynomial to PDF for sharing
    func exportToPDF() async throws -> URL {
        let image = loadImage()
        return try await pdfService.exportPDF(polynomial: polynomial, image: image)
    }

    /// Generate PDF data for sharing
    func generatePDFData() async throws -> Data {
        let image = loadImage()
        return try await pdfService.generatePDFData(polynomial: polynomial, image: image)
    }
}
