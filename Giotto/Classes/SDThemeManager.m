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

#import "SDThemeManager.h"
#import "NSObject+ThemeManager.h"

#ifndef IS_IPAD
#define IS_IPAD ( UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad )
#endif

#define FORMAT_VERSION_KEY       @"formatVersion"
#define CONSTANTS_KEY            @"Constants"
#define STYLES_KEY               @"Styles"

#define COLOR_IDENTIFIERS        @[@"color:", @"c:"]
#define STYLE_IDENTIFIERS        @[@"style:", @"s:"]
#define FONT_IDENTIFIERS         @[@"font:", @"f:"]
#define NULL_IDENTIFIERS         @[@"null", @"NULL", @"Null", @"nil", @"Nil"]

#define SIZE_IDENTIFIER          @"size:"
#define POINT_IDENTIFIER         @"point:"
#define RECT_IDENTIFIER          @"rect:"
#define EDGE_IDENTIFIER          @"edge:"

#define SYSTEM_FONT_NAME        @"system"
#define SYSTEM_BOLD_FONT_NAME   @"systembold"
#define SYSTEM_ITALIC_FONT_NAME @"systemitalic"

#define SUPERSTYLE_KEY           @"_superstyle"
#define INHERIT_FROM_DEFAULT_THEME @"_inherit"

#define XCODE_COLORS_ESCAPE      @"\033["
#define XCODE_COLORS_RESET       XCODE_COLORS_ESCAPE @";"   // Clear any foreground or background color

#define IPHONE_VARIANT           @"IPHONE"
#define IPAD_VARIANT             @"IPAD"

SDThemeManager* themeManagerSharedInstance(){
    return [SDThemeManager sharedManager];
}

id SDThemeManagerValueForConstant(NSString* key){
    return [themeManagerSharedInstance() valueForConstantWithName: key];
}
void SDThemeManagerApplyStyle (NSString* key, NSObject* object){
    [themeManagerSharedInstance() applyStyleWithName: key toObject: object];
}

@implementation SDThemeManager

#pragma mark - Singleton Pattern
+ (instancetype) sharedManager
{
    static dispatch_once_t pred;
    static id sharedManagerInstance_ = nil;
    
    dispatch_once(&pred, ^{
        sharedManagerInstance_ = [[self alloc] init];
    });
    
    return sharedManagerInstance_;
}

#pragma mark - Load methods

- (id) init
{
    self = [super init];
    if (self)
    {
        
#if BLABBER
        SDLogLevel logLevel = SDLogLevelWarning;
#if DEBUG
        logLevel = SDLogLevelVerbose;
#endif
        
        [[SDLogger sharedLogger] setLogLevel:logLevel forModuleWithName:self.loggerModuleName];
#endif
        defaultTheme = [self loadThemeFromPlist:THEME_DEFAULT_PLIST_NAME];
        if (defaultTheme)
        {
            themes = @[defaultTheme];
        }
        else
        {
            SDLogModuleError(kThemeManagerLogModuleName, @"Tema di default non trovato");
        }
    }
    return self;
}


/**
 *  Carica il tema dal plist con il nome dato, ne fa le dovute conversioni e modifiche e lo restituisce.
 *
 *  @param plistName il nome del plist da cui caricare il tema (senza l'estensione)
 *
 *  @return Il dictionary del tema caricato o nil
 */
