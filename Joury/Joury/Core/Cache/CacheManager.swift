//
//  CacheManager.swift
//  Joury
//
//  iOS cache management for API responses and data persistence.
//

import Foundation

class CacheManager {
    static let shared = CacheManager()
    
    private let cache = NSCache<NSString, CacheItem>()
    private let fileManager = FileManager.default
    private let cacheDirectory: URL
    
    private init() {
        // Create cache directory in documents
        let documentsPath = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
        cacheDirectory = documentsPath.appendingPathComponent("Cache")
        
        // Create directory if it doesn't exist
        try? fileManager.createDirectory(at: cacheDirectory, withIntermediateDirectories: true)
        
        // Configure cache
        cache.countLimit = 100
        cache.totalCostLimit = 50 * 1024 * 1024 // 50MB
    }
    
    // MARK: - Generic Cache Methods
    
    func setObject<T: Codable>(_ object: T, forKey key: String, expiration: CacheExpiration = .minutes(30)) {
        let item = CacheItem(
            data: object,
            expiration: expiration.date
        )
        cache.setObject(item, forKey: NSString(string: key))
        
        // Also persist to disk for important data
        if shouldPersistToDisk(key: key) {
            persistToDisk(object, forKey: key, expiration: expiration)
        }
    }
    
    func getObject<T: Codable>(_ type: T.Type, forKey key: String) -> T? {
        // Try memory cache first
        if let item = cache.object(forKey: NSString(string: key)) {
            if item.isValid {
                return item.data as? T
            } else {
                cache.removeObject(forKey: NSString(string: key))
            }
        }
        
        // Try disk cache
        return getFromDisk(type, forKey: key)
    }
    
    func removeObject(forKey key: String) {
        cache.removeObject(forKey: NSString(string: key))
        removeFromDisk(forKey: key)
    }
    
    func clearCache() {
        cache.removeAllObjects()
        try? fileManager.removeItem(at: cacheDirectory)
        try? fileManager.createDirectory(at: cacheDirectory, withIntermediateDirectories: true)
    }
    
    // MARK: - Specialized Cache Methods
    
    func cacheJournalEntry(_ journal: JournalResponse, forDate date: String) {
        setObject(journal, forKey: "journal_\(date)", expiration: .hours(24))
    }
    
    func getCachedJournalEntry(forDate date: String) -> JournalResponse? {
        return getObject(JournalResponse.self, forKey: "journal_\(date)")
    }
    
    func cacheUserSession(_ session: Any, forKey key: String) {
        // Don't persist sensitive session data to disk
        let item = CacheItem(
            data: session,
            expiration: CacheExpiration.hours(2).date
        )
        cache.setObject(item, forKey: NSString(string: key))
    }
    
    // MARK: - Private Methods
    
    private func shouldPersistToDisk(key: String) -> Bool {
        // Persist journal entries and other important data
        return key.hasPrefix("journal_") || 
               key.hasPrefix("user_profile") ||
               key.hasPrefix("settings_")
    }
    
    private func persistToDisk<T: Codable>(_ object: T, forKey key: String, expiration: CacheExpiration) {
        let wrapper = DiskCacheWrapper(
            data: object,
            expiration: expiration.date,
            cachedAt: Date()
        )
        
        let fileURL = cacheDirectory.appendingPathComponent("\(key).cache")
        
        do {
            let data = try JSONEncoder().encode(wrapper)
            try data.write(to: fileURL)
        } catch {
            print("Failed to persist cache item to disk: \(error)")
        }
    }
    
    private func getFromDisk<T: Codable>(_ type: T.Type, forKey key: String) -> T? {
        let fileURL = cacheDirectory.appendingPathComponent("\(key).cache")
        
        guard let data = try? Data(contentsOf: fileURL) else { return nil }
        
        do {
            let wrapper = try JSONDecoder().decode(DiskCacheWrapper<T>.self, from: data)
            
            if wrapper.isValid {
                return wrapper.data
            } else {
                // Remove expired file
                try? fileManager.removeItem(at: fileURL)
                return nil
            }
        } catch {
            print("Failed to decode cache item from disk: \(error)")
            try? fileManager.removeItem(at: fileURL)
            return nil
        }
    }
    
    private func removeFromDisk(forKey key: String) {
        let fileURL = cacheDirectory.appendingPathComponent("\(key).cache")
        try? fileManager.removeItem(at: fileURL)
    }
}

// MARK: - Cache Item
private class CacheItem: NSObject {
    let data: Any
    let expiration: Date
    
    init(data: Any, expiration: Date) {
        self.data = data
        self.expiration = expiration
    }
    
    var isValid: Bool {
        return Date() < expiration
    }
}

// MARK: - Disk Cache Wrapper
private struct DiskCacheWrapper<T: Codable>: Codable {
    let data: T
    let expiration: Date
    let cachedAt: Date
    
    var isValid: Bool {
        return Date() < expiration
    }
}

// MARK: - Cache Expiration
enum CacheExpiration {
    case seconds(TimeInterval)
    case minutes(TimeInterval)
    case hours(TimeInterval)
    case days(TimeInterval)
    case never
    
    var date: Date {
        switch self {
        case .seconds(let seconds):
            return Date().addingTimeInterval(seconds)
        case .minutes(let minutes):
            return Date().addingTimeInterval(minutes * 60)
        case .hours(let hours):
            return Date().addingTimeInterval(hours * 60 * 60)
        case .days(let days):
            return Date().addingTimeInterval(days * 24 * 60 * 60)
        case .never:
            return Date.distantFuture
        }
    }
} 