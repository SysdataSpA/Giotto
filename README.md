# Giotto

[![Version](https://img.shields.io/cocoapods/v/Giotto.svg?style=flat)](http://cocoapods.org/pods/Giotto)
[![License](https://img.shields.io/cocoapods/l/Giotto.svg?style=flat)](http://cocoapods.org/pods/Giotto)
[![Platform](https://img.shields.io/cocoapods/p/Giotto.svg?style=flat)](http://cocoapods.org/pods/Giotto)

## Example

To run the example project, clone the repo, and run `pod install` from the Example directory first.

![Example](https://raw.githubusercontent.com/SysdataSpA/Giotto/master/example.gif)

## Requirements

## Installation

Giotto is available through [CocoaPods](http://cocoapods.org). To install
it, simply add the following line to your Podfile:

```ruby
pod "Giotto"
```

## License

Giotto is available under the Apache license. See the LICENSE file for more info.

## Introduction

SDThemeManager (henceforth called TM) is born mainly with the intention of simplifying and standardizing development
of applications that require the rebranding of the GUI.


## The .plist file
The **plist** describing a theme must contain a **Constants** dictionary with all constants, while styles can be arranged as desired in other dictionaries.

## Constants
It contains all constants such as font names, colors, or sizes.
Technically it is a one level organized dictionary as follows:
`<costant_name> : <costant_value>`
By convention the keys have the following prefixes:
> * font names: key starts with ```FONT_```
> * color codes: key starts with ```COLOR_```
> * dimensions (integer o float): key starts with ```DIMENSION_```

Esempi:

```
{
	“FONT_REGULAR” : “Helvetica-Neue”,
	“COLOR_COMMON_BACKGROUND” : “color:000000FF”,
	“DIMENSION_VIEW_WIDTH” : 3 // value is a NSNumber
}
```

Convention ```color:``` is explained in the section [*Conventions*](#conventions)
Constants **can't** contains array or dictionary as value.

## Styles groups

At the same level as Constants, other dictionaries can be defined as function groups of graphic styles. Group names are free.
Technically, they are organized dictionaries as follows:
`<style_name> : <style_dictionary>`
The style dictionary is organized as follows:
`<property_name> : <value_to_apply>`
Examples:

```
{ 
	“CommonLabel” : 
	{ 
		“_superstyle”: <style name of parent>,
		“textColor” : “COLOR_COMMON_LABEL”,
		“font”: “font:FONT_REGULAR,18” 
	},
	“HomeViewController” : 
	{
		“titleLabel” : “style:CommonLabel”,
		“textField” : 
		{
			“textColor” : “color:FFFFFF”,
			“width” : “DIMENSION_FIELD_WIDTH”,
			“layer.borderWidth” : 2 
		}
	}
}
```

Conventions `_superstyle"`, `style:` and `font:` are explained in section [*Conventions*](#conventions)


## Conventions

In order to speed up the drafting of the themes and to allow the handling of particular but frequent cases, the following conventions have been defined:

## Conventions for keys
 
> * `_superstyle` : Can be entered in the dictionary of a style to indicate that the style inherits from another style. When the "parent" style is applied before the "child" style, you can overwrite the keyPaths in the "child". You can inherit from multiple styles by sequentially dividing them by a ",". The styles that are indicated will be applied in order, so the style shown after overwriting the value of the keyPaths that it has in common with a style that precedes it in the list. 

## Conventions for values
 
> *	`style:style_name1,style_name2`:  The property indicated in the key is stylized with the styles listed on the list. The styles shown must be present in one of the styles groups. Abbreviated version `s: style_name1,style_name2`. As `_superstyle` the styles shown are applied in order.
> * `font:font_name, font_size`: nstantiates a UIFont and sets it as the value of the property specified in the key. This convention can also be used in Constants. Short version `f: font_name, font_size`. 
> 
> > the `font_name` can take on conventional values ​​to load the system font:
> >
> > >	*	`system`
> > > * 	`systemBold`
> > > * 	`systemItalic`
>
> *	`color:color_string`: renders *color_string* to instantiate a UIColor to validate the property specified in the key. This convention can also be used in Constants. Short version `c: color_string`.
> * `null` or `nil`: set the property indicated in the key as `nil`.
> * `point:x,y`: set the property as a CGPoint with x and y values. The x and y values ​​are interpreted as float.
> * `size:width,height`: set the property as a CGSize with the indicated width and height values. Values ​​are interpreted as float.
> * `rect:x,y,width,height`: set the property as a CGRect with values ​​x, y, width, and height. Values ​​are interpreted as float.
> * `edge:top,left,bottom,right`: set the property as a UIEdgeInsets with top, left, bottom, and right values. Values ​​are interpreted as float.

## Keys of a style

As already mentioned, a style looks like a dictionary in one of the styles groups and can be applied to any NSObject (typically an interface element).
The dictionary keys can be:
>	*	one of the conventions given the keys (see dedicated paragraph)
>	*	a property of the object to be stylized
>	*	the keyPath of one of a property of the object to be stylized (ex. “layer.borderColor”) 
>	*	a string that does not indicate a real property but will be handled in the appropriate method that each object inherits from the category **NSObject+ThemeManager** (see section [*Special Property Management*](#special-property-management)).
>	*	a list of properties or keyPaths separated by **","** (es. textColor,layer.borderColor).

The property indicated may also be an NSArray (such as an IBOutletCollection). In this case, the value is applied to all the objects in the array.

## Application of a style

To apply a style declared in Plist to an object, simply use the following line of code:

```
[[SDThemeManager sharedManager] applyStyleWithName:@"NomeStile" toObject:object];
```

The indicated object may also be **self**.

## Special Property Management

The library contains a category *NSObject+ThemeManager* which exposes the method:

```
- (void) applyThemeValue:(id)value forKeyPath:(NSString*)keyPath;
```

This method is overridden by the categories of some subclasses to handle a few properties in a special way. These categories are always included in the Sysdata library.
Eg. *UITextField+ThemeManager* manages the fake property **placeholderColor** to use ’**attributedPlaceholder**.

The category NSObject+ThemeManager declares protocol:

```
@protocol ThemeManagerCustomizationProtocol <NSObject>
@optional
- (BOOL) shouldApplyThemeCustomizationForKeyPath:(NSString*)keyPath;
- (void) applyCustomizationOfThemeValue:(id)value forKeyPath:(NSString*)keyPath;
@end
```

The methods of this protocol enable custom property management outside the library itself. These are the only methods that must be used out of the library to avoid risking the implementation of the method previously described.

The method `shouldApplyThemeCustomizationForKeyPath:` should return `YES`only for the keyPaths you intend to handle manually.

The method `applyCustomizationOfThemeValue:forKeyPath:` must contain the custom implementation for the keyPaths accepted by the previous method.

## Alternative themes

The ThemeManager necessarily requires a **default** theme and optionally one or more alternative styles can be indicated by the method:

```
- (void) setAlternativeThemes:(NSArray*)alternativeThemes
```

The past array must contain the names of plist files of alternative themes.
When you try to apply a style, ThemeManager looks for it in the first alternative theme. If you do not find it in the second and so on. If none of the alternative themes contains the indicated style, the ThemeManager looks for it in the default theme.

**Order is important!!!**

## Backwards compatibility

Version 2 of the ThemeManager is backward compatible. To handle retrocompatibility with old Plist formats, new ones must necessarily contain the key-value pair:
`“formatVersion” : 2`


## Dynamic behaviour

The following methods can change the theme and constant values ​​in a programmatic way.

Modify the value of a constant in a programmatic way. 
```
- (void) modifyConstant:(NSString*)constant withValue:(id)value
```

Modify the value for a style at a given path in a programmatic way.
```
- (void) modifyStlye:(NSString*)style forKeyPath:(NSString*)keyPath withValue:(id)value
```
**ATTENTION**: 
 - The change will only take effect for the duration of the app session. If you want to see the modify also after restarting the app, persist the modifies using **synchronizeModifies** method
 - By default, the whole style is replaced with the new values ​​and past keypaths.
If you want to modify only specific values and maintain all the other keypath values ​​set in the basic themes, active the inheritance on the style using the method **modifyStyle:inheritanceEnable:**

By default, modifying a style setting some keypaths replace the whole style in the bundle with only the new keypaths​​.
 If you want to mantain all the other keypath values ​​set in the basic themes, active the inheritance
```
- (void) modifyStyle:(NSString*)style inheritanceEnable:(BOOL)inheritanceEnable
```


To persist all the modifies set programmatically to retreive them also at next app restart. Otherwise all the modifies will be available for the current session.
```
- (void) synchronizeModifies
```

To reset all the modifies set programmatically (using modifyConstant:withValue: or modifyStlye:forKeyPath:withValue:)
```
- (void) resetModifies
```


