//
//  NetworkManager.swift
//  Joury
//
//  Network layer management for Joury iOS app
//

import Foundation
import Combine
import Network

// MARK: - Network Error Types

enum NetworkError: Error, LocalizedError {
    case invalidURL
    case noData
    case decodingError(Error)
    case encodingError(Error)
    case httpError(Int, String?)
    case networkUnavailable
    case timeout
    case unauthorized
    case forbidden
    case notFound
    case serverError
    case unknown(Error)
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return LocalizationKeys.Errors.validationError.localized
        case .noData:
            return "No data received"
        case .decodingError(let error):
            return "Decoding error: \(error.localizedDescription)"
        case .encodingError(let error):
            return "Encoding error: \(error.localizedDescription)"
        case .httpError(let code, let message):
            return "HTTP \(code): \(message ?? "Unknown error")"
        case .networkUnavailable:
            return LocalizationKeys.Errors.networkError.localized
        case .timeout:
            return "Request timeout"
        case .unauthorized:
            return LocalizationKeys.Errors.authenticationFailed.localized
        case .forbidden:
            return LocalizationKeys.Errors.permissionDenied.localized
        case .notFound:
            return LocalizationKeys.Errors.fileNotFound.localized
        case .serverError:
            return LocalizationKeys.Errors.serverError.localized
        case .unknown(let error):
            return error.localizedDescription
        }
    }
}

// MARK: - HTTP Method

enum HTTPMethod: String {
    case GET = "GET"
    case POST = "POST"
    case PUT = "PUT"
    case DELETE = "DELETE"
    case PATCH = "PATCH"
}

// MARK: - API Response Model

struct APIResponse<T: Codable>: Codable {
    let success: Bool
    let data: T?
    let message: String?
    let timestamp: String?
    let error: APIError?
}

struct APIError: Codable {
    let code: String
    let message: String
    let details: [String: AnyCodable]?
}

struct AnyCodable: Codable {
    let value: Any
    
    init<T>(_ value: T?) {
        self.value = value ?? ()
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        
        if let intValue = try? container.decode(Int.self) {
            value = intValue
        } else if let doubleValue = try? container.decode(Double.self) {
            value = doubleValue
        } else if let stringValue = try? container.decode(String.self) {
            value = stringValue
        } else if let boolValue = try? container.decode(Bool.self) {
            value = boolValue
        } else if let arrayValue = try? container.decode([AnyCodable].self) {
            value = arrayValue.map { $0.value }
        } else if let dictValue = try? container.decode([String: AnyCodable].self) {
            value = dictValue.mapValues { $0.value }
        } else {
            value = ()
        }
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        
        switch value {
        case let intValue as Int:
            try container.encode(intValue)
        case let doubleValue as Double:
            try container.encode(doubleValue)
        case let stringValue as String:
            try container.encode(stringValue)
        case let boolValue as Bool:
            try container.encode(boolValue)
        case let arrayValue as [Any]:
            try container.encode(arrayValue.map { AnyCodable($0) })
        case let dictValue as [String: Any]:
            try container.encode(dictValue.mapValues { AnyCodable($0) })
        default:
            try container.encodeNil()
        }
    }
}

// MARK: - Network Manager

class NetworkManager: ObservableObject {
    static let shared = NetworkManager()
    
    private let session: URLSession
    private var cancellables = Set<AnyCancellable>()
    private var monitor: NWPathMonitor?
    
    @Published var isOnline: Bool = true
    
    private init() {
        let configuration = URLSessionConfiguration.default
        configuration.timeoutIntervalForRequest = AppConfig.Network.requestTimeout
        configuration.timeoutIntervalForResource = AppConfig.Network.requestTimeout * 2
        configuration.requestCachePolicy = AppConfig.Network.cachePolicy
        
        self.session = URLSession(configuration: configuration)
        
        setupNetworkMonitoring()
    }
    
    private func setupNetworkMonitoring() {
        let monitor = NWPathMonitor()
        monitor.pathUpdateHandler = { [weak self] path in
            DispatchQueue.main.async {
                self?.isOnline = path.status == .satisfied
            }
        }
        let queue = DispatchQueue(label: "NetworkMonitor")
        monitor.start(queue: queue)
        self.monitor = monitor
    }
    
    // MARK: - Request Methods
    
