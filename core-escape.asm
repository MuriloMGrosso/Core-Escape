;██████████████████████████████████████████████████████████████████████████████████████
;  ____                             ____                                               
; /\  _`\                          /\  _`\                                             
; \ \ \/\_\    ___   _ __    __    \ \ \L\_\    ____    ___     __     _____      __   
;  \ \ \/_/_  / __`\/\`'__\/'__`\   \ \  _\L   /',__\  /'___\ /'__`\  /\ '__`\  /'__`\ 
;   \ \ \L\ \/\ \L\ \ \ \//\  __/    \ \ \L\ \/\__, `\/\ \__//\ \L\.\_\ \ \L\ \/\  __/ 
;    \ \____/\ \____/\ \_\\ \____\    \ \____/\/\____/\ \____\ \__/.\_\\ \ ,__/\ \____\
;     \/___/  \/___/  \/_/ \/____/     \/___/  \/___/  \/____/\/__/\/_/ \ \ \/  \/____/
;                                                                        \ \_\         
;                                                                         \/_/                            
;██████████████████████████████████████████████████████████████████████████████████████

; [Core Escape]
; Oh no! The lava is rising! Quick, you need to get out of here!
; In this action/adventure game, you'll need to climb caves, jungles and mountains to 
; keep your butt safe!
; How high can you reach?
;
; [Controls]
; 1) Joystick for movement.
; 2) Reset switch.
;
; [About]
; This is a fan made game for the Atari 2600. The game was build respecting the 4K 
; Atari cartridge limitation and can be played on a real console. You can also play it
; on an emulator like Stella.
; All the code bellow was provided by me - Murilo M. Grosso - and it's free to use.

