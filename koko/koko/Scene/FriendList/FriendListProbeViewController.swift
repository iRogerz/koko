//
//  FriendListProbeViewController.swift
//  koko
//
//  ⚠️ 暫時畫面，Step 6 完成 FriendListViewController 後**整檔刪除**。
//
//  作用：讓情境選擇頁點下去有實際的目的地，同時打真實網路跑完整條資料鏈
//  （ScenarioPicker → ViewModel → Repository → APIClient → URLSessionHTTPClient）。
//
//  單元測試一律注入 StubHTTPClient，所以 `URLSessionHTTPClient` 本身沒有被覆蓋到
//  （見 sdd-progress Step 3 決策）。這個畫面是那一段唯一的實際驗證。
//

import Combine
import UIKit

final class FriendListProbeViewController: UIViewController {

    private let scenario: Scenario
    private let viewModel: FriendListViewModel
    private var cancellables = Set<AnyCancellable>()

    private let textView: UITextView = {
        let textView = UITextView()
        textView.translatesAutoresizingMaskIntoConstraints = false
        textView.isEditable = false
        textView.backgroundColor = AppColor.pageBackground
        textView.font = .monospacedSystemFont(ofSize: 13, weight: .regular)
        textView.textColor = AppColor.textPrimary
        return textView
    }()

    init(scenario: Scenario) {
        self.scenario = scenario
        self.viewModel = FriendListViewModel(
            scenario: scenario,
            repository: FriendRepository(
                apiClient: APIClient(httpClient: URLSessionHTTPClient())
            )
        )
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("純程式碼建立，不支援 Storyboard／XIB")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        title = scenario.menuTitle
        view.backgroundColor = AppColor.pageBackground
        view.addSubview(textView)

        NSLayoutConstraint.activate([
            textView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: Spacing.l),
            textView.leadingAnchor.constraint(equalTo: view.layoutMarginsGuide.leadingAnchor),
            textView.trailingAnchor.constraint(equalTo: view.layoutMarginsGuide.trailingAnchor),
            textView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
        ])

        viewModel.statePublisher
            .sink { [weak self] state in self?.render(state) }
            .store(in: &cancellables)

        Task { await viewModel.load() }
    }

    private func render(_ state: FriendListViewState) {
        var lines: [String] = []

        lines.append("情境：\(scenario.menuTitle)")
        lines.append("使用者：\(state.user.map { "\($0.name) / KOKO ID: \($0.kokoID ?? "（未設定）")" } ?? "載入中")")
        lines.append("")

        switch state.content {
        case .loading:
            lines.append("載入中…")

        case .empty:
            lines.append("狀態 A —— 無好友")

        case .loaded(let invites, let friends):
            lines.append(invites.isEmpty ? "狀態 B —— 好友無邀請" : "狀態 C —— 好友含邀請")
            lines.append("")
            lines.append("邀請卡片（\(invites.count)）")
            lines.append(contentsOf: invites.map { "  ・\($0.name)　fid=\($0.fid)" })
            lines.append("")
            lines.append("好友清單（\(friends.count)）")
            lines.append(contentsOf: friends.map { friend in
                let star = friend.isTop ? "★ " : "  "
                let tag = friend.status == .inviting ? "　[邀請中]" : ""
                return "  \(star)\(friend.name)　fid=\(friend.fid)　\(friend.updateDate.rawValue)\(tag)"
            })

        case .failed(let error):
            lines.append("載入失敗")
            lines.append(String(describing: error))
        }

        textView.text = lines.joined(separator: "\n")
    }
}
