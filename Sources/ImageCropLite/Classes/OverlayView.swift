// OverlayView.swift
//
// The MIT License (MIT)
// Copyright (c) 2024 Tako
//
// See LICENSE.md for license information.

import UIKit

private final class OuterLines: CAShapeLayer, CAAnimationDelegate {
    private static let lineThickness: CGFloat = 1
    private static let cornerLineThickness: CGFloat = 3
    private static let cornerLineLength: CGFloat = 20
    // rect to set after animation has ended
    private var rect: CGRect = .zero

    private enum LinePosition: CaseIterable {
        case top
        case bottom
        case left
        case right
    }

    private enum CornerLinePosition: CaseIterable {
        case topLeft
        case topMiddle
        case topRight
        case bottomLeft
        case bottomMiddle
        case bottomRight
        case leftMiddle
        case rightMiddle
    }

    convenience init(fillColor: CGColor) {
        self.init()
        self.fillColor = fillColor
    }

    func draw(in rect: CGRect) {
        path = paths(in: rect)
    }

    func animatePath(to rect: CGRect) {
        self.rect = rect
        let endPath = paths(in: rect)
        let animation = CABasicAnimation(pathAnimation: endPath)
        animation.delegate = self
        add(animation, forKey: "outerLineAnimation")
    }

    func animationDidStop(_ anim: CAAnimation, finished flag: Bool) {
        path = paths(in: rect)
        removeAnimation(forKey: "outerLineAnimation")
    }

    private func paths(in rect: CGRect) -> CGPath {
        let paths = CGMutablePath()
        for position in LinePosition.allCases {
            paths.addPath(path(position: position, rect: rect))
        }

        for position in CornerLinePosition.allCases {
            paths.addPath(path(position: position, rect: rect))
        }
        return paths
    }

    private func path(position: LinePosition, rect: CGRect) -> CGPath {
        let origin = rect.origin
        let path: CGRect
        switch position {
        case .top:
            path = .init(x: origin.x - Self.lineThickness,
                         y: origin.y - Self.lineThickness,
                         width: rect.width + 2 * Self.lineThickness,
                         height: Self.lineThickness)
        case .bottom:
            path = .init(x: origin.x - Self.lineThickness,
                         y: origin.y + rect.height,
                         width: rect.width + 2 * Self.lineThickness,
                         height: Self.lineThickness)
        case .left:
            path = .init(x: origin.x - Self.lineThickness,
                         y: origin.y,
                         width: Self.lineThickness,
                         height: rect.height)
        case .right:
            path = .init(x: origin.x + rect.width,
                         y: origin.y,
                         width: Self.lineThickness,
                         height: rect.height)
        }
        return CGPath(rect: path, transform: nil)
    }

    private func path(position: CornerLinePosition, rect: CGRect) -> CGPath {
        let origin = rect.origin
        let path = CGMutablePath()
        switch position {
        case .topLeft:
            // vertical
            path.addRect(.init(x: origin.x - Self.cornerLineThickness,
                               y: origin.y - Self.cornerLineThickness,
                               width: Self.cornerLineThickness,
                               height: Self.cornerLineLength + Self.cornerLineThickness))
            // horizontal
            path.addRect(.init(x: origin.x,
                               y: origin.y - Self.cornerLineThickness,
                               width: Self.cornerLineLength,
                               height: Self.cornerLineThickness))
        case .topMiddle:
            path.addRect(.init(x: origin.x + (rect.width - Self.cornerLineLength) / 2,
                               y: origin.y - Self.cornerLineThickness,
                               width: Self.cornerLineLength,
                               height: Self.cornerLineThickness))
        case .topRight:
            // vertical
            path.addRect(.init(x: origin.x + rect.width,
                               y: origin.y - Self.cornerLineThickness,
                               width: Self.cornerLineThickness,
                               height: Self.cornerLineLength + Self.cornerLineThickness))
            // horizontal
            path.addRect(.init(x: origin.x + rect.width - Self.cornerLineLength,
                               y: origin.y - Self.cornerLineThickness,
                               width: Self.cornerLineLength,
                               height: Self.cornerLineThickness))
        case .bottomLeft:
            path.addRect(.init(x: origin.x - Self.cornerLineThickness,
                               y: origin.y + rect.height - Self.cornerLineLength,
                               width: Self.cornerLineThickness,
                               height: Self.cornerLineLength + Self.cornerLineThickness))
            path.addRect(.init(x: origin.x,
                               y: origin.y + rect.height,
                               width: Self.cornerLineLength,
                               height: Self.cornerLineThickness))
        case .bottomMiddle:
            path.addRect(.init(x: origin.x + (rect.width - Self.cornerLineLength) / 2,
                               y: origin.y + rect.height,
                               width: Self.cornerLineLength,
                               height: Self.cornerLineThickness))
        case .bottomRight:
            path.addRect(.init(x: origin.x + rect.width,
                               y: origin.y + rect.height - Self.cornerLineLength,
                               width: Self.cornerLineThickness,
                               height: Self.cornerLineLength + Self.cornerLineThickness))
            path.addRect(.init(x: origin.x + rect.width - Self.cornerLineLength,
                               y: origin.y + rect.height,
                               width: Self.cornerLineLength,
                               height: Self.cornerLineThickness))
        case .leftMiddle:
            path.addRect(.init(x: origin.x - Self.cornerLineThickness,
                               y: origin.y + (rect.height - Self.cornerLineLength) / 2,
                               width: Self.cornerLineThickness,
                               height: Self.cornerLineLength))
        case .rightMiddle:
            path.addRect(.init(x: origin.x + rect.width,
                               y: origin.y + (rect.height - Self.cornerLineLength) / 2,
                               width: Self.cornerLineThickness,
                               height: Self.cornerLineLength))
        }
        return path
    }
}

