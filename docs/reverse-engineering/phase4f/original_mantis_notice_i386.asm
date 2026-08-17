   1a162:	pushl	%ebp
   1a163:	movl	%esp, %ebp
   1a165:	pushl	%edi
   1a166:	pushl	%esi
   1a167:	movl	$0x94b84, %esi
   1a16c:	pushl	%ebx
   1a16d:	subl	$0x3c, %esp
   1a170:	movzbl	0x10(%ebp), %eax
   1a174:	movb	%al, -0x31(%ebp)
   1a177:	calll	0x43366
   1a17c:	fstpl	-0x30(%ebp)
   1a17f:	calll	0x4eca6
   1a184:	movl	0x1dc05c, %ebx
   1a18a:	cmpb	$0x1, %al
   1a18c:	sbbl	%eax, %eax
   1a18e:	xorl	%edi, %edi
   1a190:	andl	$0x3e0, %eax
   1a195:	addl	$0x7, %eax
   1a198:	movl	%eax, -0x20(%ebp)
   1a19b:	cmpl	$0x2, 0xbfc(%ebx)
   1a1a2:	jne	0x1a2e0
   1a1a8:	movl	0x81bfc, %eax
   1a1ad:	testl	%eax, %eax
   1a1af:	js	0x1a1ba
   1a1b1:	cmpl	%eax, -0x20(%ebp)
   1a1b4:	jne	0x1a2e0
   1a1ba:	movl	-0x20(%ebp), %eax
   1a1bd:	cmpl	0xbd0(%ebx), %eax
   1a1c3:	jne	0x1a2e0
   1a1c9:	cmpb	$0x0, -0x31(%ebp)
   1a1cd:	je	0x1a2d7
   1a1d3:	movsd	0x76a40, %xmm0
   1a1db:	addsd	(%esi), %xmm0
   1a1df:	ucomisd	-0x30(%ebp), %xmm0
   1a1e4:	ja	0x1a2e0
   1a1ea:	movl	-0x4(%esi), %ecx
   1a1ed:	leal	-0x4(%esi), %eax
   1a1f0:	movsd	-0x30(%ebp), %xmm0
   1a1f5:	movl	%eax, -0x1c(%ebp)
   1a1f8:	movsd	%xmm0, (%esi)
   1a1fc:	testl	%ecx, %ecx
   1a1fe:	jne	0x1a2e0
   1a204:	movss	0xb44(%ebx), %xmm0
   1a20c:	divss	0x76d98, %xmm0
   1a214:	movss	%xmm0, (%esp)
   1a219:	calll	0x1dcbe5 ## symbol stub for: _lroundf
   1a21e:	movl	%eax, -0x24(%ebp)
   1a221:	movss	0xb48(%ebx), %xmm0
   1a229:	divss	0x76d98, %xmm0
   1a231:	movss	%xmm0, (%esp)
   1a236:	calll	0x1dcbe5 ## symbol stub for: _lroundf
   1a23b:	movl	0x8(%ebp), %edx
   1a23e:	subl	-0x24(%ebp), %edx
   1a241:	imull	%edx, %edx
   1a244:	movl	%eax, %ecx
   1a246:	movl	0xc(%ebp), %eax
   1a249:	subl	%ecx, %eax
   1a24b:	imull	%eax, %eax
   1a24e:	addl	%eax, %edx
   1a250:	movl	0xbd4(%ebx), %eax
   1a256:	testl	%eax, %eax
   1a258:	jne	0x1a26d
   1a25a:	movl	0x8(%ebp), %eax
   1a25d:	cmpl	%eax, -0x24(%ebp)
   1a260:	jge	0x1a28e
   1a262:	movl	$0xe1, %eax
   1a267:	cmpl	%edx, %eax
   1a269:	jle	0x1a2e0
   1a26b:	jmp	0x1a295
   1a26d:	cmpl	$0x2, %eax
   1a270:	jne	0x1a27a
   1a272:	movl	0x8(%ebp), %eax
   1a275:	cmpl	%eax, -0x24(%ebp)
   1a278:	jmp	0x1a282
   1a27a:	cmpl	$0x3, %eax
   1a27d:	jne	0x1a286
   1a27f:	cmpl	0xc(%ebp), %ecx
   1a282:	jle	0x1a28e
   1a284:	jmp	0x1a262
   1a286:	decl	%eax
   1a287:	jne	0x1a262
   1a289:	cmpl	0xc(%ebp), %ecx
   1a28c:	jmp	0x1a260
   1a28e:	movl	$0x31, %eax
   1a293:	jmp	0x1a267
   1a295:	movl	$0x3e99999a, (%esp)
   1a29c:	calll	0x5f86e
   1a2a1:	testb	%al, %al
   1a2a3:	je	0x1a2e0
   1a2a5:	movl	-0x1c(%ebp), %eax
   1a2a8:	movl	$0x0, 0x10(%esi)
   1a2af:	movl	$0x1, (%eax)
   1a2b5:	movl	$0x0, 0xc(%esp)
   1a2bd:	movl	$0x40000000, 0x8(%esp)
   1a2c5:	movl	$0x1, 0x4(%esp)
   1a2cd:	movl	%edi, (%esp)
   1a2d0:	calll	0x20d92
   1a2d5:	jmp	0x1a2e0
   1a2d7:	cmpl	$0x1, -0x4(%esi)
   1a2db:	jne	0x1a2e0
   1a2dd:	incl	0x10(%esi)
   1a2e0:	incl	%edi
   1a2e1:	addl	$0xc3c, %ebx
   1a2e7:	addl	$0x1c, %esi
   1a2ea:	cmpl	$0x4, %edi
   1a2ed:	jne	0x1a19b
   1a2f3:	addl	$0x3c, %esp
   1a2f6:	popl	%ebx
   1a2f7:	popl	%esi
   1a2f8:	popl	%edi
   1a2f9:	leave
   1a2fa:	retl
