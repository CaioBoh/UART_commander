/*
 * while(true)
 *      print 'Entre com o comando:'
 *      
 *      Com <- getCommand()
 *      
 *      swutch(Com)
 *      
 *      case '0': call LED()
 *      case '1': call TRIANG()
 *      case '2': call ROTACAO()
 */

/**
 * DICIONARIO
 * 
 * r8   -> DATA da UART
 * r9   -> Caractere do prompt (dado)
 * r10  -> CONTROL da UART
 * r11  -> Base de endereço
 * r12  -> Buffer de caracteres lidos
 * 
 * 
 * TEMPORARIOS
 *
 * r13  -> RVALID / WSPACE
 * r14  -> Armazenar valores
 */

.equ DATA, 0x1000
.equ CONTROL, 0x1004

.global _start

# EXCEPTION HANDLER
.org 0x20

    # Salva contexto - NÃO pode corromper registradores do main!
    subi sp, sp, 12
    stw ea, 0(sp)
    stw et, 4(sp)
    stw ra, 8(sp)

    rdctl et, ipending
    beq et, r0, OTHER_EXCEPTIONS
    subi ea, ea, 4

    # Verifica se é IRQ 0 (timer)
    andi ra, et, 1
    bne ra, r0, EXT_IRQ0
    
    # Verifica se é IRQ 1 (botões)
    andi ra, et, 2
    bne ra, r0, EXT_IRQ1

    br FIM_RTI

EXT_IRQ0:
    # Chama ISR do timer
    call timer_isr
    br FIM_RTI

EXT_IRQ1:
    # Chama ISR dos botões
    call keys_isr
    br FIM_RTI

OTHER_EXCEPTIONS:
    br FIM_RTI

FIM_RTI:
    # Restaura contexto
    ldw ra, 8(sp)
    ldw et, 4(sp)
    ldw ea, 0(sp)
    addi sp, sp, 12
    eret

# MAIN CODE
_start:
    movia sp, 0x007FFFFC

    # PROLOGO (montar stack frame)
    addi sp, sp, -4
    stw fp, 0(sp)
    mov fp, sp
    # FIM PROLOGO

    # Define o endereço base (escrita da base + offset)
    movi r11, 0x10000000

    # IMPRIMIR A MENSAGEM DE PROMPT
    movia   r8, MSG_PROMPT                  # endereço da string

    # Mostra a mensagem inicial
    PRINT_MSG:
        ldb     r9, 0(r8)                   # lê um byte
        beq     r9, r0, RVALID_LOOP         # se for '\0', sai
    
    # Lê cada caractere e escreve no prompt
    WAIT_WSPACE:
        ldwio   r10, CONTROL(r11)
        andi    r13, r10, 0xFFFF            # checa espaço p/ escrever
        beq     r13, r0, WAIT_WSPACE        # Se retornar true, não tem espaço no buffer
        stwio   r9, DATA(r11)               # escreve caractere
        addi    r8, r8, 1
        br      PRINT_MSG

    # LOOP DE LEITURA ORIGINAL
    RVALID_LOOP:
        ldwio       r8, DATA(r11)           # Armazena DATA da UART
        andi        r13, r8, 0x8000         # Aplica máscara para pegar RVALID
        beq         r13, r0, RVALID_LOOP    # Enquanto não estiver válido, volta para RVALID_LOOP
        andi        r9, r8, 0xFF            # Aplica máscara para pegar 8 bits (DATA da UART)

    WSPACE_LOOP:
        ldwio       r10, CONTROL(r11)       # Armazena CONTROL da UART
        andi        r13, r10, 0xFF00        # Aplica máscara para pegar WSPACE
        beq         r13, r0, WSPACE_LOOP    # Enquanto não tiver WSPACE, volta para WSPACE_LOOP
        stwio       r9, DATA(r11)           # Escreve o caractere dentro do DATA (echo)
        movi        r14, 0x0D               # '\r' (carriage return)
        beq         r9, r14, READ_COMMAND   # Se for Enter, processa comando
        movi        r14, 0x0A               # '\n' (line feed)
        beq         r9, r14, READ_COMMAND   # Se for Enter, processa comando
        slli        r12, r12, 8             # Deslocando BUFFER 8 bits para à esquerda
        add         r12, r12, r9            # Escreve o caractere dentro do BUFFER
    
    br RVALID_LOOP                         # Polling

    # LEITURA DO ENTER NO PROMPT
    READ_COMMAND:
        movi    r14, 0x30300000             # '00'
        andi    r13, r12, 0xFFFF0000
        beq     r13, r14, CALL_COMM_00

        movi    r14, 0x30310000             # '01'
        beq     r13, r14, CALL_COMM_01

        movi    r14, 0x3130                 # '10'
        andi    r13, r12, 0x0000FFFF
        beq     r13, r14, CALL_COMM_10

        movi    r14, 0x3230                 # '20'
        beq     r13, r14, CALL_COMM_20

        movi    r14, 0x3231                 # '21'
        beq     r13, r14, CALL_COMM_21

        movi    r12, 0                      # Comando inválido - limpa buffer
        br RVALID_LOOP

    CALL_COMM_00:
        call COMM_00
        movi r12, 0
        br REPRINT_PROMPT

    CALL_COMM_01:
        call COMM_01
        movi r12, 0
        br REPRINT_PROMPT

    CALL_COMM_10:
        call COMM_10
        movi r12, 0
        br REPRINT_PROMPT

    CALL_COMM_20:
        call COMM_20
        movi r12, 0
        br REPRINT_PROMPT

    CALL_COMM_21:
        call COMM_21
        movi r12, 0
        br REPRINT_PROMPT

    REPRINT_PROMPT:
        # Recarrega o endereço da mensagem de prompt
        movia r8, MSG_PROMPT
        br PRINT_MSG

END:
    # EPILOGO (desmontar stack frame)
    ldw fp, 0(sp)
    addi sp, sp, 4
    # FIM EPILOGO    

.data
MSG_PROMPT:
    .asciz "\nEntre com o comando:\n> "

.end
