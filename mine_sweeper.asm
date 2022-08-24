##############################################################
### Alunos: Alexsandro Meurer Schneider, Ismael Bortoluzzi ### ------> ESTÁ CONCLUÍDO
##############################################################

	.data
msg_newline:		.asciz "\n"
msg_barra:		.asciz "|"
msg_traco:		.asciz "-"
msg_espaco:		.asciz " "
msg_flag:		.asciz "F"
msg_asterisk:		.asciz "*"
msg_init:		.asciz "\n\nCAMPO MINADO\n\nOpções:\n1) Campo 8x8\n2) Campo 10x10\n3) Campo 12x12\n4) SAIR\n\nDigite o número da opção desejada: "
msg_err_input:		.asciz "\nEntrada inválida!\n"
msg_sel_lin:		.asciz "Número da LINHA: "
msg_sel_col:		.asciz "Número da COLUNA: "
msg_ingame: 		.asciz "\n\n1) Abrir uma posição\n2) Alternar Bandeira: "
msg_is_open:		.asciz "\nA coordenada selecionada já está aberta, selecione outra...\n"
msg_flagged:		.asciz "\nA coordenada selecionada está com bandeira.\nRetire a bandeira para poder abrí-la...\n"
msg_explosion:		.asciz "\n\nUma bomba EXPLODIU! Você PERDEU.\n"
msg_game_won:		.asciz "\n\nPARABÉNS! Você VENCEU!!!\n"
msg_continue:		.asciz "\nJogar novamente?\n1) SIM\n2) NÃO: "

	.text
main:
	jal CHOOSE_FIELD_SIZE # retorna a0 = &campo, a1 = size
	jal LAUNCH_FIELD # popula campo com 0's
	jal INSERE_BOMBA # inicia 15 bombas na matriz
	jal CALCULA_BOMBAS # popula campo com n° de bombas ao redor de cada coordenada
	jal START_GAME # inicia jogo
	beqz a2, main # se FLAG = 0 -> INICIA NOVO JOGO
	li a7, 10 # EXIT
	ecall

## A matriz campo será o controle do jogo. Ao escolher um tamanho de campo, iniciamos todas as posições da matriz com o valor 0, previnindo aparecimento de LIXO.
## Em seguida será inserido 15 bombas em posições aleatorias. Então contamos quantas bombas estão ao redor de cada uma das coordenadas e guardamos seu valor na matriz.
## Ao abrirmos uma coordenada válida, negativamos seu número na matriz para indicar que a posição já foi aberta. EX: coord 0x0 tinha 3 bombas, seu valor na matriz será -3.
## Caso a coordenada aberta não possua bombas ao redor, colocamos o número -9 na matriz (podemos utilizar o -9 já que ao abrir uma bomba acaba o jogo).
## Quando inserimos uma bandeira, somamos 10 ao valor da coordenada na matriz. Ao remover a bandeira, subtraimos 10 de seu valor.
## Uma coordenada que possua o valor 10 significa que possui bandeira e tem 0 bombas ao seu redor. 19 significa que possui bandeira e é uma Bomba.
## Uma coordenada não pode ser aberta se seu valor for negativo (já aberta) ou maior que 9 (possui bandeira).

## TODAS AS FUNÇÕES RECEBEM &CAMPO em a0, SIZE em a1 e FLAG game_state em a2, preocupam-se com o controle do RA e em retornar a0, a1 e a2 intactos.
## A UNICA FUNÇÃO que muda a0 é GET_COORD_ADDRESS, que seleciona uma coordenada e retorna seu endereço,
## portanto a função que chama-la deve salvar o valor de a0.

###################################
INPUT_INVALIDO: # Imprime mensagem de input invalido nos menus de escolha.
	sw a0, 0(sp) # PUSH &campo
	addi sp, sp, -4
	la a0, msg_err_input
	li a7, 4 # PRINT string
	ecall
	li a0, 750 # 0.75 segundo
	li a7, 32 # SLEEP
	ecall
	addi sp, sp, 4
	lw a0, 0(sp) # POP &campo
	ret

