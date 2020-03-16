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
int SimpleString(CACHE_EXSTRP command, CACHE_EXSTRP result) {

	if (jl_is_initialized() == false) {
		Initialize(NULL);
	}

	// Copy command text to a new pointer and add null at the end
	char* commandChar = malloc(1 + sizeof(char)*command->len);
	memcpy(commandChar, command->str.ch,  command->len);
	memcpy(commandChar + command->len, "\0", 1);

	jl_value_t *var = jl_eval_string(commandChar);

	CACHEEXSTRKILL(command);
	free(commandChar);

	if (var) {
		char *str = malloc(100);

		if (jl_is_string(var)) {
			str = jl_string_ptr(var);
		} else if (jl_isa(var, jl_char_type)) {
			str = jl_string_ptr(var);
		} else if (jl_is_bool(var)) {
			int8_t val = jl_unbox_bool(var);
			sprintf(str, "%d", val);
		} else if (jl_is_int8(var)) {
			int8_t val = jl_unbox_int8(var);
			sprintf(str, "%d", val);
		} else if (jl_is_int16(var)) {
			int16_t val = jl_unbox_int16(var);
			sprintf(str, "%d", val);
		} else if (jl_is_int32(var)) {
			int32_t val = jl_unbox_int32(var);
			sprintf(str, "%d", val);
		} else if (jl_is_int64(var)) {
			int64_t val = jl_unbox_int64(var);
			sprintf(str, "%lld", val);
		} else if (jl_isa(var, jl_float32_type)) {
			float val = jl_unbox_float32(var);
			sprintf(str, "%g", val);
		} else if (jl_isa(var, jl_float64_type)) {
			double val = jl_unbox_float64(var);
			sprintf(str, "%g", val);
		} else {
			str = "";
		}

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
	ZFENTRY("SimpleString","jJ",SimpleString)
	ZFENTRY("SimpleExecute","ccC",SimpleExecute)
ZFEND
