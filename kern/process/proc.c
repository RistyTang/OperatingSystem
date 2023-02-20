#include <proc.h>
#include <kmalloc.h>
#include <string.h>
#include <sync.h>
#include <pmm.h>
#include <error.h>
#include <sched.h>
#include <elf.h>
#include <vmm.h>
#include <trap.h>
#include <stdio.h>
#include <stdlib.h>
#include <assert.h>

/* ------------- process/thread mechanism design&implementation -------------
(an simplified Linux process/thread mechanism )
introduction:
  ucore implements a simple process/thread mechanism. process contains the independent memory sapce, at least one threads
for execution, the kernel data(for management), processor state (for context switch), files(in lab6), etc. ucore needs to
manage all these details efficiently. In ucore, a thread is just a special kind of process(share process's memory).
------------------------------
process state       :     meaning               -- reason
    PROC_UNINIT     :   uninitialized           -- alloc_proc
    PROC_SLEEPING   :   sleeping                -- try_free_pages, do_wait, do_sleep
    PROC_RUNNABLE   :   runnable(maybe running) -- proc_init, wakeup_proc, 
    PROC_ZOMBIE     :   almost dead             -- do_exit

-----------------------------
process state changing:
                                            
  alloc_proc                                 RUNNING
      +                                   +--<----<--+
      +                                   + proc_run +
      V                                   +-->---->--+ 
PROC_UNINIT -- proc_init/wakeup_proc --> PROC_RUNNABLE -- try_free_pages/do_wait/do_sleep --> PROC_SLEEPING --
                                           A      +                                                           +
                                           |      +--- do_exit --> PROC_ZOMBIE                                +
                                           +                                                                  + 
                                           -----------------------wakeup_proc----------------------------------
-----------------------------
process relations
parent:           proc->parent  (proc is children)
children:         proc->cptr    (proc is parent)
older sibling:    proc->optr    (proc is younger sibling)
younger sibling:  proc->yptr    (proc is older sibling)
-----------------------------
related syscall for process:
SYS_exit        : process exit,                           -->do_exit
SYS_fork        : create child process, dup mm            -->do_fork-->wakeup_proc
SYS_wait        : wait process                            -->do_wait
SYS_exec        : after fork, process execute a program   -->load a program and refresh the mm
SYS_clone       : create child thread                     -->do_fork-->wakeup_proc
SYS_yield       : process flag itself need resecheduling, -- proc->need_sched=1, then scheduler will rescheule this process
SYS_sleep       : process sleep                           -->do_sleep 
SYS_kill        : kill process                            -->do_kill-->proc->flags |= PF_EXITING
                                                                 -->wakeup_proc-->do_wait-->do_exit   
SYS_getpid      : get the process's pid

*/

// the process set's list
list_entry_t proc_list;

#define HASH_SHIFT          10
#define HASH_LIST_SIZE      (1 << HASH_SHIFT)
#define pid_hashfn(x)       (hash32(x, HASH_SHIFT))

// has list for process set based on pid
static list_entry_t hash_list[HASH_LIST_SIZE];

// idle proc
struct proc_struct *idleproc = NULL;
// init proc
struct proc_struct *initproc = NULL;
// current proc
struct proc_struct *current = NULL;

static int nr_process = 0;

void kernel_thread_entry(void);
void forkrets(struct trapframe *tf);
void switch_to(struct context *from, struct context *to);

