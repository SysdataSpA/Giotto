# SDThemeManager v.2
## Sommario
> [*Introduzione*](#introduzione)
> 
> [*Il Plist*](#il-plist)
> 
> >[*Constants*](#constants)
> >
> >[*Gruppi di stili*](#gruppi-di-stili)
> >
> >[*Convezioni*](#convenzioni)
> >
> > >[*Convenzioni per le chiavi*](#convenzioni-per-le-chiavi)
> > >
> > >[*Convenzioni per i valori*](#convenzioni-per-i-valori)
> >
> >[*Le chiavi di uno stile*](#le-chiavi-di-uno-stile)
>
>[*Applicazione di uno stile*](#applicazione-di-uno-stile)
>
>[*Gestione speciale di singole property*](#gestione-speciale-di-singole-property)
>
>[*Temi alternativi*](#temi-alternativi)
>
>[*Retrocompatibilità*](#retrocompatibilità)

Introduzione
============

Il SDThemeManager (da qui in poi denominato TM) nasce
principalmente con l’intenzione di semplificare e uniformare lo sviluppo
di applicazioni che richiedono il rebranding della GUI.

Il Plist
====================
Il plist che descrive un tema deve contenere un dizionario Constants con tutte le costanti, mentre gli stili possono essere organizzati a piacimento in altri dizionari.

### Constants
Contiene tutte le costanti come i nomi dei font, i colori o le dimensioni.
Tecnicamente si tratta di un dictionary a un unico livello organizzato come segue:
```<nome_costante> : <valore_costante>```
Per convenzione le chiavi hanno i seguenti prefissi:
> * nomi di font: la chiave inizia con ```FONT_```
> * codici colore: la chiave inizia con ```COLOR_```
> * dimensioni (interi o float): la chiave inizia con ```DIMENSION_```

Esempi:

```
{
	“FONT_REGULAR” : “Helvetica-Neue”,
	“COLOR_COMMON_BACKGROUND” : “color:000000FF”,
	“DIMENSION_VIEW_WIDTH” : 3 //il valore è un NSNumber
}
```

La convenzione ```color:``` è spiegata nella sezione [*Convenzioni*](#convenzioni)
Le Constants **non possono** contenere un array o un dizionario come valore.

### Gruppi di stili

Allo stesso livello di Constants possono essere definiti altri dizionari che fungono da gruppi degli stili degli elementi grafici. I nomi dei gruppi sono liberi.
Tecnicamente si tratta di dizionari organizzati come segue:
```<nome_stile> : <dizionario_stile>```
Il dizionario di uno stile è organizzato come segue:
```<nome_property> : <valore_da_applicare>```
Esempi:

```
{ 
	“CommonLabel” : 
	{ 
		“_superstyle”: <nome_altro_stile>,
		“textColor” : “COLOR_COMMON_LABEL”,
		“font”: “font:FONT_REGULAR,18” 
	},
	“HomeViewController” : 
	{
		“titleLabel” : “style:CommonLabel”,
		“textField” : 
		{
			“textColor” : “color:FFFFFF”,
			“width” : “DIMENSION_FIELD_WIDTH”,
			“layer.borderWidth” : 2 
		}
	}
}
```

Le convenzioni ```_superstyle"```, ```style:``` e ```font:``` sono spiegate nella sezione [*Convenzioni*](#convenzioni)


### Convenzioni

Al fine di rendere più rapida la stesura dei temi e per consentire la gestione di casi particolari ma frequenti, sono state definite le seguenti convenzioni:
#### Convenzioni per le chiavi
 
> * ```_superstyle``` : può essere inserita nel dizionario di uno stile per indicare che lo stile eredita da un altro stile. Quando presente lo stile “parent” viene applicato prima dello stile “child”, quindi è possibile sovrascrivere i keyPath nel “child”. È possibile ereditare da più stili, mettendoli in sequenza divisi da un ",". Gli stili così indicati saranno applicati in ordine, quindi lo stile indicato dopo sovrascrive il valore dei keyPaths che ha in comune con uno stile che lo precede nella lista. 

#### Convenzioni per i valori
 
> *	```style:nome_stile1,nome_stile2```:  la property indicata nella chiave viene stilizzata con gli stili indicati in lista. Gli stili indicati devono essere presenti in uno dei gruppi di stili. Versione abbreviata ```s: nome_stile1,nome_stile2```. Come per ```_superstyle```gli stili indicati sono applicati in ordine.
> * ```font:nome_font, font_size```: instanzia un UIFont e lo setta come valore della property indicata nella chiave. Questa convenzione può essere usata anche nelle Constants. Versione breve ```f: nome_font, font_size```. 
> 
> > il ```nome_font``` può assumere a sua volta dei valori convenzionali per caricare il font di sistema:
> >
> > >	*	```system```
> > > * 	```systemBold```
> > > * 	```systemItalic```
>
> *	```color:stringa_colore```: interpreta *stringa_colore* per instanziare un UIColor con cui valorizza la property indicata nella chiave. Questa convenzione può essere usata anche nelle Constants. Versione breve ```c: stringa_colore```.
> * ```null``` o ```nil```: setta la property indicata nella chiave come ```nil```.
> * ```point:x,y```: setta la property come un CGPoint con in valori x e y indicati. I valori x e y sono interpretati come float.
> * ```size:width,height```: setta la property come una CGSize con in valori width e height indicati. I valori sono interpretati come float.
> * ```rect:x,y,width,height```: setta la property come un CGRect con in valori x, y, width e height indicati. I valori sono interpretati come float.
> * ```edge:top,left,bottom,right```: setta la property come un UIEdgeInsets con in valori top, left, bottom e right indicati. I valori sono interpretati come float.

### Le chiavi di uno stile

Come già detto uno stile si presenta come un dictionary in uno dei gruppi di stili e può essere applicato ad un qualunque NSObject (tipicamente un elemento di interfaccia).
Le chiavi del dictionary possono essere:
>	*	una delle convenzioni indicate le chiavi (vedere paragrafo dedicato)
>	*	una property dell’oggetto da stilizzare
>	*	il keyPath di una di una property dell’oggetto da stilizzare (es. “layer.borderColor”) 
>	*	una stringa che non indica una vera property, ma che sarà gestita nell’apposito metodo che ogni oggetto eredita dalla category **NSObject+ThemeManager** (vedi capitolo [*Gestione speciale di singole property*](#gestione-speciale-di-singole-property)).
>	*	una lista di properties o keyPaths separati da **","** (es. textColor,layer.borderColor).

La property indicata può essere anche un NSArray (come un IBOutletCollection). In tal caso il valore viene applicato a tutti gli oggetti dell’array.

Applicazione di uno stile
=========================
Per applicare uno stile dichiarato nel PList ad un oggetto è sufficiente la seguente riga di codice:

```
[[SDThemeManager sharedManager] applyStyleWithName:@"NomeStile" toObject:object];
```

L’oggetto indicato può essere anche **self**.

Gestione speciale di singole property
=====================================
La libreria contiene una category *NSObject+ThemeManager* che espone il metodo:

```
- (void) applyThemeValue:(id)value forKeyPath:(NSString*)keyPath;
```

Questo metodo viene sovrascritto dalle category di alcune sottoclassi per gestire in maniera speciale alcune property. Queste category sono sempre incluse nella libreria Sysdata.
Ad esempio *UITextField+ThemeManager* gestisce la fake property **placeholderColor** per stilizzare l’**attributedPlaceholder**.

La category NSObject+ThemeManager dichiara anche il protocollo:

```
@protocol ThemeManagerCustomizationProtocol <NSObject>
@optional
- (BOOL) shouldApplyThemeCustomizationForKeyPath:(NSString*)keyPath;
- (void) applyCustomizationOfThemeValue:(id)value forKeyPath:(NSString*)keyPath;
@end
```

I metodi di questo protocollo consentono la gestione custom delle property al di fuori della libreria stessa. Questi sono gli unici metodi che devono essere usati fuori dalla libreria per non rischiare di implementare più volte il metodo precedentemente descritto.

Il metodo ```shouldApplyThemeCustomizationForKeyPath:```deve ritornare ```YES```solo per i keyPath che si intende gestire manualmente.
Il metodo ```applyCustomizationOfThemeValue:forKeyPath:``` deve contenere l’implementazione custom per i keyPath accettati dal metodo precedente.

Temi alternativi
=================

Il ThemeManager richiede obbligatoriamente un tema di **default** ed è possibile indicargli facoltativamente uno o più stili alternativi mediante il metodo:

```
- (void) setAlternativeThemes:(NSArray*)alternativeThemes
```

L’array passato deve contenere i nomi dei file plist dei temi alternativi.
Quando si prova ad applicare uno stile, il ThemeManager lo cerca nel primo tema alternativo. Se non lo trova lo cerca nel secondo e così via. Se nessuno dei temi alternativi contiene lo stile indicato, il ThemeManager lo cerca nel tema di default.
**L’ordine è importante.**

Retrocompatibilità
==================

La versione 2 del ThemeManager è retrocompatibile. Per gestire la retrocompatibilità con i vecchi formati di Plist, i nuovi devono obbligatoriamente contenere la coppia chiave-valore:
```“formatVersion” : 2``

