//
//  ComposeViewController.swift
//  MastodonComposeUI
//
//  Created by Nikita Prokhorchuk on 25.05.25.
//

import MastodonKit
import PhotosUI
import UIKit
import UIKitFoundation

final class ComposeViewController: ViewController {
    
    private let composeView = ComposeView(frame: .zero)
    private var selectedImagesCount = 0
    private var mediaUploadingTasks = [Int: Task<Void, Never>]()
    private var mediaLoadingViews = [Int: (MediaLoadingView, UIButton)]()
    
    override func setupCommon() {
        super.setupCommon()
        configureNavigationBar()
        configureComposeView()
    }

    override func loadView() {
        view = composeView
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        composeView.textView.becomeFirstResponder()
    }
    
    deinit {
        cancelAllMediaTasks()
    }
    
    private func configureNavigationBar() {
        title = "New Post"
        
        let leftBarButtonItem = UIBarButtonItem(
            title: "Cancel",
            primaryAction: UIAction { [unowned self] _ in
                presentingViewController?.dismiss(animated: true)
            }
        )
        leftBarButtonItem.tintColor = .systemRed
        navigationItem.leftBarButtonItem = leftBarButtonItem
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Publish")
    }
    
    private func configureComposeView() {
        composeView.textView.delegate = self
        composeView.toolbar.delegate = self
    }
    
    private func cancelAllMediaTasks() {
        for (_, task) in mediaUploadingTasks {
            task.cancel()
        }
    }
}

extension ComposeViewController {
    
    private func addMediaLoadingView(for image: UIImage, at index: Int) {
        let mediaLoadingView = createMediaLoadingView(with: image)
        composeView.stackView.addArrangedSubview(mediaLoadingView)

        let cancelButton = createCancelButton(for: index)
        composeView.scrollView.addSubview(cancelButton)
        
        NSLayoutConstraint.activate([
            mediaLoadingView.heightAnchor.constraint(equalToConstant: 200.0),
            cancelButton.centerXAnchor.constraint(equalTo: mediaLoadingView.trailingAnchor),
            cancelButton.centerYAnchor.constraint(equalTo: mediaLoadingView.topAnchor),
        ])
        composeView.stackView.layoutIfNeeded()
        
        mediaLoadingViews[index] = (mediaLoadingView, cancelButton)
    }
    
    private func createMediaLoadingView(with image: UIImage) -> MediaLoadingView {
        var configuration = MediaLoadingView.PreparationConfiguration()
        configuration.image = image
        let mediaLoadingView = MediaLoadingView(frame: .zero)
        mediaLoadingView.configuration = configuration
        return mediaLoadingView
    }
    
    private func createCancelButton(for index: Int) -> UIButton {
        var configuration = UIButton.Configuration.borderless()
        configuration.image = UIImage(systemName: "minus.circle.fill")!
        configuration.preferredSymbolConfigurationForImage = .preferringMulticolor()
        
        let button = UIButton(configuration: configuration)
        button.translatesAutoresizingMaskIntoConstraints = false
        
        button.addAction(
            UIAction { [unowned self] _ in
                removeMediaLoadingView(at: index)
                mediaUploadingTasks[index]?.cancel()
            },
            for: .touchUpInside
        )
        
        return button
    }

    private func removeMediaLoadingView(at index: Int) {
        selectedImagesCount -= 1
        composeView.toolbar.addPhotoButtonIsEnabled = selectedImagesCount < 4
        
        guard let (mediaLoadingView, cancelButton) = mediaLoadingViews[index] else {
            assertionFailure("No media loading view found at index \(index)")
            return
        }
        
        animateRemoval(of: mediaLoadingView, and: cancelButton)
    }
    
    private func animateRemoval(of mediaLoadingView: MediaLoadingView, and cancelButton: UIButton) {
        UIViewPropertyAnimator.runningPropertyAnimator(
            withDuration: CATransaction.animationDuration(),
            delay: 0.0
        ) {
            mediaLoadingView.alpha = 0.0
            mediaLoadingView.isHidden = true
            cancelButton.alpha = 0.0
            cancelButton.isHidden = true
        } completion: { _ in
            mediaLoadingView.removeFromSuperview()
            cancelButton.removeFromSuperview()
        }
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
    
    private func presentErrorAlert(with message: String) {
        let alertController = UIAlertController(title: "An error has occured", message: message, preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: "Ok", style: .cancel))
        present(alertController, animated: true)
    }
}

extension ComposeViewController {
    
    private func uploadImage(_ image: UIImage, at index: Int) {
        mediaUploadingTasks[index] = Task {
            guard let data = image.pngData() else {
                assertionFailure("Failed to convert image to PNG data")
                return
            }
            
            await uploadMedia(
                data: data,
                fileName: "\(UUID().uuidString).png",
                mimeType: "image/png",
                at: index
            )
        }
    }
    
