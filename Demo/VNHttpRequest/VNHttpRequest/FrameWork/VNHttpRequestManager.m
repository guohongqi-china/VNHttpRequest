//
//  VNHttpRequestManager.m
//  声未识别
//
//  Created by guohq on 2018/6/27.
//  Copyright © 2018年 guohq. All rights reserved.
//

#ifndef dispatch_main_async_safe
#define dispatch_main_async_safe(block)\
if (dispatch_queue_get_label(DISPATCH_CURRENT_QUEUE_LABEL) == dispatch_queue_get_label(dispatch_get_main_queue())) {\
block();\
} else {\
dispatch_async(dispatch_get_main_queue(), block);\
}
#endif

#import "VNHttpRequestManager.h"
#import "AFNetworking.h"
#import "VNRequestOperation.h"

static NSMutableDictionary *headerDic;
//setting request header then delete headerDic , default YES,
static BOOL         setedDelete = NO;

@interface AFHttpClientManager : AFHTTPSessionManager

@property (nonatomic, strong) NSURLSessionDataTask *task;
@property (strong, nonatomic, nonnull) NSOperationQueue *requestQueue;


+(AFHttpClientManager *)sharedClient;

@end

@implementation AFHttpClientManager

static AFHttpClientManager *client = nil;
/**
 * 单例
 */
+(AFHttpClientManager *)sharedClient{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        client = [AFHttpClientManager manager];
        
        //Https setting
        client.securityPolicy.allowInvalidCertificates = YES;
        client.securityPolicy     = [AFSecurityPolicy defaultPolicy];
        
        client.responseSerializer = [AFHTTPResponseSerializer serializer];
        
        client.requestQueue       = [[NSOperationQueue alloc]init];
        client.requestQueue.name  = @"com.vn.requetQueue";
        // 默认最大并发数为6
        client.requestQueue.maxConcurrentOperationCount    =  6;
        
        //response data type
        client.responseSerializer.acceptableContentTypes = [NSSet setWithObjects:@"application/json", @"text/json", @"text/html", @"text/javascript",@"text/plain",@"image/gif",@"image/jpeg", nil];
        
    });
    
    return client;
}


// 不同请求头部设置
+ (void)requestSerializerSetting:(AFHTTPRequestSerializer *)requestSerializer{
    
    //time out 超时时间
    [requestSerializer willChangeValueForKey:@"timeoutInterval"];
    requestSerializer.timeoutInterval = 20.f;
    [requestSerializer didChangeValueForKey:@"timeoutInterval"];
    @synchronized (client.requestSerializer) {
        if (headerDic.allKeys.count) {
            for (NSString *key in headerDic) {
                [client.requestSerializer setValue:headerDic[key] forHTTPHeaderField:key];
            }
        }
    }
    
}