- (NSDictionary*) loadThemeFromPlist:(NSString*)plistName
{
    NSString* path = [[NSBundle mainBundle] pathForResource:plistName ofType:@"plist"];
    if ([[NSFileManager defaultManager] fileExistsAtPath:path])
    {
        // converto il tema per ragioni di retrocompatibilità
        NSDictionary* plistDict = [self convertThemeForCompatibility:[NSDictionary dictionaryWithContentsOfFile:path]];
        
        // struttura che conterrà il tema finale
        NSMutableDictionary* theme = [NSMutableDictionary new];
        
        // struttura che conterrà le entries di tutti i dizionari del plist diversi da "Constants"
        NSMutableDictionary* styles = [NSMutableDictionary new];
        
        for (NSString* key in [plistDict allKeys])
        {
            if ([key isEqualToString:FORMAT_VERSION_KEY] || [key isEqualToString:CONSTANTS_KEY])
            {
                // copio nel tema i valori di "formatVersion" e "Constants"
                theme[key] = plistDict[key];
            }
            else
            {
                // inserisco in styles le entries di tutti i dizionari del plist diversi da "Constants"
                if ([plistDict[key] isKindOfClass:[NSDictionary class]])
                {
                    // ciclo sulle chiavi del dictionary per verificare l'eventuale presenza di doppioni
                    for (NSString* styleKey in [plistDict[key] allKeys])
                    {
                        if (styles[styleKey] != nil)
                        {
                            SDLogModuleWarning(kThemeManagerLogModuleName, @"Chiave duplicata \"%@\" nel dizionario \"%@\" del tema %@. Il valore della chiave duplicata verrà ignorato.", styleKey, key, plistName);
                        }
                        else
                        {
                            styles[styleKey] = plistDict[key][styleKey];
                        }
                    }
                }
                else
                {
                    // non sono ammessi chiavi generiche con valori diversi da NSDictionary
                    SDLogModuleError(kThemeManagerLogModuleName, @"Trovato valore non ammesso per la chiave \"%@\" del tema %@", key, plistName);
                }
            }
        }
        
        // copio styles sotto la generica chiave Styles del tema e lo restituisco
        theme[STYLES_KEY] = styles;
        return theme;
    }
    else
    {
        SDLogModuleError(kThemeManagerLogModuleName, @"Tema non trovato: %@", plistName);
    }
    return nil;
}

- (void) setAlternativeThemes:(NSArray*)alternativeThemes
{
    alternativeThemesPlist = alternativeThemes;
    NSMutableArray* themesNew = [NSMutableArray array];
    if (alternativeThemes.count > 0)
    {
        for (NSString* plistName in alternativeThemes)
        {
            // per ogni plist indicato, se esiste, si aggiunge il tema all'array di temi nell'ordine specificato
            NSDictionary* theme = [self loadThemeFromPlist:plistName];
            if (theme)
            {
                [themesNew addObject:theme];
            }
        }
    }
    // per ultimo si inserisce il tema di default
    [themesNew addObject:defaultTheme];
    themes = [NSArray arrayWithArray:themesNew];
}

#pragma mark - SDLoggerModuleProtocol

#if BLABBER
- (NSString *) loggerModuleName
{
    return kThemeManagerLogModuleName;
}

- (SDLogLevel)loggerModuleLogLevel
{
    return [[SDLogger sharedLogger] logLevelForModuleWithName:self.loggerModuleName];
}

- (void)setLoggerModuleLogLevel:(SDLogLevel)level
{
    [[SDLogger sharedLogger] setLogLevel:level forModuleWithName:self.loggerModuleName];
}
#endif


#pragma mark - Public methods

- (void) applyStyleWithName:(NSString*)styleName toObject:(NSObject*)object
{
    [self applyStyleWithName:styleName toObject:object withVariant:nil];
    if (IS_IPAD)
    {
        // cerca la versione iPad dello stile e la applica
        [self applyStyleWithName:styleName toObject:object withVariant:IPAD_VARIANT];
    }
    else
    {
        // cerca la versione iPhone dello stile e la applica
        [self applyStyleWithName:styleName toObject:object withVariant:IPHONE_VARIANT];
    }
}

/**
 *  @discussion
 *  ATTENZIONE:
 *  Questo metodo pubblico si distingue dal metodo privato constantValueForString: per il fatto che ritorna nil quando la costante non esiste.
 *  Non usare per le logiche interne.
 */
- (id) valueForConstantWithName:(NSString*)constantName
{
    id constantValue = [self valueForKeyPath:[NSString stringWithFormat:@"%@.%@", CONSTANTS_KEY, constantName]];
    
    // se non trovo una costante restituisco nil
    if (!constantValue)
    {
        return nil;
    }
    
    // se il valore è una stringa, cerca eventuali convenzioni, altrimenti restituisco il valore stesso
    if ([constantValue isKindOfClass:[NSString class]])
    {
        return [self valueForConventionalString:constantValue];
    }
    else
    {
        return constantValue;
    }
}

#pragma mark - Old methods for retro-compatibility

- (id) valueForKey:(NSString*)key
{
    NSString* value;
    
    for (NSDictionary* currentTheme in themes)
    {
        // si cerca la chiave in tutti i temi impostati, ordinati (l'ultimo è il tema di default)
        // al primo match si ferma la ricerca e si restituisce il risultato
        value = [currentTheme valueForKeyPath:[NSString stringWithFormat:@"%@.%@", CONSTANTS_KEY, key]];
        if (value)
        {
            break;
        }
    }
    
    return value;
}

- (float) themeFloatForKey:(NSString*)key
{
    NSNumber* themeValue = [self themeNumberForKey:key];
    
    if (themeValue)
    {
        return [themeValue floatValue];
    }
    return 0;
}