    func request<T: Codable>(
        endpoint: String,
        method: HTTPMethod = .GET,
        parameters: [String: Any]? = nil,
        body: Encodable? = nil,
        headers: [String: String]? = nil,
        responseType: T.Type
    ) -> AnyPublisher<T, NetworkError> {
        
        guard let url = buildURL(endpoint: endpoint, parameters: parameters) else {
            return Fail(error: NetworkError.invalidURL)
                .eraseToAnyPublisher()
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = method.rawValue
        
        // Add default headers
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        
        // Add custom headers
        headers?.forEach { key, value in
            request.setValue(value, forHTTPHeaderField: key)
        }
        
        // Add authentication header if available
        if let authToken = AuthenticationManager.shared.getCurrentAccessToken() {
            request.setValue("Bearer \(authToken)", forHTTPHeaderField: "Authorization")
        }
        
        // Add body for POST/PUT requests
        if let body = body {
            do {
                request.httpBody = try JSONEncoder().encode(body)
            } catch {
                return Fail(error: NetworkError.encodingError(error))
                    .eraseToAnyPublisher()
            }
        }
        
        #if DEBUG
        if AppConfig.Debug.enableNetworkLogging {
            logRequest(request)
        }
        #endif
        
        return session.dataTaskPublisher(for: request)
            .tryMap { data, response in
                #if DEBUG
                if AppConfig.Debug.enableNetworkLogging {
                    self.logResponse(data: data, response: response)
                }
                #endif
                
                guard let httpResponse = response as? HTTPURLResponse else {
                    throw NetworkError.unknown(URLError(.badServerResponse))
                }
                
                // Handle HTTP status codes
                switch httpResponse.statusCode {
                case 200...299:
                    return data
                case 401:
                    // Handle unauthorized - might need to refresh token
                    Task { await AuthenticationManager.shared.signOut() }
                    throw NetworkError.unauthorized
                case 403:
                    throw NetworkError.forbidden
                case 404:
                    throw NetworkError.notFound
                case 500...599:
                    throw NetworkError.serverError
                default:
                    let message = HTTPURLResponse.localizedString(forStatusCode: httpResponse.statusCode)
                    throw NetworkError.httpError(httpResponse.statusCode, message)
                }
            }
            .decode(type: APIResponse<T>.self, decoder: JSONDecoder())
            .tryMap { apiResponse in
                if apiResponse.success, let data = apiResponse.data {
                    return data
                } else {
                    let errorMessage = apiResponse.error?.message ?? apiResponse.message ?? "Unknown error"
                    throw NetworkError.httpError(0, errorMessage)
                }
            }
            .mapError { error in
                if let networkError = error as? NetworkError {
                    return networkError
                } else if let decodingError = error as? DecodingError {
                    return NetworkError.decodingError(decodingError)
                } else if let urlError = error as? URLError {
                    switch urlError.code {
                    case .notConnectedToInternet, .networkConnectionLost:
                        return NetworkError.networkUnavailable
                    case .timedOut:
                        return NetworkError.timeout
                    default:
                        return NetworkError.unknown(urlError)
                    }
                } else {
                    return NetworkError.unknown(error)
                }
            }
            .retry(AppConfig.Network.maxRetryAttempts)
            .eraseToAnyPublisher()
    }
    
    // MARK: - Convenience Methods
    
    func get<T: Codable>(
        endpoint: String,
        parameters: [String: Any]? = nil,
        responseType: T.Type
    ) -> AnyPublisher<T, NetworkError> {
        return request(
            endpoint: endpoint,
            method: .GET,
            parameters: parameters,
            responseType: responseType
        )
    }
    
    func post<T: Codable>(
        endpoint: String,
        body: Encodable,
        responseType: T.Type
    ) -> AnyPublisher<T, NetworkError> {
        return request(
            endpoint: endpoint,
            method: .POST,
            body: body,
            responseType: responseType
        )
    }
    
    func put<T: Codable>(
        endpoint: String,
        body: Encodable,
        responseType: T.Type
    ) -> AnyPublisher<T, NetworkError> {
        return request(
            endpoint: endpoint,
            method: .PUT,
            body: body,
            responseType: responseType
        )
    }
    
    func delete<T: Codable>(
        endpoint: String,
        responseType: T.Type
    ) -> AnyPublisher<T, NetworkError> {
        return request(
            endpoint: endpoint,
            method: .DELETE,
            responseType: responseType
        )
    }
    
    // MARK: - Helper Methods
    
    private func buildURL(endpoint: String, parameters: [String: Any]?) -> URL? {
        var components = URLComponents(string: "\(AppConfig.apiBaseURL)/\(endpoint)")
        
        if let parameters = parameters {
            components?.queryItems = parameters.map { key, value in
                URLQueryItem(name: key, value: "\(value)")
            }
        }
        
        return components?.url
    }
    
    #if DEBUG
    private func logRequest(_ request: URLRequest) {
        print("🌐 Network Request:")
        print("URL: \(request.url?.absoluteString ?? "nil")")
        print("Method: \(request.httpMethod ?? "nil")")
        print("Headers: \(request.allHTTPHeaderFields ?? [:])")
        if let body = request.httpBody {
            print("Body: \(String(data: body, encoding: .utf8) ?? "nil")")
        }
        print("---")
    }
    
    private func logResponse(data: Data, response: URLResponse) {
        print("🌐 Network Response:")
        if let httpResponse = response as? HTTPURLResponse {
            print("Status Code: \(httpResponse.statusCode)")
        }
        print("Data: \(String(data: data, encoding: .utf8) ?? "nil")")
        print("---")
    }
    #endif
}

// Remove Auth Manager placeholder since we're using AuthenticationManager 
