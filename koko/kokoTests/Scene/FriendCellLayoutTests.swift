//
//  FriendCellLayoutTests.swift
//  kokoTests
//
//  好友 cell 的版面防線（design-spec §7.7）。
//
//  背景（2026-08-12 從模擬器截圖比對設計稿發現）：星星原本和頭像放在同一個
//  UIStackView 裡，於是「有星星的列」頭像被往右推、和其他列對不齊。
//  設計稿上頭像**永遠**在 x=50，星星是疊在它左邊的固定空位。
//
//  這種錯不會 crash、不會編譯失敗，只有把兩列並排看才看得出來。
//

import XCTest
@testable import koko

@MainActor
final class FriendCellLayoutTests: XCTestCase {

    private let width: CGFloat = 375

    /// 有無星星都不得影響頭像的水平位置 —— 這正是截圖上看到的錯位。
    func test_avatarPosition_isUnaffectedByStar() async throws {
        let starred = try FriendBuilder.make(fid: "1", name: "翁勳儀", isTop: true)
        let plain = try FriendBuilder.make(fid: "2", name: "黃靖僑", isTop: false)

        let starredAvatar = try avatarFrame(for: starred)
        let plainAvatar = try avatarFrame(for: plain)

        XCTAssertEqual(
            starredAvatar.minX,
            plainAvatar.minX,
            accuracy: 0.5,
            "有星星的列頭像被推開了：\(starredAvatar.minX) vs \(plainAvatar.minX)"
        )
        XCTAssertEqual(starredAvatar.minX, 50, accuracy: 0.5, "頭像 leading 應為 50（design-spec §7.7）")
    }

    /// 列高固定 60，不隨內容變動。
    func test_rowHeight_is60() async throws {
        let cell = try layoutCell(for: FriendBuilder.make(fid: "1"))
        XCTAssertEqual(cell.contentView.bounds.height, 60, accuracy: 0.5)
    }

    /// 頭像是正圓 40，星星不吃掉它的寬度。
    func test_avatarSize_is40() async throws {
        let frame = try avatarFrame(for: FriendBuilder.make(fid: "1", isTop: true))
        XCTAssertEqual(frame.width, 40, accuracy: 0.5)
        XCTAssertEqual(frame.height, 40, accuracy: 0.5)
    }

    // MARK: -

    private func layoutCell(for friend: Friend) throws -> FriendCell {
        let cell = FriendCell(style: .default, reuseIdentifier: FriendCell.reuseIdentifier)
        cell.configure(with: friend)
        cell.frame = CGRect(x: 0, y: 0, width: width, height: 60)
        cell.layoutIfNeeded()
        return cell
    }

    /// contentView 的直接 UIImageView subview 只有星星與頭像；
    /// 星星是 SF Symbol、頭像是 Asset Catalog 素材，用這點區分即可
    /// （`⋯` 包在按鈕那組 stack 裡，不是直接 subview）。
    private func avatarFrame(for friend: Friend) throws -> CGRect {
        let cell = try layoutCell(for: friend)
        let avatar = cell.contentView.subviews
            .compactMap { $0 as? UIImageView }
            .first { $0.image?.isSymbolImage == false }

        let view = try XCTUnwrap(avatar, "找不到頭像 image view")
        return view.frame
    }
}