+ (NSMutableURLRequest *)requestData:(NSData *)data with:(NSString *)url paramType:(BodyType)type{
    NSMutableURLRequest *request ;
    
    if (type == BodyType_JSON) {
        request = [[AFJSONRequestSerializer serializer] requestWithMethod:@"POST" URLString:url parameters:nil error:nil];
    }else{
        request = [[AFHTTPRequestSerializer serializer] requestWithMethod:@"POST" URLString:url parameters:nil error:nil];
    }
    
    // 超时设置
    [request willChangeValueForKey:@"timeoutInterval"];
    request.timeoutInterval= 30.0f;
    [request didChangeValueForKey:@"timeoutInterval"];
    
    [request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    
    @synchronized (client.requestSerializer) {
        if (headerDic.allKeys.count) {
            for (NSString *key in headerDic) {
                [client.requestSerializer setValue:headerDic[key] forHTTPHeaderField:key];
            }
        }
    }
    
    // 设置body
    [request setHTTPBody:data];
    
    return request;
}


@end



@implementation VNHttpRequestManager

//JSON 参数类型
+(void)sendJSONRequestWithMethod:(RequestMethod )requestMethod
                         pathUrl:(NSString *__nonnull)pathUrl
                          params:(NSDictionary *_Nullable)params
                      complement:(resultBlock __nonnull)result{
    
    AFHttpClientManager *client = [AFHttpClientManager sharedClient];
    // json格式 请求参数
    client.requestSerializer = [AFJSONRequestSerializer serializer];
    [client.requestSerializer setValue:@"application/json;charset=utf-8" forHTTPHeaderField:@"Content-Type"];
    // 请求头设置
    [AFHttpClientManager  requestSerializerSetting:client.requestSerializer];
    
    [VNHttpRequestManager requestWidth:requestMethod requestManager:client pathUrl:pathUrl params:params requestCount:0 complement:result];
    
    
}

//JSON 参数加密类型
+(void)sendJSONRequestWithMethod:(RequestMethod )requestMethod
                         pathUrl:(NSString *__nonnull)pathUrl
                     requestData:(NSData *_Nullable)requestData
                      complement:(resultBlock __nonnull)result{
    
    AFHttpClientManager *client = [AFHttpClientManager sharedClient];
    
    //对url 进行汉字转码 iOS 9.0
    NSString *serverUrl = [pathUrl stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLQueryAllowedCharacterSet]];
    NSMutableURLRequest *request = [AFHttpClientManager requestData:requestData with:serverUrl paramType:BodyType_JSON];
    
    // 请求头设置
    [AFHttpClientManager requestSerializerSetting:client.requestSerializer];
    
    __block NSURLSessionDataTask *dataTask = nil;
    
    dataTask =  [client dataTaskWithRequest:[request copy] uploadProgress:^(NSProgress * _Nonnull uploadProgress) {
        
    } downloadProgress:^(NSProgress * _Nonnull downloadProgress) {
        
    } completionHandler:^(NSURLResponse * _Nonnull response, id  _Nullable responseObject, NSError * _Nullable error) {
        if (error) {
#ifdef DEBUG
            NSLog(@"URL Value=%@",serverUrl);
#endif
            [VNHttpRequestManager handleFailTask:dataTask error:error complement:result];
        }else{
            // 服务器响应 log 数据
            
#ifdef DEBUG
            NSLog(@"URL Value=%@",serverUrl);
#endif
            [VNHttpRequestManager handleSuccessTask:dataTask responseObject:responseObject complement:result];
        }
    }];
    
}


//FORM 参数类型
+(void)sendFORMRequestWithMethod:(RequestMethod )requestMethod
                         pathUrl:(NSString *__nonnull)pathUrl
                          params:(NSDictionary *_Nullable)params
                      complement:(resultBlock __nonnull)result{
    
    AFHttpClientManager *client = [AFHttpClientManager sharedClient];
    // formData格式 请求参数
    client.requestSerializer = [AFHTTPRequestSerializer serializer];
    [client.requestSerializer setValue:@"application/x-www-form-urlencoded" forHTTPHeaderField:@"Content-Type"];
    
    // 请求头设置
    [AFHttpClientManager  requestSerializerSetting:client.requestSerializer];
    [VNHttpRequestManager requestWidth:requestMethod requestManager:client pathUrl:pathUrl params:params requestCount:0 complement:result];
    
}

//上传文件
+ (void)uploadFileWithPath:(NSString *__nonnull)path
                  filePath:(NSArray *__nonnull)fileArray
                     parms:(NSDictionary *_Nullable)bodDic
                  fileType:(FileType)fileType
                    result:(resultBlock __nonnull)result{
    
    AFHttpClientManager *client = [AFHttpClientManager sharedClient];
    // json格式 请求参数
    client.requestSerializer = [AFJSONRequestSerializer serializer];
    [client.requestSerializer setValue:@"application/json;charset=utf-8;" forHTTPHeaderField:@"Content-Type"];
    // 请求头设置
    [AFHttpClientManager  requestSerializerSetting:client.requestSerializer];
    
    
    [VNHttpRequestManager startRequestByMethod:RequestMethod_Post
                                requestManager:client
                                   requestPath:path
                                    bodyParams:bodDic
                                      fileType:fileType
                                   requestType:RequestType_UPLOAD
                                     fileArray:fileArray
                                    complement:result];
    
}

