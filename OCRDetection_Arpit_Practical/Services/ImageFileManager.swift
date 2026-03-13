//
//  ImageFileManager.swift
//  OCRDetection_Arpit_Practical
//
//  Created by Arpit Parekh on 13/03/26.
//

import UIKit

/// Manages image file storage in Documents directory.
/// Thread-safe file operations with proper error handling.
final class ImageFileManager {

    // MARK: - Singleton

    static let shared = ImageFileManager()

    // MARK: - Properties

    private let fileManager = FileManager.default
    private let imagesDirectory: URL

    private let maxImageSize: CGFloat = 1024.0  // Max width/height in points
    private let jpegCompressionQuality: CGFloat = 0.7

    // MARK: - Initialization

    private init() {
        // Setup images directory in Documents
        let documentsUrl = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
        imagesDirectory = documentsUrl.appendingPathComponent("polynomial-images")
        createDirectoryIfNeeded()
    }

    // MARK: - Directory Management

    private func createDirectoryIfNeeded() {
        if !fileManager.fileExists(atPath: imagesDirectory.path) {
            do {
                try fileManager.createDirectory(
                    at: imagesDirectory,
                    withIntermediateDirectories: true,
                    attributes: nil
                )
            } catch {
                print("⚠️ ImageFileManager: Failed to create directory - \(error)")
            }
        }
    }

    // MARK: - Public Methods

    /// Save an image to disk and return the file path.
    /// - Parameter image: The UIImage to save
    /// - Returns: Absolute file path string, or nil if save failed
    func saveImage(_ image: UIImage) -> String? {
        // Resize image to max dimensions
        guard let processedImage = resizeImage(image) else {
            print("⚠️ ImageFileManager: Failed to resize image")
            return nil
        }

        // Compress to JPEG
        guard let imageData = processedImage.jpegData(compressionQuality: jpegCompressionQuality) else {
            print("⚠️ ImageFileManager: Failed to convert image to JPEG data")
            return nil
        }

        // Generate unique filename
        let filename = "\(UUID().uuidString).jpg"
        let fileURL = imagesDirectory.appendingPathComponent(filename)

        // Write atomically to prevent corruption
        do {
            try imageData.write(to: fileURL, options: .atomic)
            print("✅ ImageFileManager: Saved image to \(fileURL.path)")
            return fileURL.path
        } catch {
            print("⚠️ ImageFileManager: Failed to write image - \(error)")
            return nil
        }
    }

    /// Load an image from the given file path.
    /// - Parameter path: Absolute file path string
    /// - Returns: UIImage if successful, nil otherwise
    func loadImage(from path: String) -> UIImage? {
        guard fileManager.fileExists(atPath: path) else {
            print("⚠️ ImageFileManager: File does not exist at \(path)")
            return nil
        }

        return UIImage(contentsOfFile: path)
    }

    /// Delete an image file at the given path.
    /// - Parameter path: Absolute file path string
    /// - Throws: FileManager error if deletion fails
    func deleteImage(at path: String) throws {
        guard fileManager.fileExists(atPath: path) else {
            print("⚠️ ImageFileManager: File does not exist, skipping delete")
            return
        }

        try fileManager.removeItem(atPath: path)
        print("✅ ImageFileManager: Deleted image at \(path)")
    }

    /// Get the file size in bytes for a given path.
    /// - Parameter path: Absolute file path string
    /// - Returns: File size in bytes, or nil if file doesn't exist
    func fileSize(at path: String) -> Int64? {
        guard fileManager.fileExists(atPath: path) else {
            return nil
        }

        let attributes = try? fileManager.attributesOfItem(atPath: path)
        return attributes?[.size] as? Int64
    }

    /// Delete all images in the polynomial-images directory.
    func deleteAllImages() throws {
        let contents = try fileManager.contentsOfDirectory(
            at: imagesDirectory,
            includingPropertiesForKeys: nil
        )

        for url in contents {
            try fileManager.removeItem(at: url)
        }
        print("✅ ImageFileManager: Deleted all images")
    }

    // MARK: - Private Helper Methods

    /// Resize image to max dimensions while maintaining aspect ratio.
    private func resizeImage(_ image: UIImage) -> UIImage? {
        let size = image.size

        // Check if resize is needed
        if size.width <= maxImageSize && size.height <= maxImageSize {
            return image
        }

        // Calculate scaling factor
        let widthRatio = maxImageSize / size.width
        let heightRatio = maxImageSize / size.height
        let scaleFactor = min(widthRatio, heightRatio)

        let newSize = CGSize(
            width: size.width * scaleFactor,
            height: size.height * scaleFactor
        )

        // Resize using UIGraphicsImageRenderer
        return UIGraphicsImageRenderer(size: newSize).image { _ in
            image.draw(in: CGRect(origin: .zero, size: newSize))
        }
    }
}
