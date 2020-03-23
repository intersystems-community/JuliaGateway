#define USE_CALLIN_CHAR

#define ZF_DLL  /* Required only for dynamically linked libraries. */

#include <julia.h>
#include <cdzf.h>
#include <stdbool.h>
#include <stdio.h>

#ifdef __linux__
	#include <dlfcn.h>
#endif

#ifdef _WIN32
	// 'int64_t {aka long long int}'
	const char* int64format = "%lld";
#else
	const char* int64format = "%ld";
#endif

// Haldle for a library if we want to load it explicitly
void *libHandle = NULL;

// Pointer to incoming code to execute
char* inStream = NULL;

// Current position in incoming code to execute
int curpos = 0;

// Size of inStream pointer
int maxpos = 0;

// Initializes Python environment
// and obtains reference to the main module.
// Due to the problems with lib-dynload, sometimes library file should be loaded explicitly
// https://bugs.python.org/issue4434
// Do not use it, unless you get errors like: undefined symbol: _Py_TrueStruct and so on)
int Initialize(char *file) {
	if (jl_is_initialized() == false) {
		
		if ((file) && (!libHandle)) {
			#ifdef __linux__
				//linux code goes here
				//http://tldp.org/HOWTO/Program-Library-HOWTO/dl-libraries.html
				libHandle = dlopen(file, RTLD_LAZY |RTLD_GLOBAL);
			#endif
		}
		
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

int Execute(char* commandChar, CACHE_EXSTRP result)
{
	if (jl_is_initialized() == false) {
		Initialize(NULL);
	}

	jl_value_t *var = jl_eval_string(commandChar);

	free(commandChar);

	if (var) {
		char *str = malloc(100);

		if (jl_is_string(var)) {
			str = jl_string_ptr(var);
		} else if (jl_isa(var, jl_char_type)) {
			uint32_t ch = *(uint32_t*)var >> 24;
			sprintf(str,"%c", ch);
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
			sprintf(str, int64format, val);
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
	} else if (jl_exception_occurred()) {
		const char *str = jl_unbox_voidpointer(jl_eval_string("pointer(sprint(showerror, ccall(:jl_exception_occurred, Any, ())))"));
		int len = strlen(str);

		CACHEEXSTRKILL(result);
		if (!CACHEEXSTRNEW(result,len + 5)) {
			return ZF_FAILURE;
		}
		memcpy(result->str.ch, "\x01\x01\x01\x01\x01", 5);
		memcpy(result->str.ch + 5, str, len);   // copy to retval->str.ch

	}

	return ZF_SUCCESS;
}

// Execute simple command.
// Initializes environment if required
// Does not finalize the environment.
int SimpleString(CACHE_EXSTRP command, CACHE_EXSTRP result) {

	// Copy command text to a new pointer and add null at the end
	char* commandChar = malloc(1 + sizeof(char)*command->len);
	memcpy(commandChar, command->str.ch,  command->len);
	memcpy(commandChar + command->len, "\0", 1);
	CACHEEXSTRKILL(command);

	Execute(commandChar, result);


	return ZF_SUCCESS;
}

// Init incoming stream (inStream) to length bytes + 1
int StreamInit(int length)
{
	// Free previous stream, if any.
	if (inStream) {
		free(inStream);
		inStream = NULL;
	}

	// Allocate stream
	inStream = calloc(length + 1, sizeof(char));
	curpos = 0;
	maxpos = length;

	// Return failure if allocation failed
	if (!inStream) {
		return ZF_FAILURE;
	}

	return ZF_SUCCESS;
}

// Write piece of inStream
int StreamWrite(CACHE_EXSTRP command)
{
	// Stream should be initiate first
	if (!inStream) {
		return ZF_FAILURE;
	}

	// We want to write more bytes, then available.
	// Need to extend the pointer first
	if ((int)command->len + curpos > maxpos) {
		maxpos = (int)command->len + curpos + 1;
		char *inStreamTemp = realloc(inStream, maxpos);

		if (inStreamTemp) {
			inStream = inStreamTemp;
			memset(inStream + curpos, '0', maxpos - curpos);
		} else {
			// Reallocation failed
			return ZF_FAILURE;
		}
	}

	memcpy(inStream + curpos, command->str.ch,  command->len);
	curpos += command->len;
	return ZF_SUCCESS;
}

// Send inStream to Julia and free it
int StreamExecute(CACHE_EXSTRP result)
{
	if (!inStream) {
		return ZF_FAILURE;
	}

	memcpy(inStream + curpos, "\0", 1);

	Execute(inStream, result);

	inStream = NULL;
	curpos = 0;

	return ZF_SUCCESS;
}

ZFBEGIN
	ZFENTRY("Initialize","c",Initialize)
	ZFENTRY("Finalize","",Finalize)
	ZFENTRY("SimpleString","jJ",SimpleString)
	ZFENTRY("StreamInit","i",StreamInit)
	ZFENTRY("StreamWrite","j",StreamWrite)
	ZFENTRY("StreamExecute","J",StreamExecute)
ZFEND
