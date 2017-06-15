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

#import "SDThemeManager.h"
#import "NSObject+ThemeManager.h"

#ifndef IS_IPAD
#define IS_IPAD ( UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad )
#endif

#define FORMAT_VERSION_KEY       @"formatVersion"
#define CONSTANTS_KEY            @"Constants"
#define STYLES_KEY               @"Styles"

#define COLOR_IDENTIFIERS        @[@"color:", @"c:"]
#define STYLE_IDENTIFIERS        @[@"style:", @"s:"]
#define FONT_IDENTIFIERS         @[@"font:", @"f:"]
#define NULL_IDENTIFIERS         @[@"null", @"NULL", @"Null", @"nil", @"Nil"]

#define SIZE_IDENTIFIER          @"size:"
#define POINT_IDENTIFIER         @"point:"
#define RECT_IDENTIFIER          @"rect:"
#define EDGE_IDENTIFIER          @"edge:"

#define SYSTEM_FONT_NAME        @"system"
#define SYSTEM_BOLD_FONT_NAME   @"systembold"
#define SYSTEM_ITALIC_FONT_NAME @"systemitalic"

#define SUPERSTYLE_KEY           @"_superstyle"
#define INHERIT_FROM_DEFAULT_THEME @"_inherit"

#define XCODE_COLORS_ESCAPE      @"\033["
#define XCODE_COLORS_RESET       XCODE_COLORS_ESCAPE @";"   // Clear any foreground or background color

#define IPHONE_VARIANT           @"IPHONE"
#define IPAD_VARIANT             @"IPAD"

SDThemeManager* themeManagerSharedInstance(){
    return [SDThemeManager sharedManager];
}

id SDThemeManagerValueForConstant(NSString* key){
    return [themeManagerSharedInstance() valueForConstantWithName: key];
}
void SDThemeManagerApplyStyle (NSString* key, NSObject* object){
    [themeManagerSharedInstance() applyStyleWithName: key toObject: object];
}

@implementation SDThemeManager

#pragma mark - Singleton Pattern
+ (instancetype) sharedManager
{
    static dispatch_once_t pred;
    static id sharedManagerInstance_ = nil;
    
    dispatch_once(&pred, ^{
        sharedManagerInstance_ = [[self alloc] init];
    });
    
    return sharedManagerInstance_;
}

#pragma mark - Load methods

- (id) init
{
    self = [super init];
    if (self)
    {
        
#if BLABBER
        SDLogLevel logLevel = SDLogLevelWarning;
#if DEBUG
        logLevel = SDLogLevelVerbose;
#endif
        
        [[SDLogger sharedLogger] setLogLevel:logLevel forModuleWithName:self.loggerModuleName];
#endif
        defaultTheme = [self loadThemeFromPlist:THEME_DEFAULT_PLIST_NAME];
        if (defaultTheme)
        {
            themes = @[defaultTheme];
        }
        else
        {
            SDLogModuleError(kThemeManagerLogModuleName, @"Default theme not found");
        }
    }
    return self;
}


/**
 * Load the theme from the plist with the given name, make the necessary conversions and changes and return it.
 *
 * @param plistName the name of the plist from which to upload the theme (without the extension)
 *
 * @return The theme dictionary loaded or nil
 */
