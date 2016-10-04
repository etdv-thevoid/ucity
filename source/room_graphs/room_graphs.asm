;###############################################################################
;
;    BitCity - City building game for Game Boy Color.
;    Copyright (C) 2016 Antonio Nino Diaz (AntonioND/SkyLyrac)
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
        ;LONG_CALL   GraphDrawTotalPopulation - TODO
        ret
.not_population:

    ld      b,b ; Not found!
    call    MinimapSetDefaultPalette
    LONG_CALL   APA_BufferClear
    call    APA_BufferUpdate

    ret

;-------------------------------------------------------------------------------

GraphsSelectGraph:: ; b = graph to select

    ld      a,b
    ld      [graphs_selected],a

    ret

;-------------------------------------------------------------------------------

InputHandleGraphs:

    ; Exit if  B or START are pressed
    ld      a,[joy_pressed]
    and     a,PAD_B|PAD_START
    jr      z,.end_b_start
        ld      a,1
        ld      [graphs_room_exit],a ; exit
        ret
.end_b_start:

    ret ; don't exit

;-------------------------------------------------------------------------------

RoomGraphs::

    call    SetPalettesAllBlack

    ld      bc,RoomGraphsVBLHandler
    call    irq_set_VBL

    xor     a,a
    ld      [rSCX],a
    ld      [rSCY],a

    ld      a,LCDCF_BG9800|LCDCF_OBJON|LCDCF_BG8800|LCDCF_ON
    ld      [rLCDC],a

    ld      b,1 ; bank at 8800h
    call    LoadText

    LONG_CALL   RoomMinimapLoadBG ; Same graphics as minimap room

    call    LoadTextPalette

    ld      a,GRAPHS_SELECTION_POPULATION
    ld      [graphs_selected],a

    LONG_CALL   GraphsDrawSelected

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

    call    SetPalettesAllBlack

    ret

;###############################################################################

    SECTION "Room Graphs Code Bank 0",ROM0

;-------------------------------------------------------------------------------

RoomGraphsVBLHandler:

    call    refresh_OAM

    ret

;###############################################################################