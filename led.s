/**
 * led.s
 *
 * Rotinas para controle dos LEDs
 *      COMM_00: Acende o xx-ésimo led vermelho
 *      COMM_01: Apaga o xx-ésimo led vermelho
 */

.equ RED_LEDS, 0x10000000

.global COMM_00
.global COMM_01

_start:
    movia sp, 0x007FFFFC

    # PROLOGO (montar stack frame)
    addi sp, sp, -4
    stw fp, 0(sp)
    mov fp, sp
    # FIM PROLOGO

    movi r11, 0x10000000

    # ---------------------------------
    # ACENDER XX-ÉSIMO LED VERMELHO
    # ---------------------------------
    COMM_00:
        addi    sp, sp, -20          # Reserva 20 bytes na pilha (salvar r4..r8)
        stw     r4, 0(sp)
        stw     r5, 4(sp)
        stw     r6, 8(sp)
        stw     r7, 12(sp)
        stw     r8, 16(sp)

        andi    r5, r12, 0xFF        # r5 = último byte (caractere menos significativo)
        srli    r6, r12, 8           # r6 = r12 >> 8 (agora contém o 2º último byte + mais)
        andi    r6, r6, 0xFF         # r6 = segundo último byte (apenas 8 LSB)

        addi    r5, r5, -48          # r5 = low_digit_value = low_char - '0'
        addi    r6, r6, -48          # r6 = high_digit_value = high_char - '0'

        slli    r7, r6, 3            # r7 = high * 8  (parte para calcular high*10)
        slli    r8, r6, 1            # r8 = high * 2  (outra parte)
        add     r4, r7, r8           # r4 = high * 10
        add     r4, r4, r5           # r4 = high*10 + low  => r4 = num

        addi    r5, r0, 9            # r5 = 9 (limite máximo de índice de LED; ajuste se necessário)
        bgt     r4, r5, COMM00_SET9  # se num > 9, pular para ajustar para 9
        br      COMM00_CONTINUE      # senão continuar

    COMM00_SET9:
        addi    r4, r0, 9            # força r4 = 9 (limita índice)

    COMM00_CONTINUE:
        movi    r7, 1                # r7 = máscara inicial = 1
        beq     r4, r0, COMM00_MASK_DONE # se num == 0, máscara já é 1, pular laço

        movi    r8, 0                # r8 = contador i = 0
    COMM00_MASK_LOOP:
        add     r7, r7, r7           # r7 *= 2  (deslocamento à esquerda por multiplicação por 2)
        addi    r8, r8, 1            # r8++
        blt     r8, r4, COMM00_MASK_LOOP # repetir enquanto r8 < num

    COMM00_MASK_DONE:
        movia   r9, RED_LEDS         # r9 = endereço base dos LEDs
        ldwio   r10, (r9)            # r10 = valor atual do registrador de LEDs
        or      r10, r10, r7         # r10 = r10 | mask  (liga o bit correspondente)
        stwio   r10, (r9)            # gravar de volta o novo valor dos LEDs

        ldw     r4, 0(sp)
        ldw     r5, 4(sp)
        ldw     r6, 8(sp)
        ldw     r7, 12(sp)
        ldw     r8, 16(sp)
        addi    sp, sp, 20           # liberar espaço da pilha

        ret                          # retornar ao chamador (main)

    # ---------------------------------
    # APAGAR XX-ÉSIMO LED VERMELHO
    # ---------------------------------
    COMM_01:
        addi    sp, sp, -20          # Reserva 20 bytes na pilha (salvar r4..r8)
        stw     r4, 0(sp)
        stw     r5, 4(sp)
        stw     r6, 8(sp)
        stw     r7, 12(sp)
        stw     r8, 16(sp)

        andi    r5, r12, 0xFF        # r5 = último byte (caractere menos significativo)
        srli    r6, r12, 8           # r6 = r12 >> 8 (agora contém o 2º último byte + mais)
        andi    r6, r6, 0xFF         # r6 = segundo último byte (apenas 8 LSB)

        addi    r5, r5, -48          # r5 = low_digit_value = low_char - '0'
        addi    r6, r6, -48          # r6 = high_digit_value = high_char - '0'

        slli    r7, r6, 3            # r7 = high * 8  (parte para calcular high*10)
        slli    r8, r6, 1            # r8 = high * 2  (outra parte)
        add     r4, r7, r8           # r4 = high * 10
        add     r4, r4, r5           # r4 = high*10 + low  => r4 = num

        addi    r5, r0, 9            # r5 = 9 (limite máximo de índice de LED; ajuste se necessário)
        bgt     r4, r5, COMM01_SET9  # se num > 9, pular para ajustar para 9

        br      COMM01_CONTINUE      # senão continuar

    COMM01_SET9:
        addi    r4, r0, 9            # força r4 = 9 (limita índice)

    COMM01_CONTINUE:
        movi    r7, 1                # r7 = máscara inicial = 1
        beq     r4, r0, COMM01_MASK_DONE # se num == 0, máscara já é 1, pular laço

        movi    r8, 0                # r8 = contador i = 0
    COMM01_MASK_LOOP:
        add     r7, r7, r7           # r7 *= 2  (deslocamento à esquerda por multiplicação por 2)
        addi    r8, r8, 1            # r8++
        blt     r8, r4, COMM01_MASK_LOOP # repetir enquanto r8 < num

    COMM01_MASK_DONE:
        not     r7, r7               # r7 = ~mask  (máscara invertida para limpar bit)
        movia   r9, RED_LEDS         # r9 = endereço base dos LEDs
        ldwio   r10, (r9)            # r10 = valor atual do registrador de LEDs
        and     r10, r10, r7         # r10 = r10 & ~mask  (limpa o bit correspondente)
        stwio   r10, (r9)            # gravar de volta o novo valor dos LEDs

        ldw     r4, 0(sp)
        ldw     r5, 4(sp)
        ldw     r6, 8(sp)
        ldw     r7, 12(sp)
        ldw     r8, 16(sp)
        addi    sp, sp, 20           # liberar espaço da pilha

        ret                          # retornar ao chamador (main)

END:
    # EPILOGO (desmontar stack frame)
    ldw fp, 0(sp)
    addi sp, sp, 4
    # FIM EPILOGO    

.end