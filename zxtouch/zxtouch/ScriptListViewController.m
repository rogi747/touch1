//
//  ScriptListViewController.m
//  zxtouch
//
//  Created by Jason on 2020/12/14.
//

#import "ScriptListViewController.h"
#import "ScriptListTableCell.h"
#import "ScriptEditorViewController.h"
#import "LogViewController.h"
#import "ScriptManagement/AdderPopOverViewController.h"
#import "ImageViewerViewController.h"
#include "Config.h"
#import "ScriptManagement/MoreOptionsPopOverTableViewController.h"
#import "Socket.h"
#import "Util.h"

NSArray *builtin = nil;

@interface ScriptListViewController () <ScriptListTableCellDelegate>
@property (weak, nonatomic) UILabel *footer;
@property (strong, nonatomic) NSString *ip;
@property (assign, nonatomic) BOOL isScriptRoot;
@end

@implementation ScriptListViewController
{
    NSMutableArray *scriptList;
    NSString *currentFolder;
    UIRefreshControl *refreshControl;
}


- (void)setFolder:(NSString *)folder {
    currentFolder = folder;
    _isScriptRoot = [currentFolder isEqualToString:SCRIPTS_PATH];
}

- (UIModalPresentationStyle) adaptivePresentationStyleForPresentationController: (UIPresentationController * ) controller {
    return UIModalPresentationNone;
}

- (IBAction)logButtonClick:(id)sender {
    LogViewController *logEditorViewController = [[LogViewController alloc] initWithNibName: @"LogViewController" bundle: nil];
    
    logEditorViewController.title = @"Log";
    //[logEditorViewController setFile:RUNTIME_OUTPUT_PATH];

    [self presentViewController:logEditorViewController animated:YES completion:nil];
}

- (IBAction)addButtonClick:(id)sender {
    AdderPopOverViewController *contentVC = [[AdderPopOverViewController alloc] initWithNibName:@"AdderPopOverViewController" bundle:nil];
    contentVC.modalPresentationStyle = UIModalPresentationPopover;
    [contentVC setFolder:currentFolder];
    [contentVC setUpperLevelViewController:self];
    UIPopoverPresentationController *popPC = contentVC.popoverPresentationController;
    popPC.permittedArrowDirections = UIPopoverArrowDirectionAny;
    popPC.barButtonItem = sender;
    popPC.delegate = contentVC;
    [self presentViewController:contentVC animated:YES completion:nil];
}


- (NSMutableArray*) updateScriptList {
    NSMutableArray *scriptList = [[NSMutableArray alloc] init];

    [self insertFileListIntoArray:scriptList fromPath:currentFolder];
    
    NSFileManager *fm = [NSFileManager defaultManager];
    
    [scriptList sortUsingComparator:^NSComparisonResult(NSString *path1, NSString *path2) {
        BOOL isDir1 = NO, isDir2 = NO;
        [fm fileExistsAtPath:path1 isDirectory:&isDir1];
        [fm fileExistsAtPath:path2 isDirectory:&isDir2];
        
        if (isDir1 && !isDir2) {
            return NSOrderedAscending; // 目录在前
        } else if (!isDir1 && isDir2) {
            return NSOrderedDescending;
        } else {
            // 都是目录或都不是目录
            if (!isDir1 && !isDir2) {
                // 都是文件，判断bdl扩展
                NSString *ext1 = [[path1 pathExtension] lowercaseString];
                NSString *ext2 = [[path2 pathExtension] lowercaseString];
                BOOL isBDL1 = [ext1 isEqualToString:@"bdl"];
                BOOL isBDL2 = [ext2 isEqualToString:@"bdl"];
                
                if (isBDL1 && !isBDL2) {
                    return NSOrderedAscending; // bdl在前
                } else if (!isBDL1 && isBDL2) {
                    return NSOrderedDescending;
                }
            }
            // 同类型（目录、bdl、普通文件），按名称排序
            NSString *name1 = [[[path1 lastPathComponent] stringByDeletingPathExtension] lowercaseString];
            NSString *name2 = [[[path2 lastPathComponent] stringByDeletingPathExtension] lowercaseString];
            return [name1 compare:name2 options:NSCaseInsensitiveSearch];
        }
    }];

    // add scripts from documents list
    return scriptList;
}

