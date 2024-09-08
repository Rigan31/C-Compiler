%{
#include<bits/stdc++.h>
#include "1705031.cpp"
#include "optimize.cpp"

#define YYSTYPE SymbolInfo*
#define TABLE_SIZE 30

using namespace std;

int yyparse(void);
int yylex(void);
extern FILE *yyin;
FILE * ErrorFile;
FILE * AssemblyFile;
FILE * OptimizeAssemblyFile;


struct variable {
	string variableName;
	int variableSize;
};

struct parameter {
	string parameterType;
	string parameterName;
};

SymbolTable *table = new SymbolTable(TABLE_SIZE);

int line_count = 1;
int total_error = 0;

string type, finalType;
string name, finalName;  


vector<variable> variableList;
vector<parameter> parameterList;
vector<string> argumentList;

// new variable declaration for IR representation

int scopeNo = 0;
int labelNo = 0;
bool mmDefined = false;
vector<string> sendArguList;
vector<string> receiveArguList;
vector<string> newVariableList;	
string finalAvariable;


/////////////////////////////////


/// new function of IR 

string getPrintlnProc(){
	string tmpAcode = "";
	tmpAcode += "PRINTLN PROC\n";
	tmpAcode += "\tPOP GET_ADDRESS\n";
	tmpAcode += "\tPOP BX\n";
	tmpAcode += "\tCMP BX, 0\n";
	tmpAcode += "\tJGE POSITIVE_NUMBER\n";
	tmpAcode += "\tNEG BX\n";
	tmpAcode += "\tMOV AH, 2\n";
	tmpAcode += "\tMOV DL, '-'\n";
	tmpAcode += "\tINT 21H\n";
	tmpAcode += "\tPOSITIVE_NUMBER:\n";
	tmpAcode += "\tMOV AX, BX\n";
	tmpAcode += "\tXOR DX, DX\n";
	tmpAcode += "\tWHILE_LOOP:\n";
	tmpAcode += "\tDIV START_FROM_DIV\n";
	tmpAcode += "\tMOV SINGLE_DIGIT, AX\n";
	tmpAcode += "\tMOV BX, DX\n";
	tmpAcode += "\tCMP SINGLE_DIGIT, 0\n";
	tmpAcode += "\tJNE PRINT_THE_OUTPUT\n";
	tmpAcode += "\tCMP LOOP_DONE, 0\n";
	tmpAcode += "\tJNE PRINT_THE_OUTPUT\n";
	tmpAcode += "\tCMP START_FROM_DIV, 1\n";
	tmpAcode += "\tJNE DIVIDE_AGAIN\n";
	tmpAcode += "\tMOV AH, 2\n";
	tmpAcode += "\tMOV DX, BX\n";
	tmpAcode += "\tOR DX, 30h\n";
	tmpAcode += "\tINT 21H\n";
	tmpAcode += "\tJMP WHILE_LOOP_END\n";
	tmpAcode += "\tPRINT_THE_OUTPUT:\n";
	tmpAcode += "\tMOV LOOP_DONE, 1\n";
	tmpAcode += "\tMOV AH, 2\n";
	tmpAcode += "\tMOV DX, SINGLE_DIGIT\n";
	tmpAcode += "\tOR DX, 30H\n";
	tmpAcode += "\tINT 21H\n";
	tmpAcode += "\tDIVIDE_AGAIN:\n";
	tmpAcode += "\tMOV SINGLE_DIGIT, BX\n";
	tmpAcode += "\tCMP START_FROM_DIV, 1\n";
	tmpAcode += "\tJE WHILE_LOOP_END\n";
	tmpAcode += "\tMOV AX, START_FROM_DIV\n";
	tmpAcode += "\tXOR DX, DX\n";
	tmpAcode += "\tMOV BX, 10\n";
	tmpAcode += "\tDIV BX\n";
	tmpAcode += "\tMOV START_FROM_DIV, AX\n";
	tmpAcode += "\tMOV AX, SINGLE_DIGIT\n";
	tmpAcode += "\tXOR DX, DX\n";
	tmpAcode += "\tJMP WHILE_LOOP\n";
	tmpAcode += "\tWHILE_LOOP_END:\n";
	tmpAcode += "\tMOV AH, 2\n";
	tmpAcode += "\tMOV DL, 0AH\n";
	tmpAcode += "\tINT 21H\n";
	tmpAcode += "\tMOV DL, 0DH\n";
	tmpAcode += "\tINT 21H\n";
	tmpAcode += "\tMOV START_FROM_DIV, 10000\n";
	tmpAcode += "\tMOV LOOP_DONE, 0\n";
	tmpAcode += "\tPUSH GET_ADDRESS\n";
	tmpAcode += "\tRET\n";
	tmpAcode += "PRINTLN ENDP\n";
	
	return tmpAcode;

}


string newLabel() {
    string str = "Label";
    str += to_string(labelNo);
    labelNo++;
    return str;
}

int isTaken[100];
int tmpVarNo = -1;
string newVariable() {
	int tmp;
	for(int i = 0; i < 100; i++){
		if(isTaken[i] == 0){
			tmp = i;
			isTaken[i] = 1;
			break;
		}
	} 
    	string str = "t";
    	str += to_string(tmp);
    	if(tmp > tmpVarNo){
    		newVariableList.push_back(str + " dw ?");
    		tmpVarNo = tmp;
    	}
    	return str;
}

void returnNewVariable(string s){
	if(s.length() == 0 || s.length() == 1){
		return;
	}
	if(s[0] != 't'){
		return;
	}
	int pos = s[1]-'0';
	isTaken[pos] = 0;
}

///////////////////////////////////
void yyerror(char *s)
{
	//write your code
}


void pushFuncToSymbol(string tmpType, string name, int mm){
	SymbolInfo *tmp = new SymbolInfo(name, "ID");
	tmp->setTmpType(tmpType);
	tmp->setTmpSize(mm);
	
	for(int i = 0; i < parameterList.size(); i++){
		tmp->addParameter(parameterList[i].parameterName, parameterList[i].parameterType);
	}
	
	table->insertIntoTableSymbol(tmp);
	
	// new code for IR
	tmp->setSymbol(name);
	/////////////////////
	return;
}

void pushVartoSymbol(string tmpType, variable tmpVar){
	SymbolInfo *tmp = new SymbolInfo(tmpVar.variableName, "ID");
	tmp->setTmpType(tmpType);
	tmp->setTmpSize(tmpVar.variableSize);
	
	
	// new code for IR //////////////////////////////
	string tmpStr;
	string str = tmpVar.variableName;
    	
    	str += to_string(scopeNo);
    	tmp->setSymbol(str);
	
	if(tmpVar.variableSize == -1){
		newVariableList.push_back(str + " dw ?");
	}
	else{
		str += " dw ";
        	str += to_string(tmpVar.variableSize);
        	str += " dup (?)";
        	newVariableList.push_back(str); 
	}
	////////////////////////////////////////////////
	
	table->insertIntoTableSymbol(tmp);
	/////// new code for IR
	finalAvariable = str;
	//////////////////////
	return;

}
%}

%token IF ELSE FOR WHILE DO BREAK INT CHAR FLOAT DOUBLE VOID RETURN SWITCH CASE DEFAULT CONTINUE MAIN PRINTLN
%token ADDOP MULOP RELOP LOGICOP INCOP DECOP ASSIGNOP NOT LPAREN RPAREN LCURL RCURL LTHIRD RTHIRD COMMA SEMICOLON
%token CONST_INT CONST_FLOAT ID
%token UNRECOGNIZED

%nonassoc LOWER_THAN_ELSE
%nonassoc ELSE


%%

start : program{
		//write your code in this block in all the similar blocks below
		
		cout << "At line no: " << line_count << " start: program" << endl << endl;
		//cout << $1->getName() << endl << endl;
		
		$$ = new SymbolInfo($1->getName(), "NON_TERM");
		
		// new code for IR
		
		if(total_error == 0){
			
			// writing the initial segment ///////////////////////////
			
			string finalAssemblyCode = "";
			finalAssemblyCode += ".MODEL SMALL\n";
			finalAssemblyCode += ".STACK 100H\n";
			finalAssemblyCode += ".DATA\n";
			
			/////////////////////////////////////////
			
			
			
			////////////// adding the variable in assembly code///////////////////
			
			finalAssemblyCode += "\tSTART_FROM_DIV dw 10000\n";
			finalAssemblyCode += "\tGET_ADDRESS dw 0\n";
			finalAssemblyCode += "\tSINGLE_DIGIT dw ?\n";
			finalAssemblyCode += "\tLOOP_DONE db 0\n";
			
			for(string avar : newVariableList){
				finalAssemblyCode += "\t" + avar + "\n";
			}
			
			////////////////////////////////////////////////
			
			
			
			// writing the main code and procedure /////////////////////

			finalAssemblyCode += ".CODE\n";
			finalAssemblyCode += $1->getAcode();
			finalAssemblyCode += getPrintlnProc();
			finalAssemblyCode += "END MAIN\n";		
			
			///////////////////////////////////////////////
			
			
			
			// writing the final assembly code in code.asm file
			
			fprintf(AssemblyFile, "%s", finalAssemblyCode.c_str());
			
			/////////////////////////////////////
			
			//cout << "assembly code" << endl;
			
			//cout << finalAssemblyCode << endl;
			
			// getting the optimize final code calling Optimize class
			Optimize *optimize = new Optimize();
			optimize->optimizeAssemblyCode(finalAssemblyCode);
			string optimizeFinalCode = optimize->getOptimizeCode();
			
			fprintf(OptimizeAssemblyFile, "%s", optimizeFinalCode.c_str());
			/////////////////////////////////////////////////////////
			
			//-------------------THE END--------------------/////////
			//-------------IT WAS FUN TO MAKE THIS----------/////////
		}
	}
	;

program : program unit{
		string tmp = $1->getName() +$2->getName(); 
		cout << "At line no: " << line_count << " program : program unit" << endl << endl;
		cout << tmp << endl << endl;
		
		$$ = new SymbolInfo(tmp, "NON_TERM");
		
		// new code for IR
		
		$$->setAcode($1->getAcode() + $2->getAcode());
	}
	| unit{
		cout << "At line no: " << line_count << " program : unit" << endl << endl;
		cout << $1->getName() << endl << endl;
		
		$$ = new SymbolInfo($1->getName(), "NON_TERM");
		
		// new code for IR
		$$->setAcode($1->getAcode());
	}
	;
	
unit : var_declaration{
		cout << "At line no: " << line_count << " unit : var_declaration" << endl << endl;
		cout << $1->getName() << endl << endl;
		
		$$ = new SymbolInfo($1->getName(), "NON_TERM");
	}
     	| func_declaration {
     		cout << "At line no: " << line_count << " unit : func_declaration" << endl << endl;
		cout << $1->getName() << endl << endl;
		
		$$ = new SymbolInfo($1->getName(), "NON_TERM");     	
	}
     	| func_definition {
     		cout << "At line no: " << line_count << " unit : func_definition" << endl << endl;
     		cout << $1->getName() << endl << endl;
     		
     		$$ = new SymbolInfo($1->getName(), "NON_TERM");
     		
     		// new code for IR
     		$$->setAcode($1->getAcode());
     	}
     ;
     
