;
; Macros to 'bypass' conditional jumps' limited range.
;

macro je_Far label
   local SKIP
   jne SKIP
   jmp label
SKIP:       
endm


macro jne_Far label
	local SKIP
	je SKIP
	jmp label
SKIP:
endm


macro ja_Far label
	local SKIP
	jbe SKIP
	jmp label
SKIP:
endm


macro jb_Far label
	local SKIP
	jae SKIP
	jmp label
SKIP:
endm


macro jz_Far label
	local SKIP
	jnz SKIP
	jmp label
SKIP:
endm


macro jbe_Far label
	local SKIP
	ja SKIP
	jmp label
SKIP:
endm


macro jae_Far label
	local SKIP
	jb SKIP
	jmp label
SKIP:
endm


macro loop_Far label
	local SKIP
	dec cx
	cmp cx, 0
	je SKIP
	jmp label

SKIP:
endm