.model small
.stack 100h
.data 
    exec_msg db 13, 10, "Trying execute program 'LAB_3.exe'$"
    prog_start_err_msg db 13, 10, "Program start error$" 
    prog_closed_msg db 13, 10, "Press any key to see result$"
    program_name db "LAB_3.exe", 0
    file_parameters db 128 dup("$")
    buffer_file db 1
    counter db 1 
    buffer db 128 dup("$")
    parameters db 128 dup("$")
    endl db 10, 13, "$" 
    not_found_file db 10, 13, "File not found!$" 
    prog_param_msg db 10, 13, "Program parameters: $"
    error_number_parameters db 13, 10, "Invalid number of parameters$"
    opened db 13, 10, "File has been opened$"
    closed db 13, 10, "File has been closed$"    
    EPB dw 0
    cmd_off dw offset parameters
    cmd_seg dw ?
    fcb1 dd ?
    fcb2 dd ?
    EPB_len dw $ - EPB 
    dsize = $ - exec_msg
  
.code
start:

print_str macro str
    mov ax, 0900h
    lea dx, str
    int 21h       
endm print_str

    mov ax, @data
    mov ds, ax
    mov cmd_seg, ax
    call command_line
    call copy_parameters
    cmp file_parameters[0], 24h
    je error
    print_str file_parameters 
    print_str endl
    call open_file
    print_str prog_param_msg
    print_str parameters[1]
    print_str endl
    call start_another_program
    jmp exit
    
error:
    print_str error_number_parameters

exit:      
    mov ax, 4c00h
    int 21h  

copy_parameters proc
    mov si, 2
    xor di, di 
    mov file_parameters[1], 0
        
iter_check:    
    cmp buffer[si], 20h
    je next
    cmp buffer[si], 09h
    je next
    cmp buffer[si], 24h
    je exit_copy_parameters
    cmp buffer[si], 0dh
    je exit_copy_parameters
    jmp iter_copy_params
    
next: 
    cmp di, 0
    jne exit_copy_parameters
    inc si
    jmp iter_check

iter_copy_params:
    mov dl, buffer[si]   
    mov file_parameters[di], dl
    inc di  
    inc si         
    jmp iter_check   

exit_copy_parameters:          
    inc di
    mov file_parameters[di], 0
    ret
endp copy_parameters

open_file proc     
    mov ax, 3d00h
    mov dx, offset file_parameters
    int 21h
    jc error_open_file
    mov bx, ax
    print_str opened
    call read_file
    call close_file
    jmp ok
    
error_open_file:
    print_str not_found_file
    jmp exit
    
ok:
    ret
endp open_file

read_file proc
    mov si, 1
    mov counter, 1 
    mov parameters[si], 20h
    inc si   
   
reading:
    mov ax, 3f00h
    mov dx, offset buffer_file
    mov cx, 1
    int 21h 
    cmp ax, 0
    je reading_end 
    mov al, buffer_file 
    cmp al, 0dh
    je next_arg
    cmp al, 0ah
    je reading
    mov parameters[si], al  
    inc si
    inc counter
    jmp reading  
    
next_arg:
    mov parameters[si], ' '
    inc si   
    inc counter
    jmp reading
    
reading_end:    
    mov dl, counter
    mov parameters[0], dl
    ret
endp read_file

close_file proc
    mov ax, 3e00h
    int 21h
    print_str closed 
    ret
endp close_file

command_line proc
    xor cx, cx
    xor di, di
    mov si, 80h  
    
command_line_input:
    mov al, es:[si]
    inc si
    cmp al, 0                 
    je command_line_end
    mov buffer[di], al
    inc di
    jmp command_line_input

command_line_end:
    ret
endp command_line

start_another_program proc
    mov ax, 4a00h
    mov bx, ((csize/16) + 17) + ((dsize/16) + 17) + 1
    int 21h
    print_str exec_msg
    print_str prog_closed_msg
    mov ax, 0100h
    int 21h   
    mov ax, @data  
    mov es, ax
    mov ax, 4b00h
    lea dx, program_name 
    lea bx, EPB
    int 21h
    jb error_start_program
    jmp exit
    
error_start_program:
    print_str prog_start_err_msg
    ret
endp start_another_program 

csize = $ - start
end start