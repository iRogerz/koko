# KOKO 好友列表

國泰世華 iOS 面試考題 — 曾子庭

以 **Swift + UIKit（純程式碼）+ MVVM + Swift Concurrency** 實作 KOKO 好友列表頁，
依三種資料情境自動切換三種畫面狀態，並支援姓名關鍵字搜尋。

## 執行

```bash
open koko/koko.xcodeproj
```

- Xcode 26 / Swift 5.9+
- 最低支援 iOS 15.0
- **無第三方套件**，不需要 `pod install` 或任何額外步驟

跑測試：

```bash
cd koko && xcodebuild test -project koko.xcodeproj -scheme koko -destination 'platform=iOS Simulator,name=iPhone 16'
```

## 目前進度

| 層 | 狀態 |
|---|---|
| Model（`User` / `Friend` / `FriendStatus` / `UpdateDate`） | ✅ 完成，測試通過 |
| 合併去重與排序（`FriendMerger` / `FriendSorter`） | ✅ 完成，測試通過 |
| Network（`HTTPClient` / `Endpoint` / `APIClient`） | ✅ 完成，測試通過 |
| Repository（`FriendRepository`，三種情境並行載入） | ✅ 完成，測試通過 |
| ViewModel（`FriendListViewModel` / 搜尋 / 狀態判定） | ✅ 完成，測試通過 |
| DesignSystem（色票／字級／間距／素材 token） | ✅ 完成，測試通過 |
| Scene — 情境選擇頁 | ✅ 完成 |
| Scene — 好友列表頁（狀態 B／C） | ✅ 完成 |
| Scene — 空狀態（狀態 A） | ⬜ 未開始 |

資料層到此全部完成，後續都是畫面。

好友列表頁的狀態 B／C（有好友、含邀請）已完成；狀態 A 空狀態畫面尚未實作。

## 架構

```
情境選擇頁 ──push──▶ 好友列表頁
                        │
                   FriendListViewModel      ← 不 import UIKit
                        │
                   FriendRepository         ← async let 並行載入 + 合併去重
                        │
                     APIClient              ← 解 response 信封 → Model
                        │
                    HTTPClient (protocol)   ← URLSessionHTTPClient｜StubHTTPClient
```

網路層抽成 `HTTPClient` protocol，測試注入 stub —— 全部單元測試都不碰真實網路，
也不需要為了測試去動 `URLSession` 設定。

三條硬規則：

1. **ViewModel 不得 import UIKit。**
2. **View 不得直接呼叫網路**，一律經 Repository → APIClient。
3. **ViewModel 對外只暴露單一 view state**，View 依 state 渲染，不自行推導畫面狀態。

```
urgent/
├── docs/
│   ├── spec.md          # Feature Spec — 唯一真實來源
│   ├── design-spec.md   # Zeplin 色票／字級／版面
│   └── sdd-progress.md  # 開發歷程與決策紀錄
├── CLAUDE.md            # 專案規範
└── koko/                # Xcode 專案
```

## 三個關鍵技術決策

這題的難度不在畫面，在資料。以下三點是實作時真正需要判斷的地方，
完整推導在 [`docs/spec.md`](docs/spec.md)。

### 1. `updateDate` 有兩種格式，必須正規化後才能比較

`friend1` / `friend3` 用 `yyyyMMdd`（`20190801`），
但 **`friend2` 用 `yyyy/MM/dd`**（`2019/08/02`）。

直接字串比較會得到**相反**的答案 —— `/` 的 ASCII 是 `0x2F`，小於 `0` 的 `0x30`，
所以 `"2019/08/02" < "20190801"`。合併時會挑到舊的那一筆，情境二直接畫錯畫面。

處理方式：把 `updateDate` 做成獨立值型別 [`UpdateDate`](koko/koko/Model/UpdateDate.swift)，
**建構當下就正規化成 `Date`**，`Comparable` 只看正規化結果，原始字串不參與比較。
目的是讓「拿字串去比大小」在型別層面就不可能發生，而不是靠寫的人記得。

正規化採 `DateFormatter` + **回寫比對**（`formatter.string(from: date) == rawValue`），
擋掉 `20190841`、`201908`、尾端空白這些 `DateFormatter` 會寬容吃掉的輸入。
未知格式一律 throw，不做 fallback —— 寧可解碼失敗，也不要讓無法正規化的值靜默排錯序。

### 2. 邀請卡片的判定是 `status == 0`，這是推導出來的

設計稿把 `status == 2` 的人（彭安亭、施君凌）畫成邀請卡片，
但 Zeplin 註解寫的是 `status == 0` 為「邀請送出」。兩者衝突。

用需求 (2)-II 可以反證註解才是對的：

- 需求規定 `friend1 + friend2` 合併後必須呈現「**好友列表無邀請**」。
- 合併結果中 `翁勳儀` 是 `status == 2`。
- 若 `2` 是邀請卡片 → 情境二會冒出一張卡片 → **與需求矛盾**。
- 若 `0` 是邀請卡片 → 合併後 `status == 0` 為 0 筆 → 無卡片 → **符合需求**。

∴ 設計稿的假資料是示意用途，不具規範效力。

這條判定集中在 [`FriendStatus.invitationCard`](koko/koko/Model/FriendStatus.swift) 這一個常數，
不散落在各處。**若認定相反，改那一行即可全案切換。**

### 3. 去重只能用 `fid`，不能用 `name`

`friend1` 中 `fid=004` 與 `fid=005` 都叫「梁立璇」。用姓名去重會少一筆。

## 測試

`kokoTests/` 全部使用 `Fixtures/` 內的離線 JSON，**不打真實網路**。
五支 fixture 取自題目指定的 API，內容與 spec 的黃金樣本逐筆相符。

測試除了驗證正確行為，也刻意留下**防線**，擋住之後可能的退化：

| 防的是什麼 | 怎麼防 |
|---|---|
| 有人把日期改回字串比較 | 先斷言字串比較確實是反的，再斷言正規化推翻它 |
| 有人把 `isTop` 解碼放寬成同時吃 Bool / Int | 傳非字串必須解碼失敗 |
| 有人把 `status` 解碼放寬成同時吃字串 | 傳字串必須解碼失敗 |
| 有人把邀請卡片改回 `status == 2` | 三個測試從不同角度釘住 `status == 0` |
| 有人改用 `name` 去重 | 把「同名不同 fid」這個前提寫成測試 |
| 並行請求退化成循序 | 量測同時在途的請求數，循序會掉到 1 |

另有 `scripts/check-architecture.sh` —— 不需編譯的架構檢查，涵蓋
「ViewModel 不得 import UIKit」「不得殘留 Storyboard／SwiftUI」等規則：

```bash
./scripts/check-architecture.sh
```

## 待補

- [ ] 好友列表頁 UI（header／tab／搜尋框／邀請卡片／好友 cell／空狀態／TabBar）
- [ ] 加分項目：下拉更新、搜尋框上推、邀請卡片展開收合（Unit Test 已完成）
- [ ] 錄影檔（涵蓋三種情境與四項加分功能）
