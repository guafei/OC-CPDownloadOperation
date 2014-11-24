//
//  CPOperation.h
//  CPMultithreadDownload
//
//  Created by guafei on 14/11/18.
//  Copyright (c) 2014年 guafei. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface CPOperation : NSOperation<NSURLSessionDelegate,NSURLSessionDownloadDelegate>

- (instancetype)initWithRequest:(NSURLRequest *)urlRequest;

@end
