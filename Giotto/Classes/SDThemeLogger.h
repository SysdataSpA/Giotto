

#import <UIKit/UIKit.h>

// This code is compatible with our logger "Blabber".
#define kThemeManagerLogModuleName @"Giotto"

#if BLABBER
#import <Blabber/SDLogger.h>
#else
#define SDLogError(frmt, ...)   NSLog(frmt, ##__VA_ARGS__)
#define SDLogWarning(frmt, ...) NSLog(frmt, ##__VA_ARGS__)
#define SDLogInfo(frmt, ...)    NSLog(frmt, ##__VA_ARGS__)
#define SDLogVerbose(frmt, ...) NSLog(frmt, ##__VA_ARGS__)
#define SDLogModuleError(mdl, frmt, ...)   NSLog(frmt, ##__VA_ARGS__)
#define SDLogModuleWarning(mdl, frmt, ...) NSLog(frmt, ##__VA_ARGS__)
#define SDLogModuleInfo(mdl, frmt, ...)    NSLog(frmt, ##__VA_ARGS__)
#define SDLogModuleVerbose(mdl, frmt, ...) NSLog(frmt, ##__VA_ARGS__)
#endif