+ (NSURLSessionDownloadTask *)downLoadRequest:(NSString *__nonnull)pathUrl
                                     filePath:(NSString *_Nullable)filePath
                                 downProgress:(void (^)(double progress))downProgress
                                   complement:(void (^_Nullable)(NSURLResponse * _Nonnull response, NSURL * _Nullable filePath, NSError * _Nullable error))complement{
    
    AFHttpClientManager *client = [AFHttpClientManager sharedClient];
    // json格式 请求参数
    client.requestSerializer = [AFJSONRequestSerializer serializer];
    [client.requestSerializer setValue:@"application/json;charset=utf-8" forHTTPHeaderField:@"Content-Type"];
    
    // 请求头设置
    [AFHttpClientManager  requestSerializerSetting:client.requestSerializer];
    
    //请求
    NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:pathUrl]];
    
    
    NSURLSessionDownloadTask *downTask = [client downloadTaskWithRequest:request progress:^(NSProgress * _Nonnull downloadProgress) {
        downProgress(downloadProgress.completedUnitCount * 0.1 / (downloadProgress.totalUnitCount * 0.1));
        
    } destination:^NSURL * _Nonnull(NSURL * _Nonnull targetPath, NSURLResponse * _Nonnull response) {
        if (filePath) {
            return [NSURL fileURLWithPath:filePath];;
        }
        NSString *cachesPath = [NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) lastObject];
        NSString *path = [cachesPath stringByAppendingPathComponent:response.suggestedFilename];
        return [NSURL fileURLWithPath:path];
    } completionHandler:complement];
    
    return downTask;
}

// 开始下载
+ (void)startResume:(NSURLSessionDownloadTask *_Nullable)downloadTask{
    [downloadTask resume];
}

// 下载暂停
+ (void)suspend:(NSURLSessionDownloadTask *_Nullable)downloadTask{
    [downloadTask suspend];
}


// 网络请求取消
+ (void)cancleRequestWork{
    AFHttpClientManager *client = [AFHttpClientManager sharedClient];
    [client.task cancel];
}

+ (void)requestHeaderWidth:(NSDictionary *_Nullable)headerFields{
    headerDic = [headerFields mutableCopy];
}

+ (void)deleteHeaderSeting:(BOOL)result{
    //    setedDelete = result;
}

#pragma mark------------------------------------  私有方法   --------------------------------------------------

// 响应重定向再次发起请求
+ (void)requestWidth:(RequestMethod)method
      requestManager:(AFHttpClientManager *)manager
             pathUrl:(NSString *)pathUrl
              params:(NSDictionary *)params
        requestCount:(NSInteger)requestCount
          complement:(resultBlock)result{
    __block NSInteger count = requestCount;
    [VNHttpRequestManager startRequestByMethod:method
                                requestManager:manager
                                   requestPath:pathUrl
                                    bodyParams:params
                                      fileType:0
                                   requestType:RequestType_REQUEST
                                     fileArray:nil
                                    complement:^(ServerResponseInfo *serverInfo) {
                                        //网络请求重定向
                                        if (serverInfo.httpCode == 302 && count < 2) {
                                            count ++;
                                            [VNHttpRequestManager requestWidth:method requestManager:manager pathUrl:pathUrl params:params requestCount:count complement:result];
                                            
                                        }else{
                                            dispatch_main_async_safe(^{
                                                result(serverInfo);
                                            })
                                        }
                                        
                                    }];
    
}

/**
 服务器响应数据解析
 
 @param requestMethod 请求类型(枚举值)
 @param params 请求参数
 @param pathUrl 请求链接
 @param result 数据回调
 @param requestType 数据交互/上传文件
 @param fileArray 文件路径数组
 @param fileType 上传文件的类型（视频、图片）
 */

+ (void)startRequestByMethod:(RequestMethod)requestMethod
              requestManager:(AFHttpClientManager *)manager
                 requestPath:(NSString *)pathUrl
                  bodyParams:(NSDictionary *)params
                    fileType:(FileType)fileType
                 requestType:(RequestType)requestType
                   fileArray:(NSArray *)fileArray
                  complement:(resultBlock)result{
    
    //对url 进行汉字转码 iOS 9.0
    NSString *serverUrl = [pathUrl stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLQueryAllowedCharacterSet]];
    
    void (^successBlock)(NSURLSessionDataTask *,id) = ^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        
        // 服务器响应 log 数据
