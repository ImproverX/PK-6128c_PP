M_SP	.EQU    0DCF0h	; DW указатель стека
M_PP1	.EQU    0DCF1h	; DW ссылка на подпрограмму 1
M_PP2	.EQU    0DCF4h	; DW ссылка на подпрограмму 2
M_HPIC	.EQU    0DCF7h	; DB высота картинки
M_VAR1	.EQU    0DED0h	; DB/DW тут хранится указатель стека (КД) или начало загрузки
M_DSK	.EQU	0DED2h	; DB номер КД
M_DKD	.EQU    0DED3h	; DB номер дорожки КД
M_SKD	.EQU    0DED4h	; DB номер сектора КД
M_BKD	.EQU    0DED5h	; DW адрес буфера под чтение с КД
M_RKD	.EQU    0DED7h	; DW адрес начала сектора на КД
M_VEF1	.EQU    0DEF1h	;
M_VEF4	.EQU    0DEF4h	; DB инверсный/прямой сигнал МГ
M_VEF6	.EQU    0DEF6h	; DB скорость чтения с МГ
S_KBD	.EQU    0DEF7h	; DB код нажатых клавиш
B_DRV	.EQU    0E400h	; буфер для чтения НГМД/НЖМД
M_BT	.EQU	0DED2h	; загрузочный сектор НГМД/НЖМД (20h байт):
			; DW начальный адрес для загрузки
M_SKB	.EQU	M_BT+4	; DB количество секторов (1к) для загрузки
M_FM9l	.EQU	0E050h	; подпрограмма для FM9
X_E053	.EQU	0E053h
X_E0D8	.EQU	0E0D8h
;
;F3_PRG			; Бейсик
F3_LEN	.EQU    03300h	; размер
#DEFINE F4_PRG F3_PRG+F3_LEN	; Монитор СуперМонстр
F4_LEN	.EQU    03D00h	; размер в блоках
;
L_TEST:	.EQU	07FF8h	; адрес ПП переключения на тестовую прошивку
;
	.ORG    00000h
L_0000:	DI
	MVI  A, 091h	; B,C (7-4) - вывод,  A,C (3-0) - ввод
	OUT     004h	; -> РУС ПУ
	MVI  A, 088h	; A,B,C (3-0) - вывод, C (7-4) - ввод
	OUT     000h	; -> РУС клавиатуры
	MVI  A, 068h	; выключение канала 1 звука
	OUT     008h	; <- реж-4,ст.байт-(одновибратор)
	MVI  A, 0A8h	; выключение канала 2 звука
	OUT     008h	; <- реж-4,ст.байт-(одновибратор)
	; Значение делителя частоты (1,5 МГц / 1500 = 1 кГц)
	MVI  A, 036h	; 0011 0110 -- [канал 0][чт/зп слова][режим 3][двоичный]
	OUT     008h	; РУС м/с ВИ53
	MVI  A, 0DCh
	OUT     00Bh	; Канал 0
	MVI  A, 005h
	OUT     00Bh	; Канал 0
	XRA  A		; обнулить аккумулятор
	OUT     002h	; Порт В -- рамка и режим экрана 256*256
	OUT     010h	; отключаем КД10 (на всякий случай)
	OUT     011h	; отключаем КД11
	OUT     00Eh	; Распределение памяти: Банк 0 - Банк 1
	OUT     00Dh	; Экран из Банка 1
	LXI  SP,M_SP
	JMP	L_NXT
;
	.db  "  Improver"	; метка версии прошивки
	RET		; для RST7
	.db  "BOOT6128+02"
;
L_NXT:	LXI  H, 0C13Eh
	PUSH H		; примитивная проверка памяти...
	POP  D		; D = C1h, E = 3Eh (считано)
	MOV  A, L	; A = 3Eh (записанное значение)
	SUB  E		; A = A - E
	ADD  H		; A = A + H (+записанное значение)
	SUB  D		; A = A - D
	JNZ     L_TEST	; >> не совпало, переключение не тестовую прошивку
	LXI  B, 08000h	; счётчик
	IN      001h
	ANI     040h	; выделить нажатие клавиши УС (C=40H - маска)
	JNZ     L_0039	; если не нажата УС >>>
	MVI  B, 010h	; счётчик
L_0039:	LXI  SP,00000h	; стартовый адрес
	LXI  H, 00000h	; чем заполнять
L_CLRM:	PUSH H
	DCR  C
	JNZ     L_CLRM
	DCR  B
	JNZ     L_CLRM	; цикл очистки памяти
	ANA  A	
	JZ	L_NXT2	; была нажата УС >>>
	MVI  A, 028h	; выключение канала 0 звука (отключение писка)
	OUT     008h	; <- реж-4,ст.байт-(одновибратор)
	MVI  A, 0AAh
	OUT     00Eh	; Распределение памяти: Банк 2 - Банк 3
	MVI  B, 080h	; счётчик	
L_CLR2:	PUSH H
	DCR  C
	JNZ     L_CLR2
	DCR  B
	JNZ     L_CLR2	; циклы полной очистки памяти
	XRA  A
	OUT     00Eh	; Распределение памяти: Банк 0 - Банк 1
L_NXT2:	OUT     001h	; выставить в порт C ноль (вкл.мотор,погасить рус.)
	LXI  SP,M_SP	; стек рабочий
;	MOV  B, A	; B = 00h
	MVI  A, 028h	; выключение канала 0 звука (отключение писка)
	OUT     008h	; <- реж-4,ст.байт-(одновибратор)
	LXI  D, 00009h	; высота строки
	MVI  C, 0FFh	; C = 0FFh, теперь рисуем загрузочную таблицу
L_0059:	MOV  H, B
	MOV  L, D	; L = 0
	CALL    L_0141	; вычисление координат
	DCR  L		; на строку ниже
	MOV  M, C
	DAD  D		; +9 строк
	MOV  M, C
	INR  L		; +1 строка
	MVI  M, 081h
	INR  B		; счётчик
	JNZ     L_0059	; цикл рисования таблицы ^^^
	LXI  H, L_06CB	; надпись ВЕКТОР-06Ц
	LXI  D, 0C4E9h	; адрес в экране
	MVI  A, 007h	; число столбцов
	CALL    L_0172	; вывод рисунка на экран
	LXI  H, L_00EF	; адрес ПП окончания загрузки ...
	PUSH H		; ... поместить в стек
	MVI  A, 0C3h	; в А код "JMP"
	STA     M_PP1	; JMP по адресу 0DCF1h
	STA     M_PP2	; JMP по адресу 0DCF4h
	CALL    L_0107	; запись палитры + опрос клавиатуры
	LDA     S_KBD	; читать код клавиши
	CPI     0FBh	; клавиша АР2 / УС+АР2 ?
	JZ      L_0857	; >> загрузка из РС через порты ПУ-LPT
	CPI     07Fh	; клавиша F5 / УС+F5 ?
	JZ      L_00E0	; >> загрузка из МППЗУ
	IN      001h
	ANI     040h	; Проверка нажатия УС
	LDA     S_KBD
	JNZ     L_00A6	; (УС не нажата)
	CPI     0BFh	; клавиши УС+F4
	JZ      L_0819	; >> реанимация 0 блока монитора (режим загрузки детектируется)
	CPI     0FDh	; клавиши УС+СТР
	JZ      L_07B6	; >> загрузка модуля выгрузки данных через ПУ (в мониторе)
	CPI     0F7h	; клавиши УС+F1
	JZ      L_TEST	; >> переключение не тестовую прошивку
	MVI  A, 0F7h	; в остальных случаях с УС -- магнитофон
L_00A6:	CPI     0F7h	; клавиша F1 ?
	JZ      L_042B	; >> магнитофон
	CPI     0EFh	; клавиша F2 ?
	JZ      L_00D4	; >> жесткий диск
	CPI     0DFh	; клавиша F3 ?
	JZ      L_07C8	; >> Бейсик
	CPI     0BFh	; клавиша F4 ?
	JZ      L_07AD	; >> Монитор СуперМонстр
	CPI     0E7h	; клавиши F1+F2 ?
	JZ      L_00DA	; >> загрузка с флоповода
	CPI     0D7h	; клавиши F1+F3 ?
	JZ      L_00E6	; >> сетевой адаптер
	CPI     0FEh	; клавиша [влево-вверх] ?
	JZ      L_FM9	; >> FM9
	CPI     07Bh	; клавиши F5+AP2 ?
	JZ      L_07F9	; >> тест ПЗУ
	CALL    L_04FA	; проверка наличия КД
	JZ      L_0547	; >>> переход на загрузку с КД
L_00D4:	CALL    L_CHDD	; проверка наличия ХДД
	JZ      L_067B	; >>> переход на загрузку с диска
L_00DA:	CALL    L_035A	; проверка по in 19 (дисковод)
	JZ      L_0365	; >>> загрузка с флоповода
L_00E0:	CALL    L_030A	; проверка наличия МППЗУ
	JNZ     L_033C	; >>> загрузка из МППЗУ
