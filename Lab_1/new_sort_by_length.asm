.model small;   
.stack 100h;    
.data
i dw 0h
String db ': $' 
Stg db 100h dup(0h);     Массив для строки   
.code   
Start:
Sort proc
mov ax, @data;  
mov ds, ax;
mov ah, 00h;     Очистка экрана
mov al, 2h; 
int 10h
mov ah, 09h
Lea dx, String
int 21h 
mov ah, 1h;  Ф-я ввода символа
mov si, 0h
mov bx, 0h
Input:   ;Ввод массива
int 21h
mov cx, si
mov Stg[bx], cl;     Длина слова
cmp al, 32;  Проверка на пробел
jne Skip1
mov si, 0h
add bx, 10h;     Начало следующего слова
jmp Input
Skip1:
inc si
mov Stg[bx+si], al;  Помещение символа в массив  
cmp al, 13
jne Input
mov Stg[bx+si], 0h;  Удаление Enter'а
mov i, bx;   Кол-во слов
mov bx, 0h
Sort1:   ;Выборочная сортировка
mov di, bx;  Индекс минимальной длины
mov ax, bx
add ax, 10h
Sort2:
mov si, ax
 
mov cl, Stg[di]
cmp cl, Stg[si]
jae Skip2
mov di, si;  Если меньше
Skip2: 
add ax, 10h
cmp ax, i
jbe Sort2
mov si, 0h
Sort3:
moV cl, Stg[bx+si]; Смена слов
mov al, Stg[di]
mov Stg[bx+si], al
mov Stg[di], cl
inc si
inc di
cmp si, 10h
jb Sort3
add bx, 10h
cmp bx, i
jb Sort1
mov ah, 02h; Ф-я установки позиции курсора:
mov bh, 0h;  № Страницы   
mov dh, 2h; № строки
mov dl, 0h; № столбца
int 10h
mov bx, 0h
mov si, 0h
mov ah, 2h;  Ф-я вывода символа
Output:  ;Вывод массива
inc si
mov dx, word ptr Stg[bx+si]
cmp dx, 0h
jne Skip3
cmp bx, i
je Exit
mov si, 0h
add bx, 10h
mov dx, ' ' 
Skip3:
int 21h
cmp bx, i
jbe Output
Exit:
mov ah, 4ch;
int 21h 
Sort endp
End Start
;.model small;   
;.stack 100h;    
;.data
;    i dw 0h
;    String db 'Enter the string : $' 
;    arr db 200 dup(0h)     ;array for string
;    error_message db 0Ah,0Dh,"Invalid input! Only English letters and single spaces allowed.",0Ah,0Dh,'$'
;.code   
;print_string macro string 
;    mov ah,09h
;    mov dx,offset string
;    int 21h
;endm
;Start:
;    mov ax, @data  
;    mov ds, ax
;    mov ah, 00h;         clear screen
;    mov al, 2h;          number of func output 
;    int 10h
;    mov ah, 09h
;    Lea dx, String
;    int 21h 
;    mov ah, 1h;          func input symbol
;    mov bx, 0h
;Input:                   ;input massiva
;    int 21h
;    mov cx, si
;    mov arr[bx], cl;     lenght word
;    cmp al, 'A'               ; If below 'A' -> invalid input
;    jl invalid_input
;    cmp al, 'Z'               ; Within 'A-Z'?
;    jg invalid_input
;    cmp al, 'a'               ; If below 'a' -> invalid input
;    jl invalid_input
;    cmp al, 'z'               ; Within 'a-z'?
;    jg invalid_input
;    cmp al, 32;          check space
;    jne AddToArray
;    cmp cl, 0h;	         if several spaces
;    je Input;            equals
;    mov si, 0h;
;    add bx, 10h;         start next word (line translation)
;    jmp Input
;AddToArray:
;    inc si
;    mov arr[bx+si], al;  set symbol in array 
;    cmp al, 13
;    jne Input
;    mov arr[bx+si], 0h   ;delete enter
;    mov i, bx            ;quantity words
;    mov bx, 0h
;invalid_input:
;    print_string error_message
;    mov ax, 4c00h
;    int 21h
;Sort:                    ;viborochnaya sort
;    mov di, bx           ;index of minimal lenght
;    mov ax, bx
;    add ax, 10h
;Compare:
;    mov si, ax 
;    mov cl, arr[di]
;    cmp cl, arr[si]
;    jae CompareEnd        ;jbe 
;    mov di, si            ;if less
;CompareEnd: 
;    add ax, 10h
;    cmp ax, i
;    jle Compare
;    mov si, 0h
;Swap:
;    mov cl, arr[bx+si]    ;swap words
;    mov al, arr[di]
;    mov arr[bx+si], al
;    mov arr[di], cl
;    inc si
;    inc di
;    cmp si, 10h
;    jb Swap
;    add bx, 10h
;    cmp bx, i
;    jb Sort
;    mov ah, 02h           ;func setting pos cursor
;    mov bh, 0h            ;num page 
;    mov dh, 2h            ;num line
;    mov dl, 0h            ;num column
;    int 10h
;    mov bx, 0h
;    mov si, 0h
;    mov ah, 2h            ;func output symbol
;Output:                   ;output array
;    inc si
;    mov dx, word ptr arr[bx+si]
;    cmp dx, 0h
;    jne Skip
;    cmp bx, i
;    je Exit
;    mov si, 0h
;    add bx, 10h
;    mov dx, ' ' 
;Skip:
;    int 21h
;    cmp bx, i
;    jbe Output
;Exit:
;    mov ah, 4ch;
;    int 21h 
;End Start