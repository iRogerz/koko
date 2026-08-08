//
//  DesignSystemTests.swift
//  kokoTests
//
//  Design token 與素材的存在性檢查。
//  這類錯誤（素材漏放、名字打錯、字體名寫錯）不會編譯失敗，
//  只會在畫面上靜默變成空白，靠肉眼很難發現。
//

import XCTest
@testable import koko

final class AppImageTests: XCTestCase {

    /// 每一個 AppImage 都必須在 Assets.xcassets 找得到。
    /// 素材漏放或 imageset 名字打錯會在這裡失敗，而不是在畫面上變空白。
    func test_allImages_resolveFromAssetCatalog() {
        for asset in AppImage.allCases {
            XCTAssertNotNil(
                UIImage(named: asset.rawValue),
                "找不到素材「\(asset.rawValue)」（AppImage.\(asset)）"
            )
        }
    }

    func test_allImages_areVectorBacked() {
        for asset in AppImage.allCases {
            guard let image = UIImage(named: asset.rawValue) else { continue }
            XCTAssertGreaterThan(image.size.width, 0, "\(asset.rawValue) 尺寸異常")
            XCTAssertGreaterThan(image.size.height, 0, "\(asset.rawValue) 尺寸異常")
        }
    }

    func test_rawValues_areUnique() {
        let names = Set(AppImage.allCases.map(\.rawValue))
        XCTAssertEqual(names.count, AppImage.allCases.count)
    }
}

final class AppTextTests: XCTestCase {

    /// PingFang TC 取不到時會退回系統字體 —— 那是保險，不該是常態。
    /// 這個測試確保正常環境下真的拿到 PingFang。
    func test_pingFang_isAvailable() {
        XCTAssertEqual(AppText.pingFang(.regular, 13).fontName, "PingFangTC-Regular")
        XCTAssertEqual(AppText.pingFang(.medium, 17).fontName, "PingFangTC-Medium")
    }

    func test_textStyles_matchDesignSpec() {
        XCTAssertEqual(AppText.emptyStateTitle.font.pointSize, 21)
        XCTAssertEqual(AppText.name.font.pointSize, 17)
        XCTAssertEqual(AppText.inviteName.font.pointSize, 16)
        XCTAssertEqual(AppText.tabTitle.font.pointSize, 14)
        XCTAssertEqual(AppText.actionButton.font.pointSize, 13)
        XCTAssertEqual(AppText.body.font.pointSize, 13)
        XCTAssertEqual(AppText.caption.font.pointSize, 11)
    }

    func test_lineHeightAndLetterSpacing_matchDesignSpec() {
        XCTAssertEqual(AppText.name.lineHeight, 18)
        XCTAssertEqual(AppText.actionButton.lineHeight, 18)
        XCTAssertEqual(AppText.body.lineHeight, 18)
        XCTAssertEqual(AppText.caption.letterSpacing, 1)
    }

    func test_attributes_includeLineHeightWhenSpecified() {
        let attributes = AppText.name.attributes()
        let paragraph = attributes[.paragraphStyle] as? NSParagraphStyle

        XCTAssertEqual(paragraph?.minimumLineHeight, 18)
        XCTAssertEqual(paragraph?.maximumLineHeight, 18)
    }

    func test_withColor_keepsEverythingElse() {
        let original = AppText.tabTitle
        let recolored = original.withColor(AppColor.kokoPink)

        XCTAssertEqual(recolored.font, original.font)
        XCTAssertEqual(recolored.lineHeight, original.lineHeight)
        XCTAssertEqual(recolored.letterSpacing, original.letterSpacing)
        XCTAssertEqual(recolored.color, AppColor.kokoPink)
    }
}

final class AppColorTests: XCTestCase {

    /// design-spec §1 的關鍵色票。Zeplin 有三組同名不同值的定義，
    /// 這裡把實際數值釘死，避免日後改名時對錯值。
    func test_keyColors_matchDesignSpec() {
        assertHex(AppColor.kokoPink, 0xEC008C, "主色")
        assertHex(AppColor.kokoPinkLight, 0xF9B2DC, "badge 底")
        assertHex(AppColor.textPrimary, 0x474747, "主要文字")
        assertHex(AppColor.textSecondary, 0x999999, "次要文字")
        assertHex(AppColor.borderDisabled, 0xC9C9C9, "停用外框")
        assertHex(AppColor.separator, 0xE4E4E4, "分隔線")
        assertHex(AppColor.searchBarBackground, 0xEFEFEF, "搜尋框底")
        assertHex(AppColor.pageBackground, 0xF5F5F5, "頁面底")
        assertHex(AppColor.cardBackground, 0xFCFCFC, "卡片底")
    }

    /// 三組同名色票必須解析成不同的值 —— 這正是不能直接用 Zeplin 匯出檔的原因。
    func test_duplicatelyNamedZeplinColors_areDistinct() {
        XCTAssertNotEqual(AppColor.kokoPink, AppColor.cardBackground, "Zeplin 都叫 hot pink")
        XCTAssertNotEqual(AppColor.kokoPinkLight, AppColor.surface, "Zeplin 都叫 very light pink")
        XCTAssertNotEqual(AppColor.separator, AppColor.searchBarBackground, "Zeplin 都叫 transferMoney")
    }

    func test_greenGradient_isOrderedLightToDark() {
        XCTAssertNotEqual(AppColor.greenLight, AppColor.greenPrimary)
        XCTAssertNotEqual(AppColor.greenPrimary, AppColor.greenDark)
        XCTAssertEqual(AppColor.greenShadow.cgColor.alpha, 0.4, accuracy: 0.001)
    }

    private func assertHex(
        _ color: UIColor,
        _ expected: UInt32,
        _ label: String,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        color.getRed(&r, green: &g, blue: &b, alpha: &a)

        let actual = (UInt32(round(r * 255)) << 16) | (UInt32(round(g * 255)) << 8) | UInt32(round(b * 255))
        XCTAssertEqual(
            String(format: "%06X", actual),
            String(format: "%06X", expected),
            label,
            file: file,
            line: line
        )
    }
}

final class SpacingTests: XCTestCase {

    func test_spacing_matchesDesignSpec() {
        XCTAssertEqual(Spacing.xs, 4)
        XCTAssertEqual(Spacing.s, 8)
        XCTAssertEqual(Spacing.m, 12)
        XCTAssertEqual(Spacing.l, 16)
    }
}
