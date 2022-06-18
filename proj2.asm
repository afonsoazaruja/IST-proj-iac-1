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
LINHA_TEC  EQU 8       ; linha a testar (linha 8, 1000b)
MASCARA    EQU 0FH     ; necessário para isolar os bits de 4-7

TEC_MOV_ESQ         EQU 0           ; tecla de movimento do rover para a esquerda ('0')
TEC_MOV_DIR         EQU 2           ; tecla de movimento do rover para a direita ('2')
TEC_MISSIL          EQU 1           ; tecla de disparo do missil ('1')
TEC_COMECAR         EQU 0CH         ; tecla para começar o jogo ('C')
TEC_PAUSAR          EQU 0DH         ; tecla para suspender/continuar o jogo ('D')
TEC_TERMINAR        EQU 0EH         ; tecla para terminar o jogo

PARADO      EQU 0       ; modo parado da aplicação
ATIVO       EQU 1       ; modo ativo da aplicação
PAUSA       EQU 2       ; modo pausa da aplicação

ATRASO_ROVER    EQU	3000H       ; atraso para limitar a velocidade de movimento do rover

FATOR   EQU 3E8H            ; fator e divisor utilizados na conversão
DIVISOR EQU 0AH             ; de 

MIN_DISPLAY EQU 0H          ; valor hexadecimal minimo que o display pode apresentar
MAX_DISPLAY EQU 64H         ; valor hexadecimal maximo que o display pode apresentar

; ****************************************************************************** 
; * DEFINIÇÃO DO MEDIA CENTER
; ****************************************************************************** 

DEFINE_LINHA            EQU 600AH      ; endereço do comando para definir a linha
DEFINE_COLUNA           EQU 600CH      ; endereço do comando para definir a coluna
DEFINE_PIXEL            EQU 6012H      ; endereço do comando para escrever um pixel
APAGA_AVISO             EQU 6040H      ; endereço do comando para apagar o aviso de nenhum cenário selecionado
APAGA_ECRA              EQU 6002H      ; endereço do comando para apagar todos os pixels já desenhados
SELEC_ECRA              EQU 6004H      ; endereço do comando para selecionar o ecrã onde se vai desenhar
SELEC_CENARIO_FUNDO     EQU 6042H      ; endereço do comando para selecionar uma imagem de fundo
REPRODUZ_SOM            EQU 605AH      ; endereço do comando para reproduzir um som
REPRODUZ_VIDEO_LOOP     EQU 605CH      ; endereço do comando para reproduzir um video em loop
PAUSA_VIDEO             EQU 605EH      ; endereço do comando para pausar a reprodução do vídeo especificado
CONTINUA_VIDEO          EQU 6060H      ; endereço do comando para continuar a reprodução do vídeo especificado
TERMINA_VIDEO           EQU 6066H      ; endereço do comando para terminar a reprodução do vídeo especificado
SELEC_CENARIO_FRONTAL   EQU 6046H      ; endereço do comando para selecionar o cenário frontal a visualizar
APAGA_CENARIO_FRONTAL   EQU 6044H      ; endereço do comando para apagar o cenário frontal

MIN_COLUNA		EQU 0		   ; número da coluna mais à esquerda que um objeto pode ocupar
MAX_COLUNA		EQU 59         ; número da coluna mais à direita que um objeto de largura 5 pode ocupar
MAX_LINHA       EQU 32         ; número da linha máxima

CINZENTO    EQU 0ADCDH         ; cores utilizadas
VERDE       EQU 0F0F0H
AMARELO     EQU	0FFF0H
VERMELHO    EQU 0FF00H
AZUL        EQU 0F0AFH
ROXO        EQU 0FA0FH

; ******************************************************************************
; * STACKS
; ******************************************************************************
PLACE 1000H

	STACK 100H              ; espaço reservado para a pilha do processo "controlo"
SP_inicial_controlo:        ; endereço com que o SP deste processo deve ser inicializado

    STACK 100H              ; espaço reservado para a pilha do processo "teclado"
SP_inicial_teclado:         ; endereço com que o SP deste processo deve ser inicializado

    STACK 100H              ; espaço reservado para a pilha do processo "rover"
SP_inicial_rover:           ; endereço com que o SP deste processo deve ser inicializado

    STACK 100H              ; espaço reservado para a pilha do processo "energia"
SP_inicial_energia:         ; endereço com que o SP deste processo deve ser inicializado

    STACK 100H              ; espaço reservado para a pilha do processo "missil"
SP_inicial_missil:          ; endereço com que o SP deste processo deve ser inicializado

    STACK 100H              ; espaço reservado para a pilha do processo "meteoros", instância 1