;######################################################################################
;   _____            _           _           
;  |_   _|          | |         | |          
;    | |  _ __   ___| |_   _  __| | ___  ___ 
;    | | | '_ \ / __| | | | |/ _` |/ _ \/ __|
;   _| |_| | | | (__| | |_| | (_| |  __/\__ \
;  |_____|_| |_|\___|_|\__,_|\__,_|\___||___/
;
;######################################################################################

				processor 6502
				include "vcs.h"
				include "macro.h"

;######################################################################################
;   __  __                          
;  |  \/  |                         
;  | \  / | __ _  ___ _ __ ___  ___ 
;  | |\/| |/ _` |/ __| '__/ _ \/ __|
;  | |  | | (_| | (__| | | (_) \__ \
;  |_|  |_|\__,_|\___|_|  \___/|___/
;                                 
;######################################################################################

SCREEN_H		equ #192					; Screen height in scanlines
PLAYER_H		equ #13						; Player height in scanlines
TILE_H			equ	#16						; Tile height in scanlines
TILES_COUNT		equ #12						; Tiles rows per screen
SCR_PER_AREA	equ #8						; Screens per area
SCR_PER_AREA_C	equ #11						; Screens per area avaliable
MAPS_COUNT		equ #16						; Number of different maps

DEFAULT_PF_COL	equ #$00					; Default playfield color
PLAYER_COL		equ #$0e					; Player color
DEAD_PLAYER_COL	equ #$02					; Dead player color
LAVA_COL_0		equ #$38					; First lava color
LAVA_COL_1		equ #$28					; Second lava color
STT_LAVA_H		equ #20						; Initial lava height

LAVA_TIMER		equ #1						; Time to lava rise one scanline

X_MIN			equ #0						; Left bound
X_MAX			equ #152					; Right bound
Y_MIN			equ #2						; Bottom bound
Y_MAX			equ #190					; Top bound

STT_X			equ #72						; Initial player x coordinate
STT_Y			equ #74						; Initial player y coordinate
STT_SCORE		equ #5						; Initial score

RIGHT			equ #%10000000				; Right code
LEFT			equ #%01000000				; Left code
DOWN			equ #%00100000				; Down code
UP				equ #%00010000				; Up code

AUD_VOL			equ #6						; Audio volume
COL_SOUND		equ #8						; Collision sound

;######################################################################################
;  __      __        _       _     _           
;  \ \    / /       (_)     | |   | |          
;   \ \  / /_ _ _ __ _  __ _| |__ | | ___  ___ 
;    \ \/ / _` | '__| |/ _` | '_ \| |/ _ \/ __|
;     \  / (_| | |  | | (_| | |_) | |  __/\__ \
;      \/ \__,_|_|  |_|\__,_|_.__/|_|\___||___/
;                                         
;######################################################################################                                           

				seg.u vars
				org $80

playerX			ds 1						; Player x coordinate
playerY			ds 1						; Player y coordinate
prevPlayerX		ds 1						; Previous player x coordinate
prevPlayerY		ds 1						; Previous player y coordinate
playerMove		ds 1						; Player movement direction 
											; R|L|D|U|0|0|0|0
isPlayerDead	ds 1						; Indicates whether the player is dead
prevCollided	ds 1						; Indicates whether player collided

tileTimer		ds 1						; Timer for tile changing
screen			ds 1						; Current screen
areaScreenIdx	ds 1						; Current area screen table index
area			ds 1						; Current area
randMap			ds 1						; Random map generator
currentMap		ds 1						; Current map

score			ds 1						; Score
prevScore		ds 1						; Previous score
digitIdx0		ds 1						; First score digit index
digitIdx1		ds 1						; Second score digit index
digitIdx2		ds 1						; Third score digit index
digitIdx3		ds 1						; Fourth score digit index
digitPF0		ds 5						; Third score digit buffer
digitPF1		ds 5						; First and second score digits buffer
digitPF2		ds 5						; Last score digit buffer
digitTemp		ds 1						; Temporary variable to store digits

lavaHeight		ds 1						; Lava height
lavaTimer		ds 1						; Timer for rise lava
lavaColor		ds 1						; Current lava color
lavaScreen		ds 1						; Current lava screen

temp			ds 1 						; Temporary variable

pf0Buffer		ds 12						; PF0 buffer
pf1Buffer		ds 12						; PF1 buffer
pf2Buffer		ds 12						; PF2 buffer

gameStarted		ds 1						; Indicates whether the game started

				seg	main
				org $f000

;######################################################################################
;   _____                _   
;  |  __ \              | |  
;  | |__) |___  ___  ___| |_ 
;  |  _  // _ \/ __|/ _ \ __|
;  | | \ \  __/\__ \  __/ |_ 
;  |_|  \_\___||___/\___|\__|
;                    
;######################################################################################

reset:			CLEAN_START

;.............................. PLAYER COLOR ..........................................
				lda #PLAYER_COL				; (2)
				sta COLUP0					; (3)

;.............................. INITIAL PLAYER POSITION ...............................
				lda #STT_X					; (2)
				sta playerX					; (3)
				sta prevPlayerX				; (3)
				lda #STT_Y					; (2)
				sta playerY					; (3)
				sta prevPlayerY				; (3)

;.............................. INITIAL LAVA POSITION .................................
				lda #STT_LAVA_H				; (2)
				sta lavaHeight				; (3)

;.............................. INITIAL SCORE .........................................
				lda #STT_SCORE-1			; (2)
				sta digitIdx0				; (3)

;.............................. TIMERS ................................................
				lda #LAVA_TIMER				; (2)
				sta lavaTimer				; (3)

;.............................. LAVA AUDIO ............................................
				lda #2						; (2)
				sta AUDC1					; (3)
				lda #20						; (2)
				sta AUDF1					; (3)
				lda #0						; (2)
				sta AUDV1					; (3)

;######################################################################################
;   _    _           _       _       
;  | |  | |         | |     | |      
;  | |  | |_ __   __| | __ _| |_ ___ 
;  | |  | | '_ \ / _` |/ _` | __/ _ \
;  | |__| | |_) | (_| | (_| | ||  __/
;   \____/| .__/ \__,_|\__,_|\__\___|
;         | |                        
;         |_|                        
;######################################################################################

;--------------------------------------------------------------------------------------
;  __   __       _   _         _   ___                 ________  
;  \ \ / /__ _ _| |_(_)__ __ _| | / __|_  _ _ _  __   / /__ /\ \ 
;   \ V / -_) '_|  _| / _/ _` | | \__ \ || | ' \/ _| | | |_ \ | |
;    \_/\___|_|  \__|_\__\__,_|_| |___/\_, |_||_\__| | ||___/ | |
;                                      |__/           \_\    /_/ 
;--------------------------------------------------------------------------------------

startFrame:		lda #0            			; (2)       
				sta VBLANK					; (3)
				lda #2                   	; (2)
				sta VSYNC                	; (3)
				sta WSYNC                	; (3)
				sta WSYNC					; (3)
				sta WSYNC					; (3)
				lda #0						; (2)
				sta VSYNC					; (3)

;--------------------------------------------------------------------------------------
;  __   __       _   _         _   ___ _           _      ____________  
;  \ \ / /__ _ _| |_(_)__ __ _| | | _ ) |__ _ _ _ | |__  / /__ /__  \ \ 
;   \ V / -_) '_|  _| / _/ _` | | | _ \ / _` | ' \| / / | | |_ \ / / | |
;    \_/\___|_|  \__|_\__\__,_|_| |___/_\__,_|_||_|_\_\ | ||___//_/  | |
;                                                        \_\        /_/ 
;--------------------------------------------------------------------------------------

