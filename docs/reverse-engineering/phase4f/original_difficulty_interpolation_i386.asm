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
   275a3:	retl
   275a4:	pushl	%ebp
   275a5:	movl	%esp, %ebp
   275a7:	subl	$0x4, %esp
   275aa:	movss	0xc(%ebp), %xmm0
   275af:	movss	0x14(%ebp), %xmm2
   275b4:	movaps	%xmm0, %xmm1
   275b7:	subss	0x10(%ebp), %xmm1
   275bc:	mulss	0x8(%ebp), %xmm1
   275c1:	subss	%xmm1, %xmm0
   275c5:	maxss	%xmm0, %xmm2
   275c9:	movss	%xmm2, -0x4(%ebp)
   275ce:	flds	-0x4(%ebp)
   275d1:	leave
   275d2:	retl
