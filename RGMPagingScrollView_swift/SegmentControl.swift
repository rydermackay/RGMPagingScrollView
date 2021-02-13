//
//  SegmentControl.swift
//  Paging
//
//  Created by Squirrel on 2019/6/28.
//  Copyright © 2019 Squirrel. All rights reserved.
//

import UIKit

enum SegmentSelectionStyle {
    case textWidth
    case fullWidth
    case box
    case arrow
}

enum SelectionIndicatorLocation {
    case up
    case down
    case none
}

enum WidthStyle {
    case fixed
    case dynamic
}

enum ControlType {
    case text
    case images
    case textImages
}

class HMScrollView: UIScrollView {
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        if !self.isDragging {
            self.next?.touchesBegan(touches, with: event)
        } else {
            super.touchesBegan(touches, with: event)
        }
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        if !self.isDragging {
            self.next?.touchesMoved(touches, with: event)
        } else {
            super.touchesMoved(touches, with: event)
        }
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        if !self.isDragging {
            self.next?.touchesEnded(touches, with: event)
        } else {
            super.touchesEnded(touches, with: event)
        }
    }
}

class SegmentControl: UIControl {
    var sectionTitles: [String]! {
        didSet {
            setNeedsLayout()
        }
    }
    var sectionImages = [UIImage]() {
        didSet {
            setNeedsLayout()
        }
    }
    var sectionSelectedImages = [UIImage]()
    
    /*
     Provide a block to be executed when selected index is changed.
     
     Alternativly, you could use `addTarget:action:forControlEvents:`
     */
    var indexChangeBlock: ((Int) -> Void)?
    
    /*
     Font for segments names when segmented control type is `ControlType.text`
     */
    var font = UIFont(name: "STHeitiSC-Light", size: 18)!
    
    /*
     Text color for segments names when segmented control type is `ControlType.text`
     */
    var textColor = UIColor.black
    
    /*
     Text color for selected segment name when segmented control type is `ControlType.text`
     */
    var selectedTextColor = UIColor.black
    
    /*
     Color for the selection indicator stripe/box
     
     Default is R:52, G:181, B:229
     */
    var selectionIndicatorColor = UIColor(red: 52/255.0, green: 181/255.0, blue: 229/255.0, alpha: 1)
    
    /*
     Specifies the style of the control
     */
    var type = ControlType.text
    
    /*
     Specifies the style of the selection indicator.
     */
    var selectionStyle = SegmentSelectionStyle.textWidth
    
    /*
     Specifies the style of the segment's width.
     */
    var segmentWidthStyle = WidthStyle.fixed
    
    /*
     Specifies the location of the selection indicator.
     */
    var selectionIndicatorLocation = SelectionIndicatorLocation.up {
        didSet {
            if selectionIndicatorLocation == .none {
                selectionIndicatorHeight = 0
            }
        }
    }
    
    /*
     Default is YES. Set to NO to deny scrolling by dragging the scrollView by the user.
     */
    var userDraggable = true
    
    /*
     Default is YES. Set to NO to deny any touch events by the user.
     */
    var touchEnabled = true
    
    /*
     Index of the currently selected segment.
     */
    var selectedSegmentIndex: Int = 0
    
    /*
     Height of the selection indicator. Only effective when `SegmentSelectionStyle` is either `textWidth` or `fullWidth`.
     
     Default is 5.0
     */
    var selectionIndicatorHeight: CGFloat = 5
    
    /*
     Inset left and right edges of segments. Only effective when `scrollEnabled` is set to YES.
     
     Default is UIEdgeInsetsMake(0, 5, 0, 5)
     */
    var segmentEdgeInset = UIEdgeInsets(top: 0, left: 5, bottom: 0, right: 5)
    
    /*
     Default is YES. Set to NO to disable animation during user selection.
     */
    var shouldAnimateUserSelection = true
    
    private var stripLayer = CALayer()
    private var boxLayer = CALayer()
    private var arrowLayer = CALayer()
    private var arrowShapeLayer = CAShapeLayer()
    private var textLayers = [CATextLayer]()
    private var segmentWidth: CGFloat = 0
    private var segmentWidths = [CGFloat]()
    private var scrollView: HMScrollView!
    private var isDraggingBegin = false
    private var draggingStartOffset: CGFloat = 0
    
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        commonInit()
    }
}

//MARK - Public

extension SegmentControl {
    
    convenience init(titles: [String]) {
        self.init(frame: .zero)
        self.sectionTitles = titles
        self.commonInit()
    }
    