private final class InnerLines: CAShapeLayer {
    convenience init(strokeColor: CGColor) {
        self.init()
        lineWidth = 1
        self.strokeColor = strokeColor
    }

    func draw(in rect: CGRect) {
        let origin = rect.origin
        let mutablePath = CGMutablePath()
        let numberOfLines = 2
        for i in 1...numberOfLines {
            // vertial lines
            let x = origin.x + rect.width * CGFloat(i) / CGFloat(numberOfLines + 1)
            mutablePath.move(to: .init(x: x, y: origin.y))
            mutablePath.addLine(to: .init(x: x, y: origin.y + rect.height))
            // horizontal lines
            let y = origin.y + rect.height * CGFloat(i) / CGFloat(numberOfLines + 1)
            mutablePath.move(to: .init(x: origin.x, y: y))
            mutablePath.addLine(to: .init(x: origin.x + rect.width, y: y))
        }
        path = mutablePath
    }

    func setVisibility(_ visible: Bool) {
        let currentOpacity = presentation()?.opacity ?? opacity
        opacity = visible ? 1 : 0 // set target opacity
        let duration = 0.25 * (visible ? (1 - currentOpacity) : currentOpacity)
        let animation = CABasicAnimation(opacityAnimation: currentOpacity, visible: visible,
                                         duration: TimeInterval(duration))
        add(animation, forKey: nil)
    }
}

private enum GridGesturePosition {
    case topLeft
    case topRight
    case bottomLeft
    case bottomRight
    case top
    case bottom
    case left
    case right

    init?(at location: CGPoint, cropRect: CGRect) {
        let padding: CGFloat = 32
        let handleSize: CGFloat = 64
        let expandFrame = cropRect.insetBy(dx: -padding, dy: -padding)
        // Check for corners
        let topLeft = CGRect(origin: expandFrame.origin,
                             size: .init(width: handleSize, height: handleSize))
        if topLeft.contains(location) {
            self = .topLeft
            return
        }

        let topRight = CGRect(origin: .init(x: expandFrame.maxX - handleSize,
                                            y: expandFrame.origin.y),
                              size: .init(width: handleSize, height: handleSize))
        if topRight.contains(location) {
            self = .topRight
            return
        }

        let bottomLeft = CGRect(origin: .init(x: expandFrame.origin.x,
                                              y: expandFrame.maxY - handleSize),
                                size: .init(width: handleSize, height: handleSize))
        if bottomLeft.contains(location) {
            self = .bottomLeft
            return
        }

        let bottomRight = CGRect(origin: .init(x: expandFrame.maxX - handleSize,
                                               y: expandFrame.maxY - handleSize),
                                 size: .init(width: handleSize, height: handleSize))
        if bottomRight.contains(location) {
            self = .bottomRight
            return
        }
        // Check for edges
        let top = CGRect(origin: expandFrame.origin,
                         size: .init(width: expandFrame.width, height: handleSize))
        if top.contains(location) {
            self = .top
            return
        }

        let bottom = CGRect(
            origin: .init(x: expandFrame.origin.x,
                          y: expandFrame.maxY - handleSize),
            size: .init(width: expandFrame.width, height: handleSize)
        )
        if bottom.contains(location) {
            self = .bottom
            return
        }

        let left = CGRect(origin: expandFrame.origin,
                          size: .init(width: handleSize, height: expandFrame.height))
        if left.contains(location) {
            self = .left
            return
        }

        let right = CGRect(origin: .init(x: expandFrame.maxX - handleSize,
                                         y: expandFrame.origin.y),
                           size: .init(width: handleSize, height: expandFrame.height))
        if right.contains(location) {
            self = .right
            return
        }

        return nil
    }
}

