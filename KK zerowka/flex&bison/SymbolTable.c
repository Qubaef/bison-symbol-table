#include "SymbolTable.h"

unsigned hash(char* identifier)
{
	// djb2 hash algorithm
	unsigned hash = 5381;
	int c;

	while (c = *identifier++)
		hash = ((hash << 5) + hash) + c; /* hash * 33 + c */

	return hash;
}


TableEntry* TableEntry_new(enum EntryType entryType, char* identifier, int* pFuncParams, int type, TableEntry* next)
{
	TableEntry* pTableEntry = malloc(sizeof(TableEntry));
	if (pTableEntry)
	{
		pTableEntry->entryType = entryType;
		strcpy(pTableEntry->identifier, identifier);

		if (entryType == FUNC && pFuncParams != NULL)
		{
			pTableEntry->pFuncParams = calloc(MAX_FUNC_PARAMS, sizeof(int));
			memcpy(pTableEntry->pFuncParams, pFuncParams, MAX_FUNC_PARAMS);
		}
		else
		{
			pTableEntry->pFuncParams = NULL;
		}

		pTableEntry->type = type;
		pTableEntry->next = next;

		if (entryType == VAR)
		{
			pTableEntry->pSubScope = NULL;
		}
		else
		{
			pTableEntry->pSubScope = ScopeNode_new(currentScopeNode);
		}
	}
	else
	{
		printf("ERROR: TableEntry_new(): bad alloc.\n");
	}

	return pTableEntry;
}

//TableEntry* TableEntry_new(TableEntry* pTableEntry)
//{
//	TableEntry* pNewTableEntry = malloc(sizeof(TableEntry));
//	if (pNewTableEntry)
//	{
//		pNewTableEntry->entryType = pTableEntry->entryType;
//		strcpy(pNewTableEntry->identifier, pTableEntry->identifier);
//
//		if (pTableEntry->entryType == FUNC && pTableEntry->pFuncParams != NULL)
//		{
//			pNewTableEntry->pFuncParams = calloc(MAX_FUNC_PARAMS, sizeof(int));
//			memcpy(pNewTableEntry->pFuncParams, pTableEntry->pFuncParams, MAX_FUNC_PARAMS);
//		}
//		else
//		{
//			pNewTableEntry->pFuncParams = NULL;
//		}
//
//		pNewTableEntry->type = pTableEntry->type;
//		pNewTableEntry->next = pTableEntry->next;
//		pNewTableEntry->pSubScope = pTableEntry->pSubScope;
//	}
//	else
//	{
//		printf("ERROR: TableEntry_new(): bad alloc.\n");
//	}
//
//	return pNewTableEntry;
//}

void TableEntry_delete(TableEntry* pTableEntry)
{
	if (pTableEntry->pSubScope != NULL)
	{
		ScopeNode_delete(pTableEntry->pSubScope);
	}

	if (pTableEntry->next != NULL)
	{
		TableEntry_delete(pTableEntry->next);
	}

	free(pTableEntry);
}


ScopeNode* ScopeNode_new(ScopeNode* pParent)
{
	ScopeNode* pSymbolTableNode = malloc(sizeof(ScopeNode));
	if (pSymbolTableNode)
	{
		pSymbolTableNode->tableEntry = calloc(SCOPE_TABLE_SIZE, sizeof(TableEntry*));
		pSymbolTableNode->pParent = pParent;
	}
	else
	{
		printf("ERROR: SymbolTableNode_new(): bad alloc.\n");
	}

	return pSymbolTableNode;
}

void ScopeNode_delete(ScopeNode* pSymbolTableNode)
{
	for (int i = 0; i < SCOPE_TABLE_SIZE; i++)
	{
		if (pSymbolTableNode->tableEntry[i] != NULL)
		{
			TableEntry_delete(pSymbolTableNode->tableEntry[i]);
		}
	}

	free(pSymbolTableNode->tableEntry);
	free(pSymbolTableNode);
}


void initSymbolTable()
{
	globalScopeNode = ScopeNode_new(NULL);
	currentScopeNode = globalScopeNode;
}


