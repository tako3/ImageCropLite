# ImageCropLite

An image crop library for iOS/iPadOS, similar to the Photos.app.

<p>
<img src="https://github.com/tako3/ImageCropLite/blob/main/ss/ss01.gif" style="width: 280px;" />
</p>
<p>
<img src="https://github.com/tako3/ImageCropLite/blob/main/ss/ss01.png" style="width: 280px;" />
<img src="https://github.com/tako3/ImageCropLite/blob/main/ss/ss02.png" style="width: 280px;" />
</p>

# Features

- Compatible with both iOS and iPadOS.
- Supports only rectangular shape cropping.
- Rotate images by 90 degrees.
- Flip images vertically.
- Clamp the crop box to a selected aspect ratio.
- Pinch to zoom in/out.

# System requirements

- iOS/iPadOS 16.0  or above

# Installation

Swift Package Manager

1. In Xcode, select “File” → “Add Packages Dependencies...”
2. Enter https://github.com/tako3/ImageCropLite.git

# Usage

```swift
import ImageCropLite

let image: UIImage = // Load image
let cropViewController = CropViewController(cropViewConfiguration: .init(image: image))
// Set edit end callback
// Alternatively, set `didFinishEditingWithoutImage` if no cropped image is needed
cropViewController.didFinishEditing = { cropViewController, image, editInfo in
    // 'image' is the cropped image
    // 'editInfo' has edited information such as cropped origin, size, transformation, etc
    // Dismiss or pop depending on the current presentation
    cropViewController.dismiss(animated: true)
}
// Set cancel callback
cropViewController.didCancel = { cropViewController in
    // Dismiss or pop
    cropViewController.dismiss(animated: true)
}
// present
present(cropViewController, animated: true, completion: nil)
```

# License

ImageCropLite is licensed under the MIT License, please see [LICENSE.md](https://github.com/tako3/ImageCropLite/blob/main/LICENSE.md) for license information.