- (BOOL)insertFileListIntoArray:(NSMutableArray *)arr fromPath:(NSString *)path {
    NSError *err = nil;
    NSArray *files = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:path error:&err];
    
    if (err) {
        NSLog(@"Error happens while getting files list. Error info: %@", err);
        return NO;
    }
    
    for (NSString *fileName in files) {
        if ([fileName hasPrefix:@"."]) {
            continue;
        }
        NSString *filePath = [path stringByAppendingPathComponent:fileName];
        [arr addObject:filePath];
    }
    
    return YES;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    if (![[NSUserDefaults standardUserDefaults] boolForKey:@"notifyDoubleClickVolumnBtn"])
    {
        
        UIAlertController* alert = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"prompt", nil)
                                                                       message:NSLocalizedString(@"showPopUpWindow", nil)
                                       preferredStyle:UIAlertControllerStyleAlert];
         
        UIAlertAction* defaultAction = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault
           handler:^(UIAlertAction * action) {}];
         
        [alert addAction:defaultAction];
        [self presentViewController:alert animated:YES completion:nil];
        
        [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"notifyDoubleClickVolumnBtn"];
        [[NSUserDefaults standardUserDefaults] synchronize];
    }
    
    if (!currentFolder)
        [self setFolder:SCRIPTS_PATH];
    
    scriptList = [self updateScriptList];
    
    refreshControl = [[UIRefreshControl alloc] init];
    [refreshControl addTarget:self action:@selector(refreshTable) forControlEvents:UIControlEventValueChanged];
    self.scriptListTableView.refreshControl = refreshControl;
    
    if (!_isScriptRoot) {
        self.navigationItem.leftBarButtonItems = nil;
    }
    
    builtin = @[@"Debug", @"examples", @"recording"];
    if ([builtin containsObject:self.navigationItem.title] || [currentFolder.pathExtension isEqualToString:@"bdl"]) {
        self.navigationItem.rightBarButtonItems = nil;
    }
    
    UILabel *footer = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, [UIScreen mainScreen].bounds.size.width, 50)];
    footer.textAlignment = NSTextAlignmentCenter;
    _scriptListTableView.tableFooterView = footer;
    _footer = footer;
    if (_isScriptRoot && !_ip) {
        [self getWANIPAddress];
    }
}

- (void)getWANIPAddress {
    NSURL *url = [NSURL URLWithString:@"https://ipinfo.io/json"];
    NSURLSessionConfiguration *cfg = [NSURLSessionConfiguration defaultSessionConfiguration];
    NSURLSession *session = [NSURLSession sessionWithConfiguration:cfg];
    NSURLSessionDataTask *task = [session dataTaskWithURL:url completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        if (data) {
            NSDictionary *dict = [NSJSONSerialization JSONObjectWithData:data options:kNilOptions error:nil];
            
            dispatch_async(dispatch_get_main_queue(), ^{
                NSString *ip = dict[@"ip"];
                self.ip = ip;
                self.footer.text = ip;
            });
        }
    }];
    
    [task resume];
}

- (void)cell:(ScriptListTableCell *)cell performActionWith:(id )sender index:(NSInteger)index {
    if (index == 0) {
        [self playScriptWithCell:cell];
    } else if (index == 1) {
        [self showMoreWithCell:cell sender:sender];
    }
}

- (void)playScriptWithCell:(ScriptListTableCell *)cell {
    NSIndexPath *indexPath = [_scriptListTableView indexPathForCell:cell];
    NSString *path = scriptList[indexPath.row];
    
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        Socket *springBoardSocket = [[Socket alloc] init];
        int ret = [springBoardSocket connect:@"127.0.0.1" byPort:6000];
        if (ret != 0) {
            return;
        }
        
        [springBoardSocket send:[NSString stringWithFormat:@"19%@", path]];
        NSString *result = [springBoardSocket recv:1024];
        if (result.length == 0 || [result characterAtIndex:0] != '0') {
            dispatch_async(dispatch_get_main_queue(), ^{
                [Util showAlertBoxWithOneOption:self title:@"Error" message:[NSString stringWithFormat:@"Cannot play script. Error: %@", result] buttonString:@"OK"];
            });
        }
        [springBoardSocket close];
    });
}

- (void)showMoreWithCell:(ScriptListTableCell *)cell sender:(id)sender {
    NSIndexPath *indexPath = [_scriptListTableView indexPathForCell:cell];
    
    MoreOptionsPopOverTableViewController *contentVC = [[MoreOptionsPopOverTableViewController alloc] initWithFolderPath:scriptList[indexPath.row]];
    
    contentVC.modalPresentationStyle = UIModalPresentationPopover;
    [contentVC setUpperLevelViewController:self];
    UIPopoverPresentationController *popPC = contentVC.popoverPresentationController;
    popPC.permittedArrowDirections = UIPopoverArrowDirectionAny;
    //popPC.barButtonItem = sender;
    popPC.sourceView = sender;
    popPC.delegate = contentVC;
    [self presentViewController:contentVC animated:YES completion:nil];
}

