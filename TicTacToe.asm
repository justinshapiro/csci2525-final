TITLE TicTacToe.asm
; Best viewed in Notepad++

INCLUDE Irvine32.inc ; used for procedures where call was used rather than INVOKE

;============================================= PROCEDURE PROTOTYPES ======================================================================;
CheckInput 		    PROTO userInput_param:DWORD, instanceType_param:BYTE	                    							              ;
DisplayMenu 	    PROTO			                                                          								              ;
RouteUser  		    PROTO userInput_param2:DWORD   	                                            						                  ;
InstructionsPrint   PROTO																        							              ;
RunGame_PvC         PROTO name_param:PTR BYTE, name_size:BYTE																			  ;
RunGame_CvC			PROTO							    							          											  ;
UpdateGameBoard     PROTO player_type_param:BYTE, assign_type_param:BYTE, location_param:DWORD, gameBoard_param:PTR BYTE                  ;
PrintBoard			PROTO																									              ;
PrintGameBoardMoves PROTO gameBoard_param2:PTR BYTE  																		              ;
GoToScreenPos		PROTO pos_num_param:BYTE																				              ;
FindWin				PROTO gameBoard_param3:DWORD, num_moves_param:BYTE, name_param2:PTR BYTE, P1_param:BYTE, instanceType_param2:BYTE								  ;					;
WinTests			PROTO param1:BYTE, param2:DWORD, param3:BYTE, param4:DWORD, param5:BYTE, param6:DWORD, gameBoard_param3:PTR BYTE	  ;
DrawWinPath			PROTO l_param1:BYTE, h_param2:BYTE, l_param_3:BYTE, h_param4:BYTE, l_param5:BYTE, h_param6:BYTE, path_type_param:BYTE ;	         	;
;======================================================================================================================================== ;

