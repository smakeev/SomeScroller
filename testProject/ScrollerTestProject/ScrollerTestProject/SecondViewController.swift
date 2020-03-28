//
//  SecondViewController.swift
//  SomeScroller
//
//  Created by Sergey Makeev on 05/11/2018.
//  Copyright © 2020 SomeProjects. All rights reserved.
//

import UIKit

class SecondViewController: UIViewController {

	@IBOutlet weak var scrollerView: ScrollerView!

	lazy var colorList: [UIColor] = {
        var colors = [UIColor]()
        for hue in stride(from: 0, to: 1.0, by: 0.25) {
            let color = UIColor(hue: CGFloat(hue),
                                saturation: 1,
                                brightness: 1,
                                alpha: 1)
            colors.append(color)
        }
        return colors
    }()

	override func viewDidLoad() {
		super.viewDidLoad()
		     for _ in 0..<colorList.count {
            scrollerView.append(self.makeItem())
        }

        scrollerView.elementsOnScreen = 3
        scrollerView.orientation = .horizontal
		scrollerView.autoOrientation = true

        let delimiterVertical = createDefaultDelimiter()
        delimiterVertical.background = .black
        delimiterVertical.bitmap = rotatedImage(UIImage(named: "bitmap"), degree: 90)
        delimiterVertical.delimiterWidth = 10
        scrollerView.verticalDelimiter = delimiterVertical

        let delimiterHorizontal = createDefaultDelimiter()
        delimiterHorizontal.background = .white
        delimiterHorizontal.bitmap = UIImage(named: "bitmap")
        delimiterHorizontal.delimiterWidth = 15
        scrollerView.horizontalDelimiter = delimiterHorizontal
	}

	func makeItem() -> ScrollerItem {
      return ScrollerItem(view: nil) { (index, _) -> UIView in
            let result = UIView()
            result.backgroundColor = self.colorList[index]

            let label = UILabel()
            label.text = String(index)

            result.addSubview(label)
            label.translatesAutoresizingMaskIntoConstraints = false
            label.textAlignment = .center
            label.centerXAnchor.constraint(equalTo: result.centerXAnchor).isActive = true
            label.centerYAnchor.constraint(equalTo: result.centerYAnchor).isActive = true
            label.widthAnchor.constraint(equalTo: result.widthAnchor).isActive = true
            label.heightAnchor.constraint(equalTo: result.heightAnchor).isActive = true

            return result
        }
    }

    @IBAction func backPressed(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
    }
}
