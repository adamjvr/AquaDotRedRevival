   1c4af:	movl	-0xb0(%ebp), %eax
   1c4b5:	movl	$0xffffffff, %esi
   1c4ba:	movl	$0x0, 0x4(%esp)
   1c4c2:	movl	%eax, (%esp)
   1c4c5:	calll	0x3377a
   1c4ca:	imull	$0x1c, 0x8(%ebp), %eax
   1c4ce:	cmpl	$0x3, 0x94b00(%eax)
   1c4d5:	jne	0x1c5fc
   1c4db:	jmp	0x1c4f8
   1c4dd:	cmpl	$0x7, %esi
   1c4e0:	jne	0x1c7ca
   1c4e6:	calll	0x4eca6
   1c4eb:	testb	%al, %al
   1c4ed:	je	0x1cf0b
   1c4f3:	jmp	0x1c7a4
   1c4f8:	imull	$0x1c, 0x8(%ebp), %ebx
   1c4fc:	movl	0x94b0c(%ebx), %eax
   1c502:	decl	%eax
   1c503:	testl	%eax, %eax
   1c505:	movl	%eax, 0x94b0c(%ebx)
   1c50b:	jns	0x1c544
   1c50d:	movl	0x8(%ebp), %edx
   1c510:	movl	$0xffffffff, %esi
   1c515:	movl	$0x2, 0x94b00(%ebx)
   1c51f:	movl	$0x0, 0xc(%esp)
   1c527:	movl	$0x40000000, 0x8(%esp)
   1c52f:	movl	$0xffffffff, 0x4(%esp)
   1c537:	movl	%edx, (%esp)
   1c53a:	calll	0x20d92
   1c53f:	jmp	0x1c5fc
   1c544:	movl	0xc(%ebp), %eax
   1c547:	movl	0x14(%ebp), %edx
   1c54a:	movl	0x10(%ebp), %ecx
   1c54d:	movl	%eax, 0x4(%esp)
   1c551:	movl	0x8(%ebp), %eax
   1c554:	movl	%edx, (%esp)
   1c557:	movl	-0xb0(%ebp), %edx
   1c55d:	calll	0x1bb6e
   1c562:	cmpl	%eax, -0xb0(%ebp)
   1c568:	movl	%eax, %esi
   1c56a:	je	0x1c5fc
   1c570:	cvtsi2sdl	0x94b0c(%ebx), %xmm0
   1c578:	mulsd	0x76ef0, %xmm0
   1c580:	addsd	0x76970, %xmm0
   1c588:	cvtsd2ss	%xmm0, %xmm0
   1c58c:	movss	%xmm0, (%esp)
   1c591:	calll	0x5f86e
   1c596:	testb	%al, %al
   1c598:	je	0x1c5fc
   1c59a:	movl	-0xb0(%ebp), %eax
   1c5a0:	movl	%eax, (%esp)
   1c5a3:	calll	0x13484
   1c5a8:	movl	-0xb0(%ebp), %edx
   1c5ae:	movl	%edx, 0x8(%esp)
   1c5b2:	movl	0x10(%ebp), %edx
   1c5b5:	movl	%eax, 0xc(%esp)
   1c5b9:	movl	0x14(%ebp), %eax
   1c5bc:	movl	%edx, (%esp)
   1c5bf:	movl	%eax, 0x4(%esp)
   1c5c3:	calll	0x1b5f4
   1c5c8:	movl	$0x0, 0xc(%esp)
   1c5d0:	movl	$0x40000000, 0x8(%esp)
   1c5d8:	movl	$0xffffffff, 0x4(%esp)
   1c5e0:	movl	%eax, %esi
   1c5e2:	movl	0x8(%ebp), %eax
   1c5e5:	movl	%eax, (%esp)
   1c5e8:	calll	0x20d92
   1c5ed:	movl	$0x2, 0x94b00(%ebx)
   1c5f7:	jmp	0x1bd53
   1c5fc:	imull	$0x1c, 0x8(%ebp), %edx
   1c600:	movl	0x94b00(%edx), %eax
   1c606:	testl	%eax, %eax
   1c608:	jne	0x1c696
   1c60e:	movl	0x94b10(%edx), %ecx
   1c614:	cmpl	%ecx, 0x10(%ebp)
   1c617:	jne	0x1c647
   1c619:	movl	0x14(%ebp), %eax
   1c61c:	cmpl	0x94b14(%edx), %eax
   1c622:	jne	0x1c647
   1c624:	movl	$0x94b10, %eax
   1c629:	movl	$0xffffffff, 0x94b10(%edx)
   1c633:	movl	$0xffffffff, 0x4(%edx,%eax)
   1c63b:	movl	$0x1, 0x94b00(%edx)
   1c645:	jmp	0x1c696
   1c647:	imull	$0x1c, 0x8(%ebp), %ebx
   1c64b:	movl	%ecx, (%esp)
   1c64e:	movl	0x94b14(%ebx), %eax
   1c654:	movl	%eax, 0x4(%esp)
   1c658:	calll	0x350f2
   1c65d:	leal	-0x28(%ebp), %eax
   1c660:	movl	-0xb0(%ebp), %edx
   1c666:	movl	%eax, 0x14(%esp)
   1c66a:	movl	0x94b14(%ebx), %eax
   1c670:	movl	%edx, 0x10(%esp)
   1c674:	movl	0x10(%ebp), %edx
   1c677:	movl	%eax, 0xc(%esp)
   1c67b:	movl	0x94b10(%ebx), %eax
   1c681:	movl	%edx, (%esp)
   1c684:	movl	%eax, 0x8(%esp)
   1c688:	movl	0x14(%ebp), %eax
   1c68b:	movl	%eax, 0x4(%esp)
   1c68f:	calll	0x35646
   1c694:	movl	%eax, %esi
   1c696:	imull	$0x1c, 0x8(%ebp), %edi
   1c69a:	cmpl	$0x1, 0x94b00(%edi)
   1c6a1:	jne	0x1c6e3
   1c6a3:	movl	-0xb0(%ebp), %eax
   1c6a9:	movl	0x14(%ebp), %edx
   1c6ac:	movl	%eax, 0x8(%esp)
   1c6b0:	movl	0x10(%ebp), %eax
   1c6b3:	movl	%edx, 0x4(%esp)
   1c6b7:	movl	%eax, (%esp)
   1c6ba:	calll	0x34fce
   1c6bf:	testl	%eax, %eax
   1c6c1:	movl	%eax, %ebx
   1c6c3:	js	0x1c6d9
   1c6c5:	movl	$0x1, 0x4(%esp)
   1c6cd:	movl	%ebx, %esi
   1c6cf:	movl	%eax, (%esp)
   1c6d2:	calll	0x3377a
   1c6d7:	jmp	0x1c6e3
   1c6d9:	movl	$0x2, 0x94b00(%edi)
   1c6e3:	imull	$0x1c, 0x8(%ebp), %edi
   1c6e7:	cmpl	$0x2, 0x94b00(%edi)
   1c6ee:	jne	0x1c8b3
   1c6f4:	leal	-0x2c(%ebp), %eax
   1c6f7:	movl	%eax, 0x4(%esp)
   1c6fb:	leal	-0x30(%ebp), %eax
   1c6fe:	movl	%eax, (%esp)
   1c701:	calll	0x33cf2
   1c706:	movl	-0x30(%ebp), %ecx
   1c709:	testl	%ecx, %ecx
   1c70b:	js	0x1c714
   1c70d:	movl	-0x2c(%ebp), %edx
   1c710:	testl	%edx, %edx
   1c712:	jns	0x1c743
   1c714:	movl	0xc(%ebp), %edx
   1c717:	movl	-0xb0(%ebp), %eax
   1c71d:	movl	%edx, 0x10(%esp)
   1c721:	movl	0x14(%ebp), %edx
   1c724:	movl	%eax, 0xc(%esp)
   1c728:	movl	0x10(%ebp), %eax
   1c72b:	movl	%edx, 0x8(%esp)
   1c72f:	movl	0x8(%ebp), %edx
   1c732:	movl	%eax, 0x4(%esp)
   1c736:	movl	%edx, (%esp)
   1c739:	calll	0x1b094
   1c73e:	jmp	0x1c266
   1c743:	leal	-0x28(%ebp), %eax
   1c746:	movl	$0x94b10, %ebx
   1c74b:	movl	%eax, 0x14(%esp)
   1c74f:	movl	-0xb0(%ebp), %eax
   1c755:	movl	%edx, 0xc(%esp)
   1c759:	movl	0x14(%ebp), %edx
   1c75c:	movl	%ecx, 0x8(%esp)
   1c760:	movl	%eax, 0x10(%esp)
   1c764:	movl	0x10(%ebp), %eax
   1c767:	movl	%edx, 0x4(%esp)
   1c76b:	movl	%eax, (%esp)
   1c76e:	calll	0x35646
   1c773:	movl	-0x30(%ebp), %edx
   1c776:	movl	%edx, 0x94b10(%edi)
   1c77c:	movl	%eax, %esi
   1c77e:	movl	-0x2c(%ebp), %eax
   1c781:	movl	%eax, 0x4(%edi,%ebx)
   1c785:	movl	%eax, 0x4(%esp)
   1c789:	movl	%edx, (%esp)
   1c78c:	calll	0x350f2
   1c791:	movl	$0x0, 0x94b00(%edi)
   1c79b:	movl	%eax, 0x8(%edi,%ebx)
   1c79f:	jmp	0x1c8b3
