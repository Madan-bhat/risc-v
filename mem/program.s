addi x2, x0, 0
addi x1, x0, 1
addi x3, x0, 11

loop:
    beq  x1, x3, done
    add  x2, x2, x1
    addi x1, x1, 1
    j    loop

done:
    sw   x2, 0(x0)
hang:
    j    hang
