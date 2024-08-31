// CropViewConfiguration.swift
//
// The MIT License (MIT)
// Copyright (c) 2024 Tako
//
// See LICENSE.md for license information.

import UIKit

// Portrait supported ratios => 3:2, 4:3, 5:3, 5:4, 7:5, 16:9
public enum PortraitRatio: Equatable, CaseIterable, Sendable {
    case ratio2x3
    case ratio3x5
    case ratio3x4
    case ratio5x7
    case ratio4x5
    case ratio9x16

    public var title: String {
        switch self {
        case .ratio2x3:
            "2:3"
        case .ratio3x5:
            "3:5"
        case .ratio3x4:
            "3:4"
        case .ratio5x7:
            "5:7"
        case .ratio4x5:
            "4:5"
        case .ratio9x16:
            "9:16"
        }
    }

    public var value: CGFloat {
        switch self {
        case .ratio2x3:
            2 / 3
        case .ratio3x5:
            3 / 5
        case .ratio3x4:
            3 / 4
        case .ratio5x7:
            5 / 7
        case .ratio4x5:
            4 / 5
        case .ratio9x16:
            9 / 16
        }
    }
}
// Landscape supported ratios => 3:2, 4:3, 5:3, 5:4, 7:5, 16:9
public enum LandscapeRatio: Equatable, CaseIterable, Sendable {
    case ratio3x2
    case ratio5x3
    case ratio4x3
    case ratio7x5
    case ratio5x4
    case ratio16x9

    public var title: String {
        switch self {
        case .ratio3x2:
            "3:2"
        case .ratio5x3:
            "5:3"
        case .ratio4x3:
            "4:3"
        case .ratio7x5:
            "7:5"
        case .ratio5x4:
            "5:4"
        case .ratio16x9:
            "16:9"
        }
    }

    public var value: CGFloat {
        switch self {
        case .ratio3x2:
            3 / 2
        case .ratio5x3:
            5 / 3
        case .ratio4x3:
            4 / 3
        case .ratio7x5:
            7 / 5
        case .ratio5x4:
            5 / 4
        case .ratio16x9:
            16 / 9
        }
    }
}

public enum AspectRatio: Equatable, Sendable {
    case original
    case freeform // default value
    case square // 1:1
    case portrait(ratio: PortraitRatio)
    case landscape(ratio: LandscapeRatio)

    public func value(sourceSize size: CGSize) -> CGFloat? {
        switch self {
        case .original:
            size.width / size.height
        case .freeform:
            nil
        case .square:
            1.0
        case let .portrait(ratio):
            ratio.value
        case let .landscape(ratio):
            ratio.value
        }
    }
}

public struct CropNavigationBarConfiguration: Equatable {
    /// Shows the 'cancel' button on navigation bar if presented.
    /// Defaults to 'false'.
    public var showCancelButton: Bool
    /// The name of the system symbol image for cancel button
    /// Defaults to 'chevron.left'.
    public var cancelSystemName: String
    /// The tint color for the cancel button
    /// Default to nil.
    public var cancelTintColor: UIColor?
    /// Shows the 'done' button on navigation bar if presented.
    /// Defaults to 'false'.
    public var showDoneButton: Bool
    /// The tint color for the done button
    /// Default to nil.
    public var doneTintColor: UIColor?

    public init(showCancelButton: Bool = false, cancelSystemName: String = "chevron.left",
                cancelTintColor: UIColor? = nil,
                showDoneButton: Bool = false, doneTintColor: UIColor? = nil) {
        self.showCancelButton = showCancelButton
        self.cancelSystemName = cancelSystemName
        self.cancelTintColor = cancelTintColor
        self.showDoneButton = showDoneButton
        self.doneTintColor = doneTintColor
    }
}

