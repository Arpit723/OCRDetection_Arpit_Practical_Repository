//
//  PDFExportServiceImpl.swift
//  OCRDetection_Arpit_Practical
//
//  Created by Claude on 13/03/26.
//

import Foundation
import UIKit

/// Implementation of PDF export service using UIGraphicsPDFRenderer.
final class PDFExportServiceImpl: PDFExportService {

    // MARK: - Singleton

    static let shared = PDFExportServiceImpl()

    // MARK: - Properties

    private let configuration: PDFConfiguration
    private let fileManager: FileManager

    // MARK: - Init

    private init(configuration: PDFConfiguration = .default) {
        self.configuration = configuration
        self.fileManager = .default
    }

    // MARK: - PDFExportService

    func exportPDF(polynomial: Polynomial, image: UIImage?) async throws -> URL {
        let data = try await generatePDFData(polynomial: polynomial, image: image)

        let filename = "polynomial_\(polynomial.id.uuidString.prefix(8)).pdf"
        let tempURL = fileManager.temporaryDirectory.appendingPathComponent(filename)

        do {
            try data.write(to: tempURL, options: .atomic)
            return tempURL
        } catch {
            throw PDFError.fileWriteFailed(error)
        }
    }

    func exportPDF(polynomials: [Polynomial], images: [UUID: UIImage]?) async throws -> URL {
        guard !polynomials.isEmpty else {
            throw PDFError.invalidData
        }

        let renderer = UIGraphicsPDFRenderer(bounds: CGRect(origin: .zero, size: configuration.pageSize))

        let data = renderer.pdfData { context in
            var yPosition = configuration.margins.top
            let contentWidth = configuration.pageSize.width - configuration.margins.left - configuration.margins.right

            // Title page
            yPosition = drawTitlePage(in: context, yPosition: &yPosition, contentWidth: contentWidth)

            // Table of contents
            context.beginPage()
            yPosition = configuration.margins.top
            yPosition = drawTableOfContents(in: context, yPosition: &yPosition, polynomials: polynomials, contentWidth: contentWidth)

            // Each polynomial on its own page
            for polynomial in polynomials {
                context.beginPage()
                yPosition = configuration.margins.top

                let image = images?[polynomial.id]
                yPosition = drawPolynomial(in: context, yPosition: &yPosition, polynomial: polynomial, image: image, contentWidth: contentWidth)
            }
        }

        let filename = "polynomials_report_\(UUID().uuidString.prefix(8)).pdf"
        let tempURL = fileManager.temporaryDirectory.appendingPathComponent(filename)

        do {
            try data.write(to: tempURL, options: .atomic)
            return tempURL
        } catch {
            throw PDFError.fileWriteFailed(error)
        }
    }

    func generatePDFData(polynomial: Polynomial, image: UIImage?) async throws -> Data {
        let renderer = UIGraphicsPDFRenderer(bounds: CGRect(origin: .zero, size: configuration.pageSize))

        return renderer.pdfData { context in
            var yPosition = configuration.margins.top
            let contentWidth = configuration.pageSize.width - configuration.margins.left - configuration.margins.right

            // Header
            yPosition = drawHeader(in: context, yPosition: &yPosition, contentWidth: contentWidth)

            // Polynomial content
            yPosition = drawPolynomial(in: context, yPosition: &yPosition, polynomial: polynomial, image: image, contentWidth: contentWidth)

            // Footer
            drawFooter(in: context)
        }
    }

    // MARK: - Private Methods - Drawing

