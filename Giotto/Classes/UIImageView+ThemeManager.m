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

#import "UIImageView+ThemeManager.h"
#import "NSObject+ThemeManager.h"

@implementation UIImageView (ThemeManager)

- (void)applyThemeValue:(id)value forKeyPath:(NSString *)keyPath
{
    if ([keyPath isEqualToString:@"image"])
    {
        if (value == nil)
        {
            self.image = nil;
        }
        else
        {
            self.image = [UIImage imageNamed:value];
        }
    }
    else
    {
        [super applyThemeValue:value forKeyPath:keyPath];
    }
}

@end