;.............................. EMPTY SCANLINES .......................................
; 				ldx #0						; (2)
; verticalBlank:	sta WSYNC					; (3)				
; 				inx							; (2)
; 				cpx #1    					; (2)
; 				bne verticalBlank			; (2/3)

;.............................. RESET .................................................
		        lda #%00000001				; (2)
                bit SWCHB					; (3)
                beq reset					; (2/3)

;.............................. RIGHT WARP ............................................
				lda #X_MAX+1				; (2)
				clc							; (2)
				sbc playerX					; (3)
				bcc	continueWarp			; (2/3)
				jmp skipWarp				; (3)
	
continueWarp:	lda #X_MIN-10				; (2)
				clc							; (2)
				sbc playerX					; (3)
				bcc	rightWarp				; (2/3)
				jmp skipWarp				; (3)
				
rightWarp:		lda #X_MAX					; (2)
				sta playerX					; (3)
				lda #X_MIN					; (2)
				sta prevPlayerX				; (3)

skipWarp:		sta WSYNC					; (3)

;.............................. PLAYFIELD BUFFER ......................................
				ldx currentMap				; (3)
				lda mapOffset,x				; (4)
				clc							; (2)
				adc areaScreenIdx			; (3)
				tay							; (2)
				ldx RAND_SCREEN,y			; (4)
				ldy screenOffset,x			; (4)
				ldx area					; (3)
				beq caveBuffer				; (2/3)
				dex							; (2)
				beq jungleBuffer			; (2/3)
				dex							; (2)
				beq rocksBuffer				; (2/3)
				dex							; (2)
				beq mountainBuffer			; (2/3)
				dex							; (2)
				beq iceBuffer				; (2/3)
				dex							; (2)
				beq spaceBuffer				; (2/3)

				ldx #0						; (2)

caveBuffer:		lda PF0_CAVE,y				; (4)
				sta pf0Buffer,x				; (3)
				lda PF1_CAVE,y				; (4)
				sta pf1Buffer,x				; (3)
				lda PF2_CAVE,y				; (4)
				sta pf2Buffer,x				; (3)
				inx							; (2)
				iny							; (2)			
				cpx #12    					; (2)
				bne caveBuffer				; (2/3)
				jmp endPlayfieldBuffer		; (3)

jungleBuffer:	lda PF0_JUNGLE,y			; (4)
				sta pf0Buffer,x				; (3)
				lda PF1_JUNGLE,y			; (4)
				sta pf1Buffer,x				; (3)
				lda PF2_JUNGLE,y			; (4)
				sta pf2Buffer,x				; (3)
				inx							; (2)
				iny							; (2)		
				cpx #12    					; (2)
				bne jungleBuffer			; (2/3)
				jmp endPlayfieldBuffer		; (3)

rocksBuffer:	lda PF0_ROCKS,y				; (4)
				sta pf0Buffer,x				; (3)
				lda PF1_ROCKS,y				; (4)
				sta pf1Buffer,x				; (3)
				lda PF2_ROCKS,y				; (4)
				sta pf2Buffer,x				; (3)
				inx							; (2)
				iny							; (2)
				sta WSYNC					; (3)			
				cpx #12    					; (2)
				bne rocksBuffer				; (2/3)
				jmp endPlayfieldBuffer		; (3)

mountainBuffer:	lda PF0_MOUNTAIN,y			; (4)
				sta pf0Buffer,x				; (3)
				lda PF1_MOUNTAIN,y			; (4)
				sta pf1Buffer,x				; (3)
				lda PF2_MOUNTAIN,y			; (4)
				sta pf2Buffer,x				; (3)
				inx							; (2)
				iny							; (2)			
				cpx #12    					; (2)
				bne mountainBuffer			; (2/3)
				jmp endPlayfieldBuffer		; (3)