SP_inicial_meteoros_0:      ; endereço com que o SP deste processo deve ser inicializado

    STACK 100H              ; espaço reservado para a pilha do processo "meteoros", instância 2
SP_inicial_meteoros_1:      ; endereço com que o SP deste processo deve ser inicializado

    STACK 100H              ; espaço reservado para a pilha do processo "meteoros", instância 3
SP_inicial_meteoros_2:      ; endereço com que o SP deste processo deve ser inicializado

    STACK 100H              ; espaço reservado para a pilha do processo "meteoros", instância 4
SP_inicial_meteoros_3:      ; endereço com que o SP deste processo deve ser inicializado

meteoros_SP_tab:                        ; tabela com os endereços das pilhas das
	WORD	SP_inicial_meteoros_0       ; várias instâncias do processo "meteoros"
	WORD	SP_inicial_meteoros_1
	WORD	SP_inicial_meteoros_2
	WORD	SP_inicial_meteoros_3

; ****************************************************************************** 
; * DADOS
; ****************************************************************************** 

tecla_pressionada:
    LOCK 0                 ; LOCK para o teclado comunicar aos restantes processos que tecla detetou

modo_aplicacao:
    WORD PARADO            ; modo atual da aplicação

bloqueio:
    LOCK 0                 ; LOCK para bloquear o processo "rover"

linha_a_testar:
    WORD LINHA_TEC         ; linha inicial a testar

; ****************************************************************************** 
; * DEFINIÇÃO DO ROVER
; ****************************************************************************** 

ALTURA_ROVER    EQU 4
LARGURA_ROVER   EQU	5

DEF_ROVER:                              ; tabela que define o rover
	WORD	LARGURA_ROVER, ALTURA_ROVER                             
    WORD    0 , 0, AMARELO, 0 , 0
	WORD	AMARELO, 0, AMARELO, 0, AMARELO
    WORD    AMARELO, AMARELO, AMARELO, AMARELO, AMARELO
    WORD    0, AMARELO, 0, AMARELO, 0

LINHA_ROVER     EQU 28          ; linha inicial do pixel de referência do rover
COLUNA_ROVER    EQU 30          ; coluna inicial do pixel de referência do rover

POS_ROVER:                      ; posição do rover (vai sendo atualizada)
    WORD    LINHA_ROVER, COLUNA_ROVER

; ****************************************************************************** 
; CONSTANTES - METEOROS
; ****************************************************************************** 

MET_BOM         EQU 0           ; constantes usadas na escolha do
MET_MAU         EQU 130         ; tamanho de meteoro a usar

LINHA_DEF_1     EQU 0           ; linhas correspondentes a cada
LINHA_DEF_2     EQU 2           ; tamanho dos meteoros
LINHA_DEF_3     EQU 5
LINHA_DEF_4     EQU 8
LINHA_DEF_5     EQU 11

ALTURA_MET_1    EQU 1           ; diferentes alturas e larguras
LARGURA_MET_1   EQU 1           ; que os meteoros podem tomar

ALTURA_MET_2    EQU 2
LARGURA_MET_2   EQU 2

ALTURA_MET_3    EQU 3
LARGURA_MET_3   EQU 3

ALTURA_MET_4    EQU 4
LARGURA_MET_4   EQU 4

ALTURA_MET_5    EQU 5
LARGURA_MET_5   EQU 5

; ****************************************************************************** 
; * DEFINIÇÕES DOS METEOROS
; ****************************************************************************** 

DEF_MET:                                    ; tabela que define os vários tamanhos e
    WORD    LARGURA_MET_5, ALTURA_MET_5     ; formas que os meteoros podem apresentar
    WORD    0, VERDE, VERDE, VERDE, 0           ; começa pelos meteoros bons
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

    WORD    LARGURA_MET_5, ALTURA_MET_5         ; e tem depois as naves inimigas
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

; ****************************************************************************** 
; POSIÇÕES DOS METEOROS (MAX 4)
; ****************************************************************************** 

POS_MET:
    WORD    0, 0, 0, 1       ; linha, coluna, tipo e ecrã, respetivamente,
    WORD    0, 0, 0, 2       ; de cada um dos meteoros
    WORD    0, 0, 0, 3       ; estes 0's são imediamente
    WORD    0, 0, 0, 4       ; atualizados no início do jogo

; ****************************************************************************** 
; * DEFINIÇÃO DO MÍSSIL
; ****************************************************************************** 

DEF_MISSIL:             ; tabela que define o míssil
    WORD 1, 1
    WORD ROXO

