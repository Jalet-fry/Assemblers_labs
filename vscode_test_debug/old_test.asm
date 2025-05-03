.model small            
.stack 300h            
.386                   

.data                  
    welcome db "Usage:test.exe path.txt N K", '$'
    exec_msg db 13, 10, "Trying execute program $" ; Сообщение о запуске программы
    prog_start_err_msg db 13, 10, "Program start error$"      ; Сообщение об ошибке запуска
    prog_closed_msg db 13, 10, "Press any key to see result$" ; Сообщение-приглашение
    opened db 13, 10, "File has been opened$" 
    closed db 13, 10, "File has been closed$" 
    not_found_file db 13, 10, "File not found!$"
    exec_success db 13, 10, "Program executed successfully$"
    exec_error db 13, 10, "Error executing program$"
    text db "HELLO.EXE",0
  ; сообщения об ошибках
    read_error_msg db "Error reading file", '$'
    eof_reached_msg db "End of file reached", '$'
    no_args_message db "Error: No arguments provided", '$'
    path_empty_message db "Error: File path is empty", '$'
    first_num_empty_message db "Error: First number is missing", '$'
    first_num_invalid_message db "Error: First number is invalid (must be 1-255)", '$'
    second_num_empty_message db "Error: Second number is missing", '$'
    second_num_invalid_message db "Error: Second number is invalid (must be 1-255)", '$'
    extra_args_message db "Error: Too many arguments provided", '$'

    goodbye db "Goodbye!!", '$'
    hello db "hello", '$'
    first db "first", '$'
    second db "second", '$'
    we_are_in_conv db "we_are_in_conv", '$'
    bad_params_message db "Bad cmd arguments", '$'         
    bad_source_file_message db "Cannot open file", '$'     
    file_not_found_message db "File not found", '$'        
    error_closing_file_message db "Cannot close file", '$'  
    error_read_file_text_message db "Error reading from file", '$' 
    file_is_empty_message db "File is empty", '$'           

    b_num_10 db 10                      ; Число 10 для конвертации (десятичная система)
    space_char equ 32                   ; ASCII-код пробела
    new_line_char equ 13                ; ASCII-код символа новой строки (CR)
    return_char equ 10                  ; ASCII-код возврата каретки (LF)
    tabulation equ 9                    ; ASCII-код табуляции
    endl_char equ 0                     ; ASCII-код конца строки (нуль-терминатор)
    symbol  db ?                        ; Буфер для хранения текущего символа из файла
    flag_not_empty dw 0                 ; Флаг: 0 - файл пуст, 1 - файл не пуст


    max_size equ 20                  
    cmd_size db ?                       ; Размер командной строки (количество символов)
    cmd_text db max_size + 2 dup('$')     ; Буфер для хранения командной строки 
    path db max_size + 2 dup('$')         ; Буфер для хранения пути к файлу
    number_text db max_size + 2 dup('$')  ; Буфер для хранения числа (максимальная длина)
    number_text2 db max_size + 2 dup('$') ; Буфер для второго числа

    num_10 db 10                        ; Еще одна константа для деления на 10

    ; Временные переменные:
    file_desc dw 0                      ; Дескриптор файла (идентификатор)
    num1 dw 0                           ; Первое число (1-255)
    num2 dw 0                           ; Второе число (1-255)
    lines_counter dw 0                  ; Счетчик строк, удовлетворяющих условию
    buffer db max_size + 2 dup(0)       ; Буфер для чтения данных из файла

    ; Структура EPB (Environment Parameter Block) для запуска программы
    EPB dw 0                                         ; Сегмент среды (0 - использовать текущую)
    cmd_seg dw ?                                     ; Сегмент командной строки
    fcb1 dd ?                                        ; FCB (File Control Block) 1
    fcb2 dd ?                                        ; FCB (File Control Block) 2
    EPB_len dw $ - EPB                               ; Длина EPB

    dsize = $ - welcome                             ; Размер сегмента данных в байтах
.code                  

exit_app macro
   mov ax, 4C00h      ; Функция DOS 4Ch - завершение программы
   int 21h            
