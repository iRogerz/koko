//
//  UpdateDate.swift
//  koko
//
//  spec.md §3.3：`updateDate` 有 `yyyyMMdd`（friend1/friend3）與
//  `yyyy/MM/dd`（friend2）兩種格式並存。
//
//  直接字串比較會得到相反的結果（`/` 的 ASCII 0x2F 小於 `0` 的 0x30，
//  所以 `"2019/08/02" < "20190801"`），合併時會挑到錯誤的那一筆。
//  因此本型別在「建構當下」就把字串正規化成 `Date`，
//  之後所有比較都走 `Date`，字串沒有機會被拿去比大小。
//

import Foundation

struct UpdateDate {

    /// API 原始字串，保留給顯示／除錯用，**不參與比較**。
    let rawValue: String

    /// 正規化後的日期，所有比較的唯一依據。
    let date: Date

    /// spec 明列的兩種格式。順序即嘗試順序。
    static let acceptedFormats = ["yyyyMMdd", "yyyy/MM/dd"]

    enum ParsingError: Error, Equatable {
        /// 不屬於 `acceptedFormats` 的任何一種。
        case unrecognizedFormat(String)
    }

    /// - Throws: `ParsingError.unrecognizedFormat` —— 未知格式一律大聲失敗。
    ///   寧可解碼失敗，也不要讓無法正規化的值靜默進入模型後排錯序。
    init(rawValue: String) throws {
        guard let date = Self.normalize(rawValue) else {
            throw ParsingError.unrecognizedFormat(rawValue)
        }
        self.rawValue = rawValue
        self.date = date
    }

    /// 純函式：把原始字串正規化成 `Date`，無法對應任一允許格式則回 `nil`。
    static func normalize(_ rawValue: String) -> Date? {
        for formatter in formatters {
            guard let date = formatter.date(from: rawValue) else { continue }
            // 回寫比對：確保 rawValue 是「完整且精確」地符合該格式，
            // 而不是 DateFormatter 寬容地吃掉了部分字元後把剩下的丟掉。
            guard formatter.string(from: date) == rawValue else { continue }
            return date
        }
        return nil
    }

    /// 固定 POSIX locale + UTC，讓正規化結果與裝置時區、地區曆法無關。
    private static let formatters: [DateFormatter] = acceptedFormats.map { format in
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.isLenient = false
        formatter.dateFormat = format
        return formatter
    }
}

// MARK: - Comparable

/// 相等與大小都只看正規化後的 `date`，
/// 因此 `"20190801"` 與 `"2019/08/01"` 視為同一天。
extension UpdateDate: Hashable, Comparable {

    static func == (lhs: UpdateDate, rhs: UpdateDate) -> Bool {
        lhs.date == rhs.date
    }

    static func < (lhs: UpdateDate, rhs: UpdateDate) -> Bool {
        lhs.date < rhs.date
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(date)
    }
}

// MARK: - Decodable

extension UpdateDate: Decodable {

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        try self.init(rawValue: container.decode(String.self))
    }
}

// MARK: - Debug

extension UpdateDate: CustomStringConvertible {

    var description: String { rawValue }
}
