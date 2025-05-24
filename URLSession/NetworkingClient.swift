//
//  RequestClient.swift
//  DandaniaData
//
//  Created by Martin Lalev on 28.09.18.
//  Copyright © 2018 Martin Lalev. All rights reserved.
//

import Foundation
import FlooidRequests

enum ServiceError: Error {
    case notHTTPResponse
    case bodyNotEncodable
}

extension URLSession: @retroactive RequestExecuter {
    public func execute(request: Request) async throws -> Response {
        let urlRequest = try request.generateRequest()
        
        let (data, response) = try await self.data(for: urlRequest)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw ServiceError.notHTTPResponse
        }
        
        let normalizedHeaders = httpResponse.allHeaderFields.enumerated().reduce(into: [:]) { partialResult, element in
            if let stringKey = element.element.key as? String {
                partialResult[stringKey.uppercased()] = element.element.value
            } else {
                partialResult[element.element.key] = element.element.value
            }
        }
        
        return Response(
            status: httpResponse.statusCode,
            data: data,
            headers: normalizedHeaders
        )
    }
}

public extension ResponseStatusCheck {
    static var success: ResponseStatusCheck {
        .range(200 ..< 300)
    }
    static var badRequest: ResponseStatusCheck {
        .single(400)
    }
    static var unauthorized: ResponseStatusCheck {
        .single(401)
    }
}