    private func drawTitlePage(in context: UIGraphicsPDFRendererContext, yPosition: inout CGFloat, contentWidth: CGFloat) -> CGFloat {
        var y = yPosition

        // App title
        let title = "Polynomial Analysis Report"
        let titleAttrs: [NSAttributedString.Key: Any] = [
            .font: configuration.titleFont,
            .foregroundColor: UIColor.label
        ]
        let titleSize = title.size(withAttributes: titleAttrs)
        title.draw(at: CGPoint(x: configuration.margins.left, y: y), withAttributes: titleAttrs)
        y += titleSize.height + 30

        // Date
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .long
        dateFormatter.timeStyle = .short
        let dateStr = "Generated: \(dateFormatter.string(from: Date()))"
        let dateAttrs: [NSAttributedString.Key: Any] = [
            .font: configuration.bodyFont,
            .foregroundColor: UIColor.secondaryLabel
        ]
        let dateSize = dateStr.size(withAttributes: dateAttrs)
        dateStr.draw(at: CGPoint(x: configuration.margins.left, y: y), withAttributes: dateAttrs)
        y += dateSize.height + 20

        // Divider
        let dividerPath = UIBezierPath()
        dividerPath.move(to: CGPoint(x: configuration.margins.left, y: y))
        dividerPath.addLine(to: CGPoint(x: configuration.pageSize.width - configuration.margins.right, y: y))
        dividerPath.lineWidth = 1.0
        UIColor.separator.set()
        dividerPath.stroke()
        y += 30

        return y
    }

    private func drawTableOfContents(in context: UIGraphicsPDFRendererContext, yPosition: inout CGFloat, polynomials: [Polynomial], contentWidth: CGFloat) -> CGFloat {
        var y = yPosition

        let heading = "Table of Contents"
        let headingAttrs: [NSAttributedString.Key: Any] = [
            .font: configuration.headingFont,
            .foregroundColor: UIColor.label
        ]
        let headingSize = heading.size(withAttributes: headingAttrs)
        heading.draw(at: CGPoint(x: configuration.margins.left, y: y), withAttributes: headingAttrs)
        y += headingSize.height + 20

        for (index, polynomial) in polynomials.enumerated() {
            let entry = "\(index + 1). \(polynomial.originalExpression)"
            let entryAttrs: [NSAttributedString.Key: Any] = [
                .font: configuration.bodyFont,
                .foregroundColor: UIColor.label
            ]
            let entrySize = entry.size(withAttributes: entryAttrs)
            entry.draw(at: CGPoint(x: configuration.margins.left, y: y), withAttributes: entryAttrs)
            y += entrySize.height + 10
        }

        return y
    }

    private func drawHeader(in context: UIGraphicsPDFRendererContext, yPosition: inout CGFloat, contentWidth: CGFloat) -> CGFloat {
        var y = yPosition

        // Title
        let title = "Polynomial Analysis Report"
        let titleAttrs: [NSAttributedString.Key: Any] = [
            .font: configuration.titleFont,
            .foregroundColor: UIColor.label
        ]
        let titleSize = title.size(withAttributes: titleAttrs)
        title.draw(at: CGPoint(x: configuration.margins.left, y: y), withAttributes: titleAttrs)
        y += titleSize.height + 10

        // Date
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .medium
        let dateStr = dateFormatter.string(from: Date())
        let dateAttrs: [NSAttributedString.Key: Any] = [
            .font: configuration.captionFont,
            .foregroundColor: UIColor.secondaryLabel
        ]
        dateStr.draw(at: CGPoint(x: configuration.margins.left, y: y), withAttributes: dateAttrs)
        y += 20

        // Divider
        let dividerPath = UIBezierPath()
        dividerPath.move(to: CGPoint(x: configuration.margins.left, y: y))
        dividerPath.addLine(to: CGPoint(x: configuration.pageSize.width - configuration.margins.right, y: y))
        dividerPath.lineWidth = 2.0
        UIColor.separator.set()
        dividerPath.stroke()

        return y + 20
    }

