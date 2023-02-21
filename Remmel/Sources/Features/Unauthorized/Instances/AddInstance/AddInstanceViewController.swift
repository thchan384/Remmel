//
//  AddInstanceViewController.swift
//  Lemmy-iOS
//
//  Created by uuttff8 on 21.12.2020.
//  Copyright © 2020 Anton Kuzmin. All rights reserved.
//

import UIKit
import RMFoundation
import RMServices

protocol AddInstanceViewControllerProtocol: AnyObject {
    func displayAddInstancePresentation(viewModel: AddInstanceDataFlow.InstancePresentation.ViewModel)
    func displayAddInstanceCheck(viewModel: AddInstanceDataFlow.InstanceCheck.ViewModel)
}

final class AddInstanceViewController: UIViewController {
    
    weak var coordinator: InstancesCoordinator?
    private let viewModel: AddInstanceViewModelProtocol
    
    var completionHandler: (() -> Void)?
    
    private lazy var addView = self.view as? AddInstanceView
    
    private var validUrl: String?
    
    private lazy var addBarButton = UIBarButtonItem(
        title: "instances-add".localized,
        style: .done,
        target: self,
        action: #selector(addBarButtonTapped(_:))
    )
    
    private lazy var _activityIndicator = UIActivityIndicatorView(style: .medium).then {
        $0.startAnimating()
    }
    private lazy var loadingBarButton = UIBarButtonItem(customView: _activityIndicator)
    
    private var enteredInstanceUrl: String?
    
    init(viewModel: AddInstanceViewModelProtocol) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }
    
    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func loadView() {
        let view = AddInstanceView()
        self.view = view
        view.delegate = self
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupNavigationItem()
    }
    
    @objc
    func addBarButtonTapped(_ sender: UIBarButtonItem) {
        guard let instanceUrl = enteredInstanceUrl else {
            debugPrint("Entered instance url is nil, cannot save to CoreData")
            return
        }
        
        let instance = Instance(entity: Instance.entity(), insertInto: CoreDataHelper.shared.context)
        instance.label = instanceUrl
        CoreDataHelper.shared.save()
        
        completionHandler?()
        dismiss(animated: true)
    }
    
    private func setNewBarButton(loading: Bool, isEnabled: Bool) {
        let button: UIBarButtonItem = loading ? loadingBarButton : addBarButton
        button.isEnabled = isEnabled
        navigationItem.rightBarButtonItem = button
    }
    
    private func setupNavigationItem() {
        title = "Add Instance"
        navigationItem.rightBarButtonItem = addBarButton
        addBarButton.isEnabled = false
    }
}

extension AddInstanceViewController: AddInstanceViewControllerProtocol {
    func displayAddInstancePresentation(viewModel: AddInstanceDataFlow.InstancePresentation.ViewModel) {
        // nothing
    }
    
    func displayAddInstanceCheck(viewModel: AddInstanceDataFlow.InstanceCheck.ViewModel) {
        switch viewModel.state {
        case let .result(iconUrl, instanceUrl):
            enteredInstanceUrl = instanceUrl
            setNewBarButton(loading: false, isEnabled: true)
            addView?.bindImage(with: iconUrl)
        case .noResult:
            setNewBarButton(loading: false, isEnabled: false)
            addView?.unbindImage()
        }
    }
}
extension AddInstanceViewController: AddInstanceViewDelegate {
    func addInstanceView(_ view: AddInstanceView, didTyped text: String?) {
        
        if let text = text {
            setNewBarButton(loading: true, isEnabled: false)
            viewModel.doAddInstanceCheck(request: .init(query: text))
        }
    }
}

extension AddInstanceViewController: StyledNavigationControllerPresentable {
    var navigationBarAppearanceOnFirstPresentation: StyledNavigationController.NavigationBarAppearanceState {
        .pageSheetAppearance()
    }
}