LINHA_MISSIL    EQU 14          ; 14 é a linha onde o míssil se extingue
COLUNA_MISSIL   EQU 0           ; 0 é apenas um valor inicial sem significado

POS_MISSIL:             ; posição do míssil (vai sendo atualizada)
    WORD LINHA_MISSIL, COLUNA_MISSIL

LINHA_MAX_MISSIL    EQU 15

; ****************************************************************************** 
; * DEFINIÇÃO DA EXPLOSÃO
; ****************************************************************************** 

DEF_EXPLOSAO:           ; tabela que define a explosão
    WORD   LARGURA_MET_5, ALTURA_MET_5 
    WORD    0, AZUL, 0, AZUL, 0
    WORD    AZUL, 0, AZUL, 0, AZUL
    WORD    0, AZUL, 0, AZUL, 0
    WORD    AZUL, 0, AZUL, 0, AZUL
    WORD    0, AZUL, 0, AZUL, 0

POS_EXPLOSAO:           ; posição da última explosão
    WORD 0, 0

; ******************************************************************************
; * DISPLAYS
; ****************************************************************************** 

VALOR_DISPLAY:          ; valores em memória do display
    WORD    64H         ; valor hexadecimal real
    WORD    100H        ; valor para mostrar como se fosse decimal

; ******************************************************************************
; * INTERRUPÇÕES
; ****************************************************************************** 

tab:
	WORD rot_int_0			; rotina de atendimento da interrupção 0
	WORD rot_int_1			; rotina de atendimento da interrupção 1
	WORD rot_int_2			; rotina de atendimento da interrupção 2

evento_int_bonecos:			; LOCKs para cada rotina de interrupção comunicar ao
						; respetivo processo que a interrupção ocorreu
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
    MOV [APAGA_AVISO], R1
    MOV [APAGA_ECRA], R1	            ; limpa o ecrã
    MOV [APAGA_CENARIO_FRONTAL], R1     ; Apaga o cenário frontal de pausa
    MOV R0, PARADO
    MOV [modo_aplicacao], R0            ; dá reset ao modo da aplicação
    MOV	R0, 0		                    ; cenário de fundo número 0
    MOV [SELEC_CENARIO_FUNDO], R0	    ; seleciona o cenário de fundo
    MOV R1, MAX_DISPLAY
    MOV [VALOR_DISPLAY], R1             ; obter valor display decimal
    CALL converte                       ; inicializa display a 100
    MOV R1, [VALOR_DISPLAY+2]
    MOV [DISPLAYS], R1
    CALL inicializa_meteoros
    EI0
    EI1
    EI2
    EI

inicializa_processos:
    CALL teclado            ; cria o processo "teclado"
    CALL rover              ; cria o processo "rover"
    CALL missil             ; cria o processo "missil"
    CALL energia            ; cria o processo "energia"
    MOV R0, 24
    MOV R11, 0
    MOV R1, 8
inicializa_processos_ciclo: 
    CALL meteoros           ; cria o processo "meteoros" em ciclo
    ADD R11, R1             ; existem assim 4 instâncias deste processo em simultâneo
    CMP R11, R0
    JLE inicializa_processos_ciclo


espera_inicio_jogo:
    MOV R0, [tecla_pressionada]         ; Espera por uma tecla
    MOV R11, TEC_COMECAR                
    XOR R11, R0                         ; Verifica se a tecla pressionada corresponde à de início
    JNZ espera_inicio_jogo              ; Se não, contínua à espera

comeca_jogo:
    MOV R0, 0
    MOV [SELEC_ECRA], R0                ; vai desenhar no ecrã 0
    MOV R1, MAX_DISPLAY
    MOV [VALOR_DISPLAY], R1
    CALL converte                       ; obtém valor display decimal
    MOV R1, [VALOR_DISPLAY+2]           ; inicializa display a 100
    MOV [DISPLAYS], R1
    MOV R1, ATIVO                       
    MOV [modo_aplicacao], R1            ; troca o modo da aplicação para ATIVO
    MOV [APAGA_ECRA], R1                ; apaga o ecrã
    MOV R0, 0
    MOV [REPRODUZ_VIDEO_LOOP], R0       ; inicia a reprodução em loop do vídeo de fundo
    MOV R7, [POS_ROVER]
    MOV R8, [POS_ROVER+2]
    MOV R9, DEF_ROVER
    CALL desenha_boneco                 ; desenha o rover
    MOV [bloqueio], R1                  ; desbloqueia o processo "rover"

