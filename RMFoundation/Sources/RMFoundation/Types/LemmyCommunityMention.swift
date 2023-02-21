//
//  LemmyCommunityMention.swift
//  Lemmy-iOS
//
//  Created by uuttff8 on 13.01.2021.
//  Copyright © 2021 Anton Kuzmin. All rights reserved.
//

import Foundation

public class LemmyCommunityMention {
    
    public let absoluteName: String
    public var absoluteId: Int?
    
    public init(name: String, id: Int? = nil) {
        if name.hasPrefix("!") {
            var retString = name
            retString.removeFirst()
            
            self.absoluteName = retString
            return
        }
        
        if name.hasPrefix("/c/") {
            var retString = name
            retString.removeFirst(3)
                        
            self.absoluteName = retString
            return
        }
        
        self.absoluteId = id
        self.absoluteName = name
    }
    
    public init?(url: URL) {
        
        if let community = parseCommunity(passedUrl: url) {
            self.absoluteName = community
            return
        }

        return nil
    }
}

private func parseCommunity(passedUrl: URL) -> String? {
    
    // community hostname MUST match current instance
    guard let host = passedUrl.host,
          !host.contains(LemmyShareData.shared.authedInstanceUrl.rawHost)
    else { return nil }
    
    if passedUrl.absoluteString.hasPrefix("!") {
        var retString = passedUrl.absoluteString
        retString.removeFirst()
        
        return retString
    }
    
    if passedUrl.absoluteString.hasPrefix("/c/") {
        var retString = passedUrl.absoluteString
        retString.removeFirst(3)
        
        return retString
    }
    
    if passedUrl.relativePath.contains("/c/") {
        var retString = passedUrl.relativePath
        retString.removeFirst(3)
        
        return retString
    }
    
    return nil
}
