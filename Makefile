#					
# Makefile for Silk SDK			
#
# Copyright (c) 2009, Skype Limited
# All rights reserved.
#

#Platform detection and settings

BUILD_OS := $(shell uname | sed -e 's/^.*Darwin.*/MacOS-X/ ; s/^.*CYGWIN.*/Windows/')

BUILD_ARCHITECTURE := $(shell uname -m | sed -e 's/i686/i386/')

EXESUFFIX = 
LIBPREFIX = lib
LIBSUFFIX = .a
OBJSUFFIX = .o

# sudo xcode-select -switch /Developer
# sudo xcode-select -switch /Applications/Xcode.app/Contents/Developer

XCODE_SDK_NAME ?= iphoneos
XCODE_SDK ?= $(shell xcodebuild -version -sdk ${XCODE_SDK_NAME} Path)
ARCH ?= armv7

#CFLAGS += -g -arch armv7 -mthumb -isysroot ${XCODE_SDK}
#CFLAGS += -g -arch armv7s -isysroot ${XCODE_SDK}
CFLAGS += -g -arch ${ARCH} -fPIC
#LDFLAGS += -Wl,-no_pie -arch armv7 -mthumb -isysroot ${XCODE_SDK}
#LDFLAGS += -Wl,-no_pie -arch armv7s -isysroot ${XCODE_SDK}
CFLAGS += -isysroot ${XCODE_SDK}
ifneq (iphonesimulator,$(XCODE_SDK_NAME))
	LDFLAGS += -Wl,-pie -arch ${ARCH} -isysroot ${XCODE_SDK}
	USE_NEON=yes
else
	LDFLAGS += -Wl,-pie -arch ${ARCH}
	USE_NEON=no
endif

# CC     = `xcrun -sdk ${IPHONE_SDK} -find gcc-4.2`
# CXX    = `xcrun -sdk ${IPHONE_SDK} -find g++-4.2`
CC     = $(shell xcrun -sdk ${XCODE_SDK} -find clang)
CXX    = $(shell xcrun -sdk ${XCODE_SDK} -find clang++)
AR     = $(shell xcrun -sdk ${XCODE_SDK} -find ar)
RANLIB = $(shell xcrun -sdk ${XCODE_SDK} -find ranlib)
LIPO   = $(shell xcrun -sdk ${XCODE_SDK} -find lipo)
CP     = $(TOOLCHAIN_PREFIX)cp

cppflags-from-defines 	= $(addprefix -D,$(1))
cppflags-from-includes 	= $(addprefix -I,$(1))
ldflags-from-ldlibdirs 	= $(addprefix -L,$(1))
ldlibs-from-libs 		= $(addprefix -l,$(1))

ifneq (,$(TARGET_CPU))
	CFLAGS	+= -mcpu=$(TARGET_CPU)
	ifneq (,$(TARGET_TUNE))
		CFLAGS	+= -mtune=$(TARGET_TUNE)
	else
		CFLAGS	+= -mtune=$(TARGET_CPU)
	endif
endif
ifneq (,$(TARGET_FPU))
	CFLAGS += -mfpu=$(TARGET_FPU)
endif
ifneq (,$(TARGET_ARCH))
	CFLAGS	+= -march=$(TARGET_ARCH)
endif
# Helper to make NEON testing easier, when using USE_NEON=yes do not set TARGET_CPU or TARGET_FPU
ifeq (yes,$(USE_NEON))
	#CFLAGS += -mcpu=cortex-a8 -mfloat-abi=softfp -mfpu=neon
	CFLAGS += -mfloat-abi=softfp
endif


#CFLAGS	+= -Wall -enable-threads -O3 -flto
CFLAGS	+= -Wall -O3 

CFLAGS  += $(call cppflags-from-defines,$(CDEFINES))
CFLAGS  += $(call cppflags-from-defines,$(ADDED_DEFINES))
CFLAGS  += $(call cppflags-from-includes,$(CINCLUDES))
LDFLAGS += $(call ldflags-from-ldlibdirs,$(LDLIBDIRS))
LDLIBS  += $(call ldlibs-from-libs,$(LIBS))

COMPILE.c.cmdline   = $(CC) -c $(CFLAGS) $(ADDED_CFLAGS) -o $@ $<
COMPILE.S.cmdline   = $(CC) -c $(CFLAGS) $(ADDED_CFLAGS) -o $@ $<
COMPILE.cpp.cmdline = $(CXX) -c $(CFLAGS) $(ADDED_CFLAGS) -o $@ $<
LINK.o              = $(CXX) $(LDPREFLAGS) $(LDFLAGS)
LINK.o.cmdline      = $(LINK.o) $^ $(LDLIBS) -o $@$(EXESUFFIX) 
ARCHIVE.cmdline     = $(AR) $(ARFLAGS) $@ $^ && $(RANLIB) $@

