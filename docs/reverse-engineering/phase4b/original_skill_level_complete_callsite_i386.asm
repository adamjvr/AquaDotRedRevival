   285bf:	movl	%esp, %ebp
   285c1:	subl	$0x28, %esp
   285c4:	cmpb	$0x0, 0x951cc
   285cb:	je	0x285d9
   285cd:	movb	$0x1, 0x951cb
   285d4:	jmp	0x28753
   285d9:	calll	0x1aace
   285de:	movl	$0x0, 0x8(%esp)
   285e6:	movl	$0x0, (%esp)
   285ed:	movl	$0x3fe00000, 0x4(%esp)
   285f5:	calll	0x5356c
   285fa:	calll	0x13eba
   285ff:	movl	$0x0, (%esp)
   28606:	calll	0x2de9a
   2860b:	movb	$0x1, 0x81c10
   28612:	movb	$0x1, 0x951c0
   28619:	calll	0x24888
   2861e:	calll	0x248a6
   28623:	calll	0x5b21a
   28628:	calll	0x18050
   2862d:	calll	0x19426
   28632:	movl	$0x0, (%esp)
   28639:	calll	0x1455e
   2863e:	calll	0xc1c6
   28643:	leal	-0x10(%ebp), %eax
   28646:	movl	%eax, 0x4(%esp)
   2864a:	leal	-0xc(%ebp), %eax
   2864d:	movl	%eax, (%esp)
   28650:	calll	0x5f3c2
   28655:	movl	-0x10(%ebp), %eax
   28658:	movl	%eax, (%esp)
   2865b:	calll	0x8d18
   28660:	calll	0x5082a
   28665:	testb	%al, %al
   28667:	jne	0x286f4
   2866d:	calll	0x5067e
   28672:	movl	-0x10(%ebp), %eax
   28675:	testl	%eax, %eax
   28677:	jne	0x2868e
   28679:	movl	$0x3f800000, 0x8(%esp)
   28681:	fstps	0x4(%esp)
   28685:	movl	$0x2e, (%esp)
   2868c:	jmp	0x286ef
   2868e:	cmpl	$0x1, %eax
   28691:	jne	0x286a8
   28693:	movl	$0x3f800000, 0x8(%esp)
   2869b:	fstps	0x4(%esp)
   2869f:	movl	$0x2f, (%esp)
   286a6:	jmp	0x286ef
   286a8:	cmpl	$0x2, %eax
   286ab:	jne	0x286c2
   286ad:	movl	$0x3f800000, 0x8(%esp)
   286b5:	fstps	0x4(%esp)
   286b9:	movl	$0x30, (%esp)
   286c0:	jmp	0x286ef
   286c2:	cmpl	$0x3, %eax
   286c5:	jne	0x286dc
   286c7:	movl	$0x3f800000, 0x8(%esp)
   286cf:	fstps	0x4(%esp)
   286d3:	movl	$0x31, (%esp)
   286da:	jmp	0x286ef
   286dc:	movl	$0x3f800000, 0x8(%esp)
   286e4:	fstps	0x4(%esp)
   286e8:	movl	$0x32, (%esp)
   286ef:	calll	0x5088a
   286f4:	calll	0x9430
   286f9:	movl	$0x0, 0xc(%esp)
   28701:	movl	$0x0, 0x8(%esp)
   28709:	movl	$0xd, 0x4(%esp)
   28711:	movl	$0x0, (%esp)
   28718:	calll	0xaa00
   2871d:	movb	$0x1, 0x951ca
   28724:	movb	$0x0, 0x951c8
   2872b:	movb	$0x0, 0x951c4
