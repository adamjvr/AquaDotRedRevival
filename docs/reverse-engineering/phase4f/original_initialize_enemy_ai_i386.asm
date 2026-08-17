   19894:	pushl	%ebp
   19895:	movl	%esp, %ebp
   19897:	pushl	%edi
   19898:	pushl	%esi
   19899:	pushl	%ebx
   1989a:	subl	$0x3c, %esp
   1989d:	movl	0x8(%ebp), %eax
   198a0:	testl	%eax, %eax
   198a2:	js	0x198b0
   198a4:	movl	0x1dc058, %edx
   198aa:	cmpl	(%edx), %eax
   198ac:	jl	0x198bc
   198ae:	jmp	0x198b6
   198b0:	movl	0x1dc058, %edx
   198b6:	movl	(%edx), %edx
   198b8:	xorl	%esi, %esi
   198ba:	jmp	0x198c1
   198bc:	leal	0x1(%eax), %edx
   198bf:	movl	%eax, %esi
   198c1:	movl	%edx, -0x34(%ebp)
   198c4:	movl	%esi, %eax
   198c6:	movl	%esi, %ecx
   198c8:	shll	$0x4, %eax
   198cb:	leal	0x94cc0(%eax), %edi
   198d1:	addl	$0x94c80, %eax
   198d6:	shll	$0x5, %ecx
   198d9:	imull	$0xc3c, %esi, %ebx
   198df:	leal	(,%esi,4), %edx
   198e6:	movl	%eax, -0x2c(%ebp)
   198e9:	movl	%ecx, %eax
   198eb:	addl	$0x94c00, %ecx
   198f1:	addl	0x1dc05c, %ebx
   198f7:	subl	%edx, %eax
   198f9:	addl	%esi, %edx
   198fb:	movl	%edi, -0x30(%ebp)
   198fe:	leal	0x94aa0(,%edx,4), %edx
   19905:	leal	0x94b00(%eax), %edi
   1990b:	addl	$0x94b80, %eax
   19910:	movl	%edi, -0x28(%ebp)
   19913:	movl	%eax, -0x24(%ebp)
   19916:	movl	%ecx, -0x20(%ebp)
   19919:	movl	%edx, -0x1c(%ebp)
   1991c:	jmp	0x19af8
   19921:	movl	0xbd0(%ebx), %eax
   19927:	leal	0xbd0(%ebx), %edi
   1992d:	cmpl	$0x4, %eax
   19930:	jne	0x1995e
   19932:	movl	-0x30(%ebp), %eax
   19935:	movl	$0x0, 0x8(%eax)
   1993c:	movl	$0x0, 0xc(%eax)
   19943:	movl	$0x1, (%eax)
   19949:	movl	$0x0, 0xbb8(%ebx)
   19953:	movl	-0x30(%ebp), %edx
   19956:	movl	0x4(%edx), %eax
   19959:	jmp	0x19a81
   1995e:	cmpl	$0x5, %eax
   19961:	jne	0x1996c
   19963:	calll	0x4eca6
   19968:	testb	%al, %al
   1996a:	jne	0x19980
   1996c:	cmpl	$0x6, 0xbd0(%ebx)
   19973:	jne	0x199a9
   19975:	calll	0x4eca6
   1997a:	testb	%al, %al
   1997c:	je	0x199a9
   1997e:	jmp	0x199b9
   19980:	movl	-0x2c(%ebp), %edi
   19983:	movl	$0x0, 0x8(%edi)
   1998a:	movl	$0x0, 0xc(%edi)
   19991:	movl	$0x0, 0xbb8(%ebx)
   1999b:	movl	0x4(%edi), %eax
   1999e:	movl	%eax, 0x8(%esp)
   199a2:	movl	(%edi), %eax
   199a4:	jmp	0x19a6b
   199a9:	cmpl	$0x7, (%edi)
   199ac:	jne	0x199f0
   199ae:	calll	0x4eca6
   199b3:	testb	%al, %al
   199b5:	je	0x199f0
   199b7:	jmp	0x19a00
   199b9:	movl	-0x28(%ebp), %eax
   199bc:	movl	$0x2, (%eax)
   199c2:	movl	$0xffffffff, 0xc(%eax)
   199c9:	movl	$0xffffffff, 0x10(%eax)
   199d0:	movl	$0xffffffff, 0x14(%eax)
   199d7:	movl	$0x0, 0xbb8(%ebx)
   199e1:	movl	-0x28(%ebp), %edx
   199e4:	movl	0x8(%edx), %eax
   199e7:	movl	%eax, 0x8(%esp)
   199eb:	movl	0x4(%edx), %eax
   199ee:	jmp	0x19a6b
   199f0:	movl	(%edi), %eax
   199f2:	cmpl	$0x3, %eax
   199f5:	je	0x19a35
   199f7:	decl	%eax
   199f8:	jne	0x19a87
   199fe:	jmp	0x19a71
   19a00:	movl	-0x24(%ebp), %edi
   19a03:	movl	$0x0, (%edi)
   19a09:	movl	$0xffffffff, 0x18(%edi)
   19a10:	movl	$0x0, 0x14(%edi)
   19a17:	calll	0x1dc870 ## symbol stub for: _SWGetMicroseconds
   19a1c:	fstpl	0x4(%edi)
   19a1f:	movl	$0x0, 0xbb8(%ebx)
   19a29:	movl	0x10(%edi), %eax
   19a2c:	movl	%eax, 0x8(%esp)
   19a30:	movl	0xc(%edi), %eax
   19a33:	jmp	0x19a6b
   19a35:	movl	-0x20(%ebp), %eax
   19a38:	movl	$0x0, (%eax)
   19a3e:	calll	0x1dc870 ## symbol stub for: _SWGetMicroseconds
   19a43:	movl	-0x20(%ebp), %edx
   19a46:	movl	$0x3e7, 0x14(%edx)
   19a4d:	movl	$0x3e7, 0x18(%edx)
   19a54:	fstpl	0x4(%edx)
   19a57:	movl	$0x0, 0xbb8(%ebx)
   19a61:	movl	0x10(%edx), %eax
   19a64:	movl	%eax, 0x8(%esp)
   19a68:	movl	0xc(%edx), %eax
   19a6b:	movl	%eax, 0x4(%esp)
   19a6f:	jmp	0x19ab1
   19a71:	movl	$0x0, 0xbb8(%ebx)
   19a7b:	movl	-0x1c(%ebp), %edi
   19a7e:	movl	0xc(%edi), %eax
   19a81:	movl	%eax, 0x8(%esp)
   19a85:	jmp	0x19aa9
   19a87:	movl	$0x3d75c28f, 0x4(%esp)
   19a8f:	movl	$0x3ca3d70a, (%esp)
   19a96:	calll	0x5f898
   19a9b:	fstps	0xbb8(%ebx)
   19aa1:	movl	$0x40100000, 0x8(%esp)
   19aa9:	movl	$0x3f800000, 0x4(%esp)
   19ab1:	movl	%esi, (%esp)
   19ab4:	addl	$0xc3c, %ebx
   19aba:	calll	0x20cf6
   19abf:	movl	%esi, (%esp)
   19ac2:	incl	%esi
   19ac3:	movl	$0x0, 0xc(%esp)
   19acb:	movl	$0x3f800000, 0x8(%esp)
   19ad3:	movl	$0xffffffff, 0x4(%esp)
   19adb:	calll	0x20d92
   19ae0:	addl	$0x10, -0x30(%ebp)
   19ae4:	addl	$0x10, -0x2c(%ebp)
   19ae8:	addl	$0x1c, -0x28(%ebp)
   19aec:	addl	$0x1c, -0x24(%ebp)
   19af0:	addl	$0x20, -0x20(%ebp)
   19af4:	addl	$0x14, -0x1c(%ebp)
   19af8:	cmpl	%esi, -0x34(%ebp)
   19afb:	jg	0x19921
   19b01:	addl	$0x3c, %esp
   19b04:	popl	%ebx
   19b05:	popl	%esi
   19b06:	popl	%edi
   19b07:	leave
   19b08:	retl
