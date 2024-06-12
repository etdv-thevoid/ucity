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
##                                ROM name                                    ##

NAME := ucity
EXT  := gbc

################################################################################
##               Command to run resulting ROM in an emulator                  ##

EMULATOR := wine ./tools/bgb.exe

################################################################################
##                All source folders - subfolders are included                ##

SOURCE := source audio bin images includes

################################################################################
## RGBDS can be made to point at a specific folder with the binaries of RGBDS ##

RGBASM  := $(RGBDS)rgbasm
RGBLINK := $(RGBDS)rgblink
RGBFIX  := $(RGBDS)rgbfix
RGBGFX  := $(RGBDS)rgbgfx

################################################################################

BIN := $(NAME).$(EXT)
COMPAT_BIN := $(NAME)_compat.$(EXT)

# List of relative paths to all folders and subfolders with code or data.
SOURCE_ALL_DIRS := $(sort $(shell find $(SOURCE) -type d -print))

# List of include directories: All source and data folders.
# A '/' is appended to the path.
INCLUDES := $(foreach dir,$(SOURCE_ALL_DIRS),-I$(dir)/)

# All files with extension asm are assembled.
ASMFILES := $(foreach dir,$(SOURCE_ALL_DIRS),$(sort $(wildcard $(dir)/*.asm)))

# Prepare object paths from source files.
OBJ := $(ASMFILES:.asm=.obj)

# All files with extension png are converted.
PNGFILES := $(foreach dir,$(SOURCE_ALL_DIRS),$(sort $(wildcard $(dir)/*.png)))

# Prepare 2bpp paths from source files.
2BPP := $(PNGFILES:.png=.2bpp)

################################################################################
##                                Make Targets                                ##

.PHONY : all rebuild clean run

all: $(BIN) $(COMPAT_BIN)

rebuild:
	@make -B
	@rm -f $(2BPP) $(OBJ)

run: $(BIN)
	$(EMULATOR) $(BIN)

clean:
	@echo rm $(2BPP) $(OBJ) $(BIN) $(COMPAT_BIN) $(NAME).sym $(NAME).map
	@rm -f $(2BPP) $(OBJ) $(BIN) $(COMPAT_BIN) $(NAME).sym $(NAME).map

################################################################################

images/build_select_sprites.2bpp: GFX_OPTS += -x 4
images/graphs_menu_tiles.2bpp: GFX_OPTS += -x 3
images/minimap_menu_tiles.2bpp: GFX_OPTS += -x 3
images/text_tiles.2bpp: GFX_OPTS += -x 2

%.2bpp: %.png
	@echo rgbgfx $(GFX_OPTS) $@
	@$(RGBGFX) $(GFX_OPTS) -d 2 -o $@ $<

# TODO: Remove the -h when RGBASM is updated to remove it
%.obj : %.asm
	@echo rgbasm $@
	@$(RGBASM) $(INCLUDES) -h -E -o $@ $<

################################################################################

$(BIN): $(2BPP) $(OBJ)
	@echo rgblink $(BIN)
	@$(RGBLINK) -o $(BIN) -p 0xFF -m $(NAME).map -n $(NAME).sym $(OBJ)
	@echo rgbfix $(BIN)
	@$(RGBFIX) -p 0xFF -v $(BIN)

$(COMPAT_BIN): $(2BPP) $(BIN)
	@echo rgbfix $(COMPAT_BIN)
	@cp $(BIN) $(COMPAT_BIN)
	@$(RGBFIX) -v -O -r 3 $(COMPAT_BIN)

################################################################################
