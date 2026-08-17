   1a2fc:	pushl	%ebp
   1a2fd:	movl	%esp, %ebp
   1a2ff:	pushl	%edi
   1a300:	pushl	%esi
   1a301:	movl	$0x94b00, %esi
   1a306:	pushl	%ebx
   1a307:	subl	$0x2c, %esp
   1a30a:	calll	0x4eca6
   1a30f:	movl	0x1dc05c, %ebx
   1a315:	cmpb	$0x1, %al
   1a317:	sbbl	%eax, %eax
   1a319:	xorl	%edi, %edi
   1a31b:	andl	$0x3e1, %eax
   1a320:	addl	$0x6, %eax
   1a323:	movl	%eax, -0x1c(%ebp)
   1a326:	cmpl	$0x2, 0xbfc(%ebx)
   1a32d:	jne	0x1a43d
   1a333:	movl	0x81bfc, %eax
   1a338:	testl	%eax, %eax
   1a33a:	js	0x1a345
   1a33c:	cmpl	%eax, -0x1c(%ebp)
   1a33f:	jne	0x1a43d
   1a345:	movl	-0x1c(%ebp), %eax
   1a348:	cmpl	0xbd0(%ebx), %eax
   1a34e:	jne	0x1a43d
   1a354:	cmpl	$0x3, (%esi)
   1a357:	jne	0x1a36f
   1a359:	cmpl	$0x4, 0xc(%esi)
   1a35d:	jg	0x1a43d
   1a363:	movl	$0x5, 0xc(%esi)
   1a36a:	jmp	0x1a43d
   1a36f:	movss	0xb44(%ebx), %xmm0
   1a377:	divss	0x76d98, %xmm0
   1a37f:	movss	%xmm0, (%esp)
   1a384:	calll	0x1dcbe5 ## symbol stub for: _lroundf
   1a389:	movl	%eax, -0x20(%ebp)
   1a38c:	movss	0xb48(%ebx), %xmm0
   1a394:	divss	0x76d98, %xmm0
   1a39c:	movss	%xmm0, (%esp)
   1a3a1:	calll	0x1dcbe5 ## symbol stub for: _lroundf
   1a3a6:	movl	0x8(%ebp), %edx
   1a3a9:	subl	-0x20(%ebp), %edx
   1a3ac:	imull	%edx, %edx
   1a3af:	movl	%eax, %ecx
   1a3b1:	movl	0xc(%ebp), %eax
   1a3b4:	subl	%ecx, %eax
   1a3b6:	imull	%eax, %eax
   1a3b9:	addl	%eax, %edx
   1a3bb:	movl	0xbd4(%ebx), %eax
   1a3c1:	testl	%eax, %eax
   1a3c3:	jne	0x1a3d8
   1a3c5:	movl	0x8(%ebp), %eax
   1a3c8:	cmpl	%eax, -0x20(%ebp)
   1a3cb:	jge	0x1a3f9
   1a3cd:	movl	$0x64, %eax
   1a3d2:	cmpl	%edx, %eax
   1a3d4:	jle	0x1a43d
   1a3d6:	jmp	0x1a400
   1a3d8:	cmpl	$0x2, %eax
   1a3db:	jne	0x1a3e5
   1a3dd:	movl	0x8(%ebp), %eax
   1a3e0:	cmpl	%eax, -0x20(%ebp)
   1a3e3:	jmp	0x1a3ed
   1a3e5:	cmpl	$0x3, %eax
   1a3e8:	jne	0x1a3f1
   1a3ea:	cmpl	0xc(%ebp), %ecx
   1a3ed:	jle	0x1a3f9
   1a3ef:	jmp	0x1a3cd
   1a3f1:	decl	%eax
   1a3f2:	jne	0x1a3cd
   1a3f4:	cmpl	0xc(%ebp), %ecx
   1a3f7:	jmp	0x1a3cb
   1a3f9:	movl	$0x19, %eax
   1a3fe:	jmp	0x1a3d2
   1a400:	movl	$0x3f666666, (%esp)
   1a407:	calll	0x5f86e
   1a40c:	testb	%al, %al
   1a40e:	je	0x1a43d
   1a410:	movl	$0x3, (%esi)
   1a416:	movl	$0x5, 0xc(%esi)
   1a41d:	movl	$0x0, 0xc(%esp)
   1a425:	movl	$0x40000000, 0x8(%esp)
   1a42d:	movl	$0x1, 0x4(%esp)
   1a435:	movl	%edi, (%esp)
   1a438:	calll	0x20d92
   1a43d:	incl	%edi
   1a43e:	addl	$0xc3c, %ebx
   1a444:	addl	$0x1c, %esi
   1a447:	cmpl	$0x4, %edi
   1a44a:	jne	0x1a326
   1a450:	addl	$0x2c, %esp
   1a453:	popl	%ebx
   1a454:	popl	%esi
   1a455:	popl	%edi
   1a456:	leave
   1a457:	retl
