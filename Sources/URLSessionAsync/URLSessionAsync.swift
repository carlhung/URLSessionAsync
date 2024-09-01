import Foundation

#if canImport(FoundationNetworking)
    import FoundationNetworking
#endif

public extension URLSession {
    enum URLSessionError: CustomStringConvertible, Error {
        case nilData
        case nilResponse
        case httpURLResponseFailure
        case wrongStatusCode(Int)

        // It must mark as public. otherwise, I will consider as internal.
        // when the other module runs it, it will call the default one.
        public var localizedDescription: String {
            switch self {
            case .nilData: return "nil data"
            case .nilResponse: return "nil response"
            case .httpURLResponseFailure: return "failed to cast to HTTPURLResponse"
            case .wrongStatusCode(let wrongCode):
                return "wrong status code: " + String(wrongCode)
            }
        }

        public var description: String {
            self.localizedDescription
        }
    }

    enum CheckStatus {
        case statusRange(Range<Int>), statusCode(Int), statusCodeSet(Set<Int>)
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
        accept status: CheckStatus? = nil, 
        encoding: String.Encoding = .utf8,
        decodingStrategy: JSONDecoder.KeyDecodingStrategy = .useDefaultKeys,
        dateDecodingStrategy: JSONDecoder.DateDecodingStrategy = .deferredToDate,
        dataDecodingStrategy: JSONDecoder.DataDecodingStrategy = .base64, 
        decode _: T.Type = T.self
    ) async throws -> T {
        let result = try await self.data(from: from)
        return try handler(
            result: result, 
            status: status, 
            encoding: encoding, 
            decodingStrategy: decodingStrategy, 
            dateDecodingStrategy: dateDecodingStrategy, 
            dataDecodingStrategy: dataDecodingStrategy
        )
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
        decode _: T.Type = T.self
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
        encoding: String.Encoding,// = .utf8,
        decodingStrategy: JSONDecoder.KeyDecodingStrategy,// = .useDefaultKeys,
        dateDecodingStrategy: JSONDecoder.DateDecodingStrategy,// = .deferredToDate,
        dataDecodingStrategy: JSONDecoder.DataDecodingStrategy// = .base64
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
            case .statusCodeSet(let statusCodeSet) where statusCodeSet.contains(httpURLResponse.statusCode):
                isSuccess = true
            default:
                isSuccess = false
            }
            guard isSuccess else {
                throw URLSessionError.wrongStatusCode(httpURLResponse.statusCode)
            }
        }
        return try data.decodeJSON(decodingStrategy: decodingStrategy, dateDecodingStrategy: dateDecodingStrategy, dataDecodingStrategy: dataDecodingStrategy)
    }
}