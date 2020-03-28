///
//  SomeScrollerView.swift
//  SomeScroller
//
//  Created by Sergey Makeev on 01/11/2018.
//  Copyright © 2020 SomeProjects. All rights reserved.
//

import UIKit

// MARK: - constants

//  infiniteSize should be >= 100 to have infiniteSize / 2 to be even. Is needed for toCenter logic.
//  To get it bigger makes toCenter be called reraly.
//  This is good for scrolling aimation peromance.
internal let infiniteSize = 10000//1000000
private let reuseId = "scrollerCellReuseId"
private let reuseDelimiterId = "scrollerCellDelimiterReuseId"

// MARK: - enums

public enum ScrollerOrientation: Int {
    case horizontal
    case vertical
}

//  SomeScrollerGravityType only takes effect if all elements are on the screen (means no scrollable)
//  In this case the view is not scrollable.
//  If there is an empty space elements could be located
//  in several Orientations.
//  left = top
//  right = bottom
//  adjustable contains a list of percents of total free space per each gap Orientation
//  It should get 100 in sum.
//  List's elements count must be
public enum ScrollerGravityType {
	case left
	case top
	case right
	case bottom
	case center
	case justify
	case adjustable([Int])
}

//  how to place Delimiter if free space between elements is more than delimiterWidth
//  Only takes effect in no scrollable case.
public enum ScrollerDelimiterGravityType {
	case left
	case top
	case right
	case bottom
	case center
	case fill
}

// MARK: - Protocols

//  Protocol to handle elements to be shown.
//  Supposed being called on main thread only.
public protocol ScrollerViewDataHelper {
    // Invalidation means that view in collectionview cell (not in case of Delimiter) will be recreated.
    // This could be important after any changes with collectio view scope (add/remove) any view,
    // or just after some data changes.
    // As usually Scroller does not recreate the view it may be recreaded forced by user call invalidation
    // for the view.

    // invalidateAll() - invalidate all not Delimiter views.
    func invalidateAll()

    // invalidate(at: Int) - invalidate view with index. Only one view will be invalidated.
    // index is the index of this view in items array. Has nothing incommon with collectionViewCell index path
    func invalidate(at index: Int)
    // invalidate(withId: String) if view has a string id, it will be invalidated in case of matching this id.
    // Note, several views could have the same id. All of them will be invalidated though.
    func invalidate(withId itemId: String)
    func append(_ item: ScrollerItem)
    func append(contentsOf newItems: [ScrollerItem])
    func pushFront(_ item: ScrollerItem)
    func pushFront(contentsOf newItems: [ScrollerItem])
    func insert(_ item: ScrollerItem, at index: Int)
    func insert(contentsOf newItems: [ScrollerItem], at index: Int)
    func removeAll()
    func remove(at index: Int)
    func removeBy(_ stringId: String)
    func replace(item item1: Int, with item2: Int)
}

// MARK: - ScrollerItem

public struct ScrollerItem {
    public var itemView: UIView?
    //creator for  view.
    public let viewFabric: (_ index: Int, _ stringId: String?) -> UIView
    //fill view with data
    public let stringId: String? //  string id of item provided by user. optional.

    public init(view: UIView?, stringId: String? = nil, fabric: @escaping (_ index: Int, _ stringId: String?) -> UIView) {
        itemView = view
        viewFabric = fabric
        guard let validStringId = stringId else {self.stringId = nil; return}
        self.stringId = validStringId
    }

    mutating public func invalidate() {
        itemView = nil
    }
}

// MARK: - SCrollerViewDelegate

@objc public protocol ScrollerViewDelegate: class {

    func scroller(_ scroller: ScrollerView, updateViewAfterCreation view: UIView, atIndex index: Int, stringId: String?, rowIndex: Int)
    func scroller(_ scroller: ScrollerView, updateViewForced view: UIView, atIndex index: Int, stringId: String?)
    func scroller(_ scroller: ScrollerView, updateForShowView view: UIView, atIndex index: Int, stringId: String?, rowIndex: Int)
    func scroller(_ scroller: ScrollerView, movedOn offset: Int)
    func scroller(_ scroller: ScrollerView, cellSizeChanged newSize: CGSize)
    func scroller(_ scroller: ScrollerView, scrollerIntrinsicContentSizeChanged newSize: CGSize)
    func scroller(_ scroller: ScrollerView, viewIsOffScreen view: UIView, atIndex index: Int, stringId: String?, rowIndex: Int)
    func scroller(_ scroller: ScrollerView, didScrollWithPointOffset pointOffset: CGFloat)
    func scroller(_ scroller: ScrollerView, pressedOn view: UIView, atIndex index: Int, stringId: String?, rowIndex: Int)
    func scroller(_ scroller: ScrollerView, doubleClicked view: UIView, atIndex index: Int, stringId: String?, rowIndex: Int)
    func scroller(_ scroller: ScrollerView, longPressed view: UIView, atIndex index: Int, stringId: String?, rowIndex: Int)
}

