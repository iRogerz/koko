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
        window.rootViewController = makeRootViewController()
        window.makeKeyAndVisible()
        self.window = window
    }

    /// spec.md §5：起始頁是情境選擇頁，點擊後 push 至好友列表頁。
    private func makeRootViewController() -> UIViewController {
        let navigationController = UINavigationController()

        let picker = ScenarioPickerViewController { [weak navigationController] scenario in
            // TODO: Step 6 換成 FriendListViewController。
            navigationController?.pushViewController(
                FriendListProbeViewController(scenario: scenario),
                animated: true
            )
        }

        navigationController.viewControllers = [picker]
        return navigationController
    }
}
