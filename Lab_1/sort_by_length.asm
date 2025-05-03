.model small
.stack 100h
.data

i dw 0h
String db 'Enter the string : $'
arr db 100h dup(0h)  ; массив для хранения введенной строки

error_message db 0Ah,0Dh,"Invalid input! Only English letters and single spaces allowed.",0Ah,0Dh,'$'

.code

print_string macro string  ; Макрос для вывода строки
    mov ah,09h
    mov dx,offset string
    int 21h
endm

Start:
    mov ax, @data  
    mov ds, ax
    
    mov ah, 00h     ; Очистка экрана
    mov al, 2h      ; Номер функции вывода
    int 10h
    
    mov ah, 09h
    Lea dx, String  ; Вывод приглашения на ввод строки
    int 21h 
    
    mov ah, 1h      ; Функция ввода символа
    mov bx, 0h      ; Начальный индекс массива

Input:                   ; Ввод символов в массив
    int 21h
    cmp al, 13       ; Проверка на нажатие Enter
    je ValidateInput  ; Если Enter, переходим к проверке
    
    cmp al, 32       ; Проверка на пробел
    je CheckSpace    
    cmp al, 'A'      ; Проверка на допустимые символы (A-Z, a-z)
    jl InvalidInput
    cmp al, 'Z'
    jle StoreChar
    cmp al, 'a'
    jl InvalidInput
    cmp al, 'z'
    jle StoreChar

InvalidInput:            ; Вывод ошибки при недопустимом вводе
    print_string error_message
    mov ax, 4c00h
    int 21h

CheckSpace:
    cmp bx, 0        ; Проверка, если пробел в начале строки
    je InvalidInput  ; Запрещено
    cmp arr[bx-1], 32 ; Запрещены двойные пробелы
    je InvalidInput

StoreChar:
    mov arr[bx], al  ; Запись символа в массив
    inc bx           ; Увеличение индекса
    jmp Input        ; Продолжение ввода

ValidateInput:
    mov arr[bx], 0h  ; Завершаем строку нулем
    mov i, bx        ; Сохраняем длину строки
    mov bx, 0h       ; Обнуляем индекс перед сортировкой

Sort:                ; Сортировка пузырьком по длине слов
    mov di, bx       ; Индекс минимального слова
    mov ax, bx
    add ax, 10h

Compare:
    mov si, ax
    mov cl, arr[di]
    cmp cl, arr[si]
    jae CompareEnd
    mov di, si      ; Если нашли меньшее слово, запоминаем индекс

CompareEnd:
    add ax, 10h
    cmp ax, i
    jle Compare

    mov si, 0h
Swap:
    mov cl, arr[bx+si]
    mov al, arr[di]
    mov arr[bx+si], al
    mov arr[di], cl
    inc si
    inc di
    cmp si, 10h
    jb Swap

    add bx, 10h
    cmp bx, i
    jb Sort

    mov ah, 02h       ; Установка курсора
    mov bh, 0h
    mov dh, 2h
    mov dl, 0h
    int 10h

    mov bx, 0h
    mov si, 0h
    mov ah, 2h        ; Функция вывода символа

Output:
    inc si
    mov dx, word ptr arr[bx+si]
    cmp dx, 0h
    jne Skip
    cmp bx, i
    je Exit
    mov si, 0h
    add bx, 10h
    mov dx, ' '

Skip:
    int 21h
    cmp bx, i
    jbe Output

Exit:
    mov ah, 4ch
    int 21h 

End Start