- (NSDictionary*) loadThemeFromPlist:(NSString*)plistName
{
    NSString* path = [[NSBundle mainBundle] pathForResource:plistName ofType:@"plist"];
    if ([[NSFileManager defaultManager] fileExistsAtPath:path])
    {
        // convert the theme for reasons of retrocompatibility
        NSDictionary* plistDict = [self convertThemeForCompatibility:[NSDictionary dictionaryWithContentsOfFile:path]];
        
        // structure that will contain the final theme
        NSMutableDictionary* theme = [NSMutableDictionary new];
        
        // structure that will contain the entries of all plist dictionaries other than "Constants"
        NSMutableDictionary* styles = [NSMutableDictionary new];
        
        for (NSString* key in [plistDict allKeys])
        {
            if ([key isEqualToString:FORMAT_VERSION_KEY] || [key isEqualToString:CONSTANTS_KEY])
            {
                // copy in the theme the values ​​of "formatVersion" and "Constants"
                theme[key] = plistDict[key];
            }
            else
            {
                // insert in styles the entries of all plist dictionaries other than "Constants"
                if ([plistDict[key] isKindOfClass:[NSDictionary class]])
                {
                    // cycle on the keys of the dictionary to verify the presence of duplicates
                    for (NSString* styleKey in [plistDict[key] allKeys])
                    {
                        if (styles[styleKey] != nil)
                        {
                            SDLogModuleWarning(kThemeManagerLogModuleName, @"Duplicate key \"%@\" into dictionary \"%@\" of theme %@. Duplica key will be ignored.", styleKey, key, plistName);
                        }
                        else
                        {
                            styles[styleKey] = plistDict[key][styleKey];
                        }
                    }
                }
                else
                {
                    // Generic keys with values ​​other than NSDictionary are not allowed
                    SDLogModuleError(kThemeManagerLogModuleName, @"Value not allowed for key \"%@\" in theme %@", key, plistName);
                }
            }
        }
        
        // Copy styles under the generic Key Styles theme and return it
        theme[STYLES_KEY] = styles;
        return theme;
    }
    else
    {
        SDLogModuleError(kThemeManagerLogModuleName, @"Theme not found: %@", plistName);
    }
    return nil;
}

- (void) setAlternativeThemes:(NSArray*)alternativeThemes
{
    alternativeThemesPlist = alternativeThemes;
    NSMutableArray* themesNew = [NSMutableArray array];
    if (alternativeThemes.count > 0)
    {
        for (NSString* plistName in alternativeThemes)
        {
            
            // for each plist indicated, if it exists, add the topic to the array of themes in the specified order
            NSDictionary* theme = [self loadThemeFromPlist:plistName];
            if (theme)
            {
                [themesNew addObject:theme];
            }
        }
    }
    // Finally, you enter the default theme
    [themesNew addObject:defaultTheme];
    themes = [NSArray arrayWithArray:themesNew];
}

#pragma mark - SDLoggerModuleProtocol

#if BLABBER
- (NSString *) loggerModuleName
{
    return kThemeManagerLogModuleName;
}

- (SDLogLevel)loggerModuleLogLevel
{
    return [[SDLogger sharedLogger] logLevelForModuleWithName:self.loggerModuleName];
}

- (void)setLoggerModuleLogLevel:(SDLogLevel)level
{
    [[SDLogger sharedLogger] setLogLevel:level forModuleWithName:self.loggerModuleName];
}
#endif


#pragma mark - Public methods

- (void) applyStyleWithName:(NSString*)styleName toObject:(NSObject*)object
{
    [self applyStyleWithName:styleName toObject:object withVariant:nil];
    if (IS_IPAD)
    {
        // Looks for the iPad version of the style and applies it
        [self applyStyleWithName:styleName toObject:object withVariant:IPAD_VARIANT];
    }
    else
    {
        // Looks for the iPhone style version and applies it
        [self applyStyleWithName:styleName toObject:object withVariant:IPHONE_VARIANT];
    }
}

/**
 *  @discussion
 *  CAUTION:
 *  This public method differs from the constantValueForString private method: because it returns nil when the constant does not exist.
 *  Do not use for internal logic.
 */
- (id) valueForConstantWithName:(NSString*)constantName
{
    id constantValue = [self valueForKeyPath:[NSString stringWithFormat:@"%@.%@", CONSTANTS_KEY, constantName]];
    
    // if I do not find a constant I return nil
    if (!constantValue)
    {
        return nil;
    }
    
    // If the value is a string, look for any conventions, otherwise I return the value
    if ([constantValue isKindOfClass:[NSString class]])
    {
        return [self valueForConventionalString:constantValue];
    }
    else
    {
        return constantValue;
    }
}

#pragma mark - Old methods for retro-compatibility

- (id) valueForKey:(NSString*)key
{
    NSString* value;
    
    for (NSDictionary* currentTheme in themes)
    {
        // you search for the key in all the topics you set, sorted (the last is the default theme)
        // The first match stops the search and returns the result
        value = [currentTheme valueForKeyPath:[NSString stringWithFormat:@"%@.%@", CONSTANTS_KEY, key]];
        if (value)
        {
            break;
        }
    }
    
    return value;
}