controla_aplicacao:
    YIELD
    MOV R0, [tecla_pressionada]
    MOV R11, [modo_aplicacao]
    CMP R11, PARADO                     ; se o jogo estiver parado
    JNZ pausa_e_termina
    MOV R11, TEC_COMECAR                ; e for pressionada a tecla de começar
    XOR R11, R0
    JZ  comeca_jogo                     ; vai começar o jogo
    JMP espera_inicio_jogo              ; se não, fica à espera que seja pressionada
pausa_e_termina:                        ; se o jogo estiver em pausa ou ativo, só pode pausar ou terminar
    MOV R11, TEC_PAUSAR
    XOR R11, R0
    JZ  pausa_continua_jogo             ; se a tecla pressionada for 'D'
    MOV R11, TEC_TERMINAR
    XOR R11, R0
    JZ  termina_jogo                    ; se a tecla pressionada for 'E'
    JMP controla_aplicacao

pausa_continua_jogo:
    MOV R1, [modo_aplicacao]
    CMP R1, ATIVO                       ; Verifica se o modo de jogo é ATIVO
    JZ pausa_jogo                       ; Se sim, pausa
    JMP continua_jogo                   ; Se não, contínua o jogo

pausa_jogo:
    DI                                  
    MOV R1, PAUSA
    MOV [modo_aplicacao], R1            ; Muda o modo de jogo para PAUSA
    MOV R1, 0
    MOV [PAUSA_VIDEO], R1
    MOV R1, 4
    MOV [SELEC_CENARIO_FRONTAL], R1     ; Apresenta um cenário frontal de pausa
    JMP controla_aplicacao

continua_jogo:
    EI
    MOV R1, ATIVO           
    MOV [modo_aplicacao], R1            ; Muda o modo de jogo para ATIVO
    MOV R1, 0
    MOV [APAGA_CENARIO_FRONTAL], R1     ; Apaga o cenário frontal de pausa
    MOV [CONTINUA_VIDEO], R1
    MOV [bloqueio], R1                  ; Bloqueia o processo ROVER
    JMP controla_aplicacao

termina_jogo:
    DI
    MOV R1, 0
    MOV [TERMINA_VIDEO], R1
    CALL fim_de_jogo
    MOV [APAGA_CENARIO_FRONTAL], R1     ; Apaga o cenário frontal de pausa
    MOV R1, 3
    MOV [SELEC_CENARIO_FUNDO], R1
    CALL inicializa_meteoros
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

ha_tecla:                       ; neste ciclo espera-se até nenhuma tecla estar premida
    YIELD
    CMP R0, 0
    JZ espera_tecla
    CMP R0, 2
    JZ espera_tecla
    MOVB [R3], R1               ; escrever no periférico de saída (linhas)
    MOVB R2, [R4]               ; ler do periférico de entrada (colunas)
    AND R2, R5                  ; elimina bits para além dos bits 0-3
    CMP R2, 0                   ; se ler coluna nenhuma do teclado
    JNZ ha_tecla                ; se ainda houver uma tecla premida, espera até não haver
    JMP espera_tecla            ; volta a esperar que seja premida uma nova tecla

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
    CMP R1, ATIVO                   ; Se o jogo tiver ativo
    JZ movimento                    ; O rover pode mover-se

bloqueia_rover:
    MOV R2, [bloqueio]              ; Caso contrario
    JMP rover                       ; Espera que o jogo fique ativo
    
movimento:
    MOV R0, [tecla_pressionada]
    MOV R1, [modo_aplicacao]
    CMP R1, ATIVO
    JNZ bloqueia_rover
    MOV R10, 0
    MOV [SELEC_ECRA], R10       ; vai desenhar no ecrã 0
    CMP R0, TEC_MOV_ESQ
    JZ  mover_esq                ; se for tecla '0'
    CMP R0, TEC_MOV_DIR
    JZ  mover_dir                ; se for tecla '2'
    CMP R0, TEC_MISSIL
    JZ  dispara                  ; se for tecla '1'
    JMP rover

mover_esq:
    MOV R7, [POS_ROVER]
    MOV R8, [POS_ROVER+2]
    MOV R9, DEF_ROVER
    CMP R8, MIN_COLUNA          ; o rover esta na coluna 0?
    JZ  rover                   ; se estiver, não faz nada
    CALL apaga_boneco           ; caso contrário, apaga o rover,
    DEC R8                      ; decrementa a coluna,
    MOV [POS_ROVER+2], R8       ; atualiza a coluna em memória,
    CALL desenha_boneco         ; e desenha o rover na nova posição
    MOV R10, ATRASO_ROVER
    CALL atraso                 ; delay de movimento
    JMP rover

