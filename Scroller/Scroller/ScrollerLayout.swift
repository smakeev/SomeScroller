//
//  SomeScrollerLayout.swift
//  SomeScroller
//
//  Created by Sergey Makeev on 14/11/2018.
//  Copyright © 2020 SomeProjects. All rights reserved.
//

import UIKit

// MARK: - ScrollerLayoutDelegate

//  Delegate for the collecion view layout.
//  This is a class protocol to suppot weak references to it (as usually delegates do)
//  All methods get collectionView as a parameter to support external delegation in the future if needed once.

internal protocol ScrollerLayoutDelegate: class {
    func collectionView(collectionView: UICollectionView, heightForItemAtIndexPath indexPath: IndexPath) -> CGFloat
    func collectionView(collectionView: UICollectionView, widthForItemAtIndexPath indexPath: IndexPath) -> CGFloat
    func realElementsFor(collectionView: UICollectionView) -> Int
    func orientationFor(collectionView: UICollectionView) -> ScrollerOrientation
    func gravityFor(collecionView: UICollectionView) -> ScrollerGravityType
    func delimiterGravityFor(collectionView: UICollectionView) -> ScrollerDelimiterGravityType
    func scrollableFor(collectionView: UICollectionView) -> Bool
    func hasDelimiterFor(collectionView: UICollectionView) -> Bool
    func delimiterWidthFor(collectionView: UICollectionView) -> CGFloat
}

// MARK: - ScrollerLayout

//  The layout for the collecion view.
//  Usually just presents elements one after another.
//  If all elements are on the screen could have geps to fill an empty space.
//  For empty space filling 'gravity' and 'DelimiterGravity' could be used to provide
//  the way

class ScrollerLayout: UICollectionViewLayout {

    // MARK: - ScrollerLayout variables

    weak var delegate: ScrollerLayoutDelegate?
    internal var ready: Bool = false
    internal var cached = [UICollectionViewLayoutAttributes]()

    //on screen element(view) width.
    internal var width: CGFloat {
        guard let validCollectionView = collectionView else {return 0}
        return validCollectionView.bounds.width
    }
    //on screen element(view) height.
    internal var height: CGFloat {
            if let validCollectionView = collectionView {
                return validCollectionView.bounds.height
            }
            return 0
    }

    internal var contentWidth: CGFloat = 0.0
    internal var contentHeight: CGFloat = 0.0

    //all elements width or height (depends on orientation) on the one screen. Means just to show all of them ony once.
    //This includes Delimiters if there are them.
    //Note: Last element does not have a Delimiter.
    internal var allElementsSize: CGFloat = 0.0

    override var collectionViewContentSize: CGSize {
            return CGSize(width: contentWidth, height: contentHeight)
    }

    // MARK: - ScrollerLayout functions

    //additional methods

    func allElementsWidth() -> CGFloat {
        guard let validCollectionView = collectionView, let validDelegate = delegate else {return 0}

        if validDelegate.orientationFor(collectionView: validCollectionView) == .horizontal {
            return allElementsSize.rounded(.up)
        } else {
            return width.rounded(.up)
        }
    }

    func allElementsHeight() -> CGFloat {
        guard let validCollectionView = collectionView, let validDelegate = delegate else {return 0}
        if validDelegate.orientationFor(collectionView: validCollectionView) == .vertical {
            return allElementsSize.rounded(.up)
        } else {
            return height.rounded(.up)
        }
    }

