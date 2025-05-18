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
}

extension URLSession: @retroactive RequestExecuter {
    public func execute(request: Request) async throws -> Response {
        let urlRequest = request.generateRequest()
        let (data, response) = try await self.data(for: urlRequest)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw ServiceError.notHTTPResponse
        }
        return Response(status: httpResponse.statusCode, data: data, headers: httpResponse.allHeaderFields)
    }
}
