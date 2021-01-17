%{
#include <stdio.h> /* printf() */
#include <string.h> /* strcpy */
#include <stdlib.h> /* atoi(), atof() */
#include "common.h" /* MAX_STR_LEN */
#include "c.tab.h" /* declarations for terminal symbols */

/* print information about the terminal symbol found  */
int process_token(const char *text, const char *TokenType,
                  const char *TokenVal, const int TokenID); 

int str_beg = 0;  /* line number for beginning of string */
int comm_beg = 0; /* line number for beginning of comment */
%}

%option yylineno

/* declaration of start conditions */
/* (start  condition INITIAL does not need to be declared) */
/* ..................... */

%x COMMENT STRING INCLUDE
%%

 /* removal of multi-line comments using start conditions */
<INITIAL>"/*" { BEGIN(COMMENT); comm_beg = yylineno; yymore();} /* wejdź w warunek */
<COMMENT>"*/" { BEGIN(INITIAL); } /* pomiń wnętrze komentarza */
<COMMENT>.|\n /* pomiń wnętrze komentarza */


 /* removal of one-line comments without using start conditions */
\/\/.*$ ;


 /* detection of error: unexpected closing of comment */
<INITIAL>"*/" { fprintf(stderr, "Unexpected closing of comment in line %d\n", yylineno); } /* wejdź w warunek */


 /* detection of strings ".." using start conditions */
<INITIAL>\"   { BEGIN(STRING); str_beg = yylineno; yymore();} /* wejdź w warunek */
<STRING>\"    { BEGIN(INITIAL); return process_token(yytext, "STRING_CONST", yytext, STRING_CONST); } /* wyjdź z warunku */
<STRING>.     { yymore(); }
<STRING>\n    { BEGIN(INITIAL); fprintf(stderr, "Unfinished string opened in line %d\n", str_beg); }


 /* detection of directives in form of #include <name.h> and #include "name.h" */
 /* using start conditions */
<INITIAL>"#include"         { BEGIN(INCLUDE); yymore(); }
<INCLUDE>.                  { yymore(); }
<INCLUDE>"\n"               { printf("Processing directive %s", yytext); BEGIN(INITIAL); };
 /* #include ?+(\".*\"|\<.*\>)  { printf("Processing directive %s\n", yytext);} */


 /* detection of keywords */
char      { return process_token(yytext, "KW_CHAR", "", KW_CHAR);}
unsigned  { return process_token(yytext, "KW_UNSIGNED", "", KW_UNSIGNED);}
short     { return process_token(yytext, "KW_SHORT", "", KW_SHORT);}
int       { return process_token(yytext, "KW_INT", "", KW_INT);}
long      { return process_token(yytext, "KW_LONG", "", KW_LONG);}
float     { return process_token(yytext, "KW_FLOAT", "", KW_FLOAT);}
void      { return process_token(yytext, "KW_VOID", "", KW_VOID);}
for       { return process_token(yytext, "KW_FOR", "", KW_FOR);}
double    { return process_token(yytext, "KW_DOUBLE", "", KW_DOUBLE);}
if        { return process_token(yytext, "KW_IF", "", KW_IF);}
else      { return process_token(yytext, "KW_ELSE", "", KW_ELSE);}
while     { return process_token(yytext, "KW_WHILE", "", KW_WHILE);}
do        { return process_token(yytext, "KW_DO", "", KW_DO);}
struct    { return process_token(yytext, "KW_STRUCT", "", KW_STRUCT);}


 /* detection of symbols descirbed with complex regular expressions */
[0-9]+ { return process_token(yytext, "INTEGER_CONST", yytext, INTEGER_CONST);}
(([0-9]+\.[0-9]*)|([0-9]*\.[0-9]+))([eE](\+|-)?[0-9]{1,2})? { return process_token(yytext, "FLOAT_CONST", yytext, FLOAT_CONST);}
 /* \"[^\"\n]*\" { return process_token(yytext, "STRING_CONST", yytext, STRING_CONST);} */
\'.\' { return process_token(yytext, "CHARACTER_CONST", yytext, CHARACTER_CONST);}

[\_a-zA-Z][\_a-zA-Z0-9]* { return process_token(yytext, "IDENT", yytext, IDENT);}

 /* cutting out white space */
[ \s\t\n\r] ;

 /* multicharacter operators, e.g. ++ */ 
"++" { return process_token(yytext, "INC", "", INC);}
"<=" { return process_token(yytext, "LE", "", LE);}


 /* single character operator and punctuation */
. { return process_token(yytext, yytext, "", *yytext);}



%%

/* Name:	strnncpy
 * Purpose:	Copies given number of characters from a stream appending
 *		character with code 0.
 * Parameters:	dst		- (o) string to be copied from;
 *		src		- (i) string to be copied to;
 *		n		- (i) max number of characters to copy.
 * Returns:	dst.
 * Remarks:	strncpy does not append character 0 to the copied string.
 *		Destination string must have room for additional n+1 character.
 */
char *
strnncpy(char *dst, const char *src, const int n)
{
  if (n > 0) {
    strncpy(dst, src, n);
  }
  dst[n] = '\0';
  return dst;
}/*strnncpy*/

/* Name:	return process_token
 * Purpose:	Print information about detected token and pass it up
 *              with its value if present.
 * Parameters:	text            - (i) matched text;
 *              TokenType       - (i) string representing token name;
 *              TokenVal        - (i) token value if present;
 *              TokenID         - (i) token type identifier declared
 *                                      using %token directive
 *                                      in c.y file single character code
 *					(in the parser put into single quotes).
 * Returns:	Token type identifier (TokenID).
 * Remarks:	Info about detected token is printed in 3 columns.
 *		The first one contains matched text, the second - token type,
 *		the third - token value, if it exists.
 */
int process_token(const char *text, const char *TokenType,
                  const char *TokenVal, const int TokenID)
{
  int l;
  printf("%-20.20s%-15s %s\n", text, TokenType, TokenVal);
  switch (TokenID) {

  case INTEGER_CONST:
    yylval.i = atoi(text); break;

  case FLOAT_CONST:
    yylval.d = atof(text); break;

  case IDENT:
    strncpy(yylval.s, text, MAX_STR_LEN); break;

  case STRING_CONST:
    l = strlen(TokenVal);
    yylval.s[0] = '\0';
    strnncpy(yylval.s, TokenVal+1, l - 2 <= MAX_STR_LEN ? l - 1 : MAX_STR_LEN);
    break;

  case CHARACTER_CONST:
    yylval.i = text[1]; break;

  }

  return(TokenID);
}


int yywrap( void )
{ /* function called at the end of input stream */

  /* Checking whether YY_START is different from INITIAL. */
  /* If it is so, it means that a string or comment has not been closed
     - we print an error message */
  /* ..................... */
  if (YY_START == COMMENT) {
    fprintf(stderr, "Unfinished comment opened in line %d\n", comm_beg);
  }
  if (YY_START == STRING) {
    fprintf(stderr, "Unfinished string opened in line %d\n", str_beg);
  }
  return 1;
}
