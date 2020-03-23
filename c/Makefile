CC := gcc
RM := rm
CD := cd
MAKE := make
LDFLAGS := -shared

CFLAGS += -Wall -Wextra -fpic -O3 -fno-strict-aliasing -Wno-incompatible-pointer-types

SYS := $(shell gcc -dumpmachine)

ifndef GLOBALS_HOME
	$(error Couldn't find GLOBALS_HOME)
endif

ifndef JULIA_HOME
	$(error Couldn't find JULIA_HOME)
endif

ifneq (, $(findstring linux, $(SYS)))
	SUFFIX := so
	
	INCLUDES += $(shell julia ${JULIA_HOME}/share/julia/julia-config.jl --cflags)
	LDFLAGS += $(shell julia ${JULIA_HOME}/share/julia/julia-config.jl --ldflags)
	LIBS += $(shell julia ${JULIA_HOME}/share/julia/julia-config.jl --ldlibs)
else ifneq (, $(findstring mingw, $(SYS)))
	SUFFIX := dll
	
	INCLUDES += $(shell julia ${JULIA_HOME}\share\julia\julia-config.jl --cflags)
	LDFLAGS += $(shell julia ${JULIA_HOME}\share\julia\julia-config.jl --ldflags)
	LIBS  = $(shell julia ${JULIA_HOME}\share\julia\julia-config.jl --ldlibs)
else ifneq (, $(findstring apple, $(SYS)))
	SUFFIX := dylib

	INCLUDES += $(shell julia ${JULIA_HOME}/share/julia/julia-config.jl --cflags)
	LDFLAGS += $(shell julia ${JULIA_HOME}/share/julia/julia-config.jl --ldflags)
	LIBS  = $(shell julia ${JULIA_HOME}/share/julia/julia-config.jl --ldlibs)
else 
	$(error Unsupported build platform)
endif

INCLUDES += -I${GLOBALS_HOME}/dev/cpp/include
INCLUDES += -I${GLOBALS_HOME}/dev/iris-callin/include
CFLAGS += $(INCLUDES)

.PHONY: all clean

all: iscjulia.$(SUFFIX)

iscjulia.o: iscjulia.c

iscjulia.$(SUFFIX): iscjulia.o
	$(CC) $(LDFLAGS) -o $@ $^ $(LIBS)

clean:
	$(RM) *.$(SUFFIX) *.o