endm

print_new_line proc

    push ax        
    push dx        
    ; Вывод перевода строки (CR+LF)
    mov ah, 02h    ; Функция DOS для вывода символа
    mov dl, new_line_char    ; Символ возврата каретки (CR)
    int 21h        
    mov dl, return_char    ; Символ перевода строки (LF)
    int 21h        

    pop dx         
    pop ax         
    ret            
print_new_line endp

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

skip_spaces proc 
skip_spaces_loop:
    mov dl, [si]       ; Берем текущий символ
    cmp dl, ' '        ; Сравниваем с пробелом
    jne skip_spaces_end ; Если не пробел - выходим
    inc si             ; Переходим к следующему символу
    jmp skip_spaces_loop ; Повторяем проверку
skip_spaces_end:
    ret
skip_spaces endp

; Макрос для чтения командной строки:
read_cmd proc
    xor ch, ch         ; Обнуляем ch (для использования cx как 16-битного счетчика)
    mov cl, ds:[80h]   

    push ds
    mov ax, @data
    mov ds, ax
    mov cmd_size, cl   ; Сохраняем длину в переменную cmd_size
    pop ds
    cmp cl, 0
    je no_args_error
    mov si, 81h        ; Указываем на начало командной строки в PSP
    mov di, offset cmd_text 
    rep movsb          ; Копируем командную строку из si в di cl раз в cmd_text
    ; mov byte ptr [di], 0
    ; mov byte ptr [di], '$'
    ret
endp

; Макрос для вывода строки на экран:
show_str macro out_str
    push ax            
    push dx            
    mov ah, 9h         ; Функция DOS 09h - вывод строки
    mov dx, offset out_str ; Указываем адрес строки
    int 21h            
    mov dl, return_char ; Загружаем символ возврата каретки (LF)
    mov ah, 2h         
    int 21h            
    mov dl, new_line_char ; Загружаем символ новой строки (CR)
    mov ah, 2h         
    int 21h            
    pop dx             
    pop ax             
endm

; Вход: SI - адрес строки (заканчивается 0 или '$')
; Процедура для вывода строки посимвольно (без lodsb)
; Вход: SI - адрес строки (заканчивается 0 или '$')
show_string proc
    push ax
    push dx
    push si
    
    mov ah, 02h        ; Функция DOS для вывода символа
    
print_loop:
    ; mov dl, [si]       ; Загружаем символ напрямую из памяти
    lodsb
    cmp al, 0          ; Проверяем на нуль-терминатор
    je print_end       ; Если 0 - завершаем
    cmp al, '$'        ; Проверяем на символ конца строки
    je print_end       ; Если '$' - завершаем
    
    mov dl, al
    int 21h            ; Выводим символ
    ; inc si             ; Переходим к следующему символу
    jmp print_loop     ; Продолжаем цикл
    
print_end:
    ; Выводим перевод строки (CR+LF)
    mov dl, new_line_char ; CR
    int 21h
    mov dl, return_char ; LF
    int 21h
    
    pop si
    pop dx
    pop ax
    ret
show_string endp

; Макрос для проверки, пуста ли строка:
is_empty_line macro text_line, marker  
    push si            
    mov si, offset text_line ; Указываем адрес строки
    call strlen        
    pop si             
    cmp ax, 0          
    je marker
    cmp ax, '$'          
    je marker
endm

; Процедура для вычисления длины строки:
strlen proc
    push bx            
    push si            
    xor ax, ax         ; Обнуляем ax (здесь будет длина строки)
start_calculation:
    mov bl, ds:[si]    ; Загружаем текущий символ строки
    cmp bl, endl_char  
    je end_calculation ; Если конец строки, выходим
    inc si             ; Переходим к следующему символу
    inc ax             ; Увеличиваем счетчик длины
    jmp start_calculation ; Повторяем цикл
end_calculation:
    pop si             
    pop bx             
    ret                
endp

; Процедура для вывода числа на экран:
print_result proc
    push dx    
    push bx            ;
    mov bx, ax         ; Сохраняем число в bx
    mov bp, sp         ; Сохраняем указатель стека в bp
