.include "display_vars_2244_0203.asm"
.include "display_constants_2244_0203.asm"
.include "macros.asm"

# -------------------------------------------------------------------------------------------------
# Display control and frame sync
# -------------------------------------------------------------------------------------------------
display_init:
	sll a0, a0, DISPLAY_MODE_MS_SHIFT
	beq a1, 0, _no_fb
		or a0, a0, DISPLAY_MODE_FB_ENABLE
	_no_fb:

	beq a2, 0, _no_tm
		or a0, a0, DISPLAY_MODE_TM_ENABLE
	_no_tm:
	or  a0, a0, DISPLAY_MODE_ENHANCED
	sw  a0, display_ctrl

	sw zero, display_reset

	sw zero, display_sync
jr ra

# -------------------------------------------------------------------------------------------------

# void display_enable_fb()
#   enable the framebuffer if it isn't already.
display_enable_fb:
	lw t0, display_ctrl
	or t0, t0, DISPLAY_MODE_FB_ENABLE
	sw t0, display_ctrl
jr ra

# -------------------------------------------------------------------------------------------------
display_disable_fb:
	lw  t0, display_ctrl
	and t1, t0, DISPLAY_MODE_TM_ENABLE
	beq t1, 0, _return

	# god I wish MARS could do constant expressions.
	li  t1, DISPLAY_MODE_FB_ENABLE
	not t1, t1
	and t0, t0, t1
	sw  t0, display_ctrl
_return:
jr ra

# -------------------------------------------------------------------------------------------------
display_enable_tm:
	lw t0, display_ctrl
	or t0, t0, DISPLAY_MODE_TM_ENABLE
	sw t0, display_ctrl
jr ra

# -------------------------------------------------------------------------------------------------
display_disable_tm:
	lw  t0, display_ctrl
	and t1, t0, DISPLAY_MODE_FB_ENABLE
	beq t1, 0, _return

	# god I wish MARS could do constant expressions.
	li  t1, DISPLAY_MODE_TM_ENABLE
	not t1, t1
	and t0, t0, t1
	sw  t0, display_ctrl
_return:
jr ra

# -------------------------------------------------------------------------------------------------
display_finish_frame:
	sw zero, display_sync
	lw zero, display_sync
jr ra

# -------------------------------------------------------------------------------------------------
# Input
# -------------------------------------------------------------------------------------------------

# sets %reg to 1 if %key is being held, 0 if not
.macro display_is_key_held %reg, %key
	li %reg, %key
	sw %reg, display_key_held
	lw %reg, display_key_held
.end_macro

# -------------------------------------------------------------------------------------------------

# sets %reg to 1 if %key was pressed on this frame, 0 if not
.macro display_is_key_pressed %reg, %key
	li %reg, %key
	sw %reg, display_key_pressed
	lw %reg, display_key_pressed
.end_macro

# -------------------------------------------------------------------------------------------------

# sets %reg to 1 if %key was released on this frame, 0 if not
.macro display_is_key_released %reg, %key
	li %reg, %key
	sw %reg, display_key_released
	lw %reg, display_key_released
.end_macro

# -------------------------------------------------------------------------------------------------
# Palette
# -------------------------------------------------------------------------------------------------
display_load_palette:
	mul a1, a1, 4
	la  t0, display_palette_ram
	add a1, a1, t0

	_loop:
		lw t0, (a0)
		sw t0, (a1)
		add a0, a0, 4
		add a1, a1, 4
	sub a2, a2, 1
	bgt a2, 0, _loop
jr ra

# -------------------------------------------------------------------------------------------------
# Framebuffer
# -------------------------------------------------------------------------------------------------
display_set_pixel:
	blt a0, 0, _return
	bge a0, DISPLAY_W, _return
	blt a1, 0, _return
	bge a1, DISPLAY_H, _return

	sll t0, a1, DISPLAY_W_SHIFT
	add t0, t0, a0
	sb  a2, display_fb_ram(t0)
_return:
jr  ra

# -------------------------------------------------------------------------------------------------
.globl display_draw_hline
display_draw_hline:
	sll t0, a1, DISPLAY_W_SHIFT
	add t0, t0, a0
	la  t1, display_fb_ram
	add t0, t0, t1

	_loop:
		sb  a3, (t0)
		inc t0
	dec  a2
	bnez a2, _loop
jr ra

