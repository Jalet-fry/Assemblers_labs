.model small       ; Модель памяти small (один сегмент кода и один сегмент данных)
.stack 100h        ; Определяем размер стека (256 байт)

.data 
    exec_msg db 13, 10, "Trying execute program 'LAB_3.exe'$" ; Сообщение о запуске программы
    prog_start_err_msg db 13, 10, "Program start error$"      ; Сообщение об ошибке запуска
    prog_closed_msg db 13, 10, "Press any key to see result$" ; Сообщение-приглашение
    not_found_file db 10, 13, "File not found!$"              ; Сообщение об отсутствии файла
    prog_param_msg db 10, 13, "Program parameters: $"         ; Заголовок для параметров
    error_number_parameters db 13, 10, "Invalid number of parameters$" ; Ошибка параметров
    opened db 13, 10, "File has been opened$"                 ; Сообщение об открытии файла
    closed db 13, 10, "File has been closed$"                 ; Сообщение о закрытии файла
    
    program_name db "LAB_3.exe", 0                    ; Имя запускаемой программы с нулевым окончанием
    file_parameters db 128 dup("$")                   ; Буфер для имени файла из параметров
    buffer_file db 1                                  ; Буфер для чтения файла (1 байт)
    counter db 1                                      ; Счетчик прочитанных байт
    buffer db 128 dup("$")                            ; Буфер для командной строки
    parameters db 128 dup("$")                        ; Буфер для параметров программы
    endl db 10, 13, "$"                              ; Символы перевода строки и возврата каретки
    
    ; Структура EPB (Environment Parameter Block) для запуска программы
    EPB dw 0                                         ; Сегмент среды (0 - использовать текущую)
    cmd_off dw offset parameters                     ; Смещение командной строки
    cmd_seg dw ?                                     ; Сегмент командной строки
    fcb1 dd ?                                        ; FCB (File Control Block) 1
    fcb2 dd ?                                        ; FCB (File Control Block) 2
    EPB_len dw $ - EPB                               ; Длина EPB
    
    dsize = $ - exec_msg                             ; Размер сегмента данных в байтах

.code

print_str macro str
    mov ax, 0900h            ; Функция DOS 09h - вывод строки
    lea dx, str              ; Загружаем адрес строки в DX
    int 21h                  ; Вызываем прерывание DOS
endm print_str

start:
    mov ax, @data            ; Загружаем адрес сегмента данных
    mov ds, ax               ; Устанавливаем DS на сегмент данных
    mov cmd_seg, ax          ; Сохраняем сегмент данных для EPB
    
    call command_line        ; Читаем командную строку
    call copy_parameters     ; Извлекаем параметры из командной строки
    
    ; Проверяем, есть ли параметры (первый символ не '$')
    cmp file_parameters[0], 24h 
    je error                 ; Если нет параметров - ошибка
    
    ; Выводим информацию о параметрах
    print_str file_parameters ; Показываем имя файла из параметров
    print_str endl           ; Переводим строку
    
    ; Работа с файлом
    call open_file           ; Открываем указанный файл
    print_str prog_param_msg ; Выводим заголовок
    print_str parameters[1]  ; Показываем параметры из файла
    print_str endl           ; Переводим строку
    
    ; Запуск внешней программы
    call start_another_program ; Запускаем LAB_3.exe
    jmp exit                  ; Выходим после запуска
    
error:
    ; Обработка ошибки - неверное количество параметров
    print_str error_number_parameters

exit:      
    ; Корректное завершение программы
    mov ax, 4C00h            ; Функция DOS 4Ch - завершение программы
    int 21h                 ; Вызов прерывания DOS

; ==============================================
; ПРОЦЕДУРА КОПИРОВАНИЯ ПАРАМЕТРОВ ИЗ КОМАНДНОЙ СТРОКИ
; ==============================================
; Копирует первый параметр из командной строки в file_parameters
copy_parameters proc
    mov si, 2               ; Пропускаем первые 2 байта в буфере (длина и пробел)
    xor di, di              ; Обнуляем индекс для file_parameters
    mov file_parameters[1], 0 ; Инициализируем второй байт как 0
    
; Основной цикл проверки символов
iter_check:    
    cmp buffer[si], 20h     ; Пропускаем пробелы (20h)
    je next
    cmp buffer[si], 09h     ; Пропускаем табуляции (09h)
    je next
    cmp buffer[si], 24h     ; Проверяем конец строки (24h - '$')
    je exit_copy_parameters
    cmp buffer[si], 0Dh     ; Проверяем конец строки (0Dh - CR)
    je exit_copy_parameters
    jmp iter_copy_params    ; Если не спецсимвол - копируем
    
; Обработка пробелов/табуляции
next: 
    cmp di, 0               ; Если di=0, значит еще не начали копировать
    jne exit_copy_parameters ; Если уже копировали - выходим
    inc si                  ; Пропускаем пробел/табуляцию
    jmp iter_check          ; Проверяем следующий символ

; Копирование символов параметра
iter_copy_params:
    mov dl, buffer[si]      ; Читаем символ из буфера командной строки
    mov file_parameters[di], dl ; Записываем в буфер параметров файла
    inc di                  ; Увеличиваем индекс приемника
    inc si                  ; Увеличиваем индекс источника
    jmp iter_check          ; Проверяем следующий символ
    
; Завершение процедуры
exit_copy_parameters:          
    inc di
    mov file_parameters[di], 0 ; Добавляем нулевой символ в конец строки
    ret
