format pe console

include 'win32ax.inc'

entry main

; Data section
section '.data!!!' data readable writeable

input FILE 'day1_input.txt'

first_digit dd 0
last_digit dd 0
solution dd 0
output db 256 dup(0)				; Output string buffer

zero 	db 'zero',0
one 	db 'one',0
two 	db 'two',0
three 	db 'three',0
four 	db 'four',0
five 	db 'five',0
six 	db 'six',0
seven 	db 'seven',0
eight 	db 'eight',0
nine 	db 'nine',0

digits dd zero, one, two, three, four, five, six, seven, eight, nine

; Code section
section '.txt' code executable readable

str_len:
	; Calculate string length and put in ECX
	push esi
	dec esi
check_char:
	inc esi
	cmp byte [esi], 0
	jnz str_len
end_found:
	mov ecx, esi
	pop esi
	sub ecx, esi
	ret

is_digit:
	; Checks if the string byte in ESI is a digit
	; ZF=1 if it IS a digit, ZF=0 if it ISN'T a digit
	push eax					; Save EAX
	cmp byte [esi], '0'			; Check if digit is greater or equal than '0'
	setae ah
	cmp byte [esi], '9'			; Check if digit is lesser or equal than '9'
	setbe al					
	cmp al, ah					; Compare AL and AH
	pop eax						; Restore EAX
	ret

is_string_digit:
	; Checks if the string in ESI is pointing to an english digit string
	; ZF=1 if it IS a digit, ZF=0 if it ISN'T a digit
	; EAX should contain numeric value of digit string
	push ebx					; Save EBX
	push ecx					; Save ECX
	mov ebx, esi				; "backup" ESI in EBX
	mov ecx, 0					; Start with first string
check_next_digit:
	mov esi, ebx				; Restore ESI
	mov edi, [digits + ecx*4]	; Load the string to compare with
compare_next_char:
	cmp byte [edi], 0			; Check if end of dst string
	jz return_result			; End of dst string without mismatch, digit found!
	cmp byte [esi], 0			; Check if end of src string
	jz no_match					; Premature end of src string, no match
	cmpsb						; Compare the characters
	jnz no_match				; If zero flag not set, strings are different
	jmp compare_next_char
no_match:
	inc ecx						; Go to next string
	cmp ecx, 10					; Check if there is a next string (digit counter should be less than 10)
	jl check_next_digit			; If there is, check next string
								; Otherwise, no digit was found. 
	mov ecx, -1					; Prepare return value in ECX
return_result:
	mov esi, ebx				; Restore ESI from EBX
	mov eax, ecx				; Put ECX in EAX as return value
	pop ecx						; Restore ECX
	pop ebx						; Restore EBX
	ret

calculate_solution:
	mov esi, input				; Initialize ESI to input string

handle_next_line:
	cmp byte [esi], 0			; Check if end of input
	je solution_finished		; If so, return solution

	call find_next_digit		; Find first digit for the line
	cmp eax, -1					; Check if digit is found
	je handle_next_line			; Continue if end of line

	mov [first_digit], eax		; Store in [first_digit]
	mov [last_digit], eax		; Also store in [last_digit], in case there is only one

	call find_last_digit		; Find last digit for the line
	cmp eax, -1					; Check if digit is found
	je multiply_digits			; If no additional digit is found, we use the first digit twice
	mov [last_digit], eax		; Store in [last_digit]

multiply_digits:
	mov eax, [first_digit]		; Move first digit to EAX
	imul eax, 10				; First digit is the 10's-place, so multiply by 10
	add eax, [last_digit]		; Add second digit in the 1's-place
	add [solution], eax			; Add to solution
	jmp handle_next_line		; Continue with next line

solution_finished:
	ret

find_last_digit:
	mov edx, -1					; Reset EDX
continue_search:
	call find_next_digit		; Find the next digit
	cmp eax, -1					; Check if found
	jne store_digit				; If found, store it
	mov eax, edx				; If not found, whatever is in EDX is our result
	ret
store_digit:
	mov edx, eax				; Store digit in EBX
	jmp continue_search

find_next_digit:
	cmp byte [esi], 0			; Check for end of string
	jz end_of_input
	cmp byte [esi], 0x0D		; Check for CR
	jz handle_crlf
	cmp byte [esi], 0x0A		; Check for LF
	jz handle_lf
	call is_digit				; Check if current character is a digit
	jz digit_found				; If we found a digit, prepare for return
	call is_string_digit		; Check if the current string pointer is a text digit
	cmp eax, -1					; Check if result value was positive
	jne string_digit_found		; If not -1, a string digit was found
	inc esi						; Move to next character
	jmp find_next_digit			; Continue searching
digit_found:
	mov eax, 0
	mov byte al, [esi]			; Copy digit to eax
	sub eax, '0'				; Convert ASCII to decimal
	inc esi
	ret
string_digit_found:
	inc esi						; This actually doesn't skip the entire digit string, but we don't care
	ret
handle_crlf:
	inc esi						; Skip CR
handle_lf:
	inc esi						; Skip LF
end_of_input:
	mov eax, -1					; Set EAX to -1 to signal no result found
	ret

print_solution:
	; Convert to string
	cinvoke itoa,[solution],output,10

	; Print
	cinvoke printf,output

	ret

main:
	; Calculate and print solution
	call calculate_solution
	call print_solution

	; Exit succesfully
	push 0
	call [ExitProcess]
	  
section '.blah' import data readable

library \
	kernel32,'kernel32.dll',\
	msvcrt,'msvcrt.dll'

import kernel32,\
	ExitProcess,'ExitProcess'

import msvcrt,\
	printf,'printf',\
	itoa,'_itoa',\
	system,'system'