// alloc_proc - alloc a proc_struct and init all fields of proc_struct
static struct proc_struct *
alloc_proc(void) {
    struct proc_struct *proc = kmalloc(sizeof(struct proc_struct));
    if (proc != NULL) {
    //LAB4:EXERCISE1 YOUR CODE
    /*
     * below fields in proc_struct need to be initialized
     *       enum proc_state state;                      // Process state
     *       int pid;                                    // Process ID
     *       int runs;                                   // the running times of Proces
     *       uintptr_t kstack;                           // Process kernel stack
     *       volatile bool need_resched;                 // bool value: need to be rescheduled to release CPU?
     *       struct proc_struct *parent;                 // the parent process
     *       struct mm_struct *mm;                       // Process's memory management field
     *       struct context context;                     // Switch here to run process
     *       struct trapframe *tf;                       // Trap frame for current interrupt
     *       uintptr_t cr3;                              // CR3 register: the base addr of Page Directroy Table(PDT)
     *       uint32_t flags;                             // Process flag
     *       char name[PROC_NAME_LEN + 1];               // Process name
     */
        proc->state = PROC_UNINIT;//未初始化
        proc->pid = -1;
        proc->runs = 0;
        proc->kstack = 0;
        proc->need_resched = 0;
        proc->parent = NULL;
        proc->mm = NULL;
        memset(&(proc->context), 0, sizeof(struct context));
        proc->tf = NULL;
        proc->cr3 = boot_cr3;//该进程页目录表的基址寄存器 pmm_init()里面boot_cr3 = PADDR(boot_pgdir);
        proc->flags = 0;
        memset(proc->name, 0, PROC_NAME_LEN);
    }
    return proc;
}

// set_proc_name - set the name of proc
char *
set_proc_name(struct proc_struct *proc, const char *name) {
    memset(proc->name, 0, sizeof(proc->name));
    return memcpy(proc->name, name, PROC_NAME_LEN);
}

// get_proc_name - get the name of proc
char *
get_proc_name(struct proc_struct *proc) {
    static char name[PROC_NAME_LEN + 1];
    memset(name, 0, sizeof(name));
    return memcpy(name, proc->name, PROC_NAME_LEN);
}

// get_pid - alloc a unique pid for process
static int
get_pid(void) {
    //实际上，之前定义了 MAX_PID=2*MAX_PROCESS，意味着ID的总数目是大于PROCESS的总数目的
    //因此不会出现部分PROCESS无ID可分的情况
    static_assert(MAX_PID > MAX_PROCESS);
    struct proc_struct *proc;
    list_entry_t *list = &proc_list, *le;
    //next_safe和last_pid两个变量，这里需要注意！ 它们是static全局变量！！！
    static int next_safe = MAX_PID, last_pid = MAX_PID;
    //++last_pid>-MAX_PID,说明pid以及分到尽头，需要从头再来
    if (++ last_pid >= MAX_PID) 
    {
        last_pid = 1;
        goto inside;
    }
    if (last_pid >= next_safe) 
    {
    inside:
        next_safe = MAX_PID;
    repeat:
        //le等于线程的链表头
        le = list;
        //遍历一遍链表
        //循环扫描每一个当前进程：当一个现有的进程号和last_pid相等时，则将last_pid+1；
        //当现有的进程号大于last_pid时，这意味着在已经扫描的进程中
        //[last_pid,min(next_safe, proc->pid)] 这段进程号尚未被占用，继续扫描。
        while ((le = list_next(le)) != list) 
        { 
            proc = le2proc(le, list_link);//proc为le在list_link中对应的程序
            //如果proc的pid与last_pid相等，则将last_pid加1
            //当然，如果last_pid>=MAX_PID,then 将其变为1
            //确保了没有一个进程的pid与last_pid重合
            if (proc->pid == last_pid) 
            {
                if (++ last_pid >= next_safe) 
                {
                    if (last_pid >= MAX_PID) 
                    {
                        last_pid = 1;
                    }
                    next_safe = MAX_PID;
                    goto repeat;
                }
            }
            //last_pid<pid<next_safe，确保最后能够找到这么一个满足条件的区间，获得合法的pid；
            else if (proc->pid > last_pid && next_safe > proc->pid) 
            {
                next_safe = proc->pid;
            }
        }
    }
    return last_pid;
}

