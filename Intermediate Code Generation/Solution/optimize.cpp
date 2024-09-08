#include<bits/stdc++.h>

using namespace std;


class Optimize{
private:
	string optimizeCode;
public:	
	Optimize(){
		optimizeCode = "";
	}
	
	void optimizeAssemblyCode(string code){
		vector<string> linesOfCode;
		string answer = "";
		string tmp = "";
		for(int i = 0; i < code.size(); i++){
			if(code[i] == '\n'){
				linesOfCode.push_back(tmp);
				tmp = "";
			}
			else{
				tmp += code[i];
			}
		}
		
		int totalLine = linesOfCode.size();
		for(int i =0; i < totalLine; i++){
			if(i == totalLine-1){
				answer += linesOfCode[i] + "\n";
			}
			else if(linesOfCode[i].size() < 4 || linesOfCode[i+1].size() < 4){
				answer += linesOfCode[i] + "\n";
			}
			else if(linesOfCode[i].substr(1,3) == "MOV" && linesOfCode[i+1].substr(1,3) == "MOV"){
				stringstream s1(linesOfCode[i]);
				stringstream s2(linesOfCode[i+1]);
				
				vector<string> t1, t2;
				while(getline(s1, tmp, ' ')){
					t1.push_back(tmp);
				}
				
				while(getline(s2, tmp, ' ')){
					t2.push_back(tmp);
				}
				if((t1[1].substr(0, t1[1].length()-1) == t2[2]) && (t1[2] == t2[1].substr(0, t2[1].length()-1))){
					answer += linesOfCode[i] + "\n";
					i++;
				}
				else{
					answer += linesOfCode[i] + "\n";
				}
			}
			else{
				answer += linesOfCode[i] + "\n";
			}
		}
		
		optimizeCode = answer;
	}
	
	string getOptimizeCode(){
		return optimizeCode;
	}
	
	
};
