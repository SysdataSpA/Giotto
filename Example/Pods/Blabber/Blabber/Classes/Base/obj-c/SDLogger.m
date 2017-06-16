// Copyright 2016 Sysdata Digital
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

#import "SDLogger.h"
#if COCOALUMBERJACK
#import "DDLog.h"
#import "SDDDFormatter.h"
#endif

#define kGenericModuleName  @"SDLogger.Generic"

@interface SDLoggerUtils : NSObject

#if COCOALUMBERJACK
+ (DDLogLevel)ddLogLevelFromSDLogLevel:(SDLogLevel)level;
+ (DDLogFlag)ddLogFlagFromSDLogLevel:(SDLogLevel)level;
#endif

@end

@implementation SDLoggerUtils


#if COCOALUMBERJACK
/**
 *  utility method to convert SDLogLevel into corresponding DDLogLevel
 */
+ (DDLogLevel)ddLogLevelFromSDLogLevel:(SDLogLevel)level
{
    switch (level)
    {
        case SDLogLevelVerbose:
        {
            return DDLogLevelVerbose;
        }
        case SDLogLevelInfo:
        {
            return DDLogLevelInfo;
        }
        case SDLogLevelWarning:
        {
            return DDLogLevelWarning;
        }
        case SDLogLevelError:
        {
            return DDLogLevelError;
        }
    }
}

/**
 *  utility to convert SDLogLevel into corresponding DDLogFlag
 */
+ (DDLogFlag)ddLogFlagFromSDLogLevel:(SDLogLevel)level
{
    switch (level)
    {
        case SDLogLevelVerbose:
        {
            return DDLogFlagVerbose;
        }
        case SDLogLevelInfo:
        {
            return DDLogFlagInfo;
        }
        case SDLogLevelWarning:
        {
            return DDLogFlagWarning;
        }
        case SDLogLevelError:
        {
            return DDLogFlagError;
        }
    }
}

#endif

@end


@interface SDLogModuleSetting ()

/**
 *  keys: SDLogLevel wrapped in NSNumber; values: BOOL wrapped in NSNumber
 */
@property (nonatomic, strong) NSMutableDictionary *asyncModeByLevel;

/**
 *  value used by logger DDTTYLogger differentiate colors to use
 */
@property (nonatomic, assign) NSInteger context;
@end

@implementation SDLogModuleSetting

- (instancetype) initWithModuleName:(NSString*)name context:(NSInteger)context
{
    self = [super init];
    if (self)
    {
        _moduleName = name;
        _context = context;
        
        _asyncModeByLevel = [[NSMutableDictionary alloc] initWithObjectsAndKeys:@NO, @(SDLogLevelError), @YES, @(SDLogLevelWarning), @YES, @(SDLogLevelVerbose), nil];
#if DEBUG
        _logLevel = SDLogLevelVerbose;
#else
        _logLevel = SDLogLevelError;
#endif
    }
    return self;
}

- (void)setUseAsyncLog:(BOOL)useAsync forLogLevel:(SDLogLevel)logLevel
{
    [self.asyncModeByLevel setObject:@(useAsync) forKey:@(logLevel)];
}

- (BOOL)useAsyncLogForLogLevel:(SDLogLevel)logLevel
{
    return [self.asyncModeByLevel[@(logLevel)] boolValue];
}

@end

@interface SDLogger ()
{
    /**
     *  structure to keep module informations.
     *
     *  keys: module names; values: SDLogModuleSetting
     */
    NSMutableDictionary <NSString*, SDLogModuleSetting*> *settingsByModule;
}

@end

@implementation SDLogger

+ (instancetype) sharedLogger
{
    static dispatch_once_t pred;
    static id sharedLoggerInstance_ = nil;
    
    dispatch_once(&pred, ^{
        sharedLoggerInstance_ = [[self alloc] init];
    });
    
    return sharedLoggerInstance_;
}

- (instancetype)init
{
    self = [super init];
    if (self)
    {
        settingsByModule = [[NSMutableDictionary alloc] init];
    }
    return self;
}

- (void)setup
{
    [self setupWithLoggers:nil];
}

