//
//  PageContentView.swift
//  DNSPageView
//
//  Created by Daniels on 2018/2/24.
//  Copyright © 2018 Daniels. All rights reserved.
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.
//

import UIKit
import CollectionViewPagingLayout
import SnapKit

public protocol PageContentViewDelegate: AnyObject {
    func contentView(_ contentView: PageContentView, didEndScrollAt index: Int)
    func contentView(_ contentView: PageContentView, scrollingWith sourceIndex: Int, targetIndex: Int, progress: CGFloat)
}


private let CellID = "CellID"
public class PageContentViewCell: UICollectionViewCell, ScaleTransformView {
    public var scaleOptions = ScaleTransformViewOptions(
        minScale: 0.95,
        maxScale: 1,
        scaleRatio: 0.40,
        translationRatio: .init(x: 0.92, y: 0.20),
        minTranslationRatio: .init(x: -5.00, y: -5.00),
        maxTranslationRatio: .init(x: 2.00, y: 0.00),
        keepVerticalSpacingEqual: true,
        keepHorizontalSpacingEqual: true,
        scaleCurve: .linear,
        translationCurve: .linear,
        shadowEnabled: false,
        blurEffectEnabled: false,
        rotation3d: nil,
        translation3d: nil
    )

    // The card view that we apply transforms on
    var card: UIView!
    
    override init(frame: CGRect) {
        super.init(frame: frame)
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
}

public class PageContentView: UIView {
    
    public weak var delegate: PageContentViewDelegate?
    
    public weak var container: PageViewContainer?

    public weak var eventHandler: PageEventHandleable?
    
    private (set) public var style: PageStyle = PageStyle() {
        didSet {
            collectionView.semanticContentAttribute = style.isRTL ? .forceRightToLeft : .forceLeftToRight
        }
    }

    private (set) public var childViewControllers : [UIViewController] = [UIViewController]()
    
    /// 初始化后，默认显示的页数
    private (set) public var currentIndex: Int {
        didSet {
            guard delegate == nil else { return }
            container?.updateCurrentIndex(currentIndex)
        }
    }

    private var startOffsetX: CGFloat = 0
    
    private var isForbidDelegate: Bool = false
    
    private (set) public lazy var collectionView: UICollectionView = {
//        let layout = PageCollectionViewFlowLayout()
//        layout.minimumLineSpacing = 0
//        layout.minimumInteritemSpacing = 0
//        layout.scrollDirection = .horizontal
        
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: CollectionViewPagingLayout())
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.isPagingEnabled = true
        collectionView.scrollsToTop = false
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.bounces = false
        if #available(iOS 10, *) {
            collectionView.isPrefetchingEnabled = false
        }
        collectionView.register(PageContentViewCell.self, forCellWithReuseIdentifier: CellID)
        return collectionView
    }()
    
    
    public init(frame: CGRect, style: PageStyle, childViewControllers: [UIViewController], currentIndex: Int = 0) {
        assert(currentIndex >= 0 && currentIndex < childViewControllers.count,
               "currentIndex < 0 or currentIndex >= childViewControllers.count")
        self.currentIndex = currentIndex
        super.init(frame: frame)
        setupCollectionView()
        configure(childViewControllers: childViewControllers, style: style, currentIndex: currentIndex)
    }
    
    required public init?(coder aDecoder: NSCoder) {
        self.currentIndex = 0
        super.init(coder: aDecoder)
        setupCollectionView()
    }
    
    private func setupCollectionView() {
        addSubview(collectionView)
        collectionView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }
    
//    public override func layoutSubviews() {
//        super.layoutSubviews()
//        collectionView.frame = CGRect(origin: CGPoint.zero, size: frame.size)
//        let layout = collectionView.collectionViewLayout as! CollectionViewPagingLayout
//        layout.itemSize = frame.size
//        layout.offset = CGFloat(currentIndex) * frame.size.width
//        layout.invalidateLayout()
//    }
}