    func elementRect(by indexPath: IndexPath) -> CGRect {
        guard let validCollectionView = collectionView, let validDelegate = delegate else { return CGRect.zero}

        let visibleLayoutAttributes = cached[0]

        if !validDelegate.hasDelimiterFor(collectionView: validCollectionView) {
            //without Delimiters just multiply elementindex on it's size to get offset
            if validDelegate.orientationFor(collectionView: validCollectionView) == .horizontal {
                let originX = (CGFloat(indexPath.row) * visibleLayoutAttributes.frame.width).rounded(.up)
                return CGRect(x: originX, y: 0, width: visibleLayoutAttributes.frame.width.rounded(.up), height: visibleLayoutAttributes.frame.height.rounded(.up))
            } else {
                let originY = (CGFloat(indexPath.row) * visibleLayoutAttributes.frame.height).rounded(.up)
                return CGRect(x: 0, y: originY, width: visibleLayoutAttributes.frame.width.rounded(.up), height: visibleLayoutAttributes.frame.height.rounded(.up))
            }
        } else {
            let visibleLayoutAtributesForDelimiter = cached[1]

            var workingSize: CGFloat
            var delimiterWorkingSize: CGFloat
            let isHorizontal = validDelegate.orientationFor(collectionView: validCollectionView) == .horizontal
            if  isHorizontal {
                workingSize = visibleLayoutAttributes.frame.width.rounded(.up)
                delimiterWorkingSize = visibleLayoutAtributesForDelimiter.frame.width.rounded(.up)
            } else {
                workingSize = visibleLayoutAttributes.frame.height.rounded(.up)
                delimiterWorkingSize = visibleLayoutAtributesForDelimiter.frame.height.rounded(.up)
            }
            if indexPath.row % 2 == 0 {
                //element
                let elementsOfDiffKind = indexPath.row / 2
                let offset = (CGFloat(elementsOfDiffKind) * workingSize + CGFloat(elementsOfDiffKind) * delimiterWorkingSize).rounded(.up)
                return CGRect(x: isHorizontal ? offset : 0, y: !isHorizontal ? offset : 0, width: visibleLayoutAttributes.frame.width.rounded(.up), height: visibleLayoutAttributes.frame.height.rounded(.up))
            } else {
                //Delimiter
                let elements = (indexPath.row + 1) / 2
                var delimiters = elements - 1
                if delimiters < 0 {
                    delimiters = 0
                }
                let offset = (CGFloat(elements) * workingSize + CGFloat(delimiters) * delimiterWorkingSize).rounded(.up)
                return CGRect(x: isHorizontal ? offset : 0, y: !isHorizontal ? offset : 0, width: visibleLayoutAtributesForDelimiter.frame.width.rounded(.up), height: visibleLayoutAtributesForDelimiter.frame.height.rounded(.up))
            }
        }
    }

    //returns indexes of cells inside the screen intersects with rect
    func elements(in rect: CGRect) -> [IndexPath] {
        var result: [IndexPath] = [IndexPath]()
        let index = elementsBinarySearch(searchRect: rect)
        if let index = index {
            result.append(index)
            //search for right side
            var shouldSearch = true
            var nextIndexPath = index

            while shouldSearch {
                if nextIndexPath.row + 1 >= infiniteSize {
                    shouldSearch = false
                    break
                }
                nextIndexPath = IndexPath(row: (nextIndexPath.row + 1), section: 0)
                if elementRect(by: nextIndexPath).intersects(rect) {
                    result.append(nextIndexPath)
                } else {
                    shouldSearch = false
                }
            }
            //search for left side
            shouldSearch = true
            nextIndexPath = index
            while shouldSearch {
                if nextIndexPath.row - 1 < 0 {
                    shouldSearch = false
                    break
                }
                nextIndexPath = IndexPath(row: (nextIndexPath.row - 1), section: 0)
                if elementRect(by: nextIndexPath).intersects(rect) {
                    result.append(nextIndexPath)
                } else {
                    shouldSearch = false
                }
            }
        }
        return result
    }

    //Helper methods:
    internal func calculateRightContentSize() {
        contentWidth = self.width
        contentHeight = self.height
        guard let validCollectionView = collectionView, let validDelegate = delegate else {return}
        if validDelegate.orientationFor(collectionView: validCollectionView) == .horizontal {
            if validDelegate.scrollableFor(collectionView: validCollectionView) && validDelegate.hasDelimiterFor(collectionView: validCollectionView) {
                contentWidth = ((CGFloat(infiniteSize) / 2) * validDelegate.delimiterWidthFor(collectionView: validCollectionView) + (CGFloat(infiniteSize) / 2) * validDelegate.collectionView(collectionView: validCollectionView, widthForItemAtIndexPath: IndexPath(row: 0, section: 0))).rounded(.up)
            } else if validDelegate.scrollableFor(collectionView: validCollectionView) {
                contentWidth = (CGFloat(infiniteSize) * allElementsWidth() / CGFloat(validDelegate.realElementsFor(collectionView: validCollectionView))).rounded(.up)
            }
        } else {
            if validDelegate.scrollableFor(collectionView: validCollectionView) {
                contentHeight = (CGFloat(infiniteSize) * allElementsHeight() / CGFloat(validDelegate.realElementsFor(collectionView: validCollectionView))).rounded(.up)
            }
        }
    }

