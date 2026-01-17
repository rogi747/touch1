@interface NSTask : NSObject
@property (nullable, copy) NSArray *arguments;
@property (nullable, copy) NSString *currentDirectoryPath;
@property (nullable, copy) NSDictionary *environment;
@property (nullable, copy) NSString *launchPath;
@property (readonly) int processIdentifier;
@property long long qualityOfService;
@property (getter=isRunning, readonly) bool running;
@property (nullable, retain) id standardError;
@property (nullable, retain) id standardInput;
@property (nullable, retain) id standardOutput;
@property (nullable, copy) id /* block */ terminationHandler;
@property (readonly) long long terminationReason;
@property (readonly) int terminationStatus;
+ (nullable id)currentTaskDictionary;
+ (nullable id)launchedTaskWithDictionary:(_Nullable id)arg1;
+ (nullable id)launchedTaskWithLaunchPath:(_Nullable id)arg1 arguments:(_Nullable id)arg2;
- (nullable id)init;
- (void)interrupt;
- (bool)isRunning;
- (void)launch;
- (int)processIdentifier;
- (long long)qualityOfService;
- (bool)resume;
- (bool)suspend;
- (void)waitUntilExit;
- (long long)suspendCount;
- (void)terminate;
- (nullable id /* block */)terminationHandler;
- (long long)terminationReason;
- (int)terminationStatus;

- (BOOL)launchAndReturnError:(out NSError *_Nullable *_Nullable)error;
@end
