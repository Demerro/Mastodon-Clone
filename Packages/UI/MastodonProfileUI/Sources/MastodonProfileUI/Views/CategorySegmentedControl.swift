//
//  CategorySegmentedControl.swift
//  MastodonProfileUI
//
//  Created by Nikita Prokhorchuk on 14.01.25.
//

import UIKit
import UIKitFoundation
import FoundationUtilities

@MainActor
protocol CategorySegmentedControlDelegate: AnyObject {
    func categorySegmentedControl(_ segmentedControl: CategorySegmentedControl, didSelectItemAt index: Int)
}

final class CategorySegmentedControl: View {
    
    static let visualEffectGroupName = NSStringFromClass(CategorySegmentedControl.self)
    
    private(set) public var hasActiveInteractiveAnimation = false
    
    private var currentAnimator: UIViewPropertyAnimator?
    
    weak var delegate: (any CategorySegmentedControlDelegate)?
    
    private(set) var state = State()
    
    var categoryTitles: [String] = [] {
        didSet { updateViews() }
    }
    
    let visualEffectView: UIVisualEffectView = {
        $0.translatesAutoresizingMaskIntoConstraints = false
        $0.isHidden = true
        let setAllowsGroupFilteringSelector = NSSelectorFromEncodedString("X3NldEFsbG93c0dyb3VwRmlsdGVyaW5nOg==") // _setAllowsGroupFiltering:
        let setGroupNameSelector = NSSelectorFromEncodedString("X3NldEdyb3VwTmFtZTo=") // _setGroupName:
        if $0.responds(to: setAllowsGroupFilteringSelector), $0.responds(to: setGroupNameSelector) {
            $0.perform(setAllowsGroupFilteringSelector, with: true)
            $0.perform(setGroupNameSelector, with: CategorySegmentedControl.visualEffectGroupName)
        }
        return $0
    }(UIVisualEffectView(effect: UIBlurEffect(style: .systemChromeMaterial)))
    
    private let stackView: UIStackView = {
        $0.translatesAutoresizingMaskIntoConstraints = false
        $0.distribution = .equalSpacing
        $0.axis = .horizontal
        $0.isLayoutMarginsRelativeArrangement = true
        return $0
    }(UIStackView(frame: .zero))
    
    private let lineViewHeight = 2.0
    private let lineView: UIView = {
        $0.backgroundColor = .tintColor
        $0.layer.cornerRadius = 1.0
        $0.layer.cornerCurve = .continuous
        return $0
    }(UIView(frame: .zero))
    
    override func setupCommon() {
        super.setupCommon()
        preservesSuperviewLayoutMargins = true
        addSubview(visualEffectView)
        addSubview(stackView)
        addSubview(lineView)
        addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(handleTapGestureRecognizer)))
    }
    
    override func setupConstraints() {
        super.setupConstraints()
        NSLayoutConstraint.activate([
            visualEffectView.topAnchor.constraint(equalTo: topAnchor),
            visualEffectView.leadingAnchor.constraint(equalTo: leadingAnchor),
            trailingAnchor.constraint(equalTo: visualEffectView.trailingAnchor),
            bottomAnchor.constraint(equalTo: visualEffectView.bottomAnchor),
            
            stackView.topAnchor.constraint(equalTo: topAnchor, constant: lineViewHeight * 2.0),
            stackView.leadingAnchor.constraint(equalTo: leadingAnchor),
            trailingAnchor.constraint(equalTo: stackView.trailingAnchor),
            bottomAnchor.constraint(equalTo: stackView.bottomAnchor, constant: lineViewHeight * 3.0),
        ])
    }
    
    public override func setupAfterLayoutSubviews() {
        super.setupAfterLayoutSubviews()
        RunLoop.current.perform { [self] in
            MainActor.assumeIsolated {
                guard let firstSubview = stackView.subviews.first else { return }
                lineView.frame = CGRect(x: firstSubview.frame.minX, y: firstSubview.frame.maxY + lineViewHeight * 2.0, width: firstSubview.frame.width, height: lineViewHeight)
            }
        }
    }
    
    override func layoutMarginsDidChange() {
        super.layoutMarginsDidChange()
        stackView.layoutMargins = UIEdgeInsets(top: 0.0, left: directionalLayoutMargins.leading, bottom: 0.0, right: directionalLayoutMargins.trailing)
    }
}