func_declaration : type_specifier id funcIn LPAREN parameter_list RPAREN funcOutDeclar SEMICOLON {
		string tmp = $1->getName()+" "+$2->getName()+"("+$5->getName()+");\n";
		
		cout << "At line no: " << line_count << " func_declaration : type_specifier ID LPAREN parameter_list RPAREN SEMICOLON" << endl << endl;
		cout << tmp << endl << endl;
		
		$$ = new SymbolInfo(tmp, "NON_TERM");
		
		parameterList.clear();
	}
	| type_specifier id funcIn LPAREN RPAREN funcOutDeclar SEMICOLON{
		string tmp = $1->getName()+" "+$2->getName()+"();\n";
		
		cout << "At line no: " << line_count << " func_declaration : type_specifier ID LPAREN RPAREN SEMICOLON" << endl << endl;
		cout << tmp << endl << endl;
		
		$$ = new SymbolInfo(tmp, "NON_TERM");
		
		parameterList.clear();
	}
	|type_specifier id funcIn LPAREN parameter_list RPAREN funcOutDeclar error{
		string tmp = $1->getName()+" "+$2->getName()+"("+$5->getName()+")\n";
		
		cout << "At line no: " << line_count << " func_declaration : type_specifier ID LPAREN parameter_list RPAREN SEMICOLON" << endl << endl;
		cout << tmp << endl << endl;
		
		$$ = new SymbolInfo(tmp, "NON_TERM");
		
		parameterList.clear();
		cout << "Error at line: " << line_count << " ; missing in function " << $2->getName() << endl << endl;
		fprintf(ErrorFile, "Error at line: %d ; missing in function %s\n\n", line_count, $2->getName().c_str());
		total_error++;
	
	}
	|type_specifier id funcIn LPAREN RPAREN funcOutDeclar error{
		string tmp = $1->getName()+" "+$2->getName()+"();\n";
		
		cout << "At line no: " << line_count << " func_declaration : type_specifier ID LPAREN RPAREN SEMICOLON" << endl << endl;
		cout << tmp << endl << endl;
		
		$$ = new SymbolInfo(tmp, "NON_TERM");
		
		parameterList.clear();
		
		cout << "Error at line: " << line_count << " ; missing in function " << $2->getName() << endl << endl;
		fprintf(ErrorFile, "Error at line: %d ; missing in function %s\n\n", line_count, $2->getName().c_str());
		total_error++;
	}
	;
		 
func_definition : type_specifier id funcIn LPAREN parameter_list RPAREN funcOutDefi compound_statement{
		string tmp = $1->getName()+" "+$2->getName()+"("+$5->getName()+")" +$8->getName() + "\n";
		
		cout << "At linen no: " << line_count << " func_definition : type_specifier ID LPAREN parameter_list RPAREN compound_statement" << endl << endl;
		cout << tmp << endl << endl;
		
		$$ = new SymbolInfo(tmp, "NON_TERM");
		
		// new code for IR
		
		string tmpAcode = "";
		
		if(mmDefined){
			if($2->getName() == "main"){
				tmpAcode += "MAIN PROC\n";
				tmpAcode += "\tMOV AX, @DATA\n";
				tmpAcode += "\tMOV DS, AX\n\n\n";
				tmpAcode += $8->getAcode();
				tmpAcode += "\tMOV AH, 4CH\n";
				tmpAcode += "\tINT 21H\n";
				tmpAcode += "\tMAIN ENDP\n";
			}
			else{
				tmpAcode += $2->getName() + " PROC\n";
				tmpAcode += "\tPOP GET_ADDRESS\n";
				
			
				for(int i = receiveArguList.size()-1; i >= 0; i--){
					tmpAcode += "\tPOP " + receiveArguList[i] + "\n";
				}
				tmpAcode += $8->getAcode();
				tmpAcode += "\tPUSH GET_ADDRESS\n";
				tmpAcode += "\tRET\n";
				tmpAcode += $2->getName() + " ENDP\n";
			}
			mmDefined = false;
		}
		
		receiveArguList.clear();
		$$->setAcode(tmpAcode);
		
		
	}
	| type_specifier id funcIn LPAREN RPAREN funcOutDefi compound_statement{
		string tmp = $1->getName()+ " " + $2->getName()+ "()" + $7->getName()+"\n";
		
		cout << "At line no: " << line_count << " func_definition : type_specifier ID LPAREN RPAREN compound_statement" << endl << endl;
		cout << tmp << endl << endl;
		
		$$ = new SymbolInfo(tmp, "NON_TERM");
		
		/////////// new code for IR 
		
		string tmpAcode = "";
		
		if(mmDefined){
			if($2->getName() == "main"){
				tmpAcode += "MAIN PROC\n";
				tmpAcode += "\tMOV AX, @DATA\n";
				tmpAcode += "\tMOV DS, AX\n\n\n";
				tmpAcode += $7->getAcode();
				tmpAcode += "\tMOV AH, 4CH\n";
				tmpAcode += "\tINT 21H\n";
				tmpAcode += "\tMAIN ENDP\n";
			}
			else{
				tmpAcode += $2->getName() + " PROC\n";
				tmpAcode += "\tPOP GET_ADDRESS\n";
				
				for(int i = receiveArguList.size()-1; i >= 0; i--){
					tmpAcode += "\tPOP " + receiveArguList[i] + "\n";
				}
				
				tmpAcode += $7->getAcode();
				tmpAcode += "\tPUSH GET_ADDRESS\n";
				tmpAcode += "\tRET\n";
				tmpAcode += $2->getName() + " ENDP\n";
			}
			mmDefined = false;
		}
		
		receiveArguList.clear();
		$$->setAcode(tmpAcode);
		
		
				
	}
 	;
 	
 
funcIn: {
 		finalName = name;
 		finalType = type;
 	}
 	;
 
funcOutDeclar:{
 		SymbolInfo *tmp = table->lookUp(finalName);
 		
 		if(tmp != NULL){
 			//fprintf(ErrorFile, "-------------%s\n", finalName);
 			fprintf(ErrorFile, "Error at line: %d Multiple Declaration of function %s\n\n", line_count, finalName.c_str());
 			cout << "Error at line: " << line_count << " Multiple Declaration of function " << finalName << endl << endl;
 			total_error++;
 		}
 		else{
 			pushFuncToSymbol(finalType, finalName, -2);
 		}
 	}
	;

funcOutDefi:{
		SymbolInfo *tmp = table->lookUp(finalName);
		if(tmp == NULL){
			// first time to define this function
			mmDefined = true;
			pushFuncToSymbol(finalType, finalName, -3);
		}
		else if(tmp->getTmpSize() != -2){
			// same function definition twice
			fprintf(ErrorFile, "Error at line: %d Multiple Definition of function %s\n\n", line_count, finalName.c_str());
			cout << "Error at line: " << line_count << " Multiple Definition of function " << finalName << endl << endl;
			total_error++;
		}
		else{
			if(tmp->getTmpType() != finalType){
				fprintf(ErrorFile, "Error at line: %d Return type mismatch with function declaration in function %s\n\n", line_count, finalName.c_str());
				cout << "Error at line: " << line_count << " Return type mismatch with function declaration in function " << finalName << endl << endl;
				total_error++;
			}
			else if(tmp->getParameterSize() == 1 && parameterList.size() == 0 && tmp->getParameter(0).type == "void"){
				mmDefined = true;
				tmp->setTmpSize(-3);
			}
			else if(tmp->getParameterSize() == 0 && parameterList.size() == 1 && parameterList[0].parameterType == "void"){
				mmDefined = true;
				tmp->setTmpSize(-3);
			}
			else if(tmp->getParameterSize() != parameterList.size()){
				fprintf(ErrorFile, "Error at line: %d Total number of arguments mismatch with it's declaration in function %s\n\n", line_count, finalName.c_str());
				cout << "Error at line: " << line_count << " Total number of arguments mismatch with it's declaration in function " << finalName << endl << endl;
				total_error++;
			}
			else{
				bool mm = true;
				
				for(int i = 0; i < parameterList.size(); i++){
					//SymbolInfo *tmpSymbol = table->lookUpCurrentScope(parameterList[i].parameterName);
						//fprintf(ErrorFile, "------------- %d: %s", line_count, parameterList[i].parameterName.c_str());
					//if(tmpSymbol != NULL){
					//	fprintf(ErrorFile, "Error at line: %d Multiple Declaration of %s in parameter\n\n", line_count, parameterList[i].parameterName.c_str());
					//	total_error++;
					//}
					if(tmp->getParameter(i).type != parameterList[i].parameterType){
						mm = false;
						break;
					}
				}
				
				if(mm){
					mmDefined = true;
					tmp->setTmpSize(-3);
				}
				else{
					fprintf(ErrorFile, "Error at line: %d Parameter Type mismatch with it's declaration\n\n", line_count);
					cout << "Error at line: " << line_count << " Parameter Type mismatch with it's declaration" << endl << endl;
					total_error++;
				}
			}
		}
		
	}
	;
	
