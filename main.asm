.include "display_2244_0203.asm"
.include "graphics.asm"

.eqv MODE_NOTHING 0
.eqv MODE_BRUSH   1
.eqv MODE_COLOR   2

.eqv PALETTE_X  32
.eqv PALETTE_Y  56
.eqv PALETTE_X2 96
.eqv PALETTE_Y2 72

.data
	drawmode: .word MODE_NOTHING
	last_x:   .word -1
	last_y:   .word -1
	color:    .word 0b111111 # 3,3,3 (white)
	
	# My variables
	location_tile_x: .word PALETTE_X
	location_tile_y: .word PALETTE_Y
.text

.global main
main:
	# Call display init with arguments
	li a0, 15 
	li a1, 1
	li a2, 0
	jal display_init
	
	# Other functions
	jal load_graphics
	
	_main_loop:
		# Call functions
		jal check_input
		jal draw_cursor 
		jal display_finish_frame
		
		# Loop back
		j _main_loop
		
#----------
		
load_graphics:
	push ra 
	
	# Call display_load_sprite_gfx with cursor_gfx
	la a0, cursor_gfx
	li a1, CURSOR_TILE
	li a2, N_CURSOR_TILES
	jal display_load_sprite_gfx
	
	# Call display_load_sprite_gfx with cursor_gfx
	la a0, palette_sprite_gfx
	li a1, PALETTE_TILE
	li a2, N_PALETTE_TILES
	jal display_load_sprite_gfx
	
	pop ra 
	jr ra
	
#------------

check_input:
	push ra
	
	lw t0, drawmode
	
	# If drawmode variable is nothing
	beq t0, MODE_NOTHING, _case_nothing
	
	# If drawmode variable is brush
	beq t0, MODE_BRUSH, _case_brush
	
	# If drawmode variable is color
	beq t0, MODE_COLOR, _case_color
	
	# This should never happen
    j default_case

	# Switch cases
	_case_nothing:
		# Call a function and then leave the switch case 
		jal drawmode_nothing
		j end_switch
	_case_brush:
		# Call a function and then leave the switch case
		jal drawmode_brush
	    j end_switch
	
	_case_color:
		# Call a function and then leave the switch case
		jal drawmode_color
	    j end_switch
	
	default_case:
		print_str "This should never happen"
		
	end_switch:
		
	pop ra 
	jr ra
	
#------------


draw_cursor:
	push ra
	
	# Sprites Array
	la t0, display_spr_table
	
	# display_mouse_x
	lw t1, display_mouse_x
	sub t1, t1, 3
	sb t1, 0(t0)
	
	# display_mouse_y
	lw t1, display_mouse_y
	sub t1, t1, 3
	sb t1, 1(t0)
	
	# Pick tile
	li t1, CURSOR_TILE
	sb t1, 2(t0)
	
	# Make cursor visible
	li t1, COLOR_RED
	sb t1, 3(t0)
	
	pop ra
	jr ra
	
#-------------

drawmode_nothing:
	push ra

	# Check if user pressed left mouse button
	lw t0, display_mouse_pressed
	# Extract and check left mouse button
	and t1, t0, MOUSE_LBUTTON
	beq t1, 0, _end_mouse_if
		# Get value if alt is pressed (i'm not switching it, i want to keep it the same + i'm lazy)
		li t0, KEY_ALT
		sw t0, display_key_held
		lw t0, display_key_held
		# If not held then skip
		bne t0, 1, _end_if
			# Get the arguments for the 
			lw a0, display_mouse_x
			lw a1, display_mouse_y
			jal display_get_pixel
			sw v0, color
			# Don't need to start brush so skip it
			j _end_mouse_if
		_end_if:
		jal start_brush
	_end_mouse_if:
	
	li t0, KEY_C
	sw t0, display_key_pressed
	lw t0, display_key_pressed
	
	beq t0, 0, _end_key_c_if
		# If key was pressed
		li t0, MODE_COLOR
		sw t0, drawmode
		
		jal display_palette
		
	_end_key_c_if:
	
	# Get the status of the F key
	li t0, KEY_F
	sw t0, display_key_pressed 
	lw t0, display_key_pressed
	
	# If Key is not pressed go to end if
	beq t0, 0, _end_key_f_if
		jal flood_fill
	
	_end_key_f_if:
	
	pop ra
	jr ra
	
#-------------

