TITLE prog06A     (prog06A.asm)

INCLUDE Irvine32.inc


;-------------------------------------------------------------------------
getString MACRO address_string, lengthOfString
	
	.data
	promptRules			BYTE	"Please enter an unsigned number: ", 0
	
	.code
	
	push		edx
	push		ecx
	mov	  	edx, OFFSET promptRules
	call		WriteString
	mov	  	edx, address_string ; points to the input buffer
	mov	  	ecx, lengthOfString ; max number of non-null chars to read
	call		ReadString
	pop	  	ecx
	pop	  	edx
	
ENDM
;-------------------------------------------------------------------------


;-------------------------------------------------------------------------
displayString MACRO address_string

	push		edx
	mov	  	edx, OFFSET address_string
	call		WriteString
	pop	  	edx
	
ENDM
;-------------------------------------------------------------------------

MAXSIZE = 10 ; max size of array for user inputted integers

.data

;-------------------------------------------------------------------------
;		This is the introduction, prompts for instructions and goodbye   -
;-------------------------------------------------------------------------

promptIntro1			BYTE	"PROGRAMMING ASSIGNMENT 5: Designing low-level I/O procedures Written by: Matt Ksiazek. ", 0
promptIntro2	  		BYTE	"Please provide 10 unsigned decimal integers. Each number needs to be small enough to fit inside a 32 bit register. ", 0
promptIntro3	  		BYTE	"After you have finished inputting the raw numbers I will display a list of the integers, their sum, and their average value.",  0
outOfRangePrompt		BYTE	"ERROR: You did not enter an unsigned number or your number was too big. Please try again.", 0
arrayPrompt	    		BYTE	"You entered the following numbers: ", 0
sumString		    	BYTE	"The sum of these numbers is: ", 0
averagePrompt		  	BYTE	"The average is: ", 0
goodbyePrompt		  	BYTE	"Thanks for playing!", 0
spaces3			      	BYTE	"   ", 0 ; This is needed to have 3 spaces between the numbers

;--------------------------------------------------------------------------
; These are the variables to hold the user entered number of elemnts, as
; well as the variables to hold the average and sum of the integeres
;--------------------------------------------------------------------------


arrayOfNumbers			DWORD 	MAXSIZE DUP (0)
arrayOfStrings			DWORD 	MAXSIZE DUP (0) ; temp array to hold strings before they are converted
sum			          	DWORD 	? ; this variable holds the sum of the integers inputted
average			     	DWORD	? ; this variable holds the average of the integeres inputted

;-------------------------------------------------------------------------------------------------------------------



.code
main PROC


call introduction


mov		ecx, MAXSIZE ; needed to loop through 10 times
mov		esi, OFFSET arrayOfNumbers

loopArray:

push	OFFSET outOfRangePrompt ; ebp + 16
push	OFFSET arrayOfStrings ; ebp + 12
push	MAXSIZE ; ebp + 8
call	readVal

mov		eax, arrayOfStrings
mov		[esi], eax
add		esi, 4 ; next element in array

loop loopArray

push	MAXSIZE ; ebp + 12
push	OFFSET arrayOfNumbers ; ebp + 8
call	summationOfArray

push	sum ; ebp + 12
push	MAXSIZE ; ebp + 8
call	averageOfInput

call	farewell

exit	; exit to operating system
main ENDP


;-------------------------------------------------------------------
; Procedure to introduce the user to the program and displays rules
; receives: N/A
; returns: N/A
; preconditions: N/A
; registers changed: N/A
;-------------------------------------------------------------------

			  
introduction	PROC													  
																		 
displayString promptIntro1
call  Crlf
call  Crlf
displayString promptIntro2
call  Crlf
displayString promptIntro3
call  Crlf
call  Crlf

ret

introduction ENDP

;-------------------------------------------------------------------
; Procedure to get the user's string into an integer while also validating
; receives: outOfRangePrompt and arrayOfStrings pushed on stack
; returns: String user entered validated and converted to int data type
; preconditions: outOfRangePrompt and arrayOfStrings pushed on stack
; registers changed: EAX, EBX, ECX, ESI
;-------------------------------------------------------------------


; readVal should invoke the getString macro to get the user’s string of digits. 
; It should then convert the digit string to numeric, while validating the user’s input.

readVal	PROC

pushad
mov		ebp, esp

beginningOfLoop:

getString	[ebp + 40],[ebp + 36]

mov		esi, [ebp + 40] ; @arrayOfStrings
mov		eax, 0
mov		ebx, 10 ; needed to multiply inputted string to get correct ASCII value
mov		ecx, 0


ifInputIsCorrect:

cld ; clear flag to move forward in array

lodsb
cmp		al, 0 ; checks if the null character is reached, and if it is then to end the validation
je		endOfValadation ; al == 0