###################################
COORD_OPENED: # Imprime mensagem de coordenada já aberta ao Abrir Coord/Mudar Bandeira.
	sw a0, 0(sp) # PUSH &campo
	addi sp, sp, -4
	li a7, 4 # PRINT string
	la a0, msg_is_open
	ecall
	li a0, 1250 # 1.25 segundo
	li a7, 32 # SLEEP
	ecall
	addi sp, sp, 4
	lw a0, 0(sp) # POP &campo
	ret

###################################
CHOOSE_FIELD_SIZE: # Escolhe o tamanho do campo de jogo. Retorna em a0 um &campo na memoria HEAP, e em a1 SIZE (numero de linhas/colunas)
	sw ra, 0(sp) # PUSH ra
	addi sp, sp, -4
	li t0, 1 # def 1
	li t1, 2 # def 2
	li t2, 3 # def 3
	li t3, 4 # def 4
size_input:
	la a0, msg_init
	li a7, 4 # PRINT string
	ecall
	li a7, 5 # INPUT int
	ecall
	blt a0, t0, size_invalido # if int < 1
	bgt a0, t3, size_invalido # or int > 4
	beq a0, t0, campo_8 # if int = 1 jump
	beq a0, t1, campo_10 # if int = 2 jump
	beq a0, t2, campo_12 # if int = 3 jump
	li a7, 10
	ecall
campo_8:
	li t0, 8 # size = 8
	j cria_campo
campo_10:
	li t0, 10 # size = 10
	j cria_campo
campo_12:
	li t0, 12 # size = 12
cria_campo:
	mv a1, t0 # Return size em a1
	mul t0, t0, t0 # n° index = size*size
	slli a0, t0, 2 # index << 2 = index*4 = tamanho de bytes p/ alocar
	li a7, 9 # MALLOC a0 bytes -> &a0
	ecall # Return &campo em a0
	addi sp, sp, 4
	lw ra, 0(sp) # POP ra
	ret
size_invalido:
	jal INPUT_INVALIDO
	j size_input

###################################
LAUNCH_FIELD: # Inicializa o campo com ZERO em todas as posições, para evitar LIXO.
	mv t0, a0 # &campo modificavel
	mul t1, a1, a1 # n° de indexes
popula_loop:
	beqz t1, end_popula # while n° index > 0
	sw zero, 0(t0) # todas posições de &campo recebem zero!
	addi t0, t0, 4 # &campo -> next
	addi t1, t1, -1 # index--
	j popula_loop
end_popula:
	ret

###################################
START_GAME: # Inicia o menu do jogo e fica em loop até perder/vencer. Ao retornar para MAIN, descarta a0 (ao iniciar novo jogo, é criado novo &campo).
	li a2, 0 # SET FLAG = 0 (reset)
	sw ra, 0(sp) # PUSH ra
	addi sp, sp, -4
in_game:
	jal MOSTRA_CAMPO
	li a7, 4 # PRINT string
	bgtz a2, game_won
	bltz a2, game_lost
	mv t0, a0 # TEMP &campo
	li t1, 1 # escolha 1
	li t2, 2 # escolha 2
	li a7, 4 # PRINT string
	la a0, msg_ingame
	ecall
	li a7, 5 # INPUT int
	ecall
	mv t3, a0 # salva INPUT
	mv a0, t0 # RET TEMP &campo
	beq t3, t1, PLAY_COORDINATE
	beq t3, t2, TOGGLE_FLAG
	jal INPUT_INVALIDO
	j in_game
game_won:
	la a0, msg_game_won
	ecall
	j choice_continue
game_lost:
	la a0, msg_explosion
	ecall
choice_continue:
	li a7, 4 # PRINT string
	la a0, msg_continue
	ecall
	li a7, 5 # INPUT int
	ecall
	li t0, 1 # escolha 1
	li t1, 2 # escolha 2
	beq a0, t0, continue_game
	beq a0, t1, end_game
	jal INPUT_INVALIDO
	j choice_continue
continue_game:
	li a2, 0 # SET FLAG p/ continuar
end_game:
	addi sp, sp, 4
	lw ra, 0(sp) # POP ra
	ret

