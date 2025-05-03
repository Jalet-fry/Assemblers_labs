.model small
.stack 100h

.data
    ; Messages
    usage_msg db "Usage: launcher.exe <N> <filename> <K>", 13, 10, '$'
    invalid_N_msg db "N must be between 1 and 255", 13, 10, '$'
    invalid_K_msg db "K must be between 1 and 255", 13, 10, '$'
    file_open_error db "Error opening file", 13, 10, '$'
    file_not_found db "File not found", 13, 10, '$'
    line_not_found db "Line K not found in file", 13, 10, '$'
    exec_error_msg db "Error executing program", 13, 10, '$'
    executing_msg db "Executing: ", '$'
    times_msg db " times", 13, 10, '$'
    newline db 13, 10, '$'
    
    ; Parameters
    N db 0                  ; Number of executions (1-255)
    K db 0                  ; Line number to read (1-255)
    program_name db 128 dup(0) ; Buffer for program name
    filename db 128 dup(0)  ; Input filename buffer
    
    ; File handling
    file_handle dw ?
    line_counter db 1
    char_buffer db ?
    
    ; Execution block
    EPB dw 0                ; Environment segment
        dw offset command_tail, 0 ; Command tail offset/segment
        dw 5Ch, 0, 6Ch, 0   ; FCB pointers
    EPB_len = $ - EPB
    
    command_tail db 0       ; Command tail (empty)
    
.code

; Macro to print a string
print macro msg
    push ax
    push dx
    mov ah, 09h
    lea dx, msg
    int 21h
    pop dx
    pop ax
endm

; Convert ASCII string to number (0-255)
; Input: SI = string pointer
; Output: AL = number (0-255), CF=1 if error
atoi proc
    push bx
    push cx
    push si
    
    xor ax, ax
    xor bx, bx
    mov cl, 10
    
atoi_loop:
    mov bl, [si]
    cmp bl, 0
    je atoi_done
    cmp bl, '0'
    jb atoi_error
    cmp bl, '9'
    ja atoi_error
    
    sub bl, '0'
    mul cl
    jc atoi_error
    add al, bl
    jc atoi_error
    inc si
    jmp atoi_loop
    
atoi_error:
    stc
    jmp atoi_exit
    
atoi_done:
    clc
    
atoi_exit:
    pop si
    pop cx
    pop bx
    ret
atoi endp

; Read command line parameters
parse_cmd_line proc
    push ax
    push bx
    push cx
    push si
    push di
    
    ; Skip first two bytes (length and space)
    mov si, 82h
    
    ; Parse N
    mov di, offset filename ; Temporary storage
    call skip_whitespace
    call read_word
    mov byte ptr [di], 0    ; Null-terminate
    mov di, offset filename
    call atoi
    jc invalid_N
    cmp al, 1
    jb invalid_N
    cmp al, 255
    ja invalid_N
    mov N, al
    
    ; Parse filename
    mov di, offset filename
    call skip_whitespace
    call read_word
    mov byte ptr [di], 0    ; Null-terminate
    cmp filename, 0         ; Check if empty
    je invalid_params
    
    ; Parse K
    mov di, offset filename ; Temporary storage
    call skip_whitespace
    call read_word
    mov byte ptr [di], 0    ; Null-terminate
    mov di, offset filename
    call atoi
    jc invalid_K
    cmp al, 1
    jb invalid_K
    cmp al, 255
    ja invalid_K
    mov K, al
    
    jmp parse_success
    
invalid_N:
    print invalid_N_msg
    mov ax, 1
    jmp parse_exit
    
invalid_K:
    print invalid_K_msg
    mov ax, 1
    jmp parse_exit
    
invalid_params:
    print usage_msg
    mov ax, 1
    jmp parse_exit
    
parse_success:
    xor ax, ax
    
parse_exit:
    pop di
    pop si
    pop cx
    pop bx
    pop ax
    ret
parse_cmd_line endp

; Skip whitespace characters
skip_whitespace proc
skip_loop:
    mov al, es:[si]
    cmp al, ' '
    je skip_next
    cmp al, 9       ; Tab
    je skip_next
    cmp al, 13      ; CR
    je skip_next
    cmp al, 10      ; LF
    je skip_next
    ret
    
skip_next:
    inc si
    jmp skip_loop
skip_whitespace endp

