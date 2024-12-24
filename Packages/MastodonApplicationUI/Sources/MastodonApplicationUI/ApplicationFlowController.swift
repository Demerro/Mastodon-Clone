//
//  ApplicationFlowController.swift
//  MastodonApplicationUI
//
//  Created by Nikita Prokhorchuk on 23.11.24.
//

import UIKit

import AuthorizationUI
import UIKitFoundation

public final class ApplicationFlowController: ViewController {
    
    private lazy var authorizationFlowController = AuthorizationFlowController()
    
    private lazy var applicationFlowView = _ApplicationFlowView(frame: .zero, flowView: { authorizationFlowController.view })
    
    public override func loadView() {
        view = applicationFlowView
    }
    
    public override func setupCommon() {
        super.setupCommon()
        addChild(authorizationFlowController)
    }
    
    public override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        authorizationFlowController.didMove(toParent: self)
    }
}

fileprivate final class _ApplicationFlowView: View {
    
    private let flowViewProvider: () -> UIView
    
    var flowView: UIView { flowViewProvider() }
    
    override func setupCommon() {
        super.setupCommon()
        flowView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(flowView)
    }
    
    override func setupConstraints() {
        super.setupConstraints()
        NSLayoutConstraint.activate([
            flowView.topAnchor.constraint(equalTo: topAnchor),
            flowView.leadingAnchor.constraint(equalTo: leadingAnchor),
            trailingAnchor.constraint(equalTo: flowView.trailingAnchor),
            bottomAnchor.constraint(equalTo: flowView.bottomAnchor),
        ])
    }
    
    init(frame: CGRect, @_implicitSelfCapture flowView flowViewProvider: @escaping () -> UIView) {
        self.flowViewProvider = flowViewProvider
        super.init(frame: frame)
    }
}
