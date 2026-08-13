//
//  FriendListViewController.swift
//  koko
//
//  spec.md §6 好友列表頁。
//
//  **依 view state 渲染，不自行推導畫面狀態**（CLAUDE.md architecture rule 3）。
//  這個 VC 不知道「什麼情況算空狀態」「誰是邀請卡片」—— 那些都在 ViewModel。
//
//  三種狀態齊備：A 空狀態（`EmptyStateView`）／B 好友清單／C 含邀請卡片。
//

import Combine
import UIKit

final class FriendListViewController: UIViewController {

    /// 尺寸依 design-spec.md §7。
    private enum Layout {
        static let rowHeight: CGFloat = 60
        static let sectionDividerHeight: CGFloat = 1
    }

    private let viewModel: FriendListViewModel
    private var cancellables = Set<AnyCancellable>()

    private var friends: [Friend] = []
    private var isInvitationSectionExpanded = false

    /// AC-13：搜尋中，畫面已上推到搜尋框置頂。
    private var isSearchPushedUp = false

    /// 底部 TabBar 切到「朋友」以外 —— 那是**另一個分頁**，整頁（含 header 與
    /// 好友／聊天 segment）都換成空白（spec.md §11）。
    private var showsOtherTabPage: Bool {
        tabBarView.selectedTab != .friends
    }

    /// 「聊天」segment —— 仍在同一個分頁裡，**只有 segment 以下的內容區**空白。
    /// header 與 segment 本身必須留著，否則使用者切不回「好友」。
    private var showsChatSegment: Bool {
        tabView.selectedSegment != .friends
    }

    // MARK: Views

    private let topActionBarView = TopActionBarView()
    private let profileHeaderView = ProfileHeaderView()
    private let tabView = FriendChatTabView()
    private let invitationSectionView = InvitationSectionView()
    private let searchBarView = FriendSearchBarView()
    private let tabBarView = AppTabBarView()

    /// 上半部（#FCFCFC）與下半部（白）之間的全寬分隔線。
    /// 它跟著 header 捲動，位置隨邀請卡片區的高度浮動（design-spec §7.1）。
    private let sectionDivider: UIView = {
        let view = UIView()
        view.backgroundColor = AppColor.sectionDivider
        view.translatesAutoresizingMaskIntoConstraints = false
        view.heightAnchor.constraint(equalToConstant: Layout.sectionDividerHeight).isActive = true
        return view
    }()

    /// AC-12 下拉更新。
    private let refreshControl: UIRefreshControl = {
        let control = UIRefreshControl()
        control.tintColor = AppColor.kokoPink
        return control
    }()

    private lazy var tableView: UITableView = {
        let tableView = UITableView(frame: .zero, style: .plain)
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.backgroundColor = AppColor.surface
        tableView.separatorStyle = .none
        tableView.dataSource = self
        tableView.delegate = self
        tableView.rowHeight = Layout.rowHeight
        tableView.keyboardDismissMode = .onDrag
        tableView.refreshControl = refreshControl
        tableView.register(FriendCell.self, forCellReuseIdentifier: FriendCell.reuseIdentifier)
        return tableView
    }()

