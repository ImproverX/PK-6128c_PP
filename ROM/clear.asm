	.ORG 00000h
L_START:DI
	JMP	L_SWMEM
	.db 0FFh
;==========
	.ORG 07FF8h
L_SWMEM:MVI A, 001h
	OUT 00Dh	; переключение на другой банк ПЗУ
	JMP	L_START
	.db 000h
	.end
