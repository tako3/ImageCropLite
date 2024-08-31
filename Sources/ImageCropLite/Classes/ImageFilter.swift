// ImageFilter.swift
//
// The MIT License (MIT)
// Copyright (c) 2024 Tako
//
// See LICENSE.md for license information.

import CoreImage
import UIKit

public struct ImageFilterTransform: Equatable, Sendable {
    /// Actual affine transform that applied to the image
    public private(set) var value: CGAffineTransform

    public var isIdentity: Bool { value.isIdentity }

    public init() {
        value = .identity
    }
    /// Applies a 90-degree counter-clockwise rotation
    public mutating func rotate() {
        value = value.concatenating(.init(rotationAngle: .pi / 2))
    }
    /// Applies horizontal flip transformation
    public mutating func flip() {
        value = value.concatenating(.init(scaleX: -1, y: 1))
    }
    /// Reset to identity
    public mutating func reset() {
        value = .identity
    }
}

extension ImageFilterTransform: CustomDebugStringConvertible {
    public var debugDescription: String {
        """
        |\(String(format: "% 2.2f", value.a)), \(String(format: "% 2.2f", value.b)),  0|
        |\(String(format: "% 2.2f", value.c)), \(String(format: "% 2.2f", value.d)),  0|
        |\(String(format: "% 2.2f", value.tx)), \(String(format: "% 2.2f", value.ty)),  1|
        """
    }
}

public final class ImageFilter {
    public var isIdentity: Bool { transform.isIdentity }
    public private(set) var transform: ImageFilterTransform

    private let filter: CIFilter = .init(name: "CIAffineTransform")!
    private let sourceImage: CIImage
    private let sourceImageScale: CGFloat
    // Transform to the source image's orientation to up
    private let orientationTransform: CGAffineTransform

    public init(image: UIImage, transform: ImageFilterTransform) {
        self.transform = transform
        sourceImage = CIImage(image: image)!
        sourceImageScale = image.scale
        orientationTransform = .init(orientation: image.imageOrientation)
        filter.setValue(sourceImage, forKey: kCIInputImageKey)
    }
    /// Returns the size of the transformed image in points.
    /// - Parameter screenScale: The scale factor of the screen. Default is 1.
    /// - Returns: The image size in points. If `screenScale` is 1, the size is returned in pixels.
    public func imageSize(screenScale scale: CGFloat = 1) -> CGSize {
        // Apply transform to image size; size is in pixels so round to the nearest pixel
        // then devide by screen scale
        let size = CGSizeApplyAffineTransform(
            sourceImage.extent.size,
            orientationTransform.concatenating(transform.value)
        )
        return .init(width: abs(size.width).rounded() / scale,
                     height: abs(size.height).rounded() / scale)
    }

    @discardableResult
    public func flip() -> Self {
        transform.flip()
        return self
    }

    @discardableResult
    public func reset() -> Self {
        transform.reset()
        return self
    }

    @discardableResult
    public func rotate() -> Self {
        transform.rotate()
        return self
    }

    public func transformedImage(screenScale scale: CGFloat) -> UIImage {
        let output = cropImage(cropRect: .init(origin: .zero, size: imageSize()))
        return .init(ciImage: output, scale: scale, orientation: .up)
    }
    /// Clamps the current crop rect's origin and size to the nearest pixel,
    /// considering the zoom and screen scale factors.
    /// - Parameters:
    ///   - cropOrigin: The origin point of the crop rect in point.
    ///   - cropSize: The size of the crop rect in point.
    ///   - zoomScale: The zoom scale of the image.
    ///   - screenScale: The natural scale factor associated with the screen.
    /// - Returns: A CGRect representing the clamped crop rect in pixel coordinates.
    public func clampCropRect(cropOrigin: CGPoint, cropSize: CGSize, zoomScale: CGFloat, screenScale: CGFloat) -> CGRect {
        let imgSize = imageSize()
        // If image size is smaller than the screen scale, clamp size to image size.
        let adjustedScreenScale = min(imgSize.width, imgSize.height, screenScale)
        // Map origin to pixel coordinates.
        // Then round and clamp; ensure at least 1 point (screen scale) size to crop.
        var clampedOrigin = cropOrigin * adjustedScreenScale / zoomScale
        clampedOrigin.x.roundAndClamp(min: 0, max: imgSize.width - adjustedScreenScale)
        clampedOrigin.y.roundAndClamp(min: 0, max: imgSize.height - adjustedScreenScale)
        // Map size to pixel coordinates.
        var clampedSize = cropSize * adjustedScreenScale / zoomScale
        clampedSize.width.roundAndClamp(min: adjustedScreenScale, max: imgSize.width)
        clampedSize.height.roundAndClamp(min: adjustedScreenScale, max: imgSize.height)
        return .init(origin: clampedOrigin, size: clampedSize)
    }

    public func createAnimationImage(cropOrigin: CGPoint, cropSize: CGSize,
                                     zoomScale: CGFloat, screenScale: CGFloat) -> UIImage {
        let cropRect = clampCropRect(cropOrigin: cropOrigin, cropSize: cropSize,
                                     zoomScale: zoomScale, screenScale: screenScale)
        let output = cropImage(cropRect: cropRect).transformed(by: .init(scaleX: zoomScale, y: zoomScale))
        return .init(ciImage: output, scale: screenScale, orientation: .up)
    }

    public func createCroppedImage(cropRect: CGRect) -> UIImage {
        let output = cropImage(cropRect: cropRect)
        return .init(ciImage: output, scale: sourceImageScale, orientation: .up)
    }

    private func cropImage(cropRect: CGRect) -> CIImage {
        // Get output size using transform * image size instead of
        // filter.outputImage.extent.size since it is easier.
        let outputSize = imageSize()
        // Move image center (image.width / 2, image.height / 2) to (0, 0)
        let sourceSize = sourceImage.extent.size
        let toCenter = CGAffineTransform(
            translationX: -sourceSize.width / 2, y: -sourceSize.height / 2
        )
        filter.setValue(
            toCenter.concatenating(orientationTransform.concatenating(transform.value)),
            forKey: kCIInputTransformKey
        )
        // Convert y-coordinate origin from top-left to bottom-left
        var targetRect = cropRect
        targetRect.origin.y = outputSize.height - cropRect.maxY
        // Move back where origin is the bottom left corner
        let toOrigin = CGAffineTransform(
            translationX: outputSize.width / 2, y: outputSize.height / 2
        )
        return filter.outputImage!.transformed(by: toOrigin).cropped(to: targetRect)
    }
}
