	.file	"main.c"
	.intel_syntax noprefix
	.text
	.def	printf;	.scl	3;	.type	32;	.endef
	.seh_proc	printf
printf:
	push	rbp
	.seh_pushreg	rbp
	push	rbx
	.seh_pushreg	rbx
	sub	rsp, 56
	.seh_stackalloc	56
	lea	rbp, 48[rsp]
	.seh_setframe	rbp, 48
	.seh_endprologue
	mov	QWORD PTR 32[rbp], rcx
	mov	QWORD PTR 40[rbp], rdx
	mov	QWORD PTR 48[rbp], r8
	mov	QWORD PTR 56[rbp], r9
	lea	rax, 40[rbp]
	mov	QWORD PTR -16[rbp], rax
	mov	rbx, QWORD PTR -16[rbp]
	mov	ecx, 1
	mov	rax, QWORD PTR __imp___acrt_iob_func[rip]
	call	rax
	mov	rcx, rax
	mov	rax, QWORD PTR 32[rbp]
	mov	r8, rbx
	mov	rdx, rax
	call	__mingw_vfprintf
	mov	DWORD PTR -4[rbp], eax
	mov	eax, DWORD PTR -4[rbp]
	add	rsp, 56
	pop	rbx
	pop	rbp
	ret
	.seh_endproc
	.def	sprintf;	.scl	3;	.type	32;	.endef
	.seh_proc	sprintf
sprintf:
	push	rbp
	.seh_pushreg	rbp
	mov	rbp, rsp
	.seh_setframe	rbp, 0
	sub	rsp, 48
	.seh_stackalloc	48
	.seh_endprologue
	mov	QWORD PTR 16[rbp], rcx
	mov	QWORD PTR 24[rbp], rdx
	mov	QWORD PTR 32[rbp], r8
	mov	QWORD PTR 40[rbp], r9
	lea	rax, 32[rbp]
	mov	QWORD PTR -16[rbp], rax
	mov	rcx, QWORD PTR -16[rbp]
	mov	rdx, QWORD PTR 24[rbp]
	mov	rax, QWORD PTR 16[rbp]
	mov	r8, rcx
	mov	rcx, rax
	call	__mingw_vsprintf
	mov	DWORD PTR -4[rbp], eax
	mov	eax, DWORD PTR -4[rbp]
	add	rsp, 48
	pop	rbp
	ret
	.seh_endproc
	.def	__main;	.scl	2;	.type	32;	.endef
	.section .rdata,"dr"
.LC0:
	.ascii "Usage: %s <N> <K>\12\0"
	.align 8
.LC1:
	.ascii "N and K must be in range [1, 255]\12\0"
.LC2:
	.ascii "r\0"
.LC3:
	.ascii "files.txt\0"
.LC4:
	.ascii "Could not open files.txt\12\0"
.LC5:
	.ascii "\12\0"
	.align 8
.LC6:
	.ascii "K is greater than number of lines in file\12\0"
.LC7:
	.ascii "start %s\0"
	.text
	.globl	main
	.def	main;	.scl	2;	.type	32;	.endef
	.seh_proc	main
main:
	push	rbp
	.seh_pushreg	rbp
	mov	eax, 65616
	call	___chkstk_ms
	sub	rsp, rax
	.seh_stackalloc	65616
	lea	rbp, 128[rsp]
	.seh_setframe	rbp, 128
	.seh_endprologue
	mov	DWORD PTR 65504[rbp], ecx
	mov	QWORD PTR 65512[rbp], rdx
	call	__main
	mov	DWORD PTR 65484[rbp], 0
	cmp	DWORD PTR 65504[rbp], 3
	je	.L6
	mov	rax, QWORD PTR 65512[rbp]
	mov	rax, QWORD PTR [rax]
	mov	rdx, rax
	lea	rax, .LC0[rip]
	mov	rcx, rax
	call	printf
	mov	eax, 1
	jmp	.L17
