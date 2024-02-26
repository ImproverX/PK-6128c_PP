	.org 00000h
LnPRG1:	.EQU 1024
L_PRG2:	.EQU L_PRG1+LnPRG1
LnPRG2:	.EQU 27460
;
L_STRT:	DI
;инициализация портов ввода/вывода
L_SET:	MVI  A, 88h	; A,B,C (3-0) - вывод, C (7-4) - ввод
	OUT  000h	; ->РУС клавиатуры
	MVI  A, 91h	; B,C (7-4) - вывод,  A,C (3-0) - ввод
	OUT  04h	; ->РУС ПУ
	MVI  A, 0FFh  
	OUT  003h	; входы ие7 = 0FFh (сдвиг экрана)
	OUT  005h	; порт (C) паралл. интерфейса = 0FFh  
	OUT  006h	; порт (B) --//--
;выключение каналов звука
L_RT:	MVI  A, 0A8h	; реж-4,ст.байт-(одновибратор)
	MVI  C, 040h  	; шаг, запись в три таймера
L_VI53:	OUT  008h	; реж-4,ст.байт
	SUB  C		; счет каналов 2,1,0
	JNC  L_VI53	; переход если не все каналы таймера выключены
	XRA  A		; обнулить аккумулятор
	OUT  002h	; Порт В -- рамка и режим экрана 256*256
	OUT  010h	; отключаем КД10 (на всякий случай)
	OUT  011h	; отключаем КД11
	OUT  00Eh	; Распределение памяти: Банк 0 - Банк 1
	MVI  A, 003h
	OUT  00Dh	; Экран из Банка 2
	LXI  H, 07FFEh	; << тест ПЗУ
	MVI  D, 0FFh
	JMP  L_TROM
;
	.db  "Improver"
	RET		; для RST7
	.db  "TEST6128+04"	; метка версии прошивки
;
L_TROM:	MOV  A, M
	XRA  D
	MOV  D, A
	DCR  L
	JNZ	L_TROM
	DCR  H
	JP	L_TROM	; цикл подсчёта КС ПЗУ
	LDA     07FFFh	; КС в ПЗУ
	XRA  D
	JZ      L_STL	; >> всё ок!
	MOV  A, D
	OUT  006h       ; порт (B) ПУ -- вывод КС
L_STP0:	MVI  A, 008h	; включаем РУС/ЛАТ
	OUT  001h	; отправляем в порт C
L_STOP:	JMP     L_STOP	; висим, ждём сброса
;
L_STL:	LXI  H, 00000h
	SPHL		; обнуляем указатель стека и HL
	MOV  E, A	; E=0 (Банк 0 - Банк 1)
	MOV  B, A	; B=0 (порт клавиатуры)
L_LOOP:	OUT  001h	; отправляем в порт C
L_LPW:	DCX  H
	IN   001h	; чтение порта С
	MOV  D, B	; сохраняем предыдущее состояние порта
	MOV  B, A	; обновляем значение состояния порта
	XRA  D		; сравниваем с предыдущим значением
	ANI  0E0h	; маскируем всё, кроме кодов клавиш
	JZ      L_LDN	; изменения есть? нет...
	MOV  A, B	; восстанавливаем значение
	ANI  0E0h	; маскируем всё, кроме кодов клавиш
	CPI  0E0h	; ничего не нажато?
	JZ      L_ZV	; выключаем звук
	CPI  080h	; нажато УС+СС?
	JZ      L_MTST	; переход к тестированию памяти
	CPI  040h	; нажато РУС+СС?
	JZ      L_KBDT	; переход к тестированию клавиатуры
	CPI  020h	; нажато РУС+УС?
	JZ      L_LPAL	; переход к загрузке палитры
	ADD  C		; добавляем признак звука (чтобы отсечь неодновременное отпускание клавиш)
	MVI  C, 001h	; устанавливаем признак наличия звука
	CPI  060h	; нажата РУС/ЛАТ? (80h)
	JZ      L_RUS
	CPI  0A0h	; нажата УС? (40h)
	JZ      L_US
	CPI  0C0h	; нажата СС? (20h)
	JZ      L_SS
	; другие варианты нажатия кнопок -- выключение звука
	; Режим 0 - выдача сигнала прерывания по конечному числу
