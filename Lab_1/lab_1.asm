.model small
.stack 100h
.data
    CountsOfSymbol EQU 14
    buffer db CountsOfSymbol+1 dup(0) 
    ;buffer db "  dkf hvkj    cdefvkfv     fgrh   $"
    ;buffer db "  a b$"
    ;symbol_to_move db 0 
    ;position_of_symbol_to_move db 0
    ;current_word_length db 0
    max_word_length db 0
    max_word_start dw 0
    current_new_start_sort dw 0
    input_string_msg db "Input your string:",0ah,0dh,'$'
    sorted_string_msg db 0ah,"Your sorted string:",0ah,'$' 
    error_message db 0Ah,0Dh,"Invalid input! Only English letters and single spaces allowed.",0Ah,0Dh,'$'
.code 

print_string macro string 
    mov ah,09h
    mov dx,offset string
    int 21h
endm
      
print_str proc
    push ax        
    push dx        

    mov ah, 09h    ; Функция DOS для вывода строки
    int 21h        ; Вызов прерывания DOS

    ; Вывод перевода строки (CR+LF)
    mov ah, 02h    ; Функция DOS для вывода символа
    mov dl, 0Dh    ; Символ возврата каретки (CR)
    int 21h        
    mov dl, 0Ah    ; Символ перевода строки (LF)
    int 21h        

    pop dx         
    pop ax         
    ret            
print_str endp
;Old
;print_str proc
;    push ax
;    mov ah,09h
;    int 21h
;    pop ax
;    ret
;print_str endp
    
start: 
    mov ax,@data
    mov ds,ax 
    mov es,ax
    print_string input_string_msg
    ;mov dx, offset input_string_msg
    ;call print_str                           
    call validate_input; Check input before sorting
    mov dx, offset buffer
    call print_str 
    ;print_string buffer
    call sort
    print_string sorted_string_msg
    mov dx, offset buffer
    call print_str 
    ;print_string buffer
    
    ;ret
    mov ax,4C00h 
    int 21h


; ======= Input Validation =======
validate_input proc
    LEA  DI,  buffer
    mov cx, CountsOfSymbol
validate_loop:
    mov ah, 01h ;1 symbol
    int 21h
    cmp al, 13
    je if_symbol_is_enter
    cmp al, 32                ; Space?
    je validate_next      ; If yes, check for double spaces
    cmp al, 'A'               ; If below 'A' -> invalid input
    jl invalid_input
    cmp al, 'Z'               ; Within 'A-Z'?
    jle validate_next
    cmp al, 'a'               ; If below 'a' -> invalid input
    jl invalid_input
    cmp al, 'z'               ; Within 'a-z'?
    jle validate_next

invalid_input:
    print_string error_message
    mov ax, 4c00h
    int 21h

validate_next:
    stosb
    loop validate_loop
if_symbol_is_enter:
    mov al, '$'
    stosb
    mov al, 13 
    ret
validate_input endp

; ======= Sort =======
sort proc
    mov si,offset buffer
after_move_big_word:
    mov current_new_start_sort, si
    mov max_word_length, 0
    mov max_word_start, 0
    CLD
spaces:
    cmp al, '$'    
    je swap_words
    lodsb
    cmp al, ' '
    je spaces
    cmp al, '$'    
    je swap_words
    mov dl, 0   
    mov bx, si
    dec bx;??????? ? ?????? ?????  
letter:
    add dl, 1
    ;mov al, [si]
    lodsb
    cmp al, ' '
    je check_word
    cmp al, '$'
    jne letter
check_word:
    cmp dl, max_word_length
    ;it was old
    jle spaces
    ;jl spaces
    mov max_word_length, dl
    mov max_word_start, bx
    cmp al, ' '
    je spaces

swap_words:
;TODO:
;Check the bigest is not firts
;This 12 line is new, be careful             
    ; Check if we need to move the word
    ; Compare the start of the longest word with the current position
    push ax
    mov ax, max_word_start
    cmp ax, current_new_start_sort
    jne continue_sorting  ; If addresses are not equal, continue sorting
    pop ax
    ; Check if we have reached the end of the string ('$')
    cmp al, '$'
    je sort_final  ; If end of string, exit sorting
    cmp al, 13
    je sort_final

continue_sorting:
    pop ax
    ; Load the length of the longest word into AH
    mov ah, max_word_length
    inc ah
move_by_length:
    mov di, max_word_start
    mov si, di
    STD
    lodsb     
    mov dl,al
    mov cx, max_word_start
    sub cx, current_new_start_sort
    
move_words:
    cmp cx, 0
    jle sort_final
    lodsb
    stosb
    loop move_words
stop_moving:    
    mov di, current_new_start_sort
    mov al, dl
    stosb
    dec ah
    cmp ah, 1
    jne still_in_word
    dec max_word_start
;a bc
;bca ;
;bcaa
;bc a
still_in_word:
    inc current_new_start_sort
    inc max_word_start
    cmp ah, 0
    jne move_by_length
    mov si, current_new_start_sort
    jmp after_move_big_word
;ab cde fghi
;fghiab cde 
;a bc
;bca  
sort_final:
    ret         
sort endp
end start