- (int) themeIntegerForKey:(NSString*)key
{
    NSNumber* themeValue = [self themeNumberForKey:key];
    
    if (themeValue)
    {
        return [themeValue intValue];
    }
    return 0;
}

- (NSNumber*) themeNumberForKey:(NSString*)key
{
    NSNumber* themeValue = [self valueForKey:key];
    
    return themeValue;
}

- (UIColor*) themeColorForKey:(NSString*)key
{
    NSString* themeValue = [self valueForKey:key];
    
    id color = [self valueForConventionalString:themeValue];
    
    if ([color isKindOfClass:[UIColor class]])
    {
        return color;
    }
    return [self colorForString:themeValue];
}

- (UIFont*) themeFontForKey:(NSString*)key andSize:(CGFloat)fontSize
{
    NSString* themeValue = [self valueForKey:key];
    id font = [self valueForConventionalString:themeValue];
    
    if ([font isKindOfClass:[UIFont class]])
    {
        return [UIFont fontWithName:((UIFont*)font).fontName size:fontSize];
    }
    return [UIFont fontWithName:themeValue size:fontSize];
}

#pragma mark - Utils

- (void) applyStyleWithName:(NSString*)styleName toObject:(NSObject*)object withVariant:(NSString*)variant
{
    NSString* finalStyleName = variant.length > 0 ? [NSString stringWithFormat:@"%@_%@", styleName, variant] : styleName;
    
    if (variant.length > 0 && [self getThemeStyleForKey:finalStyleName] == nil)
    {
        // se viene richiesta la variante ma non esiste, ci si ferma
        return;
    }
    // recupera lo stile indicato
    NSDictionary* style = [self themeStyleForKey:finalStyleName];
    
    // se non ho trovato uno stile con il nome passato, mi fermo segnalando un errore
    if (!style)
    {
        SDLogModuleError(kThemeManagerLogModuleName, @"Style not found with name '%@'", finalStyleName);
        return;
    }
    SDLogModuleVerbose(kThemeManagerLogModuleName, @"Start to applying style: %@", finalStyleName);
    [self applyDictionary:style toObject:object];
}

- (id) getThemeStyleForKey:(NSString*)key fromDefaultTheme:(BOOL)fromDefault
{
    // lo stile viene cercato nel gruppo "Styles"
    id style = [self valueForKeyPath:[NSString stringWithFormat:@"%@.%@", STYLES_KEY, key] fromDefaultTheme:fromDefault];
    return style;
}

- (id) getThemeStyleForKey:(NSString*)key
{
    return [self getThemeStyleForKey:key fromDefaultTheme:NO];
}

/**
 *  Converte i vecchi temi per renderli compatibili con la nuova versione del ThemeManager.
 *
 *  @param theme Dictionary contenente il vecchio tema.
 *
 *  @return Dictionary convertito alle nuove specifiche.
 */
- (NSDictionary*) convertThemeForCompatibility:(NSDictionary*)theme
{
    int version = [[theme objectForKey:FORMAT_VERSION_KEY] intValue];
    
    if (version < 2)
    {
        // il tema caricato è del vecchio tipo, per compatibilità lo si carica tutto dentro la chiave delle costanti
        return @{ CONSTANTS_KEY: theme };
    }
    return theme;
}

/**
 *  Interpreta una stringa in formato esadecimale RRGGBBAA o RRGGBB e la converte in un UIColor.
 *
 *  @param color Stringa in formato esadecimale RRGGBBAA o RRGGBB.
 *
 *  @return Restituisce un UIColor o nil se la stringa passata non rispetta il formato richiesto.
 */
