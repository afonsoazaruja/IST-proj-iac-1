;
;
; CONSTANTES
DISPLAYS   EQU 0A000H  ; endereco dos displays de 7 segmentos (periferico POUT-1)
TEC_LIN    EQU 0C000H  ; endereco das linhas do teclado (periferico POUT-2)
TEC_COL    EQU 0E000H  ; endereco das colunas do teclado (periferico PIN)
LINHA      EQU 8       ; linha a testar 8 ( linha, 1000b)
MASCARA    EQU 0FH     ; para isolar os 4 bits de menor peso, ao ler as colunas do teclado

TEC_MOV_ESQ    EQU 0       ; tecla de movimento para a esquerda
TEC_MOV_DIR    EQU 2       ; tecla de movimento para a direita
TEC_DISPARA    EQU 1       ; tecla de disparo
TEC_INICIO     EQU 0CH     ; tecla de comecar o jogo
TEC_PAUSA      EQU 0DH     ; tecla de suspender/continuar o jogo
TEC_FIM        EQU 0EH     ; tecla de terminar o jogo



; CODIGO
PLACE 0

inicio:
    MOV R2, TEC_LIN    ; endereco da linha do teclado
    MOV R3, TEC_COL    ; endereco da coluna do teclado
    MOV R4, DISPLAYS   ; endereco do display
    MOV R5, MASCARA    ; mascara para tornar bits 4-7 a 0, (0000 1111)
    MOV R6, 0          ; contador para saber o numero da linha e coluna
    MOV R7, 4          

reset_tecla:
    MOV R1, LINHA

espera_tecla:
    MOVB [R2], R1      ; escrever no periferico de saida, (linha)
    MOVB R0, [R3]      ; le o perfierico de entrada (coluna)
    AND R0, R5         ; elimina os bits de 4-7
    CMP R0, 0          ; se houve tecla pressionada na linha certa
    JZ linha_depois    ; nao ha teclado primida? verifica proxima linha
    MOV R6, 0          ; incializa contador a zero
    JMP calcula_linha  ; se houver tecla primida, obter o valor da linha

mul_tecla:
    DEC R6             ; decrementar o numero da linha pois comeca por 0 (0, 1, 2, 3)
    MOV R1, R6         
    MUL R1, R7         ; multiplica a linha por 4, (n-1)*4
    MOV R6, 0          ; inicializa o contador a 0, para calcular a coluna
    JMP calcula_coluna ; obter o valor da coluna

add_tecla:
    DEC R6             ; decrementar o numero da linha pois comeca por 0 (0, 1, 2, 3)
    ADD R1, R6         ; soma a multiplicacao anterior com o numero da coluna

escolhe_comando:
    CMP R1, TEC_MOV_ESQ     ;
    JZ mover_esq
    CMP R1, TEC_MOV_DIR
    JZ mover_dir        
    CMP R1, TEC_DISPARA
    JZ dispara
    MOV R11, TEC_INICIO
    XOR R11, R1             ; se a tecla for filtrada pela mascara atual, eh a tecla certa
    JZ iniciar_jogo
    MOV R11, TEC_PAUSA
    XOR R11, R1
    JZ pausar_jogo
    MOV R11, TEC_FIM
    XOR R11, R1
    JZ terminar_jogo
    JMP espera_tecla

linha_depois:
    SHR R1, 1          ; vai para a proxima linha
    JNZ espera_tecla   ; se ainda nao chegou a linha 1, verifica essa linha
    MOV R1, LINHA      ; se chegou a linha 1, verificar todas as linha novamente
    JMP espera_tecla   ; ciclo para testar tecla primida

calcula_linha:
    SHR R1, 1          ; shift 1 bit para direita do valor da coluna
    INC R6             ; incrementa 1, para calcular qual coluna
    CMP R1, 0          ; chegou ao fim?
    JZ mul_tecla       ; se sim, volta para completar a conta e fazer display
    JMP calcula_linha  ; se nao, continua 

calcula_coluna:
    SHR R0, 1          ; shift 1 bit para direita do valor da coluna
    INC R6             ; incrementa 1, para calcular qual coluna
    CMP R0, 0          ; chegou ao fim?
    JZ add_tecla       ; se sim, volta para completar a soma e fazer display
    JMP calcula_coluna ; se nao, continua 


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
