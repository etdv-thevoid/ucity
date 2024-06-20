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
INCLUDE "engine.inc"

;-------------------------------------------------------------------------------

INCLUDE "room_game.inc"
INCLUDE "room_graphs.inc"

;###############################################################################

SECTION "Room Graphs Variables",WRAM0

;-------------------------------------------------------------------------------

graphs_room_exit: DS 1 ; set to 1 to exit room

graphs_selected: DS 1

;###############################################################################

SECTION "Room Graphs Functions",ROMX

;-------------------------------------------------------------------------------

GraphsDrawSelected::

    ; Not needed to clear first, the drawing functions draw over everything

    ld      a,[graphs_selected]

    cp      a,GRAPHS_SELECTION_POPULATION
    jr      nz,.not_population
        LONG_CALL   GraphDrawTotalPopulation
        ret
.not_population:
    cp      a,GRAPHS_SELECTION_RCI
    jr      nz,.not_rci
        LONG_CALL   GraphDrawRCI
        ret
.not_rci:
    cp      a,GRAPHS_SELECTION_MONEY
    jr      nz,.not_money
        LONG_CALL   GraphDrawMoney
        ret
.not_money:

    ld      b,b ; Not found!
    call    MinimapSetDefaultPalette
    LONG_CALL   APA_BufferClear
    call    APA_BufferUpdate

    ret

;-------------------------------------------------------------------------------

MACRO WRITE_B_TO_HL_VRAM ; Clobbers A and C
    di ; critical section
        xor     a,a
        ldh     [rVBK],a
        WAIT_SCREEN_BLANK ; Clobbers registers A and C
        ld      [hl],b
    ei ; end of critical section
ENDM

;-------------------------------------------------------------------------------

GraphsUpdateLeftArrow:

    push hl
    push bc

    ld      a,[graphs_selected]
    cp      a,GRAPHS_SELECTION_MIN
    jr      nz,.not_leftmost

    ; Remove the left arrow
    ld      hl,$9940
    ld      b,0
    WRITE_B_TO_HL_VRAM ; clobbers A and C
    jr      .continue

.not_leftmost

    ; Restore the left arrow
    ld      hl,$9940
    ld      b,6
    WRITE_B_TO_HL_VRAM ; clobbers A and C

.continue

    pop hl
    pop bc

    ret

;-------------------------------------------------------------------------------

GraphsUpdateRightArrow:

    push hl
    push bc

    ld      a,[graphs_selected]
    cp      a,GRAPHS_SELECTION_MAX
    jr      nz,.not_rightmost

    ; Remove the right arrow
    ld      hl,$9953
    ld      b,0
    WRITE_B_TO_HL_VRAM ; clobbers A and C
    jr      .continue

.not_rightmost

    ; Restore the right arrow
    ld      hl,$9953
    ld      b,4
    WRITE_B_TO_HL_VRAM ; clobbers A and C

.continue

    pop hl
    pop bc

    ret

;-------------------------------------------------------------------------------

GraphsSelectGraph:: ; b = graph to select

    ld      a,b
    ld      [graphs_selected],a

    call    GraphsUpdateLeftArrow
    call    GraphsUpdateRightArrow

    ret

;-------------------------------------------------------------------------------

InputHandleGraphs:

    LONG_CALL_ARGS  GraphsMenuHandleInput ; If it returns 1, exit room
    and     a,a
    ret     z ; don't exit

    ; Exit
    ld      a,1
    ld      [graphs_room_exit],a
    ret

;-------------------------------------------------------------------------------

RoomGraphs::

    call    SetPalettesAllBlack

    LONG_CALL   GraphsMenuReset

    ld      bc,RoomGraphsVBLHandler
    call    irq_set_VBL

    xor     a,a
    ldh     [rSCX],a
    ldh     [rSCY],a

    ld      a,LCDCF_BG9800|LCDCF_OBJON|LCDCF_BG8800|LCDCF_ON
    ldh     [rLCDC],a

    ld      b,1 ; bank at 8800h
    call    LoadText

    LONG_CALL   RoomMinimapLoadBG ; Same graphics as minimap room

    call    LoadTextPalette

    ld      b,GRAPHS_SELECTION_POPULATION
    call    GraphsSelectGraph

    LONG_CALL   GraphsDrawSelected

    ; This can be loaded after the rest, it isn't shown until A is pressed
    ; so there is no hurry.
    LONG_CALL   GraphsMenuLoadGFX

    xor     a,a
    ld      [graphs_room_exit],a

.loop:

    call    wait_vbl

    call    scan_keys
    call    KeyAutorepeatHandle

    call    InputHandleGraphs

    ld      a,[graphs_room_exit]
    and     a,a
    jr      z,.loop

    call    SetDefaultVBLHandler

    call    WaitReleasedAllKeys

    call    SetPalettesAllBlack

    ret

;###############################################################################

SECTION "Room Graphs Code Bank 0",ROM0

;-------------------------------------------------------------------------------

RoomGraphsVBLHandler:

    call    GraphsMenuVBLHandler

    call    refresh_OAM

    call    SFX_Handler

    call    rom_bank_push
    call    gbt_update
    call    rom_bank_pop

    ret

;###############################################################################
