//
//  AppColor.swift
//  koko
//
//  色票 token，取自 `docs/design-spec.md` §1。
//  ViewController 內不得寫死顏色（CLAUDE.md architecture rule 6）。
//
//  ⚠️ Zeplin 的命名有重複：`hot pink`、`very light pink`、`transferMoney`
//  各有兩個不同數值的定義，直接用匯出的 `UIColor+Additions` 會因為
//  重複的 method 名稱而編譯失敗。下面採用 design-spec 的「建議命名」。
//

import UIKit

enum AppColor {

    // MARK: - 主色

    /// `#EC008C` — 轉帳外框、tab 指示器、badge 文字、✓ 按鈕。（Zeplin: hot pink）
    static let kokoPink = hex(0xEC008C)

    /// `#F9B2DC` — badge 底色。（Zeplin: very light pink）
    static let kokoPinkLight = hex(0xF9B2DC)

    // MARK: - 「加好友」按鈕漸層（由淺到深）

    /// `#A6CC42`（Zeplin: b）
    static let greenLight = hex(0xA6CC42)

    /// `#79C41B`（Zeplin: appleGreen）
    static let greenPrimary = hex(0x79C41B)

    /// `#56B30B`（Zeplin: frogGreen）
    static let greenDark = hex(0x56B30B)

    /// `#79C41B` @ 40% — 按鈕陰影。（Zeplin: appleGreen40）
    static let greenShadow = hex(0x79C41B, alpha: 0.4)

    // MARK: - 文字

    /// `#474747` — 主要文字。（Zeplin: lightGrey）
    static let textPrimary = hex(0x474747)

    /// `#999999` — 次要文字、placeholder。（Zeplin: warmGrey）
    static let textSecondary = hex(0x999999)

    // MARK: - 線與底

    /// `#C9C9C9` — 「邀請中」外框、✕ 按鈕。（Zeplin: pinkishGrey）
    static let borderDisabled = hex(0xC9C9C9)

    /// `#E4E4E4` — cell 分隔線。（Zeplin: transferMoney，白 228）
    static let separator = hex(0xE4E4E4)

    /// `#EFEFEF` — 搜尋框底色。（Zeplin: transferMoney，白 239）
    static let searchBarBackground = hex(0xEFEFEF)

    /// `#F5F5F5` — 頁面底色。（Zeplin: white）
    static let pageBackground = hex(0xF5F5F5)

    /// `#FCFCFC` — 卡片底色。（Zeplin: hot pink，白 252）
    static let cardBackground = hex(0xFCFCFC)

    /// `#FFFFFF` — 純白。（Zeplin: very light pink，白 255）
    static let surface = hex(0xFFFFFF)

    /// `#8E8E93` — iOS 系統灰。
    static let systemGrey = hex(0x8E8E93)

    /// 置頂星星。
    ///
    /// ⚠️ design-spec §4.5 只寫「黃色實心」，**沒有給 hex**。此為近似值。
    /// 若比對設計稿有色差，改這一行即可。
    static let star = hex(0xF8C81C)

    // MARK: -

    private static func hex(_ value: UInt32, alpha: CGFloat = 1) -> UIColor {
        UIColor(
            red: CGFloat((value & 0xFF0000) >> 16) / 255,
            green: CGFloat((value & 0x00FF00) >> 8) / 255,
            blue: CGFloat(value & 0x0000FF) / 255,
            alpha: alpha
        )
    }
}