iceBuffer:		lda PF0_ICE,y				; (4)
				sta pf0Buffer,x				; (3)
				lda PF1_ICE,y				; (4)
				sta pf1Buffer,x				; (3)
				lda PF2_ICE,y				; (4)
				sta pf2Buffer,x				; (3)
				inx							; (2)
				iny							; (2)		
				cpx #12    					; (2)
				bne iceBuffer				; (2/3)
				jmp endPlayfieldBuffer		; (3)

spaceBuffer:	lda PF0_SPACE,y				; (4)
				sta pf0Buffer,x				; (3)
				lda PF1_SPACE,y				; (4)
				sta pf1Buffer,x				; (3)
				lda PF2_SPACE,y				; (4)
				sta pf2Buffer,x				; (3)
				inx							; (2)
				iny							; (2)			
				cpx #12    					; (2)
				bne jungleBuffer			; (2/3)
				jmp endPlayfieldBuffer		; (3)

endPlayfieldBuffer:
				sta WSYNC					; (3)

;.............................. LAVA ..................................................
				lda lavaHeight				; (3)
				cmp #Y_MAX					; (2)
				bne dontLavaScreen			; (2/3)
				lda #0						; (3)
				sta lavaHeight				; (3)
				inc lavaScreen				; (5)
dontLavaScreen:
				lda gameStarted				; (3)
				beq	dontIncLava				; (2/3)
				dec lavaTimer				; (5)
				bne dontIncLava				; (2/3)
				inc lavaHeight				; (5)
				lda #LAVA_TIMER				; (2)
				clc 						; (2)
				adc lavaColor				; (3)
				sta lavaTimer				; (3)
				lda lavaColor				; (3)
				eor #1						; (2)
				sta lavaColor				; (3)
dontIncLava:	sta WSYNC					; (3)
				lda screen					; (3)
				sec							; (2)
				sbc lavaScreen				; (3)
				sta temp					; (3)
				lda #2						; (2)
				clc							; (2)
				sbc temp					; (3)
				lda #0						; (2)
				bcc	skipLavaSound			; (3)
				ldx temp					; (3)
				lda #7						; (2)
				sec							; (2)
				sbc multFive,x				; (4)
skipLavaSound:	sta AUDV1					; (3)

				sta WSYNC					; (3)

;.............................. CALCULATE SCORE .......................................
				lda playerY					; (3)
				lsr							; (2)
				lsr							; (2)
				lsr							; (2)
				lsr							; (2)
				sta score					; (3)

				cmp prevScore				; (3)
				beq scoreNotChanged			; (2/3)
scoreChanged:	clc							; (2)
				sbc prevScore				; (3)
				bcc scoreSmaller			; (2/3) 
				inc digitIdx0				; (5)
				jmp scoreNotChanged			; (3)
scoreSmaller:	dec digitIdx0				; (5)
scoreNotChanged:lda score					; (3)
				sta prevScore				; (3)

				sta WSYNC					; (3)

				lda digitIdx0				; (3)
				cmp #10						; (2)
				bne notIncrement			; (2/3)
				lda #0						; (2)
				sta digitIdx0				; (3)
				inc digitIdx1				; (5)

				lda digitIdx1				; (3)
				cmp #10						; (2)
				bne notIncrement			; (2/3)
				lda #0						; (2)
				sta digitIdx1				; (3)
				inc digitIdx2				; (5)

				lda digitIdx2				; (3)
				cmp #10						; (2)
				bne notIncrement			; (2/3)
				lda #0						; (2)
				sta digitIdx2				; (3)
				inc digitIdx3				; (5)		

notIncrement:   sta WSYNC					; (3)

				lda digitIdx0				; (3)
				cmp #-1						; (3)
				bne notDecrement			; (2/3)
				lda #9						; (2)
				sta digitIdx0				; (3)
				dec digitIdx1				; (5)

				lda digitIdx1				; (3)
				cmp #-1						; (3)
				bne notDecrement			; (2/3)
				lda #9						; (2)
				sta digitIdx1				; (3)
				dec digitIdx2				; (5)

				lda digitIdx2				; (3)
				cmp #-1						; (3)
				bne notDecrement			; (2/3)
				lda #9						; (2)
				sta digitIdx2				; (3)
				dec digitIdx3				; (5)		

notDecrement:   sta WSYNC					; (3)

