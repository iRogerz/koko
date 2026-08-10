//
//  FriendListViewController.swift
//  koko
//
//  spec.md §6 好友列表頁。
//
//  **依 view state 渲染，不自行推導畫面狀態**（CLAUDE.md architecture rule 3）。
//  這個 VC 不知道「什麼情況算空狀態」「誰是邀請卡片」—— 那些都在 ViewModel。
//
//  Step 6a 範圍：狀態 B／C。狀態 A（空狀態）於 Step 6b 實作。
//

import Combine
import UIKit

final class FriendListViewController: UIViewController {

    private enum Layout {
        static let estimatedRowHeight: CGFloat = 68
    }

    private let viewModel: FriendListViewModel
    private var cancellables = Set<AnyCancellable>()

    private var friends: [Friend] = []
    private var isInvitationSectionExpanded = false

    /// 「朋友」以外的分頁、以及「聊天」segment 都只呈現空白（spec.md §11）。
    private var showsBlankPage: Bool {
        tabBarView.selectedTab != .friends || tabView.selectedSegment != .friends
    }

    // MARK: Views

    private let profileHeaderView = ProfileHeaderView()
    private let tabView = FriendChatTabView()
    private let invitationSectionView = InvitationSectionView()
    private let searchBarView = FriendSearchBarView()
    private let tabBarView = AppTabBarView()

    private lazy var tableView: UITableView = {
        let tableView = UITableView(frame: .zero, style: .plain)
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.backgroundColor = AppColor.surface
        tableView.separatorStyle = .none
        tableView.dataSource = self
        tableView.delegate = self
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = Layout.estimatedRowHeight
        tableView.keyboardDismissMode = .onDrag
        tableView.register(FriendCell.self, forCellReuseIdentifier: FriendCell.reuseIdentifier)
        return tableView
    }()

    /// tableHeaderView 的內容。Auto Layout 算完高度後手動指定 frame。
    private lazy var headerStack: UIStackView = {
        let stack = UIStackView(arrangedSubviews: [
            profileHeaderView, tabView, invitationSectionView, searchBarView,
        ])
        stack.axis = .vertical
        stack.setCustomSpacing(Spacing.m, after: tabView)
        stack.setCustomSpacing(Spacing.m, after: invitationSectionView)
        return stack
    }()

