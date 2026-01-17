#include "Common.h"
#include "Config.h"
#import <sys/utsname.h>
#include "NSTask.h"
#include <ftw.h>
#import <dlfcn.h>
#import <sys/socket.h>
#import <arpa/inet.h>
#import <unistd.h>
#import <string.h>
#include "jbroot.h"
#include "util.h"
#include <spawn.h>
#import <CoreFoundation/CoreFoundation.h>

int unlink_cb(const char *fpath, const struct stat *sb, int typeflag, struct FTW     *ftwbuf)
{
    int rv = remove(fpath);
    
    if (rv)
        perror(fpath);
    
    return rv;
}

/*
Get device model name
*/
NSString* getDeviceName()
{
    struct utsname systemInfo;
    uname(&systemInfo);

    return [NSString stringWithCString:systemInfo.machine
                                encoding:NSUTF8StringEncoding];
}

/*
round up number by multiple of another number
*/
int roundUp(int numToRound, int multiple)
{
    if (multiple == 0)
        return numToRound;

    int remainder = numToRound % multiple;
    if (remainder == 0)
        return numToRound;

    return numToRound + multiple - remainder;
}

/*
Check whether current device is an iPad
*/
Boolean isIpad()
{
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad)
    {
        return YES;
    }
    return NO;
}

/*
generate a random integer between min and max.

ONLY POSITIVE NUMBER IS SUPPORTED!
*/
int getRandomNumberInt(int min, int max)
{
	min = abs(min);
	max = abs(max);

	if (max < min)
	{
		NSLog(@"### com.zjx.springboard: Max is less than min in getRandomNumberInt(). max: %d, min: %d", max, min);
	}
	return arc4random_uniform(abs(max-min)) + min;
}

/*
generate a random float between min and max.

ONLY POSITIVE NUMBER IS SUPPORTED!
ONLY SUPPORTS TO UP TO 5 DIGIT.
*/
float getRandomNumberFloat(float min, float max)
{
	min = abs(min);
	max = abs(max);

	if (max < min)
	{
		NSLog(@"### com.zjx.springboard: Max is less than min in getRandomNumberFloat(). max: %f, min: %f", max, min);
	}

	
	return getRandomNumberInt((int)(min*10000), (int)(max*10000))/10000.0f;
}

/**
Get document root of springboard
*/
NSString* getDocumentRoot()
{
    //NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    return [NSString stringWithFormat:@"%s/%s/", JBROOT_PATH("/var/mobile/Library"), DOCUMENT_ROOT_FOLDER_NAME];
}

/**
Get scripts path
*/
NSString* getScriptsFolder()
{
    //NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    return [NSString stringWithFormat:@"%@/%s/", getDocumentRoot(), SCRIPT_FOLDER_NAME];
}

/**
Get config dir
*/
NSString *getConfigFilePath()
{
	return [getDocumentRoot() stringByAppendingPathComponent:@CONFIG_FOLDER_NAME];
}

NSString *getCommonConfigFilePath()
{
    return [getConfigFilePath() stringByAppendingPathComponent:@COMMON_CONFIG_NAME];
}

void swapCGFloat(CGFloat *a, CGFloat *b)
{
	CGFloat temp = *a;
	*a = *b;
	*b = temp;
}

pid_t system2(const char * command, int * infp, int * outfp)
{
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
        dup2(::open("/dev/null", O_RDONLY), 2);
        /// Close all other descriptors for the safety sake.
        for (int i = 3; i < 4096; ++i)
            ::close(i);

        setsid();
        execl(JBROOT_PATH("/bin/sh"), "sh", "-c", command, NULL);
        _exit(1);
    }

    close(p_stdin[0]);
    close(p_stdout[1]);

    if (infp == NULL) {
        close(p_stdin[1]);
    } else {
        *infp = p_stdin[1];
    }

    if (outfp == NULL) {
        close(p_stdout[0]);
    } else {
        *outfp = p_stdout[0];
    }

    if (pid > 0)
    {
        waitpid(pid, NULL, 0);
    }
    return pid;
}