;.............................. SCORE BUFFERS .........................................
				ldx #0						; (2)
scoreDigits:	ldy digitIdx0				; (3)		
				txa							; (2)
				clc							; (2)
				adc multFive,y				; (4)
				tay							; (2)
				lda DIGITS,y				; (3)
				and #%00001111				; (2)
				sta digitTemp				; (3)

				ldy digitIdx1				; (3)		
				txa							; (2)
				clc							; (2)
				adc multFive,y				; (4)
				tay							; (2)
				lda DIGITS,y				; (3)
				and #%11110000				; (2)
				clc							; (2)
				adc digitTemp				; (3)
				sta digitPF1,x				; (4)

				sta WSYNC					; (3)	

				ldy digitIdx2				; (3)		
				txa							; (2)
				clc							; (2)
				adc multFive,y				; (4)
				tay							; (2)
				lda DIGITS_REV,y			; (3)
				sta digitPF0,x				; (4)

				ldy digitIdx3				; (3)		
				txa							; (2)
				clc							; (2)
				adc multFive,y				; (4)
				tay							; (2)
				lda DIGITS_REV,y			; (3)
				and #%11110000				; (2)
				sta digitPF2,x				; (4)

				inx							; (2)
				sta WSYNC					; (3)
				cpx #5    					; (2)
				bne scoreDigits				; (2/3)

				sta WSYNC					; (3)

;.............................. DRAWSCORE .............................................
				lda #%11111110				; (2)
				sta	CTRLPF					; (3)
				
				lda #%00000000				; (2)
				sta PF0						; (3)
				sta PF1						; (3)
				sta PF2						; (3)

				lda #PLAYER_COL				; (2)
				sta COLUPF					; (3)
				lda #DEFAULT_PF_COL			; (2)
				sta COLUBK					; (3)

				sta WSYNC					; (3)

				SLEEP 4
				ldx #0						; (2)
drawScore:		lda #%00000000				; (2)
				sta PF0						; (3)
				sta PF1						; (3)
				sta PF2						; (3)

				txa							; (2)
				lsr							; (2)
				tay							; (2)
				lda digitPF2,y				; (4)
				sta PF2						; (3)
				lda digitPF0,y				; (4)
				sta PF0						; (3)
				lda digitPF1,y				; (4)
				sta PF1						; (3)

				lda LETTERS,y				; (2)
				sta PF2						; (2)

				sta WSYNC					; (3)		
				inx							; (2)
				cpx #10    					; (2)
				bne drawScore				; (2/3)

				lda pf0Buffer				; (3)
				and #%00000001				; (2)
				eor	#%11111110				; (2)
				sta	CTRLPF					; (3)

;.............................. COLOR .................................................

				ldx area					; (3)
				lda PF_COL,x				; (4)
				sta COLUPF					; (3)
				lda BG_COL,x				; (4)				
				ldx screen					; (3)
				cpx lavaScreen				; (3)
				bne darkBG					; (2/3)
				clc							; (2)
				adc #2						; (2)
darkBG:			sta COLUBK					; (3)
				lda #%11111111				; (2)
				sta PF0						; (3)
				sta PF1						; (3)
				sta PF2						; (3)

;.............................. HORIZONTAL PLAYER POSITION ............................
				lda playerX					; (3)
				ldx #0						; (2)
	        	sta WSYNC	        		; (3)
                bit 0               		; (3)
	            sec		            		; (2)
hPlayer:        sbc #15		        		; (2)
	            bcs hPlayer	    			; (2/3)
	            eor #7		        		; (2)
	            asl                 		; (2)
	            asl                 		; (2)
	            asl                 		; (2)
	            asl                 		; (2)
	            sta RESP0,x	        		; (3)
	            sta HMP0,x	        		; (3)

				sta WSYNC					; (3)
				sta HMOVE					; (3)

				sta WSYNC					; (3)

;--------------------------------------------------------------------------------------
;   ___                   __ _     _    _    ___ ___ _____  
;  |   \ _ _ __ ___ __ __/ _(_)___| |__| |  / / / _ \_  ) \ 
;  | |) | '_/ _` \ V  V /  _| / -_) / _` | | || \_, // / | |
;  |___/|_| \__,_|\_/\_/|_| |_\___|_\__,_| | ||_|/_//___|| |
;                                           \_\         /_/ 
;--------------------------------------------------------------------------------------

