; keyboard and subprograms
STACK SEGMENT PARA STACK
DW 100 DUP(?)
STACK ENDS

DATA SEGMENT PARA

CHS_S DB 0DH, 0AH,'Press 1 ~ 7 to call sub program. Press ESC to exit.',0DH,0AH,'$'
D2H_S DB 'Decimal to heximal',0DH,0AH,'$'
H2D_S DB 'Heximal to decimal',0DH,0AH,'$'
CPY_S DB 'String copy',0DH,0AH,'$'
CMP_S DB 'String compare',0DH,0AH,'$'
MUL_S DB 'Mulitiply',0DH,0AH,'$'
SRH_S DB 'Search',0DH,0AH,'$'
SRT_S DB 'Sort',0DH,0AH,'$'

MENU DW D_TO_H, H_TO_D, STRCPY, STRCMP, MUL_NUM, SEARCH, SORT

HEX_NUM DW 0FFH
DEC_NUM DB '1024','$'
DEC_NUM2 DB 10 DUP(?)

STRING1 DB 'this is a string','$'
STRING2 DB 20 DUP(?)
STRING3 DB 'this is a string2','$'

NUM1 DD 060009H
NUM2 DD 070008H
RESULT DD 2 DUP(?)

DATA ENDS

CODE SEGMENT PARA
	ASSUME CS:CODE , DS:DATA, SS:STACK 

PRINTS	MACRO STR
	MOV DX, OFFSET STR
	MOV AH,	9
	INT	21H
		ENDM


START:
	MOV AX, DATA
	MOV DS, AX
	MOV ES, AX

CHOOSE:
	PRINTS CHS_S	; Print tips string.
	
	MOV AH, 0 ; Get a key
	INT 16H

	CMP AH, 1 ; If press ESC , exit
	JE END_L

	CMP AH, 8
	JA	CHOOSE

	SUB AH,2 	; From scan code to index
	MOV BL,AH
	XOR BH,BH
	SHL BX,1
	ADD BX, OFFSET MENU
	JMP [BX]
END_L:
	MOV AH, 4CH
	INT 21H
D_TO_H:
	
	PRINTS D2H_S
	
	MOV AX, OFFSET DEC_NUM 	; Decimal string
	PUSH AX
	CALL D2H_FUNC
	JMP CHOOSE

H_TO_D:
	PRINTS H2D_S
	
	MOV AX, OFFSET DEC_NUM2 ; Decimal string
	PUSH AX
	MOV AX, HEX_NUM 	; Heximal number
	PUSH AX
	CALL H2D_FUNC

	JMP CHOOSE

STRCPY:
	PRINTS CPY_S
	
	MOV AX, OFFSET STRING1	; src_string
	PUSH AX
	MOV AX, OFFSET STRING2	; dst_string
	PUSH AX
	CALL STRCPY_FUNC

	JMP CHOOSE

STRCMP:
	PRINTS CMP_S
	MOV AX, OFFSET STRING1	; str2
	PUSH AX
	MOV AX, OFFSET STRING3	; str1
	PUSH AX
	CALL STRCMP_FUNC
	JMP CHOOSE

MUL_NUM:
	PRINTS MUL_S
	MOV AX,OFFSET NUM2
	PUSH AX
	MOV AX,OFFSET NUM1
	PUSH AX
	MOV AX,OFFSET RESULT
	PUSH AX
	CALL MUL_FUNC
	JMP CHOOSE
SEARCH:
	PRINTS SRH_S

	JMP CHOOSE
SORT:
	PRINTS SRT_S

	JMP CHOOSE




;	d2h_func(char * decimal)
D2H_FUNC PROC
	PUSH BP
	MOV BP,SP
	PUSH SI

	MOV SI,[BP+4]	; Get decmial string offset
	XOR DX,DX
	XOR AX,AX	; Set ax= 0

	MOV BX,10
D2H_LP:
	CMP BYTE PTR [SI],'$'	; Test end of string
	JE	D2H_RET
	MUL BX

	XOR CX,CX
	MOV CL,[SI]
	SUB CL,30H
	ADD AX,CX
	INC SI
	JMP D2H_LP
	
