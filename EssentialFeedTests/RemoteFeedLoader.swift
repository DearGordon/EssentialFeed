//
//  RemoteFeedLoader.swift
//  EssentialFeedTests
//
//  Created by Gordon Feng on 29/5/21.
//

import XCTest
@testable import EssentialFeed

protocol HTTPClient {
    func get(form url: URL)
}

class HTTPClientSpy: HTTPClient {
    var requestURL: URL?

    func get(form url: URL) {
        requestURL = url
    }
}

class RemoteFeedLoader {

    let client: HTTPClient

    init(client: HTTPClient) {
        self.client = client
    }

    func load() {
        client.get(form: URL(string: "https://google.com")!)
    }
}

class RemoteFeedLoaderTest: XCTestCase {


    func testInitDoesNotRequestDataFromURL() {
        let clientSpy = HTTPClientSpy()
        _ = RemoteFeedLoader(client: clientSpy)

        XCTAssertNil(clientSpy.requestURL)
    }

    func testLoadRequestDataFromURL() {
        let clientSpy = HTTPClientSpy()
        let loader = RemoteFeedLoader(client: clientSpy)
        loader.load()

        XCTAssertNotNil(clientSpy.requestURL)
    }

}
