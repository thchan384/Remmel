//
//  ProfileScreenModel.swift
//  Lemmy-iOS
//
//  Created by uuttff8 on 07.11.2020.
//  Copyright © 2020 Anton Kuzmin. All rights reserved.
//

import UIKit
import Combine
import RMModels
import RMNetworking
import RMServices
import RMFoundation

protocol ProfileScreenViewModelProtocol: AnyObject {
    var loadedProfile: ProfileScreenViewModel.ProfileData? { get }
    
    func doReceiveMessages()
    func doProfileFetch()
    func doIdentifyProfile()
    func doProfileLogout()
    func doSubmoduleControllerAppearanceUpdate(request: ProfileScreenDataFlow.SubmoduleAppearanceUpdate.Request)
    func doSubmodulesRegistration(request: ProfileScreenDataFlow.SubmoduleRegistration.Request)
    func doSubmodulesDataFilling(request: ProfileScreenDataFlow.SubmoduleDataFilling.Request)
    //    func doSubmoduleDataFilling(request: ProfileScreenDataFlow.SubmoduleDataFilling.Request)
}

extension ProfileScreenViewModel {
    struct ProfileData: Identifiable {
        let id: Int
        let viewData: ProfileScreenHeaderView.ViewData
        let userDetails: RMModels.Api.Person.GetPersonDetailsResponse
    }
}

class ProfileScreenViewModel: ProfileScreenViewModelProtocol {
    private var profileId: Int?
    private let profileUsername: String?
    
    weak var viewController: ProfileScreenViewControllerProtocol?
    
    private weak var wsClient: WSClientProtocol?
    
    private let userAccountService: UserAccountServiceProtocol
    
    private var cancellable = Set<AnyCancellable>()
    
    private(set) var loadedProfile: ProfileData?
    
    // Tab index -> Submodule
    private(set) var submodules: [Int: ProfileScreenSubmoduleProtocol] = [:] {
        didSet {
            print("Submodules is changed")
        }
    }
    
    init(
        profileId: Int?,
        profileUsername: String?,
        userAccountService: UserAccountServiceProtocol,
        wsClient: WSClientProtocol
    ) {
        self.profileId = profileId
        self.profileUsername = profileUsername
        self.userAccountService = userAccountService
        self.wsClient = wsClient
    }
    
    func doReceiveMessages() {
        self.wsClient?.onTextMessage.addObserver(self, completionHandler: { [weak self] operation, data in
            guard let self = self else {
                return
            }
            
            switch operation {
            case RMUserOperation.GetPersonDetails.rawValue:
                guard let userDetails = self.wsClient?.decodeWsType(
                    RMModels.Api.Person.GetPersonDetailsResponse.self,
                    data: data
                ) else { return }
                
                DispatchQueue.main.async {
                    self.fetchProfile(with: userDetails)
                }
                
            default: break
            }
        })
    }
    
    func doProfileFetch() {
        self.viewController?.displayNotBlockingActivityIndicator(viewModel: .init(shouldDismiss: false))
        
        let parameters = RMModels.Api.Person.GetPersonDetails(personId: profileId,
                                                              username: profileUsername,
                                                              sort: .active,
                                                              page: 1,
                                                              limit: 50,
                                                              communityId: nil,
                                                              savedOnly: false,
                                                              auth: LemmyShareData.shared.jwtToken)
        
        self.wsClient?.send(RMUserOperation.GetPersonDetails, parameters: parameters)
    }
    
    func doIdentifyProfile() {
        let isCurrent = loadedProfile?.id == userAccountService.currentUserInfo?.localUserView.person.id
            ? true
            : false
        guard let profile = loadedProfile else {
            return
        }
        
        let userId = profile.id
        
        let isBlocked = self.userIsBlocked(userId: userId)
        
        self.viewController?.displayMoreButtonAlert(
            viewModel: .init(isCurrentProfile: isCurrent,
                             isBlocked: isBlocked,
                             userId: userId,
                             actorId: profile.userDetails.personView.person.actorId)
        )
    }
    
    func doProfileLogout() {
        userAccountService.userLogout()
        NotificationCenter.default.post(name: .didLogin, object: nil)
    }
    
    func doSubmoduleControllerAppearanceUpdate(request: ProfileScreenDataFlow.SubmoduleAppearanceUpdate.Request) {
        self.submodules[request.submoduleIndex]?.handleControllerAppearance()
    }
    
    func doSubmodulesRegistration(request: ProfileScreenDataFlow.SubmoduleRegistration.Request) {
        for (key, value) in request.submodules {
            self.submodules[key] = value
        }
        self.pushCurrentCourseToSubmodules(submodules: Array(self.submodules.values))
    }
    
