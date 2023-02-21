//
//  CommentsFrontPageViewController.swift
//  Lemmy-iOS
//
//  Created by uuttff8 on 10/12/20.
//  Copyright © 2020 Anton Kuzmin. All rights reserved.
//

import UIKit
import RMModels
import RMServices
import RMFoundation

extension CommentsFrontPageViewController {
    struct Appearance {
        let estimatedRowHeight: CGFloat = CommentContentTableCell.estimatedHeight
    }
}

class CommentsFrontPageViewController: UIViewController {

    typealias Snapshot = NSDiffableDataSourceSnapshot<Section, RMModels.Views.CommentView>
    
    enum Section {
        case comments
    }

    weak var coordinator: FrontPageCoordinator?
    
    private let appearance: Appearance

    private let viewModel = CommentsFrontPageModel()
    private let showMoreHandler = ShowMoreHandlerServiceImp()
    
    private let refreshControl = UIRefreshControl()

    lazy var tableView = LemmyTableView(style: .plain).then {
        $0.registerClass(CommentContentTableCell.self)
        $0.delegate = viewModel
        $0.keyboardDismissMode = .onDrag
        $0.refreshControl = self.refreshControl
        self.refreshControl.addTarget(self, action: #selector(refreshControlValueChanged), for: .valueChanged)
    }
    
    private lazy var dataSource = makeDataSource()
    
    private let pickerView = LemmySortListingPickersView()
    
    init(appearance: Appearance = Appearance()) {
        self.appearance = appearance
        super.init(nibName: nil, bundle: nil)
        
        setupView()
        addSubviews()
        makeConstraints()
    }
    
    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.showActivityIndicator()
        viewModel.loadComments()
        setupTableHeaderView()

        viewModel.dataLoaded = { [self] in
            diffTable(animating: false)
            tableView.hideActivityIndicator()
            if self.refreshControl.isRefreshing {
                self.refreshControl.endRefreshing()
            }
        }
        
        viewModel.newDataLoaded = { [self] in
            diffTable(animating: true)
        }
        
        viewModel.createCommentLikeUpdate = { index in
            let indexPath = IndexPath(row: index, section: 0)
            
            DispatchQueue.main.async {
                if let cell = self.tableView.cellForRow(at: indexPath) as? CommentContentTableCell {
                    cell.updateForCreateCommentLike(comment: self.viewModel.commentsDataSource[index])
                }
            }
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.tableView.showActivityIndicator()
        self.viewModel.receiveMessages()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        tableView.snp.makeConstraints {
            $0.edges.equalTo(self.view.safeAreaLayoutGuide)
        }
        
        tableView.layoutTableHeaderView()
    }

    func diffTable(animating: Bool) {
        var snapshot = Snapshot()
        
        snapshot.appendSections([.comments])
        snapshot.appendItems(self.viewModel.commentsDataSource, toSection: .comments)
        dataSource.apply(snapshot, animatingDifferences: animating)
    }

    @objc
    func refreshControlValueChanged() {
        updateTableData(immediately: false)
    }
    
    fileprivate func setupTableHeaderView() {
//        pickerView.listingFirstPick = viewModel.currentListingType
//        pickerView.sortFirstPick = viewModel.currentSortType
//
//        pickerView.sortTypeView.addTap {
//            self.present(self.pickerView.sortTypeView.configuredAlert, animated: true)
//        }
//
//        pickerView.listingTypeView.addTap {
//            self.present(self.pickerView.listingTypeView.configuredAlert, animated: true)
//        }
                
//        pickerView.listingTypeView.newCasePicked = { [self] pickedValue in
//            self.viewModel.currentListingType = pickedValue
//
//            updateTableData(immediately: true)
//        }
//
//        pickerView.sortTypeView.newCasePicked = { [self] pickedValue in
//            self.viewModel.currentSortType = pickedValue
//
//            updateTableData(immediately: true)
//        }
    }

    private func makeDataSource() -> UITableViewDiffableDataSource<Section, RMModels.Views.CommentView> {
        return UITableViewDiffableDataSource<Section, RMModels.Views.CommentView>(
            tableView: tableView,
            cellProvider: { tableView, indexPath, _ -> UITableViewCell? in
                let cell = tableView.cell(forClass: CommentContentTableCell.self)
                cell.commentContentView.delegate = self
                cell.bind(with: self.viewModel.commentsDataSource[indexPath.row], level: 0)

                return cell
            })
    }
    
    private func updateTableData(immediately: Bool) {
        if immediately {
            let snapshot = Snapshot()
            self.dataSource.apply(snapshot)
        }

        viewModel.loadComments()
    }
}

extension CommentsFrontPageViewController: ProgrammaticallyViewProtocol {
    func setupView() {
        tableView.tableHeaderView = pickerView
        tableView.estimatedRowHeight = self.appearance.estimatedRowHeight
    }
    
    func addSubviews() {
        self.view.addSubview(tableView)
    }
    
    func makeConstraints() {
        tableView.snp.makeConstraints { make in
            make.edges.equalTo(self.view.safeAreaLayoutGuide)
        }
    }
}

extension CommentsFrontPageViewController: CommentContentTableCellDelegate {
    func postNameTapped(in comment: RMModels.Views.CommentView) {
        self.coordinator?.goToPostScreen(postId: comment.post.id)
    }
    
    func usernameTapped(with mention: LemmyUserMention) {
        self.coordinator?.goToProfileScreen(userId: mention.absoluteId, username: mention.absoluteUsername)
    }
    
    func communityTapped(with mention: LemmyCommunityMention) {
        self.coordinator?.goToCommunityScreen(communityId: mention.absoluteId, communityName: mention.absoluteName)
    }

    func voteContent(
        scoreView: VoteButtonsWithScoreView,
        voteButton: VoteButton,
        newVote: LemmyVoteType,
        comment: RMModels.Views.CommentView
    ) {
        guard let coordinator = coordinator else {
            return
        }
        
        ContinueIfLogined(on: self, coordinator: coordinator) {
            viewModel.createCommentLike(scoreView: scoreView, voteButton: voteButton, for: newVote, comment: comment)
        }
    }
    
    func showContext(in comment: RMModels.Views.CommentView) {
        self.coordinator?.goToPostAndScroll(to: comment)
    }
    
    func reply(to comment: RMModels.Views.CommentView) {
        coordinator?.goToWriteComment(postSource: comment.post, parrentComment: comment.comment) {
            RMMessagesToast.showSuccessCreateComment()
        }
    }
    
    func onLinkTap(in comment: RMModels.Views.CommentView, url: URL) {
        self.coordinator?.goToBrowser(with: url)
    }
    
    func showMoreAction(in comment: RMModels.Views.CommentView) {
        if let index = self.viewModel.commentsDataSource.getElementIndex(by: comment.id) {
            guard let coordinator = coordinator else {
                return
            }
            
//            showMoreHandler.showMoreInComment(
//                on: self,
//                coordinator: coordinator,
//                comment: self.viewModel.commentsDataSource[index]
//            ) { updatedComment in
//                self.viewModel.commentsDataSource.updateElementById(updatedComment)
//            }
        }
    }
}
