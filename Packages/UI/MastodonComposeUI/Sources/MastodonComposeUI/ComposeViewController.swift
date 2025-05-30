//
//  ComposeViewController.swift
//  MastodonComposeUI
//
//  Created by Nikita   on 25.05.25.
//

import UIKit
import UIKitFoundation
import PhotosUI

final class ComposeViewController: ViewController {
    
    private let composeView = ComposeView(frame: .zero)
    
    private var selectedImagesCount = 0
    
    override func setupCommon() {
        super.setupCommon()
        title = "New Post"
        let leftBarButtonItem = UIBarButtonItem(title: "Cancel", primaryAction: UIAction { [unowned self] _ in
            presentingViewController?.dismiss(animated: true)
        })
        leftBarButtonItem.tintColor = .systemRed
        navigationItem.leftBarButtonItem = leftBarButtonItem
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Publish")
        composeView.textView.delegate = self
        composeView.toolbar.delegate = self
    }
    
    override func loadView() {
        view = composeView
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        composeView.textView.becomeFirstResponder()
    }
}

extension ComposeViewController {
    
    private func addMediaLoadingView(for image: UIImage) {
        var configuration = MediaLoadingView.LoadingConfiguration()
        configuration.image = image
        let mediaLoadingView = MediaLoadingView(frame: .zero)
        mediaLoadingView.configuration = configuration
        composeView.stackView.addArrangedSubview(mediaLoadingView)
        
        let cancelButton = createCancelButton()
        composeView.scrollView.addSubview(cancelButton)
        cancelButton.addAction(UIAction { [unowned self] _ in
            selectedImagesCount -= 1
            composeView.toolbar.addPhotoButtonIsEnabled = selectedImagesCount < 4
            UIViewPropertyAnimator.runningPropertyAnimator(withDuration: CATransaction.animationDuration(), delay: 0.0) {
                mediaLoadingView.alpha = 0.0
                mediaLoadingView.isHidden = true
                cancelButton.alpha = 0.0
                cancelButton.isHidden = true
            } completion: { _ in
                mediaLoadingView.removeFromSuperview()
                cancelButton.removeFromSuperview()
            }
        }, for: .touchUpInside)
        
        NSLayoutConstraint.activate([
            mediaLoadingView.heightAnchor.constraint(equalToConstant: 200.0),
            
            cancelButton.centerXAnchor.constraint(equalTo: mediaLoadingView.trailingAnchor),
            cancelButton.centerYAnchor.constraint(equalTo: mediaLoadingView.topAnchor),
        ])
        composeView.stackView.layoutIfNeeded()
    }
    
    private func getFirstFrame(from url: URL) -> UIImage? {
        let asset = AVAsset(url: url)
        let imageGenerator = AVAssetImageGenerator(asset: asset)
        return if let cgImage = try? imageGenerator.copyCGImage(at: .zero, actualTime: nil) {
            UIImage(cgImage: cgImage)
        } else {
            nil
        }
    }
    
    private func createCancelButton() -> UIButton {
        var configuration = UIButton.Configuration.borderless()
        configuration.image = UIImage(systemName: "minus.circle.fill")!
        configuration.preferredSymbolConfigurationForImage = .preferringMulticolor()
        let button = UIButton(configuration: configuration)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }
}

extension ComposeViewController: UITextViewDelegate {
    
    func textViewDidChange(_ textView: UITextView) {
        let composeTextView = textView as! ComposeTextView
        composeView.toolbar.symbolCount = Constants.maxPostSymbolsCount - composeTextView.text.count
        composeTextView.placeholderLabel.isHidden = !composeTextView.text.isEmpty
    }
    
    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        textView.text.count + text.count - range.length <= Constants.maxPostSymbolsCount
    }
}

extension ComposeViewController: UITextFieldDelegate {
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        composeView.textView.becomeFirstResponder()
    }
}

extension ComposeViewController: Toolbar.Delegate {
    
    func toolbarDidSelectPhotoButton(_ toolbar: Toolbar) {
        var configuration = PHPickerConfiguration(photoLibrary: .shared())
        configuration.selectionLimit = 4
        configuration.preferredAssetRepresentationMode = .current
        let pickerViewController = PHPickerViewController(configuration: configuration)
        pickerViewController.delegate = self
        present(pickerViewController, animated: true)
    }
    
    func toolbarDidSelectExclamationmarkButton(_ toolbar: Toolbar) {
        composeView.spoilerTextField.isDescendant(of: composeView.stackView) ? removeSpolerTextField() : addSpoilerTextField()
        
        func addSpoilerTextField() {
            composeView.spoilerTextField.delegate = self
            composeView.stackView.insertArrangedSubview(composeView.spoilerTextField, at: 0)
            UIViewPropertyAnimator.runningPropertyAnimator(withDuration: CATransaction.animationDuration(), delay: 0.0) { [composeView] in
                composeView.spoilerTextField.alpha = 1.0
                composeView.spoilerTextField.isHidden = false
            }
        }
        
        func removeSpolerTextField() {
            UIViewPropertyAnimator.runningPropertyAnimator(withDuration: CATransaction.animationDuration(), delay: 0.0) { [composeView] in
                composeView.spoilerTextField.alpha = 0.0
                composeView.spoilerTextField.isHidden = true
            } completion: { [weak self] _ in
                guard let self else { return }
                composeView.textView.becomeFirstResponder()
                composeView.spoilerTextField.removeFromSuperview()
                composeView.spoilerTextField.delegate = nil
            }
        }
    }
}

extension ComposeViewController: PHPickerViewControllerDelegate {
    
    func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
        selectedImagesCount += results.count
        composeView.toolbar.addPhotoButtonIsEnabled = selectedImagesCount < 4
        for result in results {
            let itemProvider = result.itemProvider
            if itemProvider.canLoadObject(ofClass: UIImage.self) {
                itemProvider.loadObject(ofClass: UIImage.self) { image, error in
                    guard error == nil, let image = image as? UIImage else { return }
                    DispatchQueue.main.async { [self] in
                        addMediaLoadingView(for: image)
                    }
                }
            } else if itemProvider.canLoadObject(ofClass: PHLivePhoto.self) {
                itemProvider.loadObject(ofClass: PHLivePhoto.self) { [weak self] livePhoto, error in
                    guard let self, error == nil, let livePhoto = livePhoto as? PHLivePhoto else { return }
                    let resource = PHAssetResource.assetResources(for: livePhoto)
                    let photo = resource.first(where: { $0.type == .photo })!
                    let imageData = NSMutableData()
                    PHAssetResourceManager.default().requestData(for: photo, options: nil) { data in
                        imageData.append(data)
                    } completionHandler: { error in
                        guard error == nil, let image = UIImage(data: imageData as Data) else { return }
                        DispatchQueue.main.async {
                            self.addMediaLoadingView(for: image)
                        }
                    }
                }
            } else if itemProvider.hasItemConformingToTypeIdentifier(UTType.movie.identifier) {
                itemProvider.loadFileRepresentation(forTypeIdentifier: UTType.movie.identifier) { [weak self] url, error in
                    guard let self, error == nil, let url, let firstFrame = getFirstFrame(from: url) else { return }
                    DispatchQueue.main.async {
                        self.addMediaLoadingView(for: firstFrame)
                    }
                }
            }
        }
        dismiss(animated: true)
    }
}