.L6:
	mov	rax, QWORD PTR 65512[rbp]
	add	rax, 8
	mov	rax, QWORD PTR [rax]
	mov	rcx, rax
	call	atoi
	mov	DWORD PTR 65476[rbp], eax
	mov	rax, QWORD PTR 65512[rbp]
	add	rax, 16
	mov	rax, QWORD PTR [rax]
	mov	rcx, rax
	call	atoi
	mov	DWORD PTR 65472[rbp], eax
	cmp	DWORD PTR 65476[rbp], 0
	jle	.L8
	cmp	DWORD PTR 65476[rbp], 255
	jg	.L8
	cmp	DWORD PTR 65472[rbp], 0
	jle	.L8
	cmp	DWORD PTR 65472[rbp], 255
	jle	.L9
.L8:
	lea	rax, .LC1[rip]
	mov	rcx, rax
	call	printf
	mov	eax, 1
	jmp	.L17
.L9:
	lea	rax, .LC2[rip]
	mov	rdx, rax
	lea	rax, .LC3[rip]
	mov	rcx, rax
	call	fopen
	mov	QWORD PTR 65464[rbp], rax
	cmp	QWORD PTR 65464[rbp], 0
	jne	.L11
	lea	rax, .LC4[rip]
	mov	rcx, rax
	call	printf
	mov	eax, 1
	jmp	.L17
.L13:
	lea	rax, 176[rbp]
	mov	edx, DWORD PTR 65484[rbp]
	movsx	rdx, edx
	sal	rdx, 8
	add	rax, rdx
	lea	rdx, .LC5[rip]
	mov	rcx, rax
	call	strcspn
	mov	edx, DWORD PTR 65484[rbp]
	movsx	rdx, edx
	sal	rdx, 8
	lea	rcx, 65488[rdx]
	lea	rdx, [rcx+rbp]
	add	rax, rdx
	sub	rax, 65312
	mov	BYTE PTR [rax], 0
	add	DWORD PTR 65484[rbp], 1
.L11:
	cmp	DWORD PTR 65484[rbp], 254
	jg	.L12
	lea	rax, 176[rbp]
	mov	edx, DWORD PTR 65484[rbp]
	movsx	rdx, edx
	sal	rdx, 8
	add	rax, rdx
	mov	rdx, QWORD PTR 65464[rbp]
	mov	r8, rdx
	mov	edx, 256
	mov	rcx, rax
	call	fgets
	test	rax, rax
	jne	.L13
.L12:
	mov	rax, QWORD PTR 65464[rbp]
	mov	rcx, rax
	call	fclose
	mov	eax, DWORD PTR 65472[rbp]
	cmp	eax, DWORD PTR 65484[rbp]
	jle	.L14
	lea	rax, .LC6[rip]
	mov	rcx, rax
	call	printf
	mov	eax, 1
	jmp	.L17
.L14:
	mov	eax, DWORD PTR 65472[rbp]
	lea	edx, -1[rax]
	lea	rax, 176[rbp]
	movsx	rdx, edx
	sal	rdx, 8
	add	rax, rdx
	mov	QWORD PTR 65456[rbp], rax
	mov	DWORD PTR 65480[rbp], 0
	jmp	.L15
.L16:
	mov	rdx, QWORD PTR 65456[rbp]
	lea	rax, -96[rbp]
	mov	r8, rdx
	lea	rdx, .LC7[rip]
	mov	rcx, rax
	call	sprintf
	lea	rax, -96[rbp]
	mov	rcx, rax
	call	system
	add	DWORD PTR 65480[rbp], 1
.L15:
	mov	eax, DWORD PTR 65480[rbp]
	cmp	eax, DWORD PTR 65476[rbp]
	jl	.L16
	mov	eax, 0
.L17:
	add	rsp, 65616
	pop	rbp
	ret
	.seh_endproc
	.ident	"GCC: (GNU) 13.2.0"
	.def	__mingw_vfprintf;	.scl	2;	.type	32;	.endef
	.def	__mingw_vsprintf;	.scl	2;	.type	32;	.endef
	.def	atoi;	.scl	2;	.type	32;	.endef
	.def	fopen;	.scl	2;	.type	32;	.endef
	.def	strcspn;	.scl	2;	.type	32;	.endef
	.def	fgets;	.scl	2;	.type	32;	.endef
	.def	fclose;	.scl	2;	.type	32;	.endef
	.def	system;	.scl	2;	.type	32;	.endef
