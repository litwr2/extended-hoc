OBJS = y.tab.o code.o
OPS = -DLEX

hoc: $(OBJS)
	g++ $(OBJS) -o hoc

y.tab.o: y.tab.c hoc.cpp.l
	-lex hoc.cpp.l
	g++ -c $(COPS) y.tab.c

hoc.cpp.l:
	echo >hoc.cpp.l

code.o: code.cpp hoc.h y.tab.c makefile
	g++ -c code.cpp

y.tab.c: hoc.cpp.y hoc.h makefile
	yacc -d hoc.cpp.y

clean:
	rm -f y.tab.[ch] lex.yy.c hoc *.o
