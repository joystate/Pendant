//
//  ViewController.h
//  Pendant
//
//  Created by Nadia Yudina on 8/13/14.
//  Copyright (c) 2014 Nadia. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <QuartzCore/QuartzCore.h>
#import <AVFoundation/AVFoundation.h>
#import <SpeechKit/SpeechKit.h>

#import "EZAudio.h"
#import "FontAwesomeKit/FontAwesomeKit.h"
#import "AppDelegate.h"

#import "RFduinoDelegate.h"
#import "RFduino.h"


@interface AppViewController : UIViewController<EZMicrophoneDelegate, SKRecognizerDelegate, SpeechKitDelegate, RFduinoDelegate>

@property (nonatomic,strong) EZMicrophone *microphone;
@property (weak, nonatomic) IBOutlet EZAudioPlot *audioPlot;

@property (strong, nonatomic) SKRecognizer* voiceSearch;
@property (strong, nonatomic) AppDelegate *appDelegate;

@property(nonatomic, strong) RFduino *rfduino;

@end
