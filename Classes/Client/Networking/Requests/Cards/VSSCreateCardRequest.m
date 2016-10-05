//
//  VSSCreateCardRequest.m
//  VirgilSDK
//
//  Created by Pavel Gorb on 2/3/16.
//  Copyright © 2016 VirgilSecurity. All rights reserved.
//

#import "VSSCreateCardRequest.h"
#import "VSSModelCommons.h"
#import "VSSCardData.h"
#import "VSSCardDataPrivate.h"
#import "VSSCardModel.h"
#import "VSSCardModelPrivate.h"
#import "NSObject+VSSUtils.h"

@implementation VSSCreateCardRequest

#pragma mark - Lifecycle

- (instancetype)initWithContext:(VSSRequestContext *)context cardModel:(VSSCardModel *)model {
    self = [super initWithContext:context];
    if (self == nil) {
        return nil;
    }
    
    NSDictionary *body = [model serialize];
    
    [self setRequestBodyWithObject:body];
    
    return self;
}

#pragma mark - Overrides

- (NSString *)methodPath {
    return @"card";
}

- (NSError *)handleResponse:(NSObject *)candidate {
    NSError *error = [super handleResponse:candidate];
    if (error != nil) {
        return error;
    }
    
    /// Deserialize actual card
    self.cardModel = [[VSSCardModel alloc] initWithDict:[candidate as:[NSDictionary class]]];
    return nil;
}

@end