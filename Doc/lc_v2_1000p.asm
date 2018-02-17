;Stazeno z www.HW.cz 
;	Autorem tohoto SW je Jiri Recek -  j_recek@del.cz
;	uprava proti nedokonalemu nulovani s indikaci OK2TEJ


; Program pro LC meter

kurzof	equ	0Ch		; Prikaz pro displej

CAL	bit	P1.4
CX	bit	P1.3

OSCOUT	bit	P3.5

LCD_E	bit	P3.4
LCD_RS	bit	P1.2
D4_R1	bit	P3.3
D5_R2	bit	P3.2
D6_R3	bit	P3.1
D7_R4	bit	P3.0

citca	data	14	; dìlen?kmitoètu pro èasovaèe
citc1s	data	15	; deleni pro 1Hz

MeziVysledek1	data	18	; 6 byt?
; 19..23
MeziVysledek2	data	24	; 6 byt?
; 25..29

; Bitov?oblast

Sign		bit	3	; Znamínko
nulovano	bit	4	; priznak OK nulovani
zmereno		bit	6	; frekvence pøeètena
zkalibrovano	bit	7

RozCas	data	39	; roz?íø?n?èasovaèe
frekvb	data	40	; 3byty zmìøen?frekvence

M1real	data	44	; mezivýsledek pro výpoèty
M2real	data	48	; mezivýsledek pro výpoèty
M3real	data	52	; mezivýsledek pro výpoèty
F2real	data	56	; frekvence po zmìøen?

; Kalibraèn?konstanty:
F1real	data	60	; frekvence naprázdno

C2real	data	64	; kapacita kalibraèního kondenzátoru
C1real	data	72	; kapacita kondenzátoru C1
L1real	data	76	; Indukènost cívky L1

kalnum	data	80	; pocet pruchodu pri kalibraci (1. neni pouzitelny)

; *********** zaèátek programu

; Reset
	org	0h
	AJMP	start

; Pøeru?en?od èasovaèe 0
	org	0Bh
	ajmp	intt0

; Pøeru?en?od èasovaèe 1
	org	1Bh
	inc	RozCas
	reti

	org	30h

start:
	CLR	EA
	MOV	SP,#88
	acall	init		; inicializace po zapnut?

; ***** Zaèátek cyklu
;  program b??stále dokola.

cykl:

	; zapamatovat frekvenci kalibraèn?
	;  pokud je stisknuto tlaèítko S2
	mov	c,CAL		; tlaèítko S2
	cpl	c
	anl	c,/zkalibrovano	; Pouze jednou v okam?iku sepnut?
	jnc	cykl03

	clr	nulovano
	mov	kalnum,#0
	mov	r0,#F2real		; Zkopírovat hodnotu
	mov	r1,#F1real
	acall	movreal
cykl03:

	mov	c,CAL
	cpl	c
	orl	c,zkalibrovano
	mov	zkalibrovano,c	; zapamatovat stav tlaèítka

	; Bitík je nahozen v programu pøeru?en?
	;  po zmìøen?frekvence.
	jnb	zmereno,cykl01

	acall	frekvence	; pøevod frekvence do F2real

	jb	CAL,cykl02
	acall	kalibrace	; Výpoèet kalibraèních hodnot

	mov	a,kalnum
	jz	cykl04
	setb	nulovano

cykl04:	inc	kalnum		; zrus priznak spatne kalibrace pri 2. pruchodu


cykl02:			;  pøi zmaèknutém tlaèítku S2

	mov	c,CAL
	cpl	c
	mov	zkalibrovano,c

	acall	mereni	; Výpoèet zmìøen?hodnoty

	clr	zmereno	; pøíznak vynulovat.
cykl01:

	acall	Zobraz	; Zobrazován?na displeji

	AJMP	cykl
; *********************************** Konec cyklu

