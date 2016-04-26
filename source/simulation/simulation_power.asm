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
    INCLUDE "tileset_info.inc"

;###############################################################################

    SECTION "Queue Variables",HRAM

;-------------------------------------------------------------------------------

; FIFO circular buffer
queue_in_ptr:  DS 2 ; LSB first
queue_out_ptr: DS 2; LSB first

;###############################################################################

    SECTION "Simulation Services Functions",ROMX

;-------------------------------------------------------------------------------

QueueInit: ; Reset pointers
    ld      a,SCRATCH_RAM_2 & $FF ; LSB first
    ldh     [queue_in_ptr+0],a
    ldh     [queue_out_ptr+0],a
    ld      a,(SCRATCH_RAM_2>>8) & $FF
    ldh     [queue_in_ptr+1],a
    ldh     [queue_out_ptr+1],a
    ret

QueueAdd: ; Add register DE to the queue. Preserves DE

    ld      a,BANK_SCRATCH_RAM_2
    ld      [rSVBK],a

    ldh     a,[queue_in_ptr+0] ; Get pointer to next empty space
    ld      l,a
    ldh     a,[queue_in_ptr+1]
    ld      h,a

    ld      [hl],d ; Save and increment pointer
    inc     hl
    ld      [hl],e
    inc     hl

    ld      a,$0F ; Wrap pointer and store
    and     a,h
    or      a,$D0
    ldh     [queue_in_ptr+1],a
    ld      a,l
    ldh     [queue_in_ptr+0],a

    ret

QueueGet: ; Get queue element from DE

    ld      a,BANK_SCRATCH_RAM_2
    ld      [rSVBK],a

    ldh     a,[queue_out_ptr+0] ; Get pointer to next element to get
    ld      l,a
    ldh     a,[queue_out_ptr+1]
    ld      h,a

    ld      d,[hl] ; Read and increment pointer
    inc     hl
    ld      e,[hl]
    inc     hl

    ld      a,$0F ; Wrap pointer and store
    and     a,h
    or      a,$D0
    ldh     [queue_out_ptr+1],a
    ld      a,l
    ldh     [queue_out_ptr+0],a

    ret

QueueIsEmpty: ; Returns a=1 if empty

    ldh     a,[queue_out_ptr+0]
    ld      b,a
    ldh     a,[queue_in_ptr+0]
    cp      a,b
    jr      z,.equal0
    xor     a,a
    ret ; Different, return 0
.equal0:

    ldh     a,[queue_out_ptr+1]
    ld      b,a
    ldh     a,[queue_in_ptr+1]
    cp      a,b
    jr      z,.equal1
    xor     a,a
    ret ; Different, return 0
.equal1:

    ld      a,1
    ret ; Equal, return 1

;-------------------------------------------------------------------------------

TILE_HANDLED_BIT             EQU 7
TILE_HANDLED_POWER_PLANT_BIT EQU 6

TILE_HANDLED                 EQU %10000000
TILE_HANDLED_POWER_PLANT     EQU %01000000
TILE_POWER_LEVEL_MASK        EQU %00111111 ; How much power there is now

POWER_PLANT_POWER: ; Base tile, energetic power - LSB first
    DW T_POWER_PLANT_COAL,     3000
    DW T_POWER_PLANT_OIL,      2000
    DW T_POWER_PLANT_WIND,      100 ; TODO Change this depending on the season
    DW T_POWER_PLANT_SOLAR,    1000
    DW T_POWER_PLANT_NUCLEAR,  5000
    DW T_POWER_PLANT_FUSION,  10000
    DW 0,0 ; End

; Flood fill from the power plant on the specified coordinates. This function is
; supposed to receive only the top left corner of a power plant. If not, it will
; fail!
Simulation_PowerPlantFloodFill: ; d = y, e = x

    ; Check if this power plant has been handled
    ; ------------------------------------------

    ld      a,BANK_SCRATCH_RAM ; Get current state
    ld      [rSVBK],a

    call    GetMapAddress ; e=x , d=y ret: address=hl, preserves DE
    ld      a,[hl]
    and     a,TILE_HANDLED_POWER_PLANT
    ret     nz ; If not 0, this power plant has already been handled

    ; Reset all TILE_HANDLED flags
    ; ----------------------------

    ld      hl,SCRATCH_RAM
    ld      a,(SCRATCH_RAM+$1000)>>8