parameter_list  : parameter_list COMMA type_specifier id{
		string tmp = $1->getName()+", "+$3->getName()+ " " + $4->getName();
		
		cout << "At line no: " << line_count << " parameter_list : parameter_list COMMA type_specifier ID" << endl << endl;
		cout << tmp << endl << endl;
		
		$$ = new SymbolInfo(tmp, "NON_TERM");
		
		parameter tmpPara;
		tmpPara.parameterType = $3->getName();
		tmpPara.parameterName = $4->getName();
		parameterList.push_back(tmpPara);
	}
	| parameter_list COMMA type_specifier{
		string tmp = $1->getName()+ ", " + $3->getName();
		cout << "At line no: " << line_count << " parameter_list : parameter_list COMMA type_specifier" << endl << endl;
		cout << tmp << endl << endl;
		
		$$ = new SymbolInfo(tmp, "NON_TERM");
		
		parameter tmpPara;
		tmpPara.parameterType = $3->getName();
		tmpPara.parameterName = "";
		parameterList.push_back(tmpPara);
	}
 	| type_specifier id{
 		string tmp = $1->getName()+" "+$2->getName();
 		
 		cout << "At line no: " << line_count << " parameter_list : type_specifier ID" << endl << endl;
 		cout << tmp << endl << endl;
 		
 		$$ = new SymbolInfo(tmp, "NON_TERM");
 		
 		parameter tmpPara;
		tmpPara.parameterType = $1->getName();
		tmpPara.parameterName = $2->getName();
		parameterList.push_back(tmpPara);
 	}
 	| type_specifier{
 		string tmp = $1->getName();
 		
 		cout << "At line no: " << line_count << " parameter_list : type_specifier" << endl << endl;
 		cout << tmp << endl << endl;
 		
 		$$ = new SymbolInfo(tmp, "NON_TERM");
 		
 		parameter tmpPara;
		tmpPara.parameterType = $1->getName();
		tmpPara.parameterName = "";
		parameterList.push_back(tmpPara);
 	}
 	| parameter_list error type_specifier id{
 		string tmp = $1->getName();
		
		cout << "At line no: " << line_count << " parameter_list : parameter_list error type_specifier ID" << endl << endl;
		cout << tmp << endl << endl;
		
		$$ = new SymbolInfo(tmp, "NON_TERM");
		
		cout << "Error at line: " << line_count << " comma(,) missing" <<  endl << endl;
 		fprintf(ErrorFile, "Error at line: %d comma(,) missing\n\n", line_count);
 		total_error++;
 	}
 	| parameter_list error type_specifier{
 		string tmp = $1->getName();
		
		cout << "At line no: " << line_count << " parameter_list : parameter_list error type_specifier" << endl << endl;
		cout << tmp << endl << endl;
		
		$$ = new SymbolInfo(tmp, "NON_TERM");
		
		cout << "Error at line: " << line_count << " comma(,) missing" <<  endl << endl;
 		fprintf(ErrorFile, "Error at line: %d comma(,) missing\n\n", line_count);
 		total_error++;
 	}
 	| ADDOP{
 		string tmp = $1->getName();
		
		cout << "At line no: " << line_count << " parameter_list: ADDOP" << endl << endl;
		cout << tmp << endl << endl;
		
		cout << "Error at line: " << line_count << " Syntax error: ADDOP in parameter list" << endl << endl;
		fprintf(ErrorFile, "Error at line: %d Syntax error: ADDOP in parameter list\n\n", line_count);
		total_error++;
		
		
		$$ = new SymbolInfo("", "NON_TERM");
		
 	}
 	|parameter_list COMMA ADDOP {
 		string tmp = $1->getName();
		
		cout << "At line no: " << line_count << " parameter_list : parameter_list COMMA ADDOP" << endl << endl;
		cout << tmp << ", " << $3->getName() << endl << endl;
		
		$$ = new SymbolInfo(tmp, "NON_TERM");
		
		cout << "Error at line: " << line_count << " Syntax error: ADDOP in parameter list" <<  endl << endl;
 		fprintf(ErrorFile, "Error at line: %d Syntax error: ADDOP in parameter list\n\n", line_count);
 		total_error++;
 	} 
 	|type_specifier ADDOP{
 		string tmp = $1->getName() + " " + $2->getName();
		
		cout << "At line no: " << line_count << " parameter_list: type_specifier ADDOP" << endl << endl;
		cout << tmp << endl << endl;
		
		cout << "Error at line: " << line_count << " Syntax error: ADDOP in parameter list" << endl << endl;
		fprintf(ErrorFile, "Error at line: %d Syntax error: ADDOP in parameter list\n\n", line_count);
		total_error++;
		
		
		$$ = new SymbolInfo("", "NON_TERM");
 	} 
 	| parameter_list COMMA type_specifier ADDOP{
 		string tmp = $1->getName();
		
		cout << "At line no: " << line_count << " parameter_list : parameter_list COMMA type_specifier ADDOP" << endl << endl;
		cout << tmp << ", " << $3->getName() << " " << $4->getName()<< endl << endl;
		
		$$ = new SymbolInfo(tmp, "NON_TERM");
		
		cout << "Error at line: " << line_count << " Syntax error: ADDOP in parameter list" <<  endl << endl;
 		fprintf(ErrorFile, "Error at line: %d Syntax error: ADDOP in parameter list\n\n", line_count);
 		total_error++;
 	}
 	|type_specifier id ADDOP{
 		string tmp = $1->getName() + " " + $2->getName() + " " + $3->getName();
		
		cout << "At line no: " << line_count << " parameter_list: type_specifier ID ADDOP" << endl << endl;
		cout << tmp << endl << endl;
		
		cout << "Error at line: " << line_count << " Syntax error: ADDOP in parameter list" << endl << endl;
		fprintf(ErrorFile, "Error at line: %d Syntax error: ADDOP in parameter list\n\n", line_count);
		total_error++;
		
		
		$$ = new SymbolInfo("", "NON_TERM");
 	} 
 	| parameter_list COMMA type_specifier id ADDOP{
 		string tmp = $1->getName();
		
		cout << "At line no: " << line_count << " parameter_list : parameter_list COMMA type_specifier ADDOP" << endl << endl;
		cout << tmp << ", " << $3->getName() << " " << $4->getName()<< " " << $5->getName() <<  endl << endl;
		
		$$ = new SymbolInfo(tmp, "NON_TERM");
		
		cout << "Error at line: " << line_count << " Syntax error: ADDOP in parameter list" <<  endl << endl;
 		fprintf(ErrorFile, "Error at line: %d Syntax error: ADDOP in parameter list\n\n", line_count);
 		total_error++;
 	}
 	
 	;
 
 		
compound_statement : LCURL compoundIn statements RCURL{
		string tmp = "{\n" + $3->getName() + "}\n";
		
		cout << "At line no: " << line_count << " compound_statement : LCURL statements RCURL" << endl << endl;
		cout << tmp << endl << endl;
		
		$$ = new SymbolInfo(tmp, "NON_TERM");
		
		table->printAllScopeTable();
		table->ExitScopeTable();
		
		cout << endl << endl;
		
		//// new code for IR
		
		$$->setAcode($3->getAcode());
	}
	| LCURL compoundIn RCURL{
		string tmp = "{ }\n";
		
		cout << "At line no: " << line_count << " compound_statement : LCURL RCURL" << endl << endl;
		cout << tmp << endl << endl;
		
		$$ = new SymbolInfo(tmp, "NON_TERM");
		table->printAllScopeTable();
		table->ExitScopeTable();
		
		cout << endl << endl;
	}
	|error compoundIn statements RCURL{
		string tmp = "\n" + $3->getName() + "}\n";
		
		cout << "At line no: " << line_count << " compound_statement : error statements RCURL" << endl << endl;
		cout << tmp << endl << endl;
		
		$$ = new SymbolInfo(tmp, "NON_TERM");
		
		cout << "Error at line: " << line_count << "LCURL'{' is missing" << endl << endl;
		fprintf(ErrorFile, "Error at line: %d LCURL'{' is missing\n\n", line_count);
		total_error++;
		
		table->printAllScopeTable();
		table->ExitScopeTable();
		
		cout << endl << endl;
	}
	|error compoundIn RCURL{
		string tmp = " }\n";
		
		cout << "At line no: " << line_count << " compound_statement : error RCURL" << endl << endl;
		cout << tmp << endl << endl;
		
		$$ = new SymbolInfo(tmp, "NON_TERM");
		
		cout << "Error at line: " << line_count << "LCURL'{' is missing" << endl << endl;
		fprintf(ErrorFile, "Error at line: %d LCURL'{' is missing\n\n", line_count);
		total_error++;
		
		table->printAllScopeTable();
		table->ExitScopeTable();
		
		cout << endl << endl;
	}
	|LCURL compoundIn statements error{
		string tmp = "{\n" + $3->getName();
		
		cout << "At line no: " << line_count << " compound_statement : LCURL statements error" << endl << endl;
		cout << tmp << endl << endl;
		
		$$ = new SymbolInfo(tmp, "NON_TERM");
		
		cout << "Error at line: " << line_count << "RCURL'}' is missing" << endl << endl;
		fprintf(ErrorFile, "Error at line: %d RCURL'}' is missing\n\n", line_count);
		total_error++;
		
		table->printAllScopeTable();
		table->ExitScopeTable();
		
		cout << endl << endl;
	}
	|LCURL compoundIn error {
		string tmp = "{\n";
		
		cout << "At line no: " << line_count << " compound_statement : LCURL error" << endl << endl;
		cout << tmp << endl << endl;	
		
		$$ = new SymbolInfo(tmp, "NON_TERM");
		
		cout << "Error at line: " << line_count << "RCURL'}' is missing" << endl << endl;
		fprintf(ErrorFile, "Error at line: %d RCURL'}' is missing\n\n", line_count);
		total_error++;
		
		table->printAllScopeTable();
		table->ExitScopeTable();
		
		cout << endl << endl;
	}
 	;
 	

compoundIn : {
		table->EnterScopeTable();
		scopeNo++;
		
		if(parameterList.size() == 1 && parameterList[0].parameterType == "void"){
			
		}
		else{
			for(int i = 0; i < parameterList.size(); i++){
				variable tmpVar;
				tmpVar.variableName = parameterList[i].parameterName;
				tmpVar.variableSize = -1;
				
				SymbolInfo *tmpSymbol = table->lookUpCurrentScope(tmpVar.variableName);
				if(tmpSymbol != NULL){
					fprintf(ErrorFile, "Error at line: %d Multiple Declaration of %s in parameter\n\n", line_count, tmpVar.variableName.c_str());
					cout << "Error at line: " << line_count << " Multiple Declaration of " << tmpVar.variableName << " in parameter" << endl << endl;
					total_error++;
					continue;
				}
				pushVartoSymbol(parameterList[i].parameterType, tmpVar);
				receiveArguList.push_back(finalAvariable);
			}
		}
		
		parameterList.clear();
	}
	;
 		    
var_declaration : type_specifier declaration_list SEMICOLON{
		string tmp = $1->getName()+ " "+$2->getName()+ ";" + "\n";
		
		cout << "At line no: " << line_count << " var_declaration : type_specifier declaration_list SEMICOLON" << endl << endl;
		cout << tmp << endl;
		
		$$ = new SymbolInfo(tmp, "NON_TERM");
		
		if($1->getName() == "void"){
			fprintf(ErrorFile, "Error at line: %d void isn't a variable type\n\n", line_count);
			cout << "Error at line: " << line_count << " void isn't a variable type" << endl << endl;
			total_error++;
			
			for(int i = 0; i < variableList.size(); i++){
				pushVartoSymbol("float", variableList[i]);
			}
		}
		else{
			for(int i = 0; i < variableList.size(); i++){
			
				pushVartoSymbol($1->getName(), variableList[i]);
			}
		}
		
		variableList.clear();
	}
	|type_specifier declaration_list error{
		string tmp = $1->getName()+ " "+$2->getName()+ "\n";
		
		cout << "At line no: " << line_count << " var_declaration : type_specifier declaration_list error" << endl << endl;
		cout << tmp << endl;
		
		cout << "Error at line: " << line_count << " semicolon(;) is missing" << endl << endl;
		fprintf(ErrorFile, "Error at line: %d semicolon(;) is missing\n\n", line_count);
		total_error++;
		
		$$ = new SymbolInfo(tmp, "NON_TERM");
		
		if($1->getName() == "void"){
			fprintf(ErrorFile, "Error at line: %d void isn't a variable type\n\n", line_count);
			cout << "Error at line: " << line_count << " void isn't a variable type" << endl << endl;
			total_error++;
			
			for(int i = 0; i < variableList.size(); i++){
				pushVartoSymbol("float", variableList[i]);
			}
		}
		else{
			for(int i = 0; i < variableList.size(); i++){
			
				pushVartoSymbol($1->getName(), variableList[i]);
			}
		}
		
		variableList.clear();
		
		
	}
 	;
 		 