mover_dir:
    MOV R7, [POS_ROVER]
    MOV R8, [POS_ROVER+2]
    MOV R9, DEF_ROVER
    MOV R10, MAX_COLUNA	        ; valor maximo da coluna do pixel de referência
    CMP R8, R10                 ; o rover esta na coluna 64?
    JZ  rover                   ; se estiver, não faz nada
    CALL apaga_boneco           ; caso contrário, apaga o rover,
    INC R8                      ; aumenta a coluna,
    MOV [POS_ROVER+2], R8       ; atualiza a coluna em memória,
    CALL desenha_boneco         ; e desenha o rover na nova posição
    MOV R10, ATRASO_ROVER
    CALL atraso                 ; delay de movimento
    JMP rover

dispara:
    MOV R3, [POS_MISSIL]
    MOV R4, LINHA_MAX_MISSIL
    CMP R3, R4                  ; Se o míssil não tiver andado 12 linhas (até à linha nº 14)
    JNN rover                   ; Não é disparado mais nenhum
    CALL verifica_energia       ; Caso contrário, continua
    MOV R3, -5                  
    CALL altera_energia         ; Diminui a energia em 5
    MOV R10, [modo_aplicacao]   ; verifica se o modo de aplicação saiu de ATIVO
    CMP R10, ATIVO
    JNZ rover                   ; se sim, não faz mais nada
    MOV R7, [POS_ROVER]
    DEC R7                      ; Linha onde o míssil vai aparecer
    MOV R8, [POS_ROVER+2]       
    ADD R8, 2                   ; Coluna onde o míssil vai aparecer
    MOV R9, DEF_MISSIL
    CALL desenha_boneco         ; Desenha o míssil
    MOV R10, 1
    MOV [REPRODUZ_SOM], R10     ; reproduz o som do disparo do míssil
    MOV [POS_MISSIL], R7
    MOV [POS_MISSIL+2], R8
    JMP rover

; ******************************************************************************
;   METEOROS - Testa se a interrupção 0 ocorreu e, caso tenha ocorrido, faz
;              descer os meteoros
; ******************************************************************************
PROCESS SP_inicial_meteoros_0
meteoros:
    MOV R10, POS_MET
    ADD R10, R11                    ; R10 PASSA A DEFINIR O METEORO DESTE PROCESSO
    SHR R11, 2
    MOV R1, meteoros_SP_tab
    MOV SP, [R1+R11]                ; reinicializa o SP com o endereço correto
    
meteoros_ciclo:
    WAIT
    MOV R0, [evento_int_bonecos]    ; Lock na interrupção 0
    MOV R1, [modo_aplicacao]            
    CMP R1, ATIVO                   ; Se o não jogo estiver ATIVO
    JNZ sai_meteoros                ; Não contínua
    MOV R11, [R10+6]                ; ecrã onde se deve desenhar o meteoro
    MOV [SELEC_ECRA], R11           ; vai desenhar no ecrã especifico do meteoro
    MOV R7, [POS_EXPLOSAO]          
    CMP R7, 0
    JZ baixa_meteoro                ; se não houver explosão anterior, passa à frente
    MOV R8, [POS_EXPLOSAO+2]
    MOV R9, DEF_EXPLOSAO
    CALL apaga_boneco

baixa_meteoro:
    MOV R7, [R10]               ; linha atual do meteoro
    MOV R8, [R10+2]             ; coluna atual do meteoro
    MOV R6, [R10+4]             ; tipo de meteoro
    CALL escolhe_def                ; determina qual definição do boneco a usar
    CALL apaga_boneco
    INC R7                          ; aumenta linha
    MOV R11, MAX_LINHA              
    CMP R7, R11                     ; verifica se chegou ao fim
    JZ  reinicia_meteoro            ; se sim, transforma-o num novo meteoro
    MOV [R10], R7               ; atualiza linha
    CALL escolhe_def
    CALL desenha_boneco
    JMP deteta_colisao_missil

reinicia_meteoro:
    MOV R7, -1
    MOV [R10], R7
    CALL met_aleatorio
    MOV [R10+2], R2
    MOV [R10+4], R3
    JMP sai_meteoros

deteta_colisao_missil:
    MOV R11, 14
    CMP R7, R11                     ; se o meteoro ainda estiver for do alcance do míssil
    JLE sai_meteoros                ; não faz nada
    MOV R2, [POS_MISSIL]
    CMP R2, R11                     ; verifica se o missil existe
    JZ  deteta_colisao_rover        ; se não, passa para a deteção da colisão com o rover
    MOV R3, [POS_MISSIL+2]
    MOV R4, [R10]
    ADD R4, 5                       ; Linha máxima do meteoro (mais abaixo)
    CMP R2, R4                      ; verifica se o missil esta acima da linha maxima do meteoro
    JGT deteta_colisao_rover        ; Se sim não faz nada
    MOV R4, [R10+2]     
    CMP R3, R4                      ; Verifica se a coluna mais à esquerda do meteoro é inferior à do míssil
    JN deteta_colisao_rover
    ADD R4, 5
    CMP R3, R4                      ; Verifica se a coluna mais à direita do meteoro é superior à do míssil
    JN explosao

