#include "hoc.h"
#include "y.tab.h"

#define NSTACK 256 //stack size
static Datum stack[NSTACK]; //the stack, we are using the module/file scope here
static Datum *stackp; //stack pointer, it points to the top of the stack

#define NPROG 2048 //max program size
Inst prog[NPROG]; //memory for a program
Inst *progp; //it points to the first free space in memory
Inst *pc; //program counter

void initcode() {
  stackp = stack;
  progp = prog;
}

Inst* code(Inst f) { //put a command to memory
  Inst *saved_progp = progp;
  if (progp >= prog + NPROG)
    throw (string) "program too big";
  *progp++ = f;
  return saved_progp;
}

void execute(Inst *p) { //execute commands - it is the interpreter
  for (pc = p; *pc != STOP;)
    (*(*pc++))();
}

//for the work with the stack
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

//commands for the interpreter
void pop_code() {
  pop();
}

void constpush() { //write a constant to the stack
  Datum d;
  d.val = ((Symbol*) *pc++)->val;
  push(d);
}

void varpush() { //write a wariable to the stack
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
  push(d1);
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
