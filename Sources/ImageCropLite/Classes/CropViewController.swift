// CropViewController.swift
//
// The MIT License (MIT)
// Copyright (c) 2024 Tako
//
// See LICENSE.md for license information.

import UIKit

/// Contains information about the current crop editing session.
public struct CropEditInfo: Equatable, Sendable {
    /// The rectangle representing the cropped area in the transformed image
    /// coordinate space in pixel.  Top left corner is the origin.
    public let rect: CGRect
    /// The transformation applied to the image during cropping,
    /// such as flipping or rotation.
    public let transform: ImageFilterTransform
    /// The aspect ratio currently selected for cropping.
    public let aspectRatio: AspectRatio
    /// The current scale factor applied to the image
    public let zoomScale: CGFloat
}
/// A closure type that is called when the user confirms their crop selection.
///
/// - Parameters:
///   - cropViewController: The `CropViewController` that is currently presented.
///   - croppedImage: The resulting `UIImage` after cropping.
///   - cropEditInfo: The current crop editing information.
///
/// After handling this closure, remember to dismiss or pop the view controller
/// from the navigation stack.
public typealias FinishEditingHandler = (CropViewController,
                                         UIImage,
                                         CropEditInfo) -> Void
/// A closure type that is called when the user confirms their crop selection
/// without performing actual cropping.
///
/// - Parameters:
///   - cropViewController: The `CropViewController` that is currently presented.
///   - cropEditInfo: The current crop editing information.
///
/// Remember to dismiss or pop the view controller from the navigation stack after
/// handling this.
public typealias FinishEditingHandlerWithoutImage = (CropViewController,
                                                     CropEditInfo) -> Void
/// A closure type that is called when the user cancels the crop.
///
/// - parameter cropViewController: The currently presented crop view controller.
///
/// Remember to dismiss or pop the view controller from the navigation stack after
/// handling this.
public typealias CancelHandler = (CropViewController) -> Void

public final class CropViewController: UIViewController, UIGestureRecognizerDelegate {
    override public var prefersStatusBarHidden: Bool {
        isStatusBarHidden
    }

    override public var preferredStatusBarStyle: UIStatusBarStyle {
        statusBarStyle
    }

