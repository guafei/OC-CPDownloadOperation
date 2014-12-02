//
//  CPDownloadOperationManager.m
//  CPMultithreadDownload
//
//  Created by guafei on 14/11/18.
//  Copyright (c) 2014年 guafei. All rights reserved.
//

#import "CPDownloadOperationManager.h"

@interface CPDownloadOperationManager()

@property (nonatomic, strong) NSOperationQueue      *downloadQueue;
@property (nonatomic, strong) NSMutableArray        *downloadUrls;
@property (nonatomic, strong) NSMutableDictionary   *mappingOperationDic;

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
    self.downloadQueue = [[NSOperationQueue alloc] init];
    [self.downloadQueue setMaxConcurrentOperationCount:5];
    self.mappingOperationDic = [[NSMutableDictionary alloc] initWithCapacity:[downloadUrls count]];
    return self;
}

- (void)startDownloadAll
{
    for (int i = 0; i < [self.downloadUrls count]; i++)
    {
        NSString *url = [self.downloadUrls objectAtIndex:i];
        NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:url]];
        CPOperation *downloadOperation = [[CPOperation alloc] initWithRequest:request];
        [self.mappingOperationDic setValue:[NSString stringWithFormat:@"%d",downloadOperation.oid] forKey:url];
        [self.downloadQueue addOperation:downloadOperation];
    }
}

- (void)startDownloadWithUrl:(NSString *) url
{
    id operationId = [self.mappingOperationDic objectForKey:url];
    NSArray *operations = [self.downloadQueue operations];
    for (int i = 0; i < [operations count]; i++)
    {
        CPOperation *current = [operations objectAtIndex:i];
        if (current.oid == (NSInteger)operationId)
        {
            [current start];
        }
    }
}

- (void)stopDownloadWithUrl:(NSString *) url
{
    id operationId = [self.mappingOperationDic objectForKey:url];
    NSArray *operations = [self.downloadQueue operations];
    for (int i = 0; i < [operations count]; i++)
    {
        CPOperation *current = [operations objectAtIndex:i];
        if (current.oid == (NSInteger)operationId)
        {
            [current cancel];
        }
    }
}

@end
