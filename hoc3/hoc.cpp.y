%{
#include <iostream>
#include <cctype>
#include <sstream>
#include <cmath>
using namespace std;

int yylex(), yyerror(const string&);
int lineno = 1;
double vars[26];
%}
%union {
  double val; //value
  int index;  //index of a variable in vars array
}
%token <val> NUMBER //a typed token
%token <index> VAR
%type <val> expr //sets type for expressions
%right '='    //assignment, it has the lowest priority
%left '+' '-'
%left '*' '/'
%right '^'
%left UNARYMINUS
%%
list:
| list '\n'
| list expr '\n' {cout << $2 << endl;}
| list error {yyerrok;}
;
expr: NUMBER
| VAR {$$ = vars[$1];}
| VAR '=' expr {$$ = vars[$1] = $3;}
| expr '+' expr {$$ = $1 + $3;}
| expr '-' expr {$$ = $1 - $3;}
| expr '*' expr {$$ = $1 * $3;}
| expr '/' expr {$$ = $1 / $3;}
| expr '^' expr {$$ = pow($1, $3);}
| '-' expr %prec UNARYMINUS {$$ = -$2;}
| '(' expr ')' {$$ = $2;}
;
%%
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
  if (islower(c)) {
      yylval.index = c - 'a';
      return VAR;
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
  yyparse();
}
