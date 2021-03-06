PACKAGE	   ?= $(NAME)
URL		   ?= github.com/krimtonz/kz
CC          = mips64-gcc
LD          = mips64-g++
AS			= mips64-gcc -x assembler-with-cpp
OBJCOPY     = mips64-objcopy
GRC			= grc
ARMIPS      = armips
GENHOOKS	= CPPFLAGS='$(subst ','\'',$(CPPFLAGS))' ./genhooks
CFILES      = *.c
SFILES		= *.S
RESFILES	= *.png
SRCDIR		= src
OBJDIR 		= obj
BINDIR		= bin
VCDIR		= vc
HOMEBOYDIR	= homeboy
PATCHDIR	= patch/dol
KZ_VERSIONS	= NZSE NZSJ NZSJ10
VC_VERSIONS	= NARJ NARE
NAME		= kz
RESDESC		= res.json

ADDRESS     = 0x80800060
ADDRESS_LITE	= 0x806E0060
ADDRESS_LDR	= 0x80080000
ALL_CFLAGS      = -c -MMD -MP -std=gnu11 -Wall -ffunction-sections -fdata-sections -O1 -fno-reorder-blocks -mno-check-zero-division $(CFLAGS)
ALL_CPPFLAGS	= -DPACKAGE=$(PACKAGE) -DURL=$(URL) -DF3DEX_GBI_2 $(CPPFLAGS)
ALL_LDFLAGS     = -T gl-n64.ld -nostartfiles -specs=nosys.specs $(LDFLAGS)

KZ 			= $(foreach v,$(KZ_VERSIONS),kz-$(v))
KZ_LITE		= $(foreach v,$(KZ_VERSIONS),kz-lite-$(v))
LDR			= $(foreach v,$(KZ_VERSIONS),ldr-kz-$(v))
LDRLITE		= $(foreach v,$(KZ_VERSIONS),ldr-kz-lite-$(v))

KZ-FULL			= $(OBJ-kz-NZSE) $(OBJ-kz-NZSJ) $(OBJ-kz-NZSJ10)
KZ-LITE-NZSE	= $(OBJ-kz-lite-NZSE) $(ELF-kz-lite-NZSE) $(HOOKS-kz-lite-NZSE)
KZ-LITE-NZSJ	= $(OBJ-kz-lite-NZSJ) $(ELF-kz-lite-NZSJ) $(HOOKS-kz-lite-NZSJ)
KZ-LITE-NZSJ10	= $(OBJ-kz-lite-NZSJ10) $(ELF-kz-lite-NZSJ10) $(HOOKS-kz-lite-NZSJ10)
KZ-LITE			= $(KZ-LITE-NZSE) $(KZ-LITE-NZSJ) $(KZ-LITE-NZSJ10)
KZ-NZSE		= $(OBJ-kz-NZSE) $(ELF-kz-NZSE) $(HOOKS-kz-NZSE) $(KZ-LITE-NZSE)
KZ-NZSJ		= $(OBJ-kz-NZSJ) $(ELF-kz-NZSJ) $(HOOKS-kz-NZSJ) $(KZ-LITE-NZSJ)
KZ-NZSJ10	= $(OBJ-kz-NZSJ10) $(ELF-kz-NZSJ10) $(HOOKS-kz-NZSJ10) $(KZ-LITE-NZSJ10)

VC	= $(foreach v,$(VC_VERSIONS),kz-vc-$(v))

all			: $(KZ) $(KZ_LITE) $(VC)
clean       :
	rm -rf $(OBJDIR) $(BINDIR) $(PATCHDIR)