// proc_run - make process "proc" running on cpu
// NOTE: before call switch_to, should load  base addr of "proc"'s new PDT
//注意：在执行上下文切换之前需要先load 这个进程的新的PDT的地址
void proc_run(struct proc_struct *proc) 
{  
    //判断一下要调度的进程是不是当前进程
    if (proc != current) 
    {
        bool intr_flag;
        struct proc_struct *prev = current, *next = proc;
        // 关闭中断,进行进程切换sync.h
        local_intr_save(intr_flag);
        {
            //当前进程设为待调度的进程
            current = proc;
            //加载待调度进程的内核栈基地址
            //设置任务状态段ts中特权态0下的栈顶指针esp0为next内核线程initproc的内核栈的栈顶
            load_esp0(next->kstack + KSTACKSIZE);//pmm.c118
            //将当前的cr3寄存器改为需要运行进程的页目录表，完成进程间的页表切换；
            lcr3(next->cr3);
            //进行上下文切换，保存原线程的寄存器并恢复待调度线程的寄存器
            //Switch.S
            switch_to(&(prev->context), &(next->context));
        }
        //恢复中断
        local_intr_restore(intr_flag);
    }
}

//新线程/进程的第一个内核入口点
// forkret -- the first kernel entry point of a new thread/process
// NOTE: the addr of forkret is setted in copy_thread function
//       after switch_to, the current proc will execute here.
static void
forkret(void) {
    forkrets(current->tf);
}

// hash_proc - add proc into proc hash_list将进程放入进程哈希列表
static void
hash_proc(struct proc_struct *proc) {
    list_add(hash_list + pid_hashfn(proc->pid), &(proc->hash_link));
}

// find_proc - find proc frome proc hash_list according to pid
struct proc_struct *
find_proc(int pid) {
    if (0 < pid && pid < MAX_PID) {
        list_entry_t *list = hash_list + pid_hashfn(pid), *le = list;
        while ((le = list_next(le)) != list) {
            struct proc_struct *proc = le2proc(le, hash_link);
            if (proc->pid == pid) {
                return proc;
            }
        }
    }
    return NULL;
}

// kernel_thread - create a kernel thread using "fn" function
// NOTE: the contents of temp trapframe tf will be copied to 
//       proc->tf in do_fork-->copy_thread function
int
kernel_thread(int (*fn)(void *), void *arg, uint32_t clone_flags) {
    //1.首先设置initproc的中断帧，创建一个tf中断帧，记录了进程在被中断前的状态
    struct trapframe tf;//结构体在trap.h
    memset(&tf, 0, sizeof(struct trapframe));//将tf清零
    //2.之后进行相关的参数的赋值
    tf.tf_cs = KERNEL_CS;//代码段是在内核里
    tf.tf_ds = tf.tf_es = tf.tf_ss = KERNEL_DS;//数据段在内核里
    tf.tf_regs.reg_ebx = (uint32_t)fn;//fn代表实际的入口地址/* ebx指向函数地址 */
    tf.tf_regs.reg_edx = (uint32_t)arg;/* edx指向参数 */ 
    tf.tf_eip = (uint32_t)kernel_thread_entry;//entry.S中
    //CLONE_VM pmm.h 11->0x00000100
    //clone_flags在init时传入的参数是 0
    //3.调用dofork函数进行线程创建
    return do_fork(clone_flags | CLONE_VM, 0, &tf);//308
}

// setup_kstack - alloc pages with size KSTACKPAGE as process kernel stack
static int
setup_kstack(struct proc_struct *proc) {
    //memlayout.h->2
    //1.为该线程分配空间——两页
    struct Page *page = alloc_pages(KSTACKPAGE);//分配页
    if (page != NULL) {
        proc->kstack = (uintptr_t)page2kva(page);//设置内核栈空间地址 
        return 0;
    }
    return -E_NO_MEM;
}

// put_kstack - free the memory space of process kernel stack
static void
put_kstack(struct proc_struct *proc) {
    free_pages(kva2page((void *)(proc->kstack)), KSTACKPAGE);
}

