#include <iostream>
#include <string>
#include <cmath>
using namespace std;
struct Symbol {
  string *name;
  short type; //VAR, BLTIN, UNDEF, NUMBER, FUNCCALL, PROCCALL
  union {
    double val;  //VAR, NUMBER
    double (*fp)(double); //BLTIN
    void (*deffn)(); //FUNCDEF, PROCDEF
  };
};
int yylex(), yyparse(), yyerror(const string &);

union Datum { //type for the interpreter stack
  double val;
  Symbol *sym;
};

typedef void (*Inst)();
#define STOP 0
extern Inst prog[], *progp, *progbase;
extern int indef;

Datum pop();
Inst* code(Inst);
void initcode(), push(Datum), pop_code(), execute(Inst*), constpush(),
  varpush(), add(), sub(), mul(), div(), power(), negate_code(), bltin(),
  assign_code(), eval(), print(), gt(), ge(), lt(), le(), eq(), ne(),
  and_code(), or_code(), not_code(), while_code(), if_code(), prexpr(),
  defonly(const string&), define(Symbol*), call(), procret(), funcret(),
  arg(), argassign(), prstr(), varread();

void disassm(Inst*, Inst, char);
