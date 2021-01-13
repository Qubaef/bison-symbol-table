#
CC=gcc
LEX=flex

% : %.tab.o %.o 
	$(CC) $< $*.o SymbolTable.o $(LDFLAGS) -o $@

%.tab.c %.tab.h: %.y
	bison -d $<

%.c: %.l %.tab.h
	$(LEX) -t $< > $@

c: c.y c.l SymbolTable

SymbolTable:
	$(CC) -o $@.o -c $@.c

