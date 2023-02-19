//
//  PostScreenViewController.swift
//  Lemmy-iOS
//
//  Created by uuttff8 on 9/26/20.
//  Copyright © 2020 Anton Kuzmin. All rights reserved.
//

import UIKit
import SwiftMessages
import RMModels
import RMServices

protocol PostScreenViewControllerProtocol: AnyObject {
    func displayPostWithComments(viewModel: PostScreen.PostLoad.ViewModel)
    func displayOnlyPost(viewModel: PostScreen.OnlyPostLoad.ViewModel)
    func displayCreateCommentLike(viewModel: PostScreen.CreateCommentLike.ViewModel)
    func displayUpdateComment(viewModel: PostScreen.UpdateComment.ViewModel)
    func displayToastMessage(viewModel: PostScreen.ToastMessage.ViewModel)
    func displayCreatedComment(viewModel: PostScreen.CreateComment.ViewModel)
}

class PostScreenViewController: UIViewController, Containered {
    weak var coordinator: PostScreenCoordinator?
    private let viewModel: PostScreenViewModelProtocol
        
    lazy var postScreenView = PostScreenViewController.View().then {
        $0.headerView.postHeaderView.delegate = self
        $0.delegate = self
    }
    
    private let scrollToComment: RMModel.Views.CommentView?
    
    private lazy var commentsViewController = FoldableLemmyCommentsViewController().then {
        $0.commentDelegate = self
    }
    
    private var state: PostScreen.ViewControllerState
    
    private let showMoreHandlerService: ShowMoreHandlerService
    private let contentScoreService: ContentScoreServiceProtocol

    init(
        viewModel: PostScreenViewModelProtocol,
        state: PostScreen.ViewControllerState = .loading,
        scrollToComment: RMModel.Views.CommentView?,
        contentScoreService: ContentScoreServiceProtocol,
        showMoreHandlerService: ShowMoreHandlerService
    ) {
        self.viewModel = viewModel
        self.state = state
        self.contentScoreService = contentScoreService
        self.showMoreHandlerService = showMoreHandlerService
        self.scrollToComment = scrollToComment
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        self.add(asChildViewController: commentsViewController)
        
        self.viewModel.doPostFetch()
        self.viewModel.doReceiveMessages()
        self.updateState(newState: state)
    }
                
    private func updateState(newState: PostScreen.ViewControllerState) {
        defer {
            self.state = newState
        }

        if case .loading = newState {
            postScreenView.showLoadingView()
            return
        }

        if case .loading = self.state {
            postScreenView.hideLoadingView()
        }

        if case .result(let data) = newState {
            state = .result(data: data)
            postScreenView.bind(with: data.post)
            commentsViewController.showComments(with: data.comments)
            commentsViewController.setupHeaderView(postScreenView)
            
            if let comment = self.scrollToComment {
                self.commentsViewController.scrollTo(comment)
            }
        }
    }
}

extension PostScreenViewController: PostScreenViewControllerProtocol {
    func displayToastMessage(viewModel: PostScreen.ToastMessage.ViewModel) {
        if viewModel.isSuccess {
            let config = RMMessagesToast.successBottomToast(title: "Success", body: viewModel.message)
            SwiftMessages.show(config: config.0, view: config.1)
        }
    }
    
    func displayOnlyPost(viewModel: PostScreen.OnlyPostLoad.ViewModel) {
        postScreenView.bind(with: viewModel.postView)
    }
    
    func displayUpdateComment(viewModel: PostScreen.UpdateComment.ViewModel) {
        commentsViewController.updateExistingComment(viewModel.commentView)
    }
    
    func displayCreateCommentLike(viewModel: PostScreen.CreateCommentLike.ViewModel) {
        commentsViewController.displayCommentLike(commentView: viewModel.commentView)
    }
    
    func displayCreatedComment(viewModel: PostScreen.CreateComment.ViewModel) {
        commentsViewController.displayCreatedComment(comment: viewModel.comment)
    }
    