    convenience init(images: [UIImage], selectedImages: [UIImage]) {
        self.init(frame: .zero)
        self.sectionImages = images
        self.sectionSelectedImages = selectedImages
        self.commonInit()
    }
    
    convenience init(titles: [String], images: [UIImage], selectedImages: [UIImage]) {
        self.init(frame: .zero)
        self.sectionTitles = titles
        self.sectionImages = images
        self.sectionSelectedImages = selectedImages
        self.commonInit()
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        segmentWidth = 0
        commonInit()
    }
    
    
    
    override func layoutSubviews() {
        super.layoutSubviews()
        updateSegmentsRects()
    }
    
    override var frame: CGRect {
        didSet {
            updateSegmentsRects()
        }
    }
    
    func beginDragging(index: Int) {
        if isDraggingBegin { return }
        isDraggingBegin = true
        draggingStartOffset = currentLayer.position.x
    }
    
    func dragging(percent: CGFloat) {
        if !isDraggingBegin || percent == 0 { return }
        var moveTo = CGPoint.zero
        if percent < 0 {
            if selectedSegmentIndex == 0 { return }
            let previous = frameForCurrentLayer(index: selectedSegmentIndex - 1)
            let total = draggingStartOffset - previous.origin.x
            moveTo = CGPoint(x: draggingStartOffset + total * percent, y: currentLayer.position.y)
            
            let pLayer = textLayers[selectedSegmentIndex - 1]
            let cLayer = textLayers[selectedSegmentIndex]
            pLayer.foregroundColor = color(between: textColor, to: selectedTextColor, percent: percent).cgColor
            cLayer.foregroundColor = color(between: selectedTextColor, to: textColor, percent: percent).cgColor
        } else {
            if selectedSegmentIndex == sectionCount - 1 { return }
            let next = frameForCurrentLayer(index: sectionCount - 1)
            let total = next.origin.x - draggingStartOffset
            moveTo = CGPoint(x: draggingStartOffset + total * percent, y: currentLayer.position.y)
            
            let nLayer = textLayers[selectedSegmentIndex + 1]
            let cLayer = textLayers[selectedSegmentIndex]
            
            nLayer.foregroundColor = color(between: textColor, to: selectedTextColor, percent: percent).cgColor
            cLayer.foregroundColor = color(between: selectedTextColor, to: textColor, percent: percent).cgColor
        }
        currentLayer.position = moveTo
    }
    
    func endDragging(index: Int) {
        if isDraggingBegin == false { return }
        isDraggingBegin = false
        if index == selectedSegmentIndex {
            setSelected(index: selectedSegmentIndex, animated: true)
        } else {
            selectedSegmentIndex = index
            setSelected(index: selectedSegmentIndex, animated: true)
        }
    }
    
