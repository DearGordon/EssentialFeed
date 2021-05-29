//
//  RemoteFeedLoader.swift
//  EssentialFeedTests
//
//  Created by Gordon Feng on 29/5/21.
//

import XCTest
@testable import EssentialFeed

class HTTPClient {

    static var shared = HTTPClient() //make singleton assignable, but it will not be a real singleton, cause it's mutable

    func get(form url: URL) {}
}

class HTTPClientSpy: HTTPClient {
    var requestURL: URL?

    override func get(form url: URL) {
        requestURL = url
    }
}

class RemoteFeedLoader {

    func load() {
        HTTPClient.shared.get(form: URL(string: "https://google.com")!)
    }
}

class RemoteFeedLoaderTest: XCTestCase {


    func testInitDoesNotRequestDataFromURL() {
        let clientSpy = HTTPClientSpy()
        HTTPClient.shared = clientSpy
        _ = RemoteFeedLoader()

        XCTAssertNil(clientSpy.requestURL)
    }

    func testLoadRequestDataFromURL() {
        let clientSpy = HTTPClientSpy()
        HTTPClient.shared = clientSpy
        let loader = RemoteFeedLoader()
        loader.load()

        XCTAssertNotNil(clientSpy.requestURL)
    }

}
