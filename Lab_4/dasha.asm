.model tiny  
.286
.code 
org 100h  

main:
    mov dx, offset msg_program_start  
    call output_string  

    call getConsoleParameters  
    
    mov dx, offset msg_program_name  
    call output_string_without_new_line  
    mov dx, offset program_name  
    call output_string  

    mov dx, offset msg_argument  
    call output_string_without_new_line  
    mov dx, offset program_parameters  
    inc dx 
    call output_string  

    
    mov dx, offset msg_iterations  
    call output_string_without_new_line  
    mov dx, offset iterations_string  
    call output_string 

    
    call string_to_number
    mov al, iterations  
    cmp al, 0  
    je short_jump_invalid_iterations  

    push cx 
    call change_memory_size
    pop cx   

    xor cx, cx 
    mov cl, iterations  
    
iteration:
    call run_program  
    call start_new_line

    loop iteration  

    mov ah, 4Ch  
    mov al, 0    
    int 21h      

short_jump_invalid_iterations:
    jmp error_invalid_iterations 

print_char proc
    push ax      
    push dx     
    mov ah, 02h 
    int 21h      
    pop dx       
    pop ax       
    ret          
print_char endp

change_memory_size proc      
    mov ah, 4Ah          
    mov bx, program_size + 600h  
    shr bx, 4            
    inc bx 
    int 21h              
    jc change_memory_size_error  
   
    mov ax, cs           
    mov word ptr EPB+4, ax  
    mov word ptr EPB+8, ax  
    mov word ptr EPB+0Ch, ax  
    ret                  
change_memory_size endp    


change_memory_size_error:
    cmp ax, 07h  
    jne short not_error_memory_manager_blocks
    jmp error_memory_manager_blocks_are_destroyed
not_error_memory_manager_blocks:
    cmp ax, 08h  
    jne short not_error_too_few_memory
    jmp error_too_few_memory
not_error_too_few_memory:
    cmp ax, 09h 
    jne short default_change_memory_size_error
    jmp error_invalid_adress_in_es
default_change_memory_size_error:
    mov dx, offset errorChangeMemorySize  
    call output_string  
    mov ah, 4Ch  
    mov al, 1    
    int 21h      


run_program proc 
    mov ah, 4Bh  
    mov al, 00h  
    mov dx, offset program_name  
    mov bx, offset EPB  
    int 21h      
    jnc short run_program_no_error  
    jmp run_program_error  
run_program_no_error:
    ret          
run_program endp    

run_program_error:
    cmp ax, 02h  
    jne short not_error_cannot_find_file
    jmp error_cannot_find_file
not_error_cannot_find_file:
    cmp ax, 05h 
    jne short not_error_cannot_access_file
    jmp error_cannot_access_file
not_error_cannot_access_file:
    cmp ax, 08h  
    jne short not_error_too_few_memory_run
    jmp error_too_few_memory
not_error_too_few_memory_run:
    cmp ax, 0Ah 
    jne short not_error_bad_enviroment
    jmp error_bad_enviroment
not_error_bad_enviroment:
    cmp ax, 0Bh  
    jne short default_run_program_error
    jmp error_invalid_format
default_run_program_error:
    mov dx, offset errorInvalidFormat 
    call output_string  
    mov ah, 4Ch  
    mov al, 1    
    int 21h      


getConsoleParameters proc
    pusha        
    push si      
    push di      
    
    
    mov si, 81h  
    mov di, 0   
    mov word ptr program_name_len, 0  
    mov word ptr program_params_len, 0  
    mov word ptr iterations_len, 0  
    
skip_space_1:
    mov al, ds:[si]  
    cmp al, 0dh 
    jne short skip_space_1_not_cr  
    jmp error_cannot_read_all_parameters_jump  
skip_space_1_not_cr:
    cmp al, 20h  
    je short skip_space_1_continue  
    jmp read_program_name  
skip_space_1_continue:
    inc si       
    jmp skip_space_1  
    
error_cannot_read_all_parameters_jump:
    jmp error_cannot_read_all_parameters  
    