private final class CropView: UIView {
    private static let minimumCropLength: CGFloat = 69.0

    private(set) var cropRect: CGRect = .zero
    private var gesturePosition: GridGesturePosition?
    private var aspectRatio: CGFloat?
    private let innerLines: InnerLines
    private let outerLines: OuterLines

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError() }

    init(lineColor: UIColor = .white) {
        innerLines = .init(strokeColor: lineColor.cgColor)
        outerLines = .init(fillColor: lineColor.cgColor)
        super.init(frame: .zero)
        translatesAutoresizingMaskIntoConstraints = false
        backgroundColor = .clear
        layer.addSublayer(innerLines)
        layer.addSublayer(outerLines)
        isUserInteractionEnabled = false
        innerLines.opacity = 0.0
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        innerLines.frame = bounds
        outerLines.frame = bounds
        if cropRect != .zero {
            draw()
        }
    }

    func shouldReceiveTouch(at location: CGPoint) -> Bool {
        let inner = cropRect.insetBy(dx: 22, dy: 22)
        let outer = cropRect.insetBy(dx: -22, dy: -22)
        //        print("inner:", inner)
        //        print("outer:", outer)
        return outer.contains(location) && !inner.contains(location)
    }

    func panGestureBegan(at locaion: CGPoint) {
        gesturePosition = .init(at: locaion, cropRect: cropRect)
        // show inner grid
        innerLines.setVisibility(true)
    }

    func panGestureChanged(by translation: CGPoint, contentOffset: CGPoint,
                           contentPadding: UIEdgeInsets, scaledContentSize: CGSize) {
        guard let gesturePosition else {
            return
        }

        if let aspectRatio {
            panGestureChanged(at: gesturePosition, by: translation,
                              contentOffset: contentOffset, contentPadding: contentPadding,
                              scaledContentSize: scaledContentSize, aspectRatio: aspectRatio)
        } else {
            panGestureChanged(at: gesturePosition, by: translation,
                              contentOffset: contentOffset, contentPadding: contentPadding,
                              scaledContentSize: scaledContentSize)
        }

        draw()
    }

    func panGestureEnded() {
        innerLines.setVisibility(false)
        gesturePosition = nil
    }

    func set(aspectRatio: CGFloat?) {
        self.aspectRatio = aspectRatio
    }

    func set(cropRect: CGRect, redraw: Bool = true) {
        self.cropRect = cropRect

        if redraw {
            draw()
        }
    }

    func setGrid(visible: Bool) {
        innerLines.setVisibility(visible)
    }

    func animate(cropRect: CGRect) {
        innerLines.draw(in: cropRect)
        outerLines.animatePath(to: cropRect)
        self.cropRect = cropRect
    }
}
// MARK: - private OverlayView
extension CropView {
    private func draw() {
        innerLines.draw(in: cropRect)
        outerLines.draw(in: cropRect)
    }

