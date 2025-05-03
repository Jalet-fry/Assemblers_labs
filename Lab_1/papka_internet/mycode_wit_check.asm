.model small;   
.stack 100h;    
.data
    i dw 0h
    CountsOfSymbol EQU 12
    String db ': $' 
    Stg db CountsOfSymbol dup(0h);     ?????? ??? ??????   
    input_string_msg db "Input your string:",0ah,0dh,'$'
    sorted_string_msg db 0ah,0dh,"Your sorted string:",0ah,0dh,'$' 
    error_message db 0Ah,0Dh,"Invalid input! Only English letters and single spaces allowed.",0Ah,0Dh,'$'
.code   

print_string macro string 
    mov ah,09h
    mov dx,offset string
    int 21h
endm
      
print_str proc
    push ax
    mov ah,09h
    int 21h
    pop ax
    ret
print_str endp
Start:
Sort proc
    mov ax, @data;  
    mov ds, ax;
    mov ah, 00h;     ??????? ??????
    mov al, 2h; 
    int 10h
    mov ah, 09h
    Lea dx, String
    int 21h 
    mov ah, 1h;  ?-? ????? ???????
    mov si, 0h
    mov bx, 0h
Input:   ;???? ???????
    int 21h
    mov cx, si
    mov Stg[bx], cl;     ????? ?????
    cmp al, 32;  ???????? ?? ??????
    jne Skip1
    mov si, 0h
    add bx, 10h;     ?????? ?????????? ?????
    jmp Input
Skip1:
    inc si
    mov Stg[bx+si], al;  ????????? ??????? ? ??????  
    cmp al, 13
    jne Input
    mov Stg[bx+si], 0h;  ???????? Enter'?
    mov i, bx;   ???-?? ????
    mov bx, 0h
Sort1:   ;?????????? ??????????
    mov di, bx;  ?????? ??????????? ?????
    mov ax, bx
    add ax, 10h
Sort2:
    mov si, ax
     
    mov cl, Stg[di]
    cmp cl, Stg[si]
    jae Skip2
    mov di, si;  ???? ??????
Skip2: 
    add ax, 10h
    cmp ax, i
    jbe Sort2
    mov si, 0h
Sort3:
    moV cl, Stg[bx+si]; ????? ????
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
    mov ah, 02h; ?-? ????????? ??????? ???????:
    mov bh, 0h;  ? ????????   
    mov dh, 2h; ? ??????
    mov dl, 0h; ? ???????
    int 10h
    mov bx, 0h
    mov si, 0h
    mov ah, 2h;  ?-? ?????? ???????
Output:  ;????? ???????
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
; ======= Input Validation =======
validate_input proc
    LEA  DI,  Stg
    mov cx, CountsOfSymbol
validate_loop:
    mov ah, 01h
    int 21h
    cmp al, 13
    je enter
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
enter:
    mov al, '$'
    stosb
    ret
validate_input endp

End Start