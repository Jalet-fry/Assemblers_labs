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
    result_not_first db 'NOT result (first number): $'
    result_not_second db 'NOT result (second number): $'
    result_not_first_again db '2nd NOT result (first number): $'
    result_not_second_again db '2nd NOT result (second number): $'
    error_msg db 'Error: overflow or invalid input.$'
    error_message db 0Ah,0Dh,"Invalid input! Only in [A,F], [a,f], [0,9], +, - and single spaces allowed.",0Ah,0Dh,'$'

.code

print_string macro string 
    mov ah,09h
    mov dx,offset string
    int 21h
endm

print_new_line proc

    push ax        
    push dx        
    ; Вывод перевода строки (CR+LF)
    mov ah, 02h    ; Функция DOS для вывода символа
    mov dl, 0Dh    ; Символ возврата каретки (CR)
    int 21h        
    mov dl, 0Ah    ; Символ перевода строки (LF)
    int 21h        

    pop dx         
    pop ax         
    ret            
print_new_line endp

print_str proc
    push ax        
    push dx        

    mov ah, 09h    ; Функция DOS для вывода строки
    int 21h        ; Вызов прерывания DOS

    call print_new_line

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


    mov ax,4C00h 
    int 21h

print_result proc
    push ax
    mov ax, result
    call print_signed_hex
    call print_new_line
    call print_binary
    call print_new_line
    pop ax
    ret
print_result endp
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
    call read_1_digit
    call check_after_read_digit
    mov dig1, bx 

;after_convert_1_digit
    call skip_spaces
    call what_is_sign
    call read_1_digit
    call check_after_read_digit
    cmp al, 13
    je all_good
    cmp al, ' '
    jne bad_people
    call skip_spaces
    cmp al, 13
    je all_good
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
    cmp sign, '-'
    jne positive_check
    
    ; Отрицательное число:
    cmp bx, 8000h       ; Проверяем, не больше ли 8000h
    ja overflow_error   ; Если больше — ошибка переполнения
    neg bx              ; Преобразуем в доп. код
    jmp end_check
    
positive_check:
    cmp bx, 7FFFh       
    ja overflow_error   
    
end_check:
    ret
    
overflow_error:
    print_string error_msg
    mov ax, 4C00h
    int 21h
check_after_read_digit endp

what_is_sign proc
    ; SI указывает на текущий символ в строке
    cmp al, '+'
    je is_sign
    cmp al, '-'
    je is_sign
    
    ; Если знака нет:
    mov sign, '+'          ; По умолчанию '+'
    ret                    ; Выход 1 — знака не было, откатились
    
is_sign:
    mov sign, al           ; Сохраняем знак (+/-)
    lodsb
    ret                    ; Выход 2 — знак был, не откатываемся
what_is_sign endp

logic_operation proc
    call and_proc 
    mov dx, offset result_and
    call print_str                           
    call print_result

    call or_proc
    mov dx, offset result_or
    call print_str                           
    call print_result

    call xor_proc
    mov dx, offset result_xor
    call print_str                           
    call print_result

    mov ax, dig1
    mov dx, offset result_not_first
    call not_proc
    ;mov dx, offset result_not_first_again
    ;call not_proc

    mov ax, dig2
    mov dx, offset result_not_second
    call not_proc
    ;mov dx, offset result_not_second_again
    ;call not_proc

    ret
logic_operation endp

not_proc proc
    not ax
    mov result, ax
    call print_str                           
    call print_result
    ret
not_proc endp

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

; Вывод числа в двоичном виде (16 бит)
print_binary proc
    push ax
    push bx
    push cx
    push dx
    
    mov bx, ax      ;
    mov cx, 16      ; 16 бит для вывода
    
binary_loop:
    rol bx, 1       ; Сдвигаем старший бит в CF
    mov dl, '0'     ; По умолчанию выводим '0'
    jnc print_bit   ; Если CF=0, оставляем '0'
    mov dl, '1'     ; Если CF=1, меняем на '1'
    
print_bit:
    push bx         ; Сохраняем BX (так как INT 21h портит его)
    mov ah, 02h     ; Функция вывода символа
    int 21h         ; Выводим '0' или '1'
    pop bx          ; Восстанавливаем BX
    
    ; Добавляем пробел каждые 4 бита для удобства чтения
    mov ax, cx      ; Текущий счетчик в AX
    dec ax          ; Уменьшаем на 1 (т.к. CX уже уменьшился после loop)
    test ax, 03h    ; Проверяем, кратно ли 4 (остаток от деления на 4)
    jnz skip_space  ; Если не кратно, пропускаем пробел
    
    ; Выводим пробел (только если это не последний бит)
    cmp cx, 1
    je skip_space
    push bx
    mov dl, ' '     ; Пробел для разделения тетрад
    mov ah, 02h
    int 21h
    pop bx
    
skip_space:
    loop binary_loop
    
    ; Выводим 'b' в конце, чтобы обозначить binary формат
    mov dl, 'b'
    mov ah, 02h
    int 21h
    
    call print_new_line ; Новая строка для удобства
    
    pop dx
    pop cx
    pop bx
    pop ax
    ret
print_binary endp

end start