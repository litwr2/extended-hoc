%option    noyywrap
number     [0-9]+\.?|[0-9]*\.[0-9]+
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
\+=	   return AADD;
-=	   return ASUB;
\*=	   return AMUL;
\/=	   return ADIV;
\^=	   return APOW;
\+\+       return INC;
--         return DEC;
\$[0-9]+   {
              istringstream iss(yytext + 1);
              int n;
              iss >> n;
              if (n == 0)
                throw (string) "strange $...";
              yylval.narg = n;
              return ARG;
           }
\"[^"]*\"     {
              string istr(yytext + 1), so("\b\n\r\t\f"), si[] = {"\\b", "\\n", "\\r", "\\t", "\\f"};
              istr.erase(istr.length() - 1);
              int i, p;
              for (i = 0; i < so.length(); i++)
                 while ((p = istr.find(si[i])) != string::npos)
                    istr.replace(p, 2, so.substr(i, 1));
              yylval.sym = new Symbol;
              yylval.sym->name = new string(istr);
              return yylval.sym->type = STRING;
           }
{number}   {
              istringstream iss(yytext);
              double w;
              string s(yytext);
              iss >> w;
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
              if (inauto) {
                names[defname + "@"].type = names[defname + "@" + sbuf].type = inauto++;
                return VAR;
              }
              if (indef && names.find(defname + "@" + sbuf) != names.end()) {
                yylval.narg = -names[defname + "@" + sbuf].type;
                return ARG;
              }
              string xbuf(sbuf);
              if (indef) xbuf = defname + ":" + xbuf;
              if (instatic)
                names[xbuf].type = VAR;
              else if (names.find(xbuf) == names.end()) {
                xbuf = sbuf;
                if (names.find(xbuf) == names.end())
                  names[xbuf].type = UNDEF;
              }
              names[xbuf].name = &(string&)names.find(xbuf)->first;
              Symbol *s = &names[xbuf];
              yylval.sym = s;
              return s->type == UNDEF ? VAR : s->type;
           }
#.*\n|\n   ++lineno; return '\n';
.          return yytext[0];
