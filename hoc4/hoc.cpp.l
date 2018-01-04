%option    noyywrap
number	   [0-9]+\.?|[0-9]*\.[0-9]+
symbol     [a-zA-Z][a-zA-Z0-9]*
%%
[ ]	
{number}   {istringstream is(yytext); is >> yylval.val; return NUMBER;}
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
\n	   ++lineno; return '\n';
.          return yytext[0];
