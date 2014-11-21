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

static NSString * const kAFNetworkingLockName = @"com.alamofire.networking.operation.lock";
NSString * const AFNetworkingOperationDidStartNotification = @"com.alamofire.networking.operation.start";

typedef void (^CPOperationDownloadProgressBlock)(NSUInteger bytes, long long totalBytes, long long totalBytesExpected);

@interface CPOperation()

@property (nonatomic, strong) NSSet *runLoopModes;
@property (nonatomic, strong) NSURLRequest *request;
@property (nonatomic, assign) CPOperationState state;
@property (nonatomic, strong) NSRecursiveLock *lock;
@property (nonatomic, strong) NSError *error;
@property (nonatomic, strong) NSURLSession *downlSession;
@property (nonatomic, strong) NSURLSessionDownloadTask *downloadTask;

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
    
    self.lock = [[NSRecursiveLock alloc] init];
    self.lock.name = CPDownloadLockName;
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

- (BOOL)isAsynchronous {
    return YES;
}

- (void)start
{
    [self.lock lock];
    if ([self isCancelled]) {
        [self performSelector:@selector(cancelConnection) onThread:[[self class] downloadThread] withObject:nil waitUntilDone:NO modes:[self.runLoopModes allObjects]];
    } else if ([self isReady]) {
        self.state = CPOperationExecutingState;
        
        [self performSelector:@selector(operationDidStart) onThread:[[self class] downloadThread] withObject:nil waitUntilDone:NO modes:[self.runLoopModes allObjects]];
    }
    [self.lock unlock];
    
    
}

- (void)cancel
{
    [self.lock lock];
    if (![self isFinished] && ![self isCancelled]) {
        [super cancel];
        
        if ([self isExecuting]) {
            [self performSelector:@selector(cancelConnection) onThread:[[self class] downloadThread] withObject:nil waitUntilDone:NO modes:[self.runLoopModes allObjects]];
        }
    }
    [self.lock unlock];
}

- (void)operationDidStart
{
    [self.lock lock];
    if (![self isCancelled]) {
        static dispatch_once_t onceToken;
        dispatch_once(&onceToken, ^{
            NSURLSessionConfiguration *configuration = [NSURLSessionConfiguration backgroundSessionConfigurationWithIdentifier:@"CPOperationSession"];
            //TODO (NSURLSession *)sessionWithConfiguration:(NSURLSessionConfiguration *)configuration delegate:(id <NSURLSessionDelegate>)delegate delegateQueue:(NSOperationQueue *)queue;
            self.downlSession = [NSURLSession sessionWithConfiguration:configuration];
            self.downloadTask = [self.downlSession downloadTaskWithRequest:self.request];
            [_downloadTask resume];
        });
        
    }
    [self.lock unlock];
    
}

- (void)cancelConnection
{
    NSDictionary *userInfo = nil;
    if ([self.request URL]) {
        userInfo = [NSDictionary dictionaryWithObject:[self.request URL] forKey:NSURLErrorFailingURLErrorKey];
    }
    NSError *error = [NSError errorWithDomain:NSURLErrorDomain code:NSURLErrorCancelled userInfo:userInfo];
    
    if (![self isFinished]) {
        if (self.downlSession) {
            [self.downloadTask cancel];
            [self performSelector:@selector(session:didFailWithError:) withObject:self.downlSession withObject:error];
        }
    }
}

- (void)session:(NSURLSession *)session didFailWithError:(NSError *)error
{
    self.error = error;
}

#pragma mark -
#pragma mark - NSURLSessionDelegate and init




/*********************************
 * better to use start() function 
 * run a thread
 *********************************/
//- (void)main
//{
//    
//}


@end
