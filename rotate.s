.equ BASE,           0x10000000
.equ HEX_BASE,       0x10000020      # HEX0..HEX3
.equ HEX_BASE_HIGH,  0x10000030      # HEX4..HEX7

.equ TIMER_STATUS,   0x2000
.equ TIMER_CONTROL,  0x2004
.equ TIMER_LOW,      0x2008
.equ TIMER_HIGH,     0x200C

# Variável global para o estado
.data
.align 2
current_state: .word 0

.text
.global COMM_20
.global COMM_21
.global timer_isr

COMM_20:
    # PROLOGO
    addi sp, sp, -8
    stw  fp, 0(sp)
    stw  ra, 4(sp)
    mov  fp, sp

    movia r11, BASE

    stwio r0, TIMER_CONTROL(r11)        # Para o timer antes de reconfigurar
    stwio r0, TIMER_STATUS(r11)         # Limpa o bit TO que pode estar setado

    movia r8, current_state             # Reseta o estado para começar do zero
    stw r0, 0(r8)

    # CONFIG TIMER — 200ms
    movia r8, 0x9680                    # 200ms LOW
    stwio r8, TIMER_LOW(r11)

    movia r8, 0x0098                    # 200ms HIGH
    stwio r8, TIMER_HIGH(r11)

    movi r8, 0b111
    stwio r8, TIMER_CONTROL(r11)

    # Habilitar interrupções do timer
    movi r8, 0b1
    wrctl ienable, r8

    # Habilitar interrupções globais
    rdctl r8, status
    ori r8, r8, 0b1
    wrctl status, r8

    # EPILOGO
    ldw ra, 4(sp)
    ldw fp, 0(sp)
    addi sp, sp, 8
    ret

timer_isr:
    # Salva contexto
    subi sp, sp, 32
    stw r8, 0(sp)
    stw r9, 4(sp)
    stw r10, 8(sp)
    stw r11, 12(sp)
    stw r12, 16(sp)
    stw r13, 20(sp)
    stw r14, 24(sp)
    stw r15, 28(sp)

    # Limpa o bit TO no TIMER_STATUS
    movia r11, BASE
    stwio r0, TIMER_STATUS(r11)

    # Carrega o estado atual
    movia r8, current_state
    ldw r10, 0(r8)

    # ESTADOS HARD-CODED
    beq r10, r0, ISR_STATE0
    movi r9, 1
    beq r10, r9, ISR_STATE1
    movi r9, 2
    beq r10, r9, ISR_STATE2
    movi r9, 3
    beq r10, r9, ISR_STATE3
    movi r9, 4
    beq r10, r9, ISR_STATE4
    movi r9, 5
    beq r10, r9, ISR_STATE5
    movi r9, 6
    beq r10, r9, ISR_STATE6
    br ISR_STATE7

ISR_STATE0:
    movia r14, 0x5B3F5B7D
    movia r15, 0x003F0600
    br ISR_WRITE_HEX

ISR_STATE1:
    movia r14, 0x3F5B7D00
    movia r15, 0x3F06005B
    br ISR_WRITE_HEX

ISR_STATE2:
    movia r14, 0x5B7D003F
    movia r15, 0x06005B3F
    br ISR_WRITE_HEX

ISR_STATE3:
    movia r14, 0x7D003F06
    movia r15, 0x005B3F5B
    br ISR_WRITE_HEX

ISR_STATE4:
    movia r14, 0x003F0600
    movia r15, 0x5B3F5B7D
    br ISR_WRITE_HEX

ISR_STATE5:
    movia r14, 0x3F06005B
    movia r15, 0x3F5B7D00
    br ISR_WRITE_HEX

ISR_STATE6:
    movia r14, 0x06005B3F
    movia r15, 0x5B7D003F
    br ISR_WRITE_HEX

ISR_STATE7:
    movia r14, 0x005B3F5B
    movia r15, 0x7D003F06
    br ISR_WRITE_HEX

ISR_WRITE_HEX:
    # Escreve nos displays
    movia r9, HEX_BASE
    stwio r14, 0(r9)
    stwio r15, 16(r9)

    # Incrementa estado
    addi r10, r10, 1
    movi r9, 8
    blt r10, r9, ISR_SAVE_STATE

    movi r10, 0                 # Reset para estado 0

ISR_SAVE_STATE:
    movia r8, current_state
    stw r10, 0(r8)

    # Restaura contexto
    ldw r8, 0(sp)
    ldw r9, 4(sp)
    ldw r10, 8(sp)
    ldw r11, 12(sp)
    ldw r12, 16(sp)
    ldw r13, 20(sp)
    ldw r14, 24(sp)
    ldw r15, 28(sp)
    addi sp, sp, 32

    eret

COMM_21:
    addi sp, sp, -8
    stw fp, 0(sp)
    stw ra, 4(sp)
    mov fp, sp

    movia r11, BASE

    stwio r0, TIMER_CONTROL(r11)        # Para o timer
    stwio r0, TIMER_STATUS(r11)         # Limpa do timer
    wrctl ienable, r0                   # Desabilita interrupções do timer no ienable

    # Limpa os displays
    movia r9, HEX_BASE
    stwio r0, 0(r9)
    stwio r0, 16(r9)

    # Reseta o estado
    movia r8, current_state
    stw r0, 0(r8)

    ldw ra, 4(sp)
    ldw fp, 0(sp)
    addi sp, sp, 8
    ret