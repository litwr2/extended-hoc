#include "hoc.h"
#include "y.tab.h"

#define NSTACK 5000 //stack size
static Datum stack[NSTACK];
static Datum *stackp, *bp; //stack pointer and pointer to local variables base

#define NPROG 2000 //max program size in commands
Inst prog[NPROG];
Inst *progp;
Inst *pc; //program counter
Inst *progbase = prog; //the start of the next subroutine
int returning; //1, if return is executing

void initcode() {
  stackp = stack;
  progp = progbase;
  returning = 0;
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

void varpush() {
  Datum d;
  d.sym = (Symbol*) *pc++;
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
  Datum d1 = pop(), d2 = pop();
  d1.sym->val = d2.val;
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
  cout << fixed << d.val << endl;
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

void and_code() {
  Datum d1 = pop(), d2 = pop();
  d2.val = (d2.val && d1.val);
  push(d2);
}

void or_code() {
  Datum d1 = pop(), d2 = pop();
  d2.val = (d2.val || d1.val);
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
  execute(pc + 2); //condition
  d = pop();
  while (d.val) {
    execute(*(Inst**)savepc); //body
    if (returning)
      break;
    execute(savepc + 2); //condition
    d = pop();
  }
  if (!returning)
    pc = *(Inst**)(savepc + 1); //the next command
}

void if_code() {
  Inst *savepc = pc;
  execute(pc + 3); //condition
  Datum d = pop();
  if (d.val)
    execute(*(Inst**)savepc); //then-part
  else if (*(savepc + 1)) //check else-part presence
    execute(*(Inst**)(savepc + 1)); //else-part
  if (!returning)
    pc = (*(Inst**)(savepc + 2)); //the next command
}

void prexpr() {
  Datum d = pop();
  cout << fixed << d.val;
}

void defonly(const string& s) {
  if (!indef)
    throw s + " used outside definition";
}

void define(Symbol *sp) {
  sp->deffn = (Inst) progbase;
  progbase = progp;
}

void call() { //a subroutine call
  Datum d;
  d.sym = (Symbol*)(pc + 2);  //return address
  push(d);
  d.sym = (Symbol*)bp;  //local variables base address
  push(d);
  bp = stackp;   //a new value for the base
  execute((Inst*)((Symbol*)*pc)->deffn);
      //usage of the symbol table to retrieve a subroutine address
  returning = 0;
}

void ret() { //general return from a subroutine
  Datum d = pop();
  bp = (Datum*) d.sym;
  d = pop();
  pc = (Inst*)d.sym;
  for (int i = 0; i < (long)*(pc - 1); i++)
    pop(); //remove arguments
  returning = 1;
}

void funcret() { //return from a function
  Datum d = pop(); //function's value
  Symbol *sp = *(*(Symbol***)(stackp - 2) - 2);
  if (sp->type == PROCCALL)
    throw *sp->name + " (proc) returns value";
  ret();
  push(d);
}

void procret() { //return from a procedure
  Symbol *sp = *(*(Symbol***)(stackp - 2) - 2);
  if (sp->type == FUNCCALL)
    throw *sp->name + " (func) returns no value";
  ret();
}

double *getarg() { //returns a pointer to an argument
  int narg = (long)*pc++; //argument's number
  long nargs = (long)*(*(Symbol***)(bp - 2) - 1);
  if (narg > nargs)
    throw *(*(*(Symbol***)(bp - 2) - 2))->name + " not enough arguments";
  return &(bp - nargs + narg - 3)->val;
}

void arg() { //move argument to the operation stack
  Datum d;
  d.val = *getarg();
  push(d);
}

void argassign() { //writes a value of the top of the stack to an argument
  Datum d;
  push(d = pop());
  *getarg() = d.val;
}

void prstr() { //print text string
  cout << *(((Symbol*) *pc++)->name);
}

void varread() { //reads values for the variables
  Datum d;
  Symbol *var = (Symbol*) *pc++;
  if (!(cin >> var->val))
    throw "non-number read into " + *var->name;
  d.val = var->val;
  var->type = VAR;
  push(d);
}
