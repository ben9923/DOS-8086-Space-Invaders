	TableNameColumn			equ	13
	TableScoreColumn		equ	24
	TableTitlesLine			equ	5
	
CODESEG
; ----------------------------------------
; Print the main menu, handle user choices
; Ben Raz
; ----------------------------------------
proc PrintMainMenu
@@printMenu:
	push offset MainMenuFileName
	push offset MainMenuFileHandle
	call OpenFile

	push [MainMenuFileHandle]
	push offset FileReadBuffer
	call PrintFullScreenBMP

	push [MainMenuFileHandle]
	call CloseFile

@@getKey:
	xor ah, ah
	int 16h

	cmp ah, 19h ;P key
	je @@play

	cmp ah, 17h ;I key
	je_Far @@printInstructions

	cmp ah, 14h ;T key
	je_Far @@printHighScoreTable

	cmp ah, 1 ;Esc key
	je_Far @@procEnd
	jmp @@getKey

@@play:
	call PlayGame

	;try to open file, if missing it's ok:
	push offset ScoresFileName
	push offset ScoresFileHandle
	call OpenFile

	cmp ax, 0
	je @@createNewFile ;if table is empty, no problem to add score to new file

	jmp @@getAmountFirstTime

@@createNewFile:
	xor cx, cx
	mov dx, offset ScoresFileName
	mov ah, 3Ch
	int 21h

	mov [ScoresFileHandle], ax ;save new FileHandle

	;set current scores amount to zero (new file...):
	mov [byte ptr FileReadBuffer], 0

	mov ah, 40h
	mov bx, [ScoresFileHandle]
	mov cx, 1
	mov dx, offset FileReadBuffer
	int 21h

@@getAmountFirstTime:
	;set score file pointer to start:
	mov ah, 42h
	xor al, al
	mov bx, [ScoresFileHandle]
	xor cx, cx
	xor dx, dx
	int 21h

	;get amount of saved scores:
	mov ah, 3Fh
	mov bx, [ScoresFileHandle]
	mov cx, 1
	mov dx, offset FileReadBuffer
	int 21h

	;check if table is full:
	cmp [byte ptr FileReadBuffer], 5
	jne @@okToAsk

	;check if current score is better than 5th place:

	;set score file pointer to last score:
	mov ah, 42h
	xor al, al
	mov bx, [ScoresFileHandle]
	xor cx, cx
	mov dx, 45 ;score of 5th place
	int 21h

	;get 5th place score:
	mov ah, 3Fh
	mov bx, [ScoresFileHandle]
	mov cx, 1
	mov dx, offset FileReadBuffer
	int 21h

	mov al, [FileReadBuffer]
	cmp al, [Score]
	ja_Far @@printMenu ;if current score is lower than 5th place, don't ask

@@okToAsk:
	push offset AskSaveFileName
	push offset AskSaveFileHandle
	call OpenFile

	push [AskSaveFileHandle]
	push offset FileReadBuffer
	call PrintFullScreenBMP

	push [AskSaveFileHandle]
	call CloseFile

@@askYN:
	xor ah, ah
	int 16h

	cmp ah, 31h ;N key
	je_Far @@printMenu

	cmp ah, 15h ;Y key
	jne @@askYN
	
	;ask user for name:
	call ClearScreen

	mov ah, 2
	xor bh, bh
	mov dh, 12
	mov dl, 5
	int 10h

	mov ah, 9
	mov dx, offset EnterYourNameString
	int 21h

;Get name:

	;zero the current info at 'buffer'
	push ds
	pop es
	mov di, offset FileReadBuffer + 1
	xor al, al
	mov cx, 11
	rep stosb


	mov [byte ptr FileReadBuffer + 1], 9
	mov dx, offset FileReadBuffer + 1

	mov ah, 0Ah
	int 21h


	;set score file pointer to start:
	mov ah, 42h
	xor al, al
	mov bx, [ScoresFileHandle]
	xor cx, cx
	xor dx, dx
	int 21h

	;get amount of saved scores:
	mov ah, 3Fh
	mov bx, [ScoresFileHandle]
	mov cx, 1
	mov dx, offset FileReadBuffer
	int 21h

	cmp [byte ptr FileReadBuffer], 0 ;check if amount of scores is 0
	je @@putScoreIfTableIsEmpty

	cmp [byte ptr FileReadBuffer], 5 ;check if amount of scores is 5
	je @@replaceWithFifthPlace

	;update amount of scores in file:
	inc [byte ptr FileReadBuffer]
	;set to amount location (first byte):
	mov ah, 42h
	mov al, 0
	mov bx, [ScoresFileHandle]
	xor cx, cx
	xor dx, dx
	int 21h

	;move updated amount of players to file:
	mov ah, 40h
	mov bx, [ScoresFileHandle]
	mov cx, 1 ;one byte
	mov dx, offset FileReadBuffer
	int 21h


	;check where to initially place new score, before putting in correct rank:
	mov al, [FileReadBuffer]
	dec al
	mov bl, 9 ;every score is 9 bytes (8 name + 1 score)
	mul bl

	mov dx, ax

	;set to this location:
	mov ah, 42h
	mov al, 1
	mov bx, [ScoresFileHandle]
	xor cx, cx
	int 21h

	jmp @@moveNameAndScoreToFile