L_ZV:	MVI  A, 030h	; 0011 0000 -- [канал 0][чт/зп слова][режим 0][двоичный]
	OUT     008h	; РУС м/с ВИ53
	MVI  A, 070h	; 0111 0000 -- [канал 1][чт/зп слова][режим 0][двоичный]
	OUT     008h	; РУС м/с ВИ53
	MVI  A, 0B0h	; 1011 0000 -- [канал 2][чт/зп слова][режим 0][двоичный]
	OUT     008h	; РУС м/с ВИ53
	MVI  C, 000h	; звук выключен
L_LDN:	MOV  A, L
	ORA     H
	JNZ     L_LPW	; цикл ожидания, 65536 раз...
	CMP  C		; На выходе А=0, если С=1, то писк не выводим
	JNZ     L_LDN2
	MVI  H, 030h	; Счётчик 1
L_BEEP:	MVI  L, 040h	; Счётчик 2
L_BPW:	DCR  L
	JNZ     L_BPW	; Задержка 40h циклов
	XRI     001h	; А=0000 000х, режим оперирования битами, инверсия бита 0
	OUT     000h
	DCR  H
	JNZ     L_BEEP	; Цикл, повтор 30h раз
L_LDN2:	MOV  A, E	; загр. конфигурацию памяти
	OUT     00Eh	; отправляем...
			; 33h (Банк 0 - Банк 2), A16x = A15, A15x = 0
			; 22h (Банк 0 - Банк 3), A16x = A15, A15x = A15
			; 11h (Банк 0 - Банк 0), A16x = 0, A15x = 0
			; 00h (Банк 0 - Банк 1), A16x = 0, A15x = A15
	ADI	011h	; следующее значение
	JNC	L_BM	; если не было переноса
	XRA  A
L_BM:	MOV  E, A	; сохраняем
	ANI     001h	; берём последний бит A
	MVI  A, 055h
	JZ      L_PU
	CMA
L_PU:	OUT  006h	; порт (B) ПУ отправляем 55 или AA.
	MOV  A, B
	XRI  08h	; инвертируем РУС/ЛАТ
	JMP     L_LOOP	; цикл мигания индикатором
;
	; Режим 3 - генератор прямоугольных сигналов
L_RUS:	; Значение делителя частоты (1,5 МГц / 1500 = 1 кГц)
	MVI  A, 036h	; 0011 0110 -- [канал 0][чт/зп слова][режим 3][двоичный]
	OUT     008h	; РУС м/с ВИ53
	MVI  A, 0DCh
	OUT     00Bh	; Канал 0
	MVI  A, 005h
	OUT     00Bh	; Канал 0
	MVI  A, 00Fh	; рамка есть
	LXI  D, 00000h	; чем заполняем
	JMP     L_FLM0
;
L_SS:	; Значение делителя частоты (1,5 МГц / 750 = 2 кГц)
	MVI  A, 076h	; 0111 0110 -- [канал 1][чт/зп слова][режим 3][двоичный]
	OUT     008h	; РУС м/с ВИ53
	MVI  A, 0EEh
	OUT     00Ah	; Канал 1
	MVI  A, 002h
	OUT     00Ah	; Канал 1
	LXI  D, 0FFFFh	; чем заполняем
	JMP     L_FLM
;
L_US:	; Значение делителя частоты (1,5 МГц / 500 = 3 кГц)
	MVI  A, 0B6h	; 1011 0110 -- [канал 2][чт/зп слова][режим 3][двоичный]
	OUT     008h	; РУС м/с ВИ53
	MVI  A, 0F4h
	OUT     009h	; Канал 2
	MVI  A, 001h
	OUT     009h	; Канал 2
; заполнение видеопамяти методом записи через стек
	LXI  D, 0A8A8h	; чем заполняем
