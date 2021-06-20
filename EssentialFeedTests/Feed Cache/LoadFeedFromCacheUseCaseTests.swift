//
//  LoadFeedFromCacheUseCaseTests.swift
//  EssentialFeedTests
//
//  Created by Gordon Feng on 20/6/21.
//

import XCTest
import EssentialFeed

class LoadFeedFromCacheUseCaseTests: XCTestCase {

    func test_init_doesNotStoreMessageUponCreation() {
        let (_, store) = makeSUT()

        XCTAssertEqual(store.receivedMessage, [])
    }

    func test_load_requestCacheRetrieval() {
        let (sut, store) = makeSUT()

        sut.load { _ in }

        XCTAssertEqual(store.receivedMessage, [.retrieve])
    }

    func test_load_failsOnRetrievalError() {
        let (sut, store) = makeSUT()
        let retrievalError = anyError()

        expect(sut, toCompleteWith: .failure(retrievalError), when: {
            store.completeRetrievalWith(retrievalError)
        })
    }

    func test_load_deliversNoImagesOnEmptyCache() {
        let (sut, store) = makeSUT()

        expect(sut, toCompleteWith: .success([]), when: {
            store.completeRetrievalWithEmptyCache()
        })
    }

    //MARK: - HELPER

    private func makeSUT(currentDate: @escaping () -> Date = Date.init, file: StaticString = #file, line: UInt = #line) -> (LocalFeedLoader, FeedStoreSpy) {
        let store = FeedStoreSpy()
        let loader = LocalFeedLoader(store: store, currentDate: currentDate)
        trackForMemoryLeaks(store, file: file, line: line)
        trackForMemoryLeaks(loader, file: file, line: line)
        return (loader, store)
    }

    private func expect(_ sut: LocalFeedLoader, toCompleteWith expectedResult: LocalFeedLoader.LoadResult, when action: () ->Void, file: StaticString = #file, line: UInt = #line) {

        let exp = expectation(description: "wait for completion")
        sut.load { (receivedResult) in
            switch (expectedResult, receivedResult) {
            case let (.success(expectImages), .success(receivedImages)):
                XCTAssertEqual(expectImages, receivedImages, file: file, line: line)

            case let (.failure(expectError as NSError), .failure(receivedError as NSError)):
                XCTAssertEqual(expectError, receivedError, file: file, line: line)

            default:
                XCTFail("Expect \(expectedResult), but received \(receivedResult) instead", file: file, line: line)
            }
            exp.fulfill()
        }

        action()
        wait(for: [exp], timeout: 1.0)
    }

    private func anyError() -> NSError {
        return NSError(domain: "any Error", code: 0)
    }

}