;.............................. LAVA BACKGROUND .......................................
				lda lavaScreen				; (3)
				clc							; (2)
				sbc screen					; (3)
				bcc notScreenInLava			; (2/3)
				ldy #LAVA_COL_0				; (2)
				lda lavaColor				; (3)
				bne otherLavaCol			; (2/3)
				ldy #LAVA_COL_1				; (2)
otherLavaCol:	sty COLUBK					; (3)
notScreenInLava:

;.............................. START DRAWFILED .......................................
				lda #0						; (2)
				sta tileTimer				; (3)
				ldx #SCREEN_H				; (2)

drawField:		lda tileTimer				; (3)
                bne drawPlayer				; (2/3)

;.............................. PLAYFIELD .............................................
				ldy divideTileHeight,x		; (4)
				lda pf0Buffer,y				; (4)
				sta WSYNC					; (3)
				sta PF0						; (3)
				lda pf1Buffer,y				; (4)
				sta PF1						; (3)
				lda pf2Buffer,y				; (4)
				sta PF2						; (3)

				lda #TILE_H					; (2)
				sta tileTimer				; (3)

				dex							; (2)
				bne drawField				; (2/3)
				jmp endDrawfield			; (3)

;.............................. DRAW PLAYER ...........................................
drawPlayer:		txa							; (2)
				sec						    ; (2)
				sbc playerY					; (3)
				cmp #PLAYER_H				; (2)
				bcc playerSprite			; (2/3)
				lda #0					    ; (2)
playerSprite:	tay							; (2)
				lda	PLAYER_SPR,y			; (4)
				sta WSYNC					; (3)
				sta	GRP0					; (3)

;.............................. LAVA ..................................................
				ldy screen					; (3)
				cpy lavaScreen				; (3)
				bne dontDrawnLava			; (2/3)

				cpx lavaHeight				; (3)
				bne dontDrawnLava			; (2/3)
				ldy #LAVA_COL_0				; (2)
				lda lavaColor				; (3)
				bne otherLavaColor			; (2/3)
				ldy #LAVA_COL_1				; (2)
otherLavaColor:	sty COLUBK					; (3)
dontDrawnLava:

				dec tileTimer				; (5)
				dex							; (2)
				bne drawField				; (2/3)

;.............................. END DRAWFIELD .........................................
endDrawfield:	lda #%01000010				; (2)
				sta VBLANK					; (3)

;.............................. CLEAR PLAYFIELD .......................................
				sta WSYNC					; (3)
				lda	#%11111111				; (2)
				sta PF0						; (3)
				sta PF1						; (3)
				sta PF2						; (3)

;--------------------------------------------------------------------------------------
;    ___                                  ______ ____  
;   / _ \__ _____ _ _ ___ __ __ _ _ _    / /__ //  \ \ 
;  | (_) \ V / -_) '_(_-</ _/ _` | ' \  | | |_ \ () | |
;   \___/ \_/\___|_| /__/\__\__,_|_||_| | ||___/\__/| |
;                                        \_\       /_/ 
;--------------------------------------------------------------------------------------

;.............................. EMPTY SCANLINES .......................................
				ldx #0						; (2)
overscan:       sta WSYNC					; (3)
				inx							; (2)
				cpx #21						; (2)
				bne overscan				; (2/3)
				sta WSYNC					; (3)

;.............................. RANDOM MAP GENERATOR ..................................
				inc randMap					; (5)
				lda randMap					; (3)
				cmp #MAPS_COUNT				; (2)
				bne dontResetMap			; (2/3)
				lda #0						; (2)
				sta randMap					; (3)
dontResetMap:	sta WSYNC					; (3)

;.............................. AUDIO .................................................
				lda lavaTimer				; (3)
				asl							; (2)
				asl							; (2)
				asl							; (2)
				sta AUDF0					; (3)
				lda #AUD_VOL				; (2)
				sta AUDV0					; (3)
				lda #0						; (2)
				sta AUDC0					; (3)
				sta WSYNC					; (3)

;.............................. LEFT WARP .............................................
				lda #X_MAX+1				; (2)
				clc							; (2)
				sbc playerX					; (3)
				bcc	leftWarp				; (2/3)
				jmp skipLeftWarp			; (3)
	
leftWarp:		lda #X_MIN					; (2)
				sta playerX					; (3)
				lda #X_MAX					; (2)
				sta prevPlayerX				; (3)

skipLeftWarp:	sta WSYNC					; (3)

