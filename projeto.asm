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

TEC_MOV_ESQ          EQU 0           ; tecla de movimento do rover para a esquerda ('0')
TEC_MOV_DIR          EQU 2           ; tecla de movimento do rover para a direita ('2')
TEC_DEC_DISPLAY      EQU 0CH         ; tecla para decrementar o display ('c')
TEC_INC_DISPLAY      EQU 0DH         ; tecla para incrementar o display ('d')
TEC_BAIXA_MET        EQU 0EH         ; tecla para fazer descer o meteoro ('e')

; ************************ Definição do MediaCenter ****************************

DEFINE_LINHA    		EQU 600AH      ; endereço do comando para definir a linha
DEFINE_COLUNA   		EQU 600CH      ; endereço do comando para definir a coluna
DEFINE_PIXEL    		EQU 6012H      ; endereço do comando para escrever um pixel
APAGA_AVISO     		EQU 6040H      ; endereço do comando para apagar o aviso de nenhum cenário selecionado
APAGA_ECRÃ	 		    EQU 6002H      ; endereço do comando para apagar todos os pixels já desenhados
SELEC_CENARIO_FUNDO     EQU 6042H      ; endereço do comando para selecionar uma imagem de fundo
REPRODUZ_SOM            EQU 605AH      ; endereço do comando para reproduzir um som

MIN_COLUNA		EQU 0		   ; número da coluna mais à esquerda que o objeto pode ocupar
MAX_COLUNA		EQU 64         ; número da coluna mais à direita que o objeto pode ocupar
MAX_LINHA       EQU 32         ; número da linha máxima

; ******************************************************************************

ATRASO			EQU	2500H		    ; atraso para limitar a velocidade de movimento do rover

LINHA_ROVER        	EQU 28          ; linha do rover
COLUNA_ROVER		EQU 30          ; coluna do rover

ALTURA_ROVER        EQU 4           ; altura do rover
LARGURA_ROVER	    EQU	5	        ; largura do rover
COR_PIXEL_ROVER		EQU	0FFF0H      ; cor do pixel do rover: vermelho em ARGB

LINHA_MET_BOM       EQU 0           ; linha do meteoro bom
COLUNA_MET_BOM      EQU 16          ; coluna do meteoro bom

ALTURA_METEORO_BOM  EQU 5           ; altura do meteoro bom
LARGURA_METEORO_BOM EQU 5           ; largura do meteoro bom
COR_PIXEL_MET_BOM   EQU 0F0F0H      ; cor do pixel do meteoro bom: verde

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

; ******************************** Definição ROVER *****************************

DEF_ROVER:					                                                                                ; tabela que define o rover (cor, largura, pixels)
	WORD	LARGURA_ROVER, ALTURA_ROVER
    WORD    0 , 0, COR_PIXEL_ROVER, 0 , 0                                                                   ; Definição da 1ª linha da nave 
	WORD	COR_PIXEL_ROVER, 0, COR_PIXEL_ROVER, 0, COR_PIXEL_ROVER                                         ; Definição da 2ª linha da nave
    WORD    COR_PIXEL_ROVER, COR_PIXEL_ROVER, COR_PIXEL_ROVER, COR_PIXEL_ROVER, COR_PIXEL_ROVER             ; Definição da 3ª linha da nave
    WORD    0, COR_PIXEL_ROVER, 0, COR_PIXEL_ROVER, 0                                                       ; Definição da 4ª linha da nave

POS_ROVER: 
    WORD    LINHA_ROVER, COLUNA_ROVER

; ******************************* Definição METEORO BOM ************************

DEF_METEORO_BOM:                                                                                            ; tabela que define o meteoro bom (cor, largura, pixels)
    WORD    LARGURA_METEORO_BOM, ALTURA_METEORO_BOM
    WORD    0, COR_PIXEL_MET_BOM, COR_PIXEL_MET_BOM, COR_PIXEL_MET_BOM, 0                                   ; Definição da 1ª linha do meteoro
    WORD    COR_PIXEL_MET_BOM, COR_PIXEL_MET_BOM, COR_PIXEL_MET_BOM, COR_PIXEL_MET_BOM, COR_PIXEL_MET_BOM   ; Definição da 2ª linha do meteoro 
    WORD    COR_PIXEL_MET_BOM, COR_PIXEL_MET_BOM, COR_PIXEL_MET_BOM, COR_PIXEL_MET_BOM, COR_PIXEL_MET_BOM   ; Definição da 3ª linha do meteoro 
    WORD    COR_PIXEL_MET_BOM, COR_PIXEL_MET_BOM, COR_PIXEL_MET_BOM, COR_PIXEL_MET_BOM, COR_PIXEL_MET_BOM   ; Definição da 4ª linha do meteoro 
    WORD    0, COR_PIXEL_MET_BOM, COR_PIXEL_MET_BOM, COR_PIXEL_MET_BOM, 0                                   ; Definição da 5ª linha do meteoro