    func displayPostWithComments(viewModel: PostScreen.PostLoad.ViewModel) {
        updateState(newState: viewModel.state)
    }
}

extension PostScreenViewController: PostContentTableCellDelegate {
    func postCellDidSelected(postId: RMModel.Views.PostView.ID) {
        let post = postScreenView.postData.require()
        self.coordinator?.goToPostScreen(post: post)
    }
        
    func voteContent(
        scoreView: VoteButtonsWithScoreView,
        voteButton: VoteButton,
        newVote: LemmyVoteType,
        post: RMModel.Views.PostView
    ) {
        guard let coordinator = coordinator else {
            return
        }
        
        ContinueIfLogined(on: self, coordinator: coordinator) {
            scoreView.setVoted(voteButton: voteButton, to: newVote)
            self.contentScoreService.votePost(for: newVote, post: post)
        }
    }
        
    func onLinkTap(in post: RMModel.Views.PostView, url: URL) {
        coordinator?.goToBrowser(with: url)
    }
    
    func showMore(in post: RMModel.Views.PostView) {
        
        if let post = postScreenView.postData {
            guard let coordinator = coordinator else {
                return
            }
//            self.showMoreHandlerService.showMoreInPost(on: self, coordinator: coordinator, post: post) { updatedPost in
//                self.postScreenView.bind(with: updatedPost)
//            }
        }
    }
    
    func presentVc(viewController: UIViewController) {
        present(viewController, animated: true)
    }
}

extension PostScreenViewController: CommentsViewControllerDelegate {
    func postNameTapped(in comment: RMModel.Views.CommentView) { }
    
    func usernameTapped(with mention: LemmyUserMention) {
        coordinator?.goToProfileScreen(userId: mention.absoluteId, username: mention.absoluteUsername)
    }
    
    func communityTapped(with mention: LemmyCommunityMention) {
        coordinator?.goToCommunityScreen(communityId: mention.absoluteId, communityName: mention.absoluteName)
    }

    func voteContent(
        scoreView: VoteButtonsWithScoreView,
        voteButton: VoteButton,
        newVote: LemmyVoteType,
        comment: RMModel.Views.CommentView
    ) {
        guard let coordinator = coordinator else {
            return
        }
        
        ContinueIfLogined(on: self, coordinator: coordinator) {
            scoreView.setVoted(voteButton: voteButton, to: newVote)
            self.contentScoreService.voteComment(for: newVote, comment: comment)
        }
    }
        
    func showContext(in comment: RMModel.Views.CommentView) { }
    
    func reply(to comment: RMModel.Views.CommentView) {
        coordinator?.goToWriteComment(postSource: comment.post, parrentComment: comment.comment) {
            RMMessagesToast.showSuccessCreateComment()
        }
    }
    
    func onLinkTap(in comment: RMModel.Views.CommentView, url: URL) {
        self.coordinator?.goToBrowser(with: url)
    }
    
    func showMoreAction(in comment: RMModel.Views.CommentView) {
        if let index = commentsViewController.commentDataSource.getElementIndex(by: comment.id) {
            guard let coordinator = coordinator, let commentContent = commentsViewController.commentDataSource[index].commentContent else {
                return
            }
//            showMoreHandlerService.showMoreInComment(
//                on: self,
//                coordinator: coordinator,
//                comment: commentContent
//            ) { updatedComment in
//                self.commentsViewController.updateExistingComment(updatedComment)
//            }
        }
    }
    
    func refreshControlDidRequestRefresh() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            self.viewModel.doPostFetch()
        }
    }
}

extension PostScreenViewController: PostScreenViewDelegate {
    func postView(_ postView: View, didWriteCommentTappedWith post: RMModel.Views.PostView) {
        coordinator?.goToWriteComment(postSource: post.post, parrentComment: nil) {
            RMMessagesToast.showSuccessCreateComment()
        }
    }
    
    func postView(didEmbedTappedWith url: URL) {
        coordinator?.goToBrowser(with: url)
    }
}