// MARK: - ScrollerView

@IBDesignable public class ScrollerView: UIView {

    // MARK: - ScrollerView variables

    public let numberOfSlotsInScroller: Int = {
        return infiniteSize
    }()

    public var beginningIndex: Int = {
        return infiniteSize / 2
    }()

    public let beginingRowIndex: Int = infiniteSize / 2
    public private(set) var elementWidth: CGFloat = 0
    public private(set) var elementHeight: CGFloat = 0

    public weak var delegate: ScrollerViewDelegate?

    public var visibleIndeces: [Int] {
        return collectionView.indexPathsForVisibleItems.map { getIndexByIndexPath($0) }
    }
    public var visibleIndexPathes: [Int] {
        return collectionView.indexPathsForVisibleItems.map { $0.row }
    }

    public var count: Int {
        return items.count
    }

    public func viewForIndex(_ index: Int) -> UIView? {
        guard index > 0 && index < items.count else { return nil }
        return items[index].itemView
    }

    public private(set) var offset: CGFloat = 0
    private var offsetInitialPosition: Int = 0

    private var initialPointOffsetX: CGFloat = 0
    private var initialPointOffsetY: CGFloat = 0

    public fileprivate(set) var cellSize: CGSize! {
        didSet {
            if let validDelegate = delegate {
                validDelegate.scroller(self, cellSizeChanged: cellSize)
            }
        }
    }

    @IBInspectable public var elementsOnScreen: Int = 1 {
        didSet {
            if elementsOnScreen <= 0 {
                fatalError("Elements on screen must be > 0")
            }
            self.setNeedsLayout()
        }
    }
    @IBInspectable public var aspectRatio: Float = 1.0 {
        didSet {
            self.setNeedsLayout()
        }
    }

    @IBInspectable public var autoOrientation: Bool = false {
        didSet {
            self.setNeedsLayout()
        }
    }

    public internal(set) var delimiter: DelimiterDataProtocol? = nil {
        didSet {
            self.setNeedsLayout()
            delimiter?.scroller = self
        }
    }

    public var horizontalDelimiter: DelimiterDataProtocol? = nil {
        didSet {
            if orientation == .horizontal {
                delimiter = horizontalDelimiter
            }
        }
    }

    public var verticalDelimiter: DelimiterDataProtocol? = nil {
        didSet {
            if orientation == .vertical {
                delimiter = verticalDelimiter
            }
        }
    }

    public var orientation: ScrollerOrientation = .horizontal {
        didSet {
            adjustGravityIfNeeded()
            if orientation == .horizontal {
                delimiter = horizontalDelimiter
            } else {
                delimiter = verticalDelimiter
            }

            adjustDelimiterGravityIfNeeded()
            self.restartComponent()
        }
    }

    public var gravity: ScrollerGravityType = .left {
        didSet {
            adjustGravityIfNeeded()
            self.restartComponent()
        }
    }

    public var delimiterGravity: ScrollerDelimiterGravityType = .left {
        didSet {
            adjustDelimiterGravityIfNeeded()
            self.restartComponent()
        }
    }

    @IBInspectable public var shouldAlwaysShowElementsEntirely: Bool = true

    public private(set) var collectionView: UICollectionView!
    internal var items: [ScrollerItem] = [ScrollerItem]()

    internal var lastMinVisibleIndex = 0
    internal var lastMaxVisibleIndex = infiniteSize + 1

    // MARK: - ScrollerView inits

    public override init(frame: CGRect) {
        orientation = .horizontal
        gravity = .left
        delimiterGravity = .left
        super.init(frame: frame)
        self.startCompponent()
    }

    required public init?(coder aDecoder: NSCoder) {
        orientation = .horizontal
        gravity = .left
        delimiterGravity = .left
        super.init(coder: aDecoder)
        self.startCompponent()
    }

