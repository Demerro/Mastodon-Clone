//
//  FeedCollectionView.swift
//  MastodonSharedUI
//
//  Created by Nikita Prokhorchuk on 21.05.25.
//

import UIKit

public final class FeedCollectionView: UICollectionView {
    
    private var oldContentSize = CGSize.zero
    
    public weak var observer: Observer?
    
    public override func layoutSubviews() {
        super.layoutSubviews()
        if oldContentSize != contentSize {
            oldContentSize = contentSize
            observer?.feedCollectionView(self, didChangeContentSize: contentSize)
        }
    }
}

extension FeedCollectionView {
    
    @MainActor
    public protocol Observer: AnyObject {
        func feedCollectionView(_ collectionView: FeedCollectionView, didChangeContentSize contentSize: CGSize)
    }
}
