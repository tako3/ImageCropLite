// Extensions.swift
//
// The MIT License (MIT)
// Copyright (c) 2024 Tako
//
// See LICENSE.md for license information.

import CoreImage
import UIKit

func +(lhs: CGPoint, rhs: CGPoint) -> CGPoint {
    .init(x: lhs.x + rhs.x, y: lhs.y + rhs.y)
}

func -(lhs: CGPoint, rhs: CGPoint) -> CGPoint {
    lhs + -rhs
}

func +=(lhs: inout CGPoint, rhs: CGPoint) {
    lhs = lhs + rhs
}

prefix func -(point: CGPoint) -> CGPoint {
    .init(x: -point.x, y: -point.y)
}

func -=(lhs: inout CGPoint, rhs: CGPoint) {
    lhs += -rhs
}

func *(lhs: CGPoint, rhs: CGFloat) -> CGPoint {
    .init(x: lhs.x * rhs, y: lhs.y * rhs)
}

func /(lhs: CGPoint, rhs: CGFloat) -> CGPoint {
    .init(x: lhs.x / rhs, y: lhs.y / rhs)
}

func -(lhs: CGSize, rhs: CGSize) -> CGSize {
    .init(width: lhs.width - rhs.width, height: lhs.height - rhs.height)
}

func *(lhs: CGSize, rhs: CGFloat) -> CGSize {
    .init(width: lhs.width * rhs, height: lhs.height * rhs)
}

func /(lhs: CGSize, rhs: CGFloat) -> CGSize {
    lhs * (1.0 / rhs)
}

func +(lhs: UIEdgeInsets, rhs: UIEdgeInsets) -> UIEdgeInsets {
    .init(top: lhs.top + rhs.top, left: lhs.left + rhs.left,
          bottom: lhs.bottom + rhs.bottom, right: lhs.right + rhs.right)
}

func +(lhs: UIEdgeInsets, rhs: CGFloat) -> UIEdgeInsets {
    .init(top: lhs.top + rhs, left: lhs.left + rhs,
          bottom: lhs.bottom + rhs, right: lhs.right + rhs)
}

extension CGFloat {
    /// Rounds the CGFloat value and clamps it between min and max.
    /// - Parameters:
    ///   - min: The minimum value for clamping
    ///   - max: The maximum value for clamping
    mutating func roundAndClamp(min minValue: CGFloat, max maxValue: CGFloat) {
        self = .minimum(.maximum(rounded(), minValue), maxValue)
    }
}

extension CGPoint {
    /// A convenient initializer to create a `CGPoint` from a `CGSize`.
    /// The width of the `CGSize` is used as the x-coordinate and the height as the y-coordinate.
    /// - Parameter size: The `CGSize` to convert into a `CGPoint`.
    /// - Returns: A new `CGPoint` with x-coordinate set to the width and y-coordinate set to
    ///            the height of the provided `CGSize`.
    init(size: CGSize) {
        self = .init(x: size.width, y: size.height)
    }
}

extension CGRect {
    /// Checks if the rectangle is valid within the given image size.
    ///
    /// A valid rectangle must have its origin within the image bounds and must have positive dimensions that do not exceed the image size.
    /// - Parameter size: The size of the image to check against.
    /// - Returns: `true` if the rectangle is valid within the image size; otherwise, `false`.
    func isValid(in size: CGSize) -> Bool {
        (origin.x >= 0) && (origin.x < size.width) && (origin.y >= 0) &&
            (origin.y < size.height) && (size.width > 0) && (size.width <= size.width) &&
            (size.height > 0) && (size.height <= size.height)
    }
}

extension CABasicAnimation {
    convenience init(opacityAnimation currentOpacity: Float, visible: Bool, duration: TimeInterval = 0.25) {
        self.init(keyPath: "opacity")
        fromValue = currentOpacity
        toValue = visible ? 1.0 : 0.0
        self.duration = duration
        timingFunction = CAMediaTimingFunction(name: visible ? .easeIn : .easeOut)
        isRemovedOnCompletion = false
    }

    convenience init(pathAnimation path: CGPath, duration: TimeInterval = 0.25) {
        self.init(keyPath: "path")
        toValue = path
        self.duration = duration
        timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
        fillMode = .forwards
        isRemovedOnCompletion = false
    }
}

extension CGAffineTransform {
    /// Initializes a `CGAffineTransform` that correctly adjusts the image's orientation.
    ///
    /// This initializer creates a transformation that adjusts an image's orientation to `.up` (the default, upright orientation) based on its current orientation.
    /// The transformation includes necessary translations, rotations, and scaling operations.
    ///
    /// - Parameter orientation: The current orientation of the image, represented by `UIImage.Orientation`.
    /// - Returns: A `CGAffineTransform` that, when applied to the image, reorients it to `.up`
    ///            while preserving its visual appearance.
    public init(orientation: UIImage.Orientation) {
        self = switch orientation {
        case .up: .identity
        case .down: .init(rotationAngle: .pi)
        case .left: .init(rotationAngle: .pi / 2)
        case .right: .init(rotationAngle: -.pi / 2)
        case .upMirrored: .init(scaleX: -1, y: 1)
        case .downMirrored: .init(scaleX: 1, y: -1)
        case .leftMirrored: .init(scaleX: -1, y: 1).rotated(by: -.pi / 2)
        case .rightMirrored: .init(scaleX: -1, y: 1).rotated(by: .pi / 2)
        @unknown default: .identity
        }
    }
}

extension UIView {
    var screenScale: CGFloat {
        window?.windowScene?.screen.scale ?? 1
    }

    func add(subview: UIView, withInsets insets: UIEdgeInsets = .zero) {
        subview.translatesAutoresizingMaskIntoConstraints = false
        addSubview(subview)
        NSLayoutConstraint.activate([
            subview.topAnchor.constraint(equalTo: topAnchor, constant: insets.top),
            subview.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -insets.bottom),
            subview.leadingAnchor.constraint(equalTo: leadingAnchor, constant: insets.left),
            subview.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -insets.right),
        ])
    }
}

extension UIImage {
    convenience init(ciImage image: CIImage, scale: CGFloat, orientation: UIImage.Orientation) {
        let context = CIContext(options: nil)
        let cgImage = context.createCGImage(image, from: image.extent)
        self.init(cgImage: cgImage!, scale: scale, orientation: orientation)
    }
}

extension UIImageView {
    func reset(image: UIImage) {
        self.image = image
        frame = .init(origin: .zero, size: image.size)
    }
}

extension UIPanGestureRecognizer.State: CustomDebugStringConvertible {
    public var debugDescription: String {
        switch self {
        case .possible:
            "possible"
        case .began:
            "began"
        case .changed:
            "changed"
        case .ended:
            "ended"
        case .cancelled:
            "cancelled"
        case .failed:
            "failed"
        @unknown default:
            "unknown"
        }
    }
}
