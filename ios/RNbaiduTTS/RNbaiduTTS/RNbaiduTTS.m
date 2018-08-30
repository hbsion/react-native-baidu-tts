//
//  RNbaiduTTS.m
//  RNbaiduTTS
//
//  Created by 胡操航 on 2018/8/30.
//  Copyright © 2018年 dzyc. All rights reserved.
//
#import "RNbaiduTTS.h"
#import <React/RCTEventDispatcher.h>

static NSString* APP_EVENT_NAME = @"REACT_NATIVE_BAIDU_TTS";

@interface RNbaiduTTS()

@property (nonatomic,strong)NSDictionary* options;

@end

@implementation RNbaiduTTS

@synthesize bridge = _bridge;

RCT_EXPORT_MODULE();

RCT_EXPORT_METHOD(ping:(NSString *)name)
{
    NSLog(@"hello %@", name);
    NSLog(@"Heiheihei %@", name);
}

RCT_EXPORT_METHOD(init:(NSDictionary*)options
                  resolver:(RCTPromiseResolveBlock)resolve
                  rejecter:(RCTPromiseRejectBlock)reject)
{
    
    [[BDSSpeechSynthesizer sharedInstance] setSynthesizerDelegate:self];
    
    [self configureOnlineTTS:options];
    //    NSLog(@"offlineEngine2018 %@", options[@"offlineEngine"]);
    //    在线配置
    //    if (!!options[@"offlineEngine"]) {
    //        NSError* error = [self configureOfflineTTS:options];
    //
    //        if (error) {
    //            reject(@"init-failed", @"error-occured-while-init-offline-engine", error);
    //            return;
    //        }
    //
    //    }
    
    resolve([NSNumber numberWithBool:YES]);
    
}

-(void)configureOnlineTTS:(NSDictionary*)options
{
    [BDSSpeechSynthesizer setLogLevel:BDS_PUBLIC_LOG_VERBOSE];
    BDSSpeechSynthesizer* instance = [BDSSpeechSynthesizer sharedInstance];
    [instance setApiKey:options[@"apiKey"] withSecretKey:options[@"secretKey"]];
    NSLog(@"在线合成初始化");
}

-(NSError*)configureOfflineTTS:(NSDictionary*)options {
    
    NSLog(@"configure options: %@", options);
    
    NSBundle* bundle = [NSBundle mainBundle];
    NSString* chineseSpeechData;
    NSString* chineseTextData = @"Chinese_Text";
    NSString* englishSpeechData;
    NSString* englishTextData = @"English_Text";
    
    if ([options[@"tongue"]  isEqual: @"male"]) {
        chineseSpeechData = @"Chinese_Speech_Male";
        englishSpeechData = @"English_Speech_Male";
    } else {
        chineseSpeechData = @"Chinese_Speech_Female";
        englishSpeechData = @"English_Speech_Female";
    }
    
    NSLog(@"12321");
    
    // 中文离线包
    NSString* offlineChineseSpeechData = [bundle pathForResource:chineseSpeechData ofType:@"dat"];
    NSString* offlineChineseTextData = [bundle pathForResource:chineseTextData ofType:@"dat"];
    
    // 许可文件
    NSString* licenseFile = [bundle pathForResource:@"offline_engine_tmp_license" ofType:@"dat"];
    
    NSLog(@"embed dat: %@, %@, %@", offlineChineseSpeechData, offlineChineseTextData, licenseFile);
    
    BDSSpeechSynthesizer* instance = [BDSSpeechSynthesizer sharedInstance];
    
    // 加载离线引擎
    NSError* err = [instance
                    loadOfflineEngine:offlineChineseTextData
                    speechDataPath:offlineChineseSpeechData
                    licenseFilePath:licenseFile
                    withAppCode:options[@"appID"]];
    
    if (err) {
        //        NSLog(@" TTS load offline engine failed: %@", err);
        NSLog(@"离线配置失败%@",err);
        return err;
    }
    
    // 英文离线包
    NSString* offlineEnglishSpeechData = [bundle pathForResource:englishSpeechData ofType:@"dat"];
    NSString* offlineEngineTextData = [bundle pathForResource:englishTextData ofType:@"dat"];
    
    // 加载英文离线资源
    err = [instance
           loadEnglishDataForOfflineEngine:offlineEngineTextData
           speechData:offlineEnglishSpeechData];
    
    if (err) {
        //        NSLog(@"TTS offline engine load English support failed: %@", err);
        NSLog(@"离线配置失败%@",err);
        return err;
    }
    
    return nil;
    
}


// 合成语音
// 只合成，不播报
// 若当前没有合成过程，那么开始批量合成过程
// 若当前已有合成过程，那么将文本添加到当前的合成过程
RCT_EXPORT_METHOD(synthesizeSentence:(NSString*)sentence
                  resolver:(RCTPromiseResolveBlock)resolve
                  rejecter:(RCTPromiseRejectBlock)reject)
{
    
    NSError* error;
    
    NSInteger id = [[BDSSpeechSynthesizer sharedInstance] synthesizeSentence:sentence withError:&error];
    
    if (error == nil) {
        resolve([NSNumber numberWithInteger:id]);
    }
    else {
        reject(@"speak-failed", @"", error);
    }
    
}

