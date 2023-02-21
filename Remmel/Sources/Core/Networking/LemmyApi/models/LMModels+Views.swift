//
//  LMModels+Views.swift
//  Lemmy-iOS
//
//  Created by uuttff8 on 15.01.2021.
//  Copyright © 2021 Anton Kuzmin. All rights reserved.
//

import Foundation

extension LMModels {
    enum Views {
        
        struct PersonViewSafe: Codable {
            let person: LMModels.Source.PersonSafe
            let counts: LMModels.Aggregates.PersonAggregates
        }
        
        struct PersonMentionView: Identifiable, Codable, VoteGettable {
            
            var id: Int {
                comment.id
            }
            
            let personMention: LMModels.Source.PersonMention
            var comment: LMModels.Source.Comment
            let creator: LMModels.Source.PersonSafe
            let post: LMModels.Source.Post
            let community: LMModels.Source.CommunitySafe
            let recipient: LMModels.Source.PersonSafe
            let counts: LMModels.Aggregates.CommentAggregates
            let creatorBannedFromCommunity: Bool
            let subscribed: LMModels.Others.SubscribedType
            let saved: Bool
            let creatorBlocked: Bool
            let myVote: Int?
            
            enum CodingKeys: String, CodingKey {
                case personMention = "person_mention"
                case comment, creator, post, community
                case recipient, counts
                case creatorBannedFromCommunity = "creator_banned_from_community"
                case subscribed, saved
                case creatorBlocked = "creator_blocked"
                case myVote = "my_vote"
            }
        }
        
        struct LocalUserSettingsView: Codable {
            let localUser: LMModels.Source.LocalUserSettings
            let person: LMModels.Source.PersonSafe
            let counts: LMModels.Aggregates.PersonAggregates
            
            enum CodingKeys: String, CodingKey {
                case localUser = "local_user"
                case person, counts
            }
        }
        
        struct SiteView: Codable {
            let site: LMModels.Source.Site
            let localSite: LMModels.Source.LocalSite
            let localSiteRateLimit: LMModels.Source.LocalSiteRateLimit
            let taglines: [LMModels.Source.Tagline]?
            let counts: LMModels.Aggregates.SiteAggregates
            
            enum CodingKeys: String, CodingKey {
                case site
                case localSite = "local_site"
                case localSiteRateLimit = "local_site_rate_limit"
                case taglines, counts
            }
        }
        
        struct PrivateMessageView: Codable {
            let privateMessage: LMModels.Source.PrivateMessage
            let creator: LMModels.Source.PersonSafe
            let recipient: LMModels.Source.PersonSafe
            
            enum CodingKeys: String, CodingKey {
                case privateMessage = "private_message"
                case creator, recipient
            }
        }
        
        struct PostView: Identifiable, Codable, VoteGettable, Hashable, Equatable {
            // for uniquness in uitableviewdiffabledatasource
            let uuid = UUID()
            
            var id: Int {
                post.id
            }
            
            let post: LMModels.Source.Post
            let creator: LMModels.Source.PersonSafe
            let community: LMModels.Source.CommunitySafe
            let creatorBannedFromCommunity: Bool
            var counts: LMModels.Aggregates.PostAggregates
            let subscribed: LMModels.Others.SubscribedType
            let saved: Bool
            let read: Bool
            let creatorBlocked: Bool
            var myVote: Int?
            let unreadComments: Int
            
            enum CodingKeys: String, CodingKey {
                case creator, post, community, counts
                case creatorBannedFromCommunity = "creator_banned_from_community"
                case subscribed, saved, read
                case creatorBlocked = "creator_blocked"
                case myVote = "my_vote"
                case unreadComments = "unread_comments"
            }
        }
        
        struct PostReportView: Codable {
            let postReport: LMModels.Source.PostReport
            let post: LMModels.Source.Post
            let community: LMModels.Source.CommunitySafe
            let creator: LMModels.Source.PersonSafe
            let postCreator: LMModels.Source.PersonSafe
            let creatorBannedFromCommunity: Bool
            let myVote: Int?
            let counts: LMModels.Aggregates.PostAggregates
            let resolver: LMModels.Source.PersonSafe?
            
            enum CodingKeys: String, CodingKey {
                case postReport = "post_report"
                case postCreator = "post_creator"
                case post, community, creator
                case creatorBannedFromCommunity = "creator_banned_from_community"
                case myVote = "my_vote"
                case counts
                case resolver
            }
        }
        
        struct CommentView: Hashable, Equatable, Identifiable, VoteGettable, Codable {
            // for uniquness in uitableviewdiffabledatasource
            let uuid = UUID()
            