L_00E6:	CALL    L_0195	; проверка наличия сетевого адаптера
	JNZ     L_01C6	; >>> загрузка через сетевой адаптер
	JMP     L_042B	; >>> загрузка с магнитофона
;
L_00EF: CALL    L_NN	; << загрузка окончена
	MVI  A, 003h	; установка PC[1]=1 (выкл.реле)
	OUT     000h
	OUT     00Fh	; сброс ПК6128
L_00F6:	EI
	HLT
	INX  B
	MOV  A, C
	ANI     008h
	RAR
	RAR
	RAR
	ADI	006h
	OUT     000h
	JMP     L_00F6	; ожидание БЛК-СБРОС
;
L_0107: EI		; запись палитры и опрос клавиатуры
	HLT
	DI
	PUSH B
	LXI  H, 02D80h	; загружаем цвет 1 в L и цвет 2 в H
	LXI  D, 0100Fh	; D - счётчик, E - физ.цвет
L_PL16:	MOV  A, E
	OUT     002h	; палитра -- выбор математического цвета
	ANI     002h
	MOV  A, L	; A = L, если (физ.цвет & 06) = 0
	JZ      L_COL1
	MOV  A, H	; и A = H, если (физ.цвет & 06) <> 0
L_COL1:	OUT     00Ch	; палитра -- установка физического цвета
	PUSH PSW
	POP  PSW
	PUSH PSW
	POP  PSW	; задержка
	DCR  E
	DCR  D		; (счётчик -1)
	OUT     00Ch	; палитра -- установка физического цвета, ещё раз
	JNZ     L_PL16	; цикл установки палитры, 16 раз
;
	MVI  A, 08Ah	; A,C (3-0) - вывод, B,C (7-4) - ввод
	OUT     000h	; -> РУС клавиатуры
	MVI  A, 0FDh	; выбор линейки клавиатуры
	OUT     003h	; в порт А (клавиатура)
	IN      002h	; читать код клавиши из порта
	STA     S_KBD	; сохранить код клавиши в ЯП 0DEF7h
	MVI  A, 088h	; A,B,C (3-0) - вывод, C (7-4) - ввод
	OUT     000h	; -> РУС клавиатуры
;
	XRA  A
	OUT     002h	; в порт B -- цвет бордюра
	DCR  A
	OUT     003h	; в порт А -- входы ие7 = 0FFh (сдвиг экрана)
	POP  B
	RET
;
L_0141:	PUSH D		; вычисление координат загрузочной таблицы
	MOV  A, L
	RLC
	RLC
	RLC
	MOV  L, A
	MOV  A, H
	RAR
	ANI     070h
	MOV  D, A
	RAR
	ADD  D
	ADD  L
	ADI     018h
	MOV  L, A
	MOV  A, H
	ANI     01Fh
	ADI     0C0h
	MOV  H, A
	POP  D
	RET
;
L_015A:	PUSH H		; <<< заполнение блока, HL=начало
	PUSH B
	CALL    L_0141	; > вычисление координат
	MVI  A, 008h
	ADD  L		; A = L + 8
	MVI  C, 07Eh	; чёрточка блока
L_0164:	MOV  M, C
	INR  L
	CMP  L
	JNZ     L_0164
	POP  B
	POP  H
	RET
;
L_016D:	MVI  A, 002h	; число столбцов   <<< ПП отрисовки картинки
L_016F:	LXI  D, 0D8E2h	
L_0172:	MOV  B, M	; считываем высоту картинки  << надпись ВЕКТОР...
	INX  H
L_0174:	STA     M_HPIC	; столбцы
;	MVI  A, 07Fh
;	ANA  B
;	MOV  C, A
	MOV  C, B
	PUSH D
L_017C:	;MOV  A, B
	;ORA  A		; B >= 80h ?
	DCR  C
	MOV  A, M
	STAX D
	INX  D
	JP      L_0186	; не двойная высота
	STAX D
	INX  D
L_0186:	INX  H
	MVI  A, 07Fh
	ANA  C
	JNZ     L_017C
	POP  D
	INR  D
	LDA     M_HPIC
	DCR  A
	JNZ     L_0174
	RET
;
;===================================================================
L_0195:	MVI  B, 004h	; << проверка наличия сетевого адаптера
	IN      007h	; <- порт А ПУ
	ORI     0E0h
	MOV  C, A
	MVI  A, 08Bh	; 1000 1011
	OUT     004h	; -> РУС ПУ
L_01A0:	MOV  A, C
	OUT     007h	; -> порт А ПУ
	XTHL
	XTHL
	IN      005h	; <- порт С ПУ
	ANI     008h
	JZ      L_NN	; >>> сетевого адаптера нет
	MVI  A, 07Fh
	ANA  C
	OUT     007h	; -> порт А ПУ
	IN      005h	; <- порт С ПУ
	CMA
	ANI     008h
	JZ      L_NN	; >>> сетевого адаптера нет
	DCR  B
	JNZ     L_01A0	; цикл, 4 раза
	ORA  A
	JZ      L_NN	; >>> сетевого адаптера нет
L_01C1:	MVI  A, 09Bh	; A,B,C - ввод, режим 0 (1001 1011)
	OUT     004h	; -> РУС ПУ
	RET		; >>> сетевой адаптер обнаружен
;
; ---------------------------------------------------------
L_01C6:	;CALL    L_0620	; << загрузка через сетевой адаптер
	LXI  H, L_0779	; картинка сети
	CALL    L_016D	; отрисовка картинки
	LXI  H, L_02A8
	SHLD    M_PP1+1	; 0DCF2h
	LXI  H, L_01D8
	SHLD    M_PP2+1	; 0DCF5h
L_01D8:	CALL    L_01C1	; <<<<<<<<<<<<<<< PP2
	IN      007h
	ANI     01Fh
	MOV  C, A
	MVI  B, 00Ah
L_01E2:	IN      005h
	ANI     070h
	CPI     040h
	JNZ     L_01D8
	IN      006h
	ANI     01Fh
	CMP  C
	JNZ     L_01D8
	DCR  B
	JNZ     L_01E2
	IN      006h
	MOV  B, A
	MVI  A, 098h
	OUT     004h
	MOV  A, C
	OUT     006h
	XRA  A
	OUT     005h
	MVI  D, 0FAh
L_0206:	DCR  D
	JZ      L_01D8
	IN      005h
	ANI     070h
	CPI     070h
	JNZ     L_0206
	CALL    L_01C1
	MOV  A, B
	ANI     0E0h
	JNZ     L_01D8
	MVI  E, 003h
L_021E:	MVI  A, 008h	; <<<<<<<<<<<<<<<
	CALL    M_PP1	; >>>
	CPI     055h
	JZ      L_022D
	CPI     0AAh
	JNZ     M_PP2	; >>>
L_022D:	DCR  E
	JNZ     L_021E
L_0231:	CALL    L_02E6
	MOV  E, A
	MOV  A, M
	ORA  A
	JNZ     L_0231
	LXI  H, M_VEF1
	MOV  A, M
	DCX  H
	CMP  M
	JNZ     M_PP2	; >>>
	MOV  D, A
	DCX  H
	MOV  B, M
L_0246:	CALL    L_02E6
	PUSH PSW
	MOV  A, M
	ORA  A
	JZ      L_0282
	ADD  A
	ADD  A
	ADD  A
	ADD  A
	ADD  A
	MOV  C, A
	POP  PSW
	INX  H
	MOV  A, M
	CMP  E
	JNZ     L_0246
	PUSH D
	PUSH B
	INX  H
	LXI  D, 0207Eh	; 7Е -- чёрточка блока, 20 -- счётчик
L_0262:	MOV  A, M
	STAX B
	LDAX B
	XRA  M
	MOV  M, A
	INX  H
	INR  C
	DCR  D
	JNZ     L_0262
	POP  B
	MOV  L, C
	MOV  H, B
	CALL    L_0141	; вычисление координат загрузочной таблицы
	MOV  M, E
	POP  D
	CALL    L_0297
	JZ      L_0246
	MOV  A, D
	CPI     001h
	JNZ     L_0246
	RET
;
L_0282:	POP  PSW
	SUB  E
	JZ      L_0246
	INR  A
	JNZ     L_0000	; сброс
	CALL    L_0297
	JZ      L_0000	; сброс
	DCR  E
	INR  B
	DCR  D
	JMP     L_0246
;
L_0297:	MVI  L, 000h
	MOV  H, B
	CALL    L_0141	; вычисление координат загрузочной таблицы
L_029D:	MOV  A, M
	ANA  A
	RZ
	INX  H
	CPI     081h
	JNZ     L_029D
	ANA  A
	RET
;
L_02A8: PUSH D		; <<<<<<<< PP1
	MVI  D, 070h
	CPI     0FFh
	CZ      L_02DD
	CALL    L_02B5
	POP  D
	RET
;
L_02B5: MVI  E, 060h
L_02B7: IN      005h
	ANA  D
	CPI     040h
	JZ      L_0000	; сброс
	CMP  E
	JNZ     L_02B7
	IN      006h
	PUSH PSW
	MVI  A, 09Ah
	OUT     004h
	XRA  A
	OUT     005h