;.............................. CHANGE SCREEN .........................................
				lda #Y_MAX					; (2)
				clc							; (2)
				sbc playerY					; (3)
				bcc	nextScreen				; (2/3)

				lda playerY					; (2)
				clc							; (2)
				sbc #Y_MIN					; (3)
				bcc	prevScreen				; (2/3)

;.............................. COLLISION .............................................
				lda CXP0FB              	; (2)
				bmi collision				; (2/3)
				lda playerX					; (3)
				sta prevPlayerX				; (3)
				lda playerY					; (3)
				sta prevPlayerY				; (3)
				lda #0						; (2)
				sta prevCollided			; (3)
				jmp noCollision				; (3)

collision:		lda prevPlayerX				; (3)
				sta playerX					; (3)
				lda prevPlayerY				; (3)
				sta playerY					; (3)
				lda #0						; (2)
				sta playerMove				; (3)
				lda prevCollided			; (3)
				bne noCollision				; (2/3)
				lda #1						; (2)
				sta prevCollided			; (3)
				lda #COL_SOUND				; (2)
				sta AUDC0					; (3)
				jmp noCollision				; (3)

nextScreen:		inc screen					; (5)
				inc areaScreenIdx			; (5)
				lda #Y_MIN					; (2)
				sta playerY					; (3)
				sta prevPlayerY				; (3)

 				lda areaScreenIdx			; (3)
 				cmp #SCR_PER_AREA			; (2)
 				bne	noCollision				; (2/3)
 				lda #0						; (2)
 				sta areaScreenIdx			; (3)
				inc area					; (5)
				lda randMap					; (3)
				sta currentMap				; (3)
				jmp noCollision				; (3)

prevScreen:		dec screen					; (5)
				dec areaScreenIdx			; (5)
				lda #Y_MAX					; (2)
				sta playerY					; (3)
				sta prevPlayerY				; (3)

 				lda areaScreenIdx			; (3)
 				cmp #$ff					; (2)
 				bne	noCollision				; (2/3)
 				lda #SCR_PER_AREA-1			; (2)
 				sta areaScreenIdx			; (3)
				dec area					; (5)

noCollision:	sta CXCLR					; (3)

				sta WSYNC					; (3)

;.............................. INPUT .................................................
				lda playerMove				; (3)
				bne skipInput				; (2/3)

                lda #RIGHT      			; (2)
                bit SWCHA					; (3)
                beq skipInput				; (2/3)

				lda #LEFT      				; (2)
                bit SWCHA					; (3)
                beq skipInput				; (2/3)

				lda #DOWN      				; (2)
                bit SWCHA					; (3)
                beq skipInput				; (2/3)

				lda #UP      				; (2)
                bit SWCHA					; (3)
                beq skipInput				; (2/3)

				lda #0						; (2)
skipInput:		sta playerMove				; (3)
				beq	notMoveSound			; (2)
				lda #1						; (2)
				sta AUDV0					; (3)
				lda #12						; (2)
				sta AUDC0					; (3)
notMoveSound:
				sta WSYNC					; (3)

;.............................. MOVEMENT ..............................................
				ldx playerX					; (3)
				ldy playerY					; (3)

				lda playerMove				; (3)
				beq skipMovement			; (2/3)

				lda gameStarted				; (3)
				bne	skipInitialGeneration	; (2/3)
				lda randMap					; (3)
				sta currentMap				; (3)
				lda #1						; (2)
				sta gameStarted				; (3)
skipInitialGeneration:
				lda isPlayerDead			; (3)
				bne	skipMovement			; (2/3)

movement:		lda #RIGHT      			; (2)
                bit playerMove				; (3)
                beq notMovingRight			; (2/3)
                inx							; (2)
                inx							; (2)
                lda #%00001000				; (2)
                sta REFP0					; (3)
				jmp skipMovement			; (3)

notMovingRight:	lda #LEFT      				; (2)
                bit playerMove				; (3)
                beq notMovingLeft			; (2/3)
                dex							; (2)
                dex							; (2)
                lda #0						; (2)
                sta REFP0                	; (3)
				jmp skipMovement			; (3)

notMovingLeft:	lda #DOWN      				; (2)
                bit playerMove				; (3)
                beq notMovingDown			; (2/3)
                dey							; (2)
                dey							; (2)
                dey							; (2)
				jmp skipMovement			; (3)

