#include <asm.h>

# Start the CPU: switch to 32-bit protected mode, jump into C.
# The BIOS loads this code from the first sector of the hard disk into
# memory at physical address 0x7c00 and starts executing in real mode
# with %cs=0 %ip=7c00.

.set PROT_MODE_CSEG,        0x8                     # kernel code segment selector #代码段最前面定义了PROT_MODE_CSGE和PROT_MODE_DSEG，分别被定义为0x8h和0x10h，这两个分别是代码段和数据段的选择子。
.set PROT_MODE_DSEG,        0x10                    # kernel data segment selector
.set CR0_PE_ON,             0x1                     # protected mode enable flag
.set SMAP,                  0x534d4150

# 第一部分:屏蔽中断，设置串地址增长方向，设置一些重要的数据段寄存器(DS,ES,SS)
# start address should be 0:7c00, in real mode, the beginning address of the running bootloader
.globl start
start:
.code16                                             # Assemble for 16-bit mode  # 编译处于实模式下，可用的内存大小不多于1M，因此需要告诉编译器使用16位模式编译。
    cli                                             # Disable interrupts     # 屏蔽中断
    cld                                             # String operations increment    # 设置串地址增长方向 cld将DF位置零，从而决定内存地址是增大(对应的std是将DF置一，内存地址减小)

    # Set up the important data segment registers (DS, ES, SS).
    xorw %ax, %ax                                   # Segment number zero   #使用xorw异或指令让ax寄存器值变成0，再把ax的值赋给ds，es和ss寄存器。准备工作到此结束
    movw %ax, %ds                                   # -> Data Segment
    movw %ax, %es                                   # -> Extra Segment
    movw %ax, %ss                                   # -> Stack Segment    #除了cs的段寄存器有ds、ss、es只能被通用寄存器ax赋值，那cs咋办？？

    # Enable A20:     第二部分:启动A20
    #  For backwards compatibility with the earliest PCs, physical
    #  address line 20 is tied low, so that addresses higher than
    #  1MB wrap around to zero by default. This code undoes this.
seta20.1:
    inb $0x64, %al                                  # Wait for not busy(8042 input buffer empty). #读取当前状态到al寄存器  读取状态寄存器,等待8042键盘控制器闲置
    testb $0x2, %al                                 #检查当前状态寄存器的第二位是否为1(缓冲区是否为空)
    jnz seta20.1                                    #若缓冲区不为0，跳转到开始处

    movb $0xd1, %al                                 # 0xd1 -> port 0x64  #将0xd1h写入al寄存器  0xd1表示写输出端口命令，参数随后通过0x60端口写入
    outb %al, $0x64                                 # 0xd1 means: write data to 8042's P2 port  #向0x64h发送0xd1h命令，表示要写；写Output Port：向64h发送0d1h命令，然后向60h写入Output Port的数据

seta20.2:
    inb $0x64, %al                                  # Wait for not busy(8042 input buffer empty).
    testb $0x2, %al
    jnz seta20.2

    movb $0xdf, %al                                 # 0xdf -> port 0x60  #将0xdfh写入al寄存器
    outb %al, $0x60                                 # 0xdf = 11011111, means set P2's A20 bit(the 1 bit) to 1   #向0x60h写入0xdfh，打开A20  通过0x60写入数据11011111 即将A20置1

#探测物理内存：eflags的CF位：若INT 15中断执行成功，则不置位，否则置位；
probe_memory:
    movl $0, 0x8000
    xorl %ebx, %ebx
    movw $0x8004, %di
start_probe:
    movl $0xE820, %eax
    movl $20, %ecx
    movl $SMAP, %edx
    int $0x15
    jnc cont
    movw $12345, 0x8000
    jmp finish_probe
cont:
    addw $20, %di
    incl 0x8000
    cmpl $0, %ebx
    jnz start_probe
finish_probe:

    # Switch from real to protected mode, using a bootstrap GDT
    # and segment translation that makes virtual addresses
    # identical to physical addresses, so that the
    # effective memory map does not change during the switch.   #第三部分，初始化GDT表，通过lgdt gdtdesc指令就可以实现。
    lgdt gdtdesc
    movl %cr0, %eax                                             #第四部分就是进入保护模式，进入保护模式的原理就是让cr0寄存器中的PE值为1
    orl $CR0_PE_ON, %eax
    movl %eax, %cr0

    # Jump to next instruction, but in 32-bit code segment.     #第五部分通过一个长跳转来更新CS寄存器的基地址
    # Switches processor into 32-bit mode.
    ljmp $PROT_MODE_CSEG, $protcseg

.code32                                             # Assemble for 32-bit mode
protcseg:
    # Set up the protected-mode data segment registers  #第六部分是设置段寄存器并建立堆栈
    movw $PROT_MODE_DSEG, %ax                       # Our data segment selector
    movw %ax, %ds                                   # -> DS: Data Segment
    movw %ax, %es                                   # -> ES: Extra Segment
    movw %ax, %fs                                   # -> FS
    movw %ax, %gs                                   # -> GS
    movw %ax, %ss                                   # -> SS: Stack Segment

    # Set up the stack pointer and call into C. The stack region is from 0--start(0x7c00)
    movl $0x0, %ebp
    movl $start, %esp
    call bootmain                                   # 第七部分:调用bootmain

    # If bootmain returns (it shouldn't), loop.
spin:
    jmp spin

.data
# Bootstrap GDT
.p2align 2                                          # force 4 byte alignment
gdt:
    SEG_NULLASM                                     # null seg
    SEG_ASM(STA_X|STA_R, 0x0, 0xffffffff)           # code seg for bootloader and kernel
    SEG_ASM(STA_W, 0x0, 0xffffffff)                 # data seg for bootloader and kernel

gdtdesc:
    .word 0x17                                      # sizeof(gdt) - 1
    .long gdt                                       # address gdt