L_02CD: DCR  E
	JZ      L_02D8
	IN      005h
	ANA  D
	CMP  D
	JNZ     L_02CD
L_02D8: CALL    L_01C1
	POP  PSW
	RET
;
L_02DD: CALL    L_02B5
	CPI     0E6h
	JNZ     L_02DD
	RET
;
L_02E6:	PUSH B
	PUSH D
	LXI  H, M_VAR1
L_02EB:	PUSH H
	LXI  B, 00023h
	MVI  A, 0FFh
L_02F1:	CALL    M_PP1	; >>>
	MOV  M, A
	INX  H
	ADD  B
	MOV  B, A
	MVI  A, 008h
	DCR  C
	JNZ     L_02F1
	DCX  H
	MOV  A, B
	SUB  M
	SUB  M
	MOV  A, M
	POP  H
	JNZ     L_02EB
	POP  D
	POP  B
	RET
;
;==========================================================
L_030A:	MVI  A, 082h	; << проверка наличия МППЗУ
	OUT     004h	; 1000 0010 -> порт РУС ПУ
	MVI  B, 0FFh
L_0310:	MOV  A, B
	OUT     005h	; -> порт С ПУ
	MVI  A, 0FEh
	OUT     007h	; -> порт A ПУ
	IN      006h	; <- порт B ПУ
	CPI     055h
	JNZ     L_032F	; >>> не совпало
	MVI  A, 0FFh
	OUT     007h	; -> порт A ПУ
	IN      006h	; <- порт B ПУ
	CPI     0AAh
	JNZ     L_032F	; >>> не совпало
	MOV  A, B
	ANI     07Fh
	INR  A
	MOV  D, A
;	ORA  A
	RET		; >>> МППЗУ есть
;
L_032F:	MOV  A, B
	SUI     020h
	MOV  B, A
	JM      L_0310
L_NN:	MVI  A, 91h	; B,C (7-4) - вывод,  A,C (3-0) - ввод
	OUT     004h	; -> РУС ПУ
	XRA  A
	RET		; >>> МППЗУ нет
;
L_033C:	CALL    L_07F0	; картинка чипа << загрузка из МППЗУ
	LXI  H, 08000h
	MOV  B, L
	MOV  C, L
L_0344:	MOV  A, L
	OUT     007h
	MOV  A, H
	OUT     005h
	IN      006h
	STAX B
	INX  H
	INX  B
	MOV  A, B
	CMP  D
	JNZ     L_0344
	LXI  H, 00000h
	JMP     L_FBL1	; >> заполнение блоков
;
;==========================================================
L_035A:	MVI  A, 00Bh	; << проверка наличия флоповода
	OUT     019h
	MOV  C, A
	XTHL
	XTHL
	IN      019h
	CMP  C
	RET
;
L_0365:	LXI  H, L_0755	; дискетка	; << загрузка с флоповода
	CALL    L_016D	; отрисовка картинки
	MVI  A, 034h
	STA     M_VAR1
	CALL    L_0420	; >
	XRA  A
	OUT     01Bh
	CALL    L_0414	; >
	MVI  C, 001h
	LXI  H, B_DRV
	CALL    L_03ED	; >
	CZ      L_CHBT	; проверка загрузочного сектора
	JNZ     L_0000	; ошибка >>> сброс
	CALL    L_SETB	; чтение параметров загрузки
	PUSH D		; сохраняем количество блоковдля таблицы
;	MOV  B, A
L_03A5:	MVI  C, 001h	; номер сектора
L_03A7:	CALL    L_03ED	; >
	JNZ     L_0000	; сброс
	DCR  B
	JZ      L_03D3	; > заполнение блоков
	INR  C
	MVI  A, 006h
	CMP  C
	JNZ     L_03A7
	LDA     M_VAR1
	XRI     004h
	STA     M_VAR1
	CALL    L_0420	; >
	MOV  A, D
	ANI     004h
	JZ      L_03A5
	MVI  A, 058h
	OUT     01Bh
	CALL    L_0414	; >
	JMP     L_03A5
;
L_03D3:	POP  D
	JMP     L_DDN	; >> заполнение блоков
;
L_03ED:	CALL    L_0414	; >
	MOV  A, C
	OUT     019h
	LXI  D, 00103h	; ????
	MVI  A, 080h
	OUT     01Bh
L_03FA:	IN      01Bh
	RRC
	JNC     L_03FA
L_0400:	IN      01Bh
	ANA  E		; 0000 0011
	SUB  D		; -01h
	JZ      L_0400
	IN      018h
	MOV  M, A
	INX  H
	JP      L_0400
	DCX  H
	IN      01Bh
	ANI     09Ch
	RET
;
L_0414:	LDA     M_VAR1
	OUT     01Ch	; регистр управления
	IN      01Bh	; регистр состояния (IN)
	RRC
	JC      L_0414
	RET
;
L_0420:	MOV  D, A
L_0421:	OUT     01Ch	; регистр управления
	IN      01Bh	; регистр состояния (IN)
	RLC
	MOV  A, D
	JC      L_0421
	RET
;
;==========================================================
L_042B:	LXI  H, L_0714	; << загрузка с магнитофона
	CALL    L_016D	; картинка
;;	MVI  A, 007h	; включаем РУС/ЛАТ	+++
;;	OUT     000h	; отправляем в порт C	+++
	XRA  A		; подчистка экрана
	LXI  H, M_VAR1	; начало
	MVI  C, 007h	; счётчик
L_0437:	MOV  M, A
	INR  L
	DCR  C
	JNZ     L_0437  ; цикл подчистки
Lx043D:	MVI  A, 011h	; <== PP2
	STA     M_VEF6	; Начальная скорость чтения
	LXI  H, L_04B1
	SHLD    M_PP1+1	; 0DCF2h
	LXI  H, Lx043D
	SHLD    M_PP2+1	; 0DCF5h
	CALL    L_0486
L_0451:	MOV  D, A
	ORA  A
	RAR
	MOV  E, A
	ADD  D
	MOV  H, A
	CALL    L_0486
	CMP  H
	JC      L_0451
	ADD  D
	ADI	006h	; поправка для ПК-6128ц
	STA     M_VEF6	; скорость чтения
;;	MVI  A, 006h	; выключаем РУС/ЛАТ	+++
;;	OUT     000h	; отправляем в порт C	+++
	MVI  E, 00Ch
	JMP     L_021E	; >>>>>>>>>>>>>>>>>>
;
L_0467:;;;	PUSH D
	IN      001h
	ANI     010h
	MOV  E, A
L_046D:	IN      001h
	ANI     010h
	CMP  E
	JZ      L_046D	; ожидание сигнала
L_0475:	MOV  E, A
	MVI  D, 001h
L_0478:	IN      001h
	ANI     010h
	INR  D
	CMP  E
	JZ      L_0478
	MOV  A, D
	ADD  A
	ADD  A
;;;	POP  D
	RET
;
L_0486:	PUSH H
	PUSH D
L_0488:	CALL    L_0467
	MOV  B, A
	ORA  A
	RAR
	MOV  C, A
	LXI  H, 00000h
	MVI  D, 020h
L_0494:	PUSH D
	CALL    L_0467
;;;	PUSH D
	MVI  D, 000h
	MOV  E, A
	DAD  D
	POP  D
	MOV  E, A
	SUB  B
	JNC     L_04A4
	MOV  A, B
	SUB  E
L_04A4:	CMP  C
	JNC     L_0488
	DCR  D
	JNZ     L_0494
	DAD  H
	MOV  A, H
	POP  D
	POP  H
	RET
;
L_04B1: PUSH B		; <<<<<<<<<<< PP1
	PUSH D
	MVI  C, 000h
	MOV  D, A
L_04B6: IN      001h
	ANI     010h
	MOV  E, A
L_04BB: IN      001h
	ANI     010h
	CMP  E
	JZ      L_04BB
	RLC
	RLC
	RLC
	RLC
	MOV  A, C
	RAL
	MOV  C, A
	LDA     M_VEF6	; скорость чтения
L_04CD: DCR  A
	JNZ     L_04CD
	MOV  A, D
	ORA  A
	JP      L_04EF
	MOV  A, C
	CPI     0E6h
	JNZ     L_04E3
	XRA  A
	STA     M_VEF4	; ????
	JMP     L_04ED
;
L_04E3: CPI     019h
	JNZ     L_04B6
	MVI  A, 0FFh
	STA     M_VEF4	; ????
L_04ED: MVI  D, 009h
L_04EF: DCR  D
	JNZ     L_04B6
	LDA     M_VEF4	; ????
	XRA  C
	POP  D
	POP  B
	RET
;
;==========================================================
L_04FA:	XRA  A		; << проверка наличия КД
L_04FB:	STA     M_DSK	; КД 10
	LXI  H, 0F800h
	SHLD    M_BKD	; адрес буфера под чтение каталога КД
	XRA  A		; читаем весь каталог КД в буфер
	CALL    L_0586	; чтение дорожки 0 КД
	JNZ	L_ERR	; >> ошибка чтения КД
	MVI  A, 001h
	CALL    L_0586	; чтение дорожки 1 КД
	JNZ	L_ERR	; >> ошибка чтения КД