// copy_mm - process "proc" duplicate OR share process "current"'s mm according clone_flags
//         - if clone_flags & CLONE_VM, then "share" ; else "duplicate"
static int
copy_mm(uint32_t clone_flags, struct proc_struct *proc) {
    assert(current->mm == NULL);//由于系统！进程没有虚存，其值为NULL
    /* do nothing in this project */
    return 0;
}

// copy_thread - setup the trapframe on the  process's kernel stack top and
//             - setup the kernel entry point and stack of process
static void
copy_thread(struct proc_struct *proc, uintptr_t esp, struct trapframe *tf) {
    //在内核堆栈的顶部设置中断帧大小的一块栈空间
    proc->tf = (struct trapframe *)(proc->kstack + KSTACKSIZE) - 1;
    *(proc->tf) = *tf;//拷贝在kernel_thread函数建立的临时中断帧的初始值
    proc->tf->tf_regs.reg_eax = 0;
    //设置子进程执行完do_fork后的返回值
    proc->tf->tf_esp = esp;//设置中断帧中的栈指针esp
    proc->tf->tf_eflags |= FL_IF;//使能中断mmu.h->0x00000200

    proc->context.eip = (uintptr_t)forkret;//完成对返回中断的一个处理过程
    //forkret主要对返回的中断处理，基本可以认为是一个中断处理并恢复
    //在trapentry.S

    proc->context.esp = (uintptr_t)(proc->tf);//当前的栈顶指针指向proc->tf
}

/* do_fork -     parent process for a new child process
 * @clone_flags: used to guide how to clone the child process
 * @stack:       the parent's user stack pointer. if stack==0, It means to fork a kernel thread.
 * @tf:          the trapframe info, which will be copied to child process's proc->tf
 */
 //实现具体的尤其针对init_proc的内核进程控制块的初始化
int
do_fork(uint32_t clone_flags, uintptr_t stack, struct trapframe *tf) {
    //error.h9->5
    int ret = -E_NO_FREE_PROC;//ret=-5
    struct proc_struct *proc;
    //线程数已经到达最大值
    if (nr_process >= MAX_PROCESS) {
        goto fork_out;
    }
    //error.h9->4
    ret = -E_NO_MEM;
    //LAB4:EXERCISE2 YOUR CODE
    /*
     * Some Useful MACROs, Functions and DEFINEs, you can use them in below implementation.
     * MACROs or Functions:
     *   alloc_proc:   create a proc struct and init fields (lab4:exercise1)
     *   setup_kstack: alloc pages with size KSTACKPAGE as process kernel stack
     *   copy_mm:      process "proc" duplicate OR share process "current"'s mm according clone_flags
     *                 if clone_flags & CLONE_VM, then "share" ; else "duplicate"
     *   copy_thread:  setup the trapframe on the  process's kernel stack top and
     *                 setup the kernel entry point and stack of process
     *   hash_proc:    add proc into proc hash_list
     *   get_pid:      alloc a unique pid for process
     *   wakeup_proc:  set proc->state = PROC_RUNNABLE
     * VARIABLES:
     *   proc_list:    the process set's list
     *   nr_process:   the number of process set
     */

    //    1. call alloc_proc to allocate a proc_struct
    //    2. call setup_kstack to allocate a kernel stack for child process
    //    3. call copy_mm to dup OR share mm according clone_flag
    //    4. call copy_thread to setup tf & context in proc_struct
    //    5. insert proc_struct into hash_list && proc_list
    //    6. call wakeup_proc to make the new child process RUNNABLE
    //    7. set ret vaule using child proc's pid
    //第一步：申请进程块，如果失败，直接返回处理
    if ((proc = alloc_proc()) == NULL) {
        goto fork_out;
    }
    //申请成功，则新的线程的父进程是当前进程，也就对应着init_proc的父进程是idleproc
    proc->parent = current;
    //第二步：为进程分配一个内核栈，若失败则将分配的页释放
    //274行
    if (setup_kstack(proc) != 0) {
        goto bad_fork_cleanup_proc;
    }
    //call copy_mm to dup OR share mm according clone_flag
    //292
    //3.根据cloneflags来设置复制/共享内存空间——在本次实验中因为系统进程没有虚存，mm为null
    if (copy_mm(clone_flags, proc) != 0) {
        goto bad_fork_cleanup_kstack;
    }
    //301
    //4.设置进程在内核（将来也包括用户态）正常运行和调度所需的中断帧和执行上下文
    copy_thread(proc, stack, tf);

    //5.原子性执行以下操作：
    bool intr_flag;
    local_intr_save(intr_flag);//sync.h24
    {
        proc->pid = get_pid();//138，为进程分配一个独一无二的进程号
        hash_proc(proc);//220将进程id进行哈希运算后放入proc的哈希列表
        list_add(&proc_list, &(proc->list_link));//将proc放入proc链表
        nr_process ++;
    }
    local_intr_restore(intr_flag);//恢复中断

    wakeup_proc(proc);//sched.c将proc的状态设置为可执行runnable
    //返回值为子进程的id
    ret = proc->pid;
    //之后回到proc_init
fork_out:
    return ret;

bad_fork_cleanup_kstack:
    put_kstack(proc);
bad_fork_cleanup_proc:
    kfree(proc);
    goto fork_out;
}

