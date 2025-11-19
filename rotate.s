.equ BASE,           0x10000000
.equ HEX_BASE,       0x10000020      # HEX0..HEX3
.equ HEX_BASE_HIGH,  0x10000030      # HEX4..HEX7

.equ TIMER_STATUS,   0x2000
.equ TIMER_CONTROL,  0x2004
.equ TIMER_LOW,      0x2008
.equ TIMER_HIGH,     0x200C

.global COMM_20
.global COMM_21

###########################################################
# MAIN: chama COMM_20
###########################################################
_start:
    movia sp, 0x007FFFFC

###########################################################
# COMM_20 — hardcoded rotation
###########################################################
COMM_20:
    # PROLOGO
    addi sp, sp, -8
    stw  fp, 0(sp)
    stw  ra, 4(sp)
    mov  fp, sp

    movia r11, BASE

    ###########################################################
    # CONFIG TIMER — 200ms (ou 4s se quiser trocar LOW/HIGH)
    ###########################################################
    movia r8, 0x9680     # 200ms LOW
    stwio r8, TIMER_LOW(r11)

    movia r8, 0x0098     # 200ms HIGH
    stwio r8, TIMER_HIGH(r11)

    movi r8, 0b110       # start + continuous
    stwio r8, TIMER_CONTROL(r11)

    movi r10, 0          # estado atual (0..3)

ROT_LOOP:

WAIT_TIMER:
    ldwio r8, TIMER_STATUS(r11)
    andi  r9, r8, 1
    beq   r9, r0, WAIT_TIMER

    stwio r0, TIMER_STATUS(r11)   # clear TO


    ###########################################################
    # ESTADOS HARD-CODED
    ###########################################################

    STATE:
        beq r10, r0, DO_STATE0      # 0
        movi r8, 1
        beq r10, r8, DO_STATE1      # 1
        movi r8, 2
        beq r10, r8, DO_STATE2      # 2
        movi r8, 3
        beq r10, r8, DO_STATE3      # 3
        movi r8, 4
        beq r10, r8, DO_STATE4      # 4
        movi r8, 5
        beq r10, r8, DO_STATE5      # 5
        movi r8, 6
        beq r10, r8, DO_STATE6      # 6
        br  DO_STATE7               # 7

    # 3f - 0
    # 06 - 1
    # 5b - 2
    # 7d - 6

    DO_STATE0:
        movia r14, 0x5B3F5B7D   # HEX0..HEX3
        movia r15, 0x003F0600   # HEX4..HEX7
        br WRITE_HEX

    DO_STATE1:
        movia r14, 0x3F5B7D00   # HEX0..HEX3
        movia r15, 0x3F06005B   # HEX4..HEX7
        br WRITE_HEX

    DO_STATE2:
        movia r14, 0x5B7D003F   # HEX0..HEX3
        movia r15, 0x06005B3F   # HEX4..HEX7
        br WRITE_HEX

    DO_STATE3:
        movia r14, 0x7D003F06   # HEX0..HEX3
        movia r15, 0x005B3F5B   # HEX4..HEX7
        br WRITE_HEX

    DO_STATE4:
        movia r14, 0x003F0600   # HEX0..HEX3
        movia r15, 0x5B3F5B7D   # HEX4..HEX7
        br WRITE_HEX

    DO_STATE5:
        movia r14, 0x3F06005B   # HEX0..HEX3
        movia r15, 0x3F5B7D00   # HEX4..HEX7
        br WRITE_HEX

    DO_STATE6:
        movia r14, 0x06005B3F   # HEX0..HEX3
        movia r15, 0x5B7D003F   # HEX4..HEX7
        br WRITE_HEX

    DO_STATE7:
        movia r14, 0x005B3F5B   # HEX0..HEX3
        movia r15, 0x7D003F06   # HEX4..HEX7
        br WRITE_HEX


###########################################################
# ESCREVER NOS DISPLAYS
###########################################################
WRITE_HEX:
    movia r4, HEX_BASE
    stwio r14, 0(r4)        # HEX0..HEX3
    stwio r15, 16(r4)       # HEX4..HEX7


###########################################################
# PRÓXIMO ESTADO
###########################################################
    # incrementa estado
    addi r10, r10, 1

    # compara r10 >= 8
    movi r8, 8
    bge  r10, r8, RESET_STATE

    br ROT_LOOP

    RESET_STATE:
        movi r10, 0
        br ROT_LOOP


    movi r10, 0
    br ROT_LOOP


    # EPILOGO
    ldw ra, 4(sp)
    ldw fp, 0(sp)
    addi sp, sp, 8
    ret



###########################################################
# COMM_21 — sem função
###########################################################
COMM_21:
    addi sp, sp, -8
    stw fp, 0(sp)
    stw ra, 4(sp)
    mov fp, sp

    # vazio

    ldw ra, 4(sp)
    ldw fp, 0(sp)
    addi sp, sp, 8
    ret
