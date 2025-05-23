//
//  AboutViewController.swift
//  MastodonProfileUI
//
//  Created by Nikita Prokhorchuk on 3.05.25.
//

import UIKit
import UIKitFoundation
import MastodonKit

@MainActor
protocol AboutViewControllerDelegate: AnyObject {
    
    func aboutViewController(_ viewController: AboutViewController, didSelectURL url: URL)
}

final class AboutViewController: ViewController {
    
    private static let cellIdentifier = NSStringFromClass(UICollectionViewListCell.self)
    
    let collectionView: UICollectionView = {
        var layoutConfiguration = UICollectionLayoutListConfiguration(appearance: .insetGrouped)
        layoutConfiguration.backgroundColor = .systemBackground
        let layout = UICollectionViewCompositionalLayout.list(using: layoutConfiguration)
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        collectionView.register(UICollectionViewListCell.self, forCellWithReuseIdentifier: AboutViewController.cellIdentifier)
        return collectionView
    }()
    
    var fields = [Field]() {
        didSet { collectionView.reloadData() }
    }
    
    weak var delegate: (any AboutViewControllerDelegate)?
    
    override func setupCommon() {
        super.setupCommon()
        collectionView.dataSource = self
    }
    
    override func loadView() {
        view = collectionView
    }
}

extension AboutViewController: UICollectionViewDataSource {
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        fields.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: Self.cellIdentifier, for: indexPath) as! UICollectionViewListCell
        let field = fields[indexPath.item]
        cell.contentConfiguration = FieldView.Configuration(title: field.name, value: field.value)
        var backgroundConfiguration = UIBackgroundConfiguration.listPlainCell()
        backgroundConfiguration.backgroundColor = .secondarySystemBackground
        cell.backgroundConfiguration = backgroundConfiguration
        (cell.contentView as! FieldView).textViewDelegate = self
        return cell
    }
}

extension AboutViewController: UITextViewDelegate {
    
    func textView(_ textView: UITextView, shouldInteractWith URL: URL, in characterRange: NSRange) -> Bool {
        delegate?.aboutViewController(self, didSelectURL: URL)
        return false
    }
}