distclean 	: clean
	rm -rf build/*.z64 build/*.wad

.PHONY		: all clean distclean

define bin_template
SRCDIR-$(1)      = $(5)
OBJDIR-$(1)      = obj/$(1)
BINDIR-$(1)      = bin/$(1)
HOOKSDIR-$(1)	 = patch/$(1)
RESDIR-$(1)		 = $(6)
NAME-$(1)        = $(1)
ADDRESS-$(1)	 = $(4)
CSRC-$(1)       := $$(foreach s,$$(CFILES),$$(wildcard $$(SRCDIR-$(1))/$$(s)))
COBJ-$(1)        = $$(patsubst $$(SRCDIR-$(1))/%,$$(OBJDIR-$(1))/%.o,$$(CSRC-$(1)))
SSRC-$(1)       := $$(foreach s,$$(SFILES),$$(wildcard $$(SRCDIR-$(1))/$$(s)))
SOBJ-$(1)		 = $$(patsubst $$(SRCDIR-$(1))/%,$$(OBJDIR-$(1))/%.o,$$(SSRC-$(1)))
RESSRC-$(1)		:= $$(wildcard $$(RESDIR-$(1))/*)
RESOBJ-$(1)	     = $$(patsubst $$(RESDIR-$(1))/%,$$(OBJDIR-$(1))/%.o,$$(RESSRC-$(1)))
OBJ-$(1)		 = $$(COBJ-$(1)) $$(SOBJ-$(1)) $$(RESOBJ-$(1))
ELF-$(1)         = $$(BINDIR-$(1))/$(3).elf
BIN-$(1)         = $$(BINDIR-$(1))/$(3).bin
OUTDIR-$(1)      = $$(OBJDIR-$(1)) $$(BINDIR-$(1)) $$(HOOKSDIR-$(1))
HOOKS-$(1)		 = patch/gsc/$(1)/hooks.gsc
BUILD-$(1)		 = $(1)
CLEAN-$(1)		 = clean-$(1)
$$(ELF-$(1))		 : LDFLAGS += -Wl,--defsym,start=$$(ADDRESS-$(1))
$$(BUILD-$(1))       : $$(BIN-$(1))
$$(CLEAN-$(1))       :
	rm -rf $$(OUTDIR-$(1))

$$(COBJ-$(1))     : $$(OBJDIR-$(1))/%.o: $$(SRCDIR-$(1))/% | $$(OBJDIR-$(1))
	$(CC) $$(ALL_CPPFLAGS) $$(ALL_CFLAGS) $$< -o $$@
$$(SOBJ-$(1))		: $$(OBJDIR-$(1))/%.o: $$(SRCDIR-$(1))/% | $$(OBJDIR-$(1))
	$(AS) -c -MMD -MP $$(ALL_CPPFLAGS) $$< -o $$@
$$(RESOBJ-$(1))		: $$(OBJDIR-$(1))/%.o: $$(RESDIR-$(1))/% | $$(OBJDIR-$(1))
	$(GRC) $$< -d $(RESDESC) -o $$@
$$(ELF-$(1))      : $$(OBJ-$(1)) | $$(BINDIR-$(1))
	$(LD) $$(ALL_LDFLAGS) $$^ -o $$@
$$(BIN-$(1))      : $$(ELF-$(1)) | $$(BINDIR-$(1))
	$(OBJCOPY) -S -O binary $$< $$@
$$(OUTDIR-$(1))   :
	mkdir -p $$@
$$(HOOKS-$(1))	: $$(ELF-$(1)) $$(HOOKSDIR-$(1)) | $$(SRCDIR-$(1))/z2.h
	$$(GENHOOKS) $$< $(7) >$$@  
endef

define vc_template
VCDIR-$(1)	= $(PATCHDIR)/vc/$(1)
PATCH-$(1)	= $$(VCDIR-$(1))/$(2).gzi
BIN-$(1)	= $$(VCDIR-$(1))/$(2).bin
HOMEBOY-$(1)	= $$(VCDIR-$(1))/homeboy.bin
BUILD-$(1)	= $(1)
$$(BUILD-$(1)) : $$(HOMEBOY-$(1))

$$(PATCH-$(1))	: $$(BIN-$(1))
	cd $(VCDIR) && make ../$$@

$$(BIN-$(1))	:
	cd $(VCDIR) && make ../$$@

$$(HOMEBOY-$(1))	: $$(PATCH-$(1))
	cd $(HOMEBOYDIR) && make bin/hb-$(3)/homeboy.bin
	cp $(HOMEBOYDIR)/bin/hb-$(3)/homeboy.bin $$@
endef

$(foreach v,$(KZ_VERSIONS),$(eval $(call bin_template,kz-$(v),$(v),kz,$(ADDRESS),src,res)))
$(foreach v,$(KZ_VERSIONS),$(eval $(call bin_template,kz-lite-$(v),$(v),kz,$(ADDRESS_LITE),src,res,lite)))
$(foreach v,$(KZ_VERSIONS),$(eval $(call bin_template,ldr-kz-$(v),$(v),ldr,$(ADDRESS_LDR),ldr,ldr/res)))
$(foreach v,$(KZ_VERSIONS),$(eval $(call bin_template,ldr-kz-lite-$(v),$(v),ldr,$(ADDRESS_LDR),ldr,ldr/res)))
$(foreach v,$(VC_VERSIONS),$(eval $(call vc_template,kz-vc-$(v),kz-vc,$(v))))

$(KZ-NZSE)  	: CPPFLAGS	?=	-DZ2_VERSION=NZSE
$(KZ-NZSJ)		: CPPFLAGS	?=	-DZ2_VERSION=NZSJ
$(KZ-NZSJ10)	: CPPFLAGS	?=	-DZ2_VERSION=NZSJ10
$(KZ-FULL)		: CPPFLAGS	+=	-DKZ_VERSION=KZ_FULL
$(KZ-LITE)		: CPPFLAGS	+=	-DLITE -DKZ_VERSION=KZ_LITE