POS_METEORO_BOM:
    WORD    LINHA_MET_BOM, COLUNA_MET_BOM
; ******************************************************************************
VALOR_DISPLAY:
    WORD    000H

; ******************************************************************************
; * CODIGO
; ******************************************************************************

PLACE 0H

inicio:
    MOV SP, SP_inicial                  ; inicializa o Stack Pointer
    MOV [APAGA_AVISO], R1	            ; apaga o aviso de nenhum cenário selecionado (o valor de R1 não é relevante)
    MOV [APAGA_ECRÃ], R1	            ; apaga todos os pixels já desenhados (o valor de R1 não é relevante)
	MOV	R0, 0		                    ; cenário de fundo número 0
    MOV [DISPLAYS], R0                  ; inicializa display a 0
    MOV [SELEC_CENARIO_FUNDO], R0	; seleciona o cenário de fundo
    MOV R1, LINHA                       ; linha inicial a analisar
    MOV R6, 0                           ; contador da linha e da coluna
    MOV R7, [POS_ROVER]                 ; linha do rover
    MOV R8, [POS_ROVER+2]               ; coluna do rover
    MOV R9, DEF_ROVER                   ; tabela que define o rover
    CALL desenha_boneco                 ; desenha o rover
    MOV R7, [POS_METEORO_BOM]           ; linha do meteoro bom
    MOV R8, [POS_METEORO_BOM+2]         ; coluna do meteoro bom
    MOV R9, DEF_METEORO_BOM             ; tabela que define o meteoro bom
    CALL desenha_boneco                 ; desenha o meteoro bom

espera_tecla:
    MOV R0, 0          ; reset valor de tecla
    CALL teclado       ; calcula coluna pressionada, regista no R2
    CMP R2, 0          ; se houve tecla pressionada na linha certa
    JZ linha_depois    ; não há teclado primida? verifica próxima linha
    MOV R3, R1         ; guarda valor da linha para poder ser usada depois
    JMP calcula_linha  ; se houver tecla primida, obter o valor da linha

ha_tecla:              ; neste ciclo espera-se até NENHUMA tecla estar premida
    MOV  R1, R3        ; linha lida anteriormente
    CALL teclado       ; calcula coluna
    CMP  R2, 0         ; há tecla premida?
    JNZ  ha_tecla      ; se ainda houver uma tecla premida, espera até não haver
    JMP  espera_tecla  ; volta a esperar que seja premida uma nova tecla

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
    JZ  mover_esq                ; se for tecla '0'
    CMP R0, TEC_MOV_DIR
    JZ  mover_dir                ; se for tecla '2'
    MOV R11, TEC_DEC_DISPLAY     ; criação de máscara
    XOR R11, R0                  ; se a tecla for filtrada é a tecla correta
    JZ  decrementa               ; se for tecla 'c'
    MOV R11, TEC_INC_DISPLAY     ; atualização de máscara
    XOR R11, R0                  ; se a tecla for filtrada é a tecla correta
    JZ  incrementa               ; se for tecla 'd'
    MOV R11, TEC_BAIXA_MET       ; atualização de máscara
    XOR R11, R0                  ; se a tecla for filtrada é a tecla correta
    JZ  baixa_meteoro            ; se for tecla 'e'
    JMP espera_tecla             ; caso não corresponda a nenhuma tecla

mover_esq:
    MOV R7, [POS_ROVER]     ; linha atual do rover
    MOV R8, [POS_ROVER+2]   ; coluna atual do rover
    MOV R9, DEF_ROVER       ; tabela que define o rover
    CMP R8, MIN_COLUNA      ; o rover esta na coluna 0?
    JZ espera_tecla         ; se estiver, não faz nada
    CALL apaga_boneco       ; caso contrário, apaga o rover
    DEC R8                  ; decrementa a coluna
    MOV [POS_ROVER+2], R8   ; atualiza a coluna em memória
    MOV R9, DEF_ROVER       ; tabela que define o rover
    CALL desenha_boneco     ; desenha o rover na nova posição
    CALL atraso             ; delay de movimento
    JMP espera_tecla        ; vai esperar por uma nova tecla

