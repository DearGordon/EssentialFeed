//
//  CodableFeedStoreTests.swift
//  EssentialFeedTests
//
//  Created by Gordon Feng on 3/7/21.
//

import XCTest
import EssentialFeed

class CodableFeedStore {

    func retrieve(completion: @escaping FeedStore.RetrievalCompletion) {
        completion(.empty)
    }
}

class CodableFeedStoreTests: XCTestCase {

    func test_retrieve_deliverEmptyOnEmptyCache() {
        let sut = CodableFeedStore()

        let exp = expectation(description: "wait for completion")
        sut.retrieve { (result) in
            switch result {
            case .empty:
                break
            default:
                XCTFail("Expect empty but receive \(result) instead")
            }
            exp.fulfill()
        }

        wait(for: [exp], timeout: 1.0)
    }
}
