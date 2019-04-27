;
; Macro to 'bypass' conditional loops' limited range.
;

macro loop_Far label
	local SKIP
	dec cx
	jz SKIP
	jmp label

SKIP:
endm