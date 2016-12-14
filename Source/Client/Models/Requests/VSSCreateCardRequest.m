//
//  VSSCreateCardRequest.m
//  VirgilSDK
//
//  Created by Oleksandr Deundiak on 9/29/16.
//  Copyright © 2016 VirgilSecurity. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "VSSCreateCardRequest.h"
#import "VSSSignableRequestPrivate.h"
#import "VSSCreateCardSnapshotModelPrivate.h"
#import "VSSModelKeys.h"
#import "NSObject+VSSUtils.h"

@implementation VSSCreateCardRequest

+ (instancetype)createCardRequestWithIdentity:(NSString *)identity identityType:(NSString *)identityType publicKeyData:(NSData *)publicKeyData data:(NSDictionary<NSString *, NSString *> *)data {
    VSSCreateCardSnapshotModel *model = [VSSCreateCardSnapshotModel createCardSnapshotModelWithIdentity:identity identityType:identityType publicKeyData:publicKeyData data:data];
    return [[VSSCreateCardRequest alloc] initWithSnapshotModel:model];
}

+ (instancetype)createCardRequestWithIdentity:(NSString *)identity identityType:(NSString *)identityType publicKeyData:(NSData *)publicKeyData {
    return [VSSCreateCardRequest createCardRequestWithIdentity:identity identityType:identityType publicKeyData:publicKeyData data:nil];
}

+ (VSSSnapshotModel * __nullable)buildSnapshotModelFromSnapshot:(NSData * __nonnull)snapshot {
    return [VSSCreateCardSnapshotModel createFromCanonicalForm:snapshot];
}

@end