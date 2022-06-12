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
TEC_DEC_DISPLAY     EQU 0AH         ; tecla para decrementar o display ('A')
TEC_INC_DISPLAY     EQU 0BH         ; tecla para incrementar o display ('B')
TEC_BAIXA_MET       EQU 0FH         ; tecla para fazer descer o meteoro ('F')
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

	STACK 100H              ; espaço reservado para a pilha do processo "programa principal"
SP_inicial_prog_princ:      ; endereço com que o SP deste processo deve ser inicializado

    STACK 100H              ; espaço reservado para a pilha do processo "teclado"
SP_inicial_teclado:         ; endereço com que o SP deste processo deve ser inicializado

    STACK 100H              ; espaço reservado para a pilha do processo "escolhe_comando"
SP_inicial_escolhe_comando: ; endereço com que o SP deste processo deve ser inicializado

    STACK 100H              ; espaço reservado para a pilha do processo "testa_int0"
SP_inicial_int0:            ; endereço com que o SP deste processo deve ser inicializado

    STACK 100H              ; espaço reservado para a pilha do processo "testa_int2"
SP_inicial_int2:            ; endereço com que o SP deste processo deve ser inicializado

tecla_pressionada:
    LOCK 0                 ; LOCK para o teclado comunicar aos restantes processos que tecla detetou

modo_aplicacao:
    WORD PARADO            ; modo atual da aplicação

bloqueio:
    LOCK 0                 ; LOCK para bloquear o processo "escolhe_comando"

linha_a_testar:
    WORD LINHA_TEC         ; linha inicial a testar

registo_int:
    WORD 0

; ******************************* CORES ****************************************

CINZENTO    EQU 0A000H
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

; ******************************* Definições Gerais Meteoros *******************

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

DEF_MET_GERAL_1:
    WORD    LARGURA_MET_1, ALTURA_MET_1
    WORD    CINZENTO

DEF_MET_GERAL_2:
    WORD    LARGURA_MET_2, ALTURA_MET_2
    WORD    CINZENTO

; ******************************* Definições METEOROS BONS *********************

DEF_MET_BOM_1:
    WORD    LARGURA_MET_3, ALTURA_MET_3
    WORD    0, VERDE, 0
    WORD    VERDE, VERDE, VERDE
    WORD    0, VERDE, 0

DEF_MET_BOM_2:
    WORD    LARGURA_MET_4, ALTURA_MET_4
    WORD    0, VERDE, VERDE, 0
    WORD    VERDE, VERDE, VERDE, VERDE
    WORD    VERDE, VERDE, VERDE, VERDE
    WORD    0, VERDE, VERDE, 0

DEF_MET_BOM_3:
    WORD    LARGURA_MET_5, ALTURA_MET_5
    WORD    0, VERDE, VERDE, VERDE, 0
    WORD    VERDE, VERDE, VERDE, VERDE, VERDE
    WORD    VERDE, VERDE, VERDE, VERDE, VERDE
    WORD    VERDE, VERDE, VERDE, VERDE, VERDE
    WORD    0, VERDE, VERDE, VERDE, 0

; ******************************* Definições METEOROS MAUS *********************

DEF_MET_MAU_1:
    WORD    LARGURA_MET_3, ALTURA_MET_3
    WORD    VERMELHO, 0, VERMELHO
    WORD    0, VERMELHO, 0
    WORD    VERMELHO, 0, VERMELHO

DEF_MET_MAU_2:
    WORD    LARGURA_MET_4, ALTURA_MET_4
    WORD    VERMELHO, 0, 0, VERMELHO
    WORD    0, VERMELHO, VERMELHO, 0
    WORD    VERMELHO, 0, 0, VERMELHO
    WORD    VERMELHO, 0, 0, VERMELHO

DEF_MET_MAU_3:
    WORD    LARGURA_MET_5, ALTURA_MET_5
    WORD    VERMELHO, 0, 0, 0, VERMELHO
    WORD    VERMELHO, 0, VERMELHO, 0, VERMELHO
    WORD    0, VERMELHO, VERMELHO, VERMELHO, 0
    WORD    VERMELHO, 0, VERMELHO, 0, VERMELHO
    WORD    VERMELHO, 0, 0, 0, VERMELHO

; ******************************* Posições dos Meteoros (no máximo 4)***********

LINHA_MET_BOM   EQU 0           ; linha do meteoro bom
COLUNA_MET_BOM  EQU 16          ; coluna do meteoro bom