read_program_name:
    mov [program_name + di], al  
    inc si       
    inc di       
    mov al, ds:[si]  
    cmp al, 20h  
    je skip_space_2  
    cmp al, 0dh  
    jne read_program_name  
    jmp error_cannot_read_all_parameters_jump  
          
skip_space_2:  
    mov byte ptr [program_name + di], 0  
    
    mov word ptr program_name_len, di 
    mov di, 0    
    
skip_space_2_loop:
    mov al, ds:[si]  
    cmp al, 0dh 
    jne short skip_space_2_not_cr
    jmp error_cannot_read_all_parameters  
skip_space_2_not_cr:
    cmp al, 20h  
    je short skip_space_2_continue  
    jmp read_program_parameters  
skip_space_2_continue:
    inc si       
    jmp skip_space_2_loop  
    
read_program_parameters:
    mov [program_parameters + 1 + di], al  
    inc si       
    inc di       
    mov al, ds:[si]  
    cmp al, 20h  
    je skip_space_3  
    cmp al, 0dh  
    jne read_program_parameters 
    jmp error_cannot_read_all_parameters  
    
skip_space_3:  
    mov byte ptr [program_parameters + 1 + di], 0  
    
    mov word ptr program_params_len, di  
    mov di, 0    
    
skip_space_3_loop:
    mov al, ds:[si]  
    cmp al, 0dh  
    jne short skip_space_3_not_cr
    jmp error_cannot_read_all_parameters 
skip_space_3_not_cr:
    cmp al, 20h  
    jne read_iterations  
    inc si       
    jmp skip_space_3_loop  
    
read_iterations:
    mov [iterations_string + di], al 
    inc si       
    inc di       
    mov al, ds:[si]  
    cmp al, 20h  
    je end_read_parameters  
    cmp al, 0dh  
    je end_read_parameters  
    jmp read_iterations  
    
end_read_parameters:
    mov byte ptr [iterations_string + di], 0  
    
    mov word ptr iterations_len, di 
    
    cmp word ptr program_name_len, 0  
    je error_cannot_read_all_parameters  
    cmp word ptr program_params_len, 0  
    je error_cannot_read_all_parameters  
    cmp word ptr iterations_len, 0  
    je error_cannot_read_all_parameters  

    mov bx, program_params_len  
    mov byte ptr [program_parameters], bl  
    mov byte ptr [program_parameters + 1 + bx], 0Dh  

    mov bx, iterations_len   
    mov iterations_string_size, bx  


    pop di       
    pop si       
    popa         
    ret          
getConsoleParameters endp 

number_to_string proc
    pusha  
    mov di, offset iteration_buffer  
    mov bx, 10  
    xor cx, cx  

convert_loop:
    xor dx, dx  
    div bx      
    add dl, '0' 
    push dx     
    inc cx       
    cmp ax, 0    
    jne convert_loop  

store_loop:
    pop dx       
    mov [di], dl  
    inc di       
    loop store_loop  

    mov byte ptr [di], 0  
    popa  
    ret  
number_to_string endp


error_cannot_read_all_parameters:
    mov dx, offset errorCannotReadAllParametersMessage 
    call output_string  
    mov ah, 4Ch  
    mov al, 1    
    int 21h      


error_overflow:
    mov dx, offset errorOverflowMessage 
    call output_string  
    mov ah, 4Ch  
    mov al, 1    
    int 21h      


error_invalid_iterations:
    mov dx, offset errorInvalidIterations  
    call output_string  
    mov ah, 4Ch  
    mov al, 1    
    int 21h      


output_string proc    
    push ax      
    push si      
    mov si, dx   
print_loop:
    mov al, [si]  
    cmp al, 0    
    je end_print  
    mov dl, al   
    mov ah, 02h  
    int 21h      
    inc si       
    jmp print_loop  
end_print:
    call start_new_line  
    pop si       
    pop ax       
    ret          
output_string endp   


output_string_without_new_line proc    
    push ax      
    push si      
    mov si, dx   