    // MARK: - ScrollerView functios

    public func viewForRowIndex(_ rowIndex: Int) -> UIView? {
        if (delimiter != nil && rowIndex % 2 != 0) || items.count == 0 {
            return nil
        }
        let indexPath = IndexPath(row: rowIndex, section: 0)
        let index = getIndexByIndexPath(indexPath)
        return items[index].itemView
    }

    public override func layoutSubviews() {
        super.layoutSubviews()
        if autoOrientation {
            if self.bounds.width == self.bounds.height {
                //do nothing
            } else if self.bounds.width > self.bounds.height {
                if orientation == .vertical {
                    orientation = .horizontal
                }
            } else {
                if orientation == .horizontal {
                    orientation = .vertical
                }
            }
        }

        invalidateIntrinsicContentSize()
    }

    public override var intrinsicContentSize: CGSize {
        let size: CGSize

        if orientation == .horizontal {
            var mainSize = self.bounds.size.width
            guard mainSize > 0 else {
                cellSize = CGSize.zero
                return CGSize.zero
            }
            if let validDelimiter = delimiter {
                mainSize = (mainSize - CGFloat(elementsOnScreen - 1) * validDelimiter.delimiterWidth).rounded(.up)
            }
            elementWidth = (mainSize / CGFloat(elementsOnScreen)).rounded(.up)
            elementHeight = (CGFloat(1/aspectRatio) * elementWidth).rounded(.up)
            cellSize = CGSize(width: elementWidth, height: elementHeight)
            size = CGSize(width: -1, height: elementHeight)
            assert(elementHeight > 0, "Height of an element is less or equal to 0. Be sure that element height is big enugh and Delimiter width is not too big.")
        } else {
            var mainSize = self.bounds.size.height
            guard mainSize > 0 else {
                cellSize = CGSize.zero
                return CGSize.zero
            }
            if let validDelimiter = delimiter {
                mainSize = (mainSize - CGFloat(elementsOnScreen - 1) * validDelimiter.delimiterWidth).rounded(.up)
            }
            elementHeight = (mainSize / CGFloat(elementsOnScreen)).rounded(.up)
            elementWidth = (CGFloat(aspectRatio) * elementHeight).rounded(.up)
            cellSize = CGSize(width: elementWidth, height: elementHeight)
            size = CGSize(width: elementWidth, height: -1)
            assert(elementWidth > 0, "Width of an element is less or equal to 0. Be sure that element height is big enugh and Delimiter width is not too big.")
        }
        collectionView.reloadData()
        self.toCenter()
        if let validDelegate = delegate {
            validDelegate.scroller(self, scrollerIntrinsicContentSizeChanged: size)
        }
        return size
    }

    public func updateViewsForced() {

        guard items.count > 0 else { return }
        guard let validDelegate = delegate else { return }
        for index in items.indices {
            if let validView = items[index].itemView {
                validDelegate.scroller(self, updateViewForced: validView, atIndex: index, stringId: items[index].stringId)
            }
        }
    }

    public func stopScrolling() {
        if collectionView.isDragging || collectionView.isDecelerating {
            collectionView.setContentOffset(collectionView.contentOffset, animated: false)
        }

    }

    public func moveOn(_ offset: Int, animated: Bool) {
        if !self.scrollableFor(collectionView: collectionView) {
            return
        }

        if let currentLeft = visibleIndexPathes.sorted().min() {
            //@TO-DO: check if offset moves us out of bounds
            let target = currentLeft + offset
            if self.orientationFor(collectionView: collectionView) == .horizontal {
                collectionView.scrollToItem(at: IndexPath(row: target, section: 0), at: .left, animated: false)
            } else {
                collectionView.scrollToItem(at: IndexPath(row: target, section: 0), at: .top, animated: false)
            }
        }
    }

    public func toCenter() {
        if !self.scrollableFor(collectionView: collectionView) {
            //all elements are presented on the screen. Have nothin to do here.
            return
        }

        //If infiniteSize >= 100 and is even than infiniteSize / 2 is even too. This garantees us an elements Cell (not a Delimiter)
        //to be focused on.
        if self.orientationFor(collectionView: collectionView) == .horizontal {
            collectionView.scrollToItem(at: IndexPath(row: infiniteSize / 2, section: 0), at: .left, animated: false)
        } else {
            collectionView.scrollToItem(at: IndexPath(row: infiniteSize / 2, section: 0), at: .top, animated: false)
        }

        lastMinVisibleIndex = infiniteSize / 2
        lastMaxVisibleIndex = infiniteSize / 2 + (items.count - 1)
        if delimiter != nil {
            lastMaxVisibleIndex += (items.count - 1)
        }
        offset = 0
        offsetInitialPosition = lastMinVisibleIndex

        initialPointOffsetX = collectionView.contentOffset.x
        initialPointOffsetY = collectionView.contentOffset.y
    }

