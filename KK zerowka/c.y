%{
#include <stdio.h> /* printf() */
#include <string.h> /* strcpy() */
#include "common.h" /* MAX_STR_LEN */
#include "SymbolTable.h"

struct IdentNode{
    char ident[MAX_IDENTIFIER_LENGTH];

}

int yylex(void);
void yyerror(const char *txt);
 
void found( const char *nonterminal, const char *value );
%}

%union 
{
	char s[ MAX_STR_LEN + 1 ]; /* pole tekstowe dla nazw itp. */
	int i; /* pole całkowite */
	double d; /* pole zmiennoprzecinkowe */
}



%token<i> KW_CHAR KW_UNSIGNED KW_SHORT KW_INT KW_LONG KW_FLOAT KW_VOID KW_FOR
%token<i> KW_DOUBLE KW_IF KW_ELSE KW_WHILE KW_DO KW_STRUCT
%token<i> INTEGER_CONST 
%token<d> FLOAT_CONST
%token<s> STRING_CONST CHARACTER_CONST
%token<i> INC LE
%token<s> IDENT

 /* Priorytety operacji arytmetycznych '+' '-' '*' '/' 'NEG' */
%left '+' '-'
%left '*' '/'
%right NEG
%right COND

%type <s> FUN_HEAD FUN_CALL
%type <s> VAR_LIST VAR
%%

 /* STRUKTURA PROGRAMU W C */

 /* program może być pusty (błąd semantyczny), zawierać błąd składniowy lub
    składać się z listy sekcji (SECTION_LIST) */
Grammar: { yyerror( "Plik jest pusty" ); YYERROR; }
	| error
	/* !!!!!!!! od tego miejsca należy zacząć !!!!!!!!!!!! */
    | SECTION_LIST

;

/* SECTION_LIST */
 /* lista sekcji składa się przynajmniej z 1 sekcji (SECTION) */
SECTION_LIST: SECTION 
    | SECTION_LIST SECTION
;
 
/* SECTION */
 /* sekcja może być deklaracją (S_DECLARATION) lub funkcją (S_FUNCTION) */
SECTION: S_DECLARATION 
    | S_FUNCTION
;

 /* DEKLARACJE DANYCH */

/* S_DECLARACTION */
 /* deklaracja danych składa się z określenia typu (DATA_TYPE) oraz listy 
    zmiennych (VAR_LIST) zakończonych średnikiem */
S_DECLARATION: DATA_TYPE VAR_LIST ';' { 
        found("DECL", $2);
        // TODO: loop which inserts every element in var_list
    };

/* DATA_TYPE */
 /* typ może być jednym z typów prostych: char, unsigned char, short,
    unsigned short, 
    int, unsigned int, unsigned, long, unsigned long, float, double
    lub może być strukturą (STRUCTURE) */
DATA_TYPE: KW_CHAR
    | KW_UNSIGNED KW_CHAR
    | KW_SHORT
    | KW_UNSIGNED KW_SHORT
    | KW_INT
    | KW_UNSIGNED KW_INT
    | KW_UNSIGNED
    | KW_UNSIGNED KW_LONG
    | KW_FLOAT
    | KW_DOUBLE
    | STRUCTURE
;

/* STRUCTURE */
 /* structura składa się ze słowa kluczowego struct (KW_STRUCT),
    opcjonalnej nazwy struktury (OPT_TAG), lewego nawiasu klamrowego,
    listy pól (FIELD_LIST) i prawego nawiasu klamrowego. */
STRUCTURE: KW_STRUCT OPT_TAG '{' FIELD_LIST '}' { 
        found("STRUCT", ""); 
        // TODO: insert new structure; then loop to insert all fields
    }
;

/* OPT_TAG */
 /* opcjonalna nazwa struktury składa się z identyfikatora lub jest pusta */
OPT_TAG: /* puste */ 
    | IDENT
;

/* FIELD_LIST */
 /* lista pól jest niepustym ciągiem pól (FIELD) */
