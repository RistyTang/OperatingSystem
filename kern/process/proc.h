#ifndef __KERN_PROCESS_PROC_H__
#define __KERN_PROCESS_PROC_H__

#include <defs.h>
#include <list.h>
#include <trap.h>
#include <memlayout.h>


// process's state in his life cycle    //进程生命周期
enum proc_state {
    PROC_UNINIT = 0,  // uninitialized
    PROC_SLEEPING,    // sleeping
    PROC_RUNNABLE,    // runnable(maybe running)
    PROC_ZOMBIE,      // almost dead, and wait parent proc to reclaim his resource
};

// Saved registers for kernel context switches.
// Don't need to save all the %fs etc. segment registers,
// because they are constant across kernel contexts.
// Save all the regular registers so we don't need to care
// which are caller save, but not the return register %eax.
// (Not saving %eax just simplifies the switching code.)
// The layout of context must match code in switch.S.
struct context {        //上下文
    uint32_t eip;   //存储CPU要读取指令的地址
    uint32_t esp;   //栈指针寄存器，指向栈顶
    uint32_t ebx;   //数据寄存器
    uint32_t ecx;    //计数寄存器
    uint32_t edx;    //数据寄存器
    uint32_t esi;   //变址寄存器，主要用于存放存储单元在段内的偏移量
    uint32_t edi;   //变址寄存器，主要用于存放存储单元在段内的偏移量
    uint32_t ebp;   //基址指针寄存器，指向栈底
};
//需要强调的是不需要保存所有的段寄存器，因为这些都是跨内核上下文的常量
//保存的是上下文切换时前一个进程的状态现场。
//保存上下文的函数在switch.S中

#define PROC_NAME_LEN               15
#define MAX_PROCESS                 4096
#define MAX_PID                     (MAX_PROCESS * 2)   //8192

extern list_entry_t proc_list;      //进程块双向链表

struct proc_struct {    //进程控制块
    enum proc_state state;                      // Process state                        //创建但未初始化、睡着、就绪/运行、死亡
    int pid;                                    // Process ID                           //默认值设为-1
    int runs;                                   // the running times of Proces          //进程运行时间，默认值0
    uintptr_t kstack;                           // Process kernel stack                 //内核栈位置
    volatile bool need_resched;                 // bool value: need to be rescheduled to release CPU?//是否需要重新参与调度以释放CPU，初值0（false，表示不需要）
    struct proc_struct *parent;                 // the parent process                   //爹进程，初值NULL，只有第一个进程无爹（idle proc）
    struct mm_struct *mm;                       // Process's memory management field    //用户！进程虚拟内存管理单元指针，由于系统！进程没有虚存，其值为NULL
    struct context context;                     // Switch here to run process           //进程上下文，默认值全零
    struct trapframe *tf;                       // Trap frame for current interrupt     //中断帧指针，默认值NULL
    uintptr_t cr3;                              // CR3 register: the base addr of Page Directroy Table(PDT) //该进程页目录表的基址寄存器 内核线程指向bootcr3，pmm_init()里面boot_cr3 = PADDR(boot_pgdir);
                                                //boot_cr3指向了uCore启动时建立好的饿内核虚拟空间的页目录表首地址。
    uint32_t flags;                             // Process flag                         //进程标志位，默认值0
    char name[PROC_NAME_LEN + 1];               // Process name                         //进程名
    list_entry_t list_link;                     // Process link list                    //链在proc_list这个双向循环链表中
    list_entry_t hash_link;                     // Process hash list                    //链在hash_list[HASH_LIST_SIZE]这个哈希表中，根据pid算哈希值
};

//根据结构体成员（proc）来找这个结构体
#define le2proc(le, member)         \
    to_struct((le), struct proc_struct, member)

extern struct proc_struct *idleproc, *initproc, *current;

void proc_init(void);   //kern_init()新加
void proc_run(struct proc_struct *proc);
int kernel_thread(int (*fn)(void *), void *arg, uint32_t clone_flags);//创initproc

char *set_proc_name(struct proc_struct *proc, const char *name);
char *get_proc_name(struct proc_struct *proc);
void cpu_idle(void) __attribute__((noreturn));//idleproc调

struct proc_struct *find_proc(int pid);
int do_fork(uint32_t clone_flags, uintptr_t stack, struct trapframe *tf);
int do_exit(int error_code);

#endif /* !__KERN_PROCESS_PROC_H__ */