    fileprivate func startCompponent() {

        let layout = ScrollerLayout()
        layout.delegate = self

        collectionView = UICollectionView(frame: CGRect(), collectionViewLayout: layout)
        collectionView.bounces = false
        self.addSubview(collectionView)

        collectionView.translatesAutoresizingMaskIntoConstraints = false
        collectionView.centerXAnchor.constraint(equalTo: self.centerXAnchor).isActive = true
        collectionView.centerYAnchor.constraint(equalTo: self.centerYAnchor).isActive = true
        collectionView.widthAnchor.constraint(equalTo: self.widthAnchor).isActive = true
        collectionView.heightAnchor.constraint(equalTo: self.heightAnchor).isActive = true

        collectionView.register(ScrollerCell.self, forCellWithReuseIdentifier: reuseId)
        collectionView.register(ScrollerDelimiterCell.self, forCellWithReuseIdentifier: reuseDelimiterId)

        collectionView.backgroundColor = .clear
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.showsVerticalScrollIndicator = false

        let doubleTapGesture = UITapGestureRecognizer(target: self, action:#selector(didDoubleTapCollectionView(_:)))
        doubleTapGesture.numberOfTapsRequired = 2
        doubleTapGesture.delaysTouchesBegan = true
        self.collectionView.addGestureRecognizer(doubleTapGesture)

        let longPressGesture = UILongPressGestureRecognizer(target: self, action:#selector(didLongPressesCollectionView(_:)))
        longPressGesture.delaysTouchesBegan = true
        self.collectionView.addGestureRecognizer(longPressGesture)
        self.restartComponent()
    }

    fileprivate func restartComponent() {
        collectionView.reloadData()
        self.setNeedsLayout()
    }

    private func handleGesture(_ gesture: UIGestureRecognizer, handler: (_:UICollectionView, _:IndexPath) -> (Void)) {
        let pointInCollectionView: CGPoint = gesture.location(in: collectionView)
        if let selectedIndexPath = collectionView.indexPathForItem(at: pointInCollectionView) {
            handler(collectionView, selectedIndexPath)
        }
    }

    @objc func didLongPressesCollectionView(_ gesture: UILongPressGestureRecognizer) {
        guard gesture.state == .ended else {return}
        handleGesture(gesture) { collectionView, indexPath in
            self.collectionView(collectionView, didLongTapped: indexPath)
        }
    }

    @objc func didDoubleTapCollectionView(_ gesture: UITapGestureRecognizer) {
        handleGesture(gesture) { collectionView, indexPath in
            self.collectionView(collectionView, didDoubleClicked: indexPath)
        }
    }

    internal func adjustGravityIfNeeded() {
        switch gravity {
        case .top where orientation == .horizontal:
            gravity = .left
        case .bottom where orientation == .horizontal:
            gravity = .right
        case .left where orientation == .vertical:
            gravity = .top
        case .right where orientation == .vertical:
            gravity = .bottom
        default:
            break; //do nothing
        }
    }

    internal func adjustDelimiterGravityIfNeeded() {
        switch delimiterGravity {
        case .top where orientation == .horizontal:
            delimiterGravity = .left
        case .bottom where orientation == .horizontal:
            delimiterGravity = .right
        case .left where orientation == .vertical:
            delimiterGravity = .top
        case .right where orientation == .vertical:
            delimiterGravity = .bottom
        default:
            break; //do nothing
        }
    }
}

extension ScrollerView: ScrollerLayoutDelegate {
    func collectionView(collectionView: UICollectionView, heightForItemAtIndexPath indexPath: IndexPath) -> CGFloat {
        if let validDelimiter = delimiter, orientation == .vertical {
            if indexPath.row % 2 == 1 {
                return validDelimiter.delimiterWidth
            }
        }
        return cellSize.height
    }

    func collectionView(collectionView: UICollectionView, widthForItemAtIndexPath indexPath: IndexPath) -> CGFloat {
        if let validDelimiter = delimiter, orientation == .horizontal {
            if indexPath.row % 2 == 1 {
                return validDelimiter.delimiterWidth
            }
        }

        return cellSize.width
    }

    func realElementsFor(collectionView: UICollectionView) -> Int {
        return items.count
    }

    func orientationFor(collectionView: UICollectionView) -> ScrollerOrientation {
        return orientation
    }

    func gravityFor(collecionView: UICollectionView) -> ScrollerGravityType {
        return gravity
    }

    func delimiterGravityFor(collectionView: UICollectionView) -> ScrollerDelimiterGravityType {
        return delimiterGravity
    }

    func scrollableFor(collectionView: UICollectionView) -> Bool {
        return items.count > elementsOnScreen
    }

    func hasDelimiterFor(collectionView: UICollectionView) -> Bool {
        return delimiter != nil
    }

    func delimiterWidthFor(collectionView: UICollectionView) -> CGFloat {
        guard let validDelimiter = delimiter else {return 0}
        return validDelimiter.delimiterWidth
    }
}

extension ScrollerView: UICollectionViewDataSource, UICollectionViewDelegate {

    fileprivate func findMinMaxVisibleIndexes(for scrollView: UIScrollView) -> (minIndex: Int, maxIndex: Int)? {
        guard let collectionView = scrollView as? UICollectionView else {return nil}
        let cells = collectionView.visibleCells

        guard !cells.isEmpty else {return nil}
        var minimumIndex = infiniteSize
        var maximumIndex = -1
        for cell in collectionView.visibleCells {
            if let cell = cell as? ScrollerCell {

                let cellIndex = collectionView.indexPath(for: cell)!.row
                if cellIndex < minimumIndex {
                    minimumIndex = cellIndex
                }
                if cellIndex > maximumIndex {
                    maximumIndex = cellIndex
                }
            }
        }
        return (minIndex: minimumIndex, maxIndex: maximumIndex)
    }

    public func scrollViewDidScroll(_ scrollView: UIScrollView) {
        guard let validDelegate = delegate else { return }
        guard  let collectionView = scrollView as? UICollectionView else { return }

        var pointOffset: CGFloat = 0
        var initialOffset: CGFloat = 0
        var sizeToSearch: CGFloat = 0
        if orientation == .horizontal {
            pointOffset = collectionView.contentOffset.x
            initialOffset = initialPointOffsetX
            sizeToSearch = elementWidth
        } else {
            pointOffset = collectionView.contentOffset.y
            initialOffset = initialPointOffsetY
            sizeToSearch = elementHeight
        }

        if delimiter != nil {
            sizeToSearch += delimiterWidthFor(collectionView: collectionView)
        }

        let delta = pointOffset - initialOffset
        validDelegate.scroller(self, didScrollWithPointOffset: delta)
        let newOffset = (delta / sizeToSearch).rounded(.up)
        if offset != newOffset {
             offset = newOffset
             validDelegate.scroller(self, movedOn: Int((offset).rounded(.up)))
        }

    }

    public func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate declerate: Bool) {
        if !declerate {
            scrollViewDidEndDecelerating(scrollView)
        }
    }

    public func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        guard shouldAlwaysShowElementsEntirely else {return}
        let indexes = findMinMaxVisibleIndexes(for: scrollView)
        if let collectionView = scrollView as? UICollectionView, let indexes = indexes {
            //There could be some items not presented entirely.
            //just scroll to the most left been presented wholly.
            if indexes.minIndex >= lastMinVisibleIndex {
                collectionView.scrollToItem(at: IndexPath(row: indexes.maxIndex, section: 0), at: self.orientationFor(collectionView: collectionView) == .horizontal ? .right : .bottom, animated: true)
            } else {
                collectionView.scrollToItem(at: IndexPath(row: indexes.minIndex, section: 0), at: self.orientationFor(collectionView: collectionView) == .horizontal ? .left : .top, animated: true)
            }
        }
    }

