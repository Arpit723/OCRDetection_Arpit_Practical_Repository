//
//  PolynomialListViewController.swift
//  OCRDetection_Arpit_Practical
//
//  Created by Claude on 13/03/26.
//

import UIKit
import PhotosUI

/// Main view controller that displays a list of detected polynomials.
/// Manages OCR pipeline, image import, and collection view display.
class PolynomialListViewController: UIViewController {

    // MARK: - IBOutlets

    @IBOutlet private weak var previewImageView: UIImageView!
    @IBOutlet private weak var statusLabel: UILabel!
    @IBOutlet private weak var collectionView: UICollectionView!
    @IBOutlet private weak var activityIndicator: UIActivityIndicatorView!

    // MARK: - Properties

    private let viewModel: PolynomialListViewModel
    private var polynomials: [Polynomial] = []

    // MARK: - Init

    init?(coder: NSCoder, viewModel: PolynomialListViewModel) {
        self.viewModel = viewModel
        super.init(coder: coder)
    }

    required init?(coder: NSCoder) {
        // Use DependencyContainer for initialization
        self.viewModel = DependencyContainer.shared.makePolynomialListViewModel()
        super.init(coder: coder)
    }

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        loadPolynomials()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        loadPolynomials()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        collectionView.collectionViewLayout.invalidateLayout()
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        collectionView.collectionViewLayout.invalidateLayout()
    }

    // MARK: - Setup

    private func setupUI() {
        // Setup navigation bar
        title = "Polynomial OCR"
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .add,
            target: self,
            action: #selector(importButtonTapped)
        )

        // Configure collection view
        collectionView.dataSource = self
        collectionView.delegate = self

        // Setup preview image view
        previewImageView.layer.cornerRadius = 12
        previewImageView.layer.borderWidth = 1
        previewImageView.layer.borderColor = UIColor.separator.cgColor
        previewImageView.contentMode = .scaleAspectFit
        previewImageView.clipsToBounds = true
        previewImageView.backgroundColor = .secondarySystemBackground

        // Set placeholder image
        let config = UIImage.SymbolConfiguration(pointSize: 40, weight: .light)
        previewImageView.image = UIImage(systemName: "doc.text.viewfinder", withConfiguration: config)

        // Setup status label
        statusLabel.font = .preferredFont(forTextStyle: .caption1)
        statusLabel.textColor = .secondaryLabel
        statusLabel.textAlignment = .center
        updateStatus(detected: 0)

        // Accessibility
        setupAccessibility()
    }

    private func setupAccessibility() {
        collectionView.isAccessibilityElement = false
        collectionView.accessibilityLabel = "List of detected polynomials"

        previewImageView.isAccessibilityElement = true
        previewImageView.accessibilityLabel = "Image preview"
        previewImageView.accessibilityHint = "Shows the imported image for polynomial detection"

        statusLabel.isAccessibilityElement = true
        statusLabel.accessibilityLabel = "Detection status"
    }

    // MARK: - Actions

    @objc private func importButtonTapped() {
        var configuration = PHPickerConfiguration(photoLibrary: .shared())
        configuration.filter = .images
        configuration.selectionLimit = 1
        configuration.preferredAssetRepresentationMode = .current

        let picker = PHPickerViewController(configuration: configuration)
        picker.delegate = self
        present(picker, animated: true)
    }

    // MARK: - Data Loading

    private func loadPolynomials() {
        print("🔄 [DEBUG] loadPolynomials called")
        Task { @MainActor in
            do {
                print("📊 [DEBUG] Fetching all polynomials from repository...")
                polynomials = try await viewModel.fetchAllPolynomials()
                print("✅ [DEBUG] Fetched \(polynomials.count) polynomials from Core Data")

                // Update UI on main thread
                print("🔄 [DEBUG] Updating UI with \(polynomials.count) items")
                collectionView.reloadData()
                updateStatus(detected: polynomials.count)

                // Verify collection view state
                print("  📊 Collection view has \(collectionView.numberOfItems(inSection: 0)) items")
                print("  📊 polynomials array has \(polynomials.count) items")
                print("✅ [DEBUG] Collection view reloaded successfully")

                // Force layout update
                collectionView.layoutIfNeeded()
            } catch {
                print("❌ [DEBUG] loadPolynomials ERROR: \(error)")
                showError(error, message: "Failed to load polynomials")
            }
        }
    }

    // MARK: - OCR Processing

    private func processImage(_ image: UIImage) {
        print("🔍 [DEBUG] processImage called with image size: \(image.size)")
        showActivityIndicator()

        Task { @MainActor in
            do {
                print("📸 [DEBUG] Starting OCR pipeline...")
                let results = try await viewModel.processImage(image)
                print("✅ [DEBUG] OCR pipeline completed, got \(results.count) polynomials")

                // Small delay to ensure Core Data saves complete and merge happens
                try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds

                hideActivityIndicator()

                // Update preview FIRST
                print("🖼️ [DEBUG] Updating preview image")
                previewImageView.image = image
                print("✅ [DEBUG] Preview image updated")

                // THEN load polynomials
                print("🔄 [DEBUG] Loading polynomials after save...")
                loadPolynomials()

                // Show results message
                if results.isEmpty {
                    print("⚠️ [DEBUG] No polynomials detected - showing alert")
                    showAlert(
                        title: "No Polynomials Detected",
                        message: "No polynomial expressions were found in the image. Please try an image with clearer mathematical expressions."
                    )
                }
            } catch {
                print("❌ [DEBUG] processImage ERROR: \(error.localizedDescription)")
                hideActivityIndicator()
                showError(error, message: "Failed to process image")
            }
        }
    }

    // MARK: - UI Updates

    private func updateStatus(detected count: Int) {
        statusLabel.text = count == 1 ? "1 polynomial detected" : "\(count) polynomials detected"
    }

    private func showActivityIndicator() {
        activityIndicator.isHidden = false
        activityIndicator.startAnimating()
        collectionView.isUserInteractionEnabled = false
        navigationItem.rightBarButtonItem?.isEnabled = false
    }

    private func hideActivityIndicator() {
        activityIndicator.stopAnimating()
        collectionView.isUserInteractionEnabled = true
        navigationItem.rightBarButtonItem?.isEnabled = true
    }

    private func showError(_ error: Error, message: String) {
        showAlert(
            title: "Error",
            message: "\(message): \(error.localizedDescription)"
        )
    }

    private func showAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }

    // MARK: - Navigation

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "showDetail",
           let detailVC = segue.destination as? PolynomialDetailViewController,
           let indexPath = collectionView.indexPathsForSelectedItems?.first {
            let polynomial = polynomials[indexPath.item]
            detailVC.polynomial = polynomial
            detailVC.image = previewImageView.image
        }
    }
}

