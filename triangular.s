/**
 * DICIONÁRIO (somente registradores usados)
 *
 * r4  -> Endereço dos switches OU endereço da tabela HEX
 * r5  -> Valor lido dos switches (0–255) e depois valor TRIANGULAR
 * r6  -> Centenas (0–9)
 * r7  -> Dezenas  (0–9)
 * r8  -> Milhares (0–9)
 * r9  -> Dezena de milhar (0–9)
 * r14 -> Unidades (0–9)
 * r15 -> Temporário para subtrações sucessivas e montagem final do valor dos displays
 */

.equ SWITCHES,   0x10000040
.equ HEX_BASE,   0x10000020

.global COMM_10

_start:
    movia sp, 0x007FFFFC

    # PROLOGO (montar stack frame)
    addi sp, sp, -4
    stw fp, 0(sp)
    mov fp, sp
    # FIM PROLOGO

    movi r11, 0x10000000

    # ---------------------------------
    # TRIAGULAR
    # ---------------------------------
        COMM_10:
            # -------------------------------------------------
            # 1. Ler valor dos switches (0–255)
            # -------------------------------------------------
            movia r4, SWITCHES
            ldwio r5, 0(r4)
            andi r5, r5, 0xFF      # r5 = N

            # -------------------------------------------------
            # 2. Calcular número triangular T(N) = 1+2+...+N
            # -------------------------------------------------
            mov r6, r0            # acumulador
            mov r7, r0            # contador i

        tri_loop_comm:
            beq r5, r0, tri_done_comm
            addi r7, r7, 1
            add r6, r6, r7
            addi r5, r5, -1
            br tri_loop_comm

        tri_done_comm:
            mov r5, r6            # r5 = T(N)

            # -------------------------------------------------
            # 3. Converter r5 em decimal (dezenaMilhar/milhares/centenas/dezenas/unidades)
            # -------------------------------------------------
            mov r9, r0            # dezena de milhar
            mov r8, r0            # milhares
            mov r6, r0            # centenas
            mov r7, r0            # dezenas
            mov r14, r0           # unidades

        dezmil_loop_comm:
            addi r15, r5, -10000
            blt r15, r0, mil_loop_comm
            mov r5, r15
            addi r9, r9, 1
            br dezmil_loop_comm

        mil_loop_comm:
            addi r15, r5, -1000
            blt r15, r0, cent_loop_comm
            mov r5, r15
            addi r8, r8, 1
            br mil_loop_comm

        cent_loop_comm:
            addi r15, r5, -100
            blt r15, r0, dez_loop_comm
            mov r5, r15
            addi r6, r6, 1
            br cent_loop_comm

        dez_loop_comm:
            addi r15, r5, -10
            blt r15, r0, uni_set_comm
            mov r5, r15
            addi r7, r7, 1
            br dez_loop_comm

        uni_set_comm:
            mov r14, r5

            # -------------------------------------------------
            # 4. Converter dígitos para tabela 7 segmentos
            # -------------------------------------------------
            movia r4, HEX_TABLE
            add r15, r4, r14
            ldb r14, 0(r15)    # unidades
            add r15, r4, r7
            ldb r7, 0(r15)     # dezenas
            add r15, r4, r6
            ldb r6, 0(r15)     # centenas
            add r15, r4, r8
            ldb r8, 0(r15)     # milhares
            add r15, r4, r9
            ldb r9, 0(r15)     # dezena de milhar

            # -------------------------------------------------
            # 5. Enviar aos displays HEX0–HEX4
            # -------------------------------------------------
            movia r4, HEX_BASE

            mov r15, r14          # unidades no byte 0
            slli r7, r7, 8
            or r15, r15, r7       # dezenas no byte 1
            slli r6, r6, 16
            or r15, r15, r6       # centenas no byte 2
            slli r8, r8, 24
            or r15, r15, r8       # milhares no byte 3   
            stwio r15, 0(r4)

            # HEX4
            movia r4, HEX_BASE
            addi r4, r4, 4         # HEX4
            stwio r9, 0(r4)        # dezena de milhar
            
            ret

END:
    # EPILOGO (desmontar stack frame)
    ldw fp, 0(sp)
    addi sp, sp, 4
    # FIM EPILOGO    

HEX_TABLE:
    .byte 0x3F   # 0
    .byte 0x06   # 1
    .byte 0x5B   # 2
    .byte 0x4F   # 3
    .byte 0x66   # 4
    .byte 0x6D   # 5
    .byte 0x7D   # 6
    .byte 0x07   # 7
    .byte 0x7F   # 8
    .byte 0x6F   # 9

.end
