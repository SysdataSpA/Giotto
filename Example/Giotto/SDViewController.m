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

#import "SDViewController.h"
@import Giotto;


@interface SDViewController ()

@property (weak, nonatomic) IBOutlet UIView *containerView;
@property (weak, nonatomic) IBOutlet UILabel *styledLabel;
@property (weak, nonatomic) IBOutlet UILabel *boldLabel;

@property (weak, nonatomic) IBOutlet UIButton *modifyButton;
@property (weak, nonatomic) IBOutlet UIButton *inheritanceButton;
@property (weak, nonatomic) IBOutlet UIButton *saveButton;
@property (weak, nonatomic) IBOutlet UIButton *resetButton;

@end

@implementation SDViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [self applyStyleToViewController];
}

- (void) applyStyleToViewController
{
    self.inheritanceButton.selected = [[SDThemeManager sharedManager] isInheritanceEnabledForStyle:@"TestViewController"];
    SDThemeManagerApplyStyle(@"TestViewController", self);
    SDThemeManagerApplyStyle(self.inheritanceButton.selected ? @"CommonColoredButtonSelected" : @"CommonColoredButton", self.inheritanceButton);
}

- (IBAction)segmentControlValueChanged:(UISegmentedControl *)sender
{
    if(sender.selectedSegmentIndex == 0)
    {
        [[SDThemeManager sharedManager] setAlternativeThemes:@[]];
    }
    else
    {
        NSString* themePath = [NSBundle.mainBundle pathForResource:@"theme_2" ofType:@"plist"];
        if (themePath)
        {
            [SDThemeManager.sharedManager setAlternativeThemesWithPaths:@[themePath]];
        }
    }
    
    [self applyStyleToViewController];
}

- (IBAction)modifyStyleTapped:(UIButton*)sender
{
    NSUInteger randomColor1 = arc4random_uniform(16777216);
    NSString* exString1 = [NSString stringWithFormat:@"c:%02lx",(unsigned long)randomColor1];
    
    NSUInteger randomColor2 = arc4random_uniform(16777216);
    NSString* exString2 = [NSString stringWithFormat:@"c:%02lx",(unsigned long)randomColor2];
    
    [[SDThemeManager sharedManager] modifyConstant:@"COLOR_BACKGROUND_COMMON" withValue:exString1];
    [[SDThemeManager sharedManager] modifyConstant:@"DIMENSION_CORNER_RADIUS_COMMON" withValue:@30];
    [[SDThemeManager sharedManager] modifyStlye:@"TestViewController" forKeyPath:@"boldLabel.textColor" withValue:exString2];
    
    [self applyStyleToViewController];
}

- (IBAction)activeInheritanceTapped:(UIButton *)sender
{
    [[SDThemeManager sharedManager] modifyStyle:@"TestViewController" inheritanceEnable:!sender.selected];
    [self applyStyleToViewController];
    
    NSDictionary* dict = [[SDThemeManager sharedManager] mergedValueForStyle:@"TestViewController"];
    NSLog(@"%@", dict);
}

- (IBAction)peristModifiesTapped:(UIButton *)sender
{
    [[SDThemeManager sharedManager] synchronizeModifies];
    [self applyStyleToViewController];
}

- (IBAction)resetModifiesTapped:(UIButton *)sender
{
    [[SDThemeManager sharedManager] resetModifies];
    [self applyStyleToViewController];
}

@end
