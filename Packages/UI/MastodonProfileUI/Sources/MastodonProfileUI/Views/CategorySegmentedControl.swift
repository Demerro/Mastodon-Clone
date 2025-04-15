//
//  CategorySegmentedControl.swift
//  MastodonProfileUI
//
//  Created by Nikita Prokhorchuk on 14.01.25.
//

import UIKit
import UIKitFoundation

protocol CategorySegmentedControlDelegate: AnyObject {
    func categorySegmentedControl(_ segmentedControl: CategorySegmentedControl, didSelectItemAt index: Int)
}

final class CategorySegmentedControl: View {
    
    private(set) public var hasActiveInteractiveAnimation = false
    
    private var currentAnimator: UIViewPropertyAnimator?
    
    weak var delegate: (any CategorySegmentedControlDelegate)?
    
    var state = State()
    
    var categoryTitles: [String] = [] {
        didSet { updateViews() }
    }
    
    private let stackView: UIStackView = {
        $0.translatesAutoresizingMaskIntoConstraints = false
        $0.distribution = .equalSpacing
        $0.axis = .horizontal
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
        addSubview(stackView)
        addSubview(lineView)
    }
    
    override func setupConstraints() {
        super.setupConstraints()
        NSLayoutConstraint.activate([
            stackView.topAnchor.constraint(equalTo: topAnchor),
            stackView.leadingAnchor.constraint(equalTo: leadingAnchor),
            trailingAnchor.constraint(equalTo: stackView.trailingAnchor),
            bottomAnchor.constraint(equalTo: stackView.bottomAnchor),
        ])
    }
    
    public override func setupAfterLayoutSubviews() {
        super.setupAfterLayoutSubviews()
        RunLoop.current.add(Timer(timeInterval: 0.0, repeats: false, block: { [self] _ in
            MainActor.assumeIsolated {
                guard let firstSubview = stackView.subviews.first else { return }
                lineView.frame = CGRect(x: firstSubview.frame.minX, y: firstSubview.frame.maxY + lineViewHeight, width: firstSubview.frame.width, height: lineViewHeight)
            }
        }), forMode: .common)
    }
}

extension CategorySegmentedControl {
    
    public func startInteractiveAnimation(toSelectedIndex index: Int) {
        guard !hasActiveInteractiveAnimation, state.selectedIndex != index else { return }
        hasActiveInteractiveAnimation = true
        
        let previousSelectedIndex = state.selectedIndex
        state.selectedIndex = index
        
        let targetLabel = stackView.subviews[state.selectedIndex] as! UILabel
        currentAnimator = UIViewPropertyAnimator(duration: CATransaction.animationDuration(), curve: .easeInOut) { [self] in
            lineView.frame = CGRect(x: targetLabel.frame.minX, y: lineView.frame.minY, width: targetLabel.frame.width, height: lineViewHeight)
        }
        currentAnimator!.pauseAnimation()
        currentAnimator!.addCompletion { [unowned self] in
            hasActiveInteractiveAnimation = false
            guard $0 == .start else { return }
            state.selectedIndex = previousSelectedIndex
        }
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
            let gestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(didTapOnTitle))
            label.addGestureRecognizer(gestureRecognizer)
            stackView.addArrangedSubview(label)
            if index == 0 {
                state.lastSelectedLabel = label
                label.textColor = .label
            }
        }
        
        func createLabel(with title: String) -> UILabel {
            let label = UILabel()
            label.text = title
            label.textColor = .secondaryLabel
            label.isUserInteractionEnabled = true
            label.font = .preferredFont(forTextStyle: .body, compatibleWith: UITraitCollection(legibilityWeight: .bold))
            return label
        }
    }
    
    @objc private func didTapOnTitle(_ sender: UITapGestureRecognizer) {
        guard let label = sender.view as? UILabel else { return }
        state.selectedIndex = stackView.subviews.firstIndex(of: label)!
        delegate?.categorySegmentedControl(self, didSelectItemAt: state.selectedIndex)
        animateLabelColorChange(selectedLabel: label, deselectedLabel: state.lastSelectedLabel)
        UIViewPropertyAnimator.runningPropertyAnimator(withDuration: CATransaction.animationDuration(), delay: 0.0) { [self] in
            lineView.frame = CGRect(x: label.frame.minX, y: lineView.frame.minY, width: label.frame.width, height: lineViewHeight)
        } completion: { [unowned self] _ in
            state.lastSelectedLabel = label
        }
        
        func animateLabelColorChange(selectedLabel: UILabel, deselectedLabel: UILabel) {
            UIView.transition(with: selectedLabel, duration: CATransaction.animationDuration(), options: [.transitionCrossDissolve]) {
                selectedLabel.textColor = .label
            }
            
            UIView.transition(with: deselectedLabel, duration: CATransaction.animationDuration(), options: [.transitionCrossDissolve]) {
                deselectedLabel.textColor = .secondaryLabel
            }
        }
    }
}

extension CategorySegmentedControl {
    
    struct State {
        
        var selectedIndex = 0
        
        var lastSelectedLabel: UILabel!
    }
}