// do_exit - called by sys_exit
//   1. call exit_mmap & put_pgdir & mm_destroy to free the almost all memory space of process
//   2. set process' state as PROC_ZOMBIE, then call wakeup_proc(parent) to ask parent reclaim itself.
//   3. call scheduler to switch to other process
int
do_exit(int error_code) {
    panic("process exit!!.\n");
}

// init_main - the second kernel thread used to create user_main kernel threads
static int
init_main(void *arg) {
    cprintf("this initproc, pid = %d, name = \"%s\"\n", current->pid, get_proc_name(current));
    cprintf("To U: \"%s\".\n", (const char *)arg);
    cprintf("To U: \"en.., Bye, Bye. :)\"\n");
    return 0;
}

// proc_init - set up the first kernel thread idleproc "idle" by itself and 
//           - create the second kernel thread init_main
//设置第一个内核线程空闲进程“idle”，并创建第二个内核线程init_main
void
proc_init(void) {
    int i;

    list_init(&proc_list);//将进程集合列表初始化（将proc_list的prev和next指向自己）
    for (i = 0; i < HASH_LIST_SIZE; i ++) {
        list_init(hash_list + i);
    }
    //86行
    if ((idleproc = alloc_proc()) == NULL) {
        panic("cannot alloc idleproc.\n");
    }
    //初始化idleproc后进行相关状态的变更
    idleproc->pid = 0;//进程id=0
    idleproc->state = PROC_RUNNABLE;//可执行状态
    idleproc->kstack = (uintptr_t)bootstack;//内核栈位置为entry.s的bootstack
    idleproc->need_resched = 1;//需要重新参与调度以释放CPU
    set_proc_name(idleproc, "idle");
    nr_process ++;//当前进程数量

    current = idleproc;//当前进程为idleproc
    
    //得到的pid是init_proc的
    int pid = kernel_thread(init_main, "Hello world!!", 0);//254
    if (pid <= 0) {//说明未创建成功
        panic("create init_main failed.\n");
    }

    initproc = find_proc(pid);//找到initproc
    set_proc_name(initproc, "init");

    assert(idleproc != NULL && idleproc->pid == 0);
    assert(initproc != NULL && initproc->pid == 1);
}

// cpu_idle - at the end of kern_init, the first kernel thread idleproc will do below works
void
cpu_idle(void) {
    while (1) {
        //一旦当前进程需要重新调度
        //sched.c
        if (current->need_resched) {
            schedule();
        }
    }
}

