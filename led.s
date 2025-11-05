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
            movi    r17, 0xF0
            
            br END

    # ---------------------------------
    # APAGAR XX-ÉSIMO LED VERMELHO
    # ---------------------------------
        COMM_01:
            movi    r17, 0x0F

            br END

END:
    # EPILOGO (desmontar stack frame)
    ldw fp, 0(sp)
    addi sp, sp, 4
    # FIM EPILOGO    

.end