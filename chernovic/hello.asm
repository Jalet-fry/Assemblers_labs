.model small
.stack 100h

.data
    message db 'Hello, World!', '$'  ; Строка для вывода (завершается '$')

.code
print_new_line proc

    push ax        
    push dx        
    ; Вывод перевода строки (CR+LF)
    mov ah, 02h    ; Функция DOS для вывода символа
    mov dl, 13    ; Символ возврата каретки (CR)
    int 21h        
    mov dl, 10    ; Символ перевода строки (LF)
    int 21h        

    pop dx         
    pop ax         
    ret            
print_new_line endp
start:
    ; Инициализация сегмента данных
    mov ax, @data
    mov ds, ax

    ; Вывод строки на экран (функция 09h)
    mov ah, 09h
    mov dx, offset message
    int 21h

    call print_new_line
    ; Завершение программы
    mov ax, 4C00h
    int 21h
end start