L_FLM:	XRA  A
L_FLM0:	OUT     002h	; Порт В -- рамка и режим экрана 256*256
	MVI  A, 033h
	OUT	00Eh	; (Банк 0 - Банк 2)
;	OUT     00Dh	; Экран из банка 2
	LXI  SP,00000h	; начало
	XRA  A		; счётчик
L_TMC:	PUSH D		; положить в стек DE, 64 раза
	PUSH D\	PUSH D\	PUSH D\	PUSH D\	PUSH D\	PUSH D\	PUSH D		; 8
	PUSH D\	PUSH D\	PUSH D\	PUSH D\	PUSH D\	PUSH D\	PUSH D\	PUSH D		; 16
	PUSH D\	PUSH D\	PUSH D\	PUSH D\	PUSH D\	PUSH D\	PUSH D\	PUSH D		; 24
	PUSH D\	PUSH D\	PUSH D\	PUSH D\	PUSH D\	PUSH D\	PUSH D\	PUSH D		; 32
	PUSH D\	PUSH D\	PUSH D\	PUSH D\	PUSH D\	PUSH D\	PUSH D\	PUSH D		; 40
	PUSH D\	PUSH D\	PUSH D\	PUSH D\	PUSH D\	PUSH D\	PUSH D\	PUSH D		; 48
	PUSH D\	PUSH D\	PUSH D\	PUSH D\	PUSH D\	PUSH D\	PUSH D\	PUSH D		; 56
	PUSH D\	PUSH D\	PUSH D\	PUSH D\	PUSH D\	PUSH D\	PUSH D\	PUSH D		; 64
	DCR  A
	JNZ     L_TMC	; цикл 256 раз
	LXI  SP,00000h	;
	JMP     L_LDN
;
; сначала проверим озу по адресам FFFEh-FFFFh
L_LPAL:	MVI  A, 033h
	OUT  00Eh	; (Банк 0 - Банк 2)
	LXI  SP,00000h	;
	LXI  D, 0AA55h	; чем заполняем
	PUSH D
	POP  H
	MOV  A, H
	CMP  D
	JNZ     L_LDN	; не нормально, возврат
	XRA  L
	INR  A		; если всё нормально, то обнулится
	JNZ     L_LDN	; не нормально, возврат
	XCHG
	LXI  H, L_PALI	; ссылка на палитру, должна быть по адресам ХХ00h-ХХ0Fh
        EI
        HLT
L_PLL:	MOV  A, L	; счётчик
	OUT     002h	; палитра -- выбор математического цвета
	MOV  A, M
	OUT     00Ch	; палитра -- установка физического цвета
	PUSH PSW
	POP  PSW
	PUSH PSW
	POP  PSW
	DCR  L		; счётчик и ссылка -1
	NOP\ NOP
	OUT     00Ch	; палитра -- установка физического цвета, ещё раз
	JP     L_PLL	; цикл установки палитры, 16 раз
	DI
	XCHG
	LXI  D, 00000h	; чем заполняем
	MVI  A, 2	; цвет бордюра
	OUT     002h	; Порт В -- рамка и режим экрана 256*256
;
	; очистка верхней памяти
	LXI  SP,00000h	; начало
	XRA  A		; счётчик
L_GR0:	PUSH D		; положить в стек DE, 64 раза
	PUSH D\	PUSH D\	PUSH D\	PUSH D\	PUSH D\	PUSH D\	PUSH D		; 8
	PUSH D\	PUSH D\	PUSH D\	PUSH D\	PUSH D\	PUSH D\	PUSH D\	PUSH D		; 16
	PUSH D\	PUSH D\	PUSH D\	PUSH D\	PUSH D\	PUSH D\	PUSH D\	PUSH D		; 24
	PUSH D\	PUSH D\	PUSH D\	PUSH D\	PUSH D\	PUSH D\	PUSH D\	PUSH D		; 32
	PUSH D\	PUSH D\	PUSH D\	PUSH D\	PUSH D\	PUSH D\	PUSH D\	PUSH D		; 40
	PUSH D\	PUSH D\	PUSH D\	PUSH D\	PUSH D\	PUSH D\	PUSH D\	PUSH D		; 48
	PUSH D\	PUSH D\	PUSH D\	PUSH D\	PUSH D\	PUSH D\	PUSH D\	PUSH D		; 56
	PUSH D\	PUSH D\	PUSH D\	PUSH D\	PUSH D\	PUSH D\	PUSH D\	PUSH D		; 64
	DCR  A
	JNZ     L_GR0	; цикл 256 раз
	;
	; Заполнить FFh области (остальное -- нули):
	; E700-ECFF (1), F300-F8FF (2)
	; CD00-D8FF (3)
	; B900-BFFF (4)
	LXI  D, 0FFFFh
	LXI  SP,0ED00h	; (1)
