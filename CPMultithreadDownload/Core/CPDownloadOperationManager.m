//
//  CPDownloadOperationManager.m
//  CPMultithreadDownload
//
//  Created by guafei on 14/11/18.
//  Copyright (c) 2014年 guafei. All rights reserved.
//

#import "CPDownloadOperationManager.h"

#define DOWNLOAD_URL_0          @""
#define DOWNLOAD_URL_1          @""
#define DOWNLOAD_URL_2          @""

@interface CPDownloadOperationManager()

@property (nonatomic,strong) NSOperationQueue *downloadQueue;

- (void)startDownload;

@end


@implementation CPDownloadOperationManager

- (void)startDownload
{
    NSURL *url_0 = [NSURL URLWithString:DOWNLOAD_URL_0];
    NSURLRequest *request_0 = [NSURLRequest requestWithURL:url_0];
    NSURL *url_1 = [NSURL URLWithString:DOWNLOAD_URL_0];
    NSURLRequest *request_1 = [NSURLRequest requestWithURL:url_1];
    NSURL *url_2 = [NSURL URLWithString:DOWNLOAD_URL_0];
    NSURLRequest *request_2 = [NSURLRequest requestWithURL:url_2];
    
    CPOperation *downloadOperation0 = [[CPOperation alloc] initWithRequest:request_0];
    CPOperation *downloadOperation1 = [[CPOperation alloc] initWithRequest:request_1];
    CPOperation *downloadOperation2 = [[CPOperation alloc] initWithRequest:request_2];
    
    [self.downloadQueue addOperation:downloadOperation0];
    [self.downloadQueue addOperation:downloadOperation1];
    [self.downloadQueue addOperation:downloadOperation2];
}

@end