- (UIColor*) colorForString:(NSString*)color
{
    // si interpreta il colore dalla stringa nel formato RRBBGGAA (rosso, verde, blu, alfa)
    if (color.length != 6 && color.length != 8 && color.length != 3 && color.length != 4)
    {
        SDLogModuleError(kThemeManagerLogModuleName, @"Color string %@ in wrong format", color);
        return nil;
    }
    
    if (color.length == 3) // se si specificano solamente i 3 caratteri RGB, si duplicano e si imposta l'alpha al massimo
    {
        const char* chars = [color UTF8String];
        color = [NSString stringWithFormat:@"%c%c%c%c%c%c%@", chars[0], chars[0], chars[1], chars[1], chars[2], chars[2], @"FF"];
    }
    else if (color.length == 4) // se si specificano solamente 4 caratteri RGB, si duplicano tutti
    {
        const char* chars = [color UTF8String];
        color = [NSString stringWithFormat:@"%c%c%c%c%c%c%c%c", chars[0], chars[0], chars[1], chars[1], chars[2], chars[2], chars[3], chars[3]];
    }
    else if (color.length == 6) // se si specificano solamente i 6 caratteri RRGGBB, si appende l'alpha al massimo
    {
        color = [color stringByAppendingString:@"FF"];
    }
    
    NSScanner* scanner = [NSScanner scannerWithString:color];
    
    unsigned hex;
    if (![scanner scanHexInt:&hex])
    {
        return nil;
    }
    int r = (hex >> 24) & 0xFF;
    int g = (hex >> 16) & 0xFF;
    int b = (hex >> 8) & 0xFF;
    int a = (hex) & 0xFF;
    
    return [UIColor colorWithRed:r / 255.0f green:g / 255.0f blue:b / 255.0f alpha:a / 255.0f];
}

- (id) valueForKeyPath:(NSString*)keyPath
{
    return [self valueForKeyPath:keyPath fromDefaultTheme:NO];
}

- (id) valueForKeyPath:(NSString*)keyPath fromDefaultTheme:(BOOL)fromDefault
{
    NSString* value;
    
    if (fromDefault)
    {
        value = [defaultTheme valueForKeyPath:keyPath];
    }
    else
    {
        for (NSDictionary* currentTheme in themes)
        {
            // si cerca la chiave in tutti i temi impostati, ordinati (l'utimo è il tema di default)
            // al primo match si ferma la ricerca e si restituisce il risultato
            value = [currentTheme valueForKeyPath:keyPath];
            if (value)
            {
                break;
            }
        }
    }
    
    return value;
}

/**
 *  Ricerca il stile passato prima nel gruppo Interfaces e (come fallback) nel gruppo Styles del plist.
 *
 *  @param key Nome dello stile da ricercare.
 *
 *  @return Il dictionary dello stile o nil se questo non esiste.
 */
- (NSDictionary*) themeStyleForKey:(NSString*)key fromDefaultTheme:(BOOL)fromDefault
{
    // lo stile viene cercato nel gruppo "interfaces"
    id style = [self getThemeStyleForKey:key fromDefaultTheme:fromDefault];
    
    if ([style isKindOfClass:[NSString class]])
    {
        id value = [self valueForConventionalString:style];
        
        if (![value isKindOfClass:[NSDictionary class]])
        {
            SDLogModuleError(kThemeManagerLogModuleName, @"Style not found with name '%@' for key %@", style, key);
            return nil;
        }
        else
        {
            return value;
        }
    }
    else
    {
        if (!style)
        {
            SDLogModuleError(kThemeManagerLogModuleName, @"Style not found with name '%@' for key %@", style, key);
        }
        return style;
    }
}

- (NSDictionary*) themeStyleForKey:(NSString*)key
{
    return [self themeStyleForKey:key fromDefaultTheme:NO];
}

/**
 *  Applica il dictionary di uno stile all'oggetto passato
 *
 *  @param style  Lo stile da applicare.
 *  @param object L'oggetto al quale va applicato lo stile.
 */
- (void) applyDictionary:(NSDictionary*)style toObject:(NSObject*)object
{
    if ([object isKindOfClass:[NSArray class]])
    {
        NSArray* array = (NSArray*)object;
        for (id element in array)
        {
            [self applyDictionary:style toObject:element];
        }
    }
    else
    {
        // eventuale eredità dal tema default
        NSString* inheritstyleName = style[INHERIT_FROM_DEFAULT_THEME];
        if (inheritstyleName.length > 0)
        {
            NSDictionary* superstyle = [self themeStyleForKey:inheritstyleName fromDefaultTheme:YES];
            [self applyDictionary:superstyle toObject:object];
        }
        
        // applicazione di un eventuale _superstyle
        NSString* superstyleName = style[SUPERSTYLE_KEY];
        
        if (superstyleName.length > 0)
        {
            NSArray* styles = [superstyleName componentsSeparatedByString:@","];
            for (NSString* styleName in styles)
            {
                NSDictionary* superstyle = [self themeStyleForKey:styleName fromDefaultTheme:NO];
                [self applyDictionary:superstyle toObject:object];
            }
        }
        
        // normalizza lo stile parsando le chiavi
        NSDictionary* normalizedStyle = [self normalizeDictionary:style];
        
        // applico i valori alle property elencate nel dictionary
        for (NSString* key in normalizedStyle.allKeys)
        {
            if ([key isEqualToString:SUPERSTYLE_KEY] || [key isEqualToString:INHERIT_FROM_DEFAULT_THEME])
            {
                continue;
            }
            
            [self applyValue:normalizedStyle[key] toKeyPath:key ofObject:object];
        }
    }
}