type_specifier	: INT{
		string tmp = "int";
		
		cout << "At line no: " << line_count << " type_specifier : INT" << endl << endl;
		cout << tmp << " "<< endl << endl;
		
		$$ = new SymbolInfo(tmp, "NON_TERM");
		type = tmp;
	}
 	| FLOAT{
 		string tmp = "float";
		
		cout << "At line no: " << line_count << " type_specifier : FLOAT" << endl << endl;
		cout << tmp << endl << endl;
		
		$$ = new SymbolInfo(tmp, "NON_TERM");
		type = tmp;
 	}
 	| VOID{
 		string tmp = "void";
		
		cout << "At line no: " << line_count << " type_specifier : VOID" << endl << endl;
		cout << tmp << endl << endl;
		
		$$ = new SymbolInfo(tmp, "NON_TERM");
		type = tmp;
 	}
 	;

id: ID {
            $$ = new SymbolInfo($1->getName(), "NON_TERM");
            name = $1->getName();
    }
        ;
 		
declaration_list : declaration_list COMMA id{
		string tmp = $1->getName() + "," + $3->getName();
		
		cout << "At line no: " << line_count << " declaration_list : declaration_list COMMA ID" << endl << endl;
		cout << tmp << endl << endl;
		
		$$ = new SymbolInfo(tmp, "NON_TERMINAL");
		
		variable tmpVar;
		tmpVar.variableName = $3->getName();
		tmpVar.variableSize = -1;
		variableList.push_back(tmpVar);
		
		
		SymbolInfo *tmpSymbol = table->lookUpCurrentScope($3->getName());
		if(tmpSymbol != NULL){
			fprintf(ErrorFile, "Error at line: %d Multiple Declaration of %s\n\n", line_count, $3->getName().c_str());
			cout << "Error at line: " << line_count << " Multiple Declaration of " << $3->getName() << endl << endl;
			total_error++;
		}
	}
 	| declaration_list COMMA id LTHIRD CONST_INT RTHIRD{
 		string tmp = $1->getName()+ "," + $3->getName() + "[" + $5->getName() + "]";
 		
 		cout << "At line no: " << line_count << " declaration_list : declaration_list COMMA ID LTHIRD CONST_INT RTHIRD" << endl << endl;
 		cout << tmp << endl << endl;
 		
 		$$ = new SymbolInfo(tmp, "NON_TERM");
 		
 		variable tmpVar;
		tmpVar.variableName = $3->getName();
		tmpVar.variableSize = stoi($5->getName());
		variableList.push_back(tmpVar);
		
		SymbolInfo *tmpSymbol = table->lookUpCurrentScope($3->getName());
		if(tmpSymbol != NULL){
			fprintf(ErrorFile, "Error at line: %d Multiple Declaration of %s\n\n", line_count, $3->getName().c_str());
			cout << "Error at line: " << line_count << " Multiple Declaration of " << $3->getName() << endl << endl;
			total_error++;
		}
 	}
 	| id{
 		string tmp = $1->getName();
 		
 		cout << "At line no: " << line_count << " declaration_list : ID" << endl << endl;
 		cout << tmp << endl << endl;
 		
 		$$ = new SymbolInfo(tmp, "NON_TERM");
 		
 		variable tmpVar;
		tmpVar.variableName = $1->getName();
		tmpVar.variableSize = -1;
		variableList.push_back(tmpVar);
		
	
		
		SymbolInfo *tmpSymbol = table->lookUpCurrentScope($1->getName());
		if(tmpSymbol != NULL){
			fprintf(ErrorFile, "Error at line: %d Multiple Declaration of %s\n\n", line_count, $1->getName().c_str());
			cout << "Error at line: " << line_count << " Multiple Declaration of " << $1->getName() << endl << endl;
			total_error++;
		}
 	}
 	| id LTHIRD CONST_INT RTHIRD {
 		string tmp = $1->getName() + "[" + $3->getName() + "]";
 		
 		cout << "At line no: " << line_count << " declaration_list : ID LTHIRD CONST_INT RTHIRD" << endl;
 		cout << tmp << endl << endl;
 		
 		$$ = new SymbolInfo(tmp, "NON_TERM");
 		
 		variable tmpVar;
		tmpVar.variableName = $1->getName();
		tmpVar.variableSize = stoi($3->getName());
		variableList.push_back(tmpVar);
		
		
		SymbolInfo *tmpSymbol = table->lookUpCurrentScope($1->getName());
		if(tmpSymbol != NULL){
			fprintf(ErrorFile, "Error at line: %d Multiple Declaration of %s\n\n", line_count, $1->getName().c_str());
			cout << "Error at line: " << line_count << " Multiple Declaration of " << $1->getName() << endl << endl;
			total_error++;
		}
 	}
 	| id LTHIRD error RTHIRD{
 		string tmp = $1->getName() + "[" + $3->getName() + "]";
 		
 		cout << "At line no: " << line_count << " declaration_list : ID LTHIRD error RTHIRD" << endl;
 		cout << tmp << endl << endl;
 		
 		$$ = new SymbolInfo(tmp, "NON_TERM");
 		
 		cout << "Error at line: " << line_count << " array index must be integer not " << $3->getName() << endl << endl;
 		fprintf(ErrorFile, "Errro at line: %d array index must be integer not %s\n\n", line_count, $3->getName().c_str());
 		total_error++;
 	}
 	| declaration_list COMMA id LTHIRD error RTHIRD{
 		string tmp = $1->getName()+ "," + $3->getName() + "[" + $5->getName() + "]";
 		
 		cout << "At line no: " << line_count << " declaration_list : declaration_list COMMA ID LTHIRD error RTHIRD" << endl << endl;
 		cout << tmp << endl << endl;
 		
 		$$ = new SymbolInfo($1->getName(), "NON_TERM");
 		cout << "Error at line: " << line_count << " array index must be integer not " << $3->getName() << endl << endl;
 		fprintf(ErrorFile, "Errro at line: %d array index must be integer not %s\n\n", line_count, $3->getName().c_str());
 		total_error++;
 		
 		
 	}
 	|declaration_list ADDOP id{
		string tmp = $1->getName() + " "+ $2->getName() + " " + $3->getName();
		
		cout << "At line no: " << line_count << " declaration_list : declaration_list error ID" << endl << endl;
		cout << tmp << endl << endl;
		
		$$ = new SymbolInfo($1->getName(), "NON_TERM");
		
		cout << "Error at line: " << line_count << "Syntax error" << endl << endl;
 		fprintf(ErrorFile, "Error at line: %d Syntax Error\n\n", line_count);
 		total_error++;
	}
	|declaration_list COMMA ADDOP id{
		string tmp = $1->getName() + ", "+ $3->getName() + " " + $4->getName();
		
		cout << "At line no: " << line_count << " declaration_list : declaration_list COMMA error ID" << endl << endl;
		cout << tmp << endl << endl;
		
		$$ = new SymbolInfo($1->getName(), "NON_TERM");
		
		cout << "Error at line: " << line_count << "Syntax error" << endl << endl;
 		fprintf(ErrorFile, "Error at line: %d Syntax Error\n\n", line_count);
 		total_error++;
	}
 	

 	| ADDOP id {
 		cout << "At line no: " << line_count << " declaration_list : error ID" << endl << endl;
 		cout << $1->getName() << " "<< $2->getName() << endl << endl;
 		
 		$$ = new SymbolInfo("", "NON_TERM");
 		
 		cout << "Error at line: " << line_count << "ADDOP in declaration list" << endl << endl;
 		fprintf(ErrorFile, "Error at line: %d ADDOP in declaration list\n\n", line_count);
 		total_error++;
 	}
 	;
 		  
statements : statement{
		string tmp = $1->getName()+"\n";
		
		cout << "At line no: " << line_count << " statements : statement" << endl << endl;
		cout << tmp << endl << endl;
		
		$$ = new SymbolInfo(tmp, "NON_TERM");	
		
		// new code for IR
		$$->setAcode($1->getAcode());
	}
	| statements statement {
		string tmp = $1->getName()  +  $2->getName() + "\n";
		
		cout << "At line no: " << line_count << " statements : statements statement" << endl << endl;
		cout << tmp << endl << endl;
		
		$$ = new SymbolInfo(tmp, "NON_TERM");
		
		// new code for IR
		
		$$->setAcode($1->getAcode() + $2->getAcode());
	}
	;
	   
