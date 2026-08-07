# 設計規格摘錄（Zeplin）

專案：iOS Interview（Zeplin 連結見面試信件，不公開）
擷取日期：2026-08-07　Platform：iOS　基準尺寸：375 × 667（iPhone 8）

---

## 1. 色票（Local styleguide）

Zeplin 上的命名有重複與錯置（同名不同值），下表以 **實際數值** 為準，
`建議命名` 是實作時應採用的語意名稱。

| Zeplin 名稱 | RGB | Hex | 建議命名 | 用途 |
|---|---|---|---|---|
| hot pink | 236, 0, 140 | `#EC008C` | `kokoPink` | 主色：轉帳外框、tab 指示器、badge、✓ 按鈕 |
| very light pink | 249, 178, 220 | `#F9B2DC` | `kokoPinkLight` | badge 底色 |
| appleGreen | 121, 196, 27 | `#79C41B` | `greenPrimary` | 「加好友」按鈕漸層 |
| frogGreen | 86, 179, 11 | `#56B30B` | `greenDark` | 「加好友」按鈕漸層 |
| b | 166, 204, 66 | `#A6CC42` | `greenLight` | 「加好友」按鈕漸層 |
| appleGreen40 | 121, 196, 27 @ 40% | `#79C41B` 40% | `greenShadow` | 按鈕陰影 |
| lightGrey | white 71 | `#474747` | `textPrimary` | 主要文字 |
| warmGrey | white 153 | `#999999` | `textSecondary` | 次要文字、placeholder |
| pinkishGrey | white 201 | `#C9C9C9` | `borderDisabled` | 「邀請中」外框、✕ 按鈕 |
| transferMoney | white 228 | `#E4E4E4` | `separator` | 分隔線 |
| transferMoney | white 239 | `#EFEFEF` | `searchBarBg` | 搜尋框底色 |
| white | white 245 | `#F5F5F5` | `pageBg` | 頁面底色 |
| hot pink | white 252 | `#FCFCFC` | `cardBg` | 卡片底色 |
| very light pink | white 255 | `#FFFFFF` | `surface` | 純白 |
| very light pink | 142, 142, 147 | `#8E8E93` | `systemGrey` | 系統灰（iOS 標準） |

> ⚠️ `hot pink`、`very light pink`、`transferMoney` 各有兩個不同值的定義。
> 直接用 Zeplin 匯出的 `UIColor+Additions` 會產生重複的 method 名稱而編譯失敗。
> **必須自行改名**後再使用。

---

## 2. 字型（Local styleguide）

全部為 **PingFang TC**（`PingFangTC-Regular` / `PingFangTC-Medium`）。

| Zeplin 名稱 | 字重 | 大小 | 行高 | 字距 | 顏色 | 用途推斷 |
|---|---|---|---|---|---|---|
| Text Style 6 | Medium | 21pt | — | — | `#474747` | 空狀態主標題「就從加好友開始吧：）」 |
| Text Style 4 | Medium | 17pt | 18pt | — | `#474747` | Header 姓名、好友姓名 |
| Text Style 3 | Regular | 16pt | — | 0 | `#474747` | 邀請卡片姓名 |
| Text Style 5 | Medium | 14pt | — | 0 | `#999999` | Tab 標題、搜尋框 placeholder |
| Text Style 2 | Medium | 13pt | 18pt | — | `#474747` | 「轉帳」按鈕文字 |
| Text Style | Regular | 13pt | 18pt | — | `#474747` | 空狀態副標、KOKO ID |
| Text Style 7 | Medium | 11pt | — | 1pt | `#999999` | TabBar 文字、「邀請中」標籤 |

---

## 3. 間距 Token

| Token | 值 |
|---|---|
| `spacing-xs` | 4pt |
| `spacing-s` | 8pt |
| `spacing-m` | 12pt |
| `spacing-l` | 16pt |

---

## 4. 畫面元素

### 4.1 Header（三種狀態共用）

