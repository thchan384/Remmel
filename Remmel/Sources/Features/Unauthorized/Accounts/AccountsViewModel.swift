//
//  AccountsViewModel.swift
//  Lemmy-iOS
//
//  Created by Komolbek Ibragimov on 24/12/2020.
//  Copyright © 2020 Anton Kuzmin. All rights reserved.
//

import Combine
import Foundation
import RMModels
import RMFoundation
import RMServices
import RMNetworking

protocol AccountsViewModelProtocol: AnyObject {
    func doAccountsRefresh(request: AccountsDataFlow.AccountsRefresh.Request)
    func doAccountDelete(request: AccountsDataFlow.AccountDelete.Request)
    func doAccountUserSelect(request: AccountsDataFlow.AccountSelected.Request)
    func doAccountGuestSelect(request: AccountsDataFlow.GuestSelected.Request)
}

final class AccountsViewModel: AccountsViewModelProtocol {
    weak var viewController: AccountsViewControllerProtocol?
    
    let currentInstance: Instance
    
    private let accountsPersistenceService: AccountsPersistenceServiceProtocol
    private let shareData: LemmyShareData
    
    private var cancellables = Set<AnyCancellable>()
    
    init(
        instance: Instance,
        shareData: LemmyShareData,
        accountsPersistenceService: AccountsPersistenceServiceProtocol
    ) {
        self.currentInstance = instance
        self.shareData = shareData
        self.accountsPersistenceService = accountsPersistenceService
    }
    
    func doAccountsRefresh(request: AccountsDataFlow.AccountsRefresh.Request) {
        self.viewController?.displayAccounts(
            viewModel: .init(state: .result(data: self.currentInstance.accounts))
        )
    }
    
    func doAccountDelete(request: AccountsDataFlow.AccountDelete.Request) {
        self.accountsPersistenceService.delete(request.account)
            .receive(on: DispatchQueue.main)
            .sink(receiveValue: {})
            .store(in: &cancellables)
    }
    
    func doAccountUserSelect(request: AccountsDataFlow.AccountSelected.Request) {
        let parameters = RMModels.Api.Person.Login(
            usernameOrEmail: request.account.login,
            password: request.account.password
        )
        
        ApiManager.requests.asyncLogin(parameters: parameters)
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: { completion in
                Logger.logCombineCompletion(completion)
                
                if case let .failure(why) = completion {
                    self.viewController?.displayUnexpectedError(viewModel: .init(error: why.description))
                }
            }, receiveValue: { response in
                
                guard let jwt = response.jwt else {
                    return
                }
                
                self.fetchUser(with: jwt)
            }).store(in: &cancellables)
    }
    
    func doAccountGuestSelect(request: AccountsDataFlow.GuestSelected.Request) {
        self.shareData.loginData.userLogout()
        self.viewController?.displayGuestSelected(viewModel: .init())
    }
        
    private func fetchUser(with jwtToken: String) {
        self.loadUserOnSuccessResponse(jwt: jwtToken) { (currentUser: RMModels.Api.Site.MyUserInfo) in
            self.shareData.userdata = currentUser
            self.viewController?.displayAccountSelected(viewModel: .init(myUser: currentUser))
        }
    }
        
    private func loadUserOnSuccessResponse(
        jwt: String,
        completion: @escaping ((RMModels.Api.Site.MyUserInfo) -> Void)
    ) {
        self.shareData.loginData.login(jwt: jwt)
        
        let params = RMModels.Api.Site.GetSite(auth: jwt)
        
        ApiManager.requests.asyncGetSite(parameters: params)
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: { completion in
                Logger.logCombineCompletion(completion)
            }, receiveValue: { response in
                guard let myUser = response.myUser
                else {
                    debugPrint("There is no current user in response")
                    return
                }
                
                completion(myUser)
            }).store(in: &cancellables)
    }
}

enum AccountsDataFlow {
    
    enum AccountsRefresh {
        struct Request { }
        struct ViewModel {
            let state: ViewControllerState
        }
    }
    
    enum AccountDelete {
        struct Request {
            let account: Account
        }
        
        struct ViewModel { }
    }
    
    enum AccountSelected {
        struct Request {
            let account: Account
        }
        
        struct ViewModel {
            let myUser: RMModels.Api.Site.MyUserInfo
        }
    }
    
    enum GuestSelected {
        struct Request { }
        struct ViewModel { }
    }
    
    enum UnexpectedError {
        struct Request { }
        
        struct ViewModel {
            let error: String
        }
    }
    
    enum ViewControllerState {
        case loading
        case result(data: [Account])
    }
}
