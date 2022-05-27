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

TEC_MOV_ESQ    EQU 0       ; tecla de movimento do rover para a esquerda ('0')
TEC_MOV_DIR    EQU 2       ; tecla de movimento do rover para a direita ('2')
TEC_DISPARA    EQU 1       ; tecla de disparo do rover ('1')
TEC_INICIO     EQU 0CH     ; tecla de comecar o jogo ('c')
TEC_PAUSA      EQU 0DH     ; tecla de suspender/continuar o jogo ('d')
TEC_FIM        EQU 0EH     ; tecla de terminar o jogo ('e')

MIN_COLUNA  EQU 0   ; número mínimo da coluna
MAX_COLUNA  EQU 63  ; número máximo da coluna

; ******************************************************************************
; * CODIGO
; ******************************************************************************

PLACE 0

inicio:
    MOV R2, TEC_LIN    ; endereço da linha do teclado
    MOV R3, TEC_COL    ; endereço da coluna do teclado
    MOV R4, DISPLAYS   ; endereço do display
    MOV R5, MASCARA    ; mascara para tornar bits 4-7 a 0
    MOV R6, 0          ; contador para saber o numero da linha e coluna
    MOV R7, 4          ; constante para calcular qual tecla foi pressionada

reset_tecla:
    MOV R1, LINHA

espera_tecla:
    MOVB [R2], R1      ; escrever no periférico de saída, (linha)
    MOVB R0, [R3]      ; lê o periférico de entrada (coluna)
    AND R0, R5         ; elimina os bits de 4-7
    CMP R0, 0          ; se houve tecla pressionada na linha certa
    JZ linha_depois    ; não há teclado primida? verifica próxima linha
    MOV R6, 0          ; incializa contador a 0
    JMP calcula_linha  ; se houver tecla primida, obter o valor da linha

linha_depois:
    SHR R1, 1          ; vai para a próxima linha
    JNZ espera_tecla   ; se ainda não ultrapassou a linha 1
    MOV R1, LINHA      ; se ultrapassou a linha 1, repetir ciclo
    JMP espera_tecla   ; repetir ciclo

calcula_linha:
    SHR R1, 1          ; shift 1 bit para direita até chegar a 0
    INC R6             ; incrementa o contador para calcular a linha
    CMP R1, 0          ; chegou ao fim?
    JZ mul_tecla       ; se sim, volta para completar a conta
    JMP calcula_linha  ; se não, continua

calcula_coluna:
    SHR R0, 1          ; shift 1 bit para direita até chegar a 0
    INC R6             ; incrementa o contador para calcular a coluna 
    CMP R0, 0          ; chegou ao fim?
    JZ add_tecla       ; se sim, volta para finalizar a conta
    JMP calcula_coluna ; se não, continua 

mul_tecla:
    DEC R6             ; decrementar o número da linha pois (0, 1, 2, 3)
    MOV R1, R6         
    MUL R1, R7         ; multiplica a linha por 4 --> (n-1)*4
    MOV R6, 0          ; inicializa o contador a 0, para calcular a coluna
    JMP calcula_coluna ; obter o valor da coluna

add_tecla:
    DEC R6             ; decrementar o número da coluna pois (0, 1, 2, 3)
    ADD R1, R6         ; soma a multiplicação anterior com o número da coluna

escolhe_comando:
    CMP R1, TEC_MOV_ESQ
    JZ mover_esq            ; se for tecla '0'
    CMP R1, TEC_MOV_DIR
    JZ mover_dir            ; se for tecla '2'
    CMP R1, TEC_DISPARA     
    JZ dispara              ; se for tecla '1'
    MOV R11, TEC_INICIO     ; criação de máscara
    XOR R11, R1             ; se a tecla for filtrada é a tecla correta
    JZ iniciar_jogo         ; se for tecla 'c'
    MOV R11, TEC_PAUSA      ; atualização de máscara
    XOR R11, R1             ; se a tecla for filtrada é a tecla correta
    JZ pausar_jogo          ; se for tecla 'd'
    MOV R11, TEC_FIM        ; atualização de máscara
    XOR R11, R1             ; se a tecla for filtrada é a tecla correta
    JZ terminar_jogo        ; se for tecla 'e'
    JMP espera_tecla        ; caso não corresponda a nenhuma tecla

mover_esq:
    MOV R10, 0
    JMP reset_tecla
mover_dir:
    MOV R10, 2
    JMP reset_tecla
dispara:
    MOV R10, 1
    JMP reset_tecla
iniciar_jogo:
    MOV R10, 0CH
    JMP reset_tecla
pausar_jogo:
    MOV R10, 0DH
    JMP reset_tecla
terminar_jogo:
    MOV R10, 0EH
    JMP reset_tecla