; *********************************** 
kalibrace:	; Výpoèet kapacity kondenzátoru C1
		;  a indukènosti L1
	; L1=1
	mov	L1real,#0
	mov	L1real+1,#0
	mov	L1real+2,#80h
	mov	L1real+3,#3Fh

	; M2=1
	mov	M2real,#0
	mov	M2real+1,#0
	mov	M2real+2,#80h
	mov	M2real+3,#3Fh

	; L1=L1/F1
	mov	r0,#L1real
	mov	r1,#F1real
	acall	divreal
	mov	r0,#4		; adresa výsledku
	mov	r1,#L1real	;  výsledek ulo?it do L1
	acall	movreal

	; M1=F1/L1
	mov	r0,#F1real
	mov	r1,#L1real
	acall	divreal
	mov	r0,#4		; adresa výsledku
	mov	r1,#M1real
	acall	movreal

	; M2=M2/F2
	mov	r0,#M2real
	mov	r1,#F2real
	acall	divreal
	mov	r0,#4		; adresa výsledku
	mov	r1,#M2real
	acall	movreal

	; M2=F2/M2
	mov	r0,#F2real
	mov	r1,#M2real
	acall	divreal
	mov	r0,#4		; adresa výsledku
	mov	r1,#M2real
	acall	movreal

	; C1=M2
	mov	r0,#M2real
	mov	r1,#C1real
	acall	movreal

	; M2=-M2
	xrl	M2real+3,#80h

	; M1=M1+M2
	mov	r0,#M1real
	mov	r1,#M2real
	acall	addreal
	mov	r0,#4		; adresa výsledku
	mov	r1,#M1real
	acall	movreal

	; C1=C1/M1
	mov	r0,#C1real
	mov	r1,#M1real
	acall	divreal
	mov	r0,#4		; adresa výsledku
	mov	r1,#C1real
	acall	movreal

	; M1=1
	mov	M1real,#0
	mov	M1real+1,#0
	mov	M1real+2,#80h
	mov	M1real+3,#3Fh

	; M1=M1/C2
	mov	r0,#M1real
	mov	r1,#C2real
	acall	divreal
	mov	r0,#4		; adresa výsledku
	mov	r1,#M1real
	acall	movreal

	; C1=C1/M1
	mov	r0,#C1real
	mov	r1,#M1real
	acall	divreal
	mov	r0,#4		; adresa výsledku
	mov	r1,#C1real
	acall	movreal

	; L1=L1/F1
	mov	r0,#L1real
	mov	r1,#F1real
	acall	divreal
	mov	r0,#4		; adresa výsledku
	mov	r1,#L1real
	acall	movreal

	; M1=4PI^2
	mov	M1real,#0E6h
	mov	M1real+1,#0E9h
	mov	M1real+2,#1Dh
	mov	M1real+3,#42h

	; L1=L1/M1
	mov	r0,#L1real
	mov	r1,#M1real
	acall	divreal
	mov	r0,#4		; adresa výsledku
	mov	r1,#L1real
	acall	movreal

	; L1=L1/C1
	mov	r0,#L1real
	mov	r1,#C1real
	acall	divreal
	mov	r0,#4		; adresa výsledku
	mov	r1,#L1real
	acall	movreal

	ret

; *********************************** 
mereni:	; Výpoèet zmìøen?hodnoty
	; M1real=1
	mov	M1real,#0
	mov	M1real+1,#0
	mov	M1real+2,#80h
	mov	M1real+3,#3Fh

	; M2real=1
	mov	M2real,#0
	mov	M2real+1,#0
	mov	M2real+2,#80h
	mov	M2real+3,#3Fh

	; M1real=1/F1
	mov	r0,#M1real
	mov	r1,#F1real
	acall	divreal
	mov	r0,#4		; výsledek
	mov	r1,#M1real	; do M1real
	acall	movreal

	; M1real=F1real/M1real
	mov	r0,#F1real
	mov	r1,#M1real
	acall	divreal
	mov	r0,#4		; adresa výsledku
	mov	r1,#M1real
	acall	movreal

	; M1real=M1real/F2real
	mov	r0,#M1real
	mov	r1,#F2real
	acall	divreal
	mov	r0,#4		; adresa výsledku
	mov	r1,#M1real
	acall	movreal

	; M1real=M1real/F2real
	mov	r0,#M1real
	mov	r1,#F2real
	acall	divreal
	mov	r0,#4		; adresa výsledku
	mov	r1,#M1real
	acall	movreal

	; M2real=M2real/C1real
	mov	r0,#M2real
	mov	r1,#C1real		; Pokud je mìøen?kapacity
	jnb	CX,mereni01
	mov	r1,#L1real		; Pokud je mìøen?indukènosti
mereni01:
	acall	divreal
	mov	r0,#4		; adresa výsledku
	mov	r1,#M2real
	acall	movreal

	; M1real=M1real/M2real
	mov	r0,#M1real
	mov	r1,#M2real
	acall	divreal
	mov	r0,#4		; adresa výsledku
	mov	r1,#M1real
	acall	movreal

	; M1real=M1real-C1real
	xrl	C1real+3,#80h	; znaménko minus
	xrl	L1real+3,#80h	; znaménko minus
	mov	r0,#M1real
	mov	r1,#C1real		; Pokud je mìøen?kapacity
	jnb	CX,mereni02
	mov	r1,#L1real		; Pokud je mìøen?indukènosti
mereni02:
	acall	addreal
	xrl	C1real+3,#80h
	xrl	L1real+3,#80h
	mov	r0,#4		; adresa výsledku
	mov	r1,#M1real
	acall	movreal

	ret

; *********************************** 
movreal:	; kopie èty?byt?
	; @r0 - odkud
	; @r1 - kam

	mov	r2,#4
	push	acc
