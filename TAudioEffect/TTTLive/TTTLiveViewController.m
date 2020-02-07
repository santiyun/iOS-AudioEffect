//
//  TTTLiveViewController.m
//  TTTLive
//
//  Created by yanzhen on 2018/8/21.
//  Copyright © 2018年 yanzhen. All rights reserved.
//

#import "TTTLiveViewController.h"

@interface TTTLiveViewController ()<TTTRtcEngineDelegate, UIPickerViewDelegate, UIPickerViewDataSource>
@property (weak, nonatomic) IBOutlet UIImageView *anchorVideoView;
@property (weak, nonatomic) IBOutlet UIButton *voiceBtn;
@property (weak, nonatomic) IBOutlet UIButton *switchBtn;
@property (weak, nonatomic) IBOutlet UILabel *roomIDLabel;
@property (weak, nonatomic) IBOutlet UILabel *anchorIdLabel;
@property (weak, nonatomic) IBOutlet UILabel *audioStatsLabel;
@property (weak, nonatomic) IBOutlet UILabel *videoStatsLabel;
@property (weak, nonatomic) IBOutlet UIView *pickBGView;
@property (weak, nonatomic) IBOutlet UIPickerView *pickerView;
@property (weak, nonatomic) IBOutlet UILabel *effectNameLabel;

@property (nonatomic, strong) NSArray<NSString *> *effectTypes;
@property (nonatomic, strong) WSAudioEffect *effect;
@end

@implementation TTTLiveViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    
    _roomIDLabel.text = [NSString stringWithFormat:@"房号: %lld", TTManager.roomID];
    _anchorIdLabel.text = [NSString stringWithFormat:@"主播ID: %lld", TTManager.uid];
    _effectTypes = @[@"NULL", @"DELAY", @"LOW", @"HI", @"ROBOT", @"WHISPER"];
    
    TTManager.rtcEngine.delegate = self;
    [TTManager.rtcEngine startPreview];
    TTTRtcVideoCanvas *videoCanvas = [[TTTRtcVideoCanvas alloc] init];
    videoCanvas.renderMode = TTTRtc_Render_Adaptive;
    videoCanvas.uid = TTManager.uid;
    videoCanvas.view = _anchorVideoView;
    [TTManager.rtcEngine setupLocalVideo:videoCanvas];
}

- (IBAction)leftBtnsAction:(UIButton *)sender {
    if (sender.tag == 1001) {
        sender.selected = !sender.isSelected;
        [TTManager.rtcEngine muteLocalAudioStream:sender.isSelected];
    } else if (sender.tag == 1002) {
//        [_effect chooseEffectType:WSAUDIO_EFFECT_NULL];
        _pickBGView.hidden = !_pickBGView.isHidden;
    } else {
        [TTManager.rtcEngine switchCamera];
    }
}

- (IBAction)pickerDone:(UIButton *)sender {
    NSInteger index = [_pickerView selectedRowInComponent:0];
    [_effect chooseEffectType:(WSAudioEffect_Type)index];
    _effectNameLabel.text = _effectTypes[index];
}

- (IBAction)exitChannel:(id)sender {
    __weak TTTLiveViewController *weakSelf = self;
    UIAlertController *alert  = [UIAlertController alertControllerWithTitle:@"提示" message:@"您确定要退出房间吗？" preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:nil]];
    UIAlertAction *sureAction = [UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        [TTManager.rtcEngine leaveChannel:nil];
        [TTManager.rtcEngine stopPreview];
        [weakSelf dismissViewControllerAnimated:YES completion:nil];
    }];
    [alert addAction:sureAction];
    [self presentViewController:alert animated:YES completion:nil];
}

