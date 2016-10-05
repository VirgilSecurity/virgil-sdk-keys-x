//
//  VSSCrypto.m
//  VirgilSDK
//
//  Created by Oleksandr Deundiak on 9/29/16.
//  Copyright © 2016 VirgilSecurity. All rights reserved.
//

#import <Foundation/Foundation.h>
#include <CommonCrypto/CommonDigest.h>
#import "VSSCrypto.h"
#import "VSSCryptoPrivate.h"
#import "VSSKeyPairPrivate.h"
#import "VSSPublicKeyPrivate.h"
#import "VSSPrivateKeyPrivate.h"


@import VirgilCrypto;

@implementation VSSCrypto

- (VSSKeyPair *)generateKey {
    VSCKeyPair *keyPair = [[VSCKeyPair alloc] init];
    
    NSData *keyPairId = [self computeHashForPublicKey:keyPair.publicKey];
    if ([keyPairId length] == 0)
        return nil;
    
    VSSPrivateKey *privateKey = [[VSSPrivateKey alloc] initWithKey:keyPair.privateKey identifier:keyPairId];
    VSSPublicKey *publicKey = [[VSSPublicKey alloc] initWithKey:keyPair.publicKey identifier:keyPairId];
    
    return [[VSSKeyPair alloc] initWithPrivateKey:privateKey publicKey:publicKey];
}

- (VSSPrivateKey *)importPrivateKey:(NSData *)keyData password:(NSString *)password {
    if ([keyData length] == 0)
        return nil;

    NSData *privateKeyData = ([password length] == 0) ?
        [VSCKeyPair privateKeyToDER:keyData] : [VSCKeyPair decryptPrivateKey:keyData privateKeyPassword:password];
    
    if ([privateKeyData length] == 0)
        return nil;

    NSData *publicKey = [VSCKeyPair extractPublicKeyWithPrivateKey:privateKeyData privateKeyPassword:nil];
    if ([publicKey length] == 0)
        return nil;

    NSData *keyIdentifier = [self computeHashForPublicKey:publicKey];
    if ([keyIdentifier length] == 0)
        return nil;
    
    NSData *exportedPrivateKeyData = [VSCKeyPair privateKeyToDER:privateKeyData];
    if ([exportedPrivateKeyData length] == 0)
        return nil;
    
    VSSPrivateKey *privateKey = [[VSSPrivateKey alloc] initWithKey:exportedPrivateKeyData identifier:keyIdentifier];
    
    return privateKey;
}

- (VSSPublicKey *)importPublicKey:(NSData *)keyData {
    NSData *keyIdentifier = [self computeHashForPublicKey:keyData];
    if ([keyData length] == 0)
        return nil;

    NSData *exportedPublicKey = [VSCKeyPair publicKeyToDER:keyData];
    if ([exportedPublicKey length] == 0)
        return nil;
    
    VSSPublicKey *publicKey = [[VSSPublicKey alloc] initWithKey:exportedPublicKey identifier:keyIdentifier];
    if (publicKey == nil)
        return nil;
    
    return publicKey;
}

- (NSData *)exportPrivateKey:(VSSPrivateKey *)privateKey password:(NSString *)password {
    if ([password length] == 0)
        return [VSCKeyPair privateKeyToDER:privateKey.key];
    
    NSData *encryptedPrivateKeyData = [VSCKeyPair encryptPrivateKey:privateKey.key privateKeyPassword:password];
    
    return [VSCKeyPair privateKeyToDER:encryptedPrivateKeyData privateKeyPassword:password];
}

- (NSData *)exportPublicKey:(VSSPublicKey *)publicKey {
    return [VSCKeyPair publicKeyToDER:publicKey.key];
}

- (VSSPublicKey *)extractPublicKeyFromPrivateKey:(VSSPrivateKey *)privateKey {
    NSData *publicKeyData = [VSCKeyPair extractPublicKeyWithPrivateKey:privateKey.key privateKeyPassword:nil];
    if ([publicKeyData length] == 0)
        return nil;
    
    NSData *exportedPublicKey = [VSCKeyPair publicKeyToDER:publicKeyData];
    if ([exportedPublicKey length] == 0)
        return nil;
    
    VSSPublicKey *publicKey = [[VSSPublicKey alloc] initWithKey:exportedPublicKey identifier:privateKey.identifier];
    
    return publicKey;
}

- (NSData *)encryptData:(NSData *)data forRecipients:(NSArray<VSSPublicKey *> *)recipients error:(NSError **)errorPtr {
    VSCCryptor *cipher = [[VSCCryptor alloc] init];
    
    NSError *error;
    for (VSSPublicKey *publicKey in recipients) {
        [cipher addKeyRecipient:publicKey.identifier publicKey:publicKey.key error:&error];
        
        if (error != nil) {
            if (errorPtr != nil)
                *errorPtr = error;
            return nil;
        }
    }

    NSData *encryptedData = [cipher encryptData:data embedContentInfo:YES error:&error];
    if (error != nil) {
        if (errorPtr != nil)
            *errorPtr = error;
        return nil;
    }

    return encryptedData;
}