            var id: Int {
                comment.id
            }
            
            let comment: LMModels.Source.Comment
            let creator: LMModels.Source.PersonSafe
            let recipient: LMModels.Source.PersonSafe?
            let post: LMModels.Source.Post
            let community: LMModels.Source.CommunitySafe
            var counts: LMModels.Aggregates.CommentAggregates
            let creatorBannedFromCommunity: Bool
            let subscribed: LMModels.Others.SubscribedType
            let saved: Bool
            let creatorBlocked: Bool
            var myVote: Int?
            
            enum CodingKeys: String, CodingKey {
                case comment, creator, recipient, post
                case community, counts
                case creatorBannedFromCommunity = "creator_banned_from_community"
                case subscribed, saved
                case creatorBlocked = "creator_blocked"
                case myVote = "my_vote"
            }
        }
        
            struct CommentReplyView: Codable, Identifiable {
                var id: Int {
                    commentReply.id
                }
                
                let commentReply: LMModels.Source.CommentReply
                let comment: LMModels.Source.Comment
                let creator: LMModels.Source.PersonSafe
                let post: LMModels.Source.Post
                let community: LMModels.Source.CommunitySafe
                let recipient: LMModels.Source.PersonSafe
                let counts: LMModels.Aggregates.CommentAggregates
                let creatorBannedFromCommunity: Bool
                let subscribed: LMModels.Others.SubscribedType
                let saved: Bool
                let creatorBlocked: Bool
                let myVote: Int?
                
                enum CodingKeys: String, CodingKey {
                    case commentReply = "comment_reply"
                    case comment, creator, post
                    case community, recipient, counts
                    case creatorBannedFromCommunity = "creator_banned_from_community"
                    case subscribed, saved
                    case creatorBlocked = "creator_blocked"
                    case myVote = "my_vote"
                }
            }

        
        struct CommentReportView: Codable {
            let commentReport: LMModels.Source.CommentReport
            let comment: LMModels.Source.Comment
            let post: LMModels.Source.Post
            let community: LMModels.Source.CommunitySafe
            let creator: LMModels.Source.PersonSafe
            let commentCreator: LMModels.Source.PersonSafe
            let counts: LMModels.Aggregates.CommentAggregates
            let creatorBannedFromCommunity: Bool
            let myVote: Int?
            let resolver: LMModels.Source.PersonSafe?
            
            enum CodingKeys: String, CodingKey {
                case commentReport = "comment_report"
                case commentCreator = "comment_creator"
                case counts
                case post, comment, community, creator
                case creatorBannedFromCommunity = "creator_banned_from_community"
                case myVote = "my_vote"
                case resolver
            }
        }
        
        struct ModAddCommunityView: Codable {
            let modAddCommunity: LMModels.Source.ModAddCommunity
            let moderator: LMModels.Source.PersonSafe?
            let community: LMModels.Source.CommunitySafe
            let moddedPerson: LMModels.Source.PersonSafe
            
            enum CodingKeys: String, CodingKey {
                case modAddCommunity = "mod_add_community"
                case moddedPerson = "modded_person"
                case moderator, community
            }
        }
        
        struct ModTransferCommunityView: Codable {
            let modTransferCommunity: LMModels.Source.ModTransferCommunity
            let moderator: LMModels.Source.PersonSafe?
            let community: LMModels.Source.CommunitySafe
            let moddedPerson: LMModels.Source.PersonSafe
            
            enum CodingKeys: String, CodingKey {
                case modTransferCommunity = "mod_transfer_community"
                case moderator, community
                case moddedPerson = "modded_person"
            }
       }
        
        struct ModAddView: Codable {
            let modAdd: LMModels.Source.ModAdd
            let moderator: LMModels.Source.PersonSafe?
            let moddedPerson: LMModels.Source.PersonSafe
            
            enum CodingKeys: String, CodingKey {
                case modAdd = "mod_add"
                case moddedPerson = "modded_person"
                case moderator
            }
        }
        
        struct ModBanFromCommunityView: Codable {
            let modBanFromCommunity: LMModels.Source.ModBanFromCommunity
            let moderator: LMModels.Source.PersonSafe?
            let community: LMModels.Source.CommunitySafe
            let bannedPerson: LMModels.Source.PersonSafe
            
            enum CodingKeys: String, CodingKey {
                case modBanFromCommunity = "mod_ban_from_community"
                case bannedPerson = "banned_person"
                case community, moderator
            }
        }
        