L_GR1:	PUSH D		; положить в стек DE, 3 раза
	PUSH D\	PUSH D
	DCR  A
	JNZ     L_GR1	; цикл 256 раз
	LXI  SP,0F900h	; (2)
L_GR2:	PUSH D		; положить в стек DE, 3 раза
	PUSH D\	PUSH D
	DCR  A
	JNZ     L_GR2	; цикл 256 раз
	LXI  SP,0D900h	; (3)
L_GR3:	PUSH D		; положить в стек DE, 6 раз
	PUSH D\	PUSH D\	PUSH D\	PUSH D\	PUSH D
	DCR  A
	JNZ     L_GR3	; цикл 256 раз
	LXI  SP,0C000h	; (4)
L_GR4:	PUSH D		; положить в стек DE, 3 раза
	PUSH D\	PUSH D
	DCR  A
	JNZ     L_GR4	; цикл 256 раз
	MVI  A, 080h
L_GR5:	PUSH D		; положить в стек DE, 1 раз
	DCR  A
	JNZ     L_GR5	; цикл 128 раз
	LXI  SP,00000h	;
	MVI  D, 040h	; Счётчик 1
L_BP3:	MVI  E, 050h	; Счётчик 2
L_BPW3:	DCR  E
	JNZ     L_BPW3	; Задержка 40h циклов
	XRI     001h	; А=0000 000х, режим оперирования битами, инверсия бита 0
	OUT     000h
	DCR  D
	JNZ     L_BP3	; Цикл, повтор 30h раз
	MVI  C, 001h	; устанавливаем признак наличия звука
	JMP     L_LDN
;
; Проверка озу
L_MTST:	MVI  A, 0A8h	; реж-4,ст.байт-(одновибратор) -- отключение звуков
	MVI  C, 040h  	; шаг, запись в три таймера
L_VIx3:	OUT  08h	; реж-4,ст.байт
	SUB  C		; счет каналов 2,1,0
	JNC	L_VIx3	; переход если не все каналы таймера выключены
;
	LXI  H, 0FF00h	; адрес для проверки переключения банков
	MVI  A, 033h
	MOV  B, A
	OUT  00Eh	; Банк памяти:
			; 33h - Банк 2
			; 22h - Банк 3
			; 11h - Банк 0
			; 00h - Банк 1
	MOV  M, A	; <-33h
	SUI  011h
	OUT  00Eh
	MOV  M, A	; <-22h
	ADI  011h
	OUT  00Eh
	SUB  M		; 	
	JNZ	L_MTA	; <> 33h
	OUT  00Eh	; =00h
	MVI  M, 044h
	MVI  A, 022h
	OUT  00Eh
	SUB  M	
	JNZ	L_MTA	; <> 22h
	OUT  00Eh
	MOV  A, M
	CPI  044h  
	JZ	L_MTB	; == 44h