sai_meteoros:
    JMP meteoros_ciclo

deteta_colisao_rover:
    MOV R2, [POS_ROVER]
    MOV R4, [R10]
    ADD R4, 5                   ; linha adjacente à linha máxima do meteoro
    CMP R2, R4                  ; verifica se o pixel de referência do rover está depois desta
    JGE sai_meteoros            ; se estiver, não faz nada
    MOV R3, [POS_ROVER+2]
    MOV R4, [R10+2]
    SUB R3, R4                  ; verifica se o pixel de referência do rover está a uma
    CMP R3, -5                  ; distância máxima de 5 do pixel de referência do meteoro
    JLE sai_meteoros
    CMP R3, 5
    JGE sai_meteoros
    MOV R11, MET_MAU            ; se chegou aqui, então colidiu com o rover
    CMP R6, R11
    JZ perde_jogo               ; se era uma nave inimiga, perde o jogo
    CALL apaga_boneco           ; se era um meteoro bom, continua
    MOV R7, -1
    MOV [R10], R7
    CALL met_aleatorio          ; transforma-o num novo meteoro
    MOV [R10+2], R2
    MOV [R10+4], R3
    MOV R3, 10
    CALL altera_energia         ; incrementa a energia
    MOV R11, 2
    MOV [REPRODUZ_SOM], R11
    JMP sai_meteoros

perde_jogo:
    MOV R1, 0
    MOV [TERMINA_VIDEO], R1
    CALL fim_de_jogo
    MOV R1, 4
    MOV [REPRODUZ_SOM], R1
    MOV R1, 2
    MOV [SELEC_CENARIO_FUNDO], R1
    CALL inicializa_meteoros
    JMP sai_meteoros

explosao:
    MOV R9, DEF_EXPLOSAO
    CALL desenha_boneco             ; Desenha a explosão
    MOV [POS_EXPLOSAO], R7
    MOV [POS_EXPLOSAO+2], R8
    MOV R7, -1
    MOV [R10], R7
    CALL met_aleatorio
    MOV [R10+2], R2
    MOV [R10+4], R3
    MOV R7, [POS_MISSIL]
    MOV R8, [POS_MISSIL+2]
    MOV R9, DEF_MISSIL
    MOV R11, 0
    MOV [SELEC_ECRA], R11           ; vai desenhar no ecrã 0
    CALL apaga_boneco               ; Apaga o míssil
    MOV R2, 14
    MOV [POS_MISSIL], R2
    CMP R6, MET_BOM
    JZ sai_meteoros                 ; se for meteoro bom, sai
    MOV R3, 5
    CALL altera_energia
    MOV R11, 3
    MOV [REPRODUZ_SOM], R11
    JMP sai_meteoros

; ******************************************************************************
;   MÍSSIL - Controla o movimento linear do míssil, dependente da interrupção 1
; ******************************************************************************
PROCESS SP_inicial_missil
missil:
    WAIT
    MOV R0, [evento_int_bonecos+2]          ; lock na rotina de interrupção 1
    MOV R1, [modo_aplicacao]            
    CMP R1, ATIVO                           ; se o jogo não estiver a correr
    JNZ sai_missil                          ; Não faz nada
    MOV R7, [POS_MISSIL]                    ; Caso contrário
    MOV R10, 14
    CMP R7, R10                             ; Verifica se já existe algum míssil na linha 14
    JZ sai_missil                           ; Se sim, não faz nada
    MOV R8, [POS_MISSIL+2]                  ; Caso contrário
    MOV R9, DEF_MISSIL
    MOV R10, 0
    MOV [SELEC_ECRA], R10                   ; vai desenhar no ecrã 0
    CALL apaga_boneco
    DEC R7
    MOV R10, LINHA_MAX_MISSIL
    CMP R7, R10
    JN altera_valor_linha
    CALL desenha_boneco
altera_valor_linha:
    MOV [POS_MISSIL], R7
sai_missil:
    JMP missil