#ifdef DEBUG
        NSLog(@"URL Value=%@",serverUrl);
        NSLog(@"Parms Value=%@",params);
#endif
        VNRequestOperation<VNOperationAdapter> *requestOperation = [[VNRequestOperation alloc]initOperationWithTask:^{
            [VNHttpRequestManager handleSuccessTask:task responseObject:responseObject complement:result];
        }];
        [manager.requestQueue addOperation:requestOperation];
    };
    
    void (^failureBlock)(NSURLSessionDataTask *,NSError *) =^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        
#ifdef DEBUG
        NSLog(@"URL Value=%@",serverUrl);
        NSLog(@"Parms Value=%@",params);
#endif
        VNRequestOperation<VNOperationAdapter> *requestOperation = [[VNRequestOperation alloc]initOperationWithTask:^{
            [VNHttpRequestManager handleFailTask:task error:error complement:result];
        }];
        [manager.requestQueue addOperation:requestOperation];
        
    };
    
    switch (requestType) {
        case RequestType_REQUEST:
        {
            [VNHttpRequestManager startRequestByMethod:requestMethod requestManager:client requestPath:serverUrl bodyParams:params successBlock:successBlock failureBlock:failureBlock];
        }
            break;
        case RequestType_UPLOAD:
        {
            [VNHttpRequestManager uploadFileWithManager:client requestPath:serverUrl bodyParams:params fileArray:fileArray fileType:fileType successBlock:successBlock failureBlock:failureBlock];
        }
            break;
            
        default:
            break;
    }
    
    
}

+ (void)handleSuccessTask:(NSURLSessionDataTask * _Nonnull )task responseObject:(id  _Nullable)responseObject complement:(resultBlock)result{
    NSHTTPURLResponse *response = (NSHTTPURLResponse *)task.response;
    // 获取相应code值
    ServerResponseInfo *infoData = [ServerResponseInfo new];
    infoData.httpCode = response.statusCode;
    infoData.responseHeader = [VNHttpRequestManager josnSerialization:response.allHeaderFields];
    infoData.responeStatus = YES;
    
#ifdef DEBUG
    NSLog(@"ResponseStateCode Value=%ld",(long)infoData.httpCode);
#endif
    
    
    // 服务器数据解析
    [self getObjectFromJSONData:responseObject complement:^(NSError *error, id jsonObject) {
        NSDictionary *allHeaders = response.allHeaderFields;
        NSData *jsonData = [NSJSONSerialization dataWithJSONObject:allHeaders options:NSJSONWritingPrettyPrinted
                                                             error:&error];
        if (jsonObject) {
            //如果接口相应数据放在响应体(body)里面，走这里。
            
            infoData.response = jsonObject;
            infoData.errorData = error;
            
            result(infoData);
        }else{
            //如果接口相应数据放在响应头里面，走这里。
            [self getObjectFromJSONData:jsonData complement:^(NSError *error, id jsonObject) {
                infoData.response = jsonObject;
                infoData.errorData = error;
                result(infoData);
            }];
        }
        
        
    }];
}

+ (void)handleFailTask:(NSURLSessionDataTask * _Nonnull )task error:(NSError * _Nonnull)error complement:(resultBlock)result{
    NSHTTPURLResponse *response = (NSHTTPURLResponse *)task.response;
    
    
    ServerResponseInfo *infoData = [ServerResponseInfo new];
    infoData.httpCode = response.statusCode;
    infoData.responseHeader = [VNHttpRequestManager josnSerialization:response.allHeaderFields];
    infoData.responeStatus = NO;
    
#ifdef DEBUG
    NSLog(@"ResponseStateCode Value=%ld",(long)infoData.httpCode);
    for (id errorInfo in error.userInfo.allKeys) {
        
        id obj = error.userInfo[errorInfo];
        if ([obj isKindOfClass:NSData.class]) {
            NSString *resul1t =[[ NSString alloc] initWithData:error.userInfo[errorInfo] encoding:NSUTF8StringEncoding];
            obj = resul1t;
        }
        NSLog(@"Error %@ : %@",errorInfo, obj);
    }
#endif
    
    [self getErrorInfo:error infoData:infoData];
    infoData.errorData = error;
    
    result(infoData);
}

