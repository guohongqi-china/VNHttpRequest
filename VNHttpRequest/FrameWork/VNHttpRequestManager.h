//
//  Created by guohq on 2017/6/27.
//  Copyright © 2017年 guohq. All rights reserved.
//

#import <Foundation/Foundation.h>
@class ServerResponseInfo;

// 请求方式类型枚举
typedef NS_ENUM(NSInteger,RequestMethod){
    RequestMethod_Get = 100,
    RequestMethod_Post,
    RequestMethod_Put,
    RequestMethod_Delete,
    RequestMethod_Patch,
    RequestMethod_HEAD,
    
};

// 请求方式类型枚举
typedef NS_ENUM(NSInteger,BodyType){
    BodyType_JSON = 1000,
    BodyType_FORM,
};

// 请求类型枚举
typedef NS_ENUM(NSInteger,RequestType){
    RequestType_UPLOAD = 10000, //上传文件
    RequestType_REQUEST    //交互
};

// 文件类型
typedef NS_ENUM(NSInteger,FileType){
    FileType_Video = 100000, //上传视频、音频
    FileType_Image    //上传图片
};

//  请求成功回调
typedef void(^resultBlock)(ServerResponseInfo * _Nullable serverInfo);


/**
 * 注意:如有特殊请求头要求请在 .m文件 requestSerializerSetting 方法里面设置。
 */

@interface VNHttpRequestManager : NSObject


/**
 JSON 参数
 
 @param requestMethod 请求类型(枚举值)
 @param params 请求参数
 @param pathUrl 请求链接
 @param result 数据回调
 */
+(void)sendJSONRequestWithMethod:(RequestMethod )requestMethod
                         pathUrl:(NSString *__nonnull)pathUrl
                          params:(NSDictionary *_Nullable)params
                      complement:(resultBlock __nonnull)result;

/**
 JSON 加密 参数
 
 @param requestMethod 请求类型(枚举值)
 @param requestData 加密之后的参数数据
 @param pathUrl 请求链接
 @param result 数据回调
 */
+(void)sendJSONRequestWithMethod:(RequestMethod )requestMethod
                         pathUrl:(NSString *__nonnull)pathUrl
                     requestData:(NSData *_Nullable)requestData
                      complement:(resultBlock __nonnull)result;

/**
 FormData 参数类型
 
 @param requestMethod 请求类型(枚举值)
 @param params 请求参数
 @param pathUrl 请求链接
 @param result 数据回调
 */
+(void)sendFORMRequestWithMethod:(RequestMethod )requestMethod
                         pathUrl:(NSString *__nonnull)pathUrl
                          params:(NSDictionary *_Nullable)params
                      complement:(resultBlock __nonnull)result;

/**
 批次上传文件
 
 @param fileArray 文件路径数组 注意：fileArray 里面的文件类型要保持一致
 @param bodDic 请求参数
 @param path 请求链接
 @param result 数据回调
 @param fileType 上传文件的类型   图片 or  视/音频
 */
+ (void)uploadFileWithPath:(NSString *__nonnull)path
                  filePath:(NSArray *__nonnull)fileArray
                     parms:(NSDictionary *_Nullable)bodDic
                  fileType:(FileType)fileType
                    result:(resultBlock __nonnull)result;

/**
 文件下载
 
 @param pathUrl 下载路径
 @param filePath 下载路径 可传 null
 @param complement 数据回调
 */
+ (NSURLSessionDownloadTask *_Nullable)downLoadRequest:(NSString *__nonnull)pathUrl
                                              filePath:(NSString *_Nullable)filePath
                                          downProgress:(void (^_Nullable)(double progress))downProgress
                                            complement:(void (^_Nullable)(NSURLResponse * _Nonnull response, NSURL * _Nullable filePath, NSError * _Nullable error))complement;

/**
 请求管理者特殊要求头部设置(未作特殊要求，不用调用次函数，一般全局只需调用一次)
 
 @param headerFields 下载路径
 
 */
+ (void)requestHeaderWidth:(NSDictionary *_Nullable)headerFields;

/**
 一般请求头全局只需设置一次，不要多次设置，如果需要多次设置请求头请设置为NO;
 
 @param result 是否需要删除请求头，不删除就会多次设置，浪费时间
 
 */
//+ (void)deleteHeaderSeting:(BOOL)result;


/**
 开始下载
 @param downloadTask 下载管理者
 */
+ (void)startResume:(NSURLSessionDownloadTask *_Nullable)downloadTask;

/**
 下载暂停
 @param downloadTask 下载管理者
 */
+ (void)suspend:(NSURLSessionDownloadTask *_Nullable)downloadTask;

/**
 取消请求
 */
+ (void)cancleRequestWork;

/**
 网络状态监听
 */
+ (void)netWorkReachability:(void(^_Nullable)(NSString * _Nullable))currentStatus;






@end



// 错误信息 详情
@interface ServerResponseInfo : NSObject

@property (nonatomic,getter=isSuccess) BOOL responeStatus;           //响应是否成功

@property (nonatomic, strong) id _Nullable response;                           //成功响应数据
@property (nonatomic, strong) id _Nullable errorData;
@property (nonatomic, assign) NSInteger httpCode;                    // http 响应码
@property (nonatomic, copy) NSString * _Nullable errorMessage;                  // 响应提示
@property (nonatomic, copy) NSString * _Nullable httpMessage;                   // http 响应提示

@property (nonatomic, strong) NSDictionary * _Nullable responseHeader;          // 响应header


@end











