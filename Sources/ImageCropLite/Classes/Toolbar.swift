// Toolbar.swift
//
// The MIT License (MIT)
// Copyright (c) 2024 Tako
//
// See LICENSE.md for license information.

import UIKit

@MainActor
protocol ToolbarDelegate: AnyObject {
    var aspectRatio: AspectRatio { get }
    func aspectRatioDidSelect(aspectRatio: AspectRatio)
    func cancelDidTap()
    func doneDidTap()
    func flipDidTap()
    func resetDidTap()
    func rotateDidTap()
}

private enum AspectRatioCategoryMenu: Equatable, CaseIterable {
    case original
    case freeform
    case square
    case portrait
    case landscape

    var title: String {
        switch self {
        case .original:
            String(localized: "ORIGINAL", bundle: .module)
        case .freeform:
            String(localized: "FREEFORM", bundle: .module)
        case .square:
            String(localized: "SQUARE", bundle: .module)
        case .portrait:
            String(localized: "PORTRAIT", bundle: .module)
        case .landscape:
            String(localized: "LANDSCAPE", bundle: .module)
        }
    }

    func image(selected: Bool = false) -> UIImage? {
        switch self {
        case .square:
            .init(systemName: "square")!
        case .portrait:
            if selected {
                .init(named: "rectangle.portrait.checkmark", in: .module, with: nil)
            } else {
                .init(systemName: "rectangle.portrait")
            }
        case .landscape:
            if selected {
                .init(named: "rectangle.checkmark", in: .module, with: nil)
            } else {
                .init(systemName: "rectangle")
            }
        default:
            nil
        }
    }
}

extension AspectRatio {
    fileprivate static func ==(lhs: AspectRatio, rhs: AspectRatioCategoryMenu) -> Bool {
        switch (lhs, rhs) {
        case (.original, .original), (.freeform, .freeform),
             (.square, .square), (.portrait, .portrait),
             (.landscape, .landscape):
            true
        default:
            false
        }
    }

    static func ==(lhs: AspectRatio, rhs: PortraitRatio) -> Bool {
        if case let .portrait(selected) = lhs {
            selected == rhs
        } else {
            false
        }
    }

    static func ==(lhs: AspectRatio, rhs: LandscapeRatio) -> Bool {
        if case let .landscape(selected) = lhs {
            selected == rhs
        } else {
            false
        }
    }
}

private func ==(lhs: AspectRatio?, rhs: AspectRatioCategoryMenu) -> Bool {
    lhs.map { $0 == rhs } ?? false
}

func ==(lhs: AspectRatio?, rhs: PortraitRatio) -> Bool {
    lhs.map { $0 == rhs } ?? false
}

func ==(lhs: AspectRatio?, rhs: LandscapeRatio) -> Bool {
    lhs.map { $0 == rhs } ?? false
}

final class Toolbar: UIView {
    enum Position: Equatable {
        case bottom
        case left
        case none
    }

    static let toolbarHeightOrWidth: CGFloat = 44
    private static let buttonWidth: CGFloat = 44.0
    private static let edgeInset: CGFloat = 15
    private static let margin: CGFloat = 4

    weak var delegate: (any ToolbarDelegate)?