//发起请求
+ (void)startRequestByMethod:(RequestMethod)requestMethod
              requestManager:(AFHttpClientManager *)manager
                 requestPath:(NSString *)pathUrl
                  bodyParams:(NSDictionary *)params
                successBlock:(void (^)(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject))successBlock
                failureBlock:(void (^)(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error))failureBlock {
    
    // 发起请求
    if (requestMethod == RequestMethod_Get) {
        manager.task = [manager GET:pathUrl parameters:params progress:nil success:successBlock failure:failureBlock];
    }else if (requestMethod == RequestMethod_Post) {
        manager.task = [manager POST:pathUrl parameters:params progress:nil success:successBlock failure:failureBlock];
    }else if (requestMethod == RequestMethod_Put) {
        manager.task = [manager PUT:pathUrl parameters:params success:successBlock failure:failureBlock];
    }else if (requestMethod == RequestMethod_Delete) {
        manager.task = [manager DELETE:pathUrl parameters:params success:successBlock failure:failureBlock];
    }else if (requestMethod == RequestMethod_Patch) {
        manager.task = [manager PATCH:pathUrl parameters:params success:successBlock failure:failureBlock];
    }else if (requestMethod == RequestMethod_HEAD){
        manager.task = [manager HEAD:pathUrl parameters:params success:^(NSURLSessionDataTask * _Nonnull task) {
            successBlock(task,nil);
        } failure:failureBlock];
    }
}



// 文件上传
+ (void)uploadFileWithManager:(AFHttpClientManager *)manager
                  requestPath:(NSString *)pathUrl
                   bodyParams:(NSDictionary *)params
                    fileArray:(NSArray *)fileArray
                     fileType:(FileType)fileType
                 successBlock:(void (^)(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject))successBlock
                 failureBlock:(void (^)(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error))failureBlock{
    
    [manager POST:pathUrl parameters:params constructingBodyWithBlock:^(id<AFMultipartFormData>  _Nonnull formData) {
        
        if (fileType == FileType_Image) {
            [VNHttpRequestManager imgFormdata:formData fileArray:fileArray];
        }else{
            [VNHttpRequestManager vedioFormdata:formData fileArray:fileArray];
        }
        
    } progress:^(NSProgress * _Nonnull uploadProgress) {
        NSLog(@"上传进度:%f",uploadProgress.fractionCompleted);
    } success:successBlock failure:failureBlock];
    
}

//音、视频上传
+ (void)vedioFormdata:(id<AFMultipartFormData>  _Nonnull)formData
            fileArray:(NSArray *)fileArray{
    NSString *type = [[fileArray.firstObject componentsSeparatedByString:@"."] lastObject];
    for (NSString *filePath in fileArray) {
        
        NSDate *date = [NSDate date];
        NSDateFormatter *formormat = [[NSDateFormatter alloc]init];
        [formormat setDateFormat:@"yyyyMMddHHmmss"];
        NSString *dateString = [formormat stringFromDate:date];
        
        NSString *fileName = [NSString  stringWithFormat:@"%@.%@",dateString,type];
        
        [formData appendPartWithFileURL:[NSURL fileURLWithPath:filePath] name:@"file" fileName:fileName mimeType:@"wav/mp4/amr/mp3" error:nil];
        
    }
}
//图片上传处理
+ (void)imgFormdata:(id<AFMultipartFormData>  _Nonnull)formData
          fileArray:(NSArray *)fileArray{
    
    NSString *type = [[fileArray.firstObject componentsSeparatedByString:@"."] lastObject];
    
    for (NSString *imgPath in fileArray) {
        UIImage * image =[UIImage  imageWithContentsOfFile:imgPath];
        NSDate *date = [NSDate date];
        NSDateFormatter *formormat = [[NSDateFormatter alloc]init];
        [formormat setDateFormat:@"yyyyMMddHHmmss"];
        NSString *dateString = [formormat stringFromDate:date];
        
        NSString *fileName = [NSString  stringWithFormat:@"%@.%@",dateString,type];
        NSData *imageData = UIImageJPEGRepresentation(image, 1);
        double scaleNum = (double)300*1024/imageData.length;
        NSLog(@"图片压缩率：%f",scaleNum);
        if(scaleNum <1){
            
            imageData = UIImageJPEGRepresentation(image, scaleNum);
        }else{
            
            imageData = UIImageJPEGRepresentation(image, 0.1);
            
        }
        
        [formData  appendPartWithFileData:imageData name:@"image" fileName:fileName mimeType:@"image/jpg/png/jpeg"];
        
    }
}


