//
//  SomeScrollerDelimiterCell.swift
//  SomeScroller
//
//  Created by Sergey Makeev on 14/11/2018.
//  Copyright © 2020 SomeProjects. All rights reserved.
//

import UIKit

public class ScrollerDelimiterCell: UICollectionViewCell {
    var delimiter: (UIView & DelimiterDataProtocol)? {
        didSet {
            if let validDelimiter = delimiter {
                self.contentView.addSubview(validDelimiter)
                validDelimiter.translatesAutoresizingMaskIntoConstraints = false
                validDelimiter.centerXAnchor.constraint(equalTo: self.contentView.centerXAnchor).isActive = true
                validDelimiter.centerYAnchor.constraint(equalTo: self.contentView.centerYAnchor).isActive = true
                validDelimiter.widthAnchor.constraint(equalTo: self.contentView.widthAnchor).isActive = true
                validDelimiter.heightAnchor.constraint(equalTo: self.contentView.heightAnchor).isActive = true
            }
        }
    }
}
