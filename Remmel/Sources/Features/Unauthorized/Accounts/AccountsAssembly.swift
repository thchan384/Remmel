//
//  AccountsAssembly.swift
//  Lemmy-iOS
//
//  Created by Komolbek Ibragimov on 24/12/2020.
//  Copyright © 2020 Anton Kuzmin. All rights reserved.
//

import UIKit
import RMFoundation
import RMNetworking
import RMServices

final class AccountsAssembly: Assembly {
    
    private let instance: Instance
    
    init(
        instance: Instance
    ) {
        self.instance = instance
    }
    
    func makeModule() -> AccountsViewController {
        let viewModel = AccountsViewModel(
            instance: self.instance,
            shareData: LemmyShareData.shared,
            accountsPersistenceService: AccountsPersistenceService()
        )
        let vc = AccountsViewController(viewModel: viewModel)
        
        viewModel.viewController = vc
        
        return vc
    }
}
