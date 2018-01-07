COPS = -DLEX

hoc: hoc.cpp.y hoc.cpp.l makefile
	-lex hoc.cpp.l
	yacc $<
	g++ -o $@ $(COPS) y.tab.c

hoc.cpp.l:
	echo >$@

clean:
	rm -f y.tab.c lex.yy.c hoc *.o