    override func draw(_ rect: CGRect) {
        backgroundColor?.setFill()
        UIRectFill(bounds)
        arrowLayer.backgroundColor = UIColor.white.cgColor
        stripLayer.backgroundColor = selectionIndicatorColor.cgColor
        boxLayer.backgroundColor = selectionIndicatorColor.cgColor
        boxLayer.borderColor = selectionIndicatorColor.cgColor
        scrollView.layer.sublayers = nil
        if type == .text {
            textLayers.removeAll()
            for (idx, title) in sectionTitles.enumerated() {
                let size = title.size(withAttributes: [.font: font])
                let strW = size.width + 10
                let strH = size.height + 5
                let y = ceil(frame.height - selectionIndicatorHeight) / 2 - strH / 2 + ((selectionIndicatorLocation == .up) ? selectionIndicatorHeight : 0)
                var rect = CGRect.zero
                if segmentWidthStyle == .fixed {
                    rect = CGRect(x: segmentWidth * CGFloat(idx) + (segmentWidth - strW) / 2, y: y, width: strW, height: strH)
                } else if segmentWidthStyle == .dynamic {
                    var xOffset: CGFloat = 0
                    for (index, wid) in segmentWidths.enumerated() {
                        if idx == index { break }
                        xOffset += wid
                    }
                    rect = CGRect(x: xOffset, y: y, width: segmentWidths[idx], height: strH)
                }
                let tlayer = CATextLayer()
                tlayer.frame = rect
                tlayer.font = font.fontName as CFTypeRef?
                tlayer.fontSize = font.pointSize
                tlayer.alignmentMode = .center
                tlayer.string = title
                tlayer.truncationMode = .end
                if selectedSegmentIndex == idx {
                    tlayer.foregroundColor = selectedTextColor.cgColor
                } else {
                    tlayer.foregroundColor = textColor.cgColor
                }
                tlayer.contentsScale = UIScreen.main.scale
                textLayers.append(tlayer)
                scrollView.layer.addSublayer(tlayer)
            }
        } else if type == .images {
            for (idx, image) in sectionImages.enumerated() {
                let imgW = image.size.width
                let imgH = image.size.height
                let y = ceil(frame.height - selectionIndicatorHeight) / 2 - imgH / 2 + ((selectionIndicatorLocation == .up) ? selectionIndicatorHeight : 0)
                let x = segmentWidth * CGFloat(idx) + (segmentWidth - imgW) / 2
                let rect = CGRect(x: x, y: y, width: imgW, height: imgH)
                let imgLayer = CALayer()
                imgLayer.frame = rect
                if selectedSegmentIndex == idx {
                    if sectionSelectedImages.count > idx {
                        let highlightIcon = sectionSelectedImages[idx]
                        imgLayer.contents = highlightIcon.cgImage
                    } else {
                        imgLayer.contents = image.cgImage
                    }
                } else {
                    imgLayer.contents = image.cgImage
                }
                scrollView.layer.addSublayer(imgLayer)
            }
        } else if type == .textImages {
            for (idx, image) in sectionImages.enumerated() {
                let imgW = image.size.width
                let imgH = image.size.height
                let size = sectionTitles[idx].size(withAttributes: [.font: font])
                let strH = size.height
                let yOffset = ceil(frame.height - selectionIndicatorHeight) / 2 - strH / 2 + ((selectionIndicatorLocation == .up) ? selectionIndicatorHeight : 0)
                var imageXOffset = segmentEdgeInset.left
                if segmentWidthStyle == .fixed {
                    imageXOffset = segmentWidth * CGFloat(idx)
                } else if segmentWidthStyle == .dynamic {
                    for (index, width) in segmentWidths.enumerated() {
                        if index == idx { break }
                        imageXOffset += width
                    }
                    
                    let imageRect = CGRect(x: imageXOffset, y: yOffset, width: imgW, height: imgH)
                    let textXOffset = imageXOffset + imgW + 7
                    let textRect = CGRect(x: textXOffset, y: yOffset, width: segmentWidths[idx] - imgW - 7 - segmentEdgeInset.left - segmentEdgeInset.right, height: strH)
                    
                    let tlayer = CATextLayer()
                    tlayer.frame = textRect
                    tlayer.font = font.fontName as CFTypeRef?
                    tlayer.fontSize = font.pointSize
                    tlayer.alignmentMode = .center
                    tlayer.string = sectionTitles[idx]
                    tlayer.truncationMode = .end
                    
                    let imgLayer = CALayer()
                    imgLayer.frame = imageRect
                    if selectedSegmentIndex == idx {
                        if sectionSelectedImages.count > idx {
                            let highlightIcon = sectionSelectedImages[idx]
                            imgLayer.contents = highlightIcon.cgImage
                        } else {
                            imgLayer.contents = image.cgImage
                        }
                        tlayer.foregroundColor = selectedTextColor.cgColor
                    } else {
                        imgLayer.contents = image.cgImage
                        tlayer.foregroundColor = textColor.cgColor
                    }
                    scrollView.layer.addSublayer(imgLayer)
                    tlayer.contentsScale = UIScreen.main.scale
                    scrollView.layer.addSublayer(tlayer)
                }
            }
        }
        
        let shadow = CALayer()
        shadow.backgroundColor = UIColor(red: 200/255.0, green: 199/255.0, blue: 204/255.0, alpha: 1).cgColor
        shadow.frame = CGRect(x: 0, y: frame.size.height - 1, width: frame.size.width, height: 1)
        scrollView.layer.addSublayer(shadow)
        
        if selectedSegmentIndex != -1 {
            if selectionStyle == .arrow {
                if arrowLayer.superlayer == nil {
                    setArrowFrame()
                    scrollView.layer.addSublayer(arrowLayer)
                }
            } else {
                if stripLayer.superlayer == nil {
                    stripLayer.frame = frameForSelectionIndicator(index: selectedSegmentIndex)
                    scrollView.layer.addSublayer(stripLayer)
                    
                    if selectionStyle == .box && boxLayer.superlayer == nil {
                        boxLayer.frame = frameForFillerSelectionIndicator(index: selectedSegmentIndex)
                        scrollView.layer.insertSublayer(boxLayer, at: 0)
                    }
                }
            }
        }
    }
}

