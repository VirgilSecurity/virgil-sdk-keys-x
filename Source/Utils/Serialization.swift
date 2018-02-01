//
//  Serialization.swift
//  VirgilSDK
//
//  Created by Eugen Pivovarov on 1/17/18.
//  Copyright © 2018 VirgilSecurity. All rights reserved.
//

import Foundation

protocol Deserializable: Decodable {
    init?(data: Data)
    
    init?(base64: String)
    
    init?(dict any: Any)
}

protocol Serializable: Encodable {
    func asJson() throws -> Any
    
    func asJsonData() throws -> Data
    
    func asStringBase64() throws -> String
}

extension Deserializable {
    init?(data: Data) {
        guard let me = try? JSONDecoder().decode(Self.self, from: data) else { return nil }
        self = me
    }
    
    init?(base64: String) {
        guard let data = Data(base64Encoded: base64) else { return nil }
        self.init(data: data)
    }
    
    init?(dict any: Any) {
        guard let data = try? JSONSerialization.data(withJSONObject: any, options: [.prettyPrinted]) else { return nil }
        self.init(data: data)
    }
}

extension Serializable {
    func asJson() throws -> Any {
        let data = try self.asJsonData()
        let dictionary = try JSONSerialization.jsonObject(with: data, options: [.allowFragments])
        return dictionary
    }
    
    func asJsonData() throws -> Data {
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        return try encoder.encode(self)
    }
    
    func asStringBase64() throws -> String {
        let data = try self.asJsonData()
        return data.base64EncodedString()
    }
}
