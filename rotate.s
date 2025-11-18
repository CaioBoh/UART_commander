/*
 * FUNCIONALIDADE: ROTATE
 * 
 * Exibe a frase 'Oi 2026' nos displays de 7 segmentos com rotação a cada 200ms.
 * - KEY1 (botão 1): Alterna sentido de rotação (direita <-> esquerda)
 * - KEY2 (botão 2): Pausa/retoma a rotação
 * 
 * DICIONÁRIO (somente registradores usados)
 *
 * r8  -> Acumulador de tempo (contador para delay de 200ms)
 * r9  -> Índice da posição de rotação (0-3 para 4 dígitos)
 * r10 -> Endereço temporário de registradores e tabela HEX
 * r11 -> Base de endereço do hardware (0x10000000)
 * r12 -> Valor lido do EDGE_BUTTON (detecta qual botão foi pressionado)
 * r13 -> Temporário para máscaras e verificações
 * r14 -> Sentido de rotação (1 = direita, -1 = esquerda)
 * r15 -> Flag de pausa (0 = rodando, 1 = pausado)
 * r16 -> Valor codificado para exibição nos displays (4 dígitos HEX)
 * r17 -> Controle de função (0xEA = ativar, 0xAE = desativar)
 * r18 -> Valor temporário para lógica de rotação
 */

.equ DISPLAY, 0x10000020
.equ EDGE_BUTTON, 0x1000005C
.equ TIMER, 0x10001000

/* Tabela com códigos de 7 segmentos para "Oi 2026" */
/* O=0x3F, i=0x06, espaço=0x00, 2=0x5B, 0=0x3F, 2=0x5B, 6=0x6D */
ROTATE_TABLE:
    .byte 0x3F, 0x06, 0x5B, 0x3F    # "Oi20"
    .byte 0x06, 0x5B, 0x3F, 0x06    # "i20i" (rotação 1)
    .byte 0x5B, 0x3F, 0x06, 0x5B    # "20i2" (rotação 2)
    .byte 0x3F, 0x06, 0x5B, 0x3F    # "0i2O" (rotação 3 - volta ao início)

.global COMM_20
.global COMM_21

/*********
RTI - Rotina de Tratamento de Interrupção
*********/
.org 0x20

    # PROLOGO - Salva o endereço de retorno na stack
    addi sp, sp, -4
    stw ra, 0(sp)
    # FIM PROLOGO

    # Lê o registrador de interrupções pendentes
    rdctl et, ipending
    # Se nenhuma interrupção, vai para exceções
    beq et, r0, OTHER_EXCEPTIONS
    # Ajusta o endereço de exceção (subtrai 4)
    subi ea, ea, 4

    # Verifica se é interrupção do botão (bit 1)
    andi r13, et, 2
    # Se não for, vai para outras interrupções
    beq r13, r0, OTHER_INTERRUPTS

    # Chama rotina de interrupção externa (botões)
    call EXT_IRQ1

    FIM_RTI:
        # EPILOGO - Restaura o endereço de retorno
        ldw ra, 0(sp)
        addi sp, sp, 4
        # FIM EPILOGO
    eret

OTHER_INTERRUPTS:
    br FIM_RTI

OTHER_EXCEPTIONS:
    br FIM_RTI

/*********
Rotina de Interrupção Externa - Tratamento de Botões
*********/
EXT_IRQ1:
    # Carrega o endereço do registrador EDGE_BUTTON
    movia r10, EDGE_BUTTON
    # Lê o valor do EDGE_BUTTON (qual botão foi pressionado)
    ldwio r12, (r10)
    # Verifica se é o botão 2 (valor 0b100 = 4)
    movia r13, 0b100
    beq r12, r13, KEY_2_PRESSED

    KEY_1_PRESSED:
        # Alterna o sentido de rotação
        # Se r14 = 1, passa para -1; se r14 = -1, passa para 1
        movi r18, 1
        # Verifica se o sentido é 1
        beq r14, r18, INVERT_TO_NEG
        # Caso contrário, inverte para 1
        movi r14, 1
        br FIM_EXT_IRQ1

        INVERT_TO_NEG:
            # Inverte para -1 (0xFFFFFFFF em complemento de dois)
            movi r14, -1
            br FIM_EXT_IRQ1

    KEY_2_PRESSED:
        # Alterna a flag de pausa
        # Se r15 = 0 (rodando), passa para 1 (pausado)
        # Se r15 = 1 (pausado), passa para 0 (rodando)
        xori r15, r15, 1
        br FIM_EXT_IRQ1

    FIM_EXT_IRQ1:
        # Carrega o endereço do EDGE_BUTTON para limpar a flag
        movia r10, EDGE_BUTTON
        # Escreve 0 no EDGE_BUTTON para limpar a interrupção
        addi r13, r0, 0
        stwio r13, (r10)
        # Retorna da interrupção
        ret