movreal01:
	mov	a,@r0
	mov	@r1,a
	inc	r0
	inc	r1
	djnz	r2,movreal01

	mov	r2,#4
movreal02:
	dec	r0
	dec	r1
	djnz	r2,movreal02

	pop	acc

	ret

; *********************************** 
frekvence:	; pøevod frekvence do real

	mov	r0,#2
frekvence1:
	clr	c
	mov	a,F2real
	rlc	a
	mov	F2real,a
	mov	frekvb,a
	mov	a,F2real+1
	rlc	a
	mov	F2real+1,a
	mov	frekvb+1,a
	mov	a,F2real+2
	rlc	a
	mov	F2real+2,a
	mov	frekvb+2,a
	djnz	r0,frekvence1

	mov	r0,#F2real
	clr	a
	mov	F2real+3,a
	acall	dtr		; double word to real

	; Korekce kmitoètu krystalu
	mov	M2real+3,#03Fh	; 0.999831331
	mov	M2real+2,#07Fh
	mov	M2real+1,#0F4h
	mov	M2real,#0F2h

	mov	r0,#F2real
	mov	r1,#M2real
	acall	divreal
	mov	r0,#4
	mov	r1,#F2real
	acall	movreal

	ret
	
; ***********************************
dtr:		; pøevod double word to real
	; @r0 - adresa èísla

	mov	r1,#31+127	; exponent
	clr	a
	mov	r2,#4
dtr00:
	orl	a,@r0
	inc	r0
	djnz	r2,dtr00

	jnz	dtr02
	; Hodnota je nulov?
	mov	r2,#4
dtr01:
	dec	r0
	mov	@r0,a
	djnz	r2,dtr01
	ajmp	dtr03		; konec
dtr02:

dtr04:	; posunut?
	dec	r0
	mov	a,@r0
	jb	acc.7,dtr05
	dec	r1		; sn?it exponent
	mov	r2,#4
	clr	c

	dec	r0
	dec	r0
	dec	r0
dtr06:
	mov	a,@r0
	rlc	a
	mov	@r0,a
	inc	r0
	djnz	r2,dtr06
	ajmp	dtr04

dtr05:
	mov	a,r1		; exponent
	clr	c		; SIGN - kladn?
	rrc	a
	xch	a,@r0
	dec	r0
	mov	acc.7,c	; nejni???bit exponentu
	xch	a,@r0
	dec	r0
	xch	a,@r0
	dec	r0
	mov	@r0,a		; hotovo - real 32 bit
	
dtr03:
	ret

; ***********************************
divreal:	; Dìlen?reálných èísel
	; @r0 - dìlenec
	; @r1 - dìlitel
	;  výsledek je v r4 a? r7

	; pøesun dìlence do mezivýsledku
	mov	MeziVysledek1,#0
	mov	MeziVysledek1+1,#0
	mov	MeziVysledek1+2,#0
	mov	MeziVysledek1+3,@r0
	inc	r0
	mov	MeziVysledek1+4,@r0
	inc	r0
	mov	MeziVysledek1+5,@r0
	orl	MeziVysledek1+5,#80H	; nastavit jednièku

	; pøesun dìlitele do druhého mezivýsledku
	mov	MeziVysledek2,#0
	mov	MeziVysledek2+1,#0
	mov	MeziVysledek2+2,#0
	mov	MeziVysledek2+3,@r1
	inc	r1
	mov	MeziVysledek2+4,@r1
	inc	r1
	mov	MeziVysledek2+5,@r1
	orl	MeziVysledek2+5,#80H	; nastavit jednièku

	; úschova adres
	mov	a,r0
	push	acc
	mov	a,r1
	push	acc

	mov	r3,#24
divreal00:

	; Odeèten?
	mov	r0,#Mezivysledek1
	mov	r1,#Mezivysledek2
	mov	r2,#6			; 6 byt?
	clr	c
divreal01:
	mov	a,@r0
	subb	a,@r1
	mov	@r0,a
	inc	r0
	inc	r1
	djnz	r2,divreal01

	; schovat výsledek
	mov	f0,c
	cpl	c
	mov	a,r4
	rlc	a
	mov	r4,a
	mov	a,r5
	rlc	a
	mov	r5,a
	mov	a,r6
	rlc	a
	mov	r6,a

	jnb	f0,divreal05
	; Pøièten?
	mov	r0,#Mezivysledek1
	mov	r1,#Mezivysledek2
	mov	r2,#6			; 6 byt?
	clr	c
divreal03:
	mov	a,@r0
	addc	a,@r1
	mov	@r0,a
	inc	r0
	inc	r1
	djnz	r2,divreal03
divreal05:

	; Posunut?dìlitele
	mov	r1,#Mezivysledek2+5
	mov	r2,#6			; 6 byt?
	clr	c