loop1:
    cmp ax, 0          
    je skip_actions    ; Если 0, пропускаем деление
    div b_num_10       ; Делим ax на 10 (результат в al, остаток в ah)
    xor bx, bx         
    mov bl, ah         ; Сохраняем остаток в bl
    xor ah, ah         
skip_actions:
    push bx            ; Сохраняем цифру в стеке
    cmp al, 0          ; Проверяем, осталось ли что-то от числа
    je print_num       ; Если нет, переходим к выводу
    jmp loop1          ; Иначе продолжаем деление
print_num:
    loop3:
        xor dx, dx     
        pop bx         ; Извлекаем цифру из стека
        add bx, '0'    ; Преобразуем цифру в символ
        mov ah, 02h    
        mov dl, bl     ; Загружаем символ в dl
        int 21h        ; Выводим символ
        cmp bp, sp     ; Сравниваем указатель стека с начальным значением
        jne loop3      ; Если стек не пуст, продолжаем вывод
    pop bx             
    pop dx             
    ret                
endp

; Процедура для конвертации строки в число с проверкой диапазона [1, 255]
; Вход: DS:SI - адрес строки с числом
; Выход: AX - число (0 если ошибка)
; CF = 1 если ошибка (не число или вне диапазона)
conv proc
    push bx            
    push cx            
    
    xor ax, ax         
    xor bx, bx         
    xor dx, dx         
    ; show_str first 
    ; show_str we_are_in_conv 
    ; call print_binary
    xor cx, cx         ; Обнуляем счетчик цифр
    mov bx, 10         ; Основание системы счисления
    
conv_loop:
    mov dl, [si]       ; Берем текущий символ
    cmp dl, endl_char  ; Конец строки?
    je check_range     ; Да - проверяем диапазон
    cmp dl, '$'  ; Конец строки?
    je check_range     ; Да - проверяем диапазон
    cmp dl, space_char  
    je check_range     ; Да - проверяем диапазон
    cmp dl, '0'        
    jl conv_error      ; Меньше '0' - ошибка
    cmp dl, '9'        
    jg conv_error      ; Больше '9' - ошибка
    
    sub dl, '0'        ; Преобразуем символ в цифру
    imul ax, bx        ; Умножаем текущий результат на 10
    ; push dx
    ; IMUL bx      ; Стало (для 8086)
    jc conv_error      ; Если переполнение - ошибка
    ; pop dx

    add ax, dx         ; Добавляем новую цифру
    ; show_str second 
    ; show_str we_are_in_conv 
    ; call print_binary
    jc conv_error      ; Если переполнение - ошибка
    inc si             ; Переходим к следующему символу
    inc cx             ; Увеличиваем счетчик цифр
    jmp conv_loop      ; Продолжаем цикл
    
check_range:
    cmp cx, 0          ; Если не было цифр - ошибка
    je conv_error
    cmp ax, 1          ; Проверяем нижнюю границу
    jl conv_error
    cmp ax, 255        ; Проверяем верхнюю границу
    jg conv_error
    clc                ; CF = 0 - успех
    jmp conv_end
    
conv_error:
    stc                ; CF = 1 - ошибка
    
conv_end:
    pop cx             
    pop bx             
    ret                
conv endp

