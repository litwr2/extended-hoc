COPS = -DLEX

hoc: hoc.cpp.y hoc.cpp.l makefile
	-lex hoc.cpp.l
	yacc hoc.cpp.y
	g++ -o hoc $(COPS) y.tab.c

hoc.cpp.l:
	echo >hoc.cpp.l

clean:
	rm -f y.tab.c lex.yy.c hoc *.o
