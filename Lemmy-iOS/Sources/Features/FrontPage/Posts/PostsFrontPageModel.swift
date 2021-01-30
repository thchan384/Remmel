//
//  PostsFrontPageModel.swift
//  Lemmy-iOS
//
//  Created by uuttff8 on 10/12/20.
//  Copyright © 2020 Anton Kuzmin. All rights reserved.
//

import UIKit
import Combine

class PostsFrontPageModel: NSObject {
    var newDataLoaded: (() -> Void)?
    var dataLoaded: (() -> Void)?
    
    private let contentScoreService = ContentScoreService(userAccountService: UserAccountService())
    private let contentPreferenceService = ContentPreferencesStorageManager()
    
    private let wsEvents = ApiManager.chainedWsCLient
    
    private var cancellable = Set<AnyCancellable>()
    
    var isFetchingNewContent = false
    var currentPage = 1
    
    var postsDataSource: [LMModels.Views.PostView] = []
    
    var currentSortType: LMModels.Others.SortType {
        get { contentPreferenceService.contentSortType }
        set {
            self.currentPage = 1
            contentPreferenceService.contentSortType = newValue
        }
    }
    
    var currentListingType: LMModels.Others.ListingType {
        get { contentPreferenceService.listingType }
        set {
            self.currentPage = 1
            contentPreferenceService.listingType = newValue
        }
    }
    
    func receiveMessages() {
        wsEvents?.connect()
            .onMessage(completion: { (operation, data) in
                
                switch operation {
                case WSEndpoint.Post.createPostLike.endpoint:
                    
                    guard let data = try? LemmyJSONDecoder().decode(
                        RequestsManager.ApiResponse<LMModels.Api.Post.PostResponse>.self,
                        from: data
                    )
                    else { return }
                    
                    self.postsDataSource.updateElementById(data.data.postView)
                default:
                    break
                }
                
            })
        
        let commJoin = LMModels.Api.Websocket.CommunityJoin(communityId: 0)

        wsEvents?.send(
            WSEndpoint.Community.communityJoin.endpoint,
            parameters: commJoin
        )
    }
    
    func loadPosts() {
        let parameters = LMModels.Api.Post.GetPosts(type: self.currentListingType,
                                                    sort: self.currentSortType,
                                                    page: 1,
                                                    limit: 50,
                                                    communityId: nil,
                                                    communityName: nil,
                                                    auth: LemmyShareData.shared.jwtToken)
        
        ApiManager.requests.asyncGetPosts(parameters: parameters)
            .receive(on: DispatchQueue.main)
            .sink { (completion) in
                Logger.logCombineCompletion(completion)
            } receiveValue: { (response) in
                self.postsDataSource = response.posts
                self.dataLoaded?()
            }.store(in: &cancellable)
    }
    
    func loadMorePosts(completion: @escaping (() -> Void)) {
        let parameters = LMModels.Api.Post.GetPosts(type: self.currentListingType,
                                                    sort: self.currentSortType,
                                                    page: self.currentPage,
                                                    limit: 50,
                                                    communityId: nil,
                                                    communityName: nil,
                                                    auth: LemmyShareData.shared.jwtToken)
        
        ApiManager.requests.asyncGetPosts(parameters: parameters)
            .receive(on: DispatchQueue.main)
            .sink { (completion) in
                Logger.logCombineCompletion(completion)
            } receiveValue: { (response) in
                self.postsDataSource.append(contentsOf: response.posts)
                self.newDataLoaded?()
                completion()
                
            }.store(in: &cancellable)
    }
    
    func getPost(by id: LMModels.Views.PostView.ID) -> LMModels.Views.PostView? {
        if let index = postsDataSource.firstIndex(where: { $0.id == id }) {
            return postsDataSource[index]
        }
        
        return nil
    }
    
    private func saveNewPost(_ post: LMModels.Views.PostView) {
        postsDataSource.updateElementById(post)
    }
    
    func createPostLike(newVote: LemmyVoteType, post: LMModels.Views.PostView) {
        self.contentScoreService.createPostLike(vote: newVote, postId: post.id)
            .receive(on: DispatchQueue.main)
            .sink { (completion) in
                Logger.logCombineCompletion(completion)
            } receiveValue: { (post) in
                self.saveNewPost(post)
            }.store(in: &cancellable)
    }
}

extension PostsFrontPageModel: FrontPageHeaderCellDelegate {
    func contentTypeChanged(to content: LemmyContentType) {
        
    }
}
