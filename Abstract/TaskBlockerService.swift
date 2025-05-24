//
//  TaskBlockerService.swift
//  
//
//  Created by Martin Lalev on 24/05/2025.
//

public protocol TaskBlockerService: Sendable {
    func perform() async throws
}

public actor TaskBlockerActor: TaskBlockerService {
    private var activeTask: Task<Void, Error>?
    
    private let performer: @Sendable () async throws -> Void

    public init(
        performer: @Sendable @escaping () async throws -> Void
    ) {
        self.performer = performer
    }

    public func perform() async throws {
        if let refreshTask = activeTask {
            _ = try await refreshTask.value
        } else {
            let task = Task { () throws in
                defer { activeTask = nil }
                return try await performer()
            }
            self.activeTask = task
            
            _ = try await task.value
        }
    }
}