    public func scrollViewDidEndScrollingAnimation(_ scrollView: UIScrollView) {
        if let indexes = findMinMaxVisibleIndexes(for: scrollView) {
            lastMinVisibleIndex = indexes.minIndex
            lastMaxVisibleIndex = indexes.maxIndex
        }
    }

    public func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if !scrollableFor(collectionView: collectionView) {
            if delimiter == nil {
                //all elements are on the screen
                return items.count
            } else {
                //all elements and Delimiters between them are on the screen.
                //Note, last element does not have a Delimiter in this case
                return items.count + items.count - 1
            }
        }
        return infiniteSize
    }

    internal func getIndexByIndexPath(_ indexPath: IndexPath) -> Int {
        var index = -1
        if delimiter == nil {
            //all elements are ScrollerCell instances.
            index = indexPath.row % items.count
        } else if !scrollableFor(collectionView: collectionView) {
            //Has Delimiter but all elements are on screen now.
            index = indexPath.row / 2
        } else {
            //Has delimerters and infinity scrolling for all elements
            if indexPath.row < items.count * 2 {
                //For the first (one screen elements) logic is the same as for no srolling case
                index = indexPath.row / 2
            } else {
                //first take index as on first screen, than take it's index in items array
                index = (indexPath.row % (items.count * 2)) / 2
            }
        }
        return index
    }
    //swiftlint:disable large_tuple
    internal func prepare(_ cell: ScrollerCell, forCollectionView collectionView: UICollectionView, forIndexPath indexPath: IndexPath) -> (UIView, Int, String?)? {
        guard items.count > 0 else { return nil }
        //swiftlint:enable large_tuple
        let index = getIndexByIndexPath(indexPath)
        guard index < items.count else { return nil }
        var view = items[index].itemView
        if view == nil {
            view = items[index].viewFabric(index, items[index].stringId)
            if let validDelegate = delegate, let validView = view {
                validDelegate.scroller(self, updateViewAfterCreation: validView, atIndex: index, stringId: items[index].stringId, rowIndex: indexPath.row)
            }
        }
        guard let validView = view else { fatalError("View Fabric must produce a view!")}
        if validView.superview != nil && validView.superview != cell.contentView {
            validView.removeFromSuperview()
        }
        items[index].itemView = view
        cell.content = validView
        return (validView, index, items[index].stringId)
    }

    public func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        //swiftlint:disable force_cast
        if delimiter == nil || indexPath.row % 2 == 0 {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: reuseId, for: indexPath) as! ScrollerCell
            if !scrollableFor(collectionView: collectionView) {
                let viewInfo = self.prepare(cell, forCollectionView: collectionView, forIndexPath: indexPath)
                if let validDelegate = delegate, let validInfo = viewInfo {
                    let (validView, validIndex, stringId) = validInfo
                    validDelegate.scroller(self, updateForShowView: validView, atIndex: validIndex, stringId: stringId, rowIndex: indexPath.row)
                }
            }
            return cell
        }

        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: reuseDelimiterId, for: indexPath) as! ScrollerDelimiterCell
        if cell.delimiter !== delimiter, let validDelimiter = delimiter as? (UIView & DelimiterDataProtocol) {
            cell.delimiter = Delimiter.delimiterWith(validDelimiter)
        }
        //swiftlint:enable force_cast
        return cell
    }

    public func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {

        //if all elements are already on screen don't need any additional actions here.
        guard scrollableFor(collectionView: collectionView) else {return}

        //For last and first cell we will move to center again with n animation
        if indexPath.row == 0 || indexPath.row == infiniteSize - 1 {
            self.toCenter()
            return
        }

        if let validCell = cell as? ScrollerCell {
            let viewInfo = prepare(validCell, forCollectionView: collectionView, forIndexPath: indexPath)
            if let validDelegate = delegate, let validInfo = viewInfo {
                let (validView, validIndex, stringId) = validInfo
                validDelegate.scroller(self, updateForShowView: validView, atIndex: validIndex, stringId: stringId, rowIndex: indexPath.row)
            }
        }
    }

    public func collectionView(_ collectionView: UICollectionView, didEndDisplaying cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {

        guard let validCell = cell as? ScrollerCell else { return }
        validCell.prepare()

        let viewInfo = prepare(validCell, forCollectionView: collectionView, forIndexPath: indexPath)

        if let validDelegate = delegate, let validInfo = viewInfo {
            let (validView, validIndex, stringId) = validInfo
            validDelegate.scroller(self, viewIsOffScreen: validView, atIndex: validIndex, stringId: stringId, rowIndex: indexPath.row)
        }
    }

    private func handlePressGestureOnElement(_ collectionView: UICollectionView, indexPath: IndexPath, handler: (_: UICollectionView, _:UIView, _:Int, _:String) -> Void) {
        if let validCell = collectionView.cellForItem(at: indexPath) as? ScrollerCell {
            let viewInfo = prepare(validCell, forCollectionView: collectionView, forIndexPath: indexPath)
            if let validInfo = viewInfo {
                let (validView, validIndex, stringId) = validInfo
                handler(collectionView, validView, validIndex, stringId ?? "")
            }
        }
    }

    public func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {

        if let validDelegate = delegate {
            handlePressGestureOnElement(collectionView, indexPath: indexPath) {
                collectionView, view, index, stringId in
                validDelegate.scroller(self, pressedOn: view, atIndex: index, stringId: stringId, rowIndex: indexPath.row)
            }
        }
    }

    public func collectionView(_ collectionView: UICollectionView, didDoubleClicked indexPath: IndexPath) {

        if let validDelegate = delegate {
            handlePressGestureOnElement(collectionView, indexPath: indexPath) {
                collectionView, view, index, stringId in
                validDelegate.scroller(self, doubleClicked: view, atIndex: index, stringId: stringId, rowIndex: indexPath.row)
            }
        }
    }

    public func collectionView(_ collectionView: UICollectionView, didLongTapped indexPath: IndexPath) {

        if let validDelegate = delegate {
            handlePressGestureOnElement(collectionView, indexPath: indexPath) {
                collectionView, view, index, stringId in
                validDelegate.scroller(self, longPressed: view, atIndex: index, stringId: stringId, rowIndex: indexPath.row)
            }
        }
    }
}

