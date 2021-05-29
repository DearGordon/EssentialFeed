//
//  RemoteFeedLoader.swift
//  EssentialFeedTests
//
//  Created by Gordon Feng on 29/5/21.
//

import XCTest
@testable import EssentialFeed

class HTTPClient {
    var url: URL?
}

class RemoteFeedLoaderTest: XCTestCase {


    func testInit() {
        _ = RemoteFeedLoader()
        let client = HTTPClient()

        XCTAssertNil(client.url)
    }

    func testLoadRequestDataFromURL() {
        let client = HTTPClient()

        //three different way of dependancy injection
        //instruction injection, property injection, functional injection
        let loader = RemoteFeedLoader()
        loader.load { (result) in
            switch result {
            case .success(let data):
                XCTAssertNotNil(data)
            case .failure(_):
                XCTFail()
            }
        }
        XCTFail()
    }

}
