//
//  ViewController.m
//  Pendant
//
//  Created by Nadia Yudina on 8/13/14.
//  Copyright (c) 2014 Nadia. All rights reserved.
//

#import "AppViewController.h"
#import "Constants.h"
#import "WordHandler.h"


#define kPurpleColor [UIColor colorWithRed:0.5 green:0 blue:1.0 alpha:1.0]

@interface AppViewController ()

@property (strong, nonatomic) AVAudioPlayer *audioPlayer;
@property (weak, nonatomic) IBOutlet UIButton *microphoneButton;
@property (nonatomic) BOOL isMicPressed;
@property (strong, nonatomic) NSArray *negativeWords;
@property (strong, nonatomic) NSArray *positiveWords;
@property (nonatomic) NSInteger emotionCounter;

@property (nonatomic) CGFloat red;
@property (nonatomic) CGFloat green;
@property (nonatomic) CGFloat blue;

@end

SpeechKitApplicationKey

@implementation AppViewController

-(void)awakeFromNib
{
    [super awakeFromNib];
    [self initializeViewController];
}

-(void)initializeViewController {
    self.microphone = [EZMicrophone microphoneWithDelegate:self];
}

- (IBAction)microphoneButtonPressed:(id)sender
{
    if (self.isMicPressed) {
        [self.microphone stopFetchingAudio];
        self.isMicPressed = NO;
        if (self.voiceSearch) {
            [self.voiceSearch stopRecording];
            [self.voiceSearch cancel];
        }
    } else {
        
        [self.microphone startFetchingAudio];
        self.voiceSearch = [[SKRecognizer alloc] initWithType:SKSearchRecognizerType
                                                        detection:SKLongEndOfSpeechDetection
                                                         language:@"en_US"
                                                         delegate:self];
        self.isMicPressed = YES;
    }
}



- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.isMicPressed = YES;
    self.emotionCounter = 0;
    self.rfduino.delegate = self;
    
    self.audioPlot.backgroundColor = [UIColor colorWithRed:1 green:1 blue:1 alpha:1.0];
    self.audioPlot.color = kPurpleColor;
    self.audioPlot.plotType = EZPlotTypeBuffer;
    
    [self.microphone startFetchingAudio];
    [self drawBufferPlot];
    [self drawMicrophoneButton];
    
    self.appDelegate = (AppDelegate *)[UIApplication sharedApplication].delegate;
    [self.appDelegate setupSpeechKitConnection];
  	self.negativeWords = [WordHandler arrayOfWordsFromFile:@"negative_words"];
    self.positiveWords = [WordHandler arrayOfWordsFromFile:@"positive_words"];
    
    self.voiceSearch = [[SKRecognizer alloc] initWithType:SKSearchRecognizerType
                                                detection:SKLongEndOfSpeechDetection
                                                 language:@"en_US"
                                                 delegate:self];
}

-(void)drawMicrophoneButton
{
    FAKIonIcons *micIcon = [FAKIonIcons ios7MicIconWithSize:50];
    [self.microphoneButton setTintColor:kPurpleColor];
    UIImage *micImage = [micIcon imageWithSize:CGSizeMake(50, 50)];

    [self.microphoneButton setImage:micImage forState:UIControlStateNormal];
}


-(void)drawBufferPlot
{
    self.audioPlot.plotType = EZPlotTypeBuffer;
    self.audioPlot.shouldMirror = NO;
    self.audioPlot.shouldFill = NO;
}

- (NSArray *)handleArray: (NSArray *)inputArray
{
    NSMutableArray *changedArray = [inputArray mutableCopy];
    NSString *firstWord = [changedArray[0] lowercaseString];
    [changedArray removeObjectAtIndex:0];
    [changedArray insertObject:firstWord atIndex:0];
    return changedArray;
}

- (void)sendByte:(uint8_t)byte
{
    uint8_t tx[1] = { byte };
    NSData *data = [NSData dataWithBytes:(void*)&tx length:1];
    [self.rfduino send:data];
}


- (void)selectColor
{
    uint8_t tx[3] = { self.red * 255, self.green * 255, self.blue * 255 };
    NSData *data = [NSData dataWithBytes:(void*)&tx length:3];
    
    [self.rfduino send:data];
}

- (void)incrementCounter: (NSArray *)result completion: (void(^)())completion
{
    for (NSString *word in result) {
        if ([self.positiveWords containsObject:[word uppercaseString]]) {
            self.emotionCounter += 1;
        }
        
        if ([self.negativeWords containsObject:[word uppercaseString]]) {
            self.emotionCounter -= 1;
        }
    }
}



