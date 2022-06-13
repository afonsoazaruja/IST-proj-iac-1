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
LINHA_TEC  EQU 8       ; linha a testar 8 (linha, 1000b)
MASCARA    EQU 0FH     ; necessário para isolar os bits de 4-7

TEC_MOV_ESQ         EQU 0           ; tecla de movimento do rover para a esquerda ('0')
TEC_MOV_DIR         EQU 2           ; tecla de movimento do rover para a direita ('2')
TEC_COMECAR         EQU 0CH         ; tecla para começar o jogo ('C')
TEC_PAUSAR          EQU 0DH         ; tecla para suspender/continuar o jogo ('D')
TEC_TERMINAR        EQU 0EH         ; tecla para terminar o jogo

ATIVO       EQU 1       ; modo ativo da aplicação
PARADO      EQU 0       ; modo parado da aplicação

ATRASO  EQU	2500H       ; atraso para limitar a velocidade de movimento do rover

FATOR   EQU 3E8H
DIVISOR EQU 0AH

MIN_DISPLAY EQU 0H
MAX_DISPLAY EQU 64H

; ************************ Definição do MediaCenter ****************************

DEFINE_LINHA        EQU 600AH      ; endereço do comando para definir a linha
DEFINE_COLUNA       EQU 600CH      ; endereço do comando para definir a coluna
DEFINE_PIXEL        EQU 6012H      ; endereço do comando para escrever um pixel
APAGA_AVISO         EQU 6040H      ; endereço do comando para apagar o aviso de nenhum cenário selecionado
APAGA_ECRA          EQU 6002H      ; endereço do comando para apagar todos os pixels já desenhados
SELEC_CENARIO_FUNDO EQU 6042H      ; endereço do comando para selecionar uma imagem de fundo
REPRODUZ_SOM        EQU 605AH      ; endereço do comando para reproduzir um som

MIN_COLUNA		EQU 0		   ; número da coluna mais à esquerda que o objeto pode ocupar
MAX_COLUNA		EQU 59         ; número da coluna mais à direita que o objeto pode ocupar
MAX_LINHA       EQU 32         ; número da linha máxima

; ******************************************************************************
; * Dados 
; ******************************************************************************
PLACE 1000H

	STACK 100H              ; espaço reservado para a pilha do processo "controlo"
SP_inicial_controlo:        ; endereço com que o SP deste processo deve ser inicializado

    STACK 100H              ; espaço reservado para a pilha do processo "teclado"
SP_inicial_teclado:         ; endereço com que o SP deste processo deve ser inicializado

    STACK 100H              ; espaço reservado para a pilha do processo "rover"
SP_inicial_rover:           ; endereço com que o SP deste processo deve ser inicializado

    STACK 100H              ; espaço reservado para a pilha do processo "meteoros"
SP_inicial_meteoros:        ; endereço com que o SP deste processo deve ser inicializado

    STACK 100H              ; espaço reservado para a pilha do processo "energia"
SP_inicial_energia:         ; endereço com que o SP deste processo deve ser inicializado

tecla_pressionada:
    LOCK 0                 ; LOCK para o teclado comunicar aos restantes processos que tecla detetou

modo_aplicacao:
    WORD PARADO            ; modo atual da aplicação

bloqueio:
    LOCK 0                 ; LOCK para bloquear o processo "rover"

linha_a_testar:
    WORD LINHA_TEC         ; linha inicial a testar

; ******************************* CORES ****************************************

CINZENTO    EQU 0ADCDH
VERDE       EQU 0F0F0H
AMARELO     EQU	0FFF0H
VERMELHO    EQU 0FF00H
AZUL        EQU 0F0AFH
ROXO        EQU 0FA0FH

; ******************************** Definição ROVER *****************************

ALTURA_ROVER    EQU 4           ; altura do rover
LARGURA_ROVER   EQU	5	        ; largura do rover

