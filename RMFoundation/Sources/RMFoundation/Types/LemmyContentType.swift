//
//  LemmyContentType.swift
//  Lemmy-iOS
//
//  Created by uuttff8 on 16.01.2021.
//  Copyright © 2021 Anton Kuzmin. All rights reserved.
//

import Foundation

public enum LemmyContentType: String, Codable, CaseIterable {
    case posts = "Posts"
    case comments = "Comments"

    public var label: String {
        switch self {
        case .posts: return "content-posts".localized
        case .comments: return "content-comments".localized
        }
    }

    public var index: Int {
        switch self {
        case .posts: return 0
        case .comments: return 1
        }
    }
}