// 合成语音并播报
// 若当前没有合成过程，那么开始批量合成过程
// 若当前已有合成过程，那么将文本添加到当前的合成过程
RCT_EXPORT_METHOD(speekSentence:(NSString*)sentence
                  resolver:(RCTPromiseResolveBlock)resolve
                  rejecter:(RCTPromiseRejectBlock)reject)
{
    
    NSError* error;
    NSLog(@"speekSentence %@", sentence);
    NSInteger id = [[BDSSpeechSynthesizer sharedInstance] speakSentence:sentence withError:&error];
    
    if (error == nil) {
        resolve([NSNumber numberWithInteger:id]);
    }
    else {
        reject(@"speak-failed", @"", error);
    }
    
    
}

// 取消本次合成并停止朗读
RCT_EXPORT_METHOD(cancel:(RCTPromiseResolveBlock)resolve
                  rejecter:(RCTPromiseRejectBlock)reject)
{
    
    [[BDSSpeechSynthesizer sharedInstance] cancel];
    resolve([NSNumber numberWithBool:YES]);
    
}

RCT_EXPORT_METHOD(getStatus:(RCTPromiseResolveBlock)resolve
                  rejecter:(RCTPromiseRejectBlock)reject)
{
    
    resolve([NSNumber numberWithInteger:[[BDSSpeechSynthesizer sharedInstance] synthesizerStatus]]);
    
}

RCT_EXPORT_METHOD(setVolume:(float)volume
                  resolver:(RCTPromiseResolveBlock)resolve
                  rejecter:(RCTPromiseRejectBlock)reject)
{
    
    [[BDSSpeechSynthesizer sharedInstance] setPlayerVolume:volume];
    
    resolve([NSNumber numberWithBool:YES]);
    
}

#pragma mark - implement BDSSpeechSynthesizerDelegate

// 合成开始
- (void)synthesizerStartWorkingSentence:(NSInteger)SynthesizeSentence
{
    [self.bridge.eventDispatcher
     sendAppEventWithName:APP_EVENT_NAME
     body:@{
            @"name": @"synthesize-start",
            @"synthesizeSentenceID": [NSNumber numberWithInteger: SynthesizeSentence]
            }];
}

// 合成结束
- (void)synthesizerFinishWorkingSentence:(NSInteger)SynthesizeSentence
{
    [self.bridge.eventDispatcher
     sendAppEventWithName:APP_EVENT_NAME
     body:@{
            @"name": @"synthesize-end",
            @"synthesizeSentenceID": [NSNumber numberWithInteger: SynthesizeSentence]
            }];
}

// 播报开始
- (void)synthesizerSpeechStartSentence:(NSInteger)SpeakSentence{
    [self.bridge.eventDispatcher
     sendAppEventWithName:APP_EVENT_NAME
     body:@{
            @"name": @"speech-start",
            @"speekSentenceID": [NSNumber numberWithInteger: SpeakSentence]
            }];
}

// 播报结束
- (void)synthesizerSpeechEndSentence:(NSInteger)SpeakSentence
{
    [self.bridge.eventDispatcher
     sendAppEventWithName:APP_EVENT_NAME
     body:@{
            @"name": @"speech-end",
            @"speekSentenceID": [NSNumber numberWithInteger: SpeakSentence]
            }];
}

// 新的播报语音块合成完成
- (void)synthesizerNewDataArrived:(NSData *)newData
                       DataFormat:(BDSAudioFormat)fmt
                   characterCount:(int)newLength
                   sentenceNumber:(NSInteger)SynthesizeSentence
{
    
    [self.bridge.eventDispatcher
     sendAppEventWithName:APP_EVENT_NAME
     body:@{
            @"name": @"new-data",
            @"characterCount": [NSNumber numberWithInt:newLength],
            @"synthesizeSentenceID": [NSNumber numberWithInteger: SynthesizeSentence]
            }];
    
}

// 播放进度变更
- (void)synthesizerTextSpeakLengthChanged:(int)newLength
                           sentenceNumber:(NSInteger)SpeakSentence
{
    [self.bridge.eventDispatcher
     sendAppEventWithName:APP_EVENT_NAME
     body:@{
            @"name": @"progress",
            @"speekSentenceID": [NSNumber numberWithInteger:SpeakSentence]
            }];
}

// 合成器发生错误
-(void)synthesizerErrorOccurred:(NSError *)error
                       speaking:(NSInteger)SpeakSentence
                   synthesizing:(NSInteger)SynthesizeSentence
{
    
    [self.bridge.eventDispatcher
     sendAppEventWithName:APP_EVENT_NAME
     body:@{
            @"name": @"error",
            @"speekSentenceID": [NSNumber numberWithInteger:SpeakSentence],
            @"synthesizeSentenceID": [NSNumber numberWithInteger: SynthesizeSentence]
            }];
    
}

@end