DEF_ROVER:  ; tabela que define o rover (cor, largura, pixels)
	WORD	LARGURA_ROVER, ALTURA_ROVER                             
    WORD    0 , 0, AMARELO, 0 , 0                                 ; Definição da 1ª linha da nave 
	WORD	AMARELO, 0, AMARELO, 0, AMARELO                   ; Definição da 2ª linha da nave
    WORD    AMARELO, AMARELO, AMARELO, AMARELO, AMARELO   ; Definição da 3ª linha da nave
    WORD    0, AMARELO, 0, AMARELO, 0                           ; Definição da 4ª linha da nave

LINHA_ROVER     EQU 28          ; linha do rover
COLUNA_ROVER    EQU 30          ; coluna do rover

POS_ROVER: 
    WORD    LINHA_ROVER, COLUNA_ROVER

; ******************************* Constantes METEOROS **************************

MET_BOM         EQU 0
MET_MAU         EQU 130

LINHA_DEF_1     EQU 0
LINHA_DEF_2     EQU 2
LINHA_DEF_3     EQU 5
LINHA_DEF_4     EQU 9
LINHA_DEF_5     EQU 14

ALTURA_MET_1    EQU 1
LARGURA_MET_1   EQU 1

ALTURA_MET_2    EQU 2
LARGURA_MET_2   EQU 2

ALTURA_MET_3    EQU 3
LARGURA_MET_3   EQU 3

ALTURA_MET_4    EQU 4
LARGURA_MET_4   EQU 4

ALTURA_MET_5    EQU 5
LARGURA_MET_5   EQU 5

; ******************************* Definições METEOROS **************************

DEF_MET:
    WORD    LARGURA_MET_5, ALTURA_MET_5
    WORD    0, VERDE, VERDE, VERDE, 0
    WORD    VERDE, VERDE, VERDE, VERDE, VERDE
    WORD    VERDE, VERDE, VERDE, VERDE, VERDE
    WORD    VERDE, VERDE, VERDE, VERDE, VERDE
    WORD    0, VERDE, VERDE, VERDE, 0

    WORD    LARGURA_MET_4, ALTURA_MET_4
    WORD    0, VERDE, VERDE, 0
    WORD    VERDE, VERDE, VERDE, VERDE
    WORD    VERDE, VERDE, VERDE, VERDE
    WORD    0, VERDE, VERDE, 0

    WORD    LARGURA_MET_3, ALTURA_MET_3
    WORD    0, VERDE, 0
    WORD    VERDE, VERDE, VERDE
    WORD    0, VERDE, 0

    WORD    LARGURA_MET_2, ALTURA_MET_2
    WORD    CINZENTO, CINZENTO
    WORD    CINZENTO, CINZENTO

    WORD    LARGURA_MET_1, ALTURA_MET_1
    WORD    CINZENTO

    WORD    LARGURA_MET_5, ALTURA_MET_5
    WORD    VERMELHO, 0, 0, 0, VERMELHO
    WORD    VERMELHO, 0, VERMELHO, 0, VERMELHO
    WORD    0, VERMELHO, VERMELHO, VERMELHO, 0
    WORD    VERMELHO, 0, VERMELHO, 0, VERMELHO
    WORD    VERMELHO, 0, 0, 0, VERMELHO

    WORD    LARGURA_MET_4, ALTURA_MET_4
    WORD    VERMELHO, 0, 0, VERMELHO
    WORD    0, VERMELHO, VERMELHO, 0
    WORD    VERMELHO, 0, 0, VERMELHO
    WORD    VERMELHO, 0, 0, VERMELHO

    WORD    LARGURA_MET_3, ALTURA_MET_3
    WORD    VERMELHO, 0, VERMELHO
    WORD    0, VERMELHO, 0
    WORD    VERMELHO, 0, VERMELHO

    WORD    LARGURA_MET_2, ALTURA_MET_2
    WORD    CINZENTO, CINZENTO
    WORD    CINZENTO, CINZENTO

    WORD    LARGURA_MET_1, ALTURA_MET_1
    WORD    CINZENTO

