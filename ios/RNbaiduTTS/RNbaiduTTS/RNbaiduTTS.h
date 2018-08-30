//
//  RNbaiduTTS.h
//  RNbaiduTTS
//
//  Created by 胡操航 on 2018/8/30.
//  Copyright © 2018年 dzyc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <React/RCTBridgeModule.h>
#import "BDSSpeechSynthesizer.h"

@interface RNbaiduTTS: NSObject <RCTBridgeModule, BDSSpeechSynthesizerDelegate>

@end

