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

    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        guard let windowScene = scene as? UIWindowScene else { return }

        let window = UIWindow(windowScene: windowScene)
        let navigationController = UINavigationController()

        // Composition Root: assemble the dependency graph
        let imageLoader = ImageLoader.shared
        let socketService = TradernetSocketService()
        let viewModel = QuotesViewModel(service: socketService)
        let coordinator = QuotesCoordinator(navigationController: navigationController, imageLoader: imageLoader)
        let quotesVC = QuotesViewController(viewModel: viewModel, imageLoader: imageLoader, coordinator: coordinator)

        navigationController.viewControllers = [quotesVC]
        window.backgroundColor = Colors.background
        window.rootViewController = navigationController
        window.makeKeyAndVisible()
        self.window = window
        self.coordinator = coordinator
    }
}