    private func uploadVideo(_ videoData: Data, at index: Int) {
        mediaUploadingTasks[index] = Task {
            await uploadMedia(
                data: videoData,
                fileName: "\(UUID().uuidString).mp4",
                mimeType: "video/mp4",
                at: index
            )
        }
    }
    
    private func uploadMedia(data: Data, fileName: String, mimeType: String, at index: Int) async {
        let authService = AuthorizationService.shared
        guard let instanceName = authService.instanceName,
              let token = try? authService.getAccessToken(for: instanceName)
        else {
            assertionFailure("No instance or access token found")
            return
        }
        
        do {
            let request = MediaUploadRequest(
                networkService: .default(),
                instanceHost: instanceName,
                accessToken: token,
                fileData: data,
                fileName: fileName,
                mimeType: mimeType
            )
            
            _ = try await request.response()
            await MainActor.run {
                mediaLoadingViews[index]?.0.configuration = MediaLoadingView.LoadedConfiguration()
            }
        } catch {
            await MainActor.run {
                removeMediaLoadingView(at: index)
                presentErrorAlert(with: error.localizedDescription)
            }
        }
    }
}

extension ComposeViewController {
    
    private func handleImageSelection(_ itemProvider: NSItemProvider, at index: Int) {
        itemProvider.loadObject(ofClass: UIImage.self) { [weak self] image, error in
            guard let self, error == nil, let image = image as? UIImage else { return }
            
            DispatchQueue.main.async {
                self.addMediaLoadingView(for: image, at: index)
            }
            
            self.uploadImage(image, at: index)
        }
    }
    
    private func handleLivePhotoSelection(_ itemProvider: NSItemProvider, at index: Int) {
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
                    self.addMediaLoadingView(for: image, at: index)
                }
                
                self.uploadImage(image, at: index)
            }
        }
    }
    
    private func handleVideoSelection(_ itemProvider: NSItemProvider, at index: Int) {
        itemProvider.loadFileRepresentation(forTypeIdentifier: UTType.movie.identifier) { [weak self] url, error in
            guard let self, error == nil, let url, let image = getFirstFrame(from: url) else { return }
            
            DispatchQueue.main.async {
                self.addMediaLoadingView(for: image, at: index)
            }
        }
        
        itemProvider.loadDataRepresentation(forTypeIdentifier: UTType.movie.identifier) { [weak self] data, error in
            guard let self, error == nil, let data else { return }
            self.uploadVideo(data, at: index)
        }
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
        presentPhotoPickerController()
    }
    
    private func presentPhotoPickerController() {
        var configuration = PHPickerConfiguration(photoLibrary: .shared())
        configuration.selectionLimit = 4
        configuration.preferredAssetRepresentationMode = .current
        let pickerViewController = PHPickerViewController(configuration: configuration)
        pickerViewController.delegate = self
        present(pickerViewController, animated: true)
    }
    
    func toolbarDidSelectExclamationmarkButton(_ toolbar: Toolbar) {
        composeView.spoilerTextField.isDescendant(of: composeView.stackView) ? removeSpoilerTextField() : addSpoilerTextField()
    }
    
    private func addSpoilerTextField() {
        composeView.spoilerTextField.delegate = self
        composeView.stackView.insertArrangedSubview(composeView.spoilerTextField, at: 0)
        
        UIViewPropertyAnimator.runningPropertyAnimator(
            withDuration: CATransaction.animationDuration(),
            delay: 0.0
        ) { [composeView] in
            composeView.spoilerTextField.alpha = 1.0
            composeView.spoilerTextField.isHidden = false
        }
    }
    
    private func removeSpoilerTextField() {
        UIViewPropertyAnimator.runningPropertyAnimator(
            withDuration: CATransaction.animationDuration(),
            delay: 0.0
        ) { [composeView] in
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

extension ComposeViewController: PHPickerViewControllerDelegate {
    
    func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
        handlePickerResults(results)
        dismiss(animated: true)
    }
    
    private func handlePickerResults(_ results: [PHPickerResult]) {
        selectedImagesCount += results.count
        composeView.toolbar.addPhotoButtonIsEnabled = selectedImagesCount < 4
        
        for (index, result) in results.enumerated() {
            let itemProvider = result.itemProvider
            
            if itemProvider.canLoadObject(ofClass: UIImage.self) {
                handleImageSelection(itemProvider, at: index)
            } else if itemProvider.canLoadObject(ofClass: PHLivePhoto.self) {
                handleLivePhotoSelection(itemProvider, at: index)
            } else if itemProvider.hasItemConformingToTypeIdentifier(UTType.movie.identifier) {
                handleVideoSelection(itemProvider, at: index)
            }
        }
    }
}