L_NAME:	CALL    L_0524	; проверка на совпадение имени с "OS.COM"
	RZ		; >> совпало, выходим с Z=1 и HL=ссылка на список секторов
	DAD  D		; +10h, следующая запись
	JNC     L_NAME	; если HL ещё не обнулилось, то ищем дальше
L_ERR:	LDA     M_DSK
	ANA  A
	RNZ		; КД 11 и OS.COM не найден, возврат с Z=0
	INR  A
	JMP     L_04FB	; повтор с КД 11
;
L_0524:	PUSH H		; ПП проверки имени "OS.COM"
	LXI  D, L_053B	; ссылка на ОС.КОМ
	MVI  C, 00Ch	; счётчик
L_052A: LDAX D
	CMP  M
	JNZ     L_0535	; >> не совпало
	INX  D
	INX  H
	DCR  C
	JNZ     L_052A	; цикл
L_0535: POP  H
	LXI  D, 00010h
	DAD  D		; возвращаем ссылку на список треков файла
	RET
;
L_053B:	.db 000h
	.db "OS      COM"
;
L_0547:	PUSH H		; <<< загрузка с КД, HL=ссылка на список секторов OS.COM
	LXI  H, L_073C	; картинка КД
	CALL    L_016D	; картинка
	LXI  H, 00100h
	SHLD    M_BKD 	; адрес буфера под чтение КД
	MOV  B, L	; B = 0
	POP  H
L_0556:	MVI  C, 010h	; <<<---- цикл по записям дорожек
	DCX  H
	MOV  A, M	; число секторов из записи директории
	INX  H
	ANA  A		; сброс признака [С] (на всякий случай)
	RAR		; /2
	ADC  B		; A = A+B+[C]
	MOV  B, A	; B = количество блоков
L_0558:	MOV  A, M
	ORA  A
	JZ      L_0572	; >> готово
	CALL    L_0586	; чтение трека
	JNZ     L_KDER	; -> ошибка чтения!
;	MVI  A, 004h
;	ADD  B
;	MOV  B, A	; кол-во блоков +4
	INX  H
	DCR  C
	JNZ     L_0558
	CALL    L_0524	; чтение следущей записи каталога КД, == "OS.COM"?
	JZ      L_0556	; ещё есть, грузим дальше
L_0572:	MOV  D, B	; D = кол-во загруженных блоков
	LXI  H, 00100h	; адрес начала
	JMP     L_FBLK
;
L_KDER:	LXI  H, 0D7E2h	; чистое место
	LXI  D, 0D8E2h
	MVI  A, 002h	; число столбцов
	MVI  B, 08Ch	; высота картинки
	CALL    L_0174	; <<< ПП отрисовки картинки
	JMP     L_00D4	; Переход к загрузке со следующего устройства
;
	; ПП чтения дорожки КД в буфер
	; M_BKD = адр.начала буфера
	; A = номер дорожки КД (записывается в M_DKD)
L_0586:	PUSH H
	PUSH B
	LXI  H, 00000h
	DAD  SP
	SHLD    M_VAR1	; тут хранится указатель стека
	LXI  D, 00380h	; (для первого сектора)
	STA     M_DKD	; сохраняем номер дорожки КД
	CMA		; инверсия А
	CPI     0FCh
	JNC     L_EKR	; если А >= FCh
	SUI     010h	; А := А - 10h
L_EKR:	SUI     004h	; А := А - 04h
	MOV  L, A
	ADD  A		;
	ADD  A		;
	MOV  H, A	; H := А * 4
	MOV  A, L	; вост. А
	MVI  L, 000h	; L := 0
	DAD  D		; HL := HL + DE = HL - 020h
	STC		; (установка переноса =1)
	RAR		; (Циклический сдвиг вправо через перенос)
	RRC		; (сдвиг вправо)
	RRC
	RRC
	ANI     01Ch	; маскируем 2,3 и 4 биты
	MOV  B, A	; сохраняем конфигурацию КД
	MVI  A, 001h
	DI		;
L_LPKD:	SHLD    M_RKD	; адрес начала сектора на КД
	STA     M_SKD	; номер сектора на дорожке КД
	LDA     M_DSK
	ANA  A		; Признак Z по номеру КД
	MOV  A, B
	JNZ     L_KD11
	OUT     010h	; подключаем КД 10
	JMP     L_KD10
L_KD11: OUT     011h	; подключаем КД 11
L_KD10:	SPHL		; стек на адрес чтения
	LHLD    M_BKD	; куда сохранять
	XRA  A
	MVI  C, 020h	; счётчик, 20h*4 = 128 байт
L_05CE:	POP  D		; читаем в DE
	ADD  E
	ADD  D		; A:= A+E+D (контр.сумма)
	MOV  M, E
	INX  H
	MOV  M, D
	INX  H
	POP  D		; читаем 2 в DE
	ADD  E
	ADD  D
	MOV  M, E
	INX  H
	MOV  M, D
	INX  H
	DCR  C
	JNZ     L_05CE	; цикл копирования сектора (128 байт)
	SHLD    M_BKD	; сохраняем новый адрес буфера под чтение КД
	; проверка контрольной суммы
	MOV  C, A	; C = контрольная сумма
	LDA     M_DSK
	ANA  A		; Признак Z по номеру КД
	MVI  A, 01Fh	; 0001 1111 -- банк 0 как СТЕК
	JNZ     L_KK11
	OUT     010h	; отправляем на квазидиск 10
	JMP     L_KK10
L_KK11: OUT     011h	; подключаем КД 11
	; вычисляем адрес КС
L_KK10:	LDA     M_DKD	; номер дорожки КД
	MOV  L, A
	MVI  H, 00Fh
	DAD  H
	DAD  H
	DAD  H
	DAD  H
	LDA     M_SKD	; номер сектора КД
	DCR  A
	ADD  A
	ADD  L
	MOV  L, A
	SPHL
	POP  D		; считываем КС
	MOV  A, E
	CMP  D
	JNZ     L_KCER	; >> КС считана с ошибкой, выход из ПП
	CMP  C
	JNZ     L_KCER	; >> КС не совпала, всё плохо, выход из ПП
	LHLD    M_RKD	; адрес начала сектора
	LXI  D, 0FF80h	; DE = -80h
	DAD  D		; HL = новый адрес начала сектора
	LDA     M_SKD	; номер сектора КД
	INR  A
	CPI     009h
	JNZ     L_LPKD
	LDA     M_DSK
	ANA  A		; Признак Z по номеру КД
	JNZ     L_KX11
	OUT     010h	; отключаем КД 10
	JMP     L_DONE
L_KX11:	XRA  A		; Z=1
	OUT     011h	; отключаем КД 11
L_DONE:	LHLD    M_VAR1
	SPHL		; восстанавливаем указатель стека
	EI
	POP  B
	POP  H
	RET		; >>> выход, Z=0 при ошибке
;
L_KCER:	LDA     M_DSK
	ANA  A		; Признак Z по номеру КД
	JNZ     L_KY11
	OUT     010h	; отключаем КД 10
	INR  A		; Z=0
	JMP     L_DONE
L_KY11:	MVI  A, 000h	; Z=0
	OUT     011h	; отключаем КД 11
	JMP     L_DONE
;
;==========================================================
; проверка наличия HDD и сброс
L_RES:	MVI  A, 010h	; сброс на нулевой цилиндр
	OUT     057h	; Запись: регистр команды
L_RDY:	LXI  B, 00000h	; B = 0000h -- счётчик
L_LOOP:	IN      057h	; регистр статуса
	ANI     0C0h	; 1100 0000
	CPI     040h
	RZ		; > выход из ПП
	DCX  B
	MOV  A, B
	ORA  C
	JNZ     L_LOOP	; цикл на 65536 попыток
	RET		; >>>> долго ждём, сброс (A = 0)
;
; проверка наличия НЖМД, вых. Z = 1 -- всё ок.
L_CHDD:	IN      057h	; регистр статуса НЖМД
	INR  A		; если А <> FFh
	CNZ     L_RES	; сброс и ожидание готовности НЖМД
	CPI     040h
	RNZ		; >> нет отклика от НЖМД
	LXI  H, B_DRV	; куда читать
	MVI  C, 001h	; сколько секторов читать
	CALL    L_RHDD	; чтение в буфер
L_CHBT:	LXI  H, B_DRV	; <<<<< ПП проверки загрузочного сектора
	LXI  D, M_BT
	MVI  C, 01Fh
	MVI  A, 066h
L_CBT1:	ADD  M
	MOV  B, A
	MOV  A, M
	STAX D
	INX  H
	INX  D
	DCR  C
	MOV  A, B
	JNZ     L_CBT1	; цикл подсчёта КС с копированием
	SUB  M
	RNZ		; КС не совпала -- выход (Z=0)
	LDA     M_SKB	; количество секторов (1к) при загрузке
	DCR  A
	RM		; выход, если A < 0 (и Z=0)
	XRA  A
	RET		; выход (Z=1)
