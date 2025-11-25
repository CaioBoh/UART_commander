.equ BASE,           0x10000000
.equ HEX_BASE,       0x10000020      # HEX0..HEX3
.equ HEX_BASE_HIGH,  0x10000030      # HEX4..HEX7

.equ TIMER_STATUS,   0x2000
.equ TIMER_CONTROL,  0x2004
.equ TIMER_LOW,      0x2008
.equ TIMER_HIGH,     0x200C

.equ KEYS_BASE,      0x10000050      # Endereço base dos botões
.equ KEYS_EDGE,      0x1000005C      # Edge capture (offset 0xC)
.equ KEYS_MASK,      0x10000058      # Interrupt mask (offset 0x8)

# Variáveis globais
.data
.align 2
current_state: .word 0
is_frozen:     .word 0               # 0 = rodando, 1 = congelado
direction:     .word 1               # 1 = normal, -1 = invertido

.text
.global COMM_20
.global COMM_21
.global timer_isr
.global keys_isr

# COMM_20 — hardcoded rotation COM INTERRUPÇÃO
COMM_20:
    # PROLOGO
    addi sp, sp, -8
    stw  fp, 0(sp)
    stw  ra, 4(sp)
    mov  fp, sp

    movia r11, BASE

    # IMPORTANTE: Para o timer antes de reconfigurar
    stwio r0, TIMER_CONTROL(r11)
    
    # Limpa o bit TO que pode estar setado
    stwio r0, TIMER_STATUS(r11)

    # Reseta variáveis de controle
    movia r8, current_state
    stw r0, 0(r8)
    
    movia r8, is_frozen
    stw r0, 0(r8)                # Inicia descongelado
    
    movia r8, direction
    movi r9, 1
    stw r9, 0(r8)                # Inicia direção normal

    # CONFIG BOTÕES (KEY1 e KEY2)
    movia r8, KEYS_EDGE
    movi r9, 0b110               # KEY2 (bit 1) e KEY1 (bit 2)
    stwio r9, 0(r8)              # Limpa edge capture
    
    movia r8, KEYS_MASK
    stwio r9, 0(r8)              # Habilita interrupção para KEY1 e KEY2

    # CONFIG TIMER — 200ms
    movia r8, 0x9680     # 200ms LOW
    stwio r8, TIMER_LOW(r11)

    movia r8, 0x0098     # 200ms HIGH
    stwio r8, TIMER_HIGH(r11)

    movi r8, 0b111       # start + continuous + ITO (interrupção habilitada)
    stwio r8, TIMER_CONTROL(r11)

    # Habilitar interrupções no ienable (IRQ 0 = timer, IRQ 1 = botões)
    movi r8, 0b11        # Bits 0 e 1
    wrctl ienable, r8

    # Habilitar interrupções globais (PIE bit no status)
    # Lê o status atual e seta o bit PIE (bit 0)
    rdctl r8, status
    ori r8, r8, 0b1
    wrctl status, r8

    # EPILOGO - retorna ao menu! A ISR cuida do resto
    ldw ra, 4(sp)
    ldw fp, 0(sp)
    addi sp, sp, 8
    ret

# ISR DO TIMER
timer_isr:
    # Salva contexto - IMPORTANTE: salvar registradores usados pelo main!
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

    # Verifica se está congelado
    movia r8, is_frozen
    ldw r9, 0(r8)
    bne r9, r0, ISR_EXIT_FROZEN  # Se congelado, sai sem atualizar

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

    # Atualiza estado baseado na direção
    movia r8, direction
    ldw r9, 0(r8)
    add r10, r10, r9             # r10 += direction (1 ou -1)
    
    # Verifica limites (0 a 7)
    blt r10, r0, ISR_WRAP_TO_7   # Se < 0, vai para 7
    movi r9, 8
    bge r10, r9, ISR_WRAP_TO_0   # Se >= 8, vai para 0
    br ISR_SAVE_STATE

ISR_WRAP_TO_7:
    movi r10, 7
    br ISR_SAVE_STATE

ISR_WRAP_TO_0:
    movi r10, 0

ISR_SAVE_STATE:
    movia r8, current_state
    stw r10, 0(r8)

ISR_EXIT_FROZEN:

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

# ISR DOS BOTÕES - KEY1 inverte direção, KEY2 congela
keys_isr:
    # Salva contexto
    subi sp, sp, 16
    stw r8, 0(sp)
    stw r9, 4(sp)
    stw r10, 8(sp)
    stw r11, 12(sp)

    # Lê qual botão foi pressionado
    movia r11, KEYS_EDGE
    ldwio r10, 0(r11)
    
    # Limpa o edge capture (ACK da interrupção)
    stwio r10, 0(r11)

    # Verifica se foi KEY2 (bit 1)
    andi r8, r10, 0b10
    bne r8, r0, HANDLE_KEY2

    # Verifica se foi KEY1 (bit 2)
    andi r8, r10, 0b100
    bne r8, r0, HANDLE_KEY1
    
    br KEYS_ISR_EXIT

HANDLE_KEY1:
    # Toggle do estado congelado
    movia r8, is_frozen
    ldw r9, 0(r8)
    xori r9, r9, 1               # Inverte: 0→1, 1→0
    stw r9, 0(r8)
    br KEYS_ISR_EXIT

HANDLE_KEY2:
    # Inverte a direção (multiplica por -1 usando subtração)
    movia r8, direction
    ldw r9, 0(r8)
    sub r9, r0, r9               # r9 = 0 - r9 (inverte sinal: 1→-1, -1→1)
    stw r9, 0(r8)
    br KEYS_ISR_EXIT

KEYS_ISR_EXIT:
    # Restaura contexto
    ldw r8, 0(sp)
    ldw r9, 4(sp)
    ldw r10, 8(sp)
    ldw r11, 12(sp)
    addi sp, sp, 16

    eret

# COMM_21 — Para a rotação
COMM_21:
    addi sp, sp, -8
    stw fp, 0(sp)
    stw ra, 4(sp)
    mov fp, sp

    movia r11, BASE

    # Para o timer (escreve 0 no TIMER_CONTROL)
    stwio r0, TIMER_CONTROL(r11)
    
    # Limpa o bit TO do timer
    stwio r0, TIMER_STATUS(r11)
    
    # Desabilita interrupções dos botões
    movia r8, KEYS_MASK
    stwio r0, 0(r8)              # Desabilita interrupt mask
    
    movia r8, KEYS_EDGE
    movi r9, 0xFF
    stwio r9, 0(r8)              # Limpa edge capture

    # Desabilita interrupções globais no ienable
    wrctl ienable, r0

    # Limpa os displays
    movia r9, HEX_BASE
    stwio r0, 0(r9)
    stwio r0, 16(r9)

    # Reseta variáveis
    movia r8, current_state
    stw r0, 0(r8)
    
    movia r8, is_frozen
    stw r0, 0(r8)
    
    movia r8, direction
    movi r9, 1
    stw r9, 0(r8)

    ldw ra, 4(sp)
    ldw fp, 0(sp)
    addi sp, sp, 8
    ret
