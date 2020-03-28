//
//  SomeScrollerCell.swift
//  SomeScroller
//
//  Created by Sergey Makeev on 14/11/2018.
//  Copyright © 2020 SomeProjects. All rights reserved.
//

import UIKit

public class ScrollerCell: UICollectionViewCell {

    internal weak var content: UIView? {
        didSet {
            guard let validContent = content else {return}
            validContent.bounds = CGRect.zero

            validContent.frame = self.contentView.bounds

            for view in self.contentView.subviews {
                view.removeFromSuperview()
            }

            self.contentView.addSubview(validContent)
            validContent.translatesAutoresizingMaskIntoConstraints = false
            validContent.centerXAnchor.constraint(equalTo: self.contentView.centerXAnchor).isActive = true
            validContent.centerYAnchor.constraint(equalTo: self.contentView.centerYAnchor).isActive = true
            validContent.widthAnchor.constraint(equalTo: self.contentView.widthAnchor).isActive = true
            validContent.heightAnchor.constraint(equalTo: self.contentView.heightAnchor).isActive = true
        }
    }
    internal func prepare() {
        if content?.superview === self.contentView {
            content?.removeFromSuperview()
        } else {
            reset()
        }
    }

    internal func reset() {
        content = nil
        for view in self.contentView.subviews {
            view.removeFromSuperview()
        }
    }

}