    private func panGestureChanged(at position: GridGesturePosition,
                                   by translation: CGPoint,
                                   contentOffset: CGPoint,
                                   contentPadding: UIEdgeInsets,
                                   scaledContentSize: CGSize) {
        switch position {
        case .topLeft:
            let (originX, width) = adjustLeftEdge(originX: cropRect.origin.x, width: cropRect.width,
                                                  translationX: translation.x, contentOffsetX: contentOffset.x,
                                                  paddingLeft: contentPadding.left)

            let (originY, height) = adjustTopEdge(originY: cropRect.origin.y, height: cropRect.height,
                                                  translationY: translation.y, contentOffsetY: contentOffset.y,
                                                  paddingTop: contentPadding.top)
            cropRect.origin = .init(x: originX, y: originY)
            cropRect.size = .init(width: width, height: height)
        case .topRight:
            let width = adjustRightEdge(originX: cropRect.origin.x, width: cropRect.width, translationX: translation.x,
                                        contentOffsetX: contentOffset.x, paddingRight: contentPadding.right,
                                        scaledWidth: scaledContentSize.width)
            let (originY, height) = adjustTopEdge(originY: cropRect.origin.y, height: cropRect.height,
                                                  translationY: translation.y, contentOffsetY: contentOffset.y,
                                                  paddingTop: contentPadding.top)
            cropRect.origin.y = originY
            cropRect.size = .init(width: width, height: height)
        case .bottomLeft:
            let (originX, width) = adjustLeftEdge(originX: cropRect.origin.x, width: cropRect.width,
                                                  translationX: translation.x, contentOffsetX: contentOffset.x,
                                                  paddingLeft: contentPadding.left)
            let height = adjustBottomEdge(originY: cropRect.origin.y, height: cropRect.height,
                                          translationY: translation.y, contentOffsetY: contentOffset.y,
                                          paddingBottom: contentPadding.bottom, scaledHeight: scaledContentSize.height)
            cropRect.origin.x = originX
            cropRect.size = .init(width: width, height: height)
        case .bottomRight:
            let width = adjustRightEdge(originX: cropRect.origin.x, width: cropRect.width,
                                        translationX: translation.x, contentOffsetX: contentOffset.x,
                                        paddingRight: contentPadding.right, scaledWidth: scaledContentSize.width)
            let height = adjustBottomEdge(originY: cropRect.origin.y, height: cropRect.height,
                                          translationY: translation.y, contentOffsetY: contentOffset.y,
                                          paddingBottom: contentPadding.bottom, scaledHeight: scaledContentSize.height)
            cropRect.size = .init(width: width, height: height)
        case .top:
            let (originY, height) = adjustTopEdge(originY: cropRect.origin.y, height: cropRect.height,
                                                  translationY: translation.y, contentOffsetY: contentOffset.y,
                                                  paddingTop: contentPadding.top)
            cropRect.origin.y = originY
            cropRect.size.height = height
        case .bottom:
            let height = adjustBottomEdge(originY: cropRect.origin.y, height: cropRect.height,
                                          translationY: translation.y, contentOffsetY: contentOffset.y,
                                          paddingBottom: contentPadding.bottom, scaledHeight: scaledContentSize.height)
            cropRect.size.height = height
        case .left:
            let (originX, width) = adjustLeftEdge(originX: cropRect.origin.x, width: cropRect.width,
                                                  translationX: translation.x, contentOffsetX: contentOffset.x,
                                                  paddingLeft: contentPadding.left)
            cropRect.origin.x = originX
            cropRect.size.width = width
        case .right:
            let width = adjustRightEdge(originX: cropRect.origin.x, width: cropRect.width,
                                        translationX: translation.x, contentOffsetX: contentOffset.x,
                                        paddingRight: contentPadding.right, scaledWidth: scaledContentSize.width)
            cropRect.size.width = width
        }
    }