//Adding/removing/reordering items
extension ScrollerView: ScrollerViewDataHelper {
    public func invalidateAll() {
        for  index in items.indices {
            items[index].invalidate()
        }

        collectionView.reloadData()
    }

    public func invalidate(at index: Int) {
        guard items.indices.contains(index) else { return }
        items[index].invalidate()
        collectionView.reloadData()
    }

    public func invalidate(withId itemId: String) {
        for var item in items.filter({ $0.stringId == itemId }) {
                item.invalidate() //theoretically id could be not unique, thus don't brak here
        }
        collectionView.reloadData()
    }

    public func append(contentsOf newItems: [ScrollerItem]) {
        items.append(contentsOf: newItems)
        collectionView.reloadData()
    }

    public func append(_ item: ScrollerItem) {
        items.append(item)
        collectionView.reloadData()
    }

    public func pushFront(_ item: ScrollerItem) {
        items.insert(item, at: 0)
        collectionView.reloadData()
    }

    public func pushFront(contentsOf newItems: [ScrollerItem]) {
        for item in newItems {
            items.insert(item, at: 0)
        }
        collectionView.reloadData()
    }

    public func insert(_ item: ScrollerItem, at index: Int) {
        items.insert(item, at: index)
        collectionView.reloadData()
    }

    public func insert(contentsOf newItems: [ScrollerItem], at index: Int) {
        items.insert(contentsOf: newItems, at: index)
        collectionView.reloadData()
    }

