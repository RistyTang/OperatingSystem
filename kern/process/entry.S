.text
.globl kernel_thread_entry
kernel_thread_entry:        # void kernel_thread(void)

    pushl %edx              # push arg把函数fn的参数arg（保存在edx寄存器中）压栈
    call *%ebx              # call fn

    pushl %eax              # save the return value of fn(arg)把函数返回值eax寄存器内容压栈
    call do_exit            # call do_exit to terminate current thread退出