- (float) themeFloatForKey:(NSString*)key
{
    NSNumber* themeValue = [self themeNumberForKey:key];
    
    if (themeValue)
    {
        return [themeValue floatValue];
    }
    return 0;
}

- (int) themeIntegerForKey:(NSString*)key
{
    NSNumber* themeValue = [self themeNumberForKey:key];
    
    if (themeValue)
    {
        return [themeValue intValue];
    }
    return 0;
}

- (NSNumber*) themeNumberForKey:(NSString*)key
{
    NSNumber* themeValue = [self valueForKey:key];
    
    return themeValue;
}

- (UIColor*) themeColorForKey:(NSString*)key
{
    NSString* themeValue = [self valueForKey:key];
    
    id color = [self valueForConventionalString:themeValue];
    
    if ([color isKindOfClass:[UIColor class]])
    {
        return color;
    }
    return [self colorForString:themeValue];
}

- (UIFont*) themeFontForKey:(NSString*)key andSize:(CGFloat)fontSize
{
    NSString* themeValue = [self valueForKey:key];
    id font = [self valueForConventionalString:themeValue];
    
    if ([font isKindOfClass:[UIFont class]])
    {
        return [UIFont fontWithName:((UIFont*)font).fontName size:fontSize];
    }
    return [UIFont fontWithName:themeValue size:fontSize];
}

#pragma mark - Utils

- (void) applyStyleWithName:(NSString*)styleName toObject:(NSObject*)object withVariant:(NSString*)variant
{
    NSString* finalStyleName = variant.length > 0 ? [NSString stringWithFormat:@"%@_%@", styleName, variant] : styleName;
    
    if (variant.length > 0 && [self getThemeStyleForKey:finalStyleName] == nil)
    {
        // If the variant is requested but does not exist, it stops
        return;
    }
    // retrieves the indicated style
    NSDictionary* style = [self themeStyleForKey:finalStyleName];
    
    // If I did not find a style with the past name, I stop signaling an error
    if (!style)
    {
        SDLogModuleError(kThemeManagerLogModuleName, @"Style not found with name '%@'", finalStyleName);
        return;
    }
    SDLogModuleVerbose(kThemeManagerLogModuleName, @"Start to applying style: %@", finalStyleName);
    [self applyDictionary:style toObject:object];
}

- (id) getThemeStyleForKey:(NSString*)key fromDefaultTheme:(BOOL)fromDefault
{
    // style is searched in the "Styles" group
    id style = [self valueForKeyPath:[NSString stringWithFormat:@"%@.%@", STYLES_KEY, key] fromDefaultTheme:fromDefault];
    return style;
}

- (id) getThemeStyleForKey:(NSString*)key
{
    return [self getThemeStyleForKey:key fromDefaultTheme:NO];
}

/**
 * Converts old themes to make them compatible with the new version of ThemeManager.
 *
 * @param theme Dictionary containing the old theme.
 *
 * @return dictionary converted to new specifications.
 */
- (NSDictionary*) convertThemeForCompatibility:(NSDictionary*)theme
{
    int version = [[theme objectForKey:FORMAT_VERSION_KEY] intValue];
    
    if (version < 2)
    {
        // loaded theme is of the old type, for compatibility it loads everything inside the key of the constants
        return @{ CONSTANTS_KEY: theme };
    }
    return theme;
}

/**
 * Performs a RRGGBBAA or RRGGBB hexadecimal string and converts it into an UIColor.
 *
 * @param color RRGGBBAA hexadecimal string or RRGGBB.
 *
 * @return a UIColor or nil if the past string does not meet the required format.
 */
