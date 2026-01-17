#ifndef SCREEN_H
#define SCREEN_H

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

#define SIZE_FACTOR 10000000.0

@interface Screen :NSObject
{
    
}

+ (void)setScreenSize:(CGFloat)x height:(CGFloat) y;
+ (int)getScreenOrientation;
+ (CGFloat)getScreenWidth;
+ (CGFloat)getScreenHeight;
+ (CGFloat)getScale;
+ (NSString*)screenShot;
+ (CGRect)getBounds;
+ (NSString*)screenShotAlwaysUp;
+ (UIImage*)screenShotUIImage;
+ (CGImageRef)createScreenShotCGImageRef;

@end

#endif
