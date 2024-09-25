
.data 0xFFFF0000
	display_ctrl:           .word 0       # 0xFFFF0000
	display_sync:           .word 0       # 0xFFFF0004
	display_reset:          .word 0       # 0xFFFF0008
	display_frame_counter:  .word 0       # 0xFFFF000C

	display_fb_clear:       .word 0       # 0xFFFF0010
	display_fb_in_front:    .word 0       # 0xFFFF0014
	display_fb_pal_offs:    .word 0       # 0xFFFF0018
	display_fb_scx:         .word 0       # 0xFFFF001C
	display_fb_scy:         .word 0       # 0xFFFF0020

.data 0xFFFF0030
	display_tm_scx:         .word 0       # 0xFFFF0030
	display_tm_scy:         .word 0       # 0xFFFF0034

.data 0xFFFF0040
	display_key_held:       .word 0       # 0xFFFF0040
	display_key_pressed:    .word 0       # 0xFFFF0044
	display_key_released:   .word 0       # 0xFFFF0048
	display_mouse_x:        .word 0       # 0xFFFF004C
	display_mouse_y:        .word 0       # 0xFFFF0050
	display_mouse_held:     .word 0       # 0xFFFF0054
	display_mouse_pressed:  .word 0       # 0xFFFF0058
	display_mouse_released: .word 0       # 0xFFFF005C
	display_mouse_wheel_x:  .word 0       # 0xFFFF0060
	display_mouse_wheel_y:  .word 0       # 0xFFFF0064

.data 0xFFFF0C00
	display_palette_ram:    .word 0:256   # 0xFFFF0C00-0xFFFF0FFF
	display_palette_end:
	display_fb_ram:         .byte 0:16384 # 0xFFFF1000-0xFFFF4FFF
	display_fb_end:
	display_tm_table:       .half 0:1024  # 0xFFFF5000-0xFFFF57FF
	display_tm_end:
	display_spr_table:      .byte 0:1024  # 0xFFFF5800-0xFFFF5BFF
	display_spr_end:

.data 0xFFFF6000
	display_tm_gfx:         .byte 0:16384 # 0xFFFF6000-0xFFFF9FFF
	display_spr_gfx:        .byte 0:16384 # 0xFFFFA000-0xFFFFDFFF

.data 0x10010000
.text