endp copy_parameters

; ==============================================
; ПРОЦЕДУРА ОТКРЫТИЯ ФАЙЛА
; ==============================================
open_file proc     
    mov ax, 3D00h           ; Функция DOS 3Dh - открытие файла (режим чтения)
    mov dx, offset file_parameters ; Указатель на имя файла
    int 21h                 ; Вызов прерывания DOS
    jc error_open_file      ; Если CF=1 - произошла ошибка
    
    mov bx, ax              ; Сохраняем дескриптор файла в BX
    print_str opened        ; Выводим сообщение об успешном открытии
    
    ; Чтение и закрытие файла
    call read_file          ; Читаем содержимое файла
    call close_file         ; Закрываем файл
    jmp ok                  ; Выходим
    
error_open_file:
    ; Обработка ошибки открытия файла
    print_str not_found_file
    jmp exit                ; Завершаем программу
    
ok:
    ret
endp open_file

; ==============================================
; ПРОЦЕДУРА ЧТЕНИЯ ФАЙЛА
; ==============================================
read_file proc
    mov si, 1               ; Индекс для записи в буфер parameters
    mov counter, 1          ; Инициализируем счетчик байт (начинаем с 1)
    mov parameters[si], 20h ; Добавляем пробел в начало буфера
    inc si                  ; Увеличиваем индекс
    
; Основной цикл чтения файла
reading:
    mov ax, 3F00h           ; Функция DOS 3Fh - чтение из файла
    mov cx, 1               ; Читаем по 1 байту
    mov dx, offset buffer_file ; Буфер для чтения
    int 21h                 ; Вызов прерывания DOS
    
    cmp ax, 0               ; Проверяем, достигнут ли конец файла
    je reading_end          ; Если ax=0 - конец файла
    
    mov al, buffer_file     ; Получаем прочитанный байт
    cmp al, 0Dh             ; Пропускаем символ возврата каретки
    je next_arg
    cmp al, 0Ah             ; Пропускаем символ новой строки
    je reading
    
    ; Сохранение прочитанного символа
    mov parameters[si], al  ; Записываем символ в буфер параметров
    inc si                  ; Увеличиваем индекс
    inc counter             ; Увеличиваем счетчик байт
    jmp reading             ; Читаем следующий байт
    
; Обработка перехода на новый аргумент
next_arg:
    mov parameters[si], ' ' ; Добавляем пробел между аргументами
    inc si   
    inc counter
    jmp reading             ; Продолжаем чтение
    
; Завершение чтения файла
reading_end:    
    mov dl, counter         ; Сохраняем общее количество прочитанных байт
    mov parameters[0], dl   ; Записываем длину в первый байт буфера
    ret
endp read_file

; ==============================================
; ПРОЦЕДУРА ЗАКРЫТИЯ ФАЙЛА
; ==============================================
close_file proc
    mov ax, 3E00h           ; Функция DOS 3Eh - закрытие файла
    int 21h                 ; BX уже содержит дескриптор файла
    print_str closed        ; Выводим сообщение о закрытии файла
    ret
endp close_file

; ==============================================
; ПРОЦЕДУРА ЧТЕНИЯ КОМАНДНОЙ СТРОКИ
; ==============================================
command_line proc
    xor cx, cx              ; Обнуляем CX
    xor di, di              ; Обнуляем DI (индекс для буфера)
    mov si, 80h             ; Адрес длины командной строки в PSP
    
; Цикл чтения командной строки
command_line_input:
    mov al, es:[si]         ; Читаем символ из командной строки (сегмент ES)
    inc si                  ; Увеличиваем указатель
    cmp al, 0               ; Проверяем конец строки
    je command_line_end
    mov buffer[di], al      ; Сохраняем символ в буфере
    inc di                  ; Увеличиваем индекс буфера
    jmp command_line_input  ; Читаем следующий символ

; Завершение процедуры
command_line_end:
    ret
endp command_line

; ==============================================
; ПРОЦЕДУРА ЗАПУСКА ВНЕШНЕЙ ПРОГРАММЫ
; ==============================================
start_another_program proc
    ; Освобождаем память для запуска программы
    mov ax, 4A00h           ; Функция DOS 4Ah - изменить размер блока памяти
    mov bx, ((csize/16) + 17) + ((dsize/16) + 17) + 1 ; Расчет нового размера
    int 21h
    
    ; Информируем пользователя
    print_str exec_msg      ; Сообщение о запуске программы
    print_str prog_closed_msg ; Подсказка нажать любую клавишу
    
    ; Ожидание нажатия клавиши
    mov ax, 0100h           ; Функция DOS 01h - ввод символа с ожиданием
    int 21h
    
    ; Подготовка к запуску программы
    mov ax, @data  
    mov es, ax              ; Устанавливаем ES на сегмент данных
    
    ; Запуск программы
    mov ax, 4B00h           ; Функция DOS 4Bh - запуск программы
    lea dx, program_name    ; Имя программы для запуска
    lea bx, EPB             ; Блок параметров среды (EPB)
    int 21h
    
    ; Проверка на ошибку
    jb error_start_program  ; Если CF=1 - произошла ошибка
    jmp exit                ; Выход после успешного запуска
    
error_start_program:
    ; Обработка ошибки запуска
    print_str prog_start_err_msg
    ret
endp start_another_program 

; Определение размера кода программы
csize = $ - start
end start