###################################
PLAY_COORDINATE: # Abre uma coordenada, verificando se é valida/bomba/flag.
	sw ra, 0(sp) # PUSH ra
	addi sp, sp, -4
	sw a0, 0(sp) # PUSH &campo
	addi sp, sp, -4
	jal GET_COORD_ADDRESS
	li t0, 9 # BOMBA
	lw t1, 0(a0) # lê valor da coordenada
	beqz t1, coord_is_zero # Coord = 0, não possui bomba, set = -9 (não utilizado em jogo)
	bltz t1, coord_already_open # Coord < 0 = ja aberto
	bgt t1, t0, coord_flagged # Coord > 9 = está flagado
	beq t1, t0, coord_is_bomb # Coord = 9, perde o jogo
	neg t1, t1 # Coord negativa == ABERTO
	j save_coord
coord_is_zero:
	li t1, -9 # -9 == (0 bombas) já ABERTO
save_coord:
	sw t1, 0(a0) # Salva coord aberta
	j end_op_coord
coord_is_bomb:
	li a2, -1 # SETA FLAG perdeu
	j end_op_coord
coord_already_open:
	jal COORD_OPENED
	j end_op_coord
coord_flagged:
	li a7, 4 # PRINT string
	la a0, msg_flagged
	ecall
	li a0, 1500 # 1.5 segundo
	li a7, 32 # SLEEP
	ecall
end_op_coord:
	addi sp, sp, 4
	lw a0, 0(sp) # POP &campo
	addi sp, sp, 4
	lw ra, 0(sp) # POP ra
	j in_game

###################################	
TOGGLE_FLAG: # Alterna bandeira na coordenada selecionada.
	sw ra, 0(sp) # PUSH ra
	addi sp, sp, -4
	sw a0, 0(sp) # PUSH &campo
	addi sp, sp, -4
	jal GET_COORD_ADDRESS
	li t0, 9 # P/ comparar
	lw t1, 0(a0) # Lê valor da coordenada
	bltz t1, flag_opened # Coord < 0 = ja aberto
	bgt t1, t0, remove_flag # Coord > 9 = está flagado
	addi t1, t1, 10 # Coord+10 = insere flag
	j end_toggle
flag_opened:
	jal COORD_OPENED
	j end_toggle
remove_flag:
	addi t1, t1, -10 # Coord-10 = remove flag
end_toggle:
	sw t1, 0(a0) # salva Coord atualizada
	addi sp, sp, 4
	lw a0, 0(sp) # POP &campo
	addi sp, sp, 4
	lw ra, 0(sp) # POP ra
	j in_game

###################################
GET_COORD_ADDRESS: # Seleciona uma coordenada e retorna seu endereço em 'a0'.
	sw ra, 0(sp) # PUSH ra
	addi sp, sp, -4
	mv t0, a0 # TEMP &campo
select_linha:
	li a7, 4 # PRINT string
	la a0, msg_sel_lin
	ecall
	li a7, 5 # INPUT int
	ecall
	bltz a0, invalid_row # int < 0 == coord invalida
	bge a0, a1, invalid_row # int >= size == coord invalida
	mv t1, a0 # salva coord linha
select_coluna:
	li a7, 4 # PRINT string
	la a0, msg_sel_col
	ecall
	li a7, 5 # INPUT int
	ecall
	bltz a0, invalid_column # int < 0 == coord invalida
	bge a0, a1, invalid_column # int >= size == coord invalida
	mv t2, a0 # salva coord coluna
coord_adress:
	mul t1, t1, a1 # linha*size
	add t1, t1, t2 # (linhas*size) + colunas
	slli t1, t1, 2 # t1 << 2 = t1*4
	add a0, t0, t1 # &vetor+'LxC' = &coordenada
	addi sp, sp, 4
	lw ra, 0(sp) # POP ra
	ret # retorna &coord no A0
invalid_row:
	jal INPUT_INVALIDO
	j select_linha
invalid_column:
	jal INPUT_INVALIDO
	j select_coluna

