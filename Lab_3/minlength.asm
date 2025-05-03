.model small            
.stack 100h            
.386                   ; Разрешаем использование инструкций процессора 80386

.data                  

bad_params_message db "Bad cmd arguments", '$'         
bad_source_file_message db "Cannot open file", '$'     
file_not_found_message db "File not found", '$'        
error_closing_file_message db "Cannot close file", '$'  
error_read_file_text_message db "Error reading from file", '$' 
file_is_empty_message db "File is empty", '$'           
result_message db "Number of lines with a length less than specified : ", '$' 


b_num_10 db 10                      ; Число 10 для конвертации (десятичная система)
space_char equ 32                   ; ASCII-код пробела
new_line_char equ 13                ; ASCII-код символа новой строки (CR)
return_char equ 10                  ; ASCII-код возврата каретки (LF)
tabulation equ 9                    ; ASCII-код табуляции
endl_char equ 0                     ; ASCII-код конца строки (нуль-терминатор)
symbol  db ?                        ; Буфер для хранения текущего символа из файла
flag_not_empty dw 0                 ; Флаг: 0 - файл пуст, 1 - файл не пуст


max_size equ 126                    
cmd_size db ?                       ; Размер командной строки (количество символов)
cmd_text db max_size + 2 dup(0)     ; Буфер для хранения командной строки 
path db max_size + 2 dup(0)         ; Буфер для хранения пути к файлу
number_text db max_size + 2 dup(0)  ; Буфер для хранения числа (максимальная длина)

num_10 db 10                        ; Еще одна константа для деления на 10

; Временные переменные:
temp_length dw 0                    ; Временная переменная для хранения длины строки
file_desc dw 0                      ; Дескриптор файла (идентификатор)
max_length dw 0                     ; Максимальная длина строки (из аргументов)
lines_counter dw 0                  ; Счетчик строк, удовлетворяющих условию
buffer db max_size + 2 dup(0)       ; Буфер для чтения данных из файла

.code                  


exit_app macro
   mov ax, 4C00h      ; Функция DOS 4Ch - завершение программы
   int 21h            
endm

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

; Макрос для проверки, пуста ли строка:
is_empty_line macro text_line, marker  
    push si            
    mov si, offset text_line ; Указываем адрес строки
    call strlen        
    pop si             
    cmp ax, 0          
    je marker          ; Если строка пуста, переходим по метке marker которую передали(да-да, так тоже можно)
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
    jmp start_calculation ; Повторяем цикл(как while)
end_calculation:
    pop si             
    pop bx             
    ret                
endp

; Макрос для чтения командной строки:
read_cmd proc
    xor ch, ch         ; Обнуляем ch (для использования cx как 16-битного счетчика)
    mov cl, ds:[80h]   
    mov cmd_size, cl   ; Сохраняем длину в переменную cmd_size
    mov si, 81h        ; Указываем на начало командной строки в PSP
    mov di, offset cmd_text 
    rep movsb          ; Копируем командную строку из si в di cl раз в cmd_text
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

; Процедура для конвертации строки в число:
conv proc
    pusha              ; Сохраняем все регистры общего назначения
    push di            
    push si            
    mov di, offset number_text ; Указываем на строку с числом
    mov si, offset number_text ; Копируем адрес в si
    xor cx, cx         ; Обнуляем cx (счетчик длины строки)
    call strlen        
    mov cx, ax         ; Сохраняем длину строки в cx
    xor ax, ax         ; Обнуляем ax (здесь будет результат)
    mov si, 10         ; Загружаем 10 для умножения
    xor bh, bh         ; Обнуляем bh (для использования bl как 8-битного регистра)