divreal06:
	mov	a,@r1
	rrc	a
	mov	@r1,a
	dec	r1
	djnz	r2,divreal06

	djnz	r3,divreal00

	; obnova adres
	pop	acc
	mov	r1,a
	pop	acc
	mov	r0,a

	; Výpoèet exponentu
	mov	a,@r1
	inc	r1
	rlc	a
	mov	a,@r1
	rlc	a
	mov	b,a
	mov	a,@r0
	inc	r0
	rlc	a
	mov	a,@r0
	rlc	a
	clr	c
	subb	a,b
	add	a,#127
	mov	r7,a
	mov	a,r6
	jb	acc.7,divreal07
	clr	c
	mov	a,r4
	rlc	a
	mov	r4,a
	mov	a,r5
	rlc	a
	mov	r5,a
	mov	a,r6
	rlc	a
	mov	r6,a
	dec	r7
divreal07:
	clr	c		; Posunut?exponentu
	mov	a,r7
	rrc	a
	mov	r7,a
	mov	a,r6
	mov	acc.7,c
	mov	r6,a

	; znaménko
	mov	a,@r0
	xrl	a,@r1
	anl	a,#80H
	orl	a,r7
	mov	r7,a

	ret

; ***********************************
AddReal:	; Seèítán?reálných èísel
	; @r0 a @r1
	;  výsledek je v r4 a? r7

	; Kontrola znaménka
	inc	r0
	inc	r1
	inc	r0
	inc	r1
	inc	r0
	inc	r1
	mov	a,@r0
	xrl	a,@r1
	rlc	a
	mov	f0,c		; f0=1 - bude se odeèítat
	mov	a,@r0
	jnb	acc.7,addreal00a
	; Pøehodit èísla
	xch	a,r0		; r0 <-> r1
	xch	a,r1
	xch	a,r0
addreal00a:
	; pøesun 1. èísla do mezivýsledku
	mov	MeziVysledek1+5,@r0	; pro znaménko
	dec	r0
	mov	a,@r0
	rlc	a
	inc	r0
	mov	a,@r0
	rlc	a
	mov	MeziVysledek1+4,a		; pro exponent
	dec	r0
	mov	MeziVysledek1+3,@r0
	jz	addreal00b
	orl	MeziVysledek1+3,#80H	; nastavit jednièku
addreal00b:
	dec	r0
	mov	MeziVysledek1+2,@r0
	dec	r0
	mov	MeziVysledek1+1,@r0
	mov	MeziVysledek1,#0
	; pøesun 2. èísla do mezivýsledku
	mov	MeziVysledek2+5,@r1	; pro znaménko
	dec	r1
	mov	a,@r1
	rlc	a
	inc	r1
	mov	a,@r1
	rlc	a
	mov	MeziVysledek2+4,a		; pro exponent
	dec	r1
	mov	MeziVysledek2+3,@r1
	jz	addreal00c
	orl	MeziVysledek2+3,#80H	; nastavit jednièku
addreal00c:
	dec	r1
	mov	MeziVysledek2+2,@r1
	dec	r1
	mov	MeziVysledek2+1,@r1
	mov	MeziVysledek2,#0

addreal00:
	; Srovnat øádov?podle exponentu
	mov	r0,#MeziVysledek1+4
	mov	r1,#MeziVysledek2+4
	clr	c
	mov	a,@r1
	jz	addreal02
	mov	a,@r0
	jz	addreal02
	subb	a,@r1
	jz	addreal02
	jnc	addreal01
	; Pøehodit èísla
	xch	a,r0		; r0 <-> r1
	xch	a,r1
	xch	a,r0
addreal01:
	inc	@r1		; exponent zv?it
	mov	r2,#4
	clr	c
addreal03:
	dec	r1
	mov	a,@r1
	rrc	a
	mov	@r1,a
	djnz	r2,addreal03	; ètyøi byty
	ajmp	addreal00

addreal02:
	; Kontrola, jestli je prvn?èíslo nulov?
	mov	a,@r0
	jnz	addreal04
	mov	a,@r1
	mov	@r0,a
addreal04:

	; Operace
	mov	r0,#MeziVysledek1
	mov	r1,#MeziVysledek2
	mov	r2,#4		; Ètyøi byty
	clr	c
	jb	f0,addreal05	; Pokud je 1, bude se odèítat
addreal07:
	; Pøièten?
	mov	a,@r0
	addc	a,@r1
	mov	@r0,a
	inc	r0
	inc	r1
	djnz	r2,addreal07
	jnc	addreal06
	inc	@r0
	mov	a,@r0
	mov	r2,#4
addreal08:
	dec	r0
	mov	a,@r0
	rrc	a
	mov	@r0,a
	djnz	r2,addreal08
	ajmp	addreal06
