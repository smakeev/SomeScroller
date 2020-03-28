//
//  ViewController.swift
//  SomeScroller
//
//  Created by Sergey Makeev on 01/11/2018.
//  Copyright © 2020 SomeProjects. All rights reserved.
//

import UIKit

func rotatedImage(_ image: UIImage?, degree: CGFloat) -> UIImage? {
    guard let image = image else { return nil }
    let size = image.size
    UIGraphicsBeginImageContext(size)

    let ctx = UIGraphicsGetCurrentContext()

    ctx?.translateBy(x: size.width / 2, y: size.height / 2)
    ctx?.rotate(by: CGFloat.pi * degree / 180)
    image.draw(in: CGRect(x: -size.width / 2, y: -size.height / 2, width: size.width, height: size.height))
    let newImage = UIGraphicsGetImageFromCurrentImageContext()

    UIGraphicsEndImageContext()
    return newImage
}

class ViewController: UIViewController {

    @IBOutlet weak var scrollerBar: ScrollerView!
    @IBOutlet weak var scrollBarVertical: ScrollerView!

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

    @IBAction func pushBack3Pressed(_ sender: Any) {

        let create:  (_ index: Int, _ stringId: String?) -> (UIView) = { (index, stringId) -> UIView in
            let result = UIView()
            result.backgroundColor = .clear

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

        let item = ScrollerItem(view: nil, fabric: create)
        let item1 = ScrollerItem(view: nil, fabric: create)
        let item2 = ScrollerItem(view: nil, fabric: create)
        scrollerBar.pushFront(contentsOf: [item, item1, item2])
        scrollBarVertical.pushFront(contentsOf: [item, item1, item2])
    }

    @IBAction func pushBackPressed(_ sender: Any) {

     let item = ScrollerItem(view: nil) { (index, _) -> UIView in
            let result = UIView()
            result.backgroundColor = .clear

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

        scrollerBar.pushFront(item)
        scrollBarVertical.pushFront(item)
    }

    @IBAction func removeAllPressed(_ sender: Any) {
        scrollerBar.removeAll()
        scrollBarVertical.removeAll()
    }

    @IBAction func replace0AndLastPressed(_ sender: Any) {
        scrollerBar.replace(item: 0, with: scrollerBar.count - 1)
        scrollBarVertical.replace(item: 0, with: scrollerBar.count - 1)
    }

    @IBAction func removaAt0(_ sender: Any) {
        scrollerBar.remove(at: 0)
        scrollBarVertical.remove(at: 0)
    }

    @IBAction func insertAtIndex(_ sender: Any) {
        let item = ScrollerItem(view: nil) { (index, _) -> UIView in
            let result = UIView()
            result.backgroundColor = .blue

            let label = UILabel()
            label.text = String(String(index) + " inserted")

            result.addSubview(label)
            label.translatesAutoresizingMaskIntoConstraints = false
            label.textAlignment = .center
            label.centerXAnchor.constraint(equalTo: result.centerXAnchor).isActive = true
            label.centerYAnchor.constraint(equalTo: result.centerYAnchor).isActive = true
            label.widthAnchor.constraint(equalTo: result.widthAnchor).isActive = true
            label.heightAnchor.constraint(equalTo: result.heightAnchor).isActive = true

            return result
        }
         scrollerBar.insert(item, at: 3) //here ould be acrash in case of no elements for such indecies
         scrollBarVertical.insert(item, at: 3) //here ould be acrash in case of no elements for such indecies
    }

    @IBAction func insertAtIndexes(_ sender: Any) {
        let item1 = ScrollerItem(view: nil) { (index, _) -> UIView in
            let result = UIView()
            result.backgroundColor = .blue

            let label = UILabel()
            label.text = String(String(index) + " inserted")

            result.addSubview(label)
            label.translatesAutoresizingMaskIntoConstraints = false
            label.textAlignment = .center
            label.centerXAnchor.constraint(equalTo: result.centerXAnchor).isActive = true
            label.centerYAnchor.constraint(equalTo: result.centerYAnchor).isActive = true
            label.widthAnchor.constraint(equalTo: result.widthAnchor).isActive = true
            label.heightAnchor.constraint(equalTo: result.heightAnchor).isActive = true

            return result
        }
        let item2 = ScrollerItem(view: nil) { (index, _) -> UIView in
            let result = UIView()
            result.backgroundColor = .blue

            let label = UILabel()
            label.text = String(String(index) + " 2 inserted")

            result.addSubview(label)
            label.translatesAutoresizingMaskIntoConstraints = false
            label.textAlignment = .center
            label.centerXAnchor.constraint(equalTo: result.centerXAnchor).isActive = true
            label.centerYAnchor.constraint(equalTo: result.centerYAnchor).isActive = true
            label.widthAnchor.constraint(equalTo: result.widthAnchor).isActive = true
            label.heightAnchor.constraint(equalTo: result.heightAnchor).isActive = true

            return result
        }
        scrollerBar.insert(contentsOf: [item1, item2], at: 3)
        scrollBarVertical.insert(contentsOf: [item1, item2], at: 3)
    }

    @IBAction func append(_ sender: Any) {
        scrollerBar.append(self.makeItem())
        scrollBarVertical.append(self.makeItem())
    }

    @IBAction func appenbdSeveral(_ sender: Any) {
        scrollerBar.append(contentsOf: [self.makeItem(), self.makeItem()])
        scrollBarVertical.append(contentsOf: [self.makeItem(), self.makeItem()])
    }

    //invalidate is needed to recreate views.
    @IBAction func invalidatePressed(_ sender: Any) {
        scrollerBar.invalidateAll()
        scrollBarVertical.invalidateAll()
    }

    @IBAction func delimiterOnOff(_ sender: Any) {
        if scrollerBar.delimiter != nil {
            scrollerBar.delimiter = nil
            scrollBarVertical.delimiter = nil
        } else {
            let delimiter = createDefaultDelimiter()
            delimiter.background = .black
            delimiter.bitmap = UIImage(named: "bitmap")
            delimiter.delimiterWidth = 10
            scrollerBar.horizontalDelimiter = delimiter

            let delimiterVertical = createDefaultDelimiter()
            delimiterVertical.background = .black
            delimiterVertical.bitmap = rotatedImage(UIImage(named: "bitmap"), degree: 90)
            delimiterVertical.delimiterWidth = 10
            scrollBarVertical.verticalDelimiter = delimiterVertical
        }

    }


    @IBAction func removeById2Action(_ sender: Any) {
        scrollerBar.removeBy("2")
        scrollBarVertical.removeBy("2")
    }

/////////////////////////////////////////////////////////////////////

    override func viewDidLoad() {
        super.viewDidLoad()
        for idx in 0..<colorList.count {
            scrollerBar.append(self.makeItem(String(idx)))
            scrollBarVertical.append(self.makeItem(String(idx)))
        }
        scrollBarVertical.orientation = .vertical

        scrollerBar.elementsOnScreen = 6
        scrollerBar.aspectRatio = 9/6
        scrollerBar.gravity = .justify//.adjustable([10, 20, 30, 40, 0, 0])
        scrollerBar.delimiterGravity = .center

        let delimiter = createDefaultDelimiter()
        delimiter.background = .black
        delimiter.bitmap = UIImage(named: "bitmap")
        delimiter.delimiterWidth = 10
        //scrollerBar.Delimiter = Delimiter

        scrollBarVertical.gravity = .justify //.adjustable([10, 20, 30, 40, 0, 0])
        scrollBarVertical.delimiterGravity = .center
        scrollBarVertical.elementsOnScreen = 6
        let delimiterVertical = createDefaultDelimiter()
        delimiterVertical.background = .black
        delimiterVertical.bitmap = rotatedImage(UIImage(named: "bitmap"), degree: 90)
        delimiterVertical.delimiterWidth = 600
       // scrollBarVertical.Delimiter = DelimiterVertical
        //scrollBarVertical.aspectRatio = 6/9
    }

    func makeItem(_ stringId: String? = nil) -> ScrollerItem {
        return ScrollerItem(view: nil, stringId: stringId) { (index, _) -> UIView in
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
}
