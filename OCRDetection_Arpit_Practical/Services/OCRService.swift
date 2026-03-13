//
//  OCRService.swift
//  OCRDetection_Arpit_Practical
//
//  Created by Claude on 13/03/26.
//

import Foundation
import UIKit
import Vision

/// Recognition level for OCR processing
enum OCRRecognitionLevel {
    case fast
    case accurate

    var visionLevel: VNRequestTextRecognitionLevel {
        switch self {
        case .fast: return .fast
        case .accurate: return .accurate
        }
    }
}

/// Errors that can occur during OCR processing
enum OCRError: Error, LocalizedError {
    case imageProcessingFailed
    case noTextFound
    case visionError(Error)
    case cancelled

    var errorDescription: String? {
        switch self {
        case .imageProcessingFailed:
            return "Failed to process the image"
        case .noTextFound:
            return "No text was detected in the image"
        case .visionError(let error):
            return "Vision framework error: \(error.localizedDescription)"
        case .cancelled:
            return "OCR processing was cancelled"
        }
    }
}

/// Protocol for OCR text recognition service.
/// Provides asynchronous image processing to extract text with bounding boxes.
protocol OCRService {

    /// Process an image and extract all recognized text.
    /// - Parameter image: The UIImage to process
    /// - Returns: Array of OCRResult containing text, bounding boxes, and confidence scores
    /// - Throws: OCRError if processing fails
    func processImage(_ image: UIImage) async throws -> [OCRResult]

    /// Process an image with a specific recognition level.
    /// - Parameters:
    ///   - image: The UIImage to process
    ///   - recognitionLevel: The accuracy level (fast or accurate)
    /// - Returns: Array of OCRResult containing text, bounding boxes, and confidence scores
    /// - Throws: OCRError if processing fails
    func processImage(_ image: UIImage, recognitionLevel: OCRRecognitionLevel) async throws -> [OCRResult]

    /// Cancel any ongoing OCR operations.
    func cancelProcessing()
}