/**
 *  Normalizza il dictionary passato parsando tutte le sue chiavi.
 *  Prima divide tutte le chiavi che rapprensentano liste di keyPaths divisi da ",".
 *  Per tutte i keyPaths così ottenuti, ne normalizza il primo livello.
 *
 *  Esempio -
 *  Il dictionary:
 *
 *  { "view.layer.borderWidth,view2.layer.borderWidth" : 2} viene trasformato in
 *
 *  {
 *      "view"  : { "layer.borderWidth" : 2 },
 *      "view2" : { "layer.borderWidth" : 2 }
 *  }
 *
 *  @param dictionary Il dictionary da normalizzare.
 *
 *  @return Il dictionary normalizzato.
 */
- (NSDictionary*) normalizeDictionary:(NSDictionary*)dictionary
{
    NSMutableDictionary* normalizedDictionary = [NSMutableDictionary dictionary];
    
    // parsa tutti i keyPaths del dictionary passato in argomento
    for (NSString* originalKeyPaths in dictionary.allKeys)
    {
        // divide gli array espressi con la ","
        NSArray* keyPaths = [originalKeyPaths componentsSeparatedByString:@","];
        
        for (NSString* keyPath in keyPaths)
        {
            // se la chiave è un keyPath, ne trova la parte prima del primo "." che diventa la nuova chiave. Il suo valore è un dictionary al quale viene aggiunta come chiave la parte successiva del keyPath originario, associato al valore originario.
            
            NSInteger dotIndex = [keyPath rangeOfString:@"."].location;
            if (dotIndex != NSNotFound)
            {
                NSString* normalizedKey = [keyPath substringToIndex:dotIndex];
                NSString* subKeyPath = [keyPath substringFromIndex:dotIndex + 1];
                NSDictionary* normalizedValue = nil;
                
                // evito che più keyPaths associati alla chiave normalizzata si sovrascrivano tra loro
                id currentValue = normalizedDictionary[normalizedKey];
                if (currentValue != nil &&
                    [currentValue isKindOfClass:[NSDictionary class]])
                {
                    NSMutableDictionary* unionOfValues = [NSMutableDictionary dictionaryWithDictionary:currentValue];
                    unionOfValues[subKeyPath] = dictionary[originalKeyPaths];
                    normalizedValue = [NSDictionary dictionaryWithDictionary:unionOfValues];
                }
                else
                {
                    normalizedValue = @{ subKeyPath : dictionary[originalKeyPaths] };
                }
                
                normalizedDictionary[normalizedKey] = normalizedValue;
            }
            else
            {
                // il dictionary è già normalizzato
                normalizedDictionary[keyPath] = dictionary[originalKeyPaths];
            }
        }
    }
    
    return [NSDictionary dictionaryWithDictionary:normalizedDictionary];
}

/**
 *  Applica un singolo valore ad un determinato keyPath dell'oggetto passato.
 *
 *  @param value   Il valore da applicare.
 *  @param keyPath Il keyPath della property da valorizzare.
 *  @param object  L'oggetto di cui si vuole valorizzare la property indicata in 'keyPath'.
 */