- (void)encryptStream:(NSInputStream *)stream outputStream:(NSOutputStream *)outputStream forRecipients:(NSArray<VSSPublicKey *> *)recipients error:(NSError **)errorPtr {
    VSCChunkCryptor *cipher = [[VSCChunkCryptor alloc] init];

    NSError *error;
    for (VSSPublicKey *publicKey in recipients) {
        [cipher addKeyRecipient:publicKey.identifier publicKey:publicKey.key error:&error];
        if (error != nil) {
            if (errorPtr != nil)
                *errorPtr = error;
            return;
        }
    }

    [cipher encryptDataFromStream:stream toStream:outputStream error:&error];
    if (error != nil) {
        if (errorPtr != nil)
            *errorPtr = error;
        return;
    }
}

- (bool)verifyData:(NSData *)data signature:(NSData *)signature signerPublicKey:(VSSPublicKey *)signerPublicKey error:(NSError **)errorPtr {
    VSCSigner *signer = [[VSCSigner alloc] init];
    
    NSError *error;
    BOOL verified = [signer verifySignature:signature data:data publicKey:signerPublicKey.key error:&error];
    
    if (error != nil) {
        if (errorPtr != nil)
            *errorPtr = error;
        return NO;
    }
    
    return verified;
}

- (bool)verifyStream:(NSInputStream *)inputStream signature:(NSData *)signature signerPublicKey:(VSSPublicKey *)signerPublicKey error:(NSError **)errorPtr {
    VSCStreamSigner *signer = [[VSCStreamSigner alloc] init];
    
    NSError *error;
    BOOL verified = [signer verifySignature:signature fromStream:inputStream publicKey:signerPublicKey.key error:&error];
    
    if (error != nil) {
        if (errorPtr != nil)
            *errorPtr = error;
        return NO;
    }
    
    return verified;
}

- (NSData *)decryptData:(NSData *)data privateKey:(VSSPrivateKey *)privateKey error:(NSError **)errorPtr {
    VSCCryptor *cipher = [[VSCCryptor alloc] init];

    NSError *error;
    NSData *decryptedData = [cipher decryptData:data recipientId:privateKey.identifier privateKey:privateKey.key keyPassword:nil error:&error];
    
    if (error != nil) {
        if (errorPtr != nil)
            *errorPtr = error;
        return nil;
    }
    
    return decryptedData;
}

- (void)decryptStream:(NSInputStream * __nonnull)inputStream outputStream:(NSOutputStream * __nonnull)outputStream privateKey:(VSSPrivateKey * __nonnull)privateKey error:(NSError **)errorPtr {
    VSCChunkCryptor *cipher = [[VSCChunkCryptor alloc] init];

    NSError *error;
    [cipher decryptFromStream:inputStream toStream:outputStream recipientId:privateKey.identifier privateKey:privateKey.key keyPassword:nil error:&error];
    
    if (error != nil) {
        if (errorPtr != nil)
            *errorPtr = error;
    }
}

- (NSData *)signData:(NSData *)data privateKey:(VSSPrivateKey *)privateKey error:(NSError **)errorPtr {
    VSCSigner *signer = [[VSCSigner alloc] init];
    
    NSError *error;
    NSData *signature = [signer signData:data privateKey:privateKey.key keyPassword:nil error:&error];
    
    if (error != nil) {
        if (errorPtr != nil)
            *errorPtr = error;
        return nil;
    }
    
    return signature;
}

- (NSData *)signStream:(NSInputStream *)stream privateKey:(VSSPrivateKey *)privateKey error:(NSError **)errorPtr {
    VSCStreamSigner *signer = [[VSCStreamSigner alloc] init];
    
    NSError *error;
    NSData *signature = [signer signStreamData:stream privateKey:privateKey.key keyPassword:nil error:&error];
    
    if (error != nil) {
        if (errorPtr != nil)
            *errorPtr = error;
        return nil;
    }
    
    return signature;
}

- (VSSFingerprint * __nonnull)calculateFingerprintOfData:(NSData * __nonnull)data {
    NSData *hash = [self computeHashOfData:data withAlgorithm:VSSHashAlgorithmSHA256];
    return [[VSSFingerprint alloc] initWithValue:hash];
}

- (NSData *)SHA256_HASHForData:(NSData * __nonnull)data {
    NSMutableData *macOut = [[NSMutableData alloc] initWithLength:CC_SHA256_DIGEST_LENGTH];
    CC_SHA256(data.bytes, (CC_LONG)data.length, macOut.mutableBytes);
    return macOut;
}

- (NSData * __nonnull)computeHashOfData:(NSData * __nonnull)data withAlgorithm:(VSSHashAlgorithm)algorithm {
    // fixme
    if (algorithm == VSSHashAlgorithmSHA256) {
        return [self SHA256_HASHForData:data];
    }
    else
        return nil;
//    return [@"testId" dataUsingEncoding:NSUTF8StringEncoding];
//    return [[NSData alloc] init];
}

- (NSData *)computeHashForPublicKey:(NSData *)publicKey {
    NSData *publicKeyDER = [VSCKeyPair publicKeyToDER:publicKey];
    return [self computeHashOfData:publicKeyDER withAlgorithm:VSSHashAlgorithmSHA256];
}

@end
