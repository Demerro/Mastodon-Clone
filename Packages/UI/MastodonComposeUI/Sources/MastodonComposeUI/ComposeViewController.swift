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
import MastodonCoreUI

final class ComposeViewController: ViewController {
    
    private let composeView = ComposeView(frame: .zero)
    
    private var rightBarButtonItem: UIBarButtonItem!
    
    private var selectedImagesCount = 0
    
    private var mediaUploadingTasks = [UUID: Task<Void, Never>]()
    
    private var mediaLoadingViews = [UUID: (MediaLoadingView, UIButton)]()
    
    weak var delegate: (any Delegate)? = nil
    
    private let postStatusStore: PostStatusStore
    
    init(postStatusStore: PostStatusStore) {
        self.postStatusStore = postStatusStore
        super.init()
    }
    
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
        for (_, task) in mediaUploadingTasks {
            task.cancel()
        }
    }
}

extension ComposeViewController {
    
    private func configureNavigationBar() {
        title = "New Post"
        
        let leftBarButtonItem = UIBarButtonItem(title: "Cancel", primaryAction: UIAction { [unowned self] _ in
            presentConfirmationAlert()
        })
        leftBarButtonItem.tintColor = .systemRed
        navigationItem.leftBarButtonItem = leftBarButtonItem
        
        rightBarButtonItem = UIBarButtonItem(title: "Publish", primaryAction: UIAction { [unowned self] _ in
            uploadStatus()
        })
        rightBarButtonItem.isEnabled = false
        navigationItem.rightBarButtonItem = rightBarButtonItem
    }
    
    private func configureComposeView() {
        composeView.textView.delegate = self
        composeView.toolbar.delegate = self
    }
}

extension ComposeViewController {
    
    private func addMediaLoadingView(for image: UIImage, id: UUID) {
        let mediaLoadingView = createMediaLoadingView(with: image)
        composeView.stackView.addArrangedSubview(mediaLoadingView)

        let cancelButton = createCancelButton(forStorageId: id)
        composeView.scrollView.addSubview(cancelButton)
        
        NSLayoutConstraint.activate([
            mediaLoadingView.heightAnchor.constraint(equalToConstant: 200.0),
            cancelButton.centerXAnchor.constraint(equalTo: mediaLoadingView.trailingAnchor),
            cancelButton.centerYAnchor.constraint(equalTo: mediaLoadingView.topAnchor),
        ])
        composeView.stackView.layoutIfNeeded()
        
        mediaLoadingViews[id] = (mediaLoadingView, cancelButton)
    }
    
    private func createMediaLoadingView(with image: UIImage) -> MediaLoadingView {
        var configuration = MediaLoadingView.PreparationConfiguration()
        configuration.image = image
        let mediaLoadingView = MediaLoadingView(frame: .zero)
        mediaLoadingView.configuration = configuration
        return mediaLoadingView
    }
    
    private func createCancelButton(forStorageId id: UUID) -> UIButton {
        var configuration = UIButton.Configuration.borderless()
        configuration.image = UIImage(systemName: "minus.circle.fill")!
        configuration.preferredSymbolConfigurationForImage = .preferringMulticolor()
        
        let button = UIButton(configuration: configuration)
        button.translatesAutoresizingMaskIntoConstraints = false
        
        button.addAction(
            UIAction { [unowned self] _ in
                if let mediaUploadingTask = mediaUploadingTasks[id] {
                    if mediaUploadingTask.isCancelled {
                        Task { try await postStatusStore.removeMediaAttachment(withStorageId: id) }
                    } else {
                        mediaUploadingTask.cancel()
                        mediaUploadingTasks.removeValue(forKey: id)
                    }
                } else {
                    Task { try await postStatusStore.removeMediaAttachment(withStorageId: id) }
                }
                removeMediaLoadingView(with: id)
            },
            for: .touchUpInside
        )
        
        return button
    }

