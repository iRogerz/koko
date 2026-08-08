# SDD Progress — KOKO 好友列表（國泰世華 iOS 面試考題）

Last updated: 2026-08-08

## Current phase

**Phase 4 進行中**（PEV Loop）。資料層與 DesignSystem 完成，Step 6 起為好友列表頁 UI。

## Completed phases

- [x] Phase 1: Brain Dump — 來源為需求 PDF + Zeplin 四張設計稿 + 五支 API 實際回應
- [x] Phase 2: Spec Interview — 四個技術選型問題已由使用者拍板（見下）
- [x] Phase 3: Project Constitution + Feature Spec — `CLAUDE.md`、`docs/spec.md`、`docs/design-spec.md`
- [~] Phase 4: Context Reset + PEV Loop —— Step 0～5 完成
- [~] Phase 5: Anti-Drift + Hashimoto —— `scripts/check-architecture.sh` 已上線
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
| 0 | 專案去 Storyboard 化，改純程式碼啟動 | 刪 `Main.storyboard` / `LaunchScreen.storyboard` / 樣板 `ViewController.swift`；`Info.plist` 移除 `UISceneStoryboardFile`、改用 `UILaunchScreen` 空 dict；`project.pbxproj` 移除 `INFOPLIST_KEY_UIMainStoryboardFile` 與 `INFOPLIST_KEY_UILaunchStoryboardName`；deployment target `26.1` → `15.0`；`SceneDelegate` 以程式碼建立 `UIWindow` | grep 全專案無 `.storyboard` / `.xib` / `import SwiftUI` ✓；使用者回報 build 與 Cmd+R 正常 ✓ | **✅ 完成** |
| 1 | Model 層：`User` / `Friend` / `FriendStatus` Decodable + `updateDate` 正規化，測試先寫 | 新增 `Model/{UpdateDate,FriendStatus,Friend,User,APIResponse}.swift`；測試 `kokoTests/Model/*` 四檔 + `Support/FixtureLoader.swift`；`Fixtures/` 放入五支 API 的實際回應 | 全部 Model 檔只 `import Foundation` ✓；使用者回報測試全過 ✓ | **✅ 完成** |
| 2 | 合併去重（§5.1）與 `isTop` 置頂排序（§5.2）純函式，測試先寫 | 新增 `Repository/{FriendMerger,FriendSorter}.swift`；測試 `kokoTests/Repository/*` 兩檔 + `Support/FriendBuilder.swift` | Repository 層只 `import Foundation` ✓；使用者回報測試全過 ✓（含 §5.3 黃金樣本逐欄比對） | **✅ 完成** |
| 3 | Network + Repository：`HTTPClient` protocol、`Endpoint`、`APIClient`、`FriendRepository`（`async let` 並行），測試先寫 | 新增 `Network/{Endpoint,HTTPClient,URLSessionHTTPClient,APIClient}.swift`、`Model/Scenario.swift`、`Repository/FriendRepository.swift`；測試 `kokoTests/Network/*` 兩檔 + `Repository/FriendRepositoryTests.swift` + `Support/{StubHTTPClient,XCTestAsyncHelpers}.swift` | Network / Repository 層只 `import Foundation` ✓；使用者回報測試全過 ✓（含 AC-3 並行量測） | **✅ 完成** |
| 4 | ViewModel：`FriendListViewState` + `FriendListViewModel`（`@Published`）、搜尋篩選純函式，測試先寫 | 新增 `Scene/FriendList/{FriendListViewState,FriendListViewModel}.swift`、`Repository/FriendSearch.swift`；測試 `kokoTests/Scene/FriendListViewModelTests.swift` + `Repository/FriendSearchTests.swift` + `Support/StubFriendRepository.swift`；另補 `scripts/check-architecture.sh` | `./scripts/check-architecture.sh` 全綠且經負面測試 ✓；使用者回報測試全過 ✓（23/23） | **✅ 完成** |

| 5 | DesignSystem token（色票／字級／間距／素材）＋情境選擇頁 ScenarioPicker | 安裝 11 個 Zeplin PDF 向量素材進 Asset Catalog；新增 `DesignSystem/{AppColor,AppText,Spacing,AppImage}.swift`、`Scene/ScenarioPicker/*`；刪除 `RootPlaceholderViewController`，`SceneDelegate` 改以 ScenarioPicker 為 root；新增暫時的 `FriendListProbeViewController` 作為 push 目的地 | 架構檢查全綠 ✓；使用者回報測試全過 ✓、Cmd+R 三情境畫面正確 ✓（含真實網路端到端） | **✅ 完成** |

