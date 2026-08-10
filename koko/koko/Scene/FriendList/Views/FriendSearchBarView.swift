//
//  FriendSearchBarView.swift
//  koko
//
//  spec.md §6.4 / design-spec §4.3：
//  底色 `#EFEFEF` 膠囊、左側放大鏡、placeholder「想轉一筆給誰呢？」，
//  右側是**獨立於搜尋框之外**的加好友按鈕。
//
//  只負責把輸入往外拋，篩選邏輯在 ViewModel（`FriendSearch` 純函式）。
//

import UIKit

final class FriendSearchBarView: UIView {

    private enum Layout {
        static let fieldHeight: CGFloat = 36
        static let iconSize: CGFloat = 16
        static let addFriendSize: CGFloat = 24
    }

    private enum Text {
        static let placeholder = "想轉一筆給誰呢？"
    }

    /// 關鍵字變動時呼叫。
    var onKeywordChange: ((String) -> Void)?

    /// 使用者點進搜尋框（AC-13 的觸發點，動畫在 Step 7）。
    var onBeginEditing: (() -> Void)?

    private let field: UITextField = {
        let field = UITextField()
        field.translatesAutoresizingMaskIntoConstraints = false
        field.attributedPlaceholder = AppText.tabTitle.attributedString(Text.placeholder)
        field.defaultTextAttributes = AppText.tabTitle
            .withColor(AppColor.textPrimary)
            .attributes()
        field.borderStyle = .none
        field.clearButtonMode = .whileEditing
        field.returnKeyType = .search
        field.autocorrectionType = .no
        return field
    }()

    private let container: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = AppColor.searchBarBackground
        view.layer.cornerRadius = Layout.fieldHeight / 2
        return view
    }()

    private let magnifier: UIImageView = {
        let imageView = UIImageView(image: UIImage(systemName: "magnifyingglass"))
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.tintColor = AppColor.textSecondary
        imageView.contentMode = .scaleAspectFit
        return imageView
    }()

    private let addFriendButton: UIButton = {
        let button = UIButton(type: .system)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setImage(AppImage.addFriend.image.withRenderingMode(.alwaysOriginal), for: .normal)
        button.imageView?.contentMode = .scaleAspectFit
        return button
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = AppColor.surface
        directionalLayoutMargins = .init(top: 0, leading: Spacing.l, bottom: 0, trailing: Spacing.l)

        addSubview(container)
        addSubview(addFriendButton)
        container.addSubview(magnifier)
        container.addSubview(field)

        field.addTarget(self, action: #selector(editingChanged), for: .editingChanged)
        field.addTarget(self, action: #selector(editingBegan), for: .editingDidBegin)

        NSLayoutConstraint.activate([
            container.leadingAnchor.constraint(equalTo: layoutMarginsGuide.leadingAnchor),
            container.topAnchor.constraint(equalTo: topAnchor, constant: Spacing.s),
            container.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -Spacing.s),
            container.heightAnchor.constraint(equalToConstant: Layout.fieldHeight),

            addFriendButton.leadingAnchor.constraint(equalTo: container.trailingAnchor, constant: Spacing.m),
            addFriendButton.trailingAnchor.constraint(equalTo: layoutMarginsGuide.trailingAnchor),
            addFriendButton.centerYAnchor.constraint(equalTo: container.centerYAnchor),
            addFriendButton.widthAnchor.constraint(equalToConstant: Layout.addFriendSize),
            addFriendButton.heightAnchor.constraint(equalToConstant: Layout.addFriendSize),

            magnifier.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: Spacing.m),
            magnifier.centerYAnchor.constraint(equalTo: container.centerYAnchor),
            magnifier.widthAnchor.constraint(equalToConstant: Layout.iconSize),
            magnifier.heightAnchor.constraint(equalToConstant: Layout.iconSize),

            field.leadingAnchor.constraint(equalTo: magnifier.trailingAnchor, constant: Spacing.s),
            field.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -Spacing.m),
            field.topAnchor.constraint(equalTo: container.topAnchor),
            field.bottomAnchor.constraint(equalTo: container.bottomAnchor),
        ])
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("純程式碼建立，不支援 Storyboard／XIB")
    }

    func resignSearchFocus() {
        field.resignFirstResponder()
    }

    @objc private func editingChanged() {
        onKeywordChange?(field.text ?? "")
    }

    @objc private func editingBegan() {
        onBeginEditing?()
    }
}
