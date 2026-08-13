# Feature Spec：KOKO 好友列表頁

國泰世華 iOS 面試考題 — 曾子庭
最後更新：2026-08-07　版本：v1.0（Phase 3 定稿）

---

## 1. Goal

以 **Swift + UIKit（純程式碼）+ MVVM + Swift Concurrency** 實作 KOKO 好友列表頁，
能依三種資料情境自動切換三種畫面狀態，並支援姓名關鍵字搜尋。

---

## 2. 來源文件

| 項目 | 位置 |
|---|---|
| 需求 PDF | `國泰世華iOS面試考題(urgent-曾子庭).pdf`（不入版控） |
| Zeplin 專案 | 連結見面試信件（不公開） |
| 設計規格摘錄 | `docs/design-spec.md` |

Zeplin 四個畫面：

| 畫面 | Zeplin screen id | 對應狀態 |
|---|---|---|
| 朋友_KOKO 好友_New Comer | `5d776380061b64a13531f133` | 狀態 A：無好友 |
| 朋友_KOKO 好友_列表 | `5d77637a8919b56be93718c5` | 狀態 B：有好友、無邀請 |
| 朋友_KOKO 好友_邀請待回覆 | `5d77637368f73118f9951870` | 狀態 C：有好友 + 邀請（收合） |
| 朋友_KOKO 好友_邀請展開 | `5d77637750db6d7380db8c87` | 狀態 C：有好友 + 邀請（展開） |

---

## 3. API Datasource

| 代號 | 用途 | URL |
|---|---|---|
| U | 使用者資料 | https://dimanyen.github.io/man.json |
| F1 | 好友列表 1 | https://dimanyen.github.io/friend1.json |
| F2 | 好友列表 2 | https://dimanyen.github.io/friend2.json |
| F3 | 好友列表含邀請 | https://dimanyen.github.io/friend3.json |
| F4 | 無資料 | https://dimanyen.github.io/friend4.json |

### 3.1 實際回應（已於 2026-08-07 驗證）

```jsonc
// man.json
{ "response": [ { "name": "蔡國泰", "kokoid": "Mike" } ] }

// friend4.json
{ "response": [] }
```

`friend1 / friend2 / friend3` 之 `response` 為好友物件陣列。

### 3.2 欄位定義

| 欄位 | 型別（JSON 實際型別） | 說明 |
|---|---|---|
| `name` | String | 姓名 |
| `status` | **Number** | `0` 邀請送出／`1` 已完成／`2` 邀請中 |
| `isTop` | **String**（`"0"` / `"1"`） | 是否顯示星星 |
| `fid` | String | 好友 id（唯一鍵） |
| `updateDate` | String | 資料更新時間 |

> ⚠️ **`status` 是數字、`isTop` 是字串**，兩者型別不一致，Decodable 必須分別處理。
> 不可假設 `isTop` 是 Bool 或 Int。

### 3.3 `updateDate` 格式不一致（關鍵陷阱）

| 來源 | 格式 | 範例 |
|---|---|---|
| friend1 / friend3 | `yyyyMMdd` | `20190801` |
| **friend2** | **`yyyy/MM/dd`** | **`2019/08/02`** |

**必須先正規化成可比較的日期後才能比大小。**

直接用字串比較會出錯：`"2019/08/02" < "20190801"`（因為 ASCII `/`(0x2F) < `0`(0x30)），
會導致合併時挑到錯誤的那一筆 → 情境二畫錯畫面（見 §5.3 推導）。

---

## 4. 狀態機定義

### 4.1 status 語意（**規範**）

依 Zeplin `邀請展開` 畫面註解 #1 / #3 / #5：

| status | 註解原文 | 呈現位置 |
|---|---|---|
| `0` | 「邀請送出」，在上方 Cell UI，待用戶同意 | **上方邀請卡片區**（可接受／拒絕） |
| `1` | 已完成 | 好友清單一般列 |
| `2` | 「邀請中」，待對方同意 | 好友清單列 + 灰色「邀請中」標籤 |

### 4.2 為什麼採用這個定義（推導，非臆測）

設計稿的假資料把 `彭安亭 / 施君凌`（friend3 中 `status=2`）畫成邀請卡片，
表面上與註解衝突。以需求 (2)-II 反推可證明註解才是對的：

- 需求 (2)-II 規定：`F1 + F2` 合併後的情境**必須呈現「好友列表無邀請」**（畫面 1-(2)）。
- 合併結果（見 §5.3）中，`翁勳儀` 為 **`status = 2`**。
- 若 `status=2` → 邀請卡片，情境二就會出現一張邀請卡片 → 與需求 (2)-II **矛盾**。
- 若 `status=0` → 邀請卡片，合併後 `status=0` 的筆數為 **0** → 無邀請卡片 → **符合**需求。

