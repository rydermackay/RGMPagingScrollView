//
//  ViewController.swift
//  Paging
//
//  Created by Squirrel on 2019/6/28.
//  Copyright © 2019 Squirrel. All rights reserved.
//

import UIKit

class ViewController: UIViewController {
    
    var pagingView = PagingScrollView(frame: UIScreen.main.bounds)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Example"
        pagingView.pageDelegate = self
        pagingView.pageDataSource = self
        view.addSubview(pagingView)
        setControl()
        // Do any additional setup after loading the view.
    }
    
    func setControl() {
        pagingView.translatesAutoresizingMaskIntoConstraints = false
        let top = NSLayoutConstraint(item: pagingView, attribute: NSLayoutConstraint.Attribute.top, relatedBy: NSLayoutConstraint.Relation.equal, toItem: view.safeAreaLayoutGuide, attribute: NSLayoutConstraint.Attribute.top, multiplier: 1, constant: 0)
        let bottom = NSLayoutConstraint(item: pagingView, attribute: NSLayoutConstraint.Attribute.bottomMargin, relatedBy: NSLayoutConstraint.Relation.equal, toItem: view, attribute: NSLayoutConstraint.Attribute.bottomMargin, multiplier: 1, constant: 0)
        let left = NSLayoutConstraint(item: pagingView, attribute: NSLayoutConstraint.Attribute.left, relatedBy: NSLayoutConstraint.Relation.equal, toItem: view, attribute: NSLayoutConstraint.Attribute.left, multiplier: 1, constant: 0)
        let right = NSLayoutConstraint(item: pagingView, attribute: NSLayoutConstraint.Attribute.right, relatedBy: NSLayoutConstraint.Relation.equal, toItem: view, attribute: NSLayoutConstraint.Attribute.right, multiplier: 1, constant: 0)
        
        view.addConstraints([top, bottom, left, right])
        pagingView.headerFrame = CGRect(x: 0, y: 0, width: UIScreen.main.bounds.width, height: 44)
        pagingView.bounces = false
        pagingView.segmentControl = SegmentControl(frame: pagingView.headerFrame)
        let segmentControl = pagingView.segmentControl!
        segmentControl.font = UIFont.systemFont(ofSize: 14)
        segmentControl.selectionIndicatorLocation = .down
        segmentControl.selectionStyle = .box
        segmentControl.segmentWidthStyle = .fixed
//        segmentControl.selectionIndicatorColor = UIColor(red: 1, green: 0, blue: 0, alpha: 1)
        segmentControl.selectionIndicatorHeight = 0
        segmentControl.backgroundColor = UIColor(red: 0x00/255.0, green: 0x00/255.0, blue: 0x00/255.0, alpha: 1)
        segmentControl.textColor = UIColor(red: 0xcc/255.0, green: 0xcc/255.0, blue: 0xcc/255.0, alpha: 1)
        segmentControl.selectedTextColor = UIColor(red: 1, green: 1, blue: 1, alpha: 1)
        segmentControl.shouldAnimateUserSelection = true
        
        pagingView.register(UITableView.classForCoder(), forCellWithReuseIdentifier: "PageReuseIdentifier")
    }
}


extension ViewController: PagingScrollViewDelegate, PagingScrollViewDataSource {
    func numberOfPages(in view: PagingScrollView) -> Int {
        return 2
    }
    
    func view(for idx: Int, in view: PagingScrollView) -> UIView {
        let tableView = view.dequeueReusablePage(with: "PageReuseIdentifier", for: idx) as! UITableView
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "CellReuseIdentifier")
        if let _ = tableView.dataSource, let _ = tableView.delegate {
            return tableView
        }
        tableView.tag = idx
        tableView.delegate = self
        tableView.dataSource = self
        tableView.tableFooterView = UIView()
        return tableView
    }
    
    func title(of view: PagingScrollView) -> [String]? {
        return ["Item1", "Item2"]
    }
    
}

extension UIViewController: UITableViewDataSource, UITableViewDelegate {
    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if tableView.tag == 0 {
            return 11
        } else {
            return 22
        }
    }
    
    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "CellReuseIdentifier", for: indexPath)
        if tableView.tag == 0 {
            cell.textLabel?.text = "item1_\(indexPath.row)"
        } else {
            cell.textLabel?.text = "item2_\(indexPath.row)"
        }
        cell.selectionStyle = .none
        if indexPath.row % 2 == 0 {
            cell.contentView.backgroundColor = UIColor(red: 0xFA / 255.0, green: 0xFA / 255.0, blue: 0xFA / 255.0, alpha: 1)
        } else {
            cell.contentView.backgroundColor = UIColor.white
        }
        return cell
    }
    
    public func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        return 65
    }
}
