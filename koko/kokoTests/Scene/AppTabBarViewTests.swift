//
//  AppTabBarViewTests.swift
//  kokoTests
//
//  底部 TabBar 素材接線的防線。
//
//  背景（2026-08-12 回報的 bug）：Zeplin 的檔名與分頁名稱對不起來 ——
//  `icTabbarHomeOff` 不是「錢錢」而是中央的 KO 按鈕，「錢錢」其實是
//  `icTabbarProductsOff`。接錯不會編譯失敗，畫面上只會出現一團灰色色塊
//  （KO 圖被 template rendering 壓成實心），肉眼要比對設計稿才看得出來。
//
//  另外每個分頁素材都已內含分頁名稱文字，再加 UILabel 會變成兩份文字。
//

import XCTest
@testable import koko

@MainActor
final class AppTabBarViewTests: XCTestCase {

    /// 每個分頁必須各自對到不同素材。接錯或漏接會讓兩格長得一樣。
    func test_eachTab_mapsToDistinctAsset() async {
        let assets = AppTabBarView.Tab.allCases.map(\.image)
        XCTAssertEqual(
            Set(assets).count,
            AppTabBarView.Tab.allCases.count,
            "有分頁共用同一張素材：\(assets.map(\.rawValue))"
        )
    }

    /// 中央 KO 按鈕的素材**只有**中央那格能用。
    /// 「錢錢」原本就是接到這張圖，畫面上變成一團灰色色塊。
    func test_centerKOAsset_isUsedOnlyByCenterTab() async {
        for tab in AppTabBarView.Tab.standardTabs {
            XCTAssertNotEqual(
                tab.image,
                .tabCenterKOOff,
                "\(tab.title) 用到中央 KO 按鈕的素材（\(AppImage.tabCenterKOOff.rawValue)）"
            )
        }
        XCTAssertEqual(AppTabBarView.Tab.ko.image, .tabCenterKOOff)
    }

    /// `standardTabs` 必須是「除了 ko 以外的全部」。漏掉新分頁會讓上面幾條檢查失效。
    func test_standardTabs_areAllCasesExceptCenter() async {
        XCTAssertEqual(
            AppTabBarView.Tab.standardTabs.count,
            AppTabBarView.Tab.allCases.count - 1
        )
        XCTAssertFalse(AppTabBarView.Tab.standardTabs.contains(.ko))
    }

    /// 一般分頁的素材是 icon + 文字的合成圖，比例明顯高於寬（78:128）。
    /// 若哪天素材被換成純 icon（接近正方形），這裡會失敗，
    /// 提醒必須同時把分頁名稱的 UILabel 加回來。
    /// KO 是橫的（含 TabBar 凹口造型），不適用。
    func test_tabAssets_areIconWithLabelComposites() async {
        for tab in AppTabBarView.Tab.standardTabs {
            let size = tab.image.image.size
            XCTAssertLessThan(
                size.width / size.height,
                0.8,
                "\(tab.title) 的素材比例不像 icon+文字合成圖（\(size)）"
            )
        }
    }

    /// 分頁名稱只能來自素材。TabBar 裡不該有任何寫著分頁名稱的 UILabel。
    func test_tabBar_doesNotRenderTabTitlesAsLabels() async {
        let tabBar = AppTabBarView()
        let titles = Set(AppTabBarView.Tab.allCases.map(\.title))

        for label in tabBar.recursiveLabels() {
            let text = label.text ?? label.attributedText?.string ?? ""
            XCTAssertFalse(
                titles.contains(text),
                "分頁名稱「\(text)」被畫成 UILabel —— 素材裡已經有這段文字，會重複"
            )
        }
    }

    /// 中央 KO 按鈕是淺灰圓形的原色素材。若被改成 template rendering，
    /// 圓底與 KO 字會一起被 tint 壓成實心色塊 —— 正是第一版畫面上那一團灰。
    /// 它是 `AppTabBarView` 的直接 subview，分頁圖示則包在 UIStackView 裡。
    func test_centerKOButton_isNotTemplateRendered() async throws {
        let ko = try XCTUnwrap(centerKOButton(in: AppTabBarView()))
        XCTAssertNotEqual(
            ko.image?.renderingMode,
            .alwaysTemplate,
            "KO 按鈕被 template rendering 上色，圓底會變成實心色塊"
        )
    }

    /// KO 是可切換的分頁（2026-08-12 需求變更），必須收得到觸控。
    /// 它比 TabBar 高，凸出去那截落在 bounds 之外 —— 少了 `point(inside:)` 就點不到。
    func test_centerKOButton_isTappable() async throws {
        let tabBar = laidOutTabBar()
        let ko = try XCTUnwrap(centerKOButton(in: tabBar))

        XCTAssertTrue(ko.isUserInteractionEnabled, "KO 按鈕不可點")
        XCTAssertFalse(ko.gestureRecognizers?.isEmpty ?? true, "KO 按鈕沒有掛觸控")

        // 圓的上半截高過 TabBar，要靠 point(inside:) 才收得到。
        let koTop = CGPoint(x: ko.frame.midX, y: ko.frame.minY + 2)
        XCTAssertTrue(tabBar.point(inside: koTop, with: nil), "KO 凸出去那截收不到觸控")
    }

    /// ViewController 靠 `selectedTab != .friends` 決定是否顯示空白頁，
    /// 所以選了 KO 之後狀態必須真的離開 `.friends`。
    func test_selectingKO_leavesFriendsTab() async {
        let tabBar = laidOutTabBar()
        XCTAssertEqual(tabBar.selectedTab, .friends, "預設應停在朋友")

        tabBar.select(.ko)

        XCTAssertEqual(tabBar.selectedTab, .ko)
        XCTAssertNotEqual(tabBar.selectedTab, .friends)
    }

    // MARK: -

    private func laidOutTabBar() -> AppTabBarView {
        let tabBar = AppTabBarView()
        tabBar.frame = CGRect(x: 0, y: 0, width: 375, height: 55)
        tabBar.layoutIfNeeded()
        return tabBar
    }

    /// KO 是唯一的直接 UIImageView subview（分頁圖示都包在 UIStackView 裡）。
    private func centerKOButton(in tabBar: AppTabBarView) -> UIImageView? {
        let candidates = tabBar.subviews.compactMap { $0 as? UIImageView }
        XCTAssertEqual(candidates.count, 1, "找不到中央 KO 按鈕（或多了別的 UIImageView）")
        return candidates.first
    }
}

private extension UIView {

    func recursiveLabels() -> [UILabel] {
        subviews.flatMap { view -> [UILabel] in
            let nested = view.recursiveLabels()
            return (view as? UILabel).map { [$0] + nested } ?? nested
        }
    }
}