    override public var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        interfaceOrientations
    }

    public var didFinishEditing: FinishEditingHandler?
    public var didFinishEditingWithoutImage: FinishEditingHandlerWithoutImage?
    public var didCancel: CancelHandler?
    // a view that covers the screen during interface orientation changes
    // to prevent poor-quality animations
    private let transitionCoverView: UIVisualEffectView = .init(
        effect: UIBlurEffect(style: .systemThinMaterialDark)
    )
    private let animationView: AnimationView = .init()
    private let overlayView: OverlayView = .init()
    private let scrollView: ScrollView
    private let toolbar: Toolbar?
    private let imageFilter: ImageFilter
    private let initialCropRect: CGRect
    private let navigationBarConfiguration: CropNavigationBarConfiguration
    private let isStatusBarHidden: Bool
    private let statusBarStyle: UIStatusBarStyle
    private let interfaceOrientations: UIInterfaceOrientationMask

    private(set) var aspectRatio: AspectRatio
    private var toolbarPosition: Toolbar.Position = .bottom
    private var didSetImage: Bool = false
    private var isImageAnimating: Bool = false
    private var gridGestureEndTask: Task<Void, Never>?
    private var isGridGestureEndTaskRunning: Bool = false
    private var rescheduleGridGestureEnd: Bool = false
    private var regularConstraints: [NSLayoutConstraint] = []
    private var compactConstraints: [NSLayoutConstraint] = []

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError() }

    /// - Parameters:
    ///   - cropViewConfiguration: crop view configuration
    ///   - navigationBarConfiguration: navigation bar configuration
    ///   - toolbarConfiguration: toolbar configuration
    public init(cropViewConfiguration configuration: CropViewConfiguration,
                navigationBarConfiguration: CropNavigationBarConfiguration = .init(),
                toolbarConfiguration: CropToolbarConfiguration = .init()) {
        imageFilter = .init(image: configuration.image,
                            transform: configuration.transform)
        scrollView = .init(image: configuration.image,
                           additionalInsets: configuration.additionalInsets)
        if toolbarConfiguration.showToolbar {
            toolbar = .init(configuration: toolbarConfiguration,
                            aspectRatio: configuration.aspectRatio)
        } else {
            toolbar = nil
            toolbarPosition = .none
        }
        aspectRatio = configuration.aspectRatio
        initialCropRect = configuration.cropRect
        self.navigationBarConfiguration = navigationBarConfiguration
        isStatusBarHidden = configuration.isStatusBarHidden
        statusBarStyle = configuration.statusBarStyle
        interfaceOrientations = configuration.interfaceOrientations
        super.init(nibName: nil, bundle: nil)
        if toolbar != nil {
            toolbarPosition = traitCollection.verticalSizeClass == .compact ? .left : .bottom
        }
    }

    override public func viewDidLoad() {
        super.viewDidLoad()
        configureNavigationBarItems()
        configureSubviews()
    }

    private func configureNavigationBarItems() {
        if navigationBarConfiguration.showCancelButton {
            navigationItem.leftBarButtonItem = .init(
                image: .init(systemName: navigationBarConfiguration.cancelSystemName),
                primaryAction: .init { [weak self] _ in
                    self?.cancelDidTap()
                }
            )
        }
        navigationItem.leftBarButtonItem?.tintColor = navigationBarConfiguration.cancelTintColor

        if navigationBarConfiguration.showDoneButton {
            navigationItem.rightBarButtonItem = .init(
                image: .init(systemName: "checkmark.circle.fill"),
                primaryAction: .init { [weak self] _ in
                    self?.doneDidTap()
                }
            )
        }
        navigationItem.rightBarButtonItem?.tintColor = navigationBarConfiguration.doneTintColor
    }

    override public func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        if !didSetImage {
            setupImage()
            didSetImage = true
        }
    }

    override public func viewWillTransition(to size: CGSize,
                                            with coordinator: any UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        if !isForeground { return }

        overlayView.isHidden = true
        transitionCoverView.isHidden = false
        coordinator.animate(alongsideTransition: nil) {
            [contentOffset = scrollView.contentOffset] _ in
            self.handleViewChange(currentContentOffset: contentOffset)
            self.overlayView.isHidden = false
            UIView.animate(withDuration: 0.2) {
                self.transitionCoverView.alpha = 0
            } completion: { _ in
                self.transitionCoverView.alpha = 1
                self.transitionCoverView.isHidden = true
            }
        }
    }

    override public func willTransition(to newCollection: UITraitCollection,
                                        with coordinator: any UIViewControllerTransitionCoordinator) {
        super.willTransition(to: newCollection, with: coordinator)
        if !isForeground { return }

        if toolbar != nil {
            toolbarPosition = newCollection.verticalSizeClass == .compact ? .left : .bottom
        }

        coordinator.animate { [currentVerticalSizeClass = traitCollection.verticalSizeClass] _ in
            guard let toolbar = self.toolbar else {
                return
            }

            switch (currentVerticalSizeClass, newCollection.verticalSizeClass) {
            case (.compact, .regular):
                NSLayoutConstraint.deactivate(self.compactConstraints)
                toolbar.deactivateConstraints(for: .compact)
                NSLayoutConstraint.activate(self.regularConstraints)
                toolbar.activateConstraints(for: .regular)
            case (.regular, .compact):
                NSLayoutConstraint.deactivate(self.regularConstraints)
                toolbar.deactivateConstraints(for: .regular)
                NSLayoutConstraint.activate(self.compactConstraints)
                toolbar.activateConstraints(for: .compact)
            default:
                break
            }
        }
    }
    // MARK: - UIGestureRecognizerDelegate
    public func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        overlayView.shouldReceiveTouch(at: gestureRecognizer.location(in: overlayView))
    }
    // MARK: - gestures
    @objc private func gridPanGesture(_ sender: UIPanGestureRecognizer) {
        switch sender.state {
        case .began:
            if isGridGestureEndTaskRunning {
                gridGestureEndTask?.cancel()
            }
            overlayView.panGestureBegan(at: sender.location(in: overlayView))
        case .changed:
            // toolbarPosition
            overlayView.panGestureChanged(
                by: sender.translation(in: overlayView),
                contentOffset: scrollView.contentOffset,
                contentPadding: scrollView.contentPadding(toolbarPosition: toolbarPosition),
                scaledContentSize: imageFilter.imageSize(screenScale: view.screenScale) * scrollView.zoomScale
            )
        case .ended, .cancelled, .failed:
            overlayView.panGestureEnded()
            scrollView.updateContentInsetAndMinZoomScale(
                with: overlayView.cropRect,
                imageSize: imageFilter.imageSize(screenScale: view.screenScale)
            )
            scheduleGridPanGestureEnd()
        default:
            break
        }
        sender.setTranslation(.zero, in: overlayView)
    }
}
// MARK: - UIScrollViewDelegate
extension CropViewController: UIScrollViewDelegate {
    public func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        self.scrollView.imageView
    }

    public func scrollViewWillBeginDragging(_: UIScrollView) {
        beginScrollViewTouchEvents()
    }

    public func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        endScrollViewTouchEvents()
    }

    public func scrollViewWillBeginZooming(_ scrollView: UIScrollView, with view: UIView?) {
        beginScrollViewTouchEvents()
    }

    public func scrollViewDidEndZooming(_ scrollView: UIScrollView, with view: UIView?, atScale scale: CGFloat) {
        endScrollViewTouchEvents()
    }
}
// MARK: - ToolbarDelegate
extension CropViewController: ToolbarDelegate {
    func aspectRatioDidSelect(aspectRatio: AspectRatio) {
        if self.aspectRatio != aspectRatio {
            update(aspectRatio: aspectRatio)
        }
    }

