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

#import <UIKit/UIKit.h>
#import "SDThemeLogger.h"

#pragma mark - THEME MANAGER

#define themeIntForKey(key) \
[[SDThemeManager sharedManager] themeIntegerForKey: key]

#define themeFloatForKey(key) \
[[SDThemeManager sharedManager] themeFloatForKey: key]

#define themeNumberForKey(key) \
[[SDThemeManager sharedManager] themeNumberForKey: key]

#define themeValueForKey(key) \
[[SDThemeManager sharedManager] valueForKey: key]

#define themeColorForKey(key) \
[[SDThemeManager sharedManager] themeColorForKey: key]

#define themeFontForKeyAndSize(key, size) \
[[SDThemeManager sharedManager] themeFontForKey: key andSize: size]

@class SDThemeManager;

SDThemeManager* themeManagerSharedInstance();

id SDThemeManagerValueForConstant(NSString* key);

void SDThemeManagerApplyStyle (NSString* key, NSObject* object);

#define THEME_DEFAULT_PLIST_NAME @"theme_default"

/**
 *  Questa classe permette di gestire file di tema con logica di chiave/valore e alcune utility per accedere ai valori tipizzandoli (UIColor, int, float, NSNumber)
 *  Va previsto sempre un tema di default (theme_default.plist)
 *  E' possibile specificare più file di tema in ordine di priorità utilizzando setAlternativeThemes: e specificando un array di NSString, nomi dei differenti file plist
 *  Per modificare la logica di accesso ai temi, vincolandola ad esempio a eventi o stati specifici (es.: utente loggato/non loggato) è necessario sovrascrivere il motodo valueForKey:
 *
 *  Si consiglia di utilizzare la libreria ReflectableEnum - https://github.com/fastred/ReflectableEnum - per avere comodi i nomi delle chiavi dei temi, per evitare di dover creare un milione di define (vedere il progetto Zoppas Stone per riferimento). In particolare, creare un ENUM per tipologia (colori, immagini, dimensioni, font, ...)
 *  Per l'accesso al valore contenuto nel file di tema è necessario specificare una chiave
 */


#if BLABBER
@interface SDThemeManager : NSObject <SDLoggerModuleProtocol>
#else
@interface SDThemeManager : NSObject
#endif
{
    NSDictionary* defaultTheme;
    NSArray* alternativeThemesPlist;
    NSArray* themes;
}

/**
 *  Invocando questo metodo si permette l'utilizzo di temi alternativi oltre a quello di default, che va specificato comunque nel file theme_default.plist
 *
 *  @param alternativeThemes array contenente i nomi ordinati dei plist contenenti versioni alternative dei temi, senza esntensione; la chiave di ogni valore verrà cercata prima all'interno di essi, nell'ordine con cui sono stati inseriti e, per finire, nel tema di default
 */
- (void) setAlternativeThemes:(NSArray*)alternativeThemes;

+ (instancetype) sharedManager;

#pragma mark - Old methods for retro-compatibility
/**
 *  A questo metodo accedono tutti gli altri per recuperare informazioni dai file di tema
 *  Sovrascriverlo per personalizzare l'accesso ai temi vincolandolo a eventi o stati specifici (es.: utente loggato/non loggato)
 *
 *  @param key chiave da ricercare nel file di tema
 *
 *  @return il valore corrispondente alla chiave
 */
- (id) valueForKey:(NSString*)key;
- (UIColor*) themeColorForKey:(NSString*)key __deprecated;
- (UIFont*) themeFontForKey:(NSString*)key andSize:(CGFloat)fontSize __deprecated;
- (NSNumber*) themeNumberForKey:(NSString*)key __deprecated;
- (float) themeFloatForKey:(NSString*)key __deprecated;
- (int) themeIntegerForKey:(NSString*)key __deprecated;
#pragma mark - New methods
/**
 *  Questo metodo va utilizzato solo se si definisce il plist del tema con la struttura Constants-Styles-Interfaces.
 *
 *  @param styleName Il nome di un elemento del dictionary Styles o Interfaces del plist.
 *  @param object    L'oggetto al quale va applicato il tema
 */
- (void) applyStyleWithName:(NSString*)styleName toObject:(NSObject*)object;

/**
 *  Metodo di utility per recuperare il valore associato ad una costante.
 *
 *  @param constantName Nome di una costante.
 *
 *  @return Il valore associato alla costante o nil se la costante non esiste.
 */
- (id) valueForConstantWithName:(NSString*)constantName;

@end