    private func panGestureChanged(at position: GridGesturePosition,
                                   by translation: CGPoint,
                                   contentOffset: CGPoint,
                                   contentPadding: UIEdgeInsets,
                                   scaledContentSize: CGSize,
                                   aspectRatio: CGFloat) {
        switch position {
        case .topLeft:
            let originX: CGFloat
            let originY: CGFloat
            let width: CGFloat
            let height: CGFloat
            if abs(translation.x) > abs(translation.y) {
                (originX, width) = adjustLeftEdge(originX: cropRect.origin.x, width: cropRect.width,
                                                  translationX: translation.x, contentOffsetX: contentOffset.x,
                                                  paddingLeft: contentPadding.left)
                height = width / aspectRatio
                originY = cropRect.origin.y + (cropRect.height - height)
                if !isTopEdgeValid(height: height, originY: originY, contentOffsetY: contentOffset.y,
                                   paddingTop: contentPadding.top) {
                    return
                }
                if !isBottomEdgeValid(height: height, originY: originY, contentOffsetY: contentOffset.y,
                                      scaledHeight: scaledContentSize.height, paddingBottom: contentPadding.bottom) {
                    return
                }
            } else {
                (originY, height) = adjustTopEdge(originY: cropRect.origin.y, height: cropRect.height,
                                                  translationY: translation.y, contentOffsetY: contentOffset.y,
                                                  paddingTop: contentPadding.top)
                width = height * aspectRatio
                originX = cropRect.origin.x + (cropRect.width - width)
                if !isLeftEdgeValid(width: width, originX: originX, contentOffsetX: contentOffset.x,
                                    paddingLeft: contentPadding.left) {
                    return
                }
                if !isRightEdgeValid(width: width, originX: originX, contentOffsetX: contentOffset.x,
                                     scaledWidth: scaledContentSize.width, paddingRight: contentPadding.right) {
                    return
                }
            }
            cropRect = .init(x: originX, y: originY, width: width, height: height)
        case .topRight:
            let originY: CGFloat
            let width: CGFloat
            let height: CGFloat
            if abs(translation.x) > abs(translation.y) {
                width = adjustRightEdge(originX: cropRect.origin.x, width: cropRect.width,
                                        translationX: translation.x, contentOffsetX: contentOffset.x,
                                        paddingRight: contentPadding.right, scaledWidth: scaledContentSize.width)
                height = width / aspectRatio
                originY = cropRect.origin.y + (cropRect.height - height)
                if !isTopEdgeValid(height: height, originY: originY, contentOffsetY: contentOffset.y,
                                   paddingTop: contentPadding.top) {
                    return
                }
                if !isBottomEdgeValid(height: height, originY: originY, contentOffsetY: contentOffset.y,
                                      scaledHeight: scaledContentSize.height, paddingBottom: contentPadding.bottom) {
                    return
                }
            } else {
                (originY, height) = adjustTopEdge(originY: cropRect.origin.y, height: cropRect.height,
                                                  translationY: translation.y, contentOffsetY: contentOffset.y,
                                                  paddingTop: contentPadding.top)
                width = height * aspectRatio
                if !isLeftEdgeValid(width: width, originX: cropRect.origin.x, contentOffsetX: contentOffset.x,
                                    paddingLeft: contentPadding.left) {
                    return
                }
                if !isRightEdgeValid(width: width, originX: cropRect.origin.x, contentOffsetX: contentOffset.x,
                                     scaledWidth: scaledContentSize.width, paddingRight: contentPadding.right) {
                    return
                }
            }
            cropRect.origin.y = originY
            cropRect.size = .init(width: width, height: height)
        case .bottomLeft:
            let originX: CGFloat
            let width: CGFloat
            let height: CGFloat
            if abs(translation.x) > abs(translation.y) {
                (originX, width) = adjustLeftEdge(originX: cropRect.origin.x, width: cropRect.width,
                                                  translationX: translation.x, contentOffsetX: contentOffset.x,
                                                  paddingLeft: contentPadding.left)
                height = width / aspectRatio
                if !isTopEdgeValid(height: height, originY: cropRect.origin.y, contentOffsetY: contentOffset.y,
                                   paddingTop: contentPadding.top) {
                    return
                }
                if !isBottomEdgeValid(height: height, originY: cropRect.origin.y, contentOffsetY: contentOffset.y,
                                      scaledHeight: scaledContentSize.height, paddingBottom: contentPadding.bottom) {
                    return
                }
            } else {
                height = adjustBottomEdge(originY: cropRect.origin.y, height: cropRect.height,
                                          translationY: translation.y, contentOffsetY: contentOffset.y,
                                          paddingBottom: contentPadding.bottom, scaledHeight: scaledContentSize.height)
                width = height * aspectRatio
                originX = cropRect.origin.x + (cropRect.width - width)
                if !isLeftEdgeValid(width: width, originX: originX, contentOffsetX: contentOffset.x,
                                    paddingLeft: contentPadding.left) {
                    return
                }
                if !isRightEdgeValid(width: width, originX: originX, contentOffsetX: contentOffset.x,
                                     scaledWidth: scaledContentSize.width, paddingRight: contentPadding.right) {
                    return
                }
            }
            cropRect.origin.x = originX
            cropRect.size = .init(width: width, height: height)
        case .bottomRight:
            let width: CGFloat
            let height: CGFloat
            if abs(translation.x) > abs(translation.y) {
                width = adjustRightEdge(originX: cropRect.origin.x, width: cropRect.width,
                                        translationX: translation.x, contentOffsetX: contentOffset.x,
                                        paddingRight: contentPadding.right, scaledWidth: scaledContentSize.width)
                height = width / aspectRatio
                if !isTopEdgeValid(height: height, originY: cropRect.origin.y, contentOffsetY: contentOffset.y,
                                   paddingTop: contentPadding.top) {
                    return
                }
                if !isBottomEdgeValid(height: height, originY: cropRect.origin.y, contentOffsetY: contentOffset.y,
                                      scaledHeight: scaledContentSize.height, paddingBottom: contentPadding.bottom) {
                    return
                }
            } else {
                height = adjustBottomEdge(originY: cropRect.origin.y, height: cropRect.height,
                                          translationY: translation.y, contentOffsetY: contentOffset.y,
                                          paddingBottom: contentPadding.bottom, scaledHeight: scaledContentSize.height)
                width = height * aspectRatio
                if !isLeftEdgeValid(width: width, originX: cropRect.origin.x, contentOffsetX: contentOffset.x,
                                    paddingLeft: contentPadding.left) {
                    return
                }
                if !isRightEdgeValid(width: width, originX: cropRect.origin.x, contentOffsetX: contentOffset.x,
                                     scaledWidth: scaledContentSize.width, paddingRight: contentPadding.right) {
                    return
                }
            }
            cropRect.size = .init(width: width, height: height)
        case .top:
            let (originY, height) = adjustTopEdge(originY: cropRect.origin.y, height: cropRect.height,
                                                  translationY: translation.y, contentOffsetY: contentOffset.y,
                                                  paddingTop: contentPadding.top)
            let width = height * aspectRatio
            let originX = cropRect.origin.x + (cropRect.width - width) / 2
            if !isLeftEdgeValid(width: width, originX: originX, contentOffsetX: contentOffset.x,
                                paddingLeft: contentPadding.left) {
                return
            }
            if !isRightEdgeValid(width: width, originX: originX, contentOffsetX: contentOffset.x,
                                 scaledWidth: scaledContentSize.width, paddingRight: contentPadding.right) {
                return
            }
            cropRect = .init(x: originX, y: originY, width: width, height: height)
        case .bottom:
            let height = adjustBottomEdge(originY: cropRect.origin.y, height: cropRect.height,
                                          translationY: translation.y, contentOffsetY: contentOffset.y,
                                          paddingBottom: contentPadding.bottom, scaledHeight: scaledContentSize.height)
            let width = height * aspectRatio
            let originX = cropRect.origin.x + (cropRect.width - width) / 2
            if !isLeftEdgeValid(width: width, originX: originX, contentOffsetX: contentOffset.x,
                                paddingLeft: contentPadding.left) {
                return
            }
            if !isRightEdgeValid(width: width, originX: originX, contentOffsetX: contentOffset.x,
                                 scaledWidth: scaledContentSize.width, paddingRight: contentPadding.right) {
                return
            }
            cropRect.origin.x = originX
            cropRect.size = .init(width: width, height: height)
        case .left:
            let (originX, width) = adjustLeftEdge(originX: cropRect.origin.x, width: cropRect.width,
                                                  translationX: translation.x, contentOffsetX: contentOffset.x,
                                                  paddingLeft: contentPadding.left)
            let height = width / aspectRatio
            let originY = cropRect.origin.y + (cropRect.height - height) / 2
            if !isTopEdgeValid(height: height, originY: originY, contentOffsetY: contentOffset.y,
                               paddingTop: contentPadding.top) {
                return
            }
            if !isBottomEdgeValid(height: height, originY: originY, contentOffsetY: contentOffset.y,
                                  scaledHeight: scaledContentSize.height, paddingBottom: contentPadding.bottom) {
                return
            }
            cropRect = .init(x: originX, y: originY, width: width, height: height)
        case .right:
            let width = adjustRightEdge(originX: cropRect.origin.x, width: cropRect.width,
                                        translationX: translation.x, contentOffsetX: contentOffset.x,
                                        paddingRight: contentPadding.right, scaledWidth: scaledContentSize.width)
            let height = width / aspectRatio
            let originY = cropRect.origin.y + (cropRect.height - height) / 2
            if !isTopEdgeValid(height: height, originY: originY, contentOffsetY: contentOffset.y,
                               paddingTop: contentPadding.top) {
                return
            }
            if !isBottomEdgeValid(height: height, originY: originY, contentOffsetY: contentOffset.y,
                                  scaledHeight: scaledContentSize.height, paddingBottom: contentPadding.bottom) {
                return
            }
            cropRect.origin.y = originY
            cropRect.size = .init(width: width, height: height)
        }
    }

