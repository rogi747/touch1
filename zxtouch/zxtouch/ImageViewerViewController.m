//
//  ImageViewerViewController.m
//  zxtouch
//
//  Created by Jason on 2021/2/2.
//

#import "ImageViewerViewController.h"
#import "Util.h"

@interface ImageViewerViewController ()

@end

@implementation ImageViewerViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    if (_path) {
        UIImage *image = [UIImage imageWithContentsOfFile:_path];
        _imageView.image = image;
        
        CGSize imageSize = image.size;
        CGSize viewSize = _imageView.bounds.size;
        
        if (imageSize.width <= viewSize.width &&
            imageSize.height <= viewSize.height) {
            _imageView.contentMode = UIViewContentModeCenter;
        } else {
            _imageView.contentMode = UIViewContentModeScaleAspectFit;
        }
    } else {
        [Util showAlertBoxWithOneOption:self title:NSLocalizedString(@"error", nil) message:NSLocalizedString(@"anErrorHappened", nil) buttonString:@"OK"];
    }
}

@end
