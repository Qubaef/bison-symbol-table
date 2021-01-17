#include "common.h"

// TODO:

//////////////////////////////////////////////////////////
/// S_DECLARATION

// Data structure for bison's VAR type
typedef struct var {
	char ident[MAX_IDENTIFIER_LENGTH];
	unsigned assigned_type;
	var* next;
} var;

// Data structure for bison's VAR_LIST type
typedef struct {
	var* var;
} var_list;

// Data structure for bison's S_DECLARATION type
typedef struct s_declaration {
	unsigned data_type;
	var_list* var_list;
	s_declaration* next;
} s_declaration;

//////////////////////////////////////////////////////////

/////////////////////////////////////////////////////////////
/// INSTRUCTION

enum InstructionType
{
	FUN_CALL,
	FOR_INSTR,
	ASSIGNMENT,
	INCR,
	IF_INSTR,
	WHILE_INSTR,
	DO_WHILE
};

// Data structure for bison's INSTRUCTION type
typedef struct instruction {
	InstructionType instrType;
	
	//	instruction* instruction;
} instruction;

/////////////////////////////////////////////////////////////
/// S_FUNCTION

// Data structure for bison's FORM_PARAM type
typedef struct form_param {
	unsigned data_type;
	char ident[MAX_IDENTIFIER_LENGTH];
	form_param* next;
} form_param;

// Data structure for bison's FORM_PARAM_LIST type
typedef struct {
	form_param* form_param;
} form_param_list;

// Data structure for bison's FUN_HEAD type
typedef struct {
	unsigned data_type;
	char ident[MAX_IDENTIFIER_LENGTH];
	form_param_list* form_param_list;
} fun_head;

// Data structure for bison's DECL_LIST type
typedef struct {
	s_declaration* s_declaration;
} decl_list;

// Data structure for bison's INSTR_LIST type
typedef struct {
	instruction* instruction;
} instr_list;

// Data structure for bison's BLOCK type
typedef struct {
	decl_list* decl_list;
	instr_list* instr_list;
} block;

// Data structure for bison's S_FUNCTION type
typedef struct {
	unsigned type;
	fun_head* fun_head;
	block* block;
} s_function;