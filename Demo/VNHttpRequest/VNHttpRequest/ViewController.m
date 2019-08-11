//
//  ViewController.m
//  VNHttpRequest
//
//  Created by guohq on 2019/8/9.
//  Copyright © 2019 guohq. All rights reserved.
//

#import "ViewController.h"
#import "VNHttpRequestManager.h"

@interface ViewController ()
{
    NSURLSessionDownloadTask *downTask;
}
@property (nonatomic, strong) NSMutableArray *itemArr;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    /**
     设置请求头，全局只需设置一次
        [VNHttpRequestManager requestHeaderWidth:@{@"APP-LOGIN-TOKEN":str,@"Accept":@"application/json",@"Content-Type":@"application/json",@"APP-LANGUAGE-TYPE":@"en-us",@"APP-USER-ID":str1,@"APP-CONTENT-ENCRYPTED":@"0"}];

     */
    
    downTask =  [VNHttpRequestManager downLoadRequest:@"http://dldir1.qq.com/qqfile/QQforMac/QQ_V5.4.0.dmg"  filePath:nil downProgress:^(double progress) {
        [[NSOperationQueue mainQueue] addOperationWithBlock:^{
            NSLog(@"%f",progress);
        }];
    } complement:^(NSURLResponse * _Nonnull response, NSURL * _Nullable filePath, NSError * _Nullable error) {
        
    }];

}

#pragma mark --  开始/继续  下载
- (void)downloadAction{
    [VNHttpRequestManager startResume:downTask];
}

#pragma mark --  暂停
- (void)suapendAction{
    [VNHttpRequestManager suspend:downTask];
}


#pragma mark --  json提参方式，get请求
- (void)jsonGetRequest{
    [VNHttpRequestManager sendJSONRequestWithMethod:RequestMethod_Get pathUrl:@"https://westus.api.cognitive.microsoft.com/spid/v1.0/identificationProfiles" params:nil complement:^(ServerResponseInfo *serverInfo) {
        if (serverInfo.isSuccess) {
            self.itemArr = [serverInfo.response mutableCopy];
        }
    }];
}

#pragma mark --  json提参方式，post请求
- (void)jsonPostRequest{
    [VNHttpRequestManager sendJSONRequestWithMethod:RequestMethod_Post pathUrl:@"https://westus.api.cognitive.microsoft.com/spid/v1.0/identificationProfiles/" params:@{@"locale":@"en-us"} complement:^(ServerResponseInfo *serverInfo) {
        if (serverInfo.isSuccess) {
            
        }
    }];
    
    [VNHttpRequestManager sendFORMRequestWithMethod:RequestMethod_Post pathUrl:@"https://westus.api.cognitive.microsoft.com/spid/v1.0/identificationProfiles/" params:@{@"key":@"value"} complement:^(ServerResponseInfo * _Nullable serverInfo) {
        
    }];
}

#pragma mark --  json提参方式，delete请求
- (void)jsonDeleteRequest{
    NSString *pathStr = [@"https://westus.api.cognitive.microsoft.com/spid/v1.0/identificationProfiles/" stringByAppendingString:self.itemArr.firstObject[@"identificationProfileId"]];
    [VNHttpRequestManager sendJSONRequestWithMethod:RequestMethod_Delete pathUrl:pathStr params:nil complement:^(ServerResponseInfo *serverInfo) {
        if (serverInfo.isSuccess) {
            [self.itemArr removeObjectAtIndex:0];
        }
    }];
}

#pragma mark --  上传文件
- (void)uplodData{
    [VNHttpRequestManager uploadFileWithPath:@"https://westus.api.cognitive.microsoft.com/spid/v1.0/identificationProfiles/28277c34-9512-4b89-97af-3a3683172287/enroll?shortAudio=true" filePath:@[@"/Users/用户/Desktop/xxxx.wav"] parms:nil fileType:FileType_Video result:^(ServerResponseInfo *serverInfo) {
        if (serverInfo.isSuccess) {
            [self.itemArr removeObjectAtIndex:0];
        }
    }];
}


@end
