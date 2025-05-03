.model small
.stack 100h

.data
    CountsOfSymbol EQU 5
    buffer db CountsOfSymbol+1 dup(0) 
    dig1 dw 0
    dig2 dw 0
    sign db 0
    input_string_msg db "Input your string:",0ah,0dh,'$'
    prompt1 db 'Enter the first number in HEX: $'
    prompt2 db 'Enter the second number in HEX: $'
    result_and db 'AND result: $'
    result_or db 'OR result: $'
    result_xor db 'XOR result: $'
    result_not db 'NOT result (first number): $'
    error_msg db 'Error: overflow or invalid input.$'
    error_message db 0Ah,0Dh,"Invalid input! Only in [A,F], [a,f], [0,9], +, - and single spaces allowed.",0Ah,0Dh,'$'

.code

print_string macro string 
    mov ah,09h
    mov dx,offset string
    int 21h
endm


print_str proc
    push ax        
    push dx        

    mov ah, 09h    ; Функция DOS для вывода строки
    int 21h        ; Вызов прерывания DOS

    ; Вывод перевода строки (CR+LF)
    mov ah, 02h    ; Функция DOS для вывода символа
    mov dl, 0Dh    ; Символ возврата каретки (CR)
    int 21h        
    mov dl, 0Ah    ; Символ перевода строки (LF)
    int 21h        

    pop dx         
    pop ax         
    ret            
print_str endp

start:
    mov ax,@data
    mov ds,ax 
    mov es,ax
    mov dx, offset input_string_msg
    call print_str                           
    call validate_input
    call get_numbers


    mov ax,4C00h 
    int 21h

; ======= Input Validation =======
validate_input proc
    push ax
    push cx
    push dx
    push di
    LEA  DI,  buffer
    mov cx, CountsOfSymbol
validate_loop:
    mov ah, 01h ;1 symbol
    int 21h
    cmp al, 13
    je if_symbol_is_enter
    stosb
    loop validate_loop
    mov al, 13
if_symbol_is_enter:
    stosb
    pop di
    pop dx
    pop cx
    pop ax
    ret
validate_input endp

; ======= Get Numbers =======
; al for input, bx for number
; cx for loop, dl is operand's count
; dh is a flag that we have at least 1 digit in number  
get_numbers proc
    push ax
    push bx
    push cx
    push dx
    push si

;& | ^
    lea  si,  buffer
    mov bx, 0
    mov dx, 0
    call skip_spaces

    cmp al, '+'
    jne is_minus 
    mov sign, al 
    jmp after_sign
is_minus:
    cmp al, '-'
    jne bad_input 
minus:
    mov sign, al 
after_sign:
    call read_1_digit
    cmp al, ' '
    jne bad_input
    mov dig1, bx
    call skip_spaces
    call read_1_digit
    cmp al, 13
    je all_good
    cmp al, ' '
    jne bad_input
    call skip_spaces
    cmp al, 13
    je all_good
bad_input:
    print_string error_message
    mov ax, 4c00h
    int 21h
;ToDO: print error and exit
all_good:
    mov dig2, bx
    pop si
    pop dx
    pop cx
    pop bx
    pop ax
    ret
get_numbers endp

skip_spaces proc 
spaces:
    lodsb
    cmp al, ' '
    je spaces
skip_spaces endp

read_1_digit proc
    mov cx, 4
    mov bx, 0
hex:
    cmp al, '0'               
    jl end_hex
    cmp al, '9'               
    jg big_letter
    shl bx, 4
    sub al, '0'
    or bl, al
    jmp next

big_letter:
    cmp al, 'A'               
    jl end_hex
    cmp al, 'F'               
    jg small_letter
    shl bx, 4
    sub al, 'A' - 10
    or bl, al
    jmp next

small_letter:
    cmp al, 'a'               
    jl end_hex
    cmp al, 'f'               
    jg end_hex
    shl bx, 4
    sub al, 'a' - 10
    or bl, al

next:
    lodsb
    loop hex
end_hex:
    ret
read_1_digit endp


end start