    func cancelDidTap() {
        didCancel?(self)
    }

    func doneDidTap() {
        endEditing()
    }

    func flipDidTap() {
        if isImageAnimating {
            return
        }

        flipImage()
    }

    func resetDidTap() {
        reset()
    }

    func rotateDidTap() {
        if isImageAnimating {
            return
        }

        rotateImage()
    }
}
// MARK: - private
extension CropViewController {
    private var isForeground: Bool {
        let activationState = view.window?.windowScene?.activationState
        return activationState == .foregroundActive || activationState == .foregroundInactive
    }

    private func configureSubviews() {
        view.backgroundColor = .black
        view.add(subview: scrollView)
        view.add(subview: overlayView)
        view.add(subview: animationView)
        if let toolbar {
            view.addSubview(toolbar)
            regularConstraints = [
                toolbar.bottomAnchor.constraint(equalTo: view.bottomAnchor),
                toolbar.leadingAnchor.constraint(equalTo: view.leadingAnchor),
                toolbar.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            ]
            compactConstraints = [
                toolbar.topAnchor.constraint(equalTo: view.topAnchor),
                toolbar.bottomAnchor.constraint(equalTo: view.bottomAnchor),
                toolbar.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            ]
            toolbar.activateConstraints(for: traitCollection.verticalSizeClass)
            if traitCollection.verticalSizeClass == .compact {
                NSLayoutConstraint.activate(compactConstraints)
            } else {
                NSLayoutConstraint.activate(regularConstraints)
            }
            toolbar.delegate = self
        }

        view.add(subview: transitionCoverView)

        let panGesture = UIPanGestureRecognizer(target: self, action: #selector(gridPanGesture(_:)))
        panGesture.delegate = self
        view.addGestureRecognizer(panGesture)
        scrollView.panGestureRecognizer.require(toFail: panGesture)
        scrollView.delegate = self

        transitionCoverView.isHidden = true
    }

    private func setupImage() {
        let image = imageFilter.transformedImage(screenScale: view.screenScale)
        scrollView.reset(image: image)

        let cropRect: CGRect
        if initialCropRect == .zero || !initialCropRect.isValid(in: image.size * view.screenScale) {
            cropRect = .init(origin: .zero, size: image.size)
            aspectRatio = .freeform
        } else {
            cropRect = .init(origin: initialCropRect.origin / view.screenScale,
                             size: initialCropRect.size / view.screenScale)
            // Check aspect ratio is valid
            let ratio = aspectRatio.value(sourceSize: image.size)
            if let ratio, abs(cropRect.width / cropRect.height - ratio) >= CGFloat.ulpOfOne {
                aspectRatio = .freeform
            }
        }

        let ratio = aspectRatio.value(sourceSize: image.size)
        overlayView.set(aspectRatio: ratio)

        let (updateCropRect, scale) = scrollView.calcCropRectAndScale(
            from: cropRect, position: toolbarPosition
        )
        let contentOffset = cropRect.origin * scale - updateCropRect.origin
        scrollView.reset(cropRect: updateCropRect, zoomScale: scale, contentOffset: contentOffset,
                         imageSize: image.size)
        overlayView.update(cropRect: updateCropRect)
    }

    private func handleViewChange(currentContentOffset contentOffset: CGPoint) {
        let cropRect = overlayView.cropRect
        let (updateCropRect, scale) = scrollView.calcCropRectAndScale(
            from: cropRect, position: toolbarPosition
        )
        let cropCenter = contentOffset + cropRect.origin + .init(size: cropRect.size) / 2
        let contentOffset = cropCenter * scale - (.init(size: updateCropRect.size) / 2 + updateCropRect.origin)
        scrollView.reset(cropRect: updateCropRect, zoomScale: scrollView.zoomScale * scale,
                         contentOffset: contentOffset,
                         imageSize: imageFilter.imageSize(screenScale: view.screenScale))
        overlayView.update(cropRect: updateCropRect)
    }

    private func createAnimationImage() -> UIImage {
        imageFilter.createAnimationImage(
            cropOrigin: scrollView.calcCropOrigin(from: overlayView.cropRect.origin),
            cropSize: overlayView.cropRect.size,
            zoomScale: scrollView.zoomScale,
            screenScale: view.window?.windowScene?.screen.scale ?? 1
        )
    }

    private func endEditing() {
        let clampedRect = imageFilter.clampCropRect(
            cropOrigin: scrollView.calcCropOrigin(from: overlayView.cropRect.origin),
            cropSize: overlayView.cropRect.size,
            zoomScale: scrollView.zoomScale,
            screenScale: view.window?.windowScene?.screen.scale ?? 1
        )

        let transform = imageFilter.transform
        let editInfo = CropEditInfo(rect: clampedRect, transform: transform, aspectRatio: aspectRatio,
                                    zoomScale: scrollView.zoomScale)
        if let didFinishEditing {
            let image = imageFilter.createCroppedImage(cropRect: clampedRect)
            didFinishEditing(self, image, editInfo)
        } else if let didFinishEditingWithoutImage {
            didFinishEditingWithoutImage(self, editInfo)
        }
    }

    private func flipImage() {
        let image = createAnimationImage()
        let cropRect = overlayView.cropRect
        isImageAnimating = true
        animationView.performFlipAnimation(image: image, frame: cropRect) {
            let flippedImage = self.imageFilter.flip().transformedImage(screenScale: self.view.screenScale)
            self.scrollView.flip(image: flippedImage, withCropRect: cropRect)
        } completion: {
            self.isImageAnimating = false
        }
    }

    private func reset() {
        if !imageFilter.isIdentity {
            scrollView.reset(image: imageFilter.reset().transformedImage(screenScale: view.screenScale))
        }

        aspectRatio = .freeform
        toolbar?.toggleAspectRatioButton(for: aspectRatio)

        let (updateCropRect, scale) = scrollView.calcCropRectAndScale(
            from: .init(origin: .zero, size: imageFilter.imageSize(screenScale: view.screenScale)),
            position: toolbarPosition
        )
        scrollView.reset(cropRect: updateCropRect, zoomScale: scale,
                         contentOffset: -updateCropRect.origin,
                         imageSize: imageFilter.imageSize(screenScale: view.screenScale))
        overlayView.update(cropRect: updateCropRect)
    }

    private func rotateImage() {
        // calculate the crop rect scale from rotated crop rect size
        let rotatedCropSize = CGSize(width: overlayView.cropRect.height,
                                     height: overlayView.cropRect.width)
        let scale = scrollView.calcScale(from: rotatedCropSize, position: toolbarPosition)
        let image = createAnimationImage()
        isImageAnimating = true
        animationView.performRotateAnimation(image: image, frame: overlayView.cropRect, scale: scale) {
            self.rotateCompletion(scale: scale)
        } completion: {
            self.isImageAnimating = false
        }
    }

    private func rotateCompletion(scale: CGFloat) {
        // calculate target crop rect
        let cropRect = overlayView.cropRect
        let updateCropSize = CGSize(width: cropRect.height, height: cropRect.width) * scale
        let updateCropOrigin = scrollView.calcCropRectOrigin(
            with: updateCropSize, toolbarPosition: toolbarPosition
        )
        let updateCropRect = CGRect(origin: updateCropOrigin, size: updateCropSize)
        let rotatedImage = imageFilter.rotate().transformedImage(screenScale: view.screenScale)
        scrollView.rotate(withCurrentCropRect: cropRect, updatedCropRect: updateCropRect,
                          scale: scale, rotatedImage: rotatedImage)
        overlayView.update(cropRect: updateCropRect)
    }

    private func update(aspectRatio: AspectRatio) {
        self.aspectRatio = aspectRatio
        toolbar?.toggleAspectRatioButton(for: aspectRatio)

        let ratio = aspectRatio.value(sourceSize: imageFilter.imageSize(screenScale: view.screenScale))
        overlayView.set(aspectRatio: ratio)
        guard let ratio else {
            return
        }

        let updateRect = scrollView.updateCropRect(
            for: ratio, cropRect: overlayView.cropRect,
            imageHeight: imageFilter.imageSize(screenScale: view.screenScale).height,
            toolbarPosition: toolbarPosition
        )
        overlayView.update(cropRect: updateRect, animate: true)
    }
    // end pan gesture with some delay
    private func scheduleGridPanGestureEnd() {
        gridGestureEndTask = Task {
            do {
                // set blur view visible after delay
                try await Task.sleep(until: .now + .seconds(0.4))
                if !overlayView.isBlurViewVisible {
                    overlayView.setBlurView(visible: true)
                    // end grid pan gesture after delay
                    try await Task.sleep(until: .now + .seconds(0.8))
                } else {
                    try await Task.sleep(until: .now + .seconds(0.4))
                }
                endGridPanGesture()
            } catch {
                // task has canceled
            }
            isGridGestureEndTaskRunning = false
        }
        isGridGestureEndTaskRunning = true
    }

    private func endGridPanGesture() {
        let (updateCropRect, scale) = scrollView.calcCropRectAndScale(
            from: overlayView.cropRect, position: toolbarPosition
        )
        // animation order matters
        scrollView.animateZoomAndOffset(
            withCropRect: overlayView.cropRect,
            updatedCropRect: updateCropRect,
            scale: scale, imageSize: imageFilter.imageSize(screenScale: view.screenScale)
        )
        overlayView.update(cropRect: updateCropRect, animate: true)
    }

    private func beginScrollViewTouchEvents() {
        overlayView.setGrid(visible: true)

        if isGridGestureEndTaskRunning {
            gridGestureEndTask?.cancel()
            rescheduleGridGestureEnd = true
        }
    }

    private func endScrollViewTouchEvents() {
        overlayView.setGrid(visible: false)

        if rescheduleGridGestureEnd {
            scheduleGridPanGestureEnd()
            rescheduleGridGestureEnd = false
        }
    }
}