    internal func calculateOneScreenElementsSize(elementsNumber: inout Int) {
        allElementsSize = 0
        guard let validDelegate = delegate else {allElementsSize = 0; return}
        guard let validCollectionView = collectionView, validDelegate.realElementsFor(collectionView: validCollectionView) > 0 else {return}
        if validDelegate.hasDelimiterFor(collectionView: validCollectionView) {
            elementsNumber += validDelegate.realElementsFor(collectionView: validCollectionView) - 1
            //if not all elements are on one screen than last element should have a Delimiter
            if validDelegate.scrollableFor(collectionView: validCollectionView) {
                elementsNumber += 1
            }
        }

        for item in 0..<elementsNumber {
            let indexPath = IndexPath(item: item, section: 0)
            if validDelegate.orientationFor(collectionView: validCollectionView) == .horizontal {
                allElementsSize +=  validDelegate.collectionView(collectionView: validCollectionView, widthForItemAtIndexPath: indexPath)
            } else {
                allElementsSize += validDelegate.collectionView(collectionView: validCollectionView, heightForItemAtIndexPath: indexPath)
            }
        }
    }

    internal func prepareForGravityIfNeeded(offset: inout CGFloat, justifyParam: inout CGFloat, freeSpace: inout CGFloat, currentIndexInPercentVector: inout Int) {
        guard let validCollectionView = collectionView, let validDelegate = delegate else {return}

        if !validDelegate.scrollableFor(collectionView: validCollectionView) {
            //handle gravity
            let gravity = validDelegate.gravityFor(collecionView: validCollectionView)

            switch gravity {
            case .left, .top: break; //nothing to do
            case .right, .bottom:
                if validDelegate.orientationFor(collectionView: validCollectionView) == .horizontal {
                    offset = width - allElementsWidth()
                } else {
                    offset = height - allElementsHeight()
                }
            case .center:
                if validDelegate.orientationFor(collectionView: validCollectionView) == .horizontal {
                    offset = (width - allElementsWidth()) / 2
                } else {
                    offset = (height - allElementsHeight()) / 2
                }
            case .justify:
                let places = validDelegate.realElementsFor(collectionView: validCollectionView) + 1
                if validDelegate.orientationFor(collectionView: validCollectionView) == .horizontal {
                    freeSpace = width - allElementsWidth()
                } else {
                    freeSpace = height - allElementsHeight()
                }

                if freeSpace != 0 && validDelegate.delimiterGravityFor(collectionView: validCollectionView) == .fill {
                    let delimiterWidth = validDelegate.delimiterWidthFor(collectionView: validCollectionView)
                    if delimiterWidth != 0 {
                        freeSpace = (freeSpace + CGFloat(validDelegate.realElementsFor(collectionView: validCollectionView) - 1) * delimiterWidth).rounded(.up)
                    }
                }

                if freeSpace == 0 {
                    break
                }
                justifyParam = (freeSpace / CGFloat(places)).rounded(.up)
                offset = justifyParam
            case .adjustable(let percentVector):
                let places = validDelegate.realElementsFor(collectionView: validCollectionView) + 1
                if validDelegate.orientationFor(collectionView: validCollectionView) == .horizontal {
                    freeSpace = width - allElementsWidth()
                } else {
                    freeSpace = height - allElementsHeight()
                }

                if freeSpace != 0 && validDelegate.delimiterGravityFor(collectionView: validCollectionView) == .fill {
                    let delimiterWidth = validDelegate.delimiterWidthFor(collectionView: validCollectionView)
                    if delimiterWidth != 0 {
                        freeSpace = (freeSpace + CGFloat(validDelegate.realElementsFor(collectionView: validCollectionView) - 1) * delimiterWidth).rounded(.up)
                    }
                } else {
                    break
                }

                //check the vector
                if percentVector.count != places {
                    fatalError("Scroller adjustable vector has wrong parameters number")
                }
                //swiftlint:disable control_statement
                if (percentVector.reduce(0) { $0 + $1}) != 100 {
                    fatalError("Scroller adjustable vector must have 100 as a sum of all arguments")
                }
                //swiftlint:enable control_statement
                offset = (freeSpace * CGFloat(percentVector[0]) / 100).rounded(.up)
                justifyParam = (freeSpace * CGFloat(percentVector[1]) / 100).rounded(.up)
                currentIndexInPercentVector = 1
            }
        }
    }