;
; ПП установки параметров загрузки
L_SETB:	LXI  D, 0FF80h	; (-80h)
	LHLD    M_BT	; считываем начальный адрес
	DAD  D		; поправка на смещение данных
	LDA     M_SKB	; (сколько блоков/4 программа в сист.области)
	MOV  B, A	; для НГМД
	ADD  A
	MOV  C, A	; число секторов НЖМД = блоков/4 * 2 (для L_RHDD)
	ADD  A
	MOV  D, A	; D = число блоков для отображения (по 256 байт)
	RET
;
; ПП загрузки с жёсткго диска
;
L_067B:	LXI  H, L_078E	; ссылка на картинку с диском
	CALL    L_016D	; рисуем...
	DI
	CALL    L_RES	; сброс и ожидание готовности НЖМД
	CALL    L_SETB	; чтение параметров загрузки
	CALL    L_RHDD
L_DDN:	LHLD    M_BT	; считываем начальный адрес
L_FBLA:	MVI  A, 0FCh
	ANA  L
	ORA  H		; начальный адрес больше 0003h
	JZ      L_FBL2	; заполняем блоки в таблице c JMP addr(HL)
L_FBLK:	MVI  A, 0C3h	; =JMP		<<<<<<<<<<<<<<<<<
	STA     00000h
	SHLD    00001h
L_FBL2:	MVI  L, 000h	; обнуляем для правильной отрисовки блоков
L_FBL1:	CALL    L_015A	; >> заполнение блока,  << D=количество блоков
	INR  H
	DCR  D
	JNZ     L_FBL2
	RET
;
L_RHDD:	XRA  A
	OUT     054h	; LBA [15..8]
	OUT     055h	; LBA [23..16]
	MVI  A, 002h	; сектор №2
	OUT     053h	; LBA [7..0]
	MVI  A, 0E0h	; 1110 0000
	OUT     056h	; режим и LBA[27..24]
	MOV  A, C
	OUT     052h	; Счетчик числа секторов для операции чтения/записи
	MVI  A, 020h	; 2xH = сектор чтения (x = retry and ECC-read)
	OUT     057h	; Запись:	регистр команды
	CALL    L_RDY	; ожидание готовности НЖМД
L_RLP:	IN      057h	; регистр статуса
	ANI     008h	; 0000 1000 :	запрос данных. Буфер ждет данных (занято)
	RZ		; >>> RET в случае ошибки или окончания чтения
	IN      050h	; Регистр данных. Чтение данных в буфер
	MOV  M, A
	INX  H
	IN      058h	; Регистр данных. Чтение данных в буфер
	MOV  M, A
	INX  H
	JMP     L_RLP
;
;==========================================================
L_06CB:	.db 009h	; высота
	.db 000h	; - |        |
	.db 0DBh	; - |■■ ■■ ■■| ПК-6128Ц++
	.db 0DBh	; - |■■ ■■ ■■|
	.db 0DBh	; - |■■ ■■ ■■|
	.db 0DBh	; - |■■ ■■ ■■|
	.db 0DBh	; - |■■ ■■ ■■|
	.db 0DBh	; - |■■ ■■ ■■|
	.db 0DBh	; - |■■ ■■ ■■|
	.db 0FBh	; - |■■■■■ ■■|
;
	.db 000h	; - |        |
	.db 060h	; - | ■■     |
	.db 061h	; - | ■■    ■|
	.db 061h	; - | ■■    ■|
	.db 04Dh	; - | ■  ■■ ■|
	.db 08Dh	; - |■   ■■ ■|
	.db 041h	; - | ■     ■|
	.db 061h	; - | ■■    ■|
	.db 060h	; - | ■■     |
;
	.db 000h	; - |        |
	.db 0E3h	; - |■■■   ■■|
	.db 0B3h	; - |■ ■■  ■■|
	.db 0B3h	; - |■ ■■  ■■|
	.db 0B3h	; - |■ ■■  ■■|
	.db 0E7h	; - |■■■  ■■■|
	.db 087h	; - |■    ■■■|
	.db 0B3h	; - |■ ■■  ■■|
	.db 0E1h	; - |■■■    ■|
;
	.db 000h	; - |        |
	.db 07Ch	; - | ■■■■■  |
	.db 065h	; - | ■■  ■ ■|
	.db 061h	; - | ■■    ■|
	.db 039h	; - |  ■■■  ■|
	.db 00Ch	; - |    ■■  |
	.db 06Dh	; - | ■■ ■■ ■|
	.db 06Dh	; - | ■■ ■■ ■|
	.db 038h	; - |  ■■■   |
;
	.db 000h	; - |        |
	.db 0E7h	; - |        |
	.db 0B6h	; - |       ■|
	.db 0B6h	; - |■■     ■|
	.db 0B6h	; - | ■■ ■■ ■|
	.db 0E6h	; - | ■■ ■■ ■|
	.db 0B6h	; - | ■■    ■|
	.db 0B0h	; - | ■■    ■|
	.db 0E0h	; - |■■      |
;
	.db 020h	; - |        |
	.db 0E0h	; - |■■■   ■■|
	.db 0C6h	; - |■ ■■ ■■ |
	.db 0C6h	; - |■ ■■ ■■ |
	.db 0DFh	; - |■ ■■ ■■ |
	.db 0DFh	; - |■ ■■ ■■■|
	.db 0C6h	; - |■ ■■ ■■ |
	.db 006h	; - |■ ■■ ■■ |
	.db 000h	; - |■■■   ■■|
;
	.db 000h	; - |        |
	.db 000h	; - |■     ■■|
	.db 00Ch	; - |■■ ■■■■■|
	.db 00Ch	; - |■■ ■ ■■ |
	.db 0BFh	; - |■■ ■ ■■ |
	.db 0BFh	; - |■  ■ ■■ |
	.db 00Ch	; - |   ■ ■■ |
	.db 00Ch	; - |■■ ■ ■■ |
	.db 000h	; - |■  ■ ■■ |
;
;	.db 06Fh	; - | ■■ ■■■■|
;	.db 06Ch	; - | ■■ ■■  |
;	.db 00Ch	; - |    ■■  |
;	.db 007h	; - |     ■■■|
;	.db 001h	; - |       ■|
;	.db 00Dh	; - |    ■■ ■|
;	.db 00Dh	; - |    ■■ ■|
;	.db 007h	; - |     ■■■|
;
;	.db 09Ch	; - |■  ■■■  |
;	.db 0B6h	; - |■ ■■ ■■ |
;	.db 036h	; - |  ■■ ■■ |
;	.db 006h	; - |     ■■ |
;	.db 09Ch	; - |■  ■■■  |
;	.db 086h	; - |■    ■■ |
;	.db 0B6h	; - |■ ■■ ■■ |
;	.db 01Ch	; - |   ■■■  |
;
L_0714:	.db 00Dh	; высота
	.db 03Fh	; - |  ■■■■■■| Картинка кассеты
	.db 0ABh	; - |■ ■ ■ ■■|
	.db 0BFh	; - |■ ■■■■■■|
	.db 0C0h	; - |■■      |
	.db 0FFh	; - |■■■■■■■■|
	.db 0EFh	; - |■■■ ■■■■|
	.db 0C4h	; - |■■   ■  |
	.db 0ECh	; - |■■■ ■■  |
	.db 0FFh	; - |■■■■■■■■|
	.db 0FFh	; - |■■■■■■■■|
	.db 080h	; - |■       |
	.db 0C0h	; - |■■      |
	.db 07Fh	; - | ■■■■■■■|
;
	.db 0FCh	; - |■■■■■■  |
	.db 0D5h	; - |■■ ■ ■ ■|
	.db 0FDh	; - |■■■■■■ ■|
	.db 003h	; - |      ■■|
	.db 0FFh	; - |■■■■■■■■|
	.db 0F7h	; - |■■■■ ■■■|
	.db 023h	; - |  ■   ■■|
	.db 037h	; - |  ■■ ■■■|
	.db 0FFh	; - |■■■■■■■■|
	.db 0FFh	; - |■■■■■■■■|
	.db 001h	; - |       ■|
	.db 003h	; - |      ■■|
	.db 0FEh	; - |■■■■■■■ |
;
	.db 07Ch	; - | ■■■■■  |
	.db 050h	; - | ■ ■    |
	.db 040h	; - | ■      |
	.db 07Ch	; - | ■■■■■  |
	.db 020h	; - |  ■     |
	.db 010h	; - |   ■    |
	.db 020h	; - |  ■     |
	.db 07Ch	; - | ■■■■■  |
	.db 000h	; - |        |
	.db 024h	; - |  ■  ■  |
	.db 054h	; - | ■ ■ ■  |
	.db 054h	; - | ■ ■ ■  |
	.db 038h	; - |  ■■■   |