    private func fetchProfile(with response: RMModels.Api.Person.GetPersonDetailsResponse) {
        self.viewController?.displayNotBlockingActivityIndicator(viewModel: .init(shouldDismiss: true))
        
        let loadedProfile = self.initializeProfileData(with: response)
        self.loadedProfile = loadedProfile
        
        // if blocked user then show nothing
        if self.userIsBlocked(userId: loadedProfile.id) {
            self.loadedProfile = ProfileData(id: loadedProfile.id,
                                             viewData: loadedProfile.viewData,
                                             userDetails: response)
            self.viewController?.displayProfile(viewModel: .init(state: .blockedUser))
            return
        }
        
        self.viewController?.displayProfile(
            viewModel: .init(state: .result(profile: loadedProfile.viewData,
                                            posts: response.posts,
                                            comments: response.comments))
        )
    }
    
    private func pushCurrentCourseToSubmodules(submodules: [ProfileScreenSubmoduleProtocol]) {
        guard let profileData = loadedProfile else {
            return
        }
        
        self.submodules.forEach { key, submodule in
            switch key {
            case ProfileScreenDataFlow.Tab.posts.rawValue:
                submodule.updatePostsData(profile: profileData, posts: profileData.userDetails.posts)
            case ProfileScreenDataFlow.Tab.comments.rawValue:
                submodule.updateCommentsData(profile: profileData, comments: profileData.userDetails.comments)
                
            default:
                break
            }
            
        }
    }
    
    func doSubmodulesDataFilling(request: ProfileScreenDataFlow.SubmoduleDataFilling.Request) {
        guard let profileData = loadedProfile else {
            debugPrint("Profile is not initialized")
            return
        }
        
        self.submodules = request.submodules
        
        request.submodules.forEach { key, submodule in
            switch key {
            case ProfileScreenDataFlow.Tab.posts.rawValue:
                submodule.updatePostsData(profile: profileData, posts: request.posts)
            case ProfileScreenDataFlow.Tab.comments.rawValue:
                submodule.updateCommentsData(profile: profileData, comments: request.comments)
                
            default:
                break
            }
        }
    }
    
    private func initializeProfileData(with response: RMModels.Api.Person.GetPersonDetailsResponse) -> ProfileData {
        let userView = response.personView
        
        return ProfileData(
            id: userView.person.id,
            viewData: .init(
                name: userView.person.name,
                avatarUrl: userView.person.avatar,
                bannerUrl: userView.person.banner,
                numberOfComments: userView.counts.commentCount,
                numberOfPosts: userView.counts.postCount,
                published: userView.person.published.toLocalTime()
            ),
            userDetails: response
        )
    }
    
    private func userIsBlocked(userId: Int) -> Bool {
        if LemmyShareData.shared.blockedUsersId.contains(userId) {
            return true
        }
        
        return false
    }
}

enum ProfileScreenDataFlow {
    enum Tab: Int, CaseIterable {
        case posts
        case comments
        
        var title: String {
            switch self {
            case .comments: return "content-comments".localized
            case .posts: return "content-posts".localized
            }
        }
    }
    
    enum ProfileLoad {
        struct Request { }
        
        struct ViewModel {
            var state: ViewControllerState
        }
    }
    
    enum IdentifyProfile {
        struct Request { }
        
        struct ViewModel {
            let isCurrentProfile: Bool
            let isBlocked: Bool
            let userId: Int
            let actorId: URL
        }
    }
    
    enum BlockedUser {
        struct ViewModel { }
    }
    
    enum SubmoduleDataFilling {
        struct Request {
            let submodules: [Int: ProfileScreenSubmoduleProtocol]
            let posts: [RMModels.Views.PostView]
            let comments: [RMModels.Views.CommentView]
        }
    }
    
    /// Handle submodule controller appearance
    enum SubmoduleAppearanceUpdate {
        struct Request {
            let submoduleIndex: Int
        }
    }
    
    /// Register submodules
    enum SubmoduleRegistration {
        struct Request {
            var submodules: [Int: ProfileScreenSubmoduleProtocol]
        }
    }
    
    /// Register submodules
    enum SubmoduleOneRegistration {
        struct Request {
            var submodules: [ProfileScreenSubmoduleProtocol]
        }
    }
    
    enum ShowingActivityIndicator {
        struct ViewModel {
            let shouldDismiss: Bool
        }
    }
    
    enum ViewControllerState {
        case loading
        case result(profile: ProfileScreenHeaderView.ViewData,
                    posts: [RMModels.Views.PostView],
                    comments: [RMModels.Views.CommentView])
        case blockedUser
    }
}
