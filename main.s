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
 * r8   -> r
 * r9   -> dado
 * r10  -> w
 * r11  -> base
 * 
 * TEMPORARIOS
 *
 * r13  -> RVALID / WSPACE
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

    movi r11, 0x10000000

    # ---------------------------------
    # IMPRIMIR A MENSAGEM DE PROMPT
    # ---------------------------------
    movia   r8, MSG_PROMPT          # endereço da string
    PRINT_MSG:
        ldb     r9, 0(r8)               # lê um byte
        beq     r9, r0, RVALID_LOOP     # se for '\0', sai
    WAIT_WSPACE:
        ldwio   r10, CONTROL(r11)
        andi    r13, r10, 0xFFFF        # checa espaço p/ escrever
        beq     r13, r0, WAIT_WSPACE
        stwio   r9, DATA(r11)           # escreve caractere
        addi    r8, r8, 1
        br      PRINT_MSG

    # ---------------------------------
    # LOOP DE LEITURA ORIGINAL
    # ---------------------------------
    RVALID_LOOP:
        ldwio       r8, DATA(r11)
        andi        r13, r8, 0x8000        # Aplica máscara para pegar RVALID
        beq         r13, r0, RVALID_LOOP
        andi        r9, r8, 0xFF


    WSPACE_LOOP:
        ldwio       r10, CONTROL(r11)
        andi        r13, r8, 0xFF00        # Aplica máscara para pegar WSPACE
        beq         r13, r0, WSPACE_LOOP
        stwio       r9, DATA(r11)

    br RVALID_LOOP                         # Polling

END:
    # EPILOGO (desmontar stack frame)
    ldw fp, 0(sp)
    addi sp, sp, 4
    # FIM EPILOGO    

.data
MSG_PROMPT:
.asciz "\nEntre com o comando:\n> "

.end