D2H_RET:

	POP SI
	MOV SP,BP
	POP BP
	RET 2
D2H_FUNC ENDP


; h2d_func(int heximal, char *decimal)
H2D_FUNC PROC
	PUSH BP
	MOV BP, SP
	PUSH DI

	MOV DI, [BP+6]
	MOV AX, [BP+4]

	MOV BX, 10
	XOR CX,CX
H2D_LP:	
	XOR DX,DX
	DIV BX
	PUSH DX ; Push remainder
	INC CX;	
	CMP AX, 0
	JE H2D_NEXT
	JMP H2D_LP
H2D_NEXT:
	POP AX 	; Pop num
	ADD AX, 30H ; To ASCII code
	MOV [DI],AX
	INC DI
	LOOP H2D_NEXT
	MOV BYTE PTR [DI],'$'	; Add end
	POP DI
	MOV SP,BP
	POP BP
	RET 4
H2D_FUNC ENDP

; strcpy_func(char *dst, char * src)
STRCPY_FUNC PROC
	PUSH BP
	MOV BP,SP
	PUSH SI
	PUSH DI

	MOV SI,[BP+6]
	MOV DI,[BP+4]

CPY_LP:
	CMP BYTE PTR[SI],'$'
	JE CPY_RET
	LODSB
	STOSB
	JMP CPY_LP

CPY_RET:
	MOV BYTE PTR [DI],'$'

	POP DI
	POP SI	
	MOV SP,BP
	POP BP
	RET 4
STRCPY_FUNC ENDP


; strcmp_func(char * str1, char * str2)
; str1 > str2 -> 1
; str1 = str2 -> 0
; str1 < str2 -> -1
STRCMP_FUNC PROC
	PUSH BP
	MOV BP, SP
	PUSH SI
	PUSH DI
	MOV SI, [BP+6]	; str2
	MOV DI, [BP+4]	; str1
CMP_LP:
	MOV AX, [SI]
	CMP AX, [DI]
	JG CMP_G
	JL CMP_L
	CMP AX, '$'
	JE CMP_E
	INC SI
	INC DI
	JMP CMP_LP
CMP_G:
	MOV AX, 1
	JMP CMP_RET
CMP_L:
	MOV AX, -1
	JMP CMP_RET
CMP_E:
	XOR AX,AX
CMP_RET:
	POP DI
	POP SI
	MOV SP, BP
	POP BP
	RET 4
STRCMP_FUNC ENDP

; mul_func(int * result,int* num1, int *num2)
;
; num2 		SI:DI
; num1 		DX:AX
;        -----------
;			
;    ---------------- 
MUL_FUNC PROC
	PUSH BP
	MOV BP, SP
	PUSH SI
	PUSH DI
	
	MOV BX,[BP+4]
	MOV DI,[BX]
	MOV SI,[BX+2]

	MOV BX,[BP+6]
	MOV BX,[BX]

	MOV AX,DI
	MUL BX
	PUSH AX
	PUSH DX
	MOV AX,SI
	MUL BX
	POP CX
	ADD CX,AX
	ADC DX,0
	PUSH DX

	MOV BX,[BP+6]
	MOV BX,[BX+2]
	MOV AX,DI
	MUL BX
	ADD CX,AX
	POP AX
	ADC AX,0
	PUSH CX
	PUSH AX
	MOV CX,DX
	MOV AX,SI
	MUL BX
	ADD CX,AX
	ADC DX,0
	POP AX
	ADD CX,AX
	ADC DX,0

	POP BX
	POP AX ;	DX:CX:BX:AX

	MOV SI,[BP+8]
	MOV [SI],AX
	MOV [SI+2],BX
	MOV [SI+4],CX
	MOV [SI+6],DX

	POP DI
	POP SI
	MOV SP,BP
	POP BP
	RET 
MUL_FUNC ENDP

SEARCH_FUNC PROC
SEARCH_FUNC ENDP

SORT_FUNC PROC
SORT_FUNC ENDP



CODE ENDS
	END START

