%{
#include <cctype>
#include "hoc.h"
#define code2(c1,c2) code(c1);code(c2)
#define code3(c1,c2,c3) code(c1);code(c2);code(c3)
#define code4(c1,c2,c3,c4) code(c1);code(c2);code(c3);code(c4)
int lineno = 1, indef, inloop, instatic, inauto;
string defname;
%}
%union {
  Symbol *sym;
  Inst *inst;
  long narg;  //must be long (long long, int64_t, ...) for x86_64
}
%token <sym> VAR BLTIN UNDEF NUMBER ARRAY PRINT WHILE IF ELSE DO FOR
%token <sym> STRING FUNCCALL PROCCALL RETURN FUNCDEF PROCDEF READ
%token <sym> BREAK CONTINUE STATIC DELETE AUTO
%token <narg> ARG
%type <inst> assign expr oper operlist while if cond endop
%type <inst> prlist begin var andif orif
%type <sym> subrname varlist
%type <narg> arglist idxlist
%right '=' AADD ASUB AMUL ADIV APOW
%left OR
%left AND
%left GT GE LT LE EQ NE
%left '+' '-'
%left '*' '/'
%right '^'
%left INC DEC NOT
%%
list:
| list '\n'
| list assign '\n' {code2(pop_code, STOP); return 1;}
| list expr '\n' {code2(print, STOP); return 1;}
| list oper '\n' {code(STOP); return 1;}
| list deffn '\n'
;
assign: var '=' expr {code(assign_code);}
| var AADD expr {code(assign_plus);}
| var ASUB expr {code(assign_minus);}
| var AMUL expr {code(assign_mul);}
| var ADIV expr {code(assign_div);}
| var APOW expr {code(assign_pow);}
| INC var {$$ = $2; code(inc_assign);}
| DEC var {$$ = $2; code(dec_assign);}
| var INC {code(assign_inc);}
| var DEC {code(assign_dec);}
| ARG '=' expr {defonly("$"); code2(argassign, (Inst) $1); $$ = $3;}
| ARG AADD expr {defonly("$"); code2(argassign_plus, (Inst) $1); $$ = $3;}
| ARG ASUB expr {defonly("$"); code2(argassign_minus, (Inst) $1); $$ = $3;}
| ARG AMUL expr {defonly("$"); code2(argassign_mul, (Inst) $1); $$ = $3;}
| ARG ADIV expr {defonly("$"); code2(argassign_div, (Inst) $1); $$ = $3;}
| ARG APOW expr {defonly("$"); code2(argassign_pow, (Inst) $1); $$ = $3;}
| INC ARG {defonly("$"); $$ = code2(inc_arg, (Inst) $2);}
| DEC ARG {defonly("$"); $$ = code2(dec_arg, (Inst) $2);}
| ARG INC {defonly("$"); $$ = code2(arg_inc, (Inst) $1);}
| ARG DEC {defonly("$"); $$ = code2(arg_dec, (Inst) $1);}
;
var: VAR begin idxlist {$$ = $2; code3(push_idx, (Inst) $3, (Inst) $1);}
;
idxlist: {$$ = 0;}
| idxlist '[' expr ']' {$$ = $1 + 1;}
;
oper: expr {code(pop_code);}
| PRINT prlist {$$ = $2;}
| while cond {inloop = 1;} oper endop {
    ($1)[1] = (Inst) $4;
    ($1)[2] = (Inst) $5;
    inloop = 0;}
| DO {inloop = 1;} oper while cond endop {
    $$ = $3;
    ($4)[1] = (Inst) $3;
    ($4)[2] = (Inst) $6;
    inloop = 0;}
| FOR '(' expr {code(pop_code); inloop = 1; $<inst>$ = code4(for_code, 0, 0, 0);}
  cond expr {code2(pop_code, STOP);}
  ')' oper endop { //for (init (cond) inc) oper
    $$ = $3;
    ($<inst>4)[1] = (Inst) $9;
    ($<inst>4)[2] = (Inst) $10;
    ($<inst>4)[3] = (Inst) $6;
    inloop = 0;
}
| if cond oper endop {
    ($1)[1] = (Inst) $3;
    ($1)[3] = (Inst) $4;}
| if cond oper endop ELSE oper endop {
    ($1)[1] = (Inst) $3;
    ($1)[2] = (Inst) $6;
    ($1)[3] = (Inst) $7;}
