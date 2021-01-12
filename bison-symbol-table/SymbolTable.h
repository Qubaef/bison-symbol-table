#pragma once
#include <stdlib.h>
#include <string.h>
#include <stdio.h>
#include "common.h"

#define SCOPE_TABLE_SIZE 16
#define MAX_FUNC_PARAMS 127		// according to C standard

enum EntryType
{
	SCOPE,
	VAR,
	FUNC,
	STRUCT
};

//// Define SymbolTable entry 
typedef struct TableEntry
{
	enum EntryType entryType;				// Type of the entry [ALL]
	char identifier[MAX_IDENTIFIER_LENGTH];	// Entry Identifier  [ALL]
	int type;								// Entry's type		 [VAR and FUNC]
	int* pFuncParams;						// Func params types [FUNC]
	struct ScopeNode* pSubScope;			// Entry's subScope  [FUNC and STRUCT]

	struct TableEntry* next;
} TableEntry;

TableEntry* TableEntry_new(enum EntryType entryType, char* identifier, int* pFuncParams, int type, TableEntry* next);
void TableEntry_delete(TableEntry* pTableEntry);


//// Define SymbolTable node 
typedef struct ScopeNode
{
	struct ScopeNode* pParent;
	TableEntry** tableEntry;
} ScopeNode;

ScopeNode* ScopeNode_new(ScopeNode* pParent);
void ScopeNode_delete(ScopeNode* pSymbolTableNode);


//// Fields
static ScopeNode* globalScopeNode;
static ScopeNode* currentScopeNode;

//// Functions

// initialize SymbolTable
void initSymbolTable();

// calculate and return hash value for given identifier
unsigned hash(char* identifier);

// insert symbol of given attributes to the table
// if symbol already exists, it would not be inserted
// return pointer to entry
TableEntry* insertScope(char* identifier);
TableEntry* insertStruct(char* identifier);
TableEntry* insertVar(char* identifier, int type);
TableEntry* insertFunc(char* identifier, int type, int* pFuncParams);

// check if symbol exists in current scope
// returns pointer to entry
// returns NULL if not found
TableEntry* lookup(char* identifier);

// go down one scope
int decScope(char* identifier);

// go up one scope
void incScope();

// print symbolsTable for debug purposes
void printSymbolTable();
void printSymbolTableToFile();