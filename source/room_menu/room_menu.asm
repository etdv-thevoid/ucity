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

    INCLUDE "map_load.inc"
    INCLUDE "text.inc"
    INCLUDE "room_text_input.inc"

;###############################################################################

    SECTION "Room Menu Variables",WRAM0

menu_selection: DS 1
menu_exit:      DS 1

;###############################################################################

    SECTION "Room Menu Data",ROMX

;-------------------------------------------------------------------------------

MAIN_MENU_BG_MAP::
    INCBIN "data/main_menu_bg_map.bin"

;###############################################################################

    SECTION "Room Menu Code Data",ROM0

;-------------------------------------------------------------------------------

MenuNewCity:

    ld      a,0
    call    CityMapSet

    ld      de,STR_CITY_NAME
    LONG_CALL_ARGS  RoomTextInputSetPrompt ; de = pointer to string

    LONG_CALL   RoomTextInput

    ld      hl,text_input_buffer
    ld      de,current_city_name
    ld      bc,TEXT_INPUT_LENGTH
    call    memcopy ; bc = size    hl = source address    de = dest address

    ret

;-------------------------------------------------------------------------------

MenuLoadCitySRAM:

    ld      b,0 ; 0 = load data mode
    LONG_CALL_ARGS    RoomSaveMenu ; returns A = SRAM bank, -1 if error
    ld      b,a ; (*) save bank to b

    cp      a,$FF
    jr      z,.error ; no banks or user pressed cancel

    ld      hl,sram_bank_status
    ld      e,a
    ld      d,0
    add     hl,de
    ld      a,[hl] ; get bank status

    cp      a,1
    jr      nz,.error ; bank is empty or corrupted

    ld      a,b ; (*) get bank
    or      a,CITY_MAP_SRAM_FLAG
    call    CityMapSet

    ret

.error:

    ; TODO

    ret

;-------------------------------------------------------------------------------

STR_CITY_NAME:
    String2Tiles "C","i","t","y"," ","N","a","m","e",":",0

InputHandleMenu:

    ld      a,[joy_pressed]
    and     a,PAD_A
    jr      z,.not_a

        call    MenuNewCity

        ld      a,1
        ld      [menu_exit],a
        ret
.not_a:

    ld      a,[joy_pressed]
    and     a,PAD_B
    jr      z,.not_b

        call    MenuLoadCitySRAM

        ld      a,1
        ld      [menu_exit],a
        ret
.not_b:

    ret

;-------------------------------------------------------------------------------

RoomMenuVBLHandler:

    call    refresh_OAM

    ret

;-------------------------------------------------------------------------------

RoomMenuLoadBG:

    ; Reset scroll
    ; ------------

    xor     a,a
    ld      [rSCX],a
    ld      [rSCY],a

    ; Load graphics
    ; -------------

    ld      b,BANK(MAIN_MENU_BG_MAP)
    call    rom_bank_push_set

    ; Tiles

    xor     a,a
    ld      [rVBK],a

    ld      de,$9800
    ld      hl,MAIN_MENU_BG_MAP

    ld      a,18
.loop1:
    push    af

    ld      b,20
    call    vram_copy_fast ; b = size - hl = source address - de = dest

    push    hl
    ld      hl,32-20
    add     hl,de
    ld      d,h
    ld      e,l
    pop     hl

    pop     af
    dec     a
    jr      nz,.loop1

    ; Attributes

    ld      a,1
    ld      [rVBK],a

    ld      de,$9800

    ld      a,18
.loop2:
    push    af

    ld      b,20
    call    vram_copy_fast ; b = size - hl = source address - de = dest

    push    hl
    ld      hl,32-20
    add     hl,de
    ld      d,h
    ld      e,l
    pop     hl

    pop     af
    dec     a
    jr      nz,.loop2

    call    rom_bank_pop

    ret

;-------------------------------------------------------------------------------

RoomMenu::

    xor     a,a
    ld      [menu_selection],a
    ld      [menu_exit],a

    call    SetPalettesAllBlack

    ld      bc,RoomMenuVBLHandler
    call    irq_set_VBL

    call    RoomMenuLoadBG

    ld      b,0 ; bank at 8000h
    call    LoadText

    di ; Entering critical section

    ld      b,144
    call    wait_ly

    xor     a,a
    ld      [rIF],a

    ld      a,LCDCF_BG9800|LCDCF_OBJON|LCDCF_BG8000|LCDCF_ON
    ld      [rLCDC],a

    call    LoadTextPalette

    ei ; End of critical section

.loop:

    call    wait_vbl

    call    scan_keys
    call    KeyAutorepeatHandle

    call    InputHandleMenu

    ld      a,[menu_exit]
    and     a,a
    jr      z,.loop

    call    SetDefaultVBLHandler

    ret

;###############################################################################
