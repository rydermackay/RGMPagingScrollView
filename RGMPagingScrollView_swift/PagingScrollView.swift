//
//  PagingScrollView.swift
//  Paging
//
//  Created by Squirrel on 2019/6/28.
//  Copyright © 2019 Squirrel. All rights reserved.
//

import UIKit

enum PagingDirection {
    case horizontal
    case vertical
}

@objc protocol PagingScrollViewDelegate: UIScrollViewDelegate {
    @objc optional func pagingView(_ view: PagingScrollView, scrollTo page: Int)
    @objc optional func pagingView(_ view: PagingScrollView, scrollTo bonus: Bool)
}

@objc protocol PagingScrollViewDataSource {
    @objc func numberOfPages(in view: PagingScrollView) -> Int
    @objc func view(for idx: Int, in view: PagingScrollView) -> UIView
    
    @objc optional func title(of view: PagingScrollView) -> [String]?
}


class PagingScrollView: UIScrollView {
    var direction: PagingDirection = .horizontal
    var headerFrame: CGRect = .zero
    var segmentControl: SegmentControl? = nil {
        didSet {
            segmentControl?.addTarget(self, action: #selector(handleSegmentClicked), for: .valueChanged)
        }
    }
    
    weak var pageDelegate: PagingScrollViewDelegate? {
        get {
            return privateDelegate.delegate
        }
        set {
            privateDelegate.delegate = newValue
            super.delegate = privateDelegate
        }
    }
    weak var pageDataSource: PagingScrollViewDataSource?
    
    var currentPage: Int {
        get {
            var page = 0
            switch direction {
            case .horizontal:
                page = Int(floor(bounds.minX / (model!.width + model!.gutter)))
            case .vertical:
                page = Int(floor(bounds.minY / (model!.height + model!.gutter)))
            }
            page = max(page, 0)
            page = min(page, model!.pageNums - 1)
            return page
        }
        set {
            setCurrentPage(newValue, animated: false)
        }
    }
    
    private var viewModel: PagingScrollViewModel?
    private var visiblePages = Set<UIView>()
    private var reusablePages = [String: Set<UIView>]()
    private var registeredClasses = [String: AnyClass]()
    private var registeredNibs = [String: UINib]()
    
    private var privateDelegate: NovaPagingScrollViewPrivateDelegate!
    private var startOffset: CGFloat = 0
    
    
    private var model: PagingScrollViewModel? {
        get {
            if viewModel == nil {
                viewModel = PagingScrollViewModel(pageNums: pageDataSource?.numberOfPages(in: self) ?? 0, width: UIScreen.main.bounds.width, height: bounds.height - headerFrame.height, gutter: 0)
                contentSize = viewModel!.contentSize(for: direction)
                let temp = frame
                switch direction {
                case .horizontal:
                    frame.size.width += viewModel!.gutter
                    frame.origin.x -= viewModel!.gutter / 2
                case .vertical:
                    frame.size.height += viewModel!.gutter
                    frame.origin.y -= viewModel!.gutter / 2
                }
                frame = temp
                segmentControl?.sectionTitles = pageDataSource?.title?(of: self)
            }
            return viewModel
        } set {
            viewModel = newValue
        }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        commonInit()
    }
    
    deinit {
        pageDelegate = nil
    }
    
    func commonInit() {
        if #available(iOS 11.0, *) {
            contentInsetAdjustmentBehavior = .never
        }
        isPagingEnabled = true
        showsHorizontalScrollIndicator = false
        showsVerticalScrollIndicator = false
        privateDelegate = NovaPagingScrollViewPrivateDelegate(pagingView: self)
        startOffset = -1
        initHeader()
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        guard let model = model else { return }
        let pageNums = model.pageNums
        let visibleBounds = clipsToBounds ? bounds : convert(superview?.bounds ?? .zero, from: superview)
        var pageLength: CGFloat = 0
        var amin = pageLength
        var amax = pageLength
        
        switch direction {
        case .horizontal:
            pageLength = model.width + model.gutter
            amin = visibleBounds.minX + model.gutter / 2
            amax = visibleBounds.maxX - model.gutter / 2
        case .vertical:
            pageLength = model.height + model.gutter
            amin = visibleBounds.minY + model.gutter / 2
            amax = visibleBounds.maxY - model.gutter / 2
        }
        amax -= 1
        let firstNeed = max(0, Int(floor(amin / pageLength)))
        let lastNeed = min(Int(floor(amax / pageLength)), pageNums - 1)
        var removedPages = Set<UIView>()
        for visiblePage in visiblePages {
            if visiblePage.tag < firstNeed || visiblePage.tag > lastNeed {
                visiblePage.removeFromSuperview()
                removedPages.insert(visiblePage)
                queuePageForReuse(visiblePage)
            }
        }
        visiblePages = visiblePages.subtracting(removedPages)
        if pageNums > 0 {
            for idx in firstNeed...lastNeed {
                if !isPageDisplaying(idx) {
                    let page = pageDataSource!.view(for: idx, in: self)
                    page.frame = frame(for: idx)
                    page.tag = idx
                    insertSubview(page, at: 0)
                    visiblePages.insert(page)
                }
            }
        }
        positionSegmentControl()
    }
}


