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

#import "MKAnnotationView+ThemeManager.h"

@implementation MKAnnotationView (ThemeManager)

- (void) applyThemeValue:(id)value forKeyPath:(NSString*)keyPath
{
	if ([keyPath isEqualToString:@"image"] && [value isKindOfClass:[NSString class]])
	{
		self.image = [UIImage imageNamed:value];
	}
	else if ([keyPath isEqualToString:@"centerOffset"] && [value isKindOfClass:[NSString class]])
	{
		NSArray* values = [value componentsSeparatedByString:@","];
		if (values.count == 2)
		{
			self.centerOffset = CGPointMake([values[0] floatValue], [values[1] floatValue]);
		}
	}
    else
    {
        [super applyThemeValue:value forKeyPath:keyPath];
    }
}

@end
