%option    noyywrap
number	   [0-9]+\.?|[0-9]*\.[0-9]+
symbol     [a-zA-Z][a-zA-Z0-9]*
%%
[ ]	
>= 	   return GE;
\<= 	   return LE;
== 	   return EQ;
!= 	   return NE;
> 	   return GT;
\< 	   return LT;
\|\|	   return OR;
&&         return AND;
!          return NOT;
{number}   {
              istringstream iss(yytext);
              double w;
              iss >> w;
              string s(yytext);
              if (names.find(s) == names.end()) {
                names[s].type = NUMBER;
                names[s].name = &(string&)names.find(s)->first;
                names[s].val = w;
              }
              yylval.sym = &names[s];
              return NUMBER;
           }
{symbol}   {
              string sbuf(yytext);
              if (names.find(sbuf) == names.end()) {
                names[sbuf].type = UNDEF;
                names[sbuf].name = &(string&)names.find(sbuf)->first;
              }
              Symbol *s = &names[sbuf];
              yylval.sym = s;
              return s->type == UNDEF ? VAR : s->type;
           }
\n         ++lineno; return '\n';
.          return yytext[0];
