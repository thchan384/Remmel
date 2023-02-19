//
//  ProfileScreenSubscribedViewModel.swift
//  Lemmy-iOS
//
//  Created by uuttff8 on 12.11.2020.
//  Copyright © 2020 Anton Kuzmin. All rights reserved.
//

import UIKit
import Combine
import RMModels

protocol ProfileScreenAboutViewModelProtocol {
    // TODO do pagination
    func doProfileAboutFetch()
}

class ProfileScreenSubscribedViewModel: ProfileScreenAboutViewModelProtocol {
    weak var viewController: ProfileScreenAboutViewControllerProtocol?
    
    private var loadedProfile: ProfileScreenViewModel.ProfileData?
    
    var cancellable = Set<AnyCancellable>()
    
    func doProfileAboutFetch() { }
}

extension ProfileScreenSubscribedViewModel: ProfileScreenSubscribedInputProtocol {
    func updateFollowersData(
        profile: ProfileScreenViewModel.ProfileData,
        subscribers: [RMModel.Views.CommunityFollowerView]
    ) {
        self.loadedProfile = profile
        self.viewController?.displayProfileSubscribers(
            viewModel: .init(state: .result(data: .init(subscribers: subscribers)))
        )
    }
    
    func registerSubmodule() { }
    
    func handleControllerAppearance() { }
}

enum ProfileScreenAbout {
    enum SubscribersLoad {
        struct Response {
            let subscribers: [RMModel.Views.CommunityFollowerView]
        }
        
        struct ViewModel {
            let state: ViewControllerState
        }
    }
    
    // MARK: States
    enum ViewControllerState {
        case loading
        case result(data: ProfileScreenSubscribedViewController.View.ViewData)
    }
}