public struct CropToolbarConfiguration: Equatable {
    /// Shows tool bar
    /// Defaults to 'true'.
    public var showToolbar: Bool
    /// Crop toolbar background color
    /// Defaults to 'UIColor(white: 0.15, alpha: 1.0)'
    public var backgroundColor: UIColor
    /// Shows the 'cancel' button on the toolbar.
    /// Defaults to 'true'.
    public var showCancelButton: Bool
    /// Cancel button foreground color
    /// Defaults to 'UIColor.white'.
    public var cancelButtonForegroundColor: UIColor
    /// Shows the 'reset' button on the toolbar.
    /// Defaults to 'true'.
    public var showResetButton: Bool
    /// Reset button foreground color
    /// Defaults to 'UIColor.white'.
    public var resetButtonForegroundColor: UIColor
    /// Shows the 'flip' button on the toolbar.
    /// Defaults to 'UIColor.white'.
    /// Defaults to 'true'.
    public var showFlipButton: Bool
    /// Flip button foreground color
    /// Defaults to 'UIColor.white'.
    public var flipButtonForegroundColor: UIColor
    /// Shows the 'rotate' button on the toolbar.
    /// Defaults to 'true'.
    public var showRotateButton: Bool
    /// Rotate button foreground color
    /// Defaults to 'UIColor.white'.
    public var rotateButtonForegroundColor: UIColor
    /// Shows the 'aspect ratio' button on the toolbar.
    /// Defaults to 'true'.
    public var showAspectRatioButton: Bool
    /// Aspect ratio button foreground color
    /// Defaults to 'UIColor.white'.
    public var aspectRatioButtonForegroundColor: UIColor
    /// Shows the 'done' button on the toolbar.
    /// Defaults to 'true'.
    public var showDoneButton: Bool
    /// Done button foreground color
    /// Defaults to 'UIColor.white'.
    public var doneButtonForegroundColor: UIColor

    public init(
        showToolbar: Bool = true,
        backgroundColor: UIColor = .init(white: 0.15, alpha: 1.0),
        showCancelButton: Bool = true,
        cancelButtonForegroundColor: UIColor = .white,
        showResetButton: Bool = true,
        resetButtonForegroundColor: UIColor = .white,
        showFlipButton: Bool = true,
        flipButtonForegroundColor: UIColor = .white,
        showRotateButton: Bool = true,
        rotateButtonForegroundColor: UIColor = .white,
        showAspectRatioButton: Bool = true,
        aspectRatioButtonForegroundColor: UIColor = .white,
        showDoneButton: Bool = true,
        doneButtonForegroundColor: UIColor = .white
    ) {
        self.showToolbar = showToolbar
        self.backgroundColor = backgroundColor
        self.showCancelButton = showCancelButton
        self.cancelButtonForegroundColor = cancelButtonForegroundColor
        self.showResetButton = showResetButton
        self.resetButtonForegroundColor = resetButtonForegroundColor
        self.showFlipButton = showFlipButton
        self.flipButtonForegroundColor = flipButtonForegroundColor
        self.showRotateButton = showRotateButton
        self.rotateButtonForegroundColor = rotateButtonForegroundColor
        self.showAspectRatioButton = showAspectRatioButton
        self.aspectRatioButtonForegroundColor = aspectRatioButtonForegroundColor
        self.showDoneButton = showDoneButton
        self.doneButtonForegroundColor = doneButtonForegroundColor
    }
}

public struct CropViewConfiguration: Equatable {
    /// The image to be cropped.
    public var image: UIImage
    /// The cropping rectangle to be applied initially.
    /// - Note: The coordinate system is based on the image in pixels,
    ///   with the top-left corner as the origin.
    /// - Setting this to `.zero` will select the entire image by default.
    public var cropRect: CGRect
    /// The transform to be applied to the image during the initial crop.
    public var transform: ImageFilterTransform
    /// The currently selected aspect ratio.
    /// defaults to '.freeform'
    public var aspectRatio: AspectRatio
    /// Additional insets to crop area's margin
    public var additionalInsets: UIEdgeInsets
    /// Hides status bar
    /// default to 'false'
    public var isStatusBarHidden: Bool
    /// Status bar style
    /// defaults to '.default'
    public var statusBarStyle: UIStatusBarStyle
    /// The available user interface orientations.
    /// defaults to '.all'
    public var interfaceOrientations: UIInterfaceOrientationMask

    public init(
        image: UIImage,
        cropRect: CGRect = .zero,
        transform: ImageFilterTransform = .init(),
        aspectRatio: AspectRatio = .freeform,
        additionalInsets: UIEdgeInsets = .zero,
        isStatusBarHidden: Bool = false,
        statusBarStyle: UIStatusBarStyle = .default,
        interfaceOrientations: UIInterfaceOrientationMask = .all
    ) {
        self.image = image
        self.cropRect = cropRect
        self.transform = transform
        self.aspectRatio = aspectRatio
        self.additionalInsets = additionalInsets
        self.isStatusBarHidden = isStatusBarHidden
        self.statusBarStyle = statusBarStyle
        self.interfaceOrientations = interfaceOrientations
    }
}
