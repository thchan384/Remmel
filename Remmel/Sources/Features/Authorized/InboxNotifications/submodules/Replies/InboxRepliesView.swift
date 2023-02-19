//
//  InboxRepliesView.swift
//  Lemmy-iOS
//
//  Created by uuttff8 on 06.01.2021.
//  Copyright © 2021 Anton Kuzmin. All rights reserved.
//

import UIKit

protocol InboxRepliesViewDelegate: AnyObject {
    func inboxRepliesViewDidRequestRefresh()
}

final class InboxRepliesView: UIView {
    weak var delegate: InboxRepliesViewDelegate?
    
    private var tableManager: InboxRepliesTableManager?
    
    private let refreshControl = UIRefreshControl()
    
    private lazy var tableView = LemmyTableView(style: .plain, separator: false).then {
        $0.registerClass(ReplyMentionTableCell.self)
        $0.backgroundColor = .clear
        $0.showsVerticalScrollIndicator = false
        $0.refreshControl = self.refreshControl
        self.refreshControl.addTarget(self, action: #selector(refreshControlValueChanged), for: .valueChanged)
    }
            
    private lazy var emptyStateLabel = UILabel().then {
        $0.text = "nodata-replies".localized
        $0.textAlignment = .center
        $0.textColor = .tertiaryLabel
    }
    
    init() {
        super.init(frame: .zero)
        setupView()
        addSubviews()
        makeConstraints()
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
    
    func updateTableViewData(dataSource: InboxRepliesTableManager) {
        if refreshControl.isRefreshing {
            self.refreshControl.endRefreshing()
        }

        self.tableView.isHidden = false
        self.emptyStateLabel.isHidden = true
        self.hideActivityIndicator()
        _ = dataSource.tableView(self.tableView, numberOfRowsInSection: 0)
//            self.emptyStateLabel.isHidden = numberOfRows != 0

        self.tableManager = dataSource
        self.tableView.dataSource = dataSource
        self.tableView.delegate = dataSource
        self.tableView.reloadData()
    }
    
    func deleteAllContent() {
        self.tableManager?.viewModels = []
        self.tableView.reloadData()
    }
    
    func displayNoData() {
        self.emptyStateLabel.isHidden = false
        self.tableView.isHidden = true
        makeConstraints()
    }
    
    func appendNew(data: [LMModels.Views.CommentReplyView]) {
        self.tableManager?.appendNew(posts: data) { newIndexpaths in
            tableView.performBatchUpdates {
                tableView.insertRows(at: newIndexpaths, with: .none)
            }
        }
    }
    
    @objc func refreshControlValueChanged() {
        self.delegate?.inboxRepliesViewDidRequestRefresh()
    }
}

extension InboxRepliesView: ProgrammaticallyViewProtocol {
    func setupView() {
        self.emptyStateLabel.isHidden = true
    }
    
    func addSubviews() {
        self.addSubview(tableView)
        self.addSubview(emptyStateLabel)
    }
    
    func makeConstraints() {
        self.tableView.snp.makeConstraints { make in
            make.top.equalToSuperview()
            make.leading.trailing.equalTo(self.safeAreaLayoutGuide)
            make.bottom.equalTo(self.safeAreaLayoutGuide) // tab bar
        }
        
        self.emptyStateLabel.snp.makeConstraints {
            $0.center.equalTo(self.snp.center)
        }
    }
}
