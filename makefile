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
EXT  := gbc

################################################################################
##               Command to run resulting ROM in an emulator                  ##

ifeq (,$(shell which bgb))
EMULATOR := bgb
else ifeq (,$(shell which gambatte))
EMULATOR := gambatte
else ifeq (,$(shell which sameboy))
EMULATOR := sameboy
else ifeq (,$(shell which mgba))
EMULATOR := mgba
else
EMULATOR :=
endif

################################################################################
## RGBDS can be made to point at a specific folder with the binaries of RGBDS ##

RGBASM  := $(RGBDS)rgbasm
RGBLINK := $(RGBDS)rgblink
RGBFIX  := $(RGBDS)rgbfix
RGBGFX  := $(RGBDS)rgbgfx

################################################################################
##                All source folders - subfolders are included                ##

SOURCE := source assets audio images includes tools

################################################################################
##                                 Build Paths                                ##

# List of relative paths to all folders and subfolders with code or data.
SOURCE_ALL_DIRS := $(sort $(shell find $(SOURCE) -type d -print))

# List of include directories; '/' is appended to the path.
INCLUDES := $(foreach dir,$(SOURCE_ALL_DIRS),-I$(dir)/)

# All files with extension .asm
ASMFILES := $(foreach dir,$(SOURCE_ALL_DIRS),$(sort $(wildcard $(dir)/*.asm)))

# All files with extension .tilemap and/or .attrmap
MAPFILES := $(foreach dir,$(SOURCE_ALL_DIRS),$(sort $(wildcard $(dir)/scenario*.tilemap)))
MAPFILES += $(foreach dir,$(SOURCE_ALL_DIRS),$(sort $(wildcard $(dir)/scenario*.attrmap)))

# All files with extension .png
PNGFILES := $(foreach dir,$(SOURCE_ALL_DIRS),$(sort $(wildcard $(dir)/*.png)))

# All files with extension .c
TOOLFILES := $(foreach dir,$(SOURCE_ALL_DIRS),$(sort $(wildcard $(dir)/*.c)))

################################################################################
##                                Build Objects                               ##

BIN := $(NAME).$(EXT)

# Prepare .obj paths from source files
OBJ := $(ASMFILES:.asm=.obj)

# Prepare .rle paths from source files
RLE := $(MAPFILES:.tilemap=_tilemap.rle)
RLE += $(MAPFILES:.attrmap=_attrmap.rle)

# Prepare .*bpp paths from source files
BPP := $(PNGFILES:.png=.2bpp)

# Prepare .o paths from source files
TOOLS := $(TOOLFILES:.c=.o)

################################################################################
##                                Make Targets                                ##

.PHONY : all rom tools tidy clean run

all: tools rom

rom: $(BIN)

tools: $(TOOLS)

tidy: 
	@rm -f $(RLE) $(BPP) $(OBJ)

clean: tidy
	@rm -f $(TOOLS) $(BIN) $(NAME).sym $(NAME).map

run: rom
	$(EMULATOR) $(BIN)

################################################################################

GFX_OPTS :=

%/build_select_sprites.2bpp: GFX_OPTS += -x 4
%/graphs_menu_tiles.2bpp: GFX_OPTS += -x 3
%/minimap_menu_tiles.2bpp: GFX_OPTS += -x 3
%/text_tiles.2bpp: GFX_OPTS += -x 2

%.2bpp: %.png
	@echo rgbgfx $(GFX_OPTS) $@
	@$(RGBGFX) $(GFX_OPTS) -o $@ $<

%.1bpp: %.png
	@echo rgbgfx $(GFX_OPTS) -d 1 $@
	@$(RGBGFX) $(GFX_OPTS) -d 1 -o $@ $<

################################################################################

MAP_OPTS :=

%_tilemap.rle: %.tilemap
	@echo compress $(MAP_OPTS) $@
	@./tools/compress_map.sh $(MAP_OPTS) -o $@ $<

%_attrmap.rle: %.attrmap
	@echo compress $(MAP_OPTS) $@
	@./tools/compress_map.sh $(MAP_OPTS) -o $@ $<

################################################################################

# TODO: Remove the -h when RGBASM is updated to remove it
ASM_OPTS := -h -E

%.obj: %.asm
	@echo rgbasm $(ASM_OPTS) $@
	@$(RGBASM) $(INCLUDES) $(ASM_OPTS) -o $@ $<

################################################################################

PAD := 0xFF
LINK_OPTS := -p $(PAD) -m $(NAME).map -n $(NAME).sym
FIX_OPTS := -p $(PAD) -v

$(BIN): $(BPP) $(OBJ)
	@echo rgblink $(BIN)
	@$(RGBLINK) $(LINK_OPTS) -o $(BIN) $(OBJ)
	@echo rgbfix $(BIN)
	@$(RGBFIX) $(FIX_OPTS) $(BIN)

################################################################################