statement : var_declaration{
		string tmp = $1->getName();
		
		cout << "At line no: " << line_count << " statement : var_declaration" << endl << endl;
		cout << tmp << endl;
		
		$$ = new SymbolInfo(tmp, "NON_TERM");
	}
	| expression_statement{
		string tmp = $1->getName();
		
		cout << "At line no: " << line_count << " statement : expression_statement" << endl << endl;
		cout << tmp << endl << endl;
		
		$$ = new SymbolInfo(tmp, "NON_TERM");
		
		// new code for IR
		$$->setAcode($1->getAcode());
	}
	| compound_statement{
		string tmp = $1->getName();
		
		cout << "At line no: " << line_count << " statement : compound_statement" << endl << endl;
		cout << tmp << endl << endl;
		
		$$ = new SymbolInfo(tmp, "NON_TERM");
		
		// new code for IR
		$$->setAcode($1->getAcode());
	}
	| FOR LPAREN expression_statement expre expreVoid expression_statement expre expreVoid expression expre expreVoid RPAREN statement{
		string tmp = "for(" + $3->getName() + $6->getName() + $9->getName() + ")" + $13->getName();
		
		cout << "At line no: " << line_count << " statement : FOR LPAREN expression_statement expression_statement expression RPAREN statement" << endl << endl;
		cout << tmp << endl << endl;
		
		$$ = new SymbolInfo(tmp, "NON_TERM");
		
		// new code for IR
		string l1 = newLabel();
		string l2 = newLabel();
		
		string tmpAcode = $3->getAcode();
		tmpAcode += "\t" + l1 + ":\n";
		tmpAcode += $6->getAcode();
		tmpAcode += "\tMOV AX, " + $6->getSymbol() + "\n";
		tmpAcode += "\tCMP AX, 0\n";
		tmpAcode += "\tJE " + l2 + "\n";
		tmpAcode += $13->getAcode()+$9->getAcode();
		tmpAcode += "\tJMP " + l1 + "\n";
		tmpAcode += "\t" + l2 + ":\n";
		
		returnNewVariable($3->getSymbol());
		returnNewVariable($6->getSymbol());
		
		$$->setAcode(tmpAcode);
	}
	| IF LPAREN expression expre RPAREN expreVoid statement %prec LOWER_THAN_ELSE{
		string tmp = "if(" + $3->getName() + ")" + $7->getName();
		
		cout << "At line no: " << line_count << " statement : IF LPAREN expression RPAREN statement" << endl << endl;
		cout << tmp << endl << endl;
		
		$$ = new SymbolInfo(tmp, "NON_TERM");
		
		// new code for IR
		string l = newLabel();
		
		string tmpAcode = $3->getAcode();
		tmpAcode += "\tMOV AX, " + $3->getSymbol() + "\n";
		tmpAcode += "\tCMP AX, 0\n";
		tmpAcode += "\tJE " + l + "\n";
		tmpAcode += $7->getAcode();
		tmpAcode += "\t" + l + ":\n";
		
		returnNewVariable($3->getSymbol());
	}
	| IF LPAREN expression expre RPAREN expreVoid statement ELSE statement{
		string tmp = "if(" + $3->getName() + ")" + $7->getName() + "else " + $9->getName();
		
		cout << "At line no: " << line_count << " statement : IF LPAREN expression RPAREN statement ELSE statement" << endl << endl;
		cout << tmp << endl << endl;
		
		$$ = new SymbolInfo(tmp, "NON_TERM");
		
		// new code for IR
		string l1 = newLabel();
		string l2 = newLabel();
		
		string tmpAcode = $3->getAcode();
		tmpAcode += "\tMOV AX, " + $3->getSymbol() + "\n";
		tmpAcode += "\tCMP AX, 0\n";
		tmpAcode += "\tJE " + l1 + "\n";
		tmpAcode += $7->getAcode();
		tmpAcode += "\tJMP " + l2 + "\n";
		tmpAcode += "\t" + l1 + ":\n";
		tmpAcode += $9->getAcode();
		tmpAcode += "\t" + l2 + ":\n";
		
		returnNewVariable($3->getSymbol());
		
		$$->setAcode(tmpAcode);
	}
	| WHILE LPAREN expression expre RPAREN expreVoid statement{
		string tmp = "while(" + $3->getName() + ")" + $7->getName();
		
		cout << "At line no: " << line_count << " statement : WHILE LPAREN expression RPAREN statement" << endl << endl;
		cout << tmp << endl << endl;
		
		$$ = new SymbolInfo(tmp, "NON_TERM");
		
		// new code for IR
		string l1 = newLabel();
		string l2 = newLabel();
		
		string tmpAcode = "\t" + l1 + ":\n";
		tmpAcode += $3->getAcode();
		tmpAcode += "\tMOV AX, " + $3->getSymbol() + "\n";
		tmpAcode += "\tCMP AX, 0\n";
		tmpAcode += "\tJE " + l2 + "\n";
		tmpAcode += $7->getAcode();
		tmpAcode += "\tJMP " + l1 + "\n";
		tmpAcode += "\t" + l2 + ":\n";
		
		returnNewVariable($3->getSymbol());
		$$->setAcode(tmpAcode);
	}
	| PRINTLN LPAREN id RPAREN SEMICOLON{
		string tmp = "println(" + $3->getName() + ");\n";
		
		cout << "At line no: " << line_count << " statement : PRINTLN LPAREN ID RPAREN SEMICOLON" << endl << endl;
		cout << tmp << endl << endl;
		
		$$ = new SymbolInfo(tmp, "NON_TERM");
		
		SymbolInfo *tmpSymbol = table->lookUp($3->getName());
		if(tmpSymbol == NULL){
			fprintf(ErrorFile, "Error at line: %d Undeclared Variable %s\n\n", line_count, $3->getName().c_str());
			cout << "Error at line: " << line_count << " Undeclared Variable " << $3->getName() << endl << endl;
			total_error++;
		}
		
		// new code for IR
		string idSymbol = tmpSymbol->getSymbol();
		
		string tmpAcode = "\tPUSH AX\n";
		tmpAcode += "\tPUSH BX\n";
		tmpAcode += "\tPUSH GET_ADDRESS\n";
		tmpAcode += "\tPUSH " + idSymbol + "\n";
		tmpAcode += "\tCALL PRINTLN\n";
		tmpAcode += "\tPOP GET_ADDRESS\n";
		tmpAcode += "\tPOP BX\n";
		tmpAcode += "\tPOP AX\n";
		
		returnNewVariable(idSymbol);
		$$->setAcode(tmpAcode);
	}
	| RETURN expression SEMICOLON{
		string tmp = "return " + $2->getName() + ";\n";
		
		cout << "At line no: " << line_count << " statement : RETURN expression SEMICOLON" << endl << endl;
		cout << tmp << endl << endl;
		
		$$ = new SymbolInfo(tmp, "NON_TERM");
		
		if($2->getTmpType() == "void"){
			fprintf(ErrorFile, "Error at line: %d Return type is void\n\n", line_count);
			cout << "Error at line: " << line_count << " Return type is void" << endl << endl;
			total_error++;
		} 
		
		// new code for IR
		string tmpAcode = $2->getAcode();
		tmpAcode += "\tPUSH " + $2->getSymbol() + "\n";
		returnNewVariable($2->getSymbol());
		$$->setAcode(tmpAcode);
	}
	| RETURN expression error{
		string tmp = "return " + $2->getName() + "\n";
		
		cout << "At line no: " << line_count << " statement : RETURN expression error" << endl << endl;
		cout << tmp << endl << endl;
		
		$$ = new SymbolInfo(tmp, "NON_TERM");
		
		if($2->getTmpType() == "void"){
			fprintf(ErrorFile, "Error at line: %d Return type is void\n\n", line_count);
			cout << "Error at line: " << line_count << " Return type is void" << endl << endl;
			total_error++;
		} 
		
		cout << "Error at line: " << line_count << " semicolon(;) is missing" << endl << endl;
		fprintf(ErrorFile, "Error at line: %d semicolon(;) is missing\n\n", line_count);
		total_error++;
	}
	| PRINTLN LPAREN id RPAREN error{
		string tmp = "printf(" + $3->getName() + ")\n";
		
		cout << "At line no: " << line_count << " statement : PRINTLN LPAREN ID RPAREN error" << endl << endl;
		cout << tmp << endl << endl;
		
		$$ = new SymbolInfo(tmp, "NON_TERM");
		
		SymbolInfo *tmpSymbol = table->lookUp($3->getName());
		if(tmpSymbol == NULL){
			fprintf(ErrorFile, "Error at line: %d Undeclared Variable %s\n\n", line_count, $3->getName().c_str());
			cout << "Error at line: " << line_count << " Undeclared Variable " << $3->getName() << endl << endl;
			total_error++;
		}
		
		cout << "Error at line: " << line_count << " semicolon(;) is missing" << endl << endl;
		fprintf(ErrorFile, "Error at line: %d semicolon(;) is missing\n\n", line_count);
		total_error++;
	}
	| ELSE statement{
		string tmp = "else "+ $2->getName();
		cout << "At line no: " << line_count << " statement: ELSE statement" << endl << endl;
		cout << tmp << endl << endl;
		
		$$ = new SymbolInfo(tmp, "NON_TERM");
		
		cout << "Error at line : " << line_count << " else statement without any if" << endl << endl;
		fprintf(ErrorFile, "Error at line: %d else statement without any if\n\n", line_count);
		total_error++;
	}
	;
	  
expre: {
		finalType = type;
	}
	;

expreVoid:{
		if(finalType == "void"){
			fprintf(ErrorFile, "Error at line: %d Void type within expression\n\n", line_count);
			cout << "Error at line: " << line_count << " Void type within expression" << endl << endl;
			total_error++;
		}
	}
	;

expression_statement 	: SEMICOLON{
		string tmp = ";";
		
		cout << "At line no: " << line_count << " expression_statement : SEMICOLON" << endl << endl;
		cout << tmp << endl << endl;
		
		$$ = new SymbolInfo(tmp, "NON_TERM");
		$$->setTmpType("int");
		$$->setSymbol("");
		type = "int";
	}		
	| expression SEMICOLON{
		string tmp = $1->getName() + ";";
		
		cout << "At line no: " << line_count << " expression_statement : expression SEMICOLON" << endl << endl;
		cout << tmp << endl << endl;
		
		$$ = new SymbolInfo(tmp, "NON_TERM");
		$$->setTmpType($1->getTmpType());
		
		type = $1->getTmpType();
		
		// new code for IR
		
		$$->setAcode($1->getAcode());
		$$->setSymbol($1->getSymbol());
	} 
	| expression error{
		string tmp = $1->getName();
		
		cout << "At line no: " << line_count << " expression_statement : expression error" << endl << endl;
		cout << tmp << endl << endl;
		
		$$ = new SymbolInfo(tmp, "NON_TERM");
		$$->setTmpType($1->getTmpType());
		
		type = $1->getTmpType();
		
		cout << "Error at line: " << line_count << " semicolon(;) is missing" << endl << endl;
		fprintf(ErrorFile, "Error at line: %d semicolon(;) is missing\n\n", line_count);
		total_error++;
	}
	| UNRECOGNIZED{
		cout << "At line no: " << line_count << "expression_statement: UNRECOGNIZED" << endl << endl;
		cout << $1->getName() << endl << endl;
		
		cout << "Error at line: " << line_count << " unrecognized character " << $1->getName() << endl << endl;
		fprintf(ErrorFile, "Error at line: %d unrecognized character %s\n\n", line_count, $1->getName().c_str());
		total_error++;
		
		$$ = new SymbolInfo("", "NON_TERM");
	}
	;
	  
