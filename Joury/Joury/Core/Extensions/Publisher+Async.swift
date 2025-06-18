//
//  Publisher+Async.swift
//  Joury
//
//  Extension to convert Combine publishers to async/await
//

import Foundation
import Combine

extension Publisher {
    /// Converts a Combine publisher to async/await
    func asyncValue() async throws -> Output {
        return try await withCheckedThrowingContinuation { continuation in
            var cancellable: AnyCancellable?
            
            cancellable = self
                .sink(
                    receiveCompletion: { completion in
                        switch completion {
                        case .finished:
                            break
                        case .failure(let error):
                            continuation.resume(throwing: error)
                        }
                        cancellable?.cancel()
                    },
                    receiveValue: { value in
                        continuation.resume(returning: value)
                        cancellable?.cancel()
                    }
                )
        }
    }
} 