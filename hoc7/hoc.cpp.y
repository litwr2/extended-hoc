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
  Inst *inst;   //pointer to a command
  long narg; //number of a subroutine arguments (must be long (long long, int64_t, ...) for x86_64)
}
%token <sym> VAR BLTIN UNDEF NUMBER PRINT WHILE IF ELSE
%token <sym> STRING FUNCCALL PROCCALL RETURN FUNCDEF PROCDEF READ
%token <narg> ARG
%type <inst> assign expr oper operlist while if cond endop
%type <inst> prlist begin
%type <sym> subrname
%type <narg> arglist
%right '='
%left OR
%left AND
%left GT GE LT LE EQ NE
%left '+' '-'
%left '*' '/'
%right '^'
%left NOT
%%
list:
| list '\n'
| list assign '\n' {code2(pop_code, STOP); return 1;}
| list expr '\n' {code2(print, STOP); return 1;}
| list oper '\n' {code(STOP); return 1;}
| list deffn '\n'
;
assign: VAR '=' expr {$$ = $3; code3(varpush, (Inst) $1, assign_code);}
| ARG '=' expr {defonly("$"); code2(argassign, (Inst) $1); $$ = $3;}
;
oper: expr {code(pop_code);}
| PRINT prlist {$$ = $2;}
| while cond oper endop {
    ($1)[1] = (Inst) $3;
    ($1)[2] = (Inst) $4;}
| if cond oper endop {
    ($1)[1] = (Inst) $3;
    ($1)[3] = (Inst) $4;}
| if cond oper endop ELSE oper endop {
    ($1)[1] = (Inst) $3;
    ($1)[2] = (Inst) $6;
    ($1)[3] = (Inst) $7;}
| '{' operlist '}' {$$ = $2;}
| RETURN {defonly("return"); code(procret);}
| RETURN expr {defonly("return"); code(funcret); $$ = $2;}
| PROCCALL begin '(' arglist ')' {
    $$ = $2;
    code3(call, (Inst) $1, (Inst) $4);}
;
cond: '(' expr ')' {code(STOP); $$ = $2;}
;
while: WHILE {$$ = code3(while_code, STOP, STOP);}
;
if: IF {$$ = code(if_code); code3(STOP, STOP, STOP);}
;
endop: {code(STOP); $$ = progp;}
;
operlist: {$$ = progp;}
| operlist '\n'
| operlist oper
;
begin: {$$ = progp;}
;
prlist: expr {code(prexpr);}
| STRING {$$ = code2(prstr, (Inst) $1);}
| prlist ',' expr {code(prexpr);}
| prlist ',' STRING {code2(prstr, (Inst) $3);}
;
deffn: FUNCDEF subrname {$2->type = FUNCCALL; indef = 1;}
  '(' ')' oper {code(funcret); define($2); indef = 0;}
| PROCDEF subrname {$2->type = PROCCALL; indef = 1;}
   '(' ')' oper {code(procret); define($2); indef = 0;}
;
subrname: VAR
| FUNCCALL
| PROCCALL
;
arglist: {$$ = 0;}
| expr {$$ = 1;}
| arglist ',' expr {$$ = $1 + 1;}
;
expr: NUMBER {$$ = code2(constpush, (Inst) $1);}
| VAR {$$ = code3(varpush, (Inst) $1, eval);}
| assign
| BLTIN '(' expr ')' {$$ = $3; code2(bltin, (Inst)$1->fp);}
| expr '+' expr {code(add);}
| expr '-' expr {code(sub);}
| expr '*' expr {code(mul);}
| expr '/' expr {code(div);}
| expr '^' expr {code(power);}
| '-' expr %prec NOT {$$ = $2; code(negate_code);}
| '(' expr ')' {$$ = $2;}
| expr GT expr {code(gt);}
| expr GE expr {code(ge);}
| expr LT expr {code(lt);}
| expr LE expr {code(le);}
| expr EQ expr {code(eq);}
| expr NE expr {code(ne);}
| expr AND expr {code(and_code);}
| expr OR expr {code(or_code);}
| NOT expr {$$ = $2; code(not_code);}
| ARG {defonly("$"); $$ = code2(arg, (Inst) $1);}
| FUNCCALL begin '(' arglist ')' {
    $$ = $2;
    code3(call, (Inst) $1, (Inst) $4);}
| READ '(' VAR ')' {$$ = code2(varread, (Inst) $3);}
;
%%
int lineno = 1, indef;

struct Flist {
  string name;
  double (*fp)(double);
} flist[] = {{"sin", sin}, {"ln", log}, {"sqrt", sqrt}, {"arctg", atan}};