POS_MET_BOM:
    WORD    LINHA_MET_BOM, COLUNA_MET_BOM

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
    MOV SP, SP_inicial_prog_princ       ; inicializa o SP do programa principal
    MOV BTE, tab                        ; inicializa BTE
    MOV [APAGA_AVISO], R1	            ; apaga o aviso de nenhum cenário selecionado (o valor de R1 não é relevante)
    MOV [APAGA_ECRA], R1	            ; apaga todos os pixels já desenhados (o valor de R1 não é relevante)
	MOV	R0, 0		                    ; cenário de fundo número 0
    MOV R1, [VALOR_DISPLAY+2]           ; obter valor display decimal
    MOV [DISPLAYS], R1                  ; inicializa display a 100
    MOV [SELEC_CENARIO_FUNDO], R0	    ; seleciona o cenário de fundo
    MOV [modo_aplicacao], R0            ; dá reset ao modo da aplicação
    
    CALL teclado            ; cria o processo "teclado"
    CALL escolhe_comando    ; cria o processo "escolhe_comando"
    CALL testa_int0         ; cria o processo "testa_int0"
    CALL testa_int2         ; cria o processo "testa_int2"

espera_inicio_jogo:
    WAIT
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
    MOV R7, [POS_MET_BOM]               ; linha do meteoro bom
    MOV R8, [POS_MET_BOM+2]             ; coluna do meteoro bom
    MOV R9, DEF_MET_BOM_3               ; tabela que define o meteoro bom
    CALL desenha_boneco                 ; desenha o meteoro bom
    MOV [bloqueio], R1                  ; desbloqueia o processo "escolhe_comando"
    EI0
    ;EI1
    ;EI2
    EI

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
    CMP R1, 1
    JZ pausa_jogo
    JMP continua_jogo

pausa_jogo:
    MOV R1, PARADO
    MOV [modo_aplicacao], R1
    ;DI
    MOV R1, 2
    MOV [SELEC_CENARIO_FUNDO], R1
    JMP controla_aplicacao

continua_jogo:
    MOV R1, ATIVO
    MOV [modo_aplicacao], R1
    ;EI
    MOV [SELEC_CENARIO_FUNDO], R1
    MOV [bloqueio], R1
    JMP controla_aplicacao

termina_jogo:
    MOV R1, PARADO
    MOV [modo_aplicacao], R1
    ;DI
    MOV [SELEC_CENARIO_FUNDO], R1
    MOV R7, [POS_ROVER]
    MOV R8, [POS_ROVER+2]
    MOV R9, DEF_ROVER
    CALL apaga_boneco
    MOV R7, [POS_MET_BOM]
    MOV R8, [POS_MET_BOM+2]
    MOV R9, DEF_MET_BOM_3
    CALL apaga_boneco
    MOV R2, LINHA_ROVER
    MOV [POS_ROVER], R2
    MOV R2, COLUNA_ROVER
    MOV [POS_ROVER+2], R2
    MOV R2, LINHA_MET_BOM
    MOV [POS_MET_BOM], R2
    MOV R2, COLUNA_MET_BOM
    MOV [POS_MET_BOM+2], R2
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
; ESCOLHE_COMANDO - Escolhe o comando a realizar dependendo da tecla pressionada
; ******************************************************************************
PROCESS SP_inicial_escolhe_comando
escolhe_comando:
    WAIT
    MOV R0, [tecla_pressionada]
    MOV R1, [modo_aplicacao]
    CMP R1, PARADO
    JNZ seleciona_comando

bloqueia_escolhe_comando:
    MOV R2, [bloqueio]
    JMP escolhe_comando
    
seleciona_comando:    
    CMP R0, TEC_MOV_ESQ
    JZ  mover_esq                ; se for tecla '0'
    CMP R0, TEC_MOV_DIR
    JZ  mover_dir                ; se for tecla '2'
    MOV R11, TEC_DEC_DISPLAY     ; criação de máscara
    XOR R11, R0                  ; se a tecla for filtrada é a tecla correta
    JZ  decrementa               ; se for tecla 'A'
    MOV R11, TEC_INC_DISPLAY     ; atualização de máscara
    XOR R11, R0                  ; se a tecla for filtrada é a tecla correta
    JZ  incrementa               ; se for tecla 'B'
    MOV R11, TEC_BAIXA_MET       ; atualização de máscara
    XOR R11, R0                  ; se a tecla for filtrada é a tecla correta
    JZ  baixa_meteoro            ; se for tecla 'E'
    JMP escolhe_comando

mover_esq:
    MOV R7, [POS_ROVER]     ; linha atual do rover
    MOV R8, [POS_ROVER+2]   ; coluna atual do rover
    MOV R9, DEF_ROVER       ; tabela que define o rover
    CMP R8, MIN_COLUNA      ; o rover esta na coluna 0?
    JZ  escolhe_comando   ; se estiver no limite, não faz nada
    CALL apaga_boneco       ; caso contrário, apaga o rover
    DEC R8                  ; decrementa a coluna
    MOV [POS_ROVER+2], R8   ; atualiza a coluna em memória
    CALL desenha_boneco     ; desenha o rover na nova posição
    CALL atraso             ; delay de movimento
    JMP escolhe_comando

