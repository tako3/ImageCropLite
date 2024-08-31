// ScrollView.swift
//
// The MIT License (MIT)
// Copyright (c) 2024 Tako
//
// See LICENSE.md for license information.

import UIKit

final class ScrollView: UIScrollView {
    private(set) var imageView: UIImageView

    private static let minimumMargin: CGFloat = 16.0
    private var additionalInsets: UIEdgeInsets = .zero

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError() }

    init(image: UIImage, additionalInsets: UIEdgeInsets) {
        imageView = .init(image: image)
        self.additionalInsets = additionalInsets
        super.init(frame: .zero)
        imageView.frame = .init(origin: .zero, size: image.size)
        addSubview(imageView)
        translatesAutoresizingMaskIntoConstraints = false
        alwaysBounceVertical = true
        alwaysBounceHorizontal = true
        showsHorizontalScrollIndicator = false
        showsVerticalScrollIndicator = false
        contentInsetAdjustmentBehavior = .never
    }

    func contentPadding(toolbarPosition position: Toolbar.Position) -> UIEdgeInsets {
        let insets: UIEdgeInsets
        switch position {
        case .bottom:
            insets = .init(top: safeAreaInsets.top,
                           left: safeAreaInsets.left,
                           bottom: safeAreaInsets.bottom + Toolbar.toolbarHeightOrWidth,
                           right: safeAreaInsets.right)
        case .left:
            insets = .init(top: safeAreaInsets.top,
                           left: safeAreaInsets.left + Toolbar.toolbarHeightOrWidth,
                           bottom: safeAreaInsets.bottom,
                           right: safeAreaInsets.right)
        case .none:
            insets = safeAreaInsets
        }
        return insets + additionalInsets + Self.minimumMargin
    }
    /// Calculates the origin point on the image where the cropping start,
    /// based on the current position of the crop rect
    ///
    /// - Parameter cropRectOrigin: the origin of the crop rect
    /// - Returns: the corresponding origin point on the image, taking into account the scroll view's content offset.
    func calcCropOrigin(from cropRectOrigin: CGPoint) -> CGPoint {
        contentOffset + cropRectOrigin
    }
    /// Calculates the center point of the crop area on the image based on the
    /// cropping frame's origin and size.
    ///
    /// - Parameter cropRect: the rect to crop
    /// - Returns: the visible center point of the crop area on the image.
    func calcCropCenter(from cropRect: CGRect) -> CGPoint {
        contentOffset + cropRect.origin + .init(size: cropRect.size) / 2
    }
    /// Calculates crop rect origin that fits in the ceter of the bounds
    func calcCropRectOrigin(with cropRectSize: CGSize, toolbarPosition position: Toolbar.Position) -> CGPoint {
        let contentPadding = contentPadding(toolbarPosition: position)
        let width = bounds.size.width - (contentPadding.left + contentPadding.right)
        let height = bounds.size.height - (contentPadding.top + contentPadding.bottom)
        let originX: CGFloat
        let originY: CGFloat
        switch position {
        case .bottom:
            originX = (width - cropRectSize.width) / 2
            originY = (height - cropRectSize.height) / 2
        case .left:
            originX = (width - cropRectSize.width) / 2 + Toolbar.toolbarHeightOrWidth
            originY = (height - cropRectSize.height) / 2
        case .none:
            originX = (width - cropRectSize.width) / 2
            originY = (height - cropRectSize.height) / 2
        }
        return .init(x: floor(originX + contentPadding.left),
                     y: floor(originY + contentPadding.top))
    }
    /// Calculates a new crop rectangle and scale based on the current crop rectangle and
    /// the position of the crop toolbar.
    ///
    /// - Parameters:
    ///   - cropRect: the current crop rectangle.
    ///   - position: the position of the crop toolbar.
    /// - Returns: a tuple containing the calculated crop rectangle and the corresponding scale.
    func calcCropRectAndScale(from cropRect: CGRect,
                              position: Toolbar.Position) -> (cropRect: CGRect, scale: CGFloat) {
        let scale = calcScale(from: cropRect.size, position: position)
        let updatedCropSize = cropRect.size * scale
        let updatedCropOrigin = calcCropRectOrigin(with: updatedCropSize, toolbarPosition: position)
        return (.init(origin: updatedCropOrigin, size: updatedCropSize), scale)
    }

    func calcScale(from cropSize: CGSize, position: Toolbar.Position) -> CGFloat {
        let availableSize = availableContentSize(toolbarPosition: position)
        return min(availableSize.width / cropSize.width, availableSize.height / cropSize.height)
    }

    func updateContentInset(with cropRect: CGRect) {
        let size = bounds.size
        let top = cropRect.origin.y
        let bottom = size.height - (cropRect.origin.y + cropRect.height)
        let left = cropRect.origin.x
        let right = size.width - (cropRect.origin.x + cropRect.width)
        contentInset = .init(top: top, left: left, bottom: bottom, right: right)
    }

    func updateContentInsetAndMinZoomScale(with cropRect: CGRect, imageSize: CGSize) {
        updateMinMaxZoomScale(with: cropRect.size, imageSize: imageSize)
        updateContentInset(with: cropRect)
    }

    func updateCropRect(for aspectRatio: CGFloat, cropRect: CGRect,
                        imageHeight: CGFloat, toolbarPosition: Toolbar.Position) -> CGRect {
        let cropOrigin = cropRect.origin
        let cropSize = cropRect.size
        let padding = contentPadding(toolbarPosition: toolbarPosition)
        var updateRect = CGRect(
            x: cropOrigin.x,
            y: cropOrigin.y + (cropSize.height - (cropSize.width / aspectRatio)) / 2,
            width: cropSize.width,
            height: cropSize.width / aspectRatio
        )

        let isAtTopOrBottomEdge = updateRect.origin.y < padding.top ||
            updateRect.maxY >= (bounds.height - padding.bottom)

        let isBeyondContentBounds = contentOffset.y + updateRect.origin.y < 0 ||
            contentOffset.y + updateRect.maxY - imageHeight * zoomScale >= 0

        let scale: CGFloat
        if isAtTopOrBottomEdge {
            // zoom out
            let availableHeight = bounds.height - (padding.top + padding.bottom)
            let zoom = availableHeight / updateRect.height
            let zoomedSize = updateRect.size * zoom
            updateRect = .init(
                x: cropOrigin.x + (cropSize.width - zoomedSize.width) / 2,
                y: cropOrigin.y + (cropSize.height - zoomedSize.height) / 2,
                width: zoomedSize.width,
                height: zoomedSize.height
            )
            scale = max(updateRect.width / cropSize.width, updateRect.height / cropSize.height)
        } else if isBeyondContentBounds {
            scale = updateRect.height / cropRect.height
        } else {
            (updateRect, scale) = calcCropRectAndScale(from: updateRect, position: toolbarPosition)
        }

        if scale != 1 {
            UIView.animate(withDuration: 0.3, delay: 0, options: .curveEaseInOut) {
                self.zoomScale *= scale
            }
        }
        // do not put before animate; order matters
        updateContentInset(with: updateRect)

        return updateRect
    }

    func reset(cropRect: CGRect, zoomScale: CGFloat, contentOffset: CGPoint, imageSize: CGSize) {
        updateMinMaxZoomScale(with: cropRect.size, imageSize: imageSize)
        self.zoomScale = zoomScale
        self.contentOffset = contentOffset
        updateContentInset(with: cropRect)
    }

    func flip(image: UIImage, withCropRect cropRect: CGRect) {
        imageView.image = image
        let cropRectOriginX = cropRect.origin.x
        let cropRectWidth = cropRect.width
        let scaledImageSize = image.size * zoomScale
        contentOffset.x = scaledImageSize.width - (contentOffset.x + 2 * cropRectOriginX +
            cropRectWidth)
    }

    func rotate(withCurrentCropRect cropRect: CGRect, updatedCropRect: CGRect, scale: CGFloat,
                rotatedImage: UIImage) {
        let cropCenter = calcCropCenter(from: cropRect)
        let scaledImageSize = rotatedImage.size * zoomScale
        let contentOffset = CGPoint(
            x: cropCenter.y,
            y: scaledImageSize.height - cropCenter.x
        ) * scale - updatedCropRect.origin - .init(size: updatedCropRect.size) / 2
        let zoomScale = zoomScale * scale
        // set rotated image
        reset(image: rotatedImage)
        // reset
        reset(cropRect: updatedCropRect, zoomScale: zoomScale, contentOffset: contentOffset,
              imageSize: rotatedImage.size)
    }

    func animateZoomAndOffset(withCropRect cropRect: CGRect, updatedCropRect: CGRect, scale: CGFloat,
                              imageSize: CGSize) {
        let contentOffset = calcCropOrigin(from: cropRect.origin) * scale - updatedCropRect.origin
        let zoomScale = zoomScale * scale
        UIView.animate(withDuration: 0.3, delay: 0, options: .curveEaseInOut) {
            self.zoomScale = zoomScale
            self.contentOffset = contentOffset
        } completion: { _ in
            self.updateContentInsetAndMinZoomScale(with: updatedCropRect, imageSize: imageSize)
        }
    }
}

