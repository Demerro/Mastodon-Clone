//
//  InstancesViewController.swift.swift
//  MastodonAuthorizationUI
//
//  Created by Nikita Prokhorchuk on 30.11.24.
//

import UIKit
import UIKitFoundation
import MastodonUtilities
import MastodonKit

@MainActor
protocol InstancesViewControllerDelegate: AnyObject {
    
    func instancesViewController(_ viewController: InstancesViewController, didSelectInstance instance: Instance)
}

final class InstancesViewController: ViewController {
    
    private let instancesView = InstancesView(frame: .zero)
    
    private let instancesStore = InstancesStore()
    
    private var isShimmering = false
    
    private lazy var dataSource = makeDataSource()
    
    private let searchController = UISearchController()
    
    private var runningTask: Task<Void, Error>?
    
    weak var delegate: (any InstancesViewControllerDelegate)?
    
    override func setupCommon() {
        super.setupCommon()
        
        title = "Add account"
        setContentScrollView(instancesView.collectionView)
        
        instancesView.collectionView.delegate = self
        instancesView.collectionView.prefetchDataSource = self
        
        setupSearchBar()
        
        runListTask()
    }
    
    override func loadView() {
        view = instancesView
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        runningTask?.cancel()
        runningTask = nil
    }
}

extension InstancesViewController {
    
    private func makeShimmerRegistration() -> UICollectionView.CellRegistration<InstanceCollectionViewCell<ItemIdentifier>, ItemIdentifier> {
        .init { cell, indexPath, itemIdentifier in
            cell.isShimmering = true
            cell.contentConfiguration = cell.shimmerContentConfiguration()
        }
    }
    
    private func makeCellRegistration() -> UICollectionView.CellRegistration<InstanceCollectionViewCell<ItemIdentifier>, ItemIdentifier> {
        .init { [unowned self] cell, indexPath, itemIdentifier in
            cell.itemIdentifier = itemIdentifier
            cell.isShimmering = false
            let item = instancesStore.instances[indexPath.item]
            var configuration = cell.defaultContentConfiguration()
            configuration.name = item.name
            configuration.description = item.description
            configuration.usersCount = item.usersCount
            configuration.statusesCount = item.statusesCount
            cell.contentConfiguration = configuration
            guard let url = item.thumbnailURL else { return }
            Task {
                let image = try? await ImageDownloader.shared.loadImage(from: url)
                guard cell.itemIdentifier == itemIdentifier else { return }
                configuration.image = image
                cell.contentConfiguration = configuration
            }
        }
    }
    
    private func makeDataSource() -> UICollectionViewDiffableDataSource<Section, ItemIdentifier> {
        let shimmerRegistration = makeShimmerRegistration()
        let cellRegistration = makeCellRegistration()
        return .init(collectionView: instancesView.collectionView) { [unowned self] collectionView, indexPath, itemIdentifier in
            collectionView.dequeueConfiguredReusableCell(
                using: isShimmering ? shimmerRegistration : cellRegistration,
                for: indexPath,
                item: itemIdentifier
            )
        }
    }
}

extension InstancesViewController {
    
    private func setupShimmerSnapshot() async {
        isShimmering = true; defer { isShimmering = false }
        var snapshot = NSDiffableDataSourceSnapshot<Section, ItemIdentifier>()
        snapshot.appendSections([.main])
        snapshot.appendItems((0..<3).map { _ in UUID().uuidString })
        await dataSource.applySnapshotUsingReloadData(snapshot)
        scrollToTop()
    }
    
    private func updateSnapshot(with items: [String]) async {
        var snapshot = NSDiffableDataSourceSnapshot<Section, ItemIdentifier>()
        snapshot.appendSections([.main])
        snapshot.appendItems(items, toSection: .main)
        await dataSource.applySnapshotUsingReloadData(snapshot)
        scrollToTop()
    }
    
    private func scrollToTop() {
        guard instancesView.collectionView.numberOfItems(inSection: Section.main.rawValue) > 0 else { return }
        instancesView.collectionView.scrollToItem(at: [0, Section.main.rawValue], at: .top, animated: false)
    }
}

extension InstancesViewController {
    
    private enum Section: Int, CaseIterable {
        case main
    }
    
    private typealias ItemIdentifier = Instance.ID
}

extension InstancesViewController {
    
    private func setupSearchBar() {
        searchController.showsSearchResultsController = false
        searchController.searchBar.delegate = self
        searchController.searchBar.placeholder = "Instance URL"
        searchController.searchBar.textContentType = .URL
        searchController.searchBar.keyboardType = .URL
        searchController.searchBar.autocorrectionType = .no
        searchController.searchBar.autocapitalizationType = .none
        navigationItem.searchController = searchController
        navigationItem.hidesSearchBarWhenScrolling = false
    }
}

extension InstancesViewController {
    
    private func runTask(with action: @escaping () async throws -> Void) {
        runningTask?.cancel()
        instancesView.nothingFoundLabel.isHidden = true
        instancesView.collectionView.isUserInteractionEnabled = false
        runningTask = Task {
            await setupShimmerSnapshot()
            try await action()
            await updateSnapshot(with: instancesStore.instances.map(\.id))
            instancesView.nothingFoundLabel.isHidden = !instancesStore.instances.isEmpty
            instancesView.collectionView.isUserInteractionEnabled = true
        }
    }

    private func runListTask() {
        runTask { [weak self] in
            try await self?.instancesStore.listInstances()
        }
    }

    private func runSearchTask() {
        guard let query = searchController.searchBar.text, !query.isEmpty else {
            runListTask()
            return
        }
        runTask { [weak self] in
            try await self?.instancesStore.searchInstances(query: query)
        }
    }
}

extension InstancesViewController: UICollectionViewDelegate {
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        collectionView.deselectItem(at: indexPath, animated: false)
        delegate?.instancesViewController(self, didSelectInstance: instancesStore.instances[indexPath.item])
    }
    
    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        searchController.searchBar.endEditing(true)
    }
}

extension InstancesViewController: UICollectionViewDataSourcePrefetching {
    
    func collectionView(_ collectionView: UICollectionView, prefetchItemsAt indexPaths: [IndexPath]) {
        for indexPath in indexPaths {
            guard let url = instancesStore.instances[indexPath.item].thumbnailURL else { continue }
            Task {
                try await ImageDownloader.shared.loadImage(from: url)
            }
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, cancelPrefetchingForItemsAt indexPaths: [IndexPath]) {
        for indexPath in indexPaths {
            guard let url = instancesStore.instances[indexPath.item].thumbnailURL else { continue }
            ImageDownloader.shared.cancelDownloadingIfNeeded(for: url)
        }
    }
}

extension InstancesViewController: UISearchBarDelegate {
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        runSearchTask()
    }
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        runSearchTask()
    }
    
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        runListTask()
    }
}