| '{' operlist '}' {$$ = $2;}
| BREAK {looponly("break"); $$ = code(break_code);}
| CONTINUE {looponly("continue"); $$ = code(continue_code);}
| RETURN {defonly("return"); code(procret);}
| RETURN expr {defonly("return"); code(funcret); $$ = $2;}
| PROCCALL begin '(' arglist ')' {
    $$ = $2;
    code3(call, (Inst) $1, (Inst) $4);}
| STATIC {instatic = 1;} varlist {defonly("static"); instatic = 0;}
| DELETE VAR begin idxlist {$$ = $3; code4(push_idx, (Inst) $4, (Inst) $2, delete_code);}
| AUTO {inauto = 1;} varlist {defonly("auto"); inauto = 0;}
;
cond: '(' expr ')' {code(STOP); $$ = $2;}
;
while: WHILE {$$ = code3(while_code, 0, 0);}
;
if: IF {$$ = code4(if_code, 0, STOP, 0);}
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
varlist: VAR
| varlist ',' VAR
;
deffn: FUNCDEF subrname {$2->type = FUNCCALL; indef = 1; defname = *$2->name;}
  '(' ')' oper {code(funcret); define($2); indef = 0;}
| PROCDEF subrname {$2->type = PROCCALL; indef = 1; defname = *$2->name;}
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
| var {code(eval);}
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
| expr andif expr endop {($2)[1] = (Inst) $4;}
| expr orif expr endop {($2)[1] = (Inst) $4;}
| NOT expr {$$ = $2; code(not_code);}
| ARG {defonly("$"); $$ = code2(arg, (Inst) $1);}
| FUNCCALL begin '(' arglist ')' {
    $$ = $2;
    code3(call, (Inst) $1, (Inst) $4);}
| READ '(' VAR ')' {$$ = code2(varread, (Inst) $3);}
;
andif: AND {$$ = code2(andif, 0);}
;
orif: OR {$$ = code2(orif, 0);}
;
%%
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
  {"func", FUNCDEF}, {"proc", PROCDEF}, {"return", RETURN}, {"read", READ},
  {"do", DO}, {"for", FOR}, {"break", BREAK}, {"continue", CONTINUE},
  {"static", STATIC}, {"delete", DELETE}, {"auto", AUTO}};

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
  static string transtab = "b\bf\fn\nr\rt\t";
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
  if (c == '#')
    while ((c = cin.get()) != '\n');
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
  switch (c) {
    case '>': return follow('=', GE, GT);
    case '<': return follow('=', LE, LT);
    case '!': return follow('=', NE, NOT);
    case '=': return follow(c, EQ, c);
    case '|': return follow(c, OR, c);
    case '&': return follow(c, AND, c);
    case '+': return follow('=', AADD, c) == c ? follow(c, INC, c) : AADD;
    case '-': return follow('=', ASUB, c) == c ? follow(c, DEC, c) : ASUB;
    case '*': return follow('=', AMUL, c);
    case '/': return follow('=', ADIV, c);
    case '^': return follow('=', APOW, c);
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
} dia[] = {{"pop_code", pop_code},{"constpush", constpush},
{"add", add},{"sub", sub},{"mul", mul},{"div", div},{"power", power},
{"negate", negate_code},{"bltin", bltin},{"assign_code", assign_code},
{"eval", eval},{"print", print},{">", gt},{">=", ge},{"<", lt},{"<=", le},
{"=", eq},{"!=", ne},{"andif", andif},{"orif", orif},
{"!", not_code},{"while", while_code},{"if", if_code},
{"prexpr", prexpr},{"call", call},{"procret", procret},{"funcret", funcret},
{"arg", arg},{"argassign", argassign},{"prstr", prstr},{"varread", varread},
{"break", break_code}, {"continue", continue_code}, {"+=", assign_plus},
{"-=", assign_minus}, {"*=", assign_mul}, {"/=", assign_div}, {"^=", assign_pow},
{"argassign_plus", argassign_plus}, {"argassign_minus", argassign_minus},
{"argassign_mul", argassign_mul}, {"argassign_div", argassign_div},
{"argassign_pow", argassign_pow}, {"assign_inc", assign_inc},
{"assign_dec", assign_dec}, {"inc_assign", inc_assign}, {"dec_assign", dec_assign},
{"inc_arg", inc_arg}, {"dec_arg", dec_arg}, {"arg_inc", arg_inc},
{"arg_dec", arg_dec}, {"push_idx", push_idx}, {"for_code", for_code}};

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
  else if (p->type ==  VAR || p->type == UNDEF || p->type == ARRAY)
    cout << *p->name;
  else if (p->type == STRING)
    cout << '"' << *p->name << '"';
  cout << endl;
}

main () {
  initdisassm();
  init_names(flist, clist, klist);
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
