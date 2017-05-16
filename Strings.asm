;
; Strings saved here for printing to user + debugging
;

DATASEG
	ScoreString				db	'Score: ', '$'
	LevelString				db	'Level: ', '$'

	GameOverString			db	'Game Over!$'

	WinString				db	'You Win!$'

	YouEarnedXString		db	'You earned $'
	ScoreWordString			db	' Score!$'

	PerfectLevelString		db	'Perfect level, +5 Score!$'
	HitString				db	'You got hit, -5 Score :($'

	NAString				db	'N/A$'

	RankString				db	'Rank$'
	NameString				db	'Name$'
	JustScoreString			db	'Score$'

	EnterYourNameString		db	'Please enter your name: $'

	ScoreSavedString		db	'Your score was saved!$'


;Debug strings:
	OpenErrorMsg			db 'File Open Error', 10,'$'
	CloseErrorMsg			db 'File Close Error', 10,'$'

	PointerSetErrorMsg		db 'Pointer Set Error', 10, '$'
	ReadErrorMsg			db 'Read Error', 10, '$'


	PlayersInTableString	db	' Players in table$'

	NoNeedToSortString		db	'0 or 1 score in table, no need to sort$'
	ReplacedRanksString		db	'Replaced ranks $'
	AndWordString			db	' and $'