print_loop_no_newline:
    mov al, [si]  
    cmp al, 0    
    je end_print_no_newline  
    mov dl, al   
    mov ah, 02h  
    int 21h      
    inc si       
    jmp print_loop_no_newline  
end_print_no_newline:
    pop si       
    pop ax       
    ret          
output_string_without_new_line endp   


start_new_line proc    
    pusha        
    mov dl, 0Dh  
    mov ah, 02h  
    int 21h      
    mov dl, 0Ah  
    mov ah, 02h  
    int 21h      
    popa         
    ret          
start_new_line endp                 


string_to_number proc 
    pusha        
    push si      
    
    mov cx, iterations_string_size  
    xor ax, ax   
    xor bx, bx   
    xor dx, dx   
    mov si, 0    
        
get_digit:       
    mov dl, iterations_string[si]  
    sub dl, '0'  
    cmp dl, 9    
    ja error_nan  
                        
    
    mov bl, 10   
    mul bl       
            
    cmp ah, 0    
    jne error_overflow  
            
 
    add al, dl   
    inc si      
                
    loop get_digit  
    mov iterations, al  
   
   
    pop si       
    popa         
    ret          
string_to_number endp

error_nan:
    mov dx, offset errorNanMessage  
    call output_string  
    mov ah, 4Ch  
    mov al, 1    
    int 21h      
     
error_memory_manager_blocks_are_destroyed:
    mov dx, offset errorMemoryManagerBlocksAreDestroyed  
    call output_string  
    mov ah, 4Ch  
    mov al, 1    
    int 21h      
       
error_too_few_memory:  
    mov dx, offset errorTooFewMemory  
    call output_string  
    mov ah, 4Ch  
    mov al, 1    
    int 21h      
    
error_invalid_adress_in_es:
    mov dx, offset errorInvalidAdressInEs  
    call output_string  
    mov ah, 4Ch  
    mov al, 1    
    int 21h      

error_cannot_find_file:        
    mov dx, offset errorCannotFindFile  
    call output_string  
    mov ah, 4Ch  
    mov al, 1    
    int 21h      
    
error_cannot_access_file:
    mov dx, offset errorCannotAccessFile  
    call output_string  
    mov ah, 4Ch  
    mov al, 1    
    int 21h      
      
error_bad_enviroment:     
    mov dx, offset errorBadEnviroment  
    call output_string  
    mov ah, 4Ch  
    mov al, 1    
    int 21h      

error_invalid_format:
    mov dx, offset errorInvalidFormat  
    call output_string  
    mov ah, 4Ch  
    mov al, 1    
    int 21h      


program_size equ ($ - main)  

program_name db 128 dup (0)  
program_parameters db 128 dup (0)  
iterations_string db 64 dup (0)  
program_name_len dw 0  
program_params_len dw 0  
iterations_len dw 0  
iterations_string_size dw 0  
iterations db 0  
iteration_buffer db 6 dup (0) 


msg_program_start db "Program started", 0
msg_program_name db "Program name: ", 0
msg_argument db "Argument: ", 0
msg_iterations db "Iterations: ", 0


errorCannotReadAllParametersMessage db "Error: too few parameters!", 0
errorOverflowMessage db "Error: too big number!", 0  
errorNanMessage db "Error: not a number!", 0  
errorInvalidIterations db "Error: number of iterations must be between 1 and 255!", 0
errorChangeMemorySize db "Error: changing size of memory!", 0
errorMemoryManagerBlocksAreDestroyed db "Error: memory manager blocks are destroyed!", 0
errorTooFewMemory db "Error: too few memory!", 0
errorInvalidAdressInEs db "Error: invalid adress in es!", 0
errorCannotFindFile db "Error: cannot find file path!", 0  
errorCannotAccessFile db "Error: cannot access file!", 0  
errorBadEnviroment db "Error: bad enviroment!", 0  
errorInvalidFormat db "Error: invalid format!", 0    


EPB             dw 0000h  
                dw offset program_parameters, 0 
                dw 005Ch, 0, 006Ch, 0  

program_size_value dw 0  

end main  