### Step 0 決策

- **`LaunchScreen.storyboard` 一併刪除**，改用 `Info.plist` 的 `UILaunchScreen` 空 dict（iOS 14+ 機制）。
  理由：憲法寫的是 no Storyboard，留一個 storyboard 只為了啟動畫面不一致。
- 曾以 `App/RootPlaceholderViewController.swift` 作為暫時 root，**Step 5 已刪除**，
  改為 ScenarioPicker。
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

### Step 5 決策

- **素材全部是 Zeplin 匯出的 PDF 向量檔**，以 `Single Scale` + `preserves-vector-representation`
  安裝進 Asset Catalog，一個檔吃所有解析度，不需要 @1x/@2x/@3x 三份。
- **imageset 名稱沿用 Zeplin 檔名**（`icTabbarFriendsOn` 等），保留回溯設計稿的線索；
  語意化命名放在 `AppImage` 的 case 名稱上，呼叫端不寫字串。
- **`AppImage.image` 在素材缺漏時 `assertionFailure`**，不靜默回傳空白 —— 靜默變空白比崩潰難查。
  另有 `test_allImages_resolveFromAssetCatalog` 覆蓋全部 case。
- **色票依 design-spec 的「建議命名」改名**。Zeplin 的 `hot pink`／`very light pink`／
  `transferMoney` 各有兩個不同值，測試 `test_duplicatelyNamedZeplinColors_areDistinct`
  釘住「同名者必須解析成不同值」。
- **字級封裝成 `TextStyle`（字體＋顏色＋行高＋字距）**，而不是只給 `UIFont`。
  design-spec 有行高與字距的規格，只給字體的話 ViewController 還是得自己組
  paragraph style，等於把魔術數字搬個位置。
- **`Scenario` 的顯示文字放在 Scene 層**（`Scenario+Display.swift`），Model 層保持無 UI 文字。
- **新增暫時的 `FriendListProbeViewController`**：讓情境選擇頁點下去有目的地，
  同時是 `URLSessionHTTPClient` 唯一的實際驗證（單元測試一律注入 stub，那層沒被覆蓋）。
  Step 6 完成後整檔刪除。

### Step 4 決策

- **View state 改為 `struct { user, content }`**，四個 case 原樣移入 `Content`。
  原因：§7.1 初版的 enum 沒有容納 header 用的 `user`，但 §6.1 規定 header 三種狀態共用。
  已回寫 `docs/spec.md` §7.1 並記為 O-5。仍是單一 view state，符合 CLAUDE.md rule 3。
- **ViewModel 只保留一份 `allFriends`（完整清單），搜尋與分區都即時推導。**
  不另存「篩選後的清單」——那會產生兩份真實來源，清空關鍵字就可能還原不回去。
- **`@Published private(set)` 的投影值 `$state` 在型別外不可見**，
  故另開唯讀的 `statePublisher: AnyPublisher<...>` 給 View 訂閱。
- **`refresh()` 不切回 `.loading`**（AC-12）：下拉本身已有轉圈動畫，再閃骨架很突兀。
  寫成測試 `test_refresh_doesNotShowLoadingState`。
- **空狀態判定寫在 `makeContent()` 開頭的 `guard !allFriends.isEmpty`**，
  用的是合併後**總數**。只有邀請沒有一般好友時仍是狀態 C
  （`test_load_withOnlyInvitations_isNotEmpty` 釘住這點）。
- **接受／拒絕邀請都只是本地移除**，依 spec §6.2 字面實作，見 O-6。
  若錄影時觀感不佳，改成接受→轉 `status 1` 只影響一個方法。

### Step 3 決策

- **網路層抽成 `HTTPClient` protocol**（`func data(from:) async throws -> Data`），
  由 `URLSessionHTTPClient` 正式實作、`StubHTTPClient` 測試注入。
  選它而非 `URLProtocol` 攔截：不必為了測試去動 `URLSession` 設定，
  且測試可以直接觀測「請求了哪些 URL、同時在途幾個」。
- **`URLSessionHTTPClient` 刻意做到極薄**（只有發請求 + 檢查狀態碼），
  所有值得測的邏輯都推到 `APIClient` 與 `FriendRepository`。
  代價：狀態碼檢查本身不在單元測試覆蓋範圍內，這是有意識的取捨。
