//
//  ProfileScreenPostsUI.swift
//  Lemmy-iOS
//
//  Created by uuttff8 on 10.11.2020.
//  Copyright © 2020 Anton Kuzmin. All rights reserved.
//

import UIKit
import SnapKit
import RMModels

protocol ProfileScreenPostsViewDelegate: AnyObject {
    func profileScreenPostsViewDidPickerTapped(toVc: UIViewController)
    func profileScreenPosts(
        _ view: ProfileScreenPostsViewController.View,
        didPickedNewSort type: RMModel.Others.SortType
    )
}

extension ProfileScreenPostsViewController.View {
    struct Appearance {
        
    }
}

extension ProfileScreenPostsViewController {
    
    class View: UIView {
        
        struct ViewData {
            let posts: [RMModel.Views.PostView]
        }
        
        weak var delegate: ProfileScreenPostsViewDelegate?
        
        let appearance: Appearance
        var sortType: RMModel.Others.SortType = .active {
            didSet {
                self.delegate?.profileScreenPosts(self, didPickedNewSort: sortType)
            }
        }
                
        // Proxify delegates
        private weak var pageScrollViewDelegate: UIScrollViewDelegate?
        
        weak var tableManager: PostsTableDataSource?
        
        private lazy var tableView = LemmyTableView(style: .plain, separator: false).then {
            $0.registerClass(PostContentPreviewTableCell.self)
            $0.backgroundColor = .clear
            $0.showsVerticalScrollIndicator = false
            $0.delegate = self
        }
                
        private lazy var emptyStateLabel = UILabel().then {
            $0.text = "nodata-posts".localized
            $0.textAlignment = .center
            $0.textColor = .tertiaryLabel
        }
        
        private lazy var profileScreenHeader = ProfileScreenTableHeaderView().then { view in
//            view.contentTypeView.addTap {
//                let vc = view.contentTypeView.configuredAlert
//                self.delegate?.profileScreenPostsViewDidPickerTapped(toVc: vc)
//            }
//
//            view.contentTypeView.newCasePicked = { newCase in
//                self.sortType = newCase
//            }
        }
        
        init(
            frame: CGRect = .zero,
            appearance: Appearance = Appearance(),
            tableViewDelegate: PostsTableDataSource
        ) {
            self.appearance = appearance
            self.tableManager = tableViewDelegate
            super.init(frame: frame)

            self.setupView()
            self.addSubviews()
            self.makeConstraints()
        }
        
        @available(*, unavailable)
        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
        
        func showLoadingIndicator() {
            self.emptyStateLabel.isHidden = true
            tableView.showActivityIndicator()
        }
        
        func hideLoadingIndicator() {
            tableView.hideActivityIndicator()
        }
        
        func updateTableViewData(dataSource: UITableViewDataSource) {
            self.hideLoadingIndicator()
            self.emptyStateLabel.isHidden = true
            _ = dataSource.tableView(self.tableView, numberOfRowsInSection: 0)
//            self.emptyStateLabel.isHidden = numberOfRows != 0

            tableView.tableHeaderView = profileScreenHeader
            
            self.tableView.dataSource = dataSource
            self.tableView.reloadData()
        }
        
        func deleteAllContent() {
            self.tableManager?.viewModels = []
            self.tableView.reloadData()
        }
        
        func displayNoData() {
            self.emptyStateLabel.isHidden = false
            self.hideLoadingIndicator()
        }
        
        func appendNew(data: [RMModel.Views.PostView]) {
            self.tableManager?.appendNew(posts: data) { newIndexpaths in
                tableView.performBatchUpdates {
                    tableView.insertRows(at: newIndexpaths, with: .none)
                }
            }
        }
        
        override func layoutSubviews() {
            super.layoutSubviews()
            self.tableView.layoutTableHeaderView()
        }
    }
}

extension ProfileScreenPostsViewController.View: ProgrammaticallyViewProtocol {
    func setupView() {
        self.emptyStateLabel.isHidden = true
    }
    
    func addSubviews() {
        self.addSubview(tableView)
        self.addSubview(emptyStateLabel)
    }
    
    func makeConstraints() {
        self.tableView.snp.makeConstraints { make in
            make.top.leading.trailing.equalToSuperview()
            make.bottom.equalTo(self.safeAreaLayoutGuide) // tab bar
        }
        
        self.emptyStateLabel.snp.makeConstraints {
            $0.top.equalToSuperview().inset(350)
            $0.leading.trailing.equalToSuperview()
        }
        
        self.tableView.layoutTableHeaderView()
    }
}

extension ProfileScreenPostsViewController.View: UITableViewDelegate {
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        self.emptyStateLabel.bounds.origin = scrollView.contentOffset
        self.pageScrollViewDelegate?.scrollViewDidScroll?(scrollView)
    }
    
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        self.tableManager?.tableView(tableView, willDisplay: cell, forRowAt: indexPath)
    }
}

extension ProfileScreenPostsViewController.View: ProfileScreenScrollablePageViewProtocol {
    var scrollViewDelegate: UIScrollViewDelegate? {
        get {
             self.pageScrollViewDelegate
        }
        set {
            self.pageScrollViewDelegate = newValue
        }
    }

    var contentInsets: UIEdgeInsets {
        get {
             self.tableView.contentInset
        }
        set {
            self.tableView.contentInset = newValue
        }
    }

    var contentOffset: CGPoint {
        get {
             self.tableView.contentOffset
        }
        set {
            self.tableView.contentOffset = newValue
        }
    }

    var contentInsetAdjustmentBehavior: UIScrollView.ContentInsetAdjustmentBehavior {
        get {
             self.tableView.contentInsetAdjustmentBehavior
        }
        set {
            self.tableView.contentInsetAdjustmentBehavior = newValue
        }
    }
}
