#!/bin/bash
#
# check-architecture.sh
#
# 不需編譯的架構檢查。針對「編譯器不會擋、但會造成隱性失敗」的規則。
# 每條規則都對應一次真實踩過的坑，見 docs/sdd-progress.md 的 Hashimoto log。
#
# 用法：./scripts/check-architecture.sh
# 回傳：全部通過 0，任一違規 1

set -uo pipefail

cd "$(dirname "$0")/.." || exit 1

APP="koko/koko"
TESTS="koko/kokoTests"
failures=0

fail() {
    printf '\033[31m✗\033[0m %s\n' "$1"
    failures=$((failures + 1))
}

pass() {
    printf '\033[32m✓\033[0m %s\n' "$1"
}

# ---------------------------------------------------------------------------
# 規則 1：ViewModel 與 view state 不得 import UIKit
#
# CLAUDE.md architecture rule 1 / AC-11。
# 用行首比對 —— 註解裡出現「不得 import UIKit」不算違規（曾誤報過）。
# ---------------------------------------------------------------------------
check_viewmodel_uikit() {
    local hits
    hits=$(find "$APP" -name '*ViewModel.swift' -o -name '*ViewState.swift' \
        | xargs grep -ln '^import UIKit' 2>/dev/null)

    if [ -n "$hits" ]; then
        fail "ViewModel／ViewState 不得 import UIKit："
        echo "$hits" | sed 's/^/    /'
    else
        pass "ViewModel／ViewState 未 import UIKit"
    fi
}

# ---------------------------------------------------------------------------
# 規則 2：資料層不得 import UIKit
#
# View 不得直接呼叫網路、Model 不得依賴 UI（CLAUDE.md rule 2）。
# ---------------------------------------------------------------------------
check_data_layer_uikit() {
    local hits
    hits=$(grep -rln '^import UIKit' "$APP/Model" "$APP/Network" "$APP/Repository" 2>/dev/null)

    if [ -n "$hits" ]; then
        fail "Model／Network／Repository 不得 import UIKit："
        echo "$hits" | sed 's/^/    /'
    else
        pass "資料層（Model／Network／Repository）未 import UIKit"
    fi
}

# ---------------------------------------------------------------------------
# 規則 3：@MainActor 測試類別內不得有同步 test 方法
#
# XCTest 透過 ObjC runtime 呼叫同步測試方法，碰上 MainActor 隔離會 abort，
# 症狀是 "pointer being freed was not allocated" —— 訊息完全不提 MainActor，
# 極難從錯誤本身回推。2026-08-07 實際踩過一次。
# ---------------------------------------------------------------------------
check_mainactor_sync_tests() {
    violated=0

    for file in $(grep -rl '@MainActor' "$TESTS" 2>/dev/null); do
        sync_tests=$(grep -n 'func test_' "$file" | grep -v 'async' || true)

        if [ -n "$sync_tests" ]; then
            # 變數名必須用大括號界定：後面接的全形冒號是多位元組字元，
            # 不加括號 bash 會把它併進變數名而在 set -u 下報 unbound。
            fail "${file}：@MainActor 測試類別內有同步 test 方法（須改成 async）"
            echo "$sync_tests" | sed 's/^/    /'
            violated=1
        fi
    done

    [ "$violated" -eq 0 ] && pass "@MainActor 測試類別內的 test 方法皆為 async"
}

# ---------------------------------------------------------------------------
# 規則 4：不得殘留 Storyboard／XIB
#
# CLAUDE.md tech stack：純程式碼 UIKit。
# ---------------------------------------------------------------------------
check_no_storyboards() {
    local hits
    hits=$(find koko -name '*.storyboard' -o -name '*.xib' 2>/dev/null)

    if [ -n "$hits" ]; then
        fail "不得使用 Storyboard／XIB："
        echo "$hits" | sed 's/^/    /'
    else
        pass "無 Storyboard／XIB"
    fi
}

# ---------------------------------------------------------------------------
# 規則 5：不得使用 SwiftUI
# ---------------------------------------------------------------------------
check_no_swiftui() {
    local hits
    hits=$(grep -rln '^import SwiftUI' koko 2>/dev/null)

    if [ -n "$hits" ]; then
        fail "不得使用 SwiftUI："
        echo "$hits" | sed 's/^/    /'
    else
        pass "無 SwiftUI"
    fi
}

# ---------------------------------------------------------------------------
# 規則 6：邀請卡片區必須排在好友／聊天 tab 列「之上」
#
# 設計稿（三張稿一致）與 spec.md §6 的小節順序都是
# header → 邀請卡片 → tab 列。Step 6a 曾經做反，畫面上不會壞掉、
# 只是位置不對，肉眼比對設計稿才看得出來 —— 所以釘在這裡。
# ---------------------------------------------------------------------------
check_header_order() {
    local file='koko/koko/Scene/FriendList/FriendListViewController.swift'
    local stack invitation tab

    if [ ! -f "$file" ]; then
        fail "找不到 ${file}"
        return
    fi

    # 取 headerStack 的 arrangedSubviews 陣列內容（跨行）。
    stack=$(sed -n '/UIStackView(arrangedSubviews:/,/\])/p' "$file" | tr -d ' \n')
    invitation=$(printf '%s' "$stack" | grep -bo 'invitationSectionView' | head -1 | cut -d: -f1)
    tab=$(printf '%s' "$stack" | grep -bo 'tabView' | head -1 | cut -d: -f1)

    if [ -z "$invitation" ] || [ -z "$tab" ]; then
        fail "headerStack 找不到 invitationSectionView 或 tabView"
        return
    fi

    if [ "$invitation" -lt "$tab" ]; then
        pass "邀請卡片區排在 tab 列之上"
    else
        fail "邀請卡片區排在 tab 列之下 —— 設計稿與 spec.md §6 都是卡片在上"
    fi
}

echo "架構檢查（docs/spec.md + CLAUDE.md）"
echo "───────────────────────────────────────"
check_viewmodel_uikit
check_data_layer_uikit
check_mainactor_sync_tests
check_no_storyboards
check_no_swiftui
check_header_order
echo "───────────────────────────────────────"

if [ "$failures" -gt 0 ]; then
    printf '\033[31m%d 項違規\033[0m\n' "$failures"
    exit 1
fi

printf '\033[32m全部通過\033[0m\n'
