%{
#include <iostream>
#include <cctype>
#include <sstream>
using namespace std;

int yylex(), yyerror(const string&);
int lineno = 1;
%}
%token NUMBER
%left '+' '-'
%left '*' '/'              //higher priority than '+' and '-'
%left UNARYMINUS
%right '^'
%%
list:
| list '\n'
| list expr '\n' {cout << $2 << endl;}
;
expr: NUMBER
| expr '+' expr {$$ = $1 + $3;}
| expr '-' expr {$$ = $1 - $3;}
| expr '*' expr {$$ = $1 * $3;}
| expr '/' expr {$$ = $1 / $3;}
| expr '^' expr {$$ = 1; for (int i = 0; i < $3; i++) $$ *= $1;}
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
  if (isdigit(c)) {
       cin.unget();
       cin >> yylval;
       return NUMBER;
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
