# extended-hoc

It is a simple programming language step-by-step implementation using Bison or Yacc power.  The usage of Flex is optional but recommended.  The hoc language is described in a book The Unix Programming Environment (Prentice-Hall Software Series) by Brian W. Kernighan and Rob Pike.  The presented implementation uses some advantages of C++ language and finally implements more advanced and fast language.

## Step 1
It is a calculator for the integer arithmetic.  All five base operations (+, -, *, /, ^) are implemented.

## Step 2
The support for real arithmetic is added.

## Step 3
The opportunity to use up to 26 variables is provided.  Every variable has to have a name which consists of one small letter.  A simple error handling is added too.

## Step 4
The possibility to use standard functions and constants is implemented.  It allows to use functions like _sin()_, _exp()_, _log()_ and constants like _pi_ or _phi_.  A bit more advanced way to work with errors is provide too.

## Step 5
It is the same language as in the step 4 but instead of immediate interpretation it realizes the code generation.  This allows further to implement language statements.

## Step 6
It is the statements _if_, _while_, _print_ and _{}_ (grouping) implementation.  It also implements 6 relational (==, !=, <=, >=, <, >) and 3 logical (&&, ||, !) operators.

## Step 7
It is adding the subroutines (functions and procedures) and required for this _return_ statement.  We have also improved _print_ statement making it multi-argument with possibility to use text strings in it.  Besides that the input operator _read_ is implemented.  A test file is provided to check the new features.  There is also a simple tracer-disassembler realized.

## Step 8
There is a bunch of improvements and new features here: comments, C-like logical _and_ and _or_, _do_-statement, _for_-statement, _break_-statement, _continue_-statement, more C-like assignment-operators (+=, -=, *=, /=, ^=, ++, --), automatic and static local variables, arrays (hashes) with the delete element operator.  Several test files are made.  This level of implementation can easily be expanded by some new operators and features, for example, _until_ and _unless_ statements, more C-like operators (, and ?:), ...

