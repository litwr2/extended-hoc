%option   noyywrap
number	  [0-9]+
%%
[ ]	  /* skip spaces */
{number}  {istringstream s(yytext); s >> yylval; return NUMBER;}
\n	  ++lineno; return '\n';
.	  return yytext[0];   //for lex . is any symbol but an end of line marker