//MARK - public Method
extension PagingScrollView {
    func setCurrentPage(_ index: Int, animated: Bool) {
        var offset = self.frame(for: index).origin
        switch direction {
        case .horizontal:
            offset.x -= model!.gutter / 2
            offset.y = 0
        case .vertical:
            offset.y -= model!.gutter / 2
        }
        setContentOffset(offset, animated: animated)
    }
    
    
    func dequeueReusablePage(with identifier: String, for index: Int) -> UIView {
        assert(!identifier.isEmpty, "Identifier can not be empty ")
        var set = reusablePages(with: identifier)
        if set.count > 0 {
            var page: UIView!
            var minus = 0
            for view in set {
                if view.tag == index {
                    view.prepareForReuse()
                    set.remove(view)
                    return view
                } else {
                    if abs(view.tag - index) > minus {
                        minus = abs(view.tag - index)
                        page = view
                    }
                }
            }
            page.prepareForReuse()
            set.remove(page)
            return page
        }
        assert(registeredClasses.keys.contains(identifier) || registeredNibs.keys.contains(identifier), "No registered class or nib for identifier \(identifier)")
        let pageClass = registeredClasses[identifier] as? UIView.Type
        var page = pageClass?.init(frame: .zero)
        if page == nil {
            let registeredNib = registeredNibs[identifier]
            let topLevel = registeredNib?.instantiate(withOwner: self, options: nil)
            assert(topLevel?.count == 1, "")
            page = topLevel?.first as? UIView
        }
        page?.pageReuseIdentifier = identifier
        return page!
    }
    
    var selectedPage: UIView? { get {
        return page(at: currentPage)
        } }
    
    func page(at index: Int) -> UIView? {
        for view in visiblePages {
            if view.tag == index {
                return view
            }
        }
        return nil
    }
    
    func register(_ aClass: AnyClass?, forCellWithReuseIdentifier identifier: String) {
        assert(!identifier.isEmpty, "Identifier can not be empty ")
        if let aClass = aClass {
            registeredClasses[identifier] = aClass
            registeredNibs.removeValue(forKey: identifier)
        }
    }
    
    func register(_ nib: UINib?, forCellWithReuseIdentifier identifier: String) {
        assert(!identifier.isEmpty, "Identifier can not be empty ")
        if let nib = nib {
            registeredNibs[identifier] = nib
            registeredClasses.removeValue(forKey: identifier)
        }
    }
    
    func reloadData() {
        for view in visiblePages {
            view.removeFromSuperview()
        }
        visiblePages.removeAll()
        reusablePages.removeAll()
        model = nil
        setNeedsLayout()
    }
    
    func initHeader() {
        
    }
    
    @objc func handleSegmentClicked(sender: Any?) {
        if let seg = segmentControl {
            setCurrentPage(seg.selectedSegmentIndex, animated: true)
            if let delegate = pageDelegate {
                delegate.pagingView?(self, scrollTo: seg.selectedSegmentIndex)
            }
        }
    }
    
    override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
        if clipsToBounds == false {
            let newPoint = superview?.convert(point, from: self) ?? .zero
            return superview?.bounds.contains(newPoint) ?? false
        } else {
            return super.point(inside: point, with: event)
        }
    }
    
    
}

extension PagingScrollView: UIScrollViewDelegate {
    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        if decelerate == false {
            didScroll(to: currentPage)
        }
    }
    
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        didScroll(to: currentPage)
    }
    
    func scrollViewDidEndScrollingAnimation(_ scrollView: UIScrollView) {
        didScroll(to: currentPage)
    }
    
    func didScroll(to page: Int) {
        pageDelegate?.pagingView?(self, scrollTo: page)
    }
    
    func pageIndexOfScrollView(xoffset: CGFloat) -> Int {
        return Int(xoffset / frame.width)
    }
    
    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        segmentControl?.beginDragging(index: pageIndexOfScrollView(xoffset: scrollView.contentOffset.x))
        startOffset = scrollView.contentOffset.x
    }
    
    func reportScrollViewDidScrollToBonus(_ bonus: Bool) {
        pageDelegate?.pagingView?(self, scrollTo: bonus)
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if scrollView.contentOffset.x <= 0 {
            if startOffset == 0 {
                reportScrollViewDidScrollToBonus(true)
            }
            return
        }
        
        if scrollView.contentOffset.x >= scrollView.contentSize.width - model!.width {
            if startOffset == CGFloat(model!.pageNums - 1) * model!.width {
                reportScrollViewDidScrollToBonus(false)
            }
            return
        }
        
        let percent = (scrollView.contentOffset.x - startOffset) / scrollView.contentSize.width
        segmentControl?.dragging(percent: percent)
    }
    
    func scrollViewWillEndDragging(_ scrollView: UIScrollView, withVelocity velocity: CGPoint, targetContentOffset: UnsafeMutablePointer<CGPoint>) {
        segmentControl?.endDragging(index: pageIndexOfScrollView(xoffset: targetContentOffset.pointee.x))
        startOffset = -1
    }
    
}

