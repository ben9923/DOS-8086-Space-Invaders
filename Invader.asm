CODESEG

; ---------------------------------------------------------
; Printing the invaders marked as alive in the status array
; Starting at the location saved in memory
; Ben Raz
; ---------------------------------------------------------
proc PrintInvaders
	push bp
	mov bp, sp
	;create local variables for line+row:
	sub sp, 4
	;line: bp - 2
	;row: bp - 4

	mov ax, [InvadersPrintStartLine]
	mov [bp - 2], ax

	xor bx, bx ;current invader #

	mov cx, 3
@@printInvadersLine:
	push cx

	mov ax, [InvadersPrintStartRow]
	mov [bp - 4], ax


	mov cx, 8
@@printInvader:
	push cx

	push bx

	cmp [byte ptr InvadersStatusArray + bx], 1
	jne @@skipInvader

	
	;Print invader:
	push [word ptr InvaderFileHandle]
	push InvaderLength
	push InvaderHeight
	push [word ptr bp - 2]
	push [word ptr bp - 4]
	push offset FileReadBuffer
	call PrintBMP

@@skipInvader:
	pop bx
	inc bx

	pop cx


	add [word ptr bp - 4], 36 ;set location for next invader

	loop @@printInvader

	add [word ptr bp - 2], 20 ;Set location for next line

	pop cx
	loop @@printInvadersLine

	add sp, 4

	pop bp
	ret
endp PrintInvaders


; ---------------------------------------------------------------------------------------------------
; Replacing every printed invader with black color (with a black frame around it, to handle movement)
; Ben Raz
; ---------------------------------------------------------------------------------------------------
proc ClearInvaders
	push bp
	mov bp, sp
	;create local variables for line+row:
	sub sp, 4
	;line: bp - 2
	;row: bp - 4

	mov ax, [InvadersPrintStartLine]
	mov [bp - 2], ax

	xor bx, bx ;current invader #

	mov cx, 3
@@printInvadersLine:
	push cx

	mov ax, [InvadersPrintStartRow]
	mov [bp - 4], ax


	mov cx, 8
@@printInvader:
	push cx

	push bx

	cmp [byte ptr InvadersStatusArray + bx], 1
	jne @@skipInvader

	
	;clear invader:
	push 30
	push 24
	mov ax, [bp - 2]
	sub ax, 4
	push ax
	mov ax, [bp - 4]
	sub ax, 4
	push ax
	push BlackColor
	call PrintColor

@@skipInvader:
	pop bx
	inc bx

	pop cx


	add [word ptr bp - 4], 36 ;set location for next invader

	loop @@printInvader

	add [word ptr bp - 2], 20 ;Set location for next line

	pop cx
	loop @@printInvadersLine

	add sp, 4

	pop bp
	ret
endp ClearInvaders


; --------------------------------------------------------
; Moving the invaders location by current location
; Going down after moving a full line, changing directions
; Ben Raz
; --------------------------------------------------------
proc UpdateInvadersLocation
	cmp [byte ptr InvadersMovesToSideDone], 8
	je @@reverseDirectionGoDown


	inc [byte ptr InvadersMovesToSideDone]


	cmp [byte ptr InvadersMoveRightBool], 1
	je @@moveRight

	;Left:
	sub [word ptr InvadersPrintStartRow], 4
	jmp @@procEnd


@@moveRight:
	add [word ptr InvadersPrintStartRow], 4
	jmp @@procEnd

@@reverseDirectionGoDown:
	xor [byte ptr InvadersMoveRightBool], 1
	mov [byte ptr InvadersMovesToSideDone], 0
	add [word ptr InvadersPrintStartLine], 4
	
@@procEnd:
	ret
endp UpdateInvadersLocation


; ---------------------------------------------------------------
; Updating invaders location once every 4 game loops
; When updated location is updated and invaders are printed again
; Ben Raz
; ---------------------------------------------------------------
proc CheckAndMoveInvaders
	cmp [byte ptr InvadersLoopMoveCounter], 3
	jne @@skipPrint

	;Move:
	call ClearInvaders
	call PrintInvaders
	call UpdateInvadersLocation
	mov [byte ptr InvadersLoopMoveCounter], 0
	jmp @@procEnd

@@skipPrint:
	inc [byte ptr InvadersLoopMoveCounter]

@@procEnd:
	ret
endp CheckAndMoveInvaders


; -------------------------------------------------
; Choosing a random invader to shoot
; If not found after a few tries, no shot performed
; Updating shot location, adding it to shots arrays
; Ben Raz
; -------------------------------------------------
proc InvadersRandomShot
	push bp
	mov bp, sp

	;Check if max reached:
	mov al, [InvadersShootingCurrentAmount]
	cmp [InvadersShootingMaxAmount], al
	je @@procEnd

	;Shoot only after invaders movement:
	cmp [byte ptr InvadersLoopMoveCounter], 3
	jne @@procEnd


	mov al, [InvadersShootingMaxAmount]
	sub al, 2
	cmp al, [InvadersShootingCurrentAmount]
	ja @@shootRandomly

	;Shoot or not, randomly:
	;Chance of 3/4 to shoot
	push 4
	call Random
	cmp ax, 0
	je @@procEnd