    /// 「朋友」以外的分頁內容。依需求只需空白。
    private let blankPageView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = AppColor.pageBackground
        view.isHidden = true
        return view
    }()

    /// Step 6b 會換成完整的空狀態畫面（插圖 + 綠色漸層按鈕）。
    private let temporaryEmptyLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.attributedText = AppText.body
            .withColor(AppColor.textSecondary)
            .attributedString("（空狀態畫面於 Step 6b 實作）", alignment: .center)
        label.textAlignment = .center
        label.isHidden = true
        return label
    }()

    // MARK: -

    init(viewModel: FriendListViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("純程式碼建立，不支援 Storyboard／XIB")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = AppColor.surface
        navigationItem.largeTitleDisplayMode = .never

        setUpLayout()
        bindViews()

        viewModel.statePublisher
            .sink { [weak self] state in self?.render(state) }
            .store(in: &cancellables)

        Task { await viewModel.load() }
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        sizeTableHeaderToFit()
    }

    // MARK: - Setup

    private func setUpLayout() {
        view.addSubview(tableView)
        view.addSubview(blankPageView)
        view.addSubview(tabBarView)
        view.addSubview(temporaryEmptyLabel)
        tabBarView.translatesAutoresizingMaskIntoConstraints = false

        tableView.tableHeaderView = headerStack

        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: tabBarView.topAnchor),

            tabBarView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tabBarView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tabBarView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),

            blankPageView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            blankPageView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            blankPageView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            blankPageView.bottomAnchor.constraint(equalTo: tabBarView.topAnchor),

            temporaryEmptyLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            temporaryEmptyLabel.centerYAnchor.constraint(equalTo: view.centerYAnchor),
        ])
    }

    private func bindViews() {
        searchBarView.onKeywordChange = { [weak self] keyword in
            self?.viewModel.search(keyword)
        }

        invitationSectionView.onToggle = { [weak self] in
            guard let self else { return }
            self.isInvitationSectionExpanded.toggle()
            // 重新以目前 state 渲染，讓收合狀態一併套用。
            self.render(self.viewModel.state)
        }

        invitationSectionView.onRespond = { [weak self] fid in
            self?.viewModel.respondToInvitation(fid: fid)
        }

        // 「朋友」以外的分頁只呈現空白，不影響已載入的資料。
        tabBarView.onSelect = { [weak self] _ in
            guard let self else { return }
            self.searchBarView.resignSearchFocus()
            self.render(self.viewModel.state)
        }

        tabView.onSelect = { [weak self] _ in
            guard let self else { return }
            self.searchBarView.resignSearchFocus()
            self.render(self.viewModel.state)
        }
    }

    /// tableHeaderView 不吃 Auto Layout，必須自行算高度後指定 frame。
    private func sizeTableHeaderToFit() {
        guard let header = tableView.tableHeaderView else { return }

        let targetWidth = tableView.bounds.width
        guard targetWidth > 0 else { return }

        header.frame.size.width = targetWidth
        let height = header.systemLayoutSizeFitting(
            CGSize(width: targetWidth, height: UIView.layoutFittingCompressedSize.height),
            withHorizontalFittingPriority: .required,
            verticalFittingPriority: .fittingSizeLevel
        ).height

        guard header.frame.height != height else { return }
        header.frame.size.height = height
        tableView.tableHeaderView = header
    }

    // MARK: - Render

    private func render(_ state: FriendListViewState) {
        profileHeaderView.configure(with: state.user)
        tabView.setInvitationCount(state.content.invitationBadgeCount)

        // 空白分頁蓋住內容區，但 header／tab／TabBar 仍在，切回來即恢復。
        blankPageView.isHidden = !showsBlankPage
        tabView.isHidden = tabBarView.selectedTab != .friends

        guard !showsBlankPage else {
            temporaryEmptyLabel.isHidden = true
            return
        }

        switch state.content {
        case .loading:
            friends = []
            invitationSectionView.isHidden = true
            searchBarView.isHidden = true
            temporaryEmptyLabel.isHidden = true

        case .empty:
            // Step 6b 換成完整的空狀態畫面。
            friends = []
            invitationSectionView.isHidden = true
            searchBarView.isHidden = true
            temporaryEmptyLabel.isHidden = false

        case .loaded(let invites, let friends):
            self.friends = friends
            searchBarView.isHidden = false
            temporaryEmptyLabel.isHidden = true
            invitationSectionView.configure(with: invites, isExpanded: isInvitationSectionExpanded)

        case .failed(let error):
            friends = []
            invitationSectionView.isHidden = true
            searchBarView.isHidden = true
            temporaryEmptyLabel.isHidden = true
            presentFailure(error)
        }

        tableView.reloadData()
        view.setNeedsLayout()
    }

    /// spec §10 O-4：顯示錯誤提示 + 重試，不自動重試。
    private func presentFailure(_ error: Error) {
        guard presentedViewController == nil else { return }

        let alert = UIAlertController(
            title: "載入失敗",
            message: error.localizedDescription,
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "重試", style: .default) { [weak self] _ in
            Task { await self?.viewModel.load() }
        })
        alert.addAction(UIAlertAction(title: "取消", style: .cancel))
        present(alert, animated: true)
    }
}

// MARK: - UITableViewDataSource

extension FriendListViewController: UITableViewDataSource {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        friends.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(
            withIdentifier: FriendCell.reuseIdentifier,
            for: indexPath
        )
        (cell as? FriendCell)?.configure(with: friends[indexPath.row])
        return cell
    }
}

// MARK: - UITableViewDelegate

extension FriendListViewController: UITableViewDelegate {

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
    }
}
