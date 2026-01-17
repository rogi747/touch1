#import "Popup.h"
#import "Screen.h"
#import "Record.h"
#include "Play.h"
#include "AlertBox.h"
#include "Toast.h"
#import <UIKit/UIKit.h>
#import "jbroot.h"
#include "TouchIndicator/TouchIndicatorWindow.h"

extern CGFloat device_screen_width;
extern CGFloat device_screen_height;

static int windowWidth = 250;
static int windowHeight = 150;

@implementation PopupWindow
{
    UIWindow *_window;
    BOOL isShown;
}

- (id) init
{
    self = [super init];
    if(self)
    {
        dispatch_async(dispatch_get_main_queue(), ^{
            CGFloat screenWidth = [Screen getScreenWidth];
            CGFloat screenHeight = [Screen getScreenHeight];

            CGFloat scale = [Screen getScale];

            windowWidth = (int)((screenWidth/scale)/1.7);
            //windowHeight = (int)((screenHeight/scale)/4);

            int windowLeftTopCornerX = (int)((screenWidth/scale)/2 - windowWidth/2);
            int windowLeftTopCornerY = (int)((screenHeight/scale)/2 - windowHeight/2);
            _window = [[UIWindow alloc] initWithFrame:CGRectMake(windowLeftTopCornerX, windowLeftTopCornerY, windowWidth, windowHeight)];
            _window.windowLevel = UIWindowLevelAlert;
            [_window setBackgroundColor:[UIColor colorWithRed:0.3 green:0.4 blue:0.2 alpha:0.5]];

            UIPanGestureRecognizer *panGesture = [[UIPanGestureRecognizer alloc]
                                          initWithTarget:self
                                          action:@selector(handlePan:)];
            [_window addGestureRecognizer:panGesture];


            _window.layer.cornerRadius = 15.0f;
            // Add header
            NSString *headerText = @"ZXTouch Panel";

            UIFont * font = [UIFont systemFontOfSize:22];
            CGSize headerSize = [headerText sizeWithAttributes:@{NSFontAttributeName: font}];

            UILabel *headerLabel = [[UILabel alloc]initWithFrame:CGRectMake(windowWidth/2 - headerSize.width/2 - 10, 5, headerSize.width, headerSize.height)];
            headerLabel.font = font;
            headerLabel.text = headerText;
            [_window addSubview:headerLabel];

            // Add hide button
            UIButton *closeButton = [UIButton buttonWithType:UIButtonTypeCustom];
            [closeButton addTarget:self 
                    action:@selector(hide)
            forControlEvents:UIControlEventTouchUpInside];
            [closeButton setTitle:@"X" forState:UIControlStateNormal];
                        closeButton.layer.borderColor = [UIColor blueColor].CGColor;
            closeButton.layer.borderWidth = 2.0f;
            closeButton.layer.cornerRadius = 10.0f;

            [closeButton setTitleColor:[UIColor blueColor] forState:UIControlStateNormal];
 
            closeButton.backgroundColor = [UIColor clearColor];

            closeButton.frame = CGRectMake(windowWidth-35, 5, 30, 30);
            [_window addSubview:closeButton];

            // row 2 buttons
            // add record button
            UIButton *recordButton = [UIButton buttonWithType:UIButtonTypeCustom];
            [recordButton addTarget:self 
                    action:@selector(recordingStart)
            forControlEvents:UIControlEventTouchUpInside];

            recordButton.backgroundColor = [UIColor clearColor];
            [recordButton setImage:[UIImage imageWithContentsOfFile:JBROOT_PATH_OC("/Library/Application Support/zxtouch/start-recording.png")] forState:UIControlStateNormal];

            recordButton.frame = CGRectMake(30, headerSize.height + 10, 60, 60);
            [_window addSubview:recordButton];

            // add stop script button
            UIButton *stopButton = [UIButton buttonWithType:UIButtonTypeCustom];
            [stopButton addTarget:self 
                    action:@selector(stopPlaying)
            forControlEvents:UIControlEventTouchUpInside];

            stopButton.backgroundColor = [UIColor clearColor];
            [stopButton setImage:[UIImage imageWithContentsOfFile:JBROOT_PATH_OC("/Library/Application Support/zxtouch/stop-playing.png")] forState:UIControlStateNormal];

            stopButton.frame = CGRectMake(100, headerSize.height + 10, 60, 60);
            [_window addSubview:stopButton];
        });
        isShown = NO;        
    }
    return self;
}

// 处理拖动手势
- (void)handlePan:(UIPanGestureRecognizer *)gesture {
    CGPoint translation = [gesture translationInView:_window];

    if (gesture.state == UIGestureRecognizerStateChanged) {
        // 移动视图
        gesture.view.center = CGPointMake(
            gesture.view.center.x + translation.x,
            gesture.view.center.y + translation.y
        );
        // 重置 translation，否则会累积
        [gesture setTranslation:CGPointZero inView:_window];
    }
}

- (void) recordingStart {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [self hide];
        NSError *err = nil;
        startRecording(0, &err);
        if (err)
        {
            showAlertBox(@"Error", [NSString stringWithFormat:@"Unable to start recording. Reason: %@",[err localizedDescription]], 999);
            return;
        }
    });
}

- (void) stopPlaying {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
        NSError *err = nil;
        stopScriptPlaying(&err);
        hideTouchIndicator();
        if (err)
        {
            showAlertBox(@"Error", [NSString stringWithFormat:@"Error happens while trying to stop script. %@", err], 999);
        }
        else
        {
            [Toast showToastWithContent:@"Script has been stopped" type:4 duration:1.0f position:0 fontSize:0];
        }
    });
}

- (void) show {
    dispatch_async(dispatch_get_main_queue(), ^{
        if ([UIDevice currentDevice].systemVersion.floatValue >= 13.0) {
            NSSet *scenes = [[UIApplication sharedApplication] performSelector:@selector(connectedScenes)];
            for (id windowScene in scenes){
                
                if ([windowScene activationState] == 0) {
                    [_window performSelector:@selector(setWindowScene:) withObject:windowScene];
                    break;
                }
                if ([windowScene activationState] == 1) {
                    [_window performSelector:@selector(setWindowScene:) withObject:windowScene];
                    NSLog(@"### com.zjx.springboard: popup windowScene %@", windowScene);
                }
            }
        }
        _window.hidden = NO;
    });
    isShown = YES;
}

- (void) hide {
    dispatch_async(dispatch_get_main_queue(), ^{
        _window.hidden = YES;
    });
    isShown = NO;
}

- (BOOL) isShown {
    return isShown;
}
@end