@@replaceWithFifthPlace:
	mov ah, 42h
	mov al, 1
	mov bx, [ScoresFileHandle]
	xor cx, cx
	mov dx, 36 ;start of 5th place in file
	int 21h

	jmp @@moveNameAndScoreToFile


@@putScoreIfTableIsEmpty:
	;set file pointer to start of file:
	mov ah, 42h
	xor al, al
	mov bx, [ScoresFileHandle]
	xor cx, cx
	xor dx, dx
	int 21h

	mov [byte ptr FileReadBuffer], 1

	;move updated amount of players to file:
	mov ah, 40h
	mov bx, [ScoresFileHandle]
	mov cx, 1 ;one byte
	mov dx, offset FileReadBuffer
	int 21h

@@moveNameAndScoreToFile:
	;Move name to file
	mov ah, 40h
	mov bx, [ScoresFileHandle]
	mov cx, 8 ;name length
	mov dx, offset FileReadBuffer + 3
	int 21h

	;Move score to file:
	mov ah, 40h
	mov bx, [ScoresFileHandle]
	mov cx, 1 ;one byte
	mov dx, offset Score
	int 21h


	push [ScoresFileHandle]
	call CloseFile

	call SortScoresFile

	call ClearScreen

	;move cursor to middle:
	mov ah, 2
	xor bh, bh
	mov dh, 12
	mov dl, 9
	int 10h

	;print 'saved' to user
	mov ah, 9
	mov dx, offset ScoreSavedString
	int 21h

	push 36
	call Delay

	jmp @@printHighScoreTable

@@printInstructions:
	call PrintInstructions
	jmp @@printMenu

@@printHighScoreTable:
	call PrintHighScoreTable
	jmp @@printMenu

@@procEnd:
	call ClearScreen
	ret
endp PrintMainMenu


; ------------------------------------------------------------
; Prints the instructions menu, quitting when a key is pressed
; Ben Raz
; ------------------------------------------------------------
proc PrintInstructions
	push offset InstructionsFileName
	push offset InstructionsFileHandle
	call OpenFile

	push [InstructionsFileHandle]
	push offset FileReadBuffer
	call PrintFullScreenBMP

	push [InstructionsFileHandle]
	call CloseFile

	;wait for key:
	xor ah, ah
	int 16h

	ret
endp PrintInstructions


; -------------------------------------------------------------
; Reads names and scores from the txt file.
; printinig information on a table.
; quitting when Esc pressed, resetting file when Del is pressed
; Ben Raz
; -------------------------------------------------------------
proc PrintHighScoreTable
	;Score file structure:
	;first byte - amount of players in table
	;then 8 bytes of name, and a byte of score  x5 times


	;Print background:
	push offset ScoreTableFileName
	push offset ScoreTableFileHandle
	call OpenFile

	push [ScoreTableFileHandle]
	push offset FileReadBuffer
	call PrintFullScreenBMP

	push [ScoreTableFileHandle]
	call CloseFile



	;try to open file, if missing create a new one:
	push offset ScoresFileName
	push offset ScoresFileHandle
	call OpenFile

	cmp ax, 0
	jne @@skipFileCreate

@@createNewFile: ;can also shrink file to 0 bytes if already exists
	xor cx, cx
	mov dx, offset ScoresFileName
	mov ah, 3Ch
	int 21h

	mov [ScoresFileHandle], ax ;save new FileHandle

	;set current scores amount to zero (new file...):
	mov [byte ptr FileReadBuffer], 0

	mov ah, 40h
	mov bx, [ScoresFileHandle]
	mov cx, 1
	mov dx, offset FileReadBuffer
	int 21h