FIELD_LIST: FIELD {
        //TODO: assign FIELD to FIELD_LIST
    }
    | FIELD_LIST FIELD {
        //TODO: assign FIELD to FIELD_LIST
    }
;

/* FIELD */
/* pole jest deklaracją danych (S_DECLARATION) */
FIELD: S_DECLARATION {
        // TODO: assign S_DECLARATION to FIELD
    }
;

/* VAR_LIST */
 /* lista zmiennych składa się przynajmniej z jednej zmiennej (VAR). 
    Większa liczba zmiennych powinna być oddzielona przecinkiem */
VAR_LIST: VAR { 
        strcpy($$, single);
        // TODO: assign var to var_list object
    }
    | VAR_LIST ',' VAR { 
        strcpy($$, list);
        // TODO: assign var to var_list object
    }
;

/* VAR */
 /* zmienna jest identyfikatorem (IDENT) z indeksami (SUBSCRIPTS)
    lub identyfikatorem z podstawieniem wartości 
    początkowej, która może być wyrażeniem arytmetyczno-logicznym (EXPR) lub 
    napisem (STRING_CONST) */
VAR: IDENT SUBSCRIPTS { found("VAR", $1); strcpy($$, $1); }
    | IDENT SUBSCRIPTS '=' EXPR { found("VAR", $1); strcpy($$, $1); }
    | IDENT SUBSCRIPTS '=' STRING_CONST { found("VAR", $1); strcpy($$, $1); }
;


/* SUBSCRIPTS */
 /* indeksy są możliwie pustym ciągiem indeksów (SUBSCRIPT) */
 SUBSCRIPTS: /* puste */
    | SUBSCRIPT
;

/* SUBSCRIPT */
 /* indeks jest wyrażeniem w nawiasach kwadratowych */
SUBSCRIPT: '[' EXPR ']' ;

 /* DEKLARACJE FUNKCJI */

/* S_FUNCTION */
 /* deklaracja funkcji składa się z określenia typu zwracanego przez funkcję 
    (DATA_TYPE lub KW_VOID), nagłówka funkcji (FUN_HEAD) oraz ciała funkcji 
    (BLOCK). UWAGA! Należy stworzyć dwie oddzielne reguły dla DATA_TYPE
    oraz KW_VOID */
S_FUNCTION: DATA_TYPE FUN_HEAD BLOCK { 
        found("S_FUNCTION", $2);
        // TODO: insert new function and all parameters from FUN_HEAD
    }
    | KW_VOID FUN_HEAD BLOCK {
        found("S_FUNCTION", $2); 
        // TODO: insert new function and all parameters from FUN_HEAD
    }
;

/* FUN_HEAD */
 /* nagłówek funkcji rozpoczyna się identyfikatorem (IDENT), po którym w 
    nawiasach okrągłych znajdują się argumenty formalne (FORM_PARAMS) */
FUN_HEAD: IDENT '(' FORM_PARAMS ')' { 
        found("FUN_HEAD", $1); 
        // TODO: 
    }
;

/* FORM_PARAMS */
 /* argumenty formalne mogą być słowem kluczowym void lub listą parametrów 
    formalnych (FORM_PARAM_LIST) */
FORM_PARAMS: KW_VOID
    | FORM_PARAM_LIST
;

/* FORM_PARAM_LIST */
 /* lista parametrów formalnych może być co najmniej 
    jednym argumentem formalnym FORM_PARAM (parametry formalne są rozdzielane
    przecinkiem) */
FORM_PARAM_LIST: FORM_PARAM
    | FORM_PARAM_LIST ',' FORM_PARAM
;

/* FORM_PARAM */
 /* parametr formalny składa się z definicji typu (DATA_TYPE) oraz
    identyfikatora (IDENT) */
FORM_PARAM: DATA_TYPE IDENT { found("FORM_PARAM", $2); };

