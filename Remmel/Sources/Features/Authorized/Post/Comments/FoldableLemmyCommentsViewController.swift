//
//  LemmyCommentsViewController.swift
//  Lemmy-iOS
//
//  Created by uuttff8 on 25.11.2020.
//  Copyright © 2020 Anton Kuzmin. All rights reserved.
//

import UIKit
import RMModels

protocol CommentsViewControllerDelegate: CommentContentTableCellDelegate {
    func refreshControlDidRequestRefresh()
}

final class FoldableLemmyCommentsViewController: CommentsViewController, SwiftyCommentTableViewDataSource {
        
    weak var commentDelegate: CommentsViewControllerDelegate?
        
    var commentDataSource: [LemmyComment] {
        get { currentlyDisplayed as? [LemmyComment] ?? [] }
        set { currentlyDisplayed = newValue }
    }
    
    init() {
        super.init(nibName: nil, bundle: nil)
    }
    
    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.refreshControl = UIRefreshControl()
        if let refreshControl = self.refreshControl {
            refreshControl.addTarget(
                self,
                action: #selector(self.refreshControlValueChanged),
                for: .valueChanged
            )
            tableView.addSubview(refreshControl)
        }
        
        tableView.registerClass(SwipingCommentContentTableCell.self)
        tableView.estimatedRowHeight = CommentContentTableCell.estimatedHeight
    }
    
    func showComments(with comments: [LemmyComment]) {
        _currentlyDisplayed.removeAll()
        if let refresh = self.refreshControl, refresh.isRefreshing {
            refresh.endRefreshing()
        }

        self.delegate = self
        self.fullyExpanded = true
        
        self.dataSource = self
        self.currentlyDisplayed = comments
        self.tableView.reloadData()
    }
    
    func updateExistingComment(_ comment: RMModel.Views.CommentView) {
        if let index = self.commentDataSource.getElementIndex(by: comment.id) {
            commentDataSource[index].commentContent = comment
        }
    }
    
    func displayCreatedComment(comment: RMModel.Views.CommentView) {
        self.updateExistingComment(comment)
        
        // TODO: just paste a new comment
//        let mutator = CommentTreeMutator(buildedComments: &self.commentDataSource)
//
//        
//        mutator.insert(comment: comment)
//        DispatchQueue.main.async {
//            self.tableView.reloadData()
//        }
    }
    
    func displayCommentLike(commentView: RMModel.Views.CommentView) {
        self.updateExistingComment(commentView)
        
        guard let index = commentDataSource.firstIndex(where: { $0.commentContent?.comment.id == commentView.id })
        else { return }
        
        let indexPath = IndexPath(row: index, section: 0)
        
        DispatchQueue.main.async {
            if let cell = self.tableView.cellForRow(at: indexPath) as? SwipingCommentContentTableCell {
                guard let commentContent = self.commentDataSource[index].commentContent else {
                    debugPrint("commentContent for comment is not found, so not updating comment like")
                    return
                }
                
                cell.updateForCreateCommentLike(comment: commentContent)
            }
        }
    }
    
    func scrollTo(_ comment: RMModel.Views.CommentView) {
        guard let index = commentDataSource.firstIndex(where: { $0.commentContent?.comment.id == comment.id }) else {
            return
        }
        
        let indexPath = IndexPath(row: index, section: 0)
        tableView.scrollToRow(at: indexPath, at: .middle, animated: false)
        
        if let cell = self.tableView.cellForRow(at: indexPath) as? SwipingCommentContentTableCell {
            cell.focusOnContent()
        } else {
            debugPrint("Not found cell in FoldableLemmyComments \(type(of: SwipingCommentContentTableCell.self))")
        }
    }
    
    func setupHeaderView(_ headerView: UIView) {
        self.tableView.tableHeaderView = headerView
        self.tableView.layoutTableHeaderView()
    }
    
    func commentsView(
        _ tableView: UITableView,
        commentCellForModel commentModel: AbstractComment,
        atIndexPath indexPath: IndexPath
    ) -> CommentCell {
        let commentCell: SwipingCommentContentTableCell = tableView.cell(forRowAt: indexPath)
        let comment = commentDataSource[indexPath.row]
        guard let  commentContent = comment.commentContent else {
            return CommentCell(style: .default, reuseIdentifier: "")
        }
        
        commentCell.bind(with: commentContent, level: comment.level, appearance: .init(config: .inPost))
        commentCell.commentContentView.delegate = commentDelegate
        
        return commentCell
    }
    
    @objc private func refreshControlValueChanged() {
        self.commentDelegate?.refreshControlDidRequestRefresh()
    }
}

extension FoldableLemmyCommentsViewController: CommentsViewDelegate {
    func commentCellExpanded(atIndex index: Int) {
        updateCellFoldState(false, atIndex: index)
    }
    
    func commentCellFolded(atIndex index: Int) {
        updateCellFoldState(true, atIndex: index)
    }
    
    private func updateCellFoldState(_ folded: Bool, atIndex index: Int) {

        guard let cell = tableView.cellForRow(at: IndexPath(row: index, section: 0)) as? SwipingCommentContentTableCell,
              let currentlyDisplayed = currentlyDisplayed as? [LemmyComment]
        else {
            return
        }
        cell.animateIsFolded(fold: folded)
        currentlyDisplayed[index].isFolded = folded
        tableView.beginUpdates()
        tableView.endUpdates()
    }
}
