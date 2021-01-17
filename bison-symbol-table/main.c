#include "SymbolTable.h"

#include <time.h>

enum Type
{
	INT = 1,
	CHAR,
	FLOAT,
	VOID,
	UNSIGNED,
};

void testLookup(char* ident)
{
	if (lookup(ident))
	{
		printf("Symbol \"%s\" found\n", ident);
	}
	else
	{
		printf("Symbol \"%s\" not found\n", ident);
	}
}

void testSubLookup(char* ident)
{
	if (lookup_subscope(ident))
	{
		printf("Symbol \"%s\" found\n", ident);
	}
	else
	{
		printf("Symbol \"%s\" not found\n", ident);
	}
}


int main()
{
	// Both tests and presentation of sample usages of the functions
	TableEntry* entry;
	initSymbolTable();

	// TEST: VARS
	// Add sample entries
	insertVar("aba", INT);
	insertVar("kap", FLOAT);
	insertVar("test", VOID);
	insertVar("POG", UNSIGNED);
	insertVar("_a", CHAR);

	// TEST: SUBSCOPE
	insertScope("");
	insertVar("kappa", FLOAT);
	insertVar("test", INT);
	insertVar("PogU", FLOAT);
	incScope();

	// TEST: STRUCT
	insertStruct("d1");
	insertVar("year", INT);
	insertVar("month", INT);
	insertVar("day", INT);
	incScope();

	// TEST: FUNC
	int* params = calloc(MAX_FUNC_PARAMS, sizeof(int));
	params[0] = INT;
	params[1] = FLOAT;
	params[2] = UNSIGNED;

	insertFunc("main", VOID, params);
	insertVar("entry", VOID);
	insertVar("params", INT);
	insertVar("var", INT);
	insertVar("war", INT);

	testLookup("main");
	testSubLookup("var");
	testSubLookup("main");
	testSubLookup("kap");


	incScope();
	decScope("main");

	insertFunc("decScope", INT, NULL);

	incScope();
	incScope();


	// Check values
	testLookup("aba");
	testLookup("help");
	testLookup("kap");
	testLookup("stderr");

	printSymbolTable();

	
	clock_t start = clock();

	int attempts = 10000;
	for (int i = 0; i < attempts; i++)
	{
		insertFunc("for loop scope", INT, NULL);
		
		// Add sample entries
		insertVar("kap", INT);
		insertVar("kap1", INT);
		insertVar("kap2", INT);
		insertVar("kap3", INT);
		insertVar("kap4", INT);
		insertVar("kap5", INT);
		insertVar("kap6", INT);
		insertVar("kap7", INT);
		insertVar("kap8", INT);
		insertVar("kap9", INT);
		

		entry = lookup("kap");
		entry = lookup("kap1");
		entry = lookup("kap5");
		entry = lookup("notfound");
		entry = lookup("notfound2");
	}

	clock_t end = clock();
	float seconds = (float)(end - start) / CLOCKS_PER_SEC;
	printf("time for %d scopes: %f\n",attempts, seconds);

	return 0;
}