//
//  File.swift
//  
//
//  Created by Martin Lalev on 08/01/2023.
//

import Foundation
import FlooidRequests

extension Request {
    func generateRequest() throws -> URLRequest {
        let url: URL = {
            var urlComponents = URLComponents(string: self.host)
            urlComponents?.path = "/" + self.path
            urlComponents?.queryItems = self.query.map { URLQueryItem(name: $0.name, value: $0.value) }
            return urlComponents?.url
            }()!
        
        var request = URLRequest(url: url, cachePolicy: self.cachePolicy, timeoutInterval: self.timeout)
        request.httpMethod = self.methodName.rawValue
        
        for header in self.headers ?? [:] {
            request.setValue(header.value, forHTTPHeaderField: header.key)
        }
        if let body {
            let bodyData = try body.rawData()
            request.httpBody = bodyData
            request.setValue(body.contentType, forHTTPHeaderField: "Content-Type")
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
    func rawData() throws -> Data {
        switch self {
        case .plain(let data, _):
            return data
        case .json(let parameters):
            return try JSONSerialization.data(withJSONObject: parameters, options: [])
        case .urlEncoded(let parameters):
            guard let data = parameters.map({ $0.name + "=" + ($0.value ?? "") }).joined(separator: "&").data(using: .utf8) else {
                throw ServiceError.bodyNotEncodable
            }
            return data
        }
    }
}

extension Request.Body {
    var contentType: String {
        switch self {
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
