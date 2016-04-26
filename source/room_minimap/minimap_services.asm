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
    INCLUDE "text.inc"
    INCLUDE "tileset_info.inc"

;###############################################################################

    SECTION "Minimap Services Functions",ROMX

;-------------------------------------------------------------------------------

MINIMAP_TILE_COLORS: ; Common to all services
    DB 0,0,0,0
    DB 0,1,1,0
    DB 1,1,1,1
    DB 1,2,2,1
    DB 2,2,2,2
    DB 2,3,3,2
    DB 3,3,3,3
    DB 3,3,3,3

MinimapServicesCommonDrawMap:

    LONG_CALL   APA_PixelStreamStart

    ld      hl,SCRATCH_RAM

    ld      d,0 ; d = y
.loopy:

        ld      e,0 ; e = x
.loopx:

        push    de ; (*)
        push    hl

            ; TODO Check if water?

            ld      a,BANK_SCRATCH_RAM
            ld      [rSVBK],a

            ld      a,[hl]
            srl     a
            srl     a
            srl     a
            srl     a
            srl     a ; Reduce from 8 to 3 bits

            ld      de,MINIMAP_TILE_COLORS
            ld      l,a
            ld      h,0
            add     hl,hl
            add     hl,hl ; a *= 4
            add     hl,de

            ld      a,[hl+]
            ld      b,[hl]
            inc     hl
            ld      c,[hl]
            inc     hl
            ld      d,[hl]

            call    APA_SetColors ; a,b,c,d = color (0 to 3)
            LONG_CALL   APA_PixelStreamPlot2x2

        pop     hl
        pop     de ; (*)

        inc     hl

        inc     e
        bit     6,e
        jp      z,.loopx

    inc     d
    bit     6,d
    jp      z,.loopy

    ret

;-------------------------------------------------------------------------------

MINIMAP_POLICE_PALETTE:
    DW (31<<10)|(31<<5)|(31<<0), (31<<10)|(15<<5)|(0<<0)
    DW (31<<10)|(0<<5)|(0<<0), (15<<10)|(0<<5)|(0<<0)

MINIMAP_POLICE_TITLE:
    DB "Police",0

MinimapDrawPolice::

    ; Simulate and get data!
    ; ----------------------

    ld      bc,T_POLICE_CENTER
    LONG_CALL_ARGS  Simulation_Services

    ; Draw map
    ; --------
    call    MinimapServicesCommonDrawMap

    ; Set screen white
    call    MinimapSetDefaultPalette

    ; Refresh screen with backbuffer data
    call    APA_BufferUpdate

    ; Load palette
    ld      hl,MINIMAP_POLICE_PALETTE
    call    APA_LoadPalette

    ; Draw title
    ld      hl,MINIMAP_POLICE_TITLE
    call    RoomMinimapDrawTitle

    ret

;-------------------------------------------------------------------------------

MINIMAP_FIREMEN_PALETTE:
    DW (31<<10)|(31<<5)|(31<<0), (0<<10)|(31<<5)|(31<<0)
    DW (0<<10)|(15<<5)|(31<<0), (0<<10)|(0<<5)|(31<<0)

MINIMAP_FIREMEN_TITLE:
    DB "Firemen",0

MinimapDrawFiremen::

    ; Simulate and get data!
    ; ----------------------

    ld      bc,T_FIREMEN_CENTER
    LONG_CALL_ARGS  Simulation_Services

    ; Draw map
    ; --------
    call    MinimapServicesCommonDrawMap

    ; Set screen white
    call    MinimapSetDefaultPalette

    ; Refresh screen with backbuffer data
    call    APA_BufferUpdate

    ; Load palette
    ld      hl,MINIMAP_FIREMEN_PALETTE
    call    APA_LoadPalette

    ; Draw title
    ld      hl,MINIMAP_FIREMEN_TITLE
    call    RoomMinimapDrawTitle

    ret

;-------------------------------------------------------------------------------

MINIMAP_HOSPITALS_PALETTE:
    DW (31<<10)|(31<<5)|(31<<0), (9<<10)|(31<<5)|(9<<0)
    DW (0<<10)|(31<<5)|(0<<0), (0<<10)|(15<<5)|(0<<0)

MINIMAP_HOSPITALS_TITLE:
    DB "Hospitals",0

MinimapDrawHospitals::

    ; Simulate and get data!
    ; ----------------------

    ld      bc,T_HOSPITAL_CENTER
    LONG_CALL_ARGS  Simulation_Services

    ; Draw map
    ; --------
    call    MinimapServicesCommonDrawMap

    ; Set screen white
    call    MinimapSetDefaultPalette

    ; Refresh screen with backbuffer data
    call    APA_BufferUpdate

    ; Load palette
    ld      hl,MINIMAP_HOSPITALS_PALETTE
    call    APA_LoadPalette

    ; Draw title
    ld      hl,MINIMAP_HOSPITALS_TITLE
    call    RoomMinimapDrawTitle

    ret

;-------------------------------------------------------------------------------

MINIMAP_SCHOOLS_PALETTE:
    DW (31<<10)|(31<<5)|(31<<0), (20<<10)|(10<<5)|(20<<0)
    DW (10<<10)|(5<<5)|(10<<0), (5<<10)|(0<<5)|(5<<0)

MINIMAP_SCHOOLS_TITLE:
    DB "Schools",0

MinimapDrawSchools::

    ; Simulate and get data!
    ; ----------------------

    ld      bc,T_SCHOOL_CENTER
    LONG_CALL_ARGS  Simulation_Services

    ; Draw map
    ; --------
    call    MinimapServicesCommonDrawMap

    ; Set screen white
    call    MinimapSetDefaultPalette

    ; Refresh screen with backbuffer data
    call    APA_BufferUpdate

    ; Load palette
    ld      hl,MINIMAP_SCHOOLS_PALETTE
    call    APA_LoadPalette

    ; Draw title
    ld      hl,MINIMAP_SCHOOLS_TITLE
    call    RoomMinimapDrawTitle

    ret

;-------------------------------------------------------------------------------

MINIMAP_HIGH_SCHOOLS_PALETTE:
    DW (31<<10)|(31<<5)|(31<<0), (20<<10)|(20<<5)|(10<<0)
    DW (10<<10)|(10<<5)|(5<<0), (5<<10)|(5<<5)|(0<<0)

MINIMAP_HIGH_SCHOOLS_TITLE:
    DB "High Schools",0

MinimapDrawHighSchools::

    ; Simulate and get data!
    ; ----------------------

    ld      bc,T_HIGH_SCHOOL_CENTER
    LONG_CALL_ARGS  Simulation_ServicesBig

    ; Draw map
    ; --------
    call    MinimapServicesCommonDrawMap

    ; Set screen white
    call    MinimapSetDefaultPalette

    ; Refresh screen with backbuffer data
    call    APA_BufferUpdate

    ; Load palette
    ld      hl,MINIMAP_HIGH_SCHOOLS_PALETTE
    call    APA_LoadPalette

    ; Draw title
    ld      hl,MINIMAP_HIGH_SCHOOLS_TITLE
    call    RoomMinimapDrawTitle

    ret

;###############################################################################