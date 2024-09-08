%option noyywrap


%{
#include <bits/stdc++.h>
#include "1705031.cpp"
#define YYSTYPE SymbolInfo*
#include "y.tab.h"

using namespace std;

extern YYSTYPE yylval;
extern SymbolTable *table;
void yyerror(char *);

extern int line_count;


%}

digit [0-9]
EXP [Ee][+-]?[0-9]+
%%


[ \t\v]+ {}
"if" { return IF; }
"else" { return ELSE; }
"for" { return FOR; }
"while" { return WHILE; }
"do" { return DO; }
"break" { return BREAK; }
"int" { return INT; }
"char" { return CHAR; }
"float" { return FLOAT; }
"double" { return DOUBLE; }
"void" { return VOID; }
"return" { return RETURN; }
"switch" { return SWITCH; }
"case" { return CASE; }
"default" { return DEFAULT; }
"continue" { return CONTINUE; }
"println" { return PRINTLN; }



"+"|"-"  {
    SymbolInfo *newSymbolInfo = new SymbolInfo(yytext, "ADDOP");
    yylval = (YYSTYPE) newSymbolInfo;
    return ADDOP;
}
"*"|"/"|"%"  {
    SymbolInfo *newSymbolInfo = new SymbolInfo(yytext, "MULOP");
    yylval = (YYSTYPE) newSymbolInfo;
    return MULOP;
}
"<="|">="|"=="|"<"|">"|"!=" {
    SymbolInfo *newSymbolInfo = new SymbolInfo(yytext, "RELOP");
    yylval = (YYSTYPE) newSymbolInfo; 
    return RELOP;
}
"&&"|"||"  {
    SymbolInfo *newSymbolInfo = new SymbolInfo(yytext, "LOGICOP");
    yylval = (YYSTYPE) newSymbolInfo;
    return LOGICOP;
}
"++" { return INCOP; }
"--" { return DECOP; }
"=" { return ASSIGNOP; }
"!"  { return NOT;}
"("  { return LPAREN; }
")"  { return RPAREN; }
"{"  { return LCURL;}
"}"  { return RCURL; }
"["  { return LTHIRD; }
"]"  { return RTHIRD; }
","  { return COMMA; }
";"  { return SEMICOLON; }





{digit}+ {
    SymbolInfo *newSymbolInfo = new SymbolInfo(yytext, "CONST_INT");
    yylval = (YYSTYPE) newSymbolInfo;
    return CONST_INT;
}
{digit}*(\.{digit}+)({EXP})? {
    SymbolInfo *newSymbolInfo = new SymbolInfo(yytext, "CONST_FLOAT");
    yylval = (YYSTYPE) newSymbolInfo;
    return CONST_FLOAT;
}
{digit}+({EXP}) {
    SymbolInfo *newSymbolInfo = new SymbolInfo(yytext, "CONST_FLOAT");
    yylval = (YYSTYPE) newSymbolInfo;
    return CONST_FLOAT;
}




[a-zA-Z_]+[a-zA-Z0-9_]* {
    SymbolInfo *newSymbolInfo = new SymbolInfo(yytext, "ID");
    yylval = (YYSTYPE) newSymbolInfo;
    return ID;
}


[\n] {line_count++;}

. { 
	SymbolInfo *newSymbolInfo = new SymbolInfo(yytext, "UNRECOGNIZED");
	yylval = (YYSTYPE) newSymbolInfo;
	return UNRECOGNIZED; }

%%