struct Clist {
  string name;
  double val;
} clist[] = {{"pi", 3.1415926536}, {"e", 2.7182818284}, {"phi", 1.6180339887}};

struct Klist {
  string name;
  int kval;
} klist[] = {{"if", IF}, {"else", ELSE}, {"while", WHILE}, {"print", PRINT},
  {"func", FUNCDEF}, {"proc", PROCDEF}, {"return", RETURN}, {"read", READ}};

map<string, Symbol> names;

void init_names(Flist *p1, Clist *p2, Klist *p3) {
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
   for (; p3 < klist + sizeof(klist)/sizeof(Klist); ++p3) {
      names[p3->name].name = &p3->name;
      names[p3->name].type = p3->kval;
    }
}

#ifdef LEX
#include "lex.yy.c"
#else
int backslash(int c) {
  static string transtab = "b\bf\fn\nr\rt\t"; //the word static is used for the acceleration
  if (c != '\\')
    return c;
  c = cin.get();
  if (transtab.find(c) != string::npos)
    return transtab[transtab.find(c) + 1];
  return c;
}

int follow(int expect, int ifyes, int ifno) {
  int c = cin.get();
  if (c == expect)
    return ifyes;
  cin.unget();
  return ifno;
}

int yylex () {
  int c;
  while ((c = cin.get()) == ' ' || c == '\t');
  if (c == '$') {
    int n = 0;
    while (isdigit(c = cin.get()))
      n = n*10 + c - '0';
    cin.unget();
    if (n == 0)
      throw (string) "strange $...";
    yylval.narg = n;
    return ARG;
  }
  if (c == '"') { //a quoted text string
    char sbuf[100], *p;
    for (p = sbuf; (c = cin.get()) != '"'; p++) {
      if (c == '\n')
        throw (string) "missing quote";
      if (p > sbuf + sizeof(sbuf)) {
        *p = 0;
        throw "string too long " + string(sbuf);
      }
      *p = backslash(c);
    }
    *p = 0;
    yylval.sym = new Symbol;
    yylval.sym->name = new string(sbuf);
    return yylval.sym->type = STRING;
  }
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
  switch (c) {
    case '>': return follow('=', GE, GT);
    case '<': return follow('=', LE, LT);
    case '!': return follow('=', NE, NOT);
    case '=': return follow(c, EQ, c);
    case '|': return follow(c, OR, c);
    case '&': return follow(c, AND, c);
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

map<void (*)(),string> dinfo;
struct DBIR { //debugger data
  string s;
  void (*fp)();
} dia[] = {{"pop_code", pop_code},{"constpush", constpush},{"varpush", varpush},{"add", add},
{"sub", sub},{"mul", mul},{"div", div},{"power", power},{"negate_code", negate_code},
{"bltin", bltin},{"assign_code", assign_code},{"eval", eval},{"print", print},
{"gt", gt},{"ge", ge},{"lt", lt},{"le", le},{"eq", eq},{"ne", ne},{"and_code", and_code},
{"or_code", or_code},{"not_code", not_code},{"while_code", while_code},{"if_code", if_code},
{"prexpr", prexpr},{"call", call},{"procret", procret},{"funcret", funcret},
{"arg", arg},{"argassign", argassign},{"prstr", prstr},{"varread", varread}};

void initdisassm() {
  for (DBIR *pdi = dia; pdi < dia + sizeof(dia)/sizeof(DBIR); pdi++)
    dinfo[pdi->fp] = pdi->s;
  for (Flist *pfl = flist; pfl < flist + sizeof(flist)/sizeof(Flist); ++pfl)
    dinfo[(void (*)())pfl->fp] = pfl->name;
  for (long i = 0; i < 34; i++)
    dinfo[(void (*)())i] = char(i + '0');
}

void disassm(Inst* pc, Inst f, char c) {
  Symbol *p = (Symbol *) f;
  cout << pc - prog << c << ": ";
  if (dinfo.find(f) != dinfo.end())
    cout << dinfo[f];
  else if (p->type == NUMBER)
    cout << p->val;
  else if (p->type ==  VAR || p->type == UNDEF)
    cout << *p->name;
  else if (p->type == STRING)
    cout << '"' << *p->name << '"';
  cout << endl;
}

main () {
  initdisassm();
  init_names(flist, clist, klist);
  cout.precision(2);
  while (1) {
    try {
      for (initcode();yyparse();initcode())
        execute(progbase);
      break;
    }
    catch (string s) {
      cerr << s << endl;
    }
  }
}
