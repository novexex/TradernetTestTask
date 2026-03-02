//
//  SceneDelegate.swift
//  TradernetTestTask
//
//  Created by Artur Ilyasov on 02.03.2026.
//

import UIKit

class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    var window: UIWindow?
    private var coordinator: QuotesCoordinator?
    private var socketService: TradernetSocketService?
    private var viewModel: QuotesViewModel?

    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        guard let windowScene = scene as? UIWindowScene else { return }

        let window = UIWindow(windowScene: windowScene)
        let navigationController = UINavigationController()

        // Composition Root: assemble the dependency graph
        let imageLoader = ImageLoader()
        let socketService = TradernetSocketService()
        let viewModel = QuotesViewModel(service: socketService)
        let coordinator = QuotesCoordinator(navigationController: navigationController, imageLoader: imageLoader, viewModel: viewModel)
        let quotesVC = QuotesViewController(viewModel: viewModel, imageLoader: imageLoader, coordinator: coordinator)

        navigationController.viewControllers = [quotesVC]
        window.backgroundColor = Colors.background
        window.rootViewController = navigationController
        window.makeKeyAndVisible()
        self.window = window
        self.coordinator = coordinator
        self.socketService = socketService
        self.viewModel = viewModel
    }

    func sceneDidEnterBackground(_ scene: UIScene) {
        viewModel?.stop()
    }

    func sceneWillEnterForeground(_ scene: UIScene) {
        viewModel?.start()
    }
}