/*********
MAIN - Programa Principal
*********/
.global _start

_start:
    # Configura o stack pointer
    movia sp, 0x007FFFFC

    # PROLOGO - Monta stack frame
    addi sp, sp, -4
    stw fp, 0(sp)
    mov fp, sp
    # FIM PROLOGO

    # Define o endereço base do hardware
    movi r11, 0x10000000

    # Configura os botões para gerar interrupções
    movia r10, 0x10000058
    # Máscara para usar botão 1 e botão 2 (bits 1 e 2 = 0b0110 = 6)
    movia r12, 0b0110
    stwio r12, (r10)

    # Ativa as interrupções do processador
    movia r12, 0b10
    wrctl ienable, r12

    # Ativa o bit de enable global de interrupções (PIE)
    movia r12, 1
    wrctl status, r12

    # Inicializa r8 (contador de tempo) com 0
    addi r8, r0, 0

    # Inicializa r9 (índice de rotação) com 0
    addi r9, r0, 0

    # Inicializa r14 (sentido de rotação) com 1 (rotação para direita)
    movi r14, 1

    # Inicializa r15 (flag de pausa) com 0 (rodando)
    addi r15, r0, 0

    # Inicializa r17 com 0xEA (estado ativo da função)
    movi r17, 0xEA

    br COMM_20

    # ---------------------------------
    # ROTATE - Exibe 'Oi 2026' com rotação
    # ---------------------------------
    COMM_20:
        # Verifica se a rotação está pausada (r15 = 1)
        bne r15, r0, SKIP_ROTATION
        
        # Incrementa o contador de tempo
        addi r8, r8, 1

        # Verifica se atingiu 200ms (ajuste conforme frequência do timer)
        # Valor 200000 = aproximadamente 200ms a 1MHz
        movi r13, 200000
        blt r8, r13, ROTA_LOOP

        # Reset do contador para próximo ciclo de 200ms
        addi r8, r0, 0

        # Incrementa o índice de rotação
        # Primeiro, multiplica o índice de rotação pelo sentido (1 ou -1)
        mul r18, r9, r14

        # Incrementa o resultado
        addi r18, r18, 1

        # Garante que o índice fica entre 0 e 3 (4 posições possíveis)
        andi r18, r18, 0b11

        # Armazena o novo índice de rotação
        mov r9, r18

        # Carrega o endereço base da tabela ROTATE_TABLE
        movia r10, ROTATE_TABLE

        # Adiciona o índice ao endereço base (4 bytes por posição)
        mul r13, r9, 4
        add r10, r10, r13

        # Carrega os 4 bytes da tabela (4 dígitos)
        ldb r16, 0(r10)
        ldb r13, 1(r10)
        slli r13, r13, 8
        or r16, r16, r13
        ldb r13, 2(r10)
        slli r13, r13, 16
        or r16, r16, r13
        ldb r13, 3(r10)
        slli r13, r13, 24
        or r16, r16, r13

        # Carrega o endereço do display
        movia r10, DISPLAY

        # Escreve o valor nos displays de 7 segmentos
        stwio r16, (r10)

        SKIP_ROTATION:
            # Continuação do loop
            br ROTA_LOOP

    ROTA_LOOP:
        # Loop infinito - aguarda interrupções
        br ROTA_LOOP

    # ---------------------------------
    # CANCEL ROTATE
    # ---------------------------------
    COMM_21:
        # Define r17 como 0xAE (estado inativo)
        movi r17, 0xAE
        # Retorna para o loop principal
        br END

END:
    # EPILOGO - Desmonta stack frame
    ldw fp, 0(sp)
    addi sp, sp, 4
    # FIM EPILOGO    

.end