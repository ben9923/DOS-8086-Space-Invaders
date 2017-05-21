DATASEG
include "Strings.asm"

	DebugBool						db	0

	;Files:

	RandomFileName		db	'Assets/Random.txt', 0
	RandomFileHandle	dw	?

	ScoresFileName					db	'Assets/Scores.txt', 0
	ScoresFileHandle				dw	?

	ScoreTableFileName				db	'Assets/ScoreTab.bmp', 0
	ScoreTableFileHandle			dw	?

	AskSaveFileName					db	'Assets/AskSave.bmp', 0
	AskSaveFileHandle				dw	?

	MainMenuFileName				db	'Assets/MainMenu.bmp',0
	MainMenuFileHandle				dw	?

	InstructionsFileName			db	'Assets/Instruct.bmp',0
	InstructionsFileHandle			dw	?

	InvaderFileName					db	'Assets/Invader.bmp',0
	InvaderFileHandle				dw	?
	InvaderLength					equ	32
	InvaderHeight					equ	32


	ShooterFileName					db	'Assets/Shooter.bmp', 0
	ShooterFileHandle				dw	?
	ShooterLength					equ	16
	ShooterHeight					equ	16


	HeartFileName					db	'Assets/Heart.bmp', 0
	HeartFileHandle					dw	?
	HeartLength						equ	16
	HeartHeight						equ	16

;Enemies move & status info:
	InvadersMoveRightBool			db	?
	InvadersMovesToSideDone			db	?
	InvadersPrintStartLine			dw	?
	InvadersPrintStartRow			dw	?
	InvadersLeftAmount				db	?
	InvadersStatusArray				db	24 dup (?)

	InvadersLoopMoveCounter			db	? ;Invaders move every 4 repeats of the game loop

	
	ShooterLineLocation				equ 149
	ShooterRowLocation				dw	?

	ShootingLength					equ	2
	ShootingHeight					equ	4

	PlayerShootingExists			db	?
	PlayerShootingLineLocation		dw	?
	PlayerShootingRowLocation		dw	?

	InvadersShootingMaxAmount		db	?
	InvadersShootingCurrentAmount	db	?
	InvadersShootingLineLocations	dw	10 dup (?)
	InvadersShootingRowLocations	dw	10 dup (?)

	Score							db	?
	LivesRemaining					db	?
	Level							db	?

	DidNotDieInLevelBool			db	?


	HeartsPrintStartLine			equ	182
	HeartsPrintStartRow				equ	125

	StatsAreaBorderLine				equ	175

	FileReadBuffer					db	320 dup (?)

	;Colors:
	BlackColor						equ	0
	GreenColor						equ	30h
	RedColor						equ	40
	BlueColor						equ	54
	WhiteColor						equ	255

CODESEG
include "Macros.asm"
include "Invader.asm"
include "Procs.asm"

; -----------------------------------------------------------
; Prints the lower game area with score, lives, level, etc...
; Ben Raz
; -----------------------------------------------------------
proc PrintStatsArea
	; Print border:
	push 320
	push 2
	push StatsAreaBorderLine
	push 0
	push 100
	call PrintColor

	;Print labels:

	;Level label:
	xor bh, bh
	mov dh, 23
	mov dl, 1
	mov ah, 2
	int 10h

	mov ah, 9
	mov dx, offset LevelString
	int 21h


	;Score label:
	xor bh, bh
	mov dh, 23
	mov dl, 29
	mov ah, 2
	int 10h

	mov ah, 9
	mov dx, offset ScoreString
	int 21h

	ret
endp PrintStatsArea


;----------------------------------
; Updates the lives shown on screen
; Ben Raz
;----------------------------------
proc UpdateLives
	;Clear previous hearts:
	push 64
	push 14
	push HeartsPrintStartLine
	push HeartsPrintStartRow
	push BlackColor
	call PrintColor

	push offset HeartFileName
	push offset HeartFileHandle
	call OpenFile

	;Print amount of lifes remaining:
	xor ch, ch
	mov cl, [LivesRemaining]

	mov bx, HeartsPrintStartRow

