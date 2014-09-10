# Copyright (c) 2014, Loïc Hoguin <essen@ninenines.eu>
# This file is part of erlang.mk and subject to the terms of the ISC License.

.PHONY: clean-c_src
# todo

# Configuration.

C_SRC_DIR = $(CURDIR)/c_src
C_SRC_ENV ?= env.mk
C_SRC_OUTPUT ?= $(CURDIR)/priv/$(PROJECT).so

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


# generate and include env.mk

app:: $(C_SRC_ENV)

$(C_SRC_ENV):
	$(gen_verbose) erl -noshell -noinput -eval "file:write_file(\"$(C_SRC_ENV)\", \
		io_lib:format(\"ERTS_INCLUDE_DIR ?= ~s/erts-~s/include/\", \
			[code:root_dir(), erlang:system_info(version)])), \
		init:stop()."

clean:: clean-c_env

clean-c_env:
	$(gen_verbose) rm -f $(C_SRC_ENV)

-include $(C_SRC_ENV)

CFLAGS += -I$(ERTS_INCLUDE_DIR) -fPIC
CXXFLAGS += -I$(ERTS_INCLUDE_DIR) -fPIC



# Targets.

ifndef NO_AUTO_C_SRC    # if defined, disables all automatic compiling and cleaning rules

ifeq ($(wildcard $(C_SRC_DIR)/Makefile),)

# Compile shared object from all c and c++ sources in C_SRC_DIR


# Object files.

C_SRCS = $(wildcard $(C_SRC_DIR)/*.c)
C_OBJS = $(C_SRCS:.c=.o)
CPP_SRCS = $(wildcard $(C_SRC_DIR)/*.cpp $(C_SRC_DIR)/*.cc $(C_SRC_DIR)/*.C)
CPP_OBJS = $(addsuffix .o, $(basename $(CPP_SRCS)))


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
	$(ld_verbose) $(LDCC) $(LDFLAGS) -shared -o $@ $^

%.o: %.c
	$(cc_verbose) $(CC) $(CPPFLAGS) $(CFLAGS) -c -o $@ $<
%.o: %.cpp
	$(cxx_verbose) $(CXX) $(CPPFLAGS) $(CXXFLAGS) -c -o $@ $<
%.o: %.cc
	$(cxx_verbose) $(CXX) $(CPPFLAGS) $(CXXFLAGS) -c -o $@ $<
%.o: %.C
	$(cxx_verbose) $(CXX) $(CPPFLAGS) $(CXXFLAGS) -c -o $@ $<

clean:: clean-c_src

clean-c_src:
	$(gen_verbose) rm -f $(C_SRC_OUTPUT) $(C_OBJS) $(CPP_OBJS)


else  # use custom makefile in c_src
ifneq ($(wildcard $(C_SRC_DIR)),)

app::
	$(MAKE) -C $(C_SRC_DIR)

clean::
	$(MAKE) -C $(C_SRC_DIR) clean

endif
endif


endif #NO_AUTO_C_SRC