# -------------------------------------------------------------------------------------------------
display_draw_vline:
	sll t0, a1, DISPLAY_W_SHIFT
	add t0, t0, a0
	la  t1, display_fb_ram
	add t0, t0, t1

	_loop:
		sb  a3, (t0)
		add t0, t0, DISPLAY_W
	dec  a2
	bnez a2, _loop
jr ra

# -------------------------------------------------------------------------------------------------
.globl display_draw_line
display_draw_line:
	# dx:t0 =  abs(x2-x1);
	sub t0, a2, a0
	abs t0, t0

	# sx:t1 = x1<x2 ? 1 : -1;
	slt t1, a0, a2 # 1 if true, 0 if not
	add t1, t1, t1 # 2 if true, 0 if not
	sub t1, t1, 1  # 1 if true, -1 if not

	# dy:t2 = -abs(y2-y1);
	sub t2, a3, a1
	abs t2, t2
	neg t2, t2

	# sy:t3 = y1<y2 ? 1 : -1;
	slt t3, a1, a3
	add t3, t3, t3
	sub t3, t3, 1

	# err:t4 = dx+dy;
	add t4, t0, t2

	_loop:
		# plot(x1, y1);
		sll t7, a1, DISPLAY_W_SHIFT
		add t7, t7, a0
		sb  v1, display_fb_ram(t7)

		# if(x1==x2 && y1==y2) break;
		bne a0, a2, _continue
		beq a1, a3, _return

		_continue:
			add t5, t4, t4 # e2:t5 = 2*err;

			# if(e2 >= dy)
			blt t5, t2, _dx
				add t4, t4, t2 # err += dy;
				add a0, a0, t1 # x1 += sx;

			_dx:
				# if(e2 <= dx)
				bgt t5, t0, _loop
					add t4, t4, t0 # err += dx;
					add a1, a1, t3 # y1 += sy;

	j _loop
_return:
jr ra

# -------------------------------------------------------------------------------------------------
display_fill_rect:
	# turn w/h into x2/y2
	add a2, a2, a0
	add a3, a3, a1

	# turn y1/y2 into addresses
	la  t0, display_fb_ram
	sll a1, a1, DISPLAY_W_SHIFT
	add a1, a1, t0
	add a1, a1, a0
	sll a3, a3, DISPLAY_W_SHIFT
	add a3, a3, t0

	move t0, a1
	_loop_y:
		move t1, t0
		move t2, a0
		_loop_x:
			sb   v1, (t1)
			inc t1
		inc t2
		blt t2, a2, _loop_x
	add t0, t0, DISPLAY_W
	blt t0, a3, _loop_y
jr ra

# -------------------------------------------------------------------------------------------------
display_fill_rect_fast:
	# duplicate color across v1
	and v1, v1, 0xFF
	mul v1, v1, 0x01010101
	add a2, a2, a0 # a2 = x2
	add a3, a3, a1 # a3 = y2

	# t0 = display base address
	la t0, display_fb_ram

	# a1 = start address
	sll a1, a1, DISPLAY_W_SHIFT
	add a1, a1, t0
	add a1, a1, a0

	# a3 = end address
	sll a3, a3, DISPLAY_W_SHIFT
	add a3, a3, t0

	# t0 = current row's start address
	move t0, a1
	_loop_y:
		move t1, t0 # t1 = current address
		move t2, a0 # t2 = current x
		_loop_x:
			sw   v1, (t1)
			add t1, t1, 4
		add t2, t2, 4
		blt t2, a2, _loop_x
	add t0, t0, DISPLAY_W
	blt t0, a3, _loop_y
jr ra

# -------------------------------------------------------------------------------------------------
# Tilemap
# -------------------------------------------------------------------------------------------------
display_set_tile:
	mul a1, a1, BYTES_PER_TM_ROW
	mul a0, a0, TM_ENTRY_SIZE
	add a1, a1, a0
	sb a2, display_tm_table(a1)
	sb a3, display_tm_table + 1(a1)
jr ra

# -------------------------------------------------------------------------------------------------
# Graphics data
# -------------------------------------------------------------------------------------------------
display_load_tm_gfx:
	mul a1, a1, BYTES_PER_TILE
	la  t0, display_tm_gfx
	add a1, a1, t0
	mul a2, a2, BYTES_PER_TILE
j PRIVATE_tilecpy

# -------------------------------------------------------------------------------------------------
display_load_sprite_gfx:
	mul a1, a1, BYTES_PER_TILE
	la  t0, display_spr_gfx
	add a1, a1, t0
	mul a2, a2, BYTES_PER_TILE
