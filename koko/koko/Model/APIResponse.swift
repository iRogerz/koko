//
//  APIResponse.swift
//  koko
//
//  spec.md §3.1：五支 API 的回應都包在 `{ "response": [...] }` 這層信封裡。
//

import Foundation

struct APIResponse<Element: Decodable>: Decodable {

    let response: [Element]
}
