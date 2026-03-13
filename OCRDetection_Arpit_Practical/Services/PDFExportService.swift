//
//  PDFExportService.swift
//  OCRDetection_Arpit_Practical
//
//  Created by Claude on 13/03/26.
//

import Foundation
import UIKit

/// Errors that can occur during PDF generation
enum PDFError: Error, LocalizedError {
    case generationFailed
    case fileWriteFailed(Error)
    case invalidData
    case imageProcessingFailed

    var errorDescription: String? {
        switch self {
        case .generationFailed:
            return "Failed to generate PDF"
        case .fileWriteFailed(let error):
            return "Failed to write PDF file: \(error.localizedDescription)"
        case .invalidData:
            return "Invalid polynomial data"
        case .imageProcessingFailed:
            return "Failed to process image for PDF"
        }
    }
}

/// PDF configuration options
struct PDFConfiguration {
    let pageSize: CGSize
    let margins: UIEdgeInsets
    let titleFont: UIFont
    let headingFont: UIFont
    let bodyFont: UIFont
    let captionFont: UIFont

    static let `default` = PDFConfiguration(
        pageSize: CGSize(width: 595, height: 842), // A4 in points
        margins: UIEdgeInsets(top: 50, left: 50, bottom: 50, right: 50),
        titleFont: UIFont.boldSystemFont(ofSize: 24),
        headingFont: UIFont.boldSystemFont(ofSize: 16),
        bodyFont: UIFont.systemFont(ofSize: 14),
        captionFont: UIFont.italicSystemFont(ofSize: 12)
    )
}

/// Protocol for PDF export service.
/// Generates PDF reports from polynomial data.
protocol PDFExportService {

    /// Export a single polynomial to PDF.
    /// - Parameters:
    ///   - polynomial: The polynomial to export
    ///   - image: Optional original image to include
    /// - Returns: URL to the generated PDF file
    /// - Throws: PDFError if generation fails
    func exportPDF(polynomial: Polynomial, image: UIImage?) async throws -> URL

    /// Export multiple polynomials to a single PDF.
    /// - Parameters:
    ///   - polynomials: Array of polynomials to export
    ///   - images: Optional dictionary mapping polynomial IDs to images
    /// - Returns: URL to the generated PDF file
    /// - Throws: PDFError if generation fails
    func exportPDF(polynomials: [Polynomial], images: [UUID: UIImage]?) async throws -> URL

    /// Generate shareable data from polynomial.
    /// - Parameters:
    ///   - polynomial: The polynomial to share
    ///   - image: Optional original image to include
    /// - Returns: PDF data ready for sharing
    /// - Throws: PDFError if generation fails
    func generatePDFData(polynomial: Polynomial, image: UIImage?) async throws -> Data
}
