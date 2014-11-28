//
//  CPDownloadOperationManager.h
//  CPMultithreadDownload
//
//  Created by guafei on 14/11/18.
//  Copyright (c) 2014年 guafei. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "CPOperation.h"

@interface CPDownloadOperationManager : NSObject

- (instancetype)initOperationManagerWithUrlArray:(NSMutableArray *)downloadUrls;

- (void)startDownloadAll;

- (void)startDownloadWithUrl:(NSString *) url;

- (void)stopDownloadWithUrl:(NSString *) url;

@end