- **`APIClient` / `FriendRepository` 標記 `Sendable`**，`JSONDecoder` 不做成儲存屬性
  （它非 Sendable），改為解碼當下建立。這兩層本來就無狀態，
  這樣跨 `async let` 邊界不會產生一串 Sendable 警告。
- **`Scenario` 放 Model 層且不含任何顯示文字**。選單標題屬 UI copy，留給 Scene 層。
- **Repository 回傳的 `friends` 是「已合併、未排序、未分區」的完整清單。**
  拆邀請卡片區／好友清單（§4.3）與置頂排序（§5.2）都是畫面狀態的推導，屬 ViewModel。
- **AC-3 的「並行」寫成可驗證的測試**：`StubHTTPClient` 是 actor，
  記錄同時在途的最大請求數。情境 II 應為 3（U + F1 + F2），
  單一清單情境應為 2。改成循序 `await` 會讓數字掉到 1 而測試失敗。

### Step 2 決策

- **合併與排序拆成兩個型別**（`FriendMerger` / `FriendSorter`），對應 spec §5.1 與 §5.2
  兩條獨立規則，各自可單獨測試。兩者都是 `enum` 命名空間 + static 純函式，無狀態。
- **勝出比較用 `>=` 而非 `>`**，直接落實 §5.1 規則 4「日期相同取後出現者」，
  不需要額外的 tie-break 分支。
- **輸出順序 = 各 `fid` 首次出現的順序**（另存一個 `orderOfFirstAppearance` 陣列）。
  Dictionary 本身無序，只靠它會得到不穩定的結果，黃金樣本會隨機失敗。
- **排序刻意不用 `sorted(by:)`。** Swift 的 `sort` **不保證穩定**，
  而 §5.2 要求「其餘維持合併後的原始順序」。改用 `filter(\.isTop) + filter { !$0.isTop }`，
  從實作上保證穩定性，不依賴標準函式庫未承諾的行為。

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
| 合併時把日期比較換回字串比較 | `test_merge_usesNormalizedDate_notStringOrder` —— 直接斷言 fid 001 合併後是 `.completed`，字串比較會得到 `.invitationSent` | 測試 |
| 合併輸出順序依賴 Dictionary（不穩定） | `test_merge_preservesFirstAppearanceOrder`、`test_merge_replacedRecordKeepsOriginalPosition` | 測試 |
| 排序改用不保證穩定的 `sorted(by:)` | `test_sort_isStableAmongTop`、`test_sort_isStableAmongNonTop` | 測試 |
| 合併改用 `name` 當鍵 | `test_merge_dedupeByFid_notByName`、`test_merge_sameNameDifferentFid_areBothKept` | 測試 |
| 把並行 `async let` 改成循序 `await`（AC-3 退化） | `test_load_friendsOnly_requestsInParallel` 量測最大在途請求數，循序會掉到 1 | 測試 |
| API 網址打錯（stub 測試看不出來） | `EndpointTests.test_endpoint_urls` 逐字釘死五支網址 | 測試 |
| 失敗時偷偷自動重試 | `test_load_doesNotRetryOnFailure` 斷言請求次數為 1（O-4） | 測試 |
| F1/F2 其一失敗卻仍回傳部分結果 | `test_load_friendsOnly_failsIfEitherListFails`（§5.1 規則 1） | 測試 |
| **`@MainActor` 測試類別內寫同步 `test_` 方法 → SIGABRT** | `scripts/check-architecture.sh` 規則 3 | lint 腳本 |
| ViewModel／ViewState 誤 import UIKit（AC-11） | 同上 規則 1（行首比對，註解不誤報） | lint 腳本 |
| 資料層誤 import UIKit | 同上 規則 2 | lint 腳本 |
| 誤加回 Storyboard／XIB／SwiftUI | 同上 規則 4、5 | lint 腳本 |

### Hashimoto 案例詳述：MainActor 同步測試方法（2026-08-07）

**症狀**：`test_initialState_isLoadingWithoutUser` crash，訊息是
`malloc: *** error for object 0x262c5e6f0: pointer being freed was not allocated`。

**定位過程中有用的觀察**：

1. 三次執行、三個不同 process，**位址完全相同** → 確定性錯誤，排除 data race。
2. 位址固定且低，符合「常數／immortal 物件被 free」的特徵。
3. 從 `.xcresult` 讀出 **23 個測試 22 個通過**，只有這一個 crash
   （`xcrun xcresulttool get test-results summary --path <xcresult>`）——
   這一步最關鍵，推翻了先前「`User.stub` static let 有問題」的錯誤假設。
