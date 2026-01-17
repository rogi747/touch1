//
//  ScriptListTableCell.h
//  zxtouch
//
//  Created by Jason on 2020/12/14.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@class ScriptListTableCell;
@protocol ScriptListTableCellDelegate <NSObject>

- (void)cell:(ScriptListTableCell *)cell performActionWith:(UIButton *)button index:(NSInteger)index;

@end

@interface ScriptListTableCell : UITableViewCell

@property (weak, nonatomic) IBOutlet UILabel *titleLabel;
@property (weak, nonatomic) IBOutlet UIButton *playButton;
@property (weak, nonatomic) IBOutlet UIButton *moreButton;
@property (strong, nonatomic) IBOutlet UIImageView *iconImage;
@property (weak, nonatomic) id<ScriptListTableCellDelegate> delegate;
@property (strong, nonatomic) NSString *path;
@property (assign, nonatomic) BOOL showMore;

@end

NS_ASSUME_NONNULL_END
