//
//  StubFriendRepository.swift
//  kokoTests
//
//  ViewModel 測試用的 Repository 替身。
//  ViewModel 的職責是「拿到資料後推導畫面狀態」，
//  用它取代真實 Repository 才能把狀態推導單獨測乾淨。
//

import Foundation
@testable import koko

enum UserBuilder {

    static func make(name: String = "蔡國泰", kokoID: String? = "Mike") -> User {
        User(name: name, kokoID: kokoID)
    }
}

actor StubFriendRepository: FriendLoading {

    private var result: Result<FriendListData, Error>

    private(set) var requestedScenarios: [Scenario] = []
    var loadCount: Int { requestedScenarios.count }

    init(result: Result<FriendListData, Error>) {
        self.result = result
    }

    init(friends: [Friend], user: User? = nil) {
        self.result = .success(FriendListData(user: user ?? UserBuilder.make(), friends: friends))
    }

    func load(_ scenario: Scenario) async throws -> FriendListData {
        requestedScenarios.append(scenario)
        return try result.get()
    }

    func setResult(_ result: Result<FriendListData, Error>) {
        self.result = result
    }

    func setFriends(_ friends: [Friend], user: User? = nil) {
        result = .success(FriendListData(user: user ?? UserBuilder.make(), friends: friends))
    }
}
