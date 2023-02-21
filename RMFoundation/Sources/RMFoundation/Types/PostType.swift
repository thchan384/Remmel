//
//  PostType.swift
//  Lemmy-iOS
//
//  Created by uuttff8 on 16.01.2021.
//  Copyright © 2021 Anton Kuzmin. All rights reserved.
//

import Foundation
import RMModels

enum PostType {
    case image
    case video
    case `default`
    case none
    
    static func getPostType(from postView: RMModels.Views.PostView) -> PostType {
        guard let url = postView.post.url, let str = URL(string: url)?.absoluteString else {
            return .none
        }

        if str.hasSuffix("jpg")
            || str.hasSuffix(".jpeg")
            || str.hasSuffix(".png")
            || str.hasSuffix(".gif")
            || str.hasSuffix(".webp")
            || str.hasSuffix(".bmp")
            || str.hasSuffix(".wbpm") {
            return .image
        }
        
        return .default
    }
}
