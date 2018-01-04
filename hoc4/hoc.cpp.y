%{
#include <iostream>
#include <cctype>
#include <sstream>
#include <map>
#include <cmath>
using namespace std;
int yylex(), yyerror(const string &);

struct Symbol {
  string *name;
  short type; //VAR, BLTIN, UNDEF
  union {
    double val;  //VAR
    double (*fp)(double); //BLTIN
  };
};

struct Flist {
  string name;
  double (*fp)(double);
} flist [] = {{"sin", sin}, {"ln", log}, {"sqrt", sqrt}, {"arctg", atan}};

struct Clist {
  string name;
  double val;
} clist [] = {{"pi", 3.1415926536}, {"e", 2.7182818284}, {"phi", 1.6180339887}};

map<string, Symbol> names;
%}
%union {
  double val;
  Symbol *sym;  //a pointer to a record
}
%token <val> NUMBER //sets type for numbers
%token <sym> VAR BLTIN UNDEF
%type <val> expr assign //sets type for expressions and assignments
%right '='
%left '+' '-'
%left '*' '/'
%right '^'
%left UNARYMINUS
%%
list:  /* empty list */
| list '\n'
| list assign '\n'
| list expr '\n' {cout << $2 << endl;}
| list error {yyerrok;}
;
assign: VAR '=' expr {$$ = $1->val = $3; $1->type = VAR;}
;
expr: NUMBER
| VAR {
    if ($1->type == UNDEF)
        throw "undefined variable: " + *$1->name;
    $$ = $1->val;
  }
| assign
| BLTIN '(' expr ')' {$$ = (*($1->fp))($3);}
| expr '+' expr {$$ = $1 + $3;}
| expr '-' expr {$$ = $1 - $3;}
| expr '*' expr {$$ = $1 * $3;}
| expr '/' expr {$$ = $1 / $3;}
| expr '^' expr {$$ = pow($1, $3);}
| '-' expr %prec UNARYMINUS {$$ = -$2;}
| '(' expr ')' {$$ = $2;}
;
%%
int lineno = 1;

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
      cin >> yylval.val;
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
  cerr << s << " in " << lineno << endl;
}

main () {
  init_names(flist, clist);
  while (1) {
    try {
      yyparse();
      break;
    }
    catch (string s) {
      cerr << s << endl;
    }
    catch (...) {
      cerr << "unknown error\n";
    }
  }
}
