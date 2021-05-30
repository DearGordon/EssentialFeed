//
//  HTTPClient.swift
//  EssentialFeed
//
//  Created by Gordon Feng on 30/5/21.
//

import Foundation

public typealias SuccessItem = (data: Data, response: HTTPURLResponse)

public protocol HTTPClient {
    func get(form url: URL, completion: @escaping ((Result<SuccessItem, Error>) -> Void))
}