.code 
	main PROC
	;************************************************************************************************
	;Description - directs user to the appropriate point in the program based on their choice 
	;			   by using INVOKE to first display a menu, then retrieve user input, then to
	;			   pass this input to another procedure using INVOKE to route the user accordingly 
	;Recieves - nothing
	;Returns - nothing
	;************************************************************************************************
		.data
			userInput1    DWORD 0     ; needed to retrieve user input for eax to pass to CheckInput PROC
			select_option BYTE "                                                Selection: ", 0			
			
		.code			
			Menu: INVOKE DisplayMenu					; go to the DisplayMenu procedure to display a menu of choices for the user 
	
			Selection: mov eax, lightCyan
					   call SetTextColor

					   mov edx, OFFSET select_option	; Prompt: "Selection: "
					   call WriteString
					   call ReadDec
							mov userInput1, eax
							INVOKE CheckInput, userInput1, 1	; CheckInput([user input]:DWORD, [type of error check]:BYTE)
							cmp dl, 1							; if check fails, CheckInput returns 1 in dl
								je Selection
							cmp dl, 2							; if check indicates an exit option, CheckInput returns 2 in dl
								je exitProgram
			
			INVOKE RouteUser, userInput1						; RouteUser([user input]:DWORD)
			jmp Menu
	
	exitProgram: exit
	main ENDP
			
	DisplayMenu PROC
	;**********************************************************************************
	;Description - displays a menu that promps the user to select one of four options
	;Recieves - nothing
	;Returns - nothing
	;**********************************************************************************
		.data
			menu_Prmt BYTE "     .___________. __    ______        .___________.    ___       ______        .___________.  ______    _______      ", 0
					  BYTE "     |           ||  |  /      |       |           |   /   \     /      |       |           | /  __  \  |   ____|     ", 0
					  BYTE "     `---|  |----`|  | |  ,----' ______`---|  |----`  /  ^  \   |  ,----' ______`---|  |----`|  |  |  | |  |__        ", 0
					  BYTE "         |  |     |  | |  |     |______|   |  |      /  /_\  \  |  |     |______|   |  |     |  |  |  | |   __|       ", 0
					  BYTE "         |  |     |  | |  `----.           |  |     /  _____  \ |  `----.           |  |     |  `--'  | |  |____      ", 0
					  BYTE "         |__|     |__|  \______|           |__|    /__/     \__\ \______|           |__|      \______/  |_______|     ", 0
					  BYTE " =====================================================================================================================", 0
			func1Prmt BYTE "                                          CHOOSE HOW YOU WANT TO PLAY:", 0
			func2Prmt BYTE "                                          1. Player vs. Computer      ", 0
			func3Prmt BYTE "                                          2. Computer vs. Computer    ", 0
			func4Prmt BYTE "                                          3. exit                     ", 0
																										
		.code
			mov ecx, 7
			mov bl, 0
			mov eax, lightGreen
			call SetTextColor
			printMenu: mov edx, OFFSET menu_Prmt		; a loop used to print the menu, where each array is of equal length
					   mov eax, 0
					   mov al, LENGTHOF menu_Prmt
					   mul bl							; multiplication by bl determines which line to print
						 
					   add edx, eax						; after multiplication by bl, the result stored in ax is added to edx
					   call WriteString
					   call Crlf
					   inc bl
			loop printMenu
			
			call Crlf
			call Crlf
			
			mov ecx, 4
			mov bl, 0
			mov eax, lightCyan
			call SetTextColor
			printMenu2: mov edx, OFFSET func1Prmt	
					    mov eax, 0
					    mov al, LENGTHOF func1Prmt
					    mul bl							
						 
					    add edx, eax						
					    call WriteString
					    call Crlf
					    inc bl
			loop printMenu2
			
			call Crlf
			call Crlf	
	ret
	DisplayMenu ENDP
	
	CheckInput PROC x1:DWORD, y1:BYTE	
	;*******************************************************************************************
	;Description - a reusable procedure for checking user input in many different ways
	;Recieves - user input as a DWORD parameter and a number indicating what type of checking
	;			to perform as BYTE parameter
	;Returns - 0, 1 or 2 in the dl register
	;*******************************************************************************************
		.data
			user_input1    EQU [x1 + 4]
			instance_type  EQU [y1 + 4]
			
			failCheck			   BYTE ?	; 0 = success, 1 = fail, 2 = program exit code
			
			overflow_prompt        BYTE "Sorry, that number exceeds 32-bits. ", 0
			signed_prompt          BYTE "Sorry, input must be unsigned. ", 0
			range_prompt		   BYTE "That is not a valid move. Please enter 1 - 9. "
			menuError_prompt       BYTE "Input must be a 1, 2, or 3. ", 0
			
		.code
			push ebp							; create stack frame
			mov ebp, esp
			
			jo overflowError					; regardless of type check selected, if the overflow flag is set, display a specific error 
			cmp user_input1, 0					; if user input is less than zero at any point of the program, display a signed error
				jl rangeCmp			
				
			cmp instance_type, 1				; Check 1: used for tracking menu choices
				je menuCmp
			cmp instance_type, 2			
				je rangeCmp
			cmp instance_type, 3				; Check 3: used to check if a number is in a specific range
				je rangeCmp
			
			menuCmp: cmp user_input1, 3			; there are 3 menu options, therefore if user input is greater, throw an error 
						jg menuError
					 cmp user_input1, 0
						jle menuError
					 jmp doneChecking	
						 
			rangeCmp: cmp user_input1, 0
						jl RangeSignedError
						je RangeError
					  cmp user_input1, 9
						jg RangeError
					jmp doneChecking
					  
			overflowError: mov edx, OFFSET overflow_prompt
						   jmp displayError
								   
			MenuError: mov edx, OFFSET menuError_prompt
					   jmp displayError
					   
			RangeSignedError: mov edx, OFFSET signed_prompt
							  jmp displayError
			RangeError: mov edx, OFFSET range_prompt
						jmp displayError
			
			displayError: call Crlf				; all error messages displayed will use this label to be printed. edx must have the offset 
						  mov eax, lightRed		; all error messages are displayed in red text
						  call SetTextColor
						   
						  mov ecx, 38
						  Spce: mov al, ' '
						        call WriteChar
						  loop Spce
						  call WriteString
						  call Crlf
						  
						  mov ecx, 38
						  Spce2: mov al, ' '
						         call WriteChar
						  loop Spce2
						  call WaitMsg
						   
						  mov eax, white
						  call SetTextColor
						   
						  jo clrOF				; clear the overflow flag if it has been set 
						  jmp skip_clrOF
						   
						  clrOF: mov cl, 1
								 neg cl
						   
						  skip_clrOF:
						  call Crlf
						  call Crlf
						   
						  mov failCheck, 1		; if program reaches this point, input is invalid
						  jmp leaveProc1
		
			doneChecking: cmp user_input1, 3	; if program is sent to this label, input is valid
							je setExitCode
						mov failCheck, 0
						jmp leaveProc1
				  
			setExitCode: mov failCheck, 2		; in the special case where user input is 4, generate program exit code
	
			leaveProc1: mov dl, failCheck
						leave
			   
	ret
	CheckInput ENDP
	
	RouteUser PROC x2:DWORD
	;************************************************************************************************
	;Description - a reusable procedure that routes the user to the appropriate point in the program
	;Recieves - user input as a DWORD contain value used to route user
	;Returns - nothing
	;*******************************************************************************************
		.data
			user_input2 EQU [x2 + 4]
		
		.code
			push ebp							; create stack frame
			mov ebp, esp
			
			call Randomize
			
			cmp user_input2, 1
				je Option1_GO
			cmp user_input2, 2
				je Option2_GO
			
			Option1_GO: INVOKE InstructionsPrint
						call Clrscr
						jmp leaveProc2
						
			Option2_GO: INVOKE RunGame_CvC
						call Clrscr
						jmp leaveProc2
						
	leaveProc2:	leave
	ret
	RouteUser ENDP
	
	InstructionsPrint PROC
	;************************************************************************************************
	;Description - if the user chose the player vs. computer option, they will be instructed on how
	;			   this version of the game operates. The program will also retrieve their name
	;Recieves - nothing
	;Returns - offset of string contaning user's name and a variable containing the string length
	;************************************************************************************************
		.data
			instructions  BYTE "                                                   TIC-TAC-TOE: HOW TO PLAY                             ", 0
						  BYTE "                           To win, you must place three Xs in a row on the board before the computer    ", 0
						  BYTE "                         When chosing a move, enter a number corresponding to the position on the board:", 0
						  BYTE "                                                                                                        ", 0
			board_instruc BYTE "                                       .--------------.--------------.--------------.                   ", 0
						  BYTE "                                       |      _       |    ____      |    _____     |                   ", 0
						  BYTE "                                       |     / |      |   |___ \     |   |___ /     |                   ", 0
						  BYTE "                                       |     | |      |     __) |    |     |_ \     |                   ", 0
						  BYTE "                                       |     | |      |    / __/     |    ___) |    |                   ", 0
						  BYTE "                                       |     |_|      |   |_____|    |   |____/     |                   ", 0
						  BYTE "                                       |--------------|--------------|--------------|                   ", 0
						  BYTE "                                       |    _  _      |     ____     |     __       |                   ", 0
						  BYTE "                                       |   | || |     |    | ___|    |    / /_      |                   ", 0
						  BYTE "                                       |   | || |_    |    |___ \    |   | '_ \     |                   ", 0
						  BYTE "                                       |   |__   _|   |     ___) |   |   | (_) |    |                   ", 0
						  BYTE "                                       |      |_|     |    |____/    |    \___/     |                   ", 0
						  BYTE "                                       |--------------|--------------|--------------|                   ", 0
						  BYTE "                                       |    _____     |      ___     |     ___      |                   ", 0
						  BYTE "                                       |   |___  |    |     ( _ )    |    / _ \     |                   ", 0
						  BYTE "                                       |      / /     |     / _ \    |   | (_) |    |                   ", 0
						  BYTE "                                       |     / /      |    | (_) |   |    \__, |    |                   ", 0
						  BYTE "                                       |    /_/       |     \___/    |      /_/     |                   ", 0
						  BYTE "                                       .--------------.--------------.--------------.                   ", 0
			name_prompt   BYTE "                               Enter your name to begin: ", 0
		
			name_str      BYTE 50 DUP(0)	; string that will hold user's name
			name_size     BYTE ?			; a memory variable that keeps track of the amount of characters in the user's name
		.code
			push ebp
			mov ebp, esp
			call Clrscr						; screen will always be cleared before instructions display
			
			mov ecx, 4
			mov bl, 0
			mov eax, lightGreen
			call SetTextColor
			printMenu: mov edx, OFFSET instructions		
					   mov eax, 0
					   mov al, LENGTHOF instructions
					   mul bl							
						 
					   add edx, eax						
					   call WriteString
					   
					   mov eax, yellow
			           call SetTextColor
					   call Crlf
					   inc bl
			loop printMenu
			
			mov ecx, 19
			mov bl, 0
			mov eax, white
			call SetTextColor
			printMenu2: mov edx, OFFSET board_instruc		
					    mov eax, 0
					    mov al, LENGTHOF board_instruc
					    mul bl							
						 
					    add edx, eax						
					    call WriteString
						
					    call Crlf
					    inc bl
			loop printMenu2
			
			call Crlf
			call Crlf
			
			mov edx, OFFSET name_prompt
			call WriteString
			
			mov edx, OFFSET name_str
			mov ecx, SIZEOF name_str
			call ReadString
			mov name_size, al
			
			INVOKE RunGame_PvC, ADDR name_str, name_size		; the user's name as an offset of the string and the length of that string are	
														        ; passed to the main feature of the program
			leave
	ret
	InstructionsPrint ENDP
	
	RunGame_PvC PROC x3:PTR BYTE, y2:BYTE
	;************************************************************************************************
	;Description - simulates a game of tic-tac-toe by using a 2D array that acts as a placeholder for
	;			   the moves that the user selects and the randomly generated moves that the computer
	;			   selects. 
	;Recieves - offset of string containing user's name and length of string in a memory variable 
	;Returns - nothing
	;************************************************************************************************
		.data
			player_name EQU [x3 + 4]
			sizeOfName  EQU [y2 + 4]
			
			gameBoard	       BYTE 9 DUP(0)				; non-abstracted 2D array is actually one array. row-major-order is used. 
			
			gameTitle	       BYTE " vs. Computer", 0
			computerMove       BYTE "Computer: ", 0			; the name of the computer is simply "comptuer"
									 			
			movNumber	       BYTE 0						; memory variable that keeps track of the amount of moves made
			user_selection     DWORD 0						; memory variable that holds the user's selections
			computer_selection DWORD 0						; memory variable that holds the computer's selections
			name_offset		   DWORD ?						; memory variable that hold the offset of a string to be passed to another procedure
			firstGo		       BYTE ?						; memory variable that keeps track of the randomly generated value of who to go first
			player_user_type   BYTE ?						; used as a way to direct an inherited procedure
			comp_user_type     BYTE ?						; used as a way to direct an inherited procedure
			runOnce			   BYTE ?						; keeps track of if the program was run once. runOnce = 1 if true
						 		
		.code
			push ebp										; create stack frame
			mov ebp, esp
			
			mov ebx, player_name
			mov name_offset, ebx						    ; store offset of user's name at the beginning
			cmp runOnce, 1 									; if run once, 2D array must be reinitialized to zero
				je clearTable
				
			preGame: mov movNumber, 1						; always be sure the procedure starts at the first move
			
			mov eax, 0
			mov al, 2
			call RandomRange
			mov firstGo, al									; randomly generate a 1 or 0 that is like flipping a coin for which player goes first
			
			jmp Game
			
			clearTable: mov ecx, 9
						mov al, 0
						mov esi, OFFSET gameBoard
						zeroOut: mov [esi], al
								 inc esi
						loop zeroOut
						jmp preGame
			
			Game: call Clrscr								; screen is always cleared before procedure starts 
				  
				  mov edx, 0
				  call Gotoxy
			
				  mov ecx, 50								; indent 50 spaces
				  mov eax, 0
				  Spce: mov al, ' '
				  	    call WriteChar
				  loop Spce
				
				  mov eax, white							; set program text color to white 
				  call SetTextColor
				  
				  mov edx, player_name
				  call WriteString							; print "[user's name] vs. Computer"
				
				  mov edx, OFFSET gameTitle
				  call WriteString
				
				  call Crlf
				  call Crlf
				   
				  INVOKE PrintBoard								; procedure that prints a blank board is called
				  INVOKE PrintGameBoardMoves, ADDR gameBoard	; this procedure is called to update the board with previous moves
				
				  cmp movNumber, 9								; if 9 moves have been exceeded, skip to the end of procedure 
					  jg leaveProc4
				  				 			 
				  INVOKE FindWin, ADDR gameBoard, movNumber, name_offset, firstGo, 0	; pass a pointer to the 2D array, current move, user name,
				  cmp dl, 0																; the value of the first player, and an instance type for direction 
					  je keepPlaying
				  cmp dl, 1
					  je leaveProc4
				  cmp dl, 2 
					  je leaveProc4
				  
				  keepPlaying:
				  mov dl, 55									; center text 
				  mov dh, 23
				  call Gotoxy
				  
				  mov eax, 0
				  mov al, movNumber
				  mov bl, 2
				  div bl										; the remainer from dividing the number of moves by two determines what user goes
				
				  cmp firstGo, 0								; player goes first if random value is 0
					  je player_first
				  cmp firstGo, 1								; computer goes first if random value is 1
					  je computer_first
				
				  player_first: cmp ah, 1						; if there is a remaineder, choose the player
								    je player_prompt
							    cmp ah, 0						; if there is no remainder, choose the computer
								  je computer_prompt
					
				  computer_first: cmp ah, 1
									  je computer_prompt
								  cmp ah, 0
									  je player_prompt
					
				  player_prompt: cmp firstGo, 0
									 je U_P1
				  
				                 mov eax, lightMagenta
							     call SetTextColor
								 mov player_user_type, 1			; this value determines how an X is displayed if this player is picked first 
								 jmp cont1
								
								 U_P1: mov eax, lightGreen
									   call SetTextColor
									   
									   mov player_user_type, 0
									   
							     cont1: mov edx, player_name
										call WriteString
										mov al, ':'
										call WriteChar
										mov al, ' '
										call WriteChar
										jmp user_selections
				
				  computer_prompt: cmp firstGo, 1
									   je C_P1
				  
								   mov eax, lightMagenta
								   call SetTextColor
								   mov comp_user_type, 1
								   jmp cont2
								   
								   C_P1: mov eax, lightGreen
									     call SetTextColor
										 
										 mov comp_user_type, 0
									   
								   cont2: mov edx, OFFSET computerMove
									     call WriteString
								   
								   jmp computer_selections
																	  
				  user_selections: mov eax, white
								   call SetTextColor
						  
								   mov eax, 0
								   call ReadDec								; get user's choice of move to make
									  mov user_selection, eax
									  INVOKE CheckInput, user_selection, 3
										  cmp dl, 1
											  je Game
								  
								   INVOKE UpdateGameBoard, 0, player_user_type, user_selection, ADDR gameBoard		; call procedure to record input
								   cmp dl, 1
									  je user_selections
									
								   inc movNumber
								   jmp Game
											
				  computer_selections: mov eax, 0
									   mov al, 10
									   call RandomRange
									   mov ebx, 0
									   mov bl, al
									   mov computer_selection, ebx			; a random value is generated to represent the computer's move 
									 
									   cmp computer_selection, 0
										   je computer_selections
									 
									   INVOKE UpdateGameBoard, 1, comp_user_type, computer_selection, ADDR gameBoard
										  cmp dl, 1
											  je computer_selections
									 
									   mov ebx, 0
									   mov ebx, computer_selection
									   mov al, bl
									   call WriteDec
									 
									   mov eax, 2000						; two second delay 
									   call Delay
									 
									   inc movNumber
									   jmp Game			 
									   
			leaveProc4: cmp movNumber, 10
							jne justleave
						INVOKE FindWin, ADDR gameBoard, movNumber, name_offset, firstGo, 0
			justleave:	mov runOnce, 1
			            leave
	ret
	RunGame_PvC ENDP
	
	RunGame_CvC PROC
	;************************************************************************************************
	;Description - simulates a game of tic-tac-toe between two computers by using a 2D array that acts 
	;			   as a placeholder for the moves that the user selects and the randomly generated moves
	;			   that the computer selects. This procedure has the same function as RunGame_PvC, except
	;			   no user input is obtained 
	;Recieves - nothing
	;Returns - nothing
	;************************************************************************************************
		.data			
			gameBoard2	       BYTE 9 DUP(0)
			
			gameTitle2	       BYTE "Computer 1 vs. Computer 2", 0
			computer1Move      BYTE "Computer 1", 0
			computer2Move      BYTE "Computer 2", 0
			computer_name      BYTE "Computer ", 0
									 			
			movNumber2	        BYTE 0
			computer1_selection DWORD 0
			computer2_selection DWORD 0
			comp1_assign_type   BYTE ?
			comp2_assign_type   BYTE ?
			comp_name_offset    DWORD ?
			firstGo2	        BYTE ?
			runOnce2			BYTE ?
						 		
		.code
			push ebp						; create stack frame 
			mov ebp, esp
			
			mov ebx, OFFSET computer_name
			mov comp_name_offset, ebx
			cmp runOnce2, 1 
				je clearTable_
				
			preGame_: mov movNumber2, 1
			          mov firstGo2, 0
						
			jmp Game2
			
			clearTable_: mov ecx, 9
						mov al, 0
						mov esi, OFFSET gameBoard2
						zeroOut_: mov [esi], al
								 inc esi
						loop zeroOut_
						jmp preGame_
			
			Game2:call Clrscr
				  
				  mov edx, 0
				  call Gotoxy
			
				  mov ecx, 50
				  mov eax, 0
				  Spce_: mov al, ' '
				  	    call WriteChar
				  loop Spce_
				
				  mov eax, white
				  call SetTextColor
				
				  mov edx, OFFSET gameTitle2
				  call WriteString
				
				  call Crlf
				  call Crlf
				   
				  INVOKE PrintBoard
				  INVOKE PrintGameBoardMoves, ADDR gameBoard2
				
				  cmp movNumber2, 9
					  jg leaveProc9
				  				 			 
				  INVOKE FindWin, ADDR gameBoard2, movNumber2, comp_name_offset, firstGo2, 1	; instance type value of 1 indicates different handling
				  cmp dl, 0																	    ; of FindWin for this procedure 
					  je keepPlaying_
				  cmp dl, 1
					  je leaveProc9
				  cmp dl, 2 
					  je leaveProc9
				  
				  keepPlaying_:
				  mov dl, 55
				  mov dh, 23
				  call Gotoxy
				  
				  mov eax, 0
				  mov al, movNumber2
				  mov bl, 2
				  div bl
				
				 mov firstGo2, 0
				 jmp computer1_first
				
				  computer1_first: cmp ah, 1
								       je computer1_prompt
							       cmp ah, 0
								       je computer2_prompt
										
				  computer1_prompt: cmp firstGo2, 0
									    je C1e
				  
									mov eax, lightMagenta
									call SetTextColor
									mov comp1_assign_type, 1
									jmp cont1_
								
								    C1e: mov eax, lightGreen
									     call SetTextColor
										 
										 mov comp1_assign_type, 0
									  									   
							        cont1_: mov edx, OFFSET computer1Move
										    call WriteString
										    mov al, ':'
										    call WriteChar
										    mov al, ' '
										    call WriteChar
										    jmp comp1_selections
				
				  computer2_prompt: cmp firstGo2, 1
									    je C2e
				  
								    mov eax, lightMagenta
								    call SetTextColor
									mov comp2_assign_type, 1
								    jmp cont2_
								   
								    C2e: mov eax, lightGreen
									     call SetTextColor
										
										mov comp1_assign_type, 0
										 									   
								    cont2_: mov edx, OFFSET computer2Move
									        call WriteString
										    mov al, ':'
										    call WriteChar
										    mov al, ' '
										    call WriteChar
										    jmp comp2_selections
																	  
				  comp1_selections: mov eax, 0
									mov al, 10
									call RandomRange
									mov ebx, 0
									mov bl, al
									mov computer1_selection, ebx
									 
								    cmp computer1_selection, 0
									    je comp1_selections
								 
								    INVOKE UpdateGameBoard, 1, comp1_assign_type, computer1_selection, ADDR gameBoard2
									   cmp dl, 1
										   je comp1_selections
									 
								    mov ebx, 0
								    mov ebx, computer1_selection
								    mov al, bl
								    call WriteDec
								 
								    mov eax, 2000
								    call Delay
								 
								    inc movNumber2
								    jmp Game2			 
											
				  comp2_selections: mov eax, 0
									mov al, 10
									call RandomRange
									mov ebx, 0
									mov bl, al
									mov computer2_selection, ebx
									 
								    cmp computer2_selection, 0
									    je comp2_selections
								 
								    INVOKE UpdateGameBoard, 1, comp2_assign_type, computer2_selection, ADDR gameBoard2
									    cmp dl, 1
										    je comp2_selections
								 
								    mov ebx, 0
								    mov ebx, computer2_selection
								    mov al, bl
								    call WriteDec
								 
								    mov eax, 2000
								    call Delay
								 
								    inc movNumber2
								    jmp Game2			 
									   
			leaveProc9: cmp movNumber2, 10
							jne justleave_
						INVOKE FindWin, ADDR gameBoard2, movNumber2, comp_name_offset, firstGo2, 1
			justleave_:	mov runOnce2, 1
			            leave
	ret
	RunGame_CvC ENDP
	
	PrintBoard PROC
	;************************************************************************************************
	;Description - writes a blank tic-tac-toe board on the sreen
	;Recieves - nothing
	;Returns - nothing
	;************************************************************************************************
		.data
			gameBoardPrint BYTE "                                       .--------------.--------------.--------------.                   ", 0
						   BYTE "                                       |1             |2             |3             |                   ", 0
						   BYTE "                                       |              |              |              |                   ", 0
						   BYTE "                                       |              |              |              |                   ", 0
						   BYTE "                                       |              |              |              |                   ", 0
						   BYTE "                                       |              |              |              |                   ", 0
						   BYTE "                                       |--------------|--------------|--------------|                   ", 0
						   BYTE "                                       |4             |5             |6             |                   ", 0
						   BYTE "                                       |              |              |              |                   ", 0
						   BYTE "                                       |              |              |              |                   ", 0
						   BYTE "                                       |              |              |              |                   ", 0
						   BYTE "                                       |              |              |              |                   ", 0
						   BYTE "                                       |--------------|--------------|--------------|                   ", 0
						   BYTE "                                       |7             |8             |9             |                   ", 0
						   BYTE "                                       |              |              |              |                   ", 0
						   BYTE "                                       |              |              |              |                   ", 0
						   BYTE "                                       |              |              |              |                   ", 0
						   BYTE "                                       |              |              |              |                   ", 0
						   BYTE "                                       .--------------.--------------.--------------.                   ", 0
						   
		.code
			push ebp				; create stack frame 
			mov ebp, esp
			
			mov ecx, 19
				  mov bl, 0
				  mov eax, white
				  call SetTextColor
				  printMenu: mov edx, OFFSET gameBoardPrint		
						     mov eax, 0
						     mov al, LENGTHOF gameBoardPrint
						     mul bl							
							 
						     add edx, eax						
						     call WriteString
						   
						     call Crlf
						     inc bl
				  loop printMenu
				  
			leave
	ret
	PrintBoard ENDP
	
	UpdateGameBoard PROC x4:BYTE, y3:BYTE, w1:DWORD, z1:PTR BYTE
	;************************************************************************************************
	;Description - places the move a user made as a 1 or a 2 in the 2D array passed as a pointer 
	;Recieves - number inicating computer or user, number indicating whether to assign choice as a 1 or 2,
	;			off set of name of user/computer making that selection, and the 2D array as a pointer 
	;Returns - updated 2D array
	;************************************************************************************************
		.data
			player_type EQU [x4 + 4]
			assign_type EQU [y3 + 4]
			location    EQU [w1 + 4]
			game_board  EQU [z1 + 4]
			
			occupied_error     BYTE "That space is already occupied. Please try again: ", 0
			row_size		   BYTE 3		; holds a constant value for the size of the rows in the 2D array
			row_index		   BYTE ?		; 0, 1 or 2
			column_index	   DWORD ?		; 0, 1 or 2
			
		.code 
			push ebp				; create stack frame 
			mov ebp, esp
			
			cmp location, 1
				je Fill_1
			cmp location, 2
				je Fill_2
			cmp location, 3
				je Fill_3
			cmp location, 4
				je Fill_4
		    cmp location, 5
				je Fill_5
			cmp location, 6
				je Fill_6
			cmp location, 7
				je Fill_7
			cmp location, 8
				je Fill_8
			cmp location, 9
				je Fill_9
				
			jmp leaveProc3
											; the different row/column combinates cover every choice for the entire board 
			Fill_1: mov row_index, 0
					mov column_index, 0
					jmp Fill_Task
			 	
			Fill_2: mov row_index, 0
					mov column_index, 1
					jmp Fill_Task

			Fill_3: mov row_index, 0
					mov column_index, 2
					jmp Fill_Task
							
			Fill_4: mov row_index, 1
					mov column_index, 0
					jmp Fill_Task
		
			Fill_5: mov row_index, 1
					mov column_index, 1
					jmp Fill_Task
			 			
			Fill_6: mov row_index, 1
					mov column_index, 2
					jmp Fill_Task
	
			Fill_7: mov row_index, 2
					mov column_index, 0
					jmp Fill_Task
	
			Fill_8: mov row_index, 2
					mov column_index, 1
					jmp Fill_Task
				
			Fill_9: mov row_index, 2
					mov column_index, 2
					jmp Fill_Task
													    ; To access the 2D array:
			Fill_Task: mov ebx, game_board				; move the offset of the 2D array into ebx
					   mov eax, 0
					   mov al, row_index				; mov the row number in al
					   mov dl, row_size		
					   mul dl							; multiply the row number in al by the constant row size of 3
					   add ebx, eax
					   mov esi, column_index			; move into esi the column number
					 
					   mov cl, [ebx + esi]				; the desired element can now be accessed using a base-index operand
					   cmp cl, 0
						   jne occupiedError			; if there is already a value in that location in the table, throw an error
						
					   cmp assign_type, 0
						   je setX_
					   cmp assign_type, 1
						   je setO_
						
					   setX_: mov al, 1
							  jmp addToBoard
					   setO_: mov al, 2
							  jmp addToBoard
									 
					   addToBoard: mov [ebx + esi], al	; a 1 or 2 is added to the array to record the choice of the appropriate party

					   mov dl, 0
					   jmp leaveProc3
					
			occupiedError: mov dl, 1 ; 1 = error
						
						   cmp player_type, 1			; if the user is a computer, do not display an error, as it is not needed 
							   je leaveProc3
							   
						   call Crlf
						   call Crlf
						   
						   mov eax, lightRed
						   call SetTextColor
						   
						   push edx
						       mov dl, 38
							   mov dh, 25
							   call Gotoxy
							   mov edx, OFFSET occupied_error
							   call WriteString
						   pop edx
						   
						   mov eax, white
						   call SetTextColor
						  						   
						   jmp leaveProc3
			
			leaveProc3: leave
	ret
	UpdateGameBoard ENDP
	
	PrintGameBoardMoves PROC x5:PTR BYTE
	;************************************************************************************************
	;Description - updates the tic-tac-toe board as the game progresses. An X or an O is placed on a 
	;			   particular part of the screen
	;Recieves - a pointed to the 2D array representing the game table 
	;Returns - nothing
	;************************************************************************************************
		.data
			gameTable EQU [x5 + 4]
			
			player1Mark  BYTE "__  __ ", 0
						 BYTE "\ \/ / ", 0
						 BYTE " >  <  ", 0
						 BYTE "/_/\_\ ", 0
						  				 
			player2Mark  BYTE "  ___  ", 0
					     BYTE " / _ \ ", 0
					     BYTE "| (_) |", 0
						 BYTE " \___/ ", 0
						 
			boardPos     BYTE 1
			player_type2 BYTE 0
			
		.code
			push ebp				; create stack frame 
			mov ebp, esp
			
			mov boardPos, 1
			mov ebx, 0
			mov ebx, gameTable
			mov esi, ebx
			mov ecx, 9
			findMarks: mov al, [esi]				; iterate through the 2D array looking for 1s and 2s indicating marked positions on the board
					   cmp al, 0
					       jne markFind
					   returnToLoop: inc esi
								     inc boardPos
			loop findMarks
			jmp leaveProc5

			markFind: cmp al, 1						; when a 1 or a 2 is found print it on the screen using GoToScreenPos procedure 
						   je setPlayer1
					  cmp al, 2
						   je setPlayer2
						   
					  setPlayer1: mov player_type2, 1
								  jmp findBoardPos
					  setPlayer2: mov player_type2, 2
							      jmp findBoardPos
							   
					  
					  findBoardPos: INVOKE GoToScreenPos, boardPos
			push ecx		  
				mov ecx, 4
				mov bl, 0
						   			   
				printMark:  push edx									; GoToScreenPos moves the cursor to the appropriate position for printing 
								cmp player_type2, 1
									jne getMark
										
								pMark: mov eax, lightGreen
									   call SetTextColor
									   
								       mov edx, OFFSET player1Mark								
									   mov eax, 0
									   mov al, LENGTHOF player1Mark
									   mul bl	
									   jmp continuePrint
									
								getMark: mov eax, lightMagenta
									     call SetTextColor
								
										 mov edx, OFFSET player2Mark
										 mov eax, 0
										 mov al, LENGTHOF player2Mark
										 mul bl
											 
								continuePrint: add edx, eax						
											   call WriteString
							pop edx
				   
							inc dh
							call Gotoxy
							inc bl
				loop printMark
		   pop ecx
		   
		   mov eax, white
		   call SetTextColor
		   
		    jmp returnToLoop
					   
		    leaveProc5: leave 
	ret
	PrintGameBoardMoves ENDP
	
	GoToScreenPos PROC x6:BYTE
	;************************************************************************************************
	;Description - contains data that is used to move the cursor to a point on the console window that 
	;		       reprents a move made by a player previously 
	;Recieves - a number indicating a fixed position in which to place the cursor 
	;Returns - nothing
	;************************************************************************************************
		.data
			pos EQU [x6 + 4]
			
		.code
			push ebp
			mov ebp, esp
			
			cmp pos, 1
				je Print_1
			cmp pos, 2
				je Print_2
			cmp pos, 3
				je Print_3
			cmp pos, 4
				je Print_4
			cmp pos, 5
				je Print_5
			cmp pos, 6
				je Print_6
			cmp pos, 7
				je Print_7
			cmp pos, 8
				je Print_8
			cmp pos, 9
				je Print_9
				
			jmp leaveProc6
				
			Print_1: mov dl, 44
					 mov dh, 3
					 call Gotoxy
					 jmp leaveProc6
			
			Print_2: mov dl, 59
					 mov dh, 3
					 call Gotoxy
					 jmp leaveProc6
					 
			Print_3: mov dl, 74
					 mov dh, 3
					 call Gotoxy
					 jmp leaveProc6
					 
			Print_4: mov dl, 44
					 mov dh, 9
					 call Gotoxy
					 jmp leaveProc6
					 
			Print_5: mov dl, 59
					 mov dh, 9
					 call Gotoxy
					 jmp leaveProc6
					 
			Print_6: mov dl, 74
					 mov dh, 9
					 call Gotoxy
					 jmp leaveProc6
					 
			Print_7: mov dl, 44
					 mov dh, 15
					 call Gotoxy
					 jmp leaveProc6
					 
			Print_8: mov dl, 59
					 mov dh, 15
					 call Gotoxy
					 jmp leaveProc6
					 
			Print_9: mov dl, 74
					 mov dh, 15
					 call Gotoxy
					 jmp leaveProc6
					 
			leaveProc6: leave
	ret
	GoToScreenPos ENDP
	
	FindWin PROC x7:DWORD, y4:BYTE, w2:PTR BYTE, z2:BYTE, in1:BYTE
	;************************************************************************************************
	;Description - determines when a winning position has been filled in the 2D array and marks the 
	;			   result on the console window 
	;Recieves - pointer to the 2D array, position in the game, name of user, value of player 1, and instance type
	;Returns - nothing
	;************************************************************************************************
		.data
			game_board2 EQU [x7 + 4]
			move_number EQU [y4 + 4]
			user_name   EQU [w2 + 4]
			player1     EQU [z2 + 4]
			inst_type   EQU [in1 + 4]				; used for when different procedures call this procedure 
			
			gameBoard_offset DWORD ?
			P1_Win_prompt    BYTE " WINS!", 0
			P2_Win_prompt    BYTE "COMPUTER WINS :(", 0
			draw_prompt		 BYTE "IT'S A DRAW!", 0
			test_counter	 BYTE ?
			path_type		 BYTE ? ; 0 = X, 1 = O
			
		.code
			push ebp								; create stack frame 
			mov ebp, esp
			
			mov ebx, game_board2
			mov gameBoard_offset, ebx
			
			cmp move_number, 6
				jl win_false
			
			mov test_counter, 0			; set a counter to keep track of which tests have been done on the array
			
			; The following tests cover all 8 winning positions, and if a winning position is in the array it will be found with these 
		    Test1: INVOKE WinTests, 0, 0, 0, 1, 0, 2, gameBoard_offset
				   inc test_counter
				   cmp dl, 0
					   je Test2
				   cmp dl, 1
					   je P1_Win
				   cmp dl, 2
					   je P2_Win
			Test2: INVOKE WinTests, 0, 0, 1, 1, 2, 2, gameBoard_offset
				   inc test_counter
				   cmp dl, 0
					   je Test3
				   cmp dl, 1
					   je P1_Win
				   cmp dl, 2
					   je P2_Win
			Test3: INVOKE WinTests, 1, 0, 1, 1, 1, 2, gameBoard_offset
			       inc test_counter
				   cmp dl, 0
					   je Test4
				   cmp dl, 1
					   je P1_Win
				   cmp dl, 2
					   je P2_Win
			Test4: INVOKE WinTests, 2, 0, 2, 1, 2, 2, gameBoard_offset
				   inc test_counter
				   cmp dl, 0
					   je Test5
				   cmp dl, 1
					   je P1_Win
				   cmp dl, 2
					   je P2_Win
			Test5: INVOKE WinTests, 0, 0, 1, 0, 2, 0, gameBoard_offset
				   inc test_counter
				   cmp dl, 0
					   je Test6
				   cmp dl, 1
					   je P1_Win
				   cmp dl, 2
					   je P2_Win
			Test6: INVOKE WinTests, 0, 1, 1, 1, 2, 1, gameBoard_offset
			       inc test_counter
				   cmp dl, 0
					   je Test7
				   cmp dl, 1
					   je P1_Win
				   cmp dl, 2
					   je P2_Win
			Test7: INVOKE WinTests, 0, 2, 1, 2, 2, 2, gameBoard_offset
			       inc test_counter
				   cmp dl, 0
					   je Test8
				   cmp dl, 1
					   je P1_Win
				   cmp dl, 2
					   je P2_Win
			Test8: INVOKE WinTests, 2, 0, 1, 1, 0, 2, gameBoard_offset
			       inc test_counter
				   cmp dl, 0
					   je win_false
				   cmp dl, 1
					   je P1_Win
				   cmp dl, 2
					   je P2_Win
			jmp win_false
			
			; once winning position has been found, print the appropriate text on the console window 
			P1_Win: push edx
					mov dl, 55
					mov dh, 23
				    call Gotoxy
			
			        cmp player1, 0
						je user_1
					cmp player1, 1
						je comp_1
						
					user_1: mov eax, lightGreen
							call SetTextColor
							
							mov edx, user_name
					        call WriteString
							cmp inst_type, 1
								je suffix_add1
							resume1:	
							mov edx, OFFSET P1_Win_prompt
							call WriteString
							call Crlf
							
							pop edx
							
							mov path_type, 0
							jmp fillPath
							
							suffix_add1: mov al, '1'
										call WriteChar
										jmp resume1
							
					comp_1: mov eax, lightGreen
							call SetTextColor
							
							cmp inst_type, 1
								je suffix_add2
							mov edx, OFFSET P2_Win_prompt
							call WriteString
							
							resume2:
							call Crlf
							
							pop edx
							
							mov path_type, 0
							jmp fillPath
							
							suffix_add2: mov edx, user_name
										 call WriteString
							             mov al, '2'
										 call WriteChar
										 mov edx, OFFSET P1_Win_prompt
										 call WriteString
										 jmp resume2
							
			P2_Win: push edx
					mov dl, 55
					mov dh, 23
				    call Gotoxy
			
			        cmp player1, 1
						je user_2
					cmp player1, 0
						je comp_2
						
					user_2: mov eax, lightMagenta
							call SetTextColor
							
							mov edx, user_name
					        call WriteString
							cmp inst_type, 1
								je suffix_add3
							resume3:	
							mov edx, OFFSET P1_Win_prompt
							call WriteString
							call Crlf
							
							pop edx
							
							mov path_type, 1
							jmp fillPath
							
							suffix_add3: mov al, '1'
										 call WriteChar
										 jmp resume3
							
					comp_2: mov eax, lightMagenta
							call SetTextColor
							
							cmp inst_type, 1
								je suffix_add4
							mov edx, OFFSET P2_Win_prompt
							call WriteString
							
							resume4:
							call Crlf
							
							pop edx
							
							mov path_type, 1
							jmp fillPath
							
							suffix_add4: mov edx, user_name
										 call WriteString
							             mov al, '2'
										 call WriteChar
										 mov edx, OFFSET P1_Win_prompt
										 call WriteString
										 jmp resume4
			
			win_false: cmp move_number, 10
						   je draw
					    jmp leaveskip
			
			draw: push edx
			      mov dl, 55
				  mov dh, 23
				  call Gotoxy
			
			      mov eax, yellow
				  call SetTextColor
				  
			      mov edx, OFFSET draw_prompt
				  call WriteString
				  pop edx
				  call Crlf
				  
				  jmp leaveProc7
				  
		    ; once the winning position has been found, the path will be highlighted white 		  
			fillPath: cmp test_counter, 1
						  je DT1
					  cmp test_counter, 2
						  je DT2
					  cmp test_counter, 3
						  je DT3
					  cmp test_counter, 4
						  je DT4
					  cmp test_counter, 5
						  je DT5
					  cmp test_counter, 6
						  je DT6
					  cmp test_counter, 7
						  je DT7
					  cmp test_counter, 8
						  je DT8	
						
				      ; Gotoxy dl and dh coordinates of all three squares are passed in a function that fills the squares in 
					  ; path type is passed to ensure Xs and Os are properly printed 
					  DT1: INVOKE DrawWinPath, 40, 3, 55, 3, 70, 3, path_type
						   jmp leaveProc7
					  DT2: INVOKE DrawWinPath, 40, 3, 55, 9, 70, 15, path_type
						   jmp leaveProc7
					  DT3: INVOKE DrawWinPath, 40, 9, 55, 9, 70, 9, path_type
						   jmp leaveProc7
					  DT4: INVOKE DrawWinPath, 40, 15, 55, 15, 70, 15, path_type
						   jmp leaveProc7
					  DT5: INVOKE DrawWinPath, 40, 3, 40, 9, 40, 15, path_type
						   jmp leaveProc7
					  DT6: INVOKE DrawWinPath, 55, 3, 55, 9, 55, 15, path_type
						   jmp leaveProc7
					  DT7: INVOKE DrawWinPath, 70, 3, 70, 9, 70, 15, path_type
						   jmp leaveProc7
					  DT8: INVOKE DrawWinPath, 40, 15, 55, 9, 70, 3, path_type
						   jmp leaveProc7
			leaveProc7: mov eax, white
						call SetTextColor
						
						push edx
							mov dl, 50
							mov dh, 25
							call Gotoxy
						pop edx
						
						call WaitMsg
			leaveskip:	leave
				   			
	ret
	FindWin ENDP
	
	WinTests PROC p1:BYTE, p2:DWORD, p3:BYTE, p4:DWORD, p5:BYTE, p6:DWORD, x8:PTR BYTE
	;************************************************************************************************
	;Description - performs calculations to determine if a winning position has been discovered given the 
	;			   index values passed to it 
	;Recieves - row and column index values of all three points square that are being tested 
	;Returns - value indicating results of the test in dl 
	;************************************************************************************************
		.data
			r1 			EQU [p1 + 4]
			c1 			EQU [p2 + 4]
			r2 			EQU [p3 + 4]
			c2 			EQU [p4 + 4]
			r3 			EQU [p5 + 4]
			c3 			EQU [p6 + 4]
			game_board3 EQU [x8 + 4]
			
			test_num1    BYTE ?
			test_num2    BYTE ?
			test_num3    BYTE ?
			instance	 BYTE ?

			row_size2    BYTE 3
			
			; dl = 0: no win
			; dl = 1: player 1 win
			; dl = 2: player 2 win
			; dl = 3: draw
			
	    .code
			push ebp
			mov ebp, esp
			
			mov ebx, game_board3			; ebx and dl remain constant through the tests
			mov dl, row_size2
			
			T1: mov eax, 0					; First set al and esi to the appropriate indexes 
				mov al, r1
				mov esi, c1
				jmp get_test_num1
				   
			T2: mov eax, 0
				mov al, r2
				mov esi, c2
				jmp get_test_num2
				   
			T3: mov eax, 0
				mov al, r3
				mov esi, c3
				jmp get_test_num3
				   
			getTest: mov edi, ebx
					 mul dl
					 add edi, eax
					 
					cmp instance, 1				; use an instance type to determine where to send the data 
						je set_test_num1
					cmp instance, 2
						je set_test_num2
					cmp instance, 3
						je set_test_num3
					 
				   set_test_num1: mov cl, [edi + esi]		; move the value at the array location to the approriate memory variable 
								  mov test_num1, cl
								  jmp T2
				   set_test_num2: mov cl, [edi + esi]
								  mov test_num2, cl
								  jmp T3
				   set_test_num3: mov cl, [edi + esi]
								  mov test_num3, cl
								  jmp computeResult
								  
					get_test_num1: mov instance, 1
								   jmp getTest
					get_test_num2: mov instance, 2
								   jmp getTest
					get_test_num3: mov instance, 3
								   jmp getTest
			
					computeResult: mov al, test_num1		; if all three memory variables end up being equal, a solution has been found 
								   cmp al, test_num2
										jne no_win
								   cmp al, test_num3
										jne no_win
								   mov al, test_num2
								   cmp al, test_num3
										jne no_win
									
								   mov al, test_num1	
								   add al, test_num2
								   add al, test_num3
								   
								   cmp al, 3				; adding up all three (1+1+1) or (2+2+2) provides further verification of a solution
									   je P1Win
								   cmp al, 6
									   je P2Win
								   jmp no_win
									   
			P1Win: mov dl, 1
				   jmp leaveProc8
			P2Win: mov dl, 2
				   jmp leaveProc8
			
			no_win: mov dl, 0
					jmp leaveProc8
					
			leaveProc8: leave
	ret
	WinTests ENDP 
	
	DrawWinPath PROC l_p1:BYTE, h_p2:BYTE, l_p3:BYTE, h_p4:BYTE, l_p5:BYTE, h_p6:BYTE, x9:BYTE
	;************************************************************************************************
	;Description - fills a square white indicating it is a solution to a tick tack toe problem. Reprints
	;			   the Xs and Os accordingly 
	;Recieves - Gotoxy dl and dh coordinates of specific solution squares 
	;Returns - nothing 
	;************************************************************************************************
		.data
			dl_1	  EQU [l_p1 + 4]
			dh_1	  EQU [h_p2 + 4]
			dl_2	  EQU [l_p3 + 4]
			dh_2	  EQU [h_p4 + 4]
			dl_3	  EQU [l_p5 + 4]
			dh_3	  EQU [h_p6 + 4]
			X_or_O    EQU [x9 + 4]
			
			player1Mark_  BYTE "__  __ ", 0
						  BYTE "\ \/ / ", 0
						  BYTE " >  <  ", 0
						  BYTE "/_/\_\ ", 0
						  				 
			player2Mark_  BYTE "  ___  ", 0
					      BYTE " / _ \ ", 0
					      BYTE "| (_) |", 0
						  BYTE " \___/ ", 0
			
		.code
			push ebp
			mov ebp, esp
			
			mov eax, 1000
			call Delay
			
			push edx
								
			mov eax, black + (white * 16)			; black text on white background 
			call SetTextColor
			
			; SQUARE 1
			mov dl, dl_1
			mov dh, dh_1
			call Gotoxy
			mov ecx, 5
			square1: push ecx
						mov ecx, 14
						square1a: mov al, ' '
								  call WriteChar
								  inc dl
								  call Gotoxy
						loop square1a
					 pop ecx
					 sub dl, 14
					 inc dh
					 call Gotoxy
			loop square1
			
			mov dl, dl_1
			add dl, 4
			mov dh, dh_1
			call Gotoxy
		
			mov bl, 0
			mov ecx, 4
			mov eax, black + (white * 16)
			call SetTextColor
			printMark: push edx			   			   
							cmp X_or_O, 1
								je O_path
										
							X_path: mov edx, OFFSET player1Mark_								
								    mov eax, 0
								    mov al, LENGTHOF player1Mark_
								    mul bl	
								    jmp continuePrint
									
							O_path: mov edx, OFFSET player2Mark_
									mov eax, 0
									mov al, LENGTHOF player2Mark_
									mul bl
											 
							continuePrint: add edx, eax						
										   call WriteString
					   pop edx	   
					   inc dh
				       call Gotoxy
				       inc bl
			loop printMark
						
			mov eax, black + (white * 16)
			call SetTextColor
			
			;SQUARE 2: 
			mov dl, dl_2
			mov dh, dh_2
			call Gotoxy
			mov ecx, 5
			square2: push ecx
						mov ecx, 14
						square2a: mov al, ' '
								  call WriteChar
								  inc dl
								  call Gotoxy
						loop square2a
					 pop ecx
					 sub dl, 14
					 inc dh
					 call Gotoxy
			loop square2
			
			mov dl, dl_2
			add dl, 4
			mov dh, dh_2
			call Gotoxy
			
			mov bl, 0
			mov ecx, 4
			mov eax, black + (white * 16)
			call SetTextColor
			printMark2: push edx			   			   
							cmp X_or_O, 1
								je O_path2
										
							X_path2: mov edx, OFFSET player1Mark_								
								     mov eax, 0
								     mov al, LENGTHOF player1Mark_
								     mul bl	
								     jmp continuePrint2
									
							O_path2: mov edx, OFFSET player2Mark_
									 mov eax, 0
									 mov al, LENGTHOF player2Mark_
									 mul bl
											 
							continuePrint2: add edx, eax						
										    call WriteString
					   pop edx	   
					   inc dh
				       call Gotoxy
				       inc bl
			loop printMark2
			
			mov eax, black + (white * 16)
			call SetTextColor
			
			; SQUARE 3:
			mov dl, dl_3
			mov dh, dh_3
			call Gotoxy
			mov ecx, 5
			square3: push ecx
						mov ecx, 14
						square3a: mov al, ' '
								  call WriteChar
								  inc dl
								  call Gotoxy
						loop square3a
					 pop ecx
					 sub dl, 14
					 inc dh
					 call Gotoxy
			loop square3
			
			mov dl, dl_3
			add dl, 4
			mov dh, dh_3
			call Gotoxy
			
			mov bl, 0
			mov ecx, 4
			mov eax, black + (white * 16)
			call SetTextColor
			printMark3: push edx			   			   
							cmp X_or_O, 1
								je O_path3
										
							X_path3: mov edx, OFFSET player1Mark_								
								     mov eax, 0
								     mov al, LENGTHOF player1Mark_
								     mul bl	
								     jmp continuePrint3
									
							O_path3: mov edx, OFFSET player2Mark_
									 mov eax, 0
									 mov al, LENGTHOF player2Mark_
									 mul bl
											 
							continuePrint3: add edx, eax						
										    call WriteString
					   pop edx	   
					   inc dh
				       call Gotoxy
				       inc bl
			loop printMark3
			
			pop edx
			leave
	ret
	DrawWinPath ENDP
					 
END main