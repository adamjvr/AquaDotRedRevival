   2712c:	pushl	%ebp
   2712d:	movl	%esp, %ebp
   2712f:	subl	$0x28, %esp
   27132:	movss	0x8(%ebp), %xmm2
   27137:	xorps	%xmm3, %xmm3
   2713a:	movaps	%xmm2, %xmm0
   2713d:	subss	0x95224, %xmm0
   27145:	subss	0x951d4, %xmm0
   2714d:	movss	%xmm0, -0xc(%ebp)
   27152:	movaps	%xmm3, %xmm0
   27155:	maxss	%xmm2, %xmm0
   27159:	cvtss2sd	%xmm0, %xmm1
   2715d:	movaps	%xmm0, %xmm2
   27160:	mulsd	0x77008, %xmm1
   27168:	cvtss2sd	-0xc(%ebp), %xmm0
   2716d:	ucomisd	%xmm0, %xmm1
   27171:	jbe	0x2717c
   27173:	cvtsd2ss	%xmm1, %xmm1
   27177:	movss	%xmm1, -0xc(%ebp)
   2717c:	maxss	-0xc(%ebp), %xmm3
   27181:	movss	%xmm2, 0x81c28
   27189:	movss	%xmm3, -0xc(%ebp)
   2718e:	movss	%xmm3, (%esp)
   27193:	calll	0x131b0
   27198:	movss	-0xc(%ebp), %xmm0
   2719d:	movss	%xmm0, (%esp)
   271a2:	calll	0x20418
   271a7:	movss	-0xc(%ebp), %xmm0
   271ac:	movss	%xmm0, (%esp)
   271b1:	calll	0x1afe8
   271b6:	movss	-0xc(%ebp), %xmm0
   271bb:	movss	%xmm0, (%esp)
   271c0:	calll	0x19b66
   271c5:	movss	-0xc(%ebp), %xmm0
   271ca:	movss	%xmm0, (%esp)
   271cf:	calll	0x1846c
   271d4:	movss	-0xc(%ebp), %xmm0
   271d9:	movss	%xmm0, (%esp)
   271de:	calll	0x3198c
   271e3:	movss	-0xc(%ebp), %xmm0
   271e8:	movss	%xmm0, (%esp)
   271ed:	calll	0x406ea
   271f2:	movss	-0xc(%ebp), %xmm0
   271f7:	movss	%xmm0, (%esp)
   271fc:	calll	0x2dff2
   27201:	movss	-0xc(%ebp), %xmm0
   27206:	movss	%xmm0, (%esp)
   2720b:	calll	0x19796
   27210:	movss	-0xc(%ebp), %xmm0
   27215:	movss	%xmm0, 0x8(%ebp)
   2721a:	leave
   2721b:	jmp	0x1aa9c
   27220:	pushl	%ebp
   27221:	movl	%esp, %ebp
   27223:	pushl	%ebx
   27224:	subl	$0x1a4, %esp
   2722a:	calll	0x38c44
   2722f:	movss	0x95224, %xmm0
   27237:	movl	$0x0, 0x951d0
   27241:	addss	0x951d4, %xmm0
   27249:	leal	-0x1(%eax), %ebx
   2724c:	movss	%xmm0, 0x95224
   27254:	cvtss2sd	%xmm0, %xmm0
   27258:	ucomisd	0x76ff0, %xmm0
   27260:	jbe	0x2726c
   27262:	movl	$0x3f19999a, 0x95224
   2726c:	leal	-0x190(%ebp), %eax
   27272:	movl	%eax, (%esp)
   27275:	calll	0x4a0a8
   2727a:	movl	-0x24(%ebp), %eax
   2727d:	cmpl	$0x2, %eax
   27280:	jne	0x272b6
   27282:	cvtss2sd	0x95224, %xmm0
   2728a:	ucomisd	0x76e68, %xmm0
   27292:	ja	0x27296
   27294:	jnp	0x272eb
   27296:	ucomisd	0x77138, %xmm0
   2729e:	ja	0x272ac
   272a0:	jp	0x272ac
   272a2:	subsd	0x76e68, %xmm0
   272aa:	jmp	0x2732b
   272ac:	subsd	0x76970, %xmm0
   272b4:	jmp	0x2732b
   272b6:	decl	%eax
   272b7:	jne	0x272d7
   272b9:	cvtss2sd	0x95224, %xmm0
   272c1:	ucomisd	0x76ef8, %xmm0
   272c9:	ja	0x272cd
   272cb:	jnp	0x272eb
   272cd:	ucomisd	0x77140, %xmm0
   272d5:	jmp	0x272ff
   272d7:	cvtss2sd	0x95224, %xmm0
   272df:	ucomisd	0x76ef8, %xmm0
   272e7:	ja	0x272f7
   272e9:	jp	0x272f7
   272eb:	movl	$0x0, 0x95224
   272f5:	jmp	0x27337
   272f7:	ucomisd	0x77148, %xmm0
   272ff:	ja	0x2730d
   27301:	jp	0x2730d
   27303:	subsd	0x76ef8, %xmm0
   2730b:	jmp	0x2732b
   2730d:	ucomisd	0x77138, %xmm0
   27315:	ja	0x27323
   27317:	jp	0x27323
   27319:	subsd	0x76ad8, %xmm0
   27321:	jmp	0x2732b
   27323:	subsd	0x76e70, %xmm0
   2732b:	cvtsd2ss	%xmm0, %xmm0
   2732f:	movss	%xmm0, 0x95224
   27337:	movl	$0x0, 0x951d4
   27341:	calll	0x4eca6
   27346:	testb	%al, %al
   27348:	jne	0x27399
   2734a:	calll	0x10ad0
   2734f:	xorl	%edx, %edx
   27351:	testb	%al, %al
   27353:	cmovel	-0x24(%ebp), %edx
   27357:	cmpl	$0x1, %ebx
   2735a:	movl	%edx, -0x24(%ebp)
   2735d:	jne	0x2736b
   2735f:	movl	$0x1, (%esp)
   27366:	calll	0xc1dc
   2736b:	calll	0xc270
   27370:	testb	%al, %al
   27372:	je	0x27399
   27374:	movl	-0x24(%ebp), %ecx
   27377:	cmpl	$0x2, %ecx
   2737a:	jne	0x27384
   2737c:	leal	(%ebx,%ebx), %edx
   2737f:	leal	(%ebx,%ebx,2), %eax
   27382:	jmp	0x2738f
   27384:	leal	0x4(%ebx,%ebx), %edx
   27388:	leal	(,%ebx,4), %eax
   2738f:	cmpl	$0x2, %ebx
   27392:	movl	%edx, %ebx
   27394:	cmovgl	%eax, %ebx
   27397:	jmp	0x2739c
   27399:	movl	-0x24(%ebp), %ecx
   2739c:	testl	%ebx, %ebx
   2739e:	movl	$0x0, %eax
   273a3:	cmovsl	%eax, %ebx
   273a6:	cmpl	$0x2, %ecx
   273a9:	jne	0x273c1
   273ab:	cvtsi2sd	%ebx, %xmm0
   273af:	mulsd	0x76ad8, %xmm0
   273b7:	addsd	0x77018, %xmm0
   273bf:	jmp	0x2741a
   273c1:	decl	%ecx
   273c2:	jne	0x273f0
   273c4:	cmpl	$0x7, %ebx
   273c7:	jg	0x273df
   273c9:	cvtsi2sd	%ebx, %xmm0
   273cd:	mulsd	0x76ad8, %xmm0
   273d5:	addsd	0x76970, %xmm0
   273dd:	jmp	0x2741a
   273df:	leal	-0x7(%ebx), %eax
   273e2:	cvtsi2sd	%eax, %xmm0
   273e6:	mulsd	0x76ef8, %xmm0
   273ee:	jmp	0x27412
   273f0:	cmpl	$0x14, %ebx
   273f3:	jg	0x27403
   273f5:	cvtsi2sd	%ebx, %xmm0
   273f9:	mulsd	0x76ef8, %xmm0
   27401:	jmp	0x2741a
   27403:	leal	-0x14(%ebx), %eax
   27406:	cvtsi2sd	%eax, %xmm0
   2740a:	mulsd	0x76ee8, %xmm0
   27412:	addsd	0x76930, %xmm0
   2741a:	cvtsd2ss	%xmm0, %xmm0
   2741e:	movss	%xmm0, (%esp)
   27423:	calll	0x2712c
   27428:	addl	$0x1a4, %esp
   2742e:	popl	%ebx
   2742f:	leave
   27430:	retl
   27431:	nop
   27432:	pushl	%ebp
   27433:	flds	0x95224
   27439:	movl	%esp, %ebp
   2743b:	leave
   2743c:	retl
   2743d:	nop
   2743e:	pushl	%ebp
   2743f:	flds	0x951d4
   27445:	movl	%esp, %ebp
   27447:	leave
   27448:	retl
   27449:	nop
   2744a:	pushl	%ebp
   2744b:	movl	%esp, %ebp
   2744d:	movss	0x8(%ebp), %xmm1
   27452:	ucomiss	0x76980, %xmm1
   27459:	jae	0x27462
   2745b:	jp	0x27462
   2745d:	xorps	%xmm1, %xmm1
   27460:	jmp	0x27478
   27462:	cvtss2sd	%xmm1, %xmm0
   27466:	ucomisd	0x76ff0, %xmm0
   2746e:	jbe	0x27478
   27470:	movss	0x76ea8, %xmm1
   27478:	movss	%xmm1, 0x95224
   27480:	flds	0x77188
   27486:	leave
   27487:	retl
   27488:	pushl	%ebp
   27489:	movl	%esp, %ebp
   2748b:	movss	0x8(%ebp), %xmm1
   27490:	ucomiss	0x76980, %xmm1
   27497:	jae	0x274a0
   27499:	jp	0x274a0
   2749b:	xorps	%xmm1, %xmm1
   2749e:	jmp	0x274b6
   274a0:	cvtss2sd	%xmm1, %xmm0
   274a4:	ucomisd	0x76ff0, %xmm0
   274ac:	jbe	0x274b6
   274ae:	movss	0x76ea8, %xmm1
   274b6:	movss	%xmm1, 0x951d4
   274be:	flds	0x77188
   274c4:	leave
   274c5:	retl
   274c6:	pushl	%ebp
   274c7:	movl	%esp, %ebp
   274c9:	subl	$0x28, %esp
   274cc:	movl	0x951d0, %eax
   274d1:	testl	%eax, %eax
   274d3:	jne	0x27503
   274d5:	movl	$0x0, 0x10(%esp)
   274dd:	movl	$0x6d7f4, 0xc(%esp)
   274e5:	movl	$0x6d80c, 0x8(%esp)
   274ed:	movl	$0x1f5, 0x4(%esp)
   274f5:	movl	$0x6d885, (%esp)
   274fc:	calll	0xf5e8
   27501:	jmp	0x27559
   27503:	cmpl	$0x1, %eax
   27506:	jne	0x27514
   27508:	movl	$0x3d4ccccd, 0x951d4
   27512:	jmp	0x27559
   27514:	cmpl	$0x2, %eax
   27517:	jne	0x27525
   27519:	movl	$0x3e800000, 0x951d4
   27523:	jmp	0x27559
   27525:	cmpl	$0x3, %eax
   27528:	jne	0x27536
   2752a:	movl	$0x3ee66666, 0x951d4
   27534:	jmp	0x27559
   27536:	subl	$0x3, %eax
   27539:	cvtsi2sd	%eax, %xmm0
   2753d:	mulsd	0x76e70, %xmm0
   27545:	addsd	0x76e60, %xmm0
   2754d:	cvtsd2ss	%xmm0, %xmm0
   27551:	movss	%xmm0, 0x951d4
   27559:	movl	0x81c28, %eax
   2755e:	movl	%eax, (%esp)
   27561:	calll	0x2712c
   27566:	leave
   27567:	retl
   27568:	pushl	%ebp
   27569:	flds	0x81c28
   2756f:	movl	%esp, %ebp
   27571:	leave
   27572:	retl
   27573:	nop
   27574:	pushl	%ebp
   27575:	movl	%esp, %ebp
   27577:	subl	$0x4, %esp
   2757a:	movss	0xc(%ebp), %xmm0
   2757f:	movss	0x10(%ebp), %xmm1
   27584:	movss	0x14(%ebp), %xmm2
   27589:	subss	%xmm0, %xmm1
   2758d:	mulss	0x8(%ebp), %xmm1
   27592:	addss	%xmm1, %xmm0
   27596:	minss	%xmm0, %xmm2
   2759a:	movss	%xmm2, -0x4(%ebp)
   2759f:	flds	-0x4(%ebp)
   275a2:	leave