@@shootRandomly:
	sub sp, 2 ;create local variable counting fails
	;address: bp - 2
	mov [word ptr bp - 2], 0

@@getRandomInvader:
	;Get a random invader
	push 24
	call Random
	mov si, ax

	;Check if invader 'alive':
	cmp [byte ptr InvadersStatusArray + si], 0
	jne @@setShootingLocation

	inc [word ptr bp - 2]

	cmp [word ptr bp - 2], 4
	jne @@getRandomInvader

	add sp, 2 ;clear local variable
	jmp @@procEnd


@@setShootingLocation:
	add sp, 2 ;clear local variable

	mov bl, 8
	div bl

	;al = lines, ah = rows
	push ax

	mov dx, [InvadersPrintStartLine]
	add dx, 15 ;set to buttom of first invader

	;set correct line:
	xor ah, ah
	mov bl, 20
	mul bl

	add dx, ax
	mov bl, [InvadersShootingCurrentAmount]
	xor bh, bh
	shl bx, 1
	mov [InvadersShootingLineLocations + bx], dx


	pop ax
	shr ax, 8 ;rows # in al
	mov bl, 35
	mul bl

	add ax, 10 ;set to middle of invader
	add ax, [InvadersPrintStartRow]

	mov bl, [InvadersShootingCurrentAmount]
	xor bh, bh
	shl bx, 1
	mov [InvadersShootingRowLocations + bx], ax

	inc [byte ptr InvadersShootingCurrentAmount]

@@procEnd:
	pop bp
	ret
endp InvadersRandomShot


; -------------------------------------------------------
; Moving invaders' shots down, checking if reached bottom
; If reached bottom, shot is removed
; Ben Raz
; -------------------------------------------------------
proc UpdateInvadersShots

	cmp [byte ptr InvadersShootingCurrentAmount], 0
	je @@procEnd

	xor ch, ch
	mov cl, [InvadersShootingCurrentAmount]

	xor di, di

@@moveShooting:
	add [word ptr InvadersShootingLineLocations + di], 10

	add di, 2
	loop @@moveShooting

	;Check if oldest shot reached the bottom:
	cmp [word ptr InvadersShootingLineLocations], StatsAreaBorderLine - 12
	jb @@procEnd

	;Remove shot:
	mov [word ptr InvadersShootingLineLocations], 0

	mov [word ptr InvadersShootingRowLocations], 0

	;If it's the only shot, no need to move others in array:
	cmp [byte ptr InvadersShootingCurrentAmount], 1
	je @@decShootingsAmount

	cld

	mov ax, ds
	mov es, ax

	mov si, offset InvadersShootingLineLocations
	mov di, si
	add si, 2

	mov cx, 9
	rep movsw


	mov si, offset InvadersShootingRowLocations
	mov di, si
	add si, 2

	mov cx, 9
	rep movsw

@@decShootingsAmount:
	dec [byte ptr InvadersShootingCurrentAmount]


@@procEnd:
	ret
endp UpdateInvadersShots


; --------------------------------------------------------------------
; Reading invaders' shots status, and printing them by saved locations
; Ben Raz
; --------------------------------------------------------------------
proc PrintInvadersShots
	cmp [byte ptr InvadersShootingCurrentAmount], 0
	je @@procEnd

	xor si, si

	xor ch, ch
	mov cl, [InvadersShootingCurrentAmount]

@@printShooting:
	push cx
	push si

	push ShootingLength
	push ShootingHeight
	push [word ptr InvadersShootingLineLocations + si]
	push [word ptr InvadersShootingRowLocations + si]
	push BlueColor
	call PrintColor

	pop si
	add si, 2

	pop cx
	loop @@printShooting


@@procEnd:
	ret
endp PrintInvadersShots


; --------------------------------------------------
; Replacing printed invaders' shots with black color
; (before printing at updated locations)
; Ben Raz
; --------------------------------------------------
proc ClearInvadersShots
	xor si, si
	
	xor ch, ch
	mov cl, [InvadersShootingCurrentAmount]

	cmp cx, 0
	jne @@clearShot

	ret

@@clearShot:
	push cx
	push si

	push ShootingLength
	push ShootingHeight
	push [InvadersShootingLineLocations + si]
	push [InvadersShootingRowLocations + si]
	push BlackColor
	call PrintColor

	pop si
	add si, 2
	pop cx
	loop @@clearShot
	
	ret
endp ClearInvadersShots


; ------------------------------------------------
; Checks if an invader was hi by player's shot
; If true, invader is marked as 'dead' and removed
; Ben Raz
; ------------------------------------------------
proc CheckAndKillInvader
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

	jmp @@procEnd


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

@@procEnd:
	ret
endp CheckAndKillInvader