//MARK - Private methods
extension PagingScrollView {
    private func frame(for idx: Int) -> CGRect {
        guard let model = model else { return .zero }
        switch direction {
        case .horizontal:
            return CGRect(x: (model.width + model.gutter) * CGFloat(idx) + floor(model.gutter / 2), y: headerFrame.size.height, width: model.width, height: model.height)
        case .vertical:
            return CGRect(x: 0, y: (model.height + model.gutter) * CGFloat(idx) + floor(model.gutter / 2), width: model.width, height: model.height)
        }
    }
    
    private func isPageDisplaying(_ index: Int) -> Bool {
        for page in visiblePages {
            if page.tag == index {
                return true
            }
        }
        return false
    }
    
    private func reusablePages(with identifier: String) -> Set<UIView> {
        if identifier.isEmpty { return Set<UIView>() }
        let set = reusablePages[identifier] ?? Set<UIView>()
        reusablePages[identifier] = set
        return set
        
    }
    
    private func queuePageForReuse(_ page: UIView) {
        if page.pageReuseIdentifier.isEmpty { return }
        var set = self.reusablePages(with: page.pageReuseIdentifier)
        set.insert(page)
        reusablePages[page.pageReuseIdentifier] = set
    }
    
    private func positionSegmentControl() {
        guard let seg = segmentControl else { return }
        var frame = headerFrame
        frame.origin = CGPoint(x: contentOffset.x, y: 0)
        seg.frame = frame
        if seg.superview == nil {
            addSubview(seg)
        }
        bringSubviewToFront(seg)
    }
    
}


struct PagingScrollViewModel {
    var pageNums: Int
    var width: CGFloat
    var height: CGFloat
    var gutter: CGFloat
    
    func contentSize(for direction: PagingDirection) -> CGSize {
        switch direction {
        case .horizontal:
            return CGSize(width: (width + gutter) * CGFloat(pageNums), height: height)
        case .vertical:
            return CGSize(width: width, height: (height + gutter) * CGFloat(pageNums))
        }
    }
}


fileprivate extension UIView {
    static var PageReuseIdentifierKey = "pageReuseIdentifier"
    
    var pageReuseIdentifier: String {
        get {
            return objc_getAssociatedObject(self, &UIView.PageReuseIdentifierKey) as? String ?? ""
        }
        set {
            objc_setAssociatedObject(self, &UIView.PageReuseIdentifierKey, newValue, .OBJC_ASSOCIATION_COPY_NONATOMIC)
        }
    }
    
    func prepareForReuse() {
        
    }
}



private class NovaPagingScrollViewPrivateDelegate: NSObject, UIScrollViewDelegate {
    
    weak var pagingScrollView: PagingScrollView!
    weak var delegate: PagingScrollViewDelegate?
    
    init(pagingView: PagingScrollView) {
        self.pagingScrollView = pagingView
    }
    
    override func responds(to aSelector: Selector!) -> Bool {
        return super.responds(to: aSelector) || (delegate?.responds(to: aSelector) ?? false)
    }
    
    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        pagingScrollView.scrollViewDidEndDragging(scrollView, willDecelerate: decelerate)
        if let _ = delegate {
            delegate?.scrollViewDidEndDragging?(scrollView, willDecelerate: decelerate)
        }
    }
    
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        pagingScrollView.scrollViewDidEndDecelerating(scrollView)
        if let _ = delegate {
            delegate?.scrollViewDidEndDecelerating?(scrollView)
        }
    }
    
    func scrollViewDidEndScrollingAnimation(_ scrollView: UIScrollView) {
        pagingScrollView.scrollViewDidEndScrollingAnimation(scrollView)
        if let _ = delegate {
            delegate?.scrollViewDidEndScrollingAnimation?(scrollView)
        }
    }
    
    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        pagingScrollView.scrollViewWillBeginDragging(scrollView)
        if let _ = delegate {
            delegate?.scrollViewWillBeginDragging?(scrollView)
        }
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        pagingScrollView.scrollViewDidScroll(scrollView)
        if let _ = delegate {
            delegate?.scrollViewDidScroll?(scrollView)
        }
    }
    
    func scrollViewWillEndDragging(_ scrollView: UIScrollView, withVelocity velocity: CGPoint, targetContentOffset: UnsafeMutablePointer<CGPoint>) {
        pagingScrollView.scrollViewWillEndDragging(scrollView, withVelocity: velocity, targetContentOffset: targetContentOffset)
        if let _ = delegate{
            delegate?.scrollViewWillEndDragging?(scrollView, withVelocity: velocity, targetContentOffset: targetContentOffset)
        }
    }
    
}
