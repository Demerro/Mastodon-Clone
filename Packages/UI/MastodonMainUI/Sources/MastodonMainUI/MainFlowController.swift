//
//  MainFlowController.swift
//  MastodonMainUI
//
//  Created by Nikita Prokhorchuk on 29.12.24.
//

import UIKit
import UIKitFoundation
import MastodonKit
import MastodonFeedUI
import MastodonProfileUI
import MastodonComposeUI
import FoundationUtilities

public final class MainFlowController: TabBarController {
    
    private let feedFlowController = FeedFlowController()
    
    private let profileFlowController = ProfileFlowController()
    
    private let floatingActionView: FloatingActionView = {
        $0.translatesAutoresizingMaskIntoConstraints = false
        if $0.visualEffectView.responds(to: setAllowsGroupFilteringSelector), $0.visualEffectView.responds(to: setGroupNameSelector) {
            $0.visualEffectView.perform(setAllowsGroupFilteringSelector, with: true)
            $0.visualEffectView.perform(setGroupNameSelector, with: visualEffectGroupName)
        }
        return $0
    }(FloatingActionView(frame: .zero))
    
    private var viewDidAppearVisitedOnce = false
    
    public init() {
        super.init(viewControllers: [feedFlowController, profileFlowController])
        
        let appearance = UITabBarAppearance()
        appearance.configureWithDefaultBackground()
        tabBar.standardAppearance = appearance
        tabBar.scrollEdgeAppearance = appearance
        
        view.addSubview(floatingActionView)
        NSLayoutConstraint.activate([
            view.trailingAnchor.constraint(equalTo: floatingActionView.trailingAnchor),
            tabBar.topAnchor.constraint(equalTo: floatingActionView.bottomAnchor),
        ])
        
        floatingActionView.button.addAction(UIAction { [unowned self] _ in
            let composeFlowController = ComposeFlowController()
            composeFlowController.modalPresentationStyle = .fullScreen
            composeFlowController.flowDelegate = self
            present(composeFlowController, animated: true)
        }, for: .touchUpInside)
    }
    
    public override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        guard !viewDidAppearVisitedOnce else { return }
        viewDidAppearVisitedOnce = true
        if let visualEffectView = tabBar.visualEffectView,
            visualEffectView.responds(to: setAllowsGroupFilteringSelector),
            visualEffectView.responds(to: setGroupNameSelector) {
            visualEffectView.perform(setAllowsGroupFilteringSelector, with: true)
            visualEffectView.perform(setGroupNameSelector, with: visualEffectGroupName)
        }
    }
}

extension MainFlowController: ComposeFlowController.Delegate {
    
    public func composeFlowController(_ composeFlowController: ComposeFlowController, didFinishWithUploadedStatus status: Status) {
        
    }
}

fileprivate let setAllowsGroupFilteringSelector = NSSelectorFromEncodedString("X3NldEFsbG93c0dyb3VwRmlsdGVyaW5nOg==") // _setAllowsGroupFiltering:

fileprivate let setGroupNameSelector = NSSelectorFromEncodedString("X3NldEdyb3VwTmFtZTo=") // _setGroupName:

fileprivate let visualEffectGroupName = NSStringFromClass(UITabBar.self)