;
L_073C:	.db 08Ch	; высота, +80h -- удвоение строк
	.db 00Fh	; - |    ■■■■| Картинка КД
	.db 0FFh	; - |■■■■■■■■|
	.db 080h	; - |■       |
	.db 092h	; - |■  ■  ■ |
	.db 080h	; - |■       |
	.db 092h	; - |■  ■  ■ |
	.db 080h	; - |■       |
	.db 092h	; - |■  ■  ■ |
	.db 080h	; - |■       |
	.db 092h	; - |■  ■  ■ |
	.db 080h	; - |■       |
	.db 0FFh	; - |■■■■■■■■|
;
	.db 0F0h	; - |■■■■    |
	.db 0FFh	; - |■■■■■■■■|
	.db 001h	; - |       ■|
	.db 049h	; - | ■  ■  ■|
	.db 001h	; - |       ■|
	.db 049h	; - | ■  ■  ■|
	.db 001h	; - |       ■|
	.db 049h	; - | ■  ■  ■|
	.db 001h	; - |       ■|
	.db 049h	; - | ■  ■  ■|
	.db 001h	; - |       ■|
	.db 0FFh	; - |■■■■■■■■|
;
L_0755:	.db 08Ah	; высота, +80h -- удвоение строк
	.db 0FFh	; - |■■■■■■■■| Картинка дискеты
	.db 0FEh	; - |■■■■■■■ |
	.db 0FEh	; - |■■■■■■■ |
	.db 0FFh	; - |■■■■■■■■|
	.db 0FCh	; - |■■■■■■  |
	.db 0FCh	; - |■■■■■■  |
	.db 0FFh	; - |■■■■■■■■|
	.db 081h	; - |■      ■|
	.db 081h	; - |■      ■|
	.db 0FFh	; - |■■■■■■■■|
;
	.db 0FFh	; - |■■■■■■■■|
	.db 07Fh	; - | ■■■■■■■|
	.db 07Fh	; - | ■■■■■■■|
	.db 0FFh	; - |■■■■■■■■|
	.db 03Fh	; - |  ■■■■■■|
	.db 03Fh	; - |  ■■■■■■|
	.db 0FFh	; - |■■■■■■■■|
	.db 0FEh	; - |■■■■■■■ |
	.db 0FFh	; - |■■■■■■■■|
	.db 0FFh	; - |■■■■■■■■|
;
L_076A:	.db 087h	; высота, +80h -- удвоение строк
	.db 055h	; - | ■ ■ ■ ■| Картинка чипа
	.db 0FFh	; - |■■■■■■■■|
	.db 0C0h	; - |■■      |
	.db 0C7h	; - |■■   ■■■|
	.db 0C0h	; - |■■      |
	.db 0FFh	; - |■■■■■■■■|
	.db 055h	; - | ■ ■ ■ ■|
;
	.db 054h	; - | ■ ■ ■  |
	.db 0FFh	; - |■■■■■■■■|
	.db 003h	; - |      ■■|
	.db 0C6h	; - |■■   ■■ |
	.db 003h	; - |      ■■|
	.db 0FFh	; - |■■■■■■■■|
	.db 054h	; - | ■ ■ ■  |
;
L_0779:	.db 08Ah	; высота, +80h -- удвоение строк
	.db 0C1h	; - |■■     ■| Картинка сети
	.db 020h	; - |  ■     |
	.db 00Fh	; - |    ■■■■|
	.db 001h	; - |       ■|
	.db 007h	; - |     ■■■|
	.db 0E4h	; - |■■■  ■  |
	.db 004h	; - |     ■  |
	.db 007h	; - |     ■■■|
	.db 020h	; - |  ■     |
	.db 0C1h	; - |■■     ■|
;
	.db 083h	; - |■     ■■|
	.db 004h	; - |     ■  |
	.db 0F0h	; - |■■■■    |
	.db 080h	; - |■       |
	.db 0E0h	; - |■■■     |
	.db 027h	; - |  ■  ■■■|
	.db 020h	; - |  ■     |
	.db 0E0h	; - |■■■     |
	.db 004h	; - |     ■  |
	.db 083h	; - |■     ■■|
;
L_078E:	.db 00Fh	; высота
	.db 0FFh	; - |■■■■■■■■| картинка ХДД
	.db 0B0h	; - |■ ■■    |
	.db 0E0h	; - |■■■     |
	.db 0C0h	; - |■■      |
	.db 0C0h	; - |■■      |
	.db 080h	; - |■       |
	.db 086h	; - |■    ■■ |
	.db 086h	; - |■    ■■ |
	.db 087h	; - |■    ■■■|
	.db 081h	; - |■      ■|
	.db 0C1h	; - |■■     ■|
	.db 0C0h	; - |■■      |
	.db 0E0h	; - |■■■     |
	.db 0B0h	; - |■ ■■    |
	.db 0FFh	; - |■■■■■■■■|
;
	.db 0FFh	; - |■■■■■■■■|
	.db 0F3h	; - |■■■■  ■■|
	.db 061h	; - | ■■    ■|
	.db 021h	; - |  ■    ■|
	.db 043h	; - | ■    ■■|
	.db 047h	; - | ■   ■■■|
	.db 08Fh	; - |■   ■■■■|
	.db 09Fh	; - |■  ■■■■■|
	.db 03Fh	; - |  ■■■■■■|
	.db 05Fh	; - | ■ ■■■■■|
	.db 0BFh	; - |■ ■■■■■■|
	.db 03Fh	; - |  ■■■■■■|
	.db 07Fh	; - | ■■■■■■■|
	.db 0FDh	; - |■■■■■■ ■|
	.db 0FFh	; - |■■■■■■■■|
;
L_07AD:	LXI  D, F4_LEN	; размер << Монитор СуперМонстр
	LXI  B, F4_PRG	; откуда
	JMP     L_07CE
;
L_07B6:	CALL    L_0846	; << загрузка модуля выгрузки данных через ПУ (в мониторе)
	JNZ     L_042B	; >> загрузка с магнитофона
	LXI  D, 001DAh	; размер + 100h
	LXI  B, L_08D0	; откуда
	LXI  H, 09300h	; куда
	JMP     L_07D9
;
L_07C8:	LXI  D, F3_LEN	; размер << Бейсик
	LXI  B, F3_PRG	; откуда
L_07CE:	LXI  H, 00100h	; куда
	MVI  A, 0C3h
	STA     00000h
	SHLD    00001h
L_07D9:	PUSH H
	PUSH B
	CALL    L_07F0	; отрисовка картинки чипа
	POP  B
	POP  H
L_07E0:	LDAX B		; читаем байт
	MOV  M, A	; пишем
	INX  B
	INR  L
	JNZ     L_07E0
	CALL    L_015A	; >> заполнение блока
	INR  H
	DCR  D
	JNZ     L_07E0	; цикл переноса данных
	RET
;
L_07F0:	LXI  H, L_076A	; картинка чипа
;	MVI  A, 087h
	PUSH D
	CALL    L_016D	; отрисовка
	POP  D
	RET
;
;==========================================================
L_07F9:	LXI  H, 07FFEh	; << тест ПЗУ
	LXI  D, 000FFh
L_07FF:	MOV  A, M
	XRA  D
	MOV  D, A
	DCX  H
	MOV  A, H
	CMP  E
	JNZ     L_07FF	; цикл подсчёта КС
	LDA     07FFFh	; КС в ПЗУ
	XRA  D
	JZ      L_00F6	; >> всё ок! (RZ)
	MOV  A, D
	OUT  006h       ; порт (B) ПУ -- вывод КС
	MVI  A, 7
	OUT     002h	; в порт B -- цвет бордюра (желтый)
L_0816:	JMP     L_0816	; если нет -- зацикливаемся...
;
;==========================================================
L_0819:	LXI  H, 000C3h	; << реанимация 0 блока монитора (режим загрузки детектируется)
	SHLD    00000h
	SHLD    00005h
	MVI  H, 076h	;	LXI  H, 076C3h	; !!
	SHLD    00038h
	CALL    L_0846
	LXI  H, 00002h	; !!
	JNZ     L_083B
	MVI  M, 0F8h
	MVI  L, 007h
	MVI  M, 094h
	MVI  L, 03Ah
	MVI  M, 0FDh
	RET
;
L_083B:	MVI  M, 078h
	MVI  L, 007h
	MVI  M, 054h
	MVI  L, 03Ah
	MVI  M, 07Dh
	RET
;
L_0846:	LXI  H, 09400h
	MOV  A, M
	CPI     0C3h
	RNZ
	INX  H
	MOV  A, M
	CPI     003h
	RNZ
	INX  H
	MOV  A, M
	CPI     094h
	RET
;
;==========================================================
L_0857:	LXI  H, L_0779	; картинка сети	; << загрузка из РС через порты ПУ-LPT
	CALL    L_016D	; отрисовка картинки
	MVI  A, 082h
	OUT     004h
	MVI  A, 010h
	OUT     005h
	XRA  A
	MOV  L, A
	MOV  C, A
	CALL    L_089D
	MOV  A, E
	CPI     055h
	JNZ     L_0000
	CALL    L_089D
	MOV  A, E
	CPI     0AAh
	JNZ     L_0000
	CALL    L_089D
	MOV  H, E
	CALL    L_089D
	MOV  A, H
	ADD  E
	MOV  B, A
