;
;   _____                        _____                     _               
;  / ____|                      |_   _|                   | |              
; | (___  _ __   __ _  ___ ___    | |  _ ____   ____ _  __| | ___ _ __ ___ 
;  \___ \| '_ \ / _` |/ __/ _ \   | | | '_ \ \ / / _` |/ _` |/ _ \ '__/ __|
;  ____) | |_) | (_| | (_|  __/  _| |_| | | \ V / (_| | (_| |  __/ |  \__ \
; |_____/| .__/ \__,_|\___\___| |_____|_| |_|\_/ \__,_|\__,_|\___|_|  |___/
;        | |                                                                                                                              
;  ___   |_|  ___             ___         
; | _ )_  _  | _ ) ___ _ _   | _ \__ _ ___
; | _ \ || | | _ \/ -_) ' \  |   / _` |_ /
; |___/\_, | |___/\___|_||_| |_|_\__,_/__|
;      |__/                               
;
; Space Invaders by Ben Raz.
;


IDEAL
MODEL small
STACK 100h

CODESEG

include "FileUse.asm"
include "Game.asm"
include "Print.asm"
include "Menus.asm"


start:
	mov ax, @data
	mov ds, ax


	;Check if debug mode is enabled ( -dbg flag)
	call CheckDebug
	cmp ax, 0
	je setVideoMode

	mov [byte ptr DebugBool], 1 ;set debug as true

setVideoMode:
	;Set video mode:
	mov ax, 13h
	int 10h

	call PrintMainMenu

	;Set text mode back:
	mov ax, 03h
	int 10h

exit:
	mov ax, 4c00h
	int 21h
END start