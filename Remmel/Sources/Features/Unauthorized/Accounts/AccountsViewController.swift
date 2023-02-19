//
//  AccountsViewController.swift
//  Lemmy-iOS
//
//  Created by Komolbek Ibragimov on 24/12/2020.
//  Copyright © 2020 Anton Kuzmin. All rights reserved.
//

import UIKit
import RMFoundation

protocol AccountsViewControllerProtocol: AnyObject {
    func displayAccounts(viewModel: AccountsDataFlow.AccountsRefresh.ViewModel)
    func displayAccountSelected(viewModel: AccountsDataFlow.AccountSelected.ViewModel)
    func displayGuestSelected(viewModel: AccountsDataFlow.GuestSelected.ViewModel)
    func displayUnexpectedError(viewModel: AccountsDataFlow.UnexpectedError.ViewModel)
}

final class AccountsViewController: UIViewController {
    
    weak var coordinator: AccountsCoordinator?
    let viewModel: AccountsViewModel
    
    private lazy var accountsView = self.view as? AccountsView

    private lazy var tableManager = AccountsTableDataSource().then {
        $0.delegate = self
    }
    
    private lazy var addAccountBarButton = UIBarButtonItem(
        image: UIImage(systemName: "plus.circle"),
        style: .done,
        target: self,
        action: #selector(addAccountButtonTapped(_:))
    )
    
    private lazy var createAccountBarButton = UIBarButtonItem(
        title: "Register",
        style: .done,
        target: self,
        action: #selector(createAccountBarButtonTapped(_:))
    )
    
    private var state: AccountsDataFlow.ViewControllerState
    
    init(
        viewModel: AccountsViewModel,
        state: AccountsDataFlow.ViewControllerState = .loading
    ) {
        self.viewModel = viewModel
        self.state = state
        super.init(nibName: nil, bundle: nil)
    }
    
    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func loadView() {
        let view = AccountsView()
        self.view = view
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        self.viewModel.doAccountsRefresh(request: .init())
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "accounts".localized
        view.backgroundColor = .white
        
        setupNavigationItem()
    }
    
    private func setupNavigationItem() {
        navigationItem.rightBarButtonItem = addAccountBarButton
    }
    
    private func updateState(newState: AccountsDataFlow.ViewControllerState) {
        defer {
            self.state = newState
        }

        if case .loading = newState {
            return
        }

        if case .loading = self.state {
        }

        if case .result = newState {
            accountsView?.updateTableViewData(dataSource: self.tableManager)
        }
    }
    
    // MARK: - Actions
    
    @objc private func addAccountButtonTapped(_ sender: UIBarButtonItem) {
        coordinator?.goToAddAccountModule(authMethod: .auth, with: viewModel.currentInstance) {
            self.viewModel.doAccountsRefresh(request: .init())
        }
    }
    
    @objc private func createAccountBarButtonTapped(_ sender: UIBarButtonItem) {
        coordinator?.goToAddAccountModule(authMethod: .register, with: viewModel.currentInstance) {
            self.viewModel.doAccountsRefresh(request: .init())
        }
    }
}

extension AccountsViewController: AccountsViewControllerProtocol {
    func displayAccounts(viewModel: AccountsDataFlow.AccountsRefresh.ViewModel) {
        guard case .result(let instances) = viewModel.state else {
            return
        }
        
        tableManager.viewModels = instances
        updateState(newState: viewModel.state)
    }
    
    func displayAccountSelected(viewModel: AccountsDataFlow.AccountSelected.ViewModel) {
        coordinator?.goToFrontPage()
    }
    
    func displayUnexpectedError(viewModel: AccountsDataFlow.UnexpectedError.ViewModel) {
        UIAlertController.createOkAlert(message: viewModel.error)
    }
    
    func displayGuestSelected(viewModel: AccountsDataFlow.GuestSelected.ViewModel) {
        self.coordinator?.goToFrontPage()
    }
}

extension AccountsViewController: AccountsTableDataSourceDelegate {
    func tableDidRequestDelete(_ account: Account) {
        viewModel.doAccountDelete(request: .init(account: account))
    }
    
    func tableDidSelect(_ account: Account) {
        viewModel.doAccountUserSelect(request: .init(account: account))
    }
    
    func tableDidSelectGuestPreview() {
        viewModel.doAccountGuestSelect(request: .init())
    }
}