%$(OBJSUFFIX):%.c
	$(COMPILE.c.cmdline)

%$(OBJSUFFIX):%.cpp
	$(COMPILE.cpp.cmdline)
	
%$(OBJSUFFIX):%.S
	$(COMPILE.S.cmdline)	

# Directives

CINCLUDES += interface src test

# VPATH e.g. VPATH = src:../headers
VPATH = ./ \
        interface \
        src \
        test 

# Variable definitions
LIB_NAME = SKP_SILK_SDK
TARGET = $(LIBPREFIX)$(LIB_NAME)$(LIBSUFFIX)
TARGETarmv7 = $(LIBPREFIX)$(LIB_NAME)-armv7$(LIBSUFFIX)
TARGETarmv7s = $(LIBPREFIX)$(LIB_NAME)-armv7s$(LIBSUFFIX)
TARGETarm64 = $(LIBPREFIX)$(LIB_NAME)-arm64$(LIBSUFFIX)
TARGETi386 = $(LIBPREFIX)$(LIB_NAME)-i386$(LIBSUFFIX)
TARGETx86_64 = $(LIBPREFIX)$(LIB_NAME)-x86_64$(LIBSUFFIX)

SRCS_C = $(wildcard src/*.c) 
#ifneq (,$(TOOLCHAIN_PREFIX))
	SRCS_S = $(wildcard src/*.S)
	OBJS := $(patsubst %.c,%$(OBJSUFFIX),$(SRCS_C)) $(patsubst %.S,%$(OBJSUFFIX),$(SRCS_S))
#else
#	OBJS := $(patsubst %.c,%$(OBJSUFFIX),$(SRCS_C))
#endif

ENCODER_SRCS_C = test/Encoder.c
ENCODER_OBJS := $(patsubst %.c,%$(OBJSUFFIX),$(ENCODER_SRCS_C))

DECODER_SRCS_C = test/Decoder.c
DECODER_OBJS := $(patsubst %.c,%$(OBJSUFFIX),$(DECODER_SRCS_C))

SIGNALCMP_SRCS_C = test/signalCompare.c
SIGNALCMP_OBJS := $(patsubst %.c,%$(OBJSUFFIX),$(SIGNALCMP_SRCS_C))

LIBS = \
	$(LIB_NAME)

LDLIBDIRS = ./

# Rules
default: all

all: $(TARGET) encoder decoder signalcompare

fat:
	XCODE_SDK_NAME=iphoneos ARCH=armv7 $(MAKE) $(MAKEFLAGS) -B all
	mv $(TARGET) $(TARGETarmv7)
	XCODE_SDK_NAME=iphoneos ARCH=armv7s $(MAKE) $(MAKEFLAGS) -B all
	mv $(TARGET) $(TARGETarmv7s)
	XCODE_SDK_NAME=iphoneos ARCH=arm64 $(MAKE) $(MAKEFLAGS) -B all
	mv $(TARGET) $(TARGETarm64)
	XCODE_SDK_NAME=iphonesimulator ARCH=i386 $(MAKE) $(MAKEFLAGS) -B all
	mv $(TARGET) $(TARGETi386)
	XCODE_SDK_NAME=iphonesimulator ARCH=x86_64 $(MAKE) $(MAKEFLAGS) -B all
	mv $(TARGET) $(TARGETx86_64)
	$(LIPO) -create $(TARGETarmv7) $(TARGETarmv7s) $(TARGETarm64) \
			$(TARGETi386) $(TARGETx86_64) -output $(TARGET)

lib: $(TARGET)

$(TARGET): $(OBJS)
	$(ARCHIVE.cmdline)

encoder$(EXESUFFIX): $(ENCODER_OBJS)	
	$(LINK.o.cmdline)

decoder$(EXESUFFIX): $(DECODER_OBJS)	
	$(LINK.o.cmdline)

signalcompare$(EXESUFFIX): $(SIGNALCMP_OBJS)	
	$(LINK.o.cmdline)

clean:
	$(RM) $(TARGET)* $(OBJS) $(ENCODER_OBJS) $(DECODER_OBJS) \
		  $(SIGNALCMP_OBJS) $(TEST_OBJS) \
		  encoder$(EXESUFFIX) decoder$(EXESUFFIX) signalcompare$(EXESUFFIX)

.PHONY: fat
