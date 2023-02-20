#include <swap.h>
#include <swapfs.h>
#include <swap_fifo.h>
#include <stdio.h>
#include <string.h>
#include <memlayout.h>
#include <pmm.h>
#include <mmu.h>

// the valid vaddr for check is between 0~CHECK_VALID_VADDR-1
#define CHECK_VALID_VIR_PAGE_NUM 5                               //有效的虚拟页只有5个（0x1000~0x6000）
#define BEING_CHECK_VALID_VADDR 0X1000
#define CHECK_VALID_VADDR (CHECK_VALID_VIR_PAGE_NUM+1)*0x1000    //0x6000
// the max number of valid physical page for check
#define CHECK_VALID_PHY_PAGE_NUM 4                               //有效的物理页只有4个
// the max access seq number
#define MAX_SEQ_NO 10

static struct swap_manager *sm;
size_t max_swap_offset;

volatile int swap_init_ok = 0;     //init里置为1

unsigned int swap_page[CHECK_VALID_VIR_PAGE_NUM];      //虚页5

unsigned int swap_in_seq_no[MAX_SEQ_NO],swap_out_seq_no[MAX_SEQ_NO];

static void check_swap(void);      //练习二最终check

int
swap_init(void)
{
     swapfs_init();      //fs.c：看下这个设备能放几个页（不常用的数据放在磁盘）max_swap_offset = ide_device_size(SWAP_DEV_NO) / (PGSIZE / SECTSIZE); 

     if (!(1024 <= max_swap_offset && max_swap_offset < MAX_SWAP_OFFSET_LIMIT))      //[  1024~   (1 << 24)  )     扇区号=页号（off）*8  8=4KB/512B
     {
          panic("bad max_swap_offset %08x.\n", max_swap_offset);
     }
     

     sm = &swap_manager_fifo;           //更换页替换算法
     int r = sm->init();      //fifo啥事不干返回0
     
     if (r == 0)
     {
          swap_init_ok = 1;
          cprintf("SWAP: manager = %s\n", sm->name);
          check_swap();
     }

     return r;
}

int
swap_init_mm(struct mm_struct *mm)
{
     return sm->init_mm(mm);  //priv初始化
}

int
swap_tick_event(struct mm_struct *mm)
{
     return sm->tick_event(mm); //fifo啥事不干返回0
}

int
swap_map_swappable(struct mm_struct *mm, uintptr_t addr, struct Page *page, int swap_in)
{
     return sm->map_swappable(mm, addr, page, swap_in);      //fifo把这个参数page插队列里
}

int
swap_set_unswappable(struct mm_struct *mm, uintptr_t addr)
{
     return sm->set_unswappable(mm, addr);   //fifo啥事不干返回0
}

volatile unsigned int swap_out_num=0;

int
swap_out(struct mm_struct *mm, int n, int in_tick)     //swap_out(check_mm_struct, n, 0); 在allocpage里面（消极）n为需要分配的页数
{
     int i;
     for (i = 0; i != n; ++ i)
     {
          uintptr_t v;
          //struct Page **ptr_page=NULL;
          struct Page *page;
          // cprintf("i %d, SWAP: call swap_out_victim\n",i);
          int r = sm->swap_out_victim(mm, &page, in_tick);                      //1.剔除表尾，page被复制为表尾项对应的page（被换出的页）
          if (r != 0) {
                    cprintf("i %d, swap_out: call swap_out_victim failed\n",i);
                  break;
          }          
          //assert(!PageReserved(page));

          //cprintf("SWAP: choose victim page 0x%08x\n", page);
          //2.要把被换出页的内容写进磁盘里去
          v=page->pra_vaddr;       //2.1被换出页的虚拟页起始处 ，
          pte_t *ptep = get_pte(mm->pgdir, v, 0);      //2.2找到对应pte
          assert((*ptep & PTE_P) != 0);                //最后一位PTE_P这里还是为1，表示还在物理内存！
          //3.执行写被换出页到磁盘 //被换出页的起始址addr对应的pte，前20位为页号，乘8得到读取的扇区号；在这个扇区起的8个扇区，把换出的page写进去
          if (swapfs_write( (page->pra_vaddr/PGSIZE+1)<<8, page) != 0) {   //swapfs_write(swap_entry_t entry, struct Page *page)  return ide_write_secs(SWAP_DEV_NO, swap_offset(entry) * PAGE_NSECT, page2kva(page), PAGE_NSECT); 
                    cprintf("SWAP: failed to save\n");
                    sm->map_swappable(mm, v, page, 0);      //如果写失败，恢复剔除前状态，即加回去
                    continue;
          }
          else {
                    cprintf("swap_out: i %d, store page in vaddr 0x%x to disk swap entry %d\n", i, v, page->pra_vaddr/PGSIZE+1);
                    *ptep = (page->pra_vaddr/PGSIZE+1)<<8;  //页表项就是这个被换出的页对应的vaddr/12，左移8，生成了swap_entry_t的格式，最后一位PTE_P当然变成0了，不在物理内存！！！
                    free_page(page);    //释放一个页，看分配几个页咯
          }
          
          tlb_invalidate(mm->pgdir, v); //更新tlb，访问了这个被换出页的va
     }
     return i;
}

