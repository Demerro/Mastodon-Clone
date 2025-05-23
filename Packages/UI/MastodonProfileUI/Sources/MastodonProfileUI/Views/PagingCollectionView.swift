//
//  PagingCollectionView.swift
//  MastodonProfileUI
//
//  Created by Nikita Prokhorchuk on 29.04.25.
//

import UIKit
import SwiftUtilities
import UIKitFoundation

@MainActor
protocol PagingCollectionViewDelegate: AnyObject {
    
    func collectionViewDidBeginPaging(_ collectionView: PagingCollectionView, from fromIndexPath: IndexPath, to toIndexPath: IndexPath)
    
    func collectionViewDidEndPaging(_ collectionView: PagingCollectionView, at indexPath: IndexPath)
    
    func collectionViewDidPaging(_ collectionView: PagingCollectionView, withProgress progress: CGFloat)
}

final class PagingCollectionView: UICollectionView {
    
    @_nonoverride
    let collectionViewLayout: UICollectionViewCompositionalLayout = {
        let item = NSCollectionLayoutItem(layoutSize: NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0), heightDimension: .fractionalHeight(1.0)))
        let group = NSCollectionLayoutGroup.vertical(layoutSize: NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0), heightDimension: .fractionalHeight(1.0)), subitem: item, count: 1)
        let section = NSCollectionLayoutSection(group: group)
        let configuration = UICollectionViewCompositionalLayoutConfiguration()
        configuration.scrollDirection = .horizontal
        configuration.contentInsetsReference = .none
        return UICollectionViewCompositionalLayout(section: section, configuration: configuration)
    }()
    
    var hasActivePaging: Bool { pagingState != nil }
    
    private var lastPagingIndexPath: IndexPath?
    
    private var pagingState: PagingState?
    
    weak var pagingDelegate: (any PagingCollectionViewDelegate)?
    
    init(frame: CGRect = .zero) {
        super.init(frame: frame, collectionViewLayout: collectionViewLayout)
        setupCommon()
    }
    
    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        let startContentOffsetX = startContentOffset.x
        let endContentOffsetX = endContentOffset.x
        let contentOffsetX = clamp(contentOffset.x, min: startContentOffsetX, max: endContentOffsetX)
        if let pagingState {
            let fromContentOffsetX = bounds.width * CGFloat(pagingState.fromIndexPath.item)
            let toContentOffsetX = bounds.width * CGFloat(pagingState.toIndexPath.item)
            let progress = clamp((contentOffsetX - fromContentOffsetX) / (toContentOffsetX - fromContentOffsetX), min: 0.0, max: 1.0)
            self.pagingState!.progress = progress
            pagingDelegate?.collectionViewDidPaging(self, withProgress: progress)
            if progress == 0.0 {
                let fromIndexPath = pagingState.fromIndexPath
                self.pagingState = nil
                pagingDelegate?.collectionViewDidEndPaging(self, at: fromIndexPath)
            } else if progress == 1.0 {
                let toIndexPath = pagingState.toIndexPath
                lastPagingIndexPath = pagingState.toIndexPath
                self.pagingState = nil
                pagingDelegate?.collectionViewDidEndPaging(self, at: toIndexPath)
            }
        } else {
            guard numberOfItems(inSection: 0) > 0 else {
                lastPagingIndexPath = nil
                return
            }
            if lastPagingIndexPath == nil {
                lastPagingIndexPath = IndexPath(item: 0, section: 0)
            }
            let lastPagingIndexPath = lastPagingIndexPath!
            let pagingOffsetX = bounds.width * CGFloat(lastPagingIndexPath.item)
            if contentOffsetX > pagingOffsetX {
                let fromIndexPath = lastPagingIndexPath
                let toIndexPath = IndexPath(item: lastPagingIndexPath.item + 1, section: lastPagingIndexPath.section)
                pagingState = PagingState(fromIndexPath: fromIndexPath, toIndexPath: toIndexPath, progress: 0.0)
                pagingDelegate?.collectionViewDidBeginPaging(self, from: fromIndexPath, to: toIndexPath)
            } else if contentOffsetX < pagingOffsetX {
                let fromIndexPath = lastPagingIndexPath
                let toIndexPath = IndexPath(item: lastPagingIndexPath.item - 1, section: lastPagingIndexPath.section)
                pagingState = PagingState(fromIndexPath: fromIndexPath, toIndexPath: toIndexPath, progress: 0.0)
                pagingDelegate?.collectionViewDidBeginPaging(self, from: fromIndexPath, to: toIndexPath)
            }
        }
    }
    
    private func setupCommon() {
        alwaysBounceVertical = false
        showsVerticalScrollIndicator = false
        showsHorizontalScrollIndicator = false
        isPagingEnabled = true
        contentInsetAdjustmentBehavior = .never
    }
}

extension PagingCollectionView {
    
    private struct PagingState {
        
        var fromIndexPath: IndexPath
        
        var toIndexPath: IndexPath
        
        var progress: CGFloat
    }
}

final class PagingCollectionViewCell: CollectionViewCell {
    
    static let identifier = NSStringFromClass(PagingCollectionViewCell.self)
    
    private weak var _hostedView: UIView? {
        didSet {
            if let oldValue {
                if oldValue.isDescendant(of: self) {
                    oldValue.removeFromSuperview()
                }
            }

            if let _hostedView {
                _hostedView.frame = contentView.bounds
                contentView.addSubview(_hostedView)
            }
        }
    }

    weak var hostedView: UIView? {
        get {
            guard _hostedView?.isDescendant(of: self) ?? false else {
                _hostedView = nil
                return nil
            }

            return _hostedView
        }
        set {
            _hostedView = newValue
        }
    }
    
    override func prepareForReuse() {
        hostedView = nil
        super.prepareForReuse()
    }
}