    private func drawPolynomial(in context: UIGraphicsPDFRendererContext, yPosition: inout CGFloat, polynomial: Polynomial, image: UIImage?, contentWidth: CGFloat) -> CGFloat {
        var y = yPosition

        // Original expression
        y = drawLabel(in: context, y: y, text: "Original Expression:", font: configuration.headingFont)
        y = drawLabel(in: context, y: y, text: polynomial.originalExpression, font: .boldSystemFont(ofSize: 20), color: .systemBlue)
        y += 10

        // Simplified expression
        if let simplified = polynomial.simplifiedExpression {
            y = drawLabel(in: context, y: y, text: "Simplified Expression:", font: configuration.headingFont)
            y = drawLabel(in: context, y: y, text: simplified, font: configuration.bodyFont)
            y += 10
        }

        // Derivative
        if let derivative = polynomial.derivative {
            y = drawLabel(in: context, y: y, text: "Derivative:", font: configuration.headingFont)
            y = drawLabel(in: context, y: y, text: derivative, font: configuration.bodyFont)
            y += 10
        }

        // Values
        y = drawLabel(in: context, y: y, text: "Evaluation Values:", font: configuration.headingFont)
        y = drawLabel(in: context, y: y, text: "  f(1) = \(polynomial.valueAt1Display)", font: configuration.bodyFont)
        y = drawLabel(in: context, y: y, text: "  f(2) = \(polynomial.valueAt2Display)", font: configuration.bodyFont)
        y += 20

        // Image
        if let image = image {
            y = drawImage(in: context, y: y, image: image, contentWidth: contentWidth)
        }

        return y
    }

    private func drawLabel(in context: UIGraphicsPDFRendererContext, y: CGFloat, text: String, font: UIFont, color: UIColor = .label) -> CGFloat {
        let attrs: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: color
        ]
        let size = text.size(withAttributes: attrs)

        // Check if we need a new page
        if y + size.height > configuration.pageSize.height - configuration.margins.bottom {
            context.beginPage()
            let newY = configuration.margins.top
            text.draw(at: CGPoint(x: configuration.margins.left, y: newY), withAttributes: attrs)
            return newY + size.height + 5
        }

        text.draw(at: CGPoint(x: configuration.margins.left, y: y), withAttributes: attrs)
        return y + size.height + 5
    }

    private func drawImage(in context: UIGraphicsPDFRendererContext, y: CGFloat, image: UIImage, contentWidth: CGFloat) -> CGFloat {
        // Calculate aspect fit dimensions
        let maxHeight = configuration.pageSize.height - configuration.margins.top - configuration.margins.bottom - y - 50
        let maxWidth = contentWidth

        let imageSize = image.size
        let aspectRatio = imageSize.width / imageSize.height

        var drawWidth: CGFloat
        var drawHeight: CGFloat

        if imageSize.width > imageSize.height {
            drawWidth = min(maxWidth, imageSize.width)
            drawHeight = drawWidth / aspectRatio

            if drawHeight > maxHeight {
                drawHeight = maxHeight
                drawWidth = drawHeight * aspectRatio
            }
        } else {
            drawHeight = min(maxHeight, imageSize.height)
            drawWidth = drawHeight * aspectRatio

            if drawWidth > maxWidth {
                drawWidth = maxWidth
                drawHeight = drawWidth / aspectRatio
            }
        }

        let drawRect = CGRect(
            x: configuration.margins.left + (maxWidth - drawWidth) / 2,
            y: y,
            width: drawWidth,
            height: drawHeight
        )

        image.draw(in: drawRect)

        return y + drawHeight + 10
    }

    private func drawFooter(in context: UIGraphicsPDFRendererContext) {
        let footer = "Generated by Polynomial OCR App"
        let attrs: [NSAttributedString.Key: Any] = [
            .font: configuration.captionFont,
            .foregroundColor: UIColor.tertiaryLabel
        ]

        let size = footer.size(withAttributes: attrs)
        let x = (configuration.pageSize.width - size.width) / 2
        let y = configuration.pageSize.height - configuration.margins.bottom + 10

        footer.draw(at: CGPoint(x: x, y: y), withAttributes: attrs)
    }
}
