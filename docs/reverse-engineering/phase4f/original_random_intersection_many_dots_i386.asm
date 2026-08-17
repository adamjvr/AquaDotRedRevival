   33cf2:	pushl	%ebp
   33cf3:	movl	%esp, %ebp
   33cf5:	pushl	%edi
   33cf6:	pushl	%esi
   33cf7:	pushl	%ebx
   33cf8:	subl	$0x34c, %esp
   33cfe:	calll	0x1dc870 ## symbol stub for: _SWGetMicroseconds
   33d03:	fstp	%st(0)
   33d05:	movl	0xc3640, %edi
   33d0b:	xorl	%eax, %eax
   33d0d:	jmp	0x33d17
   33d0f:	movl	%eax, -0x310(%ebp,%eax,4)
   33d16:	incl	%eax
   33d17:	cmpl	%edi, %eax
   33d19:	jl	0x33d0f
   33d1b:	leal	-0x310(%ebp), %edx
   33d21:	xorl	%eax, %eax
   33d23:	leal	-0x1(%edi), %ecx
   33d26:	movl	%edx, -0x324(%ebp)
   33d2c:	movl	%ecx, -0x328(%ebp)
   33d32:	jmp	0x33d9e
   33d34:	leal	0x1(%eax), %ecx
   33d37:	movl	-0x324(%ebp), %eax
   33d3d:	movl	%ecx, %ebx
   33d3f:	leal	(%eax,%ecx,4), %esi
   33d42:	movl	%esi, -0x32c(%ebp)
   33d48:	jmp	0x33d98
   33d4a:	movl	-0x32c(%ebp), %edx
   33d50:	movl	-0x4(%edx), %edx
   33d53:	movl	%edx, -0x31c(%ebp)
   33d59:	movl	(%esi), %eax
   33d5b:	movl	%eax, -0x320(%ebp)
   33d61:	movl	%edx, %eax
   33d63:	movl	-0x320(%ebp), %edx
   33d69:	shll	$0x5, %eax
   33d6c:	movl	0xc1e98(%eax), %eax
   33d72:	shll	$0x5, %edx
   33d75:	cmpl	0xc1e98(%edx), %eax
   33d7b:	jge	0x33d94
   33d7d:	movl	-0x32c(%ebp), %edx
   33d83:	movl	-0x320(%ebp), %eax
   33d89:	movl	%eax, -0x4(%edx)
   33d8c:	movl	-0x31c(%ebp), %edx
   33d92:	movl	%edx, (%esi)
   33d94:	incl	%ebx
   33d95:	addl	$0x4, %esi
   33d98:	cmpl	%edi, %ebx
   33d9a:	jl	0x33d4a
   33d9c:	movl	%ecx, %eax
   33d9e:	cmpl	-0x328(%ebp), %eax
   33da4:	jl	0x33d34
   33da6:	movl	-0x324(%ebp), %eax
   33dac:	cvtsi2sd	%edi, %xmm0
   33db0:	mulsd	0x76948, %xmm0
   33db8:	cvttsd2si	%xmm0, %ecx
   33dbc:	leal	(%eax,%ecx,4), %edx
   33dbf:	jmp	0x33dc2
   33dc1:	decl	%ecx
   33dc2:	testl	%ecx, %ecx
   33dc4:	js	0x33dde
   33dc6:	movl	(%edx), %eax
   33dc8:	subl	$0x4, %edx
   33dcb:	shll	$0x5, %eax
   33dce:	movl	0xc1e98(%eax), %ebx
   33dd4:	testl	%ebx, %ebx
   33dd6:	je	0x33dc1
   33dd8:	xorl	%ebx, %ebx
   33dda:	xorl	%edx, %edx
   33ddc:	jmp	0x33e3c
   33dde:	calll	0x28b0a
   33de3:	testb	%al, %al
   33de5:	jne	0x33e13
   33de7:	movl	$0x0, 0x10(%esp)
   33def:	movl	$0x6f148, 0xc(%esp)
   33df7:	movl	$0x6efa4, 0x8(%esp)
   33dff:	movl	$0x6bd, 0x4(%esp)
   33e07:	movl	$0x6f16a, (%esp)
   33e0e:	calll	0xf5e8
   33e13:	movl	0xc3640, %eax
   33e18:	movl	$0x0, (%esp)
   33e1f:	decl	%eax
   33e20:	movl	%eax, 0x4(%esp)
   33e24:	calll	0x5f826
   33e29:	jmp	0x33e80
   33e2b:	movl	-0x310(%ebp,%edx,4), %eax
   33e32:	incl	%edx
   33e33:	shll	$0x5, %eax
   33e36:	addl	0xc1e98(%eax), %ebx
   33e3c:	cmpl	%ecx, %edx
   33e3e:	jle	0x33e2b
   33e40:	xorl	%eax, %eax
   33e42:	jmp	0x33e45
   33e44:	incl	%eax
   33e45:	cmpl	%edi, %eax
   33e47:	jl	0x33e44
   33e49:	movl	%ebx, 0x4(%esp)
   33e4d:	movl	$0x1, (%esp)
   33e54:	calll	0x5f826
   33e59:	xorl	%edx, %edx
   33e5b:	movl	$0xffffffff, %ecx
   33e60:	movl	%eax, %ebx
   33e62:	jmp	0x33e75
   33e64:	incl	%ecx
   33e65:	movl	-0x310(%ebp,%ecx,4), %eax
   33e6c:	shll	$0x5, %eax
   33e6f:	addl	0xc1e98(%eax), %edx
   33e75:	cmpl	%ebx, %edx
   33e77:	jl	0x33e64
   33e79:	movl	-0x310(%ebp,%ecx,4), %eax
   33e80:	shll	$0x5, %eax
   33e83:	movl	0x8(%ebp), %ecx
   33e86:	movl	0xc1e80(%eax), %edx
   33e8c:	movl	%edx, (%ecx)
   33e8e:	movl	0xc1e84(%eax), %eax
   33e94:	movl	0xc(%ebp), %edx
   33e97:	movl	%eax, (%edx)
   33e99:	addl	$0x34c, %esp
   33e9f:	popl	%ebx
   33ea0:	popl	%esi
   33ea1:	popl	%edi
   33ea2:	leave
   33ea3:	retl
   33ea4:	pushl	%ebp
   33ea5:	xorl	%ecx, %ecx
   33ea7:	movl	%esp, %ebp
   33ea9:	pushl	%ebx
   33eaa:	movl	%ecx, %eax
   33eac:	movl	$0x20, %edx
   33eb1:	shll	$0x5, %eax
   33eb4:	addl	$0xcad20, %eax
   33eb9:	movb	$-0x1, (%eax)
   33ebc:	incl	%eax
   33ebd:	decl	%edx
   33ebe:	jne	0x33eb9
   33ec0:	incl	%ecx
   33ec1:	cmpl	$0x2a, %ecx
   33ec4:	jne	0x33eaa
   33ec6:	movl	0xc3640, %ebx
   33ecc:	andl	$0xffffff00, %ecx
   33ed2:	movl	$0xc1e80, %edx
   33ed7:	jmp	0x33ee9
   33ed9:	movl	-0x20(%edx), %eax
   33edc:	shll	$0x5, %eax
   33edf:	addl	-0x1c(%edx), %eax
   33ee2:	movb	%cl, 0xcad20(%eax)
   33ee8:	incl	%ecx
   33ee9:	addl	$0x20, %edx
   33eec:	cmpl	%ebx, %ecx
   33eee:	jl	0x33ed9
   33ef0:	popl	%ebx
   33ef1:	leave
   33ef2:	retl
   33ef3:	nop
   33ef4:	pushl	%ebp
   33ef5:	movl	%esp, %ebp
   33ef7:	pushl	%edi
   33ef8:	movl	0xc3640, %edi
   33efe:	movsd	0x8(%ebp), %xmm2
   33f03:	pushl	%esi
   33f04:	xorl	%esi, %esi
   33f06:	pushl	%ebx
   33f07:	jmp	0x33f57
   33f09:	leal	(%esi,%esi,4), %eax
   33f0c:	movl	$0x4, %edx
   33f11:	xorpd	%xmm1, %xmm1
   33f15:	leal	(%ebx,%eax,4), %eax
   33f18:	leal	0xc3660(,%eax,8), %eax
   33f1f:	movsd	(%eax), %xmm0
   33f23:	ucomisd	%xmm3, %xmm0
   33f27:	jbe	0x33f31
   33f29:	addsd	%xmm2, %xmm0
   33f2d:	movsd	%xmm0, (%eax)
   33f31:	movsd	0x80(%ecx), %xmm0
   33f39:	ucomisd	%xmm1, %xmm0
   33f3d:	jbe	0x33f47
   33f3f:	movsd	%xmm2, 0x80(%ecx)
   33f47:	addl	$0x20, %eax
   33f4a:	decl	%edx
   33f4b:	jne	0x33f1f
   33f4d:	incl	%ebx
   33f4e:	addl	$0x8, %ecx
   33f51:	cmpl	$0x4, %ebx
   33f54:	jne	0x33f09
   33f56:	incl	%esi
   33f57:	cmpl	%edi, %esi
   33f59:	jge	0x33f6f
   33f5b:	leal	(%esi,%esi,4), %eax
   33f5e:	xorl	%ebx, %ebx
   33f60:	xorpd	%xmm3, %xmm3