- (UIColor*) colorForString:(NSString*)color
{
    // Interprets the color from the string in the RRBBGGAA format (red, green, blue, alpha)
    if (color.length != 6 && color.length != 8 && color.length != 3 && color.length != 4)
    {
        SDLogModuleError(kThemeManagerLogModuleName, @"Color string %@ in wrong format", color);
        return nil;
    }
    
    if (color.length == 3) // If you only specify the 3 RGB characters, they duplicate and set the alpha to the maximum
    {
        const char* chars = [color UTF8String];
        color = [NSString stringWithFormat:@"%c%c%c%c%c%c%@", chars[0], chars[0], chars[1], chars[1], chars[2], chars[2], @"FF"];
    }
    else if (color.length == 4) // If you only specify 4 RGB characters, they all duplicate
    {
        const char* chars = [color UTF8String];
        color = [NSString stringWithFormat:@"%c%c%c%c%c%c%c%c", chars[0], chars[0], chars[1], chars[1], chars[2], chars[2], chars[3], chars[3]];
    }
    else if (color.length == 6) // If you only specify the 6 RRGGBB characters, the alpha hangs up to the maximum
    {
        color = [color stringByAppendingString:@"FF"];
    }
    
    NSScanner* scanner = [NSScanner scannerWithString:color];
    
    unsigned hex;
    if (![scanner scanHexInt:&hex])
    {
        return nil;
    }
    int r = (hex >> 24) & 0xFF;
    int g = (hex >> 16) & 0xFF;
    int b = (hex >> 8) & 0xFF;
    int a = (hex) & 0xFF;
    
    return [UIColor colorWithRed:r / 255.0f green:g / 255.0f blue:b / 255.0f alpha:a / 255.0f];
}

- (id) valueForKeyPath:(NSString*)keyPath
{
    return [self valueForKeyPath:keyPath fromDefaultTheme:NO];
}

- (id) valueForKeyPath:(NSString*)keyPath fromDefaultTheme:(BOOL)fromDefault
{
    NSString* value;
    
    if (fromDefault)
    {
        value = [defaultTheme valueForKeyPath:keyPath];
    }
    else
    {
        for (NSDictionary* currentTheme in themes)
        {
            // you search for the key in all the themes you have set, sorted (the last is the default theme)
            // The first match stops the search and returns the result
            value = [currentTheme valueForKeyPath:keyPath];
            if (value)
            {
                break;
            }
        }
    }
    
    return value;
}

/**
 * Search the past style first in the Interfaces group and (as fallback) in the plist Styles group.
 *
 * @param key Name of style to search.
 *
 * @return The style dictionary or nil if this does not exist.
 */
- (NSDictionary*) themeStyleForKey:(NSString*)key fromDefaultTheme:(BOOL)fromDefault
{
    // Style is searched in the "interfaces" group
    id style = [self getThemeStyleForKey:key fromDefaultTheme:fromDefault];
    
    if ([style isKindOfClass:[NSString class]])
    {
        id value = [self valueForConventionalString:style];
        
        if (![value isKindOfClass:[NSDictionary class]])
        {
            SDLogModuleError(kThemeManagerLogModuleName, @"Style not found with name '%@' for key %@", style, key);
            return nil;
        }
        else
        {
            return value;
        }
    }
    else
    {
        if (!style)
        {
            SDLogModuleError(kThemeManagerLogModuleName, @"Style not found with name '%@' for key %@", style, key);
        }
        return style;
    }
}

- (NSDictionary*) themeStyleForKey:(NSString*)key
{
    return [self themeStyleForKey:key fromDefaultTheme:NO];
}

/**
 * Applies the dictionary of a style to the past object
 *
 * @param style The style to apply.
 * @param object The object to which style is to be applied.
 */
- (void) applyDictionary:(NSDictionary*)style toObject:(NSObject*)object
{
    if ([object isKindOfClass:[NSArray class]])
    {
        NSArray* array = (NSArray*)object;
        for (id element in array)
        {
            [self applyDictionary:style toObject:element];
        }
    }
    else
    {
        // eventual inheritance from the default theme
        NSString* inheritstyleName = style[INHERIT_FROM_DEFAULT_THEME];
        if (inheritstyleName.length > 0)
        {
            NSDictionary* superstyle = [self themeStyleForKey:inheritstyleName fromDefaultTheme:YES];
            [self applyDictionary:superstyle toObject:object];
        }
        
        // Application of a possible _superstyle
        NSString* superstyleName = style[SUPERSTYLE_KEY];
        
        if (superstyleName.length > 0)
        {
            NSArray* styles = [superstyleName componentsSeparatedByString:@","];
            for (NSString* styleName in styles)
            {
                NSDictionary* superstyle = [self themeStyleForKey:styleName fromDefaultTheme:NO];
                [self applyDictionary:superstyle toObject:object];
            }
        }
        
        // normalize the style by parsing the keys
        NSDictionary* normalizedStyle = [self normalizeDictionary:style];
        
        // Apply values ​​to the properties listed in the dictionary
        for (NSString* key in normalizedStyle.allKeys)
        {
            if ([key isEqualToString:SUPERSTYLE_KEY] || [key isEqualToString:INHERIT_FROM_DEFAULT_THEME])
            {
                continue;
            }
            
            [self applyValue:normalizedStyle[key] toKeyPath:key ofObject:object];
        }
    }
}