int
swap_in(struct mm_struct *mm, uintptr_t addr, struct Page **ptr_result)    //练习一的else：swap_in(mm, addr, &page)) != 0
{
     struct Page *result = alloc_page();
     assert(result!=NULL);

     pte_t *ptep = get_pte(mm->pgdir, addr, 0);   //这里的pte一定有值，因为之前是建立过映射的，否则不可能进练习一的else
     // cprintf("SWAP: load ptep %x swap entry %d to vaddr 0x%08x, page %x, No %d\n", ptep, (*ptep)>>8, addr, result, (result-pages));
    
     int r;    //之前建立过映射的addr对应的pte，前24位为页号，乘8得到读取的扇区号；从磁盘中读取8个扇区到这个result的page里面
     if ((r = swapfs_read((*ptep), result)) != 0)  //swapfs_read(swap_entry_t entry, struct Page *page)  return ide_read_secs(SWAP_DEV_NO, swap_offset(entry) * PAGE_NSECT, page2kva(page), PAGE_NSECT); 
     {
        assert(r!=0);
     }
     cprintf("swap_in: load disk swap entry %d with swap_page in vadr 0x%x\n", (*ptep)>>8, addr);
     *ptr_result=result;      //把result返回给实参page
     return 0;
}



static inline void
check_content_set(void)
{
     *(unsigned char *)0x1000 = 0x0a;             //分别对起始地址为0x1000, 0x2000, 0x3000, 0x4000的虚拟页（一个页size为0x1000）按时间顺序先后执行写操作
     assert(pgfault_num==1);                      //vmm.c的全局变量，在do_pgfault里++；由于之前没有建立页表，所以会产生page fault异常
     *(unsigned char *)0x1010 = 0x0a;             
     assert(pgfault_num==1);
     *(unsigned char *)0x2000 = 0x0b;             //第二个页
     assert(pgfault_num==2);
     *(unsigned char *)0x2010 = 0x0b;
     assert(pgfault_num==2);
     *(unsigned char *)0x3000 = 0x0c;             //第三个页
     assert(pgfault_num==3);
     *(unsigned char *)0x3010 = 0x0c;
     assert(pgfault_num==3);
     *(unsigned char *)0x4000 = 0x0d;             //第四个页
     assert(pgfault_num==4);
     *(unsigned char *)0x4010 = 0x0d;             //这些从4KB~20KB的4虚拟页会与ucore保存的4个物理页帧建立映射关系；
     assert(pgfault_num==4);
}

static inline int
check_content_access(void)
{
    int ret = sm->check_swap();                   //调用fifio的swap
    return ret;
}

struct Page * check_rp[CHECK_VALID_PHY_PAGE_NUM];             //4
pte_t * check_ptep[CHECK_VALID_PHY_PAGE_NUM];                //4
unsigned int check_swap_addr[CHECK_VALID_VIR_PAGE_NUM];     //4

extern free_area_t free_area;

#define free_list (free_area.free_list)
#define nr_free (free_area.nr_free)