m1:
    mul si             ; Умножаем ax на 10 (для сдвига разрядов)
    jc bad_cmd         ; Если было переполнение, ошибка
    mov bl, [di]       ; Загружаем текущий символ
    cmp bl, 30h        ; Сравниваем с '0'
    jl bad_cmd         ; Если меньше, ошибка
    cmp bl, 39h        ; Сравниваем с '9'
    jg bad_cmd         ; Если больше, ошибка
    sub bl, 30h        ; Преобразуем символ в цифру
    add ax, bx         ; Добавляем цифру к результату
    inc di             ; Переходим к следующему символу
    loop m1            ; Повторяем цикл
    mov max_length, ax ; Сохраняем результат в max_length
    pop si             
    pop di             
    popa               
    ret                
endp

; Процедура для разбора аргументов командной строки:
read_from_cmd proc
    push bx            
    push cx            
    push dx            
    mov cl, cmd_size   
    xor ch, ch         
    mov si, offset cmd_text ; Указываем на начало командной строки, которую до этого считали
    mov di, offset buffer  ; Указываем на буфер
    call rewrite_word      ; Извлекаем первое слово (игнорируем его, сам .exe который)
next_word:
    mov di, offset path    ; Указываем на буфер для пути
    call rewrite_word      ; Извлекаем путь к файлу
    is_empty_line path, bad_cmd ; Проверяем, не пуст ли путь
    mov di, offset number_text ; Указываем на буфер для числа
    call rewrite_word      ; Извлекаем число
    call conv              ; Конвертируем строку в число
    pusha                 
    mov ax, max_length    ; Загружаем максимальную длину
    cmp ax, 8000h         ; Проверяем, не слишком ли большое число
    jae bad_cmd           ; Если слишком большое, ошибка
    popa                  
    mov di, offset buffer ; Указываем на буфер
    call rewrite_word     ; Извлекаем возможное лишнее слово
    is_empty_line buffer, cmd_is_good ; Проверяем, нет ли лишних аргументов
bad_cmd:
    show_str bad_params_message ; Выводим сообщение об ошибке
    mov ax, 1              ; Устанавливаем флаг ошибки
    jmp endproc            
cmd_is_good:
    mov ax, 0              ; Устанавливаем флаг успеха
endproc:
    pop dx                
    pop cx               
    pop bx              
    cmp ax, 0              ; Проверяем флаг ошибки
    jne end_main           ; Если ошибка, завершаем программу
    ret                 
endp

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
    mov es:[di], al       ; Копируем символ в буфер
    inc di                ; Переходим к следующей позиции в буфере
    inc si                ; Переходим к следующему символу
    loop loop_parse_word  ; Повторяем цикл
is_stopped_char:
    mov al, endl_char     ; Добавляем нуль-терминатор
    mov es:[di], al       ; Записываем его в буфер
    inc si                ; Пропускаем разделитель
    pop di            
    pop cx           
    pop ax          
    ret            
endp

; Процедура для открытия файла:
open_file proc
    push bx               
    push dx               
    mov ah, 3Dh           ; Функция DOS 3Dh - открытие файла
    mov al, 00h           ; Режим чтения
    mov dx, offset path   ; Указываем путь к файлу
    int 21h               
    jb bad_open           ; Если ошибка, переходим к обработке
    mov file_desc, ax     ; Сохраняем дескриптор файла
    mov ax, 0             ; Устанавливаем флаг успеха
    jmp end_open          
bad_open:
    show_str bad_source_file_message ; Выводим сообщение об ошибке
    cmp ax, 02h           ; Проверяем код ошибки (02h - файл не найден)
    jne error_found       ; Если не "файл не найден"(то есть файл найден), переходим дальше
    show_str file_not_found_message ; Выводим "Файл не найден"
error_found:
    mov ax, 1             ; Устанавливаем флаг ошибки
end_open:
    pop dx                
    pop bx                
    cmp ax, 0             ; Проверяем флаг ошибки
    jne end_main          ; Если ошибка, завершаем программу
    ret                   
endp