- (void) applyValue:(id)value toKeyPath:(NSString*)keyPath ofObject:(NSObject*)object
{
    @try {
        // se il value è un dictionary allora si tratta di uno stile innestato, quindi applico lo stile innestato a
        if ([value isKindOfClass:[NSDictionary class]])
        {
            NSObject* objectForKeyPath = [object valueForKeyPath:keyPath];
            [self applyDictionary:value toObject:objectForKeyPath];
        }
        // se il value è una stringa può essere un nome di costante o una delle convenzioni possibili
        else if ([value isKindOfClass:[NSString class]])
        {
            // controllo le convenzioni
            id finalValue = [self valueForConventionalString:value];
            if ([finalValue respondsToSelector:@selector(isEqualToString:)] && [finalValue isEqualToString:value])
            {
                // non ha trovato convenzioni. cerco tra le costanti
                finalValue = [self constantValueForString:value];
            }
            
            // se il final value è un dictionary di uno stile, allora richiamo il metodo per applicarlo
            if ([finalValue isKindOfClass:[NSDictionary class]])
            {
                [self applyValue:finalValue toKeyPath:keyPath ofObject:object];
            }
            // altrimenti applico il valore al keypath passato
            else
            {
#if DEBUG
                NSString* initialClassName = [self classNameForKey:keyPath ofObject:object];
#endif
                SDLogModuleVerbose(kThemeManagerLogModuleName, @"Applying value: %@ to keyPath: %@ of object of class: %@", finalValue, keyPath, NSStringFromClass([object class]));
                if ([object respondsToSelector:@selector(shouldApplyThemeCustomizationForKeyPath:)] &&
                    [object shouldApplyThemeCustomizationForKeyPath:keyPath])
                {
                    [object applyCustomizationOfThemeValue:finalValue forKeyPath:keyPath];
                }
                else
                {
                    [object applyThemeValue:finalValue forKeyPath:keyPath];
                }
#if DEBUG
                NSString* finalClassName = [self classNameForKey:keyPath ofObject:object];
                if (![finalClassName isEqualToString:initialClassName] && finalClassName != nil && initialClassName != nil)
                {
                    // purtroppo non è possibile recuperare la classe della property se la property è nil, quindi si devono saltare i casi in cui initial o final sono nil
                    SDLogModuleError(kThemeManagerLogModuleName, @"Possible error: object at keypath %@ of object %@ changed type from %@ to %@", keyPath, NSStringFromClass([object class]), initialClassName, finalClassName);
                }
#endif
            }
        }
        else
        {
            SDLogModuleVerbose(kThemeManagerLogModuleName, @"Applying value: %@ to keyPath: %@ of object of class: %@", value, keyPath, NSStringFromClass([object class]));
            if ([object respondsToSelector:@selector(shouldApplyThemeCustomizationForKeyPath:)] &&
                [object shouldApplyThemeCustomizationForKeyPath:keyPath])
            {
                [object applyCustomizationOfThemeValue:value forKeyPath:keyPath];
            }
            else
            {
                [object applyThemeValue:value forKeyPath:keyPath];
            }
        }
    }
    @catch (NSException* exception)
    {
        SDLogModuleError(kThemeManagerLogModuleName, @"Cannot apply value %@ to keyPath %@ to object of class %@", value, keyPath, object ? NSStringFromClass([object class]) : @"<nil>");
    }
}

/**
 *  Cerca il valore di una costante del dictionary Constants o, nel caso non venga trovata, la stringa passata come argomento
 *
 *  @param string Il nome della costante da trovare.
 *
 *  @return il valore di una costante del dictionary Constants o, nel caso non venga trovata, la stringa passata come argomento
 *
 *  @discussion Questo metodo privato si distingue dal metodo pubblico valueForConstantWithName: per il fatto che restituisce la stringa passata nel caso non trovi la costante. Per le logiche interne deve sempre essere usato questo metodo.
 */
- (id) constantValueForString:(NSString*)string
{
    id constantValue = [self valueForKeyPath:[NSString stringWithFormat:@"%@.%@", CONSTANTS_KEY, string]];
    
    // se non trovo una costante restituisco string
    if (!constantValue)
    {
        return string;
    }
    
    // se il valore è una stringa, cerca eventuali convenzioni, altrimenti restituisco il valore stesso
    if ([constantValue isKindOfClass:[NSString class]])
    {
        return [self valueForConventionalString:constantValue];
    }
    else
    {
        return constantValue;
    }
}

/**
 *  Cerca eventuali convenzioni nella stringa passata e restituisce un valore conforme alla convenzione o la stringa passata nel caso in cui non ci siano convenzioni conosciute.
 *
 *  @param string La stringa da parsare.
 *
 *  @return Un valore conforme alla convenzione trovata. Se trova una convenzione che non viene rispettata o la convenzione NULL restituisce nil. Se non trova alcuna convenzione restituisce string.
 */
