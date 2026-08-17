   20cf6:	pushl	%ebp
   20cf7:	movl	%esp, %ebp
   20cf9:	movss	0xc(%ebp), %xmm2
   20cfe:	pushl	%ebx
   20cff:	movl	0x8(%ebp), %edx
   20d02:	movss	0x10(%ebp), %xmm1
   20d07:	ucomiss	0x76998, %xmm2
   20d0e:	jbe	0x20d1a
   20d10:	movss	0x76998, %xmm2
   20d18:	jmp	0x20d24
   20d1a:	xorps	%xmm0, %xmm0
   20d1d:	maxss	%xmm2, %xmm0
   20d21:	movaps	%xmm0, %xmm2
   20d24:	ucomiss	0x76998, %xmm1
   20d2b:	jbe	0x20d37
   20d2d:	movss	0x76998, %xmm1
   20d35:	jmp	0x20d41
   20d37:	xorps	%xmm0, %xmm0
   20d3a:	maxss	%xmm1, %xmm0
   20d3e:	movaps	%xmm0, %xmm1
   20d41:	testl	%edx, %edx
   20d43:	js	0x20d55
   20d45:	movl	0x1dc058, %eax
   20d4a:	leal	0x1(%edx), %ecx
   20d4d:	movl	%edx, %ebx
   20d4f:	cmpl	(%eax), %edx
   20d51:	jl	0x20d5e
   20d53:	jmp	0x20d5a
   20d55:	movl	0x1dc058, %eax
   20d5a:	movl	(%eax), %ecx
   20d5c:	xorl	%ebx, %ebx
   20d5e:	imull	$0xc3c, %ebx, %edx
   20d64:	movl	0x1dc05c, %eax
   20d69:	leal	0x210(%edx,%eax), %eax
   20d70:	movl	%ebx, %edx
   20d72:	jmp	0x20d85
   20d74:	movss	%xmm2, -0xc3c(%eax)
   20d7c:	incl	%edx
   20d7d:	movss	%xmm1, -0xc38(%eax)
   20d85:	addl	$0xc3c, %eax
   20d8a:	cmpl	%edx, %ecx
   20d8c:	jg	0x20d74
   20d8e:	popl	%ebx
   20d8f:	leave
   20d90:	retl
   20d91:	nop
   20d92:	pushl	%ebp
   20d93:	movl	%esp, %ebp
   20d95:	pushl	%edi
   20d96:	pushl	%esi
   20d97:	pushl	%ebx
   20d98:	subl	$0x1c, %esp
   20d9b:	movl	0x8(%ebp), %ebx
   20d9e:	movzbl	0x14(%ebp), %eax
   20da2:	movl	0xc(%ebp), %edi
   20da5:	movb	%al, -0x19(%ebp)
   20da8:	calll	0x43366
   20dad:	testl	%ebx, %ebx
   20daf:	js	0x20dbc
   20db1:	movl	0x1dc058, %eax
   20db6:	cmpl	(%eax), %ebx
   20db8:	jl	0x20dc7
   20dba:	jmp	0x20dc1
   20dbc:	movl	0x1dc058, %eax
   20dc1:	movl	(%eax), %esi
   20dc3:	xorl	%eax, %eax
   20dc5:	jmp	0x20dcc
   20dc7:	leal	0x1(%ebx), %esi
   20dca:	movl	%ebx, %eax
   20dcc:	imull	$0xc3c, %eax, %edx
   20dd2:	movl	%eax, %ecx
   20dd4:	movsd	0x77100, %xmm5
   20ddc:	addl	0x1dc05c, %edx
   20de2:	movsd	0x76a18, %xmm6
   20dea:	movss	0x10(%ebp), %xmm2
   20def:	movss	0x76984, %xmm7
   20df7:	jmp	0x20f32
   20dfc:	cmpl	$-0x1, %edi
   20dff:	jne	0x20e39
   20e01:	movss	0x200(%edx), %xmm1
   20e09:	movss	0x214(%edx), %xmm0
   20e11:	movss	0x210(%edx), %xmm3
   20e19:	ucomiss	%xmm0, %xmm1
   20e1c:	jp	0x20e24
   20e1e:	je	0x20ec9
   20e24:	subss	%xmm3, %xmm1
   20e28:	subss	%xmm3, %xmm0
   20e2c:	divss	%xmm0, %xmm1
   20e30:	mulss	%xmm1, %xmm2
   20e34:	jmp	0x20ec9
   20e39:	cmpl	$0x1, %edi
   20e3c:	jne	0x20e78
   20e3e:	movss	0x200(%edx), %xmm0
   20e46:	movss	0x210(%edx), %xmm1
   20e4e:	movss	0x214(%edx), %xmm3
   20e56:	ucomiss	%xmm1, %xmm0
   20e59:	jp	0x20e5d
   20e5b:	je	0x20ec9
   20e5d:	movaps	%xmm3, %xmm4
   20e60:	subss	%xmm0, %xmm4
   20e64:	movaps	%xmm4, %xmm0
   20e67:	movaps	%xmm3, %xmm4
   20e6a:	subss	%xmm1, %xmm4
   20e6e:	divss	%xmm4, %xmm0
   20e72:	mulss	%xmm0, %xmm2
   20e76:	jmp	0x20ec9
   20e78:	movss	0x214(%edx), %xmm4
   20e80:	movaps	%xmm7, %xmm3
   20e83:	ucomiss	0x200(%edx), %xmm4
   20e8a:	jp	0x20e8e
   20e8c:	je	0x20ec9
   20e8e:	movss	0x210(%edx), %xmm1
   20e96:	movsd	0x76930, %xmm3
   20e9e:	cvtss2sd	%xmm2, %xmm2
   20ea2:	subss	%xmm1, %xmm4
   20ea6:	cvtss2sd	%xmm1, %xmm0
   20eaa:	subsd	%xmm0, %xmm3
   20eae:	movapd	%xmm3, %xmm0
   20eb2:	movaps	%xmm7, %xmm3
   20eb5:	cvtss2sd	%xmm4, %xmm1
   20eb9:	divsd	%xmm1, %xmm0
   20ebd:	andpd	%xmm5, %xmm0
   20ec1:	mulsd	%xmm0, %xmm2
   20ec5:	cvtsd2ss	%xmm2, %xmm2
   20ec9:	ucomiss	0x200(%edx), %xmm3
   20ed0:	leal	0x200(%edx), %eax
   20ed6:	jne	0x20ee3
   20ed8:	jp	0x20ee3
   20eda:	movb	$0x0, 0x20c(%edx)
   20ee1:	jmp	0x20f2b
   20ee3:	movl	(%eax), %eax
   20ee5:	cvtss2sd	%xmm2, %xmm0
   20ee9:	fstl	0x1f0(%edx)
   20eef:	movss	%xmm3, 0x204(%edx)
   20ef7:	mulsd	%xmm6, %xmm0
   20efb:	movsd	%xmm0, 0x1f8(%edx)
   20f03:	movb	$0x1, 0x20c(%edx)
   20f0a:	movl	%eax, 0x208(%edx)
   20f10:	cmpb	$0x0, -0x19(%ebp)
   20f14:	jne	0x20f20
   20f16:	xorps	%xmm4, %xmm4
   20f19:	xorl	%eax, %eax
   20f1b:	ucomiss	%xmm2, %xmm4
   20f1e:	jb	0x20f25
   20f20:	movl	$0x1, %eax
   20f25:	movb	%al, 0x20d(%edx)
   20f2b:	incl	%ecx
   20f2c:	addl	$0xc3c, %edx
   20f32:	cmpl	%ecx, %esi
   20f34:	jg	0x20dfc
   20f3a:	fstp	%st(0)
   20f3c:	addl	$0x1c, %esp
   20f3f:	popl	%ebx
   20f40:	popl	%esi
   20f41:	popl	%edi
   20f42:	leave
   20f43:	retl
