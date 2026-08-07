# Project Constitution — KOKO 好友列表

國泰世華 iOS 面試考題。實作前必讀 `docs/spec.md`。

## Tech stack

- 語言：Swift 5.9+
- UI：UIKit，**純程式碼**（no Storyboard、no XIB、**no SwiftUI**）
- 架構：MVVM
- 非同步：Swift Concurrency（`async/await`、`async let`）
- 網路：`URLSession`，無第三方套件
- 測試：XCTest
- 最低支援：iOS 15.0

## Architecture rules

1. **ViewModel 不得 import UIKit。** 只 import Foundation。違反即架構失敗。
2. **View 不得直接呼叫網路。** 所有 API 經由 Repository → APIClient。
3. **ViewModel 對外只暴露單一 view state**（`FriendListViewState`），View 依 state 渲染，不自行推導畫面狀態。
4. **合併、去重、排序、搜尋篩選都是純函式**，放在可單獨測試的型別中，不寫在 ViewController。
5. **不得使用第三方套件。**
6. UI 尺寸與顏色一律取自 `docs/design-spec.md` 的 token，不在 ViewController 內寫魔術數字。

## Inviolable constraints

- `updateDate` **必須先正規化再比較**。`yyyyMMdd` 與 `yyyy/MM/dd` 兩種格式並存，
  直接字串比較會產生錯誤結果（`"2019/08/02" < "20190801"`）。
- 好友去重**只能用 `fid`**，不得用 `name`（存在同名不同 fid 的資料）。
- `isTop` 在 JSON 中是 **String**（`"0"`/`"1"`），`status` 是 **Number**。不得混用型別假設。
- 邀請卡片區的判定條件是 **`status == 0`**，集中定義成單一常數／函式，
  不得散落在多處。理由與推導見 `docs/spec.md` §4.2。
- 空狀態（狀態 A）以「合併後好友總數為 0」判定，不是「一般好友數為 0」。

## Directory structure

Xcode 專案實際名稱為 **`koko`**（target `koko` / `kokoTests` / `kokoUITests`），
非早期草案的 `KOKOFriends`。以下為實際路徑。

```
urgent/                          # ← git repo root
├── .gitignore
├── README.md                    # 交付用說明（架構、關鍵決策、進度）
├── CLAUDE.md                    # 本檔（Project Constitution）
├── docs/
│   ├── spec.md                  # Feature Spec — 唯一真實來源
│   ├── design-spec.md           # Zeplin 色票／字級／版面摘錄
│   └── sdd-progress.md          # 跨 session 進度（勿刪）
└── koko/
    ├── koko.xcodeproj
    ├── koko/
    │   ├── App/                 # AppDelegate / SceneDelegate（純程式碼建立 window）
    │   ├── Model/               # User, Friend, FriendStatus, UpdateDate, APIResponse
    │   ├── Network/             # APIClient, Endpoint
    │   ├── Repository/          # FriendRepository（合併去重在此）
    │   ├── Scene/
    │   │   ├── ScenarioPicker/  # 起始情境選擇頁
    │   │   └── FriendList/      # ViewController + ViewModel + Cells + Views
    │   ├── DesignSystem/        # UIColor / UIFont / Spacing token
    │   └── Info.plist
    ├── kokoTests/
    │   ├── Fixtures/            # friend1~4.json、man.json 離線樣本
    │   ├── Support/             # FixtureLoader
    │   └── Model/ …
    └── kokoUITests/
```

> 專案使用 Xcode 的 **file system synchronized groups**（`objectVersion = 77`）：
> 檔案放進資料夾即自動加入 target，**不需要手動編輯 `project.pbxproj`**。

## Agent directives

- 動工前先讀 `docs/spec.md`，實作範圍不得超出其定義。
- 每個實作步驟走 PEV：Plan → Execute → Verify，未通過驗收條件不得前進下一步。
- **不要代替使用者跑 build／test／模擬器**——使用者自己跑並回報。可以跑 lint 這類不需編譯的檢查。
- 每完成一個階段或做出關鍵決策，更新 `docs/sdd-progress.md`。
- 修 bug 時套用 Hashimoto 原則：除了修程式碼，還要留下一個機械化防線（測試／lint 規則），
  並記錄到 `docs/sdd-progress.md` 的 Hashimoto log。
- 程式碼與 spec 衝突時，**改程式碼去符合 spec**，不是反過來。
