//
//  CreatePostCoordinator.swift
//  Lemmy-iOS
//
//  Created by uuttff8 on 20.10.2020.
//  Copyright © 2020 Anton Kuzmin. All rights reserved.
//

import UIKit

class CreatePostCoordinator: Coordinator {
    var rootViewController: CreatePostScreenViewController
    var childCoordinators: [Coordinator] = []

    var navigationController: UINavigationController?

    init(navigationController: UINavigationController?) {
        let assembly = CreatePostAssembly()
        self.rootViewController = assembly.makeModule()
        self.navigationController = navigationController

        self.navigationController?.setViewControllers([rootViewController], animated: true)
    }

    func start() {
        rootViewController.coordinator = self
        navigationController?.presentationController?.delegate = rootViewController
    }

    func goToChoosingCommunity(
        choosedCommunity: @escaping ((LemmyModel.CommunityView) -> Void)
    ) {
        let assembly = ChooseCommunityAssembly()
        assembly.onCommunitySelected = choosedCommunity
        navigationController?.pushViewController(assembly.makeModule(), animated: true)
    }

    func goToPost(post: LemmyModel.PostView) {
        rootViewController.dismiss(animated: true, completion: nil)

        if let presentingVc = rootViewController.presentingViewController as? LemmyTabBarController {
            presentingVc.coordinator?.goToPost(post: post)
        }
    }
}