    public func removeAll() {
        items.removeAll()
        let cellsOnScreen = collectionView.visibleCells.filter({ $0 is ScrollerCell})
        for cell in cellsOnScreen {
            guard let validCell = cell as? ScrollerCell else { continue }
            validCell.reset()
        }
        collectionView.reloadData()
    }

    public func remove(at index: Int) {
        let view = items[index].itemView
        items.remove(at: index)
        if let validView = view {
            let cellsOnScreen = collectionView.visibleCells.filter({ $0 is ScrollerCell})
            for cell in cellsOnScreen {
                guard let validCell = cell as? ScrollerCell else { continue }
                if validView === validCell.content {
                    validCell.reset()
                    break
                }
            }
        }
        collectionView.reloadData()
    }

    public func removeBy(_ stringId: String) {
        let removedItems = items.filter { $0.stringId == stringId }
        items = items.filter { $0.stringId != stringId }
        if removedItems.count > 0 {
            let cellsOnScreen = collectionView.visibleCells.filter({ $0 is ScrollerCell})
            for cell in cellsOnScreen {
                guard let validCell = cell as? ScrollerCell else { continue }
                for item in removedItems where item.itemView === validCell.contentView {
                        validCell.reset()
                        break
                }
            }
        }

        collectionView.reloadData()
    }

    public func replace(item item1: Int, with item2: Int) {
        items.swapAt(item1, item2)
        collectionView.reloadData()
    }
}