    internal func elementsBinarySearch(searchRect: CGRect) -> IndexPath? {
        guard let validCollectionView = collectionView, let validDelegate = delegate else {return nil}
        var lowerIndex = 0
        var upperIndex = infiniteSize

        while true {
            let currentIndex = (lowerIndex + upperIndex)/2
            if elementRect(by: IndexPath(row: currentIndex, section: 0)).intersects(searchRect) {
                return IndexPath(row: currentIndex, section: 0)
            } else if lowerIndex > upperIndex {
                return nil
            } else {
                if validDelegate.orientationFor(collectionView: validCollectionView) == .horizontal {
                    if elementRect(by: IndexPath(row: currentIndex, section: 0)).minX > searchRect.minX {
                        upperIndex = currentIndex - 1
                    } else {
                        lowerIndex = currentIndex + 1
                    }
                } else {
                    if elementRect(by: IndexPath(row: currentIndex, section: 0)).minY > searchRect.minY {
                        upperIndex = currentIndex - 1
                    } else {
                        lowerIndex = currentIndex + 1
                    }
                }
            }
        }
    }

    internal func frameWith(offset: CGFloat, indexPath: IndexPath) -> CGRect? {
        guard let validCollectionView = collectionView, let validDelegate = delegate else {return nil}
        let height = validDelegate.collectionView(collectionView: validCollectionView, heightForItemAtIndexPath: indexPath)
        let width = validDelegate.collectionView(collectionView: validCollectionView, widthForItemAtIndexPath: indexPath)
        if validDelegate.orientationFor(collectionView: validCollectionView) == .horizontal {
            return CGRect(x: offset, y: 0, width: width.rounded(.up), height: height.rounded(.up))
        } else {
            return CGRect(x: 0, y: offset, width: width.rounded(.up), height: height.rounded(.up))
        }
    }
    //swiftlint:disable function_parameter_count
    internal func  prepareScreen(indexPath: IndexPath, frame: inout CGRect, offset: inout CGFloat, justifyParam: inout CGFloat, freeSpace: CGFloat, currentIndexInPercentVector: inout Int, elementIndex item: Int, width: CGFloat, height: CGFloat) {
        guard let validCollectionView = collectionView, let validDelegate = delegate else {return}
        let isHorizontal = validDelegate.orientationFor(collectionView: validCollectionView) == .horizontal
        let workingSize = isHorizontal ? width.rounded(.up) : height.rounded(.up)
        switch validDelegate.gravityFor(collecionView: validCollectionView) {
        case .justify where !validDelegate.scrollableFor(collectionView: validCollectionView):
            let delimiterWidth = validDelegate.delimiterWidthFor(collectionView: validCollectionView).rounded(.up)
            if delimiterWidth > 0 {
                if validDelegate.delimiterGravityFor(collectionView: validCollectionView) == .left ||
                    validDelegate.delimiterGravityFor(collectionView: validCollectionView) == .top {
                } else if validDelegate.delimiterGravityFor(collectionView: validCollectionView) == .right ||
                    validDelegate.delimiterGravityFor(collectionView: validCollectionView) == .bottom {
                } else if validDelegate.delimiterGravityFor(collectionView: validCollectionView) == .center {
                    offset += workingSize + justifyParam / 2
                } else if validDelegate.delimiterGravityFor(collectionView: validCollectionView) == .fill &&  (indexPath.row % 2 == 1) {
                    if freeSpace == 0 {
                        offset += workingSize
                    } else {
                        frame = CGRect(x: isHorizontal ? offset : 0, y: !isHorizontal ? offset : 0, width: isHorizontal ? justifyParam : self.width, height: !isHorizontal ? justifyParam : self.height)
                        offset += justifyParam
                    }
                } else if indexPath.row % 2 == 0 {
                    offset += workingSize
                } else {
                    offset += workingSize  + justifyParam
                }
            } else {
                offset += workingSize + justifyParam
            }
        case .adjustable(let percentVector) where !validDelegate.scrollableFor(collectionView: validCollectionView):
            let delimiterWidth = validDelegate.delimiterWidthFor(collectionView: validCollectionView)
            if delimiterWidth == 0 {
                offset += workingSize + justifyParam
                if item + 2 <= validDelegate.realElementsFor(collectionView: validCollectionView) {
                    justifyParam = (CGFloat(percentVector[item + 2]) * freeSpace / 100).rounded(.up)
                }
            } else {
                switch validDelegate.delimiterGravityFor(collectionView: validCollectionView) {
                case .left, .top:
                    if indexPath.row % 2 == 0 {
                        offset += workingSize
                    } else {
                        offset += workingSize + justifyParam
                        justifyParam = (CGFloat(percentVector[currentIndexInPercentVector + 1]) * freeSpace / 100).rounded(.up)
                        currentIndexInPercentVector += 1
                    }
                case .right, .bottom:
                    if indexPath.row % 2 == 0 {
                        offset += workingSize + justifyParam
                    } else {
                        offset += workingSize
                        justifyParam = (CGFloat(percentVector[currentIndexInPercentVector + 1]) * freeSpace / 100).rounded(.up)
                        currentIndexInPercentVector += 1
                    }
                case .center:
                    if indexPath.row % 2 == 0 {
                        offset += workingSize + justifyParam / 2
                    } else {
                        offset += workingSize + justifyParam / 2
                        justifyParam = (CGFloat(percentVector[currentIndexInPercentVector + 1]) * freeSpace / 100).rounded(.up)
                        currentIndexInPercentVector += 1
                    }
                case .fill:
                    if indexPath.row % 2 == 0 {
                        offset += workingSize
                    } else if freeSpace == 0 {
                        offset += validDelegate.delimiterWidthFor(collectionView: validCollectionView)
                    } else {
                        frame = CGRect(x: isHorizontal ? offset : 0, y: !isHorizontal ? offset : 0, width: isHorizontal ? justifyParam : width, height: !isHorizontal ? justifyParam : height)
                        offset += justifyParam
                        justifyParam = (CGFloat(percentVector[currentIndexInPercentVector + 1]) * freeSpace / 100).rounded(.up)
                        currentIndexInPercentVector += 1
                    }
                }
            }
        default:
            offset += workingSize
        }
    }
    //swiftlint:enable function_parameter_count
    //Layout Standard methods overriding

