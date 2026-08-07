# SDD Progress — KOKO 好友列表（國泰世華 iOS 面試考題）

Last updated: 2026-08-07

## Current phase

Phase 3 完成 → **下一步是 Phase 4（Context Reset + PEV Loop）**

## Completed phases

- [x] Phase 1: Brain Dump — 來源為需求 PDF + Zeplin 四張設計稿 + 五支 API 實際回應
- [x] Phase 2: Spec Interview — 四個技術選型問題已由使用者拍板（見下）
- [x] Phase 3: Project Constitution + Feature Spec — `CLAUDE.md`、`docs/spec.md`、`docs/design-spec.md`
- [ ] Phase 4: Context Reset + PEV Loop
- [ ] Phase 5: Anti-Drift + Hashimoto
- [ ] Phase 6: Skill Extraction

## Phase 2 決議（使用者拍板）

| 問題 | 決議 |
|---|---|
| 語言與 UI 建構方式 | Swift + 純程式碼 UIKit（no Storyboard/XIB/SwiftUI） |
| 資料層／非同步 | Swift Concurrency `async/await` |
| 加分項目 | **四項全做**（下拉更新、搜尋框上推、邀請卡片縮合、Unit Test） |
| 情境切換形式 | 獨立的情境選擇首頁，點擊後 push |

## Phase 3 decisions（Project Constitution）

- Tech stack：Swift 5.9 / UIKit 純程式碼 / MVVM / Swift Concurrency / URLSession / XCTest / iOS 15+
- Architecture rules：
  - ViewModel 不得 import UIKit
  - View 不得直接呼叫網路，一律經 Repository → APIClient
  - ViewModel 只暴露單一 view state
  - 合併／去重／排序／搜尋皆為純函式，可單獨測試
  - 不使用第三方套件
- Inviolable constraints：
  - `updateDate` 必須正規化後再比較（`yyyyMMdd` vs `yyyy/MM/dd` 並存）
  - 去重只能用 `fid`，不能用 `name`
  - `isTop` 是 String、`status` 是 Number
  - 邀請卡片判定為 `status == 0`，集中成單一常數
  - 空狀態以「好友總數為 0」判定

## Feature Spec status

- Spec file：`docs/spec.md`（v1.0 定稿）
- Acceptance criteria：已定義，AC-1 ~ AC-17
- 設計規格：`docs/design-spec.md`
- 未解問題：無阻斷性問題，四個已決議議題記錄於 spec §10

## 本次調查發現的關鍵事實（不要重新推導一次）

1. **`updateDate` 格式不一致。** friend2 用 `2019/08/02`，friend1/friend3 用 `20190801`。
   直接字串比較會反向（`/` 的 ASCII 小於 `0`），導致情境二畫錯畫面。**這是本題最主要的陷阱。**
2. **`status = 0` 才是上方邀請卡片。** 設計稿假資料把 `status=2` 的人畫成邀請卡片，
   但用需求 (2)-II 可反證：F1+F2 合併後 `翁勳儀` 是 `status=2`，
   若 `status=2` 是卡片，情境二就會出現邀請卡片，與「只有好友列表」的需求矛盾。
   完整推導在 `docs/spec.md` §4.2。
3. **friend1 有同名不同 fid**（`004` / `005` 都叫「梁立璇」）→ 去重不能用姓名。
4. **`isTop` 是字串、`status` 是數字**，型別不一致。
5. Zeplin 色票有三組同名不同值（`hot pink` / `very light pink` / `transferMoney`），
   直接用 Zeplin 匯出的 `UIColor+Additions` 會編譯失敗，必須改名。
6. Zeplin 註解另外規定：聊天 badge 固定 `99+`、無頭像一律用 default 圖、邀請區支援縮合。

## Phase 4 PEV log

| Step | Plan | Execute | Verify | Status |
|------|------|---------|--------|--------|
| 0 | 專案去 Storyboard 化，改純程式碼啟動 | 刪 `Main.storyboard` / `LaunchScreen.storyboard` / 樣板 `ViewController.swift`；`Info.plist` 移除 `UISceneStoryboardFile`、改用 `UILaunchScreen` 空 dict；`project.pbxproj` 移除 `INFOPLIST_KEY_UIMainStoryboardFile` 與 `INFOPLIST_KEY_UILaunchStoryboardName`；deployment target `26.1` → `15.0`；`SceneDelegate` 以程式碼建立 `UIWindow` | grep 全專案無 `.storyboard` / `.xib` / `import SwiftUI` ✓；待使用者跑 build | **待使用者驗證** |
| 1 | Model 層：`User` / `Friend` / `FriendStatus` Decodable + `updateDate` 正規化，測試先寫 | 新增 `Model/{UpdateDate,FriendStatus,Friend,User,APIResponse}.swift`；測試 `kokoTests/Model/*` 四檔 + `Support/FixtureLoader.swift`；`Fixtures/` 放入五支 API 的實際回應 | 全部 Model 檔只 `import Foundation` ✓；待使用者跑 test | **待使用者驗證** |

### Step 0 決策

- **`LaunchScreen.storyboard` 一併刪除**，改用 `Info.plist` 的 `UILaunchScreen` 空 dict（iOS 14+ 機制）。
  理由：憲法寫的是 no Storyboard，留一個 storyboard 只為了啟動畫面不一致。
- 保留 `App/RootPlaceholderViewController.swift` 作為暫時 root，
  **待 ScenarioPicker 完成後連同 `SceneDelegate` 內引用一併刪除**。
- Deployment target 設 15.0。若 Xcode 26 拒絕（其最低支援可能是 15.6），改 15.6 並同步更新 `CLAUDE.md`。

