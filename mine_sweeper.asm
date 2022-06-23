	.data
msg_newline:	.asciz "\n"
msg_virgula:	.asciz ", "
msg_barra:	.asciz " | "
msg_espaco:	.asciz " "
msg_init:	.asciz "CAMPO MINADO\n\nTamanho do campo:\n1) 8x8\n2) 10x10\n3) 12x12\nDigite o numero correspondente ao tamanho desejado: "
msg_err_input:	.asciz "Entrada inv�lida!\n\n"
msg_sel_lin:	.asciz "\n\nDigite o n�mero da linha: "
msg_sel_col:	.asciz "\n\nDigite o n�mero da coluna: "
msg_end:	.asciz "\n\nINFORME 0 para continuar o jogo: "

	.text
main:
	li t0, 1 # def 1
	li t1, 3 # def 3
	li t2, 2 # def 2
	
	la a0, msg_init
	
	li a7, 4 # print msg
	ecall
	
	li a7, 5 # input int -> a0
	ecall
	
	blt a0, t0, input_invalido # if int < 1
	bgt a0, t1, input_invalido # or int > 3
	
	jal choose_size
	jal cria_vetores
	jal start_game
	j end
	
	
choose_size:
	addi sp, sp, -4
	sw ra, (sp)
	
	beq a0, t0, campo_8 # if int = 1 jump
	beq a0, t1, campo_12 # if int = 3 jal

	li s0, 10 # else size = 10
	j endChooseSize
	
campo_8:
	li s0, 8 # size = 8
	j endChooseSize
	
campo_12:
	li s0, 12 # size = 12
	j endChooseSize
	
endChooseSize:
	lw ra, (sp)
	addi sp, sp, 4
	
	ret
	
	
cria_vetores:
	addi sp, sp, -4
	sw ra, (sp)
	
	mul s1, s0, s0 # n� index
	slli a0, s1, 2 # index * 4
	
	li a7, 9 # malloc a0 bytes -> &a0
	ecall
	
	add s2, zero, a0 # salva &campo
	slli a0, s1, 2 # denovo index * 4
	
	ecall # malloc a0 bytes -> &a0
	
	add s3, zero, a0 # salva &interface
	add a0, zero, s3 # a0 = &interface
	add a1, zero, s1 # a1 = n� indexes
	
	jal popula_interface
	
	mv a0, s0 # size
	mv a1, s1 # n index
	mv a2, s2 # &campo
	mv a3, s3 # &interface

end_cria_vetores:
	lw ra, (sp)
	addi sp, sp, 4
	
	ret
	
	
start_game:
	addi sp, sp, -4
	sw ra, (sp)
	
	mv s0, a0 # salva size
	mv s1, a1 # salva nindex
	
in_game:
	add a0, zero, a3 # a0 = &interface
	add a1, zero, s0 # a1 = size
	
	jal printa_jogo
	
	add a0, zero, a3 # a0 = &interface
	add a1, zero, s0 # a1 = size
	
	jal joga_coord
	
	add a0, zero, a3 # a0 = &interface
	add a1, zero, s0 # a1 = size
	
	jal printa_jogo
	
	li a7, 4 # print string
	la a0, msg_end
	ecall
	
	li a7, 5 # input int
	ecall
	
	beqz a0, in_game

end_in_game:
	lw ra, (sp)
	addi sp, sp, 4
	
	ret


input_invalido:
	addi sp, sp, -4
	sw ra, (sp)

	la a0, msg_err_input
	li a7, 4 # print string
	
	ecall
	
	li a0, 1500 # 1,5 segundo
	li a7, 32 # sleep
	ecall
	
	lw ra, (sp)
	addi sp, sp, 4
	
	ret


popula_interface:
	addi sp, sp, -4
	sw ra, (sp)
	
	li t0, 4 # ############## DEFINIR INICIALIZA��O
	
pop_loop:
	beqz a1, end_pop_loop # while n� index > 0
	sw t0, 0(a0) # todas posi��es de &interface recebem zero! ########## change t0
	addi a0, a0, 4 # &interface -> next
	addi a1, a1, -1 # index--
	j pop_loop

end_pop_loop:
	lw ra, (sp)
	addi sp, sp, 4
	
	ret
	

printa_jogo:
	addi sp, sp, -4
	sw ra, (sp)
	
	add t0, zero, a0 # t0 = &interface
	add t1, zero, a1 # linhas = a1
	
print_linha:
	beqz t1, end_print # while linhas > 0
	add t2, zero, a1 # colunas = a1
	
	la a0, msg_newline
	li a7, 4 # print string
	ecall
	
print_coluna:
	beqz t2, end_coluna # while colunas > 0
	
	lw a0, 0(t0) # a0 = &interface[atual]
	li a7, 1 # print int a0
	ecall
	
	la a0, msg_espaco
	li a7, 4 # print string
	ecall
	
	addi t0, t0, 4 # &interface next
	addi t2, t2, -1 # colunas--
	
	j print_coluna
	
end_coluna:
	addi t1, t1, -1
	j print_linha
	
end_print:
	lw ra, (sp)
	addi sp, sp, 4
	
	ret


joga_coord:
	addi sp, sp, -4
	sw ra, (sp)
	
	mv t0, a0 # t0 = &interface
	
sel_coluna:
	li a7, 4 # print string
	
	la a0, msg_sel_col
	ecall
	
	li a7, 5 # input int
	ecall
	
	bltz a0, sel_coluna
	bge a0, a1, sel_coluna
	
	mv t1, a0 # salva coord coluna

sel_linha:
	li a7, 4 # print string
	
	la a0, msg_sel_lin
	ecall
	
	li a7, 5 # input int
	ecall
	
	bltz a0, sel_linha
	bge a0, a1, sel_linha
	
	mv t2, a0 # salva coord linha
	
muda_coord:
	mul t3, t2, a1 # linhas*size
	add t3, t3, t1 # (linhas*size) + colunas
	slli t3, t3, 2 # t1 << 2 = t1*4
	
	add t0, t0, t3 # &interface + index
	sw zero, 0(t0) # muda &interface(index) p/ 0

end_joga_cord:
	lw ra, (sp)
	addi sp, sp, 4
	
	ret

end:
	li a7, 10
	ecall