extension CategorySegmentedControl {
    
    public func startInteractiveAnimation(toSelectedIndex index: Int) {
        guard 0..<stackView.subviews.count ~= index,!hasActiveInteractiveAnimation, state.selectedIndex != index else { return }
        hasActiveInteractiveAnimation = true

        let targetLabel = stackView.subviews[index] as! UILabel        
        let previousSelectedIndex = state.selectedIndex
        let previousSelectedLabel = state.selectedLabel!
        state.selectedIndex = index
        state.selectedLabel = targetLabel
        
        let currentAnimator = UIViewPropertyAnimator(duration: CATransaction.animationDuration(), curve: .easeInOut) { [self] in
            lineView.frame = CGRect(x: targetLabel.frame.minX, y: lineView.frame.minY, width: targetLabel.frame.width, height: lineViewHeight)
            targetLabel.alpha = 1.0
            previousSelectedLabel.alpha = 0.5
        }
        currentAnimator.pauseAnimation()
        currentAnimator.addCompletion { [weak self] in
            guard let self else { return }
            hasActiveInteractiveAnimation = false
            if $0 == .start {
                state.selectedIndex = previousSelectedIndex
                state.selectedLabel = previousSelectedLabel
            }
        }
        self.currentAnimator = currentAnimator
    }
    
    public func updateInteractiveAnimation(_ percentComplete: CGFloat) {
        guard hasActiveInteractiveAnimation else { return }
        assert(currentAnimator != nil)
        currentAnimator!.fractionComplete = percentComplete
    }
    
    public func pauseInteractiveAnimation() {
        guard hasActiveInteractiveAnimation else { return }
        assert(currentAnimator != nil)
        currentAnimator!.pauseAnimation()
    }
    
    public func finishInteractiveAnimation() {
        guard hasActiveInteractiveAnimation else { return }
        assert(currentAnimator != nil)
        currentAnimator!.fractionComplete = 1.0
        currentAnimator!.stopAnimation(false)
        currentAnimator!.finishAnimation(at: .end)
    }
    
    public func cancelInteractiveAnimation() {
        guard hasActiveInteractiveAnimation else { return }
        assert(currentAnimator != nil)
        currentAnimator!.fractionComplete = 0.0
        currentAnimator!.stopAnimation(false)
        currentAnimator!.finishAnimation(at: .start)
    }
}

extension CategorySegmentedControl {
    
    private func updateViews() {
        for (index, categoryTitle) in categoryTitles.enumerated() {
            let label = createLabel(with: categoryTitle)
            stackView.addArrangedSubview(label)
            if index == 0 {
                state.selectedLabel = label
                label.alpha = 1.0
            }
        }
        
        func createLabel(with title: String) -> UILabel {
            let label = UILabel()
            label.text = title
            label.isUserInteractionEnabled = true
            label.font = .preferredFont(forTextStyle: .body, compatibleWith: UITraitCollection(legibilityWeight: .bold))
            label.alpha = 0.5
            return label
        }
    }
    
    @objc
    private func handleTapGestureRecognizer(_ gestureRecognizer: UITapGestureRecognizer) {
        let location = gestureRecognizer.location(in: self)
        for label in stackView.subviews {
            if CGRect(x: label.frame.minX, y: bounds.minY, width: label.frame.width, height: bounds.height).contains(location) {
                delegate?.categorySegmentedControl(self, didSelectItemAt: stackView.subviews.firstIndex(of: label)!)
                break
            }
        }
    }
}

extension CategorySegmentedControl {
    
    struct State {
        
        var selectedIndex = 0
        
        var selectedLabel: UILabel!
    }
}
