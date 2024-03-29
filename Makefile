.SUFFIXES:
ifeq ($(strip $(PSL1GHT)),)
$(error "PSL1GHT must be set in the environment.")
endif

include $(PSL1GHT)/ppu_rules

TARGET		:=	$(notdir $(CURDIR))
BUILD		:=	build
SOURCE		:=	src scetool tre/lib cJSON
INCLUDE		:=	inc
DATA		:=	data
LIBS		:=	-l:libSDL2.a -lio -laudio -lrt -llv2 -lsysutil -lgcm_sys -lrsx -lm -lhttp -lsysmodule -lssl -lnet -lhttputil -l:libz.a

TITLE		:=	Refresher PS3
APPID		:=	REFRESHER
CONTENTID	:=	UP0001-$(APPID)_00-0000000000000000
PKGFILES	:=	release

CFLAGS		+= -O2 -Wall -std=gnu99 $(LIBPSL1GHT_INC) $(LIBPSL1GHT_LIB) -I$(PORTLIBS)/include -L$(PORTLIBS)/lib -I$(CURDIR)/../tre/local_includes -I$(CURDIR)/../cJSON
CXXFLAGS	+= -O2 -Wall -Wno-write-strings -Wno-format -Itre/local_includes

LIBPATHS	:= -L$(PORTLIBS)/lib

ifneq ($(BUILD),$(notdir $(CURDIR)))

export OUTPUT	:=	$(CURDIR)/$(TARGET)
export VPATH	:=	$(foreach dir,$(SOURCE),$(CURDIR)/$(dir)) \
					$(foreach dir,$(DATA),$(CURDIR)/$(dir))
export BUILDDIR	:=	$(CURDIR)/$(BUILD)
export DEPSDIR	:=	$(BUILDDIR)

CFILES		:= $(foreach dir,$(SOURCE),$(notdir $(wildcard $(dir)/*.c)))
CXXFILES	:= $(foreach dir,$(SOURCE),$(notdir $(wildcard $(dir)/*.cpp)))				
SFILES		:= $(foreach dir,$(SOURCE),$(notdir $(wildcard $(dir)/*.S)))
BINFILES	:= $(foreach dir,$(DATA),$(notdir $(wildcard $(dir)/*.bin)))
VCGFILES	:= $(foreach dir,$(SOURCE),$(notdir $(wildcard $(dir)/*.vcg)))

# Filter out test.c from cJSON, as it tries to define main()
CFILES := $(filter-out test.c, $(CFILES))

ifeq ($(strip $(CXXFILES)),)
export LD	:=	$(CC)
else
export LD	:=	$(CXX)
endif

export OFILES	:=	$(CFILES:.c=.o) \
					$(CXXFILES:.cpp=.o) \
					$(SFILES:.S=.o) \
					$(VCGFILES:.vcg=.vcg.o) \
					$(BINFILES:.bin=.bin.o)

export BINFILES	:=	$(BINFILES:.bin=.bin.h)

export INCLUDES	:=	$(foreach dir,$(INCLUDE),-I$(CURDIR)/$(dir)) \
					-I$(CURDIR)/$(BUILD) \
					
.PHONY: $(BUILD) clean pkg run

$(BUILD):
	@[ -d $@ ] || mkdir -p $@
	@$(MAKE) --no-print-directory -C $(BUILD) -f $(CURDIR)/Makefile

clean: 
	@echo "[RM]  $(notdir $(OUTPUT))"
	@rm -rf $(BUILD) $(OUTPUT).elf $(OUTPUT).self $(OUTPUT).a $(OUTPUT)*.pkg

rpcs3: $(BUILD)
	rpcs3 $(OUTPUT).self
	# rpcs3 --no-gui $(OUTPUT).self

run: $(BUILD)
	@$(PS3LOADAPP) $(OUTPUT).self

pkg: $(BUILD) $(OUTPUT).pkg

else

DEPENDS	:= $(OFILES:.o=.d)

$(OUTPUT).self: $(OUTPUT).elf
$(OUTPUT).elf: $(OFILES)
$(OFILES): $(BINFILES)

-include $(DEPENDS)

endif