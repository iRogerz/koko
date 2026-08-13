//
//  EmptyStateViewTests.swift
//  kokoTests
//
//  狀態 A（spec.md §6.6 / design-spec §7.9）的版面防線。
//
//  空狀態只有在「合併後好友總數為 0」時才看得到，跑起來不容易注意到它壞了，
//  所以把幾個一眼看不出、但錯了就明顯不對的點釘住。
//

import XCTest
@testable import koko

@MainActor
final class EmptyStateViewTests: XCTestCase {

    private let width: CGFloat = 375

    /// 綠色按鈕 192×40、膠囊圓角。
    func test_addFriendButton_matchesDesignSize() async throws {
        let view = laidOutView()
        let button = try XCTUnwrap(gradientButton(in: view))

        XCTAssertEqual(button.bounds.width, 192, accuracy: 0.5)
        XCTAssertEqual(button.bounds.height, 40, accuracy: 0.5)

        let gradient = try XCTUnwrap(gradientLayer(in: button))
        XCTAssertEqual(gradient.cornerRadius, 20, accuracy: 0.5, "膠囊圓角應為高度的一半")
        XCTAssertTrue(gradient.masksToBounds, "漸層沒被圓角裁掉，四角會是綠色方塊")
    }

    /// 漸層是**水平**的（左深右淺）。設成垂直的話畫面上不明顯，
    /// 但和設計稿完全不同 —— 實測 y 方向幾乎不變色。
    func test_buttonGradient_isHorizontalAndDarkToLight() async throws {
        let view = laidOutView()
        let button = try XCTUnwrap(gradientButton(in: view))
        let gradient = try XCTUnwrap(gradientLayer(in: button))

        XCTAssertEqual(gradient.startPoint.y, gradient.endPoint.y, accuracy: 0.001, "漸層不是水平的")
        XCTAssertLessThan(gradient.startPoint.x, gradient.endPoint.x)

        let colors = try XCTUnwrap(gradient.colors as? [CGColor])
        XCTAssertEqual(colors.count, 2)
        XCTAssertTrue(colors[0] == AppColor.greenDark.cgColor, "左端應是深綠")
        XCTAssertTrue(colors[1] == AppColor.greenLight.cgColor, "右端應是淺綠")
    }

    /// 陰影不能被圓角裁掉 —— 漸層那層要 masksToBounds，陰影就得掛在外層。
    func test_buttonShadow_isNotClipped() async throws {
        let view = laidOutView()
        let button = try XCTUnwrap(gradientButton(in: view))

        XCTAssertFalse(button.layer.masksToBounds, "外層開了 masksToBounds，陰影會被裁掉")
        XCTAssertGreaterThan(button.layer.shadowOpacity, 0, "沒有陰影")
    }

    /// 底部連結是「灰字 + 粉紅加底線」兩段，不是整串同色。
    func test_bottomLink_hasUnderlinedPinkAction() async throws {
        let view = laidOutView()
        let text = try XCTUnwrap(bottomLinkText(in: view))

        var colors: [UIColor] = []
        var underlinedText = ""

        text.enumerateAttributes(in: NSRange(location: 0, length: text.length)) { attributes, range, _ in
            if let color = attributes[.foregroundColor] as? UIColor {
                colors.append(color)
            }
            if attributes[.underlineStyle] != nil {
                underlinedText += text.attributedSubstring(from: range).string
            }
        }

        XCTAssertTrue(colors.contains(AppColor.textSecondary), "前半段應為次要文字色")
        XCTAssertTrue(colors.contains(AppColor.kokoPink), "「設定 KOKO ID」應為粉紅")
        XCTAssertEqual(underlinedText, "設定 KOKO ID", "只有「設定 KOKO ID」該有底線")
    }

    /// 連結靠底、按鈕在它之上 —— 中間的留白負責吸收機型高度差。
    func test_bottomLink_sitsBelowTheButton() async throws {
        let view = laidOutView()
        let button = try XCTUnwrap(gradientButton(in: view))
        let link = try XCTUnwrap(bottomLinkLabel(in: view))

        XCTAssertGreaterThan(link.frame.minY, button.frame.maxY, "連結跑到按鈕上面了")
        XCTAssertEqual(view.bounds.maxY - link.frame.maxY, 18, accuracy: 1, "連結距底部應為 18")
    }

    // MARK: -

    private func laidOutView(height: CGFloat = 500) -> EmptyStateView {
        let view = EmptyStateView()
        view.frame = CGRect(x: 0, y: 0, width: width, height: height)
        view.layoutIfNeeded()
        return view
    }

    /// 按鈕是唯一的 UIControl。
    private func gradientButton(in view: EmptyStateView) -> UIControl? {
        view.subviews.compactMap { $0 as? UIControl }.first
    }

    private func gradientLayer(in button: UIControl) -> CAGradientLayer? {
        button.subviews.compactMap { $0.layer as? CAGradientLayer }.first
    }

    /// 標題／副標／連結都是 UILabel，連結是**位置最低**的那一個。
    private func bottomLinkLabel(in view: EmptyStateView) -> UILabel? {
        view.subviews
            .compactMap { $0 as? UILabel }
            .max { $0.frame.minY < $1.frame.minY }
    }

    private func bottomLinkText(in view: EmptyStateView) -> NSAttributedString? {
        bottomLinkLabel(in: view)?.attributedText
    }
}