    private var aspectRatioButton: UIButton?
    private var resetButton: UIButton?
    // left side view when axis is horizontal; top side view when axis is vertical
    private let leftSideView: UIView = .init(frame: .zero)
    // right side view when axis is horizontal; bottom side view when axis is vertical
    private let rightSideView: UIView = .init(frame: .zero)
    // constraints for parent vc's vertical size class is regular or compact
    private var regularConstraints: [NSLayoutConstraint] = []
    private var compactConstraints: [NSLayoutConstraint] = []

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError() }

    init(configuration: CropToolbarConfiguration, aspectRatio: AspectRatio) {
        super.init(frame: .zero)
        translatesAutoresizingMaskIntoConstraints = false
        backgroundColor = configuration.backgroundColor
        configureSubviews()
        configureButtons(toolbarConfig: configuration, aspectRatio: aspectRatio)
    }

    func activateConstraints(for verticalSizeClass: UIUserInterfaceSizeClass) {
        if verticalSizeClass == .compact {
            NSLayoutConstraint.activate(compactConstraints)
        } else {
            NSLayoutConstraint.activate(regularConstraints)
        }
    }

    func deactivateConstraints(for verticalSizeClass: UIUserInterfaceSizeClass) {
        if verticalSizeClass == .compact {
            NSLayoutConstraint.deactivate(compactConstraints)
        } else {
            NSLayoutConstraint.deactivate(regularConstraints)
        }
    }

    func resetButton(enable: Bool) {
        resetButton?.isEnabled = enable
    }

    func toggleAspectRatioButton(for aspectRatioCategory: AspectRatio) {
        setAspectRatioButtonImage(for: aspectRatioCategory)
    }
}
// MARK: - private
extension Toolbar {
    private func configureSubviews() {
        let spacer = UIView(frame: .zero)
        spacer.translatesAutoresizingMaskIntoConstraints = false
        leftSideView.translatesAutoresizingMaskIntoConstraints = false
        rightSideView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(leftSideView)
        addSubview(rightSideView)
        addSubview(spacer)
        spacer.setContentHuggingPriority(.defaultLow, for: .horizontal)
        spacer.setContentHuggingPriority(.defaultLow, for: .vertical)
        regularConstraints = [
            leftSideView.leadingAnchor.constraint(equalTo: safeAreaLayoutGuide.leadingAnchor,
                                                  constant: Self.edgeInset),
            leftSideView.trailingAnchor.constraint(equalTo: spacer.leadingAnchor),
            spacer.widthAnchor.constraint(greaterThanOrEqualToConstant: Self.margin),
            spacer.trailingAnchor.constraint(equalTo: rightSideView.leadingAnchor),
            rightSideView.trailingAnchor.constraint(equalTo: safeAreaLayoutGuide.trailingAnchor,
                                                    constant: -Self.edgeInset),
            leftSideView.topAnchor.constraint(equalTo: topAnchor),
            leftSideView.heightAnchor.constraint(equalToConstant: Self.toolbarHeightOrWidth),
            leftSideView.bottomAnchor.constraint(equalTo: safeAreaLayoutGuide.bottomAnchor),
            rightSideView.topAnchor.constraint(equalTo: topAnchor),
            rightSideView.heightAnchor.constraint(equalToConstant: Self.toolbarHeightOrWidth),
            rightSideView.bottomAnchor.constraint(equalTo: safeAreaLayoutGuide.bottomAnchor),
            spacer.topAnchor.constraint(equalTo: topAnchor),
            spacer.heightAnchor.constraint(equalToConstant: Self.toolbarHeightOrWidth),
            spacer.bottomAnchor.constraint(equalTo: safeAreaLayoutGuide.bottomAnchor),
        ]

        compactConstraints = [
            leftSideView.topAnchor.constraint(equalTo: safeAreaLayoutGuide.topAnchor),
            leftSideView.bottomAnchor.constraint(equalTo: spacer.topAnchor),
            spacer.heightAnchor.constraint(greaterThanOrEqualToConstant: Self.margin),
            spacer.bottomAnchor.constraint(equalTo: rightSideView.topAnchor),
            rightSideView.bottomAnchor.constraint(equalTo: safeAreaLayoutGuide.bottomAnchor),
            leftSideView.leadingAnchor.constraint(equalTo: safeAreaLayoutGuide.leadingAnchor),
            leftSideView.widthAnchor.constraint(equalToConstant: Self.toolbarHeightOrWidth),
            leftSideView.trailingAnchor.constraint(equalTo: trailingAnchor),
            rightSideView.leadingAnchor.constraint(equalTo: safeAreaLayoutGuide.leadingAnchor),
            rightSideView.widthAnchor.constraint(equalToConstant: Self.toolbarHeightOrWidth),
            rightSideView.trailingAnchor.constraint(equalTo: trailingAnchor),
            spacer.leadingAnchor.constraint(equalTo: safeAreaLayoutGuide.leadingAnchor),
            spacer.widthAnchor.constraint(equalToConstant: Self.toolbarHeightOrWidth),
            spacer.trailingAnchor.constraint(equalTo: trailingAnchor),
        ]
    }
    // stack view breaks layout when rotates so manually layout without using stack view
    private func configureButtons(toolbarConfig: CropToolbarConfiguration, aspectRatio: AspectRatio) {
        // setup buttons
        let imgConfig = UIImage.SymbolConfiguration(weight: .semibold)
        var btnConfig = UIButton.Configuration.plain()
        // left side
        // add close & reset buttons is visible
        var previousButton: UIButton?
        if toolbarConfig.showCancelButton {
            btnConfig.image = .init(systemName: "xmark", withConfiguration: imgConfig)
            btnConfig.baseForegroundColor = toolbarConfig.cancelButtonForegroundColor
            let cancelButton = UIButton(configuration: btnConfig,
                                        primaryAction: .init { [weak self] _ in
                                            self?.delegate?.cancelDidTap()
                                        })
            appendConstraints(targetButton: cancelButton, parentView: leftSideView)
            previousButton = cancelButton
        }
        // reset
        if toolbarConfig.showResetButton {
            btnConfig.image = .init(systemName: "arrow.counterclockwise",
                                    withConfiguration: imgConfig)
            btnConfig.baseForegroundColor = toolbarConfig.resetButtonForegroundColor
            let resetButton = UIButton(configuration: btnConfig,
                                       primaryAction: .init { [weak self] _ in
                                           self?.delegate?.resetDidTap()
                                       })
            self.resetButton = resetButton
            appendConstraints(targetButton: resetButton, previousButton: previousButton,
                              parentView: leftSideView)
            previousButton = resetButton
        }

        if let previousButton {
            regularConstraints.append(
                previousButton.trailingAnchor.constraint(equalTo: leftSideView.trailingAnchor)
            )
            compactConstraints.append(
                previousButton.bottomAnchor.constraint(equalTo: leftSideView.bottomAnchor)
            )
        }
        // right side
        // add flip, rotate, apsect ratio & done buttons if visible
        previousButton = nil
        // flip
        if toolbarConfig.showFlipButton {
            btnConfig.image = .init(systemName: "arrow.left.and.right.righttriangle.left.righttriangle.right",
                                    withConfiguration: imgConfig)
            btnConfig.baseForegroundColor = toolbarConfig.flipButtonForegroundColor
            let flipButton = UIButton(configuration: btnConfig,
                                      primaryAction: .init { [weak self] _ in
                                          self?.delegate?.flipDidTap()
                                      })
            appendConstraints(targetButton: flipButton, parentView: rightSideView)
            previousButton = flipButton
        }
        // rotate clockwise
        if toolbarConfig.showRotateButton {
            btnConfig.image = .init(systemName: "rotate.left",
                                    withConfiguration: imgConfig)
            btnConfig.baseForegroundColor = toolbarConfig.rotateButtonForegroundColor
            let rotateButton = UIButton(configuration: btnConfig,
                                        primaryAction: .init { [weak self] _ in
                                            self?.delegate?.rotateDidTap()
                                        })
            appendConstraints(targetButton: rotateButton, previousButton: previousButton,
                              parentView: rightSideView)
            previousButton = rotateButton
        }
        // aspect ratio
        if toolbarConfig.showAspectRatioButton {
            btnConfig.baseForegroundColor = toolbarConfig.aspectRatioButtonForegroundColor
            let aspectRatioButton = UIButton(configuration: btnConfig)
            let aspectRatioMenus = configureAspectRatioMenus()
            aspectRatioButton.menu = .init(children: [aspectRatioMenus])
            aspectRatioButton.showsMenuAsPrimaryAction = true
            self.aspectRatioButton = aspectRatioButton
            setAspectRatioButtonImage(for: aspectRatio)
            appendConstraints(targetButton: aspectRatioButton, previousButton: previousButton,
                              parentView: rightSideView)
            previousButton = aspectRatioButton
        }
        // done
        if toolbarConfig.showDoneButton {
            btnConfig.image = .init(systemName: "checkmark.circle.fill",
                                    withConfiguration: imgConfig)
            btnConfig.baseForegroundColor = toolbarConfig.doneButtonForegroundColor
            let doneButton = UIButton(configuration: btnConfig,
                                      primaryAction: .init { [weak self] _ in
                                          self?.delegate?.doneDidTap()
                                      })
            appendConstraints(targetButton: doneButton, previousButton: previousButton,
                              parentView: rightSideView)
            previousButton = doneButton
        }

        if let previousButton {
            regularConstraints.append(
                previousButton.trailingAnchor.constraint(equalTo: rightSideView.trailingAnchor)
            )
            compactConstraints.append(
                previousButton.bottomAnchor.constraint(equalTo: rightSideView.bottomAnchor)
            )
        }
    }

