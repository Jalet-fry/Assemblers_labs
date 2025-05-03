.model small
.stack 100h

.data
    smiley db '  ****  ', 13, 10,' *    * ', 13, 10,'*  <>  *', 13, 10,'*      *', 13, 10,' *    * ', 13, 10,'  ****  ', 13, 10, '$'

.code
start:
    ; Инициализация сегмента данных
    mov ax, @data
    mov ds, ax

    ; Выводим ASCII-арт
    mov ah, 09h
    mov dx, offset smiley
    int 21h

    ; Завершение программы
    mov ax, 4C00h
    int 21h
end start