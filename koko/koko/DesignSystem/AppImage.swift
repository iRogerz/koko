//
//  AppImage.swift
//  koko
//
//  Asset Catalog 的型別安全存取點。呼叫端不寫字串，避免打錯名字只能在
//  執行期發現（而且是靜默地變成空白）。
//
//  rawValue 沿用 Zeplin 匯出的檔名，保留回溯到設計稿的線索。
//  全部為 PDF 向量，Single Scale + Preserve Vector Data。
//

import UIKit

enum AppImage: String, CaseIterable {

    // MARK: 人像與插圖

    /// 預設頭像。Zeplin 註解：「無圖示可以全用這個 default」。
    case avatarDefault = "imgFriendsFemaleDefault"

    /// 空狀態插圖（兩人握手）。
    case emptyStateIllustration = "imgFriendsEmpty"

    // MARK: 圖示

    /// 加好友。
    case addFriend = "icBtnAddFriends"

    // MARK: 底部 TabBar
    //
    // ⚠️ 四個分頁素材**已內含分頁名稱文字**（icon + label 合成圖，78×128），
    // 呼叫端不可再另外加 UILabel，否則文字會出現兩次。
    //
    // ⚠️ Zeplin 檔名與分頁名稱**對不起來**，只能看圖辨認（已逐張確認）：
    //   `icTabbarProductsOff` 是錢錢、`icTabbarManageOff` 是記帳、
    //   `icTabbarHomeOff` 不是分頁，是中央的 KO 按鈕。

    /// 錢錢（錢袋 + 星星）。
    case tabMoney = "icTabbarProductsOff"
    /// 朋友。唯一的選中態（粉紅）素材。
    case tabFriends = "icTabbarFriendsOn"
    /// 記帳。
    case tabAccounting = "icTabbarManageOff"
    /// 設定。
    case tabSettings = "icTabbarSettingOff"

    /// 中央 KO 按鈕的**未選中（灰）**版本，含 TabBar 上緣的凹口造型。
    /// 設計稿上的 KO 是粉紅實心，Zeplin 未匯出該版本，見 `AppTabBarView.makeKOButton()`。
    case tabCenterKOOff = "icTabbarHomeOff"

    // MARK: KO 功能圖示

    case navScan = "icNavPinkScan"
    case navTransfer = "icNavPinkTransfer"
    case navWithdraw = "icNavPinkWithdraw"
}

extension AppImage {

    /// 素材缺漏時在 debug 直接斷言 —— 靜默變成空白比崩潰更難查。
    /// `AppImageTests` 會驗證所有 case 都取得到，正常情況不會走到 fallback。
    var image: UIImage {
        guard let image = UIImage(named: rawValue) else {
            assertionFailure("Assets.xcassets 找不到素材「\(rawValue)」")
            return UIImage()
        }
        return image
    }
}