/**
 * Normalize past dictionary by parsing all its keys.
 * First divides all keys that are represented by keyPaths lists divided by ",".
 * For all keypaths thus obtained, normalizes the first level.
 *
 *  Example -
 * The dictionary:
 *
 *  { "view.layer.borderWidth,view2.layer.borderWidth" : 2} viene trasformato in
 *
 *  {
 *      "view"  : { "layer.borderWidth" : 2 },
 *      "view2" : { "layer.borderWidth" : 2 }
 *  }
 *
 *  @param dictionary dictionary to normalize.
 *
 *  @return normalized dictionary.
 */
- (NSDictionary*) normalizeDictionary:(NSDictionary*)dictionary
{
    NSMutableDictionary* normalizedDictionary = [NSMutableDictionary dictionary];
    
    // look at all the passwords in the dictionary keyPaths
    for (NSString* originalKeyPaths in dictionary.allKeys)
    {
        // divides arrays expressed with ","
        NSArray* keyPaths = [originalKeyPaths componentsSeparatedByString:@","];
        
        for (NSString* keyPath in keyPaths)
        {
            // if the key is a keyPath, it finds the part before the first "." Which becomes the new key. Its value is a dictionary to which the next part of the original keyPath, associated with the original value, is added as a key.

            NSInteger dotIndex = [keyPath rangeOfString:@"."].location;
            if (dotIndex != NSNotFound)
            {
                NSString* normalizedKey = [keyPath substringToIndex:dotIndex];
                NSString* subKeyPath = [keyPath substringFromIndex:dotIndex + 1];
                NSDictionary* normalizedValue = nil;
                
                // Avoid that more key-paths associated with the standard key overwrite each other
                id currentValue = normalizedDictionary[normalizedKey];
                if (currentValue != nil &&
                    [currentValue isKindOfClass:[NSDictionary class]])
                {
                    NSMutableDictionary* unionOfValues = [NSMutableDictionary dictionaryWithDictionary:currentValue];
                    unionOfValues[subKeyPath] = dictionary[originalKeyPaths];
                    normalizedValue = [NSDictionary dictionaryWithDictionary:unionOfValues];
                }
                else
                {
                    normalizedValue = @{ subKeyPath : dictionary[originalKeyPaths] };
                }
                
                normalizedDictionary[normalizedKey] = normalizedValue;
            }
            else
            {
                // the dictionary is already normalized
                normalizedDictionary[keyPath] = dictionary[originalKeyPaths];
            }
        }
    }
    
    return [NSDictionary dictionaryWithDictionary:normalizedDictionary];
}

/**
 * Applies a single value to a given keyPath of the past object.
 *
 * @param value The value to apply.
 * @param keyPath The property keyPath to be valued.
 * @param object The object you want to highlight the property indicated in 'keyPath'.
 */