    private func appendConstraints(targetButton: UIButton, previousButton: UIButton? = nil,
                                   parentView: UIView) {
        targetButton.translatesAutoresizingMaskIntoConstraints = false
        parentView.addSubview(targetButton)

        if let previousButton {
            regularConstraints.append(
                previousButton.trailingAnchor.constraint(equalTo: targetButton.leadingAnchor,
                                                         constant: -Self.margin)
            )
            compactConstraints.append(
                previousButton.bottomAnchor.constraint(equalTo: targetButton.topAnchor,
                                                       constant: -Self.margin)
            )
        } else {
            regularConstraints.append(
                parentView.leadingAnchor.constraint(equalTo: targetButton.leadingAnchor)
            )
            compactConstraints.append(
                parentView.topAnchor.constraint(equalTo: targetButton.topAnchor)
            )
        }

        regularConstraints.append(contentsOf: [
            targetButton.widthAnchor.constraint(equalToConstant: Self.buttonWidth),
            targetButton.topAnchor.constraint(equalTo: parentView.topAnchor),
            targetButton.bottomAnchor.constraint(equalTo: parentView.bottomAnchor),
        ])

        compactConstraints.append(contentsOf: [
            targetButton.leadingAnchor.constraint(equalTo: parentView.leadingAnchor),
            targetButton.trailingAnchor.constraint(equalTo: parentView.trailingAnchor),
        ])
    }