; проверку подключения банка 0 (011h) не делаем -- эмулятор глючит
L_MTA:	MVI  B, 0	; обнуляем -- переключение банок не работает
L_MTB:	MOV  A, B	; A=033h (0)
; сначала проверим озу по адресам 8000h-FFFFh
L_MT0:	OUT  00Eh	; Банк памяти:
			; 33h - Банк 2
			; 22h - Банк 3
			; 11h - Банк 0
			; 00h - Банк 1
	MOV  B, A	; сохраняем
	ORI  001h	; маскируем нулевой бит, чтобы не переключалось ПЗУ на ПК-6128ц++
	OUT  00Dh	; Банк для экрана (0/2)
	; Значение делителя частоты (1,5 МГц / 3000 = 0,5 кГц)
	MVI  A, 036h	; 0011 0110 -- [канал 0][чт/зп слова][режим 3][двоичный]
	OUT     008h	; РУС м/с ВИ53
	MVI  A, 0B8h
	OUT     00Bh	; Канал 0
	MVI  A, 00Bh
	OUT     00Bh	; Канал 0
	XRA  A		; выключаем индикатор РУС/ЛАТ (если он был включён)
	OUT  01h	; отправляем в порт C
; тестирование памяти методом простого чтения/записи
	LXI  H, 08000h	; начало
	LXI  D, 0FF00h	; контр.код 1
L_MT1:	MOV  M, D
	MOV  A, M
	XRA  D
	JNZ     L_MERh	; не совпало, вывод ошибки и сброс
	MOV  M, E
	MOV  A, M
	XRA  E
	JNZ     L_MERh	; не совпало, вывод ошибки и сброс
	INR  L
	JNZ     L_MT1	; цикл LO
	INR  H
	JNZ     L_MT1	; цикл HI
;
	MVI  H, 080h	; начало
	LXI  D, 0AA55h	; контр.код 2
L_MT2:	MOV  M, D
	MOV  A, M
	XRA  D
	JNZ     L_MERh	; не совпало, вывод ошибки и сброс
	MOV  M, E
	MOV  A, M
	XRA  E
	JNZ     L_MERh	; не совпало, вывод ошибки и сброс
	INR  L
	JNZ     L_MT2	; цикл LO
	INR  H
	JNZ     L_MT2	; цикл HI
	; Значение делителя частоты (1,5 МГц / 1500 = 1 кГц)
	MVI  A, 036h	; 0011 0110 -- [канал 0][чт/зп слова][режим 3][двоичный]
	OUT     008h	; РУС м/с ВИ53
	MVI  A, 0DCh
	OUT     00Bh	; Канал 0
	MVI  A, 005h
	OUT     00Bh	; Канал 0
; тестирование памяти методом чтения/записи через стек
;	LXI  SP,00000h	; начало
	LXI  D, 06699h	; контр.код.1
L_MTs0:	XRA  A
	MOV  C, A	; счётчик
L_MTs1:	PUSH D		; положить в стек DE
	POP  H		; считать в HL
	ORA  L
	XRA  E
	XRA  H
	XRA  D
	JNZ     L_MERR	; не совпало, вывод ошибки и сброс
	PUSH D		; ещё раз положить в стек, для сдвига
	DCR  C
	JNZ     L_MTs1	; цикл LO
	LXI  H, 00000h
	DAD  SP
	MOV  A, H
	ADD  L
	CPI  080h
	JNZ     L_MTs0	; цикл до SP = 8000h
;
	LXI  SP,00000h	; начало
	LXI  D, 09966h	; контр.код.2
L_MTs2:	XRA  A
L_MTs3:	PUSH D		; положить в стек DE
	POP  H		; считать в HL
	ORA  L
	XRA  E
	XRA  H
	XRA  D
	JNZ     L_MERi	; не совпало, вывод ошибки и сброс
	PUSH B		; положить в стек счётчик, для следующего теста
	INR  C
	JNZ     L_MTs3	; цикл LO
	LXI  H, 00000h
	DAD  SP
	MOV  A, H
	ADD  L
	CPI  080h
	JNZ     L_MTs2	; цикл до SP = 8000h
;
	MVI  E, 001h	; LXI  D, 0CC01h	; контр.код (инверсия)
L_MTr2:	MOV  A, B
	CMA
	MOV  D, A
	XRA  A