; Процедура для разбора аргументов командной строки:
read_from_cmd proc
    push bx            
    push cx            
    push dx            
    push si            
    push di            
    
    mov cl, cmd_size   
    xor ch, ch         
    mov si, offset cmd_text ; Указываем на начало командной строки
    call skip_spaces
    
    
    ; Читаем путь к файлу
    mov di, offset path    
    call rewrite_word      
    is_empty_line path, path_empty_error
    
    ; Читаем первое число
    call skip_spaces
    mov di, offset number_text 
    call rewrite_word      
    is_empty_line number_text, first_num_empty_error
    push si
    mov si, offset number_text
    ; call print_binary
    call conv            ; Конвертируем в число
    pop si
    jc first_num_invalid_error ; Если ошибка - выход
    ; show_str first
    ; call print_binary
    ; mov ah, 0
    mov num1, ax         ; Сохраняем первое число
    
    ; Читаем второе число
    call skip_spaces
    mov di, offset number_text2 
    call rewrite_word      
    is_empty_line number_text2, second_num_empty_error
    push si
    mov si, offset number_text2
    mov ax, 0
    ; show_str second
    ; call print_binary
    call conv            ; Конвертируем в число
    pop si
    jc second_num_invalid_error ; Если ошибка - выход
    mov ah, 0
    mov num2, ax         ; Сохраняем второе число
    ; call print_binary
    
    ; Проверяем, нет ли лишних аргументов
    call skip_spaces
    ; cmp byte ptr [si], endl_char
    ; jne extra_args_error
    
    ; Все проверки пройдены успешно
    jmp cmd_is_good
    
no_args_error:
    show_str no_args_message
    jmp cmd_error_exit
    
path_empty_error:
    show_str path_empty_message
    jmp cmd_error_exit
    
first_num_empty_error:
    show_str first_num_empty_message
    jmp cmd_error_exit
    
first_num_invalid_error:
    show_str first_num_invalid_message
    jmp cmd_error_exit
    
second_num_empty_error:
    show_str second_num_empty_message
    jmp cmd_error_exit
    
second_num_invalid_error:
    show_str second_num_invalid_message
    jmp cmd_error_exit
    
extra_args_error:
    show_str extra_args_message
    jmp cmd_error_exit
    
cmd_is_good:
    Выводим результаты
    show_str path
    
    mov ax, num1
    call print_result
    
    mov ax, num2
    call print_result
    
    mov dl, return_char
    mov ah, 2h
    int 21h
    mov dl, new_line_char
    mov ah, 2h
    int 21h
    
    mov ax, 0              ; Устанавливаем флаг успеха
    jmp endproc            
    
cmd_error_exit:
    mov ax, 1              ; Устанавливаем флаг ошибки
    
endproc:
    pop di             
    pop si             
    pop dx             
    pop cx             
    pop bx             
    cmp ax, 0          ; Проверяем флаг ошибки
    jne end_in_read_cmd       ; Если ошибка, завершаем программу
    ret                
end_in_read_cmd:
    exit_app
read_from_cmd endp

; Процедура для извлечения слова из строки:
rewrite_word proc
    push ax             
    push cx            
    push di            
loop_parse_word:
    mov al, ds:[si]       ; Загружаем текущий символ
    cmp al, space_char    ; Проверяем на пробел
    je is_stopped_char    ; Если пробел, конец слова
    cmp al, new_line_char ; Проверяем на символ новой строки
    je is_stopped_char    
    cmp al, tabulation    ; Проверяем на табуляцию
    je is_stopped_char   
    cmp al, return_char   ; Проверяем на возврат каретки
    je is_stopped_char  
    cmp al, endl_char     ; Проверяем на конец строки
    je is_stopped_char 
    cmp al, '$'     ; Проверяем на конец строки
    je is_stopped_char 
    mov es:[di], al       ; Копируем символ в буфер
    inc di                ; Переходим к следующей позиции в буфере
    inc si                ; Переходим к следующему символу
    loop loop_parse_word  ; Повторяем цикл
is_stopped_char:
    mov al, endl_char     ; Добавляем нуль-терминатор
    mov es:[di], al       
    inc di                ; Переходим к следующей позиции
    ; mov al, '$'           
    ; mov es:[di], al 
    inc si                ; Пропускаем разделитель
    pop di             
    pop cx            
    pop ax           
    ret             
rewrite_word endp

; ==============================================
; ПРОЦЕДУРА ОТКРЫТИЯ ФАЙЛА
; ==============================================
open_file proc     
    mov ah, 3Dh             ; Функция DOS 3Dh - открытие файла
    mov al, 00h             ; Режим открытия (00h - только чтение)
    mov dx, offset path ; Указатель на имя файла
    int 21h                 ; Вызов прерывания DOS
    jc error_open_file      ; Если CF=1 - произошла ошибка
    
    mov bx, ax              ; Сохраняем дескриптор файла в BX
    mov file_desc, ax       ;; Сохраняем дескриптор в file_desc
    show_str opened        ; Выводим сообщение об успешном открытии
    
    ret
    
