#!/bin/bash
MOD2GBT=../../tools/mod2gbt/mod2gbt

$MOD2GBT city.mod song_city
mv song_city.asm ../../audio/

$MOD2GBT menu.mod song_menu
mv song_menu.asm ../../audio/

$MOD2GBT title.mod song_title
mv song_title.asm ../../audio/
