//
//  OCRServiceImpl.swift
//  OCRDetection_Arpit_Practical
//
//  Created by Claude on 13/03/26.
//

import Foundation
import UIKit
import Vision

/// Vision framework implementation of OCRService.
/// Uses VNRecognizeTextRequest for text recognition with bounding boxes.
final class OCRServiceImpl: OCRService {

    // MARK: - Singleton

    static let shared = OCRServiceImpl()

    // MARK: - Properties

    private let minimumConfidence: Float = 0.5

    // MARK: - Init

    private init() {}

    // MARK: - OCRService

    func processImage(_ image: UIImage) async throws -> [OCRResult] {
        try await processImage(image, recognitionLevel: .accurate)
    }

    func processImage(_ image: UIImage, recognitionLevel: OCRRecognitionLevel) async throws -> [OCRResult] {
        // Guard: Convert UIImage to CIImage
        guard let cgImage = image.cgImage else {
            throw OCRError.imageProcessingFailed
        }

        let ciImage = CIImage(cgImage: cgImage)

        return try await withCheckedThrowingContinuation { continuation in
            // Create and configure the request
            let request = VNRecognizeTextRequest { request, error in
                if let error = error {
                    continuation.resume(throwing: OCRError.visionError(error))
                    return
                }

                guard let observations = request.results as? [VNRecognizedTextObservation], !observations.isEmpty else {
                    continuation.resume(throwing: OCRError.noTextFound)
                    return
                }

                // Convert VNRecognizedTextObservation to OCRResult
                let ocrResults = self.convertToOCRResults(from: observations)

                if ocrResults.isEmpty {
                    continuation.resume(throwing: OCRError.noTextFound)
                } else {
                    continuation.resume(returning: ocrResults)
                }
            }

            // Configure recognition level
            request.recognitionLevel = recognitionLevel.visionLevel

            // Enable multiple languages if needed
            // request.recognitionLanguages = ["en-US"]

            // Use language correction
            request.usesLanguageCorrection = true

            // Perform request on background queue
            let handler = VNImageRequestHandler(ciImage: ciImage, options: [:])

            DispatchQueue.global(qos: .userInitiated).async {
                do {
                    try handler.perform([request])
                } catch {
                    continuation.resume(throwing: OCRError.visionError(error))
                }
            }
        }
    }

    func cancelProcessing() {
        // Vision requests are automatically cancelled when deallocated
        // For explicit cancellation, we would need to track requests
    }

    // MARK: - Private Methods

    private func convertToOCRResults(from observations: [VNRecognizedTextObservation]) -> [OCRResult] {
        var results: [OCRResult] = []

        for observation in observations {
            // Get the top candidate (highest confidence)
            guard let candidate = observation.topCandidates(1).first else {
                continue
            }

            let confidence = candidate.confidence

            // Filter by minimum confidence
            guard confidence >= minimumConfidence else {
                continue
            }

            // Create OCRResult
            if let result = OCRResult(from: observation) {
                results.append(result)
            }
        }

        // Sort by y-position (top to bottom) for natural reading order
        // Note: Vision uses bottom-left origin, so we invert y
        return results.sorted { $0.boundingBox.maxY > $1.boundingBox.maxY }
    }
}