error_open_file:
    ; Обработка ошибки открытия файла
    show_str not_found_file
    exit_app
    
endp open_file

read_file proc
    push ax
    push bx
    push cx
    push dx
    push si
    push di
    
    ; 1. Инициализация
    mov bx, file_desc       ; BX = дескриптор файла
    mov cx, num2           ; CX = K (номер нужной строки)
    dec cx                 ; Пропускаем K-1 строк (если K=1, CX=0 - ничего не пропускаем)
    
skip_lines:
    jcxz read_target_line  ; Если CX=0, переходим к чтению нужной строки
    
read_line:
    ; 2. Чтение символа из файла
    mov ah, 3Fh            ; Функция DOS 3Fh - чтение из файла
    mov dx, offset symbol  ; DX указывает на буфер для символа

    push cx
    mov cx, 1              ; Читаем 1 символ
    int 21h
    pop cx

    jc error_reading       ; Если ошибка (CF=1)
    
    cmp ax, 0              ; AX = количество прочитанных байт
    je file_too_short      ; Если 0 - конец файла
    
    ; 3. Проверка символа
    mov al, symbol         ; AL = прочитанный символ
    cmp al, new_line_char    
    je check_lf            ; Да - проверяем следующий символ
    cmp al, return_char  
    je line_end            ; Неожиданный LF (без CR)
    jmp read_line          ; Продолжаем читать символы
    
check_lf:
    ; 4. После LF должен быть CR
    mov ah, 3Fh            ; Читаем следующий символ
    mov dx, offset symbol

    push cx
    mov cx, 1
    int 21h
    pop cx

    jc error_reading
    
    cmp ax, 0              ; Конец файла после CR?
    je line_end            ; Да - считаем это концом строки
    
    mov al, symbol
    cmp al, return_char 
    je line_end            ; Да - корректный конец строки
    
    ; 5. Некорректный формат (CR без LF)
    jmp read_line          ; Пропускаем и продолжаем
    
line_end:
    ; 6. Найден конец строки (CR+LF или неожиданный конец файла)
    loop skip_lines        ; CX=CX-1, если CX≠0 - продолжаем
    
read_target_line:
    ; 7. Чтение нужной строки в буфер
    mov di, offset buffer  ; DI указывает на буфер
    mov cx, max_size       ; Максимальная длина имени
    
read_char:
    ; 8. Чтение символа K-й строки
    mov ah, 3Fh
    mov dx, offset symbol

    push cx                ; Сохраняем счётчик
    mov cx, 1
    int 21h
    pop cx                 ; Восстанавливаем счётчик

    jc error_reading
    
    cmp ax, 0              ; Конец файла?
    je end_reading
    
    ; 9. Проверка символа
    mov al, symbol
    cmp al, new_line_char    
    je end_reading
    cmp al, return_char  
    je end_reading
    cmp al, endl_char      
    je end_reading
    
    ; 10. Сохранение символа в буфере
    mov [di], al
    inc di
    loop read_char         ; Пока не заполним буфер
    
end_reading:
    ; 11. Доавление 0 и $ в конец
    ; mov byte ptr [di], endl_char
    mov [di], 0
    ; inc di
    ; mov [di], '$'
    jmp read_success
    
error_reading:
    show_str read_error_msg
    exit_app
    
file_too_short:
    show_str eof_reached_msg
    exit_app
    
read_success:
    pop di
    pop si
    pop dx
    pop cx
    pop bx
    pop ax
    ret
endp read_file

close_file proc
    mov ah, 3Eh             ; Функция DOS 3Eh - закрытие файла
     mov bx, file_desc      ; Дескриптор файла
    int 21h                 
    jc close_error         ; Ошибка закрытия

    show_str closed        ; Выводим сообщение о закрытии файла
    ret

