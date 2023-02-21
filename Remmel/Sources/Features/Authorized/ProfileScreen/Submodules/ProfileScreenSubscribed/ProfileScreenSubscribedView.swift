//
//  ProfileScreenSubscribedView.swift
//  Lemmy-iOS
//
//  Created by uuttff8 on 12.11.2020.
//  Copyright © 2020 Anton Kuzmin. All rights reserved.
//

import UIKit
import RMModels

protocol ProfileScreenSubscribedViewDelegate: AnyObject {
    func tableDidSelect(
        _ view: ProfileScreenSubscribedViewController.View,
        communityFollower: RMModels.Views.CommunityFollowerView
    )
}

extension ProfileScreenSubscribedViewController {
    
    class View: UIView {
        struct ViewData {
            let subscribers: [RMModels.Views.CommunityFollowerView]
        }
        
        weak var delegate: ProfileScreenSubscribedViewDelegate?
                
        // Proxify delegates
        private weak var pageScrollViewDelegate: UIScrollViewDelegate?
        
        private var tableManager: ProfileScreenSubscribedTableManager?
        
        private lazy var tableView = LemmyTableView(style: .plain, separator: false).then {
            $0.registerClass(CommunityMiniPreviewTableCell.self)
            $0.backgroundColor = .clear
            $0.showsVerticalScrollIndicator = false
            $0.delegate = self
        }
        
        private lazy var emptyStateLabel = UILabel().then {
            $0.text = "nodata-about".localized
            $0.textAlignment = .center
            $0.textColor = .tertiaryLabel
        }
        
        override init(frame: CGRect = .zero) {
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
            tableView.showActivityIndicator()
        }
        
        func hideActivityIndicator() {
            tableView.hideActivityIndicator()
        }
        
        func updateTableViewData(dataSource: ProfileScreenSubscribedTableManager) {
            self.tableManager = dataSource
            self.emptyStateLabel.isHidden = true
            _ = dataSource.tableView(self.tableView, numberOfRowsInSection: 0)
//            self.emptyStateLabel.isHidden = numberOfRows != 0

            self.tableView.dataSource = dataSource
            self.tableView.reloadData()
        }
        
        func displayNoData() {
            self.emptyStateLabel.isHidden = false
        }
    }
}

extension ProfileScreenSubscribedViewController.View: ProgrammaticallyViewProtocol {
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
    }
}

extension ProfileScreenSubscribedViewController.View: UITableViewDelegate {
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        self.pageScrollViewDelegate?.scrollViewDidScroll?(scrollView)
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let manager = tableManager else {
            return
        }
        
        let viewModel = manager.viewModels[indexPath.row]
        self.delegate?.tableDidSelect(self, communityFollower: viewModel)
        tableView.deselectRow(at: indexPath, animated: true)
    }
}

extension ProfileScreenSubscribedViewController.View: ProfileScreenScrollablePageViewProtocol {
    var scrollViewDelegate: UIScrollViewDelegate? {
        get { self.pageScrollViewDelegate }
        set { self.pageScrollViewDelegate = newValue }
    }

    var contentInsets: UIEdgeInsets {
        get { self.tableView.contentInset }
        set { self.tableView.contentInset = newValue }
    }

    var contentOffset: CGPoint {
        get { self.tableView.contentOffset }
        set { self.tableView.contentOffset = newValue }
    }

    var contentInsetAdjustmentBehavior: UIScrollView.ContentInsetAdjustmentBehavior {
        get { self.tableView.contentInsetAdjustmentBehavior }
        set { self.tableView.contentInsetAdjustmentBehavior = newValue }
    }
}
