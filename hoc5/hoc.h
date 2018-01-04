#include <iostream>
#include <string>
#include <cmath>
using namespace std;
struct Symbol {
  string *name;
  short type; //VAR, BLTIN, UNDEF, NUMBER
  union {
    double val;  //VAR, NUMBER
    double (*fp)(double); //BLTIN
  };
};
int yylex(), yyparse(), yyerror(const string &);

union Datum { //type for the interpreter stack
  double val;
  Symbol *sym;
};

typedef void (*Inst)();
#define STOP 0
extern Inst prog[];

Datum pop();
Inst* code(Inst);
void initcode(), push(Datum), pop_code(), execute(Inst*), constpush(),
  varpush(), add(), sub(), mul(), div(), power(), negate_code(), bltin(),
  assign_code(), eval(), print();
