%option noyywrap


%x STATE_CHAR
%x STATE_CHAR_END
%x STATE_CHAR_ERROR
%x STATE_STRING
%x STATE_SING_COMMENT
%x STATE_MULTI_COMMENT


%{
#include <bits/stdc++.h>
#include "1705031.cpp"


int total_errors = 0;
int line_count = 1;
string token;
string lexeme;
string error;
string errorMsg;
char const_char;
string str;
string comment;
int extra = 0;
int line = 0;
bool key = false;

SymbolTable *symbolTable = new SymbolTable(7);

void insertAndPrint(){
	bool mm = symbolTable->insertIntoTable(lexeme, token);
	if(mm){
		cout << endl;
		symbolTable->printAllScopeTable();
	}
		

}
void print(){
	cout << endl;
	cout << "Line no " << line_count << ": Token <" << token << "> Lexeme " << lexeme << " found";
	if(extra == 1)
		cout << " --> <" << token << ", " << const_char << ">";
	else if(extra == 2)
		cout << " --> <" << token << ", " << str << ">";
	cout << endl; 
	extra = 0;
}


void printError(){
	cout << endl;
	cout << "Error at line no " << line_count << ": " << errorMsg << " " << error << endl;  
}

void printEOF(){
	cout << endl;
	symbolTable->printAllScopeTable();
	cout << endl;
	cout << "Total lines: " << line_count-1 << endl;
	cout << "Total errors: " << total_errors << endl;
}

void printToken(){
	fprintf(yyout, "<%s", token.c_str());
	if(!key){
		if(extra == 2)
			fprintf(yyout, ", %s", str.c_str());
		else if(extra == 1){
			
			fprintf(yyout, ", %c", const_char); }
		else 
			fprintf(yyout, ", %s", lexeme.c_str());
	}
	fprintf(yyout, "> ");
	key = false;


}
char literal(string s){
	char c = s[1];
	if(c == 't') return '\t';
	else if(c == 'n') return '\n';
	else if(c == '\\') return '\\';
	else if(c == '\'') return '\'';
	else if(c == 'a') return '\a';
	else if(c == 'f') return '\f';
	else if(c == 'r') return '\r';
	else if(c == 'b') return '\b';
	else if(c == 'v') return '\v';
	else if(c == '0') return '\0';
	else if(c == '"') return '\"';
	else return '1';
	
}

%}

digit [0-9]
EXP [Ee][+-]?[0-9]+
%%


[ \t\v]+ {}
"if" { token = "IF"; lexeme = yytext; print(); key = true; printToken();}
"else" { token = "ELSE"; lexeme = yytext; print(); key = true; printToken();}
"for" { token = "FOR"; lexeme = yytext; print(); key = true; printToken();}
"while" { token = "WHILE"; lexeme = yytext; print(); key = true; printToken();}
"do" { token = "DO"; lexeme = yytext; print(); key = true; printToken();}
"break" { token = "BREAK"; lexeme = yytext; print(); key = true; printToken();}
"int" { token = "INT"; lexeme = yytext; print();key = true; printToken();}
"char" { token = "CHAR"; lexeme = yytext; print(); key = true; printToken();}
"float" { token = "FLOAT"; lexeme = yytext; print(); key = true; printToken();}
"double" { token = "DOUBLE"; lexeme = yytext; print(); key = true; printToken();}
"void" { token = "VOID"; lexeme = yytext; print(); key = true; printToken();}
"return" { token = "RETURN"; lexeme = yytext; print(); key = true; printToken();}
"switch" { token = "SWITCH"; lexeme = yytext; print(); key = true; printToken();}
"case" { token = "CASE"; lexeme = yytext; print(); key = true; printToken();}
"default" { token = "DEFAULT"; lexeme = yytext; print(); key = true; printToken();}
"continue" { token = "CONTINUE"; lexeme = yytext; print(); key = true; printToken();}


"++"|"--" { token = "INCOP"; lexeme = yytext; print(); printToken();}
"+"|"-"  {token = "ADDOP"; lexeme = yytext; print(); printToken();}
"*"|"/"|"%"  {token = "MULOP"; lexeme = yytext; print(); printToken();}
"<="|">="|"=="|"<"|">"|"!=" { token = "RELOP"; lexeme = yytext; print(); printToken();}
"=" { token = "ASSIGNOP"; lexeme = yytext; print(); printToken();}
"&&"|"||"  {token = "LOGICOP"; lexeme = yytext; print(); printToken();}
"!"  {token = "NOT"; lexeme = yytext; print(); printToken();}
"("  {token = "LPAREN"; lexeme = yytext; print(); printToken();}
")"  {token = "RPAREN"; lexeme = yytext; print(); printToken();}
"{"  {token = "LCURL"; lexeme = yytext; print(); symbolTable->EnterScopeTable(); printToken();}
"}"  {token = "RCURL"; lexeme = yytext; print(); symbolTable->ExitScopeTable(); printToken();}
"["  {token = "LTHIRD"; lexeme = yytext; print(); printToken();}
"]"  {token = "RTHIRD"; lexeme = yytext; print(); printToken();}
","  {token = "COMMA"; lexeme = yytext; print(); printToken();}
";"  {token = "SEMICOLON"; lexeme = yytext; print(); printToken();}