        struct ModBanView: Codable {
            let modBan: LMModels.Source.ModBan
            let moderator: LMModels.Source.PersonSafe?
            let bannedPerson: LMModels.Source.PersonSafe
            
            enum CodingKeys: String, CodingKey {
                case modBan = "modBan"
                case bannedPerson = "banned_person"
                case moderator
            }
        }
        
        struct ModLockPostView: Codable {
            let modLockPost: LMModels.Source.ModLockPost
            let moderator: LMModels.Source.PersonSafe?
            let post: LMModels.Source.Post
            let community: LMModels.Source.CommunitySafe
            
            enum CodingKeys: String, CodingKey {
                case modLockPost = "mod_lock_post"
                case community, post, moderator
            }
        }
        
        struct ModRemoveCommentView: Codable {
            let modRemoveComment: LMModels.Source.ModRemoveComment
            let moderator: LMModels.Source.PersonSafe?
            let comment: LMModels.Source.Comment
            let commenter: LMModels.Source.PersonSafe
            let post: LMModels.Source.Post
            let community: LMModels.Source.CommunitySafe
            
            enum CodingKeys: String, CodingKey {
                case modRemoveComment = "mod_remove_comment"
                case moderator, comment, commenter, post, community
            }
        }
        
        struct ModRemoveCommunityView: Codable {
            let modRemoveCommunity: LMModels.Source.ModRemoveCommunity
            let moderator: LMModels.Source.PersonSafe?
            let community: LMModels.Source.CommunitySafe
            
            enum CodingKeys: String, CodingKey {
                case modRemoveCommunity = "mod_remove_community"
                case community, moderator
            }
        }
        
        struct ModRemovePostView: Codable {
            let modRemovePost: LMModels.Source.ModRemovePost
            let moderator: LMModels.Source.PersonSafe?
            let post: LMModels.Source.Post
            let community: LMModels.Source.CommunitySafe
            
            enum CodingKeys: String, CodingKey {
                case modRemovePost = "mod_remove_post"
                case community, moderator, post
            }
        }
        
        struct ModFeaturePostView: Codable {
            let modFeaturePost: LMModels.Source.ModFeaturePost
            let moderator: LMModels.Source.PersonSafe?
            let post: LMModels.Source.Post
            let community: LMModels.Source.CommunitySafe
            
            enum CodingKeys: String, CodingKey {
                case modFeaturePost = "mod_feature_post"
                case community, moderator, post
            }
        }
        
        struct CommunityFollowerView: Codable {
            let community: LMModels.Source.CommunitySafe
            let follower: LMModels.Source.PersonSafe
        }
        
        struct CommunityBlockView: Codable {
            let person: LMModels.Source.PersonSafe
            let community: LMModels.Source.CommunitySafe
       }
        
        struct CommunityModeratorView: Codable {
            let community: LMModels.Source.CommunitySafe
            let moderator: LMModels.Source.PersonSafe
        }
        
        struct CommunityPersonBanView: Codable {
            let community: LMModels.Source.CommunitySafe
            let person: LMModels.Source.PersonSafe
        }
        
        struct PersonBlockView: Codable {
            let person: LMModels.Source.PersonSafe
            let target: LMModels.Source.PersonSafe
       }
        
        struct CommunityView: Identifiable, Codable {
            
            var id: Int {
                community.id
            }
            
            let community: LMModels.Source.CommunitySafe
            let subscribed: LMModels.Others.SubscribedType
            let blocked: Bool
            let counts: LMModels.Aggregates.CommunityAggregates
        }
        
        struct RegistrationApplicationView: Codable {
            let registration_application: LMModels.Source.RegistrationApplication
            let creator_local_user: LMModels.Source.LocalUserSettings
            let creator: LMModels.Source.PersonSafe
            let admin: LMModels.Source.PersonSafe?
       }
        
        struct PrivateMessageReportView: Codable {
            let privateMessageReport: LMModels.Source.PrivateMessageReport
            let privateMessage: LMModels.Source.PrivateMessage
            let privateMessageCreator: LMModels.Source.PersonSafe
            let creator: LMModels.Source.PersonSafe
            let resolver: LMModels.Source.PersonSafe?
            
            enum CodingKeys: String, CodingKey {
                case privateMessageReport = "private_message_report"
                case privateMessage = "private_message"
                case privateMessageCreator = "private_message_creator"
                case creator, resolver
            }
        }
    }
}

// legacy:
extension LMModels.Views.PostView {
    func getUrlDomain() -> String? {
        let type = PostType.getPostType(from: self)
        
        guard type != .none, let url = post.url else {
            return nil
        }

        return URL(string: url)?.host
    }
}