static void
check_swap(void)         //init里面调
{
    //backup mem env
     int ret, count = 0, total = 0, i;
     list_entry_t *le = &free_list;
     while ((le = list_next(le)) != &free_list) {
        struct Page *p = le2page(le, page_link);
        assert(PageProperty(p));
        count ++, total += p->property;
     }
     assert(total == nr_free_pages());
     cprintf("BEGIN check_swap: count %d, total %d\n",count,total);
     
     //now we set the phy pages env     
     struct mm_struct *mm = mm_create();
     assert(mm != NULL);

     extern struct mm_struct *check_mm_struct;
     assert(check_mm_struct == NULL);

     check_mm_struct = mm;

     pde_t *pgdir = mm->pgdir = boot_pgdir;
     assert(pgdir[0] == 0);

     struct vma_struct *vma = vma_create(BEING_CHECK_VALID_VADDR, CHECK_VALID_VADDR, VM_WRITE | VM_READ);     //0X1000，0x1000*6，设置合法的访问范围为4KB~24KB；
     assert(vma != NULL);

     insert_vma_struct(mm, vma);

     //setup the temp Page Table vaddr 0~4MB
     cprintf("setup Page Table for vaddr 0X1000, so alloc a page\n");
     pte_t *temp_ptep=NULL;
     //mm->pgdir[PDX(BEING CHECK_VALID_VADDR)]在这里，0
     temp_ptep = get_pte(mm->pgdir, BEING_CHECK_VALID_VADDR, 1);      //拿到0X1000对应的pte，没有就创建
     //mm->pgdir[PDX(BEING CHECK_VALID_VADDR)]在这里，30a097          //在页目录表中索引第0项，然后新开了一张一级页表
     assert(temp_ptep!= NULL);
     cprintf("setup Page Table vaddr 0~4MB OVER!\n");                 
     
     for (i=0;i<CHECK_VALID_PHY_PAGE_NUM;i++) {        //4.
          check_rp[i] = alloc_page();
          assert(check_rp[i] != NULL );
          assert(!PageProperty(check_rp[i]));
     }
     list_entry_t free_list_store = free_list;
     list_init(&free_list);                       //清掉了
     assert(list_empty(&free_list));
     
     //assert(alloc_page() == NULL);
     
     unsigned int nr_free_store = nr_free;
     nr_free = 0;                                 //清0
     for (i=0;i<CHECK_VALID_PHY_PAGE_NUM;i++) {
        free_pages(check_rp[i],1);                //释放四个页 调用free_page等操作，模拟形成一个只有4个空闲 physical page；并设置了从4KB~24KB的连续5个虚拟页的访问操作；
     }
     assert(nr_free==CHECK_VALID_PHY_PAGE_NUM);   //nr_free为4个空闲页
     
     cprintf("set up init env for check_swap begin!\n");
     //setup initial vir_page<->phy_page environment for page relpacement algorithm 

     
     pgfault_num=0;
     
     check_content_set();               //1.连续访问4个页，缺四次，然后建立四个映射
     assert( nr_free == 0);         
     for(i = 0; i<MAX_SEQ_NO ; i++)          //10
         swap_out_seq_no[i]=swap_in_seq_no[i]=-1;
     
     for (i= 0;i<CHECK_VALID_PHY_PAGE_NUM;i++) {  //4
         check_ptep[i]=0;
         check_ptep[i] = get_pte(pgdir, (i+1)*0x1000, 0);   //对应这四个la的pte，已经建好映射，就能拿到
         //cprintf("i %d, check_ptep addr %x, value %x\n", i, check_ptep[i], *check_ptep[i]);
         assert(check_ptep[i] != NULL);
         assert(pte2page(*check_ptep[i]) == check_rp[i]);
         assert((*check_ptep[i] & PTE_P));          
     }
     cprintf("set up init env for check_swap over!\n");
     // now access the virt pages to test  page relpacement algorithm 
     ret=check_content_access();   //2.访问虚页测试fifo
     assert(ret==0);
     
     //restore kernel mem env
     for (i=0;i<CHECK_VALID_PHY_PAGE_NUM;i++) {
         free_pages(check_rp[i],1);
     } 

     //free_page(pte2page(*temp_ptep));
     
     mm_destroy(mm);
         
     nr_free = nr_free_store;
     free_list = free_list_store;

     
     le = &free_list;
     while ((le = list_next(le)) != &free_list) {
         struct Page *p = le2page(le, page_link);
         count --, total -= p->property;
     }
     cprintf("count is %d, total is %d\n",count,total);
     //assert(count == 0);
     
     cprintf("check_swap() succeeded!\n");
}