// MARK: - PHPickerViewControllerDelegate

extension PolynomialListViewController: PHPickerViewControllerDelegate {

    func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
        picker.dismiss(animated: true)

        guard let result = results.first else {
            return
        }

        let itemProvider = result.itemProvider

        if itemProvider.hasItemConformingToTypeIdentifier(UTType.image.identifier) {
            itemProvider.loadObject(ofClass: UIImage.self) { [weak self] object, error in
                guard let self = self, let image = object as? UIImage else {
                    DispatchQueue.main.async {
                        self?.showError(error ?? NSError(domain: "Picker", code: -1), message: "Failed to load image")
                    }
                    return
                }

                DispatchQueue.main.async {
                    self.processImage(image)
                }
            }
        }
    }
}

// MARK: - UICollectionViewDataSource

extension PolynomialListViewController: UICollectionViewDataSource {

    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return polynomials.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(
            withReuseIdentifier: "PolynomialCell",
            for: indexPath
        ) as? PolynomialCollectionViewCell else {
            return UICollectionViewCell()
        }

        let polynomial = polynomials[indexPath.item]
        cell.configure(with: polynomial)
        cell.accessibilityLabel = "Polynomial: \(polynomial.originalExpression)"
        cell.accessibilityHint = "Double tap to view details"

        return cell
    }
}

// MARK: - UICollectionViewDelegate

extension PolynomialListViewController: UICollectionViewDelegate {

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        performSegue(withIdentifier: "showDetail", sender: indexPath)
    }
}

// MARK: - UICollectionViewDelegateFlowLayout

extension PolynomialListViewController: UICollectionViewDelegateFlowLayout {

    func collectionView(
        _ collectionView: UICollectionView,
        layout collectionViewLayout: UICollectionViewLayout,
        sizeForItemAt indexPath: IndexPath
    ) -> CGSize {
        let width = collectionView.bounds.width
        let height: CGFloat = 120

        switch traitCollection.horizontalSizeClass {
        case .compact:
            // iPhone portrait: single column
            return CGSize(width: width - 32, height: height)

        case .regular:
            // iPad or iPhone landscape: 2-3 columns
            let columns: CGFloat = traitCollection.userInterfaceIdiom == .pad ? 3 : 2
            let spacing: CGFloat = 12
            let totalSpacing = spacing * (columns + 1)
            let itemWidth = (width - totalSpacing) / columns
            return CGSize(width: itemWidth, height: height)

        default:
            return CGSize(width: width - 32, height: height)
        }
    }

    func collectionView(
        _ collectionView: UICollectionView,
        layout collectionViewLayout: UICollectionViewLayout,
        minimumInteritemSpacingForSectionAt section: Int
    ) -> CGFloat {
        return 12
    }

    func collectionView(
        _ collectionView: UICollectionView,
        layout collectionViewLayout: UICollectionViewLayout,
        minimumLineSpacingForSectionAt section: Int
    ) -> CGFloat {
        return 12
    }

    func collectionView(
        _ collectionView: UICollectionView,
        layout collectionViewLayout: UICollectionViewLayout,
        insetForSectionAt section: Int
    ) -> UIEdgeInsets {
        switch traitCollection.horizontalSizeClass {
        case .compact:
            return UIEdgeInsets(top: 12, left: 16, bottom: 12, right: 16)
        case .regular:
            return UIEdgeInsets(top: 12, left: 24, bottom: 12, right: 24)
        default:
            return UIEdgeInsets(top: 12, left: 16, bottom: 12, right: 16)
        }
    }
}
