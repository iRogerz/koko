//
//  AppText.swift
//  koko
//
//  字級 token，取自 `docs/design-spec.md` §2。全部為 PingFang TC。
//  行高與字距一併封裝，ViewController 不自行組 paragraph style。
//

import UIKit

/// 一組完整的文字樣式：字體 + 顏色 + 行高 + 字距。
struct TextStyle {

    let font: UIFont
    let color: UIColor
    let lineHeight: CGFloat?
    let letterSpacing: CGFloat?

    init(font: UIFont, color: UIColor, lineHeight: CGFloat? = nil, letterSpacing: CGFloat? = nil) {
        self.font = font
        self.color = color
        self.lineHeight = lineHeight
        self.letterSpacing = letterSpacing
    }

    /// 供 `NSAttributedString` 使用。有指定行高時會自動換算 baseline offset，
    /// 讓文字在行高內垂直置中。
    func attributes(alignment: NSTextAlignment = .natural) -> [NSAttributedString.Key: Any] {
        var attributes: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: color,
        ]

        if let letterSpacing {
            attributes[.kern] = letterSpacing
        }

        let paragraph = NSMutableParagraphStyle()
        paragraph.alignment = alignment

        if let lineHeight {
            paragraph.minimumLineHeight = lineHeight
            paragraph.maximumLineHeight = lineHeight
            attributes[.baselineOffset] = (lineHeight - font.lineHeight) / 4
        }
        attributes[.paragraphStyle] = paragraph

        return attributes
    }

    func attributedString(_ text: String, alignment: NSTextAlignment = .natural) -> NSAttributedString {
        NSAttributedString(string: text, attributes: attributes(alignment: alignment))
    }

    /// 只改顏色、其餘不變。用於同一字級但需要不同顏色的場合（如選中／未選中的 tab）。
    func withColor(_ color: UIColor) -> TextStyle {
        TextStyle(font: font, color: color, lineHeight: lineHeight, letterSpacing: letterSpacing)
    }
}

enum AppText {

    /// Text Style 6 — Medium 21pt。空狀態主標題「就從加好友開始吧：）」。
    static let emptyStateTitle = TextStyle(
        font: pingFang(.medium, 21),
        color: AppColor.textPrimary
    )

    /// Text Style 4 — Medium 17pt / 行高 18。Header 姓名、好友姓名。
    static let name = TextStyle(
        font: pingFang(.medium, 17),
        color: AppColor.textPrimary,
        lineHeight: 18
    )

    /// Text Style 3 — Regular 16pt。邀請卡片姓名。
    static let inviteName = TextStyle(
        font: pingFang(.regular, 16),
        color: AppColor.textPrimary
    )

    /// Text Style 5 — Medium 14pt。Tab 標題、搜尋框 placeholder。
    static let tabTitle = TextStyle(
        font: pingFang(.medium, 14),
        color: AppColor.textSecondary
    )

    /// Text Style 2 — Medium 13pt / 行高 18。「轉帳」按鈕文字。
    static let actionButton = TextStyle(
        font: pingFang(.medium, 13),
        color: AppColor.textPrimary,
        lineHeight: 18
    )

    /// Text Style — Regular 13pt / 行高 18。空狀態副標、KOKO ID。
    static let body = TextStyle(
        font: pingFang(.regular, 13),
        color: AppColor.textPrimary,
        lineHeight: 18
    )

    /// Text Style 7 — Medium 11pt / 字距 1。TabBar 文字、「邀請中」標籤。
    static let caption = TextStyle(
        font: pingFang(.medium, 11),
        color: AppColor.textSecondary,
        letterSpacing: 1
    )

    // MARK: -

    enum Weight {
        case regular
        case medium

        var fontName: String {
            switch self {
            case .regular: return "PingFangTC-Regular"
            case .medium: return "PingFangTC-Medium"
            }
        }

        var systemWeight: UIFont.Weight {
            switch self {
            case .regular: return .regular
            case .medium: return .medium
            }
        }
    }

    /// PingFang TC 在所有 iOS 中文環境都存在；
    /// 萬一取不到（例如未來換字體名稱）就退回系統字體，不讓畫面整個空掉。
    static func pingFang(_ weight: Weight, _ size: CGFloat) -> UIFont {
        UIFont(name: weight.fontName, size: size)
            ?? .systemFont(ofSize: size, weight: weight.systemWeight)
    }
}