/* BLOCK */
 /* blok składa się z pojedynczej instrukcji (INSTRUCTION) lub z umieszczonych
    w nawiasach klamrowych: listy deklaracji danych (DECL_LIST)
    oraz listy instrukcji (INSTR_LIST) */
BLOCK: INSTRUCTION { found("BLOCK", ""); }
    | '{' DECL_LIST INSTR_LIST '}' { found("BLOCK", ""); }
;

/* DECL_LIST */
 /* lista deklaracji może być pusta lub składać się z ciągu deklaracji
    (S_DECLARATION) */
DECL_LIST: /* puste */
    | DECL_LIST S_DECLARATION { found("DECL_LIST", ""); } 
;

/* INSTR_LIST */
 /* lista instrukcji może być pusta lub składać się z ciagu instrukcji
    (INSTRUCTION) */
INSTR_LIST: /* puste */
    | INSTR_LIST INSTRUCTION
;

/* INSTRUKCJE PROSTE i KONSTRUKCJE ZŁOŻONE

/* INSTRUCTION */
 /* instrukcją może być: instrukcja pusta (;), wywołanie funkcji (FUN_CALL), 
    instrukcja for (FOR_INSTR), przypisanie (ASSIGNMENT) zakończone średnikiem,
    zwiększenie wartości zmiennej (INCR) zakończone średnikiem,
    instrukcja warunkowa (IF_INSTR), pętla while (WHILE_INSTR),
    pętla do...while (DO_WHILE)  */
INSTRUCTION: ';'
    | FUN_CALL
    | FOR_INSTR
    | ASSIGNMENT ';'
    | INCR ';'
    | IF_INSTR
    | WHILE_INSTR
    | DO_WHILE
;

/* FUN_CALL */
 /* wywołanie funkcji składa się z identyfikatora oraz argumentów aktualnych
    (ACT_PARAMS) umieszczonych w nawiasach okrągłych. Całość jest zakończona
    średnikiem. */
FUN_CALL: IDENT '(' ACT_PARAMS ')' ';' { found("FUN_CALL", $1); } ;
 
/* ACT_PARAMS */
 /* argumenty aktualne mogą być puste lub zawierać listę argumentów
    (ACT_PARAM_LIST) */
ACT_PARAMS: /* puste */
    | ACT_PARAM_LIST
;

/* ACT_PARAM_LIST */
 /* lista argumentów aktualnych może zawierać jeden argument aktualny (ACT_PARAM) 
    lub składać się z argumentów aktualnych oddzielonych od siebie
    przecinkiem */
ACT_PARAM_LIST: ACT_PARAM
    | ACT_PARAM_LIST ',' ACT_PARAM
;

/* ACT_PARAM */
/* argument aktualny może być wyrażeniem (EXPR) lub napisem (STRING_CONST) */
ACT_PARAM: EXPR { found("ACT_PARAM", ""); }
    | STRING_CONST { found("ACT_PARAM", ""); }
;

/* INCR */
 /* zwiększenie składa się z identyfikatora, kwalifikatora (QUALIF)
    oraz operatora zwiększania (INC) */
INCR: IDENT QUALIF INC { found("INCR", $1); } ;

/* QUALIF */
 /* kwalifikator może być indeksami (SUBSCRIPTS),
    lub może składać się z kropki, identyfikatora i kwalifikatora */
QUALIF: SUBSCRIPTS
    | '.' IDENT QUALIF
;

/* ASSIGNMENT */
 /* przypisanie składa się z identyfikatora, kwalifikatora,
    operatora podstawienia oraz wyrażenia */
ASSIGNMENT: IDENT QUALIF '=' EXPR { found("ASSIGNMENT", $1); } ;

/* NUMBER */
 /* liczba może być liczbą całkowitą lub rzeczywistą */
NUMBER: INTEGER_CONST
    | FLOAT_CONST
;