addreal05:
	; Odeèten?
	mov	a,@r0
	subb	a,@r1
	mov	@r0,a
	inc	r0
	inc	r1
	djnz	r2,addreal05
	jnc	addreal09
	; Vy?lo záporn?èíslo
	mov	r2,#4
	mov	a,r0
	add	a,#256-4
	mov	r0,a
addreal10:	; dvojkov?komplement
	mov	a,@r0
	cpl	a
	addc	a,#0
	mov	@r0,a
	inc	r0
	djnz	r2,addreal10
	xrl	MeziVysledek1+5,#80H	; zmìnit znaménko
addreal09:	; kontrola nulovosti
	mov	r2,#4
	clr	a
addreal11:
	dec	r0
	orl	a,@r0
	djnz	r2,addreal11
	jnz	addreal12
	mov	MeziVysledek1+4,a		; vynulovat exponent
	ajmp	addreal06
addreal12:	; Posunut?exponentu
	mov	a,MeziVysledek1+3
	rlc	a
	jc	addreal06
	mov	r0,#MeziVysledek1
	mov	r2,#4
	clr	c
addreal13:
	mov	a,@r0
	rlc	a
	mov	@r0,a
	inc	r0
	djnz	r2,addreal13
	dec	@r0		; sn?it exponent
	ajmp	addreal12
addreal06:
	; Ulo?en?výsledku do r4..r7
	mov	a,MeziVysledek1+5
	anl	a,#80H	; jen znaménko
	mov	r7,a
	mov	a,MeziVysledek1+4
	clr	c
	rrc	a
	orl	a,r7
	mov	r7,a
	mov	a,MeziVysledek1+3
	mov	acc.7,c
	mov	r6,a
	mov	r5,MeziVysledek1+2
	mov	r4,MeziVysledek1+1

	ret

; ***********************************
; Nastaveni kurzoru
NasKurzor:
	clr	LCD_RS	; RS - registr select - LCD displej
	acall	ChOut
	setb	LCD_RS	; RS - registr select - LCD displej

	ret

; ***********************************
; Ovládán?zobrazován?

Zobraz:	;
	MOV	A,#080H	; Kurzor na 1. øádek, 1. znak
	acall	NasKurzor

	mov	a,#'C'	; Pokud je mìøen?kapacity

	jnb	CX,Zobraza
	mov	a,#'L'	; Pokud je mìøen?indukènosti
Zobraza:
	acall	ChOut
	mov	a,#'x'
	acall	ChOut
	mov	a,#'='
	acall	ChOut

; Pøevádìn?na rozumn?zobrazen?
	mov	dptr,#TabZobr
	; V b bude exponent desítkovej
	mov	b,#0		; Nejmen??zobrazen?pro kondy
	jnb	CX,Zobrazg1
	mov	b,#5		; Nejmen??zobrazen?pro cívky
Zobrazg1:

; Výbìr konstanty pro pøevod z tabulky
	mov	a,b
	clr	c
	subb	a,#21
	jnc	Zobrazg2	; Konec tabulky
	mov	a,b
	rl	a		; krát 4
	rl	a		;  (1 hodnota = 4 byty)
	mov	M2real,a
	inc	a
	mov	M2real+3,a
	inc	a
	mov	M2real+2,a
	inc	a

	movc	a,@a+dptr
	xch	a,M2real
	movc	a,@a+dptr
	xch	a,M2real+3
	movc	a,@a+dptr
	xch	a,M2real+2
	movc	a,@a+dptr
	mov	M2real+1,a
	inc	b

	; Porovnaj?se exponenty a podle toho se vybír?
	;  dal??konstanta a nebo se nech?vyzvednut?

	mov	a,M1real+2		; exponent výsledku
	rlc	a
	mov	a,M1real+3
	rlc	a
	jz	Zobrazg2		; Pokud je nula

	mov	r0,a
	mov	a,M2real+2		; exponent dìlitele
	rlc	a
	mov	a,M2real+3
	rlc	a
	xch	a,r0
	clr	c
	subb	a,r0
	add	a,#256-14-1		; 2^14 = 16384 - rozli?en?
	jc	Zobrazg1
Zobrazg2:
	push	b

	; M3=M1/M2
	mov	r0,#M1real
	mov	r1,#M2real
	acall	divreal
	mov	r0,#4
	mov	r1,#M3real
	acall	movreal

; Pøeveden?na BCD
	mov	r0,#M3real
	mov	r1,#MeziVysledek1
	acall	realbcd

	mov	c,f0
	mov	Sign,c

	pop	b
	mov	a,#3
	xch	a,b
	div	ab
	mov	r0,b		; Posice desetinn?teèky

	; Podle exponentu pøedpona
	mov	dptr,#TabPredp
	mov	r1,#MeziVysledek1+10
	movc	a,@a+dptr
	mov	@r1,a

	dec	r1
	mov	@r1,#' '
	jnb	Sign,Zobrazh1
	mov	@r1,#'-'