// unicode 编码汉化
+(NSString *)replaceUnicode:(NSString*)unicodeStr{
    if (unicodeStr.length == 0) {
        return @"";
    }
    NSString *tempStr1=[unicodeStr stringByReplacingOccurrencesOfString:@"\\u"withString:@"\\U"];
    NSString *tempStr2=[tempStr1 stringByReplacingOccurrencesOfString:@"\""withString:@"\\\""];
    NSString *tempStr3=[[@"\""stringByAppendingString:tempStr2]stringByAppendingString:@"\""];
    NSData *tempData=[tempStr3 dataUsingEncoding:NSUTF8StringEncoding];
    NSString* returnStr = [NSPropertyListSerialization propertyListWithData:tempData options:NSPropertyListImmutable format:NULL error:NULL];
    
    return [returnStr stringByReplacingOccurrencesOfString:@"\\r\\n"withString:@"\n"];
}




// 不正规json 序列化
+ (NSDictionary *)josnSerialization:(NSDictionary *)json{
    if (json) {
        NSData *jsonData = [NSJSONSerialization dataWithJSONObject:json options:NSJSONWritingPrettyPrinted error:nil];
        NSDictionary *content = [NSJSONSerialization JSONObjectWithData:jsonData options:NSJSONReadingMutableContainers error:nil];//转换数据格式
        return content;
    }
    return nil;
}

//get object（NSArray、NSDictionary）from JSON.NSData  json序列化
+ (void)getObjectFromJSONData:(NSData *)data
                   complement:(void(^)(NSError *error, id jsonObject))complement{
    id jsonObject = nil;
    
    if (data.length != 0)
    {
        NSError *error = nil;
        jsonObject = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingAllowFragments error:&error];
        if (!jsonObject)
        {
            NSString *strJSON = [[NSString alloc]initWithData:data encoding:NSUTF8StringEncoding];
            jsonObject = [VNHttpRequestManager replaceUnicode:strJSON];
            
#ifdef DEBUG
            NSLog(@"数据解析错误 -JSONValue failed. Error trace is: %@,\n JSON:%@", error,strJSON);
            NSLog(@"Response Value = %@",data );
#endif
            
            if (!jsonObject || [jsonObject length] == 0) {
                complement(nil,data);
                return;
            }
            
        }
    }
    NSData *jsonData      = [NSJSONSerialization dataWithJSONObject:jsonObject
                                                            options:NSJSONWritingPrettyPrinted
                                                              error:nil];
    NSString *strResponse = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
    
    if ([strResponse containsString:@"\\u"]) {
        strResponse = [VNHttpRequestManager replaceUnicode:strResponse];
    }
    NSLog(@"Response Value = %@",strResponse );
    
    complement(nil,jsonObject);
}

//获取错误code对应状态
+ (void)getErrorInfo:(NSError * _Nonnull )error infoData:(ServerResponseInfo *)infoData{
    
    if (error.code == -1009) {
        infoData.errorMessage = @"无网络连接";
    }else if (error.code == -1001){
        infoData.errorMessage = @"请求超时";
    }else if (error.code == -1003){
        infoData.errorMessage = @"找不到主机";
    }else if (error.code == -1004){
        infoData.errorMessage = @"服务器没有启动";
    }else{
        infoData.errorMessage = @"其他错误";
    }
    
    if (infoData.httpCode == 200) {
        infoData.httpMessage = @"请求成功";
    }else if (infoData.httpCode > 200 && infoData.httpCode < 207){
        infoData.httpMessage = @"请求成功，服务器未响应";
    }else if(infoData.httpCode == 400){
        infoData.httpMessage = @"请求body参数有误";
    }else if(infoData.httpCode == 401){
        infoData.httpMessage = @"未授权,身份验证出问题";
    }else if(infoData.httpCode == 403){
        infoData.httpMessage = @"禁止访问";
    }else if(infoData.httpCode == 404){
        infoData.httpMessage = @"请求路径找不到";
    }else if(infoData.httpCode > 499 && infoData.httpCode < 506){
        infoData.httpMessage = @"服务器错误";
    }else{
        infoData.httpMessage = @"其他错误";
    }
    
    
}