DEF_MET_DESTRUIDO:
    WORD   LARGURA_MET_5, ALTURA_MET_5 
    WORD    0, AZUL, 0, AZUL, 0
    WORD    AZUL, 0, AZUL, 0, AZUL
    WORD    0, AZUL, 0, AZUL, 0
    WORD    AZUL, 0, AZUL, 0, AZUL
    WORD    0, AZUL, 0, AZUL, 0

; ******************************* Posições dos METEOROS (no máximo 4)***********

LINHA_MET   EQU -1          ; linha do meteoro
COLUNA_MET  EQU 16          ; coluna do meteoro

POS_MET:
    WORD    LINHA_MET, COLUNA_MET, MET_BOM

; ******************************************************************************

VALOR_DISPLAY:
    WORD    64H
    WORD    100H

; ******************************************************************************

tab:
	WORD rot_int_0			; rotina de atendimento da interrupção 0
	WORD rot_int_1			; rotina de atendimento da interrupção 1
	WORD rot_int_2			; rotina de atendimento da interrupção 2

evento_int_bonecos:			; LOCKs para cada rotina de interrupção comunicar ao processo
						; boneco respetivo que a interrupção ocorreu
	LOCK 0				; LOCK para a rotina de interrupção 0
	LOCK 0				; LOCK para a rotina de interrupção 1
	LOCK 0				; LOCK para a rotina de interrupção 2

; ******************************************************************************
; * CODIGO
; ******************************************************************************

PLACE   0H

inicio:
    MOV SP, SP_inicial_controlo         ; inicializa o SP do programa principal
    MOV BTE, tab                        ; inicializa BTE
    MOV [APAGA_AVISO], R1	            ; apaga o aviso de nenhum cenário selecionado (o valor de R1 não é relevante)
    MOV [APAGA_ECRA], R1	            ; apaga todos os pixels já desenhados (o valor de R1 não é relevante)
    MOV	R0, 0		                    ; cenário de fundo número 0
    MOV [SELEC_CENARIO_FUNDO], R0	    ; seleciona o cenário de fundo
    MOV [modo_aplicacao], R0            ; dá reset ao modo da aplicação
    EI0
    ;EI1
    EI2
    EI
    
    CALL teclado            ; cria o processo "teclado"
    CALL rover              ; cria o processo "rover"
    CALL meteoros           ; cria o processo "meteoros"
    CALL energia            ; cria o processo "energia"

espera_inicio_jogo:
    MOV R1, MAX_DISPLAY
    MOV [VALOR_DISPLAY], R1           ; obter valor display decimal
    CALL converte                  ; inicializa display a 100
    MOV R1, [VALOR_DISPLAY+2]
    MOV [DISPLAYS], R1
    MOV R0, [tecla_pressionada]
    MOV R11, TEC_COMECAR
    XOR R11, R0
    JNZ espera_inicio_jogo

comeca_jogo:
    MOV R1, ATIVO
    MOV [modo_aplicacao], R1            ; troca o modo da aplicação para ATIVO
    MOV [APAGA_ECRA], R1                ; apaga o ecrã
    MOV R0, 1                           ; cenário de fundo número 1
    MOV [SELEC_CENARIO_FUNDO], R0       ; troca o cenário de fundo
    MOV R7, [POS_ROVER]                 ; linha do rover
    MOV R8, [POS_ROVER+2]               ; coluna do rover
    MOV R9, DEF_ROVER                   ; tabela que define o rover
    CALL desenha_boneco                 ; desenha o rover
    MOV [bloqueio], R1                  ; desbloqueia o processo "rover"

controla_aplicacao:
    WAIT
    MOV R0, [tecla_pressionada]
    MOV R11, TEC_PAUSAR
    XOR R11, R0
    JZ  pausa_continua_jogo         ; se a tecla pressionada for 'D'
    MOV R11, TEC_TERMINAR
    XOR R11, R0
    JZ  termina_jogo                ; se a tecla pressionada for 'E'
    JMP controla_aplicacao

pausa_continua_jogo:
    MOV R1, [modo_aplicacao]
    CMP R1, ATIVO
    JZ pausa_jogo
    JMP continua_jogo

