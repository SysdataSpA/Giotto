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

#import <Foundation/Foundation.h>


/**
 * This protocol defines the methods that allow 'custom' management of the themes outside the SysdataCore pod.
*/
@protocol ThemeManagerCustomizationProtocol <NSObject>
@optional

/**
 * Verifies whether the past keyPath is managed 'custom' by what SysdataCore provides.
 *
 * @param keyPath the keyPath to verify
 *
 * @return YES if keyPath is handled in 'custom' mode, otherwise NO.
 *
 * @discussion By default it returns NO.
 */
- (BOOL) shouldApplyThemeCustomizationForKeyPath:(NSString*)keyPath;

/**
 * It manages the stylization of the passed keyPath in a custom way and overwrites any implementation expected by SysdataCore.
 *
 * @param keyPath the keyPath to be stylized
 *
 * @discussion By default it only calls the setValue: forKeyPath:
 */
- (void) applyCustomizationOfThemeValue:(id)value forKeyPath:(NSString*)keyPath;

@end

@interface NSObject (ThemeManager) <ThemeManagerCustomizationProtocol>

- (void) applyThemeValue:(id)value forKeyPath:(NSString*)keyPath;

@end
