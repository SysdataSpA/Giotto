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

#import "UIButton+ThemeManager.h"
#import "NSObject+ThemeManager.h"
#import "UIImage+SDUtils.h"

@implementation UIButton (ThemeManager)

- (void) applyThemeValue:(id)value forKeyPath:(NSString*)keyPath
{
	NSString* cleanKeyPath = keyPath;
	UIControlState controlState = UIControlStateNormal;

	if ([keyPath hasPrefix:SELECTED_STATE_PREFIX])
	{
		cleanKeyPath = [keyPath substringFromIndex:SELECTED_STATE_PREFIX.length];
		controlState = UIControlStateSelected;
	}
	else if ([keyPath hasPrefix:DISABLED_STATE_PREFIX])
	{
		cleanKeyPath = [keyPath substringFromIndex:DISABLED_STATE_PREFIX.length];
		controlState = UIControlStateDisabled;
	}
	else if ([keyPath hasPrefix:HIGHLIGHTED_STATE_PREFIX])
	{
		cleanKeyPath = [keyPath substringFromIndex:HIGHLIGHTED_STATE_PREFIX.length];
		controlState = UIControlStateHighlighted;
	}

	if ([cleanKeyPath isEqualToString:@"titleColor"])
	{
		[self setTitleColor:value forState:controlState];
	}
	else if ([cleanKeyPath isEqualToString:@"image"])
	{
		[self setImage:[UIImage imageNamed:value] forState:controlState];
	}
    else if ([cleanKeyPath isEqualToString:@"backgroundImageWithColor"])
    {
        [self setBackgroundImage:[UIImage imageWithColor:value] forState:controlState];
    }
	else
	{
		[super applyThemeValue:value forKeyPath:cleanKeyPath];
	}
}

@end
