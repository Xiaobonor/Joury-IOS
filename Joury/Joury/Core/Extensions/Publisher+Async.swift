//
//  Publisher+Async.swift
//  Joury
//
//  Created by HongCheng on 2024/1/18.
//

import Foundation
import Combine

// MARK: - Publisher to Async/Await
extension Publisher {
    
    /// Converts a Combine Publisher into an async/await compatible function.
    ///
    /// This extension allows you to await the result of any Publisher, making it easy to integrate
    /// Combine-based APIs (like NetworkManager) with modern Swift concurrency.
    ///
    /// - Returns: The first value emitted by the publisher.
    /// - Throws: An error if the publisher completes with a failure.
    func asyncValue() async throws -> Output {
        try await withCheckedThrowingContinuation { continuation in
            var cancellable: AnyCancellable?
            
            cancellable = first()
                .sink(
                    receiveCompletion: { completion in
                        switch completion {
                        case .finished:
                            break // Successful completion, no value needed for continuation
                        case .failure(let error):
                            continuation.resume(throwing: error)
                        }
                        cancellable?.cancel()
                    },
                    receiveValue: { value in
                        continuation.resume(returning: value)
                    }
                )
        }
    }
} 