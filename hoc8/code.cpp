#include "hoc.h"
#include "y.tab.h"

#define NSTACK 5000 //stack size
static Datum stack[NSTACK];
static Datum *stackp, *bp;

#define NPROG 2000
Inst prog[NPROG];
Inst *progp;
Inst *pc;
Inst *progbase = prog;
int returning;
int exitloop, loopagain; //flags for break and continue

void initcode() {
  stackp = stack;
  progp = progbase;
  loopagain = exitloop = returning = 0;
}

Inst* code(Inst f) {
  Inst *saved_progp = progp;
  if (progp >= prog + NPROG)
    throw (string) "program too big";
//disassm(progp, f, '*');
  *progp++ = f;
  return saved_progp;
}

void execute(Inst *p) {
  for (pc = p; *pc != STOP && !returning;) {
//disassm(pc, *pc, '#');
    (*(*pc++))();
  }
}

void push(Datum d) {
   if (stackp >= stack + NSTACK)
     throw (string) "stack overflow";
   *stackp++ = d;
}

Datum pop() {
  if (stackp <= stack)
    throw (string) "stack underflow";
  return *--stackp;
}

void pop_code() {
  pop();
}

void constpush() {
  Datum d;
  d.val = ((Symbol*) *pc++)->val;
  push(d);
}

void add() {
  Datum d1 = pop(), d2 = pop();
  d2.val += d1.val;
  push(d2);
}

void sub() {
  Datum d1 = pop(), d2 = pop();
  d2.val -= d1.val;
  push(d2);
}

void mul() {
  Datum d1 = pop(), d2 = pop();
  d2.val *= d1.val;
  push(d2);
}

void div() {
  Datum d1 = pop(), d2 = pop();
  d2.val /= d1.val;
  push(d2);
}

void power() {
  Datum d1 = pop(), d2 = pop();
  d2.val = pow(d2.val, d1.val);
  push(d2);
}

void negate_code() {
  Datum d = pop();
  d.val *= -1;
  push(d);
}

void bltin() {
  Datum d = pop();
  d.val = (*(double(*)(double))(*pc++))(d.val);
  push(d);
}

void assign_code() {
  Datum d2 = pop(), d1 = pop();
  d1.sym->val = d2.val;
  d1.sym->type = VAR;
  push(d2);
}

void assign_plus() {
  Datum d2 = pop(), d1 = pop();
  d2.val = d1.sym->val += d2.val;
  d1.sym->type = VAR;
  push(d2);
}

void inc_assign() {
  Datum d = pop();
  d.sym->type = VAR;
  d.val = d.sym->val += 1;
  push(d);
}

void dec_assign() {
  Datum d = pop();
  d.sym->type = VAR;
  d.val = d.sym->val -= 1;
  push(d);
}

void assign_inc() {
  Datum d1 = pop(), d2;
  d2.val = d1.sym->val;
  push(d2);
  d1.sym->val = d1.sym->val + 1;
  d1.sym->type = VAR;
}

void assign_dec() {
  Datum d1 = pop(), d2;
  d2.val = d1.sym->val;
  push(d2);
  d1.sym->val = d1.sym->val - 1;
  d1.sym->type = VAR;
}

void assign_minus() {
  Datum d2 = pop(), d1 = pop();
  d2.val = d1.sym->val -= d2.val;
  d1.sym->type = VAR;
  push(d2);
}

void assign_mul() {
  Datum d2 = pop(), d1 = pop();
  d2.val = d1.sym->val *= d2.val;
  d1.sym->type = VAR;
  push(d2);
}

void assign_div() {
  Datum d2 = pop(), d1 = pop();
  d2.val = d1.sym->val /= d2.val;
  d1.sym->type = VAR;
  push(d2);
}

void assign_pow() {
  Datum d2 = pop(), d1 = pop();
  d2.val = d1.sym->val = pow(d1.sym->val,d2.val);
  d1.sym->type = VAR;
  push(d2);
}

