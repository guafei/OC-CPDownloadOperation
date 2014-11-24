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

static NSString * const CPOperationLockName = @"CPOperationLock";
NSString * const CPOperationDidStartNotification = @"CPOperationDidStartNotification";
NSString * const CPOperationDidFinishNotification = @"CPOperationDidFinishNotification";

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


#pragma mark -
#pragma mark - threading behaviour

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

#pragma mark -
#pragma mark - request behaviour

- (instancetype)initWithRequest:(NSURLRequest *)urlRequest
{
    self = [super init];
    if (!self) {
        return nil;
    }
    
    self.lock = [[NSRecursiveLock alloc] init];
    self.lock.name = CPOperationLockName;
    self.request = urlRequest;
    self.state = CPOperationReadyState;
    self.runLoopModes = [NSSet setWithObject:NSRunLoopCommonModes];
    
    return  self;
}

#pragma mark -
#pragma mark - operation override

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
            self.downlSession = [NSURLSession sessionWithConfiguration:configuration delegate:self delegateQueue:[NSOperationQueue currentQueue]];
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
#pragma mark - NSURLSessionDownloadDelegate

/* Sent when a download task that has completed a download.  The delegate should
 * copy or move the file at the given location to a new location as it will be
 * removed when the delegate message returns. URLSession:task:didCompleteWithError: will
 * still be called.
 */

- (void)URLSession:(NSURLSession *)session downloadTask:(NSURLSessionDownloadTask *)downloadTask
didFinishDownloadingToURL:(NSURL *)location
{
    
}

/* Sent periodically to notify the delegate of download progress. */

- (void)URLSession:(NSURLSession *)session downloadTask:(NSURLSessionDownloadTask *)downloadTask
      didWriteData:(int64_t)bytesWritten
 totalBytesWritten:(int64_t)totalBytesWritten
totalBytesExpectedToWrite:(int64_t)totalBytesExpectedToWrite
{
    
}

/* Sent when a download has been resumed. If a download failed with an
 * error, the -userInfo dictionary of the error will contain an
 * NSURLSessionDownloadTaskResumeData key, whose value is the resume
 * data.
 */

- (void)URLSession:(NSURLSession *)session downloadTask:(NSURLSessionDownloadTask *)downloadTask
 didResumeAtOffset:(int64_t)fileOffset
expectedTotalBytes:(int64_t)expectedTotalBytes
{
    
}

#pragma mark -
#pragma mark - NSURLSessionDelegate

/* The last message a session receives.  A session will only become
 * invalid because of a systemic error or when it has been
 * explicitly invalidated, in which case the error parameter will be nil.
 */

- (void)URLSession:(NSURLSession *)session didBecomeInvalidWithError:(NSError *)error
{
    
}

/* If implemented, when a connection level authentication challenge
 * has occurred, this delegate will be given the opportunity to
 * provide authentication credentials to the underlying
 * connection. Some types of authentication will apply to more than
 * one request on a given connection to a server (SSL Server Trust
 * challenges).  If this delegate message is not implemented, the
 * behavior will be to use the default handling, which may involve user
 * interaction.
 */

- (void)URLSession:(NSURLSession *)session didReceiveChallenge:(NSURLAuthenticationChallenge *)challenge
 completionHandler:(void (^)(NSURLSessionAuthChallengeDisposition disposition, NSURLCredential *credential))completionHandler
{

}

/* If an application has received an
 * -application:handleEventsForBackgroundURLSession:completionHandler:
 * message, the session delegate will receive this message to indicate
 * that all messages previously enqueued for this session have been
 * delivered.  At this time it is safe to invoke the previously stored
 * completion handler, or to begin any internal updates that will
 * result in invoking the completion handler.
 */

- (void)URLSessionDidFinishEventsForBackgroundURLSession:(NSURLSession *)session NS_AVAILABLE_IOS(7_0)
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