L_0884:	CALL    L_089D
	MOV  M, E
	MOV  A, C
	XRA  E
	MOV  C, A
	XRA  A
	ORA  L		; L = 00h?
	CZ      L_015A	; >> заполнение блока
	INX  H
	MOV  A, H
	CMP  B
	JNZ     L_0884
	CALL    L_089D
	MOV  A, E
	CMP  C
	RZ
	RST  0
L_089D:	MVI  D, 000h
L_089F:	IN      006h
	ANI     020h
	JZ      L_089F
	MOV  A, D
	ANA  A
	JNZ     L_08B4
	IN      006h
	ANI     00Fh
	MOV  E, A
	INR  D
	JMP     L_08C0
;
L_08B4:	IN      006h
	ANI     00Fh
	RLC
	RLC
	RLC
	RLC
	ORA  E
	MOV  E, A
	MVI  D, 000h
L_08C0:	XRA  A
	OUT     005h
L_08C3:	IN      006h
	ANI     020h
	JNZ     L_08C3
	MVI  A, 010h
	OUT     005h
	MOV  A, D
	ANA  A
	JNZ     L_089F
	RET
;
;===============================================================
; модуль выгрузки данных через ПУ для монитора
				;		.org 09300h
L_08D0:	.db 021h,0BAh,093h	;L_9300:	LXI  H, L_93BA
	.db 0CDh,018h,0F8h	;		CALL    0F818h
	.db 03Eh,082h		;		MVI  A, 082h
	.db 0D3h,004h		;		OUT     004h
	.db 03Eh,010h		;		MVI  A, 010h
	.db 0D3h,005h		;		OUT     005h
	.db 021h,0D9h,093h	;		LXI  H, L_93D9
	.db 046h		;		MOV  B, M
	.db 00Eh,0FFh		;		MVI  C, 0FFh
	.db 02Bh		;		DCX  H
	.db 066h		;		MOV  H, M
	.db 0AFh		;		XRA  A
	.db 06Fh		;		MOV  L, A
	.db 032h,0DAh,093h	;		STA     L_93DA
	.db 01Eh,055h		;		MVI  E, 055h
	.db 0CDh,078h,093h	;		CALL    L_9378
	.db 01Eh,0AAh		;		MVI  E, 0AAh
	.db 0CDh,078h,093h	;		CALL    L_9378
	.db 05Ch		;		MOV  E, H
	.db 0CDh,078h,093h	;		CALL    L_9378
	.db 058h		;		MOV  E, B
	.db 0CDh,078h,093h	;		CALL    L_9378
	.db 05Eh		;L_932D:	MOV  E, M
	.db 03Ah,0DAh,093h	;		LDA     L_93DA
	.db 0ABh		;		XRA  E
	.db 032h,0DAh,093h	;		STA     L_93DA
	.db 0CDh,078h,093h	;		CALL    L_9378
	.db 07Dh		;		MOV  A, L
	.db 0FEh,000h		;		CPI     000h
	.db 0C2h,045h,093h	;		JNZ     L_9345
	.db 0C5h		;		PUSH B
	.db 00Eh,02Eh		;		MVI  C, 02Eh
	.db 0CDh,009h,0F8h	;		CALL    0F809h
	.db 0C1h		;		POP  B
	.db 023h		;L_9345:	INX  H
	.db 00Bh		;		DCX  B
	.db 078h		;		MOV  A, B
	.db 0FEh,000h		;		CPI     000h
	.db 0C2h,02Dh,093h	;		JNZ     L_932D
	.db 03Ah,0DAh,093h	;		LDA     L_93DA
	.db 05Fh		;		MOV  E, A
	.db 0CDh,078h,093h	;		CALL    L_9378
	.db 021h,0D5h,093h	;		LXI  H, L_93D5
	.db 0CDh,018h,0F8h	;		CALL    0F818h
	.db 03Ah,0D8h,093h	;		LDA     L_93DA
	.db 047h		;		MOV  B, A
	.db 0CDh,015h,0F8h	;		CALL    0F815h
	.db 021h,0CCh,093h	;		LXI  H, L_93CC
	.db 0CDh,018h,0F8h	;		CALL    0F818h
	.db 03Ah,0D9h,093h	;		LDA     L_93D9
	.db 080h		;		ADD  B
	.db 03Dh		;		DCR  A
	.db 0CDh,015h,0F8h	;		CALL    0F815h
	.db 021h,0D2h,093h	;		LXI  H, L_93D2
	.db 0CDh,018h,0F8h	;		CALL    0F818h
	.db 0C3h,000h,0F8h	;		JMP     0F800h
				;
	.db 07Bh		;L_9378:	MOV  A, E
	.db 0E6h,00Fh		;		ANI     00Fh
	.db 057h		;		MOV  D, A
	.db 0DBh,005h		;		IN      005h
	.db 0E6h,0F0h		;		ANI     0F0h
	.db 0B2h		;		ORA  D
	.db 0D3h,005h		;		OUT     005h
	.db 016h,001h		;		MVI  D, 001h
	.db 0C3h,099h,093h	;		JMP     L_9399
				;
	.db 07Bh		;L_9388:	MOV  A, E
	.db 0E6h,0F0h		;		ANI     0F0h
	.db 007h		;		RLC
	.db 007h		;		RLC
	.db 007h		;		RLC
	.db 007h		;		RLC
	.db 057h		;		MOV  D, A
	.db 0DBh,005h		;		IN      005h
	.db 0E6h,0F0h		;		ANI     0F0h
	.db 0B2h		;		ORA  D
	.db 0D3h,005h		;		OUT     005h
	.db 016h,000h		;		MVI  D, 000h
	.db 0DBh,005h		;L_9399:	IN      005h
	.db 0E6h,0EFh		;		ANI     0EFh
	.db 0D3h,005h		;		OUT     005h
	.db 0DBh,006h		;L_939F: 	IN      006h
	.db 0E6h,020h		;		ANI     020h
	.db 0CAh,09Fh,093h	;		JZ      L_939F
	.db 0DBh,005h		;		IN      005h
	.db 0F6h,010h		;		ORI     010h
	.db 0D3h,005h		;		OUT     005h
	.db 0DBh,006h		;L_93AC: 	IN      006h
	.db 0E6h,020h		;		ANI     020h
	.db 0C2h,0ACh,093h	;		JNZ     L_93AC
	.db 07Ah		;		MOV  A, D
	.db 0FEh,000h		;		CPI     000h
	.db 0C2h,088h,093h	;		JNZ     L_9388
	.db 0C9h		;		RET
				;
	.db 00Ah	; <_>	;L_93BA:
	.db 00Dh	; <_>
	.db 077h	; <w>
	.db 079h	; <y>
	.db 077h	; <w>
	.db 06Fh	; <o>
	.db 064h	; <d>
	.db 020h	; < >
	.db 064h	; <d>
	.db 061h	; <a>
	.db 06Eh	; <n>
	.db 06Eh	; <n>
	.db 079h	; <y>
	.db 068h	; <h>
	.db 00Ah	; <_>
	.db 00Dh	; <_>
	.db 03Eh	; <>>
	.db 000h	; <_>
	.db 030h	; <0>	;L_93CC:
	.db 030h	; <0>
	.db 048h	; <H>
	.db 00Ah	; <_>
	.db 00Dh	; <_>
	.db 000h	; <_>
	.db 046h	; <F>	;L_93D2:
	.db 046h	; <F>
	.db 048h	; <H>
	.db 00Ah	; <_>
	.db 00Dh	; <_>
	.db 000h	; <_>
	.db 001h	; <_>	;L_93D8:
	.db 001h	; <_>	;L_93D9:
	.db 0FFh	; < >	;L_93DA:
;
;----------------------------------------
L_FM9:	LXI  H, L_0714	; << загрузка с магнитофона FM9
	MVI  A, 003h	; 3 столбца
	CALL    L_016F	; отрисовка картинки
	LXI  H, M_FM9l	; куда
	LXI  D, FM9_PP	; откуда
L_FM91:	LDAX D
	MOV  M, A
	INX  D
	INR  L
	JNZ     L_FM91	; цикл переброски подпрограммы FM9
L_FM92:	CALL    L_FM9A
	CALL    L_FM9B
	CPI     046h	; "F"
	JNZ     L_FM92
	CALL    L_FM9B
	CPI     04Dh	; "M"
	JNZ     L_FM92
	CALL    L_FM9B
	CPI     039h	; "9"
	JNZ     L_FM92
	CALL    L_FM9B
	STA     X_E053+1
	MVI  C, 00Bh
L_FM93:	CALL    L_FM9B
	DCR  C
	JNZ     L_FM93
	CALL    L_FM9B