L_MTr3:	POP  H		; считать в HL
	DAD  D		; HL = HL + (контр.код) (должно обнулиться)
	ORA  L
	ORA  H
	JNZ     L_MERR	; что-то не совпало, вывод ошибки и сброс
	INX  D
	DCR  C
	JNZ     L_MTr3	; цикл LO
	LXI  H, 00000h
	DAD  SP
	MOV  A, H
	ADD  L
	JNZ     L_MTr2	; цикл до SP = 0000h

	; Значение делителя частоты (1,5 МГц / 1000 = 1,5 кГц)
	MVI  A, 036h	; 0011 0110 -- [канал 0][чт/зп слова][режим 3][двоичный]
	OUT     008h	; РУС м/с ВИ53
	MVI  A, 0EBh
	OUT     00Bh	; Канал 0
	MVI  A, 003h
	OUT     00Bh	; Канал 0

; очистка памяти с проверкой
	XRA  A		; для очистки
	LXI  H, 08000h	; начало
L_MTc3:	MOV  M, A
	ORA  M		; проверка очистки
	JNZ     L_MERh	; что-то не совпало, вывод ошибки и сброс
	INR  L
	JNZ     L_MTc3	; цикл LO
	INR  H
	JNZ     L_MTc3	; цикл HI
;
	MVI  A, 0A8h	; реж-4,ст.байт-(одновибратор) -- отключение звуков
	MVI  C, 040h  	; шаг, запись в три таймера
L_VIx2:	OUT  08h	; реж-4,ст.байт
	SUB  C		; счет каналов 2,1,0
	JNC	L_VIx2	; переход если не все каналы таймера выключены
;
; Переключение банка памяти
	MOV  A, B
	SUI	011h	; следующее значение банка
	JP	L_MT0	; если < 80h -- цикл
;
; тестирование памяти пройдено без ошибок
;	JMP	L_STL
;
; копируем дописанную программу в память с адреса 0100h (без проверки)
	LXI  H, 00001h	;
	MVI  M, 0C3h	; << 0001: JMP ...
	INR  L
	MVI  M, 000h
	INR  L
	MVI  M, 001h	; << 0001: ... 00100h
	XRA  A
L_CLR2:	INR  L
	MOV  M, A
	JNZ	L_CLR2	; очистка до 00FFh
	MVI  M, 0F3h	; << 0000: DI
	INR  H
;	LXI  H, 00100h	; куда пишем
	IN   001h	; чтение порта С
	ANI  040h	; маскируем всё, кроме кода УС
	JZ      L_KUS	; нажата УС? -- запуск второй программы
	LXI  B, (LnPRG1+1)/2	; счётчик
	LXI  SP,L_PRG1	; начало блока
	JMP     L_CP
;
L_KUS:	LXI  B, (LnPRG2+1)/2 + 256	; счётчик, +256 из-за того, что размер не круглый
	LXI  SP,L_PRG2	; начало блока
L_CP:	POP  D
	MOV  M, E
	INX  H
	MOV  M, D
	INX  H
	DCR  C
	JNZ     L_CP	; цикл LO
	DCR  B
	JNZ     L_CP	; цикл HI копирования
;
;	LXI  H, 00000h	;
;	MVI  M, 0F3h	; << 0000: DI
;	INR  L
;	MVI  M, 0C3h	; << 0001: JMP ...
;	INR  L
;	MVI  M, 000h
;	INR  L
;	MVI  M, 001h	; << 0001: ... 00100h
L_WAIT:	IN   001h	; чтение порта С
	XRI  008h	; инвертируем индикатор РУС/ЛАТ
	ORI  002h	; установка D[1]=1 (выкл.реле для автозапуска Вектора)
;	NOP \ NOP
	OUT  001h	; отправляем в порт C
	ANI  080h	; маскируем всё, кроме кода РУС/ЛАТ
	JZ      L_STL	; нажата РУС/ЛАТ? -- возврат к первому этапу
	XRA  A
	OUT  00Fh	; Сброс ПК-6128ц
	MVI  C, 040h
L_W1:	DCR  A
	JNZ     L_W1
	DCR  C
	JNZ     L_W1
	JMP     L_WAIT	; цикл задержки -- ждём БЛК+СБРОС для продолжения
