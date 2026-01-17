//
//  ScriptEditorViewController.m
//  zxtouch
//
//  Created by Jason on 2020/12/17.
//

#import "ScriptEditorViewController.h"

@interface ScriptEditorViewController ()

@end

@implementation ScriptEditorViewController
{
    NSString *currentFilePath;
    BOOL isSaveButtonShown;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    NSError *error = nil;
    NSData *data = [NSData dataWithContentsOfFile:currentFilePath options:kNilOptions error:&error];
    NSString *content = nil;
    if (error) {
        content = error.description;
    } else if (data) {
        content = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
        if (!content && [currentFilePath.pathExtension isEqualToString:@"plist"]) { // bplist
            id obj = [NSPropertyListSerialization propertyListWithData:data options:NSPropertyListImmutable format:nil error:&error];
            if (error) {
                content = error.description;
            } else {
                NSData *newData = [NSPropertyListSerialization dataWithPropertyList:obj format:NSPropertyListXMLFormat_v1_0 options:0 error:&error];
                if (error) {
                    content = [obj description];
                } else {
                    content = [[NSString alloc] initWithData:newData encoding:NSUTF8StringEncoding];
                }
            }
        }
    }
    _textInput.text = content;
    isSaveButtonShown = NO;
}

- (void) setFile:(NSString*)file {
    currentFilePath = [file stringByStandardizingPath];
}

- (void) showSaveButton {
    if (!isSaveButtonShown)
    {
        UIBarButtonItem *save = [[UIBarButtonItem alloc] initWithTitle:@"Save"
                                         style:UIBarButtonItemStylePlain
                                        target:self
                                        action:@selector(saveFile)];
        
        [self.navigationItem setRightBarButtonItem:save animated:YES];
        isSaveButtonShown = YES;
    }
}

- (void) hideSaveButton {
    if (isSaveButtonShown)
    {
        [self.navigationItem setRightBarButtonItem:nil animated:YES];
        isSaveButtonShown = NO;
    }
}

- (void)textViewDidChange:(UITextView *)textView {
    [self showSaveButton];
}

- (void) saveFile {
    NSError *err = nil;
    [[_textInput text] writeToFile:currentFilePath atomically:YES encoding:NSUTF8StringEncoding error:&err];
    
    if (err)
    {
        NSLog(@"Error while saving file. Error: %@", err);
        UIAlertController* alert = [UIAlertController alertControllerWithTitle:@"Error"
                                       message:[NSString stringWithFormat:@"Error saving file. Error message: %@", err]
                                       preferredStyle:UIAlertControllerStyleAlert];
         
        UIAlertAction* defaultAction = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault
           handler:^(UIAlertAction * action) {}];
         
        [alert addAction:defaultAction];
        [self presentViewController:alert animated:YES completion:nil];
    }
    [self hideSaveButton];
}

@end