- (id) valueForConventionalString:(NSString*)string
{
    NSString* convention = [SDThemeManager conventionIdentifierInString:string];
    
    // convenzione style:
    if ([STYLE_IDENTIFIERS containsObject:convention])
    {
        @try
        {
            NSString* styleName = [string substringFromIndex:convention.length];
            NSArray* styles = [styleName componentsSeparatedByString:@","];
            NSMutableDictionary* styleDictionary = [NSMutableDictionary dictionary];
            for (NSString* style in styles)
            {
                [styleDictionary addEntriesFromDictionary:[self themeStyleForKey:style]];
            }
            return [styleDictionary copy];
        }
        @catch (NSException* exception)
        {
            SDLogModuleError(kThemeManagerLogModuleName, @"'style:' convention used without a valid value. Given value: %@", string);
            return nil;
        }
    }
    // convenzione font:
    if ([FONT_IDENTIFIERS containsObject:convention])
    {
        @try
        {
            // stringa attesa: "font:<NOME_FONT>,<FONT_SIZE>" o "f:<NOME_FONT>,<FONT_SIZE>"
            NSString* fontSpecs = [string substringFromIndex:convention.length];
            NSArray* specs = [fontSpecs componentsSeparatedByString:@","];
            NSString* fontName = [self constantValueForString:specs[0]];
            float fontSize = [[self constantValueForString:specs[1]] floatValue];
            if ([fontName.lowercaseString isEqualToString:SYSTEM_FONT_NAME])
            {
                return [UIFont systemFontOfSize:fontSize];
            }
            if ([fontName.lowercaseString isEqualToString:SYSTEM_BOLD_FONT_NAME])
            {
                return [UIFont boldSystemFontOfSize:fontSize];
            }
            if ([fontName.lowercaseString isEqualToString:SYSTEM_ITALIC_FONT_NAME])
            {
                return [UIFont italicSystemFontOfSize:fontSize];
            }
            UIFont* font = [UIFont fontWithName:fontName size:fontSize];
            return font;
        }
        @catch (NSException* exception)
        {
            SDLogModuleError(kThemeManagerLogModuleName, @"'font:' convention used without a valid value. Given value: %@. Expected value format: 'font:<FONT_NAME>,<FONT_SIZE>'", string);
            return nil;
        }
    }
    // convenzione color:
    if ([COLOR_IDENTIFIERS containsObject:convention])
    {
        @try
        {
            NSString* colorValue = [string substringFromIndex:convention.length];
            UIColor* color = [self colorForString:colorValue];
            if (!color)
            {
                SDLogModuleError(kThemeManagerLogModuleName, @"'color:' convention used without a valid value. Given value: %@. Expected value format: 'color:<RRGGBB>' or 'color:<RRGGBBAA>'", string);
            }
            return color;
        }
        @catch (NSException* exception)
        {
            SDLogModuleError(kThemeManagerLogModuleName, @"'color:' convention used without a valid value. Given value: %@. Expected value format: 'color:<RRGGBB>' or 'color:<RRGGBBAA>'", string);
            return nil;
        }
    }
    // convenzione null
    if ([NULL_IDENTIFIERS containsObject:convention])
    {
        return nil;
    }
    // convenzione point:
    if ([convention isEqualToString:POINT_IDENTIFIER])
    {
        @try
        {
            // stringa attesa: "point:<X_VALUE>,<Y_VALUE>"
            NSString* pointSpecs = [string substringFromIndex:convention.length];
            NSArray* specs = [pointSpecs componentsSeparatedByString:@","];
            CGFloat x = [specs[0] floatValue];
            CGFloat y = [specs[1] floatValue];
            CGPoint point = CGPointMake(x, y);
            return [NSValue valueWithCGPoint:point];
        }
        @catch (NSException* exception)
        {
            SDLogModuleError(kThemeManagerLogModuleName, @"'point:' convention used without a valid value. Given value: %@. Expected value format: 'point:<X_VALUE>,<Y_VALUE>'", string);
            return nil;
        }
    }
    // convenzione size:
    if ([convention isEqualToString:SIZE_IDENTIFIER])
    {
        @try
        {
            // stringa attesa: "size:<WIDTH_VALUE>,<HEIGHT_VALUE>"
            NSString* sizeSpecs = [string substringFromIndex:convention.length];
            NSArray* specs = [sizeSpecs componentsSeparatedByString:@","];
            CGFloat width = [specs[0] floatValue];
            CGFloat height = [specs[1] floatValue];
            CGSize size = CGSizeMake(width, height);
            return [NSValue valueWithCGSize:size];
        }
        @catch (NSException* exception)
        {
            SDLogModuleError(kThemeManagerLogModuleName, @"'size:' convention used without a valid value. Given value: %@. Expected value format: 'size:<WIDTH_VALUE>,<HEIGHT_VALUE>'", string);
            return nil;
        }
    }
    // convenzione rect:
    if ([convention isEqualToString:RECT_IDENTIFIER])
    {
        @try
        {
            // stringa attesa: "rect:<X_VALUE>,<Y_VALUE>,<WIDTH_VALUE>,<HEIGHT_VALUE>"
            NSString* rectSpecs = [string substringFromIndex:convention.length];
            NSArray* specs = [rectSpecs componentsSeparatedByString:@","];
            CGFloat x = [specs[0] floatValue];
            CGFloat y = [specs[1] floatValue];
            CGFloat width = [specs[2] floatValue];
            CGFloat height = [specs[3] floatValue];
            CGRect rect = CGRectMake(x, y, width, height);
            return [NSValue valueWithCGRect:rect];
        }
        @catch (NSException* exception)
        {
            SDLogModuleError(kThemeManagerLogModuleName, @"'rect:' convention used without a valid value. Given value: %@. Expected value format: 'rect:<X_VALUE>,<Y_VALUE>,<WIDTH_VALUE>,<HEIGHT_VALUE>'", string);
            return nil;
        }
    }
    // convenzione edge:
    if ([convention isEqualToString:EDGE_IDENTIFIER])
    {
        @try
        {
            // stringa attesa: "edge:<TOP_VALUE>,<LEFT_VALUE>,<BOTTOM_VALUE>,<RIGHT_VALUE>"
            NSString* edgeSpecs = [string substringFromIndex:convention.length];
            NSArray* specs = [edgeSpecs componentsSeparatedByString:@","];
            CGFloat top = [specs[0] floatValue];
            CGFloat left = [specs[1] floatValue];
            CGFloat bottom = [specs[2] floatValue];
            CGFloat right = [specs[3] floatValue];
            UIEdgeInsets edge = UIEdgeInsetsMake(top, left, bottom, right);
            return [NSValue valueWithUIEdgeInsets:edge];
        }
        @catch (NSException* exception)
        {
            SDLogModuleError(kThemeManagerLogModuleName, @"'edge:' convention used without a valid value. Given value: %@. Expected value format: 'edge:<TOP_VALUE>,<LEFT_VALUE>,<BOTTOM_VALUE>,<RIGHT_VALUE>'", string);
            return nil;
        }
    }
    
    return string;
}

