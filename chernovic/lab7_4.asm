.model tiny
.stack 100h  
.code
org 100h

start:
jmp beginning

max_path_size       equ 124

buf                 db ?
exec_file_path      db max_path_size dup (0), 0
text_file_path      db max_path_size dup (0), 0
file_not_found      db "file not found", 0Ah, 0Dh, '$'
path_not_found      db "path not found", 0Ah, 0Dh, '$'
too_much_open_files db "too much open files", 0Ah, 0Dh, '$'
access_denied       db "access denied", 0Ah, 0Dh, '$'
unidentified_error  db "unidentified error", 0Ah, 0Dh, '$'
no_line             db "desired line is empty or does not exist", 0Ah, 0Dh, '$'
line_is_too_big     db "desired line is too big", 0Ah, 0Dh, '$'
couldnt_get_exec_file_name  db "couldn't get exec file name", 0Dh, 0Ah, '$'
error_message       db "wrong command line argument format", 0Dh, 0Ah, "correct format:", 0Dh, 0Ah, "number_of_repeats[1-255] number_of_lines[1-255] filename", 0Dh, 0Ah, '$'
couldnt_resize_memory       db "couldn't resize memory", 0Ah, 0Dh, '$'
failed_to_start     db "failed to launch file", 0Ah, 0Dh, '$'


parce_command_line proc; dx - number of repeats, ax - number of line, text_file_path contains program path
    push bx
    push cx
    xor ah, ah
    mov al, byte ptr ds:[80h]
    cmp al, 0
    je parce_command_line_error

    xor ch, ch
    mov cl, al
    mov di, 81h
    call get_number
    jc parce_command_line_error
    mov dx, bx
    call get_number
    jc parce_command_line_error
    mov ax, bx
    call store_file_name
    jc parce_command_line_error


    jmp parce_command_line_end
    parce_command_line_error:
    stc
    parce_command_line_end:
    pop cx
    pop bx
    ret
endp

store_file_name proc; 
    push ax
    push si
    mov al, ' '
    repe scasb
    cmp cx, 0
    je store_file_name_start_error
    dec di
    inc cx
    push di
    mov si, di
    mov di, offset text_file_path
    rep movsb
    jmp store_file_name_end
    store_file_name_start_error:
    push di
    store_file_name_error:
    stc
    store_file_name_end:
    pop di
    pop si
    pop ax
    ret
endp

get_number proc; di - string, cx - number of chars, bx - result
    push ax
    push dx
    push si
    
    xor bx, bx
    mov al, ' '
    repe scasb
    cmp cx, 0
    je get_number_error
    dec di
    mov si, di
    get_number_loop:
        xor ah, ah
        lodsb
        cmp al, ' '
        je get_number_post
        cmp al, '0'
        jb get_number_error
        cmp al, '9'
        ja get_number_error
        sub al, '0'; bx - result, al - to add
        mov dx, ax; dx - to add
        mov ax, bx; ax - result
        mov bx, dx
        push cx
        mov cx, 10
        mul cx
        pop cx
        add ax, bx; ax - new result
        mov bx, ax; bx - result
        cmp bx, 255
        ja get_number_error
        loop get_number_loop

    get_number_post:
    cmp bx, 0
    je get_number_error
    jmp get_number_end

    get_number_error:
    stc
    get_number_end:
    mov di, si
    pop si
    pop dx
    pop ax
    dec di
    inc cx
    ret
endp

