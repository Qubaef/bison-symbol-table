#include "SymbolTable.h"

#include <time.h>

enum Type
{
	INT,
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


int main()
{
	TableEntry* entry;

	initSymbolTable();

	// TEST: VARS
	// Add sample entries
	insertVar("aba", INT);
	insertVar("kappa", FLOAT);
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

	incScope();
	decScope("main");

	insertFunc("decScope", INT, NULL);

	incScope();
	incScope();


	// Check values
	testLookup("aba");
	testLookup("POG");
	testLookup("kappa");
	testLookup("stderr");

	printSymbolTable();

	//clock_t start = clock();

	//int attempts = 1000000;
	//for (int i = 0; i < attempts; i++)
	//{
	//	decScope(); // new scope

	//// Add sample entries
	//	TableEntry* entry1 = insert("kappa", type, "2scop");
	//	TableEntry* entry2 = insert("testy", type, "2scop");
	//	TableEntry* entry3 = insert("abba", type, "2scop");
	//	TableEntry* entry4 = insert("pog", type, "2scop");
	//	TableEntry* entry5 = insert("a", type, "2scop");
	//	TableEntry* entry6 = insert("Dott", type, "2scop");

	//	entry = lookup("testy");
	//	entry = lookup("i");
	//	entry = lookup("abba");
	//	entry = lookup("pog");
	//	entry = lookup("a");

	//	incScope();
	//}

	//clock_t end = clock();
	//float seconds = (float)(end - start) / CLOCKS_PER_SEC;
	//printf("%f\n", seconds);


	return 0;
}