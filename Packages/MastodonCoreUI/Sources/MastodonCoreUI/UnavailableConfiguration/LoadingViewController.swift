//
//  LoadingViewController.swift
//  MastodonCoreUI
//
//  Created by Nikita Prokhorchuk on 12.01.25.
//

import UIKit
import UIKitFoundation

public final class LoadingViewController: ViewController {
    
    private let loadingView = _LoadingView(frame: .zero)
    
    public var contentConfiguration: UnavailableConfiguration {
        didSet {
            guard contentConfiguration != oldValue else { return }
            loadingView.textLabel.text = contentConfiguration.text
        }
    }
    
    public init(contentConfiguration: UnavailableConfiguration) {
        self.contentConfiguration = contentConfiguration
        super.init()
        loadingView.textLabel.text = contentConfiguration.text
    }
    
    public override func loadView() {
        view = loadingView
    }
    
    public override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        loadingView.activityIndicatorView.startAnimating()
    }
    
    public override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        loadingView.activityIndicatorView.stopAnimating()
    }
}

fileprivate final class _LoadingView: View {
    
    private let stackView: UIStackView = {
        $0.translatesAutoresizingMaskIntoConstraints = false
        $0.axis = .vertical
        $0.alignment = .center
        $0.spacing = 8.0
        return $0
    }(UIStackView(frame: .zero))
    
    let activityIndicatorView = UIActivityIndicatorView(style: .large)
    
    let textLabel: UILabel = {
        $0.font = .preferredFont(forTextStyle: .subheadline)
        $0.textColor = .secondaryLabel
        $0.numberOfLines = 0
        $0.textAlignment = .center
        return $0
    }(UILabel(frame: .zero))
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupCommon()
        setupConstraints()
    }
    
    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError()
    }
    
    override func setupCommon() {
        super.setupCommon()
        addSubview(stackView)
        stackView.addArrangedSubview(activityIndicatorView)
        stackView.addArrangedSubview(textLabel)
    }
    
    override func setupConstraints() {
        super.setupConstraints()
        NSLayoutConstraint.activate([
            stackView.leadingAnchor.constraint(greaterThanOrEqualTo: leadingAnchor),
            trailingAnchor.constraint(greaterThanOrEqualTo: stackView.trailingAnchor),
            stackView.centerYAnchor.constraint(equalTo: centerYAnchor),
            stackView.centerXAnchor.constraint(equalTo: centerXAnchor),
        ])
    }
}
