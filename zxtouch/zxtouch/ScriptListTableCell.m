//
//  ScriptListTableCell.m
//  zxtouch
//
//  Created by Jason on 2020/12/14.
//

#import "ScriptListTableCell.h"
#import "Socket.h"
#import "Util.h"

@implementation ScriptListTableCell

- (IBAction)playButtonClick:(id)sender {
    [self.delegate cell:self performActionWith:sender index:0];
}

- (IBAction)moreButtonClicked:(id)sender {
    [self.delegate cell:self performActionWith:sender index:1];
}

- (void)setTitle:(NSString*)title{
    _titleLabel.text = title;
}

- (void) hideButton{
    [_playButton setHidden:YES];
}

- (void) showButton{
    [_playButton setHidden:NO];
}

- (void)setShowMore:(BOOL)showMore {
    _showMore = showMore;
    _moreButton.hidden = !showMore;
}

- (void)setPath:(NSString *)path {
    _path = path;
    
    BOOL isDir = NO;
    self.title = [path lastPathComponent];
    
    // is script. can play
    if ([[path pathExtension] isEqualToString:@"bdl"]) {
        [self showButton];
        _iconImage.image = [UIImage imageNamed:@"script-icon"];
        
        return;
    }
    
    [[NSFileManager defaultManager] fileExistsAtPath:path isDirectory:&isDir];
    [self hideButton];

    if (!isDir)
    {
        [_iconImage setImage:[UIImage imageNamed:@"normal-file-icon"]];
    }
    else
    {
        [_iconImage setImage:[UIImage imageNamed:@"folder-icon"]];
    }
}

@end
