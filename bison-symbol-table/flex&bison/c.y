%{
#include <stdio.h> /* printf() */
#include <string.h> /* strcpy() */
#include "common.h" /* MAX_STR_LEN */
#include "SymbolTable.h"

int yylex(void);
void yyerror(const char *txt);
void found( const char *nonterminal, const char *value );


// Type check:

// Types used in type-checking
enum TypeCheck {
    NONE,   
    INTEGER,
    REAL,
    STRUCTURE,
    VOIDTYPE,
    ARRAY = 10
};


// Warnings and error messages
enum Messages {
    ERR_MSG,
    WRN_MSG,
    MSG_UNEXP_NON_NUMERIC,
    MSG_INDEX_NON_NUMERIC,
    MSG_TYPES_MISMATCH,
    MSG_UNDECLARED,
    MSG_ALREADY_DECLARED,
    MSG_QUALIF_NOT_ARRAY_TYPE,
    MSG_SYMBOL_NOT_VAR,
    MSG_SYMBOL_NOT_FUNC,
    MSG_INV_FUNC_PARAMS_NUM,
    MSG_INV_FUNC_PARAM
};

const char* st_messages[] = {
    "ERROR",
    "WARNING",
    "Unexpected non-numerical expression",
    "Non-numerical expression as array index",
    "Mismatched types",
    "Undeclared identifier",
    "Identifier already declared",
    "Qualifier used with non-array type",
    "Symbol is not variable",
    "Symbol is not function",
    "Invalid function parameters number",
    "Invalid function parameter type",
};

// Functions variables and definitions
typedef struct {
    int params_types[MAX_FUNC_PARAMS];
    char* params_idents[MAX_FUNC_PARAMS];
    int params_number;
} FuncParams;

FuncParams _funcParams = {{0}, {NULL}, 0};
FuncParams _callParams = {{0}, {NULL}, 0};
void funcParamsReset();
void callParamsReset();

// Variable used to store last met type (or key keyword)
unsigned last_met = 0;

int presence_check(char* ident);
int presence_subscope_check(char* ident);
int if_ident_numeric(char* ident);
int if_type_numeric(unsigned type);
void symbol_table_message(enum Messages type, enum Messages msg, char* param);
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
%type <i> EXPR NUMBER COND_EXPR SUBSCRIPTS QUALIF
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
S_DECLARATION: DATA_TYPE VAR_LIST ';' ;

/* DATA_TYPE */
 /* typ może być jednym z typów prostych: char, unsigned char, short,
    unsigned short, 
    int, unsigned int, unsigned, long, unsigned long, float, double
    lub może być strukturą (STRUCTURE) */
DATA_TYPE: KW_CHAR { last_met = INTEGER; }
    | KW_UNSIGNED KW_CHAR { last_met = INTEGER; }
    | KW_SHORT { last_met = INTEGER; }
    | KW_UNSIGNED KW_SHORT { last_met = INTEGER; }
    | KW_INT { last_met = INTEGER; }
    | KW_UNSIGNED KW_INT { last_met = INTEGER; }
    | KW_UNSIGNED { last_met = INTEGER; }
    | KW_UNSIGNED KW_LONG { last_met = INTEGER; }
    | KW_FLOAT { last_met = REAL; }
    | KW_DOUBLE { last_met = REAL; }
    | STRUCTURE { last_met = STRUCTURE; }
;

/* STRUCTURE */
 /* structura składa się ze słowa kluczowego struct (KW_STRUCT),
    opcjonalnej nazwy struktury (OPT_TAG), lewego nawiasu klamrowego,
    listy pól (FIELD_LIST) i prawego nawiasu klamrowego. */
STRUCTURE: KW_STRUCT OPT_TAG '{' FIELD_LIST '}' INC_SCOPE { 
        found("STRUCT", "");
    }
;

/* OPT_TAG */
 /* opcjonalna nazwa struktury składa się z identyfikatora lub jest pusta */
OPT_TAG: /* puste */  { 
        insertStruct("struct");
    }
    | IDENT { 
        insertStruct("struct");
    }
;

/* FIELD_LIST */
 /* lista pól jest niepustym ciągiem pól (FIELD) */
FIELD_LIST: FIELD 
    | FIELD_LIST FIELD
;

/* FIELD */
/* pole jest deklaracją danych (S_DECLARATION) */
FIELD: S_DECLARATION
;

/* VAR_LIST */
 /* lista zmiennych składa się przynajmniej z jednej zmiennej (VAR). 
    Większa liczba zmiennych powinna być oddzielona przecinkiem */
VAR_LIST: VAR
    | VAR_LIST ',' VAR
;

/* VAR */
 /* zmienna jest identyfikatorem (IDENT) z indeksami (SUBSCRIPTS)
    lub identyfikatorem z podstawieniem wartości 
    początkowej, która może być wyrażeniem arytmetyczno-logicznym (EXPR) lub 
    napisem (STRING_CONST) */
VAR: IDENT SUBSCRIPTS { 
        found("VAR", $1);

        // If ident is already present is current subscope, print error
        // and do not declare variable
        if(presence_subscope_check($1) != 0){
            symbol_table_message(ERR_MSG, MSG_ALREADY_DECLARED, $1);
        }
        else {
            if($2 == ARRAY){
                insertVar($1, last_met + ARRAY);
            }
            else{
                insertVar($1, last_met);
            }
        }
    }
    | IDENT SUBSCRIPTS '=' EXPR { 
        found("VAR", $1);

        if($2 == ARRAY){
            // If arrays is declared with assignment, print error
            // as you cannot initialize arrays in c w/o block definition
            // which is not supported in our pseudo-C
            symbol_table_message(ERR_MSG, MSG_TYPES_MISMATCH, $1);
        }
        else{
            // If ident is already present is current subscope, print error
            // and do not declare variable
            if(presence_subscope_check($1) != 0){
                symbol_table_message(ERR_MSG, MSG_ALREADY_DECLARED, $1);
            }
            else {
                insertVar($1, last_met); 

                // If variable and expression types are mismatched, print warning
                if(last_met != $4){
                    symbol_table_message(WRN_MSG, MSG_TYPES_MISMATCH, $1);
                }
            }
        }
    }
    | IDENT SUBSCRIPTS '=' STRING_CONST {
        found("VAR", $1);

        if($2 == ARRAY){
            // If ident is already present is current subscope, print error
            // and do not declare variable
            if(presence_subscope_check($1) != 0){
                symbol_table_message(ERR_MSG, MSG_ALREADY_DECLARED, $1);
            }
            else {
                insertVar($1, last_met + ARRAY);

                // If variable and expression types are mismatched, print warning
                if(last_met != INTEGER){
                    symbol_table_message(WRN_MSG, MSG_TYPES_MISMATCH, $1);
                }
            }
        }
        else {
            // If ident is not array type, print error
            // as basic type cannot store STRING_CONST in any way
            symbol_table_message(ERR_MSG, MSG_TYPES_MISMATCH, $1);
        }
    }
;


/* SUBSCRIPTS */
 /* indeksy są możliwie pustym ciągiem indeksów (SUBSCRIPT) */
SUBSCRIPTS: /* puste */ { $$ = NONE; }
    | SUBSCRIPTS SUBSCRIPT { $$ = ARRAY; }
;

/* SUBSCRIPT */
 /* indeks jest wyrażeniem w nawiasach kwadratowych */
SUBSCRIPT: '[' EXPR ']' {
        if(!if_type_numeric($2)){
            symbol_table_message(ERR_MSG, MSG_INDEX_NON_NUMERIC, "");
        }
    };

 /* DEKLARACJE FUNKCJI */

/* S_FUNCTION */
 /* deklaracja funkcji składa się z określenia typu zwracanego przez funkcję 
    (DATA_TYPE lub KW_VOID), nagłówka funkcji (FUN_HEAD) oraz ciała funkcji 
    (BLOCK). UWAGA! Należy stworzyć dwie oddzielne reguły dla DATA_TYPE
    oraz KW_VOID */
S_FUNCTION: DATA_TYPE FUN_HEAD BLOCK { 
        found("S_FUNCTION", $2);
    }
    | KW_VOID FUN_HEAD BLOCK {
        found("S_FUNCTION", $2); 
    }
;

/* FUN_HEAD */
 /* nagłówek funkcji rozpoczyna się identyfikatorem (IDENT), po którym w 
    nawiasach okrągłych znajdują się argumenty formalne (FORM_PARAMS) */
FUN_HEAD: IDENT '(' FORM_PARAMS ')' { 
        found("FUN_HEAD", $1);  
        
        if(_funcParams.params_number == 0){
            insertFunc($1, last_met, NULL);
        }
        else{
            insertFunc($1, last_met, _funcParams.params_types);
        }

        for(int i = 0; i < _funcParams.params_number; i++){
            // If ident is already present is current subscope, print error
            // and do not declare variable
            if(presence_subscope_check(_funcParams.params_idents[i]) != 0){
                symbol_table_message(ERR_MSG, MSG_ALREADY_DECLARED,
                 _funcParams.params_idents[i]);
            }
            else {
                insertVar(_funcParams.params_idents[i],
                 _funcParams.params_types[i]);
            }
        }

        // reset state of func params struct
        funcParamsReset();
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
FORM_PARAM: DATA_TYPE IDENT { 
        found("FORM_PARAM", $2);
        
        _funcParams.params_types[_funcParams.params_number] = last_met;
        _funcParams.params_idents[_funcParams.params_number] = calloc(MAX_IDENTIFIER_LENGTH, sizeof(char));
        strcpy(_funcParams.params_idents[_funcParams.params_number], $2);
        _funcParams.params_number++;
    };

/* BLOCK */
 /* blok składa się z pojedynczej instrukcji (INSTRUCTION) lub z umieszczonych
    w nawiasach klamrowych: listy deklaracji danych (DECL_LIST)
    oraz listy instrukcji (INSTR_LIST) */
BLOCK: INSTRUCTION INC_SCOPE { 
        found("BLOCK", "");
    }
    | '{' DECL_LIST INSTR_LIST '}' INC_SCOPE { 
        found("BLOCK", "");
    }
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
FUN_CALL: IDENT '(' ACT_PARAMS ')' ';' { 
    found("FUN_CALL", $1);

    TableEntry* res = lookup($1);
    if(res == NULL){
        symbol_table_message(ERR_MSG, MSG_UNDECLARED, $1);
    }
    else{
        if(res->entryType != FUNC){
            symbol_table_message(ERR_MSG, MSG_SYMBOL_NOT_FUNC, $1);
        }
        else{
            // Check function attributes types
            if(res->pFuncParams != NULL){
                int j = 0;
                while(res->pFuncParams[j] != 0){
                    if(res->pFuncParams[j] != _callParams.params_types[j]){
                        symbol_table_message(WRN_MSG, MSG_INV_FUNC_PARAM, $1);
                    }

                    j++;
                }

                if(j != _callParams.params_number){
                    symbol_table_message(ERR_MSG, MSG_INV_FUNC_PARAMS_NUM, $1);
                }
                

            }
            else{
                if(_callParams.params_number != 0){
                    symbol_table_message(ERR_MSG, MSG_INV_FUNC_PARAMS_NUM, $1);
                }
            }
            
            callParamsReset();
        }
    }
} ;
 
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
ACT_PARAM: EXPR { 
        found("ACT_PARAM", "");
        _callParams.params_types[_callParams.params_number] = $1;
        _callParams.params_number++;
    }
    | STRING_CONST { 
        found("ACT_PARAM", "");

        _callParams.params_types[_callParams.params_number] = INTEGER + ARRAY;
        _callParams.params_number++;
    }
;

/* INCR */
 /* zwiększenie składa się z identyfikatora, kwalifikatora (QUALIF)
    oraz operatora zwiększania (INC) */
INCR: IDENT QUALIF INC { 
    found("INCR", $1);
    if(if_ident_numeric($1) == 0){
        symbol_table_message(ERR_MSG, MSG_UNEXP_NON_NUMERIC, $1);
    }
    else if(if_ident_numeric($1)  == -1){
        symbol_table_message(ERR_MSG, MSG_UNDECLARED, $1);
    }
} ;

/* QUALIF */
 /* kwalifikator może być indeksami (SUBSCRIPTS),
    lub może składać się z kropki, identyfikatora i kwalifikatora */
QUALIF: SUBSCRIPTS { $$ = $1; } 
    | '.' IDENT QUALIF { $$ = 0; }
;

/* ASSIGNMENT */
 /* przypisanie składa się z identyfikatora, kwalifikatora,
    operatora podstawienia oraz wyrażenia */
ASSIGNMENT: IDENT QUALIF '=' EXPR { 
        found("ASSIGNMENT", $1);

        // If assignment inside "for loop" header, declare iterator as KW_INT
        if(last_met == KW_FOR){
            insertVar($1, INTEGER);
        }

        TableEntry* res = lookup($1);
        if(res == NULL){
            symbol_table_message(ERR_MSG, MSG_UNDECLARED, $1);
        }
        else{
            if(res->entryType != VAR){
                symbol_table_message(ERR_MSG, MSG_SYMBOL_NOT_VAR, $1);
            }
            else{
                int ident_type = res->type;                                         
                int expr_type = $4;
        
                // Check array types
                if($2 == ARRAY) {
                    if(ident_type > ARRAY) {
                        // if ident_type is specified as array and it has qualifiers,
                        // change it's value to basic type
                        if( ident_type - ARRAY != expr_type) {
                            symbol_table_message(WRN_MSG, MSG_TYPES_MISMATCH, $1);
                        }
                    }
                    else{
                        // if ident_type is specified as basic and it has qualifiers,
                        // print error
                        symbol_table_message(ERR_MSG, MSG_QUALIF_NOT_ARRAY_TYPE, $1);
                    }
                }
                else{
                    if(ident_type > ARRAY) {
                        // if ident_type is specified as array and it doesn't have qualifiers
                        // print error
                        symbol_table_message(WRN_MSG, MSG_TYPES_MISMATCH, $1);
                    }
                    else{
                        // if ident_type is specified as basic and it doesn't have qualifiers,
                        // check types
                        if( ident_type != expr_type) {
                            symbol_table_message(WRN_MSG, MSG_TYPES_MISMATCH, $1);
                        }
                    }
                }
            }
        }
    } ;

/* NUMBER */
 /* liczba może być liczbą całkowitą lub rzeczywistą */
NUMBER: INTEGER_CONST { $$ = INTEGER; }
    | FLOAT_CONST { $$ = REAL; }
;

/* EXPR */
 /* wyrażenie (EXPR) może być jednym z poniższych:
    liczbą, identyfikatorem z kwalifikatorem,
    dodawaniem, odejmowaniem, mnożeniem,
    dzieleniem, wyrażeniem ujemnym (nadać priorytet NEG),
    wyrażeniem w nawiasach
    lub wyrażeniem warunkowym (COND_EXPR) */
EXPR: NUMBER { $$ = $1; }
    | IDENT QUALIF {
        int type = presence_check($1);

        if(type > ARRAY){
            type -= $2;
        }
        else if(type == 0){
            symbol_table_message(ERR_MSG, MSG_UNDECLARED, $1);
        }

        $$ = type; 
    }
    | '(' EXPR ')' { $$ = $2; }
    | EXPR '+' EXPR { 
        $$ = $1;
        if(!if_type_numeric($1)){
            symbol_table_message(ERR_MSG, MSG_UNEXP_NON_NUMERIC, "");
        }
        if(!if_type_numeric($3)){
            symbol_table_message(ERR_MSG, MSG_UNEXP_NON_NUMERIC, "");
        } 
    }
    | EXPR '-' EXPR { 
        $$ = $1;
        if(!if_type_numeric($1)){
            symbol_table_message(ERR_MSG, MSG_UNEXP_NON_NUMERIC, "");
        }
        if(!if_type_numeric($3)){
            symbol_table_message(ERR_MSG, MSG_UNEXP_NON_NUMERIC, "");
        }
    }
    | EXPR '/' EXPR { 
        $$ = $1; 
        if(!if_type_numeric($1)){
            symbol_table_message(ERR_MSG, MSG_UNEXP_NON_NUMERIC, "");
        }
        if(!if_type_numeric($3)){
            symbol_table_message(ERR_MSG, MSG_UNEXP_NON_NUMERIC, "");
        }
    }
    | EXPR '*' EXPR {
        $$ = $1;
        if(!if_type_numeric($1)){
            symbol_table_message(ERR_MSG, MSG_UNEXP_NON_NUMERIC, "");
        }
        if(!if_type_numeric($3)){
            symbol_table_message(ERR_MSG, MSG_UNEXP_NON_NUMERIC, "");
        }
    }
    | '-' EXPR %prec NEG { 
        $$ = $2;
        if(!if_type_numeric($2)){
            symbol_table_message(ERR_MSG, MSG_UNEXP_NON_NUMERIC, "");
        }

    }
    | COND_EXPR { $$ = $1; }
;

/* FOR_INSTR */
 /* instrukcja for w uproszczonej wersji składa się ze słowa kluczowego for
    (KW_FOR), lewego nawiasu okrągłego, przypisania (ASSIGNMENT), średnika,
    wyrażenia logicznego (LOG_EXPR), średnika, zwiększenia (INCR),
    prawego nawiasu okrągłego i bloku (BLOCK)
 */
FOR_INSTR: INSERT_FOR KW_FOR '(' ASSIGNMENT ';' LOG_EXPR ';' INCR ')' BLOCK { found("FOR_INSTR", ""); };

INSERT_FOR: /* puste */ { 
        insertScope("f");
        last_met = KW_FOR;
    }
;

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
IF_INSTR: INSERT_IF KW_IF '(' LOG_EXPR ')' BLOCK ELSE_PART { found("IF_INSTR", ""); };

INSERT_IF: /* puste */ { 
        insertScope("i");
        last_met = KW_IF;
    }
;

/* ELSE_PART */
/* część else może być pusta lub składać się ze słowa kluczowego else (KW_ELSE)
   i bloku (BLOCK) */
ELSE_PART: /* puste */
    | KW_ELSE INSERT_IF BLOCK
;

/* WHILE_INSTR */
/* pętla while składa się ze słowa kluczowego while (KW_WHILE), lewego nawiasu
   okrągłego, wyrażenia logicznego (LOG_EXPR), prawego nawiasu okrągłego
   i bloku
 */
WHILE_INSTR: KW_WHILE '(' LOG_EXPR ')' INSERT_WHILE BLOCK { found("WHILE_INSTR", ""); };

INSERT_WHILE: /* puste */ { 
        insertScope("w");
        last_met = KW_WHILE;
    }
;

/* DO_WHILE */
/* pętla do while składa się ze słowa kluczowego do (KW_DO), bloku (BLOCK),
   słowa kluczowego WHILE, lewego nawiasu okrągłego,
   wyrażenia logicznego (LOG_EXPR), prawego nawiasu okrągłego i średnika
 */
DO_WHILE: KW_DO INSERT_WHILE BLOCK KW_WHILE '(' LOG_EXPR ')' ';' { found("DO_WHILE", ""); };


/* COND_EXPR */
/* wyrażenie warunkowe składa się z wyrażenia logicznego (LOG_EXPR),
   znaku zapytania, wyrażenia (EXPR), dwukropka i wyrażenia */
COND_EXPR: LOG_EXPR '?' EXPR ':' EXPR { found("COND_EXPR", ""); $$ = INTEGER; };


INC_SCOPE: /* puste */ { incScope(); };

%%


int main( void )
{
	initSymbolTable();

	printf( "Author: Jakub Fedorowicz\n" );
	printf( "yytext              Token type      Token value\n\n" );
	int ret = yyparse();

    printSymbolTable();
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

// reset _funcParams state
void funcParamsReset(){
    for(int i = 0; i < MAX_FUNC_PARAMS; i++){
        _funcParams.params_types[i] = 0;
        _funcParams.params_idents[i] = NULL;
    }
     _funcParams.params_number = 0;
}

// reset _callParams state
void callParamsReset(){
    for(int i = 0; i < MAX_FUNC_PARAMS; i++){
        _callParams.params_types[i] = 0;
    }
     _callParams.params_number = 0;
}

// check if ident is present in current scope
// return type if ident is present in current scope
// return 0 if ident was not found
int presence_check(char* ident){
    TableEntry* res = lookup(ident);

    if( res != NULL){
        return res->type;
    }
    else{
        return 0;
    }
}

// check if ident is present in current subscope
// return type if ident is present in current scope
// return 0 if ident was not found
int presence_subscope_check(char* ident){
    TableEntry* res = lookup_subscope(ident);

    if( res != NULL){
        return res->type;
    }
    else{
        return 0;
    }
}

// return 1 if ident of given type is numeric
// return 0 if it is not
// return -1 if type was not found
int if_ident_numeric(char* ident){
    TableEntry* res = lookup(ident);

    if(res == NULL){
        return -1;
    }

    return if_type_numeric(res->type);
}

// return 1 if type is numeric
// return 0 instead
int if_type_numeric(unsigned type){
    switch(type){
        case INTEGER:
        case REAL:
            return 1;
        default:
            return 0;
    }
}

// print properly formated symbol message
void symbol_table_message(enum Messages type, enum Messages msg, char* param) {
    printf("ST: %s: %s %s.\n", st_messages[type], st_messages[msg], param);
}