∴ **`status = 0` 才是邀請卡片。** 設計稿假資料為示意用途，不具規範效力。

> 註：`邀請待回覆` 畫面註解 #2 寫「根據status=2的人數」。此處採用同一推導反駁 ——
> 情境二 `status=2` 有 1 筆，但設計稿畫面 1-(2) 的「好友」tab **沒有任何 badge**。
> 故 badge 不是 status=2 的計數。見 §6.3。

### 4.3 三種畫面狀態

令合併後好友陣列為 `friends`：

```
invites = friends.filter { $0.status == 0 }
list    = friends.filter { $0.status == 1 || $0.status == 2 }
```

| 狀態 | 判定條件 | 呈現 |
|---|---|---|
| **A 無好友** | `friends.isEmpty` | 空狀態插圖 + 「就從加好友開始吧：）」 + 加好友按鈕 |
| **B 好友無邀請** | `!friends.isEmpty && invites.isEmpty` | 搜尋框 + 好友清單 |
| **C 好友含邀請** | `!invites.isEmpty` | 邀請卡片區 + 搜尋框 + 好友清單 |

> 狀態 A 的判定用 `friends`（全部），不是 `list`。
> 若某次資料只有邀請沒有好友，仍屬狀態 C。

---

## 5. 情境（起始頁選單）

App 啟動先進入**獨立的情境選擇首頁**，列出三個選項，點擊後 push 至好友列表頁。

| 情境 | 選單標題 | 請求 | 期望畫面 |
|---|---|---|---|
| I | 無好友 | `U` + `F4` | 狀態 A |
| II | 只有好友列表 | `U` + `F1` + `F2`（合併） | 狀態 B |
| III | 好友列表含邀請 | `U` + `F3` | 狀態 C |

- 三種情境的 `U`（使用者資料）都要打，用於填 header 的姓名與 KOKO ID。
- 所有請求皆為**非同步**，好友 API 與使用者 API **並行**發出。

### 5.1 合併規則（情境 II）

1. 並行取得 `F1`、`F2`，兩者都成功才合併。
2. 以 `fid` 為唯一鍵分組。
3. 同 `fid` 多筆時，取 **正規化後 `updateDate` 較新**的那一筆（整筆取代，不做欄位級合併）。
4. `updateDate` 完全相同時，取**後出現**的那一筆（穩定、可預期即可）。

> **不可用 `name` 去重。** friend1 中 `fid=004` 與 `fid=005` 都叫「梁立璇」，
> 用姓名去重會少一筆。

### 5.2 排序規則

好友清單排序：**`isTop == "1"` 置頂**，其餘維持合併後的原始順序（穩定排序）。

> 設計稿中星號好友（翁勳儀、洪佳妤）並未排在最前，但置頂是 `isTop` 唯一合理的語意。
> 此為明確的規格決定，見 §10 開放議題 O-2。

### 5.3 情境 II 合併結果（驗收用黃金樣本）

| fid | name | F1 | F2 | 勝出 | 最終 status | isTop |
|---|---|---|---|---|---|---|
| 001 | 黃靖僑 | 2019-08-01 / s0 | **2019-08-02 / s1** | F2 | 1 | "0" |
| 002 | 翁勳儀 | **2019-08-02 / s2** | 2019-08-01 / s1 | F1 | 2 | "1" |
| 003 | 洪佳妤 | 2019-08-04 / s1 | — | F1 | 1 | "0" |
| 004 | 梁立璇 | 2019-08-01 / s1 | — | F1 | 1 | "0" |
| 005 | 梁立璇 | 2019-08-04 / s1 | — | F1 | 1 | "0" |
| 012 | 林宜真 | — | 2019-08-01 / s1 | F2 | 1 | "0" |

**共 6 筆；`status=0` 有 0 筆 → 無邀請卡片 → 狀態 B。✓**

### 5.4 情境 III 結果（驗收用黃金樣本）

| 區塊 | 內容 |
|---|---|
| 邀請卡片（status 0） | 黃靖僑(001)、翁勳儀(002) → **2 張** |
| 好友清單 | 洪佳妤(003, s1)、彭安亭(007, s2 顯示「邀請中」)、施君凌(008, s2 顯示「邀請中」) |
| 好友 tab badge | `2` |

---

## 6. 畫面規格

完整色票、字級、間距見 `docs/design-spec.md`。以下為行為規格。

### 6.1 Header（三種狀態共用）

- 大頭貼（右上，圓形）
- 姓名：來自 `man.json` 的 `name`
- KOKO ID：
  - 有 `kokoid` → 顯示 `KOKO ID : {kokoid}` + `>`
  - 無 `kokoid` → 顯示 `設定 KOKO ID` + `>` + 粉紅小圓點（見 New Comer 稿）