Zobrazh1:

	dec	r1
	mov	a,MeziVysledek1+3	; 10^7
	swap	a
	anl	a,#0Fh
	add	a,#'0'
	mov	@r1,a

	dec	r1
	mov	a,MeziVysledek1+3	; 10^6
	anl	a,#0Fh
	add	a,#'0'
	mov	@r1,a

	dec	r1
	mov	a,MeziVysledek1+2	; 10^5
	swap	a
	anl	a,#0Fh
	add	a,#'0'
	mov	@r1,a

	dec	r1
	mov	a,MeziVysledek1+2	; 10^4
	anl	a,#0Fh
	add	a,#'0'
	mov	@r1,a

	dec	r1
	mov	a,MeziVysledek1+1	; 10^3
	swap	a
	anl	a,#0Fh
	add	a,#'0'
	mov	@r1,a

	dec	r1
	mov	a,r0			; Posice desetinn?teèky
	jnz	Zobrazh3
	mov	@r1,#'.'
	dec	r1
Zobrazh3:
	mov	a,MeziVysledek1+1	; 10^2
	anl	a,#0Fh
	add	a,#'0'
	mov	@r1,a

	dec	r1
	mov	a,r0			; Posice desetinn?teèky
	add	a,#256-1
	jnz	Zobrazh4
	mov	@r1,#'.'
	dec	r1
Zobrazh4:
	mov	a,MeziVysledek1	; 10^1
	swap	a
	anl	a,#0Fh
	add	a,#'0'
	mov	@r1,a

	dec	r1
	mov	a,r0			; Posice desetinn?teèky
	add	a,#256-2
	jnz	Zobrazh5
	mov	@r1,#'.'
	dec	r1
Zobrazh5:
	mov	a,MeziVysledek1	; 10^0
	anl	a,#0Fh
	add	a,#'0'
	mov	@r1,a

	mov	a,MeziVysledek1+9
	acall	ChOut

	mov	a,MeziVysledek1+8
	add	a,#256-'0'
	jz	Zobrazi1
	mov	a,MeziVysledek1+8
	acall	ChOut
	ajmp	Zobrazi3
Zobrazi1:

	mov	a,MeziVysledek1+7
	add	a,#256-'0'
	jz	Zobrazi2
Zobrazi3:
	mov	a,MeziVysledek1+7
	acall	ChOut
	ajmp	Zobrazi5
Zobrazi2:

	mov	a,MeziVysledek1+6
	add	a,#256-'0'
	jz	Zobrazi4
Zobrazi5:
	mov	a,MeziVysledek1+6
	acall	ChOut
	ajmp	Zobrazi7
Zobrazi4:

	mov	a,MeziVysledek1+5
	add	a,#256-'0'
	mov	r0,#' '
	jz	Zobrazi6
Zobrazi7:
	mov	r0,MeziVysledek1+5
Zobrazi6:
	mov	a,r0
	acall	ChOut

	mov	a,MeziVysledek1+4
	acall	ChOut

	mov	a,MeziVysledek1+3
	acall	ChOut

	mov	a,MeziVysledek1+2
	acall	ChOut

	mov	a,MeziVysledek1+1
	acall	ChOut

	mov	a,MeziVysledek1
	acall	ChOut


	mov	a,#' '
	acall	ChOut
	mov	a,MeziVysledek1+10
	acall	ChOut
	jb	cx,Zobraza2
	mov	a,#'F'
	acall	ChOut
	ajmp	Zobraza3
Zobraza2:
	mov	a,#'H'
	acall	ChOut
Zobraza3:
	mov	a,#' '
	acall	ChOut
	mov	a,#' '
	acall	ChOut
	mov	a,#' '
	acall	ChOut

	mov	r0,#frekvb
	mov	r1,#MeziVysledek1
	acall	bin_bcd

; Na druhém øádku je zobrazena aktuáln?frekvence.

	MOV	A,#0C0H	; Kurzor na 2. øádek, 1. znak
	acall	NasKurzor

	mov	a,MeziVysledek1+2
	acall	prthex
	mov	a,MeziVysledek1+1
	acall	prthex
	mov	a,MeziVysledek1
	acall	prthex

	mov	a,#' '
	acall	ChOut
	mov	a,#'H'
	acall	ChOut
	mov	a,#'z'
	acall	ChOut
	mov	a,#' '
	acall	ChOut

	mov	a,#' '
	acall	ChOut
	mov	a,#' '
	acall	ChOut
	jb	nulovano,zobret		; zobrazi pozadavek na nulovani
	mov	a,#'!'
	acall	ChOut
	mov	a,#'N'
	acall	ChOut
	mov	a,#'u'
	acall	ChOut
	mov	a,#'l'
	ajmp	ChOut

zobret:	mov	a,#' '
	acall	ChOut
	mov	a,#' '
	acall	ChOut
	mov	a,#' '
	acall	ChOut
	mov	a,#' '
	acall	ChOut
	ret

