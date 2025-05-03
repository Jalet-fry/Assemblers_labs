	ifndef	??version
?debug	macro
	endm
publicdll macro	name
	public	name
	endm
$comm	macro	name,dist,size,count
	comm	dist name:BYTE:count*size
	endm
	else
$comm	macro	name,dist,size,count
	comm	dist name[size]:BYTE:count
	endm
	endif
	?debug	V 300h
	?debug	S "main.c"
	?debug	C E9B94B965A066D61696E2E63
	?debug	C E9729F98471B433A5C424F524C414E44435C494E434C5544455C73+
	?debug	C 7464696F2E68
	?debug	C E9399F98471B433A5C424F524C414E44435C494E434C5544455C5F+
	?debug	C 646566732E68
	?debug	C E9FB9E98471C433A5C424F524C414E44435C494E434C5544455C5F+
	?debug	C 6E66696C652E68
	?debug	C E9FC9E98471B433A5C424F524C414E44435C494E434C5544455C5F+
	?debug	C 6E756C6C2E68
	?debug	C E9709F98471C433A5C424F524C414E44435C494E434C5544455C73+
	?debug	C 74646C69622E68
	?debug	C E9719F98471C433A5C424F524C414E44435C494E434C5544455C73+
	?debug	C 7472696E672E68
MAIN_TEXT	segment byte public 'CODE'
MAIN_TEXT	ends
DGROUP	group	_DATA,_BSS
	assume	cs:MAIN_TEXT,ds:DGROUP
