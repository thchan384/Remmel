//
//  CommunitiesAssembly.swift
//  Lemmy-iOS
//
//  Created by uuttff8 on 16.12.2020.
//  Copyright © 2020 Anton Kuzmin. All rights reserved.
//

import UIKit
import RMServices
import RMNetworking

final class CommunitiesPreviewAssembly: Assembly {
    
    func makeModule() -> CommunitiesPreviewViewController {
        let viewModel = CommunitiesPreviewViewModel(wsClient: ApiManager.chainedWsCLient)
        let vc = CommunitiesPreviewViewController(
            viewModel: viewModel,
            followService: CommunityFollowService(userAccountService: UserAccountService())
        )
        viewModel.viewContoller = vc
        
        return vc
    }
}