mover_dir:
    MOV R7, [POS_ROVER]     ; linha atual do rover
    MOV R8, [POS_ROVER+2]   ; coluna atual do rover
    MOV R9, DEF_ROVER       ; tabela que define o rover
    ADD R8, 5               ; posição do pixel mais à direita do rover
    MOV R10, MAX_COLUNA	    ; valor maximo da coluna	
    CMP R8, R10             ; o rover esta na coluna 64?
    JZ espera_tecla         ; se estiver, não faz nada
    ADD R8, -5              ; Restora para a posição do pixel mais à esquerda
    CALL apaga_boneco       ; caso contrário, apaga o rover
    INC R8                  ; aumenta a coluna
    MOV [POS_ROVER+2], R8   ; atualiza a coluna em memória
    MOV R9, DEF_ROVER       ; tabela que define o rover
    CALL desenha_boneco     ; desenha o rover na nova posição
    CALL atraso             ; delay de movimento
    JMP espera_tecla        ; vai esperar por uma nova tecla

decrementa:
    CALL obter_display          ; obter valor do display
    CMP  R7, 000H               ; verifica se atingi valor mínimo
    JZ   espera_tecla           ; se sim, não faz nada
    DEC  R7                     ; decrementa valor
    MOV  [VALOR_DISPLAY], R7    ; atualiza na memória
    MOV  [DISPLAYS], R7         ; atualiza no display      
    JMP  ha_tecla               ; espera que a tecla deixe de ser premida

incrementa:
    CALL obter_display         ; obter valor do display
    CMP  R7, 0FFF8H            ; verifica se atingi valor máximo
    JZ   espera_tecla          ; se sim, não faz nada
    INC  R7                    ; incrementa valor
    MOV  [VALOR_DISPLAY], R7   ; atualiza na memória
    MOV  [DISPLAYS], R7        ; atualiza no display
    JMP  ha_tecla              ; espera que a tecla deixe de ser premida

baixa_meteoro:
    MOV R0, 0                       ; som a reproduzir
    MOV [REPRODUZ_SOM], R0          ; reproduz som
    MOV R7, [POS_METEORO_BOM]       ; linha atual do meteoro bom
    MOV R8, [POS_METEORO_BOM+2]     ; coluna atual do meteoro bom
    MOV R9, DEF_METEORO_BOM         ; tabela que define o meteoro bom
    CALL apaga_boneco               ; apaga o meteoro bom
    INC R7                          ; incrementa a linha
    MOV R8, MAX_LINHA               ; linha máxima
    CMP R7, R8                      ; compara a linha atual do meteoro com a linha máxima
    JNN ha_tecla                    ; se a linha ainda não for a máxima, vai desenhar de novo
    MOV [POS_METEORO_BOM], R7       ; atualiza a linha em memória
    MOV R8, [POS_METEORO_BOM+2]     ; coluna atual do meteoro bom
    MOV R9, DEF_METEORO_BOM         ; tabela que define o meteoro bom
    CALL desenha_boneco             ; desenha o meteoro bom na nova posição
    JMP ha_tecla                    ; espera que a tecla deixe de ser premida

; ****************************************************************************** 
; ROTINAS
; ******************************************************************************

; ******************************************************************************
; OBTER_DISPLAY - Lê o valor do display hexadecimal
; 
; Retorna:      R7 - valor lido do display
; ******************************************************************************
obter_display:
    PUSH    R6             
    MOV R6, [VALOR_DISPLAY]   ; obtêm valor atual do display
    MOV R7, R6                ; guarda valor no registo
    POP     R6
    RET

; ******************************************************************************
; TECLADO - Faz uma leitura às teclas de uma linha do teclado e retorna o valor 
;           lido
; Argumentos:	R1 - linha a testar (em formato 1, 2, 4 ou 8)
;
; Retorna: 	R2 - valor lido das colunas do teclado (0, 1, 2, 4, ou 8)	
; ******************************************************************************
teclado:
    PUSH    R3
    PUSH    R4
    PUSH    R5
	MOV  R3, TEC_LIN   ; endereço do periférico das linhas
	MOV  R4, TEC_COL   ; endereço do periférico das colunas
	MOV  R5, MASCARA   ; para isolar os 4 bits de menor peso, ao ler as colunas do teclado
	MOVB [R3], R1      ; escrever no periférico de saída (linhas)
	MOVB R2, [R4]      ; ler do periférico de entrada (colunas)
	AND  R2, R5        ; elimina bits para além dos bits 0-3
	POP     R5
    POP     R4
    POP     R3             
    RET

