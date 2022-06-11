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
TEC_DEC_DISPLAY     EQU 0AH         ; tecla para decrementar o display ('a')
TEC_INC_DISPLAY     EQU 0BH         ; tecla para incrementar o display ('b')
TEC_BAIXA_MET       EQU 0EH         ; tecla para fazer descer o meteoro ('e')
TEC_COMECAR         EQU 0CH         ; tecla para começar o jogo

ATIVO       EQU 1       ; modo ativo da aplicação
PARADO      EQU 0       ; modo parado da aplicação

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

ATRASO  EQU	2500H       ; atraso para limitar a velocidade de movimento do rover

LINHA_ROVER     EQU 28          ; linha do rover
COLUNA_ROVER    EQU 30          ; coluna do rover

ALTURA_ROVER    EQU 4           ; altura do rover
LARGURA_ROVER   EQU	5	        ; largura do rover
COR_ROVER       EQU	0FFF0H      ; cor do pixel do rover: vermelho em ARGB

LINHA_MET_BOM   EQU 0           ; linha do meteoro bom
COLUNA_MET_BOM  EQU 16          ; coluna do meteoro bom

ALTURA_MET_BOM  EQU 5           ; altura do meteoro bom
LARGURA_MET_BOM EQU 5           ; largura do meteoro bom
COR_MET_BOM     EQU 0F0F0H      ; cor do pixel do meteoro bom: verde

; ******************************************************************************
; * Dados 
; ******************************************************************************
PLACE 1000H

	STACK 100H              ; espaço reservado para a pilha do processo "programa principal"
SP_inicial_prog_princ:      ; endereço com que o SP deste processo deve ser inicializado

    STACK 100H              ; espaço reservado para a pilha do processo "teclado"
SP_inicial_teclado:         ; endereço com que o SP deste processo deve ser inicializado

    STACK 1000H             ; espaço reservado para a pilha do processo "escolhe_comando"
SP_inicial_escolhe_comando: ; endereço com que o SP deste processo de ve ser inicializado

tecla_pressionada:
    LOCK 0                 ; LOCK para o teclado comunicar aos restantes processos que tecla detetou

modo_aplicacao:
    WORD PARADO            ; modo atual da aplicação

bloqueio:
    LOCK 0                 ; LOCK para bloquear o processo "escolhe_comando"

linha_a_testar:
    WORD LINHA_TEC         ; linha inicial a testar

; ******************************** Definição ROVER *****************************

DEF_ROVER:  ; tabela que define o rover (cor, largura, pixels)
	WORD	LARGURA_ROVER, ALTURA_ROVER                             
    WORD    0 , 0, COR_ROVER, 0 , 0                                 ; Definição da 1ª linha da nave 
	WORD	COR_ROVER, 0, COR_ROVER, 0, COR_ROVER                   ; Definição da 2ª linha da nave
    WORD    COR_ROVER, COR_ROVER, COR_ROVER, COR_ROVER, COR_ROVER   ; Definição da 3ª linha da nave
    WORD    0, COR_ROVER, 0, COR_ROVER, 0                           ; Definição da 4ª linha da nave

POS_ROVER: 
    WORD    LINHA_ROVER, COLUNA_ROVER

; ******************************* Definição METEORO BOM ************************

DEF_MET_BOM:    ; tabela que define o meteoro bom (cor, largura, pixels)
    WORD    LARGURA_MET_BOM, ALTURA_MET_BOM
    WORD    0, COR_MET_BOM, COR_MET_BOM, COR_MET_BOM, 0                     ; Definição da 1ª linha do meteoro
    WORD    COR_MET_BOM, COR_MET_BOM, COR_MET_BOM, COR_MET_BOM, COR_MET_BOM ; Definição da 2ª linha do meteoro 
    WORD    COR_MET_BOM, COR_MET_BOM, COR_MET_BOM, COR_MET_BOM, COR_MET_BOM ; Definição da 3ª linha do meteoro 
    WORD    COR_MET_BOM, COR_MET_BOM, COR_MET_BOM, COR_MET_BOM, COR_MET_BOM ; Definição da 4ª linha do meteoro 
    WORD    0, COR_MET_BOM, COR_MET_BOM, COR_MET_BOM, 0                     ; Definição da 5ª linha do meteoro

POS_MET_BOM:
    WORD    LINHA_MET_BOM, COLUNA_MET_BOM
; ******************************************************************************
VALOR_DISPLAY:
    WORD    000H

; ******************************************************************************
; * CODIGO
; ******************************************************************************

PLACE   0H

