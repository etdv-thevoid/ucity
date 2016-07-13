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

    IF !DEF(TEXT_MESSAGES_INC)
TEXT_MESSAGES_INC SET 1

;###############################################################################

ROM_BANK_TEXT_MSG EQU 3

;-------------------------------------------------------------------------------

; Labels should be named MSG_xxxx and IDs should be named ID_MSG_xxxx

; Persistent messages should be placed right after ID_MSG_EMPTY

ID_MSG_EMPTY EQU 0

ID_MSG_CLASS_TOWN       EQU 1
ID_MSG_CLASS_CITY       EQU 2
ID_MSG_CLASS_METROPOLIS EQU 3
ID_MSG_CLASS_CAPITAL    EQU 4

ID_MSG_PERSISTENT_MAX EQU 4 ; Max message ID which usage is saved to SRAM

ID_MSG_POLLUTION_HIGH EQU 5

ID_MSG_MAX EQU 5

ID_MSG_CUSTOM EQU $FF ; Can only be in the queue once! Careful with it!

;###############################################################################

    ENDC ; TEXT_MESSAGES_INC

;###############################################################################