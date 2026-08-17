   1c2da:	movl	-0xb0(%ebp), %edx
   1c2e0:	leal	-0x30(%ebp), %eax
   1c2e3:	movl	%eax, 0xc(%esp)
   1c2e7:	movl	0x14(%ebp), %eax
   1c2ea:	movl	%edx, 0x8(%esp)
   1c2ee:	movl	0x10(%ebp), %edx
   1c2f1:	movl	%eax, 0x4(%esp)
   1c2f5:	movl	%edx, (%esp)
   1c2f8:	calll	0x36d50
   1c2fd:	movl	0x8(%ebp), %ebx
   1c300:	cmpl	%eax, -0xb0(%ebp)
   1c306:	movl	%eax, %esi
   1c308:	sete	%al
   1c30b:	shll	$0x4, %ebx
   1c30e:	movl	%eax, %edi
   1c310:	movl	0x94c88(%ebx), %ecx
   1c316:	leal	-0x1(%ecx), %eax
   1c319:	cmpl	$0x3, %eax
   1c31c:	ja	0x1c368
   1c31e:	jmp	0x1c33b
   1c320:	cmpl	$0x6, %esi
   1c323:	jne	0x1c4dd
   1c329:	calll	0x4eca6
   1c32e:	testb	%al, %al
   1c330:	je	0x1cf0b
   1c336:	jmp	0x1c4af
   1c33b:	movl	%edi, %edx
   1c33d:	testb	%dl, %dl
   1c33f:	jne	0x1c350
   1c341:	movl	0x8(%ebp), %edx
   1c344:	leal	0x1(%ecx), %eax
   1c347:	shll	$0x4, %edx
   1c34a:	movl	%eax, 0x94c88(%edx)
   1c350:	movl	0x8(%ebp), %eax
   1c353:	shll	$0x4, %eax
   1c356:	cmpl	$0x1, 0x94c88(%eax)
   1c35d:	jne	0x1bd53
   1c363:	jmp	0x1c487
   1c368:	movl	0x94c8c(%ebx), %edx
   1c36e:	leal	-0x1(%edx), %eax
   1c371:	cmpl	$0x3, %eax
   1c374:	ja	0x1c3c3
   1c376:	leal	0x1(%edx), %eax
   1c379:	movl	%eax, 0x94c8c(%ebx)
   1c37f:	movl	0xc(%ebp), %eax
   1c382:	movl	-0xb0(%ebp), %edx
   1c388:	movl	%eax, 0x10(%esp)
   1c38c:	movl	0x14(%ebp), %eax
   1c38f:	movl	%edx, 0xc(%esp)
   1c393:	movl	0x10(%ebp), %edx
   1c396:	movl	%eax, 0x8(%esp)
   1c39a:	movl	0x8(%ebp), %eax
   1c39d:	movl	%edx, 0x4(%esp)
   1c3a1:	movl	%eax, (%esp)
   1c3a4:	calll	0x1b094
   1c3a9:	movl	%eax, %esi
   1c3ab:	movl	0x8(%ebp), %eax
   1c3ae:	shll	$0x4, %eax
   1c3b1:	cmpl	$0x1, 0x94c8c(%eax)
   1c3b8:	jne	0x1bd53
   1c3be:	jmp	0x1c467
   1c3c3:	cmpl	$0xa, -0x30(%ebp)
   1c3c7:	jle	0x1c3d5
   1c3c9:	movl	$0x0, 0x94c88(%ebx)
   1c3d3:	jmp	0x1c376
   1c3d5:	movl	%edi, %edx
   1c3d7:	testb	%dl, %dl
   1c3d9:	je	0x1c3f2
   1c3db:	testl	%ecx, %ecx
   1c3dd:	jne	0x1c350
   1c3e3:	movl	$0x1, 0x94c88(%ebx)
   1c3ed:	jmp	0x1c350
   1c3f2:	movl	$0x3f800000, 0x4(%esp)
   1c3fa:	movl	$0x0, (%esp)
   1c401:	calll	0x5f898
   1c406:	movl	0x94c88(%ebx), %edx
   1c40c:	leal	-0x4(%edx), %eax
   1c40f:	cvtsi2sd	%eax, %xmm0
   1c413:	mulsd	0x76ec8, %xmm0
   1c41b:	addsd	0x76930, %xmm0
   1c423:	fstps	-0x98(%ebp)
   1c429:	cvtsd2ss	%xmm0, %xmm0
   1c42d:	ucomiss	-0x98(%ebp), %xmm0
   1c434:	jbe	0x1c44e
   1c436:	leal	0x1(%edx), %eax
   1c439:	movl	%eax, 0x94c88(%ebx)
   1c43f:	movl	$0x0, 0x94c8c(%ebx)
   1c449:	jmp	0x1c350
   1c44e:	movl	$0x0, 0x94c88(%ebx)
   1c458:	movl	$0x1, 0x94c8c(%ebx)
   1c462:	jmp	0x1c37f
   1c467:	movl	0x8(%ebp), %eax
   1c46a:	movl	$0x0, 0xc(%esp)
   1c472:	movl	$0x3f800000, 0x8(%esp)
   1c47a:	movl	$0xffffffff, 0x4(%esp)
   1c482:	movl	%eax, (%esp)
   1c485:	jmp	0x1c4a5
   1c487:	movl	0x8(%ebp), %edx
   1c48a:	movl	$0x0, 0xc(%esp)
   1c492:	movl	$0x3f000000, 0x8(%esp)
   1c49a:	movl	$0x1, 0x4(%esp)
   1c4a2:	movl	%edx, (%esp)
   1c4a5:	calll	0x20d92
   1c4aa:	jmp	0x1bd53
