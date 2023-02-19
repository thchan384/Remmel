//
//  LMModels+Api+Comment.swift
//  Lemmy-iOS
//
//  Created by uuttff8 on 15.01.2021.
//  Copyright © 2021 Anton Kuzmin. All rights reserved.
//

import Foundation

extension RMModels.Api {
    enum Comment {
        
        struct CreateComment: Codable {
            let content: String
            let parentId: Int?
            let postId: Int
            let formId: String? // An optional front end ID, to tell which is coming back
            let auth: String
            
            enum CodingKeys: String, CodingKey {
                case content
                case parentId = "parent_id"
                case postId = "post_id"
                case formId = "form_id"
                case auth
            }
        }
        
        struct EditComment: Codable {
            let content: String
            let commentId: Int
            let formId: String?
            let auth: String
            
            enum CodingKeys: String, CodingKey {
                case content
                case commentId = "comment_id"
                case formId = "form_id"
                case auth
            }
        }
        
        /**
        * Only the creator can delete the comment.
        */
        struct DeleteComment: Codable {
            let commentId: Int
            let deleted: Bool
            let auth: String
            
            enum CodingKeys: String, CodingKey {
                case commentId = "comment_id"
                case deleted, auth
            }
        }
        
        /**
        * Only a mod or admin can remove the comment.
        */
        struct RemoveComment: Codable {
            let commentId: Int
            let removed: Bool
            let reason: String?
            let auth: String
            
            enum CodingKeys: String, CodingKey {
                case commentId = "comment_id"
                case removed, reason, auth
            }
        }
        
        struct MarkCommentAsRead: Codable {
            let commentId: Int
            let read: Bool
            let auth: String
            
            enum CodingKeys: String, CodingKey {
                case commentId = "comment_id"
                case read, auth
            }
        }
        
        struct SaveComment: Codable {
            let commentId: Int
            let save: Bool
            let auth: String
            
            enum CodingKeys: String, CodingKey {
                case commentId = "comment_id"
                case save, auth
            }
        }
        
        struct CommentResponse: Codable {
            let commentView: RMModels.Views.CommentView
            let recipientIds: [Int]
            let formId: String? // An optional front end ID, to tell which is coming back
            
            enum CodingKeys: String, CodingKey {
                case commentView = "comment_view"
                case recipientIds = "recipient_ids"
                case formId = "form_id"
            }
        }
        
        struct CreateCommentLike: Codable {
            let commentId: Int
            let score: Int
            let auth: String
            
            enum CodingKeys: String, CodingKey {
                case commentId = "comment_id"
                case score
                case auth
            }
        }
        
        /**
        * Comment listing types are `All, Subscribed, Community`
        *
        * `community_name` can only be used for local communities.
        * To get posts for a federated community, pass `community_id` instead.
        */
        struct GetComments: Codable {
            let type: RMModels.Others.ListingType?
            let sort: RMModels.Others.SortType?
            let page: Int?
            let limit: Int?
            let communityId: Int?
            let communityName: String?
            let savedOnly: Bool?
            let auth: String?
            
            enum CodingKeys: String, CodingKey {
                case type = "type_"
                case sort, page, limit, auth
                case communityId = "community_id"
                case communityName = "community_name"
                case savedOnly = "saved_only"
            }
        }
        
        struct GetCommentsResponse: Codable {
            let comments: [RMModels.Views.CommentView]
        }
        
        struct CreateCommentReport: Codable {
            let commentId: Int
            let reason: String
            let auth: String
            
            enum CodingKeys: String, CodingKey {
                case commentId = "comment_id"
                case reason, auth
            }
        }
        
        struct CommentReportResponse: Codable {
            let commentReportView: RMModels.Views.CommentReportView

            enum CodingKeys: String, CodingKey {
                case commentReportView = "comment_report_view"
            }
        }
        
        struct ResolveCommentReport: Codable {
            let reportId: Int
            let resolved: Bool
            let auth: String
            
            enum CodingKeys: String, CodingKey {
                case reportId = "report_id"
                case resolved, auth
            }
        }

        struct ListCommentReports: Codable {
            let page: Int?
            let limit: Int?
            /// if no community is given, it returns reports for all communities moderated by the auth user
            let communityId: Int?
            let unresolvedOnly: Bool?
            let auth: String

            enum CodingKeys: String, CodingKey {
                case page, limit
                case communityId = "community_id"
                case unresolvedOnly = "unresolved_only"
                case auth
            }
        }
        
        struct ListCommentReportsResponse: Codable {
            let comments: [RMModels.Views.CommentReportView]
        }
        
    }
}