.loop_clear:
    REPT    $20 ; Unroll to increase speed
    res     TILE_HANDLED_BIT,[hl]
    inc     hl
    ENDR
    cp      a,h
    jr      nz,.loop_clear

    ; Flag power plant as handled
    ; ---------------------------

    ; This is faster than setting the power of all other tiles of the central to
    ; have power 0 because the TILE_HANDLED flag doesn't have to be cleared this
    ; way.

    push    de
    call    CityMapGetTile ; Returns tile -> Register DE
    LD_BC_DE
    pop     de

    ; bc = tile, de = coordinates

    push    bc ; Save base tile to calculate the power in the next step (*)
    push    de ; Save coordinates too

        push    de ; save coords
        ; bc = base tile
        ; returns: d=height, e=width
        LONG_CALL_ARGS BuildingGetSizeFromBaseTile
        LD_BC_DE ; bc = size
        pop     de ; get coords

        ; d = y, e = x
        ; b = height, c = width

        ld      a,b
        ld      b,e
        ld      e,a

        ; d = y, e = height
        ; b = x, c = width

        ; Fill that square with $FF

        ld      a,BANK_SCRATCH_RAM
        ld      [rSVBK],a

.height_loop:

        push    bc ; save x and w
.width_loop:

            push    bc
            push    de
            ld      e,b ; e=x, d=y
            call    GetMapAddress ; e=x , d=y ret: address=hl
            pop     de
            pop     bc

            set     TILE_HANDLED_POWER_PLANT_BIT,[hl] ; flag as used

            inc     b ; x
            dec     c ; width
            jr      nz,.width_loop

        pop     bc ; restore x and w

        inc     d ; y
        dec     e ; height
        jr      nz,.height_loop

    pop     de
    pop     bc ; Restore base tile and coordinates (*)

    ; Get power plant power
    ; ---------------------

    push    de ; (*)

    ; Base tile won't be needed after calculating the energetic power

        ld      hl,POWER_PLANT_POWER ; Base tile, energetic power
.loop_search:
        ld      a,[hl+]
        ld      e,a
        ld      d,[hl]

        ld      a,b
        cp      a,d
        jr      nz,.next
        ld      a,c
        cp      a,e
        jr      nz,.next

            inc     hl
            ld      a,[hl+]
            ld      c,a
            ld      b,[hl] ; bc = energetic power
            jr      .exit_search
.next:
        inc     hl
        inc     hl
        inc     hl
        jr      .loop_search

.exit_search:

    pop     de ; (*)

    ; BC now holds the energetic power!

    ; Flood fill
    ; ----------

    ; For each connected tile with scratch RAM value of 0 reduce the fill amount
    ; of the power plant by the energy consumption of that tile (if possible)
    ; and add the energy given to that tile to the scratch RAM. Power lines have
    ; no energetic cost. Beware unconnected power line bridges -> Sometimes they
    ; are not connected to the ground next to them.
    push    de
    call    QueueInit
    pop     de
    call    QueueAdd ; Add first element

.loop_fill:

    ; Get Queue element

    call    QueueGet

    ; First, if not already filled, try to fill current coordinates

    call    GetMapAddress ; Preserves DE

    ld      a,BANK_SCRATCH_RAM
    ld      [rSVBK],a

    ld      a,[hl] ; Already handled by this power plant, ignore
    and     a,TILE_HANDLED
    jp      nz,.end_handle

    ld      a,TILE_HANDLED|TILE_POWER_LEVEL_MASK
    or      a,[hl]
    ld      [hl],a

    ; Then, add to queue all valid neighbours (power plants, buildings, lines)

    ; If this is a vertical bridge only try to power top and bottom. If it is
    ; horizontal, only left and right!

    ; HL holds the address from before
    push    de
    call    CityMapGetTileAtAddress ; de = tile
    LD_BC_DE
    pop     de
    ; bc = tile

    ; If not horizontal bridge, check top and bottom
    ld      a,b
IF (T_POWER_LINES_LR_BRIDGE>>8) != 0
    FAIL "Tile number > 255, fix comparison!"
ENDC
    and     a,a
    jr      nz,.continue_top_bottom
    ld      a,c
    cp      a,T_POWER_LINES_LR_BRIDGE & $FF
    jr      z,.end_top_bottom
.continue_top_bottom:
    push    de
    dec     d ; Top
    call    AddToQueueVerticalDisplacement
    pop     de

    push    de
    inc     d ; Bottom
    call    AddToQueueVerticalDisplacement
    pop     de
.end_top_bottom:

    ; If not vertical bridge, check top and bottom
    ld      a,b
IF (T_POWER_LINES_TB_BRIDGE>>8) != 0
    FAIL "Tile number > 255, fix comparison!"
ENDC
    and     a,a
    jr      nz,.continue_left_right
    ld      a,c
    cp      a,T_POWER_LINES_TB_BRIDGE & $FF
    jr      z,.end_left_right