mover_dir:
    MOV R7, [POS_ROVER]     ; linha atual do rover
    MOV R8, [POS_ROVER+2]   ; coluna atual do rover
    MOV R9, DEF_ROVER       ; tabela que define o rover
    MOV R10, MAX_COLUNA	    ; valor maximo da coluna	
    CMP R8, R10             ; o rover esta na coluna 64?
    JZ  escolhe_comando     ; se estiver no limite, não faz nada
    CALL apaga_boneco       ; apaga o rover
    INC R8                  ; aumenta a coluna
    MOV [POS_ROVER+2], R8   ; atualiza a coluna em memória
    CALL desenha_boneco     ; desenha o rover na nova posição
    CALL atraso             ; delay de movimento
    JMP escolhe_comando

decrementa:
    MOV R7, [VALOR_DISPLAY]
    CMP R7, MIN_DISPLAY                 ; verifica se atingi valor mínimo
    JZ  escolhe_comando         ; se estiver no limite, não faz nada
    SUB R7, 5                      ; decrementa valor
    MOV [VALOR_DISPLAY], R7
    CALL converte               ; converte valor hexadecimal para decimal
    MOV R7, [VALOR_DISPLAY+2]
    MOV [DISPLAYS], R7
    JMP escolhe_comando

incrementa:
    MOV R7, [VALOR_DISPLAY]
    MOV R8, MAX_DISPLAY
    CMP R7, R8             ; verifica se atingi valor máximo
    JZ escolhe_comando         ; se estiver no limite, não faz nada
    INC R7                     ; incrementa valor
    MOV [VALOR_DISPLAY], R7
    CALL converte
    MOV R7, [VALOR_DISPLAY+2]
    MOV [DISPLAYS], R7
    JMP escolhe_comando

baixa_meteoro:
    MOV R0, 0                   ; som a reproduzir
    MOV [REPRODUZ_SOM], R0      ; reproduz som
    MOV R7, [POS_MET_BOM]       ; linha atual do meteoro bom
    MOV R8, [POS_MET_BOM+2]     ; coluna atual do meteoro bom
    MOV R9, DEF_MET_BOM_3         ; tabela que define o meteoro bom
    CALL apaga_boneco           ; apaga o meteoro bom
    INC R7                      ; incrementa a linha
    MOV R8, MAX_LINHA           ; linha máxima
    CMP R7, R8                  ; compara a linha atual do meteoro com a linha máxima
    JZ  escolhe_comando         ; se chegar à linha máxima, não o volta a desenhar
    MOV [POS_MET_BOM], R7       ; atualiza a linha em memória
    MOV R8, [POS_MET_BOM+2]     ; coluna atual do meteoro bom
    CALL desenha_boneco         ; desenha o meteoro bom na nova posição
    JMP escolhe_comando

; ******************************************************************************
;   TESTA_INT0 - Testa se a interrupção 0 ocorreu e, caso tenha ocorrido, faz
;                descer os meteoros
; ******************************************************************************
PROCESS SP_inicial_int0
testa_int0:
    MOV R0, [evento_int_bonecos]
    MOV R7, [POS_MET_BOM]
    MOV R8, [POS_MET_BOM+2]
    MOV R9, DEF_MET_BOM_3
    CALL apaga_boneco
    INC R7
    MOV [POS_MET_BOM], R7
    CALL desenha_boneco

; ******************************************************************************
;   TESTA_INT2 - Testa se a interrupção 2 ocorreu e, caso tenha ocorrido,
;                decrementa o display da energia
; ******************************************************************************
PROCESS SP_inicial_int2
testa_int2:
    MOV R0, [evento_int_bonecos+4]
    MOV R7, [VALOR_DISPLAY]
    CMP R7, MIN_DISPLAY                 ; verifica se atingi valor mínimo
    SUB R7, 5                      ; decrementa valor
    MOV [VALOR_DISPLAY], R7
    CALL converte               ; converte valor hexadecimal para decimal
    MOV R7, [VALOR_DISPLAY+2]
    MOV [DISPLAYS], R7
    
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
    MOV R3, [R9]			; obtém a cor do próximo pixel do boneco
    CALL escreve_pixel		; escreve cada pixel do boneco
    ADD R9, 2			    ; endereço da cor do próximo pixel (2 porque cada cor de pixel é uma word)
    ADD R8, 1               ; próxima coluna
    SUB R1, 1			    ; menos uma coluna para tratar
    JNZ desenha_pixels      ; continua até percorrer toda a largura do objeto
    ADD R7, 1               ; próxima linha
    MOV R1, MAX_LINHA       
    CMP R7, R1              ; caso esteja na última linha do ecrã
    JZ sai_desenha_pixels   ; então para de desenhar
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
