#import <stdio.h>
#import <Foundation/Foundation.h>
#import <CoreFoundation/CoreFoundation.h>
#import <sys/socket.h>
#import <arpa/inet.h>
#import <unistd.h>
#import <string.h>
#import "NSTask.h"
#import "jbroot.h"

#define SPRINGBOARD_PORT 6000

extern "C"
CFNotificationCenterRef CFNotificationCenterGetDistributedCenter(void);

void subscribeSysNotification();
int getSpringboardSocket(void);
int executeCommand(NSString *command);
int playBackFromRawFile(NSString *file);

int main(int argc, char *argv[], char *envp[]) {
    subscribeSysNotification();
    
    // 保持运行
    CFRunLoopRun();
    
	return 0;
}

/*
int system3(const char * command) {
    int p_stdin[2];
    int p_stdout[2];
    pid_t pid;
    
    if (pipe(p_stdin) == -1)
        return -1;
    
    if (pipe(p_stdout) == -1) {
        close(p_stdin[0]);
        close(p_stdin[1]);
        return -1;
    }
    
    pid = fork();
    
    if (pid < 0) {
        close(p_stdin[0]);
        close(p_stdin[1]);
        close(p_stdout[0]);
        close(p_stdout[1]);
        return pid;
    } else if (pid == 0) {
        close(p_stdin[1]);
        dup2(p_stdin[0], 0);
        close(p_stdout[0]);
        dup2(p_stdout[1], 1);
        dup2(open("/dev/null", O_RDONLY), 2);
        /// Close all other descriptors for the safety sake.
        for (int i = 3; i < 4096; ++i)
            close(i);
        
        pid_t ret = setsid();
        
        NSString *string = [NSString stringWithFormat:@"'%s'", command];
        NSLog(@"com.zjx.zxtouch ret: %d %s", ret, string.UTF8String);
        execl("/var/jb/usr/bin/sh", "sh", "-c", string.UTF8String, NULL);
        _exit(1);
    }
    
    close(p_stdin[0]);
    close(p_stdout[1]);
    
    if (pid > 0)
    {
        waitpid(pid, NULL, 0);
    }
    return pid;
}
*/

static void callback(CFNotificationCenterRef center,
                     void *observer,
                     CFStringRef name,
                     const void *object,
                     CFDictionaryRef userInfo) {
    NSLog(@"com.zjx.zxtouchd object: %@ userInfo: %@", object, userInfo);
    if (userInfo) {
        NSString *command = (__bridge NSString *)(object);
        
        if (command) {
            if ([command hasPrefix:@"zxtouchb -e"]) { // 执行命令行
                NSString *cmd = [command stringByReplacingOccurrencesOfString:@"zxtouchb -e " withString:@""];
                executeCommand(cmd);
            } else if ([command hasPrefix:@"zxtouchb -pr"]) { // 执行raw file
                NSString *cmd = [command stringByReplacingOccurrencesOfString:@"zxtouchb -pr " withString:@""];
                playBackFromRawFile(cmd);
            } else {
                NSLog(@"com.zjx.zxtouchd: unsupported action: %@", command);
            }
        }
    }
}

void subscribeSysNotification() {
    /*
     可以使用DarwinNotifyCenter也可以使用DistributedCenter，但是需要两边一致
     CFNotificationCenterGetDarwinNotifyCenter();   //对iOS是私有
     CFNotificationCenterGetDistributedCenter();    //对iOS是公有
     */
    CFNotificationCenterRef distributedCenter = CFNotificationCenterGetDistributedCenter();
    CFNotificationSuspensionBehavior behavior = CFNotificationSuspensionBehaviorDeliverImmediately;
    CFNotificationCenterAddObserver(distributedCenter,
                                    NULL,
                                    callback,
                                    CFSTR("com.zjx.zxtouch.to.d"),
                                    NULL,
                                    behavior);
}

int executeCommand(NSString *command) {
    NSLog(@"com.zjx.zxtouchd: command to run: %@", command);
    NSArray *comps = [command componentsSeparatedByString:@"\\\""];
    
    @autoreleasepool {
        NSTask *task = [[NSTask alloc] init];
        NSString *cmd = comps[1];
        // 设置执行的命令和参数
        [task setLaunchPath:JBROOT_PATH_OC("/usr/bin/python3")];
        [task setArguments:@[cmd]];
        
        NSLog(@"executeCommand %@", task);
        // 启动任务
        NSError *error = nil;
        [task launchAndReturnError:&error];
        if (error) {
            NSLog(@"com.zjx.zxtouchd: launch error %@", error);
        }
    }
    
    return 0;
}

int playBackFromRawFile(NSString *filepath) {
    NSLog(@"com.zjx.zxtouchd: execute file: %@", filepath);
    int sbSocket = getSpringboardSocket();
    
    FILE *file = fopen([filepath UTF8String], "r");
    
    char buffer[256] = {};
    int taskType = 0;
    int sleepTime = 0;
    size_t size = sizeof(char) * 256;
    while (fgets(buffer, size, file) != NULL){
        //NSLog(@"sleep: %s",buffer);
        
        sscanf(buffer, "%2d%d", &taskType, &sleepTime);
        if (taskType == 18) {
            //[NSThread sleepForTimeInterval:sleepTime/1000000];
            usleep(sleepTime/2);
        } else {
            send(sbSocket , buffer, strlen(buffer) , 0);
        }
    }
    
    return 0;
}

int getSpringboardSocket(void) {
    int sock = 0;
    struct sockaddr_in serv_addr;
    
    if ((sock = socket(AF_INET, SOCK_STREAM, 0)) < 0)
    {
        NSLog(@"### com.zjx.zxtouchb:  Socket creation error");
        return -1;
    }
    
    serv_addr.sin_family = AF_INET;
    serv_addr.sin_port = htons(SPRINGBOARD_PORT);
    
    // Convert IPv4 and IPv6 addresses from text to binary form
    if(inet_pton(AF_INET, "127.0.0.1", &serv_addr.sin_addr)<=0)
    {
        NSLog(@"### com.zjx.zxtouchb: Invalid address. Address not supported");
        return -1;
    }
    
    if (connect(sock, (struct sockaddr *)&serv_addr, sizeof(serv_addr)) < 0)
    {
        NSLog(@"### com.zjx.zxtouchb: \nConnection Failed \n");
        return -1;
    }
    
    return sock;
}
