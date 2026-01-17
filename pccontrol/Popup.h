#ifndef POPUP_H
#define POPUP_H

#import <Foundation/Foundation.h>

@interface PopupWindow : NSObject
- (void) show;
- (void) hide;

- (BOOL) isShown;
@end

extern PopupWindow *popupWindow;

#endif