close_error:
    show_str error_closing_file_message
    exit_app
close_file endp 

; Процедура для запуска программы N раз без параметров
; Новая процедура для запуска программы
run_program_N_ras proc
    push ax
    push bx
    push cx
    push dx
    push si
    push di
    push es
    
    mov cx, num1           ; Количество запусков
    
    push cx
    
    ; mov ax, cs       ; ES = сегмент программы (CS)
    ; mov es, ax
    ; mov ax, @data
    ; mov ds, ax
    mov ax, @data
    mov es, ax
    mov ds, ax

    mov ax, 4800h 
    mov bx, 0FFFFh
    int 21h

    mov ax, 4A00h 
    mov bx, 0FFFFh
    int 21h
    ; mov bx, (csize + dsize + 256 + 15) / 16
    ; mov bx, ((csize/16) + 17) + ((dsize/16) + 17) + 1 ; Расчет нового размера

    ; Запуск программы
run_loop:
    mov ax, 4B00h          ; Функция EXEC
    mov dx, offset buffer  ; DS:DX = имя программы (ASCIIZ)
    int 21h
    jc exec_failed
    
    show_str exec_success
    
    pop cx
    loop run_loop
    jmp run_success
    
exec_failed:
    ; Выводим код ошибки (в AX)
    mov dx, offset exec_error
    push ax
    mov ah, 09h
    int 21h
    pop ax
    
    ; Выводим сам код ошибки
    mov dx, ax
    call print_result
    
    pop cx
    
run_success:
    pop es
    pop di
    pop si
    pop dx
    pop cx
    pop bx
    pop ax
    ret

run_program_N_ras endp

start_another_program proc
    ; Освобождаем память для запуска программы
    mov ax, 4A00h           ; Функция DOS 4Ah - изменить размер блока памяти
    mov bx, ((csize/16) + 17) + ((dsize/16) + 17) + 1 ; Расчет нового размера
    int 21h
    
    ; Информируем пользователя
    show_str exec_msg      ; Сообщение о запуске программы
    show_str prog_closed_msg ; Подсказка нажать любую клавишу
    
    ; Ожидание нажатия клавиши
    mov ax, 0100h           ; Функция DOS 01h - ввод символа с ожиданием
    int 21h
    
    ; Подготовка к запуску программы
    mov ax, @data  
    mov es, ax              ; Устанавливаем ES на сегмент данных
    
    ; Запуск программы
    mov ax, 4B00h           ; Функция DOS 4Bh - запуск программы
    lea dx, buffer    ; Имя программы для запуска
    lea bx, EPB             ; Блок параметров среды (EPB)
    int 21h
    
    ; Проверка на ошибку
    jb error_start_program  ; Если CF=1 - произошла ошибка
    exit_app
    
error_start_program:
    ; Обработка ошибки запуска
    show_str prog_start_err_msg
    ret
endp start_another_program 

start:
    ; Инициализация сегментных регистров
    mov ax, @data
    mov es, ax

    ; mov ax, 4B00h
    ; mov dx, offset text  ; Укажите имя файла вручную
    ; int 21h

    ; mov bx, 0FFFFh    ; Запрос нереально большого блока
    ; mov ah, 48h       ; Функция выделения памяти
    ; int 21h
    ; В BX будет максимальный доступный размер (в параграфах)

    call read_cmd              
    mov ds, ax            ; Устанавливаем ds на сегмент данных

    ; mov si, offset goodbye
    ; call show_string
    ; show_str goodbye
    ; show_str cmd_text
    ; push si
    ; mov si, offset cmd_text
    ; call print_char_with_code
    ; pop  si
    call read_from_cmd    ; Разбираем аргументы командной строки

    call open_file
    call read_file          ; Читаем содержимое файла
    call close_file         ; Закрываем файл


    call start_another_program
    call run_program_N_ras
    show_str path
    
    
end_main:
    exit_app              ; Завершаем программу
last: db ?
; Определение размера кода программы
csize = $ - start
end start                ; Конец программы
