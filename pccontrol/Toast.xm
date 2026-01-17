#import "Toast.h"
#import "Screen.h"
#import <mach/mach.h>

static int windowWidth = 200;
static int windowHeight = 200;
static NSDictionary* backgroundColorDict = @{@"4":[UIColor colorWithRed:0.282f green:0.78f blue:0.45f alpha:1.0f], @"1":[UIColor colorWithRed:0.945f green:0.275f blue:0.408f alpha:1.0f],@"2":[UIColor colorWithRed:1.0f green:0.867f blue:0.341f alpha:1.0f],@"3":[UIColor whiteColor]};
static NSDictionary* fontColorDict = @{@"4":[UIColor whiteColor], @"1":[UIColor whiteColor],@"2":[UIColor colorWithRed:0.0f green:0.0f blue:0.0f alpha:0.7f],@"3":[UIColor colorWithRed:0.0f green:0.0f blue:0.0f alpha:0.7f]};
static UIWindow *_window;
void showToastFromRawData(UInt8 *eventData, NSError **error)
{
    @autoreleasepool{
        NSArray *data = [[NSString stringWithFormat:@"%s", eventData] componentsSeparatedByString:@";;"];
        if ([data count] < 3)
        {
            *error = [NSError errorWithDomain:@"com.zjx.zxtouchsp" code:999 userInfo:@{NSLocalizedDescriptionKey:@"-1;;The data format should be \"type;;content;;duration(in seconds)[];;position(0: top, 1: bottom, 2: left, 3: right)]\". For example, 0;;success;;1.5;;0.\r\n"}];
            return;
        }
        int type = [data[0] intValue];
        int duration = [data[2] intValue];
        int position = 0;
        int fontSize = 0;
        if ([data count] >= 4)
        {
            position = [data[3] intValue];
        }
        if ([data count] >= 5)
        {
            fontSize = [data[4] intValue];
        }

        if (type > 4 || type < 0)
        {
            *error = [NSError errorWithDomain:@"com.zjx.zxtouchsp" code:999 userInfo:@{NSLocalizedDescriptionKey:@"-1;;Unknown type. The type ranges from 0-3. Please refer to the documentation on Github.\r\n"}];
            return;
        }
        if (duration <= 0 && type != 0)
        {
            *error = [NSError errorWithDomain:@"com.zjx.zxtouchsp" code:999 userInfo:@{NSLocalizedDescriptionKey:@"-1;;Duration should be a positive float number.\r\n"}];
            return;
        }
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            if (type == 0)
                [Toast hideToast];
            else
                [Toast showToastWithContent:data[1] type:type duration:duration position:position fontSize:fontSize];
        });
    }
}

@implementation Toast
{
    int duration;
    UIColor *backgroundColor;
    int type; // 0 hide 1 error 2 warning 3 message 4 success
}

+ (void) hideToast
{
    dispatch_async(dispatch_get_main_queue(), ^{
        if (_window != NULL)
        {
            _window.hidden = YES;
            _window = nil;
        }
    });
}

+ (void) showToastWithContent:(NSString*)content type:(int)type duration:(float)duration position:(int)position fontSize:(int)afontSize // positon: 0 top 1 bottom 2 left(not supported) 3 right (ns)
{
    __block UIWindow* currentWindow = NULL;
    dispatch_async(dispatch_get_main_queue(), ^{
        if (_window != NULL)
        {
            _window.hidden = YES;
            _window = nil;
        }

        CGFloat scale = [Screen getScale];
        // 尺寸是乘了scale的，先还原
        CGFloat screenWidth = [Screen getScreenWidth] / scale;
        CGFloat screenHeight = [Screen getScreenHeight] / scale;
        
        int fontSize = 15;
        if (afontSize != 0)
        {
            fontSize = afontSize;
        }
        else
        {
            fontSize = (int)(0.015*screenWidth);
            if (fontSize <= 15)
            {
                fontSize = 15;
            }
            else if (fontSize >= 30)
            {
                fontSize = 30;
            }
        }

        UIFont * font = [UIFont systemFontOfSize:fontSize];
        // window边距 2 * 10，label边距 2 * 10
        CGSize contentSize = [self calculateTextSizeWithText:content font:font maxWidth:screenWidth - 40];

        CGFloat width = contentSize.width;
        CGFloat height = contentSize.height;
        //NSLog(@"### com.zjx.springboard: screenWidth %f width: %f height %f", screenWidth, width, height);
        windowWidth = width + 20;
        windowHeight = height + 8;

        int windowLeftTopCornerX = (int)((screenWidth - windowWidth) / 2);
        int windowLeftTopCornerY = 30;

        if (position == 0)
        {
            windowLeftTopCornerY = 30;
        }
        else if (position == 1)
        {
            windowLeftTopCornerY = (int)(screenHeight - height - 50);
        }

        if (@available(iOS 11.0, *)) {
            UIWindow *window = UIApplication.sharedApplication.windows.firstObject;
            CGFloat bottomPadding = window.safeAreaInsets.bottom;

            windowLeftTopCornerY = bottomPadding + windowLeftTopCornerY;
        }

        _window = [[UIWindow alloc] initWithFrame:CGRectMake(windowLeftTopCornerX, windowLeftTopCornerY, windowWidth, windowHeight)];
        currentWindow = _window;
        _window.windowLevel = UIWindowLevelStatusBar;
        [_window setBackgroundColor: backgroundColorDict[[@(type) stringValue]]];
        _window.layer.cornerRadius = 10;
        [_window setUserInteractionEnabled:NO];

        UILabel *contentLabel = [[UILabel alloc]initWithFrame:CGRectMake(10, 4, width, height)];
        contentLabel.numberOfLines = 0;
        contentLabel.font = font;
        contentLabel.text = content;
        contentLabel.textColor = fontColorDict[[@(type) stringValue]];
        [_window addSubview:contentLabel];

        _window.hidden = NO;

        if ([UIDevice currentDevice].systemVersion.floatValue >= 13.0) {
            NSSet *scenes = [[UIApplication sharedApplication] performSelector:@selector(connectedScenes)];
            for (id windowScene in scenes){
                
                if ([windowScene activationState] == 0) {
                    [_window performSelector:@selector(setWindowScene:) withObject:windowScene];
                    continue;
                }
                if ([windowScene activationState] == 1) {
                    [_window performSelector:@selector(setWindowScene:) withObject:windowScene];
                    NSLog(@"### com.zjx.springboard: toast windowScene %@", windowScene);
                }
            }
        }

    });

    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(duration * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        if (currentWindow != _window) {
            return;
        }
        _window.hidden = YES;
        _window = nil;
    });
}

- (void) show {

    
}

- (void) setContent:(NSString*)content {
    self.content = content;
}

- (void) setBackgroundColor:(UIColor*)color{

}

- (void) setDuration:(int)d {
    duration = d;
}

+ (CGSize)calculateTextSizeWithText:(NSString *)text 
                               font:(UIFont *)font 
                           maxWidth:(CGFloat)maxWidth {
    
    CGSize constraintSize = CGSizeMake(maxWidth, CGFLOAT_MAX);
    NSDictionary *attributes = @{NSFontAttributeName: font};
    
    CGRect boundingRect = [text boundingRectWithSize:constraintSize
                                             options:NSStringDrawingUsesLineFragmentOrigin | NSStringDrawingUsesFontLeading
                                          attributes:attributes
                                             context:nil];
    
    // 使用ceil对尺寸进行向上取整
    return CGSizeMake(ceil(boundingRect.size.width), ceil(boundingRect.size.height));
}

@end