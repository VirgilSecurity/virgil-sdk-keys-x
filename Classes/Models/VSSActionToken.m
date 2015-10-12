//
//  VSSActionToken.m
//  VirgilKeysSDK
//
//  Created by Pavel Gorb on 9/13/15.
//  Copyright (c) 2015 VirgilSecurity. All rights reserved.
//

#import "VSSActionToken.h"
#import "VSSKeysModelCommons.h"
#import <VirgilFrameworkiOS/NSObject+VSSUtils.h>

@interface VSSActionToken ()

@property (nonatomic, copy, readwrite) GUID * __nonnull tokenId;
@property (nonatomic, copy, readwrite) NSArray * __nonnull userIdList;

@end

@implementation VSSActionToken

@synthesize tokenId = _tokenId;
@synthesize userIdList = _userIdList;
@synthesize confirmationCodeList = _confirmationCodeList;

#pragma mark - Lifecycle

- (instancetype)initWithTokenId:(GUID *)tokenId userIdList:(NSArray *)userIdList confirmationCodeList:(NSArray *)codeList {
    self = [super init];
    if (self == nil) {
        return nil;
    }
    
    _tokenId = [tokenId copy];
    // Deep 1-level copy. userIdList just contains NSString values with User Ids.
    _userIdList = [[NSArray alloc] initWithArray:userIdList copyItems:YES];
    // Deep 1-level copy. userIdList just contains NSString values with confirmation codes.
    if (codeList != nil) {
        _confirmationCodeList = [[NSArray alloc] initWithArray:codeList copyItems:YES];
    }
    return self;
}

- (instancetype)init {
    return [self initWithTokenId:@"" userIdList:@[] confirmationCodeList:nil];
}

#pragma mark - NSCopying

- (instancetype)copyWithZone:(NSZone *)zone {
    return [self initWithTokenId:self.tokenId userIdList:self.userIdList confirmationCodeList:self.confirmationCodeList];
}

#pragma mark - NSCoding

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    GUID *tokenId = [[aDecoder decodeObjectForKey:kVSSKeysModelActionToken] as:[GUID class]];
    NSArray *userIdList = [[aDecoder decodeObjectForKey:kVSSKeysModelUserIDs] as:[NSArray class]];
    NSArray *confCodes = [[aDecoder decodeObjectForKey:kVSSKeysModelConfirmationCodes] as:[NSArray class]];
    
    return [self initWithTokenId:tokenId userIdList:userIdList confirmationCodeList:confCodes];
}

- (void)encodeWithCoder:(NSCoder *)aCoder {
    [super encodeWithCoder:aCoder];
    
    if (self.tokenId != nil) {
        [aCoder encodeObject:self.tokenId forKey:kVSSKeysModelActionToken];
    }
    if (self.userIdList != nil) {
        [aCoder encodeObject:self.userIdList forKey:kVSSKeysModelUserIDs];
    }
    if (self.confirmationCodeList != nil) {
        [aCoder encodeObject:self.confirmationCodeList forKey:kVSSKeysModelConfirmationCodes];
    }
}

#pragma mark - VFSerializable

- (NSDictionary *)serialize {
    NSMutableDictionary *dto = [[NSMutableDictionary alloc] initWithDictionary:[super serialize]];
    
    if (self.tokenId != nil) {
        dto[kVSSKeysModelActionToken] = self.tokenId;
    }

    if (self.confirmationCodeList != nil) {
        dto[kVSSKeysModelConfirmationCodes] = self.confirmationCodeList;
    }
    
    return dto;
}

+ (instancetype)deserializeFrom:(NSDictionary *)candidate {
    GUID *tokenId = [candidate[kVSSKeysModelActionToken] as:[GUID class]];
    NSArray *userIdList = [candidate[kVSSKeysModelUserIDs] as:[NSArray class]];
    
    return [[[self class] alloc] initWithTokenId:tokenId userIdList:userIdList confirmationCodeList:nil];
}

#pragma mark - Overrides

- (NSNumber *)isValid {
    return [NSNumber numberWithBool:( (self.tokenId.length > 0) && (self.userIdList.count > 0) && ( (self.confirmationCodeList == nil) ? YES : (self.confirmationCodeList.count == self.userIdList.count) ) )];
}

@end