//MARK - Private

extension SegmentControl {
    private func commonInit() {
        scrollView = HMScrollView()
        scrollView.scrollsToTop = false
        scrollView.showsVerticalScrollIndicator = false
        scrollView.showsHorizontalScrollIndicator = false
        addSubview(scrollView)
        isOpaque = false
        arrowLayer.addSublayer(arrowShapeLayer)
        boxLayer.opacity = 1
        boxLayer.borderWidth = 1
        boxLayer.cornerRadius = 12.5
        contentMode = .redraw
    }
    
    private func setArrowFrame() {
        arrowLayer.frame = frameForSelectionIndicator(index: selectedSegmentIndex)
        arrowLayer.mask = nil
        let arrowPath = UIBezierPath()
        var p1 = CGPoint.zero
        var p2 = CGPoint.zero
        var p3 = CGPoint.zero
        if selectionIndicatorLocation == .down {
            p1 = CGPoint(x: arrowLayer.bounds.width / 2, y: 0)
            p2 = CGPoint(x: 0, y: arrowLayer.bounds.height)
            p3 = CGPoint(x: arrowLayer.bounds.width, y: arrowLayer.bounds.height)
        }
        
        if selectionIndicatorLocation == .up {
            p1 = CGPoint(x: arrowLayer.bounds.width / 2, y: arrowLayer.bounds.height)
            p2 = CGPoint(x: arrowLayer.bounds.width, y: 0)
        }
        
        arrowPath.move(to: p2)
        arrowPath.addLine(to: p1)
        arrowPath.addLine(to: p3)
        
        arrowShapeLayer.path = arrowPath.cgPath
        arrowShapeLayer.strokeColor = selectionIndicatorColor.cgColor
        arrowShapeLayer.lineWidth = 1
        arrowShapeLayer.fillColor = nil
        
    }
    
    private func frameForSelectionIndicator(index: Int) -> CGRect {
        var indicatorYOffset: CGFloat = 0
        if selectionIndicatorLocation == .down {
            indicatorYOffset = bounds.height - selectionIndicatorHeight
        }
        
        var sectionWidth: CGFloat = 0
        let addtion: CGFloat = 10
        if type == .text {
            sectionWidth = ceil(sectionTitles[index].size(withAttributes: [.font: font]).width) + addtion
        } else if type == .images {
            sectionWidth = sectionImages[index].size.width
        } else if type == .textImages {
            let strW = ceil(sectionTitles[index].size(withAttributes: [.font: font]).width)
            let imgW = sectionImages[index].size.width
            if segmentWidthStyle == .fixed {
                sectionWidth = max(strW, imgW)
            } else if segmentWidthStyle == .dynamic {
                sectionWidth = imgW + 7 + strW
            }
        }
        
        if selectionStyle == .arrow {
            let startW = segmentWidth * CGFloat(index)
            let endW = startW + segmentWidth
            let x = startW + (endW - startW) / 2 - selectionIndicatorHeight
            return CGRect(x: x, y: indicatorYOffset, width: selectionIndicatorHeight * 2, height: selectionIndicatorHeight)
        } else {
            if selectionStyle == .textWidth && sectionWidth <= segmentWidth && segmentWidthStyle != .dynamic {
                let startW = segmentWidth * CGFloat(index)
                let x = startW + (segmentWidth - sectionWidth) / 2
                return CGRect(x: x, y: indicatorYOffset, width: sectionWidth, height: selectionIndicatorHeight)
            } else {
                if segmentWidthStyle == .dynamic {
                    var segOffset: CGFloat = 0
                    for (idx, width) in segmentWidths.enumerated() {
                        if index == idx { break }
                        segOffset += width
                    }
                    return CGRect(x: segOffset, y: indicatorYOffset, width: segmentWidths[index], height: selectionIndicatorHeight)
                }
                return CGRect(x: segmentWidth * CGFloat(index), y: indicatorYOffset, width: segmentWidth, height: selectionIndicatorHeight)
            }
        }
        
    }
    