    private func removeMediaLoadingView(with id: UUID) {
        selectedImagesCount -= 1
        composeView.toolbar.addPhotoButtonIsEnabled = selectedImagesCount < 4
        rightBarButtonItem.isEnabled = !postStatusStore.mediaAttachments.isEmpty || !composeView.textView.text.isEmpty
        
        guard let (mediaLoadingView, cancelButton) = mediaLoadingViews[id] else {
            assertionFailure("No media loading view found for storage id \(id)")
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
    
    private func presentErrorAlert() {
        let alertController = UIAlertController(title: "An error has occurred", message: "Try again later.", preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: "Ok", style: .cancel))
        present(alertController, animated: true)
    }
    
    private func presentConfirmationAlert() {
        let alertController = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        alertController.addAction(UIAlertAction(title: "Discard", style: .destructive, handler: { [unowned self] _ in
            presentingViewController?.dismiss(animated: true)
        }))
        alertController.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        present(alertController, animated: true)
    }
}

extension ComposeViewController {
    
    private func uploadImage(_ image: UIImage, id: UUID) {
        mediaUploadingTasks[id] = Task {
            guard let data = image.jpegData(compressionQuality: 1.0) else {
                assertionFailure("Failed to convert image to JPEG data")
                return
            }
            do {
                try await postStatusStore.uploadMedia(data: data, fileName: "\(UUID().uuidString).jpeg", mimeType: "image/jpeg", storageId: id)
                await MainActor.run {
                    mediaLoadingViews[id]?.0.configuration = MediaLoadingView.LoadedConfiguration()
                    rightBarButtonItem.isEnabled = true
                }
            } catch let mastodonError as MastodonError {
                if !isCancellationError(mastodonError) {
                    presentErrorAlert()
                }
                removeMediaLoadingView(with: id)
            } catch {
                preconditionFailure("Unexpected error during image upload: \(error)")
            }
        }
    }
    
    private func uploadVideo(_ videoData: Data, id: UUID) {
        mediaUploadingTasks[id] = Task {
            do {
                try await postStatusStore.uploadMedia(data: videoData, fileName: "\(UUID().uuidString).mp4", mimeType: "video/mp4", storageId: id)
                await MainActor.run {
                    mediaLoadingViews[id]?.0.configuration = MediaLoadingView.LoadedConfiguration()
                    rightBarButtonItem.isEnabled = true
                }
            } catch let mastodonError as MastodonError {
                if !isCancellationError(mastodonError) {
                    presentErrorAlert()
                }
                removeMediaLoadingView(with: id)
            } catch {
                preconditionFailure("Unexpected error during video upload: \(error)")
            }
        }
    }
    
    private func isCancellationError(_ mastodonError: MastodonError) -> Bool {
        if case let .network(networkError) = mastodonError,
                  case let .clientOrTransportSpecific(urlError) = networkError,
                  urlError.code == URLError.cancelled {
            true
        } else {
            false
        }
    }
    
    private func uploadStatus() {
        rightBarButtonItem.isEnabled = false
        composeView.textView.resignFirstResponder()
        Task { [weak self] in
            guard let self else { return }
            presentLoadingToast(text: "Publishing post...")
            
            let visibility: Status.Visibility = switch composeView.toolbar.visibilityButtonState {
            case .public: .public
            case .followersOnly: .private
            case .unlisted: .unlisted
            }
            do {
                guard let status = try await postStatusStore.uploadStatus(status: composeView.textView.text, spoilerText: composeView.spoilerTextField.text.unsafelyUnwrapped, visibility: visibility) else {
                    rightBarButtonItem.isEnabled = true
                    dismissToast()
                    return
                }
                dismissToast()
                presentToast(text: "Post published successfully", image: UIImage(systemName: "checkmark.circle.fill")!)
                RunLoop.main.add(Timer(timeInterval: 2.0, repeats: false) { _ in
                    self.dismissToast()
                }, forMode: .common)
                delegate?.composeViewController(self, didUploadStatus: status)
            } catch {
                dismissToast()
                presentErrorAlert()
            }
            rightBarButtonItem.isEnabled = true
        }
    }
}

extension ComposeViewController {
    