j PRIVATE_tilecpy

# -------------------------------------------------------------------------------------------------

# PRIVATE FUNCTION, DO NOT CALL!!!!!!!
PRIVATE_tilecpy:
	_loop:
		lw t0, (a0)
		sw t0, (a1)
		add a0, a0, 4
		add a1, a1, 4
		sub a2, a2, 4
	bgt a2, 0, _loop
jr ra

# -------------------------------------------------------------------------------------------------
# Text
# -------------------------------------------------------------------------------------------------

# Font should probably also call display_set_font_xlate_table when loaded.

.data
	font_xlate_table:   .word 0

	# range of sprite indexes used by the sprite text functions
	text_sprites_start: .word 0
	text_sprites_end:   .word N_SPRITES

	text_sprites_cur:   .word 0
.text

PRIVATE_font_xlate_table_not_set:
	print_str "FATAL: font translation table has not been set.\n"
	li v0, 10
	syscall

# -------------------------------------------------------------------------------------------------

# void display_set_font_xlate_table(ubyte* table)
#   Sets the font translation table. Must be called before any other text function will work.
display_set_font_xlate_table:
	sw a0, font_xlate_table
jr ra

# -------------------------------------------------------------------------------------------------

.macro XLATE_CHAR %dest, %src, %xlate
	blt  %src, 32, _nonprintable
	ble  %src, 126, _printable

	_nonprintable:
		li %src, ' '
	_printable:

	# %dest = tile number = translation_table[ch - 32]
	sub  %src, %src, 32
	add  %src, %src, %xlate
	lbu  %dest, (%src)
.end_macro

# -------------------------------------------------------------------------------------------------
display_xlate_char:
	lw  t9, font_xlate_table
	beq t9, 0, PRIVATE_font_xlate_table_not_set

	XLATE_CHAR v0, a0, t9
jr ra

# -------------------------------------------------------------------------------------------------
display_draw_text_tm:
	li a3, 0
j display_draw_text_tm_flags

# -------------------------------------------------------------------------------------------------
display_draw_text_tm_flags:
	# t9 = translation table base
	lw  t9, font_xlate_table
	beq t9, 0, PRIVATE_font_xlate_table_not_set

	# a1 = destination address
	mul a1, a1, BYTES_PER_TM_ROW
	mul a0, a0, TM_ENTRY_SIZE
	add a1, a1, a0
	la  t0, display_tm_table
	add a1, a1, t0

	# loop over each character in the string
	_loop:
		# t0 = ch
		lbu  t0, (a2)

		# exit loop if zero terminator
		beqz t0, _return

		XLATE_CHAR t0, t0, t9

		# set tile entry
		sb   t0, 0(a1)
		sb   a3, 1(a1)

	add a1, a1, TM_ENTRY_SIZE # next tile entry
	inc a2                    # next character in the string
	j   _loop

_return:
jr ra

# -------------------------------------------------------------------------------------------------

.data
	# temp buffer for holding ASCII representation of int string
	# (way oversized but whatever)
	display_int_str_buffer:     .byte 0:49
	display_int_str_buffer_end: .byte 0

	# special-case for -2^31
	.eqv INT_MIN -2147483648
	display_int_min_str: .asciiz "-2147483648"
	.eqv INT_MIN_STR_LEN 11
.text

# -------------------------------------------------------------------------------------------------
# PRIVATE FUNCTION, DO NOT CALL!!!!!!!
PRIVATE_int_to_string:
	# v0 = destination address
	la v0, display_int_str_buffer_end
	# I'm paranoid
	sb zero, (v0)

	# if a0 == INT_MIN...
	bne a0, INT_MIN, _else
		# special case for INT_MIN cause it breaks shit otherwise
		la v0, display_int_min_str
		li v1, INT_MIN_STR_LEN
	j _endif
	_else:
		# t9 = "is negative?"
		li t9, 0
		# if a0 is negative...
		bgez a0, _endif_neg
			# negate it
			neg a0, a0

			# remember
			li t9, 1
		_endif_neg:

		# produce the digits from least- to most-significant
		_loop:
			div  a0, a0, 10
			mfhi t0 # extract least sig digit into t0
			mflo a0 # keep upper digits in a0

			# convert t0 to ascii and put in buffer
			add t0, t0, '0'
			dec v0
			sb  t0, (v0)
		bnez a0, _loop

		# was it negative?
		beq t9, 0, _not_negative
			# put a - in the buffer
			li  t0, '-'
			dec v0
			sb  t0, (v0)
		_not_negative:

		# now v0 points to first character of string.
		# calculate number of characters
		la  v1, display_int_str_buffer_end
		sub v1, v1, v0
	_endif:
jr ra

# -------------------------------------------------------------------------------------------------
display_draw_int_tm:
push ra
push s0
push s1
	move s0, a0
	move s1, a1

	# convert int to string
	move a0, a2
	jal  PRIVATE_int_to_string

	# now v0 points to the string
	move a0, s0
	move a1, s1
	move a2, v0
	jal  display_draw_text_tm
pop s1
pop s0
pop ra
jr ra

# TODO: display_draw_int_tm_flags

# -------------------------------------------------------------------------------------------------
display_set_text_sprites:
	tlti a0, 0   # start index negative
	tlti a1, 0   # end index negative
	tgei a0, 257 # start index > 256
	tgei a1, 257 # end index > 256
	tlt  a1, a0  # start index > end index

	sw a0, text_sprites_start
	sw a1, text_sprites_end
	sw a1, text_sprites_cur
jr ra

# -------------------------------------------------------------------------------------------------
display_clear_text_sprites:
	lw t0, text_sprites_start # t0 = loop counter
	lw t1, text_sprites_end   # t1 = loop upper bound

	# reset the current sprite counter
	sw t1, text_sprites_cur

	# t2 = dest address
	mul t2, t0, SPRITE_ENTRY_SIZE
	la  t3, display_spr_table
	add t2, t2, t3

	# clear everything [start..end) instead of [start..cur), in case there are old sprites
	_loop:
	bge t0, t1, _exit
		sb zero, 3(t2) # zeroing out the flags will do
	add t2, t2, SPRITE_ENTRY_SIZE
	inc t0
	j _loop
	_exit:
jr ra

# -------------------------------------------------------------------------------------------------
display_draw_text_sprites:
	li a3, 0
j display_draw_text_sprites_flags

# -------------------------------------------------------------------------------------------------
display_draw_text_sprites_flags:
	# t6 = current sprite index
	# t7 = start of text sprites
	lw t6, text_sprites_cur
	lw t7, text_sprites_start

	# setup return values
	move v0, t6
	move v1, t6

	# bail out if no sprites available
	blt t6, t7, _return

	# t8 = destination address ((text_sprites_cur - 1) * SPRITE_ENTRY_SIZE)
	sub t8, t6, 1
	mul t8, t8, SPRITE_ENTRY_SIZE
	la  t0, display_spr_table
	add t8, t8, t0

	# t9 = translation table base
	lw  t9, font_xlate_table
	beq t9, 0, PRIVATE_font_xlate_table_not_set

	# turn on BIT_ENABLE in the flags
	or  a3, a3, BIT_ENABLE

	# loop over each character in the string
	_loop:
	blt t6, t7, _break
		sub t6, t6, 1 # one more sprite used

		# t0 = ch
		lbu  t0, (a2)

		# exit loop if zero terminator
		beqz t0, _break

		XLATE_CHAR t0, t0, t9

		# set sprite entry
		sb   a0, 0(t8) # X
		sb   a1, 1(t8) # Y
		sb   t0, 2(t8) # tile
		sb   a3, 3(t8) # flags

	sub t8, t8, SPRITE_ENTRY_SIZE # next sprite entry
	add a2, a2, 1 # next character in the string
	add a0, a0, 8 # next X coordinate
	j _loop
	_break:

	# update the counter
	sw t6, text_sprites_cur

	# and first return value
	move v0, t6
_return:
jr ra

# -------------------------------------------------------------------------------------------------
display_draw_int_sprites:
push ra
push s0
push s1
	move s0, a0
	move s1, a1

	# convert int to string
	move a0, a2
	jal  PRIVATE_int_to_string

	# now v0 points to the string
	move a0, s0
	move a1, s1
	move a2, v0
	jal  display_draw_text_sprites
pop s1
pop s0
pop ra
jr ra

# TODO: display_draw_int_sprites_flags

# -------------------------------------------------------------------------------------------------

# TODO:
# - simple sprite management?
# 	- enqueue a sprite (4 args, 4 sprite attributes!)
# 	- empty sprite queue
# 	- draw all enqueued sprites
# 	- maybe you can adjust which sprite indexes are automatically managed
# 	- so that you can reserve some sprites for yourself