;;;	ORA  A		; убрал чтобы можно было грузить программы с нулевого адреса
;;;	JZ      L_FM92
	MOV  L, A
	MVI  H, 0DEh
	MVI  M, 01Bh
	CALL    L_FM9B
	MOV  B, A
	ADD  L
	DCR  A
	MOV  C, L
	MOV  L, A
	MVI  M, 01Bh
	MOV  H, C
	XRA  A
	STA     X_E0D8+1
	MOV  L, A
	MOV  C, A
	CALL    M_FM9l
	PUSH H		; начальный адрес
	ORA  A
	JZ     L_FM9y
	PUSH H
	PUSH B		; количество байт
L_FM9z:	MOV  A, M	; цикл инверсии данных
	CMA
	MOV  M, A
	INX  H
	DCR  C
	JNZ     L_FM9z
	DCR  B
	JNZ     L_FM9z
	POP  B
	POP  H
L_FM9y:	MVI  D, 0DEh	; адрес индикатора загрузки FM9
	MOV  E, H
	MOV  L, H
	MVI  H, 0DDh	; откуда будем копировать
	MOV  A, M
	STAX D
	MOV  A, L
	ADD  B
	DCR  A
	MOV  E, A
	MOV  L, A
	MOV  A, M
	STAX D
	INR  D
L_FM9x:	STAX D
	DCR  E
	DCR  L
	MOV  A, M
	JNZ     L_FM9x
	STAX D
	MOV  D, B	; количество блоков
	POP  H		; начальный адрес
	JMP     L_FBLA	; заполнение блоков
;
L_FM9A:	MVI  E, 000h
	IN      001h
	MOV  D, A
L_FM94:	CALL    L_FM9C
	MOV  A, E
	ADC  A
	MOV  E, A
	CPI     0E6h
	JNZ     L_FM94
	RET
;
L_FM9B:	PUSH B
L_FM95:	IN      001h
	CMP  D
	JZ      L_FM95
	MOV  D, A
	XTHL
	XTHL
	CALL    L_FM9C
	MOV  A, A
	CALL    L_FM9D
	CALL    L_FM9E
	CALL    L_FM9E
	CALL    L_FM9E
	CALL    L_FM9E
	CALL    L_FM9E
	CALL    L_FM9E
	MOV  A, E
	ADC  A
	POP  B
	RET
;
L_FM9E:	MOV  A, E
L_FM9D:	ADC  A
	MOV  E, A
L_FM9C:	MVI  B, 000h
L_FM96:	INR  B
	IN      001h
	CMP  D
	JZ      L_FM96
	MOV  D, A
	MVI  A, 005h
	CMP  B
	RET
;
FM9_PP:	.db 0C5h		;	M_FM9l:	PUSH B
	.db 0E5h		;		PUSH H
	.db 0C5h		;	L_E052:	PUSH B
	.db 00Eh,000h		;	X_E053:	MVI  C, 000h
	.db 0CDh		;		CALL    L_FM9A
	.dw L_FM9A
	.db 0DBh,001h		;	L_E058:	IN      001h
	.db 0BAh		;		CMP  D
	.db 0CAh,058h,0E0h	;		JZ      L_E058
	.db 057h		;		MOV  D, A
	.db 057h		;		MOV  D, A
	.db 006h,000h		;		MVI  B, 000h
	.db 004h		;	L_E062:	INR  B
	.db 0DBh,001h		;		IN      001h
	.db 0BAh		;		CMP  D
	.db 0CAh,062h,0E0h	;		JZ      L_E062
	.db 057h		;		MOV  D, A
	.db 079h		;		MOV  A, C
	.db 0B8h		;		CMP  B
	.db 07Fh		;		MOV  A, A
	.db 08Fh		;		ADC  A
	.db 05Fh		;		MOV  E, A
	.db 006h,000h		;		MVI  B, 000h
	.db 004h		;	L_E071:	INR  B
	.db 0DBh,001h		;		IN      001h
	.db 0BAh		;		CMP  D
	.db 0CAh,071h,0E0h	;		JZ      L_E071
	.db 057h		;		MOV  D, A
	.db 079h		;		MOV  A, C
	.db 0B8h		;		CMP  B
	.db 07Bh		;		MOV  A, E
	.db 08Fh		;		ADC  A
	.db 05Fh		;		MOV  E, A
	.db 006h,000h		;		MVI  B, 000h
	.db 004h		;	L_E080:	INR  B
	.db 0DBh,001h		;		IN      001h
	.db 0BAh		;		CMP  D
	.db 0CAh,080h,0E0h	;		JZ      L_E080
	.db 057h		;		MOV  D, A
	.db 079h		;		MOV  A, C
	.db 0B8h		;		CMP  B
	.db 07Bh		;		MOV  A, E
	.db 08Fh		;		ADC  A
	.db 05Fh		;		MOV  E, A
	.db 006h,000h		;		MVI  B, 000h
	.db 004h		;	L_E08F:	INR  B
	.db 0DBh,001h		;		IN      001h
	.db 0BAh		;		CMP  D
	.db 0CAh,08Fh,0E0h	;		JZ      L_E08F
	.db 057h		;		MOV  D, A
	.db 079h		;		MOV  A, C
	.db 0B8h		;		CMP  B
	.db 07Bh		;		MOV  A, E
	.db 08Fh		;		ADC  A
	.db 05Fh		;		MOV  E, A
	.db 006h,000h		;		MVI  B, 000h
	.db 004h		;	L_E09E:	INR  B
	.db 0DBh,001h		;		IN      001h
	.db 0BAh		;		CMP  D
	.db 0CAh,09Eh,0E0h	;		JZ      L_E09E
	.db 057h		;		MOV  D, A
	.db 079h		;		MOV  A, C
	.db 0B8h		;		CMP  B
	.db 07Bh		;		MOV  A, E
	.db 08Fh		;		ADC  A
	.db 05Fh		;		MOV  E, A
	.db 006h,000h		;		MVI  B, 000h
	.db 004h		;	L_E0AD:	INR  B
	.db 0DBh,001h		;		IN      001h
	.db 0BAh		;		CMP  D
	.db 0CAh,0ADh,0E0h	;		JZ      L_E0AD
	.db 057h		;		MOV  D, A
	.db 079h		;		MOV  A, C
	.db 0B8h		;		CMP  B
	.db 07Bh		;		MOV  A, E
	.db 08Fh		;		ADC  A
	.db 05Fh		;		MOV  E, A
	.db 006h,000h		;		MVI  B, 000h
	.db 004h		;	L_E0BC:	INR  B
	.db 0DBh,001h		;		IN      001h
	.db 0BAh		;		CMP  D
	.db 0CAh,0BCh,0E0h	;		JZ      L_E0BC
	.db 057h		;		MOV  D, A
	.db 079h		;		MOV  A, C
	.db 0B8h		;		CMP  B
	.db 07Bh		;		MOV  A, E
	.db 08Fh		;		ADC  A
	.db 05Fh		;		MOV  E, A
	.db 006h,000h		;		MVI  B, 000h
	.db 004h		;	L_E0CB:	INR  B
	.db 0DBh,001h		;		IN      001h
	.db 0BAh		;		CMP  D
	.db 0CAh,0CBh,0E0h	;		JZ      L_E0CB
	.db 057h		;		MOV  D, A
	.db 079h		;		MOV  A, C
	.db 0B8h		;		CMP  B
	.db 07Bh		;		MOV  A, E
	.db 08Fh		;		ADC  A
	.db 077h		;		MOV  M, A
	.db 0C6h,000h		;	X_E0D8:	ADI     000h
	.db 032h,0D9h,0E0h	;		STA     X_E0D8+1
	.db 02Ch		;		INR  L
	.db 0C2h,058h,0E0h	;		JNZ     L_E058
	.db 06Ch		;		MOV  L, H
	.db 026h,0DFh		;		MVI  H, 0DFh
	.db 036h,0F0h		;		MVI  M, 0F0h
	.db 065h		;		MOV  H, L
	.db 024h		;		INR  H
	.db 02Eh,000h		;		MVI  L, 000h
	.db 0C1h		;		POP  B
	.db 005h		;		DCR  B
	.db 0C2h,052h,0E0h	;		JNZ     L_E052
	.db 0CDh		;		CALL    L_FM9B
	.dw L_FM9B
	.db 04Fh		;		MOV  C, A
	.db 03Ah,0D9h,0E0h	;		LDA     X_E0D8+1
	.db 0B9h		;		CMP  C
	.db 0C2h,000h,000h	;		JNZ     M_0000
	.db 0CDh		;		CALL    L_FM9B
	.dw L_FM9B
	.db 0E1h		;		POP  H
	.db 0C1h		;		POP  B
	.db 0C9h		;		RET
;
F3_PRG:	;
;---------------------------------------------------------------------------------
; сюда дописываются "Бейсик 2.891" и "Монитор Супермонстр-2" в бинарном виде
;---------------------------------------------------------------------------------
;
	.ORG 07FF8h
L_SWMEM:MVI A, 003h
	OUT 00Dh	; переключение на другой банк ПЗУ
	JMP	L_START
	.db 000h	; контрольная сумма этой части ПЗУ
	.END
