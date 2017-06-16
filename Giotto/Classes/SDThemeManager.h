// Copyright 2017 Sysdata S.p.A.
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

#import <UIKit/UIKit.h>
#import "SDThemeLogger.h"

#pragma mark - THEME MANAGER

#define themeIntForKey(key) \
[[SDThemeManager sharedManager] themeIntegerForKey: key]

#define themeFloatForKey(key) \
[[SDThemeManager sharedManager] themeFloatForKey: key]

#define themeNumberForKey(key) \
[[SDThemeManager sharedManager] themeNumberForKey: key]

#define themeValueForKey(key) \
[[SDThemeManager sharedManager] valueForKey: key]

#define themeColorForKey(key) \
[[SDThemeManager sharedManager] themeColorForKey: key]

#define themeFontForKeyAndSize(key, size) \
[[SDThemeManager sharedManager] themeFontForKey: key andSize: size]

@class SDThemeManager;

SDThemeManager* themeManagerSharedInstance();

id SDThemeManagerValueForConstant(NSString* key);

void SDThemeManagerApplyStyle (NSString* key, NSObject* object);

#define THEME_DEFAULT_PLIST_NAME @"theme_default"

/**
 
 * This class allows you to manage key files with key / value logic and some utility to access values ​​by typing them (UIColor, int, float, NSNumber)
 * Must always be a default theme (theme_default.plist)
 * You can specify multiple theme files in order of priority using setAlternativeThemes: and specifying an array of NSString, names of different plist files
 * To modify the logic of access to themes, for example, by specifying events or specific states (eg Logged / Un Logged), you need to overwrite the valueForKey motto:
 *
 * We recommend using the ReflectableEnum library - https://github.com/fastred/ReflectableEnum - to have comfortably key theme names in order to avoid creating a million definitions (see the Zoppas Stone project for reference). Specifically, create an ENUM by typology (colors, images, dimensions, fonts, ...)
 * To access the value contained in the theme file, you must specify a key
 */


#if BLABBER
@interface SDThemeManager : NSObject <SDLoggerModuleProtocol>
#else
@interface SDThemeManager : NSObject
#endif


/**
 * Invoking this method allows you to use alternative themes other than the default one, which should be specified in the theme theme_default.plist
 *
 * @param alternativeThemes array containing the sorted plist names containing alternative versions of the themes, without any extensions; The key of each value will be searched first inside them, in the order in which they were inserted and, finally, in the default theme
 */
- (void) setAlternativeThemes:(NSArray<NSString*>*)alternativeThemes;

+ (instancetype) sharedManager;

#pragma mark - Old methods for retro-compatibility
/**
 * This method accesses all others to retrieve information from theme files
 * Overwrite it to customize access to topics by binding it to specific events or states (eg Logged / Not Logged In)
 *
 * @param key to search in the theme file
 *
 * @return the value corresponding to the key
 */
- (id) valueForKey:(NSString*)key;
- (UIColor*) themeColorForKey:(NSString*)key __deprecated;
- (UIFont*) themeFontForKey:(NSString*)key andSize:(CGFloat)fontSize __deprecated;
- (NSNumber*) themeNumberForKey:(NSString*)key __deprecated;
- (float) themeFloatForKey:(NSString*)key __deprecated;
- (int) themeIntegerForKey:(NSString*)key __deprecated;



#pragma mark - New methods
/**
 * This method is only used if you define the theme plist with the Constants-Styles-Interfaces structure.
 *
 * @param styleName The name of a plist Styles dictionary or Interfaces element.
 * @param object The object to which the theme is to be applied
 */
- (void) applyStyleWithName:(NSString*)styleName toObject:(NSObject*)object;

/**
 * Utility method to retrieve the value associated with a constant.
 *
 * @param constantName Name of a constant.
 *
 * @return The value associated with the constant or nil if the constant does not exist.
 */
- (id) valueForConstantWithName:(NSString*)constantName;

#pragma mark Utils


/**
 * Debug method that returns the merged dictionary for a given style. It shows alla merged values as you aspect to be performed when the style will be applied. The dictionary is merged following the inheritance and the superstyle chain.
 *
 * @param style name of the style
 *
 * @return the merged dictionary for a given style
 */

- (NSDictionary*) mergedValueForStyle:(NSString*)style;


#pragma mark Dynamic behaviour

/**
 *
 *  The following methods can change the theme and constant values ​​in a programmatic way.
 *
 */



/**
 *  Modifies the value of a constant in a programmatic way. 
 *  The change will only take effect for the duration of the app session. If you want to see the modify also after restarting the app, persist the modifies using synchronizeModifies method
 *
 * @param constant the name of the constant you want to modify
 * @param value the new value for the constant (allowed types: NSString, NSNumber)
 */
- (void) modifyConstant:(NSString*)constant withValue:(id)value;

/**
*  Modifies the value for a style at a given path in a programmatic way.
*  The change will only take effect for the duration of the app session. If you want to see the modify also after restarting the app, persist the modifies using synchronizeModifies method
*
*  NB: by default, the whole style is replaced with the new values ​​and past keypaths.
*      If you want to modify only specific values and maintain all the other keypath values ​​set in the basic themes, active the inheritance on the style using the method modifyStyle:inheritanceEnable:
*
* @param style the name of the style you want to modify
* @param keyPath the path to modify inside the theme
* @param value the new value for the constant (allowed types: NSString, NSNumber, NSDictionary)
 */
- (void) modifyStlye:(NSString*)style forKeyPath:(NSString*)keyPath withValue:(id)value;

// getter methods
- (id) modifiedValuesForConstant:(NSString*)constant;
- (id) modifiedValueForStyle:(NSString*)style;
- (id) modifiedValueForStyle:(NSString*)style atKeyPath:(NSString*)keyPath;


/**
 *  By default, modifying a style setting some keypaths replace the whole style in the bundle with only the new keypaths​​.
 *  If you want to mantain all the other keypath values ​​set in the basic themes, active the inheritance
 *
 * @param style the name of the style you want to modify
 * @param inheritanceEnable the enable state. If YES will be maintained all the keypaths for the given style set in the bundle themes. If NO the given style willl be replaced with the only keypaths added programmatically (using modifyStlye:forKeyPath:withValue:)
 */
- (void) modifyStyle:(NSString*)style inheritanceEnable:(BOOL)inheritanceEnable;

// getter method
- (BOOL) isInheritanceEnabledForStyle:(NSString*)style;

/**
 *  This method persists all the modifies set programmatically to retreive them also at next app restart. Otherwise all the modifies will be available for the current session.
 */
- (void) synchronizeModifies;

/**
 *  This method is used to reset all the modifies set programmatically (using modifyConstant:withValue: or modifyStlye:forKeyPath:withValue:).
 */
- (void) resetModifies;

@end
