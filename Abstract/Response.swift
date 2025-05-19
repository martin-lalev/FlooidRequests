//
//  File.swift
//  
//
//  Created by Martin Lalev on 10/01/2023.
//

import Foundation

public struct Response: Sendable {
    public let status: Int
    public let data: Data
    public nonisolated(unsafe) let headers: [AnyHashable: Any]

    public init(
        status: Int,
        data: Data,
        headers: [AnyHashable: Any]
    ) {
        self.status = status
        self.data = data
        self.headers = headers
    }
}