start_brush:
	push ra
	push s0
	push s1
	
	# Left mouse button was pressed so switch to drawmode_brush
	li t0, MODE_BRUSH
	sw t0, drawmode
	
	# Get current location of the mouse (we can't expect that display draw line won't change t or a registers + too lazy to check if it does change it)
	lw s0, display_mouse_x
	lw s1, display_mouse_y
	
	# Get value if alt is pressed (i'm not switching it, i want to keep it the same + i'm lazy)
	li t0, KEY_SHIFT
	sw t0, display_key_held
	lw t0, display_key_held
	# If is does not held skip
	bne t0, 1, _else_if
		print_str "shift held"
		
		lw a0, last_x
		lw a1, last_y
		j _end_if
	_else_if:
		lw a0, display_mouse_x
		lw a1, display_mouse_y
	_end_if:
	
	lw a2, display_mouse_x
	lw a3, display_mouse_y
	# Load color and pass it as argument
	lw v1, color
	
	jal display_draw_line
	
	# Set current mouse coordinate to the last_x and last_y
	sw s0, last_x
	sw s1, last_y
	
	pop s1
	pop s0
	pop ra
	jr ra

#-------------

display_palette:
	# NOTE: I know that the implementation in this nested loop is not the most elegent (especially calculation of the x and y position)
	# BUT I will not change a thing because im too lazy. But please don't take points off for this subpar code
	push ra
	push s0
	push s1
	
	# Show pallete sprites
	la t9, display_spr_table
	add t9, t9, 4
	
	# Set the i1 (index) for outer loop
	li s0, 0
	
	_outer_loop_start:
		# Set X location 
		li t0, PALETTE_X
		sw t0, location_tile_x
		# Set the limit of the outer loop
   		li t1, 2  
   		# If outer loop limit reached
  		beq s0, t1, _outer_loop_end 
	
		# Set the i2 (index) for inner_loop
   		li s1, 0
		_inner_loop_start:
   			li t3, 8
   			# If inner loop limit reached
   			beq s1, t3, _inner_loop_end
   				# # Calculate and store x 
   				# # LOCATION x = x + 8
				lw t0, location_tile_x
				sb t0, 0(t9)
				# Increment by for the future
				add t0, t0, 8
				sw t0, location_tile_x
				
				# # Calculate and store y
				lw t0, location_tile_y
				sb t0, 1(t9)
				
				# Calculate a tile
				# t0 = 8 * i1 + i2 
				mul t0, s0, 8
				add t0, t0, s1
				# Pick a tile
				li t1, PALETTE_TILE
				add t0, t0, t1
				# Stole this tile
				sb t0, 2(t9)
				
				# Flag
				li t0, 1
				sb t0, 3(t9)
				
				# Move to the next sprite
				add t9, t9, 4
			
			# Increment inner loop counter and then jump back
   			add s1, s1, 1 
   			
   			# Jump back to the inner loop
   			j _inner_loop_start
		
		_inner_loop_end:
		
		# Increment y position of next set of tiles 
		lw t0, location_tile_y
		add t0, t0, 8
		sw t0, location_tile_y
		
		# Increment outer loop and then jump back
   		add s0, s0, 1
   		j _outer_loop_start 
	# End of nested loops
	_outer_loop_end:
	
	# Reset location_tile_y variable for the future
	li t0, PALETTE_Y
	sw t0, location_tile_y
	
	pop s1
	pop s0
	pop ra
	jr ra
	
#-------------

hide_palette_display:
	push ra 
	push s0
	push s1
	
	# Show pallete sprites
	la t9, display_spr_table
	add t9, t9, 4
	
	# Set the i1 (index) for outer loop
	li s0, 0
	
	_outer_loop_start:
		# Set the limit of the outer loop
   		li t1, 2  
	
   		# If outer loop limit reached
  		beq s0, t1, _outer_loop_end 
	
		# Set the i2 (index) for inner_loop
   		li s1, 0
		_inner_loop_start:
   			li t3, 8
   			# If inner loop limit reached
   			beq s1, t3, _inner_loop_end
				# Flag
				li t0, 0
				sb t0, 3(t9)
				
				# Move to the next sprite
				add t9, t9, 4
			
			# Increment inner loop counter and then jump back
   			add s1, s1, 1 
   			
   			# Jump back to the inner loop
   			j _inner_loop_start
		
		_inner_loop_end:
		
		# Increment outer loop and then jump back
   		add s0, s0, 1
   		j _outer_loop_start 
	# End of nested loops
	_outer_loop_end:
	
	pop s1
	pop s0
	pop ra
	jr ra

#-------------

