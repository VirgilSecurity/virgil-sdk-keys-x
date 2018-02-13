//
//  Card.swift
//  VirgilSDK
//
//  Created by Oleksandr Deundiak on 9/15/17.
//  Copyright © 2017 VirgilSecurity. All rights reserved.
//

import Foundation
import VirgilCryptoAPI

@objc(VSSCard) public class Card: NSObject {
    @objc public let identifier: String
    @objc public let identity: String
    @objc public let publicKey: PublicKey
    @objc public let previousCardId: String?
    @objc public var previousCard: Card?
    @objc public var isOutdated: Bool
    @objc public let version: String
    @objc public let createdAt: Date
    @objc public let signatures: [CardSignature]
    @objc public let contentSnapshot: Data

    private init(identifier: String, identity: String, publicKey: PublicKey,
                 isOutdated: Bool = false, version: String, createdAt: Date,
                 signatures: [CardSignature], previousCardId: String? = nil,
                 previousCard: Card? = nil, contentSnapshot: Data) {

        self.identifier = identifier
        self.identity = identity
        self.publicKey = publicKey
        self.previousCardId = previousCardId
        self.previousCard = previousCard
        self.isOutdated = isOutdated
        self.version = version
        self.createdAt = createdAt
        self.signatures = signatures
        self.contentSnapshot = contentSnapshot

        super.init()
    }

    @objc public class func parse(cardCrypto: CardCrypto, rawSignedModel: RawSignedModel) -> Card? {
        let contentSnapshot = rawSignedModel.contentSnapshot
        guard let rawCardContent = try? JSONDecoder().decode(RawCardContent.self, from: contentSnapshot) else {
            return nil
        }

        guard let publicKeyData = Data(base64Encoded: rawCardContent.publicKey),
              let publicKey = try? cardCrypto.importPublicKey(from: publicKeyData),
              let fingerprint = try? cardCrypto.generateSHA512(for: rawSignedModel.contentSnapshot) else {
                return nil
        }

        let cardId = fingerprint.subdata(in: 0..<32).hexEncodedString()

        var cardSignatures: [CardSignature] = []
        for rawSignature in rawSignedModel.signatures {
            let extraFields: [String: String]?

            if let rawSnapshot = rawSignature.snapshot,
                let json = try? JSONSerialization.jsonObject(with: rawSnapshot, options: []),
                   let result = json as? [String: String] {
                    extraFields = result
                }
            else {
                extraFields = nil
            }

            let cardSignature = CardSignature(signer: rawSignature.signer, signature: rawSignature.signature,
                                              snapshot: rawSignature.snapshot, extraFields: extraFields)

            cardSignatures.append(cardSignature)
        }
        let createdAt = Date(timeIntervalSince1970: TimeInterval(rawCardContent.createdAt))

        return Card(identifier: cardId, identity: rawCardContent.identity, publicKey: publicKey,
                    version: rawCardContent.version, createdAt: createdAt, signatures: cardSignatures,
                    previousCardId: rawCardContent.previousCardId, contentSnapshot: rawSignedModel.contentSnapshot)
    }

    @objc public func getRawCard(cardCrypto: CardCrypto) throws -> RawSignedModel {
        let rawCard = RawSignedModel(contentSnapshot: self.contentSnapshot)

        for cardSignature in self.signatures {
            let signature = RawSignature(signer: cardSignature.signer,
                                         signature: cardSignature.signature,
                                         snapshot: cardSignature.snapshot)

            try rawCard.addSignature(signature)
        }

        return rawCard
    }
}
