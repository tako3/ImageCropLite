// AnimationView.swift
//
// The MIT License (MIT)
// Copyright (c) 2024 Tako
//
// See LICENSE.md for license information.

import UIKit

final class AnimationView: UIView {
    private let imageView: UIImageView

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError() }

    init() {
        imageView = .init(frame: .zero)
        super.init(frame: .zero)
        translatesAutoresizingMaskIntoConstraints = false
        addSubview(imageView)
        backgroundColor = .black
        isHidden = true
        imageView.contentMode = .topLeft
    }

    func performFlipAnimation(image: UIImage, frame: CGRect,
                              endTransform: @escaping () -> Void,
                              completion: @escaping () -> Void) {
        animate(image: image, frame: frame, transform: .init(scaleX: -1, y: 1),
                endTransform: endTransform, completion: completion)
    }

    func performRotateAnimation(image: UIImage, frame: CGRect, scale: CGFloat,
                                endTransform: @escaping () -> Void,
                                completion: @escaping () -> Void) {
        let rotation = CGAffineTransform(rotationAngle: -.pi / 2)
        let transform = rotation.concatenating(.init(scaleX: scale, y: scale))
        animate(image: image, frame: frame, transform: transform,
                endTransform: endTransform, completion: completion)
    }

    private func animate(image: UIImage, frame: CGRect, transform: CGAffineTransform,
                         endTransform: @escaping () -> Void,
                         completion: @escaping () -> Void) {
        imageView.transform = .identity
        imageView.image = image
        imageView.frame = frame
        isHidden = false
        backgroundColor = backgroundColor?.withAlphaComponent(0.0)
        // set alpha to 1
        UIView.animate(withDuration: 0.08, delay: 0, options: .curveEaseIn) {
            self.backgroundColor = self.backgroundColor?.withAlphaComponent(1.0)
        } completion: { _ in
            // apply transform
            UIView.animate(withDuration: 0.35, delay: 0, options: .curveEaseInOut) {
                self.imageView.transform = transform
            } completion: { _ in
                // call completion before setting the view's alpha to 0;
                // this avoids revealing the underlying view.
                endTransform()
                // hide animation view
                self.hideView(completion: completion)
            }
        }
    }
    // set alpha back to 0 and hide the view
    private func hideView(completion: @escaping () -> Void) {
        UIView.animate(withDuration: 0.12, delay: 0, options: .curveEaseOut) {
            self.backgroundColor = self.backgroundColor?.withAlphaComponent(0.0)
        } completion: { _ in
            self.isHidden = true
            self.imageView.image = nil
            self.imageView.transform = .identity
            completion()
        }
    }
}