### 6.2 邀請卡片區（狀態 C）

- 每張卡片：頭像、姓名、副標「邀請你成為好友：）」、✓ 接受、✕ 拒絕
- **收合態**（`邀請待回覆` 稿）：只露出第一張，第二張以錯位陰影露出底邊，暗示可展開
- **展開態**（`邀請展開` 稿）：所有卡片完整列出
- 點擊卡片區切換收合／展開（加分項目 3）
- ✓ / ✕ 為 UI 行為：本地移除該筆邀請並更新畫面狀態；**無對應 API，不做後端請求**

### 6.3 Tab 列

- 「好友」／「聊天」兩個 tab，底線指示器在「好友」
- 「聊天」badge：**固定 `99+`**（Zeplin 註解 #3），但**狀態 A 不顯示**
  —— New Comer 稿的「聊天」沒有 badge，一個好友都沒有的新用戶不會有 99+ 則聊天。
  「固定 99+」的意思是「要顯示時寫死 99+」（本題無聊天 API），不是「永遠顯示」
- 「好友」badge：**邀請卡片數（`status=0` 筆數）**；為 0 時**隱藏**
  - 依據：設計稿 1-(2) 的「好友」tab 無 badge，而該情境 `status=2` 有 1 筆 → badge 非 status=2 計數

### 6.4 搜尋框

- Placeholder：`想轉一筆給誰呢？`
- 右側「加好友」圖示按鈕
- 對**已取得的好友清單**做**姓名關鍵字篩選**（本地篩選，不重新打 API）
- 大小寫不敏感、可子字串比對；清空關鍵字還原完整清單
- **只篩選好友清單，不篩選邀請卡片區**
- 搜尋無結果時：顯示空清單（不切換成狀態 A 空狀態畫面）

### 6.5 好友 Cell

| 元素 | 規則 |
|---|---|
| 星星 | `isTop == "1"` 才顯示 |
| 頭像 | 無圖示一律用 default 頭像（Zeplin 註解 #1） |
| 姓名 | `name` |
| 轉帳按鈕 | 粉紅外框，恆常顯示 |
| 邀請中標籤 | `status == 2` 才顯示，灰色外框，不可點 |
| `⋯` 更多 | `status == 1` 顯示（與「邀請中」互斥） |

### 6.6 狀態 A（無好友）

插圖 + 「就從加好友開始吧：）」+「與好友們一起用 KOKO 聊起來！／還能互相收付款、發紅包喔：）」
+ 綠色漸層「加好友」按鈕 + 底部「幫助好友更快找到你？<u>設定 KOKO ID</u>」

---

## 7. 架構

```
情境選擇頁 ──push──▶ 好友列表頁
                        │
                   FriendListViewModel
                        │
                   FriendRepository
                        │
                   APIClient (URLSession + async/await)
```

- **Model**：`User`、`Friend`（Decodable，含 `updateDate` 正規化）
- **ViewModel**：持有 `@Published`／`AsyncStream` 形式的 view state；**不 import UIKit**
- **View**：`UIViewController` + `UITableView`（純程式碼），只依 view state 更新畫面
- 網路併發：`async let` 併發送出，錯誤以 `throw` 往上拋

### 7.1 View State

ViewModel 對外只暴露**單一** view state。header（§6.1）三種狀態共用，
故 `user` 與內容狀態並列，不放在個別 case 內。

```swift
struct FriendListViewState {
    let user: User?          // nil = 尚未載入，header 顯示骨架
    let content: Content

    enum Content {
        case loading
        case empty                                         // 狀態 A
        case loaded(invites: [Friend], friends: [Friend])  // 狀態 B / C
        case failed(Error)
    }
}
```

- `invites`：`status == 0`，即邀請卡片區；**不受搜尋關鍵字影響**（§6.4）。
- `friends`：其餘好友，已套用置頂排序（§5.2）與搜尋篩選（§6.4）。
- 「好友」tab badge 取 `invites.count`，為 0 時隱藏（§6.3）。

---

## 8. Acceptance Criteria

### 必要需求

- [ ] AC-1　起始頁可選三種情境，點擊後進入好友列表頁
- [ ] AC-2　情境 I（F4）呈現狀態 A 無好友畫面
- [ ] AC-3　情境 II（F1+F2）**並行**請求兩支 API，合併去重後呈現狀態 B
- [ ] AC-4　合併結果與 §5.3 黃金樣本完全一致（6 筆、fid/status/isTop 逐筆相符）
- [ ] AC-5　`updateDate` 兩種格式皆正確正規化；`2019/08/02` 判定為晚於 `20190801`
- [ ] AC-6　情境 III（F3）呈現狀態 C，邀請卡片 2 張、好友清單 3 筆、badge 顯示 2
- [ ] AC-7　`status=2` 的列顯示「邀請中」標籤；`status=1` 顯示 `⋯`
- [ ] AC-8　`isTop == "1"` 顯示星星並置頂
- [ ] AC-9　搜尋框輸入關鍵字即時篩選好友姓名；清空後還原
- [ ] AC-10　header 姓名與 KOKO ID 取自 `man.json`
- [ ] AC-11　全程無 SwiftUI；架構為 MVVM，ViewModel 不 import UIKit

