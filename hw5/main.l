%option noyywrap
%{
    #include"common.h"
    #include"main.tab.hh"
    #include <stack>
    #include <vector>
    using namespace std;
    //Ϊ��ʵ�������򣬱���洢������Ľṹ�����ĸ�zone�����ĸ�zone 
    //zoneջ��Ϊ���Ҹ��ڵ��� 
    stack<int>zone_stack;

    //��ʶ�����������ƺͷ��ű��е�ָ��
    struct identifier{
    	string name;
    	int no; //������ı��
        identifier(){}
        identifier(string n,int num){
            name=n;
            no=num;
        }
	};

    //�ṹ��z��zone��ÿ��zone����һ��id�б���һ�����ڵ�ֵ
    struct z{
        vector<identifier>id_list;
        int father;
        z(){
            father=-1;
        }
    }zone[20];

    //��p�ڵ��������Ƿ�ǰ�涨�����ʶ��id
    int find_zone(int p,string id){
	    int i;
        while(p>=0){
        	for(i=0;i<zone[p].id_list.size();++i){
        		if(zone[p].id_list[i].name==id){
        			return p; 
				}
        	}
        	p=zone[p].father;
		}
		return -1;
	}
    void printer(string a,string b){
        cout<<setw(8)<<a<<setw(8)<<b<<endl;
    }
    void printer(string a,string b,int c){
        cout<<setw(8)<<a<<setw(8)<<b<<setw(8)<<c<<endl;
    }
    //int id_cnt=0;//id��
    int zone_cnt=0;//zone���� 
    int zone_now=0;//��ǰ������ 
    int zone_switch_flag=0;//�Ƿ���Ҫ�л�������һ��idǰ����û��int �� 
    bool init_stack=false;
    bool for_flag=false;//for�Ļ����Ų�Ӱ����������һ������
%}
BLOCKCOMMENT \/\*([^\*^\/]*|[\*^\/*]*|[^\**\/]*)*\*\/
LINECOMMENT \/\/[^\n]*

INTEGER [0-9]+
ID [[:alpha:]_][[:alpha:][:digit:]_]*
CHAR \'.?\'
STRING \".+\"
EOL (\r\n|\n)
WHITE [\t ]
%%
{BLOCKCOMMENT} {cout<<"COMMENT:"<<yytext<<endl;} /* do nothing */
{LINECOMMENT}  {cout<<"COMMENT:"<<yytext<<endl;}/* do nothing */

"true" {
    TreeNode *node = new TreeNode(NODE_BOOL);
    node->bool_val = true;
    yylval = node;
    return TRUE;
}
"false" {
    TreeNode *node = new TreeNode(NODE_BOOL);
    node->bool_val = false;
    yylval = node;
    return FALSE;
}

"int" {
    if(init_stack==false){//��ʼ��ջ
        zone_stack.push(0);
        init_stack=true;
    }
    zone_switch_flag=1;//�¶����˱���
    return INT;
}
"void" {
    if(init_stack==false){
        zone_stack.push(0);
        init_stack=true;
    }
    zone_switch_flag=1;
    return VOID;
}
"char" {
    if(init_stack==false){
        zone_stack.push(0);
        init_stack=true;
    }
    zone_switch_flag=1;
    return CHAR;
}

"if" return IF;
"while" return WHILE;
"else" return ELSE;
"for" {//ע��for���涨���i������仯
    for_flag=true;
    zone_cnt++;     //����������++
    zone[zone_cnt].father=zone_now;     //���ø��ڵ�
    zone_now=zone_cnt;      //������for����ǰ�������Ȼ���µ�������
    zone_stack.push(zone_now);
    return FOR;
}
"return" return RETURN;

"printf" return PRINTF;
"scanf" return SCANF;

"==" return EQUAL;
"=" return ASSIGN;

"+" return ADD;
"-" return SUB;
"*" return MUL;
"/" return DIV;
"%" return MOD;
">" return LARGER;
"<" return SMALLER;
">=" return LARGER_EQUAL;
"<=" return SMALLER_EQUAL;
"!=" return NOT_EQUAL;
"&&" return AND;
"||" return OR;
"+=" return ADD_SELF;
"-=" return SUB_SELF;
"++" return ADD_ONE;
"--" return SUB_ONE;

"!" return NOT;

"&" return GET_ADDR;//ȡ��ַ

"\"" return QUOTA;
"," return COMMA;
";" {
    zone_switch_flag=0;
    return SEMICOLON;
}
"(" return LPAREN;
")" return RPAREN;
"{" {
    if(for_flag==true){//�����for���棬�����򲻱�
        return LBRACE;
    }
    zone_cnt++;     //����������++
    zone[zone_cnt].father=zone_now;     //���ø��ڵ�
    zone_now=zone_cnt;      //�����������ţ���ǰ�������Ȼ���µ�������
    zone_stack.push(zone_now);
    return LBRACE;
}
"}" {
    if(for_flag==true){
        for_flag=false;//����for��������
    }
    zone_stack.pop();//���������ţ��ʹ�ջ��pop��һ��zone
    zone_now=zone_stack.top();
    return RBRACE;
}

{STRING} {
    TreeNode *node = new TreeNode(NODE_STRING);
    node->string_val = yytext;
    yylval = node;
    printer("STRING",yytext);
    return STRING;
}

{INTEGER} {
    TreeNode *node = new TreeNode(NODE_CONST);
    node->int_val = atoi(yytext);
    yylval = node;
    printer("INT",yytext);
    return INTEGER;
}
{CHAR} {
    TreeNode* node = new TreeNode(NODE_CHAR);
    node->char_val = yytext[1];
    yylval = node;
    printer("INT",yytext);
    return CHAR;
}
{ID} {
    TreeNode *node = new TreeNode(NODE_VAR);
    node->var_name = string(yytext);
    yylval = node;

    if(zone_switch_flag==1){//���ǰ����int���൱���µ�id
        int i;
        for(i=0;i<zone[zone_now].id_list.size();++i){
            //�����ǰ���������Ѿ����������ô����
            if(zone[zone_now].id_list[i].name==yytext){
                cout<<"error,'"<<yytext<<"' has been declared in this zone"<<endl;
                break;
            }
        }
        if(i==zone[zone_now].id_list.size()){//���û��������ɹ�������id
            zone[zone_now].id_list.push_back(identifier(yytext,zone_now));
            printer("ID",yytext,zone_now);

            node->zone=zone_now;
            //id_cnt++;
        }
    }
    else{//���ǰ��û��int���������ǲ��Ƕ����id
        int p=zone_now;
        int find_zone_result=find_zone(p,yytext);
        if(find_zone_result==-1){//����Ҳ�����δ����error 
            cout<<"error,'"<<yytext<<"' has not been declared"<<endl;
        }
        else{//�ҵ�����ȷ�������� 
            p=find_zone_result;
            for(int i=0;i<zone[p].id_list.size();++i){
                if(zone[p].id_list[i].name==yytext){
                    printer("ID",yytext,zone[p].id_list[i].no);

                    node->zone=zone[p].id_list[i].no;
                    break;
                }
            }
        } 
    }
    return ID;
}
{EOL}
{WHITE}


%%
