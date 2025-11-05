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

_start:
    movia sp, 0x007FFFFC

    # PROLOGO (montar stack frame)
    addi sp, sp, -4
    stw fp, 0(sp)
    mov fp, sp
    # FIM PROLOGO

    # Define o endereço base (escrita da base + offset)
    movi r11, 0x10000000

    # ---------------------------------
    # IMPRIMIR A MENSAGEM DE PROMPT
    # ---------------------------------
    movia   r8, MSG_PROMPT              # endereço da string

    # Mostra a mensagem inicial
    PRINT_MSG:
        ldb     r9, 0(r8)               # lê um byte
        beq     r9, r0, RVALID_LOOP     # se for '\0', sai
    
    # Lê cada caractere e escreve no prompt
    WAIT_WSPACE:
        ldwio   r10, CONTROL(r11)
        andi    r13, r10, 0xFFFF        # checa espaço p/ escrever
        beq     r13, r0, WAIT_WSPACE    # Se retornar true, não tem espaço no buffer
        stwio   r9, DATA(r11)           # escreve caractere
        addi    r8, r8, 1
        br      PRINT_MSG

    # ---------------------------------
    # LOOP DE LEITURA ORIGINAL
    # ---------------------------------
    RVALID_LOOP:
        ldwio       r8, DATA(r11)           # Armazena DATA da UART
        andi        r13, r8, 0x8000         # Aplica máscara para pegar RVALID
        beq         r13, r0, RVALID_LOOP    # Enquanto não estiver válido, volta para RVALID_LOOP
        andi        r9, r8, 0xFF            # Aplica máscara para pegar 8 bits (DATA da UART)

    WSPACE_LOOP:
        ldwio       r10, CONTROL(r11)       # Armazena CONTROL da UART
        andi        r13, r10, 0xFF00        # Aplica máscara para pegar WSPACE
        beq         r13, r0, WSPACE_LOOP    # Enquanto não tiver WSPACE, volta para WSPACE_LOOP
        stwio       r9, DATA(r11)           # Escreve o caractere dentro do DATA
        andi        r13, r9, 0xF            # Aplica máscara com o caractere '\n' (ENTER)
        movi        r14, 0x0A
        beq         r13, r14, READ_COMMAND  # Inicia a rotina de leitura de comando no prompt
        slli        r12, r12, 8             # Deslocando BUFFER 8 bits para à esquerda (xxxxxxxx xxxxxxxx xxxxxxxx 00000000) para (xxxxxxxx xxxxxxxx 00000000 xxxxxxxx)
        add         r12, r12, r9            # Escreve o caractere dentro do BUFFER
    
    /**
     * Criar o buffer [OK]
     * Ajustar rotina para
     *  - Ler dígito [OK]
     *  - Armazenar no buffer [OK]
     *  - Deslocar o buffer 8 bits para esquerda [OK]
     */

    br RVALID_LOOP                         # Polling

    # ---------------------------------
    # LEITURA DO ENTER NO PROMPT
    # ---------------------------------
    READ_COMMAND:
        movi    r14, 0x30300000             # '00'
        andi    r13, r12, 0xFFFF0000
        beq     r13, r14, COMM_00

        movi    r14, 0x30310000             # '01'
        beq     r13, r14, COMM_01

        movi    r14, 0x3130                 # '10'
        andi    r13, r12, 0x0000FFFF
        beq     r13, r14, COMM_10

        movi    r14, 0x3230                 # '20'
        beq     r13, r14, COMM_20

        movi    r14, 0x3231                 # '21'
        beq     r13, r14, COMM_21

        br RVALID_LOOP

    /**
     * Polling para aguardar a tecla enter [OK]
     * armazena tudo que foi escrito em um buffer [OK]
     * Recebeu enter: sai do polling e le buffer []
     * Leu o comando []
     * Executa o comando [PENDING]
     */


END:
    # EPILOGO (desmontar stack frame)
    ldw fp, 0(sp)
    addi sp, sp, 4
    # FIM EPILOGO    

.data
MSG_PROMPT:
    .asciz "\nEntre com o comando:\n> "

.end