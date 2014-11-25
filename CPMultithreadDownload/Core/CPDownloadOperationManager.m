//
//  CPDownloadOperationManager.m
//  CPMultithreadDownload
//
//  Created by guafei on 14/11/18.
//  Copyright (c) 2014年 guafei. All rights reserved.
//

#import "CPDownloadOperationManager.h"

@interface CPDownloadOperationManager()

@property (nonatomic, strong) NSOperationQueue *downloadQueue;
@property (nonatomic, strong) NSMutableArray   *downloadUrls;

- (void)startDownload;

@end


@implementation CPDownloadOperationManager


- (instancetype)initOperationManagerWithUrlArray:(NSMutableArray *)downloadUrls
{
    self = [super init];
    if(!self)
    {
        return nil;
    }
    
    self.downloadUrls = downloadUrls;
    [self startDownload];
    return self;
}

- (void)startDownload
{
    for (int i = 0; i < [self.downloadUrls count]; i++)
    {
        NSString *url = [self.downloadUrls objectAtIndex:i];
        NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:url]];
        CPOperation *downloadOperation = [[CPOperation alloc] initWithRequest:request];
        [self.downloadQueue addOperation:downloadOperation];
    }
}



@end
