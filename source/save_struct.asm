;###############################################################################
;
;    µCity - City building game for Game Boy Color.
;    Copyright (c) 2017-2018 Antonio Niño Díaz (AntonioND/SkyLyrac)
;
;    This program is free software: you can redistribute it and/or modify
;    it under the terms of the GNU General Public License as published by
;    the Free Software Foundation, either version 3 of the License, or
;    (at your option) any later version.
;
;    This program is distributed in the hope that it will be useful,
;    but WITHOUT ANY WARRANTY; without even the implied warranty of
;    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;    GNU General Public License for more details.
;
;    You should have received a copy of the GNU General Public License
;    along with this program.  If not, see <http://www.gnu.org/licenses/>.
;
;    Contact: antonio_nd@outlook.com
;
;###############################################################################

    INCLUDE "hardware.inc"

;-------------------------------------------------------------------------------

    INCLUDE "money.inc"
    INCLUDE "room_graphs.inc"
    INCLUDE "room_text_input.inc"
    INCLUDE "save_struct.inc"
    INCLUDE "text_messages.inc"

;###############################################################################

    SECTION "Save Data General", SRAM[_SRAM]

;-------------------------------------------------------------------------------

; Save Integrity info

SAV_BANK_NUMBER:: DS 1
SAV_MAGIC_STRING:: DS MAGIC_STRING_LEN
SAV_CHECKSUM::     DS 2 ; LSB first
SAV_CHECKSUM_END::

; Each SRAM bank can hold information for one city.

SAV_CITY_NAME:: DS TEXT_INPUT_LENGTH

SAV_YEAR::  DS 2 ; LSB first
SAV_MONTH:: DS 1

SAV_LAST_SCROLL_X:: DS 1 ; Scroll when saving the game
SAV_LAST_SCROLL_Y:: DS 1

SAV_MONEY:: DS MONEY_AMOUNT_SIZE

SAV_TAX_PERCENT:: DS 1

SAV_TECHNOLOGY_LEVEL:: DS 1

SAV_PERSISTENT_MSG:: DS BYTES_SAVE_PERSISTENT_MSG

SAV_LOAN_REMAINING_PAYMENTS:: DS 1 ; 0 if no remaining payments (no loan)
SAV_LOAN_PAYMENTS_AMOUNT::    DS 2 ; BCD, LSB first

SAV_NEGATIVE_BUDGET_COUNT:: DS 1

;-------------------------------------------------------------------------------

    SECTION "Save Data Configuration", SRAM[_SRAM+$200]

;-------------------------------------------------------------------------------

SAV_OPTIONS_DISASTERS_DISABLED::  DS 1
SAV_OPTIONS_ANIMATIONS_DISABLED:: DS 1
SAV_OPTIONS_MUSIC_DISABLED::      DS 1

;-------------------------------------------------------------------------------

    SECTION "Save Data Historical Information", SRAM[_SRAM+$400]

;-------------------------------------------------------------------------------

SAV_GRAPH_POPULATION_DATA::   DS GRAPH_SIZE
SAV_GRAPH_POPULATION_OFFSET:: DS 1 ; Circular buffer start index
SAV_GRAPH_POPULATION_SCALE::  DS 1

SAV_GRAPH_RESIDENTIAL_DATA::   DS GRAPH_SIZE
SAV_GRAPH_RESIDENTIAL_OFFSET:: DS 1 ; Circular buffer start index
SAV_GRAPH_RESIDENTIAL_SCALE::  DS 1

SAV_GRAPH_COMMERCIAL_DATA::   DS GRAPH_SIZE
SAV_GRAPH_COMMERCIAL_OFFSET:: DS 1 ; Circular buffer start index
SAV_GRAPH_COMMERCIAL_SCALE::  DS 1

SAV_GRAPH_INDUSTRIAL_DATA::   DS GRAPH_SIZE
SAV_GRAPH_INDUSTRIAL_OFFSET:: DS 1 ; Circular buffer start index
SAV_GRAPH_INDUSTRIAL_SCALE::  DS 1

SAV_GRAPH_MONEY_DATA::   DS GRAPH_SIZE
SAV_GRAPH_MONEY_OFFSET:: DS 1 ; Circular buffer start index
SAV_GRAPH_MONEY_SCALE::  DS 1

;-------------------------------------------------------------------------------

    SECTION "Save Data Map Attr", SRAM[_SRAM+$E00]

;-------------------------------------------------------------------------------

SAV_MAP_ATTR_BASE::  DS $1000/8 ; compressed, only the bank 0/1 bit is saved

;-------------------------------------------------------------------------------

    SECTION "Save Data Map", SRAM[_SRAM+$1000]

;-------------------------------------------------------------------------------

SAV_MAP_TILE_BASE:: DS $1000 ; Aligned to $1000

;###############################################################################
