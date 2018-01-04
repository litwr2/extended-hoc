%option    noyywrap
number	   [0-9]+\.?|[0-9]*\.[0-9]+
variable   [a-z]
%%
[ ]	
{number}   {istringstream s(yytext); s >> yylval.val; return NUMBER;}
{variable} yylval.index = yytext[0] - 'a'; return VAR;
\n	   ++lineno; return '\n';
.          return yytext[0];
