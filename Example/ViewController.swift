import UIKit

import ImageCropLite

final class ViewController: UIViewController, UIImagePickerControllerDelegate,
                            UINavigationControllerDelegate {
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var selectImageButton: UIButton! {
        didSet {
            selectImageButton.setTitle(.init(localized: "Select Image"), for: .normal)
        }
    }
    @IBOutlet weak var editButton: UIButton! {
        didSet {
            editButton.setTitle(.init(localized: "Edit"), for: .normal)
        }
    }

    private var sourceImage: UIImage?
    private var cropRect: CGRect = .zero
    private var cropTransform: ImageFilterTransform = .init()
    private var aspectRatio: AspectRatio = .freeform

    @IBAction func selectImageTap(_ sender: UIButton) {
        let picker = UIImagePickerController()
        picker.sourceType = .photoLibrary
        picker.allowsEditing = false
        picker.delegate = self
        present(picker, animated: true, completion: nil)
    }

    @IBAction func editTap(_ sender: UIButton) {
        guard let sourceImage else {
            return
        }

        let vc = CropViewController(
            cropViewConfiguration: .init(
                image: sourceImage,
                cropRect: cropRect,
                transform: cropTransform,
                aspectRatio: aspectRatio
            ),
            navigationBarConfiguration: .init(
                showCancelButton: true,
                showDoneButton: true
            ),
            toolbarConfiguration: .init(
                showCancelButton: false,
                showDoneButton: false
            )
        )

        vc.didFinishEditing = { [weak self] vc, image, editInfo in
            self?.imageView.image = image
            self?.cropRect = editInfo.rect
            self?.cropTransform = editInfo.transform
            self?.aspectRatio = editInfo.aspectRatio
            vc.navigationController?.popViewController(animated: true)
        }

        vc.didCancel = { vc in
            vc.navigationController?.popViewController(animated: true)
        }
        // present with push
        navigationController?.pushViewController(vc, animated: true)
    }

    func imagePickerController(_ picker: UIImagePickerController,
                               didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
        guard let image = (info[.originalImage] as? UIImage) else {
            return
        }

        picker.dismiss(animated: true) { [weak self] in
            self?.present(image: image)
        }
    }

    private func present(image: UIImage) {
        let cropViewController = CropViewController(
            cropViewConfiguration: .init(image: image),
            toolbarConfiguration: .init(
                cancelButtonForegroundColor: .systemBlue,
                doneButtonForegroundColor: .systemBlue
            )
        )
        // set `didFinishEditing` or `didFinishEditingWithoutImage`
        cropViewController.didFinishEditing = { [weak self] vc, image, editInfo in
            self?.imageView.image = image
            self?.cropRect = editInfo.rect
            self?.cropTransform = editInfo.transform
            self?.aspectRatio = editInfo.aspectRatio
            vc.dismiss(animated: true)
        }

        cropViewController.didCancel = { [weak self] vc in
            self?.sourceImage = nil
            vc.dismiss(animated: true)
        }
        // present modally
        cropViewController.modalPresentationStyle = .fullScreen
        present(cropViewController, animated: true) { [weak self] in
            self?.sourceImage = image
        }
    }
}