    private func adjustLeftEdge(originX: CGFloat, width: CGFloat, translationX: CGFloat,
                                contentOffsetX: CGFloat, paddingLeft: CGFloat) -> (CGFloat, CGFloat) {
        var originX = originX + translationX
        var width = width - translationX
        if contentOffsetX + originX < 0 {
            originX = -contentOffsetX
            width = cropRect.origin.x - originX + cropRect.width
        } else if originX < paddingLeft {
            originX = paddingLeft
            width = cropRect.origin.x - originX + cropRect.width
        } else if width < Self.minimumCropLength {
            originX = cropRect.origin.x + cropRect.width - Self.minimumCropLength
            width = Self.minimumCropLength
        }
        return (originX, width)
    }

    private func adjustRightEdge(originX: CGFloat, width: CGFloat, translationX: CGFloat,
                                 contentOffsetX: CGFloat, paddingRight: CGFloat,
                                 scaledWidth: CGFloat) -> CGFloat {
        var width = width + translationX
        if contentOffsetX + originX + width > scaledWidth {
            width = scaledWidth - (contentOffsetX + originX)
        } else if bounds.width - paddingRight < originX + width {
            width = bounds.width - (originX + paddingRight)
        } else if width < Self.minimumCropLength {
            width = Self.minimumCropLength
        }
        return width
    }