void insert(TableEntry* pEntry)
{
	TableEntry** pEntryTarget = &currentScopeNode->tableEntry[hash(pEntry->identifier) % SCOPE_TABLE_SIZE];

	if (*pEntryTarget == NULL)
	{
		*pEntryTarget = pEntry;
	}
	else
	{
		while ((*pEntryTarget)->next != NULL)
		{
			pEntryTarget = &(*pEntryTarget)->next;
		}

		(*pEntryTarget)->next = pEntry;
	}
}

TableEntry* insertScope(char* identifier)
{
	TableEntry* pEntry = TableEntry_new(SCOPE, identifier, NULL, 0, NULL);
	insert(pEntry);
	currentScopeNode = pEntry->pSubScope;
	return pEntry;
}

TableEntry* insertStruct(char* identifier)
{
	TableEntry* pEntry = TableEntry_new(STRUCT, identifier, NULL, 0, NULL);
	insert(pEntry);
	currentScopeNode = pEntry->pSubScope;
	return pEntry;
}

TableEntry* insertVar(char* identifier, int type)
{
	TableEntry* pEntry = TableEntry_new(VAR, identifier, NULL, type, NULL);
	insert(pEntry);
	return pEntry;
}

TableEntry* insertFunc(char* identifier, int type, int* pFuncParams)
{
	TableEntry* pEntry = TableEntry_new(FUNC, identifier, pFuncParams, type, NULL);
	insert(pEntry);
	currentScopeNode = pEntry->pSubScope;
	return pEntry;
}


TableEntry* lookup(char* identifier)
{
	ScopeNode* analyzedScope = currentScopeNode;

	while (analyzedScope != NULL)
	{
		TableEntry* pEntryCurrent = analyzedScope->tableEntry[hash(identifier) % SCOPE_TABLE_SIZE];

		while (pEntryCurrent != NULL)
		{
			if (!strcmp(pEntryCurrent->identifier, identifier))
			{
				return pEntryCurrent;
			}

			pEntryCurrent = pEntryCurrent->next;
		}

		analyzedScope = analyzedScope->pParent;
	}

	return NULL;
}


int decScope(char* identifier)
{
	TableEntry* pEntry = currentScopeNode->tableEntry[hash(identifier) % SCOPE_TABLE_SIZE];

	if (pEntry->pSubScope != NULL)
	{
		currentScopeNode = pEntry->pSubScope;
		return 1;
	}
	else
	{
		printf("ERROR: decScope(): no subScope for given identifier.\n");
		return 0;
	}
}

void incScope()
{
	if (currentScopeNode->pParent != NULL)
	{
		currentScopeNode = currentScopeNode->pParent;
	}
	else
	{
		printf("ERROR: incScope(): attempting to inc from global scope.\n");
	}

}

void printIndentation(FILE* target, int scopeLevel)
{
	for (int i = 0; i < scopeLevel; i++)
	{
		fprintf(target, "  ");
	}
}

void printScope(FILE* target, ScopeNode* pScopeToPrint, int scopeLevel)
{
	printIndentation(target, scopeLevel);
	fprintf(target, "Scope level: %d\n", scopeLevel);

	for (int i = 0; i < SCOPE_TABLE_SIZE; i++)
	{
		printIndentation(target, scopeLevel);
		fprintf(target, "%d:\n", i);
		TableEntry* pEntryCurrent = pScopeToPrint->tableEntry[i];

		while (pEntryCurrent != NULL)
		{
			printIndentation(target, scopeLevel);
			fprintf(target, "[entryType: %d, ident: %s, type %d]\n", pEntryCurrent->entryType,
				pEntryCurrent->identifier, pEntryCurrent->type);

			if (pEntryCurrent->pSubScope != NULL)
			{
				printScope(target, pEntryCurrent->pSubScope, scopeLevel + 1);
			}

			pEntryCurrent = pEntryCurrent->next;
		}

		printIndentation(target, scopeLevel);
		fprintf(target, "<NULL>\n");
	}
}

void printSymbolTable()
{
	printScope(stdout, globalScopeNode, 0);
}

void printSymbolTableToFile()
{
	FILE* f = fopen("symbolTableDump", "w");
	if (f == NULL)
	{
		printf("ERROR: printSymbolTableToFile(): unable to open file.");
		return;
	}

	printScope(f, globalScopeNode, 0);

	fclose(f);
}