notMovingDown:	lda #UP      				; (2)
                bit playerMove				; (3)
                beq skipMovement			; (2/3)
                iny							; (2)
                iny							; (2)
                iny							; (2)

skipMovement: 	stx playerX					; (3)
				sty playerY					; (3)

				sta WSYNC					; (3)

;.............................. LAVA CHECK ............................................
				lda lavaScreen				; (3)
				cmp screen					; (3)
				bne difLavaScreen			; (3)
				lda lavaHeight				; (3)
				clc							; (2)
				sbc playerY					; (3)
				bcc notInLava				; (2/3)
				lda isPlayerDead			; (3)
				lda #1						; (2)
				sta isPlayerDead			; (3)
				lda #DEAD_PLAYER_COL		; (2)
				sta COLUP0					; (3)
				lda #0						; (2)
				sta playerMove				; (3)	
				jmp notInLava				; (3)

difLavaScreen:	clc							; (2)
				sbc screen					; (3)
				bcc notInLava				; (2/3)
				lda #1						; (2)
				sta isPlayerDead			; (3)
				lda #DEAD_PLAYER_COL			; (2)
				sta COLUP0					; (3)
notInLava:		sta WSYNC					; (3)

				jmp startFrame				; (3)

;######################################################################################
;    ____                       _   _                 
;   / __ \                     | | (_)                
;  | |  | |_ __   ___ _ __ __ _| |_ _  ___  _ __  ___ 
;  | |  | | '_ \ / _ \ '__/ _` | __| |/ _ \| '_ \/ __|
;  | |__| | |_) |  __/ | | (_| | |_| | (_) | | | \__ \
;   \____/| .__/ \___|_|  \__,_|\__|_|\___/|_| |_|___/
;         | |                                         
;         |_|                                         
;######################################################################################

divideTileHeight									
.POS			SET 0								
				REPEAT #SCREEN_H+1
				.byte (.POS-2) / #TILE_H
.POS			SET .POS+1
				REPEND	

multFive									
.POS			SET 0								
				REPEAT #10
				.byte .POS * #5
.POS			SET .POS + 1
				REPEND

screenOffset
.POS			SET 0								
				REPEAT #SCR_PER_AREA_C
				.byte .POS * #TILES_COUNT
.POS			SET .POS + 1
				REPEND

mapOffset
.POS			SET 0								
				REPEAT #MAPS_COUNT
				.byte .POS * #SCR_PER_AREA
.POS			SET .POS + 1
				REPEND

;######################################################################################
;    _____            _ _            
;   / ____|          (_) |           
;  | (___  _ __  _ __ _| |_ ___  ___ 
;   \___ \| '_ \| '__| | __/ _ \/ __|
;   ____) | |_) | |  | | ||  __/\__ \
;  |_____/| .__/|_|  |_|\__\___||___/
;         | |                        
;         |_|                                            
;######################################################################################

PLAYER_SPR     	.byte %00000000
				.byte %01101100
				.byte %00100100
				.byte %00100100
				.byte %00101100
				.byte %10111101
				.byte %10111101
				.byte %01111110
				.byte %01111110
				.byte %00111100
				.byte %00011000
				.byte %00111000
				.byte %00111000

;######################################################################################
;   _____  _              __ _      _     _   _____        _        
;  |  __ \| |            / _(_)    | |   | | |  __ \      | |       
;  | |__) | | __ _ _   _| |_ _  ___| | __| | | |  | | __ _| |_ __ _ 
;  |  ___/| |/ _` | | | |  _| |/ _ \ |/ _` | | |  | |/ _` | __/ _` |
;  | |    | | (_| | |_| | | | |  __/ | (_| | | |__| | (_| | || (_| |
;  |_|    |_|\__,_|\__, |_| |_|\___|_|\__,_| |_____/ \__,_|\__\__,_|
;                   __/ |                                           
;                  |___/                                                                                 
;######################################################################################

				include "digits.h"
				include "playfield.h"
				include "colors.h"
				include "random_rooms.h"

;######################################################################################
;   ______           _ 
;  |  ____|         | |
;  | |__   _ __   __| |
;  |  __| | '_ \ / _` |
;  | |____| | | | (_| |
;  |______|_| |_|\__,_|
;                                                                         
;######################################################################################      

				org $fffa
	
interruptVectors:
				.word reset     			; nmi
				.word reset     			; reset
				.word reset     			; irq