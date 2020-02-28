#define USE_CALLIN_CHAR

#define ZF_DLL  /* Required only for dynamically linked libraries. */

#include <julia.h>
#include <cdzf.h>
#include <stdbool.h>

/*
// Pointer to incoming code to execute
char* inStream = NULL;

// Current position in incoming code to execute
int curpos = 0;

// Size of inStream pointer
int maxpos = 0;

// Haldle for a library if we want to load it explicitly
void *libHandle = NULL;*/

// Initializes Python environment
// and obtains reference to the main module.
// Due to the problems with lib-dynload, sometimes library file should be loaded explicitly
// https://bugs.python.org/issue4434
// Do not use it, unless you get errors like: undefined symbol: _Py_TrueStruct and so on)
int Initialize(char *file) {
	if (jl_is_initialized() == false) {
		jl_init();
	}
	return ZF_SUCCESS;
}


int Finalize() {
	if (jl_is_initialized()) {
		jl_atexit_hook(0);
	}

	return ZF_SUCCESS;
}

// Execute simple command.
// Initializes environment if required
// Does not finalize the environment.
int SimpleString(CACHE_EXSTRP command, char *resultVar, CACHE_EXSTRP result) {

	if (jl_is_initialized() == false) {
		Initialize(NULL);
	}

	// Copy command text to a new pointer and add null at the end
	char* commandChar = malloc(1 + sizeof(char)*command->len);
	memcpy(commandChar, command->str.ch,  command->len);
	memcpy(commandChar + command->len, "\0", 1);

	jl_eval_string(commandChar);

	CACHEEXSTRKILL(command);
	free(commandChar);


	jl_value_t *var = jl_eval_string(resultVar);
	//jl_value_t *var = jl_get_global(jl_main_module, resultVar);
	if (var && (resultVar != NULL) && (resultVar[0] != '\0')) {
		const char *str = jl_string_ptr(var);

		int len = strlen(str);
		CACHEEXSTRKILL(result);
		if (!CACHEEXSTRNEW(result,len)) {
			return ZF_FAILURE;
		}
		memcpy(result->str.ch, str, len);   // copy to retval->str.ch
	}

	return ZF_SUCCESS;
}


// Assumes initialized environment
int SimpleExecute(char *command, char *resultVar, char* result) {

	if (jl_is_initialized() == false) {
		Initialize(NULL);
	}
	jl_eval_string(command);
	

	jl_value_t *var = jl_eval_string(resultVar);
	//jl_value_t *var = jl_get_global(jl_base_module, resultVar);

	const char *str = jl_string_ptr(var);

	sprintf(result, "%s", str);

	
	return ZF_SUCCESS;
}

ZFBEGIN
	ZFENTRY("Initialize","c",Initialize)
	ZFENTRY("Finalize","",Finalize)
	ZFENTRY("SimpleString","jcJ",SimpleString)
	ZFENTRY("SimpleExecute","ccC",SimpleExecute)
ZFEND
