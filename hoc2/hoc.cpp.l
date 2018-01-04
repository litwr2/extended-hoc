%option   noyywrap
number	  [0-9]+\.?|[0-9]*\.[0-9]+
%%
[ ]	
{number}  {istringstream s(yytext); s >> yylval; return NUMBER;}
\n	  ++lineno; return '\n';
.         return yytext[0];