### 加分項目（四項全做）

- [x] AC-12　好友列表支援下拉更新，重新呼叫該情境的 API
- [x] AC-13　點擊搜尋框時，畫面上推使搜尋框置頂至 navigationBar 下方；取消時還原
      —— 設計稿沒有 navigation bar，改為置頂至 `TopActionBarView` 下方，語意相同
- [x] AC-14　邀請卡片區支援展開／收合動畫
- [ ] AC-15　Unit Test 覆蓋：合併去重、日期正規化、搜尋篩選、狀態判定、Decodable 型別

### 交付

- [ ] AC-16　程式碼
- [ ] AC-17　錄影檔，涵蓋三種情境與四項加分功能

---

## 9. Test Standards

### Unit Test（必測，皆為純函式／ViewModel 層，不需網路）

| 測項 | 內容 |
|---|---|
| `test_updateDate_normalization` | `20190801` 與 `2019/08/02` 正規化後可正確比較 |
| `test_merge_goldenSample` | F1+F2 合併結果 == §5.3 表格 |
| `test_merge_dedupeByFid_notByName` | 004 / 005 兩筆「梁立璇」都保留 |
| `test_merge_picksNewerRecord` | 001 取 F2、002 取 F1 |
| `test_state_empty` | F4 → `.empty` |
| `test_state_loadedWithoutInvites` | F1+F2 → invites 為空 |
| `test_state_loadedWithInvites` | F3 → invites 2 筆、friends 3 筆 |
| `test_search_filtersFriendsOnly` | 關鍵字不影響邀請卡片區 |
| `test_search_emptyKeywordRestoresAll` | 清空還原 |
| `test_decode_isTopIsString_statusIsNumber` | 型別解析正確 |

固定用 bundle 內的 JSON fixture，不打真實網路。

### 手動驗證（錄影涵蓋）

三種情境切換、下拉更新、搜尋框上推、邀請卡片展開收合。

---

## 10. Open Issues（已決議，記錄理由）

| # | 議題 | 決議 |
|---|---|---|
| O-1 | 設計稿假資料把 `status=2` 畫成邀請卡片，與註解衝突 | 採註解 + 需求 (2)-II 反推：**`status=0` 為邀請卡片**（§4.2）。實作時集中成單一常數，若面試官認定相反可一行切換 |
| O-2 | `isTop` 是否置頂排序，設計稿未明確呈現 | 置頂（§5.2） |
| O-3 | 邀請 ✓／✕ 無對應 API | 僅做本地 UI 行為（§6.2） |
| O-4 | 網路失敗行為，需求未提 | 顯示錯誤提示 + 重試；不做自動重試 |
| O-5 | §7.1 初版的 `enum FriendListViewState` 沒有容納 header 用的 `user`，但 §6.1 規定 header 三種狀態共用 | 改為 `struct FriendListViewState { user, content }`，四個 case 原樣移入 `Content`。仍是單一 view state，符合 CLAUDE.md rule 3（2026-08-07 決議） |
| O-6 | §6.2 寫「✓ 接受」與「✕ 拒絕」都是「本地移除該筆邀請」，但接受後該人理應成為好友、出現在下方清單 | **依 spec 字面實作：兩者都只是移除。** 理由：無對應 API，且 spec 為唯一真實來源。若錄影時覺得「接受後人消失」觀感不佳，改成接受→`status` 轉 `1` 併入好友清單即可，僅影響 ViewModel 一個方法 |

---

## 11. Out of Scope

- 「聊天」tab 與底部 TabBar 其他分頁**可以切換，但內容為空白畫面**
  （2026-08-08 需求變更；原訂「僅呈現靜態外觀、不可點」）
- 中央 KO 按鈕**同樣是可切換的分頁**，內容也是空白畫面
  （2026-08-12 需求變更；原訂不可點）
- 「聊天」與其他分頁的**實際內容**
- 轉帳、加好友、設定 KOKO ID 的實際功能（按鈕存在但不接行為）
- 頂部功能列 ATM／換匯／掃描的實際功能（2026-08-12 依設計稿補上，同樣只有外觀）
- 大頭貼真實圖片下載（一律使用 default 頭像，依 Zeplin 註解 #1）
- 任何第三方套件
