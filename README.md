### 音效处理

#### 准备工作
1. 下载[TTTRtcEngineKit.framework](https://github.com/santiyun/iOS-LiveSDK) 和 [TTTPlayerKit.framework](https://github.com/santiyun/TTTPlayerKit_iOS)。 放在**TTTLib**目录下
2. 登录三体云[官网](http://dashboard.3ttech.cn/index/login) 注册体验账号，进入控制台新建自己的应用并获取APPID。

#### 运行工程

1. 在**TTTRtcManager.m**文件填写AppID

#### 注意事项

1. 加入房间前启用接口

```
- (int)enableAudioDataReport:(BOOL)enableLocal remote:(BOOL)enableRemote;
```

2. 音频回调处理音频数据

```
- (void)rtcEngine:(TTTRtcEngineKit *)engine localAudioData:(char *)data dataSize:(NSUInteger)size sampleRate:(NSUInteger)sampleRate channels:(NSUInteger)channels
```