; Read a word until whitespace
read_word proc
read_loop:
    mov al, es:[si]
    cmp al, ' '
    je read_done
    cmp al, 9       ; Tab
    je read_done
    cmp al, 13      ; CR
    je read_done
    cmp al, 10      ; LF
    je read_done
    cmp al, 0       ; Null terminator
    je read_done
    
    mov [di], al
    inc di
    inc si
    jmp read_loop
    
read_done:
    ret
read_word endp

; Open file and read K-th line
read_program_name proc
    push ax
    push bx
    push cx
    push dx
    push si
    push di
    
    ; Open file
    mov ah, 3Dh
    mov al, 0       ; Read-only
    mov dx, offset filename
    int 21h
    jnc open_ok
    
    ; Handle open error
    cmp ax, 2       ; File not found?
    jne generic_error
    print file_not_found
    jmp read_error
    
generic_error:
    print file_open_error
    jmp read_error
    
open_ok:
    mov file_handle, ax
    mov line_counter, 1
    
    ; Initialize program_name buffer
    mov di, offset program_name
    mov cx, 128
    xor al, al
    rep stosb
    mov di, offset program_name
    
read_line_loop:
    ; Check if we've reached the desired line
    mov al, line_counter
    cmp al, K
    je found_line
    
    ; Skip to next line
skip_line:
    mov ah, 3Fh
    mov bx, file_handle
    mov cx, 1
    mov dx, offset char_buffer
    int 21h
    jc read_file_error
    
    cmp ax, 0       ; EOF?
    je line_not_found_error
    
    mov al, char_buffer
    cmp al, 13      ; CR
    je got_cr
    cmp al, 10      ; LF
    je got_lf
    jmp skip_line
    
got_cr:
    ; Check for LF next
    mov ah, 3Fh
    mov bx, file_handle
    mov cx, 1
    mov dx, offset char_buffer
    int 21h
    jc read_file_error
    
    cmp ax, 0       ; EOF?
    je line_increment
    
    mov al, char_buffer
    cmp al, 10      ; LF
    jne line_increment
    
got_lf:
line_increment:
    inc line_counter
    jmp read_line_loop
    
found_line:
    ; Read the program name
read_name:
    mov ah, 3Fh
    mov bx, file_handle
    mov cx, 1
    mov dx, offset char_buffer
    int 21h
    jc read_file_error
    
    cmp ax, 0       ; EOF?
    je name_read_done
    
    mov al, char_buffer
    cmp al, 13      ; CR
    je name_read_done
    cmp al, 10      ; LF
    je name_read_done
    
    mov [di], al
    inc di
    jmp read_name
    
name_read_done:
    mov byte ptr [di], 0    ; Null-terminate
    
    ; Close file
    mov ah, 3Eh
    mov bx, file_handle
    int 21h
    jnc read_success
    
    ; Close error
    print file_open_error
    jmp read_error
    
read_file_error:
    print file_open_error
    jmp close_file
    
line_not_found_error:
    print line_not_found
    jmp close_file
    
close_file:
    mov ah, 3Eh
    mov bx, file_handle
    int 21h
    
read_error:
    mov ax, 1
    jmp read_exit
    
read_success:
    xor ax, ax
    
read_exit:
    pop di
    pop si
    pop dx
    pop cx
    pop bx
    pop ax
    ret
read_program_name endp

; Execute the program
execute_program proc
    push ax
    push bx
    push cx
    push dx
    push es
    
    ; Print executing message
    print executing_msg
    print program_name
    print newline
    
    ; Prepare environment
    mov ax, @data
    mov es, ax
    
    ; Execute program
    mov ah, 4Bh
    mov al, 0       ; Load and execute
    mov dx, offset program_name
    mov bx, offset EPB
    int 21h
    jnc exec_success
    
    ; Execution error
    print exec_error_msg
    mov ax, 1
    jmp exec_exit
    
exec_success:
    xor ax, ax
    
exec_exit:
    pop es
    pop dx
    pop cx
    pop bx
    pop ax
    ret
execute_program endp

main:
    mov ax, @data
    mov ds, ax
    mov es, ax
    
    ; Parse command line
    call parse_cmd_line
    or ax, ax
    jnz exit_error
    
    ; Read program name from file
    call read_program_name
    or ax, ax
    jnz exit_error
    
    ; Execute program N times
    mov cl, N
    xor ch, ch
    jcxz exec_done
    
exec_loop:
    call execute_program
    or ax, ax
    jnz exit_error
    loop exec_loop
    
exec_done:
    ; Exit successfully
    mov ax, 4C00h
    int 21h
    
exit_error:
    ; Exit with error
    mov ax, 4C01h
    int 21h

end main