/* EXPR */
 /* wyrażenie (EXPR) może być jednym z poniższych:
    liczbą, identyfikatorem z kwalifikatorem,
    dodawaniem, odejmowaniem, mnożeniem,
    dzieleniem, wyrażeniem ujemnym (nadać priorytet NEG),
    wyrażeniem w nawiasach
    lub wyrażeniem warunkowym (COND_EXPR) */
EXPR: NUMBER
    | IDENT QUALIF 
    | '(' EXPR ')'
    | EXPR '+' EXPR
    | EXPR '-' EXPR
    | EXPR '/' EXPR
    | EXPR '*' EXPR
    | '-' EXPR %prec NEG
    | COND_EXPR
;

/* FOR_INSTR */
 /* instrukcja for w uproszczonej wersji składa się ze słowa kluczowego for
    (KW_FOR), lewego nawiasu okrągłego, przypisania (ASSIGNMENT), średnika,
    wyrażenia logicznego (LOG_EXPR), średnika, zwiększenia (INCR),
    prawego nawiasu okrągłego i bloku (BLOCK)
 */
FOR_INSTR: KW_FOR '(' ASSIGNMENT ';' LOG_EXPR ';' INCR ')' BLOCK { found("FOR_INSTR", ""); };

/* LOG_EXPR */
 /* wyrażenie logiczne może składać się z dwóch wyrażeń arytmetycznych (EXPR),
    pomiędzy którymi mogą wystąpić operatory <= (LE), < i >. */
LOG_EXPR: EXPR LE EXPR
    | EXPR '<' EXPR
    | EXPR '>' EXPR
;

/* IF_INSTR */
 /* instrukcja if  składa się ze słowa kluczowego if, lewego nawiasu okrągłego,
    wyrażenia logicznego (LOG_EXPR), prawego nawiasu okrągłego, bloku (BLOCK)
    i części else (ELSE_PART)
  */
IF_INSTR: KW_IF '(' LOG_EXPR ')' BLOCK ELSE_PART { found("IF_INSTR", ""); };

/* ELSE_PART */
/* część else może być pusta lub składać się ze słowa kluczowego else (KW_ELSE)
   i bloku (BLOCK) */
ELSE_PART: /* puste */
    | KW_ELSE BLOCK
;

/* WHILE_INSTR */
/* pętla while składa się ze słowa kluczowego while (KW_WHILE), lewego nawiasu
   okrągłego, wyrażenia logicznego (LOG_EXPR), prawego nawiasu okrągłego
   i bloku
 */
WHILE_INSTR: KW_WHILE '(' LOG_EXPR ')' BLOCK { found("WHILE_INSTR", ""); };

/* DO_WHILE */
/* pętla do while składa się ze słowa kluczowego do (KW_DO), bloku (BLOCK),
   słowa kluczowego WHILE, lewego nawiasu okrągłego,
   wyrażenia logicznego (LOG_EXPR), prawego nawiasu okrągłego i średnika
 */
DO_WHILE: KW_DO BLOCK KW_WHILE '(' LOG_EXPR ')' ';' { found("DO_WHILE", ""); };

/* COND_EXPR */
/* wyrażenie warunkowe składa się z wyrażenia logicznego (LOG_EXPR),
   znaku zapytania, wyrażenia (EXPR), dwukropka i wyrażenia */
COND_EXPR: LOG_EXPR '?' EXPR ':' EXPR { found("COND_EXPR", ""); };

%%


int main( void )
{
	initSymbolTable();
    printSymbolTable();

	printf( "Author: Jakub Fedorowicz\n" );
	printf( "yytext              Typ tokena      Wartosc tokena znakowo\n\n" );
	int ret = yyparse();
	return ret;
}

void yyerror( const char *txt )
{
	printf( "Syntax error %s\n", txt );
}

void found( const char *nonterminal, const char *value )
{ /* informacja o znalezionych strukturach składniowych (nonterminal) */
	printf( "======== FOUND: %s %s%s%s ========\n", nonterminal, 
		(*value) ? "'" : "", value, (*value) ? "'" : "" );
}
