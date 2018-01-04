#include <iostream>
#include <string>
#include <sstream>
#include <cmath>
#include <map>
using namespace std;
struct Symbol {
  string *name;
  short type; //VAR, BLTIN, UNDEF, NUMBER
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
extern int indef, inloop;

Datum pop();
Inst* code(Inst);
void initcode(), push(Datum), pop_code(), execute(Inst*), constpush(),
  add(), sub(), mul(), div(), power(), negate_code(), bltin(),
  assign_code(), eval(), print(), gt(), ge(), lt(), le(), eq(), ne(),
  andif(), orif(), not_code(), while_code(), if_code(), prexpr(),
  defonly(const string&), define(Symbol*), call(), procret(), funcret(),
  arg(), argassign(), prstr(), varread(), for_code(), looponly(const string&),
  break_code(), continue_code(), assign_plus(), assign_minus(), assign_mul(),
  assign_div(), assign_pow(), argassign_plus(), argassign_minus(),
  argassign_mul(), argassign_div(), argassign_pow(), assign_inc(), assign_dec(),
  inc_assign(), dec_assign(), inc_arg(), dec_arg(), arg_inc(), arg_dec(),
  push_idx(), delete_code();

extern map<string, Symbol> names; //the symbol table

void disassm(Inst*, Inst, char);