#import <Foundation/Foundation.h>

typedef enum WSAudioEffect_Type
{
    WSAUDIO_EFFECT_NULL,            // 无音效
    WSAUDIO_EFFECT_DELAY,           // 澡堂（回音壁）
    WSAUDIO_EFFECT_PITCHSHIFT_LOW,  // 低沉 （大叔）
    WSAUDIO_EFFECT_PITCHSHIFT_HI,   // 尖锐 （萝莉）
    WSAUDIO_EFFECT_ROBOT,           // 机器人
    WSAUDIO_EFFECT_WHISPER          // 耳语 （沙沙声）
} WSAudioEffect_Type;

@interface WSAudioEffect : NSObject

/*
 * 初始化音效模块
 * 音效功能在执行process前，必须先通过setup设置当前音频流的采样率和通道数
 * 在执行setup后，需要通过chooseEffectType设置音效效果，默认为不采用任何音效
 * 注：当音频流发生改变（采样率或通道数变更）时，需要创建新的WSAudioEffect对象
 * 进行音效处理
 *
 * @param sampleRate 采样率
 * @param channels 通道数
 */
-(void) setupWithSampleRate:(int)sampleRate channels:(int) channels;

/*
 * 切换音效
 * @param effectType 音效效果 @see WSAudioEffect_Type
 */
-(void) chooseEffectType:(WSAudioEffect_Type)effectType;

/*
 * 音效处理
 * @param data pcm数据
 * @param samplesPerChannel 音频帧每个通道sample数
 * @param channels 音频通道数（必须与setup时设置一致）
 */
-(void) process:(int16_t*)data samplesPerChannel:(int)samplesPerChannel channels:(int)channels;

@end
