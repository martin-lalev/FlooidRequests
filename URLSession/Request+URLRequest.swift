//
//  File.swift
//  
//
//  Created by Martin Lalev on 08/01/2023.
//

import Foundation
import FlooidRequests

extension Request {
    func generateRequest(defaultHeaders:[String: String] = [:], timeout:TimeInterval = 60, cachePolicy:NSURLRequest.CachePolicy = .reloadIgnoringCacheData) -> URLRequest {
        let url: URL = {
            var urlComponents = URLComponents(string: self.host)
            urlComponents?.path = "/" + self.path
            urlComponents?.queryItems = self.query.map { URLQueryItem(name: $0.name, value: $0.value) }
            return urlComponents?.url
            }()!
        
        var request = URLRequest(url: url, cachePolicy: self.cachePolicy ?? cachePolicy, timeoutInterval: self.timeout ?? timeout)
        request.httpMethod = self.methodName.rawValue
        
        for header in defaultHeaders {
            request.setValue(header.value, forHTTPHeaderField: header.key)
        }
        for header in self.headers ?? [:] {
            request.setValue(header.value, forHTTPHeaderField: header.key)
        }
        if let contentType = self.body.contentType {
            request.setValue(contentType, forHTTPHeaderField: "Content-Type")
        }
        
        if let bodyData = self.body.rawData() {
            request.httpBody = bodyData
            request.setValue(String(describing:bodyData.count), forHTTPHeaderField: "Content-Length")
        }
        
        
        return request
    }
}

extension Request {
    static func cookieHeaders(for cookies: [String: String], originURL url:URL) -> [String:String] {
        return HTTPCookie.requestHeaderFields(with: cookies.reduce([]) { (result, cookie) -> [HTTPCookie] in
            if let httpCookie = HTTPCookie(properties: [HTTPCookiePropertyKey.originURL:url, HTTPCookiePropertyKey.path:"\\", HTTPCookiePropertyKey.name:cookie.key, HTTPCookiePropertyKey.value: cookie.value]) {
                return result + [httpCookie]
            } else {
                return result
            }
        })
    }
}

extension Request.Body {
    func rawData() -> Data? {
        switch self {
        case .none:
            return nil
        case .plain(let data, _):
            return data
        case .json(let parameters):
            return try? JSONSerialization.data(withJSONObject: parameters, options: [])
        case .urlEncoded(let parameters):
            return parameters.map({ $0.name + "=" + ($0.value ?? "") }).joined(separator: "&").data(using: .utf8)
        }
    }
}

extension Request.Body {
    var contentType: String? {
        switch self {
        case .none:
            return nil
        case .plain(_, let contentType):
            return contentType
        case .json:
            return "application/json"
        case .urlEncoded:
            return "application/x-www-form-urlencoded"
        }
    }
}

extension Request.Body {
    init(for parameters: [Request.QueryItem]) {
        self = .urlEncoded(parameters: parameters)
    }
}

extension Request.Method {
    var rawValue: String {
        switch self {
        case .get:
            return "GET"
        case .post:
            return "POST"
        case .put:
            return "PUT"
        case .delete:
            return "DELETE"
        case .patch:
            return "PATCH"
        }
    }
}
