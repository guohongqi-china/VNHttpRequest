VNHttpRequest 特点
==============
* AFNetworking  二次封装，对响应数据进一步解析。防止出现二进制数据，对分析问题造成阻碍。
* 对get、post、delete、put、patch、HEAD等方法进一步封装。
* 对请求任务放入到队列中进行管理，最大并发数6.
* 对请求头进一步封装。并且解析响应头数据，后台数据并不都通过body返回。
* 对JSON、FORM-DATA两种请求作区分。
* [简书地址](https://www.jianshu.com/p/385c3afaaaf4)



Installation
==============

### CocoaPods

1. Add `pod 'VNHttpRequest'` to your Podfile.
2. Run `pod install` or `pod update`.
3. Import \<VNHttpRequest/VNHttpRequest.h\>.


Use Case
==============

#### Creating an Request get
```
[VNHttpRequestManager sendJSONRequestWithMethod:RequestMethod_Get pathUrl:@"https://westus.api.cognitive.microsoft.com/spid/v1.0/identificationProfiles" params:nil complement:^(ServerResponseInfo *serverInfo) {
if (serverInfo.isSuccess) {
self.itemArr = [serverInfo.response mutableCopy];
}
}];
```
#### Creating an Request post
```
[VNHttpRequestManager sendJSONRequestWithMethod:RequestMethod_Post pathUrl:@"https://westus.api.cognitive.microsoft.com/spid/v1.0/identificationProfiles/" params:@{@"locale":@"en-us"} complement:^(ServerResponseInfo *serverInfo) {
if (serverInfo.isSuccess) {

}
}];
```
#### Creating an form-data  提参方式

```
[VNHttpRequestManager sendFORMRequestWithMethod:RequestMethod_Post pathUrl:@"https://westus.api.cognitive.microsoft.com/spid/v1.0/identificationProfiles/" params:@{@"key":@"value"} complement:^(ServerResponseInfo * _Nullable serverInfo) {

}];
```
#### Creating an upload data
```
[VNHttpRequestManager uploadFileWithPath:@"https://westus.api.cognitive.microsoft.com/spid/v1.0/identificationProfiles/28277c34-9512-4b89-97af-3a3683172287/enroll?shortAudio=true" filePath:@[@"/Users/用户/Desktop/xxxx.wav"] parms:nil fileType:FileType_Video result:^(ServerResponseInfo *serverInfo) {
if (serverInfo.isSuccess) {
[self.itemArr removeObjectAtIndex:0];
}
}];
```
#### Creating an download
```
downTask =  [VNHttpRequestManager downLoadRequest:@"http://dldir1.qq.com/qqfile/QQforMac/QQ_V5.4.0.dmg"  filePath:nil downProgress:^(double progress) {
[[NSOperationQueue mainQueue] addOperationWithBlock:^{
NSLog(@"%f",progress);
}];
} complement:^(NSURLResponse * _Nonnull response, NSURL * _Nullable filePath, NSError * _Nullable error) {

}];

# 开始/恢复下载
[VNHttpRequestManager startResume:downTask];
# 暂停下载
[VNHttpRequestManager suspend:downTask];

```


