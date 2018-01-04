%{
#include <cctype>
#include <sstream>
#include <map>
#include "hoc.h"
#define code2(c1,c2) code(c1);code(c2)
#define code3(c1,c2,c3) code(c1);code(c2);code(c3)
%}
%union {
  Symbol *sym;  //pointer to a record
  Inst *inst;   //pointer to a command
}
%token <sym> VAR BLTIN UNDEF NUMBER PRINT WHILE IF ELSE
%type <inst> assign expr oper operlist while if cond endop
%right '='
%left OR
%left AND
%left GT GE LT LE EQ NE  //> >= < <= == !=
%left '+' '-'
%left '*' '/'
%right '^'
%left NOT
%%
list:
| list '\n'
| list assign '\n' {code2(pop_code, STOP); return 1;}
| list expr '\n' {code2(print, STOP); return 1;}
| list oper '\n' {code(STOP); return 1;}
;
assign: VAR '=' expr {$$ = $3; code3(varpush, (Inst) $1, assign_code);}
;
oper: expr {code(pop_code);} //$$=$1 by default
| PRINT expr {code(prexpr); $$ = $2;}
| while cond oper endop {
    ($1)[1] = (Inst) $3; //go to a loop body
    ($1)[2] = (Inst) $4;} //exit from a loop
| if cond oper endop { //if without else
    ($1)[1] = (Inst) $3; //go to then-part
    ($1)[3] = (Inst) $4;} //exit from a conditional
| if cond oper endop ELSE oper endop { //if with else
    ($1)[1] = (Inst) $3;
    ($1)[2] = (Inst) $6; //go to else-part
    ($1)[3] = (Inst) $7;}
| '{' operlist '}' {$$ = $2;}
;
cond: '(' expr ')' {code(STOP); $$ = $2;}
;
while: WHILE {$$ = code3(while_code, STOP, STOP);} //reserves a place for 2 goto-labels
;
if: IF {$$ = code(if_code); code3(STOP, STOP, STOP);}
;
endop: {code(STOP); $$ = progp;}
;
operlist: {$$ = progp;}
| operlist '\n'
| operlist oper
;
expr: NUMBER {$$ = code2(constpush, (Inst) $1);}
| VAR {$$ = code3(varpush, (Inst) $1, eval);}
| assign
| BLTIN '(' expr ')' {$$ = $3; code2(bltin, (Inst)$1->fp);}
| expr '+' expr {code(add);}
| expr '-' expr {code(sub);}
| expr '*' expr {code(mul);}
| expr '/' expr {code(div);}
| expr '^' expr {code(power);}
| '-' expr %prec NOT {$$ = $2; code(negate_code);}
| '(' expr ')' {$$ = $2;}
| expr GT expr {code(gt);}
| expr GE expr {code(ge);}
| expr LT expr {code(lt);}
| expr LE expr {code(le);}
| expr EQ expr {code(eq);}
| expr NE expr {code(ne);}
| expr AND expr {code(and_code);}
| expr OR expr {code(or_code);}
| NOT expr {$$ = $2; code(not_code);}
;
%%
int lineno = 1;

struct Flist {
  string name;
  double (*fp)(double);
} flist [] = {{"sin", sin}, {"ln", log}, {"sqrt", sqrt}, {"arctg", atan}};

struct Clist {
  string name;
  double val;
} clist [] = {{"pi", 3.1415926536}, {"e", 2.7182818284}, {"phi", 1.6180339887}};

struct Klist {
  string name;
  int kval;
} klist [] = {{"if", IF}, {"else", ELSE}, {"while", WHILE}, {"print", PRINT}};

map<string, Symbol> names;

void init_names(Flist *p1, Clist *p2, Klist *p3) {
    for (; p1 < flist + sizeof(flist)/sizeof(Flist); ++p1) {
      names[p1->name].name = &p1->name;
      names[p1->name].type = BLTIN;
      names[p1->name].fp = p1->fp;
    }
    for (; p2 < clist + sizeof(clist)/sizeof(Clist); ++p2) {
      names[p2->name].name = &p2->name;
      names[p2->name].type = VAR;
      names[p2->name].val = p2->val;
    }
   for (; p3 < klist + sizeof(klist)/sizeof(Klist); ++p3) {
      names[p3->name].name = &p3->name;
      names[p3->name].type = p3->kval;
    }
}

#ifdef LEX
#include "lex.yy.c"
#else
int follow(int expect, int ifyes, int ifno) {
  int c = cin.get();
  if (c == expect)
    return ifyes;
  cin.unget();
  return ifno;
}

int yylex () {
  int c;
  while ((c = cin.get()) == ' ' || c == '\t');
  if (c == '.' || isdigit(c)) {
      cin.unget();
      double w;
      cin >> w;
      ostringstream oss;
      oss << w;
      string s(oss.str());
      if (names.find(s) == names.end()) {
        names[s].type = NUMBER;
        names[s].name = &(string&)names.find(s)->first;
        names[s].val = w;
      }
      yylval.sym = &names[s];
      return NUMBER;
  }
  if (isalpha(c)) {
      char sbuf[100], *p = sbuf;
      do {
        *p++ = c;
        c = cin.get();
      }
      while (!cin.eof() && isalnum(c));
      cin.unget();
      *p = 0;
      if (names.find(sbuf) == names.end()) {
        names[sbuf].type = UNDEF;
        names[sbuf].name = &(string&)names.find(sbuf)->first;
      }
      Symbol *s = &names[sbuf];
      yylval.sym = s;
      return s->type == UNDEF ? VAR : s->type;
  }
  switch (c) {
    case '>': return follow('=', GE, GT);
    case '<': return follow('=', LE, LT);
    case '!': return follow('=', NE, NOT);
    case '=': return follow(c, EQ, c);
    case '|': return follow(c, OR, c);
    case '&': return follow(c, AND, c);
  }
  if (c == '\n')
      lineno++;
  return c;
}
#endif

int yyerror(const string &s) {
   ostringstream oss;
   oss << s << " in " << lineno << endl;
   throw oss.str();
}

main () {
  init_names(flist, clist, klist);
  while (1) {
    try {
      for (initcode();yyparse();initcode())
        execute(prog);
      break;
    }
    catch (string s) {
      cerr << s << endl;
    }
  }
}
