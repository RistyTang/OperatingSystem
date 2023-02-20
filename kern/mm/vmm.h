#ifndef __KERN_MM_VMM_H__
#define __KERN_MM_VMM_H__

#include <defs.h>
#include <list.h>
#include <memlayout.h>
#include <sync.h>

//pre define
struct mm_struct;

// the virtual continuous memory area(vma), [vm_start, vm_end),         //描述应用程序对虚拟内存“需求”，表示一个连续地址的虚拟内存空间，然后用指针串起来
// addr belong to a vma means  vma.vm_start<= addr <vma.vm_end          //一个va是否属于这个区域的判定：左闭右开
struct vma_struct {
    struct mm_struct *vm_mm; // the set of vma using the same PDT       //指向它所属的组织：相同PDT的一群vma们
    uintptr_t vm_start;      // start addr of vma      
    uintptr_t vm_end;        // end addr of vma, not include the vm_end itself
    uint32_t vm_flags;       // flags of vma                            //读、写、可执行
    list_entry_t list_link;  // linear list link which sorted by start addr of vma  //按地址从小到大的顺序把所有vma（不限组）串起来
};

#define le2vma(le, member)                  \
    to_struct((le), struct vma_struct, member)          //根据结构体成员（链表项）来找这个结构体

#define VM_READ                 0x00000001      //只读
#define VM_WRITE                0x00000002      //只写
#define VM_EXEC                 0x00000004      //可执行

// the control struct for a set of vma using the same PDT   //包含所有虚拟内存空间的共同属性 相同PDT的一群vma们
struct mm_struct {
    list_entry_t mmap_list;        // linear list link which sorted by start addr of vma    //链接了所有属于同一页目录表的虚拟内存空间（同组vma们串一起）
    struct vma_struct *mmap_cache; // current accessed vma, used for speed purpose           //当前正在使用的虚拟内存空间（同组vma中正在被使用的这个vma）
    pde_t *pgdir;                  // the PDT of these vma      //所属的PDT（组名）；通过访问pgdir可以查找某虚拟地址对应的页表项是否存在以及页表项的属性等
    int map_count;                 // the count of these vma    //有多少个组员vma
    void *sm_priv;                 // the private data for swap manager   //mm里面（按页的第一次访问时间排序）的表头，维护一个FIFO的访问队列
};

struct vma_struct *find_vma(struct mm_struct *mm, uintptr_t addr);      //在mm这个组中，看addr处于哪个vma中
struct vma_struct *vma_create(uintptr_t vm_start, uintptr_t vm_end, uint32_t vm_flags);
void insert_vma_struct(struct mm_struct *mm, struct vma_struct *vma);       //插到所属mm同组中，不是全局中

struct mm_struct *mm_create(void);      //kmalloc
void mm_destroy(struct mm_struct *mm);  //kfree 释放mm这个组中的所有vma

void vmm_init(void);        //重头戏

int do_pgfault(struct mm_struct *mm, uint32_t error_code, uintptr_t addr);      //练习一

extern volatile unsigned int pgfault_num;       //哪来的
extern struct mm_struct *check_mm_struct;       //一个用来检查的组
#endif /* !__KERN_MM_VMM_H__ */