@@printHeart:
	push bx
	push cx

	push [HeartFileHandle]
	push HeartLength
	push HeartHeight
	push HeartsPrintStartLine
	push bx
	push offset FileReadBuffer
	call PrintBMP

	pop cx
	pop bx
	add bx, 20
	loop @@printHeart

	push [HeartFileHandle]
	call CloseFile

	ret
endp UpdateLives


;----------------------------------
; Updates the score shown on screen
; Ben Raz
;----------------------------------
proc UpdateScoreStat
	xor bh, bh
	mov dh, 23
	mov dl, 36
	mov ah, 2
	int 10h

	xor ah, ah
	mov al, [Score]
	push ax
	call HexToDecimal

	push ax
	mov ah, 2
	int 21h
	pop dx
	xchg dl, dh
	int 21h
	xchg dl, dh
	int 21h

	ret
endp UpdateScoreStat


; ---------------------------------------
; Updates the level # and the score count
; Ben Raz
; ---------------------------------------
proc UpdateStats
	;Update level:
	xor bh, bh
	mov dh, 23
	mov dl, 8
	mov ah, 2
	int 10h

	mov ah, 2
	mov dl, [byte ptr Level]
	add dl, 30h
	int 21h

	;Update score:
	call UpdateScoreStat

	ret
endp UpdateStats


; ------------------------------------------------------------
; Moving invaders + player to initial location, removing shots
; Not getting back dead invaders
; Ben Raz
; ------------------------------------------------------------
proc MoveToStart
	mov [byte ptr InvadersMoveRightBool], 1
	mov [byte ptr InvadersMovesToSideDone], 0

	mov [byte ptr InvadersLoopMoveCounter], 0

	mov [byte ptr InvadersPrintStartLine], 10
	mov [byte ptr InvadersPrintStartRow], 8


	mov [word ptr ShooterRowLocation], 152
	mov [byte ptr PlayerShootingExists], 0

	mov [byte ptr InvadersShootingCurrentAmount], 0


	cld
	push ds
	pop es

	;Zero invaders shots locations:
	xor ax, ax

	mov di, offset InvadersShootingLineLocations
	mov cx, 10
	rep stosw

	mov di, offset InvadersShootingRowLocations
	mov cx, 10
	rep stosw

	ret
endp MoveToStart

; ------------------------------------------------------------
; Resetting invaders locations, shootings, etc for a new level
; Ben Raz
; ------------------------------------------------------------
proc InitializeLevel
	mov [InvadersLeftAmount], 24

	cmp [byte ptr Level], 1
	jne @@checkLevelTwo

	mov [byte ptr InvadersShootingMaxAmount], 3
	jmp @@resetDidNotDieBool

@@checkLevelTwo:
	cmp [byte ptr Level], 2
	jne @@setLevelThree

	mov [byte ptr InvadersShootingMaxAmount], 5
	jmp @@resetDidNotDieBool

@@setLevelThree:
	mov [byte ptr InvadersShootingMaxAmount], 7

@@resetDidNotDieBool:
	mov [byte ptr DidNotDieInLevelBool], 1 ;true

	call MoveToStart


	cld
	push ds
	pop es

	;Set all invaders as 'active':
	mov di, offset InvadersStatusArray
	mov cx, 24
	mov al, 1
	rep stosb

	ret
endp InitializeLevel


; -----------------------------------------------
; Resetting every stat to its initial game value,
; and setting the first level
; Ben Raz
; -----------------------------------------------
proc InitializeGame
	mov [byte ptr Score], 0
	mov [byte ptr LivesRemaining], 3
	mov [byte ptr Level], 1


	call InitializeLevel

	ret
endp InitializeGame

; ------------------------------------------------
; Checking if player had died from invaders' shots
; If no, returned ax = 0, if yes, ax = 1
; Ben Raz
; ------------------------------------------------
proc CheckIfPlayerDied
	xor ch, ch
	mov cl, [InvadersShootingCurrentAmount]
	cmp cx, 0
	je @@returnZero

	xor si, si

