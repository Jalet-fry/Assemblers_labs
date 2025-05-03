.model small
.stack 100h

.data
    prompt1 db 'Enter the first number in hexadecimal: $'
    prompt2 db 'Enter the second number in hexadecimal: $'
    result_and db 'AND result: $'
    result_or db 'OR result: $'
    result_xor db 'XOR result: $'
    result_not db 'NOT result (first number): $'
    error_msg db 'Error: overflow or invalid input.$'
    buffer db 6, 0 ; Буфер для ввода (5 символов + нулевой байт)
    num1 dw 0
    num2 dw 0

.code

start:
    ; Инициализация сегментных регистров
    mov ax, @data
    mov ds, ax
    mov es, ax

    ; Вывод приглашения для ввода первого числа
    mov ah, 09h
    mov dx, offset prompt1
    int 21h

    ; Ввод первого числа
    call input_hex_number
    jc error ; Если ошибка, переходим к обработке ошибки
    mov [num1], ax

    ; Вывод приглашения для ввода второго числа
    mov ah, 09h
    mov dx, offset prompt2
    int 21h

    ; Ввод второго числа
    call input_hex_number
    jc error ; Если ошибка, переходим к обработке ошибки
    mov [num2], ax

    ; Выполнение побитовых операций

    ; AND
    mov ax, [num1]
    and ax, [num2]
    mov ah, 09h
    mov dx, offset result_and
    int 21h
    call print_hex_number

    ; OR
    mov ax, [num1]
    or ax, [num2]
    mov ah, 09h
    mov dx, offset result_or
    int 21h
    call print_hex_number

    ; XOR
    mov ax, [num1]
    xor ax, [num2]
    mov ah, 09h
    mov dx, offset result_xor
    int 21h
    call print_hex_number

    ; NOT (для первого числа)
    mov ax, [num1]
    not ax
    mov ah, 09h
    mov dx, offset result_not
    int 21h
    call print_hex_number

    ; Завершение программы
    mov ax, 4C00h
    int 21h

error:
    ; Вывод сообщения об ошибке
    mov ah, 09h
    mov dx, offset error_msg
    int 21h
    mov ax, 4C00h
    int 21h

; Процедура для ввода 16-ричного числа
input_hex_number proc
    mov ah, 0Ah
    mov dx, offset buffer
    int 21h
    mov si, offset buffer + 1 ; Пропускаем первый байт (длина строки)
    call hex_to_bin
    ret
input_hex_number endp

; Процедура для преобразования 16-ричного числа в двоичное
hex_to_bin proc
    xor ax, ax
    xor cx, cx
    mov cl, [si] ; Длина строки
    inc si ; Переход к первому символу
convert_loop:
    shl ax, 4
    mov bl, [si]
    cmp bl, '0'
    jb hex_error
    cmp bl, '9'
    jbe digit
    cmp bl, 'A'
    jb hex_error
    cmp bl, 'F'
    jbe letter
    cmp bl, 'a'
    jb hex_error
    cmp bl, 'f'
    jbe lowercase
    jmp hex_error
digit:
    sub bl, '0'
    jmp next
letter:
    sub bl, 'A' - 10
    jmp next
lowercase:
    sub bl, 'a' - 10
next:
    or al, bl
    inc si
    loop convert_loop
    clc ; Успешное завершение
    ret
hex_error:
    xor ax, ax ; Очистка ax
    stc ; Установка флага ошибки
    ret
hex_to_bin endp

; Процедура для вывода 16-ричного числа
print_hex_number proc
    push ax
    push bx
    push cx
    push dx
    mov cx, 4 ; 4 шестнадцатеричные цифры
print_loop:
    ror ax, 4
    mov dl, al
    and dl, 0Fh
    cmp dl, 9
    jbe print_digit
    add dl, 'A' - 10
    jmp print_char
print_digit:
    add dl, '0'
print_char:
    mov ah, 02h
    int 21h
    loop print_loop
    pop dx
    pop cx
    pop bx
    pop ax
    ret
print_hex_number endp

end start