### Step 1 決策

- **`UpdateDate` 是獨立值型別**，不是 `String` 也不是裸 `Date`。
  建構當下就正規化；`Comparable` / `Hashable` 只看正規化後的 `Date`，`rawValue` 僅供顯示。
  設計目的：讓「拿字串去比大小」在型別層面不可能發生。
- **正規化採 `DateFormatter` + 回寫比對**（`formatter.string(from: date) == rawValue`），
  而非去掉斜線比數字。回寫比對能擋掉 `20190841`、`201908`、尾端空白等 DateFormatter 會寬容吃掉的輸入。
  Formatter 固定 `en_US_POSIX` + UTC + Gregorian，結果與裝置時區無關。
- **未知日期格式一律 throw，不做 fallback。** 寧可解碼失敗，也不要讓無法正規化的值靜默進入模型後排錯序。
- **`isTop` 以 `String` 解碼、對外暴露 `Bool`。** JSON 型別假設不放寬（給數字或 Bool 會 throw），
  但下游不必再處理 `"0"` / `"1"` 字串。
- **`status` 用 `enum FriendStatus: Int`**，未定義值（3、-1…）解碼失敗。
- **`FriendStatus.invitationCard` 是邀請卡片判定的唯一來源**（spec §4.2 / O-1），
  `Friend.isInvitationCard` 只是轉發。若面試官認定相反，改那一行即可。
- **`User.kokoID` 正規化**：缺欄位／`null`／空字串／純空白一律 `nil`，header 只需判斷 `nil`。

### Repo 結構決策（2026-08-07）

- **git root 在 `urgent/`，不在 `koko/`。** 原本 `koko/` 有自己的 `.git`（巢狀），
  已將該 `.git` **搬到** `urgent/`（非刪除，Initial Commit 完整保留，git 也正確辨識成 rename）。
- **`docs/`、`CLAUDE.md`、考題 PDF、錄影檔一律留在 repo root，不搬進 `koko/`。** 理由：
  1. `CLAUDE.md` 必須在 repo root 才會被 Claude Code 自動載入；
  2. 這些是交付物，與 Xcode 專案平行，不是它的子資產；
  3. `koko/koko`、`kokoTests`、`kokoUITests` 是 Xcode synchronized group，
     不該混入非 target 內容。
- 新增 `.gitignore`（`xcuserdata/`、`DerivedData/`、`.DS_Store` 等），
  並把已被追蹤的 `koko.xcodeproj/xcuserdata/…` 移出版控。
- 注意：`/Users/irogerz`（家目錄）本身是一個 git repo，但 `Developer/` 未被它追蹤，
  與本 repo 無實際衝突。

### Fixtures 已驗證

`kokoTests/Fixtures/` 的五支 JSON 於 2026-08-07 自 `dimanyen.github.io` 取得，
內容與 `docs/spec.md` §5.3 / §5.4 的黃金樣本逐筆相符（含 friend2 的 `yyyy/MM/dd`、
friend1 的 004/005 同名不同 fid、friend3 的 2 筆 `status == 0`）。

## Phase 5 Hashimoto log

| Bug class | Guardrail added | Type |
|-----------|----------------|------|
| 用字串比較 `updateDate`（本題主陷阱） | `test_updateDate_normalizationBeatsNaiveStringComparison` 先斷言字串比較確實是反的，再斷言正規化後推翻它 | 測試 |
| 同上，型別層防線 | `UpdateDate` 不暴露可比較的字串；`rawValue` 不參與 `Comparable` | 型別設計 |
| 未知日期格式靜默排錯序 | `UpdateDate` 未知格式 throw + `test_updateDate_rejectsUnrecognizedFormats` | 測試 |
| 把 `isTop` 解碼放寬成同時吃 Bool/Int | `test_decode_rejectsNonStringIsTop` | 測試 |
| 把 `status` 解碼放寬成同時吃字串 | `test_decode_rejectsNonNumberStatus` | 測試 |
| 邀請卡片判定散落多處 / 改回 `status == 2` | `test_invitationCard_isStatusZero`、`test_onlyStatusZeroIsInvitationCard`、`test_statusTwoIsNotInvitationCard` | 測試 |
| 用 `name` 去重 | `test_decode_friend1_hasSameNameWithDistinctFids` 把「同名不同 fid」前提釘死 | 測試 |

## Open questions

- 無阻斷性問題。若面試官對 `status` 語意有相反認定，`spec.md` §10 O-1 已說明可一行切換。

## Next actions

1. ~~`/clear` 重置 context~~ ✓
2. ~~建立 Xcode 專案（iOS 15+，無 Storyboard）~~ ✓ 專案名為 `koko`，Step 0 已去 Storyboard 化
3. ~~PEV Step 1：Model 層~~ ✓ 已完成，**等使用者跑 test 回報**
4. PEV Step 2：`FriendMerger` 純函式 + `test_merge_goldenSample`
   （黃金樣本表在 `docs/spec.md` §5.3）。
5. PEV Step 3：`APIClient` / `Endpoint` / `FriendRepository`（`async let` 並行）。
6. 之後才進 UI（ScenarioPicker → FriendList），並刪除 `RootPlaceholderViewController`。

## Notes

- 使用者自己跑 build／test／模擬器，agent 不要代跑；agent 只跑 lint 這類不需編譯的檢查。
- 測試一律用 `KOKOFriendsTests/Fixtures/` 的離線 JSON，不打真實網路。
- 交付物包含**錄影檔**，需涵蓋三種情境與四項加分功能（AC-17）。