; ********************************************
TabZobr:	; Tabulka pro násoben?
	; 0  10^-14 (setiny piko)
	db	028h,034h,024h,0DCh
	; 1  10^-13 (desetiny piko)
	db	029h,0E1h,02Eh,013h
	; 2  10^-12 (piko)
	db	02Bh,08Ch,0BCh,0CCh
	; 3  10^-11 (setiny nano)
	db	02Dh,02Fh,0EBh,0FFh
	; 4  10^-10 (desetiny nano)
	db	02Eh,0DBh,0E6h,0FFh
	; 5  10^-9 (nano)
	db	030h,089h,070h,05Fh
	; 6  10^-8 (setiny mikro)
	db	032h,02Bh,0CCh,077h
	; 7  10^-7 (desetiny mikro)
	db	033h,0D6h,0BFh,095h
	; 8  10^-6 (mikro)
	db	035h,086h,037h,0BDh
	; 9  10^-5 (setiny mili)
	db	037h,027h,0C5h,0ACh
	; 10 10^-4 (desetiny mili)
	db	038h,0D1h,0B7h,017h
	; 11 10^-3 (mili)
	db	03Ah,083h,012h,06Fh
	; 12 10^-2 (setiny)
	db	03Ch,023h,0D7h,00Ah
	; 13 10^-1 (desetiny)
	db	03Dh,0CCh,0CCh,0CDh
	; 14 10^0 (jednotky)
	db	03Fh,080h,000h,000h
	; 15 10^1 (setiny kila)
	db	041h,020h,000h,000h
	; 16 10^2 (desetiny kila)
	db	042h,0C8h,000h,000h
	; 17 10^3 (kila)
	db	044h,07Ah,000h,000h
	; 18 10^4 (setiny mega)
	db	046h,01Ch,040h,000h
	; 19 10^5 (desetiny mega)
	db	047h,0C3h,050h,000h
	; 20 10^6 (mega)
	db	049h,074h,024h,000h

TabPredp:	; Podle exponentu pøedpona
	db	'p','n',0,'m'
	db	' ','k','M','G'

; ***********************
; pro inicializaci displeje
InitDispl:
	rlc	a
	mov	D7_R4,C
	rlc	a
	mov	D6_R3,C
	rlc	a
	mov	D5_R2,C
	rlc	a
	mov	D4_R1,C
InitDispl1:
	MOV	A,#120
	acall	Delay		; Prodleva
	djnz	r1,InitDispl1
	SETB	LCD_E		; zápis do displeje
	nop
	CLR	LCD_E

	ret

; *********************
; Pøevod bin - bcd @r0 -> @r1

bin_bcd:
	mov	a,@r0
	mov	r3,a
	inc	r0
	mov	a,@r0
	mov	r4,a
	inc	r0
	mov	a,@r0
	mov	r5,a
	dec	r0
	dec	r0

	mov	r2,#23
	ajmp	RealBcdS

; *********************
; Pøevod real - bcd @r0 -> @r1

realbcd:
	; Mantisa do r3..5
	mov	b,r0		; Schovat adresu
	mov	a,@r0
	mov	r3,a
	inc	r0
	mov	a,@r0
	mov	r4,a
	inc	r0
	mov	a,@r0
	mov	r6,a
	orl	a,#80h
	mov	r5,a
	inc	r0

	; Exponent do r2
	mov	a,r6
	rlc	a
	mov	a,@r0
	rlc	a
	mov	f0,c		; Znaménko
	add	a,#256-127
	mov	r2,a
	mov	r0,b

RealBcdS:
	; Vynulovat - nachystat výsledek
	mov	b,r1		; schovat adresu výsledku
	mov	r6,#4
	clr	a
realbcd1:
	mov	@r1,a
	inc	r1
	djnz	r6,realbcd1
	mov	r1,b		; Vyzvednout adresu výsledku

realbcdc:
	mov	a,r2
	rlc	a		; Pokud je exponent men??ne? nula
	jc	realbcdk	;  tak konec.
	; posun bitu do CY
	mov	a,r3
	rlc	a
	mov	r3,a
	mov	a,r4
	rlc	a
	mov	r4,a
	mov	a,r5
	rlc	a
	mov	r5,a

; Pøièten?ve výsledku
	mov	b,r1
	mov	r6,#4
realbcdd:
	mov	a,@r1
	addc	a,acc
	da	a
	mov	@r1,a
	inc	r1
	djnz	r6,realbcdd
	mov	r1,b
	dec	r2
	ajmp	realbcdc
realbcdk:

	ret

; ************************
; inicializace

init:
	clr	c

	MOV	citca,#48

	; Inicializace displeje
	CLR	LCD_E
	CLR	LCD_RS	; RS - registr select - LCD displej