extension ScrollView {
    func reset(image: UIImage) {
        imageView.removeFromSuperview()
        zoomScale = 1
        contentSize = image.size
        // if just setting image to image view,
        // set zoom scale to 1 sometimes does not work,
        // to workaround this, re-create and add image view instead
        let imageView = UIImageView(image: image)
        imageView.frame = .init(origin: .zero, size: image.size)
        imageView.clipsToBounds = true
        imageView.contentMode = .topLeft
        addSubview(imageView)
        self.imageView = imageView
    }
}

extension ScrollView {
    private func availableContentSize(toolbarPosition position: Toolbar.Position) -> CGSize {
        let size = bounds.size
        let width: CGFloat
        let height: CGFloat
        let contentPadding = contentPadding(toolbarPosition: position)
        switch position {
        case .bottom:
            width = size.width - (contentPadding.left + contentPadding.right)
            height = size.height - (contentPadding.top + Toolbar.toolbarHeightOrWidth +
                contentPadding.bottom)
        case .left:
            width = size.width - (contentPadding.left + Toolbar.toolbarHeightOrWidth +
                contentPadding.right)
            height = size.height - (contentPadding.top + contentPadding.bottom)
        case .none:
            width = size.width - (contentPadding.left + contentPadding.right)
            height = size.height - (contentPadding.top + contentPadding.bottom)
        }
        return .init(width: width, height: height)
    }

    private func updateMinMaxZoomScale(with cropRectSize: CGSize, imageSize: CGSize) {
        let minZoomScale = max(cropRectSize.width / imageSize.width,
                               cropRectSize.height / imageSize.height)
        minimumZoomScale = minZoomScale
        maximumZoomScale = 15 * minZoomScale
    }
}