- (void) applyValue:(id)value toKeyPath:(NSString*)keyPath ofObject:(NSObject*)object
{
    @try {
        // if the value is a dictionary then it is a grafted style, so I apply the style grafted to
        if ([value isKindOfClass:[NSDictionary class]])
        {
            NSObject* objectForKeyPath = [object valueForKeyPath:keyPath];
            [self applyDictionary:value toObject:objectForKeyPath];
        }
        // if the value is a string can be a constant name or one of the possible conventions
        else if ([value isKindOfClass:[NSString class]])
        {
            // control the conventions
            id finalValue = [self valueForConventionalString:value];
            if ([finalValue respondsToSelector:@selector(isEqualToString:)] && [finalValue isEqualToString:value])
            {
                // did not find any conventions. I look for constants
                finalValue = [self constantValueForString:value];
            }
            
            // If the final value is a dictionary of a style, then call the method to apply it
            if ([finalValue isKindOfClass:[NSDictionary class]])
            {
                [self applyValue:finalValue toKeyPath:keyPath ofObject:object];
            }
            // otherwise I apply the value to the past keypath
            else
            {
#if DEBUG
                NSString* initialClassName = [self classNameForKey:keyPath ofObject:object];
#endif
                SDLogModuleVerbose(kThemeManagerLogModuleName, @"Applying value: %@ to keyPath: %@ of object of class: %@", finalValue, keyPath, NSStringFromClass([object class]));
                if ([object respondsToSelector:@selector(shouldApplyThemeCustomizationForKeyPath:)] &&
                    [object shouldApplyThemeCustomizationForKeyPath:keyPath])
                {
                    [object applyCustomizationOfThemeValue:finalValue forKeyPath:keyPath];
                }
                else
                {
                    [object applyThemeValue:finalValue forKeyPath:keyPath];
                }
#if DEBUG
                NSString* finalClassName = [self classNameForKey:keyPath ofObject:object];
                if (![finalClassName isEqualToString:initialClassName] && finalClassName != nil && initialClassName != nil)
                {
                    // unfortunately it is not possible to retrieve the property class if the property is nil, so you have to skip the cases where initial or final are nil
                    SDLogModuleError(kThemeManagerLogModuleName, @"Possible error: object at keypath %@ of object %@ changed type from %@ to %@", keyPath, NSStringFromClass([object class]), initialClassName, finalClassName);
                }
#endif
            }
        }
        else
        {
            SDLogModuleVerbose(kThemeManagerLogModuleName, @"Applying value: %@ to keyPath: %@ of object of class: %@", value, keyPath, NSStringFromClass([object class]));
            if ([object respondsToSelector:@selector(shouldApplyThemeCustomizationForKeyPath:)] &&
                [object shouldApplyThemeCustomizationForKeyPath:keyPath])
            {
                [object applyCustomizationOfThemeValue:value forKeyPath:keyPath];
            }
            else
            {
                [object applyThemeValue:value forKeyPath:keyPath];
            }
        }
    }
    @catch (NSException* exception)
    {
        SDLogModuleError(kThemeManagerLogModuleName, @"Cannot apply value %@ to keyPath %@ to object of class %@", value, keyPath, object ? NSStringFromClass([object class]) : @"<nil>");
    }
}

/**
 * Finds the value of a Constant constants constant or, if not found, the string passed as a argument
 *
 * @param string The name of the constant to be found.
 *
 * @resurn the value of a Constants constant constant or, if not found, the passed string as argument
 *
 * @discussion This private method differs from the public method valueForConstantWithName: because it returns the passed string if you do not find the constant. This method must always be used for internal logic.
 */
- (id) constantValueForString:(NSString*)string
{
    id constantValue = [self valueForKeyPath:[NSString stringWithFormat:@"%@.%@", CONSTANTS_KEY, string]];
    
    // if I do not find a constant string return
    if (!constantValue)
    {
        return string;
    }
    
    // If the value is a string, look for any conventions, otherwise I return the value
    if ([constantValue isKindOfClass:[NSString class]])
    {
        return [self valueForConventionalString:constantValue];
    }
    else
    {
        return constantValue;
    }
}

/**
 * Look for any conventions in the past string and return a conforming value to the convention or the passed string if there are no known conventions.
 *
 * @param string The string to be parsed.
 *
 * @return A value consistent with the agreement found. If it finds a convention that is not respected or the NULL convention nil returns. If it does not find any convention, it returns string.
 */
