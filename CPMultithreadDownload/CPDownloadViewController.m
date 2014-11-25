//
//  CPDownloadViewController.m
//  CPMultithreadDownload
//
//  Created by guafei on 14/11/24.
//  Copyright (c) 2014年 guafei. All rights reserved.
//

#import "CPDownloadViewController.h"
#import "CPDownloadOperationManager.h"

#define DOWNLOADURL_CAPACITY    10
#define DOWNLOAD_URL_0          @""
#define DOWNLOAD_URL_1          @""
#define DOWNLOAD_URL_2          @""


@interface CPDownloadViewController ()

@property (nonatomic, strong) UIProgressView *processBar;
@property (nonatomic, strong) NSMutableArray *downloadUrls;

@end

@implementation CPDownloadViewController

- (instancetype)init
{
    self = [super self];
    if(!self)
    {
        return nil;
    }
    
    [self __init];
    
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    for (int i = 0; i < [self.downloadUrls count]; i++)
    {
        
    }
    
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)__init
{
    self.downloadUrls = [NSMutableArray arrayWithCapacity:DOWNLOADURL_CAPACITY];
    NSURL *url_0 = [NSURL URLWithString:DOWNLOAD_URL_0];
    NSURL *url_1 = [NSURL URLWithString:DOWNLOAD_URL_1];
    NSURL *url_2 = [NSURL URLWithString:DOWNLOAD_URL_2];
    [self.downloadUrls addObject:url_0];
    [self.downloadUrls addObject:url_1];
    [self.downloadUrls addObject:url_2];
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