; ******************************************************************************
;   ENERGIA - Testa se a interrupção 2 ocorreu e, caso tenha ocorrido,
;             decrementa o display da energia
; ******************************************************************************
PROCESS SP_inicial_energia
energia:
    WAIT
    MOV R0, [evento_int_bonecos+4]          ; lock na rotina de interrupção 2
    MOV R1, [modo_aplicacao]
    CMP R1, ATIVO                           ; Verifica se o jogo está a correr
    JNZ sai_energia                         ; Se não estiver, não faz nada
    CALL verifica_energia                   ; Caso contrário
    MOV R3, -5                              ; Diminui em 5 a energia
    CALL altera_energia
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
    MOV	R1, [R9]            ; obtém a largura do boneco
    MOV R4, R1              ; guarda a largura do boneco
    ADD	R9, 2               ; endereço da altura do boneco (2 porque a largura é uma word)
    MOV R2, [R9]            ; obtém a altura do boneco
    ADD R9, 2               ; endereço do 1º pixel
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
    MOV [DEFINE_COLUNA], R8	    ; seleciona a coluna
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
    MOV	R1, [R9]        ; obtém a largura do boneco
    MOV R4, R1          ; guarda a largura do boneco
    ADD	R9, 2           ; endereço da altura do boneco (2 porque a largura é uma word)
    MOV R2, [R9]        ; obtém a altura do boneco
    ADD R9, 2           ; endereço do 1º pixel

apaga_pixels:               ; desenha os pixels do boneco a partir da tabela
    MOV R3, MAX_LINHA
    CMP R7, R3              ; caso esteja na última linha do ecrã
    JZ sai_apaga_pixels     ; então para de apagar
    MOV R3, 0               ; obtém a cor do próximo pixel do boneco
    CALL escreve_pixel      ; escreve cada pixel do boneco
    ADD R8, 1               ; próxima coluna
    SUB R1, 1               ; menos uma coluna para tratar
    JNZ apaga_pixels        ; continua até percorrer toda a largura do objeto
    ADD R7, 1               ; próxima linha
    MOV R1, R4              ; reset à largura a percorrer
    SUB R8, R4              ; volta à coluna original
    SUB R2, 1               ; menos uma linha para tratar
    JNZ apaga_pixels        ; continua até percorrer toda a altura do objeto
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
; Argumentos:   R10 - Atraso a ser implementado
; ******************************************************************************
atraso:
    PUSH R0
    MOV R0, R10
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
    ADD R9, R6                      ; Escolhe o tipo de meteoro (com base na tabela definida)
    MOV R0, LINHA_DEF_5             
    CMP R0, R7                      ; Se está na linha (0) a mudar de definição
    JLE escolhe_def_saida           ; Sai da rotina com a nova definição escolhida
    MOV R0, 54                      
    ADD R9, R0
    MOV R0, LINHA_DEF_4             ; Se está na linha (2) a mudar de definição
    CMP R0, R7
    JLE escolhe_def_saida
    MOV R0, 36
    ADD R9, R0
    MOV R0, LINHA_DEF_3            ; Se está na linha (5) a mudar de definição
    CMP R0, R7
    JLE escolhe_def_saida
    MOV R0, 22
    ADD R9, R0
    MOV R0, LINHA_DEF_2            ; Se está na linha (9) a mudar de definição
    CMP R0, R7
    JLE escolhe_def_saida
    MOV R0, 12
    ADD R9, R0
    MOV R0, LINHA_DEF_1            ; Se está na linha (14) a mudar de definição
    CMP R0, R7
escolhe_def_saida:
    POP R0
    RET

; **********************************************************************
; VERIFICA_ENERGIA - Rotina que verifica se a energia chegou ao fim
; **********************************************************************
verifica_energia:
    PUSH R0
    PUSH R1
    MOV R0, [VALOR_DISPLAY]
    SUB R0, 5                           ; Retirar 5 à energia existente
    CMP R0, 0                           ; Se não for 0
    JNZ sai_verifica_energia            ; Sai da rotina
    MOV R1, PARADO                      ; Se for zero
    MOV [modo_aplicacao], R1            ; Procede por parar o jogo
    MOV [APAGA_ECRA], R1                ; E dar um "reset" ao ecrã, rover, meteoros e ao míssil
    MOV R1, 0
    MOV [TERMINA_VIDEO], R1
    MOV R1, 2
    MOV [SELEC_CENARIO_FUNDO], R1
    MOV R1, 4
    MOV [REPRODUZ_SOM], R1
    MOV R2, LINHA_ROVER
    MOV [POS_ROVER], R2
    MOV R2, COLUNA_ROVER
    MOV [POS_ROVER+2], R2
    MOV R2, LINHA_MISSIL
    MOV [POS_MISSIL], R2
    MOV R2, COLUNA_MISSIL
    MOV [POS_MISSIL+2], R2
    CALL inicializa_meteoros