@@checkShot:
	;check from above:
	mov ax, ShooterLineLocation
	sub ax, 3
	cmp ax, [InvadersShootingLineLocations + si]
	ja @@checkNextShot

	;check from below:
	add ax, 3
	add ax, 16 ;height
	cmp ax, [InvadersShootingLineLocations + si]
	jb @@checkNextShot

	;check from left
	mov ax, [ShooterRowLocation]
	dec ax
	cmp ax, [InvadersShootingRowLocations + si]
	ja @@checkNextShot

	;check from right:
	add ax, 16 ;length
	cmp ax, [InvadersShootingRowLocations + si]
	jb @@checkNextShot

	;Player killed:
	mov ax, 1
	ret

@@checkNextShot:
	inc si
	loop @@checkShot

@@returnZero:
	;Player not killed:
	xor ax, ax 
	ret
endp CheckIfPlayerDied


; ---------------------------------------------------------------
; Checks if the currently lowest line of invaders reached too low
; If true, ax = 1. If not, ax = 0.
; Ben Raz
; ---------------------------------------------------------------
proc CheckIfInvadersReachedBottom
	mov cx, 8
	mov bx, 16

@@checkLineTwo:
	cmp [InvadersStatusArray + bx], 0
	jne @@lineTwoNotEmpty

	inc bx
	loop @@checkLineTwo

	mov cx, 8
	mov bx, 8

@@checkLineOne:
	cmp [InvadersStatusArray + bx], 0
	jne @@lineOneNotEmpty
	
	inc bx
	loop @@checkLineOne

	mov cx, 8
	xor bx, bx

@@checkLineZero:
	cmp [InvadersStatusArray + bx], 0
	jne @@lineZeroNotEmpty
	
	inc bx
	loop @@checkLineZero

	jmp @@invadersDidNotReachBottom

@@lineTwoNotEmpty:
	cmp [word ptr InvadersPrintStartLine], ShooterLineLocation - 59
	ja @@invadersReachedBottom

	jmp @@invadersDidNotReachBottom

@@lineOneNotEmpty:
	cmp [word ptr InvadersPrintStartLine], ShooterLineLocation - 39
	ja @@invadersReachedBottom

	jmp @@invadersDidNotReachBottom

@@lineZeroNotEmpty:
	cmp [word ptr InvadersPrintStartLine], ShooterLineLocation - 19
	ja @@invadersReachedBottom


@@invadersDidNotReachBottom:
	xor ax, ax
	ret

@@invadersReachedBottom:
	mov ax, 1
	ret
endp CheckIfInvadersReachedBottom


; -----------------------------------------------------------
; Initiating the game, combining the game parts together
; Handles shooter + Invaders hits and deaths, movements, etc.
; Ben Raz
; -----------------------------------------------------------
proc PlayGame
	push offset InvaderFileName
	push offset InvaderFileHandle
	call OpenFile

	push offset ShooterFileName
	push offset ShooterFileHandle
	call OpenFile

	call InitializeGame

	call ClearScreen


@@firstLevelPrint:
	call PrintStatsArea
	call UpdateStats
	call UpdateLives

	call CheckAndMoveInvaders

	push [ShooterFileHandle]
	push ShooterLength
	push ShooterHeight
	push ShooterLineLocation
	push [word ptr ShooterRowLocation]
	push offset FileReadBuffer
	call PrintBMP


	call PrintInvaders


	;Print countdown to start:
	mov cx, 3
	mov dx, 33h
@@printCountdownNum:
	push cx
	push dx

	mov ah, 2
	xor bh, bh
	mov dh, 12
	mov dl, 19
	int 10h

	pop dx
	push dx
	mov ah, 2
	int 21h

	push 18
	call Delay

	pop dx
	dec dx
	pop cx
	loop @@printCountdownNum

	;clear number:
	mov ah, 2
	xor bh, bh
	mov dh, 12
	mov dl, 19
	int 10h

	xor dl, dl
	mov ah, 2
	int 21h