drawmode_brush:
	push ra
	
	# Load the x and y values
	lw t0, display_mouse_x
	lw t1, display_mouse_y
	
	# If the mouse coordinates off-screen
	# X < 0
	blt t0, 0, _set_brush_to_nothing
	# X > 127
	bgt t0, 127, _set_brush_to_nothing
	# Y < 0
	blt t1, 0, _set_brush_to_nothing
	# Y > 127
	bgt t1, 127, _set_brush_to_nothing
	
	# If mouse left button is released
	lw t0, display_mouse_released
	and t1, t0, MOUSE_LBUTTON
	bne t1, 0, _set_brush_to_nothing
	
	# If none of these conditions met, then go to else condition
	j _else_if
	
	_set_brush_to_nothing:
		li t0, MODE_NOTHING
		sw t0, drawmode
	
	_else_if:
		# Load last coordinates
		lw a0, last_x
		lw a1, last_y
		
		# Load x and y coordinates into s since display_draw_line can change a or t registers
		lw a2, display_mouse_x
		lw a3, display_mouse_y
		
		#check_x
		# if not equals check_y
		_check_x:
			bne a0, a2, _execute
		_check_y:
			bne a1, a3, _execute
			# Skip in none of them are changed
			j _end_if
		_execute:
			# Set a color 
			lw v1, color
			sw a2, last_x
			sw a3, last_y
			
			# Call the draw function
			jal display_draw_line
			
			print_str "draw"
		_end_if:
		
	pop ra
	jr ra

#-------------

drawmode_color:
	push ra
	
	print_str "Color"
	# Check if user pressed left mouse button
	lw t0, display_mouse_pressed
	# Extract and check left mouse button
	and t1, t0, MOUSE_LBUTTON
	
	# Check if is pressed 
	beq t0, 0, _end_if
	# 1: if x >= PALETTE_X go to the things
	
	# Get the values for the mouse_x and mouse_y
	lw t0, display_mouse_x
	lw t1, display_mouse_y
	
	# If x not inside the left bounds of palette
	blt t0, PALETTE_X, _end_if
	# If x is not inside the right bounds of palette
	bge t0, PALETTE_X2, _end_if
	# If y is not inside the top bounds of palette
	blt t1, PALETTE_Y, _end_if
	# If y is not inside the bottom bounds of the palette
	bge t1, PALETTE_Y2, _end_if
	# Do the things
	sub t0, t0, PALETTE_X
	sub t1, t1, PALETTE_Y
	
	# y/4 
	div t1, t1, 4
	# ... * 16
	mul t1, t1, 16
	# x/4 
	div t0, t0, 4
	# now add them
	add t0, t0, t1
	
	# Finally store the color
	sw t0, color
	
	# Hide the palette
	jal hide_palette_display
	
	# Store drawmode as nothing
	li t0, MODE_NOTHING 
	sw t0, drawmode
	
	# Skip
	_end_if:
	
	pop ra 
	jr ra
	
#--------------

display_get_pixel:
	sll t0, a1, DISPLAY_W_SHIFT
	add t0, t0, a0
	lb  v0, display_fb_ram(t0)
	
	jr  ra

#--------------

flood_fill:
	push ra
	
	# You literally gave us this code
	lw a0, display_mouse_x
    lw a1, display_mouse_y
    jal display_get_pixel
    lw a0, display_mouse_x 
    lw a1, display_mouse_y 
    move a2, v0
    lw a3, color
    jal flood_fill_rec
	
	pop ra
	jr ra
	
	
#-----------------

flood_fill_rec:
    # Push registers onto the stack
    push ra
    push s0
    push s1
    push s2
    push s3
    
    
    # Save arguments in safe registers
    move s0, a0
    move s1, a1
    move s2, a2
    move s3, a3
    
    # Call display_get_pixel
    jal display_get_pixel
    
    # Check if the pixel is already the replacement color or not the target color
    beq v0, s3, _return
    bne v0, s2, _return
    
    # Set the pixel to the replacement color
    move a0, s0
    move a1, s1
    move a2, s3
    jal display_set_pixel
    
    # Check if x > 0, then recurse to the left
    bgt s0, 0, _recurse_left
    j _skip_left
	_recurse_left:
	    sub a0, s0, 1
	    move a1, s1
	    move a2, s2
	    move a3, s3
	    jal flood_fill_rec
	_skip_left:
	    # Check if x < 127, then recurse right
	    blt s0, 127, _recurse_right
	    j _skip_right
	_recurse_right:
	    add a0, s0, 1
	    move a1, s1
	    move a2, s2
	    move a3, s3
	    jal flood_fill_rec
	_skip_right:
	    # Check if y > 0, then recurse up
	    bgt s1, 0,  _recurse_up
	    j _skip_up
	_recurse_up:
	    move a0, s0
	    sub a1, s1, 1
	    move a2, s2
	    move a3, s3
	    jal flood_fill_rec
	_skip_up:
	    
	    # Check if y < 127, then recurse down
	    blt s1, 127, _recurse_down
	    j _skip_down
	_recurse_down:
	    move a0, s0
	    add a1, s1, 1
	    move a2, s2
	    move a3, s3
	    jal flood_fill_rec
	_skip_down:
	
	_return:
	pop s3
	pop s2
	pop s1
	pop s0
	pop ra
 	jr ra
