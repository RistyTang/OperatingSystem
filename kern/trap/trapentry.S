#include <memlayout.h>

# vectors.S sends all traps here.
.text
.globl __alltraps
__alltraps:
    # push registers to build a trap frame
    # therefore make the stack look like a struct trapframe
    pushl %ds
    pushl %es
    pushl %fs
    pushl %gs
    pushal

    # load GD_KDATA into %ds and %es to set up data segments for kernel
    movl $GD_KDATA, %eax
    movw %ax, %ds
    movw %ax, %es

    # push %esp to pass a pointer to the trapframe as an argument to trap()
    pushl %esp

    # call trap(tf), where tf=%esp
    call trap

    # pop the pushed stack pointer
    popl %esp

    # return falls through to trapret...
.globl __trapret
__trapret:
    # restore registers from stack从_trapret开始执行到iret前，esp指向了current->tf.tf_eip
    popal                   # 顺序EDI,ESI,EBP,EBX,EDX,ECX,EAX:

    # restore %ds, %es, %fs and %gs
    popl %gs
    popl %fs
    popl %es
    popl %ds

    # get rid of the trap number and error code
    addl $0x8, %esp         # esp是current->tf,tf eip tf.tf eip =(uint32 t)kernel thread entry;
    iret                    # 执行完iret后，就开始在内核中执行kernel thread entry医数

.globl forkrets
forkrets:
    # set stack to this new process's trapframe lab4新加！！
    movl 4(%esp), %esp              # 把esp指向当前进程的中断帧
    jmp __trapret
