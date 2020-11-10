//
//  ProfileScreenViewController.swift
//  Lemmy-iOS
//
//  Created by uuttff8 on 06.11.2020.
//  Copyright © 2020 Anton Kuzmin. All rights reserved.
//

import UIKit
import Pageboy

protocol ProfileScreenScrollablePageViewProtocol: AnyObject {
    var scrollViewDelegate: UIScrollViewDelegate? { get set }
    var contentInsets: UIEdgeInsets { get set }
    var contentOffset: CGPoint { get set }
    var contentInsetAdjustmentBehavior: UIScrollView.ContentInsetAdjustmentBehavior { get set }
}

protocol ProfileScreenViewControllerProtocol: AnyObject {
    func displayProfile(response: ProfileScreenDataFlow.ProfileLoad.ViewModel)
    func displayNotBlockingActivityIndicator(response: ProfileScreenDataFlow.ShowingActivityIndicator.Response)
}

class ProfileScreenViewController: UIViewController {
    private static let topBarAlphaStatusBarThreshold = 0.85
    
    private let viewModel: ProfileScreenViewModelProtocol

    private var availableTabs: [ProfileScreenDataFlow.Tab] = [.posts, .comments, .about]
    private lazy var pageViewController = PageboyViewController()
    
    // Due to lazy initializing we should know actual values to update inset/offset of new scrollview
    private var lastKnownScrollOffset: CGFloat = 0
    private var lastKnownHeaderHeight: CGFloat = 0
    
    // Element is nil when view controller was not initialized yet
    private var submodulesControllers: [UIViewController?] = []
    
    private lazy var profileScreenView = self.view as! ProfileScreenViewController.View
    lazy var styledNavigationController = self.navigationController as? StyledNavigationController
    
    private var storedViewModel: ProfileScreenHeaderView.ViewData?
    
    init(viewModel: ProfileScreenViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }
    
    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
        
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.submodulesControllers = Array(repeating: nil, count: availableTabs.count)
        
        self.addChild(self.pageViewController)
        self.pageViewController.dataSource = self
        self.pageViewController.delegate = self
        
        styledNavigationController?.removeBackButtonTitleForTopController()
        
        self.automaticallyAdjustsScrollViewInsets = false
        
