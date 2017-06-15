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

#import "UITextField+ThemeManager.h"
#import "NSObject+ThemeManager.h"

@implementation UITextField (ThemeManager)

- (void) applyThemeValue:(id)value forKeyPath:(NSString*)keyPath
{
    if ([keyPath isEqualToString:@"placeholderColor"])
    {
        if ([self respondsToSelector:@selector(setAttributedPlaceholder:)] && [value isKindOfClass:[UIColor class]])
        {
            NSMutableAttributedString* attributedString = [self.attributedPlaceholder mutableCopy];
            if (attributedString.length == 0 && self.placeholder.length > 0)
            {
                attributedString = [[NSMutableAttributedString alloc] initWithString:self.placeholder attributes:@{ NSForegroundColorAttributeName: value }];
            }
            else
            {
                [attributedString addAttribute:NSForegroundColorAttributeName value:value range:NSMakeRange(0, attributedString.length)];
            }
            self.attributedPlaceholder = attributedString;
        }
    }
    else if ([keyPath isEqualToString:@"placeholderFont"])
    {
        if ([self respondsToSelector:@selector(setAttributedPlaceholder:)] && [value isKindOfClass:[UIFont class]])
        {
            NSMutableAttributedString* attributedString = [self.attributedPlaceholder mutableCopy];
            if (attributedString.length == 0 && self.placeholder.length > 0)
            {
                attributedString = [[NSMutableAttributedString alloc] initWithString:self.placeholder attributes:@{ NSFontAttributeName: value }];
            }
            else
            {
                [attributedString addAttribute:NSFontAttributeName value:value range:NSMakeRange(0, attributedString.length)];
            }
            self.attributedPlaceholder = attributedString;
        }
    }
    else if ([keyPath isEqualToString:@"leftMargin"])
    {
        CGFloat margin = [value floatValue];
        UIView *leftView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, margin, self.frame.size.height)];
        leftView.backgroundColor = [UIColor clearColor];
        self.leftView = leftView;
        self.leftViewMode = UITextFieldViewModeAlways;
    }
    else
    {
        [super applyThemeValue:value forKeyPath:keyPath];
    }
}

@end