#pragma mark - EZMicrophoneDelegate
#warning Thread Safety
// Note that any callback that provides streamed audio data (like streaming microphone input) happens on a separate audio thread that should not be blocked. When we feed audio data into any of the UI components we need to explicity create a GCD block on the main thread to properly get the UI to work.
-(void)microphone:(EZMicrophone *)microphone
 hasAudioReceived:(float **)buffer
   withBufferSize:(UInt32)bufferSize
withNumberOfChannels:(UInt32)numberOfChannels {
    // Getting audio data as an array of float buffer arrays. What does that mean? Because the audio is coming in as a stereo signal the data is split into a left and right channel. So buffer[0] corresponds to the float* data for the left channel while buffer[1] corresponds to the float* data for the right channel.
    
    // See the Thread Safety warning above, but in a nutshell these callbacks happen on a separate audio thread. We wrap any UI updating in a GCD block on the main thread to avoid blocking that audio flow.
    dispatch_async(dispatch_get_main_queue(),^{
        // All the audio plot needs is the buffer data (float*) and the size. Internally the audio plot will handle all the drawing related code, history management, and freeing its own resources. Hence, one badass line of code gets you a pretty plot :)
        [self.audioPlot updateBuffer:buffer[0] withBufferSize:bufferSize];
    });
}

-(void)microphone:(EZMicrophone *)microphone hasAudioStreamBasicDescription:(AudioStreamBasicDescription)audioStreamBasicDescription {
    // The AudioStreamBasicDescription of the microphone stream. This is useful when configuring the EZRecorder or telling another component what audio format type to expect.
    // Here's a print function to allow you to inspect it a little easier
    [EZAudio printASBD:audioStreamBasicDescription];
}

-(void)microphone:(EZMicrophone *)microphone
    hasBufferList:(AudioBufferList *)bufferList
   withBufferSize:(UInt32)bufferSize
withNumberOfChannels:(UInt32)numberOfChannels {
    // Getting audio data as a buffer list that can be directly fed into the EZRecorder or EZOutput. Say whattt...
}


# pragma mark - SKRecognizer Delegate Methods

- (void)recognizerDidBeginRecording:(SKRecognizer *)recognizer
{
    
}

- (void)recognizerDidFinishRecording:(SKRecognizer *)recognizer
{
    
}

- (void)recognizer:(SKRecognizer *)recognizer didFinishWithResults:(SKRecognition *)results
{
    long numOfResults = [results.results count];
    
    NSLog(@"results: %@", results);
    
    if (numOfResults > 0) {
        // update the text of text field with best result from SpeechKit
        
        NSArray *input = [[results firstResult] componentsSeparatedByString:@" "];
        NSArray *result = [self handleArray:input];
        
        NSLog(@"result: %@", result);
        
        NSLog(@"starting counter: %ld", self.emotionCounter);
        
        for (NSString *word in result) {
            if ([self.positiveWords containsObject:[word uppercaseString]]) {
                self.emotionCounter += 1;
            } else if ([self.negativeWords containsObject:[word uppercaseString]]) {
                self.emotionCounter -= 1;
            }
        }
        
        if (self.emotionCounter >= 1) {
            NSLog(@"good: %ld", (long)self.emotionCounter);
            self.red = 0;
            self.green = 1;
            self.blue = 0;
        } else if (self.emotionCounter < 1 && self.emotionCounter != 0) {
            NSLog(@"bad: %ld", (long)self.emotionCounter);
            self.red = 1;
            self.blue = 0;
            self.green = 0;
        } else {
            NSLog(@"neutral: %ld", (long)self.emotionCounter);
            self.red = 0;
            self.green = 0;
            self.blue = 1;
        }
        
        NSLog(@"counter: %ld", (long)self.emotionCounter);
        [self selectColor];
    }
    
    [self.voiceSearch stopRecording];
    [self.voiceSearch cancel];
    self.voiceSearch = [[SKRecognizer alloc] initWithType:SKSearchRecognizerType
                                                    detection:SKLongEndOfSpeechDetection
                                                     language:@"en_US"
                                                     delegate:self];
}

- (void)recognizer:(SKRecognizer *)recognizer didFinishWithError:(NSError *)error suggestion:(NSString *)suggestion
{
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Error"
                                                    message:[error localizedDescription]
                                                   delegate:nil
                                          cancelButtonTitle:@"OK"
                                          otherButtonTitles:nil];
    [alert show];
}





@end