        viewModel.doProfileFetch()
    }
    
    override func loadView() {
        let statusBarHeight = UIApplication.shared.statusBarFrame.height
        let navigationBarHeight = self.navigationController?.navigationBar.frame.height ?? 0

        let appearance = ProfileScreenViewController.View.Appearance(
            headerTopOffset: statusBarHeight + navigationBarHeight
        )

        let view = ProfileScreenViewController.View(frame: UIScreen.main.bounds,
                                                    pageControllerView: pageViewController.view,
                                                    tabsTitles: self.availableTabs.map { $0.title },
                                                    scrollDelegate: self,
                                                    appearance: appearance)
        view.delegate = self
        
        self.view = view
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)

        self.view.performBlockIfAppearanceChanged(from: previousTraitCollection) {
            // Update status bar style.
            self.updateContentOffset(scrollOffset: self.lastKnownScrollOffset)
        }
    }
    
    private func loadSubmoduleIfNeeded(at index: Int) {
        guard self.submodulesControllers[index] == nil else {
            return
        }

        guard let tab = self.availableTabs[safe: index] else {
            return
        }

        var moduleInput: ProfileScreenSubmoduleProtocol?
        let controller: UIViewController
        switch tab {
        case .posts:
            let assembly = ProfileScreenPostsAssembly()
            controller = assembly.makeModule()
            moduleInput = assembly.moduleInput
        case .comments:
            controller = UIViewController()
//            let assembly = CourseInfoTabSyllabusAssembly(
//                output: self.interactor as? CourseInfoTabSyllabusOutputProtocol
//            )
//            controller = assembly.makeModule()
//            moduleInput = assembly.moduleInput
        case .about:
            controller = UIViewController()
//            let assembly = CourseInfoTabReviewsAssembly()
//            controller = assembly.makeModule()
//            moduleInput = assembly.moduleInput
        }

        self.submodulesControllers[index] = controller

        if let submodule = moduleInput {
            self.viewModel.doSubmodulesRegistration(request: .init(submodules: [index: submodule]))
        }
    }
    
    // Update content inset (to make header visible)
    private func updateContentInset(headerHeight: CGFloat) {
        // Update contentInset for each page
        for viewController in self.submodulesControllers {
            guard let viewController = viewController else {
                continue
            }

            let view = viewController.view as? ProfileScreenScrollablePageViewProtocol

            if let view = view {
                view.contentInsets = UIEdgeInsets(
                    top: headerHeight,
                    left: view.contentInsets.left,
                    bottom: view.contentInsets.bottom,
                    right: view.contentInsets.right
                )
                view.scrollViewDelegate = self
            }

            viewController.view.setNeedsLayout()
            viewController.view.layoutIfNeeded()

            view?.contentInsetAdjustmentBehavior = .never
        }
    }
    
    private func updateTopBar(alpha: CGFloat) {
        self.view.performBlockUsingViewTraitCollection {
            self.styledNavigationController?.changeBackgroundColor(
                StyledNavigationController.Appearance.backgroundColor.withAlphaComponent(alpha),
                sender: self
            )

            let transitionColor = ColorTransitionHelper.makeTransitionColor(
                from: .white,
                to: StyledNavigationController.Appearance.tintColor,
                transitionProgress: alpha
            )
            self.styledNavigationController?.changeTintColor(transitionColor, sender: self)
            self.styledNavigationController?.changeTextColor(
                StyledNavigationController.Appearance.tintColor.withAlphaComponent(alpha),
                sender: self
            )

            let statusBarStyle: UIStatusBarStyle = {
                if alpha > CGFloat(ProfileScreenViewController.topBarAlphaStatusBarThreshold) {
                    return self.view.isDarkInterfaceStyle ? .lightContent : .dark
                } else {
                    return .lightContent
                }
            }()

            self.styledNavigationController?.changeStatusBarStyle(statusBarStyle, sender: self)
        }
    }
    
    // Update content offset (to update appearance and offset on each tab)
    private func updateContentOffset(scrollOffset: CGFloat) {
        
        let navigationBarHeight = self.navigationController?.navigationBar.bounds.height
        let statusBarHeight = min(
            UIApplication.shared.statusBarFrame.size.width,
            UIApplication.shared.statusBarFrame.size.height
        )
        let topPadding = (navigationBarHeight ?? 0) + statusBarHeight

        let offsetWithHeader = scrollOffset
            + profileScreenView.headerHeight
            + profileScreenView.appearance.segmentedControlHeight
        let headerHeight = profileScreenView.headerHeight - topPadding

        let scrollingProgress = max(0, min(1, offsetWithHeader / headerHeight))
        self.updateTopBar(alpha: scrollingProgress)

        // Pin segmented control
        let scrollViewOffset = min(offsetWithHeader, headerHeight)
        
        profileScreenView.updateScroll(offset: scrollViewOffset)

        // Arrange page views contentOffset
        let offsetWithHiddenHeader = -(topPadding + profileScreenView.appearance.segmentedControlHeight)
        self.arrangePagesScrollOffset(
            topOffsetOfCurrentTab: scrollOffset,
            maxTopOffset: offsetWithHiddenHeader
        )
    }
    
    private func arrangePagesScrollOffset(topOffsetOfCurrentTab: CGFloat, maxTopOffset: CGFloat) {
        for viewController in self.submodulesControllers {
            guard let view = viewController?.view as? ProfileScreenScrollablePageViewProtocol else {
                continue
            }

            var topOffset = view.contentOffset.y

            // Scrolling down
            if topOffset != topOffsetOfCurrentTab && topOffset <= maxTopOffset {
                topOffset = min(topOffsetOfCurrentTab, maxTopOffset)
            }

            // Scrolling up
            if topOffset > maxTopOffset && topOffsetOfCurrentTab <= maxTopOffset {
                topOffset = min(topOffsetOfCurrentTab, maxTopOffset)
            }

            view.contentOffset = CGPoint(
                x: view.contentOffset.x,
                y: topOffset
            )
        }
    }
    
}