void eval() {
  Datum d = pop();
  if (d.sym->type == UNDEF)
    throw "undefined variable: " + *d.sym->name;
  d.val = d.sym->val;
  push(d);
}

void print() {
  Datum d = pop();
  cout << d.val << endl;
}

void gt() {
  Datum d1 = pop(), d2 = pop();
  d2.val = (d2.val > d1.val);
  push(d2);
}

void ge() {
  Datum d1 = pop(), d2 = pop();
  d2.val = (d2.val >= d1.val);
  push(d2);
}

void lt() {
  Datum d1 = pop(), d2 = pop();
  d2.val = (d2.val < d1.val);
  push(d2);
}

void le() {
  Datum d1 = pop(), d2 = pop();
  d2.val = (d2.val <= d1.val);
  push(d2);
}

void eq() {
  Datum d1 = pop(), d2 = pop();
  d2.val = (d2.val == d1.val);
  push(d2);
}

void ne() {
  Datum d1 = pop(), d2 = pop();
  d2.val = (d2.val != d1.val);
  push(d2);
}

void not_code() {
  Datum d = pop();
  d.val = !d.val;
  push(d);
}

void while_code() {
  Datum d;
  Inst *savepc = pc;
  execute(pc + 2);
  d = pop();
  while (d.val) {
    execute(*(Inst**)savepc);
    if (loopagain)
      returning = loopagain = 0;
    if (returning)
      break;
    execute(savepc + 2);
    d = pop();
  }
  returning = !exitloop && returning;
  exitloop = 0;
  if (!returning)
    pc = *(Inst**)(savepc + 1);
}

void for_code() {
  Datum d;
  Inst *savepc = pc;
  execute(pc + 3);  //condition
  d = pop();
  while (d.val) {
    execute(*(Inst**)savepc);  //body
    if (loopagain)
      returning = loopagain = 0;
    if (returning)
      break;
    execute(*(Inst**)(savepc + 2));
    execute(savepc + 3);  //condition
    d = pop();
  }
  returning = !exitloop && returning;
  exitloop = 0;
  if (!returning)
    pc = *(Inst**)(savepc + 1);  //the next command
}

void if_code() {
  Inst *savepc = pc;
  execute(pc + 3);
  Datum d = pop();
  if (d.val)
    execute(*(Inst**)savepc);
  else if (*(savepc + 1))
    execute(*(Inst**)(savepc + 1));
  if (!returning)
    pc = (*(Inst**)(savepc + 2));
}

void andif() {
  Inst *savepc = pc;
  Datum d = pop();
  if (d.val) {
    execute(pc + 1);
    d = pop();
  }
  push(d);
  pc = (*(Inst**)savepc);
}

void orif() {
  Inst *savepc = pc;
  Datum d = pop();
  if (!d.val) {
    execute(pc + 1);
    d = pop();
  }
  push(d);
  pc = (*(Inst**)savepc);
}

void prexpr() {
  Datum d = pop();
  cout << d.val;
}

void defonly(const string& s) {
  if (!indef)
    throw s + " used outside definition";
}

void define(Symbol *sp) {
  sp->deffn = (Inst) progbase;
  progbase = progp;
}

void call() {
  Symbol *sp = (Symbol*)*pc; //a record for the called subroutine in the symbol table
  Datum d;
  stackp += names[*sp->name + "@"].type;
                 //allocate space for local variables
  d.sym = (Symbol*)(pc + 2);  //return address
  push(d);
  d.sym = (Symbol*)bp;  //address of the base of local parameters
  push(d);
  bp = stackp;   //new value for the base
  execute((Inst*)sp->deffn);
      //access to the symbol table to get subroutine address
  returning = 0;
}

