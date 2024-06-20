################################################################################
#
#    µCity - City building game for Game Boy Color.
#    Copyright (c) 2017-2019 Antonio Niño Díaz (AntonioND/SkyLyrac)
#
#    This program is free software: you can redistribute it and/or modify
#    it under the terms of the GNU General Public License as published by
#    the Free Software Foundation, either version 3 of the License, or
#    (at your option) any later version.
#
#    This program is distributed in the hope that it will be useful,
#    but WITHOUT ANY WARRANTY; without even the implied warranty of
#    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#    GNU General Public License for more details.
#
#    You should have received a copy of the GNU General Public License
#    along with this program.  If not, see <http://www.gnu.org/licenses/>.
#
################################################################################
##                                ROM Name                                    ##

NAME := ucity

BIN := $(NAME).gbc
SAV := $(NAME).sav
SYM := $(NAME).sym
MAP := $(NAME).map

################################################################################
## RGBDS can be made to point at a specific folder with the binaries of RGBDS ##

RGBDS ?=

RGBASM  := $(RGBDS)rgbasm
RGBLINK := $(RGBDS)rgblink
RGBFIX  := $(RGBDS)rgbfix
RGBGFX  := $(RGBDS)rgbgfx

################################################################################
##               Command to run resulting ROM in an emulator                  ##

ifneq (,$(shell which bgb))
EMU ?= bgb
else ifneq (,$(shell which gambatte))
EMU ?= gambatte
else ifneq (,$(shell which sameboy))
EMU ?= sameboy
else ifneq (,$(shell which mgba))
EMU ?= mgba
else
EMU ?=
endif

################################################################################
##                All source folders - subfolders are included                ##

SOURCE := source assets audio images includes tools

################################################################################
##                              Build Object Paths                            ##

# List of relative paths to all folders and subfolders with code or data.
SOURCE_ALL_DIRS := $(sort $(shell find $(SOURCE) -type d -print))

# List of include directories; '/' is appended to the path.
INCLUDES := $(foreach dir,$(SOURCE_ALL_DIRS),-I$(dir)/)

# All files with extension .asm
ASM_FILES := $(foreach dir,$(SOURCE_ALL_DIRS),$(sort $(wildcard $(dir)/*.asm)))

# All files with extension .tilemap
SCENARIO_TILEMAP_FILES := $(foreach dir,$(SOURCE_ALL_DIRS),$(sort $(wildcard $(dir)/scenario*.tilemap)))

# All files with extension .attrmap
SCENARIO_ATTRMAP_FILES := $(foreach dir,$(SOURCE_ALL_DIRS),$(sort $(wildcard $(dir)/scenario*.attrmap)))

# All files with extension .png
PNG_FILES := $(foreach dir,$(SOURCE_ALL_DIRS),$(sort $(wildcard $(dir)/*.png)))

# All files with extension .c
TOOL_FILES := $(foreach dir,$(SOURCE_ALL_DIRS),$(sort $(wildcard $(dir)/*.c)))

################################################################################
##                              Build Object Lists                            ##

# Prepare .o paths from source files
TOOLS := $(TOOL_FILES:.c=.o)

# Prepare object paths from source files
OBJ := $(ASM_FILES:.asm=.obj)

# Prepare .rle paths from source files
RLE := $(SCENARIO_TILEMAP_FILES:.tilemap=_tilemap.rle)
RLE += $(SCENARIO_ATTRMAP_FILES:.attrmap=_attrmap.rle)

# Prepare .2bpp paths from source files
GFX := $(PNG_FILES:.png=.2bpp)

################################################################################
##                                Make Targets                                ##

.PHONY : all rom tools tidy clean run

all: tools rom

rom: $(BIN)

tools: $(TOOLS)

tidy: 
	@rm -f $(GFX) $(RLE) $(OBJ)

clean: tidy
	@rm -f $(TOOLS) $(BIN) $(SAV) $(SYM) $(MAP) 

run: rom
	$(EMU) $(BIN)

################################################################################

TOOLS_OPTS :=

%/gen_build_prob.o: TOOLS_OPTS += -lm
%/gen_circle.o: TOOLS_OPTS += -lm
%/gen_mask.o: TOOLS_OPTS += -lm

%.o: %.c
	gcc $< -o $@ $(TOOLS_OPTS)

################################################################################

GFX_OPTS :=

%/build_select_sprites.2bpp: GFX_OPTS += -x 4
%/graphs_menu_tiles.2bpp: GFX_OPTS += -x 3
%/minimap_menu_tiles.2bpp: GFX_OPTS += -x 3
%/text_tiles.2bpp: GFX_OPTS += -x 2

%.2bpp: %.png
	$(RGBGFX) $< -o $@ $(GFX_OPTS)

################################################################################

RLE_OPTS :=

%_tilemap.rle: %.tilemap
	@echo cp -f $< $@
	@cp -f $< $@
	@echo filediff.o $@
	@./tools/compress/filediff.o $@ $@
	@echo rle.o -e $@
	@./tools/compress/rle.o -e $@

%_attrmap.rle: %.attrmap
	@cp -f $< $@
	@echo extractbit3.o $@
	@./tools/compress/extractbit3.o $@ $@
	@echo filediff.o $@
	@./tools/compress/filediff.o $@ $@
	@echo rle.o -e $@
	@./tools/compress/rle.o -e $@

################################################################################

# TODO: Remove the -h when RGBASM is updated to remove it
OBJ_OPTS := -h -E -Wextra

%.obj: %.asm
	@echo rgbasm $< $(OBJ_OPTS) -o $@
	@$(RGBASM) $< $(INCLUDES) $(OBJ_OPTS) -o $@

################################################################################

PAD := 0xFF
LINK_OPTS := -p $(PAD) -m $(MAP) -n $(SYM)
FIX_OPTS := -p $(PAD) -v

$(BIN): $(GFX) $(RLE) $(OBJ)
	@echo rgblink $(LINK_OPTS) -o $(BIN)
	@$(RGBLINK) $(LINK_OPTS) -o $(BIN) $(OBJ)
	$(RGBFIX) $(FIX_OPTS) $(BIN)

################################################################################