    private func adjustTopEdge(originY: CGFloat, height: CGFloat, translationY: CGFloat,
                               contentOffsetY: CGFloat, paddingTop: CGFloat) -> (CGFloat, CGFloat) {
        var originY = originY + translationY
        var height = height - translationY
        if contentOffsetY + originY < 0 {
            originY = -contentOffsetY
            height = cropRect.origin.y - originY + cropRect.height
        } else if originY < paddingTop {
            originY = paddingTop
            height = cropRect.origin.y - originY + cropRect.height
        } else if height < Self.minimumCropLength {
            originY = cropRect.origin.y + cropRect.height - Self.minimumCropLength
            height = Self.minimumCropLength
        }
        return (originY, height)
    }

    private func adjustBottomEdge(originY: CGFloat, height: CGFloat, translationY: CGFloat,
                                  contentOffsetY: CGFloat, paddingBottom: CGFloat,
                                  scaledHeight: CGFloat) -> CGFloat {
        var height = height + translationY
        if contentOffsetY + originY + height > scaledHeight {
            height = scaledHeight - (contentOffsetY + originY)
        } else if originY + height > bounds.height - paddingBottom {
            height = bounds.height - (originY + paddingBottom)
        } else if height < Self.minimumCropLength {
            height = Self.minimumCropLength
        }
        return height
    }

    private func isRightEdgeValid(width: CGFloat, originX: CGFloat, contentOffsetX: CGFloat,
                                  scaledWidth: CGFloat, paddingRight: CGFloat) -> Bool {
        !(width < Self.minimumCropLength || contentOffsetX + originX + width > scaledWidth ||
            originX + width > bounds.width - paddingRight)
    }

    private func isBottomEdgeValid(height: CGFloat, originY: CGFloat, contentOffsetY: CGFloat,
                                   scaledHeight: CGFloat, paddingBottom: CGFloat) -> Bool {
        !(height < Self.minimumCropLength || contentOffsetY + originY + height > scaledHeight ||
            originY + height > bounds.height - paddingBottom)
    }

    private func isLeftEdgeValid(width: CGFloat, originX: CGFloat, contentOffsetX: CGFloat,
                                 paddingLeft: CGFloat) -> Bool {
        !(width < Self.minimumCropLength || contentOffsetX + originX < 0 ||
            originX < paddingLeft)
    }

    private func isTopEdgeValid(height: CGFloat, originY: CGFloat, contentOffsetY: CGFloat,
                                paddingTop: CGFloat) -> Bool {
        !(height < Self.minimumCropLength || contentOffsetY + originY < 0 ||
            originY < paddingTop)
    }
}

private final class TranslucentView: UIView {
    private class MaskLayer: CAShapeLayer, CAAnimationDelegate {
        // rect to set after animation has ended
        private var rect: CGRect = .zero

        convenience init(fillRule: CAShapeLayerFillRule) {
            self.init()
            self.fillRule = fillRule
        }

        func setPath(rect: CGRect) {
            path = path(for: rect)
        }

        func animatePath(rect: CGRect) {
            self.rect = rect
            let path = path(for: rect)
            let animation = CABasicAnimation(pathAnimation: path)
            animation.delegate = self
            add(animation, forKey: "maskAnimation")
        }

        private func path(for rect: CGRect) -> CGPath {
            let bezierPath = UIBezierPath(rect: rect)
            bezierPath.append(UIBezierPath(rect: bounds))
            return bezierPath.cgPath
        }

        func animationDidStop(_ anim: CAAnimation, finished flag: Bool) {
            setPath(rect: rect)
            removeAnimation(forKey: "maskAnimation")
        }
    }

    private final class BlurView: UIVisualEffectView {
        private let maskLayer: MaskLayer = .init(fillRule: .evenOdd)
        private var maskRect: CGRect = .zero

        @available(*, unavailable)
        required init?(coder: NSCoder) { fatalError() }

        override init(effect: UIVisualEffect?) {
            super.init(effect: effect)
            layer.mask = maskLayer
            isUserInteractionEnabled = false
        }