pausa_jogo:
    DI
    MOV R1, PARADO
    MOV [modo_aplicacao], R1
    MOV R1, 2
    MOV [SELEC_CENARIO_FUNDO], R1
    JMP controla_aplicacao

continua_jogo:
    EI
    MOV R1, ATIVO
    MOV [modo_aplicacao], R1
    MOV [SELEC_CENARIO_FUNDO], R1
    MOV [bloqueio], R1
    JMP controla_aplicacao

termina_jogo:
    DI
    MOV R1, PARADO
    MOV [modo_aplicacao], R1
    MOV [SELEC_CENARIO_FUNDO], R1
    MOV [APAGA_ECRA], R1	            ; apaga todos os pixels já desenhados (o valor de R1 não é relevante)
    MOV R2, LINHA_ROVER
    MOV [POS_ROVER], R2
    MOV R2, COLUNA_ROVER
    MOV [POS_ROVER+2], R2
    MOV R2, LINHA_MET
    MOV [POS_MET], R2
    MOV R2, COLUNA_MET
    MOV [POS_MET+2], R2
    JMP espera_inicio_jogo

; ******************************************************************************
; PROCESSOS
; ******************************************************************************

; ******************************************************************************
; TECLADO - Faz uma leitura às teclas de uma linha do teclado e retorna o valor 
;           lido
; ******************************************************************************
PROCESS SP_inicial_teclado
teclado:
    MOV R3, TEC_LIN             ; endereço do periférico das linhas
    MOV R4, TEC_COL             ; endereço do periférico das colunas
    MOV R5, MASCARA             ; isola os 4 bits de menor peso, ao ler as colunas do teclado

espera_tecla:
    WAIT
    MOV R0, 0                   ; dá reset ao valor da tecla pressionada
    MOV R1, [linha_a_testar]    ; lê a linha a testar
    MOVB [R3], R1               ; escrever no periférico de saída (linhas)
    MOVB R2, [R4]               ; ler do periférico de entrada (colunas)
    AND R2, R5                  ; elimina bits para além dos bits 0-3
    CMP R2, 0                   ; se ler coluna nenhuma do teclado
    JZ linha_depois             ; vai ler a próxima linha
    CALL calcula_tecla          ; vai calcular a tecla lida
    MOV [tecla_pressionada], R0 ; guarda a tecla premida em memória

ha_tecla:               ; neste ciclo espera-se até nenhuma tecla estar premida
    YIELD
    CMP R0, 0
    JZ espera_tecla
    CMP R0, 2
    JZ espera_tecla
    MOVB [R3], R1               ; escrever no periférico de saída (linhas)
    MOVB R2, [R4]               ; ler do periférico de entrada (colunas)
    AND R2, R5                  ; elimina bits para além dos bits 0-3
    CMP R2, 0                   ; se ler coluna nenhuma do teclado
    JNZ ha_tecla        ; se ainda houver uma tecla premida, espera até não haver
    JMP espera_tecla    ; volta a esperar que seja premida uma nova tecla

linha_depois:
    SHR R1, 1
    JZ  reset_linha             ; se for zero, vai dar reset à linha
    MOV [linha_a_testar], R1    ; vai para a próxima linha
    JMP espera_tecla            ; se ainda não ultrapassou a linha 1

reset_linha:
    MOV R1, LINHA_TEC
    MOV [linha_a_testar], R1    ; dá reset à linha
    JMP espera_tecla

; ******************************************************************************
; ROVER - Escolhe o comando a realizar dependendo da tecla pressionada
; ******************************************************************************
PROCESS SP_inicial_rover
rover:
    WAIT
    MOV R1, [modo_aplicacao]
    CMP R1, PARADO
    JNZ movimento

bloqueia_rover:
    MOV R2, [bloqueio]
    JMP rover
    
movimento:
    MOV R0, [tecla_pressionada]
    CMP R0, TEC_MOV_ESQ
    JZ  mover_esq                ; se for tecla '0'
    CMP R0, TEC_MOV_DIR
    JZ  mover_dir                ; se for tecla '2'
    JMP rover

