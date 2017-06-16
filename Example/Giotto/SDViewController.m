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


@end

@implementation SDViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    
//    [[SDThemeManager sharedManager] modifyConstant:@"COLOR_TEXT_COMMON" withValue:@"c:C80028"];
//    [[SDThemeManager sharedManager] modifyConstant:@"DIMENSION_CORNER_RADIUS_COMMON" withValue:@30];
//
//    [[SDThemeManager sharedManager] modifyStlye:@"TestViewController" forKeyPath:@"boldLabel.textColor" withValue:@"c:000"];
//    [[SDThemeManager sharedManager] modifyStyle:@"TestViewController" inheritanceEnable:NO];
    [[SDThemeManager sharedManager] resetModifies];
    
    [self applyStyleToViewController];
}

- (void) applyStyleToViewController
{
    SDThemeManagerApplyStyle(@"TestViewController", self);
}

- (IBAction)segmentControlValueChanged:(UISegmentedControl *)sender
{
    if(sender.selectedSegmentIndex == 0)
    {
        [[SDThemeManager sharedManager] setAlternativeThemes:@[]];
    }
    else
    {
         [[SDThemeManager sharedManager] setAlternativeThemes:@[@"theme_2"]];
    }
    
    [self applyStyleToViewController];
}
@end
