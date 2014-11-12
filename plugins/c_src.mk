# Copyright (c) 2014, Loïc Hoguin <essen@ninenines.eu>
# This file is part of erlang.mk and subject to the terms of the ISC License.


# This plugin compiles c and c++ sources into shared libraries.
# It operates in one of several modes depending on variable defs and the presence of files.
# The modes are:
#
# 1. No automatic compilation.  If NO_AUTO_C_SRC is defined, all automatic compilation is disabled.
# 2. Makefile mode.  If C_SRC_DIR/Makefile is present, use that to build the shared library.
# 3. Automatic mode. If there are c and/or c++ sources in C_SRC_DIR, compile them into a shared library
# 4. None of the above mode.  If none of the above applies, nothing is done.  This makes the plugin
#    safe to include on projects that have no c/c++ sources.
#
# If the variable NEED_C_SRC_ENV is defined then the file env.mk will be generated.  This file
# defines the variable ERTS_INCLUDE_DIR that is useful for building erlang libraries.  It is
# automatically generated for 2 and 3 above and can be manually specified for other cases.
#


C_SRC_DIR ?= $(CURDIR)/c_src


# Mode 1. do nothing if NO_AUTO_C_SRC is defined
ifdef NO_AUTO_C_SRC

# Mode 2. use custom makefile in c_src if available
else ifeq ($(notdir($(C_SRC_DIR)/Makefile)),Makefile)

NEED_C_SRC_ENV := 1
app::
	$(MAKE) -C $(C_SRC_DIR)
clean::
	$(MAKE) -C $(C_SRC_DIR) clean


# Maybe mode 3.  Check for sources
else

C_SRCS = $(wildcard $(C_SRC_DIR)/*.c)
CPP_SRCS = $(wildcard $(C_SRC_DIR)/*.cpp $(C_SRC_DIR)/*.cc $(C_SRC_DIR)/*.C)

# Mode 3.  Automatic build if sources are present
ifneq ($(C_SRCS)$(CPP_SRCS),)

NEED_C_SRC_ENV := 1

C_SRC_OUTPUT ?= $(CURDIR)/priv/$(PROJECT).so

# Collect objects
CPP_OBJS = $(addsuffix .o, $(basename $(CPP_SRCS)))
C_OBJS = $(C_SRCS:.c=.o)

# System type and C compiler/flags.

UNAME_SYS := $(shell uname -s)
ifeq ($(UNAME_SYS), Darwin)
	CC ?= cc
	CFLAGS ?= -O3 -std=c99 -arch x86_64 -flat_namespace -undefined suppress -finline-functions -Wall -Wmissing-prototypes
	CXX ?= c++
	CXXFLAGS ?= -O3 -arch x86_64 -flat_namespace -undefined suppress -finline-functions -Wall
else ifeq ($(UNAME_SYS), FreeBSD)
	CC ?= cc
	CFLAGS ?= -O3 -std=c99 -finline-functions -Wall -Wmissing-prototypes
	CXX ?= c++
	CXXFLAGS ?= -O3 -finline-functions -Wall
else ifeq ($(UNAME_SYS), Linux)
	CC ?= gcc
	CFLAGS ?= -O3 -std=c99 -finline-functions -Wall -Wmissing-prototypes
	CXX ?= g++
	CXXFLAGS ?= -O3 -finline-functions -Wall
endif

# Linker.  Use c++ linker if there are any c++ sources.
ifeq ($(CPP_OBJS),)
	LDCC ?= $(CC)
else
	LDCC ?= $(CXX)
endif

# Verbosity.
cc_verbose_0  = @echo " CC    " $(notdir $<);
cxx_verbose_0 = @echo " CXX   " $(notdir $<);
ld_verbose_0  = @echo " LD    " $(notdir $@);
cc_verbose  = $(cc_verbose_$(V))
cxx_verbose = $(cxx_verbose_$(V))
ld_verbose  = $(ld_verbose_$(V))

app:: $(C_SRC_OUTPUT)

$(C_SRC_OUTPUT): $(C_OBJS) $(CPP_OBJS)
	@mkdir -p $(dir $@)
	$(ld_verbose) $(LDCC) $(LDFLAGS) $(LDLIBS) -shared -o $@ $^

%.o: %.c
	$(cc_verbose) $(CC) $(CPPFLAGS) $(CFLAGS) -c -o $@ $<
%.o: %.cpp
	$(cxx_verbose) $(CXX) $(CPPFLAGS) $(CXXFLAGS) -c -o $@ $<
%.o: %.cc
	$(cxx_verbose) $(CXX) $(CPPFLAGS) $(CXXFLAGS) -c -o $@ $<
%.o: %.C
	$(cxx_verbose) $(CXX) $(CPPFLAGS) $(CXXFLAGS) -c -o $@ $<

clean:: clean-c_src
.PHONY: clean-c_src
clean-c_src:
	$(gen_verbose) rm -f $(C_SRC_OUTPUT) $(C_OBJS) $(CPP_OBJS)

endif # Mode 3

else # Mode 4.  Nothing to compile.

endif # End of modes


ifdef NEED_C_SRC_ENV
# generate and include env.mk

C_SRC_ENV ?= env.mk

$(C_SRC_ENV):
	$(gen_verbose) erl -noshell -noinput -eval "file:write_file(\"$(C_SRC_ENV)\", \
		io_lib:format(\"ERTS_INCLUDE_DIR ?= ~s/erts-~s/include/\", \
			[code:root_dir(), erlang:system_info(version)])), \
		init:stop()."

app:: $(C_SRC_ENV)
clean:: clean-c_env

-include $(C_SRC_ENV)

clean-c_env:
	$(gen_verbose) rm -f $(C_SRC_ENV)


CFLAGS += -I$(ERTS_INCLUDE_DIR) -fPIC
CXXFLAGS += -I$(ERTS_INCLUDE_DIR) -fPIC


endif
