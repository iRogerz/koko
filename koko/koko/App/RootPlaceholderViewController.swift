//
//  RootPlaceholderViewController.swift
//  koko
//
//  暫時的 root view controller，用來驗證「無 Storyboard」啟動流程可運作。
//  PEV Step「情境選擇頁」完成後，本檔連同 SceneDelegate 內的引用一併刪除，
//  改為 ScenarioPickerViewController（spec.md §5）。
//

import UIKit

final class RootPlaceholderViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        title = "KOKO"

        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = "情境選擇頁尚未實作"
        label.textColor = .secondaryLabel
        view.addSubview(label)

        NSLayoutConstraint.activate([
            label.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            label.centerYAnchor.constraint(equalTo: view.centerYAnchor),
        ])
    }
}
