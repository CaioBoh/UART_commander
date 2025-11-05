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
            movi    r17, 0xA0
            
            br END

END:
    # EPILOGO (desmontar stack frame)
    ldw fp, 0(sp)
    addi sp, sp, 4
    # FIM EPILOGO    

.end