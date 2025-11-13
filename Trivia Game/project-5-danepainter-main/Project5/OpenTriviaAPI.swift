//
//  OpenTriviaAPI.swift
//  Project5
//
//  Created by Dane Shaw on 10/29/25.
//

import Foundation

enum OpenTriviaError: Error, LocalizedError {
    case invalidURL
    case badStatus(code: Int)
    case decoding
    case noResults
    case invalidParameter
    case tokenNotFound
    case tokenEmpty
    case rateLimited
    case unknown(code: Int)

    var errorDescription: String? {
        switch self {
        case .invalidURL: return "Invalid URL."
        case .badStatus(let code): return "Network request failed (HTTP \(code))."
        case .decoding: return "Failed to decode response."
        case .noResults: return "No results for this query."
        case .invalidParameter: return "Invalid parameter."
        case .tokenNotFound: return "Session token not found."
        case .tokenEmpty: return "Token exhausted. Reset is required."
        case .rateLimited: return "Rate limit hit. Try again in a few seconds."
        case .unknown(let code): return "Unknown API response code: \(code)."
        }
    }
}

final class OpenTriviaAPI {
    static let shared = OpenTriviaAPI()
    private init() {}

    private let base = "https://opentdb.com"
    private let session = URLSession.shared

    // Persist the token simply in UserDefaults
    private let tokenKey = "opentdb_session_token"

    var token: String? {
        get { UserDefaults.standard.string(forKey: tokenKey) }
        set { UserDefaults.standard.setValue(newValue, forKey: tokenKey) }
    }

    @discardableResult
    func ensureToken() async throws -> String {
        if let t = token { return t }
        let url = URL(string: "\(base)/api_token.php?command=request")!
        let (data, _) = try await request(url: url)

        struct TokenResponse: Decodable { let response_code: Int; let token: String }
        let decoded = try JSONDecoder().decode(TokenResponse.self, from: data)
        guard decoded.response_code == 0 else { throw OpenTriviaError.unknown(code: decoded.response_code) }
        token = decoded.token
        return decoded.token
    }

    func resetToken() async throws {
        guard let t = token else { throw OpenTriviaError.tokenNotFound }
        let url = URL(string: "\(base)/api_token.php?command=reset&token=\(t)")!
        let (data, _) = try await request(url: url)
        struct ResetResponse: Decodable { let response_code: Int }
        let decoded = try JSONDecoder().decode(ResetResponse.self, from: data)
        guard decoded.response_code == 0 else { throw OpenTriviaError.unknown(code: decoded.response_code) }
    }

    func fetchQuestions(
        amount: Int,
        categoryID: Int?,
        difficulty: String?,     // "easy" | "medium" | "hard" | nil
        type: String?            // "multiple" | "boolean" | nil
    ) async throws -> [TriviaQuestion] {
        func buildURL() async throws -> URL {
            var comps = URLComponents(string: "\(base)/api.php")!
            var items = [URLQueryItem(name: "amount", value: String(amount))]
            if let categoryID { items.append(URLQueryItem(name: "category", value: String(categoryID))) }
            if let difficulty { items.append(URLQueryItem(name: "difficulty", value: difficulty)) }
            if let type { items.append(URLQueryItem(name: "type", value: type)) }
            if let tok = try? await ensureToken() {
                items.append(URLQueryItem(name: "token", value: tok))
            }
            comps.queryItems = items
            guard let url = comps.url else { throw OpenTriviaError.invalidURL }
            return url
        }

        // First attempt
        var (data, _) = try await request(url: try buildURL())
        var decoded = try decodeResponse(data)

        // If token invalid/empty, fetch a new token and retry once
        if decoded.response_code == 3 || decoded.response_code == 4 {
            token = nil
            _ = try? await ensureToken()
            (data, _) = try await request(url: try buildURL())
            decoded = try decodeResponse(data)
        }

        switch decoded.response_code {
        case 0:
            return decoded.results
        case 1:
            throw OpenTriviaError.noResults
        case 2:
            throw OpenTriviaError.invalidParameter
        case 3:
            throw OpenTriviaError.tokenNotFound
        case 4:
            throw OpenTriviaError.tokenEmpty
        case 5:
            throw OpenTriviaError.rateLimited
        default:
            throw OpenTriviaError.unknown(code: decoded.response_code)
        }
    }

    // MARK: - Internal request helper with headers and status validation
    private func request(url: URL) async throws -> (Data, HTTPURLResponse) {
        var req = URLRequest(url: url)
        req.httpMethod = "GET"
        // Adding a User-Agent avoids occasional 403s from CDNs
        req.setValue("Project5/1.0 (iOS)", forHTTPHeaderField: "User-Agent")
        req.setValue("application/json", forHTTPHeaderField: "Accept")
        req.timeoutInterval = 30

        #if DEBUG
        print("[OpenTriviaAPI] GET \(url.absoluteString)")
        #endif

        let (data, response) = try await session.data(for: req)
        guard let http = response as? HTTPURLResponse else {
            throw OpenTriviaError.badStatus(code: -1)
        }
        guard http.statusCode == 200 else {
            throw OpenTriviaError.badStatus(code: http.statusCode)
        }
        return (data, http)
    }

    // MARK: - Decode helper with debug logging
    private func decodeResponse(_ data: Data) throws -> TriviaResponse {
        do {
            return try JSONDecoder().decode(TriviaResponse.self, from: data)
        } catch {
            #if DEBUG
            if let text = String(data: data, encoding: .utf8) {
                print("[OpenTriviaAPI] Decoding failed. Raw response:\n\(text)")
            }
            #endif
            throw OpenTriviaError.decoding
        }
    }
}