mover_esq:
    MOV R7, [POS_ROVER]     ; linha atual do rover
    MOV R8, [POS_ROVER+2]   ; coluna atual do rover
    MOV R9, DEF_ROVER       ; tabela que define o rover
    CMP R8, MIN_COLUNA      ; o rover esta na coluna 0?
    JZ  rover               ; se estiver no limite, não faz nada
    CALL apaga_boneco       ; caso contrário, apaga o rover
    DEC R8                  ; decrementa a coluna
    MOV [POS_ROVER+2], R8   ; atualiza a coluna em memória
    CALL desenha_boneco     ; desenha o rover na nova posição
    CALL atraso             ; delay de movimento
    JMP rover

mover_dir:
    MOV R7, [POS_ROVER]     ; linha atual do rover
    MOV R8, [POS_ROVER+2]   ; coluna atual do rover
    MOV R9, DEF_ROVER       ; tabela que define o rover
    MOV R10, MAX_COLUNA	    ; valor maximo da coluna	
    CMP R8, R10             ; o rover esta na coluna 64?
    JZ  rover               ; se estiver no limite, não faz nada
    CALL apaga_boneco       ; apaga o rover
    INC R8                  ; aumenta a coluna
    MOV [POS_ROVER+2], R8   ; atualiza a coluna em memória
    CALL desenha_boneco     ; desenha o rover na nova posição
    CALL atraso             ; delay de movimento
    JMP rover

; ******************************************************************************
;   METEOROS - Testa se a interrupção 0 ocorreu e, caso tenha ocorrido, faz
;              descer os meteoros
; ******************************************************************************
PROCESS SP_inicial_meteoros
meteoros:
    WAIT
    MOV R0, [evento_int_bonecos]
    MOV R1, [modo_aplicacao]
    CMP R1, PARADO
    JZ sai_meteoros
    MOV R7, [POS_MET]           ; linha atual
    MOV R8, [POS_MET+2]         ; coluna atual
    MOV R6, [POS_MET+4]         ; tipo de meteoro
    CALL escolhe_def                ; determina qual def do boneco a usar
    CALL apaga_boneco
    INC R7                          ; aumenta linha
    MOV R10, MAX_LINHA              
    CMP R7, R10                     ; verifica se chegou ao fim
    JZ  sai_meteoros                ; se sim, não desenha mais
    MOV [POS_MET], R7           ; atualiza linha
    CALL escolhe_def
    CALL desenha_boneco
sai_meteoros:    
    JMP meteoros

; ******************************************************************************
;   ENERGIA - Testa se a interrupção 2 ocorreu e, caso tenha ocorrido,
;             decrementa o display da energia
; ******************************************************************************
PROCESS SP_inicial_energia
energia:
    WAIT
    MOV R0, [evento_int_bonecos+4]
    MOV R1, [modo_aplicacao]
    CMP R1, PARADO
    JZ sai_energia
    MOV R7, [VALOR_DISPLAY]
    CMP R7, MIN_DISPLAY                 ; verifica se atingi valor mínimo
    SUB R7, 5                      ; decrementa valor
    MOV [VALOR_DISPLAY], R7
    CALL converte               ; converte valor hexadecimal para decimal
    MOV R7, [VALOR_DISPLAY+2]
    MOV [DISPLAYS], R7
sai_energia:
    JMP energia

; ****************************************************************************** 
; ROTINAS
; ******************************************************************************

; ******************************************************************************
; CALCULA_TECLA - Calcula o valor da tecla premida
; Argumentos:   R1 - linha da tecla premida (1, 2, 4 ou 8)
;               R2 - coluna da tecla premida (1, 2, 4 ou 8)
;
; Retorna:  R0 - valor da tecla premida
;*******************************************************************************
calcula_tecla:
    PUSH R1
    PUSH R2