#pragma mark - TTTRtcEngineDelegate
//使用音效处理本地音频数据
- (void)rtcEngine:(TTTRtcEngineKit *)engine localAudioData:(char *)data dataSize:(NSUInteger)size sampleRate:(NSUInteger)sampleRate channels:(NSUInteger)channels {
    if (!_effect) {
        _effect = [[WSAudioEffect alloc] init];
        [_effect setupWithSampleRate:(int)sampleRate channels:(int)channels];
        [_effect chooseEffectType:WSAUDIO_EFFECT_ROBOT];
    }
    
    NSUInteger samplesPerChannel = size / channels / 2;
    [_effect process:(int16_t*)data samplesPerChannel:(int)samplesPerChannel channels:(int)channels];
}

- (void)rtcEngine:(TTTRtcEngineKit *)engine reportAudioLevel:(int64_t)userID audioLevel:(NSUInteger)audioLevel audioLevelFullRange:(NSUInteger)audioLevelFullRange {
    if (userID == TTManager.uid) {
        [_voiceBtn setImage:[TTManager getVoiceImage:audioLevel] forState:UIControlStateNormal];
    }
}

- (void)rtcEngine:(TTTRtcEngineKit *)engine localAudioStats:(TTTRtcLocalAudioStats *)stats {
    _audioStatsLabel.text = [NSString stringWithFormat:@"A-↑%lukbps", (unsigned long)stats.sentBitrate];
}

- (void)rtcEngine:(TTTRtcEngineKit *)engine localVideoStats:(TTTRtcLocalVideoStats *)stats {
    _videoStatsLabel.text = [NSString stringWithFormat:@"V-↑%lukbps", (unsigned long)stats.sentBitrate];
}

- (void)rtcEngineConnectionDidLost:(TTTRtcEngineKit *)engine {
    [TTProgressHud showHud:self.view message:@"网络链接丢失，正在重连..."];
}

- (void)rtcEngineReconnectServerTimeout:(TTTRtcEngineKit *)engine {
    [TTProgressHud hideHud:self.view];
    [self.view.window showToast:@"网络丢失，请检查网络"];
    [engine leaveChannel:nil];
    [engine stopPreview];
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)rtcEngineReconnectServerSucceed:(TTTRtcEngineKit *)engine {
    [TTProgressHud hideHud:self.view];
}

- (void)rtcEngine:(TTTRtcEngineKit *)engine didKickedOutOfUid:(int64_t)uid reason:(TTTRtcKickedOutReason)reason {
    NSString *errorInfo = @"";
    switch (reason) {
        case TTTRtc_KickedOut_KickedByHost:
            errorInfo = @"被主播踢出";
            break;
        case TTTRtc_KickedOut_PushRtmpFailed:
            errorInfo = @"rtmp推流失败";
            break;
        case TTTRtc_KickedOut_MasterExit:
            errorInfo = @"主播已退出";
            break;
        case TTTRtc_KickedOut_ReLogin:
            errorInfo = @"重复登录";
            break;
        case TTTRtc_KickedOut_NoAudioData:
            errorInfo = @"长时间没有上行音频数据";
            break;
        case TTTRtc_KickedOut_NoVideoData:
            errorInfo = @"长时间没有上行视频数据";
            break;
        case TTTRtc_KickedOut_NewChairEnter:
            errorInfo = @"其他人以主播身份进入";
            break;
        case TTTRtc_KickedOut_ChannelKeyExpired:
            errorInfo = @"Channel Key失效";
            break;
        default:
            errorInfo = @"未知错误";
            break;
    }
    [self.view.window showToast:errorInfo];
    [engine leaveChannel:nil];
    [engine stopPreview];
    [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - UIPickerViewDelegate, UIPickerViewDataSource
- (NSInteger)numberOfComponentsInPickerView:(UIPickerView *)pickerView {
    return 1;
}

- (NSInteger)pickerView:(UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component {
    return _effectTypes.count;
}

- (CGFloat)pickerView:(UIPickerView *)pickerView rowHeightForComponent:(NSInteger)component {
    return 35;
}

- (NSString *)pickerView:(UIPickerView *)pickerView titleForRow:(NSInteger)row forComponent:(NSInteger)component {
    return _effectTypes[row];
}
@end
