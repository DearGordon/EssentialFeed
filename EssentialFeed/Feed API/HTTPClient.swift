//
//  HTTPClient.swift
//  EssentialFeed
//
//  Created by Gordon Feng on 30/5/21.
//

import Foundation

public protocol HTTPClient {
    func get(from url: URL, completion: @escaping ((Result<(Data, HTTPURLResponse), Error>) -> Void))
}