calcula_linha:
    SHR R1, 1           ; shift 1 bit para direita até chegar a 0
    CMP R1, 0           ; chegou ao fim?
    JZ mul_tecla        ; se sim, vai terminar o cálculo do valor da tecla
    INC R0              ; se não, incrementa o valor da linha
    JMP calcula_linha   ; e continua a calcular o valor da linha

mul_tecla:
    ADD R0, R0  ; multiplica por 2
    ADD R0, R0  ; multiplica por 2

calcula_coluna:
    SHR R2, 1               ; shift 1 bit para direita até chegar a 0
    CMP R2, 0               ; chegou ao fim?
    JZ sai_calcula_tecla    ; se sim, R0 tem o valor da tecla premida
    INC R0                  ; se não, incrementa o valor da coluna 
    JMP calcula_coluna      ; e continua a calcular o valor da coluna 

sai_calcula_tecla:
    POP R2
    POP R1
    RET

; ******************************************************************************
; DESENHA_BONECO - Desenha um boneco na linha e coluna indicadas
;			       com a forma e cor definidas na tabela indicada.
; Argumentos:   R7 - linha do boneco
;               R8 - coluna do boneco
;               R9 - tabela que define o boneco
; ******************************************************************************
desenha_boneco:
    PUSH R1
    PUSH R2
    PUSH R3
    PUSH R4
    PUSH R7
    PUSH R8
    PUSH R9
    MOV	R1, [R9]    ; obtém a largura do boneco
    MOV R4, R1      ; guarda a largura do boneco
    ADD	R9, 2       ; endereço da altura do boneco (2 porque a largura é uma word)
    MOV R2, [R9]    ; obtém a altura do boneco
    ADD R9, 2       ; endereço do 1º pixel
desenha_pixels:       		; desenha os pixels do boneco a partir da tabela
    MOV R3, MAX_LINHA       
    CMP R7, R3              ; caso esteja na última linha do ecrã
    JZ sai_desenha_pixels   ; então para de desenhar
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
sai_desenha_pixels:
    POP R9
    POP R8
    POP R7
    POP R4
    POP R3
    POP R2
    POP R1
    RET

; ******************************************************************************
; ESCREVE_PIXEL - Escreve um pixel na linha e coluna indicadas.
; Argumentos:   R7 - linha
;               R8 - coluna
;               R3 - cor do pixel (em formato ARGB de 16 bits)
; ******************************************************************************
escreve_pixel:
    MOV [DEFINE_LINHA], R7		; seleciona a linha
    MOV [DEFINE_COLUNA], R8	; seleciona a coluna
    MOV [DEFINE_PIXEL], R3		; altera a cor do pixel na linha e coluna já selecionadas
    RET

; ******************************************************************************
; APAGA_BONECO - Apaga um boneco na linha e coluna indicadas
;			     com a forma definida na tabela indicada.
; Argumentos:   R7 - linha
;               R8 - coluna
;               R9 - tabela que define o boneco
; ******************************************************************************
apaga_boneco:
    PUSH R1
    PUSH R2
    PUSH R3
    PUSH R4
    PUSH R7
    PUSH R8
    PUSH R9
    MOV	R1, [R9]    ; obtém a largura do boneco
    MOV R4, R1      ; guarda a largura do boneco
    ADD	R9, 2       ; endereço da altura do boneco (2 porque a largura é uma word)
    MOV R2, [R9]    ; obtém a altura do boneco
    ADD R9, 2       ; endereço do 1º pixel

apaga_pixels:           ; desenha os pixels do boneco a partir da tabela
    MOV R3, MAX_LINHA
    CMP R7, R3          ; caso esteja na última linha do ecrã
    JZ sai_apaga_pixels ; então para de apagar
    MOV R3, 0           ; obtém a cor do próximo pixel do boneco
    CALL escreve_pixel  ; escreve cada pixel do boneco
    ADD R8, 1           ; próxima coluna
    SUB R1, 1           ; menos uma coluna para tratar
    JNZ apaga_pixels    ; continua até percorrer toda a largura do objeto
    ADD R7, 1           ; próxima linha
    MOV R1, R4          ; reset à largura a percorrer
    SUB R8, R4          ; volta à coluna original
    SUB R2, 1           ; menos uma linha para tratar
    JNZ apaga_pixels    ; continua até percorrer toda a altura do objeto