    /// tableHeaderView 的內容。Auto Layout 算完高度後手動指定 frame。
    ///
    /// **順序照設計稿**：邀請卡片區在好友／聊天 tab 列**之上**（spec.md §6.2 → §6.3）。
    /// 各區塊自己帶背景色與內距，這裡不再補間距。
    private lazy var headerStack: UIStackView = {
        let stack = UIStackView(arrangedSubviews: [
            profileHeaderView, invitationSectionView, tabView, sectionDivider, searchBarView,
        ])
        stack.axis = .vertical
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

    /// 狀態 A（spec.md §6.6）。蓋在 tableView 之上、header 之下。
    private let emptyStateView: EmptyStateView = {
        let view = EmptyStateView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.isHidden = true
        return view
    }()

    /// 空狀態要從 header 底下開始，而 header 高度隨狀態變動，
    /// 由 `sizeTableHeaderToFit()` 一併更新這條約束。
    private lazy var emptyStateTop = emptyStateView.topAnchor.constraint(
        equalTo: tableView.topAnchor
    )

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

        // 上半部底色。下半部的白由 tableView 自己出。
        view.backgroundColor = AppColor.cardBackground

        // 設計稿沒有 navigation bar，頂部就是 TopActionBarView。
        // 藏掉 nav bar 會連帶停用邊緣滑動返回，所以要自己接回 delegate。
        navigationController?.interactivePopGestureRecognizer?.delegate = self

        setUpLayout()
        bindViews()

        viewModel.statePublisher
            .sink { [weak self] state in self?.render(state) }
            .store(in: &cancellables)

        Task { await viewModel.load() }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: animated)
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        // 情境選擇頁還要用 nav bar，離開時還原。
        navigationController?.setNavigationBarHidden(false, animated: animated)
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        sizeTableHeaderToFit()
    }

    // MARK: - Setup

    private func setUpLayout() {
        view.addSubview(topActionBarView)
        view.addSubview(tableView)
        view.addSubview(emptyStateView)
        view.addSubview(blankPageView)
        view.addSubview(tabBarView)
        topActionBarView.translatesAutoresizingMaskIntoConstraints = false
        tabBarView.translatesAutoresizingMaskIntoConstraints = false

        tableView.tableHeaderView = headerStack

        NSLayoutConstraint.activate([
            // 頂部功能列不捲動，固定在 safe area 上緣。
            topActionBarView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            topActionBarView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            topActionBarView.trailingAnchor.constraint(equalTo: view.trailingAnchor),

            tableView.topAnchor.constraint(equalTo: topActionBarView.bottomAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: tabBarView.topAnchor),

            // 延伸到螢幕最底，底色才會蓋滿 home indicator 那一段
            // （設計稿的 iPhone 8 沒有 home indicator，切在 safe area 會露出一條空白）。
            // 圖示列停在 safe area，由 AppTabBarView 內部處理。
            tabBarView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tabBarView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tabBarView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            blankPageView.topAnchor.constraint(equalTo: topActionBarView.bottomAnchor),
            blankPageView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            blankPageView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            blankPageView.bottomAnchor.constraint(equalTo: tabBarView.topAnchor),

            emptyStateTop,
            emptyStateView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            emptyStateView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            emptyStateView.bottomAnchor.constraint(equalTo: tabBarView.topAnchor),
        ])
    }

    private func bindViews() {
        refreshControl.addTarget(self, action: #selector(handleRefresh), for: .valueChanged)

        searchBarView.onKeywordChange = { [weak self] keyword in
            self?.viewModel.search(keyword)
        }

        searchBarView.onBeginEditing = { [weak self] in
            self?.pushUpToSearchBar()
        }

        searchBarView.onCancel = { [weak self] in
            self?.restoreFromSearch()
        }

        invitationSectionView.onToggle = { [weak self] in
            guard let self else { return }
            self.isInvitationSectionExpanded.toggle()
            // 重新以目前 state 渲染，讓收合狀態一併套用。
            self.render(self.viewModel.state)
            self.animateHeaderResize()
        }

        invitationSectionView.onRespond = { [weak self] fid in
            self?.viewModel.respondToInvitation(fid: fid)
        }

        // 「朋友」以外的分頁只呈現空白，不影響已載入的資料。
        tabBarView.onSelect = { [weak self] _ in
            self?.leaveSearch()
        }

        tabView.onSelect = { [weak self] _ in
            self?.leaveSearch()
        }
    }

    // MARK: - 加分項目

    /// AC-12：下拉更新。`refresh()` 刻意不切回 `.loading`（不閃骨架），
    /// 所以要自己在載入結束時停掉轉圈。
    @objc private func handleRefresh() {
        Task {
            await viewModel.refresh()
            refreshControl.endRefreshing()
        }
    }

    /// AC-13：點搜尋框時把畫面上推，讓搜尋框貼到頂部功能列下方。
    ///
    /// 搜尋框在 tableHeaderView 裡，所以「上推」就是把 content offset 捲到
    /// 搜尋框在 header 內的 y。內容不夠長時捲不到那麼遠，先補底部 inset。
    ///
    /// （AC-13 原文寫「置頂至 navigationBar 下方」，但設計稿沒有 navigation bar，
    /// 現在頂部是 `TopActionBarView`，語意相同。）
    private func pushUpToSearchBar() {
        isSearchPushedUp = true
        updateSearchInset()
        tableView.setContentOffset(CGPoint(x: 0, y: searchBarTopOffset), animated: true)
    }

    private func restoreFromSearch() {
        isSearchPushedUp = false
        tableView.setContentOffset(.zero, animated: true)
    }

    /// 切分頁／切 segment 時一併離開搜尋狀態，否則畫面會停在上推的位置。
    private func leaveSearch() {
        searchBarView.resignSearchFocus()
        restoreFromSearch()
        render(viewModel.state)
    }

    private var searchBarTopOffset: CGFloat {
        searchBarView.frame.minY
    }

    /// 補足底部 inset，讓 content offset 捲得到 `searchBarTopOffset`。
    /// 搜尋會讓清單變短，所以每次 render 都要重算。
    private func updateSearchInset() {
        guard isSearchPushedUp else { return }

        tableView.layoutIfNeeded()
        let overflow = searchBarTopOffset + tableView.bounds.height - tableView.contentSize.height
        tableView.contentInset.bottom = max(0, overflow)
    }

    /// AC-14：邀請卡片區展開／收合。卡片本身不會新增或移除（見 `InvitationSectionView`），
    /// 這裡只負責把 header 的新高度做成動畫。
    private func animateHeaderResize() {
        headerStack.setNeedsLayout()

        UIView.animate(withDuration: 0.25, delay: 0, options: .curveEaseInOut) {
            self.headerStack.layoutIfNeeded()
            self.sizeTableHeaderToFit()
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
        emptyStateTop.constant = height
    }

    // MARK: - Render

    private func render(_ state: FriendListViewState) {
        profileHeaderView.configure(with: state.user)
        tabView.setInvitationCount(state.content.invitationBadgeCount)
        tabView.setChatBadgeHidden(state.content.isEmptyState)

        // 另一個分頁：整頁蓋掉。資料不動，切回「朋友」即恢復。
        blankPageView.isHidden = !showsOtherTabPage

        // 「聊天」：不蓋整頁，改成把 segment 以下的內容清空 ——
        // 邀請區與搜尋框收合、清單 0 列，header 與 segment 自然留在原位。
        guard !showsOtherTabPage, !showsChatSegment else {
            friends = []
            invitationSectionView.isHidden = true
            searchBarView.isHidden = true
            emptyStateView.isHidden = true
            tableView.reloadData()
            view.setNeedsLayout()
            return
        }

        switch state.content {
        case .loading:
            friends = []
            invitationSectionView.isHidden = true
            searchBarView.isHidden = true
            emptyStateView.isHidden = true

        case .empty:
            friends = []
            invitationSectionView.isHidden = true
            searchBarView.isHidden = true
            emptyStateView.isHidden = false

        case .loaded(let invites, let friends):
            self.friends = friends
            searchBarView.isHidden = false
            emptyStateView.isHidden = true
            invitationSectionView.configure(with: invites, isExpanded: isInvitationSectionExpanded)

        case .failed(let error):
            friends = []
            invitationSectionView.isHidden = true
            searchBarView.isHidden = true
            emptyStateView.isHidden = true
            presentFailure(error)
        }

        tableView.reloadData()
        view.setNeedsLayout()
        // 搜尋會讓清單變短，上推需要的底部 inset 跟著變。
        updateSearchInset()
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

    /// 上推用的額外 inset 要等捲回頂端**之後**才收，
    /// 在捲動途中收會讓內容跳一下。
    func scrollViewDidEndScrollingAnimation(_ scrollView: UIScrollView) {
        guard !isSearchPushedUp else { return }
        tableView.contentInset.bottom = 0
    }
}

// MARK: - UIGestureRecognizerDelegate

extension FriendListViewController: UIGestureRecognizerDelegate {

    /// 藏掉 navigation bar 後，UIKit 會停用邊緣滑動返回。接回 delegate 讓它繼續有效，
    /// 但只在真的有上一頁時才允許 —— 在根畫面觸發會讓 navigation stack 卡住。
    func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        guard gestureRecognizer === navigationController?.interactivePopGestureRecognizer else {
            return true
        }
        return (navigationController?.viewControllers.count ?? 0) > 1
    }
}