    private func handleImageSelection(_ itemProvider: NSItemProvider, with id: UUID) {
        itemProvider.loadObject(ofClass: UIImage.self) { [weak self] image, error in
            guard let self, error == nil, let image = image as? UIImage else { return }
            DispatchQueue.main.async {
                self.addMediaLoadingView(for: image, id: id)
            }
            self.uploadImage(image, id: id)
        }
    }
    
    private func handleLivePhotoSelection(_ itemProvider: NSItemProvider, with id: UUID) {
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
                    self.addMediaLoadingView(for: image, id: id)
                }
                
                self.uploadImage(image, id: id)
            }
        }
    }
    
    private func handleVideoSelection(_ itemProvider: NSItemProvider, with id: UUID) {
        itemProvider.loadFileRepresentation(forTypeIdentifier: UTType.movie.identifier) { [weak self] url, error in
            guard let self, error == nil, let url, let image = getFirstFrame(from: url) else { return }
            
            DispatchQueue.main.async {
                self.addMediaLoadingView(for: image, id: id)
            }
        }
        
        itemProvider.loadDataRepresentation(forTypeIdentifier: UTType.movie.identifier) { [weak self] data, error in
            guard let self, error == nil, let data else { return }
            self.uploadVideo(data, id: id)
        }
    }
}

extension ComposeViewController: UITextViewDelegate {
    
    func textViewDidChange(_ textView: UITextView) {
        let composeTextView = textView as! ComposeTextView
        composeView.toolbar.symbolCount = Constants.maxPostSymbolsCount - composeTextView.text.count
        composeTextView.placeholderLabel.isHidden = !composeTextView.text.isEmpty
        rightBarButtonItem.isEnabled = !postStatusStore.mediaAttachments.isEmpty || !composeTextView.text.isEmpty
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
        assert(1...4 ~= selectedImagesCount)
        var configuration = PHPickerConfiguration(photoLibrary: .shared())
        configuration.selectionLimit = Constants.maxPostImageAttachmentCount - selectedImagesCount
        configuration.preferredAssetRepresentationMode = .current
        let pickerViewController = PHPickerViewController(configuration: configuration)
        pickerViewController.delegate = self
        present(pickerViewController, animated: true)
    }
    
    func toolbarDidSelectExclamationmarkButton(_ toolbar: Toolbar) {
        composeView.spoilerTextField.isDescendant(of: composeView.stackView) ? removeSpoilerTextField() : addSpoilerTextField()
        
        func addSpoilerTextField() {
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
        
        func removeSpoilerTextField() {
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
}

extension ComposeViewController: PHPickerViewControllerDelegate {
    
    func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
        handlePickerResults(results)
        dismiss(animated: true)
    }
    
    private func handlePickerResults(_ results: [PHPickerResult]) {
        selectedImagesCount += results.count
        composeView.toolbar.addPhotoButtonIsEnabled = selectedImagesCount < 4
        
        for result in results {
            let storageId = UUID()
            let itemProvider = result.itemProvider
            if itemProvider.canLoadObject(ofClass: UIImage.self) {
                handleImageSelection(itemProvider, with: storageId)
            } else if itemProvider.canLoadObject(ofClass: PHLivePhoto.self) {
                handleLivePhotoSelection(itemProvider, with: storageId)
            } else if itemProvider.hasItemConformingToTypeIdentifier(UTType.movie.identifier) {
                handleVideoSelection(itemProvider, with: storageId)
            }
        }
    }
}

extension ComposeViewController {
    
    @MainActor
    protocol Delegate: AnyObject {
        func composeViewController(_ viewController: ComposeViewController, didUploadStatus status: Status)
    }
}
