//
//  CPOperation.m
//  CPMultithreadDownload
//
//  Created by guafei on 14/11/18.
//  Copyright (c) 2014年 guafei. All rights reserved.
//

#import "CPOperation.h"

typedef NS_ENUM(NSInteger, CPOperationState){
    CPOperationPausedState      = -1,
    CPOperationReadyState       = 1,
    CPOperationExecutingState   = 2,
    CPOperationFinishedState    = 3,
};

typedef void (^CPOperationDownloadProgressBlock)(NSUInteger bytes, long long totalBytes, long long totalBytesExpected);

@interface CPOperation()

@property (nonatomic, strong) NSSet *runLoopModes;
@property (nonatomic, strong) NSURLRequest *request;
@property (nonatomic, assign) CPOperationState state;

@end

@implementation CPOperation



#pragma mark threading behaviour

+ (void)runDownloadRequest:(id)__unused object {
    @autoreleasepool {
        [[NSThread currentThread] setName:@"CPDownloadThread"];
        
        // Should keep the runloop from exiting
        CFRunLoopSourceContext context = {0, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL};
        CFRunLoopSourceRef source = CFRunLoopSourceCreate(kCFAllocatorDefault, 0, &context);
        CFRunLoopAddSource(CFRunLoopGetCurrent(), source, kCFRunLoopDefaultMode);
        
        BOOL runAlways = YES; // Introduced to cheat Static Analyzer
        while (runAlways) {
            CFRunLoopRunInMode(kCFRunLoopDefaultMode, 1.0e10, true);
        }
        
        // Should never be called, but anyway
        CFRunLoopRemoveSource(CFRunLoopGetCurrent(), source, kCFRunLoopDefaultMode);
        CFRelease(source);
        
    }
}

+ (NSThread *)downloadThread {
    static NSThread *_downloadThread = nil;
    static dispatch_once_t oncePredicate;
    dispatch_once(&oncePredicate, ^{
        _downloadThread = [[NSThread alloc] initWithTarget:self selector:@selector(runDownloadRequest:) object:nil];
        [_downloadThread start];
    });
    
    return _downloadThread;
}

+ (BOOL)isMultitaskingSupported
{
    BOOL multiTaskingSupported = NO;
    if ([[UIDevice currentDevice] respondsToSelector:@selector(isMultitaskingSupported)]) {
        multiTaskingSupported = [(id)[UIDevice currentDevice] isMultitaskingSupported];
    }
    return multiTaskingSupported;
}

#pragma mark request behaviour

- (instancetype)initWithRequest:(NSURLRequest *)urlRequest
{
    self = [super init];
    if (!self) {
        return nil;
    }
    
    self.request = urlRequest;
    self.state = CPOperationReadyState;
    self.runLoopModes = [NSSet setWithObject:NSRunLoopCommonModes];
    
    return  self;
}


#pragma mark operation override

- (BOOL)isReady {
    return self.state == CPOperationReadyState && [super isReady];
}

- (BOOL)isExecuting {
    return self.state == CPOperationExecutingState;
}

- (BOOL)isFinished {
    return self.state == CPOperationFinishedState;
}

- (BOOL)isConcurrent {
    return YES;
}

- (void)start
{
    //use NSURLSession to download zip
    
}

- (void)cancel
{
    
}



/*********************************
 * better to use start() function 
 * run a thread
 *********************************/
//- (void)main
//{
//    
//}


@end