- (void) setupWithLoggers:(NSArray*)loggers
{
#if COCOALUMBERJACK
    // default setup
    if (loggers.count == 0)
    {
        // Formatter
        SDDDFormatter *formatter = [[SDDDFormatter alloc] init];
        
        [[DDTTYLogger sharedInstance] setLogFormatter:formatter];
        
        // Logger to log into file
        NSArray* paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
        NSString* logsDirectory = [paths.firstObject stringByAppendingPathComponent:@"Logs"];
        DDLogFileManagerDefault* logFileManagerDefault = [[DDLogFileManagerDefault alloc]initWithLogsDirectory:logsDirectory];
        
        DDFileLogger* fileLogger = [[DDFileLogger alloc] initWithLogFileManager:logFileManagerDefault];
        fileLogger.rollingFrequency = 60 * 60 * 24;// 24 hour rolling
        fileLogger.logFileManager.maximumNumberOfLogFiles = 7;
        [fileLogger setLogFormatter:formatter];
        
        loggers = @[[DDASLLogger sharedInstance], [DDTTYLogger sharedInstance], fileLogger];
    }
    
    for (id<DDLogger> logger in loggers)
    {
        [DDLog addLogger:logger];
    }
#endif
    
    // default levels for generic logger.
    // levels should be set after DDTTYLogger creation to use XcodeColors.
#if DEBUG
    self.genericLogLevel = SDLogLevelVerbose;
#else
    self.genericLogLevel = SDLogLevelError;
#endif
}

- (void)setGenericLogLevel:(SDLogLevel)genericLogLevel
{
    _genericLogLevel = genericLogLevel;
    [self setLogLevel:genericLogLevel forModuleWithName:kGenericModuleName];
}

- (void)setLogLevel:(SDLogLevel)level forModuleWithName:(NSString *)module
{
    SDLogModuleSetting *setting = settingsByModule[module];
    if (!setting)
    {
        NSInteger context = [settingsByModule.allKeys count]+1;
        setting = [[SDLogModuleSetting alloc] initWithModuleName:module context:context];
        settingsByModule[module] = setting;
    }
    
    setting.logLevel = level;
}

- (SDLogLevel)logLevelForModuleWithName:(NSString *)module
{
    SDLogModuleSetting *setting = settingsByModule[module];
    if (setting)
    {
        return setting.logLevel;
    }
    return self.genericLogLevel;
}

- (SDLogModuleSetting *)moduleWithName:(NSString *)module
{
    return settingsByModule[module];
}

#pragma mark - Log

- (void) logWithLevel:(SDLogLevel)level module:(NSString *)module file:(NSString *)file function:(NSString*)function line:(NSUInteger)line format:(NSString *)format, ...
{
    // Log with CocoaLumberjack
    va_list args;
    if (format)
    {
        va_start(args, format);
        
        [self logWithLevel:level
                    module:module
                      file:file
                  function:function
                      line:line
                    format:format
                 arguments:args];
        
        va_end(args);
    }
}
- (void) logWithLevel:(SDLogLevel)level module:(NSString *)module file:(NSString *)file function:(NSString*)function line:(NSUInteger)line format:(NSString *)format arguments:(va_list)arguments;
{
    SDLogModuleSetting *setting = nil;
    SDLogLevel filterLevel = self.genericLogLevel;
    
    // In absence of module, fallback on generic module
    if (module.length == 0)
    {
        module = kGenericModuleName;
    }
    
    setting = settingsByModule[module];
    if (!setting)
    {
        setting = settingsByModule[kGenericModuleName];
    }
    
    filterLevel = setting.logLevel;
    
    // log is synchronous if corresponding settings enable it or if is anble the global flag.
    BOOL syncLog = (![setting useAsyncLogForLogLevel:level] || self.forceSyncLogs);
    
    // log levels more verbose have lower values, so if log level of module is grater than log level of message this be missed.
    if (level < filterLevel)
    {
        return;
    }
    
    // Log with CocoaLumberjack
    if (format)
    {
#if COCOALUMBERJACK
        [DDLog log:!syncLog
             level:[SDLoggerUtils ddLogLevelFromSDLogLevel:level]
              flag:[SDLoggerUtils ddLogFlagFromSDLogLevel:level]
           context:setting.context
              file:[file cStringUsingEncoding:NSUTF8StringEncoding]
          function:[function cStringUsingEncoding:NSUTF8StringEncoding]
              line:line
               tag:nil
            format:format
              args:arguments];
#else
        if([self.delegate respondsToSelector:@selector(logger:didReceiveLogWithLevel:syncMode:module:file:function:line:format:arguments:)])
        {
            [self.delegate logger:self didReceiveLogWithLevel:level syncMode:syncLog module:module file:file function:function line:line format:format arguments:arguments];
        }
        else
        {
            NSString *message = [[NSString alloc] initWithFormat:format arguments:arguments];
            NSLog(@"%@",message);
        }
        
#endif
    }
}

- (void)logWithLevel:(SDLogLevel)level module:(NSString *)module file:(NSString *)file function:(NSString *)function line:(NSUInteger)line message:(NSString *)message
{
    [self logWithLevel:level module:module file:file function:function line:line format:message, nil];
}


@end