###################################
MOSTRA_CAMPO: # Imprime a matriz CAMPO. Também controla a lógica de vencer o jogo, contando as coordenadas abertas que não são bomba.
	sw a0, 0(sp) # PUSH &campo
	addi sp, sp, -4
	li s0, 10 # p/ modulo 10
	mv t0, a0 # t0 = &campo
	li t1, 0 # linha = 0
	li t2, 0 # coluna = 0
	li t3, 9 # BOMBA
	li t4, -9 # ZERO Aberto
	li t5, 19 # BOMBA FLAGGED
	mul t6, a1, a1 # n*indexes -> LOGICA p/ ver se venceu o jogo
	addi t6, t6, -15 # n*indexes - bombas = quantas coords devem estar abertas para vencer
	li a7, 4 # PRINT string
	la a0, msg_newline
	ecall
	la a0, msg_espaco
	ecall
	ecall
print_cabecalho:
	bge t2, a1, print_linha
	rem a0, t2, s0, # coluna atual % 10
	li a7, 1 # PRINT int
	ecall
	li a7, 4 # PRINT string
	la a0, msg_espaco
	ecall
	addi t2, t2, 1 # coluna++
	j print_cabecalho
print_linha:
	beqz t6, set_game_win # se t6 == 0 venceu o jogo
	bge t1, a1, end_print # while linha < size
	li t2, 0 # coluna = 0
	li a7, 4 # PRINT string
	la a0, msg_newline
	ecall
	li a7, 1 # PRINT int
	rem a0, t1, s0 # linha atual % 10
	ecall
	li a7, 4 # PRINT string
	la a0, msg_barra
	ecall
print_coluna:
	bge t2, a1, end_coluna # while coluna < size
	lw a0, 0(t0) # a0 = &campo
	li a7, 4 # PRINT string
	beqz a2, print_coluna_normal # printa bombas ao PERDER, a2 != 0
	beq a0, t3, print_bomba # == 9
	beq a0, t5, print_bomba # == 19
print_coluna_normal:
	bgt a0, t3, print_flag # > 9 = FLAG
	beq a0, t4, print_zero # Campo = 0
	bltz a0, print_n_bombas # < 0 = ABERTO
	la a0, msg_traco
	ecall
	j att_print
print_bomba:
	la a0, msg_asterisk
	ecall
	j att_print
print_flag:
	la a0, msg_flag
	ecall
	j att_print
print_zero:
	add a0, zero, zero # valor = 0
print_n_bombas:
	neg a0, a0 # lê o número positivo
	li a7, 1 # PRINT int
	ecall
	addi t6, t6, -1 # desconta COORD aberta
att_print:
	li a7, 4 # PRINT string
	la a0, msg_barra
	ecall
	addi t0, t0, 4 # &campo -> next
	addi t2, t2, 1 # coluna++
	j print_coluna
end_coluna:
	addi t1, t1, 1 # linha++
	j print_linha
set_game_win:
	li a2, 1 # FLAG WIN
end_print:
	addi sp, sp, 4
	lw a0, 0(sp) # POP &campo
	ret

########################
CALCULA_BOMBAS: # Atualiza a matriz com a quantia de bombas ao redor de cada posição no campo.
	sw ra, 0(sp) # PUSH ra
	addi sp, sp -4
	li t5, 0 # linhas = 0
conta_linha:
	bge t5, a1, end_calcula # while linhas < size
	li t6, 0 # colunas = 0
conta_coluna:
	bge t6, a1, end_conta_coluna # while coluna < size
	jal CHECK_COORDS
	addi t6, t6, 1 # colunas++
	j conta_coluna
end_conta_coluna:
	addi t5, t5, 1 # linhas++
	j conta_linha
end_calcula:
	addi sp, sp, 4
	lw ra, 0(sp) # POP ra
	ret
	
CHECK_COORDS: # Verifica qual o tipo de posição. Ex: (canto superior/inferior direito/esquerdo, lados ou centro)
	li t0, 9 # check bomba RETurn
	mul t1, t5, a1 # linha*size
	add t1, t1, t6 # (linha*size) + coluna
	slli t1, t1, 2 # ((linha*size) + coluna) * 4
	add t1, a0, t1 # &index -------------------------> T1 = &INDEX
	slli t2, a1, 2 # size<<2 = bytes_por_linha ------> T2 = +s ou -s
	lw t3, 0(t1) # checagem de bombas
	blt t3, t0, check_case # se v(index) < 9 = não é bomba -> conta n° de bombas e salva seu valor
	ret # se for bomba, check next coord