extension PageContentView {
    internal func configure(childViewControllers: [UIViewController]? = nil, style: PageStyle? = nil, currentIndex: Int? = nil) {
        if let childViewControllers = childViewControllers {
            self.childViewControllers = childViewControllers
        }
        if let style = style {
            self.style = style
        }
        if let currentIndex = currentIndex {
            collectionView.collectionViewLayout.invalidateLayout()
            self.currentIndex = currentIndex
        }
        configureSubViews()
        collectionView.reloadData()
        setNeedsLayout()
    }
    
    private func configureSubViews() {
        collectionView.backgroundColor = style.contentViewBackgroundColor
        collectionView.isScrollEnabled = style.isContentScrollEnabled
    }
}


extension PageContentView: UICollectionViewDataSource {
    public func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return childViewControllers.count
    }
    
    public func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: CellID, for: indexPath)
        
        for subview in cell.contentView.subviews {
            subview.removeFromSuperview()
        }
        let childViewController = childViewControllers[indexPath.item]

        eventHandler = childViewController as? PageEventHandleable
//        print("cell.contentView.frame.size:\(cell.contentView.frame.size)")
//        childViewController.view.frame = CGRect(origin: CGPoint.zero, size: cell.contentView.frame.size)
            
        cell.contentView.addSubview(childViewController.view)
        childViewController.view.snp.remakeConstraints { make in
            make.edges.equalToSuperview()
        }
        return cell
    }
}


extension PageContentView: UICollectionViewDelegate {
    
    
    public func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        isForbidDelegate = false
        startOffsetX = scrollView.contentOffset.x
        
    }
    
    public func scrollViewDidScroll(_ scrollView: UIScrollView) {
        updateUI(scrollView)
    }
    
    
    public func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        if !decelerate {
            collectionViewDidEndScroll(scrollView)
        }
    }
    
    public func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        collectionViewDidEndScroll(scrollView)
    }
    
    
    private func collectionViewDidEndScroll(_ scrollView: UIScrollView) {
        
        let index = Int(round(scrollView.contentOffset.x / scrollView.frame.width))
        
        delegate?.contentView(self, didEndScrollAt: index)
        
        if index != currentIndex {
            let childViewController = childViewControllers[currentIndex]
            (childViewController as? PageEventHandleable)?.contentViewDidDisappear()
        }
        
        currentIndex = index
        
        eventHandler = childViewControllers[currentIndex] as? PageEventHandleable
        
        eventHandler?.contentViewDidEndScroll()
        
    }

    
    
    private func updateUI(_ scrollView: UIScrollView) {
        if isForbidDelegate {
            return
        }
        
        var progress: CGFloat = 0
        var targetIndex = 0
        var sourceIndex = 0
        
        
        progress = scrollView.contentOffset.x.truncatingRemainder(dividingBy: scrollView.frame.width) / scrollView.frame.width
        if progress == 0 || progress.isNaN {
            return
        }
        let index = Int(scrollView.contentOffset.x / scrollView.frame.width)
        if collectionView.contentOffset.x > startOffsetX { // 左滑动
            sourceIndex = index
            targetIndex = index + 1
        } else {
            sourceIndex = index + 1
            targetIndex = index
            progress = 1 - progress
        }
        guard targetIndex < childViewControllers.count && targetIndex >= 0 else { return }

        
        if progress > 0.998 {
            progress = 1
        }
        
        delegate?.contentView(self, scrollingWith: sourceIndex, targetIndex: targetIndex, progress: progress)
    }
}


extension PageContentView: PageTitleViewDelegate {
    public func titleView(_ titleView: PageTitleView, didSelectAt index: Int) {
        isForbidDelegate = true
        
        guard currentIndex < childViewControllers.count else { return }
        
        currentIndex = index
        
        guard let layout = collectionView.collectionViewLayout as? CollectionViewPagingLayout else { return }

        layout.setCurrentPage(currentIndex, animated: false)
//        let indexPath = IndexPath(item: index, section: 0)
//        
//        collectionView.scrollToItem(at: indexPath, at: .left, animated: false)
    }
}


