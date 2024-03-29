import Foundation

#if canImport(FoundationNetworking)
    import FoundationNetworking
#endif

public extension URLSession {
    enum URLSessionError: String, Error {
        case nilData
        case nilResponse
        case httpURLResponseFailure = "failed to cast to HTTPURLResponse"
        case statusCodeFailure = "wrong status code"

        // It must mark as public. otherwise, I will consider as internal.
        // when the other module runs it, it will call the default one.
        public var localizedDescription: String {
            rawValue
        }
    }

    enum CheckStatus {
        case statusRange(Range<Int>), statusCode(Int)
    }
}


#if os(Linux)
public extension URLSession {

    func data(from url: URL) async throws -> (Data, URLResponse) {
        return try await withCheckedThrowingContinuation { continuation in
            self.dataTask(with: url, completionHandler: {(data: Data?, urlResponse: URLResponse?, error: Error?) in
                self.handler(continuation: continuation, data: data, urlResponse: urlResponse, error: error)
            }).resume()
        }
    }

    func data(for request: URLRequest) async throws -> (Data, URLResponse) {
        return try await withCheckedThrowingContinuation { continuation in
            self.dataTask(with: request, completionHandler: {(data: Data?, urlResponse: URLResponse?, error: Error?) in
                self.handler(continuation: continuation, data: data, urlResponse: urlResponse, error: error)
            }).resume()
        }
    }

    private func handler(continuation: CheckedContinuation<(Data, URLResponse), Error>, data: Data?, urlResponse: URLResponse?, error: Error?) {
        guard error == nil else {
            continuation.resume(throwing: error!)
            return
        }
        guard let urlResponse else {
            continuation.resume(throwing: URLSessionError.nilResponse)
            return
        }
        guard let data else {
            continuation.resume(throwing: URLSessionError.nilData)
            return
        }
        continuation.resume(returning: (data, urlResponse))
    }
}
#endif

public extension URLSession {

    @available(macOS 12, iOS 15, *)
    @inlinable
    func fetch<T: Decodable>(
        from: URL, 
        accept state: CheckStatus? = nil, 
        encoding: String.Encoding = .utf8,
        decodingStrategy: JSONDecoder.KeyDecodingStrategy = .useDefaultKeys,
        dateDecodingStrategy: JSONDecoder.DateDecodingStrategy = .deferredToDate,
        dataDecodingStrategy: JSONDecoder.DataDecodingStrategy = .base64, 
        decode type: T.Type = T.self
    ) async throws -> T {
        let result = try await self.data(from: from)
        return try handler(result: result, status: state)
    }

    @available(macOS 12, iOS 15, *)
    @inlinable
    func fetch<T: Decodable>(
        for request: URLRequest, 
        accept status: CheckStatus? = nil, 
        encoding: String.Encoding = .utf8,
        decodingStrategy: JSONDecoder.KeyDecodingStrategy = .useDefaultKeys,
        dateDecodingStrategy: JSONDecoder.DateDecodingStrategy = .deferredToDate,
        dataDecodingStrategy: JSONDecoder.DataDecodingStrategy = .base64,
        decode type: T.Type = T.self
    ) async throws -> T {
        let result = try await self.data(for: request)
        return try handler(
            result: result, 
            status: status, 
            encoding: encoding, 
            decodingStrategy: decodingStrategy, 
            dateDecodingStrategy: dateDecodingStrategy, 
            dataDecodingStrategy: dataDecodingStrategy
        )
    }

    @usableFromInline
    internal func handler<T: Decodable>(
        result: (Data, URLResponse), 
        status: CheckStatus?, 
        encoding: String.Encoding = .utf8,
        decodingStrategy: JSONDecoder.KeyDecodingStrategy = .useDefaultKeys,
        dateDecodingStrategy: JSONDecoder.DateDecodingStrategy = .deferredToDate,
        dataDecodingStrategy: JSONDecoder.DataDecodingStrategy = .base64
    ) throws -> T {
        let (data, response) = result
        guard let httpURLResponse = response as? HTTPURLResponse else {
            throw URLSessionError.httpURLResponseFailure
        }
        
        if let status {
            let isSuccess: Bool
            switch status {
            case .statusRange(let range) where range ~= httpURLResponse.statusCode:
                isSuccess = true
            case .statusCode(let code) where code == httpURLResponse.statusCode:
                isSuccess = true
            default:
                isSuccess = false
            }
            guard isSuccess else {
                throw URLSessionError.statusCodeFailure
            }
        }
        return try data.decodeJSON(decodingStrategy: decodingStrategy, dateDecodingStrategy: dateDecodingStrategy, dataDecodingStrategy: dataDecodingStrategy)
    }
}