    private func frameForFillerSelectionIndicator(index: Int) -> CGRect {
        if segmentWidthStyle == .dynamic {
            var segOffset: CGFloat = 0
            for (idx, width) in segmentWidths.enumerated() {
                if index == idx { break }
                segOffset += width
            }
            return CGRect(x: segOffset, y: 0, width: segmentWidths[index], height: frame.height)
        }
        
        let x = segmentWidth * CGFloat(index)
        let zoomedWidth = segmentWidth * 0.782
        let zoomedHeight = frame.height * 0.625
        let center = CGPoint(x: x + segmentWidth / 2, y: frame.height / 2)
        return CGRect(x: center.x - zoomedWidth / 2, y: center.y - zoomedHeight / 2, width: zoomedWidth, height: zoomedHeight)
    }
    
    private func updateSegmentsRects() {
        guard let scrollView = scrollView else { return }
        scrollView.frame = CGRect(x: 0, y: 0, width: frame.width, height: frame.height)
        if sectionCount > 0 {
            segmentWidth = frame.width / CGFloat(sectionCount)
        }
        if type == .text && segmentWidthStyle == .fixed {
            for str in sectionTitles {
                let strW = ceil(str.size(withAttributes: [.font: font]).width) + segmentEdgeInset.left + segmentEdgeInset.right
                segmentWidth = max(strW, segmentWidth)
            }
        } else if type == .text && segmentWidthStyle == .dynamic {
            var widths = [CGFloat]()
            for str in sectionTitles {
                widths.append(ceil(str.size(withAttributes: [.font: font]).width) + segmentEdgeInset.left + segmentEdgeInset.right)
            }
            segmentWidths = widths
        } else if type == .images {
            for img in sectionImages {
                segmentWidth = max(segmentWidth, img.size.width + segmentEdgeInset.left + segmentEdgeInset.right)
            }
        } else if type == .textImages && segmentWidthStyle == .fixed {
            for str in sectionTitles {
                let strW = ceil(str.size(withAttributes: [.font: font]).width) + segmentEdgeInset.left + segmentEdgeInset.right
                segmentWidth = max(strW, segmentWidth)
            }
        } else if type == .textImages && segmentWidthStyle == .dynamic {
            var widths = [CGFloat]()
            for (idx, str) in sectionTitles.enumerated() {
                let strW = ceil(str.size(withAttributes: [.font: font]).width) + segmentEdgeInset.right
                let imgW = sectionImages[idx].size.width + segmentEdgeInset.left
                let total = imgW + 7 + strW
                widths.append(total)
            }
            segmentWidths = widths
        }
        scrollView.isScrollEnabled = userDraggable
        scrollView.contentSize = CGSize(width: totalSegmentedControlWidth, height: frame.height)
    }
    
    private var sectionCount: Int {
        get {
            if type == .text {
                return sectionTitles.count
            } else if type == .images || type == .textImages {
                return sectionImages.count
            }
            return 0
        }
    }
    
    override func willMove(toSuperview newSuperview: UIView?) {
        if newSuperview == nil { return }
        if sectionTitles.count > 0 || sectionImages.count > 0 {
            updateSegmentsRects()
        }
    }
    
    private var currentLayer: CALayer {
        get {
            switch self.selectionStyle {
            case .textWidth, .fullWidth:
                return stripLayer
            case .box:
                return boxLayer
            case .arrow:
                return arrowLayer
            }
        }
    }
    
    private func frameForCurrentLayer(index: Int) -> CGRect {
        switch selectionStyle {
        case .textWidth, .fullWidth, .arrow:
            return frameForSelectionIndicator(index: index)
        case .box:
            return frameForFillerSelectionIndicator(index: index)
        }
    }
    
    func float(from: CGFloat, to: CGFloat, percent: CGFloat) -> CGFloat {
        if from > to {
            return from - abs((to - from) * percent)
        } else {
            return from + abs((to - from) * percent)
        }
        
    }
    
    func color(between from: UIColor, to: UIColor, percent: CGFloat) -> UIColor {
        if let froms = from.cgColor.components, let tos = to.cgColor.components {
            assert(froms.count >= 3, "Please give a from color with (r, g, b, a)")
            assert(tos.count >= 3, "Please give a to color with (r, g, b, a)")
            let red = float(from: froms[0], to: tos[0], percent: percent)
            let green = float(from: froms[1], to: tos[1], percent: percent)
            let blue = float(from: froms[2], to: tos[2], percent: percent)
            return UIColor(red: red, green: green, blue: blue, alpha: 1)
        }
        return to
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesEnded(touches, with: event)
        let touch = touches.first
        if let location = touch?.location(in: self) {
            if bounds.contains(location) {
                var segment = 0
                if segmentWidthStyle == .fixed {
                    segment = Int((location.x + scrollView.contentOffset.x) / segmentWidth)
                } else if segmentWidthStyle == .dynamic {
                    var left = location.x + scrollView.contentOffset.x
                    for wid in segmentWidths {
                        left -= wid
                        if left <= 0 {
                            break
                        }
                        segment += 1
                    }
                }
                if segment != selectedSegmentIndex && segment < sectionTitles.count {
                    if touchEnabled {
                        setSelected(index: segment, animated: shouldAnimateUserSelection, notify: true)
                    }
                }
            }
        }
    }
    
}


