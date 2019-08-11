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