/**
 *  Cerca le convenzioni nella stringa passata
 *
 *  @param string la stringa da parsare
 *
 *  @return Restituisce la convenzione trovata o nil.
 */
+ (NSString*) conventionIdentifierInString:(NSString*)string
{
    // convenzioni per gli stili
    for (NSString* convention in STYLE_IDENTIFIERS)
    {
        if ([string hasPrefix:convention])
        {
            return convention;
        }
    }
    
    // convenzioni per i font
    for (NSString* convention in FONT_IDENTIFIERS)
    {
        if ([string hasPrefix:convention])
        {
            return convention;
        }
    }
    
    // convenzioni per i colori
    for (NSString* convention in COLOR_IDENTIFIERS)
    {
        if ([string hasPrefix:convention])
        {
            return convention;
        }
    }
    
    // convenzione per valore nullo
    for (NSString* convention in NULL_IDENTIFIERS)
    {
        if ([string hasPrefix:convention])
        {
            return convention;
        }
    }
    
    // convenzione per CGPoint
    if ([[string lowercaseString] rangeOfString:POINT_IDENTIFIER].location != NSNotFound)
    {
        return POINT_IDENTIFIER;
    }
    
    // convenzione per CGSize
    if ([[string lowercaseString] rangeOfString:SIZE_IDENTIFIER].location != NSNotFound)
    {
        return SIZE_IDENTIFIER;
    }
    
    // convenzione per CGRect
    if ([[string lowercaseString] rangeOfString:RECT_IDENTIFIER].location != NSNotFound)
    {
        return RECT_IDENTIFIER;
    }
    
    // convenzione per UIEdgeInsets
    if ([[string lowercaseString] rangeOfString:EDGE_IDENTIFIER].location != NSNotFound)
    {
        return EDGE_IDENTIFIER;
    }
    
    return nil;
}

- (NSString*) classNameForKey:(NSString*)key ofObject:(NSObject*)object
{
    if (!object || [key containsString:@":"])
    {
        // si saltano tutte le personalizzazioni legate ad esempio allo stato dei bottoni
        return nil;
    }
    
    if (![object respondsToSelector:NSSelectorFromString(key)])
    {
        return nil;
    }
    id value = [object valueForKey:key];
    if (!value)
    {
        return nil;
    }
    Class class = [value class];
    if ([value isKindOfClass:[UIColor class]])
    {
        // workaround per la gestione dei diversi tipi di colore impostati di default come sfondo e quelli creati invece dal theme manager
        class = [UIColor class];
    }
    return NSStringFromClass(class);
}

@end