- (void)refreshTable {
    if (_isScriptRoot && !_ip) {
        [self getWANIPAddress];
    }
    
    scriptList = [self updateScriptList];
    [_scriptListTableView reloadData];
    
    [refreshControl endRefreshing];
}


//配置每个section(段）有多少row（行） cell
//默认只有一个section
-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    return [scriptList count];
}


//每行显示什么东西
-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    //给每个cell设置ID号（重复利用时使用）
    static NSString *cellID = @"ScriptCell";

    //从tableView的一个队列里获取一个cell
    ScriptListTableCell *cell = [tableView dequeueReusableCellWithIdentifier:cellID];

    //判断队列里面是否有这个cell 没有自己创建，有直接使用
    if (cell == nil) {
        //没有,创建一个
        cell = [[ScriptListTableCell alloc]initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellID];
    }
    cell.delegate = self;
    NSString *path = scriptList[indexPath.row];
    cell.path = path;
    NSString *name = path.lastPathComponent;
    if ([builtin containsObject:name]) {
        cell.showMore = NO;
    } else {
        BOOL isDir = NO;
        [[NSFileManager defaultManager] fileExistsAtPath:path isDirectory:&isDir];
        cell.showMore = isDir || [[name pathExtension] isEqualToString:@"bdl"];
    }
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    BOOL isDir;
    
    NSString *path = scriptList[indexPath.row];
    [[NSFileManager defaultManager] fileExistsAtPath:path isDirectory:&isDir];
    
    if (isDir) {
        ScriptListViewController *scriptBundleContentViewController = [self.storyboard instantiateViewControllerWithIdentifier:@"scriptBundleContent"];
        
        [scriptBundleContentViewController setFolder:path];
        scriptBundleContentViewController.title = [path lastPathComponent];

        [self.navigationController pushViewController:scriptBundleContentViewController animated:YES];
        return;
    }
    
    NSArray *imageExts = @[@"jpg", @"png", @"JPG", @"PNG", @"jpeg", @"JPEG", @"GIF", @"gif"];
    NSString *ext = [path pathExtension];
    BOOL isImage = [imageExts containsObject:ext];
    
    if (isImage) {
        ImageViewerViewController *imageViewerController = [self.storyboard instantiateViewControllerWithIdentifier:@"imageViewer"];
        
        imageViewerController.title = [path lastPathComponent];
        imageViewerController.path = path;
        
        [self.navigationController pushViewController:imageViewerController animated:YES];
    } else {
        ScriptEditorViewController *scriptEditorViewController = [self.storyboard instantiateViewControllerWithIdentifier:@"fileContentEditor"];
        
        scriptEditorViewController.title = [path lastPathComponent];
        [scriptEditorViewController setFile:path];
        
        [self.navigationController pushViewController:scriptEditorViewController animated:YES];
    }
}


// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        //add code here for when you hit delete
        NSLog(@"delete button clicked for index path: %@", indexPath);
        // delete files in NSFileManager
        
        UIAlertController* alert = [UIAlertController alertControllerWithTitle:@"Alert"
                                       message:@"Are you sure you want to remove this file (folder)?"
                                       preferredStyle:UIAlertControllerStyleAlert];
         
        UIAlertAction* ok = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault
           handler:^(UIAlertAction * action) {NSError *err = nil;
            [[NSFileManager defaultManager] removeItemAtPath:self->scriptList[indexPath.row] error:&err];

            if (err)
            {
                NSLog(@"Error while removing file. Error: %@", err);
                UIAlertController* alert = [UIAlertController alertControllerWithTitle:@"Error"
                                               message:[NSString stringWithFormat:@"Error while deleting this file. Error message: %@", err]
                                               preferredStyle:UIAlertControllerStyleAlert];
                 
                UIAlertAction* defaultAction = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault
                   handler:^(UIAlertAction * action) {}];
                 
                [alert addAction:defaultAction];
                [self presentViewController:alert animated:YES completion:nil];
            }
            // delete element in our script list array
            [self->scriptList removeObjectAtIndex:indexPath.row];
            // reload table view
            [self.scriptListTableView reloadData];}];
        UIAlertAction* cancel = [UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleDefault
           handler:nil];
        
        [alert addAction:cancel];
        [alert addAction:ok];
        [self presentViewController:alert animated:YES completion:nil];
    }
}

@end
