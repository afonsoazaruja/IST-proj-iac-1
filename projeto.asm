; ******************************************************************************
; * IST-UL
; *
; * Autores:
; * - Afonso Azaruja (103624): afonso.azaruja@tecnico.ulisboa.pt
; * - Tomás Macieira (100596): tmacieira.tm@gmail.com
; * - Henrique Soares (102927): henrique.c.soares@tecnico.ulisboa.pt
; *
; * Descrição: 
; * - 
; *
; ******************************************************************************

; ****************************************************************************** 
; * CONSTANTES
; ******************************************************************************

DISPLAYS   EQU 0A000H  ; endereço dos displays de 7 segmentos (periferico POUT-1)
TEC_LIN    EQU 0C000H  ; endereço das linhas do teclado (periférico POUT-2)
TEC_COL    EQU 0E000H  ; endereço das colunas do teclado (periférico PIN)
LINHA      EQU 8       ; linha a testar 8 (linha, 1000b)
MASCARA    EQU 0FH     ; necessário para isolar os bits de 4-7

TEC_MOV_ESQ    EQU 0        ; tecla de movimento do rover para a esquerda ('0')
TEC_MOV_DIR    EQU 2        ; tecla de movimento do rover para a direita ('2')
TEC_DISPARA    EQU 1        ; tecla de disparo do rover ('1')
TEC_INICIO     EQU 0CH      ; tecla de comecar o jogo ('c')
TEC_PAUSA      EQU 0DH      ; tecla de suspender/continuar o jogo ('d')
TEC_FIM        EQU 0EH      ; tecla de terminar o jogo ('e')

DEFINE_LINHA    		EQU 600AH      ; endereço do comando para definir a linha
DEFINE_COLUNA   		EQU 600CH      ; endereço do comando para definir a coluna
DEFINE_PIXEL    		EQU 6012H      ; endereço do comando para escrever um pixel
APAGA_AVISO     		EQU 6040H      ; endereço do comando para apagar o aviso de nenhum cenário selecionado
APAGA_ECRÃ	 		    EQU 6002H      ; endereço do comando para apagar todos os pixels já desenhados
SELECIONA_CENARIO_FUNDO EQU 6042H      ; endereço do comando para selecionar uma imagem de fundo

LINHA_ROVER        	EQU 28          ; linha do boneco (a meio do ecrã))
COLUNA_ROVER			EQU 32          ; coluna do boneco (a meio do ecrã)

MIN_COLUNA		EQU 0		    ; número da coluna mais à esquerda que o objeto pode ocupar
MAX_COLUNA		EQU 63          ; número da coluna mais à direita que o objeto pode ocupar
ATRASO			EQU	400H		; atraso para limitar a velocidade de movimento do boneco

ALTURA_ROVER        EQU 4
LARGURA_ROVER	    EQU	5	        ; largura do boneco
COR_PIXEL		EQU	0FFF0H      ; cor do pixel: vermelho em ARGB (opaco e vermelho no máximo, verde e azul a 0)

; ******************************************************************************
; * Dados 
; ******************************************************************************
PLACE       1000H
pilha:
	STACK 100H      ; espaço reservado para a pilha 
					; (200H bytes, pois são 100H words)
SP_inicial:			; este é o endereço (1200H) com que o SP deve ser 
					; inicializado. O 1.º end. de retorno será 
					; armazenado em 11FEH (1200H-2)
							
DEF_ROVER:					; tabela que define o rover (cor, largura, pixels)
	WORD	LARGURA_ROVER, ALTURA_ROVER
    WORD    0 , 0, COR_PIXEL, 0 , 0                                     ; Definição da 1ª linha da nave 
	WORD	COR_PIXEL, 0, COR_PIXEL, 0, COR_PIXEL                       ; Definição da 2ª linha da nave
    WORD    COR_PIXEL, COR_PIXEL, COR_PIXEL, COR_PIXEL, COR_PIXEL       ; Definição da 3ª linha da nave
    WORD    0, COR_PIXEL, 0, COR_PIXEL, 0                               ; Definição da 4ª linha da nave

POS_ATUAL_ROVER: 
    WORD    LINHA_ROVER, COLUNA_ROVER

; ******************************************************************************
; * CODIGO
; ******************************************************************************

PLACE 0H

inicio:
    MOV SP, SP_inicial    
    MOV [APAGA_AVISO], R1	            ; apaga o aviso de nenhum cenário selecionado (o valor de R1 não é relevante)
    MOV [APAGA_ECRÃ], R1	            ; apaga todos os pixels já desenhados (o valor de R1 não é relevante)
	MOV	R0, 0		                    ; cenário de fundo número 0
    MOV [SELECIONA_CENARIO_FUNDO], R0	; seleciona o cenário de fundo
    MOV R1, LINHA      ; linha inicial a analisar
    MOV R6, 0          ; contador da linha e da coluna
    MOV R7, [POS_ATUAL_ROVER]      ; linha do rover
    MOV R8, [POS_ATUAL_ROVER+2]    ; coluna do rover
    MOV R9, DEF_ROVER        ; tabela que define o rover
    CALL desenha_boneco

espera_tecla:
    MOV R0, 0          ; reset valor de tecla
    CALL teclado       ; calcula coluna pressionada, regista no R2
    CMP R2, 0          ; se houve tecla pressionada na linha certa
    JZ linha_depois    ; não há teclado primida? verifica próxima linha
    JMP calcula_linha  ; se houver tecla primida, obter o valor da linha

linha_depois:
    SHR R1, 1          ; vai para a próxima linha
    JNZ espera_tecla   ; se ainda não ultrapassou a linha 1
    MOV R1, LINHA      ; se ultrapassou a linha 1, repetir ciclo
    JMP espera_tecla   ; repetir ciclo

