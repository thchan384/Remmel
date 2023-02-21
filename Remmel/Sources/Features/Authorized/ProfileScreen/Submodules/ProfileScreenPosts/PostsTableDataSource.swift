//
//  PostsTableDataSource.swift
//  Lemmy-iOS
//
//  Created by uuttff8 on 16.11.2020.
//  Copyright © 2020 Anton Kuzmin. All rights reserved.
//

import UIKit
import RMModels

protocol PostsTableDataSourceDelegate: PostContentPreviewTableCellDelegate {
    func tableDidRequestPagination(_ tableDataSource: PostsTableDataSource)
}

final class PostsTableDataSource: NSObject {
    weak var delegate: PostsTableDataSourceDelegate?
    
    var viewModels: [RMModels.Views.PostView]
    
    init(viewModels: [RMModels.Views.PostView] = []) {
        self.viewModels = viewModels
        super.init()
    }
    
    // MARK: - Public API
    
    func update(viewModel: RMModels.Views.PostView) {
        if let index = self.viewModels.firstIndex(where: { $0.post.id == viewModel.post.id }) {
            self.viewModels[index] = viewModel
        }
    }
    
    func appendNew(posts: [RMModels.Views.PostView], completion: (_ indexPaths: [IndexPath]) -> Void) {
        let startIndex = viewModels.count - posts.count
        let endIndex = startIndex + posts.count
        
        let newIndexpaths = Array(startIndex ..< endIndex)
            .map { IndexPath(row: $0, section: 0) }
        
        completion(newIndexpaths)
    }
    
    func deleteAll() {
        viewModels = []
    }
}

// MARK: - UITableViewDataSource -
extension PostsTableDataSource: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.viewModels.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell: PostContentPreviewTableCell = tableView.cell(forRowAt: indexPath)
        cell.updateConstraintsIfNeeded()
        
        cell.postContentView.delegate = delegate
        
        let viewModel = self.viewModels[indexPath.row]
        cell.bind(with: viewModel, isInsideCommunity: false)
        
        return cell
    }
}

extension PostsTableDataSource: UITableViewDelegate {
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        if indexPath.row == tableView.numberOfRows(inSection: indexPath.section) - 5,
           tableView.numberOfSections == 1 {
            self.delegate?.tableDidRequestPagination(self)
        }
    }
}