        override func layoutSubviews() {
            super.layoutSubviews()
            maskLayer.frame = bounds
            layer.frame = bounds
            if maskRect != .zero {
                maskLayer.setPath(rect: maskRect)
            }
        }

        func setPath(rect: CGRect) {
            maskRect = rect
            maskLayer.setPath(rect: rect)
        }

        func animatePath(rect: CGRect) {
            maskRect = rect
            maskLayer.animatePath(rect: rect)
        }

        func isMaskAnimation(_ anim: CAAnimation) -> Bool {
            maskLayer.animation(forKey: "BlurView") == anim
        }

        func removeAnimation() {
            maskLayer.removeAllAnimations()
        }
    }

    var isBlurViewVisible: Bool {
        blurView.alpha == 1
    }

    private let blurView: BlurView = .init(effect: UIBlurEffect(style: .systemThinMaterialDark))
    private let translucentLayer: CALayer = .init()
    private let maskLayer: MaskLayer = .init(fillRule: .evenOdd)
    private var maskRect: CGRect = .zero

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError() }

    init() {
        super.init(frame: .zero)
        add(subview: blurView)
        layer.addSublayer(translucentLayer)
        translucentLayer.backgroundColor = UIColor.black.withAlphaComponent(0.4).cgColor
        translucentLayer.opacity = 0
        layer.mask = maskLayer
        isUserInteractionEnabled = false
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        translucentLayer.frame = bounds
        maskLayer.frame = bounds
        layer.frame = bounds
        if maskRect != .zero {
            setMask(rect: maskRect)
        }
    }

    func setMask(rect: CGRect) {
        maskRect = rect
        maskLayer.setPath(rect: rect)
        blurView.setPath(rect: rect)
    }

    func animateMask(rect: CGRect) {
        maskRect = rect
        maskLayer.animatePath(rect: rect)
        blurView.animatePath(rect: rect)
    }

    func setBlurView(visible: Bool) {
        if (visible && isBlurViewVisible) || (!visible && !isBlurViewVisible) {
            return
        }

        if !visible {
            translucentLayer.opacity = 1
        }

        let curve = visible ? UIView.AnimationOptions.curveEaseIn : .curveEaseOut
        UIView.animate(withDuration: 0.25, delay: 0, options: curve) {
            self.blurView.alpha = visible ? 1 : 0
        } completion: { _ in
            if visible {
                self.translucentLayer.opacity = 0
            }
        }
    }
}
// MARK: - OverlayView
final class OverlayView: UIView {
    var cropRect: CGRect { cropView.cropRect }
    var isBlurViewVisible: Bool { translucentView.isBlurViewVisible }

    private let cropView: CropView = .init()
    private let translucentView: TranslucentView = .init()

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError() }

    init() {
        super.init(frame: .zero)
        isUserInteractionEnabled = false
        translatesAutoresizingMaskIntoConstraints = false
        backgroundColor = .clear
        add(subview: translucentView)
        add(subview: cropView)
    }

    func set(cropRect: CGRect) {
        cropView.set(cropRect: cropRect, redraw: false)
        translucentView.setMask(rect: cropRect)
    }

    func update(cropRect: CGRect, animate: Bool = false) {
        if animate {
            cropView.animate(cropRect: cropRect)
            translucentView.animateMask(rect: cropRect)
        } else {
            cropView.set(cropRect: cropRect)
            translucentView.setMask(rect: cropRect)
        }
    }

    func update(cropRect: CGRect) {
        cropView.set(cropRect: cropRect)
        translucentView.setMask(rect: cropRect)
    }

    func set(aspectRatio: CGFloat?) {
        cropView.set(aspectRatio: aspectRatio)
    }

    func shouldReceiveTouch(at location: CGPoint) -> Bool {
        cropView.shouldReceiveTouch(at: location)
    }

    func panGestureBegan(at locaion: CGPoint) {
        cropView.panGestureBegan(at: locaion)
        setBlurView(visible: false)
    }

    func panGestureChanged(by translation: CGPoint, contentOffset: CGPoint,
                           contentPadding: UIEdgeInsets, scaledContentSize: CGSize) {
        cropView.panGestureChanged(by: translation, contentOffset: contentOffset,
                                   contentPadding: contentPadding,
                                   scaledContentSize: scaledContentSize)
        translucentView.setMask(rect: cropRect)
    }

    func panGestureEnded() {
        cropView.panGestureEnded()
    }

    func setBlurView(visible: Bool) {
        translucentView.setBlurView(visible: visible)
    }

    func setGrid(visible: Bool) {
        cropView.setGrid(visible: visible)
    }
}
