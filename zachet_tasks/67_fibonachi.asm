.model small
.stack 100h
.286

.data
    prompt      db 'Enter n (0-23): $'
    result_msg  db 0Dh, 0Ah, 'Fibonacci number: $'
    error_msg   db 0Dh, 0Ah, 'Invalid input!$'
    buffer      db 5, ?, 5 dup('$')
    n           dw 0
    fib_num     dw 0

.code
start:
    mov ax, @data
    mov ds, ax

    ; Вывод приглашения
    mov ah, 09h
    lea dx, prompt
    int 21h

    ; Ввод числа
    mov ah, 0Ah
    lea dx, buffer
    int 21h

    ; Преобразование строки в число
    mov si, offset buffer + 2
    call atoi
    cmp ax, 23
    jg invalid_input
    cmp ax, 0
    jl invalid_input
    mov n, ax

    ; Вычисление числа Фибоначчи
    call fibonacci

    ; Вывод результата
    mov ah, 09h
    lea dx, result_msg
    int 21h

    mov ax, fib_num
    call print_number

    jmp exit

invalid_input:
    mov ah, 09h
    lea dx, error_msg
    int 21h

exit:
    mov ah, 4Ch
    int 21h

atoi proc
    xor ax, ax
    xor cx, cx
    mov cl, [buffer + 1]
convert_loop:
    imul ax, 10
    mov bl, [si]
    sub bl, '0'
    cmp bl, 9
    ja invalid
    add ax, bx
    inc si
    loop convert_loop
    ret
invalid:
    mov ax, -1
    ret
atoi endp

; Исправленная процедура вычисления Фибоначчи
fibonacci proc
    mov cx, n
    cmp cx, 0
    je case0
    cmp cx, 1
    je case1

    mov ax, 0      ; F(0) = 0
    mov bx, 1      ; F(1) = 1
    mov di, 1      ; Текущий индекс (начинаем с 1)

fib_loop:
    mov dx, ax     ; Сохраняем F(n-2)
    mov ax, bx     ; F(n-2) = F(n-1)
    add bx, dx     ; F(n-1) = F(n-1) + F(n-2)
    inc di
    cmp di, cx
    jl fib_loop
    
    mov fib_num, bx
    ret

case0:
    mov fib_num, 0
    ret
case1:
    mov fib_num, 1
    ret
fibonacci endp

print_number proc
    mov bx, 10
    xor cx, cx
divide_loop:
    xor dx, dx
    div bx
    push dx
    inc cx
    test ax, ax
    jnz divide_loop
print_loop:
    pop dx
    add dl, '0'
    mov ah, 02h
    int 21h
    loop print_loop
    ret
print_number endp

end start