;	CLR	LCD_RW

	mov	a,#30h
	mov	r1,#20	; casova prodleva
	acall	InitDispl

	mov	a,#30h
	mov	r1,#5		; casova prodleva
	acall	InitDispl

	mov	a,#30h
	mov	r1,#1		; casova prodleva
	acall	InitDispl

	mov	a,#20h
	mov	r1,#1		; èasov?prodleva
	acall	InitDispl

	MOV	TMOD,#01010010b
	CLR	A
	MOV	IE,A
	MOV	IP,A
	MOV	TL0,a
	MOV	TH0,#256-64	; pøeru?en?14400 Hz

	SETB	ET0		; povolit pøeru?en?T0
	SETB	ET1		; povolit pøeru?en?T1
	setb	pt1		; vy???priorita T1

	SETB	EA		; povolit pøeru?en?

	SETB	TR0		; zapnuti casovace
	SETB	TR1		; zapnuti citace

	MOV	A,#120
	acall	Delay		; Prodleva
	MOV	A,#28H	; Nastavit LCD na 2 øádky
	acall	ChOut
	MOV	A,#120
	acall	Delay		; Prodleva
	MOV	A,#kurzof	; LCD on, Cursor off, Blink off
	acall	ChOut
	MOV	A,#06H	; inkrement, S=0
	acall	ChOut

	; Naloudovat znak mikro
	mov	a,#40h		; 
	acall	NasKurzor		; 
	mov	a,#00000000b	; ?  ?
	acall	ChOut			; ?  ?
	mov	a,#00000000b	; ?  ?
	acall	ChOut			; ? §§
	mov	a,#00010001b	; §§??
	acall	ChOut			; ?
	mov	a,#00010001b
	acall	ChOut
	mov	a,#00010001b
	acall	ChOut
	mov	a,#00010011b
	acall	ChOut
	mov	a,#00011101b
	acall	ChOut
	mov	a,#00010000b
	acall	ChOut

        MOV     A,#80H  ; Kurzor na 1. øádek, 1. znak
        acall   NasKurzor

	clr	nulovano

; Nastaven?hodnot:
	; C2= 1000pF
	mov	C2real,#87h
	mov	C2real+1,#10h
	mov	C2real+2,#88h
	mov	C2real+3,#30h

	ret

; ************* Pøeru?en?od èasovaèe T0
	; Pøeru?en?jednou za 64 cykl? to je
	;  11059200 / 12 / 64 = 14400 Hz.

intt0:
	DJNZ	citca,IntT02
	MOV	citca,#36
	DJNZ	citc1s,IntT02
	MOV	citc1s,#100

	push	acc
	push	psw

	clr	a
	xch	a,tl1		; 
	mov	F2real,a	; ulo?en?zmìøen?frekvence
	clr	a
	xch	a,th1
	mov	F2real+1,a
	clr	a
	xch	a,RozCas
	mov	F2real+2,a
	setb	zmereno

	pop	psw
	pop	acc

IntT02:

	RETI

; *********** Zobrazen?hex bytu
prthex:
	clr	f0
	MOV	R3,#2		; Ka?d?byte dvakrát
prthex2:
	push	acc
	ANL	A,#0F0H	; Jednu pùlku
	SWAP	A
	ADD	A,#'0'	; z BCD na ASCII
	PUSH	ACC
	CLR	C
	SUBB	A,#':'
	POP	ACC
	JC	prthex1
	ADD	A,#7		; Pokud je více ne? 9
prthex1:
	acall	ChOut
	jnb	f0,prthex3
	mov	a,r3
	jb	acc.0,prthex3
	mov	a,#'.'
	acall	ChOut
prthex3:
	pop	acc		; Je?t?druhou pùlku
	SWAP	A
	DJNZ	R3,prthex2

	ret

; ************** Výstup znaku na LCD po 4 bitech
ChOut:
        PUSH    ACC
        MOV     A,#5
        acall   Delay
        POP     ACC
        rlc     a
        mov     D7_R4,C
        rlc     a
        mov     D6_R3,C
        rlc     a
        mov     D5_R2,C
        rlc     a
        mov     D4_R1,C
        nop
        SETB    LCD_E
        nop
        CLR     LCD_E
        rlc     a
        mov     D7_R4,C
        rlc     a
        mov     D6_R3,C
        rlc     a
        mov     D5_R2,C
        rlc     a
        mov     D4_R1,C
        nop
        SETB    LCD_E
        nop
        CLR     LCD_E
        RET

; Èasov?prodleva 10 cykl?krát hodnota v ACC, co? je
;  pøi 12Mhz 10 mikrosekund.
Delay:
        PUSH    ACC
        MOV     A,#02H
        MOV     A,#01H
Delay1:
        DJNZ    ACC,Delay1
        POP     ACC
        DJNZ    ACC,Delay
        RET

	end