- (id) valueForConventionalString:(NSString*)string
{
    NSString* convention = [SDThemeManager conventionIdentifierInString:string];
    
    // style convention:
    if ([STYLE_IDENTIFIERS containsObject:convention])
    {
        @try
        {
            NSString* styleName = [string substringFromIndex:convention.length];
            NSArray* styles = [styleName componentsSeparatedByString:@","];
            NSMutableDictionary* styleDictionary = [NSMutableDictionary dictionary];
            for (NSString* style in styles)
            {
                [styleDictionary addEntriesFromDictionary:[self themeStyleForKey:style]];
            }
            return [styleDictionary copy];
        }
        @catch (NSException* exception)
        {
            SDLogModuleError(kThemeManagerLogModuleName, @"'style:' convention used without a valid value. Given value: %@", string);
            return nil;
        }
    }
    // font convention:
    if ([FONT_IDENTIFIERS containsObject:convention])
    {
        @try
        {
            // aspected string: "font:<FONT_NAME>,<FONT_SIZE>" o "f:<FONT_NAME>,<FONT_SIZE>"
            NSString* fontSpecs = [string substringFromIndex:convention.length];
            NSArray* specs = [fontSpecs componentsSeparatedByString:@","];
            NSString* fontName = [self constantValueForString:specs[0]];
            float fontSize = [[self constantValueForString:specs[1]] floatValue];
            if ([fontName.lowercaseString isEqualToString:SYSTEM_FONT_NAME])
            {
                return [UIFont systemFontOfSize:fontSize];
            }
            if ([fontName.lowercaseString isEqualToString:SYSTEM_BOLD_FONT_NAME])
            {
                return [UIFont boldSystemFontOfSize:fontSize];
            }
            if ([fontName.lowercaseString isEqualToString:SYSTEM_ITALIC_FONT_NAME])
            {
                return [UIFont italicSystemFontOfSize:fontSize];
            }
            UIFont* font = [UIFont fontWithName:fontName size:fontSize];
            return font;
        }
        @catch (NSException* exception)
        {
            SDLogModuleError(kThemeManagerLogModuleName, @"'font:' convention used without a valid value. Given value: %@. Expected value format: 'font:<FONT_NAME>,<FONT_SIZE>'", string);
            return nil;
        }
    }
    // color convention:
    if ([COLOR_IDENTIFIERS containsObject:convention])
    {
        @try
        {
            NSString* colorValue = [string substringFromIndex:convention.length];
            UIColor* color = [self colorForString:colorValue];
            if (!color)
            {
                SDLogModuleError(kThemeManagerLogModuleName, @"'color:' convention used without a valid value. Given value: %@. Expected value format: 'color:<RRGGBB>' or 'color:<RRGGBBAA>'", string);
            }
            return color;
        }
        @catch (NSException* exception)
        {
            SDLogModuleError(kThemeManagerLogModuleName, @"'color:' convention used without a valid value. Given value: %@. Expected value format: 'color:<RRGGBB>' or 'color:<RRGGBBAA>'", string);
            return nil;
        }
    }
    // null convention
    if ([NULL_IDENTIFIERS containsObject:convention])
    {
        return nil;
    }
    // point convention:
    if ([convention isEqualToString:POINT_IDENTIFIER])
    {
        @try
        {
            // aspected string: "point:<X_VALUE>,<Y_VALUE>"
            NSString* pointSpecs = [string substringFromIndex:convention.length];
            NSArray* specs = [pointSpecs componentsSeparatedByString:@","];
            CGFloat x = [specs[0] floatValue];
            CGFloat y = [specs[1] floatValue];
            CGPoint point = CGPointMake(x, y);
            return [NSValue valueWithCGPoint:point];
        }
        @catch (NSException* exception)
        {
            SDLogModuleError(kThemeManagerLogModuleName, @"'point:' convention used without a valid value. Given value: %@. Expected value format: 'point:<X_VALUE>,<Y_VALUE>'", string);
            return nil;
        }
    }
    // size convention:
    if ([convention isEqualToString:SIZE_IDENTIFIER])
    {
        @try
        {
            // aspected string: "size:<WIDTH_VALUE>,<HEIGHT_VALUE>"
            NSString* sizeSpecs = [string substringFromIndex:convention.length];
            NSArray* specs = [sizeSpecs componentsSeparatedByString:@","];
            CGFloat width = [specs[0] floatValue];
            CGFloat height = [specs[1] floatValue];
            CGSize size = CGSizeMake(width, height);
            return [NSValue valueWithCGSize:size];
        }
        @catch (NSException* exception)
        {
            SDLogModuleError(kThemeManagerLogModuleName, @"'size:' convention used without a valid value. Given value: %@. Expected value format: 'size:<WIDTH_VALUE>,<HEIGHT_VALUE>'", string);
            return nil;
        }
    }
    // rect convention:
    if ([convention isEqualToString:RECT_IDENTIFIER])
    {
        @try
        {
            // aspected string: "rect:<X_VALUE>,<Y_VALUE>,<WIDTH_VALUE>,<HEIGHT_VALUE>"
            NSString* rectSpecs = [string substringFromIndex:convention.length];
            NSArray* specs = [rectSpecs componentsSeparatedByString:@","];
            CGFloat x = [specs[0] floatValue];
            CGFloat y = [specs[1] floatValue];
            CGFloat width = [specs[2] floatValue];
            CGFloat height = [specs[3] floatValue];
            CGRect rect = CGRectMake(x, y, width, height);
            return [NSValue valueWithCGRect:rect];
        }
        @catch (NSException* exception)
        {
            SDLogModuleError(kThemeManagerLogModuleName, @"'rect:' convention used without a valid value. Given value: %@. Expected value format: 'rect:<X_VALUE>,<Y_VALUE>,<WIDTH_VALUE>,<HEIGHT_VALUE>'", string);
            return nil;
        }
    }
    // edge convention:
    if ([convention isEqualToString:EDGE_IDENTIFIER])
    {
        @try
        {
            // aspected string: "edge:<TOP_VALUE>,<LEFT_VALUE>,<BOTTOM_VALUE>,<RIGHT_VALUE>"
            NSString* edgeSpecs = [string substringFromIndex:convention.length];
            NSArray* specs = [edgeSpecs componentsSeparatedByString:@","];
            CGFloat top = [specs[0] floatValue];
            CGFloat left = [specs[1] floatValue];
            CGFloat bottom = [specs[2] floatValue];
            CGFloat right = [specs[3] floatValue];
            UIEdgeInsets edge = UIEdgeInsetsMake(top, left, bottom, right);
            return [NSValue valueWithUIEdgeInsets:edge];
        }
        @catch (NSException* exception)
        {
            SDLogModuleError(kThemeManagerLogModuleName, @"'edge:' convention used without a valid value. Given value: %@. Expected value format: 'edge:<TOP_VALUE>,<LEFT_VALUE>,<BOTTOM_VALUE>,<RIGHT_VALUE>'", string);
            return nil;
        }
    }
    
    return string;
}

