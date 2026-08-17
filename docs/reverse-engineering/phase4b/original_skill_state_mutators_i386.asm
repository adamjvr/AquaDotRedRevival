   5c944:	xorl	%eax, %eax
   5c946:	pushl	%ebp
   5c947:	movl	%esp, %ebp
   5c949:	movl	$0x0, 0x1d9618
   5c953:	movl	$0x0, 0x1d9620
   5c95d:	movl	$0x0, 0x1d9624
   5c967:	movl	$0x0, 0x1d9628
   5c971:	movl	%eax, 0x1d9600
   5c976:	movl	$0x0, 0x1d961c
   5c980:	movl	$0x0, 0x1d962c
   5c98a:	movb	$0x1, 0x1d9633
   5c991:	movb	$0x1, 0x1d9632
   5c998:	movb	$0x1, 0x1d9630
   5c99f:	movb	$0x1, 0x1d9631
   5c9a6:	movb	$0x1, 0x1d9634
   5c9ad:	movb	$0x1, 0x1d9635
   5c9b4:	movb	$0x1, 0x1d9636
   5c9bb:	movb	$0x1, 0x1d9637
   5c9c2:	movb	$0x1, 0x1d9638
   5c9c9:	movb	$0x1, 0x1d9639
   5c9d0:	movb	$0x0, 0x1d963a
   5c9d7:	movl	%eax, 0x1d9604
   5c9dc:	movl	%eax, 0x1d9608
   5c9e1:	movl	$0x3f800000, 0x1d960c
   5c9eb:	movl	%eax, 0x1d9610
   5c9f0:	movl	$0x0, 0x1d9614
   5c9fa:	leave
   5c9fb:	retl
   5c9fc:	pushl	%ebp
   5c9fd:	movl	%esp, %ebp
   5c9ff:	movl	0x8(%ebp), %eax
   5ca02:	movl	%eax, 0x1d960c
   5ca07:	leave
   5ca08:	retl
   5ca09:	nop
   5ca0a:	pushl	%ebp
   5ca0b:	movl	%esp, %ebp
   5ca0d:	movl	0x8(%ebp), %eax
   5ca10:	movl	%eax, 0x1d9620
   5ca15:	leave
   5ca16:	retl
   5ca17:	nop
   5ca18:	pushl	%ebp
   5ca19:	cvtss2sd	0x1d9600, %xmm0
   5ca21:	movl	%esp, %ebp
   5ca23:	addsd	0x8(%ebp), %xmm0
   5ca28:	incl	0x1d961c
   5ca2e:	cvtsd2ss	%xmm0, %xmm0
   5ca32:	movss	%xmm0, 0x1d9600
   5ca3a:	leave
   5ca3b:	retl
   5ca3c:	pushl	%ebp
   5ca3d:	movl	%esp, %ebp
   5ca3f:	movb	$0x0, 0x1d9633
   5ca46:	leave
   5ca47:	retl
   5ca48:	pushl	%ebp
   5ca49:	movl	%esp, %ebp
   5ca4b:	movb	$0x0, 0x1d9630
   5ca52:	leave
   5ca53:	retl
   5ca54:	pushl	%ebp
   5ca55:	movl	%esp, %ebp
   5ca57:	movb	$0x0, 0x1d9631
   5ca5e:	leave
   5ca5f:	retl
   5ca60:	pushl	%ebp
   5ca61:	movl	%esp, %ebp
   5ca63:	incl	0x1d962c
   5ca69:	leave
   5ca6a:	retl
   5ca6b:	nop
   5ca6c:	pushl	%ebp
   5ca6d:	movl	%esp, %ebp
   5ca6f:	movb	$0x0, 0x1d9632
   5ca76:	leave
   5ca77:	retl
   5ca78:	pushl	%ebp
   5ca79:	movl	%esp, %ebp
   5ca7b:	movb	$0x0, 0x1d9634
   5ca82:	leave
   5ca83:	retl
   5ca84:	pushl	%ebp
   5ca85:	movl	%esp, %ebp
   5ca87:	movb	$0x0, 0x1d9635
   5ca8e:	leave
   5ca8f:	retl
   5ca90:	pushl	%ebp
   5ca91:	movl	%esp, %ebp
   5ca93:	movb	$0x0, 0x1d9636
   5ca9a:	leave
   5ca9b:	retl
   5ca9c:	pushl	%ebp
   5ca9d:	movl	%esp, %ebp
   5ca9f:	movb	$0x0, 0x1d9637
   5caa6:	leave
   5caa7:	retl
   5caa8:	pushl	%ebp
   5caa9:	movl	%esp, %ebp
   5caab:	movl	0x8(%ebp), %eax
   5caae:	movl	%eax, 0x1d9628
   5cab3:	leave
   5cab4:	retl
   5cab5:	nop
   5cab6:	pushl	%ebp
   5cab7:	movl	%esp, %ebp
   5cab9:	movb	$0x0, 0x1d9638
   5cac0:	leave
   5cac1:	retl
   5cac2:	pushl	%ebp
   5cac3:	movl	%esp, %ebp
   5cac5:	incl	0x1d9624
   5cacb:	leave
   5cacc:	retl
   5cacd:	nop
   5cace:	pushl	%ebp
   5cacf:	movl	%esp, %ebp
   5cad1:	subl	$0x28, %esp
   5cad4:	cmpb	$0x0, 0x1d963a
   5cadb:	je	0x5cb09
   5cadd:	movl	$0x0, 0x10(%esp)
   5cae5:	movl	$0x7481c, 0xc(%esp)
   5caed:	movl	$0x74754, 0x8(%esp)
   5caf5:	movl	$0x514, 0x4(%esp)
   5cafd:	movl	$0x74838, (%esp)
   5cb04:	calll	0xf5e8
   5cb09:	movl	$0x0, (%esp)
   5cb10:	movb	$0x1, 0x1d963a
   5cb17:	calll	0x5b050
   5cb1c:	fstps	0x1d9604
   5cb22:	leave
   5cb23:	retl
   5cb24:	pushl	%ebp
   5cb25:	movl	%esp, %ebp
   5cb27:	subl	$0x28, %esp
   5cb2a:	cmpb	$0x0, 0x1d963a
   5cb31:	je	0x5cb97
   5cb33:	movb	$0x0, 0x1d963a
   5cb3a:	movl	$0x0, (%esp)
   5cb41:	calll	0x5b050
   5cb46:	movss	0x1d9604, %xmm0
   5cb4e:	fstps	-0xc(%ebp)
   5cb51:	movss	-0xc(%ebp), %xmm2
   5cb56:	ucomiss	%xmm0, %xmm2
   5cb59:	ja	0x5cb97
   5cb5b:	subss	%xmm2, %xmm0
   5cb5f:	movss	0x1d960c, %xmm1
   5cb67:	movb	$0x0, 0x1d963a
   5cb6e:	addss	0x1d9608, %xmm0
   5cb76:	movss	%xmm0, 0x1d9608
   5cb7e:	movaps	%xmm2, %xmm0
   5cb81:	cmpnltss	%xmm1, %xmm0
   5cb86:	andps	%xmm0, %xmm1
   5cb89:	andnps	%xmm2, %xmm0
   5cb8c:	orps	%xmm1, %xmm0
   5cb8f:	movss	%xmm0, 0x1d960c
   5cb97:	leave
   5cb98:	retl
   5cb99:	nop
   5cb9a:	pushl	%ebp
   5cb9b:	movl	0x1d9614, %edx