check_case:
	addi t0, a1, -2 # MAX = size - 2; ex: (8x8, max = 7) 8-2 = 6, 7>6.
	li s8, 0 # RESET nºposicoes

	seqz s0, t5 # linha == 0
	sgt s1, t5, t0 # linha == MAX (S)
	seqz s2, t6 # coluna == 0
	sgt s3, t6, t0# coluna == MAX (S)

	and t0, s0, s2 # 00
	bgtz t0, coord_00
	and t0, s0, s3 # 0S
	bgtz t0, coord_0S
	and t0, s1, s3 # SS
	bgtz t0, coord_SS
	and t0, s1, s2 # S0
	bgtz t0, coord_S0
	bgtz s0, coord_0n
	bgtz s1, coord_Sn
	bgtz s2, coord_n0
	bgtz s3, coord_nS
	j coord_nn

coord_00:
	add t0, t1, t2 # &i+s
	lw s0, 4(t1) # v i+1
	lw s1, 0(t0) # v i+s
	lw s2, 4(t0) # v i+s+1
	j contador
coord_0S:
	add t0, t1, t2 # &i+s
	lw s0, -4(t1) # v i-1
	lw s1, -4(t0) # v i+s-1
	lw s2, 0(t0) # v i+s
	j contador
coord_S0:
	sub t0, t1, t2 # &i-s
	lw s0, 0(t0) # v i-s
	lw s1, 4(t0) # v i-s+1
	lw s2, 4(t1) # v i+1
	j contador
coord_SS:
	sub t0, t1, t2 # &i-s
	lw s0, -4(t0) # v i-s-1
	lw s1, 0(t0) # v i-s
	lw s2, -4(t1) # v i-1
	j contador
coord_0n:
	add t0, t1, t2 # &i+s
	lw s0, -4(t1) # v i-1
	lw s1, 4(t1) # v i+1
	lw s2, -4(t0) # v i+s-1
	lw s3, 0(t0) # v i+s
	lw s4, 4(t0) # v i+s+1
	li s8, 5
	j contador
coord_Sn:
	sub t0, t1, t2 # &i-s
	lw s0, -4(t0) # v i-s-1
	lw s1, 0(t0) # v i-s
	lw s2, 4(t0) # v i-s+1
	lw s3, -4(t1) # v i-1
	lw s4, 4(t1) # v i+1
	li s8, 5
	j contador
coord_n0:
	sub t0, t1, t2 # &i-s
	add t3, t1, t2 # &i+s
	lw s0, 0(t0) # v i-s
	lw s1, 4(t0) # v i-s+1
	lw s2, 4(t1) # v i+1
	lw s3, 0(t3) # v i+s
	lw s4, 4(t3) # v i+s+1
	li s8, 5
	j contador
coord_nS:
	sub t0, t1, t2 # &i-s
	add t3, t1, t2 # &i+s
	lw s0, -4(t0) # v i-s-1
	lw s1, 0(t0) # v i-s
	lw s2, -4(t1) # v i-1
	lw s3, -4(t3) # v i+s-1
	lw s4, 0(t3) # v i+s
	li s8, 5
	j contador
coord_nn:
	sub t0, t1, t2 # &i-s
	add t3, t1, t2 # &i+s
	lw s0, -4(t0) # v i-s-1
	lw s1, 0(t0) # v i-s
	lw s2, 4(t0) # v i-s+1
	lw s3, -4(t1) # v i-1
	lw s4, 4(t1) # v i+1
	lw s5, -4(t3) # v i+s-1
	lw s6, 0(t3) # v i+s
	lw s7, 4(t3) # v i+s+1
	li s8, 8
	j contador

