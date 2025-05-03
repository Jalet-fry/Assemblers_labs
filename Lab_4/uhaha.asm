.model small
.stack 400h        ; Увеличиваем стек (на всякий случай)

.data
    program_name db "LAB_3.EXE", 0  ; Имя файла с нулём на конце
    error_msg db "Error! AX=$"

.code
start:
    ; --- Инициализация сегментов ---
    mov ax, @data
    mov ds, ax     ; DS = сегмент данных
    mov es, ax     ; ES = сегмент данных (если не используется для EPB)

    ; --- Проверка доступной памяти ---
    mov bx, 0FFFFh ; Запросить максимальный размер
    mov ah, 48h
    int 21h
    ; BX = доступный размер в параграфах

    ; --- Освобождение памяти ---
    mov ax, cs
    mov es, ax     ; ES = CS (сегмент программы)
    mov bx, 128    ; Оставить 2 КБ (128 параграфов)
    mov ah, 4Ah
    int 21h
    jc memory_error

    ; --- Запуск программы ---
    mov ax, 4B00h
    mov dx, offset program_name  ; DS:DX = имя файла
    xor bx, bx     ; ES:BX = 0 (нет параметров)
    int 21h
    jc exec_error

    ; --- Успешный выход ---
    mov ax, 4C00h
    int 21h

memory_error:
    ; Вывод ошибки (AX = код)
    mov dx, offset error_msg
    mov ah, 09h
    int 21h
    mov ax, 4C01h
    int 21h

exec_error:
    ; Вывод ошибки (AX = код)
    mov dx, offset error_msg
    mov ah, 09h
    int 21h
    mov ax, 4C02h
    int 21h

end start