variable : id {
		cout << "At line no: " << line_count << " variable : ID" << endl << endl;
		cout << $1->getName() << endl << endl;
		
		$$ = new SymbolInfo($1->getName(), "NON_TERM");
		
		SymbolInfo *tmp = table->lookUp($1->getName());
		
		$$->setTmpSize(-1);
		
		if(tmp == NULL){
			fprintf(ErrorFile, "Error at line: %d Undeclared Variable: %s\n\n", line_count, $1->getName().c_str());
			cout << "Error at line: " << line_count << " Undeclared Variable: " << $1->getName() << endl << endl;
			total_error++;
			$$->setTmpType("float");
		}
		else{
			if(tmp->getTmpType() != "void"){
				$$->setTmpType(tmp->getTmpType());
				
				// new code for IR
				$$->setSymbol(tmp->getSymbol());
			}
			else{
				$$->setTmpType("float");
			}
		}
		
		if(tmp != NULL && tmp->getTmpSize() != -1){
			if(tmp->getTmpSize() > 0){
				fprintf(ErrorFile, "Error at line: %d Type Mismatch %s is an array\n\n", line_count, $1->getName().c_str());
				cout << "Error at line: " << line_count << " Type Mismatch " << $1->getName() << " is an array" << endl << endl;
				total_error++;
			}
			else{
				fprintf(ErrorFile, "Error at line: %d Type Mismatch %s is a function \n\n", line_count, $1->getName().c_str());
				cout << "Error at line: " << line_count << " Type Mismatch " << $1->getName() << " is a function" << endl << endl;
				total_error++;
			}
			
		
			
		}
		
	}		
	| id LTHIRD expression RTHIRD{
		string tmp = $1->getName() + "[" + $3->getName() + "]";
		cout << "At line no: " << line_count << " variable : ID LTHIRD expression RTHIRD" << endl << endl;
		cout << tmp << endl << endl;
		
		$$ = new SymbolInfo(tmp, "NON_TERM");
		SymbolInfo *tmpSymbol = table->lookUp($1->getName());
		
		if(tmpSymbol == NULL){
			fprintf(ErrorFile, "Error at line: %d Undeclared Variable: %s\n\n", line_count, $1->getName().c_str());
			cout << "Error at line: " << line_count << " Undeclared Variable " << $1->getName() << endl << endl;
			total_error++;
			$$->setTmpType("float");
		}
		else{
			if(tmpSymbol->getTmpType() != "void"){
				$$->setTmpType(tmpSymbol->getTmpType());
				
				// new code for IR
				$$->setTmpSize(tmpSymbol->getTmpSize());
				$$->setSymbol(tmpSymbol->getSymbol());
			}
			else{
				$$->setTmpSize(0);
				$$->setTmpType("float");
			}
		}
		
		if(tmpSymbol != NULL && tmpSymbol->getTmpSize() <= -1){
			fprintf(ErrorFile, "Error at line: %d %s Not An Array\n\n", line_count, $1->getName().c_str());
			cout << "Error at line: " << line_count << " " << $1->getName() << " Not An Array" << endl <<endl;
			total_error++;
		}
		
		if($3->getTmpType() != "int"){
			fprintf(ErrorFile, "Error at line: %d Expression inside third brackets not an integer\n\n", line_count);
			cout << "Error at line: " << line_count << " Expression inside third brackets not an integer" << endl << endl;
			total_error++;
		}
		
		if($3->getTmpType() == "void"){
			fprintf(ErrorFile, "Error at line: %d Expression inside third brackets not an integer\n\n", line_count);
			cout << "Error at line: " << line_count << " Expression inside third brackets not an integer" << endl << endl;
			total_error++;
		}		
		
		
		// new code for IR
		string tmpAcode = $3->getAcode();
		tmpAcode += "\tMOV BX, " + $3->getSymbol() + "\n";
		tmpAcode += "\tADD BX, BX\n";
	} 
	 ;
	 
 expression : logic_expression{
 		cout << "At line no: " << line_count << " expression : logic_expression" << endl << endl;
 		cout << $1->getName() << endl << endl;
 		
 		$$ = new SymbolInfo($1->getName(), "NON_TERM");
 		$$->setTmpType($1->getTmpType());
 		type = $1->getTmpType();
 		
 		// new code for IR
 		
 		$$->setAcode($1->getAcode());
 		$$->setSymbol($1->getSymbol());
 		
 		
 		
 	}	
	| variable ASSIGNOP logic_expression{
		string tmp = $1->getName()+"="+$3->getName();
		cout << "At line no: " << line_count << " expression : variable ASSIGNOP logic_expression" << endl << endl;
		cout << tmp << endl << endl;
		
		$$ = new SymbolInfo(tmp, "NON_TERM");
		
		//  type checking
		////// consistency of assignment operator with each other//////////
		
		if($3->getTmpType() == "void"){
			fprintf(ErrorFile, "Error at line: %d Void Type within expression\n\n", line_count);
			cout << "Error at line: " << line_count << " Void Type within expression" << endl << endl;
			total_error++;
			$3->setTmpType("float");
		}
		else if($1->getTmpType() == "void"){
			fprintf(ErrorFile, "Error at line: %d Void Type within expression\n\n", line_count);
			cout << "Error at line: " << line_count << " Void Type within expression" << endl << endl;
			total_error++;
			$1->setTmpType("float");
		}
		if($1->getTmpType() == "int" && $3->getTmpType() == "float"){
			fprintf(ErrorFile, "Error at line: %d: Type Mismatch (%s = %s)\n\n", line_count, $1->getTmpType().c_str(), $3->getTmpType().c_str());
			cout << "Error at line: " << line_count << " Type Mismatch" << endl << endl;
			total_error++;
		}
		
		$$->setTmpType($1->getTmpType());
		type = $1->getTmpType();
		
		// new code for IR
		
		string tmpAcode = "";
		string tmpSymbol = $1->getSymbol();
		
		if($1->getTmpSize() > -1){
			string tmpVar = newVariable();
			tmpSymbol = tmpVar;
				
			tmpAcode = $3->getAcode() + $1->getAcode();
			tmpAcode += "\tMOV AX, " + $3->getSymbol() + "\n";
			tmpAcode += "\tMOV " + $1->getSymbol() + "[bx], AX\n";
			tmpAcode += "\tMOV " + tmpVar + ", AX\n";
			
		}
		else{
			tmpAcode = $1->getAcode()+$3->getAcode();
			tmpAcode += "\tMOV AX, " + $3->getSymbol() + "\n";
			tmpAcode += "\tMOV " + $1->getSymbol() + ", AX\n";
		}
		
		returnNewVariable($3->getSymbol());
		
		$$->setAcode(tmpAcode);
		$$->setSymbol(tmpSymbol);
	
	}
	;
			
logic_expression : rel_expression{
		cout << "At line no: " << line_count << " logic_expression : rel_expression" << endl << endl;
		cout << $1->getName() << endl << endl;
		
		$$ = new SymbolInfo($1->getName(), "NON_TERM");
		$$->setTmpType($1->getTmpType());
		
		// new code for IR
		
		$$->setAcode($1->getAcode());
		$$->setSymbol($1->getSymbol());
		
	}	
	| rel_expression LOGICOP rel_expression{
		string tmp = $1->getName()+$2->getName()+$3->getName(); 
		cout << "At line no: " << line_count << " logic_expression : rel_expression LOGICOP rel_expression" << endl << endl;
		cout << tmp << endl << endl;
		
		$$ = new SymbolInfo(tmp, "NON_TERM");
		$$->setTmpType("int");
		
		if($1->getTmpType() == "void"){
			fprintf(ErrorFile, "Error at line: %d Void Type within expression\n\n", line_count);
			cout << "Error at line: " << line_count << " Void Type within expression" << endl << endl;
			total_error++;
		}
		
		if($3->getTmpType() == "void"){
			fprintf(ErrorFile, "Error at line: %d Void Type within expression\n\n", line_count);
			cout << "Error at line: " << line_count << " Void Type within expression" << endl << endl;
			total_error++;
		}
		
		// new code for IR
		
		string l1 = newLabel();
		string l2 = newLabel();
		string tmpVar = newVariable();
		
		string tmpAcode = $1->getAcode() + $3->getAcode();
		string tmpSymbol = tmpVar;
		
		if($2->getName() == "&&"){
			tmpAcode += "\tMOV AX, " + $1->getSymbol() + "\n";
			tmpAcode += "\tCMP AX, 0\n";
			tmpAcode += "\tJE " + l1 + "\n";
			tmpAcode += "\tMOV AX, " + $3->getSymbol() + "\n";
			tmpAcode += "\tCMP AX, 0\n";
			tmpAcode += "\tJE " + l1 + "\n";
			tmpAcode += "\tMOV AX, 1\n";
			tmpAcode += "\tMOV " + tmpVar + ", AX\n";
			tmpAcode += "\tJMP " + l2 + "\n";
			tmpAcode += "\t" + l1 + ":\n";
			tmpAcode += "\tMOV AX, 0\n";
			tmpAcode += "\tMOV " + tmpVar + ", AX\n";
			tmpAcode += "\t" + l2 + ":\n";
		}
		else if($2->getName() == "||"){
			tmpAcode += "\tMOV AX, " + $1->getSymbol() + "\n";
			tmpAcode += "\tCMP AX, 0\n";
			tmpAcode += "\tJNE " + l1 + "\n";
			tmpAcode += "\tMOV AX, " + $3->getSymbol() + "\n";
			tmpAcode += "\tCMP AX, 0\n";
			tmpAcode += "\tJNE " + l1 + "\n";
			tmpAcode += "\tMOV AX, 0\n";
			tmpAcode += "\tMOV " + tmpVar + ", AX\n";
			tmpAcode += "\tJMP " + l2 + "\n";
			tmpAcode += "\t" + l1 + ":\n";
			tmpAcode += "\tMOV AX, 1\n";
			tmpAcode += "\tMOV " + tmpVar + ", AX\n";
			tmpAcode += "\t" + l2 + ":\n";
		}
		
		returnNewVariable($1->getSymbol());
		returnNewVariable($3->getSymbol());
		
		$$->setAcode(tmpAcode);
		$$->setSymbol(tmpSymbol);
	} 	
	;
			
rel_expression	: simple_expression {
		cout << "At line no: " << line_count << " rel_expression : simple_expression" << endl << endl;
		cout << $1->getName() << endl << endl;
		
		$$ = new SymbolInfo($1->getName(), "NON_TERM");
		$$->setTmpType($1->getTmpType());
		
		// new code for IR
		
		$$->setAcode($1->getAcode());
		$$->setSymbol($1->getSymbol());
		
		
	}
	| simple_expression RELOP simple_expression{
		string tmp = $1->getName()+$2->getName()+$3->getName();
		
		cout << "At line no: " << line_count << " rel_expression : simple_expression RELOP simple_expression" << endl << endl;
		cout << tmp << endl << endl;
		
		$$ = new SymbolInfo(tmp, "NON_TERM");
		$$->setTmpType("int");
		
		if($1->getTmpType() == "void"){
			fprintf(ErrorFile, "Error at line: %d Void Type within expression\n\n", line_count);
			cout << "Error at line: " << line_count << " Void Type within expression" << endl << endl;
			total_error++;
		}
		
		if($3->getTmpType() == "void"){
			fprintf(ErrorFile, "Error at line: %d Void Type within expression\n\n", line_count);
			cout << "Error at line: " << line_count <<  " Void Type within expression" << endl << endl;
			total_error++;
		}
		
		// new code for IR
		string l1 = newLabel();
		string l2 = newLabel();
		string tmpVar = newVariable();
		
		string tmpAcode = $1->getAcode() + $3->getAcode();
		string tmpSymbol = tmpVar;
		
		tmpAcode += "\tMOV AX, " + $1->getSymbol() + "\n";
		tmpAcode += "\tCMP AX, " + $3->getSymbol() + "\n";
		
		returnNewVariable($1->getSymbol());
		returnNewVariable($3->getSymbol());
		
		if($2->getName() == ">") tmpAcode += "\tJG " + l1 + "\n";	
		else if($2->getName() == "<") tmpAcode += "\tJL " + l1 + "\n";
		else if($2->getName() == "==") tmpAcode += "\tJE " + l1 + "\n";
		else if($2->getName() == "<=") tmpAcode += "\tJLE " + l1 + "\n";
		else if($2->getName() == ">=") tmpAcode += "\tJGE " + l1 + "\n";
		else if($2->getName() == "!=") tmpAcode += "\tJNE " + l1 + "\n";
		
		tmpAcode += "\tMOV AX, 0\n";
		tmpAcode += "\tMOV " + tmpVar + ", AX\n";
		tmpAcode += "\tJMP " + l2 + "\n";
		tmpAcode += "\t" + l1 + ":\n";
		tmpAcode += "\tMOV AX, 1\n";
		tmpAcode += "\tMOV " + tmpVar + ", AX\n";
		tmpAcode += "\t" + l2 + ":\n";
		
		
		$$->setAcode(tmpAcode);
		$$->setSymbol(tmpSymbol);
		
	}	
	;
				
