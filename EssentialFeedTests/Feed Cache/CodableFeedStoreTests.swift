//
//  CodableFeedStoreTests.swift
//  EssentialFeedTests
//
//  Created by Gordon Feng on 3/7/21.
//

import XCTest
import EssentialFeed

class CodableFeedStore {

    private struct Cache: Codable {
        let feed: [LocalFeedImage]
        let timestamp: Date
    }

    private let storeURL = FileManager.default.urls(for: .documentDirectory,
                                                    in: .userDomainMask).first!.appendingPathComponent("image-feed.store")

    func retrieve(completion: @escaping FeedStore.RetrievalCompletion) {
        guard let data = try? Data(contentsOf: storeURL) else {
            return completion(.empty)
        }

        let decoder = JSONDecoder()
        let cache = try! decoder.decode(Cache.self, from: data)
        completion(.found(feed: cache.feed, timestamp: cache.timestamp))
    }

    func insert(_ feed: [LocalFeedImage], timestamp: Date, completion: @escaping FeedStore.InsertionCompletion) {
        let encoder = JSONEncoder()
        let encoded = try! encoder.encode(Cache(feed: feed, timestamp: timestamp))
        try! encoded.write(to: storeURL)
        completion(nil)
    }
}

class CodableFeedStoreTests: XCTestCase {

    override func setUp() {
        super.setUp()
        
        let storeURL = FileManager.default.urls(for: .documentDirectory,
                                                in: .userDomainMask).first!.appendingPathComponent("image-feed.store")
        try? FileManager.default.removeItem(at: storeURL)
    }

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

    func test_retrieve_hasNoSideEffectsOnEmptyCache() {
        let sut = CodableFeedStore()

        let exp = expectation(description: "wait for completion")
        sut.retrieve { (firstResult) in
            sut.retrieve { (secondResult) in
                switch (firstResult, secondResult) {
                case (.empty, .empty):
                    break
                default:
                    XCTFail("Expect receiving twice from empty cache to deliver same empty result, but received \(firstResult) and \(secondResult) instead")
                }
                exp.fulfill()
            }
        }

        wait(for: [exp], timeout: 1.0)
    }

    func test_retrieveAfterInsertingEmptyCache_deliverInsertValue() {
        let sut = CodableFeedStore()
        let feeds = uniqueImageFeed().localModel
        let timestamp = Date()

        let exp = expectation(description: "wait for completion")
        sut.insert(feeds, timestamp: timestamp) { (insertionError) in
            XCTAssertNil(insertionError, "Expect feed to be inserted successfully")

            sut.retrieve { (retrievedResult) in
                switch (retrievedResult) {
                case let .found(retrievedFeed, retrievedTimestamp):
                    XCTAssertEqual(feeds, retrievedFeed)
                    XCTAssertEqual(timestamp, retrievedTimestamp)

                default:
                    XCTFail("Expect found result with feed \(feeds) and timestamp \(timestamp), but retrieved \(retrievedResult) instead")
                }
                exp.fulfill()
            }
        }

        wait(for: [exp], timeout: 1.0)
    }
}
