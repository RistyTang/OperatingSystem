#ifndef __KERN_FS_FS_H__
#define __KERN_FS_FS_H__

#include <mmu.h>

#define SECTSIZE            512
#define PAGE_NSECT          (PGSIZE / SECTSIZE)     //8

#define SWAP_DEV_NO         1                       //设备号ideno是1

#endif /* !__KERN_FS_FS_H__ */

