.global COMM_20
.global COMM_21

_start:
    movia sp, 0x007FFFFC

    # PROLOGO (montar stack frame)
    addi sp, sp, -4
    stw fp, 0(sp)
    mov fp, sp
    # FIM PROLOGO

    movi r11, 0x10000000

    # ---------------------------------
    # ROTATE
    # ---------------------------------
        COMM_20:
            movi    r17, 0xEA
            
            br END

    # ---------------------------------
    # CANCEL ROTATE
    # ---------------------------------
        COMM_21:
            movi    r17, 0xAE

            br END

END:
    # EPILOGO (desmontar stack frame)
    ldw fp, 0(sp)
    addi sp, sp, 4
    # FIM EPILOGO    

.end