calcula_linha:
    SHR R1, 1          ; shift 1 bit para direita até chegar a 0
    CMP R1, 0          ; chegou ao fim?
    JZ mul_tecla       ; se sim, volta para completar a conta
    INC R0             ; incrementa o contador para calcular a linha
    JMP calcula_linha  ; se não, continua

mul_tecla:
    ADD R0, R0         ; multiplica por 2
    ADD R0, R0         ; multiplica por 2 

calcula_coluna:
    SHR R2, 1          ; shift 1 bit para direita até chegar a 0
    CMP R2, 0          ; chegou ao fim?
    JZ escolhe_comando ; se chegou ao fim
    INC R0             ; incrementa o contador para calcular a coluna 
    JMP calcula_coluna ; se não, continua 

escolhe_comando:
    CMP R0, TEC_MOV_ESQ
    JZ mover_esq            ; se for tecla '0'
    CMP R0, TEC_MOV_DIR
    JZ mover_dir            ; se for tecla '2'
    CMP R0, TEC_DISPARA     
    JZ dispara              ; se for tecla '1'
    MOV R11, TEC_INICIO     ; criação de máscara
    XOR R11, R0             ; se a tecla for filtrada é a tecla correta
    JZ iniciar_jogo         ; se for tecla 'c'
    MOV R11, TEC_PAUSA      ; atualização de máscara
    XOR R11, R0             ; se a tecla for filtrada é a tecla correta
    JZ pausar_jogo          ; se for tecla 'd'
    MOV R11, TEC_FIM        ; atualização de máscara
    XOR R11, R0             ; se a tecla for filtrada é a tecla correta
    JZ terminar_jogo        ; se for tecla 'e'
    JMP espera_tecla        ; caso não corresponda a nenhuma tecla

mover_esq:
    MOV	R10, 0
    JMP espera_tecla
mover_dir:
    MOV R10, 2
    JMP espera_tecla
dispara:
    MOV R10, 1
    JMP espera_tecla
iniciar_jogo:
    MOV R10, 0CH
    JMP espera_tecla
pausar_jogo:
    MOV R10, 0DH
    JMP espera_tecla
terminar_jogo:
    MOV R10, 0EH
    JMP espera_tecla

; ******************************************************************************
; TECLADO - Faz uma leitura às teclas de uma linha do teclado e retorna o valor 
;           lido
; Argumentos:	R1 - linha a testar (em formato 1, 2, 4 ou 8)
;
; Retorna: 	R2 - valor lido das colunas do teclado (0, 1, 2, 4, ou 8)	
; ******************************************************************************
teclado:
    PUSH R5
	MOV  R3, TEC_LIN   ; endereço do periférico das linhas
	MOV  R4, TEC_COL   ; endereço do periférico das colunas
	MOV  R5, MASCARA   ; para isolar os 4 bits de menor peso, ao ler as colunas do teclado
	MOVB [R3], R1      ; escrever no periférico de saída (linhas)
	MOVB R2, [R4]      ; ler do periférico de entrada (colunas)
	AND  R2, R5        ; elimina bits para além dos bits 0-3
	POP R5             ; 
    RET

; **********************************************************************
; DESENHA_BONECO - Desenha um boneco na linha e coluna indicadas
;			    com a forma e cor definidas na tabela indicada.
; Argumentos:   R7 - linha do boneco
;               R8 - coluna do boneco
;               R9 - tabela que define o boneco
;
; **********************************************************************
desenha_boneco:
	PUSH	R1
	PUSH	R2
	PUSH	R3
	PUSH	R4
    MOV	R1, [R9]			; obtém a largura do boneco
	MOV R10, R1             ; guarda a largura do boneco
    ADD	R9, 2			    ; endereço da altura do boneco (2 porque a largura é uma word)
    MOV R2, [R9]            ; obtém a altura do boneco
    MOV R11, R2             ; guarda a altura do boneco
    ADD R9, 2               ; endereço do 1º pixel

desenha_pixels:       		; desenha os pixels do boneco a partir da tabela
	MOV	 R3, [R9]			; obtém a cor do próximo pixel do boneco
	CALL escreve_pixel		; escreve cada pixel do boneco
	ADD	 R9, 2			; endereço da cor do próximo pixel (2 porque cada cor de pixel é uma word)
    ADD  R8, 1               ; próxima coluna
    SUB  R1, 1			; menos uma coluna para tratar
    JNZ  desenha_pixels      ; continua até percorrer toda a largura do objeto
    ADD  R7, 1          ; próxima linha
    MOV  R1, R10        ; reset à largura a percorrer
    SUB  R8, R10        ; volta à coluna original
    SUB  R2, 1          ; menos uma linha para tratar
    JNZ  desenha_pixels      ; continua até percorrer toda a altura do objeto
	MOV  R2, R11        ; reset à altura a percorrer
    SUB  R7, R11        ; volta à linha original
    POP	R4
	POP	R3
	POP	R2
	POP	R1
	RET

; **********************************************************************
; ESCREVE_PIXEL - Escreve um pixel na linha e coluna indicadas.
; Argumentos:   R7 - linha
;               R8 - coluna
;               R3 - cor do pixel (em formato ARGB de 16 bits)
;
; **********************************************************************
escreve_pixel:
	MOV  [DEFINE_LINHA], R7		; seleciona a linha
	MOV  [DEFINE_COLUNA], R8		; seleciona a coluna
	MOV  [DEFINE_PIXEL], R3		; altera a cor do pixel na linha e coluna já selecionadas
	RET
