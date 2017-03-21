;+--------------------------------------------------------------------------------------+
;| Trabajo Practico: Modo Protegido							|
;|--------------------------------------------------------------------------------------|
;| Ejercicio: 2.1	| Autor: Pablo Bronzone	| Curso: R5051	| Fecha: 17.05.2016	|
;|--------------------------------------------------------------------------------------|
;| Descripcion:										|
;|	Programa que inicia en modo real, luego pasa a modo protegido, permanece 	|
;|	esperando la tecla ESCape, luego se pone en modo halted.			|
;| Para compilar:									|
;|	nasm Init16.asm -o ROM.bin							|
;| Para ejecutar:									|
;|	bochs										|
;|											|
;|											|
;|											|
;|											|
;|--------------------------------------------------------------------------------------|
;| Revision	| Fecha		| Nombre	| Notas					|
;|--------------------------------------------------------------------------------------|
;| 1.1		| 17.05.2016	| P. Bronzone	| Version inicial			|
;| 		| 		|		|					|
;| 		| 		|		|					|
;+--------------------------------------------------------------------------------------+

BITS 16

Origen:
    jmp Inicio

struc	gdtd_t			;Definicion de la estructura denominada gdtd_t, la cual contiene los siguientes campos
	.limite:	resw 1	;Limite del segmento bits 00-15.
	.base00_15:	resw 1	;Direccion base del segmento bits 00-15.
	.base16_23:	resb 1	;Direccion base del segmento bits 16-23.
	.prop:  	resb 1	;Propiedades.
	.lim_prop:  	resb 1	;Limite del segmento 16-19 y propiedades.
	.base24_31:	resb 1	;Direccion base del segmento bits 24-31. 
endstruc

GDT:
; DESCRIPTOR NULO
NulDes:	
istruc gdtd_t
	at	gdtd_t.limite,		dw 0
	at	gdtd_t.base00_15,	dw 0
	at	gdtd_t.base16_23,	db 0
	at	gdtd_t.prop,		db 0
	at	gdtd_t.lim_prop,	db 0
	at	gdtd_t.base24_31,	db 0
iend

;DESCRIPTOR DE CODIGO FLAT
CodDes:	equ $-GDT 
istruc gdtd_t
	at	gdtd_t.limite,		dw 0xFFFF	; Limite (0-15) maximo
	at	gdtd_t.base00_15,	dw 0x0000	; Base (0-15) en 0
	at	gdtd_t.base16_23,	db 0x00		; Base (16-23) en 0
	at	gdtd_t.prop,		db 10011000b	; |P=1|DPL=00|S=1|1000 (descriptor de codigo, excecute only)
	at	gdtd_t.lim_prop,	db 11001111b	; |G=1|D/B=1|L=0|AVL=0|Limite (16-19)
	at	gdtd_t.base24_31,	db 0x00		; Base (24-31) en 0
iend

;DESCRIPTOR DE DATOS FLAT
DatDes:	equ $-GDT
istruc gdtd_t
	at	gdtd_t.limite,		dw 0xFFFF	; Limite (0-15) maximo
	at	gdtd_t.base00_15,	dw 0x0000	; Base (0-15) en 0
	at	gdtd_t.base16_23,	db 0x00		; Base (16-23) en 0
	at	gdtd_t.prop,		db 10010010b	; |P=1|DPL=00|S=1|0010 (descriptor de datos, read/write)
	at	gdtd_t.lim_prop,	db 11001111b	; |G=1|D/B=1|L=0|AVL=0|Limite (16-19) maximo
	at	gdtd_t.base24_31,	db 0x00		; Base (24-31) en 0
iend

ValorGDTR:	dw $-GDT	; Se componen los 48 bits que seran cargados en el registro GDTR
		dd GDT

ALIGN 4 			; Se alinea la pila para 32 bits

Stack		times 512 db 0 	; Se reserva memoria para una pila
InicioSP	equ $ 		; Se etiqueta el valor con que se inicializa el stack pointer

Inicio:
    
	cli			; Se desactivan las interrupciones
	xor eax,eax		; Se limpia eax
	mov ds,eax		; Se inicializan los registros de segmento
	mov es,eax
	mov ss,eax
	mov sp,InicioSP
	mov eax,cr0 		; Se copia el contrenido del registro de control 0
	or eax,0x0001 		; Se setea el bit de modo protegido en 1 (PM=1)
	mov cr0,eax
	jmp ModoProtegido 	; Se vacia el pipeline
    
ModoProtegido:
	xor eax,eax
	
EsperaTecla:
	in al,0x60 		; Se lee el puerto 0x60 correspondiente al teclado
	cmp al,0x01		; Se compara el valor obtenido con el correspondiente a la tecla ESC (0x01)
	jne EsperaTecla		; Si no es igual, continua esperando tecla

Halted:
	hlt			; Si fue igual a ESC, se haltea
	jmp Halted
	
times (65520 - ($-$$)) db 0	; Se rellena hasta los 64k - 16

ResetVect:
	cli			; En este punto inicia el procesador (0xFFFF0)
	cld
	jmp Origen

times (65536 - ($-$$)) db 0 ; Se rellena hasta los 64k (necesario)