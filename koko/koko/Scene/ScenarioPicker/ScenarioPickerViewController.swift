//
//  ScenarioPickerViewController.swift
//  koko
//
//  spec.md §5 / AC-1：App 啟動先進入的情境選擇首頁，
//  列出三個情境，點擊後 push 至好友列表頁。
//
//  純程式碼建立 UI，尺寸與顏色一律取自 DesignSystem token。
//

import UIKit

final class ScenarioPickerViewController: UIViewController {

    /// 由外部注入導頁行為，這個畫面不認識目的地。
    private let onSelect: (Scenario) -> Void

    private let scenarios = Scenario.allCases

    private lazy var tableView: UITableView = {
        let tableView = UITableView(frame: .zero, style: .insetGrouped)
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.backgroundColor = AppColor.pageBackground
        tableView.dataSource = self
        tableView.delegate = self
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = Layout.estimatedRowHeight
        tableView.register(ScenarioCell.self, forCellReuseIdentifier: ScenarioCell.reuseIdentifier)
        return tableView
    }()

    private enum Layout {
        static let estimatedRowHeight: CGFloat = 72
    }

    init(onSelect: @escaping (Scenario) -> Void) {
        self.onSelect = onSelect
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("純程式碼建立，不支援 Storyboard／XIB")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        title = "選擇情境"
        navigationItem.largeTitleDisplayMode = .always
        navigationController?.navigationBar.prefersLargeTitles = true

        view.backgroundColor = AppColor.pageBackground
        view.addSubview(tableView)

        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])
    }
}

// MARK: - UITableViewDataSource

extension ScenarioPickerViewController: UITableViewDataSource {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        scenarios.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(
            withIdentifier: ScenarioCell.reuseIdentifier,
            for: indexPath
        )
        (cell as? ScenarioCell)?.configure(with: scenarios[indexPath.row])
        return cell
    }
}

// MARK: - UITableViewDelegate

extension ScenarioPickerViewController: UITableViewDelegate {

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        onSelect(scenarios[indexPath.row])
    }
}

// MARK: - Cell

private final class ScenarioCell: UITableViewCell {

    static let reuseIdentifier = String(describing: ScenarioCell.self)

    private let titleLabel = UILabel()
    private let subtitleLabel = UILabel()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        accessoryType = .disclosureIndicator
        backgroundColor = AppColor.surface

        subtitleLabel.numberOfLines = 0

        let stack = UIStackView(arrangedSubviews: [titleLabel, subtitleLabel])
        stack.translatesAutoresizingMaskIntoConstraints = false
        stack.axis = .vertical
        stack.spacing = Spacing.xs
        contentView.addSubview(stack)

        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: contentView.topAnchor, constant: Spacing.m),
            stack.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -Spacing.m),
            stack.leadingAnchor.constraint(equalTo: contentView.layoutMarginsGuide.leadingAnchor),
            stack.trailingAnchor.constraint(equalTo: contentView.layoutMarginsGuide.trailingAnchor),
        ])
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("純程式碼建立，不支援 Storyboard／XIB")
    }

    func configure(with scenario: Scenario) {
        titleLabel.attributedText = AppText.name.attributedString(scenario.menuTitle)
        subtitleLabel.attributedText = AppText.body
            .withColor(AppColor.textSecondary)
            .attributedString(scenario.menuSubtitle)
    }
}