contador:
	li t0, 0 # contador = 0
	li t2, 8 # n > 8 == 9 == bomba
	sgt s0, s0, t2 # se coord > 8, set = 1, senao = 0
	sgt s1, s1, t2 # II
	sgt s2, s2, t2 # II
	add t0, t0, s0 # soma ao n° bombas
	add t0, t0, s1 # II
	add t0, t0, s2 # II
	bgtz s8, contador_2 # se nºposicoes > 0 = continua, senao salva n° de bombas na coord e retorna
	sw t0, 0(t1) # salva n°bombas no &index
	ret
contador_2:
	sgt s3, s3, t2 # se coord > 8, set = 1, senao = 0
	sgt s4, s4, t2 # II
	add t0, t0, s3 # soma ao n° bombas
	add t0, t0, s4 # II
	bge s8, t2, contador_3 # se n°posicoes > 8 = continua
	sw t0, 0(t1) # salva n°bombas no &index
	ret
contador_3:
	sgt s5, s5, t2 # se coord > 8, set = 1, senao = 0
	sgt s6, s6, t2 # II
	sgt s7, s7, t2 # II
	add t0, t0, s5 # soma ao n° bombas
	add t0, t0, s6 # II
	add t0, t0, s7 # II
	sw t0, 0(t1) # salva n°bombas no &index
	ret

##########################
INSERE_BOMBA:
		sw	ra, 0(sp) 		# PUSH ra
		addi 	sp, sp -4
		sw	a0, 0(sp) 		# PUSH &campo
		addi 	sp, sp -4
		sw	a1, 0(sp) 		# PUSH size
		addi 	sp, sp -4
		add 	t0, zero, a0		# salva a0 em t0 - endereço da matriz campo
		add 	t1, zero, a1		# salva a1 em t1 - quantidade de linhas
QTD_BOMBAS:
		addi 	t2, zero, 15 		# seta para 15 bombas
		add 	t3, zero, zero 		# inicia contador de bombas com 0
		addi 	a7, zero, 30 		# ecall 30 pega o tempo do sistema em milisegundos (usado como semente)
		ecall
		add 	a1, zero, a0		# coloca a semente em a1
INICIO_LACO:
		beq 	t2, t3, FIM_LACO
		add 	a0, zero, t1 		# carrega limite para %	(resto da divisão)
		jal 	PSEUDO_RAND
		add 	t4, zero, a0		# pega linha sorteada e coloca em t4
		add 	a0, zero, t1 		# carrega limite para % (resto da divisão)
   		jal 	PSEUDO_RAND
		add 	t5, zero, a0		# pega coluna sorteada e coloca em t5
LE_POSICAO:
		mul  	t4, t4, t1
		add  	t4, t4, t5  		# calcula (L * tam) + C
		add  	t4, t4, t4  		# multiplica por 2
		add  	t4, t4, t4  		# multiplica por 4
		add  	t4, t4, t0  		# calcula Base + deslocamento
		lw   	t5, 0(t4)   		# Le posicao de memoria LxC
VERIFICA_BOMBA:
		addi 	t6, zero, 9		# se posição sorteada já possui bomba
		beq  	t5, t6, PULA_ATRIB	# pula atribuição 
		sw   	t6, 0(t4)		# senão coloca 9 (bomba) na posição
		addi 	t3, t3, 1		# incrementa quantidade de bombas sorteadas
PULA_ATRIB:
		j	INICIO_LACO
FIM_LACO:
		addi	sp, sp, 4
		lw	a1, 0(sp)		# POP &campo
		addi	sp, sp, 4
		lw	a0, 0(sp)		# POP size
		addi	sp, sp, 4
		lw	ra, 0(sp)		# POP ra
		jr 	ra			# retorna para função que fez a chamada
PSEUDO_RAND:
		addi t6, zero, 125  		# carrega constante t6 = 125
		lui  t5, 682			# carrega constante t5 = 2796203
		addi t5, t5, 1697 		# 
		addi t5, t5, 1034 		# 
		mul  a1, a1, t6			# a = a * 125
		rem  a1, a1, t5			# a = a % 2796203
		rem  a0, a1, a0			# a % lim
		bge  a0, zero, EH_POSITIVO  	# testa se valor eh positivo
		addi s2, zero, -1           	# caso não
		mul  a0, a0, s2		    	# transforma em positivo
EH_POSITIVO:
		ret				# retorna em a0 o valor obtido
