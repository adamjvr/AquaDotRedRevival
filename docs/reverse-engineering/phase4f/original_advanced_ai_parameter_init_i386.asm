   19b66:	pushl	%ebp
   19b67:	movl	%esp, %ebp
   19b69:	pushl	%edi
   19b6a:	movl	$0x94c00, %edi
   19b6f:	pushl	%esi
   19b70:	movl	$0x94b80, %esi
   19b75:	pushl	%ebx
   19b76:	movl	$0x94b00, %ebx
   19b7b:	subl	$0x2c, %esp
   19b7e:	movss	0x76984, %xmm0
   19b86:	movl	$0x94aa0, -0x24(%ebp)
   19b8d:	movl	$0x94cc0, -0x20(%ebp)
   19b94:	movss	%xmm0, -0x28(%ebp)
   19b99:	movl	$0x94c80, -0x1c(%ebp)
   19ba0:	minss	0x8(%ebp), %xmm0
   19ba5:	movss	%xmm0, -0x28(%ebp)
   19baa:	movss	-0x28(%ebp), %xmm0
   19baf:	movl	$0x3f83d70a, 0xc(%esp)
   19bb7:	movl	$0x3f88f5c3, 0x8(%esp)
   19bbf:	movss	%xmm0, (%esp)
   19bc4:	movl	$0x3f8ccccd, 0x4(%esp)
   19bcc:	calll	0x275a4
   19bd1:	movl	-0x24(%ebp), %eax
   19bd4:	fstps	0xc(%eax)
   19bd7:	movss	-0x28(%ebp), %xmm0
   19bdc:	movl	$0x3f83d70a, 0xc(%esp)
   19be4:	movl	$0x3f88f5c3, 0x8(%esp)
   19bec:	movss	%xmm0, (%esp)
   19bf1:	movl	$0x3f8ccccd, 0x4(%esp)
   19bf9:	calll	0x275a4
   19bfe:	movl	-0x20(%ebp), %eax
   19c01:	fstps	0x4(%eax)
   19c04:	movss	-0x28(%ebp), %xmm0
   19c09:	movl	$0x3f000000, 0xc(%esp)
   19c11:	movl	$0x3f000000, 0x8(%esp)
   19c19:	movss	%xmm0, (%esp)
   19c1e:	movl	$0x3f000000, 0x4(%esp)
   19c26:	calll	0x27574
   19c2b:	movl	-0x1c(%ebp), %eax
   19c2e:	fstps	(%eax)
   19c30:	movss	-0x28(%ebp), %xmm0
   19c35:	movl	$0x3fe66666, 0xc(%esp)
   19c3d:	movl	$0x3fcccccd, 0x8(%esp)
   19c45:	movss	%xmm0, (%esp)
   19c4a:	movl	$0x3f8ccccd, 0x4(%esp)
   19c52:	calll	0x27574
   19c57:	movl	-0x1c(%ebp), %eax
   19c5a:	fstps	0x4(%eax)
   19c5d:	movl	$0x3f666666, %eax
   19c62:	movss	-0x28(%ebp), %xmm0
   19c67:	movl	%eax, 0xc(%esp)
   19c6b:	movl	%eax, 0x8(%esp)
   19c6f:	movss	%xmm0, (%esp)
   19c74:	movl	$0x3f4ccccd, 0x4(%esp)
   19c7c:	calll	0x27574
   19c81:	movss	-0x28(%ebp), %xmm0
   19c86:	movl	$0x3f83d70a, 0xc(%esp)
   19c8e:	movl	$0x3f88f5c3, 0x8(%esp)
   19c96:	movss	%xmm0, (%esp)
   19c9b:	movl	$0x3f8ccccd, 0x4(%esp)
   19ca3:	fstps	0xc(%edi)
   19ca6:	calll	0x275a4
   19cab:	movss	-0x28(%ebp), %xmm0
   19cb0:	movl	$0x3f800000, 0xc(%esp)
   19cb8:	movl	$0x3f800000, 0x8(%esp)
   19cc0:	movss	%xmm0, (%esp)
   19cc5:	movl	$0x3f800000, 0x4(%esp)
   19ccd:	fstps	0x10(%edi)
   19cd0:	addl	$0x20, %edi
   19cd3:	calll	0x27574
   19cd8:	movss	-0x28(%ebp), %xmm0
   19cdd:	movl	$0x3f000000, 0xc(%esp)
   19ce5:	movl	$0x3f000000, 0x8(%esp)
   19ced:	movss	%xmm0, (%esp)
   19cf2:	movl	$0x3f000000, 0x4(%esp)
   19cfa:	fstps	0x10(%esi)
   19cfd:	calll	0x27574
   19d02:	movss	-0x28(%ebp), %xmm0
   19d07:	movl	$0x3fb33333, 0xc(%esp)
   19d0f:	movl	$0x3fa66666, 0x8(%esp)
   19d17:	movss	%xmm0, (%esp)
   19d1c:	movl	$0x3f99999a, 0x4(%esp)
   19d24:	fstps	0xc(%esi)
   19d27:	addl	$0x1c, %esi
   19d2a:	calll	0x27574
   19d2f:	movss	-0x28(%ebp), %xmm0
   19d34:	movl	$0x3f19999a, 0xc(%esp)
   19d3c:	movl	$0x3f000000, 0x8(%esp)
   19d44:	movl	$0x3e800000, 0x4(%esp)
   19d4c:	movss	%xmm0, (%esp)
   19d51:	fstps	0x8(%ebx)
   19d54:	calll	0x27574
   19d59:	addl	$0x14, -0x24(%ebp)
   19d5d:	addl	$0x10, -0x20(%ebp)
   19d61:	addl	$0x10, -0x1c(%ebp)
   19d65:	fstps	0x4(%ebx)
   19d68:	addl	$0x1c, %ebx
   19d6b:	cmpl	$0x94af0, -0x24(%ebp)
   19d72:	jne	0x19baa
   19d78:	addl	$0x2c, %esp
   19d7b:	popl	%ebx
   19d7c:	popl	%esi
   19d7d:	popl	%edi
   19d7e:	leave
   19d7f:	retl