void ret() {
  Datum d = pop();
  bp = (Datum*) d.sym;
  d = pop();
  pc = (Inst*)d.sym;
  stackp -= (long)*(pc - 1) //remove arguments and automatic variables
      + names[*(*(Symbol**)(pc - 2))->name + "@"].type;
  returning = 1;
}

void funcret() {
  Datum d = pop();
  Symbol *sp = *(*(Symbol***)(stackp - 2) - 2);
  if (sp->type == PROCCALL)
    throw *sp->name + " (proc) returns value";
  ret();
  push(d);
}

void procret() {
  Symbol *sp = *(*(Symbol***)(stackp - 2) - 2);
  if (sp->type == FUNCCALL)
    throw *sp->name + " (func) returns no value";
  ret();
}

double *getarg() {
  int narg = (long)*pc++;
  long nargs = (long)*(*(Symbol***)(bp - 2) - 1);
  Symbol *sp = *(*(Symbol***)(bp - 2) - 2);
  int locvars = names[*sp->name + "@"].type;
  if (narg > nargs)
    throw *sp->name + " not enough arguments";
  if (narg < 0)
    return &(bp + narg - 2)->val;
  else
    return &(bp - nargs + narg - 3 - locvars)->val;
}

void arg() { //transfer an argument to the operation stack
  Datum d;
  d.val = *getarg();
  push(d);
}

void argassign() { //write the top of the stack value to an argument
  Datum d;
  push(d = pop());
  *getarg() = d.val;
}

void argassign_plus() {
  Datum d = pop();
  d.val = *getarg() += d.val;
  push(d);
}

void inc_arg() {
  Datum d;
  d.val = *getarg() += 1;
  push(d);
}

void dec_arg() {
  Datum d;
  d.val = *getarg() -= 1;
  push(d);
}

void arg_inc() {
  Datum d;
  double *ap = getarg();
  d.val = *ap;
  *ap += 1;
  push(d);
}

void arg_dec() {
  Datum d;
  double *ap = getarg();
  d.val = *ap;
  *ap -= 1;
  push(d);
}

void argassign_minus() {
  Datum d = pop();
  d.val = *getarg() -= d.val;
  push(d);
}

void argassign_mul() {
  Datum d = pop();
  d.val = *getarg() *= d.val;
  push(d);
}

void argassign_div() {
  Datum d = pop();
  d.val = *getarg() /= d.val;
  push(d);
}

void argassign_pow() {
  Datum d = pop();
  double *ap = getarg();
  d.val = *ap = pow(*ap, d.val);
  push(d);
}

void prstr() { //print text string
  cout << *(((Symbol*) *pc++)->name);
}

void varread() { //read values for variables
  Datum d;
  Symbol *var = (Symbol*) *pc++;
  if (!(cin >> var->val))
    throw "non-number read into " + *var->name;
  d.val = var->val;
  var->type = VAR;
  push(d);
}

void looponly(const string& s) {
  if (!inloop)
    throw s + " used outside loop";
}

void break_code() {
  returning = exitloop = 1;
}

void continue_code() {
  returning = loopagain = 1;
}

void push_idx() { //varpush with indices
  ostringstream os;
  int qidx = (long) *pc++;
  Datum d;
  string s;
  d.sym = (Symbol*) *pc++;
  if (qidx) {
    while (qidx--) {
      Datum t = pop();
      os << "-" << t.val;
      s = os.str() + s;
      os.str("");
    }
    s = *d.sym->name + s;
    names[s].type = ARRAY;
    names[s].name = &(string&)names.find(s)->first;
    d.sym = &names[s];
  }
  push(d);
}

void delete_code() {
  Datum d = pop();
  string s = *d.sym->name;
  int p;
  do {
    p = 0;
    for (map<string, Symbol>::iterator i = names.begin(); i != names.end(); ++i)
      if (i->first.find(s) == 0 && (i->first.length() == s.length() || i->first[s.length()] == '-')) {
        names.erase(i->first);
        p = 1;
        break;
      }
  } while (p);
}

