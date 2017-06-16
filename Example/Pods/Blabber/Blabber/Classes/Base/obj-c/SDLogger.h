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

#import <Foundation/Foundation.h>
#ifdef COCOALUMBERJACK
#import <CocoaLumberjack/CocoaLumberjack.h>
#endif

/**
 *  log levels for SDLogger.
 */
typedef NS_ENUM (NSUInteger, SDLogLevel)
{
    SDLogLevelVerbose = 1,
    SDLogLevelInfo,
    SDLogLevelWarning,
    SDLogLevelError
};

@class SDLogger;
@protocol SDLoggerDelegate <NSObject>

@optional
- (void) logger:(SDLogger* _Nonnull)logger didReceiveLogWithLevel:(SDLogLevel)level syncMode:(BOOL)syncMode module:(NSString *_Nullable)module file:(NSString *_Nullable)file function:(NSString* _Nullable)function line:(NSUInteger)line format:(NSString * _Nullable)format arguments:(va_list)arguments;

@end


@protocol SDLoggerModuleProtocol <NSObject>

- (NSString* _Nullable) loggerModuleName;
- (SDLogLevel) loggerModuleLogLevel;
- (void) setLoggerModuleLogLevel:(SDLogLevel)level;

@end

/**
 *  Class that holds all settings for an SDLogger module.
 */
@interface SDLogModuleSetting : NSObject

/**
 *  Default `init` is not available
 */
- (instancetype _Nonnull)init NS_UNAVAILABLE;

/**
 *  name of mudule.
 */
@property (nonatomic, strong) NSString * _Nullable moduleName;

/**
 *  log level of module.
 */
@property (nonatomic, assign) SDLogLevel logLevel;

/**
 *  Set print log to async mode. This will be faster, but could mesh log (order could be wrong)
 *
 *  @param useAsync flag to manage the async print.
 *  @param logLevel log level.
 */
- (void) setUseAsyncLog:(BOOL)useAsync forLogLevel:(SDLogLevel)logLevel;

/**
 *  Return the async state for a given log level.
 *
 *  @param logLevel log level.
 *
 *  @return YES if module print logs in asynchronous mode, NO otherwise.
 */
- (BOOL) useAsyncLogForLogLevel:(SDLogLevel)logLevel;

@end

/**
 *  Singleton to handle all log modules.
 */
@interface SDLogger : NSObject


@property (nonatomic, weak) id <SDLoggerDelegate> _Nullable delegate;

/**
 *  log level for all logs that are not associated to a specific module.
 *
 *  Default values: SDLogLevelVerbose for DEBUG, SDLogLevelError for RELEASE
 */
@property (nonatomic, assign) SDLogLevel genericLogLevel;

/**
 *  flag to enable all modules in synchronous mode. It will be usefull in debug, because oreder will be respect.
 *
 *  Default: NO.
 */
@property (nonatomic, assign) BOOL forceSyncLogs;


/**
 *  method that instantiate the shared instance.
 */
+ (instancetype _Nonnull) sharedLogger;

/**
 *  defualt method to setup loggers.
 *
 * Default loggers are:
 *
 *  -   DDASLLogger: to log on Apple System Log Facility.
 *
 *  -   DDTTYLogger: to log in console. This logger uses SDDDFormatter to format the logged message.
 *
 *  -   DDFileLogger: to log on file system, set with 24 hours rolling frequency and 7 max number of saved files in Documents/Logs folder. Uses SDDDFormatter to format the logged message.
 */
- (void) setup;

/**
 *  setup with specific loggers. passing 'nil' it will give the same effect of 'setup' method.
 *
 *  @param loggers loggers to use. This objects should implement `DDLogger´ protocol.
 */
- (void) setupWithLoggers:(NSArray* _Nullable)loggers;

/**
 * set log level for a specific module.
 *
 *  @discussion if the given module name doesn't exist, this will be instantiate.
 *
 *  @param level  log level.
 *  @param module module name.
 */
- (void) setLogLevel:(SDLogLevel)level forModuleWithName:(NSString* _Nonnull)module;

/**
 *  return log level for a specific module.
 *
 *  @param module module name.
 *
 *  @return log level.
 */
- (SDLogLevel) logLevelForModuleWithName:(NSString* _Nonnull)module;

