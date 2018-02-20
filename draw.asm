.data
	ddt		real8	0.000001
	t		real8	0.0
	wh4		qword	0
	wh2		qword	0
	a		dword	0
	b		dword	0
	x		qword	0
	y		qword	0
.code
	public draw
draw proc

;ARGS
;	rcx:		buffer
;	rdx:		width
;	r8:			height
;	r9:			a
;	[rbp + 48]	b
;
;VARS
;	rdx:				width or height / 4
;	r8:		FF000000	mask to preserve put pixels
;	r9:		0/1/2/3		padding
;	r10:				width
;	r11:	3			color depth on 3B
;	r12:				padding
;	rax:				pixel addres

	push rbp		;prepare stack
	mov rbp, rsp
	push r12

	mov r11, 3		;3B color depth so need to mul by 3
	mov r10, rdx	;save width in r10
	cmp rdx, r8		;cmp width w/ height
	jbe widthbe		;jump below/eq with <= height
	mov rdx, r8		;width > height

widthbe:
	shr rdx, 1				;width/height / 2 - offset in bitmap
	mov [wh2], rdx
	shr rdx, 1				;width/height / 4 - radius of drawing
	mov [wh4], rdx

	mov [a], r9d			;save 'a' from register ('a' is 4th arg)
	mov r8d, [rbp + 48]
	mov [b], r8d			;save 'b' from stack ('b' is 5th arg)

	mov r9, r10				;r9 = width
	and r9, 3H				;r9 = width mod(4) - count padding
	mov r8d, 0FF000000H		;mask to preserve already put pixels

	fild [b]
	fild [a]
	fld [ddt]
	fldpi				;load pi
	fld1
	fadd st(0), st(0)	;load 2
	fmulp				;st(0) = 2pi
	fild [wh4]
	fild [wh2]
	fld [t]

;FPU STACK
;	BEFORE/AFTER		WHILE COUNTING COORD
;		st(7)				st(7)	b
;		st(6)	b			st(6)	a
;		st(5)	a			st(5)	dt
;		st(4)	dt			st(4)	2pi
;		st(3)	2pi			st(3)	wh4
;		st(2)	wh4			st(2)	wh2
;		st(1)	wh2			st(1)	t
;		st(0)	t			st(0)	coordinate

start:
	fld st(5)			;load a, st(5) -> st(6)
	fmul st(0), st(1)	;a * t
	fcos				;cos(a * t)
	fmul st(0), st(3)	;wh4 * cos(a * t)
	fadd st(0), st(2)	;wh4 * cos(a * t) + wh2
	fistp [x]			;st(6) -> st(5)

	fld st(6)			;load b, st(6) -> st(7)
	fmul st(0), st(1)	;b * t
	fsin				;sin(b * t)
	fmul st(0), st(3)	;wh4 * sin(b * t)
	fadd st(0), st(2)	;wh4 * sin(b * t) + wh2
	fistp [y]			;st(7) -> st(6)

caddr:
	mov rax, [y]		;rax = y
	mov r12, rax		;r12 = y
	mul r10				;rax = y * width
	add rax, [x]		;rax = y * width + x
	mul r11				;rax = 3 * (y * width + x)

	imul r12, r9		;r12 = y * padding
	add rax, r12		;rax = (..) + y * padding
	add rax, 54			;rax = (..) + 54 - header size

	and [rcx + rax], r8d	;adds three 0x0B and remains previous 0x0 bytes

	fadd st(0), st(4)		;t+=ddt
	fcomi st(0), st(3)
	jnae start				;jump if less or equal: t <= 2pi

	fninit
	pop r12
	mov rsp, rbp
	pop rbp
	ret
draw endp
end
