   1cf78:	movl	$0x94b90, %esi
   1cf7d:	imull	$0x1c, 0x8(%ebp), %eax
   1cf81:	movl	$0x5, 0x8(%eax,%esi)
   1cf89:	movl	$0xffffffff, %esi
   1cf8e:	movl	$0x2, 0x94b80(%eax)
   1cf98:	movl	0x8(%ebp), %eax
   1cf9b:	movl	$0x0, 0xc(%esp)
   1cfa3:	movl	$0x3f800000, 0x8(%esp)
   1cfab:	movl	$0xffffffff, 0x4(%esp)
   1cfb3:	movl	%eax, (%esp)
   1cfb6:	calll	0x20d92