sai_apaga_pixels:
    POP R9
    POP R8
    POP R7
    POP R4
    POP R3
    POP R2
    POP R1
    RET

; ******************************************************************************
; ATRASO - Executa um ciclo para implementar um atraso.
; ******************************************************************************
atraso:
    PUSH R0
    MOV R0, ATRASO
ciclo_atraso:
    SUB	R0, 1
    JNZ	ciclo_atraso
    POP R0
    RET

; ******************************************************************************
; CONVERSOR - Converte um valor hexadecimal para decimal
; ******************************************************************************
converte:
    PUSH R0
    PUSH R1
    PUSH R2
    PUSH R3
    PUSH R4
    PUSH R5
    MOV R0, [VALOR_DISPLAY]     ; obter valor display em memória
    MOV R1, FATOR               ; fator 1000 decimal
    MOV R2, DIVISOR             ; divisor 10 decimal
converte_ciclo:
    MOD R0, R1                  ; resto da divisão do valor por o fator atual
    DIV R1, R2                  ; dividir fator por 10
    MOV R4, R0                  ; guarda digito
    DIV R4, R1                  ; obter dígito do número decimal
    SHL R5, 4                   ; shift left para dar espaço aos outros dígitos
    OR R5, R4                   ; vai compondo o resultado
    CMP R1, R2                  ; fator é maior ou igual a 10?
    JGE converte_ciclo          ; se sim, ainda não chegou ao resultado
    MOV [VALOR_DISPLAY+2], R5   ; atualiza valor do display na memória
    POP R5
    POP R4
    POP R3
    POP R2
    POP R1
    POP R0
    RET

; ******************************************************************************
; ESCOLHE_DEF - Escolhe definição do boneco conforme a linha em que se encontra
; Argumentos:  R7 - linha atual do boneco
;              R6 - tipo de meteoro
; Retorna:     R9 - definição adequada do boneco a usar
; ******************************************************************************
escolhe_def:
    PUSH R0
    MOV R9, DEF_MET
    ADD R9, R6
    MOV R0, LINHA_DEF_5
    CMP R0, R7
    JLE escolhe_def_saida
    MOV R0, 54
    ADD R9, R0
    MOV R0, LINHA_DEF_4
    CMP R0, R7
    JLE escolhe_def_saida
    MOV R0, 36
    ADD R9, R0
    MOV R0, LINHA_DEF_3
    CMP R0, R7
    JLE escolhe_def_saida
    MOV R0, 22
    ADD R9, R0
    MOV R0, LINHA_DEF_2
    CMP R0, R7
    JLE escolhe_def_saida
    MOV R0, 12
    ADD R9, R0
    MOV R0, LINHA_DEF_1
    CMP R0, R7
escolhe_def_saida:
    POP R0
    RET

; **********************************************************************
; ROT_INT_0 - Rotina de atendimento da interrupção 0
; **********************************************************************
rot_int_0:
	PUSH	R1
    MOV R1, evento_int_bonecos
	MOV	[R1+0], R0	; desbloqueia processo boneco (qualquer registo serve) 
	POP	R1
	RFE

; **********************************************************************
; ROT_INT_1 - Rotina de atendimento da interrupção 1
; **********************************************************************
rot_int_1:
	PUSH	R1
	MOV R1, evento_int_bonecos
	MOV	[R1+2], R0	; desbloqueia processo boneco (qualquer registo serve) 
	POP	R1
	RFE

; **********************************************************************
; ROT_INT_2 - Rotina de atendimento da interrupção 2
; **********************************************************************
rot_int_2:
	PUSH	R1
	MOV R1, evento_int_bonecos
    MOV	[R1+4], R0	; desbloqueia processo boneco (qualquer registo serve) 
	POP	R1
	RFE
