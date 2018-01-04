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
  Inst *inst;   //pointer to a command of the stack code
}
%token <sym> VAR BLTIN UNDEF NUMBER
%right '='
%left '+' '-'
%left UNARYMINUS
%left '*' '/'
%right '^'
%%
list:  /* empty list */
| list '\n'
| list assign '\n' {code2(pop_code, STOP); return 1;}
| list expr '\n' {code2(print, STOP); return 1;}
;
assign: VAR '=' expr {code3(varpush, (Inst) $1, assign_code);}
;
expr: NUMBER {code2(constpush, (Inst) $1);}
| VAR {code3(varpush, (Inst) $1, eval);}
| assign
| BLTIN '(' expr ')' {code2(bltin, (Inst)$1->fp);}
| expr '+' expr {code(add);}
| expr '-' expr {code(sub);}
| expr '*' expr {code(mul);}
| expr '/' expr {code(div);}
| expr '^' expr {code(power);}
| '-' expr %prec UNARYMINUS {code(negate_code);}
| '(' expr ')'
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

map<string, Symbol> names;

void init_names(Flist *p1, Clist *p2) {
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
}

#ifdef LEX
#include "lex.yy.c"
#else
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
  init_names(flist, clist);
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
