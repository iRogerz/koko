//
//  Friend.swift
//  koko
//
//  spec.md §3.2：欄位型別在 API 中並不一致 ——
//  `status` 是 **Number**、`isTop` 是 **String**（`"0"` / `"1"`）。
//  Decodable 必須分別處理，不得混用型別假設。
//

import Foundation

struct Friend: Hashable {

    /// 好友唯一鍵。**去重只能用 `fid`**（spec.md §5.1）——
    /// friend1 中 `004` 與 `005` 同名「梁立璇」，用姓名去重會少一筆。
    let fid: String

    let name: String

    let status: FriendStatus

    /// JSON 為 String `"0"` / `"1"`，在此正規化成 Bool。
    /// 語意：是否顯示星星並置頂（spec.md §5.2、§6.5）。
    let isTop: Bool

    /// 已正規化的更新時間，可直接比大小。
    let updateDate: UpdateDate
}

extension Friend {

    /// 是否屬於上方邀請卡片區。判定轉發給 `FriendStatus.invitationCard` 這個單一來源。
    var isInvitationCard: Bool { status.isInvitationCard }
}

// MARK: - Decodable

extension Friend: Decodable {

    private enum CodingKeys: String, CodingKey {
        case fid, name, status, isTop, updateDate
    }

    /// `isTop` 只接受字串 `"0"` / `"1"`。
    private enum IsTopRawValue: String {
        case no = "0"
        case yes = "1"

        var boolValue: Bool { self == .yes }
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        fid = try container.decode(String.self, forKey: .fid)
        name = try container.decode(String.self, forKey: .name)

        // status：Number。傳字串會在這裡失敗，這是刻意的。
        status = try container.decode(FriendStatus.self, forKey: .status)

        // isTop：String。傳數字或 Bool 會在這裡失敗，這也是刻意的。
        let rawIsTop = try container.decode(String.self, forKey: .isTop)
        guard let isTopValue = IsTopRawValue(rawValue: rawIsTop) else {
            throw DecodingError.dataCorruptedError(
                forKey: .isTop,
                in: container,
                debugDescription: #"isTop 只接受 "0" 或 "1"，實際收到 "\#(rawIsTop)"。"#
            )
        }
        isTop = isTopValue.boolValue

        updateDate = try container.decode(UpdateDate.self, forKey: .updateDate)
    }
}
