//
//  SceneDelegate.swift
//  koko
//
//  Created by 曾子庭 on 2026/8/7.
//

import UIKit

class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    var window: UIWindow?

    func scene(
        _ scene: UIScene,
        willConnectTo session: UISceneSession,
        options connectionOptions: UIScene.ConnectionOptions
    ) {
        guard let windowScene = scene as? UIWindowScene else { return }

        // 純程式碼建立 window，無 Storyboard。
        let window = UIWindow(windowScene: windowScene)
        window.rootViewController = UINavigationController(rootViewController: RootPlaceholderViewController())
        window.makeKeyAndVisible()
        self.window = window
    }
}
