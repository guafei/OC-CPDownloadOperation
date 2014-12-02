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
#define DOWNLOAD_URL_0          @"http://127.0.0.1:8888/4.3M.zip"
#define DOWNLOAD_URL_1          @"http://127.0.0.1:8888/7.3M.zip"
#define DOWNLOAD_URL_2          @"http://127.0.0.1:8888/12M.zip"


@interface CPDownloadViewController ()

@property (nonatomic, strong) NSMutableArray             *downloadUrls;
@property (nonatomic, strong) NSMutableDictionary        *progressBarDic;
@property (nonatomic, strong) NSMutableDictionary        *progressValueDic;
@property (nonatomic, strong) NSMutableDictionary        *operationDic;
@property (nonatomic, strong) CPDownloadOperationManager *operationManager;

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
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)__init
{
    self.view.backgroundColor = [UIColor whiteColor];
    self.downloadUrls = [NSMutableArray arrayWithCapacity:DOWNLOADURL_CAPACITY];
    [self.downloadUrls addObject:DOWNLOAD_URL_0];
    [self.downloadUrls addObject:DOWNLOAD_URL_1];
    [self.downloadUrls addObject:DOWNLOAD_URL_2];
    
    self.operationManager = [[CPDownloadOperationManager alloc] initOperationManagerWithUrlArray:self.downloadUrls];
    [_operationManager startDownloadAll];
    
    [self initProgressViews];
}

- (void)initProgressViews
{
    UIScrollView *scrollView = [[UIScrollView alloc] initWithFrame:self.view.bounds];
    self.progressBarDic = [[NSMutableDictionary alloc] initWithCapacity:DOWNLOADURL_CAPACITY];
    self.progressValueDic = [[NSMutableDictionary alloc] initWithCapacity:DOWNLOADURL_CAPACITY];
    self.operationDic = [[NSMutableDictionary alloc] initWithCapacity:DOWNLOADURL_CAPACITY];
    CGRect bounds = [[UIScreen mainScreen] bounds];
    float height = 100;
    float width = bounds.size.width;
    for (int i = 0; i < [self.downloadUrls count]; i++)
    {
        //download item include UIProgressView progressValue button
        UIView *downItem = [[UIView alloc] initWithFrame:CGRectMake(0, height * i, width, height)];
        
        //UIProgressView
        UIProgressView *progressBar = [[UIProgressView alloc] initWithFrame:CGRectMake(20, 40, 200, 20)];
        [self.progressBarDic setValue:progressBar forKey:[self.downloadUrls objectAtIndex:i]];
        progressBar.progressTintColor=[UIColor redColor];
        [downItem addSubview:progressBar];
        
        //progressValue
        UILabel *progressValue = [[UILabel alloc] initWithFrame:CGRectMake(20, 60, 200, 20)];
        progressValue.text = @"progress:";
        [self.progressValueDic setValue:progressValue forKey:[self.downloadUrls objectAtIndex:i]];
        [downItem addSubview:progressValue];
        
        //button for stop or start download resource
        UIButton *button = [[UIButton alloc] initWithFrame:CGRectMake(20 + 200 + 20, 30, 60, 40)];
        [button addTarget:self action:@selector(buttonClicked:) forControlEvents:UIControlEventTouchUpInside];
        [button setTitle:@"start" forState:UIControlStateNormal];
        button.backgroundColor = [UIColor grayColor];
        button.tag = i;
        [self.operationDic setValue:[self.downloadUrls objectAtIndex:i] forKey:[NSString stringWithFormat:@"%ld",(long)button.tag]];
        [downItem addSubview:button];
        
        [scrollView addSubview:downItem];
    }
    
    CGSize size = CGSizeMake(bounds.size.width, height);
    scrollView.contentSize = size;
    [self.view addSubview:scrollView];
}

- (IBAction)buttonClicked:(id)sender
{
    UIButton *button  = (id)sender;
    NSString *url = [self.operationDic objectForKey:[NSString stringWithFormat:@"%ld",(long)button.tag]];
    if([button.currentTitle isEqualToString:@"start"])
    {
        [self.operationManager stopDownloadWithUrl:url];
        [button setTitle:@"stop" forState:UIControlStateNormal];
    }else
    {
        [self.operationManager startDownloadWithUrl:url];
        [button setTitle:@"start" forState:UIControlStateNormal];
    }
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
