//
//  TryInCodeViewController.swift
//  SomeScrollerTestProject
//
//  Created by Sergey Makeev on 16/11/2018.
//  Copyright © 2020 SomeProjects. All rights reserved.
//

import UIKit

class TryInCodeViewController: UIViewController {

    lazy var colorList: [UIColor] = {
        var colors = [UIColor]()
        for hue in stride(from: 0, to: 1.0, by: 0.15) {
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

        let scroller = ScrollerView()
        view.addSubview(scroller)
        scroller.translatesAutoresizingMaskIntoConstraints = false
        scroller.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        scroller.centerYAnchor.constraint(equalTo: view.centerYAnchor).isActive = true
        scroller.widthAnchor.constraint(equalTo: view.widthAnchor).isActive = true

        scroller.backgroundColor = .white
        scroller.elementsOnScreen = 5

        let delimiterHorizontal = createDefaultDelimiter()
        delimiterHorizontal.background = .black
        delimiterHorizontal.bitmap = UIImage(named: "bitmap")
        delimiterHorizontal.delimiterWidth = 10
        scroller.horizontalDelimiter = delimiterHorizontal

        for _ in 0..<colorList.count {
            scroller.append(makeItem())
        }
    }

    func makeItem() -> ScrollerItem {
        return ScrollerItem(view: nil) { (index, _) -> UIView in
            let result = UIView()

            result.backgroundColor = self.colorList[index % self.colorList.count]

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
        dismiss(animated: true, completion: nil)
    }
}
