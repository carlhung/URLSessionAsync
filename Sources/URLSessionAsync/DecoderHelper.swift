import Foundation

public extension StringProtocol {
    @inlinable
    func decodeJSON<T: Decodable>(_ type: T.Type = T.self,
                                encoding: String.Encoding = .utf8,
                                decodingStrategy: JSONDecoder.KeyDecodingStrategy = .useDefaultKeys,
                                dateDecodingStrategy: JSONDecoder.DateDecodingStrategy = .deferredToDate,
                                dataDecodingStrategy: JSONDecoder.DataDecodingStrategy = .base64) throws -> T {
        let data = self.data(using: encoding) ?? Data()
        return try data.decodeJSON(T.self, 
                                   decodingStrategy: decodingStrategy, 
                                   dateDecodingStrategy: dateDecodingStrategy, 
                                   dataDecodingStrategy: dataDecodingStrategy)
    }
}

public extension Data {
    @inlinable
    func decodeJSON<T: Decodable>(_ type: T.Type = T.self,
                                decodingStrategy: JSONDecoder.KeyDecodingStrategy = .useDefaultKeys,
                                dateDecodingStrategy: JSONDecoder.DateDecodingStrategy = .deferredToDate,
                                dataDecodingStrategy: JSONDecoder.DataDecodingStrategy = .base64) throws -> T {
        let decoder = JSONDecoder()

        switch decodingStrategy {
        case .useDefaultKeys: break
        default: decoder.keyDecodingStrategy = decodingStrategy
        }

        switch dateDecodingStrategy {
        case .deferredToDate: break
        default: decoder.dateDecodingStrategy = dateDecodingStrategy
        }

        switch dataDecodingStrategy {
        case .base64: break
        default: decoder.dataDecodingStrategy = dataDecodingStrategy
        }
        return try decoder.decode(T.self, from: self)    
    }
}
