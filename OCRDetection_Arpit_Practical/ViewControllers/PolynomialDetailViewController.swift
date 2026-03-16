//
//  PolynomialDetailViewController.swift
//  OCRDetection_Arpit_Practical
//
//  Created by Claude on 13/03/26.
//

import UIKit

/// Detail view controller that displays all computed data for a polynomial.
/// Shows original expression, simplified form, derivative, and evaluation values.
class PolynomialDetailViewController: UIViewController {

    // MARK: - IBOutlets

    @IBOutlet private weak var scrollView: UIScrollView!
    @IBOutlet private weak var originalLabel: UILabel!
    @IBOutlet private weak var simplifiedTitleLabel: UILabel!
    @IBOutlet private weak var simplifiedLabel: UILabel!
    @IBOutlet private weak var derivativeTitleLabel: UILabel!
    @IBOutlet private weak var derivativeLabel: UILabel!
    @IBOutlet private weak var valueAt1TitleLabel: UILabel!
    @IBOutlet private weak var valueAt1Label: UILabel!
    @IBOutlet private weak var valueAt2TitleLabel: UILabel!
    @IBOutlet private weak var valueAt2Label: UILabel!
    @IBOutlet private weak var imageView: UIImageView!

    // MARK: - Properties

    var polynomial: Polynomial!
    var image: UIImage?
    private lazy var detailViewModel = DependencyContainer.shared.makePolynomialDetailViewModel(polynomial: polynomial)

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        configure()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        // Ensure content size is correct
        scrollView.layoutIfNeeded()
    }

    // MARK: - Setup

    private func setupUI() {
        // Setup navigation bar
        title = "Polynomial Details"
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .action,
            target: self,
            action: #selector(shareButtonTapped)
        )

        // Configure labels with semantic fonts
        originalLabel.font = .preferredFont(forTextStyle: .headline)
        originalLabel.numberOfLines = 0

        // Title labels
        simplifiedTitleLabel.font = .preferredFont(forTextStyle: .subheadline)
        simplifiedTitleLabel.textColor = .secondaryLabel
        simplifiedTitleLabel.text = "Simplified Version:"

        derivativeTitleLabel.font = .preferredFont(forTextStyle: .subheadline)
        derivativeTitleLabel.textColor = .secondaryLabel
        derivativeTitleLabel.text = "Derivative:"

        valueAt1TitleLabel.font = .preferredFont(forTextStyle: .subheadline)
        valueAt1TitleLabel.textColor = .secondaryLabel
        valueAt1TitleLabel.text = "Value at x = 1:"

        valueAt2TitleLabel.font = .preferredFont(forTextStyle: .subheadline)
        valueAt2TitleLabel.textColor = .secondaryLabel
        valueAt2TitleLabel.text = "Value at x = 2:"

        // Value labels
        simplifiedLabel.font = .preferredFont(forTextStyle: .title3)
        simplifiedLabel.numberOfLines = 0
        simplifiedLabel.textColor = .label

        derivativeLabel.font = .preferredFont(forTextStyle: .title3)
        derivativeLabel.numberOfLines = 0
        derivativeLabel.textColor = .label

        valueAt1Label.font = .preferredFont(forTextStyle: .body)
        valueAt1Label.numberOfLines = 0

        valueAt2Label.font = .preferredFont(forTextStyle: .body)
        valueAt2Label.numberOfLines = 0

        // Configure image view
        imageView.contentMode = .scaleAspectFit
        imageView.clipsToBounds = true
        imageView.layer.cornerRadius = 12
        imageView.layer.borderWidth = 1
        imageView.layer.borderColor = UIColor.separator.cgColor

        // Accessibility
        setupAccessibility()
    }

    private func setupAccessibility() {
        scrollView.isAccessibilityElement = false

        originalLabel.isAccessibilityElement = true
        originalLabel.accessibilityLabel = "Original expression"

        simplifiedLabel.isAccessibilityElement = true
        simplifiedLabel.accessibilityLabel = "Simplified expression"

        derivativeLabel.isAccessibilityElement = true
        derivativeLabel.accessibilityLabel = "Derivative"

        valueAt1Label.isAccessibilityElement = true
        valueAt1Label.accessibilityLabel = "Value at x equals 1"

        valueAt2Label.isAccessibilityElement = true
        valueAt2Label.accessibilityLabel = "Value at x equals 2"

        imageView.isAccessibilityElement = true
        imageView.accessibilityLabel = "Original image"
    }

    // MARK: - Configuration

    private func configure() {
        guard let polynomial = polynomial else { return }

        originalLabel.text = polynomial.originalExpression
        simplifiedLabel.text = polynomial.simplifiedExpression ?? "Unable to simplify"
        derivativeLabel.text = polynomial.derivative ?? "Unable to calculate derivative"

        // Format values
        if let valueAt1 = polynomial.valueAt1 {
            valueAt1Label.text = formatValue(valueAt1)
        } else {
            valueAt1Label.text = "N/A"
        }

        if let valueAt2 = polynomial.valueAt2 {
            valueAt2Label.text = formatValue(valueAt2)
        } else {
            valueAt2Label.text = "N/A"
        }

        // Load image
        if let providedImage = image {
            imageView.image = providedImage
        } else if let imagePath = polynomial.imagePath {
            imageView.image = detailViewModel.loadImage()
        } else {
            let config = UIImage.SymbolConfiguration(pointSize: 60, weight: .light)
            imageView.image = UIImage(systemName: "function", withConfiguration: config)
            imageView.tintColor = .tertiaryLabel
        }

        // Hide image view if no image
        imageView.isHidden = imageView.image == nil
    }

    private func formatValue(_ value: Double) -> String {
        if value.isInfinite { return "∞" }
        if value.isNaN { return "Undefined" }

        // Check if it's an integer
        if value.truncatingRemainder(dividingBy: 1) == 0 {
            return String(format: "%.0f", value)
        }

        return String(format: "%.4f", value)
    }

    // MARK: - Actions

    @objc private func shareButtonTapped() {
        // Show activity indicator
        let activityIndicator = UIActivityIndicatorView(style: .large)
        activityIndicator.center = view.center
        activityIndicator.hidesWhenStopped = true
        view.addSubview(activityIndicator)
        activityIndicator.startAnimating()
        navigationItem.rightBarButtonItem?.isEnabled = false

        Task {
            do {
                let pdfURL = try await detailViewModel.exportToPDF()

                await MainActor.run {
                    activityIndicator.stopAnimating()
                    activityIndicator.removeFromSuperview()
                    navigationItem.rightBarButtonItem?.isEnabled = true

                    // Present share sheet
                    let activityVC = UIActivityViewController(
                        activityItems: [pdfURL],
                        applicationActivities: nil
                    )

                    // For iPad
                    if let popover = activityVC.popoverPresentationController {
                        popover.barButtonItem = navigationItem.rightBarButtonItem
                    }

                    present(activityVC, animated: true)
                }
            } catch {
                await MainActor.run {
                    activityIndicator.stopAnimating()
                    activityIndicator.removeFromSuperview()
                    navigationItem.rightBarButtonItem?.isEnabled = true

                    showAlert(
                        title: "Export Failed",
                        message: "Failed to generate PDF: \(error.localizedDescription)"
                    )
                }
            }
        }
    }

    private func showAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }

    // MARK: - Trait Collection Changes

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)

        // Update fonts when trait collection changes (e.g., Dynamic Type)
        originalLabel.font = .preferredFont(forTextStyle: .headline)
        simplifiedLabel.font = .preferredFont(forTextStyle: .title3)
        derivativeLabel.font = .preferredFont(forTextStyle: .title3)
        valueAt1Label.font = .preferredFont(forTextStyle: .body)
        valueAt2Label.font = .preferredFont(forTextStyle: .body)
    }
}