@@readKey:
	mov ah, 1
	int 16h

	jz_Far @@checkShotStatus

	;Read key, clean buffer afterwards:
	mov ah, 0
	int 16h

	push ax
	xor al, al
	mov ah, 0ch
	int 21h
	pop ax

	cmp ah, 1 ;Esc
	je_Far @@procEnd

	cmp ah, 39h ;Space
	je_Far @@shootPressed

	cmp ah, 4Bh ;Left
	jne @@checkRight

	cmp [word ptr ShooterRowLocation], 21
	jb_Far @@clearShot

	;Clear current shooter print:
	push ShooterLength
	push ShooterHeight
	push ShooterLineLocation
	push [word ptr ShooterRowLocation]
	push 0 ;black
	call PrintColor

	sub [word ptr ShooterRowLocation], 10
	jmp @@printAgain

@@checkRight:
	cmp ah, 4Dh
	jne @@readKey

	cmp [word ptr ShooterRowLocation], 290
	ja_Far @@clearShot

	;Clear current shooter print:
	push ShooterLength
	push ShooterHeight
	push ShooterLineLocation
	push [word ptr ShooterRowLocation]
	push BlackColor
	call PrintColor

	add [word ptr ShooterRowLocation], 10

@@printAgain:
	push [ShooterFileHandle]
	push ShooterLength
	push ShooterHeight
	push ShooterLineLocation
	push [word ptr ShooterRowLocation]
	push offset FileReadBuffer
	call PrintBMP

@@checkShotStatus:
	;Check if shooting already exists in screen:
	cmp [byte ptr PlayerShootingExists], 0
	jne @@moveShootingUp

	jmp @@clearShot

@@shootPressed:
	;Check if shooting already exists in screen:
	cmp [byte ptr PlayerShootingExists], 0
	jne @@moveShootingUp

@@initiateShot:
	;Set initial shot location:
	mov ax, ShooterLineLocation
	sub ax, 6
	mov [word ptr PlayerShootingLineLocation], ax
	mov ax, [ShooterRowLocation]
	add ax, 7
	mov [word ptr PlayerShootingRowLocation], ax

	mov [byte ptr PlayerShootingExists], 1
	jmp @@printShooting

@@moveShootingUp:
	cmp [word ptr PlayerShootingLineLocation], 10
	jb @@removeShot

	sub [word ptr PlayerShootingLineLocation], 10

@@printShooting:
	push ShootingLength
	push ShootingHeight
	push [word ptr PlayerShootingLineLocation]
	push [word ptr PlayerShootingRowLocation]
	push RedColor
	call PrintColor

	jmp @@clearShot

@@removeShot:
	mov [byte ptr PlayerShootingExists], 0
	mov [word ptr PlayerShootingLineLocation], 0
	mov [word ptr PlayerShootingRowLocation], 0

@@clearShot:
	push 2
	call Delay


	;Clear shot:
	push ShootingLength
	push ShootingHeight
	push [word ptr PlayerShootingLineLocation]
	push [word ptr PlayerShootingRowLocation]
	push BlackColor
	call PrintColor

	cmp [byte ptr InvadersLeftAmount], 0
	je_Far @@setNewLevel

	;Check if invader killed:
	;Check above:
	mov ah, 0Dh
	mov dx, [PlayerShootingLineLocation]
	dec dx
	mov cx, [PlayerShootingRowLocation]
	mov bh, 0
	int 10h

	cmp al, GreenColor
	je @@killInvader

	;Check below:
	mov ah, 0Dh
	mov dx, [PlayerShootingLineLocation]
	add dx, 4
	mov cx, [PlayerShootingRowLocation]
	mov bh, 0
	int 10h

	cmp al, GreenColor
	je @@killInvader

	mov ah, 0Dh
	mov dx, [PlayerShootingLineLocation]
	sub dx, 3
	mov cx, [PlayerShootingRowLocation]
	mov bh, 0
	int 10h

	cmp al, GreenColor
	je @@killInvader

	;Check from left
	mov ah, 0Dh
	mov dx, [PlayerShootingLineLocation]
	mov cx, [PlayerShootingRowLocation]
	dec cx
	mov bh, 0
	int 10h

	cmp al, GreenColor
	je @@killInvader

	;Check from right
	mov ah, 0Dh
	mov dx, [PlayerShootingLineLocation]
	mov cx, [PlayerShootingRowLocation]
	add cx, 2
	mov bh, 0
	int 10h

	cmp al, GreenColor
	je @@killInvader

	jmp @@moveInvaders