- 姓名：Text Style 4（Medium 17pt / `#474747`）
- KOKO ID 列：Text Style（Regular 13pt）+ `>` 箭頭
  - New Comer 稿為「設定 KOKO ID ＞ ●」，末端有粉紅小圓點
  - 其他稿為「KOKO ID：olylinhuang ＞」
- 大頭貼：右側，圓形

### 4.2 Tab 列

- 「好友」／「聊天」，Text Style 5（Medium 14pt）
- 選中：`#EC008C` 文字 + 下方 2pt 粉紅指示器；未選中：`#999999`
- Badge：圓角膠囊，底 `#F9B2DC`／字 `#EC008C`
  - 聊天固定 `99+`
  - 好友為邀請卡片數，0 時隱藏

### 4.3 搜尋框

- 底色 `#EFEFEF`，圓角膠囊
- 左側放大鏡圖示（`#999999`）
- Placeholder「想轉一筆給誰呢？」Text Style 5
- 右側獨立的「加好友」粉紅圖示按鈕（在搜尋框外）

### 4.4 邀請卡片

- 白底 `#FCFCFC`，圓角 + 陰影
- 左：圓形頭像
- 中：姓名 Text Style 3（Regular 16pt）／副標「邀請你成為好友：）」`#999999`
- 右：✓ 圓形粉紅外框 `#EC008C`、✕ 圓形灰外框 `#C9C9C9`
- 收合態：第二張卡片以錯位方式露出底邊
- 展開態：卡片垂直堆疊，間距約 8pt

### 4.5 好友 Cell

由左至右：

1. 星星（`isTop == "1"`），黃色實心
2. 圓形頭像
3. 姓名 Text Style 4
4. 「轉帳」按鈕：粉紅外框 `#EC008C` + 粉紅文字，圓角矩形
5. 「邀請中」標籤（`status == 2`）：灰外框 `#C9C9C9` + 灰文字，不可點
6. `⋯`（`status == 1`）：`#C9C9C9`

Cell 之間有 `#E4E4E4` 分隔線，自頭像右緣起算（非滿版）。

### 4.6 空狀態（New Comer）

- 插圖（兩人握手）
- 主標「就從加好友開始吧：）」Text Style 6
- 副標兩行「與好友們一起用 KOKO 聊起來！」／「還能互相收付款、發紅包喔：）」Text Style
- 「加好友」按鈕：綠色漸層（`#A6CC42` → `#79C41B` → `#56B30B`），膠囊型，右側帶圖示，下方 `#79C41B` 40% 陰影
- 底部「幫助好友更快找到你？<u>設定 KOKO ID</u>」，後半為粉紅底線連結

### 4.7 底部 TabBar

錢錢／朋友／KO（中央凸起）／記帳／設定，
選中為「朋友」（粉紅圖示 + 文字 Text Style 7），其餘 `#999999`。本題不實作切換。

---

## 5. Zeplin 註解（規範來源）

### 朋友_KOKO 好友_邀請展開

| # | 內容 |
|---|---|
| 1 | `status:0` →「邀請送出」，在上方 Cell UI，待用戶同意 |
| 3 | `status:2` →「邀請中」，待對方同意 |
| 5 | `status=1` 已完成 |

### 朋友_KOKO 好友_邀請待回覆

| # | 內容 |
|---|---|
| 1 | 無圖示可以全用這個 default（預設頭像） |
| 2 | 「根據status=2的人數」／「通知的人數」（好友 tab badge）— 見 `spec.md` §6.3 的反駁 |
| 3 | 固定 99+（聊天 tab badge） |
| 4 | 支援縮合（邀請卡片區） |

### 朋友_KOKO 好友_New Comer

| # | 內容 |
|---|---|
| 1 | 「可以都用這張」（大頭貼素材） |

---

## 6. 資產

各畫面 exportable layers：New Comer 24 個、列表 33 個、邀請待回覆 32 個、邀請展開 31 個。
需自 Zeplin 下載插圖、圖示、預設頭像（@1x/@2x/@3x）。