;
; вывод ошибки проверки памяти
L_MERi:	MOV  C, A	; сохраняем А
	MOV  A, B
	JMP     L_MEx
;	
L_MERh:	MOV  C, A	; сохраняем А
	MOV  A, H
	RRC
	CMA
L_MEx:	ANI  030h	; маскируем 5 и 4 биты
	INR  A
	MOV  B, A	; номер банка памяти
	MOV  A, C	; восстанавливаем А
L_MERR:	OUT  006h	; порт (B) ПУ -- вывод сбойных битов
	MOV  A, B
	DCR  A		; 40..31 -> 3F..30 ...
	ANI  030h	; маскируем 5 и 4 биты
	RLC
	RLC
	OUT  005h	; порт (C) ПУ -- вывод в 7 и 6 битах номера банка памяти
	; 0 -- банк 8000h-9FFFh
	; 1 -- банк A000h-BFFFh
	; 2 -- банк C000h-DFFFh
	; 3 -- банк E000h-FFFFh
	JMP     L_STP0	; висим, ждём сброса
;
L_KBDT:	MVI  D, 006h	; для индикатора РУС/ЛАТ (выключен)
	MVI  A, 00Fh	; рамка есть
	OUT     002h	; Порт В -- рамка и режим экрана 256*256
	;выключение каналов звука
	MVI  A, 0A8h	; реж-4,ст.байт-(одновибратор)
	MVI  C, 040h  	; шаг, запись в три таймера
L_ZV2:	OUT  008h	; реж-4,ст.байт
	SUB  C		; счет каналов 2,1,0
	JNC  L_ZV2	; переход если не все каналы таймера выключены
;
	; очистка верхней памяти
	LXI  D, 00000h
	LXI  B, 0FF00h	; нарисовать линию внизу экрана
	LXI  SP,00000h	; начало
	MVI  A, 033h
	OUT  00Eh	; (Банк 0 - Банк 2)
	XRA  A		; счётчик
L_CLR:	PUSH B		; положить в стек DE, 64 раза
	PUSH D\	PUSH D\	PUSH D\	PUSH D\	PUSH D\	PUSH D\	PUSH D		; 8
	PUSH D\	PUSH D\	PUSH D\	PUSH D\	PUSH D\	PUSH D\	PUSH D\	PUSH D		; 16
	PUSH D\	PUSH D\	PUSH D\	PUSH D\	PUSH D\	PUSH D\	PUSH D\	PUSH D		; 24
	PUSH D\	PUSH D\	PUSH D\	PUSH D\	PUSH D\	PUSH D\	PUSH D\	PUSH D		; 32
	PUSH D\	PUSH D\	PUSH D\	PUSH D\	PUSH D\	PUSH D\	PUSH D\	PUSH D		; 40
	PUSH D\	PUSH D\	PUSH D\	PUSH D\	PUSH D\	PUSH D\	PUSH D\	PUSH D		; 48
	PUSH D\	PUSH D\	PUSH D\	PUSH D\	PUSH D\	PUSH D\	PUSH D\	PUSH D		; 56
	PUSH D\	PUSH D\	PUSH D\	PUSH D\	PUSH D\	PUSH D\	PUSH D\	PUSH D		; 64
	DCR  A
	JNZ     L_CLR	; цикл 256 раз
	LXI  SP,00000h	;
L_KLP0:	MVI  E, 0FFh	; код последней нажатой клавиши
L_KLP:	MVI  A, 088h	; A,B,C (3-0) - вывод, C (7-4) - ввод
	OUT     000h	; -> РУС клавиатуры (режим "дисплей")
	MOV  A, D	; индикатор РУС/ЛАТ
	OUT     000h	; отправляем в порт C, 3 бит
	MVI  A, 0Bh	; УСТАНОВКА ЦВЕТА БОРДЮРА.
	OUT     002h
	MOV  A, E
;;	MVI  A, 0FFh	; УСТАНОВКА ВЕРТИКАЛЬНОГО ПОЛОЖЕНИЯ ЭКРАНА.
	OUT     003h	; сдвиг = коду клавиши