; **********************************************************************
; DESENHA_BONECO - Desenha um boneco na linha e coluna indicadas
;			       com a forma e cor definidas na tabela indicada.
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
    PUSH    R5
    MOV	R1, [R9]			; obtém a largura do boneco
	MOV R4, R1              ; guarda a largura do boneco
    ADD	R9, 2			    ; endereço da altura do boneco (2 porque a largura é uma word)
    MOV R2, [R9]            ; obtém a altura do boneco
    MOV R5, R2              ; guarda a altura do boneco
    ADD R9, 2               ; endereço do 1º pixel

desenha_pixels:       		; desenha os pixels do boneco a partir da tabela
	MOV R3, [R9]			; obtém a cor do próximo pixel do boneco
	CALL escreve_pixel		; escreve cada pixel do boneco
	ADD R9, 2			    ; endereço da cor do próximo pixel (2 porque cada cor de pixel é uma word)
    ADD R8, 1               ; próxima coluna
    SUB R1, 1			    ; menos uma coluna para tratar
    JNZ desenha_pixels      ; continua até percorrer toda a largura do objeto
    ADD R7, 1               ; próxima linha
    MOV R1, R4              ; reset à largura a percorrer
    SUB R8, R4              ; volta à coluna original
    SUB R2, 1               ; menos uma linha para tratar
    JNZ desenha_pixels      ; continua até percorrer toda a altura do objeto
	MOV R2, R5              ; reset à altura a percorrer
    SUB R7, R5              ; volta à linha original
    POP     R5
    POP 	R4
	POP	    R3
	POP	    R2
	POP	    R1
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
	MOV  [DEFINE_COLUNA], R8	; seleciona a coluna
	MOV  [DEFINE_PIXEL], R3		; altera a cor do pixel na linha e coluna já selecionadas
	RET

; **********************************************************************
; APAGA_BONECO - Apaga um boneco na linha e coluna indicadas
;			     com a forma definida na tabela indicada.
; Argumentos:   R7 - linha
;               R8 - coluna
;               R9 - tabela que define o boneco
;
; **********************************************************************
apaga_boneco:
	PUSH	R1
	PUSH	R2
	PUSH	R3
	PUSH	R4
    PUSH    R5
    MOV	R1, [R9]			; obtém a largura do boneco
	MOV R4, R1              ; guarda a largura do boneco
    ADD	R9, 2			    ; endereço da altura do boneco (2 porque a largura é uma word)
    MOV R2, [R9]            ; obtém a altura do boneco
    MOV R5, R2              ; guarda a altura do boneco
    ADD R9, 2               ; endereço do 1º pixel

apaga_pixels:       		; desenha os pixels do boneco a partir da tabela
	MOV	 R3, 0			    ; obtém a cor do próximo pixel do boneco
	CALL escreve_pixel		; escreve cada pixel do boneco
    ADD  R8, 1              ; próxima coluna
    SUB  R1, 1			    ; menos uma coluna para tratar
    JNZ  apaga_pixels       ; continua até percorrer toda a largura do objeto
    ADD  R7, 1              ; próxima linha
    MOV  R1, R4             ; reset à largura a percorrer
    SUB  R8, R4             ; volta à coluna original
    SUB  R2, 1              ; menos uma linha para tratar
    JNZ  apaga_pixels       ; continua até percorrer toda a altura do objeto
	MOV  R2, R5             ; reset à altura a percorrer
    SUB  R7, R5             ; volta à linha original
    POP     R5
    POP	    R4
	POP	    R3
	POP	    R2
	POP	    R1
	RET

; **********************************************************************
; ATRASO - Executa um ciclo para implementar um atraso.
; Argumentos:   R11 - valor que define o atraso
;
; **********************************************************************
atraso:
	PUSH    R11
    MOV R11, ATRASO
ciclo_atraso:
	SUB	R11, 1
	JNZ	ciclo_atraso
	POP	    R11
	RET