+ (void)netWorkReachability:(void(^)(NSString *))currentStatus{
    AFNetworkReachabilityManager *manager = [AFNetworkReachabilityManager sharedManager];
    [manager startMonitoring];
    [manager setReachabilityStatusChangeBlock:^(AFNetworkReachabilityStatus status) {
        switch (status) {
            case AFNetworkReachabilityStatusUnknown:
            {
                //未知网络
                NSLog(@"未知网络");
                currentStatus(@"未知网络");
            }
                break;
            case AFNetworkReachabilityStatusNotReachable:
            {
                //无法联网
                currentStatus(@"无网络网");
                
            }
                break;
                
            case AFNetworkReachabilityStatusReachableViaWWAN:
            {
                //手机自带网络
                NSLog(@"当前使用的是2g/3g/4g网络");
                currentStatus(@"手机网络");
                
            }
                break;
            case AFNetworkReachabilityStatusReachableViaWiFi:
            {
                //WIFI
                NSLog(@"当前在WIFI网络下");
                currentStatus(@"当前在WIFI网络下");
                
            }
                
        }
    }];
}





@end

@implementation ServerResponseInfo


@end



//    NSURLErrorUnknown = -1,
//    NSURLErrorCancelled = -999,
//    NSURLErrorBadURL = -1000,
//    NSURLErrorTimedOut = -1001,
//    NSURLErrorUnsupportedURL = -1002,
//    NSURLErrorCannotFindHost = -1003,
//    NSURLErrorCannotConnectToHost = -1004,
//    NSURLErrorDataLengthExceedsMaximum = -1103,
//    NSURLErrorNetworkConnectionLost = -1005,
//    NSURLErrorDNSLookupFailed = -1006,
//    NSURLErrorHTTPTooManyRedirects = -1007,
//    NSURLErrorResourceUnavailable = -1008,
//    NSURLErrorNotConnectedToInternet = -1009,
//    NSURLErrorRedirectToNonExistentLocation = -1010,
//    NSURLErrorBadServerResponse = -1011,
//    NSURLErrorUserCancelledAuthentication = -1012,
//    NSURLErrorUserAuthenticationRequired = -1013,
//    NSURLErrorZeroByteResource = -1014,
//    NSURLErrorCannotDecodeRawData = -1015,
//    NSURLErrorCannotDecodeContentData = -1016,
//    NSURLErrorCannotParseResponse = -1017,
//    NSURLErrorInternationalRoamingOff = -1018,
//    NSURLErrorCallIsActive = -1019,
//    NSURLErrorDataNotAllowed = -1020,
//    NSURLErrorRequestBodyStreamExhausted = -1021,
//    NSURLErrorFileDoesNotExist = -1100,
//    NSURLErrorFileIsDirectory = -1101,
//    NSURLErrorNoPermissionsToReadFile = -1102,
//    NSURLErrorSecureConnectionFailed = -1200,
//    NSURLErrorServerCertificateHasBadDate = -1201,
//    NSURLErrorServerCertificateUntrusted = -1202,
//    NSURLErrorServerCertificateHasUnknownRoot = -1203,
//    NSURLErrorServerCertificateNotYetValid = -1204,
//    NSURLErrorClientCertificateRejected = -1205,
//    NSURLErrorClientCertificateRequired = -1206,
//    NSURLErrorCannotLoadFromNetwork = -2000,
//    NSURLErrorCannotCreateFile = -3000,
//    NSURLErrorCannotOpenFile = -3001,
//    NSURLErrorCannotCloseFile = -3002,
//    NSURLErrorCannotWriteToFile = -3003,
//    NSURLErrorCannotRemoveFile = -3004,
//    NSURLErrorCannotMoveFile = -3005,
//    NSURLErrorDownloadDecodingFailedMidStream = -3006,
//    NSURLErrorDownloadDecodingFailedToComplete = -3007