@@skipFileCreate:
	;set file pointer to start:
	mov ah, 42h
	xor al, al
	mov bx, [ScoresFileHandle]
	xor cx, cx
	xor dx, dx
	int 21h

	
	;get amount of saved scores:
	mov ah, 3Fh
	mov bx, [ScoresFileHandle]
	mov cx, 1
	mov dx, offset FileReadBuffer
	int 21h

	;Debug print:
	cmp [byte ptr DebugBool], 0
	je @@skipPlayersAmountDebugPrint

	mov ah, 2
	xor bh, bh
	xor dx, dx
	int 10h

	mov dl, [FileReadBuffer]
	add dl, 30h
	mov ah, 2
	int 21h

	mov ah, 9
	mov dx, offset PlayersInTableString
	int 21h

@@skipPlayersAmountDebugPrint:

	;print titles:

	push ds
	pop es

	;Print 'rank':
	mov bp, offset RankString

	mov ah, 13h
	mov al, 1
	xor bh, bh
	mov cx, 4
	mov bl, 30h
	mov dh, TableTitlesLine
	mov dl, TableNameColumn - 6

	int 10h


	;Print 'Name':
	mov bp, offset NameString

	mov ah, 13h
	mov al, 1
	xor bh, bh
	mov cx, 4
	mov bl, 30h
	mov dh, TableTitlesLine
	mov dl, TableNameColumn

	int 10h


	;Print 'Score':
	mov bp, offset JustScoreString

	mov ah, 13h
	mov al, 1
	xor bh, bh
	mov cx, 5
	mov bl, 30h
	mov dh, TableTitlesLine
	mov dl, TableScoreColumn

	int 10h



	;print numbers (1 - 5):
	mov cx, 5
	mov dh, TableTitlesLine + 2
@@printLineNum:
	push cx
	push dx

	mov ah, 2
	mov dl, TableNameColumn - 3
	xor bh, bh
	int 10h


	mov ah, 9
	mov al, 6
	sub al, cl
	add al, 30h
	xor bh, bh
	mov bl, 3
	mov cx, 1
	int 10h

	pop dx
	add dh, 3
	pop cx
	loop @@printLineNum


	mov dh, TableTitlesLine + 2 ;start line

	xor ch, ch
	mov cl, [FileReadBuffer]

	cmp cx, 0
	je @@skipPlayersPrint


@@printName:
	push cx
	push dx

	;set name location:
	mov dl, TableNameColumn
	xor bh, bh
	mov ah, 2
	int 10h

	;read name:
	mov ah, 3Fh
	mov bx, [ScoresFileHandle]
	mov cx, 8 ;max name length
	mov dx, offset FileReadBuffer + 1
	int 21h

	mov [byte ptr FileReadBuffer + 9], '$'
	
	mov ah, 9
	int 21h


	pop dx
	push dx

	;set score location:
	mov dl, TableScoreColumn
	xor bh, bh
	mov ah, 2
	int 10h

	;read score:
	mov ah, 3Fh
	mov bx, [ScoresFileHandle]
	mov cx, 1
	mov dx, offset FileReadBuffer + 1
	int 21h

	;print score:
	xor ah, ah
	mov al, [FileReadBuffer + 1]
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


	pop dx
	add dh, 3

	pop cx
	loop @@printName


@@skipPlayersPrint:
	xor ch, ch
	mov cl, 5
	sub cl, [FileReadBuffer]

	cmp cx, 0
	je @@skipPrintNA


@@printNA:
	push cx
	push dx

	;print name:
	mov dl, TableNameColumn
	xor bh, bh
	mov ah, 2
	int 10h

	mov ah, 9
	mov dx, offset NAString
	int 21h


	pop dx
	push dx

	;print score:
	mov dl, TableScoreColumn
	xor bh, bh
	mov ah, 2
	int 10h

	mov ah, 9
	mov dx, offset NAString
	int 21h

	pop dx
	add dh, 3

	pop cx
	loop @@printNA

@@skipPrintNA:
	push [ScoresFileHandle]
	call CloseFile


;wait for an appropriate key:
@@getKey:
	xor ah, ah
	int 16h

	cmp ah, 53h ;Delete
	je @@printBackgroundAgainBeforeDelete

	cmp ah, 1 ;Esc
	jne @@getKey

	ret

@@printBackgroundAgainBeforeDelete:
	;Print background:
	push offset ScoreTableFileName
	push offset ScoreTableFileHandle
	call OpenFile

	push [ScoreTableFileHandle]
	push offset FileReadBuffer
	call PrintFullScreenBMP

	push [ScoreTableFileHandle]
	call CloseFile

	jmp @@createNewFile
endp PrintHighScoreTable