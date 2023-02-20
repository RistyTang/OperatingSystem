.text
.globl switch_to
switch_to:                      # switch_to(from, to)

    # save from's registers先保存原本寄存器的值
    movl 4(%esp), %eax          # eax points to from将esp+4的值赋给eax，这样eax就指向了from，此时to是esp+8
    popl 0(%eax)                # save eip !popl 弹出eax，这样就完成了对eip的赋值，弹出后to变成了esp+4,from为esp
    movl %esp, 4(%eax)          # save esp::context of from
    movl %ebx, 8(%eax)          # save ebx::context of from
    movl %ecx, 12(%eax)         # save ecx::context of from
    movl %edx, 16(%eax)         # save edx::context of from
    movl %esi, 20(%eax)         # save esi::context of from
    movl %edi, 24(%eax)         # save edi::context of from
    movl %ebp, 28(%eax)         # save ebp::context of from

    # restore to's registers
    movl 4(%esp), %eax          # not 8(%esp): popped return address already
                                # eax now points to to
    movl 28(%eax), %ebp         # restore ebp::context of to
    movl 24(%eax), %edi         # restore edi::context of to
    movl 20(%eax), %esi         # restore esi::context of to
    movl 16(%eax), %edx         # restore edx::context of to
    movl 12(%eax), %ecx         # restore ecx::context of to
    movl 8(%eax), %ebx          # restore ebx::context of to
    movl 4(%eax), %esp          # restore esp::context of to

    pushl 0(%eax)               # push eip把context中保存的下一个进程要执行的指令地址context.eip放到了堆栈顶

    ret