inicio:
    MOV SP, SP_inicial_prog_princ                  ; inicializa o SP do programa principal
    MOV [APAGA_AVISO], R1	            ; apaga o aviso de nenhum cenário selecionado (o valor de R1 não é relevante)
    MOV [APAGA_ECRA], R1	            ; apaga todos os pixels já desenhados (o valor de R1 não é relevante)
	MOV	R0, 0		                    ; cenário de fundo número 0
    MOV [DISPLAYS], R0                  ; inicializa display a 0
    MOV [VALOR_DISPLAY], R0             ; inicializa o valor na memória a 0
    MOV [SELEC_CENARIO_FUNDO], R0	    ; seleciona o cenário de fundo
    MOV [modo_aplicacao], R0            ; dá reset ao modo da aplicação
    
    CALL teclado            ; cria o processo "teclado"
    CALL escolhe_comando    ; cria o processo "escolhe_comando"

controla_aplicacao:
    WAIT
    MOV R0, [tecla_pressionada]
    MOV R11, TEC_COMECAR
    XOR R11, R0
    JZ  comeca_jogo                 ; se a tecla pressionada for 'C'
    JMP controla_aplicacao

comeca_jogo:
    MOV R1, [modo_aplicacao]            ; se a aplicação já estiver no modo ATIVO
    JNZ controla_aplicacao              ; não faz nada
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
    MOV R9, DEF_MET_BOM                 ; tabela que define o meteoro bom
    CALL desenha_boneco                 ; desenha o meteoro bom
    MOV [bloqueio], R1                  ; desbloqueia o processo "escolhe_comando"

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
    MOV R1, [modo_aplicacao]
    CMP R1, 0
    JNZ seleciona_comando
    
bloqueia_escolhe_comando:
    MOV R2, [bloqueio]

seleciona_comando:    
    WAIT
    MOV R0, [tecla_pressionada]
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
    JMP seleciona_comando

mover_esq:
    MOV R7, [POS_ROVER]     ; linha atual do rover
    MOV R8, [POS_ROVER+2]   ; coluna atual do rover
    MOV R9, DEF_ROVER       ; tabela que define o rover
    CMP R8, MIN_COLUNA      ; o rover esta na coluna 0?
    JZ  seleciona_comando   ; se estiver no limite, não faz nada
    CALL apaga_boneco       ; caso contrário, apaga o rover
    DEC R8                  ; decrementa a coluna
    MOV [POS_ROVER+2], R8   ; atualiza a coluna em memória
    CALL desenha_boneco     ; desenha o rover na nova posição
    CALL atraso             ; delay de movimento
    JMP seleciona_comando

mover_dir:
    MOV R7, [POS_ROVER]     ; linha atual do rover
    MOV R8, [POS_ROVER+2]   ; coluna atual do rover
    MOV R9, DEF_ROVER       ; tabela que define o rover
    MOV R10, MAX_COLUNA	    ; valor maximo da coluna	
    CMP R8, R10             ; o rover esta na coluna 64?
    JZ  seleciona_comando     ; se estiver no limite, não faz nada
    CALL apaga_boneco       ; apaga o rover
    INC R8                  ; aumenta a coluna
    MOV [POS_ROVER+2], R8   ; atualiza a coluna em memória
    CALL desenha_boneco     ; desenha o rover na nova posição
    CALL atraso             ; delay de movimento
    JMP seleciona_comando

decrementa:
    MOV R7, [VALOR_DISPLAY]     ; obter valor do display
    CMP R7, 000H                ; verifica se atingi valor mínimo
    JZ  seleciona_comando         ; se estiver no limite, não faz nada
    DEC R7                      ; decrementa valor
    MOV [VALOR_DISPLAY], R7     ; atualiza na memória
    MOV [DISPLAYS], R7          ; atualiza no display
    JMP seleciona_comando

incrementa:
    MOV R7, [VALOR_DISPLAY]     ; obter valor do display
    CMP  R7, 0FFF8H             ; verifica se atingi valor máximo
    JZ  seleciona_comando         ; se estiver no limite, não faz nada
    INC  R7                     ; incrementa valor
    MOV  [VALOR_DISPLAY], R7    ; atualiza na memória
    MOV  [DISPLAYS], R7         ; atualiza no display
    JMP seleciona_comando

baixa_meteoro:
    MOV R0, 0                   ; som a reproduzir
    MOV [REPRODUZ_SOM], R0      ; reproduz som
    MOV R7, [POS_MET_BOM]       ; linha atual do meteoro bom
    MOV R8, [POS_MET_BOM+2]     ; coluna atual do meteoro bom
    MOV R9, DEF_MET_BOM         ; tabela que define o meteoro bom
    CALL apaga_boneco           ; apaga o meteoro bom
    INC R7                      ; incrementa a linha
    MOV R8, MAX_LINHA           ; linha máxima
    CMP R7, R8                  ; compara a linha atual do meteoro com a linha máxima
    JZ  seleciona_comando         ; se chegar à linha máxima, não o volta a desenhar
    MOV [POS_MET_BOM], R7       ; atualiza a linha em memória
    MOV R8, [POS_MET_BOM+2]     ; coluna atual do meteoro bom
    CALL desenha_boneco         ; desenha o meteoro bom na nova posição
    JMP seleciona_comando

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
