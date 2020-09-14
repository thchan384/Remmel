//
//  FrontPageCoordinator.swift
//  Lemmy-iOS
//
//  Created by uuttff8 on 9/11/20.
//  Copyright © 2020 Anton Kuzmin. All rights reserved.
//

import UIKit

class FrontPageCoordinator : Coordinator {
    var rootViewController: FrontPageViewController
    var childCoordinators: [Coordinator] = []
    
    var navigationController: UINavigationController?

    init(navigationController: UINavigationController?) {
        self.rootViewController = FrontPageViewController()
        self.navigationController = navigationController
    }

    func start() {
        navigationController?.pushViewController(self.rootViewController, animated: true)
    }
}
