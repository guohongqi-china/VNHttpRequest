//
//  VNOperationProtocol.h
//  CER_IKE_01
//
//  Created by guohq on 2019/8/6.
//  Copyright © 2019 saicmotor. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@protocol VNOperationAdapter <NSObject>

@required

- (nullable instancetype)initOperationWithTask:(void (^)(void))taskBlock;

- (void)cancel;

@end

NS_ASSUME_NONNULL_END