//MARK - Scrolling

extension SegmentControl {
    var totalSegmentedControlWidth: CGFloat {
        get {
            if type == .text && segmentWidthStyle == .fixed {
                return segmentWidth * CGFloat(sectionTitles.count)
            } else if segmentWidthStyle == .dynamic {
                return segmentWidths.reduce(0, +)
            } else {
                return CGFloat(sectionImages.count) * segmentWidth
            }
        }
    }
    
    func scrollToSelectedSegmentIndex() {
        var selectRect = CGRect.zero
        var offset: CGFloat = 0
        if segmentWidthStyle == .fixed {
            selectRect = CGRect(x: segmentWidth * CGFloat(selectedSegmentIndex), y: 0, width: segmentWidth, height: frame.height)
            offset = frame.width / 2 - segmentWidth / 2
        } else {
            var offsetter: CGFloat = 0
            for (idx, wid) in segmentWidths.enumerated() {
                if idx == selectedSegmentIndex { break }
                offsetter += wid
            }
            selectRect = CGRect(x: offsetter, y: 0, width: segmentWidths[selectedSegmentIndex], height: frame.height)
            offsetter = frame.width / 2 - segmentWidths[selectedSegmentIndex] / 2
        }
        var scrollTo = selectRect
        scrollTo.origin.x -= offset
        scrollTo.size.width += offset * 2
        scrollView.scrollRectToVisible(scrollTo, animated: true)
    }
    
}

//MARK - Index changes
extension SegmentControl {
    
    func center(of rect: CGRect) -> CGPoint {
        return CGPoint(x: rect.origin.x + rect.width / 2, y: rect.origin.y + rect.height / 2)
    }
    
    func animateIndicator() {
        CATransaction.begin()
        CATransaction.setAnimationDuration(0.15)
        CATransaction.setAnimationTimingFunction(CAMediaTimingFunction(name: .easeIn))
        setArrowFrame()
        let frame = frameForSelectionIndicator(index: 0)
        arrowLayer.frame = frame
        stripLayer.frame = frame
        boxLayer.frame = frameForFillerSelectionIndicator(index: 0)
        CATransaction.commit()
    }
    
    func setSelected(index: Int, animated: Bool = false, notify: Bool = false) {
        selectedSegmentIndex = index
        setNeedsDisplay()
        
        if index == -1 {
            arrowLayer.removeFromSuperlayer()
            stripLayer.removeFromSuperlayer()
            boxLayer.removeFromSuperlayer()
        } else {
            scrollToSelectedSegmentIndex()
            if animated {
                if selectionStyle == .arrow {
                    if arrowLayer.superlayer == nil {
                        scrollView.layer.addSublayer(arrowLayer)
                        setSelected(index: index, animated: false, notify: true)
                        return
                    }
                } else {
                    if stripLayer.superlayer == nil {
                        scrollView.layer.addSublayer(stripLayer)
                        if selectionStyle == .box, boxLayer.superlayer == nil {
                            scrollView.layer.insertSublayer(boxLayer, at: 0)
                        }
                        setSelected(index: index, animated: false, notify: true)
                        return
                    }
                }
                if notify { notifyForChange(idx: index) }
                arrowLayer.actions = nil
                stripLayer.actions = nil
                boxLayer.actions = nil
                animateIndicator()
            } else {
                let newActions: [String: CAAction]? = ["position": NSNull(), "bounds": NSNull()]
                arrowLayer.actions = newActions
                setArrowFrame()
                stripLayer.actions = newActions
                stripLayer.frame = frameForSelectionIndicator(index: 0)
                
                boxLayer.actions = newActions
                boxLayer.frame = frameForFillerSelectionIndicator(index: 0)
                if notify { notifyForChange(idx: index) }
            }
        }
    }
    
    
    func notifyForChange(idx: Int) {
        if let _ = self.superview {
            sendActions(for: .valueChanged)
        }
        if let block = indexChangeBlock {
            block(idx)
        }
    }
    
}