@@killInvader:
	;set cursor to top left
	xor bh, bh
	xor dx, dx
	mov ah, 2
	int 10h

	mov ax, [PlayerShootingLineLocation]
	sub ax, [InvadersPrintStartLine]

	cmp ax, 22
	jb @@killedInLine0

	cmp ax, 0FFE0h
	ja @@killedInLine0

	cmp ax, 42
	jb @@killedInLine1

	push 2
	jmp @@checkKilledRow

@@killedInLine0:
	push 0
	jmp @@checkKilledRow

@@killedInLine1:
	push 1

@@checkKilledRow:
	cmp [byte ptr DebugBool], 1
	jne @@skipLineDebugPrint

; Print hit debug info (if used debug flag):
	mov ah, 2
	xor bh, bh
	xor dx, dx
	int 10h

	mov dl, 'L'
	int 21h

	pop dx
	push dx
	add dl, 30h
	mov ah, 2
	int 21h

@@skipLineDebugPrint:
	mov ax, [PlayerShootingRowLocation]
	sub ax, [InvadersPrintStartRow]
	add ax, 2

	;In some rare cases startRow is bigger than shootingRow, check:
	cmp ax, 0FFE0h
	jb @@setForRowFind

	xor cx, cx
	jmp @@rowFound

@@setForRowFind:
	xor cx, cx ;row counter
	mov dx, 28
@@checkRow:
	cmp ax, dx
	jb @@rowFound

	add dx, 36
	inc cx
	jmp @@checkRow

@@rowFound:
	cmp [byte ptr DebugBool], 1
	jne @@skipRowDebugPrint

	mov ah, 2
	mov dl, 'R'
	int 21h

	mov dx, cx
	add dl, 30h
	int 21h

@@skipRowDebugPrint:
	pop bx
	;bx holding line, cx holding row

	shl bx, 3 ;multiply by 8
	add bx, cx

	push bx

	mov [byte ptr InvadersStatusArray + bx], 0
	dec [byte ptr InvadersLeftAmount]

	mov [byte ptr PlayerShootingExists], 0
	mov [word ptr PlayerShootingLineLocation], 0
	mov [word ptr PlayerShootingRowLocation], 0

	;Increase and update score:
	inc [byte ptr Score]
	call UpdateScoreStat

	pop ax
	;clear killed invader print
	mov bl, 8
	div bl
	push ax
	xor ah, ah
	mov bl, 20
	mul bl

	mov dx, ax
	add dx, [InvadersPrintStartLine]
	sub dx, 4

	pop ax
	shr ax, 8
	mov bl, 36
	mul bl
	add ax, [InvadersPrintStartRow]
	sub ax, 4

	push 36
	push 24
	push dx
	push ax
	push BlackColor
	call PrintColor

@@moveInvaders:
	call ClearInvadersShots

	call CheckAndMoveInvaders
	
	call CheckIfInvadersReachedBottom
	cmp ax, 1
	je @@playerDied

	call UpdateInvadersShots
	call InvadersRandomShot
	call printInvadersShots


	;Check if player was killed:
	call CheckIfPlayerDied
	cmp ax, 0
	je_Far @@readKey

