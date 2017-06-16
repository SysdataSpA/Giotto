# Blabber

[![Version](https://img.shields.io/cocoapods/v/Blabber.svg?style=flat)](http://cocoapods.org/pods/Blabber)
[![License](https://img.shields.io/cocoapods/l/Blabber.svg?style=flat)](http://cocoapods.org/pods/Blabber)
[![Platform](https://img.shields.io/cocoapods/p/Blabber.svg?style=flat)](http://cocoapods.org/pods/Blabber)

## Example

To run the example project, clone the repo, and run `pod install` from the Example directory first.

## Requirements
iOS 8 and above

## Installation

Docker is available through [CocoaPods](http://cocoapods.org). To install
it, simply add the following line to your Podfile:

```ruby
pod "Blabber"
```
If you want to manage your logs with CocoaLumberjack use subpod
```ruby
pod "Blabber/CocoaLumberjack"
```

## License

Blabber is available under the Apache license. See the LICENSE file for more info.

## Introduction
Blabber is a library that provides a common wrapper to our each library (ex. [Docker](https://github.com/SysdataSpA/Docker), [Umarell](https://github.com/SysdataSpA/Umarell), ...) to log messages with different filter levels.
By default it writes all messages (depending about filter level set) with NSLog.
You can also use **SDLoggerDelegate** protocol, set as logger delegate and manage your messages implementing method `logger:didReceiveLogWithLevel:syncMode:module:file:function:line:format:arguments:`

Otherwise if you want to use **CocoaLumberjack** to log your messages you can use the subpod **Blabber/CocoaLumberjack**.

### Define your log module
If you want to define a specific log module (ex. in your private pod), you can use **SDLoggerModuleProtocol**

```
- (NSString*) loggerModuleName
{
    return "your module name";
}

- (SDLogLevel) loggerModuleLogLevel
{
    return [[SDLogger sharedLogger] logLevelForModuleWithName:self.loggerModuleName];
}

- (void) setLoggerModuleLogLevel:(SDLogLevel)level
{
    [[SDLogger sharedLogger] setLogLevel:level forModuleWithName:self.loggerModuleName];
}

```