;;	CMP  E
	CPI     0FFh
	JZ	NoBEEP
;;	MOV  A, E
	OUT     006h	; порт (B) ПУ -- вывод кода клавиши
;
	XRA  A		; писк
	MVI  H, 030h	; Счётчик 1
L_BP2:	MVI  L, 040h	; Счётчик 2
L_BPW2:	DCR  L
	JNZ     L_BPW2	; Задержка 40h циклов
	XRI     001h	; А=0000 000х, режим оперирования битами, инверсия бита 0
	OUT     000h
	DCR  H
	JNZ     L_BP2	; Цикл, повтор 30h раз
;
	MVI  D, 006h	; для индикатора РУС/ЛАТ (выключен)
	IN      007h	; порт (A) ПУ -- ввод кода, для проверки ПУ
	CMP  E
	JNZ     NoBEEP	; не совпало -- пропускаем
	ANI     00Fh
	MOV  B, A
	RLC
	RLC
	RLC
	RLC
	OUT     005h	; порт (C) ПУ, биты 4-7 на вывод
	IN      005h	; порт (C) ПУ, ввод битов 0-3
	ANI     00Fh
	CMP  B
	JNZ     NoBEEP	; не совпало -- пропускаем
	INR  D		; индикатор РУС/ЛАТ включен
;
NoBEEP:	EI
	HLT		; Задержка до прерывания
	DI
	MVI  A, 08Ah	; работаем с клавиатурой
	OUT     000h	; установка РУС ВВ55
	XRA  A
	OUT     003h
	IN      002h
	INR  A
	JZ      L_KLP0	; > клавиши не нажаты, пропускаем
	LXI  B, 000FEh	; C=1111 1110
	MOV  A, C
L_Krow:	OUT     003h
	IN      002h
	CPI     0FFh
	JNZ     L_KEY	; > была нажата клавиша, в В столбец, в А строка
	INR  B
	MOV  A, C
	RLC
	MOV  C, A
	JC      L_Krow	; цикл по столбцам
	JMP     L_KLP0
;
L_KEY:	MVI  C, 0FFh
L_SDV:	INR  C
	RRC
	JC      L_SDV	; в С номер строки
	MOV  A, B
	ADD  A
	ADD  A
	ADD  A		; столбец * 8
	ADD  C		; + строка
	MOV  E, A
	JMP     L_KLP	; возврат
;
	.ORG 0500h	; палитра (должна быть выровнена по адресам с ХХ00h)
	.db 000h	; 0 - |        | чёрный		<-
	.db 052h	; 1 - | ■ ■  ■ | серый
	.db 0A4h	; 2 - |■ ■  ■  | серый светлее
	.db 0EDh	; 3 - |■■■ ■■ ■| серый светлее светлее
	.db 0F6h	; 4 - |■■■■ ■■ | почти белый
	.db 005h	; 5 - |     ■ ■| тёмно красный
	.db 006h	; 6 - |     ■■ | почти красный
	.db 007h	; 7 - |     ■■■| красный	<-
	.db 02Dh	; 8 - |  ■ ■■ ■| жёлтый (boot)
	.db 028h	; 9 - |  ■ ■   | тёмно зелёный
	.db 030h	; A - |  ■■    | почти зелёный
	.db 038h	; B - |  ■■■   | зелёный	<-
	.db 080h	; C - |■       | тёмно синий (boot)
	.db 0C0h	; D - |■■      | синий		<-
	.db 03Fh	; E - |  ■■■■■■| светло жёлтый
L_PALI:	.db 0FFh	; F - |■■■■■■■■| белый		<-
;
L_PRG1:	.db 0FFh
;
;---------------------------------------------------------------------------------
; сюда дописываются "Тест техпрогона" и "Тест устройств" в бинарном виде
;---------------------------------------------------------------------------------
;
	.ORG 07FF8h
L_SWMEM:NOP
	XRA A
	OUT 00Dh	; переключение на другой банк ПЗУ
	JMP	L_START
	.db 000h	; контрольная сумма этой части ПЗУ
	.END