_DATA	segment word public 'DATA'
d@	label	byte
d@w	label	word
_DATA	ends
_BSS	segment word public 'BSS'
b@	label	byte
b@w	label	word
_BSS	ends
MAIN_TEXT	segment byte public 'CODE'
   ;	
   ;	int main(int argc, char *argv[]) {
   ;	
	assume	cs:MAIN_TEXT
_main	proc	far
	push	bp
	mov	bp,sp
	sub	sp,18
	push	si
	push	di
   ;	
   ;	    /* Объявляем ВСЕ переменные в начале! */
   ;	    int N, K;
   ;	    FILE *file;
   ;	    char lines[MAX_LINES][MAX_LINE_LENGTH];
   ;	    int line_count = 0;
   ;	
	xor	si,si
   ;	
   ;	    int i;
   ;	    char *program;
   ;	    char command[MAX_LINE_LENGTH + 6];
   ;	
   ;	    /* Проверка аргументов */
   ;	    if (argc != 3) {
   ;	
	cmp	word ptr [bp+6],3
	je	short @1@142
   ;	
   ;	        printf("Usage: %s <N> <K>\n", argv[0]);
   ;	
	les	bx,dword ptr [bp+8]
	push	word ptr es:[bx+2]
	push	word ptr es:[bx]
	push	ds
	mov	ax,offset DGROUP:s@
	push	ax
	call	far ptr _printf
	add	sp,8
@1@86:
   ;	
   ;	        return 1;
   ;	
	mov	ax,1
@1@114:
	jmp	@1@674
@1@142:
   ;	
   ;	    }
   ;	
   ;	    N = atoi(argv[1]);
   ;	
	les	bx,dword ptr [bp+8]
	push	word ptr es:[bx+6]
	push	word ptr es:[bx+4]
	call	far ptr _atol
	pop	cx
	pop	cx
	mov	word ptr [bp-2],ax
   ;	
   ;	    K = atoi(argv[2]);
   ;	
	les	bx,dword ptr [bp+8]
	push	word ptr es:[bx+10]
	push	word ptr es:[bx+8]
	call	far ptr _atol
	pop	cx
	pop	cx
	mov	di,ax
   ;	
   ;	
   ;	    if (N < 1 || N > 255 || K < 1 || K > 255) {
   ;	
	cmp	word ptr [bp-2],1
	jl	short @1@254
	cmp	word ptr [bp-2],255
	jg	short @1@254
	cmp	di,1
	jl	short @1@254
	cmp	di,255
	jle	short @1@282
@1@254:
   ;	
   ;	        printf("N and K must be in range [1, 255]\n");
   ;	
	push	ds
	mov	ax,offset DGROUP:s@+19
	jmp	@1@506
@1@282:
   ;	
   ;	        return 1;
   ;	    }
   ;	
   ;	    /* Открытие файла */
   ;	    file = fopen("files.txt", "r");
   ;	
	push	ds
	mov	ax,offset DGROUP:s@+64
	push	ax
	push	ds
	mov	ax,offset DGROUP:s@+54
	push	ax
	call	far ptr _fopen
	add	sp,8
	mov	word ptr [bp-4],dx
	mov	word ptr [bp-6],ax
   ;	
   ;	    if (!file) {
   ;	
	mov	ax,word ptr [bp-6]
	or	ax,word ptr [bp-4]
	jne	short @1@338
   ;	
   ;	        printf("Could not open files.txt\n");
   ;	
	push	ds
	mov	ax,offset DGROUP:s@+66
	jmp	short @1@506
@1@338:
	jmp	short @1@394
@1@366:
   ;	
   ;	        return 1;
   ;	    }
   ;	
   ;	    /* Чтение строк */
   ;	    while (line_count < MAX_LINES && fgets(lines[line_count], MAX_LINE_LENGTH, file)) {
   ;	        lines[line_count][strcspn(lines[line_count], "\n")] = '\0';
   ;	
	push	ds
	mov	ax,offset DGROUP:s@+92
	push	ax
	push	ss
	mov	ax,si
	mov	cl,8
	shl	ax,cl
	lea	dx,word ptr [bp+244]
	add	ax,dx
	push	ax
	call	far ptr _strcspn
	add	sp,8
	mov	dx,si
	mov	cl,8
	shl	dx,cl
	add	dx,ax
	lea	ax,word ptr [bp+244]
	add	dx,ax
	mov	bx,dx
	mov	byte ptr ss:[bx],0
   ;	
   ;	        line_count++;
   ;	
	inc	si
@1@394:
	cmp	si,255
	jge	short @1@450
	push	word ptr [bp-4]
	push	word ptr [bp-6]
	mov	ax,256
	push	ax
	mov	ax,si
	mov	cl,8
	shl	ax,cl
	lea	dx,word ptr [bp+244]
	add	ax,dx
	push	ss
	push	ax
	call	far ptr _fgets
	add	sp,10
	or	ax,dx
	jne	short @1@366
@1@450:
   ;	
   ;	    }
   ;	
   ;	    fclose(file);
   ;	
	push	word ptr [bp-4]
	push	word ptr [bp-6]
	call	far ptr _fclose
	pop	cx
	pop	cx
   ;	
   ;	
   ;	    if (K > line_count) {
   ;	
	cmp	di,si
	jle	short @1@534
   ;	
   ;	        printf("K is greater than number of lines in file\n");
   ;	
	push	ds
	mov	ax,offset DGROUP:s@+94
@1@506:
	push	ax
	call	far ptr _printf
	pop	cx
	pop	cx
	jmp	@1@86
@1@534:
   ;	
   ;	        return 1;
   ;	    }
   ;	
   ;	    program = lines[K - 1];
   ;	
	mov	ax,di
	mov	cl,8
	shl	ax,cl
	lea	dx,word ptr [bp-12]
	add	ax,dx
	mov	word ptr [bp-10],ss
	mov	word ptr [bp-12],ax
   ;	
   ;	
   ;	    /* Запуск программы N раз */
   ;	    for (i = 0; i < N; i++) {
   ;	
	mov	word ptr [bp-8],0
	jmp	short @1@618
@1@562:
   ;	
   ;	        sprintf(command, "start %s", program);
   ;	
	push	word ptr [bp-10]
	push	word ptr [bp-12]
	push	ds
	mov	ax,offset DGROUP:s@+137
	push	ax
	push	ss
	lea	ax,word ptr [bp-18]
	push	ax
	call	far ptr _sprintf
	add	sp,12
   ;	
   ;	        system(command);
   ;	
	push	ss
	lea	ax,word ptr [bp-18]
	push	ax
	call	far ptr _system
	pop	cx
	pop	cx
	inc	word ptr [bp-8]
@1@618:
	mov	ax,word ptr [bp-8]
	cmp	ax,word ptr [bp-2]
	jl	short @1@562
   ;	
   ;	    }
   ;	
   ;	    return 0;
   ;	
	xor	ax,ax
	jmp	@1@114
@1@674:
   ;	
   ;	}
   ;	
	pop	di
	pop	si
	mov	sp,bp
	pop	bp
	ret	
_main	endp
	?debug	C E9
	?debug	C FA00000000
MAIN_TEXT	ends
_DATA	segment word public 'DATA'
s@	label	byte
	db	'Usage: %s <N> <K>'
	db	10
	db	0
	db	'N and K must be in range [1, 255]'
	db	10
	db	0
	db	'files.txt'
	db	0
	db	'r'
	db	0
	db	'Could not open files.txt'
	db	10
	db	0
	db	10
	db	0
	db	'K is greater than number of lines in file'
	db	10
	db	0
	db	'start %s'
	db	0
_DATA	ends
MAIN_TEXT	segment byte public 'CODE'
MAIN_TEXT	ends
	extrn	__setargv__:far
	public	_main
	extrn	_strcspn:far
	extrn	_system:far
	extrn	_atol:far
	extrn	_sprintf:far
	extrn	_printf:far
	extrn	_fopen:far
	extrn	_fgets:far
	extrn	_fclose:far
_s@	equ	s@
	end
