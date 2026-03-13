//
//  PolynomialCollectionViewCell.swift
//  OCRDetection_Arpit_Practical
//
//  Created by Claude on 13/03/26.
//

import UIKit

/// Collection view cell that displays a polynomial in card format.
/// Shows original expression, simplified form, and evaluation values.
class PolynomialCollectionViewCell: UICollectionViewCell {

    // MARK: - IBOutlets

    @IBOutlet private weak var cardView: UIView!
    @IBOutlet private weak var primaryLabel: UILabel!
    @IBOutlet private weak var secondaryLabel: UILabel!
    @IBOutlet private weak var tertiaryStackView: UIStackView!
    @IBOutlet private weak var valueAt1Label: UILabel!
    @IBOutlet private weak var valueAt2Label: UILabel!

    // MARK: - Reuse Identifier

    static let reuseIdentifier = "PolynomialCell"

    // MARK: - Initialization

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupView()
    }

    // MARK: - Setup

    private func setupView() {
        // This is called both when created from code and storyboard
        // Apply styling that needs to happen regardless of outlet connection
        layer.shadowColor = UIColor.black.cgColor
        layer.shadowOffset = CGSize(width: 0, height: 2)
        layer.shadowRadius = 4
        layer.shadowOpacity = 0.1
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        // Update shadow path based on actual bounds
        layer.shadowPath = UIBezierPath(
            roundedRect: bounds.insetBy(dx: 4, dy: 4),
            cornerRadius: cardView?.layer.cornerRadius ?? 12
        ).cgPath
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        primaryLabel.text = nil
        secondaryLabel.text = nil
        valueAt1Label.text = nil
        valueAt2Label.text = nil
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        updateFonts()
        updateColors()
    }

    // MARK: - Configuration

    func configure(with polynomial: Polynomial) {
        // Primary: Original expression
        primaryLabel.text = polynomial.originalExpression

        // Secondary: Simplified expression
        secondaryLabel.text = polynomial.simplifiedDisplay

        // Tertiary: Values
        valueAt1Label.text = "f(1) = \(polynomial.valueAt1Display)"
        valueAt2Label.text = "f(2) = \(polynomial.valueAt2Display)"

        updateFonts()
        updateColors()

        // Accessibility
        configureAccessibility(with: polynomial)
    }

    // MARK: - Private Methods

    private func updateFonts() {
        primaryLabel.font = .preferredFont(forTextStyle: .headline)
        secondaryLabel.font = .preferredFont(forTextStyle: .title3)
        valueAt1Label.font = .preferredFont(forTextStyle: .caption1)
        valueAt2Label.font = .preferredFont(forTextStyle: .caption1)
    }

    private func updateColors() {
        // Card background
        cardView.backgroundColor = .secondarySystemBackground

        // Primary label
        primaryLabel.textColor = .label

        // Secondary label
        secondaryLabel.textColor = .secondaryLabel

        // Value labels
        valueAt1Label.textColor = .tertiaryLabel
        valueAt2Label.textColor = .tertiaryLabel

        // Shadow color
        layer.shadowColor = UIColor.label.cgColor
    }

    private func configureAccessibility(with polynomial: Polynomial) {
        isAccessibilityElement = true
        accessibilityLabel = """
        Polynomial: \(polynomial.originalExpression)
        Simplified: \(polynomial.simplifiedDisplay)
        f(1) = \(polynomial.valueAt1Display)
        f(2) = \(polynomial.valueAt2Display)
        """
        accessibilityHint = "Double tap to view details"
    }
}