{digit}+ {token = "CONST_INT"; lexeme = yytext; print(); insertAndPrint(); printToken();}
{digit}+[^0-9 \t\v\n,;()\[\]\.]+ { errorMsg = "Invalid prefix on ID or invalid suffix on Number"; error = yytext; total_errors++; printError();}
{digit}+[\.] {errorMsg = "Ill formed number"; error = yytext; total_errors++; printError();}
{digit}*(\.{digit}+)({EXP})? {token = "CONST_FLOAT"; lexeme = yytext; print(); insertAndPrint(); printToken();}
{digit}+({EXP}) {token = "CONST_FLOAT"; lexeme = yytext; print(); insertAndPrint(); printToken();}
{digit}*(\.{digit}*(\.{digit}*)+)({EXP})? {errorMsg = "Too many decimal points"; error = yytext; total_errors++; printError();}
{digit}*(\.{digit}+)([Ee][+-]?({digit}*\.{digit}*)+) {errorMsg = "Ill formed number"; error = yytext; total_errors++; printError(); }
{digit}+([Ee][+-]?({digit}*\.{digit}*)+) {errorMsg = "Ill formed number"; error = yytext; total_errors++; printError(); }
{digit}*(\.{digit}*(\.{digit}*)+)([Ee][+-]?({digit}*\.{digit}*)+) {errorMsg = "Too many decimal points"; error = yytext; total_errors++; printError();}



"'" {lexeme = "'"; BEGIN STATE_CHAR;}
<STATE_CHAR>"'" {lexeme += yytext; errorMsg = "Empty character constant error"; error = lexeme; total_errors++; printError(); BEGIN INITIAL;}
<STATE_CHAR>[\n] {errorMsg = "Unterminated character"; error = lexeme;  printError(); total_errors++; line_count++; BEGIN INITIAL; }
<STATE_CHAR>[^\n] {token= "CONST_CHAR"; lexeme += yytext; const_char = yytext[0]; BEGIN STATE_CHAR_END; }	
<STATE_CHAR>\\[ntafrbv0\\\'\"] {token = "CONST_CHAR"; lexeme += yytext; const_char = literal(yytext); BEGIN STATE_CHAR_END;}
<STATE_CHAR_END>"'" { lexeme += yytext; extra = 1; printToken(); print(); insertAndPrint();  BEGIN INITIAL; }
<STATE_CHAR_END>[\n] {errorMsg = "Unterminated character"; error = lexeme;  printError(); line_count++; total_errors++; BEGIN INITIAL; }
<STATE_CHAR_END>[^'] {lexeme += yytext; BEGIN STATE_CHAR_ERROR;}
<STATE_CHAR_ERROR>['] {lexeme += yytext; errorMsg = "Multi character constant error"; error = lexeme; printError(); total_errors++; BEGIN INITIAL; }
<STATE_CHAR_ERROR>[\n] {errorMsg = "Unterminated character"; error = lexeme;  printError(); line_count++; total_errors++; BEGIN INITIAL; }
<STATE_CHAR_ERROR>. {lexeme += yytext; }




[a-zA-Z_]+[a-zA-Z0-9_]* {token = "ID"; lexeme = yytext; print(); printToken(); insertAndPrint(); }


"\"" {token = "STRING"; lexeme = "\""; str = lexeme; line = 0; BEGIN STATE_STRING;}
<STATE_STRING>"\"" { lexeme += yytext; str += yytext; extra = 2;  printToken(); print(); line_count += line;  BEGIN INITIAL;}
<STATE_STRING>\\[\n] {lexeme += yytext; line++;}
<STATE_STRING>[\n] { errorMsg = "Unterminated String"; error = lexeme; line++; printError(); line_count += line; total_errors++; BEGIN INITIAL;}
<STATE_STRING>\\[ntafrbv0\\\"] { lexeme += yytext; str += literal(yytext); }
<STATE_STRING>. {lexeme += yytext; str += yytext; }



"//" {token = "COMMENT"; lexeme = yytext; line = 0; BEGIN STATE_SING_COMMENT; }
<STATE_SING_COMMENT>[\n] {print();  line++; line_count+= line;  BEGIN INITIAL;}
<STATE_SING_COMMENT>[^(\n)] {lexeme += yytext;}
<STATE_SING_COMMENT>\\[\n] { lexeme += yytext; line++;}
<STATE_SING_COMMENT>\\[^(\n)] {lexeme += yytext;}

[/][\*] {lexeme = yytext; token = "COMMENT"; line = 0; BEGIN STATE_MULTI_COMMENT; }
<STATE_MULTI_COMMENT>[\*][/] {lexeme += yytext; print();  line_count+= line; BEGIN INITIAL;}
<STATE_MULTI_COMMENT><<EOF>> { errorMsg = "Unterminated Comment"; error = lexeme.substr(0, lexeme.size()-1); printError(); line_count += line; total_errors++; printEOF();  return 0;}
<STATE_MULTI_COMMENT>[\n] {line++; lexeme += yytext;}
<STATE_MULTI_COMMENT>. {lexeme += yytext; } 



[\n] {line_count++;}
<<EOF>> { printEOF(); return 0;}
. {errorMsg = "Unrecognized character"; error = yytext; total_errors++; printError();}
%%


int main(int argc,char *argv[]){
	
	if(argc!=4){
		printf("Please provide input file name and try again\n");
		return 0;
	}

	freopen(argv[1], "r+", stdin);
	freopen(argv[2], "w+", stdout);
	FILE *fout = fopen(argv[3], "w+");
	yyout = fout;
	yylex();
	
	fclose(yyout);
	return 0;
}
