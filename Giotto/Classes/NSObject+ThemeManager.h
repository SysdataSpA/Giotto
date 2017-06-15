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
 *  Questo protocollo definisce i metodi che permettono una gestione 'custom' dei temi al di fuori del pod di SysdataCore.
 */
@protocol ThemeManagerCustomizationProtocol <NSObject>
@optional

/**
 *  Verifica se il keyPath passato è gestito in maniera 'custom' da quanto previsto da SysdataCore.
 *
 *  @param keyPath il keyPath da verificare
 *
 *  @return YES se il keyPath è gestito in maniera 'custom', altrimenti NO.
 *
 *  @discussion Di default restituisce NO.
 */
- (BOOL) shouldApplyThemeCustomizationForKeyPath:(NSString*)keyPath;

/**
 *  Gestisce la stilizzazione del keyPath passato in maniera 'custom' e sovrascrive l'eventuale implementazione prevista da SysdataCore.
 *
 *  @param keyPath il keyPath da stilizzare
 *
 *  @discussion Di default chiama solo il setValue:forKeyPath:
 */
- (void) applyCustomizationOfThemeValue:(id)value forKeyPath:(NSString*)keyPath;

@end

@interface NSObject (ThemeManager) <ThemeManagerCustomizationProtocol>

- (void) applyThemeValue:(id)value forKeyPath:(NSString*)keyPath;

@end
