CODESEG
; ---------------------------------------------------------------------
; Get FileHandle, and dedicated space address for print usage from stack
; Print the BMP.
; Ben Raz
; ---------------------------------------------------------------------
proc PrintFullScreenBMP
	push bp ;Preserve bp's value
	mov bp, sp ;Use bp as a not-changing memory pointer for using pushed values before call

; -----------------------------------------------------
; Stack State:
; | bp | bp + 2 |          bp + 4        |   bp + 6   |
; | bp |   sp   | transfer space address | FileHandle |
; -----------------------------------------------------

	;Set file pointer to start of data:
	xor al, al ;Set file pointer in offset beggining start
	mov bx, [bp + 6] ;Hold FileHandle in bx
	xor cx, cx
	mov dx, 1077 ;start of data in BMP file
	mov ah, 42h
	int 21h

	jc @@printErrorSettingPointer

	jmp @@readFile

@@printErrorSettingPointer:
	mov dx, offset PointerSetErrorMsg
	mov ah, 9
	int 21h
	jmp @@procEnd

@@readFile:
	mov ax, 0A000h ;start of vram address
	mov es, ax
	mov di, 0F8BFh ;last line of vram

	cld ;clear direction flag to make sure printing in correct direction

	mov cx, 200 ;200 lines

@@readLine:
	push cx ;preserve lines number

	mov cx, 320 ;read one line
	mov dx, [bp + 4] ;Read buffer address
	mov ah, 3Fh
	int 21h

	;copy 1 line to vram:
	mov si, dx ;read from 'input' buffer
	mov cx, 320
	rep movsb

	sub di, 640 ;go one line up

	pop cx ;get lines left number
	loop @@readLine

@@procEnd:
	pop bp ;pop bp's value back + Clear the stack from pushed values
	ret 4 ;End proc + Clear the stack from pushed values
endp PrintFullScreenBMP


; ---------------------------------------------------------------------
; Get FileHandle, image length, height, destination line and row,
; and dedicated space address for print usage from stack
; Print the BMP.
; Ben Raz
; ---------------------------------------------------------------------
proc PrintBMP
	push bp ;Preserve bp's value
	mov bp, sp ;Use bp as a not-changing memory pointer for using pushed values before call

; ----------------------------------------------------------------------------------------------
; Stack State:
; | bp | bp + 2 |          bp + 4        | bp + 6  |  bp + 8  | bp + 10 | bp + 12 |   bp + 14  |
; | bp |   sp   | transfer space address | destRow | destLine |  height |  length | Filehandle |
; ----------------------------------------------------------------------------------------------

	;Set file pointer to start of data:
	xor al, al ;Set file pointer in offset beggining start
	mov bx, [bp + 14] ;Hold FileHandle in bx
	xor cx, cx
	mov dx, 1078 ;start of data in BMP file
	mov ah, 42h
	int 21h

	jc @@printErrorSettingPointer

	jmp @@readFile

@@printErrorSettingPointer:
	mov dx, offset PointerSetErrorMsg
	mov ah, 9
	int 21h
	jmp @@procEnd

@@readFile:
	;use es as vram segment
	mov ax, 0A000h
	mov es, ax

	;Set di to picture start offset in vram:
	mov ax, 320
	mov bx, [bp + 8]
	mul bx

	mov di, ax ;We ignore dx because max value can be entered in 16-bit.
	add di, [bp + 6] ;Add row number

	;Set di to start of last line to print (printing from down, upwords):
	mov bx, [bp + 10]
	dec bx
	mov ax, 320
	mul bx
	add di, ax ;We ignore dx because max value can be entered in 16-bit.

	cld ;clear direction flag to make sure printing in correct direction

	mov cx, [bp + 10] ;amount of lines

@@readLine:
	push cx ;preserve lines number

	mov bx, [bp + 14] ;Hold FileHandle
	mov cx, [bp + 12] ;read one line
	mov dx, [bp + 4] ;Read buffer address
	mov ah, 3Fh
	int 21h

	jnc @@copyToVRAM ;if no error, continue

@@printReadError:
	mov dx, offset ReadErrorMsg
	mov ah, 9
	int 21h

	pop cx ;clear stack from preserved cx
	jmp @@procEnd

@@copyToVRAM:
	;copy 1 line to vram:
	mov si, [bp + 4] ;read from 'input' buffer
	mov cx, [bp + 12]
	
@@checkBackground:
	;check if current pixel is black. If it is, skipping. If not, print it:
	cmp [byte ptr si], BlackColor
	je @@skipPixel

	movsb
	jmp @@loopLabel

@@skipPixel:
	inc si
	inc di
@@loopLabel:
	loop @@checkBackground

	;go one line up:
	sub di, [bp + 12]
	sub di, 320

	pop cx ;get lines left number
	loop @@readLine

@@procEnd:
	pop bp ;pop bp's value back + Clear the stack from pushed values
	ret 12 ;End proc + Clear the stack from pushed values
endp PrintBMP


;Black = 0, Red = 40, Blue = 54, White = 255
; ---------------------------------------------------------------------
; Get length and height, destLine, destRow and color # from stack
; Print the color with the input location and dimensions.
; Ben Raz
; ---------------------------------------------------------------------
proc PrintColor
	push bp
	mov bp, sp

; ------------------------------------------------------------------
; Stack State:
; | bp | bp + 2 |  bp + 4 | bp + 6  |  bp + 8  | bp + 10 | bp + 12 |
; | bp |   sp   | color # | destRow | destLine |  height |  length |
; ------------------------------------------------------------------

	mov ax, 0A000h
	mov es, ax

	;Set di to picture start offset in vram:
	mov ax, 320
	mov bx, [bp + 8]
	mul bx

	mov di, ax ;We ignore dx because max value can be entered in 16-bit.
	add di, [bp + 6] ;Add row number

	cld ;clear direction flag to make sure printing in correct direction

	mov cx, [bp + 10] ;amount of lines

	mov al, [bp + 4] ;hold color #

@@printLine:
	push cx
	mov cx, [bp + 12]

@@movePixel:
	mov [es:di], al
	inc di
	loop @@movePixel

	;Goto start of next line:
	sub di, [bp + 12]
	add di, 320

	pop cx
	loop @@printLine

	pop bp
	ret 10
endp PrintColor