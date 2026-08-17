   1c7a4:	movl	-0xb0(%ebp), %edx
   1c7aa:	movl	$0x0, 0x4(%esp)
   1c7b2:	movl	%edx, (%esp)
   1c7b5:	calll	0x3377a
   1c7ba:	imull	$0x1c, 0x8(%ebp), %ebx
   1c7be:	movl	0x94b80(%ebx), %eax
   1c7c4:	testl	%eax, %eax
   1c7c6:	jne	0x1c80d
   1c7c8:	jmp	0x1c7e1
   1c7ca:	cmpl	$0x3, %esi
   1c7cd:	je	0x1c8c8
   1c7d3:	cmpl	$0xc, %esi
   1c7d6:	jne	0x1cdeb
   1c7dc:	jmp	0x1cd95
   1c7e1:	movl	0xc(%ebp), %eax
   1c7e4:	movl	-0xb0(%ebp), %edx
   1c7ea:	movl	%eax, 0x10(%esp)
   1c7ee:	movl	0x14(%ebp), %eax
   1c7f1:	movl	%edx, 0xc(%esp)
   1c7f5:	movl	0x10(%ebp), %edx
   1c7f8:	movl	%eax, 0x8(%esp)
   1c7fc:	movl	0x8(%ebp), %eax
   1c7ff:	movl	%edx, 0x4(%esp)
   1c803:	movl	%eax, (%esp)
   1c806:	calll	0x1b094
   1c80b:	jmp	0x1c871
   1c80d:	decl	%eax
   1c80e:	movl	$0xffffffff, %esi
   1c813:	jne	0x1c873
   1c815:	calll	0x13f00
   1c81a:	testb	%al, %al
   1c81c:	je	0x1cf78
   1c822:	movl	0x94b94(%ebx), %eax
   1c828:	movl	$0x94b90, %esi
   1c82d:	testl	%eax, %eax
   1c82f:	jle	0x1c853
   1c831:	cvtsi2sd	%eax, %xmm0
   1c835:	mulsd	0x76ef8, %xmm0
   1c83d:	cvtsd2ss	%xmm0, %xmm0
   1c841:	movss	%xmm0, (%esp)
   1c846:	calll	0x5f86e
   1c84b:	testb	%al, %al
   1c84d:	jne	0x1cf7d
   1c853:	movl	0xc(%ebp), %edx
   1c856:	movl	0x14(%ebp), %eax
   1c859:	movl	0x10(%ebp), %ecx
   1c85c:	movl	%edx, 0x4(%esp)
   1c860:	movl	-0xb0(%ebp), %edx
   1c866:	movl	%eax, (%esp)
   1c869:	movl	0x8(%ebp), %eax
   1c86c:	calll	0x1bb6e
   1c871:	movl	%eax, %esi
   1c873:	imull	$0x1c, 0x8(%ebp), %ebx
   1c877:	cmpl	$0x2, 0x94b80(%ebx)
   1c87e:	jne	0x1c8b3
   1c880:	movl	0xc(%ebp), %edx
   1c883:	movl	0x14(%ebp), %ecx
   1c886:	movl	-0xb0(%ebp), %eax
   1c88c:	decl	0x94b98(%ebx)
   1c892:	movl	%edx, (%esp)
   1c895:	movl	0x10(%ebp), %edx
   1c898:	calll	0x1b478
   1c89d:	movl	%eax, %esi
   1c89f:	movl	0x94b98(%ebx), %eax
   1c8a5:	testl	%eax, %eax
   1c8a7:	jns	0x1c8b3
   1c8a9:	movl	$0x0, 0x94b80(%ebx)
   1c8b3:	movl	$0x1, 0x4(%esp)