get_line_from_file proc; cx - number of line, text_file_path - path to file, exec_file_path - result
    push ax
    push dx
    push cx
    push bx
    push si
    push di
    mov al, 1000010b
    mov ah, 3Dh
    mov dx, offset text_file_path
    int 21h
    jc get_line_from_file_open_error
    mov di, offset exec_file_path
    mov bx, ax
    mov si, cx
    dec si
    mov cx, 1
    mov ah, 3Fh
    mov dx, offset buf
    cmp si, 0
    je get_line_from_file_save_line
    

    get_line_from_file_find_line:
    mov ah, 3Fh
    int 21h
    cmp ax, 0
    je get_line_from_file_error_no_line
    cmp buf, 0Ah
    jne get_line_from_file_find_line
    dec si
    cmp si, 0
    je get_line_from_file_save_line
    jmp get_line_from_file_find_line
    
    get_line_from_file_save_line:
    mov ah, 3Fh
    int 21h
    cmp ax, 0
    je get_line_from_file_end_of_line
    cmp buf, 0Dh
    je get_line_from_file_end_of_line

    cmp di, max_path_size + offset exec_file_path
    jge get_line_from_file_error_too_big
    
    mov cl, buf
    mov [di], cl
    mov cx, 1
    inc di
    jmp get_line_from_file_save_line

    get_line_from_file_end_of_line:
    cmp di, offset exec_file_path
    je get_line_from_file_error_too_big
    jmp get_line_from_file_end





    get_line_from_file_open_error:
    cmp ax, 02h
    je get_line_from_file_error_1
    cmp ax, 03h
    je get_line_from_file_error_2
    cmp ax, 04h
    je get_line_from_file_error_3
    cmp ax, 05h
    je get_line_from_file_error_4
    get_line_from_file_error_1:
    mov dx, offset file_not_found
    jmp get_line_from_file_log_error
    get_line_from_file_error_2:
    mov dx, offset path_not_found
    jmp get_line_from_file_log_error
    get_line_from_file_error_3:
    mov dx, offset too_much_open_files
    jmp get_line_from_file_log_error
    get_line_from_file_error_4:
    mov dx, offset access_denied
    jmp get_line_from_file_log_error
    get_line_from_file_log_error:
    mov ah, 9h
    int 21h
    stc
    jmp get_line_from_file_end_after_close

    get_line_from_file_error_no_line:
    mov dx, offset no_line
    mov ah, 9h
    int 21h
    jmp get_line_from_file_error

    get_line_from_file_error_too_big:
    mov dx, offset line_is_too_big
    mov ah, 9h
    int 21h
    jmp get_line_from_file_error

    get_line_from_file_error:
    stc
    jmp get_line_from_file_end

    get_line_from_file_end:
    mov ah, 3Eh
    int 21h
    get_line_from_file_end_after_close:
    pop di
    pop si
    pop bx
    pop cx
    pop dx
    pop ax
    ret
endp

shrink_memory proc
    push ax
    push bx
    mov ax, cs
    mov es, ax
    mov bx, (length_of_program + 100h + 200h + 15) / 16 ; округляем вверх до параграфов
    mov ah, 4Ah
    int 21h
    jc shrink_error
    pop bx
    pop ax
    ret
shrink_error:
    stc
    pop bx
    pop ax
    ret
endp

beginning:
    call parce_command_line
    jc error_my
    jmp get_exec_file_name
error_my:
    mov dx, offset error_message
    mov ah, 9h
    int 21h
    jmp _end

get_exec_file_name:

    mov cx, ax
    call get_line_from_file
    jc get_exec_file_name_error
    ;push dx
    ;mov dx, offset exec_file_path
    ;mov ah, 9h
    ;int 21h
    ;pop dx
    jmp prep_for_start

get_exec_file_name_error:
    mov dx, offset couldnt_get_exec_file_name
    mov ah, 9h
    int 21h
    jmp _end


prep_for_start:
    call shrink_memory
    jc error1
    jmp init_EPB

    error1:
    mov dx, offset couldnt_resize_memory 
    mov ah, 9h
    int 21h
    jmp _end


    init_EPB:

    mov ax, cs
    mov word ptr EPB + 4, ax
    mov word ptr EPB + 8, ax
    mov word ptr EPB + 0Ch, ax

    
    mov ax, 04B00h
    mov cx, dx
    mov dx, offset exec_file_path
    mov bx, offset EPB
    startup_loop:
    int 21h
    jc error
    loop startup_loop

    jmp _end
error:
    mov dx, offset failed_to_start
    mov ah, 9h
    int 21h
    cmp ax, 02h
    je error_1
    cmp ax, 05h
    je error_2
    jmp error_3
error_1:
    mov dx, offset file_not_found
    jmp log_error
error_2:
    mov dx, offset access_denied
    jmp log_error
error_3:
    jmp _end
log_error:
    mov ah, 9h
    int 21h

_end:
    int 20h

EPB                 dw 0000
                    dw offset commandline, 0
                    dw 005Ch, 006Ch

commandline         db 124
command_text        db 125 dup (?)
command_buffer      db 122


length_of_program   equ $-start

end start