extern "C"
CFNotificationCenterRef CFNotificationCenterGetDistributedCenter(void);
extern "C"
void CFNotificationCenterPostNotification(CFNotificationCenterRef center, CFNotificationName name, const void *object, CFDictionaryRef userInfo, Boolean deliverImmediately);
void postSysNotification(const char *message) {
    /*
     可以使用DarwinNotifyCenter也可以使用DistributedCenter，但是需要两边一致
     CFNotificationCenterGetDarwinNotifyCenter();   //对iOS是私有
     CFNotificationCenterGetDistributedCenter();    //对iOS是公有
     CFNotificationCenterPostNotification的文档(option + 单击)说明，
     如果使用DarwinNotifyCenter，后三个参数都被忽略
     */
    CFNotificationCenterRef distributedCenter = CFNotificationCenterGetDistributedCenter();
    /*
     App extension里使用时，设置userinfo，如果对方收不到通知的话，可以用object来传递数据。
     userinfo里有swift对象、枚举等时，对方收不到通知
     对于DistributedCenter，object只能是字符串，见文档(option + 单击)
     */
    CFStringRef object = CFStringCreateWithCString(NULL, message, kCFStringEncodingUTF8);
    CFNotificationCenterPostNotification(distributedCenter,
                                         CFSTR("com.zjx.zxtouch.to.d"),
                                         (const void *)object,
                                         (CFDictionaryRef)CFBridgingRetain(@{@"test": [NSString stringWithUTF8String:message]}),      //userInfo
                                         true);
}

#define SPRINGBOARD_PORT 6000
int getSpringboardSocket(void);
int executeCommand(NSString *command);
int playBackFromRawFile(NSString *file);
void zx_excute_cmd(const char * command);

int system3(const char * command) {
    // 在守护进程中执行
    //postSysNotification(command);

    // 在本进程中执行
    zx_excute_cmd(command);

    return 0;
}

void zx_excute_cmd(const char * arg) {
    NSLog(@"com.zjx.springboard command: %s", arg);
    NSString *command = [NSString stringWithUTF8String:arg];
    
    if (command) {
        if ([command hasPrefix:@"zxtouchb -e"]) { // 执行命令行
            NSString *cmd = [command stringByReplacingOccurrencesOfString:@"zxtouchb -e " withString:@""];
            executeCommand(cmd);
        } else if ([command hasPrefix:@"zxtouchb -pr"]) { // 执行raw file
            NSString *cmd = [command stringByReplacingOccurrencesOfString:@"zxtouchb -pr " withString:@""];
            playBackFromRawFile(cmd);
        } else {
            NSLog(@"com.zjx.springboard: unsupported action: %@", command);
        }
    }
}

int executeCommand(NSString *command) {
    NSLog(@"com.zjx.springboard: command to run: %@", command);
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
            NSLog(@"com.zjx.springboard: launch error %@", error);
        }
        [task waitUntilExit];
    }
    
    return 0;
}

int playBackFromRawFile(NSString *filepath) {
    NSLog(@"com.zjx.springboard: execute file: %@", filepath);
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
        NSLog(@"### com.zjx.springboard:  Socket creation error");
        return -1;
    }
    
    serv_addr.sin_family = AF_INET;
    serv_addr.sin_port = htons(SPRINGBOARD_PORT);
    
    // Convert IPv4 and IPv6 addresses from text to binary form
    if(inet_pton(AF_INET, "127.0.0.1", &serv_addr.sin_addr)<=0)
    {
        NSLog(@"### com.zjx.springboard: Invalid address. Address not supported");
        return -1;
    }
    
    if (connect(sock, (struct sockaddr *)&serv_addr, sizeof(serv_addr)) < 0)
    {
        NSLog(@"### com.zjx.springboard: \nConnection Failed \n");
        return -1;
    }
    
    return sock;
}
