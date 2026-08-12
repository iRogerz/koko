//
//  Spacing.swift
//  koko
//
//  間距 token，取自 `docs/design-spec.md` §3。
//  ViewController 內不得寫魔術數字（CLAUDE.md architecture rule 6）。
//

import CoreGraphics

enum Spacing {

    /// 4pt
    static let xs: CGFloat = 4

    /// 8pt
    static let s: CGFloat = 8

    /// 12pt
    static let m: CGFloat = 12

    /// 16pt
    static let l: CGFloat = 16

    /// 30pt — 頁面左右邊距（design-spec §7.1）。
    ///
    /// 搜尋框、邀請卡片、header 姓名、tab 列、cell 星星全部對齊這條線。
    /// 這不是 §3 的間距階梯，而是版面基準，所以獨立命名。
    static let pageMargin: CGFloat = 30

    /// 20pt — 頂部 nav 圖示列的左右邊距（design-spec §7.2）。
    /// 設計稿上這是唯一比內容窄的一列。
    static let navMargin: CGFloat = 20
}
