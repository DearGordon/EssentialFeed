//
//  RemoteFeedLoader.swift
//  EssentialFeedTests
//
//  Created by Gordon Feng on 29/5/21.
//

import XCTest
@testable import EssentialFeed

class HTTPClient {

    static let shared = HTTPClient()

    private init() {}

    var url: URL?
}

class RemoteFeedLoader {

    func load() {
        HTTPClient.shared.url = URL(string: "https://google.com")
    }
}

class RemoteFeedLoaderTest: XCTestCase {


    func testInit() {
        _ = RemoteFeedLoader()
        let client = HTTPClient.shared

        XCTAssertNil(client.url)
    }

    func testLoadRequestDataFromURL() {
        let client = HTTPClient.shared

        //three different way of dependancy injection
        //instruction injection, property injection, functional injection
        let loader = RemoteFeedLoader()
        loader.load()

        XCTAssertNotNil(client.url)
    }

}