    // MARK: - ScrollerLayout overriden functions

    override func invalidateLayout() {
        contentWidth = 0
        ready = false
        cached = [UICollectionViewLayoutAttributes]()
        super.invalidateLayout()
    }

    override func prepare() {
        guard !ready, let validCollectionView = collectionView, let validDelegate = delegate else {return}

        var justifyParam: CGFloat = 0.0
        var offset: CGFloat = 0.0
        var freeSpace: CGFloat = 0.0
        var currentIndexInPercentVector = 0
        var elementsNumber = validDelegate.realElementsFor(collectionView: validCollectionView)

        calculateOneScreenElementsSize(elementsNumber: &elementsNumber)
        prepareForGravityIfNeeded(offset: &offset, justifyParam: &justifyParam, freeSpace: &freeSpace, currentIndexInPercentVector: &currentIndexInPercentVector)
        for item in 0..<elementsNumber {

            let indexPath = IndexPath(item: item, section: 0)

            let height = validDelegate.collectionView(collectionView: validCollectionView, heightForItemAtIndexPath: indexPath).rounded(.up)
            let width = validDelegate.collectionView(collectionView: validCollectionView, widthForItemAtIndexPath: indexPath).rounded(.up)
            var frame: CGRect = frameWith(offset: offset, indexPath: indexPath)! //can explicitly unwrap here due to delegate is not nil.
            prepareScreen(indexPath: indexPath,
                          frame: &frame,
                          offset: &offset,
                          justifyParam: &justifyParam,
                          freeSpace: freeSpace,
                          currentIndexInPercentVector: &currentIndexInPercentVector,
                          elementIndex: item,
                          width: width,
                          height: height)
            let attributes = UICollectionViewLayoutAttributes(forCellWith: indexPath)
            attributes.frame = frame
            cached.append(attributes)
        }

        calculateRightContentSize()
        ready = true
    }

    override func layoutAttributesForElements(in rect: CGRect) -> [UICollectionViewLayoutAttributes]? {
        var visibleLayoutAttributes = [UICollectionViewLayoutAttributes]()

        if let validCollectionView = collectionView, let validDelegate = delegate, !validDelegate.scrollableFor(collectionView: validCollectionView) {
            // Loop through the cached and look for items in the rect
            for attributes in cached {
                if attributes.frame.intersects(rect) {
                    visibleLayoutAttributes.append(attributes)
                }
            }
            return visibleLayoutAttributes
        }

        for index in elements(in: rect) {
            if let attribute = layoutAttributesForItem(at: index) {
                visibleLayoutAttributes.append(attribute)
            }
        }

        return visibleLayoutAttributes
    }

    override func layoutAttributesForItem(at indexPath: IndexPath) -> UICollectionViewLayoutAttributes? {
        if !ready {
            self.prepare()
        }
        let newAttributes = UICollectionViewLayoutAttributes(forCellWith: indexPath)
        newAttributes.frame = elementRect(by: indexPath)
        return newAttributes
    }
}