@@playerDied:
	;Player died:
	push 18
	call Delay

	;decrease amount of lives left, check if 0 left:
	dec [byte ptr LivesRemaining]
	cmp [byte ptr LivesRemaining], 0
	je_Far @@printDied

	;Clear screan without stats area:
	push 320
	push StatsAreaBorderLine
	push 0 ;line
	push 0 ;row
	push BlackColor
	call PrintColor

	mov ah, 2
	xor bh, bh
	mov dh, 12
	mov dl, 8
	int 10h

	;tell user he was hit, -5 score...
	mov ah, 9
	mov dx, offset HitString
	int 21h

; Nice blink animation for death:
	mov cx, 3
@@blinkShooter:
	push cx

	push ShooterLength
	push ShooterHeight
	push ShooterLineLocation
	push [word ptr ShooterRowLocation]
	push BlackColor
	call PrintColor

	push 6
	call Delay

	push [word ptr ShooterFileHandle]
	push ShooterLength
	push ShooterHeight
	push ShooterLineLocation
	push [word ptr ShooterRowLocation]
	push offset FileReadBuffer
	call PrintBMP

	push 6
	call Delay

	pop cx
	loop @@blinkShooter

	;sub 5 score if possible, if he doesn't have 5 yet, just reset to 0:
	cmp [byte ptr Score], 5
	jb @@resetScoreAfterDeath

	sub [byte ptr Score], 5
	jmp @@resetBeforeContinueAfterDeath


@@resetScoreAfterDeath:
	mov [byte ptr Score], 0

@@resetBeforeContinueAfterDeath:
	call MoveToStart

	mov [byte ptr DidNotDieInLevelBool], 0 ;false


	push 24
	call Delay

	call ClearScreen

	
	jmp @@firstLevelPrint


	jmp @@readKey

@@printDied:
	call ClearScreen
; Print a message when game is over:
	mov ah, 2
	xor bh, bh
	mov dh, 12
	mov dl, 15
	int 10h

	mov ah, 9
	mov dx, offset GameOverString
	int 21h

	;print actual score #:
	mov ah, 2
	xor bh, bh
	mov dh, 13
	mov dl, 10
	int 10h

	mov ah, 9
	mov dx, offset YouEarnedXString
	int 21h
	
	xor ah, ah
	mov al, [Score]
	push ax
	call HexToDecimal

	push ax
	mov ah, 2
	int 21h
	pop dx
	xchg dl, dh
	int 21h
	xchg dl, dh
	int 21h

	mov ah, 9
	mov dx, offset ScoreWordString
	int 21h
	
	push 54
	call Delay

	jmp @@procEnd


@@setNewLevel:
	cmp [byte ptr DidNotDieInLevelBool], 1
	jne @@SkipPerfectLevelBonus

	add [byte ptr Score], 5 ;special bonus for perfect level (no death in level)

	;print bonus message:
	mov ah, 2
	xor bh, bh
	mov dh, 12
	mov dl, 8
	int 10h

	mov ah, 9
	mov dx, offset PerfectLevelString
	int 21h

	push 24
	call Delay

	call ClearScreen


@@SkipPerfectLevelBonus:

	cmp [byte ptr Level], 3
	je @@printWin


	inc [byte ptr Level]
	call InitializeLevel

	call ClearScreen
	jmp @@firstLevelPrint

@@printWin:
; Print win message to user (finished 3 levels):
	mov ah, 9
	mov dx, offset WinString
	int 21h

	;print actual score #:
	mov ah, 2
	xor bh, bh
	mov dh, 13
	mov dl, 15
	int 10h

	mov ah, 9
	mov dx, offset YouEarnedXString
	int 21h

	xor ah, ah
	mov al, [Score]
	push ax
	call HexToDecimal

	push ax
	mov ah, 2
	int 21h
	pop dx
	xchg dl, dh
	int 21h
	xchg dl, dh
	int 21h

	mov ah, 9
	mov dx, offset ScoreWordString
	int 21h


@@procEnd:
	push [ShooterFileHandle]
	call CloseFile

	push [InvaderFileHandle]
	call CloseFile

	ret
endp PlayGame
