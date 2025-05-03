.model small
.stack 100h

.data
    CountsOfSymbol EQU 15
    buffer db CountsOfSymbol+1 dup(0) 
    dig1 dw 0
    dig2 dw 0
    sign db 0
    operation db 0
    result dw 0
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
    call logic_operation

    push ax
    mov ax, result
    call print_signed_hex
    pop ax

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
    call what_is_sign
after_sign:
    lodsb
    call read_1_digit
    call check_after_read_digit
    mov dig1, bx 
after_convert_1_digit:
    call skip_spaces
    call remember_operation
    call skip_spaces

    call what_is_sign
    lodsb
    call read_1_digit
    call check_after_read_digit
    cmp al, 13
    je all_good
    cmp al, ' '
    jne bad_people
    call skip_spaces
    cmp al, 13
    je all_good
;bad_input:
;    print_string error_message
;    mov ax, 4c00h
;    int 21h
;ToDO: print error and exit
all_good:
    mov dig2, bx
    pop si
    pop dx
    pop cx
    pop bx
    pop ax
    ret
bad_people:
    call bad_input
get_numbers endp

bad_input proc
    print_string error_message
    mov ax, 4c00h
    int 21h
bad_input endp


skip_spaces proc 
spaces:
    lodsb
    cmp al, ' '
    je spaces
    ret
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


check_after_read_digit proc
    cmp sign, '+'
    je not_to_do 
    cmp sign, '-'
    jne bad_input
    neg bx
    ;not bx
    ;inc bx
not_to_do:
    ret
check_after_read_digit endp

what_is_sign proc
    cmp al, '+'
    jne is_minus 
    mov sign, al 
    jmp sign_is_good
is_minus:
    cmp al, '-'
    je minus 
    call bad_input
minus:
    mov sign, al
sign_is_good:
    ret
what_is_sign endp


logic_operation proc
    cmp operation, '&'
    jne is_it_or
    call and_proc 
    jmp logic_is_done
is_it_or:
    cmp operation, '|'
    jne is_it_xor
    call or_proc
    jmp logic_is_done
is_it_xor:
    cmp operation, '^'
    jne whaaat
    call xor_proc
    jmp logic_is_done
whaaat:
    call bad_input
logic_is_done:
    ret
logic_operation endp

and_proc proc
    push ax
    push bx

    mov ax, dig1
    mov bx, dig2
    and ax, bx 
    mov result, ax

    pop bx
    pop ax
    ret
and_proc endp


or_proc proc
    push ax
    push bx

    mov ax, dig1
    mov bx, dig2
    or ax, bx 
    mov result, ax

    pop bx
    pop ax
    ret
or_proc endp


xor_proc proc
    push ax
    push bx

    mov ax, dig1
    mov bx, dig2
    xor ax, bx 
    mov result, ax

    pop bx
    pop ax
    ret
xor_proc endp


remember_operation proc
    cmp al, '&'
    je operation_is_logic 
    cmp al, '|'
    je operation_is_logic
    cmp al, '^'
    je operation_is_logic
    call bad_input
operation_is_logic:
    mov operation, al 
    ret
remember_operation endp

;           ; Процедура вывода числа в HEX виде
;           ; Вход: AX - число для вывода
;           print_hex proc
;               push ax
;               push bx
;               push cx
;               push dx
;               
;               mov bx, ax      ; Сохраняем число в BX
;               mov cx, 4       ; Будем обрабатывать 4 шестнадцатеричных цифры
;               
;           print_hex_loop:
;               rol bx, 4       ; Циклический сдвиг влево на 4 бита (чтобы обрабатывать цифры слева направо)
;               mov al, bl      ; Копируем младший байт в AL
;               and al, 0Fh     ; Оставляем только младшие 4 бита (одну цифру)
;               
;               ; Преобразуем цифру в символ
;               cmp al, 10
;               jl is_digit
;               add al, 'A' - 10 ; Для цифр A-F
;               jmp print_char
;           is_digit:
;               add al, '0'      ; Для цифр 0-9
;               
;           print_char:
;               mov dl, al      ; Готовим символ для вывода
;               mov ah, 02h     ; Функция вывода символа
;               int 21h         ; Выводим символ
;               
;               loop print_hex_loop ; Повторяем для всех 4 цифр
;               
;               ; Выводим 'h' в конце, чтобы обозначить hex формат
;               mov dl, 'h'
;               mov ah, 02h
;               int 21h
;               
;               pop dx
;               pop cx
;               pop bx
;               pop ax
;               ret
;           print_hex endp

; Вывод 16-битного числа в HEX с обязательным знаком (+/-)
; Вход: AX - число для вывода
print_signed_hex proc
    push ax
    push bx
    push cx
    push dx
    
    test ax, ax      ; Проверяем знак числа
    jns positive_num ; Если положительное (SF=0)
    
    ; Отрицательное число:
    mov dl, '-'      ; Выводим '-'
    push ax
    mov ah, 02h
    int 21h
    pop ax
    
    neg ax           
    ;inc ax
    ;toDo хз надо ли inc или нет
    jmp print_value  ; Пропускаем вывод '+'
    
positive_num:
    mov dl, '+'      ; Выводим '+' для положительных чисел
    push ax
    mov ah, 02h
    int 21h
    pop ax
    
print_value:
    call print_hex   ; Выводим само число в HEX
    
    pop dx
    pop cx
    pop bx
    pop ax
    ret
print_signed_hex endp
; Вспомогательная процедура: вывод беззнакового HEX (как раньше)
print_hex proc
    push ax
    push bx
    push cx
    push dx
    
    mov bx, ax      ; Сохраняем число
    mov cx, 4       ; 4 цифры
    
print_loop:
    rol bx, 4       ; Сдвигаем старшую цифру в младшие 4 бита
    mov al, bl
    and al, 0Fh     ; Изолируем цифру
    
    cmp al, 10
    jl is_digit
    add al, 'A' - 10 
    jmp print_digit
is_digit:
    add al, '0'      
    
print_digit:
    mov dl, al
    mov ah, 02h
    int 21h
    
    loop print_loop
    
    mov dl, 'h'     
    mov ah, 02h
    int 21h
    
    pop dx
    pop cx
    pop bx
    pop ax
    ret
print_hex endp

end start