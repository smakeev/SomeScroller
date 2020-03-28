//
//  Delimiter.swift
//  SomeScroller
//
//  Created by Sergey Makeev on 14/11/2018.
//  Copyright © 2020 SomeProjects. All rights reserved.
//

import UIKit

// MARK: - DelimiterDataProtocol

public protocol DelimiterDataProtocol: class {

    static func newDelimiter() -> DelimiterDataProtocol
    static func delimiterWith(_ delimiter: UIView & DelimiterDataProtocol) -> UIView & DelimiterDataProtocol
    var delimiterWidth: CGFloat {get set}
    var background: UIColor {get set}
    var bitmap: UIImage? {get set}
    var drawer: ((_ context: CGContext, _ rect: CGRect, _ orientation: ScrollerOrientation) -> Void)? {get set}
    var scroller: ScrollerView? {get set}

}

// MARK: - createDefaultDelimiter()

public func createDefaultDelimiter() -> DelimiterDataProtocol {
    return Delimiter.newDelimiter()
}

// MARK: - Delimiter

internal  class Delimiter: UIView, DelimiterDataProtocol {

// MARK: - Delimiter variables

    var background: UIColor {
        get {
            return self.backgroundColor ?? .clear
        }

        set {
            self.backgroundColor = newValue
        }
    }

    var delimiterWidth: CGFloat = 2 {
        didSet {
            self.setNeedsDisplay()
        }
    }

    var bitmap: UIImage? = nil {
        didSet {
            self.setNeedsDisplay()
        }
    }

    var drawer: ((_ context: CGContext, _ rect: CGRect, _ orientation: ScrollerOrientation) -> Void)? = nil {
        didSet {
            self.setNeedsDisplay()
        }
    }

    weak var scroller: ScrollerView? = nil {
        didSet {
            self.setNeedsDisplay()
        }
    }

    // MARK: - Delimiter class functions

    class func newDelimiter() -> DelimiterDataProtocol {
        return Delimiter()
    }

    class func delimiterWith(_ delimiter: UIView & DelimiterDataProtocol) -> UIView & DelimiterDataProtocol {
        let result: Delimiter = Delimiter()

        result.bitmap = delimiter.bitmap
        result.backgroundColor = delimiter.backgroundColor
        result.delimiterWidth = delimiter.delimiterWidth
        result.scroller = delimiter.scroller
        return result
    }

    // MARK: - Delimiter inits

    init() {
        super.init(frame: CGRect.zero)
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

    override init(frame: CGRect) {
        super.init(frame: CGRect.zero)
    }

// MARK: - Delimiter overrided functions

    override func draw(_ rect: CGRect) {
        if let validBitmap = bitmap {
            validBitmap.draw(in: rect)
        } else if let drawer = drawer, let scroller = scroller {
            guard let context = UIGraphicsGetCurrentContext() else {return}
            drawer(context, rect, scroller.orientation)
        }
    }
}
