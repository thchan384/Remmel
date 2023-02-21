//
//  InstancesViewController.swift
//  Lemmy-iOS
//
//  Created by uuttff8 on 19.12.2020.
//  Copyright © 2020 Anton Kuzmin. All rights reserved.
//

import UIKit
import RMFoundation
import RMServices

protocol InstancesViewControllerProtocol: AnyObject {
    func displayInstances(viewModel: InstancesDataFlow.InstancesLoad.ViewModel)
}

extension InstancesViewController {
    struct Appearance {
        // swiftlint:disable:next force_unwrapping
        let mainLemmyInstance = InstanceUrl(string: "https://lemmy.ml/")!
    }
}

class InstancesViewController: UIViewController {
    
    private let appearance: Appearance
    
    weak var coordinator: InstancesCoordinator?
    private let viewModel: InstancesViewModelProtocol
    
    private lazy var tableManager = InstancesTableDataSource().then {
        $0.delegate = self
    }
    private lazy var instancesView = self.view as? InstancesView
    
    private lazy var createInstanceBarButton = UIBarButtonItem(
        image: UIImage(systemName: "plus.circle"),
        style: .done,
        target: self,
        action: #selector(createInstanceButtonTapped(_:))
    )
    
    private var state: InstancesDataFlow.ViewControllerState
    
    init(
        viewModel: InstancesViewModelProtocol,
        state: InstancesDataFlow.ViewControllerState = .loading,
        appearance: Appearance = Appearance()
    ) {
        self.viewModel = viewModel
        self.state = state
        self.appearance = appearance
        super.init(nibName: nil, bundle: nil)
    }
    
    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func loadView() {
        let view = InstancesView()
        self.view = view
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        self.viewModel.doInstancesRefresh(request: .init())
        
        if LemmyShareData.shared.needsAppOnboarding {
            self.coordinator?.goToOnboarding(
                onUserOwnInstance: {
                    self._goToInstance()
                },
                onLemmyMlInstance: {
                    self.viewModel.doAddInstance(request: .init(link: self.appearance.mainLemmyInstance))
                }
            )
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = "instances".localized
        
        setupNavigationItem()
    }
    
    private func updateState(newState: InstancesDataFlow.ViewControllerState) {
        defer {
            self.state = newState
        }

        if case .loading = newState {
            instancesView?.showLoadingView()
            return
        }

        if case .loading = self.state {
            instancesView?.hideLoadingView()
        }

        if case .result = newState {
            instancesView?.updateTableViewData(dataSource: self.tableManager)
        }
    }
    
    @objc func createInstanceButtonTapped(_ action: UIBarButtonItem) {
        _goToInstance()
    }
    
    private func setupNavigationItem() {
        navigationItem.rightBarButtonItem = createInstanceBarButton
    }
    
    private func _goToInstance() {
        coordinator?.goToAddInstance { [self] in
            viewModel.doInstancesRefresh(request: .init())
        }
    }
}

extension InstancesViewController: InstancesViewControllerProtocol {
    func displayInstances(viewModel: InstancesDataFlow.InstancesLoad.ViewModel) {
        guard case .result(let instances) = viewModel.state else {
            return
        }
        
        tableManager.viewModels = instances
        updateState(newState: viewModel.state)
    }
}

extension InstancesViewController: InstancesTableDataSourceDelegate {
    func tableDidRequestDelete(_ instance: Instance) {
        viewModel.doInstanceDelete(request: .init(instance: instance))
    }
    
    func tableDidRequestAddAccountsModule(_ instance: Instance) {
        coordinator?.goToAccounts(from: instance)
        LemmyShareData.shared.currentInstanceUrl = InstanceUrl(string: instance.label)
    }
}