.continue_left_right:
    push    de
    dec     e ; Left
    call    AddToQueueHorizontalDisplacement
    pop     de

    push    de
    inc     e ; Right
    call    AddToQueueHorizontalDisplacement
    pop     de
.end_left_right:

.end_handle:
    ; Last, check if queue is empty. If so, exit loop
    call    QueueIsEmpty
    and     a,a
    jp      z,.loop_fill

    ; Done!
    ; -----

    ret

;--------------------------------------

AddToQueueVerticalDisplacement: ; d=y e=x

    ld      a,d ; Check map border
    and     a,128+64 ; ~63
    ret     nz

    ld      a,BANK_SCRATCH_RAM ; Check if already handled
    ld      [rSVBK],a
    call    GetMapAddress
    ld      a,[hl]
    bit     TILE_HANDLED_BIT,a
    ret     nz

    push    hl ; save address
    call    CityMapGetTypeNoBoundCheck ; Check if it transmits power
    call    TypeHasElectricityExtended ; in: A=type, out: A = TYPE_HAS_POWER / 0
    bit     TYPE_HAS_POWER_BIT,a
    pop     hl
    ret     z

    ; Check if it is a bridge with incorrect orientation
    ; Return if horizontal bridge!
    push    de
    call    CityMapGetTileAtAddress ; hl = address, returns tile in de
    LD_BC_DE
    pop     de
    ld      a,b
IF (T_POWER_LINES_LR_BRIDGE>>8) != 0
    FAIL "Tile number > 255, fix comparison!"
ENDC
    and     a,a
    jr      nz,.continue
    ld      a,c
    cp      a,T_POWER_LINES_LR_BRIDGE & $FF
    ret     z
.continue:

    ; Add to queue!
    call    QueueAdd
    ret

AddToQueueHorizontalDisplacement: ; d=y e=x

    ld      a,e ; Check map border
    and     a,128+64 ; ~63
    ret     nz

    ld      a,BANK_SCRATCH_RAM ; Check if already handled
    ld      [rSVBK],a
    call    GetMapAddress
    ld      a,[hl]
    bit     TILE_HANDLED_BIT,a
    ret     nz

    push    hl ; save address
    call    CityMapGetTypeNoBoundCheck ; Check if it transmits power
    call    TypeHasElectricityExtended ; in: A=type, out: A = TYPE_HAS_POWER / 0
    bit     TYPE_HAS_POWER_BIT,a
    pop     hl
    ret     z

    ; Check if it is a bridge with incorrect orientation
    ; Return if vertical bridge!
    push    de
    call    CityMapGetTileAtAddress ; hl = address, returns tile in de
    LD_BC_DE
    pop     de
    ld      a,b
IF (T_POWER_LINES_TB_BRIDGE>>8) != 0
    FAIL "Tile number > 255, fix comparison!"
ENDC
    and     a,a
    jr      nz,.continue
    ld      a,c
    cp      a,T_POWER_LINES_TB_BRIDGE & $FF
    ret     z
.continue:

    ; Add to queue!
    call    QueueAdd
    ret

;-------------------------------------------------------------------------------

; Output data to WRAMX bank BANK_SCRATCH_RAM
Simulation_PowerDistribution::

    ; Clear
    ; -----

    ld      a,BANK_SCRATCH_RAM
    ld      [rSVBK],a

    ld      bc,$1000
    ld      d,0
    ld      hl,SCRATCH_RAM
    call    memset

    ; For each tile check if it is type TYPE_POWER_PLANT (power plant)
    ; ----------------------------------------------------------------

    ld      d,0 ; y
.loopy:
        ld      e,0 ; x
.loopx:
        push    de

            ; Returns type = a, address = hl
            call    CityMapGetType ; e = x , d = y

            cp      a,TYPE_POWER_PLANT
            jr      nz,.not_power_plant
                pop     de
                push    de
                ; The coordinates will be the top left corner because of the
                ; order of iteration when searching the map for power plants.
                ; After calling this function the whole power plant will be
                ; flagged as handled.
                call    Simulation_PowerPlantFloodFill ; e=x, d=y, address=hl
.not_power_plant:

        pop     de

        inc     e
        ld      a,CITY_MAP_WIDTH
        cp      a,e
        jr      nz,.loopx

    inc     d
    ld      a,CITY_MAP_HEIGHT
    cp      a,d
    jr      nz,.loopy

    ret

;-------------------------------------------------------------------------------

Simulation_PowerDistributionSetTileOkFlag::

    ; TODO - Fill BANK_CITY_MAP_TILE_OK_FLAGS from BANK_SCRATCH_RAM

    ret

;###############################################################################