; Процедура для обработки файла:
file_handling proc
    pusha                 
    mov lines_counter, 0  ; Обнуляем счетчик строк
    mov si, 0             ; Обнуляем счетчик символов в строке
    mov flag_not_empty, 0 ; Обнуляем флаг "файл не пуст"
read_next_char:
    mov ah, 3Fh           ; Функция DOS 3Fh - чтение из файла
    mov bx, file_desc     ; Указываем дескриптор файла
    mov cx, 1             ; Читаем 1 символ
    lea dx, symbol        ; Указываем буфер для символа
    int 21h               
    jc read_error         ; Если ошибка, переходим к обработке
    cmp ax, 0             
    je end_of_file        ; Если достигнут конец файла, переходим к завершению
    mov flag_not_empty, 1 
    mov al, symbol        ; Загружаем символ в al
    cmp al, new_line_char ; Проверяем на символ CR
    je process_cr         ; Если да, обрабатываем конец строки
    cmp al, return_char   ; Проверяем на символ LF
    je process_lf         ; Если да, обрабатываем конец строки
    inc si                ; Увеличиваем счетчик символов в строке
    jmp read_next_char    ; Читаем следующий символ
process_cr:
    call process_line_end ; Обрабатываем конец строки
    jmp read_next_char    ; Читаем следующий символ
process_lf:
    call process_line_end ; Обрабатываем конец строки
    jmp read_next_char    ; Читаем следующий символ
end_of_file:
    cmp si, 0             ; Проверяем, была ли необработанная строка
    je check_empty_file   ; Если нет, проверяем, пуст ли файл
    call process_line_end ; Обрабатываем последнюю строку
check_empty_file:
    cmp flag_not_empty, 0 ; Проверяем, был ли файл пуст
    jne handling_done     ; Если нет, завершаем обработку
    show_str file_is_empty_message ; Выводим сообщение "Файл пуст"
handling_done:
    popa                  
    ret                   
read_error:
    show_str error_read_file_text_message ; Выводим сообщение об ошибке чтения
    popa                  
    ret                   
file_handling endp

; Процедура для обработки конца строки:
process_line_end proc
    cmp si, 0             
    je skip_increment     ; Если пуста, пропускаем инкремент
    cmp si, max_length    
    jge skip_increment    ; Если больше или равна, пропускаем инкремент
    inc lines_counter     
skip_increment:
    mov si, 0             ; Обнуляем счетчик символов в строке
    ret                   
process_line_end endp

; Процедура для закрытия файла:
close_file proc
    push bx               
    push cx               
    xor cx, cx            ; Обнуляем cx (флаг ошибки)
    mov ah, 3Eh           ; Функция DOS 3Eh - закрытие файла
    mov bx, file_desc     ; Указываем дескриптор файла
    int 21h               
    jnb good_close        ; Если нет ошибки, переходим к good_close
    show_str error_closing_file_message ; Выводим сообщение об ошибке
    inc cx                ; Устанавливаем флаг ошибки
good_close:
    mov ax, cx            ; Возвращаем флаг ошибки
    pop cx                
    pop bx               
    cmp ax, 0             ; Проверяем флаг ошибки
    jne end_main          ; Если ошибка, завершаем программу
    ret                   ; Возвращаемся из процедуры
endp

; Начало программы:
start:
    mov ax, @data         
    mov es, ax            
    call read_cmd              
    mov ds, ax            ; Устанавливаем ds на сегмент данных
    call read_from_cmd    ; Разбираем аргументы командной строки
    call open_file        
    call file_handling    
    call close_file      
    mov ah, 9h          
    mov dx, offset result_message 
    int 21h               
    mov ax, lines_counter ; Загружаем счетчик строк
    call print_result     ; Выводим число
    mov dl, return_char   ; Загружаем символ LF
    mov ah, 2h            
    int 21h              
    mov dl, new_line_char ; Загружаем символ CR
    mov ah, 2h          
    int 21h            
end_main:
    exit_app              ; Завершаем программу
end start                ; Конец программы