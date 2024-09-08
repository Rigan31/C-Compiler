#include<bits/stdc++.h>
#define ll long long int

using namespace std;


struct Parameter{
    string name;
    string type;
};


class SymbolInfo{
private:
    string Name;
    string Type;
    SymbolInfo * next;


    // for parser implementation
    // for function
    vector<Parameter> parameterList;

    // for array
    string tmpType;
    int tmpSize;
    
    //for assembly code
    string acode;
    string symbol;


public:
    SymbolInfo(){
        this->Name = "";
        this->Type = "";
        this->next = NULL;
    }
    SymbolInfo(string name, string type){
        this->Name = name;
        this->Type = type;
        this->next = NULL;

    }

    void SymbolPrint(){
    cout << "< " << Name << " : " << Type << "> ";
    }

    //------------------ getter------------------//
    string getName(){
        return Name;
    }
    string getType(){
        return Type;
    }
    Parameter getParameter(int n){
        return parameterList[n];
    }
    int getParameterSize(){
        return parameterList.size();
    }
    string getTmpType(){
        return tmpType;
    }
    int getTmpSize(){
        return tmpSize;
    }
    string getAcode(){
    	return acode;
    }
    string getSymbol(){
    	return symbol;
    }

    //-----------------------------------------------//


    //-------------------setter----------------------//

    void setName(string name){
        this->Name = name;
    }
    void setType(string type){
        this->Type = type;
    }
    void addParameter(string name, string type){
        Parameter tmp;
        tmp.name = name;
        tmp.type = type;

        parameterList.push_back(tmp);
    }
    void setTmpType(string type){
        tmpType = type;
    }
    void setTmpSize(int size){
        tmpSize = size; 
    }
    void setAcode(string s){
    	this->acode = s;
    }
    void setSymbol(string s){
    	this->symbol = s;
    }

    //-----------------------------------------------//

    ~SymbolInfo(){
        parameterList.clear();
    }
};



class ScopeTable{
private:
    int total_buckets;
    vector<SymbolInfo*> *table;
    ScopeTable *parentScope;
    int totalChild;
    string id;

public:
    ScopeTable(int n){
        total_buckets = n;
        table = new vector<SymbolInfo*>[total_buckets];
        parentScope = NULL;
        totalChild = 0;
        //cout << "New ScopeTable with id ";
    }

    ll HashFunction(string name){
        ll sum_of_ascii = 0;
        for(char c : name){
            sum_of_ascii += c;
        }

        return (sum_of_ascii%total_buckets);

    }

    bool insertIntoTable(string name, string type){
        SymbolInfo *tmp = lookUpIntoHash(name);
        if(tmp == NULL){
            SymbolInfo *newSymbol = new SymbolInfo(name, type);
            ll position = HashFunction(name);
            table[position].push_back(newSymbol);

            //cout << "Inserted in ScopeTable# " << id << " at position " << position << ", " << table[position].size()-1<< endl;
            return true;
        }
        else{
            //cout << name << " already exists in current ScopeTable" << endl;
            return false;
        }
    }
    
    bool insertIntoTableSymbol(SymbolInfo *symbol){
    	string name = symbol->getName();
    	SymbolInfo *tmp = lookUpIntoHash(name);
    	
    	if(tmp == NULL){
    		ll position = HashFunction(name);
    		table[position].push_back(symbol);
    		return true;
    	}
    	else{
    		return false;
    	}
    	
    }

    SymbolInfo * lookUpIntoHash(string name){
        ll position = HashFunction(name);
        for(int i = 0; i < table[position].size(); i++){
            SymbolInfo *v = table[position][i];
            if(v->getName() == name){
                //cout << "Found in ScopeTable# " << id << " at position " << position << ", " << i << endl;
                return v;
            }
        }
        return NULL;
    }

