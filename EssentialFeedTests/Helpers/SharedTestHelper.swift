//
//  SharedTestHelper.swift
//  EssentialFeedTests
//
//  Created by Gordon Feng on 27/6/21.
//

import Foundation

func anyURL() -> URL {
    return URL(string: "http://any-url.com")!
}

func anyError() -> NSError {
    return NSError(domain: "any Error", code: 0)
}