extension ProfileScreenViewController: PageboyViewControllerDataSource, PageboyViewControllerDelegate {
    func numberOfViewControllers(in pageboyViewController: PageboyViewController) -> Int {
        availableTabs.count
    }
    
    func viewController(
        for pageboyViewController: PageboyViewController,
        at index: PageboyViewController.PageIndex
    ) -> UIViewController? {
        self.loadSubmoduleIfNeeded(at: index)
        self.updateContentOffset(scrollOffset: self.lastKnownScrollOffset)
        self.updateContentInset(headerHeight: self.lastKnownHeaderHeight)
        return self.submodulesControllers[index]
    }
    
    func defaultPage(for pageboyViewController: PageboyViewController) -> PageboyViewController.Page? {
        .at(index: 0)
    }
        
    func pageboyViewController(
        _ pageboyViewController: PageboyViewController,
        didScrollToPageAt index: PageboyViewController.PageIndex,
        direction: PageboyViewController.NavigationDirection,
        animated: Bool
    ) {
        self.profileScreenView.updateCurrentPageIndex(index)
        self.viewModel.doSubmoduleControllerAppearanceUpdate(request: .init(submoduleIndex: index))
    }

    func pageboyViewController(
        _ pageboyViewController: PageboyViewController,
        willScrollToPageAt index: PageboyViewController.PageIndex,
        direction: PageboyViewController.NavigationDirection,
        animated: Bool
    ) { }

    func pageboyViewController(
        _ pageboyViewController: PageboyViewController,
        didScrollTo position: CGPoint,
        direction: PageboyViewController.NavigationDirection,
        animated: Bool
    ) { }

    func pageboyViewController(
        _ pageboyViewController: PageboyViewController,
        didReloadWith currentViewController: UIViewController,
        currentPageIndex: PageboyViewController.PageIndex
    ) { }
}

extension ProfileScreenViewController: UIScrollViewDelegate {
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        print(scrollView.contentOffset.y)
    }
}

extension ProfileScreenViewController: ProfileScreenViewControllerProtocol {
    func displayProfile(response: ProfileScreenDataFlow.ProfileLoad.ViewModel) {
        guard case let .result(data) = response.state else { return }
        
        self.storedViewModel = data
        profileScreenView.configure(viewData: data)
    }
    
    func displayNotBlockingActivityIndicator(response: ProfileScreenDataFlow.ShowingActivityIndicator.Response) {
        response.shouldDismiss ? self.profileScreenView.hideLoading() : self.profileScreenView.showLoading()
    }
}

extension ProfileScreenViewController: ProfileScreenViewDelegate {
    func numberOfPages(in courseInfoView: ProfileScreenViewController.View) -> Int {
        self.submodulesControllers.count
    }
    
    func profileView(_ profileView: View, didRequestScrollToPage index: Int) {
        self.pageViewController.scrollToPage(.at(index: index), animated: true)
    }

    func profileViewView(_ profileView: View, didReportNewHeaderHeight height: CGFloat) {
        self.lastKnownHeaderHeight = height
        self.updateContentInset(headerHeight: self.lastKnownHeaderHeight)
    }
}

extension ProfileScreenViewController: StyledNavigationControllerPresentable {
    var navigationBarAppearanceOnFirstPresentation: StyledNavigationController.NavigationBarAppearanceState {
        .init(
            shadowViewAlpha: 0.0,
            backgroundColor: StyledNavigationController.Appearance.backgroundColor.withAlphaComponent(0.0),
            statusBarColor: StyledNavigationController.Appearance.statusBarColor.withAlphaComponent(0.0),
            textColor: StyledNavigationController.Appearance.tintColor.withAlphaComponent(0.0),
            tintColor: .white,
            statusBarStyle: .lightContent
        )
    }
}