    bool DeleteFromTable(string name){
        ll position = HashFunction(name);
        vector<SymbolInfo*>::iterator it;
        int i = 0;

        for(auto it = table[position].begin(); it != table[position].end(); ++it){
            if(table[position][i]->getName() == name){
                cout << "Found in ScopeTable# " << id << " at position " << position << ", " << i << endl;
                table[position].erase(it);
                cout << "Deleted Entry " << position << ", " << i << " from current ScopeTable" << endl;
                return true;
            }
            i++;
        }

        cout << "Not Found" << endl;
        return false;
    }

    void printScopeTable(){
        cout << "ScopeTable # " << id << endl;
        for(int i = 0; i < total_buckets; i++){

            if(table[i].size() == 0 )
                continue;
            cout << " " <<  i << " --> ";
            for(SymbolInfo *v: table[i]){
                v->SymbolPrint();
            }
            cout << endl;
        }

    }

    string getId(){
        return id;
    }

    int getTotalChild(){
        return totalChild;
    }

    ScopeTable* getParentScope(){
        return parentScope;
    }

    void incTotalChild(){
        totalChild += 1;
    }

    void setParentScope(ScopeTable *t){
        parentScope = t;
    }

    void setId(int v){
        if(parentScope == NULL){
            id = to_string(v);
        }
        else{
            id = parentScope->getId()+"."+to_string(v);
        }

        //cout << id << " created" << endl;
    }

    ~ScopeTable() {
        delete[] table;
    }
};


class SymbolTable{
private:
    ScopeTable *currentScopetable;
    int total_buckets;
    int first_id;

public:
    SymbolTable(int buckets){
        total_buckets = buckets;
        first_id = 1;
        currentScopetable = new ScopeTable(total_buckets);
        currentScopetable->setId(first_id);
        first_id++;
    }

    void EnterScopeTable(){
        if(currentScopetable == NULL){
            currentScopetable = new ScopeTable(total_buckets);
            currentScopetable->setId(first_id);
            first_id++;
        }
        else{
            currentScopetable->incTotalChild();
            int id = currentScopetable->getTotalChild();
            ScopeTable *newScope = new ScopeTable(total_buckets);
            newScope->setParentScope(currentScopetable);
            newScope->setId(id);
            currentScopetable = newScope;
        }
    }

    void ExitScopeTable(){
        ScopeTable *newScope = currentScopetable;
        currentScopetable = currentScopetable->getParentScope();
        //cout << "ScopeTable with id " << newScope->getId() << " removed" << endl;
        delete newScope;
    }

    bool insertIntoTable(string name, string type){
        return currentScopetable->insertIntoTable(name, type);

    }
    
    bool insertIntoTableSymbol(SymbolInfo * symbol){
    	return currentScopetable->insertIntoTableSymbol(symbol);
    }

    bool removeFromTable(string name){
        return currentScopetable->DeleteFromTable(name);
    }

    SymbolInfo* lookUp(string name){
        ScopeTable *tmp = currentScopetable;
        while(tmp != NULL){
            SymbolInfo *symbol =  tmp->lookUpIntoHash(name);
            if(symbol == NULL){
                tmp = tmp->getParentScope();
            }
            else{
                return symbol;
            }
        }
        //cout << "Not Found" << endl;
        return NULL;
    }
    
    SymbolInfo *lookUpCurrentScope(string name){
    	ScopeTable *tmp = currentScopetable;
    	SymbolInfo *symbol =  tmp->lookUpIntoHash(name);
        return symbol;
    }

    void printCurrentScopeTable(){
        if(currentScopetable == NULL) return;
        currentScopetable->printScopeTable();
        return;
    }

    void printAllScopeTable(){
        ScopeTable *tmp = currentScopetable;
        while(tmp != NULL){
            tmp->printScopeTable();
            tmp = tmp->getParentScope();
            if(tmp != NULL) cout << endl;
        }
    }

    ~SymbolTable(){
        
    }
};