simple_expression : term {
		cout << "At line no: " << line_count << " simple_expression : term" << endl << endl;
		cout << $1->getName() << endl << endl;
		
		$$ = new SymbolInfo($1->getName(), "NON_TERM");
		$$->setTmpType($1->getTmpType());
		
		// new code for IR
		
		$$->setAcode($1->getAcode());
		$$->setSymbol($1->getSymbol());
	}
	| simple_expression ADDOP term{
		string tmp = $1->getName()+$2->getName()+$3->getName();
		 
		cout << "At line no: " << line_count << " simple_expression : simple_expression ADDOP term" << endl << endl;
		cout << tmp << endl << endl;
		
		$$ = new SymbolInfo(tmp, "NON_TERM");	
		
		if($1->getTmpType() == "void"){
			fprintf(ErrorFile, "Error at line: %d Void Type within expression\n\n", line_count);
			cout << "Error at line: " << line_count << " Void Type within expression" << endl << endl;
			total_error++;
			
			$1->setTmpType("float");
		}
		
		if($3->getTmpType() == "void"){
			fprintf(ErrorFile, "Error at line: %d Void Type within expression\n\n", line_count);
			cout << "Error at line: " << line_count << " Void Type within expression" << endl << endl;
			total_error++;
			$3->setTmpType("float");
		} 
		
		if($1->getTmpType() == "float" || $3->getTmpType() == "float"){
			$$->setTmpType("float");
		} 
		else{
			$$->setTmpType($1->getTmpType());
		}
		
		// new code for IR
		
		string tmpVar = newVariable();
		
		string tmpAcode = $1->getAcode() + $3->getAcode();
		string tmpSymbol = tmpVar;
		
		if($2->getName() == "+"){
			tmpAcode += "\tMOV AX, " + $1->getSymbol() + "\n";
			tmpAcode += "\tADD AX, " + $3->getSymbol() + "\n";
			tmpAcode += "\tMOV " + tmpVar + ", AX\n";
		}
		else if($2->getName() == "-"){
			tmpAcode += "\tMOV AX, " + $1->getSymbol() + "\n";
			tmpAcode += "\tSUB AX, " + $3->getSymbol() + "\n";
			tmpAcode += "\tMOV " + tmpVar + ", AX\n";
		}
		returnNewVariable($3->getSymbol());
		
		$$->setAcode(tmpAcode);
		$$->setSymbol(tmpSymbol);
	} 
	;
					
term :	unary_expression{
		cout << "At line no: " << line_count << " term : unary_expression" << endl << endl;
		cout << $1->getName() << endl << endl;
		
		$$ = new SymbolInfo($1->getName(), "NON_TERM");
		$$->setTmpType($1->getTmpType());
		
		// new code for IR
		
		$$->setAcode($1->getAcode());
		$$->setSymbol($1->getSymbol());
	}
     	|  term MULOP unary_expression{
     		string tmp = $1->getName()+$2->getName()+$3->getName(); 
     		cout << "At line no: " << line_count << " term : term MULOP unary_expression" << endl << endl;
     		cout << tmp << endl << endl;
     		
     		$$ = new SymbolInfo(tmp, "NON_TERM");
     		
     		if($1->getTmpType() == "void"){
			fprintf(ErrorFile, "Error at line: %d Void Type within MULOP expression\n\n", line_count);
			cout << "Error at line: " << line_count << " Void Type within MULOP expression" << endl << endl;
			total_error++;
			
			$1->setTmpType("float");
		}
		
		if($3->getTmpType() == "void"){
			fprintf(ErrorFile, "Error at line: %d Void Type within MULOP expression\n\n", line_count);
			cout << "Error at line: " << line_count << " Void Type within MULOP expression" << endl << endl;
			total_error++;
			$3->setTmpType("float");
		} 
		
		if($2->getName() == "%" && ($1->getTmpType() != "int" || $3->getTmpType() != "int")){
			fprintf(ErrorFile, "Error at line: %d Non-Integer operand on modulus operator\n\n", line_count);
			cout << "Error at line: " << line_count << " Non-Integer operand on modulus operator" << endl << endl;
			total_error++;
			
			$$->setTmpType("int");
		}
		if($2->getName() == "%" && $3->getName() == "0"){
			fprintf(ErrorFile, "Error at line: %d Modulus by zero\n\n", line_count);
			cout << "Error at line: " << line_count << " Modulus by zero" << endl << endl;
			total_error++;
			
			$$->setTmpType("int");
			
		}
		else if($2->getName() != "%" && ($1->getTmpType() == "float" || $3->getTmpType() == "float")){
			$$->setTmpType("float");
		}
		else{
			$$->setTmpType($1->getTmpType());
		}
		
		// new code for IR
		tmp = newVariable();
		string tmpAcode = $1->getAcode() + $3->getAcode();
		string tmpSymbol = tmp;
		
		if($2->getName() == "*"){
			tmpAcode += "\tMOV AX, " + $1->getSymbol() + "\n";
			tmpAcode += "\tMOV BX, " + $3->getSymbol() + "\n";
			tmpAcode += "\tIMUL BX\n";
			tmpAcode += "\tMOV " + tmp + ", AX\n";
		}
		else if($2->getName() == "/"){
			tmpAcode += "\tMOV AX, " + $1->getSymbol() + "\n";
			tmpAcode += "\tCWD\n";
			tmpAcode += "\tMOV BX, " + $3->getSymbol() + "\n";
			tmpAcode += "\tIDIV BX\n";
			tmpAcode += "\tMOV " + tmp + ", AX\n";
		}
		else{
			tmpAcode += "\tMOV AX, " + $1->getSymbol() + "\n";
			tmpAcode += "\tCWD\n";
			tmpAcode += "\tMOV BX, " + $3->getSymbol() + "\n";
			tmpAcode += "\tIDIV BX\n";
			tmpAcode += "\tMOV " + tmp + ", DX\n";
		}
		returnNewVariable($3->getSymbol());
		
		$$->setAcode(tmpAcode);
		$$->setSymbol(tmpSymbol);
     		
     	}        
     	;

unary_expression : ADDOP unary_expression{
		cout << "At line no: " << line_count << " unary_expression : ADDOP unary_expression" << endl << endl;
		cout << $1->getName() << $2->getName() << endl << endl;
		
		$$ = new SymbolInfo($1->getName()+$2->getName(), "NON_TERM");
		
		if($2->getTmpType() == "void"){
			fprintf(ErrorFile, "Error at line: %d Void Type within expression\n\n", line_count);
			cout << "Error at line: " << line_count << " Void Type within expression" << endl << endl;
			total_error++;
			$$->setTmpType("float");
		}
		else{
			$$->setTmpType($2->getTmpType());
		}
		
		// new code for IR
		
		string tmpSymbol = $2->getSymbol();
		string tmpAcode = $2->getAcode();
		
		if($1->getName() == "-"){
			string tmp = newVariable();
			tmpAcode += "\tMOV AX, "+ $2->getSymbol() + "\n";
			tmpAcode += "\tMOV "+ tmp + ", AX\n";
			tmpAcode += "\tNEG " + tmp + "\n";
			tmpSymbol = tmp;
		}
		
		$$->setAcode(tmpAcode);
		$$->setSymbol(tmpSymbol);
	} 
	| NOT unary_expression{
		cout << "At line no: " << line_count << " unary_expression : NOT unary_expression" << endl << endl;
		cout << "!" << $2->getName() << endl << endl;
		
		$$ = new SymbolInfo("!"+$2->getName(), "NON_TERM");
		
		if($2->getTmpType() == "void"){
			fprintf(ErrorFile, "Error at line: %d Void Type within expression\n\n", line_count);
			cout << "Error at line: " << line_count << " Void Type within expression" << endl << endl;
			total_error++;
			$$->setTmpType("float");
		}
		else{
			$$->setTmpType($2->getTmpType());
		} 
		
		// new code for IR
		
		string l1 = newLabel();
		string l2 = newLabel();
		string tmp = newVariable();
		
		string tmpAcode = $2->getAcode()+ "\tMOV AX, "+$2->getSymbol() + "\n";
		tmpAcode += "\tCMP AX, 0\n\tJE "+ l1 + "\n";
		tmpAcode += "\tMOV AX, 0\n";
		tmpAcode += "\tMOV "+ tmp + ", AX\n\tJMP "+ l2 + "\n";
		tmpAcode += "\t" + l1 + ": \n\tMOV AX, 1\n";
		tmpAcode += "\tMOV " + tmp + ", AX\n\t" + l2 + ":\n";
		
		$$->setAcode(tmpAcode);
		$$->setSymbol(tmp);
	} 
	| factor {
		cout << "At line no: " << line_count << " unary_expression : factor" << endl << endl;
		cout << $1->getName() << endl << endl;
		
		$$ = new SymbolInfo($1->getName(), "NON_TERM");
		$$->setTmpType($1->getTmpType());
		
		// new code for IR
		$$->setSymbol($1->getSymbol());
		$$->setAcode($1->getAcode());
	} 
	;
	
