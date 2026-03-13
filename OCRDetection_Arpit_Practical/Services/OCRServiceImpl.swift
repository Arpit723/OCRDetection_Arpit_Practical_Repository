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
        print("🔍 [DEBUG] OCRService.processImage starting")
        print("  Image size: \(image.size.width) x \(image.size.height)")

        // Guard: Convert UIImage to CIImage
        guard let cgImage = image.cgImage else {
            print("❌ [DEBUG] Failed to get CGImage from UIImage")
            throw OCRError.imageProcessingFailed
        }

        let ciImage = CIImage(cgImage: cgImage)
        print("✅ [DEBUG] Converted to CIImage successfully")

        return try await withCheckedThrowingContinuation { continuation in
            // Create and configure the request
            let request = VNRecognizeTextRequest { request, error in
                if let error = error {
                    print("❌ [DEBUG] Vision request failed: \(error.localizedDescription)")
                    continuation.resume(throwing: OCRError.visionError(error))
                    return
                }

                guard let observations = request.results as? [VNRecognizedTextObservation], !observations.isEmpty else {
                    print("⚠️ [DEBUG] Vision request completed but no text observations found")
                    continuation.resume(throwing: OCRError.noTextFound)
                    return
                }

                print("✅ [DEBUG] Vision found \(observations.count) text observations")

                // Convert VNRecognizedTextObservation to OCRResult
                let ocrResults = self.convertToOCRResults(from: observations)

                if ocrResults.isEmpty {
                    print("⚠️ [DEBUG] No OCR results passed confidence threshold (>= \(self.minimumConfidence))")
                    continuation.resume(throwing: OCRError.noTextFound)
                } else {
                    print("✅ [DEBUG] Returning \(ocrResults.count) OCR results above threshold")
                    continuation.resume(returning: ocrResults)
                }
            }

            // Configure recognition level
            request.recognitionLevel = recognitionLevel.visionLevel
            print("  Recognition level: \(recognitionLevel)")

            // Enable multiple languages if needed
            // request.recognitionLanguages = ["en-US"]

            // Use language correction
            request.usesLanguageCorrection = true

            // Perform request on background queue
            let handler = VNImageRequestHandler(ciImage: ciImage, options: [:])

            print("🔄 [DEBUG] Starting Vision request on background queue...")
            DispatchQueue.global(qos: .userInitiated).async {
                do {
                    try handler.perform([request])
                } catch {
                    print("❌ [DEBUG] Handler.perform failed: \(error.localizedDescription)")
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
        var skippedCount = 0
        var failedCount = 0

        print("  🔄 [DEBUG] Converting \(observations.count) observations to OCRResult...")

        for (index, observation) in observations.enumerated() {
            // Get the top candidate (highest confidence)
            guard let candidate = observation.topCandidates(1).first else {
                skippedCount += 1
                continue
            }

            let confidence = candidate.confidence
            let confidencePercent = String(format: "%.1f%%", confidence * 100)

            // Filter by minimum confidence
            guard confidence >= minimumConfidence else {
                print("    [\(index)] Skipping '\(candidate.string.prefix(30))' (confidence: \(confidencePercent) < \(Int(minimumConfidence * 100))%)")
                skippedCount += 1
                continue
            }

            // Create OCRResult
            if let result = OCRResult(from: observation) {
                results.append(result)
                print("    [\(index)] ✅ '\(result.text.prefix(30))' (confidence: \(confidencePercent))")
            } else {
                print("    [\(index)] ❌ Failed to create OCRResult from observation")
                failedCount += 1
            }
        }

        print("  📊 [DEBUG] Conversion summary: \(results.count) passed, \(skippedCount) skipped, \(failedCount) failed")

        // Sort by y-position (top to bottom) for natural reading order
        // Note: Vision uses bottom-left origin, so we invert y
        return results.sorted { $0.boundingBox.maxY > $1.boundingBox.maxY }
    }
}
