.model small
.stack 100h
.286

.data
    prompt      db 'Enter a number (0-8): $'
    result_msg  db 0Dh, 0Ah, 'Factorial: $'
    error_msg   db 0Dh, 0Ah, 'Invalid input!$'
    buffer      db 5, ?, 5 dup('$')  ; Буфер для ввода
    num         dw 0
    factorial   dw 1

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
    mov si, offset buffer + 2  ; Начало введенных данных
    call atoi
    cmp ax, 8
    jg invalid_input
    cmp ax, 0
    jl invalid_input       ; Проверка на отрицательное число
    mov num, ax

    ; Вычисление факториала
    call calculate_factorial

    ; Вывод результата
    mov ah, 09h
    lea dx, result_msg
    int 21h

    mov ax, factorial
    call print_number

    jmp exit

invalid_input:
    mov ah, 09h
    lea dx, error_msg
    int 21h

exit:
    mov ah, 4Ch
    int 21h

; Преобразование строки в число (результат в AX)
atoi proc
    xor ax, ax
    xor cx, cx
    mov cl, [buffer + 1]  ; Длина ввода

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

; Вычисление факториала (num -> factorial)
calculate_factorial proc
    mov cx, num
    cmp cx, 0
    je done
    mov ax, 1
    mov factorial, ax
    mov cx, 1          ; Начинаем с 1

calc_loop:
    mov ax, factorial
    mul cx             ; AX = AX * CX
    mov factorial, ax
    inc cx             ; Увеличиваем множитель
    cmp cx, num        ; Проверяем, достигли ли исходного числа
    jle calc_loop      ; Если меньше или равно, продолжаем

done:
    ret
calculate_factorial endp

; Вывод числа из AX
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