factor	: variable {

		cout << "At line no: " << line_count << " factor : variable" << endl  << endl;
		cout << $1->getName() << endl  << endl;

		$$ = new SymbolInfo($1->getName(), "NON_TERM");
		$$->setTmpType($1->getTmpType());
		
		// new code for IR
		
		$$->setTmpSize($1->getTmpSize());
		string tmpSymbol = $1->getSymbol();
		string tmpAcode = $1->getAcode();
		
		if($1->getTmpSize() > -1 ){
			string tmp = newVariable();
			tmpSymbol = tmp;
			tmpAcode += "\tMOV AX, "+ $1->getSymbol() + "[BX]\n\tMOV "+ tmp+ ", AX\n";
			
		}
		
		$$->setAcode(tmpAcode);
		$$->setSymbol(tmpSymbol);
		delete $1;
	}

	| id LPAREN argument_list RPAREN{
		string tmp = $1->getName()+"("+$3->getName()+")";
		cout << "At line no: " << line_count << " factor : ID LPAREN argument_list RPAREN" << endl  << endl;
        	cout << tmp << endl  << endl;

		$$ = new SymbolInfo(tmp, "NON_TERM");
		
		SymbolInfo *symbol = table->lookUp($1->getName());
		
		if(symbol == NULL){
			fprintf(ErrorFile, "Error at line: %d Undeclared Identifier %s\n\n", line_count, $1->getName().c_str());
			cout << "Error at line: " << line_count << " Undeclared Identifier " << $1->getName() << endl << endl;
			total_error++;
			$$->setTmpType("float");
		}
		else if(symbol->getTmpSize() != -3){
			fprintf(ErrorFile, "Error at line: %d Type Mismatch\n\n", line_count);
			cout << "Error at line: " << line_count << " Type Mismatch" << endl << endl;
			total_error++;
			$$->setTmpType("float");
		}
		else{
			if(symbol->getParameterSize() == 1 && argumentList.size() == 0 && symbol->getParameter(0).type == "void"){
				$$->setTmpType(symbol->getTmpType());
			}
			else if(symbol->getParameterSize() != argumentList.size()){
				fprintf(ErrorFile, "Error at line: %d  Inconsistency of function call(Parameter list size don't match) in function %s\n\n", line_count, $1->getName().c_str());
				cout << "Error at line: " << line_count << " Inconsistency of function call(Parameter list size don't match) in function " << $1->getName() << endl << endl;
				total_error++;
				$$->setTmpType("float");
			}
			else{
				bool mm = true;
				int i;
				
				for(i = 0; i < argumentList.size(); i++){
					if(symbol->getParameter(i).type != argumentList[i]){
						mm = false;
						break;
					}
				}
				
				if(mm){
					$$->setTmpType(symbol->getTmpType());
				}
				else{
					fprintf(ErrorFile, "Error at line: %d %dth argument mismatch in function %s\n\n", line_count, i+1 , $1->getName().c_str());
					cout << "Error at line: " << line_count << " " << i+1 << "th argument mismatch in function " << $1->getName() << endl << endl;
					total_error++;
					$$->setTmpType("float");
				}
			}
		}
		
		argumentList.clear();
		
		// new code for IR
		
		tmp = newVariable();
		string tmpAcode = $3->getAcode();
		tmpAcode += "\tPUSH AX\n";
		tmpAcode += "\tPUSH BX\n";
		tmpAcode += "\tPUSH GET_ADDRESS\n";
		for(string s: sendArguList){
			tmpAcode += "\tPUSH "+ s + "\n";
		}
		tmpAcode += "\tCALL " + symbol->getSymbol() + "\n";
		
		if(symbol->getTmpType() != "void"){
			tmpAcode += "\tPOP "+ tmp + "\n"; 
		}
		
		tmpAcode += "\tPOP GET_ADDRESS\n";
		tmpAcode += "\tPOP BX\n";
		tmpAcode += "\tPOP AX\n";
		$$->setAcode(tmpAcode);
		$$->setSymbol(tmp);
		
		sendArguList.clear();
		
	}

	| LPAREN expression RPAREN{
		cout << "At line no: " << line_count << " factor : LPAREN expression RPAREN" << endl << endl;
		cout << "(" << $2->getName() << ")" << endl << endl;
		
		$$ = new SymbolInfo("("+$2->getName()+")", "NON_TERM");
		
		if($2->getTmpType() == "void"){
			fprintf(ErrorFile, "Error at line: %d Void Type within expression\n\n", line_count);
			cout << "Error at line: " << line_count << " Void Type within expression" << endl << endl;
			total_error++;
			
			$2->setTmpType("float");
		}
		$$->setTmpType($2->getTmpType());
		
		// new code for IR
		
		$$->setAcode($2->getAcode());
		$$->setSymbol($2->getSymbol());
	}
	| CONST_INT {
		cout << "At line no: " << line_count << " factor : CONST_INT" << endl << endl;
		cout << $1->getName() << endl << endl;
		
		$$ = new SymbolInfo($1->getName(), "NON_TERM");
		$$->setTmpType("int");
		
		// new code for IR
		$$->setSymbol($1->getName());
		
	}
	| CONST_FLOAT{
		cout << "At line no: " << line_count << " factor : CONST_FLOAT" << endl << endl;
		cout << $1->getName() << endl << endl;
		
		$$ = new SymbolInfo($1->getName(), "NON_TERM");
		$$->setTmpType("float");
		
		// new code for IR
		$$->setSymbol($1->getName());
	}
	| variable INCOP {
		cout << "At line no: " << line_count << " factor : variable INCOP" << endl << endl;
		cout << $1->getName() << "++" << endl << endl;
		
		$$ = new SymbolInfo($1->getName()+"++", "NON_TERM");
		$$->setTmpType($1->getTmpType());
		
		// new code for IR
		
		string tmp = newVariable();
		string tmpAcode = $1->getAcode();
		if($1->getTmpSize() > -1){
			tmpAcode += "\tMOV AX, "+ $1->getSymbol() + "[BX]\n\tMOV "+ tmp + ", AX\n\tINC "+ $1->getSymbol() + "[BX]\n";
		}
		else {
			tmpAcode += "\tMOV AX, " + $1->getSymbol() + "\n\tMOV "+tmp + ", AX\n\tINC " +$1->getSymbol() + "\n";  
		}
		$$->setAcode(tmpAcode);
		$$->setSymbol(tmp);
	}
	| variable DECOP{
		cout << "At line no: " << line_count << " factor : variable DECOP" << endl << endl;
		cout << $1->getName() << "--" << endl << endl;
		
		$$ = new SymbolInfo($1->getName()+"--", "NON_TERM");
		$$->setTmpType($1->getTmpType());
		
		// new code for IR
		
		string tmp = newVariable();
		string tmpAcode = $1->getAcode();
		if($1->getTmpSize() > -1){
			tmpAcode += "\tMOV AX, "+ $1->getSymbol() + "[BX]\n\tMOV "+ tmp + ", AX\n\tDEC "+ $1->getSymbol() + "[BX]\n";
		}
		else {
			tmpAcode += "\tMOV AX, " + $1->getSymbol() + "\n\tMOV "+tmp + ", AX\n\tDEC " +$1->getSymbol() + "\n";  
		}
		
		$$->setAcode(tmpAcode);
		$$->setSymbol(tmp);
	}
	| id LPAREN argument_list error{
		string tmp = $1->getName()+"("+$3->getName();
		cout << "At line no: " << line_count << " factor : ID LPAREN argument_list error" << endl  << endl;
        	cout << tmp << endl  << endl;
        	
        	cout << "Error at line: " << line_count << " right parenthesis ')' is missing" << endl << endl;
        	fprintf(ErrorFile, "Error at line: %d right parenthesis ')' is missing\n\n", line_count);
		total_error++;
		
		
		$$ = new SymbolInfo(tmp, "NON_TERM");
		
		SymbolInfo *symbol = table->lookUp($1->getName());
		
		if(symbol == NULL){
			fprintf(ErrorFile, "Error at line: %d Undeclared Identifier %s\n\n", line_count, $1->getName().c_str());
			cout << "Error at line: " << line_count << " Undeclared Identifier " << $1->getName() << endl << endl;
			total_error++;
			$$->setTmpType("float");
		}
		else if(symbol->getTmpSize() != -3){
			fprintf(ErrorFile, "Error at line: %d Type Mismatch\n\n", line_count);
			cout << "Error at line: " << line_count << " Type Mismatch" << endl << endl;
			total_error++;
			$$->setTmpType("float");
		}
		else{
			if(symbol->getParameterSize() == 1 && argumentList.size() == 0 && symbol->getParameter(0).type == "void"){
				$$->setTmpType(symbol->getTmpType());
			}
			else if(symbol->getParameterSize() != argumentList.size()){
				fprintf(ErrorFile, "Error at line: %d  Inconsistency of function call(Parameter list size don't match) in function %s\n\n", line_count, $1->getName().c_str());
				cout << "Error at line: " << line_count << " Inconsistency of function call(Parameter list size don't match) in function " << $1->getName() << endl << endl;
				total_error++;
				$$->setTmpType("float");
			}
			else{
				bool mm = true;
				int i;
				
				for(i = 0; i < argumentList.size(); i++){
					if(symbol->getParameter(i).type != argumentList[i]){
						mm = false;
						break;
					}
				}
				
				if(mm){
					$$->setTmpType(symbol->getTmpType());
				}
				else{
					fprintf(ErrorFile, "Error at line: %d %dth argument mismatch in function %s\n\n", line_count, i+1 , $1->getName().c_str());
					cout << "Error at line: " << line_count << " " << i+1 << "th argument mismatch in function " << $1->getName() << endl << endl;
					total_error++;
					$$->setTmpType("float");
				}
			}
		}
		
		argumentList.clear();
	}
	| LPAREN expression error{
		cout << "At line no: " << line_count << " factor : LPAREN expression RPAREN" << endl << endl;
		cout << "(" << $2->getName() << ")" << endl << endl;
		
		cout << "Error at line: " << line_count << " right parenthesis ')' is missing" << endl << endl;
        	fprintf(ErrorFile, "Error at line: %d right parenthesis ')' is missing\n\n", line_count);
		total_error++;
		
		$$ = new SymbolInfo("("+$2->getName()+")", "NON_TERM");
		
		if($2->getTmpType() == "void"){
			fprintf(ErrorFile, "Error at line: %d Void Type within expression\n\n", line_count);
			cout << "Error at line: " << line_count << " Void Type within expression" << endl << endl;
			total_error++;
			
			$2->setTmpType("float");
		}
		$$->setTmpType($2->getTmpType());
	}
	;
	
argument_list : arguments{
		cout << "At line no: " << line_count << " argument_list : arguments" << endl << endl;
		cout << $1->getName() << endl << endl;
		
		
		$$ = new SymbolInfo($1->getName(), "NON_TERM");
		
		// new code for IR
		$$->setAcode($1->getAcode());
		delete $1;	
	}
	|{
		cout << "At line no: " << line_count << " argumentList : empty" << endl << endl;
		cout << "" << endl << endl;
		
		$$ = new SymbolInfo("", "NON_TERM");
	}
	;
	
arguments : arguments COMMA logic_expression{
		cout << "At line no: " << line_count << " arguments : arguments COMMA logic_expression" << endl << endl;
		cout << $1->getName() << "," << $3->getName() << endl << endl;
		
		$$ = new SymbolInfo($1->getName()+ "," + $3->getName(), "NON_TERM");
		if($3->getTmpType() == "void"){
			fprintf(ErrorFile, "Error at line: %d Void Type within expression\n\n", line_count);
			cout << "Error at line: " << line_count << " Void Type within expression" << endl << endl;
			total_error++;
			
			$3->setTmpType("float");
		}
		
		argumentList.push_back($3->getTmpType());
		
		// new code for IR
		$$->setAcode($1->getAcode()+$3->getAcode());
		sendArguList.push_back($3->getSymbol());
		delete $1;
		delete $3;
		
	}
	| logic_expression{
		cout << "At line no: " << line_count << " arguments : logic_expression" << endl << endl;
		cout << $1->getName() << endl << endl;
		
		$$ = new SymbolInfo($1->getName(), "NON_TERM");
		if($1->getTmpType() == "void"){
			fprintf(ErrorFile, "Error at line: %d Void Type within expression\n\n", line_count);
			cout << "Error at line: " << line_count << " Void Type within expression" << endl << endl;
			total_error++;
			
			$1->setTmpType("float");
		}
		
		argumentList.push_back($1->getTmpType());
		
		// new code for IR
		
		sendArguList.push_back($1->getSymbol());
		$$->setAcode($1->getAcode());
		delete $1;
	}
	;

	
%%


int main(int argc,char *argv[])
{
	if(argc != 2){
		cout << "give the file name" << endl;
		return 0;
	}

	FILE *fp = fopen(argv[1], "r");
	if(fp == NULL){
		cout << "file can't be opened. try later" << endl;
		return 0;
	}

	freopen("log.txt", "w+", stdout);
	ErrorFile = fopen("error.txt", "w+");
	
	if(ErrorFile == NULL){
		cout << "Error file can't be opened" << endl;
		return 0;
	}
	
	AssemblyFile = fopen("code.asm", "w+");
	if(AssemblyFile == NULL){
		cout << "ASM file can't be opened" << endl;
		return 0;
	}
	
	OptimizeAssemblyFile = fopen("optimized_code.asm", "w+");
	if(OptimizeAssemblyFile == NULL){
		cout << "optimized_code.asm file can't be opened" << endl;
		return 0;
	}

	for(int i = 0; i < 100; i++){
		isTaken[i] = 0;
	}

	yyin = fp;
	yyparse();

	
	
	table->printAllScopeTable();
	table->ExitScopeTable();
	
	cout << endl << endl;
	
	cout << "Total lines: " << line_count << endl;
	cout << "Total errors: " << total_error << endl << endl;
	fprintf(ErrorFile, "Total errors: %d\n", total_error);
	
	fclose(fp);
	
	return 0;
}
