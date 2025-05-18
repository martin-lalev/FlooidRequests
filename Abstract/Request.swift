//
//  Request.swift
//  DandaniaDomain
//
//  Created by Martin Lalev on 20.01.19.
//  Copyright © 2019 Martin Lalev. All rights reserved.
//

import Foundation

public struct Request: Sendable {
    public struct QueryItem: Sendable {
        public let name: String
        public let value: String?
        
        public init(name: String, value: String?) {
            self.name = name
            self.value = value
        }
    }

    public enum Method: Sendable {
        case get
        case post
        case put
        case delete
        case patch
    }
    
    public enum Body: Sendable {
        case none
        case plain(data: Data?, contentType: String?)
        case json(parameters: [String: Any & Sendable])
        case urlEncoded(parameters: [QueryItem])
    }

    public let methodName: Method
    public let host: String
    public let path: String
    public let query: [QueryItem]
    public let body: Body
    public let headers: [String: String]?
    public let timeout: TimeInterval?
    public let cachePolicy: NSURLRequest.CachePolicy?
    
    public init(_ methodName: Method, host: String, path: String, query: [QueryItem] = [], body: Body = .none, headers: [String: String]? = [:], timeout: TimeInterval? = nil, cachePolicy: NSURLRequest.CachePolicy? = nil) {
        self.methodName = methodName
        self.host = host
        self.path = path
        self.query = query
        self.body = body
        self.headers = headers
        self.timeout = timeout
        self.cachePolicy = cachePolicy
    }
}


public extension Request {
    static func get(host: String, path: String, query: [QueryItem] = [], headers:[String: String]? = [:], timeout: TimeInterval? = nil, cachePolicy: NSURLRequest.CachePolicy? = nil) -> Request {
        return Request(.get, host: host, path: path, query: query, body: Request.Body.none, headers: headers, timeout: timeout, cachePolicy: cachePolicy)
    }
    static func post(host: String, path: String, body: Body, headers:[String: String]? = [:], timeout: TimeInterval? = nil, cachePolicy: NSURLRequest.CachePolicy? = nil) -> Request {
        return Request(.post, host: host, path: path, body: body, headers: headers, timeout: timeout, cachePolicy: cachePolicy)
    }
    static func put(host: String, path: String, body: Body, headers:[String: String]? = [:], timeout: TimeInterval? = nil, cachePolicy: NSURLRequest.CachePolicy? = nil) -> Request {
        return Request(.put, host: host, path: path, body: body, headers: headers, timeout: timeout, cachePolicy: cachePolicy)
    }
    static func delete(host: String, path: String, body: Body = .none, headers:[String: String]? = [:], timeout: TimeInterval? = nil, cachePolicy: NSURLRequest.CachePolicy? = nil) -> Request {
        return Request(.delete, host: host, path: path, body: body, headers: headers, timeout: timeout, cachePolicy: cachePolicy)
    }
    static func patch(host: String, path: String, body: Body, headers:[String: String]? = [:], timeout: TimeInterval? = nil, cachePolicy: NSURLRequest.CachePolicy? = nil) -> Request {
        return Request(.patch, host: host, path: path, body: body, headers: headers, timeout: timeout, cachePolicy: cachePolicy)
    }
}