/**
 *  return `SDLogModuleSetting´ isntance that handle all infos abuot a specific module.
 *
 *  @param module module name.
 *
 *  @return module settings if exists, otherwise `nil´.
 */
- (SDLogModuleSetting* _Nullable)moduleWithName:(NSString* _Nonnull)module;

/**
 *  method to log a single message.
 *
 *
 *
 *  @param level    log level.
 *  @param module   associated module if exists, 'nil' for generic logs.
 *  @param file     file name that requires log. Use `__FILE__´ to retreive it.
 *  @param function function mane that requires log. Use `__PRETTY_FUNCTION__´ to retreive it.
 *  @param line     number of line that requires log. Use `__LINE__´ to retreive it.
 *  @param format   format of message.
 */
- (void)logWithLevel:(SDLogLevel)level
              module:(NSString* _Nullable)module
                file:(NSString* _Nonnull)file
            function:(NSString* _Nonnull)function
                line:(NSUInteger)line
              format:(NSString *_Nullable)format, ...NS_FORMAT_FUNCTION(6,7);


- (void)logWithLevel:(SDLogLevel)level
              module:(NSString* _Nullable)module
                file:(NSString* _Nonnull)file
            function:(NSString* _Nonnull)function
                line:(NSUInteger)line
              format:(NSString * _Nullable)format
           arguments:(va_list)arguments;

- (void)logWithLevel:(SDLogLevel)level
              module:(NSString* _Nullable)module
                file:(NSString* _Nonnull)file
            function:(NSString* _Nonnull)function
                line:(NSUInteger)line
             message:(NSString * _Nullable)message;

@end

/**
 *  Define to call log message method
 
 *  @param lvl  log level.
 *  @param mdl  associated module if exists, 'nil' for generic logs.
 *  @param fnct file name that requires log. Use `__FILE__´ to retreive it.
 *  @param frmt format of message.
 *  @param ...  parameters of format.
 */
#define SD_LOG_MACRO(lvl, mdl, fnct, frmt, ...) [[SDLogger sharedLogger] logWithLevel: lvl module: mdl file:[NSString stringWithUTF8String:__FILE__] function:[NSString stringWithUTF8String:fnct] line:__LINE__ format:(frmt), ## __VA_ARGS__]


/**
 *  functions to log message associated to a module with different SDLogLevel.
 *
 *  @param mdl  module name.
 *  @param frmt format of message.
 *  @param ...  parameters of format.
 */

#define SDLogModuleError(mdl, frmt, ...)   SD_LOG_MACRO(SDLogLevelError, mdl, __PRETTY_FUNCTION__, frmt, ## __VA_ARGS__)
#define SDLogModuleWarning(mdl, frmt, ...)   SD_LOG_MACRO(SDLogLevelWarning, mdl, __PRETTY_FUNCTION__, frmt, ## __VA_ARGS__)
#define SDLogModuleInfo(mdl, frmt, ...)   SD_LOG_MACRO(SDLogLevelInfo, mdl, __PRETTY_FUNCTION__, frmt, ## __VA_ARGS__)
#define SDLogModuleVerbose(mdl, frmt, ...)   SD_LOG_MACRO(SDLogLevelVerbose, mdl, __PRETTY_FUNCTION__, frmt, ## __VA_ARGS__)

/**
 *  function to log a generic message (not associated to specific module).
 *
 *  @param frmt format of message.
 *  @param ...  parameters of format.
 */

#define SDLogError(frmt, ...)   SD_LOG_MACRO(SDLogLevelError, nil, __PRETTY_FUNCTION__, frmt, ## __VA_ARGS__)
#define SDLogWarning(frmt, ...)   SD_LOG_MACRO(SDLogLevelWarning, nil, __PRETTY_FUNCTION__, frmt, ## __VA_ARGS__)
#define SDLogInfo(frmt, ...)   SD_LOG_MACRO(SDLogLevelInfo, nil, __PRETTY_FUNCTION__, frmt, ## __VA_ARGS__)
#define SDLogVerbose(frmt, ...)   SD_LOG_MACRO(SDLogLevelVerbose, nil, __PRETTY_FUNCTION__, frmt, ## __VA_ARGS__)