4. 該測試是全類別**唯一的同步方法**，其餘 22 個都是 `async`。

**原因**：類別標了 `@MainActor`。XCTest 透過 ObjC runtime 呼叫同步測試方法，
與 MainActor 隔離檢查衝突而 abort。`async` 測試走 Swift concurrency runtime，不受影響。

**修正**：測試方法改成 `async`（一個字）。

**教訓**：錯誤訊息完全不提 MainActor，靠讀訊息永遠猜不到。
`.xcresult` 的通過／失敗分佈才是決定性線索 —— 下次先讀它，不要從錯誤訊息開始猜。

**腳本本身也踩了兩個坑**（都是寫完立刻用假違規驗證才發現）：
- `set -u` + process substitution + `local` → 改用 `for` 迴圈。
- `"$file：..."` 的**全形冒號是多位元組字元，bash 會併進變數名** → 必須寫成 `"${file}："`。
  這也說明「從不亮紅燈的檢查等於沒有檢查」，guardrail 一定要用假違規驗證過。
| 空狀態誤用「一般好友數為 0」判定 | `test_load_withOnlyInvitations_isNotEmpty` —— 只有邀請時仍須是狀態 C | 測試 |
| 搜尋無結果誤切成空狀態畫面 | `test_search_withNoMatches_staysLoadedWithEmptyList` | 測試 |
| 搜尋誤篩到邀請卡片區 | `test_search_filtersFriendListButNotInvitations` | 測試 |
| 下拉更新時清掉搜尋關鍵字／閃回骨架 | `test_refresh_keepsActiveKeyword`、`test_refresh_doesNotShowLoadingState` | 測試 |
| 邀請 ✓/✕ 偷打後端 API | `test_respondToInvitation_removesItLocally` 斷言 loadCount 不變（§6.2） | 測試 |
| **架構規則靠人工 grep 檢查（會被註解誤導）** | `scripts/check-architecture.sh` —— 行首比對 import、涵蓋 rule 1/2、SwiftUI、Storyboard、邀請判定集中性；已做負面測試確認會回非零 exit code | 腳本 |

## Open questions

- 無阻斷性問題。若面試官對 `status` 語意有相反認定，`spec.md` §10 O-1 已說明可一行切換。

## Next actions

1. ~~`/clear` 重置 context~~ ✓
2. ~~建立 Xcode 專案（iOS 15+，無 Storyboard）~~ ✓ 專案名為 `koko`，Step 0 已去 Storyboard 化
3. ~~PEV Step 1：Model 層~~ ✓ 測試全過
4. ~~PEV Step 2：`FriendMerger` 純函式 + `test_merge_goldenSample`~~ ✓ 測試全過
5. ~~PEV Step 3：`APIClient` / `Endpoint` / `FriendRepository`（`async let` 並行）~~ ✓ 測試全過
6. ~~PEV Step 4：`FriendListViewModel` + `FriendListViewState`~~ ✓ 測試全過（23/23）
7. ~~PEV Step 5：`DesignSystem/` ＋情境選擇頁 ScenarioPicker~~ ✓ 已完成，**等使用者跑 test 回報**
8. PEV Step 6：好友列表頁 UI（header／tab／搜尋框／邀請卡片／好友 cell／空狀態／TabBar）
   ＋三種狀態；完成後刪除 `FriendListProbeViewController`。
9. PEV Step 7：三項 UI 加分（下拉更新、搜尋框上推、邀請卡片展開收合）。
10. 最後：錄影（AC-17，涵蓋三種情境與四項加分功能）。

> 資料層（Model／Network／Repository／ViewModel）到此全部完成，後續都是畫面。
> 每次動 code 後跑 `./scripts/check-architecture.sh`（不需編譯，agent 可自行執行）。

## Notes

- 使用者自己跑 build／test／模擬器，agent 不要代跑；agent 只跑 lint 這類不需編譯的檢查。
- 測試一律用 `koko/kokoTests/Fixtures/` 的離線 JSON，不打真實網路。
- **`@MainActor` 測試類別內的 test 方法一律寫成 `async`**，同步方法會 SIGABRT，見 Hashimoto log。
- 讀測試結果用 `xcrun xcresulttool get test-results summary --path <xcresult>`，
  比從 console 訊息猜快得多。
- 交付物包含**錄影檔**，需涵蓋三種情境與四項加分功能（AC-17）。