sai_verifica_energia:
    POP R1
    POP R0
    RET

; **********************************************************************
; ALTERA_ENERGIA - Altera o valor da energia do rover
; Argumentos:      R3: valor a alterar
; **********************************************************************
altera_energia:
    PUSH R7
    PUSH R8
    MOV R7, [VALOR_DISPLAY]
    ADD R7, R3                      ; altera valor
    MOV R8, MAX_DISPLAY
    CMP R7, R8
    JLE sai_altera_energia
    MOV R7, 100
sai_altera_energia:
    MOV [VALOR_DISPLAY], R7
    CALL converte                   ; converte valor hexadecimal para decimal
    MOV R7, [VALOR_DISPLAY+2]
    MOV [DISPLAYS], R7
    POP R8
    POP R7
    RET

; **********************************************************************
; MET_ALEATORIO - Calcula um valor pseudo-aleatório para a coluna de um
;                 meteoro e determina o seu tipo
; Retorna:        R2: valor para a coluna
;                 R3: tipo de meteoro
; **********************************************************************
met_aleatorio:
    PUSH R0
    PUSH R1
    PUSH R10
    MOV R10, 1
met_aleatorio_numero:               ; escolhe um número aleatório
    MOV R0, 0F0H
    MOV R1, [TEC_COL]
    AND R1, R0
    SHR R1, 5
    CMP R10, 0
    JZ met_aleatorio_tipo
met_aleatorio_coluna:               ; decide a sua coluna
    MOV R2, 8
    MUL R2, R1
    DEC R10
    JMP met_aleatorio_numero
met_aleatorio_tipo:                 ; decide o seu tipo
    CMP R1, 6
    JGE define_met_bom
    MOV R3, MET_MAU
    JMP sai_met_aleatorio
define_met_bom:
    MOV R3, MET_BOM
sai_met_aleatorio:
    POP R10
    POP R1
    POP R0
    RET

; **********************************************************************
; INICIALIZA_METEOROS - Inicializa a tabela de meteoros em jogo
; **********************************************************************
inicializa_meteoros:
    PUSH R0
    PUSH R1
    PUSH R2
    PUSH R3
    PUSH R4
    PUSH R11
    MOV R0, 4
    MOV R1, -1
    MOV R4, 8
    MOV R11, POS_MET
inicializa_meteoros_ciclo:
    CALL met_aleatorio          ; inicializa um meteoro
    MOV [R11], R1
    MOV [R11+2], R2
    MOV [R11+4], R3
    ADD R11, R4                 ; passa para o próximo meteoro                
    DEC R0
    CMP R0, 0
    JNZ inicializa_meteoros_ciclo
    POP R11
    POP R4
    POP R3
    POP R2
    POP R1
    POP R0
    RET

; **********************************************************************
; FIM_DE_JOGO - Termina o jogo alterando o modo de aplicação para PARADO
; **********************************************************************
fim_de_jogo:
    PUSH R1
    PUSH R2    
    MOV R1, PARADO                      ; Se for zero
    MOV [modo_aplicacao], R1            ; Procede por parar o jogo
    MOV [APAGA_ECRA], R1                ; E dar um "reset" ao ecrã, rover, meteoros e ao míssil
    MOV R2, LINHA_ROVER
    MOV [POS_ROVER], R2
    MOV R2, COLUNA_ROVER
    MOV [POS_ROVER+2], R2
    MOV R2, LINHA_MISSIL
    MOV [POS_MISSIL], R2
    MOV R2, COLUNA_MISSIL
    MOV [POS_MISSIL+2], R2
    POP R2
    POP R1
    RET

; **********************************************************************
; ROT_INT_0 - Rotina de atendimento da interrupção 0
; **********************************************************************
rot_int_0:
	PUSH	R1
    MOV R1, evento_int_bonecos
	MOV	[R1+0], R0	                ; desbloqueia processo boneco (qualquer registo serve) 
	POP	R1
	RFE

; **********************************************************************
; ROT_INT_1 - Rotina de atendimento da interrupção 1
; **********************************************************************
rot_int_1:
	PUSH	R1
	MOV R1, evento_int_bonecos
	MOV	[R1+2], R0	                ; desbloqueia processo boneco (qualquer registo serve) 
	POP	R1
	RFE

; **********************************************************************
; ROT_INT_2 - Rotina de atendimento da interrupção 2
; **********************************************************************
rot_int_2:
	PUSH	R1
	MOV R1, evento_int_bonecos
    MOV	[R1+4], R0	                ; desbloqueia processo boneco (qualquer registo serve) 
	POP	R1
	RFE
