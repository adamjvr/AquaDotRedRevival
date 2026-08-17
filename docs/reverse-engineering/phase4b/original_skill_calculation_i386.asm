   5f3c2:	pushl	%ebp
   5f3c3:	movl	%esp, %ebp
   5f3c5:	pushl	%ebx
   5f3c6:	subl	$0x34, %esp
   5f3c9:	calll	0x27568
   5f3ce:	fstps	-0x10(%ebp)
   5f3d1:	calll	0x2dfe8
   5f3d6:	movl	%eax, %ebx
   5f3d8:	movl	0x1d961c, %eax
   5f3dd:	testl	%eax, %eax
   5f3df:	jg	0x5f3eb
   5f3e1:	xorps	%xmm0, %xmm0
   5f3e4:	movss	%xmm0, -0xc(%ebp)
   5f3e9:	jmp	0x5f400
   5f3eb:	cvtsi2ss	%eax, %xmm0
   5f3ef:	movss	0x1d9600, %xmm1
   5f3f7:	divss	%xmm0, %xmm1
   5f3fb:	movss	%xmm1, -0xc(%ebp)
   5f400:	calll	0x2dfde
   5f405:	movl	$0x1, (%esp)
   5f40c:	movl	%eax, 0x1d9620
   5f411:	calll	0x5b050
   5f416:	cmpb	$0x0, 0x1d963a
   5f41d:	fstps	0x1d9610
   5f423:	je	0x5f482
   5f425:	movb	$0x0, 0x1d963a
   5f42c:	movl	$0x0, (%esp)
   5f433:	calll	0x5b050
   5f438:	movss	0x1d9604, %xmm0
   5f440:	fstps	-0x1c(%ebp)
   5f443:	movss	-0x1c(%ebp), %xmm1
   5f448:	ucomiss	%xmm0, %xmm1
   5f44b:	ja	0x5f482
   5f44d:	subss	%xmm1, %xmm0
   5f451:	movss	0x1d960c, %xmm4
   5f459:	movb	$0x0, 0x1d963a
   5f460:	addss	0x1d9608, %xmm0
   5f468:	ucomiss	%xmm1, %xmm4
   5f46b:	movss	%xmm0, 0x1d9608
   5f473:	jbe	0x5f48a
   5f475:	movaps	%xmm1, %xmm4
   5f478:	movss	%xmm1, 0x1d960c
   5f480:	jmp	0x5f48a
   5f482:	movss	0x1d960c, %xmm4
   5f48a:	cmpl	$0x3, %ebx
   5f48d:	jle	0x5f4fb
   5f48f:	movl	0x1d9620, %eax
   5f494:	cvtsi2sd	%ebx, %xmm1
   5f498:	movsd	0x77178, %xmm0
   5f4a0:	divsd	%xmm1, %xmm0
   5f4a4:	cvtsd2ss	%xmm0, %xmm0
   5f4a8:	cmpl	$0x1, %eax
   5f4ab:	jne	0x5f4b7
   5f4ad:	mulss	0x76aec, %xmm0
   5f4b5:	jmp	0x5f4e2
   5f4b7:	cmpl	$0x2, %eax
   5f4ba:	jne	0x5f4d5
   5f4bc:	movss	0x76998, %xmm7
   5f4c4:	mulss	%xmm7, %xmm0
   5f4c8:	addss	0x76980, %xmm0
   5f4d0:	jmp	0x5f567
   5f4d5:	cmpl	$0x3, %eax
   5f4d8:	jne	0x5f4ec
   5f4da:	mulss	0x774a4, %xmm0
   5f4e2:	addss	0x76980, %xmm0
   5f4ea:	jmp	0x5f55f
   5f4ec:	cmpl	$0x4, %eax
   5f4ef:	jne	0x5f55c
   5f4f1:	mulss	0x77340, %xmm0
   5f4f9:	jmp	0x5f4e2
   5f4fb:	jne	0x5f525
   5f4fd:	movl	0x1d9620, %eax
   5f502:	cmpl	$0x1, %eax
   5f505:	jne	0x5f511
   5f507:	movss	0x77494, %xmm0
   5f50f:	jmp	0x5f55f
   5f511:	cmpl	$0x2, %eax
   5f514:	jne	0x5f520
   5f516:	movss	0x774a0, %xmm0
   5f51e:	jmp	0x5f55f
   5f520:	cmpl	$0x3, %eax
   5f523:	jmp	0x5f550
   5f525:	cmpl	$0x2, %ebx
   5f528:	jne	0x5f546
   5f52a:	movl	0x1d9620, %eax
   5f52f:	cmpl	$0x1, %eax
   5f532:	jne	0x5f541
   5f534:	movss	0x76998, %xmm7
   5f53c:	movaps	%xmm7, %xmm0
   5f53f:	jmp	0x5f567
   5f541:	cmpl	$0x2, %eax
   5f544:	jmp	0x5f550
   5f546:	decl	%ebx
   5f547:	jne	0x5f552
   5f549:	cmpl	$0x1, 0x1d9620
   5f550:	jne	0x5f55c
   5f552:	movss	0x77340, %xmm0
   5f55a:	jmp	0x5f55f
   5f55c:	xorps	%xmm0, %xmm0
   5f55f:	movss	0x76998, %xmm7
   5f567:	movss	-0xc(%ebp), %xmm1
   5f56c:	movss	0x77354, %xmm6
   5f574:	movl	0x1d962c, %eax
   5f579:	mulss	%xmm1, %xmm1
   5f57d:	cmpl	$0x1, %eax
   5f580:	mulss	-0xc(%ebp), %xmm1
   5f585:	mulss	%xmm6, %xmm1
   5f589:	addss	%xmm0, %xmm1
   5f58d:	jne	0x5f599
   5f58f:	addss	0x76aec, %xmm1
   5f597:	jmp	0x5f5bc
   5f599:	cmpl	$0x2, %eax
   5f59c:	jne	0x5f5a4
   5f59e:	addss	%xmm7, %xmm1
   5f5a2:	jmp	0x5f5bc
   5f5a4:	cmpl	$0x3, %eax
   5f5a7:	jne	0x5f5b3
   5f5a9:	addss	0x76990, %xmm1
   5f5b1:	jmp	0x5f5bc
   5f5b3:	cmpl	$0x4, %eax
   5f5b6:	jne	0x5f5bc
   5f5b8:	addss	%xmm6, %xmm1
   5f5bc:	cmpb	$0x0, 0x1d9633
   5f5c3:	je	0x5f5c9
   5f5c5:	addss	%xmm7, %xmm1
   5f5c9:	cmpb	$0x0, 0x1d9632
   5f5d0:	je	0x5f5da
   5f5d2:	addss	0x774a4, %xmm1
   5f5da:	cmpb	$0x0, 0x1d9630
   5f5e1:	je	0x5f60e
   5f5e3:	cvtss2sd	%xmm1, %xmm1
   5f5e7:	cvtss2sd	-0x10(%ebp), %xmm3
   5f5ec:	movsd	0x76930, %xmm5
   5f5f4:	movapd	%xmm3, %xmm0
   5f5f8:	addsd	%xmm5, %xmm0
   5f5fc:	mulsd	0x770c0, %xmm0
   5f604:	addsd	%xmm0, %xmm1
   5f608:	cvtsd2ss	%xmm1, %xmm1
   5f60c:	jmp	0x5f675
   5f60e:	movss	0x1d9608, %xmm0
   5f616:	ucomiss	0x76984, %xmm0
   5f61d:	jae	0x5f668
   5f61f:	jp	0x5f668
   5f621:	cvtss2sd	%xmm0, %xmm0
   5f625:	movsd	0x76930, %xmm5
   5f62d:	cvtss2sd	-0x10(%ebp), %xmm3
   5f632:	movapd	%xmm5, %xmm2
   5f636:	subsd	%xmm0, %xmm2
   5f63a:	movapd	%xmm2, %xmm0
   5f63e:	cvtss2sd	%xmm1, %xmm2
   5f642:	movapd	%xmm0, %xmm1
   5f646:	mulsd	0x770c0, %xmm1
   5f64e:	mulsd	%xmm1, %xmm0
   5f652:	movapd	%xmm3, %xmm1
   5f656:	addsd	%xmm5, %xmm1
   5f65a:	mulsd	%xmm1, %xmm0
   5f65e:	addsd	%xmm0, %xmm2
   5f662:	cvtsd2ss	%xmm2, %xmm1
   5f666:	jmp	0x5f675
   5f668:	cvtss2sd	-0x10(%ebp), %xmm3
   5f66d:	movsd	0x76930, %xmm5
   5f675:	mulss	%xmm4, %xmm4
   5f679:	movapd	%xmm3, %xmm2
   5f67d:	cvtss2sd	%xmm1, %xmm1
   5f681:	cmpb	$0x0, 0x1d9631
   5f688:	addsd	%xmm5, %xmm2
   5f68c:	mulss	%xmm6, %xmm4
   5f690:	cvtss2sd	%xmm4, %xmm0
   5f694:	mulsd	%xmm2, %xmm0
   5f698:	addsd	%xmm0, %xmm1
   5f69c:	cvtsd2ss	%xmm1, %xmm1
   5f6a0:	je	0x5f6aa
   5f6a2:	addss	0x774a4, %xmm1
   5f6aa:	movss	0x1d9610, %xmm0
   5f6b2:	cvtss2sd	%xmm1, %xmm1
   5f6b6:	movss	0x774a8, %xmm3
   5f6be:	cmpb	$0x0, 0x1d9634
   5f6c5:	mulss	%xmm0, %xmm0
   5f6c9:	mulss	%xmm3, %xmm0
   5f6cd:	cvtss2sd	%xmm0, %xmm0
   5f6d1:	mulsd	%xmm2, %xmm0
   5f6d5:	addsd	%xmm0, %xmm1
   5f6d9:	cvtsd2ss	%xmm1, %xmm0
   5f6dd:	je	0x5f6e3
   5f6df:	addss	%xmm3, %xmm0
   5f6e3:	cmpb	$0x0, 0x1d9635
   5f6ea:	je	0x5f6f4
   5f6ec:	addss	0x774a0, %xmm0
   5f6f4:	cmpb	$0x0, 0x1d9639
   5f6fb:	je	0x5f705
   5f6fd:	addss	0x774a0, %xmm0
   5f705:	cmpb	$0x0, 0x1d9638
   5f70c:	je	0x5f718
   5f70e:	addss	0x76aec, %xmm0
   5f716:	jmp	0x5f74f
   5f718:	cmpl	$0x1, 0x1d9628
   5f71f:	jne	0x5f72b
   5f721:	addss	0x77340, %xmm0
   5f729:	jmp	0x5f731
   5f72b:	jle	0x5f731
   5f72d:	addss	%xmm6, %xmm0
   5f731:	cmpb	$0x0, 0x1d9636
   5f738:	je	0x5f73e
   5f73a:	addss	%xmm7, %xmm0
   5f73e:	cmpb	$0x0, 0x1d9637
   5f745:	je	0x5f74f
   5f747:	addss	0x774a4, %xmm0
   5f74f:	movl	0x1d9624, %eax
   5f754:	mulss	%xmm7, %xmm0
   5f758:	testl	%eax, %eax
   5f75a:	je	0x5f78e
   5f75c:	cmpl	$0x1, %eax
   5f75f:	jne	0x5f76f
   5f761:	cvtss2sd	%xmm0, %xmm0
   5f765:	mulsd	0x77180, %xmm0
   5f76d:	jmp	0x5f78a
   5f76f:	cmpl	$0x2, %eax
   5f772:	jne	0x5f77e
   5f774:	mulss	0x76988, %xmm0
   5f77c:	jmp	0x5f78e
   5f77e:	cvtss2sd	%xmm0, %xmm0
   5f782:	mulsd	0x76e70, %xmm0
   5f78a:	cvtsd2ss	%xmm0, %xmm0
   5f78e:	cvtss2sd	%xmm0, %xmm0
   5f792:	mulsd	%xmm2, %xmm0
   5f796:	cvtsd2ss	%xmm0, %xmm1
   5f79a:	ucomiss	0x772b8, %xmm1
   5f7a1:	jae	0x5f7b1
   5f7a3:	jp	0x5f7b1
   5f7a5:	movl	$0x0, 0x1d9614
   5f7af:	jmp	0x5f7f7
   5f7b1:	ucomiss	0x774ac, %xmm1
   5f7b8:	jae	0x5f7c8
   5f7ba:	jp	0x5f7c8
   5f7bc:	movl	$0x1, 0x1d9614
   5f7c6:	jmp	0x5f7f7
   5f7c8:	ucomiss	0x774b0, %xmm1
   5f7cf:	jae	0x5f7df
   5f7d1:	jp	0x5f7df
   5f7d3:	movl	$0x2, 0x1d9614
   5f7dd:	jmp	0x5f7f7
   5f7df:	movss	0x774b4, %xmm0
   5f7e7:	xorl	%eax, %eax
   5f7e9:	ucomiss	%xmm1, %xmm0
   5f7ec:	setbe	%al
   5f7ef:	addl	$0x3, %eax
   5f7f2:	movl	%eax, 0x1d9614
   5f7f7:	movl	0x1d9614, %edx
   5f7fd:	movl	0xc(%ebp), %eax
   5f800:	movl	%edx, (%eax)
   5f802:	movss	%xmm1, (%esp)
   5f807:	calll	0x1dcba4 ## symbol stub for: _floorf
   5f80c:	movl	0x8(%ebp), %eax
   5f80f:	fstps	-0x14(%ebp)
   5f812:	cvttss2si	-0x14(%ebp), %edx
   5f817:	movl	%edx, (%eax)
   5f819:	movl	%edx, 0x1d9618
   5f81f:	addl	$0x34, %esp
   5f822:	popl	%ebx
   5f823:	leave
   5f824:	retl
   5f825:	nop
   5f826:	pushl	%ebp
   5f827:	movl	%esp, %ebp
   5f829:	subl	$0x8, %esp