/**
 * Find conventions in the past string
 *
 * @param string the string to be parsed
 *
 * @return Returns the found agreement or nil.
 */
+ (NSString*) conventionIdentifierInString:(NSString*)string
{
    // stle convention
    for (NSString* convention in STYLE_IDENTIFIERS)
    {
        if ([string hasPrefix:convention])
        {
            return convention;
        }
    }
    
    // font convention
    for (NSString* convention in FONT_IDENTIFIERS)
    {
        if ([string hasPrefix:convention])
        {
            return convention;
        }
    }
    
    // color convention
    for (NSString* convention in COLOR_IDENTIFIERS)
    {
        if ([string hasPrefix:convention])
        {
            return convention;
        }
    }
    
    // null convention
    for (NSString* convention in NULL_IDENTIFIERS)
    {
        if ([string hasPrefix:convention])
        {
            return convention;
        }
    }
    
    // CGPoint convention
    if ([[string lowercaseString] rangeOfString:POINT_IDENTIFIER].location != NSNotFound)
    {
        return POINT_IDENTIFIER;
    }
    
    // CGSize convention
    if ([[string lowercaseString] rangeOfString:SIZE_IDENTIFIER].location != NSNotFound)
    {
        return SIZE_IDENTIFIER;
    }
    
    // CGRect convention
    if ([[string lowercaseString] rangeOfString:RECT_IDENTIFIER].location != NSNotFound)
    {
        return RECT_IDENTIFIER;
    }
    
    // UIEdgeInsets convention
    if ([[string lowercaseString] rangeOfString:EDGE_IDENTIFIER].location != NSNotFound)
    {
        return EDGE_IDENTIFIER;
    }
    
    return nil;
}

- (NSString*) classNameForKey:(NSString*)key ofObject:(NSObject*)object
{
    if (!object || [key containsString:@":"])
    {
        // Jump all the customizations that are linked, for example, to the status of the buttons
        return nil;
    }
    
    if (![object respondsToSelector:NSSelectorFromString(key)])
    {
        return nil;
    }
    id value = [object valueForKey:key];
    if (!value)
    {
        return nil;
    }
    Class class = [value class];
    if ([value isKindOfClass:[UIColor class]])
    {
        // workaround for managing different default color types as background and those created by the theme manager instead
        class = [UIColor class];
    }
    return NSStringFromClass(class);
}

@end
