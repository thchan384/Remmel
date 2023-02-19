//
//  LemmyCheckLogin.swift
//  Lemmy-iOS
//
//  Created by uuttff8 on 10/12/20.
//  Copyright © 2020 Anton Kuzmin. All rights reserved.
//

import UIKit
import RMFoundation

func ContinueIfLogined(
    on viewController: UIViewController,
    coordinator: BaseCoordinator,
    doAction: () -> Void,
    elseAction: (() -> Void)? = nil
) {

    func auth(authMethod: LemmyAuthMethod) {

        let loginvc = LoginViewController(authMethod: authMethod)
        let navController = StyledNavigationController(rootViewController: loginvc)

        viewController.present(navController, animated: true)
    }

    func goToInstances() {
        LemmyShareData.shared.loginData.logout()

        if !LemmyShareData.shared.isLoggedIn {
            coordinator.childCoordinators.removeAll()

            NotificationCenter.default.post(name: .didLogin, object: nil)

            let myCoordinator = InstancesCoordinator(router: Router(navigationController: StyledNavigationController()))
            myCoordinator.start()
            coordinator.childCoordinators.append(myCoordinator)
            myCoordinator.router.setRoot(myCoordinator, isAnimated: true)

            guard let navigationController = myCoordinator.router.navigationController else {
                return
            }

            UIApplication.shared.windows.first?.replaceRootViewControllerWith(navigationController, animated: true)
        } else {
            fatalError("Unexpexted error, must not be happen")
        }
    }

    if LemmyShareData.shared.isLoggedIn {
        doAction()
    } else {
        elseAction?()
        UIAlertController.showLoginOrRegisterAlert(
            on: viewController,
            onLogin: {
                auth(authMethod: .auth)
            }, onRegister: {
                auth(authMethod: .register)
            }, onInstances: {
                goToInstances()
            })
    }
}