    private func configureAspectRatioMenus() -> UIMenuElement {
        UIDeferredMenuElement.uncached { [weak self] completion in
            let actions = AspectRatioCategoryMenu.allCases.reversed().map { category in
                let selected = self?.delegate?.aspectRatio == category
                let menu: UIMenuElement
                if category == .portrait {
                    let child = UIDeferredMenuElement.uncached { [weak self] completion in
                        let actions = PortraitRatio.allCases.map { ratio in
                            let state = self?.delegate?.aspectRatio == ratio ? UIMenuElement.State.on : .off
                            return UIAction(title: ratio.title, state: state) { [weak self] _ in
                                self?.delegate?.aspectRatioDidSelect(aspectRatio: .portrait(ratio: ratio))
                            }
                        }
                        completion(actions)
                    }
                    menu = UIMenu(title: category.title, image: category.image(selected: selected),
                                  options: .singleSelection, children: [child])
                } else if category == .landscape {
                    let child = UIDeferredMenuElement.uncached { [weak self] completion in
                        let actions = LandscapeRatio.allCases.map { ratio in
                            let state = self?.delegate?.aspectRatio == ratio ? UIMenuElement.State.on : .off
                            return UIAction(title: ratio.title, state: state) { [weak self] _ in
                                self?.delegate?.aspectRatioDidSelect(aspectRatio: .landscape(ratio: ratio))
                            }
                        }
                        completion(actions)
                    }
                    menu = UIMenu(title: category.title, image: category.image(selected: selected),
                                  options: .singleSelection, children: [child])
                } else {
                    let state: UIMenuElement.State = selected ? .on : .off
                    menu = UIAction(title: category.title, image: category.image(), state: state) {
                        [weak self] _ in
                        switch category {
                        case .freeform:
                            self?.delegate?.aspectRatioDidSelect(aspectRatio: .freeform)
                        case .original:
                            self?.delegate?.aspectRatioDidSelect(aspectRatio: .original)
                        case .square:
                            self?.delegate?.aspectRatioDidSelect(aspectRatio: .square)
                        default:
                            break
                        }
                    }
                }
                return menu
            }
            completion(actions)
        }
    }

    private func setAspectRatioButtonImage(for aspectRatio: AspectRatio) {
        let systemName = aspectRatio == .freeform ? "aspectratio" : "aspectratio.fill"
        var config = aspectRatioButton?.configuration
        let imageConfig = UIImage.SymbolConfiguration(weight: .semibold)
        config?.image = .init(systemName: systemName, withConfiguration: imageConfig)
        aspectRatioButton?.configuration = config
    }
}