cmp		al, 48 ; 0 is at ASCII 48
jb		notAInteger ; CF = 1 :Jump if below/not above or equal

cmp		al, 57 ; 9 is at ASCII 57
ja		notAInteger ; CF = 0 and ZF = 0 :Jump if above/not below or equal

; if input is in range 0-9 then proceed

sub		al, 48 ; to convert from string to integer
xchg	eax, ecx
mul		ebx

jc		notAInteger ; jump if carry (CF = 1) which means it is not an integer
jnc		isAInteger ; jump if NOT carry (CF = 0) which validates it is a integer

notAInteger:

displayString outOfRangePrompt ;  print out error message and loop back to beginningOfLoop
call	CrLf
jmp		beginningOfLoop

isAInteger:

add		eax, ecx
xchg	eax, ecx
jmp		ifInputIsCorrect

endOfValadation:

cmp   ecx, 214748364 ;this compare will make sure the number will fit inside 32 bits
JG    notAInteger
cmp   ecx, 111111111 ; 
JGE   notAInteger

xchg	ecx, eax
mov		arrayOfStrings, eax

popad
ret 12 

readVal ENDP
;---------------------------------------------------------------------------

;-------------------------------------------------------------------
; Procedure to convert a numeric value to a string of digits.
; receives: outOfRangePrompt and arrayOfStrings pushed on stack
; returns: arrayOfStrings after being converted to display results
; preconditions: outOfRangePrompt and arrayOfStrings pushed on stack
; registers changed: EAX, EBX, EBP, EDI
;-------------------------------------------------------------------

; writeVal should convert a numeric value to a string of digits, 
; and invoke the displayString macro to produce the output

writeVal PROC
pushad
mov		ebp, esp
mov		eax, [ebp + 40] 
mov		edi, [ebp + 36] 
mov		ebx, 10 
push	0 

convertToInt:

mov 	edx, 0
div 	ebx
add		edx, 48
push 	edx

cmp		eax, 0
JNE 	convertToInt

L2:

pop		[edi]
mov		eax, [edi]
inc		edi
cmp		eax, 0
JNE		L2

mov		edx, [ebp + 36]
displayString OFFSET arrayOfStrings

popad
ret 8

writeVal ENDP

;-------------------------------------------------------------------
; Procedure to calculate sum of the inputs
; receives: MAXSIZE and OFFSET of arrayOfNumbers is pushed on stack
; returns: sum of the user inputted elements
; preconditions: MAXSIZE and OFFSET of arrayOfNumbers is pushed on stack
; registers changed: EAX, EBX, ECX, ESI
;-------------------------------------------------------------------
summationOfArray	PROC													  

pushad					
mov		ebp, esp
mov		ecx, [ebp + 40] ; MAXSIZE
mov		esi, [ebp + 36] ; @arrayOfNumbers
mov		ebx, 0									 
call	CrLf

displayString arrayPrompt

summationLoop:

mov		eax, [esi]
add		ebx, eax ; adding elements together

push	eax
push	OFFSET arrayOfStrings
call	WriteVal

displayString spaces3
add		esi, 4 ; move to next array element
loop	summationLoop

; when sum is calculated

mov		eax, ebx
mov		sum, eax ; put sum into sum variable
call	CrLf
displayString sumString
call	WriteDec

popad
ret 8

summationOfArray ENDP

;-------------------------------------------------------------------
; Procedure to calculate average of the inputs
; receives: sum is pushed on stack
; returns: average of the user inputted elements
; preconditions: sum is pushed on stack
; registers changed: EAX, EBX, ECX, EDX, ESI
;-------------------------------------------------------------------


averageOfInput		PROC

pushad
mov		ebp, esp
mov		eax, [ebp + 40] ; variable holding sum
mov		ebx, [ebp + 36] ; MAXSIZE
mov		edx, 0

; divide sum by 10 since that is how many elements were inputted

div		ebx ; sum/10 and puts quotient is in eax, remainder is in edx

mov		ecx, eax ; move average into ECX
mov		eax, edx ; zero out EAX
mov		edx, 2 
mul		edx ; mul EBX = EBX*EAX and stores result eax
mov		eax, ecx
mov		average, eax

call	CrLf
displayString averagePrompt

push	average
push	OFFSET arrayOfStrings
call	WriteVal

popad
ret 8

averageOfInput ENDP

;-------------------------------------------------------------------
; Procedure to say goodbye to the user
; receives: N/A
; returns: N/A
; preconditions: N/A
; registers changed: N/A
;-------------------------------------------------------------------

farewell	PROC

call	CrLf
call	CrLf
displayString goodbyePrompt
call	CrLf
call	CrLf

ret

farewell ENDP


END main
