.model small
.stack 100h
.data

    buffer db 200, 200 dup('$') 
    string_length db 0
    input_string_msg db "Input your string:",0ah,0dh,'$'
    sorted_string_msg db 0ah,0dh,"Your sorted string:",0ah,0dh,'$' 
    error_message db 0Ah,0Dh,"Invalid input! Only English letters and single spaces allowed.",0Ah,0Dh,'$'

.code 

print_string macro string 
    mov ah,09h
    mov dx,offset string
    int 21h
endm

start: 
    mov ax,@data
    mov ds,ax 
    mov es,ax
    
    print_string input_string_msg
    
    mov ah,0ah
    mov dx,offset buffer
    int 21h
    
    mov al,buffer+1
    mov string_length,al
    
    xor dx,dx
    mov dl,string_length

    call validate_input  ; Check input before sorting
    call sort
    call cleanse_buffer

    print_string sorted_string_msg
    print_string buffer+2
    
    mov ax, 4c00h
    int 21h 

; ======= Input Validation =======
validate_input proc
    mov si, offset buffer+2   ; Start of user input
    mov cl, string_length
    mov ch, 0                 ; CX = input length
    mov bl, 0                 ; Double-space flag

validate_loop:
    lodsb                     ; Load character into AL
    cmp al, 32                ; Space?
    je check_double_space      ; If yes, check for double spaces
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

check_double_space:
    cmp bl, 1                 ; If the previous character was a space -> invalid input
    je invalid_input
    mov bl, 1                 ; Set space flag
    jmp validate_next

validate_next:
    mov bl, 0                 ; Reset double-space flag
    loop validate_loop

    ret
validate_input endp

; ======= Sorting =======
sort proc
    xor cx,cx
    mov si,2
    mov bx,0
    mov cx,dx
    
    calc_words_number: 
        inc si
        cmp buffer[si],20h 
        je inc_calc_words_number          
        loop calc_words_number
    
    inc_calc_words_number: 
        inc bx
        cmp cx,0
        jne calc_words_number   
    
    mov cx,bx
    add dx,2

    sorting:
        mov si,dx
        mov di,dx
        mov bx,dx
    
        internal_cycle:    
            cmp si,2
            jle again
    
            push cx
    
            std 

            mov cx,di
            mov di,offset buffer
            add di,si
            mov al,20h
            repne scasb 

            pop cx 
    
        found_space:
            inc di
            mov si,di
    
        find_word_begin:
            dec si
            cmp si,2
            jl compare_words
            cmp buffer[si],20h
            je compare_words
            jmp find_word_begin
    
        compare_words:
            push si
            push di
            push ax 	

            call is_left_word_bigger 

            pop ax
            pop di
            pop si

            jle after_shift
    
        shift_words:
            push si
            push di
    
            inc si
            mov di,bx
            dec di

            call reverse

            pop di
            pop si
    
            mov ax,di
            mov di,si
            add di,bx
            sub di,ax
    
            push si
            push di

            inc si 
            dec di
            
            call reverse
            
            pop di
            pop si

            push si
            push di
    
            inc di
            mov si,di
            mov di,bx
            dec di

            call reverse

            pop di
            pop si
    
        after_shift:
            mov bx,di
            jmp internal_cycle

    again:    
    loop sorting	    
    ret
sort endp 

; ======= Compare Two Words =======
is_left_word_bigger proc 
    push dx
    push bx

    start_proc:
    inc si 
    inc di
    
    mov dl,buffer[si]
    mov bl,buffer[di]
        
    cmp dl,91
    jnl not_less      
    cmp dl,64
    jng not_less
    add dl,32

    not_less:    
        cmp bl, 91
        jnl another
        cmp bl, 64
        jng another
        add bl, 32   

    another:
        cmp dx, bx
        jne stop_cycle  
        cmp dx,20h
        je stop_cycle
        cmp bx,20h
        je stop_cycle
        cmp bx,'$'
        je stop_cycle 

    less:   
        jmp start_proc
        
    stop_cycle:
        cmp dx,bx
        pop bx
        pop dx
        
        ret 
        
is_left_word_bigger endp         

; ======= Reverse a Word =======
reverse proc
    cycle:
        cmp si,di
        jge return
        
        mov ah,buffer[si]
        mov al,buffer[di]
        mov buffer[si],al
        mov buffer[di],ah
        inc si
        dec di
        jmp cycle  
    
    return:    
        ret
reverse endp 

; ======= Clean Buffer =======
cleanse_buffer proc
    find_first_letter: 
        mov cl,string_length
        cld
        mov di,offset buffer+2      
        mov al,20h
        repe scasb
        dec di 
        mov cl,string_length

    move_letters:
        mov si,di
        mov di,offset buffer+2
        rep movsb   
        xor ax,ax
        mov al,string_length
        mov di,ax
        mov buffer[di+2],'$'

    ret
cleanse_buffer endp

end start
