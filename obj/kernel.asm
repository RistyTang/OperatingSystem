
bin/kernel:     file format elf32-i386


Disassembly of section .text:

c0100000 <kern_entry>:

.text
.globl kern_entry
kern_entry:
    # load pa of boot pgdir
    movl $REALLOC(__boot_pgdir), %eax
c0100000:	b8 00 60 12 00       	mov    $0x126000,%eax
    movl %eax, %cr3                           #把页目录表的起始地址存入CR3寄存器中
c0100005:	0f 22 d8             	mov    %eax,%cr3

    # enable paging
    movl %cr0, %eax
c0100008:	0f 20 c0             	mov    %cr0,%eax
    orl $(CR0_PE | CR0_PG | CR0_AM | CR0_WP | CR0_NE | CR0_TS | CR0_EM | CR0_MP), %eax
c010000b:	0d 2f 00 05 80       	or     $0x8005002f,%eax
    andl $~(CR0_TS | CR0_EM), %eax
c0100010:	83 e0 f3             	and    $0xfffffff3,%eax
    movl %eax, %cr0                           #把cr0中的CR0_PG标志位设置上。使能分页模式！！！
c0100013:	0f 22 c0             	mov    %eax,%cr0

    # update eip        此时的内核（EIP）还在0~4M的低虚拟地址区域（之后给用户程序使用）运行，需要使用一个绝对跳转来使内核跳转到高虚拟地址。
    # now, eip = 0x1.....
    leal next, %eax
c0100016:	8d 05 1e 00 10 c0    	lea    0xc010001e,%eax
    # set eip = KERNBASE + 0x1.....
    jmp *%eax
c010001c:	ff e0                	jmp    *%eax

c010001e <next>:
next:

    # unmap va 0 ~ 4M, it's temporary mapping   通过把boot_pgdir[0]对应的第一个页目录表项（0~4MB）清零来取消了临时的页映射关系
    xorl %eax, %eax
c010001e:	31 c0                	xor    %eax,%eax
    movl %eax, __boot_pgdir
c0100020:	a3 00 60 12 c0       	mov    %eax,0xc0126000

    # set ebp, esp
    movl $0x0, %ebp
c0100025:	bd 00 00 00 00       	mov    $0x0,%ebp
    # the kernel stack region is from bootstack -- bootstacktop,
    # the kernel stack size is KSTACKSIZE (8KB)defined in memlayout.h
    movl $bootstacktop, %esp
c010002a:	bc 00 50 12 c0       	mov    $0xc0125000,%esp
    # now kernel stack is ready , call the first C function
    call kern_init
c010002f:	e8 02 00 00 00       	call   c0100036 <kern_init>

c0100034 <spin>:

# should never get here
spin:
    jmp spin
c0100034:	eb fe                	jmp    c0100034 <spin>

c0100036 <kern_init>:
void grade_backtrace(void);
static void lab1_switch_test(void);

//在entry.S中调用
int
kern_init(void) {
c0100036:	55                   	push   %ebp
c0100037:	89 e5                	mov    %esp,%ebp
c0100039:	83 ec 28             	sub    $0x28,%esp
    extern char edata[], end[];
    memset(edata, 0, end - edata);
c010003c:	ba 58 b1 12 c0       	mov    $0xc012b158,%edx
c0100041:	b8 00 80 12 c0       	mov    $0xc0128000,%eax
c0100046:	29 c2                	sub    %eax,%edx
c0100048:	89 d0                	mov    %edx,%eax
c010004a:	89 44 24 08          	mov    %eax,0x8(%esp)
c010004e:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
c0100055:	00 
c0100056:	c7 04 24 00 80 12 c0 	movl   $0xc0128000,(%esp)
c010005d:	e8 41 94 00 00       	call   c01094a3 <memset>

    cons_init();                // init the console
c0100062:	e8 25 1d 00 00       	call   c0101d8c <cons_init>

    const char *message = "(THU.CST) os is loading ...";
c0100067:	c7 45 f4 a0 9d 10 c0 	movl   $0xc0109da0,-0xc(%ebp)
    cprintf("%s\n\n", message);
c010006e:	8b 45 f4             	mov    -0xc(%ebp),%eax
c0100071:	89 44 24 04          	mov    %eax,0x4(%esp)
c0100075:	c7 04 24 bc 9d 10 c0 	movl   $0xc0109dbc,(%esp)
c010007c:	e8 28 02 00 00       	call   c01002a9 <cprintf>

    print_kerninfo();
c0100081:	e8 c9 08 00 00       	call   c010094f <print_kerninfo>

    grade_backtrace();
c0100086:	e8 a0 00 00 00       	call   c010012b <grade_backtrace>

    pmm_init();                 // init physical memory management lab2
c010008b:	e8 b4 39 00 00       	call   c0103a44 <pmm_init>

    pic_init();                 // init interrupt controller
c0100090:	e8 5c 1e 00 00       	call   c0101ef1 <pic_init>
    idt_init();                 // init interrupt descriptor table lab1
c0100095:	e8 e1 1f 00 00       	call   c010207b <idt_init>

    vmm_init();                 // init virtual memory management lab3
c010009a:	e8 9f 54 00 00       	call   c010553e <vmm_init>
    proc_init();                // init process table   新加的！！418
c010009f:	e8 b9 8d 00 00       	call   c0108e5d <proc_init>
    
    ide_init();                 // init ide devices lab3
c01000a4:	e8 9b 0c 00 00       	call   c0100d44 <ide_init>
    swap_init();                // init swap lab3
c01000a9:	e8 8f 65 00 00       	call   c010663d <swap_init>

    clock_init();               // init clock interrupt
c01000ae:	e8 7c 14 00 00       	call   c010152f <clock_init>
    intr_enable();              // enable irq interrupt
c01000b3:	e8 73 1f 00 00       	call   c010202b <intr_enable>

    //LAB1: CAHLLENGE 1 If you try to do it, uncomment lab1_switch_test()
    // user/kernel mode switch test
    //lab1_switch_test();
    //进行cpu的调度
    cpu_idle();                 // run idle process     新加的！！
c01000b8:	e8 5d 8f 00 00       	call   c010901a <cpu_idle>

c01000bd <grade_backtrace2>:
}

void __attribute__((noinline))
grade_backtrace2(int arg0, int arg1, int arg2, int arg3) {
c01000bd:	55                   	push   %ebp
c01000be:	89 e5                	mov    %esp,%ebp
c01000c0:	83 ec 18             	sub    $0x18,%esp
    mon_backtrace(0, NULL, NULL);
c01000c3:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
c01000ca:	00 
c01000cb:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
c01000d2:	00 
c01000d3:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
c01000da:	e8 fa 0b 00 00       	call   c0100cd9 <mon_backtrace>
}
c01000df:	90                   	nop
c01000e0:	c9                   	leave  
c01000e1:	c3                   	ret    

c01000e2 <grade_backtrace1>:

void __attribute__((noinline))
grade_backtrace1(int arg0, int arg1) {
c01000e2:	55                   	push   %ebp
c01000e3:	89 e5                	mov    %esp,%ebp
c01000e5:	53                   	push   %ebx
c01000e6:	83 ec 14             	sub    $0x14,%esp
    grade_backtrace2(arg0, (int)&arg0, arg1, (int)&arg1);
c01000e9:	8d 4d 0c             	lea    0xc(%ebp),%ecx
c01000ec:	8b 55 0c             	mov    0xc(%ebp),%edx
c01000ef:	8d 5d 08             	lea    0x8(%ebp),%ebx
c01000f2:	8b 45 08             	mov    0x8(%ebp),%eax
c01000f5:	89 4c 24 0c          	mov    %ecx,0xc(%esp)
c01000f9:	89 54 24 08          	mov    %edx,0x8(%esp)
c01000fd:	89 5c 24 04          	mov    %ebx,0x4(%esp)
c0100101:	89 04 24             	mov    %eax,(%esp)
c0100104:	e8 b4 ff ff ff       	call   c01000bd <grade_backtrace2>
}
c0100109:	90                   	nop
c010010a:	83 c4 14             	add    $0x14,%esp
c010010d:	5b                   	pop    %ebx
c010010e:	5d                   	pop    %ebp
c010010f:	c3                   	ret    

c0100110 <grade_backtrace0>:

void __attribute__((noinline))
grade_backtrace0(int arg0, int arg1, int arg2) {
c0100110:	55                   	push   %ebp
c0100111:	89 e5                	mov    %esp,%ebp
c0100113:	83 ec 18             	sub    $0x18,%esp
    grade_backtrace1(arg0, arg2);
c0100116:	8b 45 10             	mov    0x10(%ebp),%eax
c0100119:	89 44 24 04          	mov    %eax,0x4(%esp)
c010011d:	8b 45 08             	mov    0x8(%ebp),%eax
c0100120:	89 04 24             	mov    %eax,(%esp)
c0100123:	e8 ba ff ff ff       	call   c01000e2 <grade_backtrace1>
}
c0100128:	90                   	nop
c0100129:	c9                   	leave  
c010012a:	c3                   	ret    

c010012b <grade_backtrace>:

void
grade_backtrace(void) {
c010012b:	55                   	push   %ebp
c010012c:	89 e5                	mov    %esp,%ebp
c010012e:	83 ec 18             	sub    $0x18,%esp
    grade_backtrace0(0, (int)kern_init, 0xffff0000);
c0100131:	b8 36 00 10 c0       	mov    $0xc0100036,%eax
c0100136:	c7 44 24 08 00 00 ff 	movl   $0xffff0000,0x8(%esp)
c010013d:	ff 
c010013e:	89 44 24 04          	mov    %eax,0x4(%esp)
c0100142:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
c0100149:	e8 c2 ff ff ff       	call   c0100110 <grade_backtrace0>
}
c010014e:	90                   	nop
c010014f:	c9                   	leave  
c0100150:	c3                   	ret    

c0100151 <lab1_print_cur_status>:

static void
lab1_print_cur_status(void) {
c0100151:	55                   	push   %ebp
c0100152:	89 e5                	mov    %esp,%ebp
c0100154:	83 ec 28             	sub    $0x28,%esp
    static int round = 0;
    uint16_t reg1, reg2, reg3, reg4;
    asm volatile (
c0100157:	8c 4d f6             	mov    %cs,-0xa(%ebp)
c010015a:	8c 5d f4             	mov    %ds,-0xc(%ebp)
c010015d:	8c 45 f2             	mov    %es,-0xe(%ebp)
c0100160:	8c 55 f0             	mov    %ss,-0x10(%ebp)
            "mov %%cs, %0;"
            "mov %%ds, %1;"
            "mov %%es, %2;"
            "mov %%ss, %3;"
            : "=m"(reg1), "=m"(reg2), "=m"(reg3), "=m"(reg4));
    cprintf("%d: @ring %d\n", round, reg1 & 3);
c0100163:	0f b7 45 f6          	movzwl -0xa(%ebp),%eax
c0100167:	83 e0 03             	and    $0x3,%eax
c010016a:	89 c2                	mov    %eax,%edx
c010016c:	a1 00 80 12 c0       	mov    0xc0128000,%eax
c0100171:	89 54 24 08          	mov    %edx,0x8(%esp)
c0100175:	89 44 24 04          	mov    %eax,0x4(%esp)
c0100179:	c7 04 24 c1 9d 10 c0 	movl   $0xc0109dc1,(%esp)
c0100180:	e8 24 01 00 00       	call   c01002a9 <cprintf>
    cprintf("%d:  cs = %x\n", round, reg1);
c0100185:	0f b7 45 f6          	movzwl -0xa(%ebp),%eax
c0100189:	89 c2                	mov    %eax,%edx
c010018b:	a1 00 80 12 c0       	mov    0xc0128000,%eax
c0100190:	89 54 24 08          	mov    %edx,0x8(%esp)
c0100194:	89 44 24 04          	mov    %eax,0x4(%esp)
c0100198:	c7 04 24 cf 9d 10 c0 	movl   $0xc0109dcf,(%esp)
c010019f:	e8 05 01 00 00       	call   c01002a9 <cprintf>
    cprintf("%d:  ds = %x\n", round, reg2);
c01001a4:	0f b7 45 f4          	movzwl -0xc(%ebp),%eax
c01001a8:	89 c2                	mov    %eax,%edx
c01001aa:	a1 00 80 12 c0       	mov    0xc0128000,%eax
c01001af:	89 54 24 08          	mov    %edx,0x8(%esp)
c01001b3:	89 44 24 04          	mov    %eax,0x4(%esp)
c01001b7:	c7 04 24 dd 9d 10 c0 	movl   $0xc0109ddd,(%esp)
c01001be:	e8 e6 00 00 00       	call   c01002a9 <cprintf>
    cprintf("%d:  es = %x\n", round, reg3);
c01001c3:	0f b7 45 f2          	movzwl -0xe(%ebp),%eax
c01001c7:	89 c2                	mov    %eax,%edx
c01001c9:	a1 00 80 12 c0       	mov    0xc0128000,%eax
c01001ce:	89 54 24 08          	mov    %edx,0x8(%esp)
c01001d2:	89 44 24 04          	mov    %eax,0x4(%esp)
c01001d6:	c7 04 24 eb 9d 10 c0 	movl   $0xc0109deb,(%esp)
c01001dd:	e8 c7 00 00 00       	call   c01002a9 <cprintf>
    cprintf("%d:  ss = %x\n", round, reg4);
c01001e2:	0f b7 45 f0          	movzwl -0x10(%ebp),%eax
c01001e6:	89 c2                	mov    %eax,%edx
c01001e8:	a1 00 80 12 c0       	mov    0xc0128000,%eax
c01001ed:	89 54 24 08          	mov    %edx,0x8(%esp)
c01001f1:	89 44 24 04          	mov    %eax,0x4(%esp)
c01001f5:	c7 04 24 f9 9d 10 c0 	movl   $0xc0109df9,(%esp)
c01001fc:	e8 a8 00 00 00       	call   c01002a9 <cprintf>
    round ++;
c0100201:	a1 00 80 12 c0       	mov    0xc0128000,%eax
c0100206:	40                   	inc    %eax
c0100207:	a3 00 80 12 c0       	mov    %eax,0xc0128000
}
c010020c:	90                   	nop
c010020d:	c9                   	leave  
c010020e:	c3                   	ret    

c010020f <lab1_switch_to_user>:

static void
lab1_switch_to_user(void) {
c010020f:	55                   	push   %ebp
c0100210:	89 e5                	mov    %esp,%ebp
    //LAB1 CHALLENGE 1 : TODO
}
c0100212:	90                   	nop
c0100213:	5d                   	pop    %ebp
c0100214:	c3                   	ret    

c0100215 <lab1_switch_to_kernel>:

static void
lab1_switch_to_kernel(void) {
c0100215:	55                   	push   %ebp
c0100216:	89 e5                	mov    %esp,%ebp
    //LAB1 CHALLENGE 1 :  TODO
}
c0100218:	90                   	nop
c0100219:	5d                   	pop    %ebp
c010021a:	c3                   	ret    

c010021b <lab1_switch_test>:

static void
lab1_switch_test(void) {
c010021b:	55                   	push   %ebp
c010021c:	89 e5                	mov    %esp,%ebp
c010021e:	83 ec 18             	sub    $0x18,%esp
    lab1_print_cur_status();
c0100221:	e8 2b ff ff ff       	call   c0100151 <lab1_print_cur_status>
    cprintf("+++ switch to  user  mode +++\n");
c0100226:	c7 04 24 08 9e 10 c0 	movl   $0xc0109e08,(%esp)
c010022d:	e8 77 00 00 00       	call   c01002a9 <cprintf>
    lab1_switch_to_user();
c0100232:	e8 d8 ff ff ff       	call   c010020f <lab1_switch_to_user>
    lab1_print_cur_status();
c0100237:	e8 15 ff ff ff       	call   c0100151 <lab1_print_cur_status>
    cprintf("+++ switch to kernel mode +++\n");
c010023c:	c7 04 24 28 9e 10 c0 	movl   $0xc0109e28,(%esp)
c0100243:	e8 61 00 00 00       	call   c01002a9 <cprintf>
    lab1_switch_to_kernel();
c0100248:	e8 c8 ff ff ff       	call   c0100215 <lab1_switch_to_kernel>
    lab1_print_cur_status();
c010024d:	e8 ff fe ff ff       	call   c0100151 <lab1_print_cur_status>
}
c0100252:	90                   	nop
c0100253:	c9                   	leave  
c0100254:	c3                   	ret    

c0100255 <cputch>:
/* *
 * cputch - writes a single character @c to stdout, and it will
 * increace the value of counter pointed by @cnt.
 * */
static void
cputch(int c, int *cnt) {
c0100255:	55                   	push   %ebp
c0100256:	89 e5                	mov    %esp,%ebp
c0100258:	83 ec 18             	sub    $0x18,%esp
    cons_putc(c);
c010025b:	8b 45 08             	mov    0x8(%ebp),%eax
c010025e:	89 04 24             	mov    %eax,(%esp)
c0100261:	e8 53 1b 00 00       	call   c0101db9 <cons_putc>
    (*cnt) ++;
c0100266:	8b 45 0c             	mov    0xc(%ebp),%eax
c0100269:	8b 00                	mov    (%eax),%eax
c010026b:	8d 50 01             	lea    0x1(%eax),%edx
c010026e:	8b 45 0c             	mov    0xc(%ebp),%eax
c0100271:	89 10                	mov    %edx,(%eax)
}
c0100273:	90                   	nop
c0100274:	c9                   	leave  
c0100275:	c3                   	ret    

c0100276 <vcprintf>:
 *
 * Call this function if you are already dealing with a va_list.
 * Or you probably want cprintf() instead.
 * */
int
vcprintf(const char *fmt, va_list ap) {
c0100276:	55                   	push   %ebp
c0100277:	89 e5                	mov    %esp,%ebp
c0100279:	83 ec 28             	sub    $0x28,%esp
    int cnt = 0;
c010027c:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
    vprintfmt((void*)cputch, &cnt, fmt, ap);
c0100283:	8b 45 0c             	mov    0xc(%ebp),%eax
c0100286:	89 44 24 0c          	mov    %eax,0xc(%esp)
c010028a:	8b 45 08             	mov    0x8(%ebp),%eax
c010028d:	89 44 24 08          	mov    %eax,0x8(%esp)
c0100291:	8d 45 f4             	lea    -0xc(%ebp),%eax
c0100294:	89 44 24 04          	mov    %eax,0x4(%esp)
c0100298:	c7 04 24 55 02 10 c0 	movl   $0xc0100255,(%esp)
c010029f:	e8 52 95 00 00       	call   c01097f6 <vprintfmt>
    return cnt;
c01002a4:	8b 45 f4             	mov    -0xc(%ebp),%eax
}
c01002a7:	c9                   	leave  
c01002a8:	c3                   	ret    

c01002a9 <cprintf>:
 *
 * The return value is the number of characters which would be
 * written to stdout.
 * */
int
cprintf(const char *fmt, ...) {
c01002a9:	55                   	push   %ebp
c01002aa:	89 e5                	mov    %esp,%ebp
c01002ac:	83 ec 28             	sub    $0x28,%esp
    va_list ap;
    int cnt;
    va_start(ap, fmt);
c01002af:	8d 45 0c             	lea    0xc(%ebp),%eax
c01002b2:	89 45 f0             	mov    %eax,-0x10(%ebp)
    cnt = vcprintf(fmt, ap);
c01002b5:	8b 45 f0             	mov    -0x10(%ebp),%eax
c01002b8:	89 44 24 04          	mov    %eax,0x4(%esp)
c01002bc:	8b 45 08             	mov    0x8(%ebp),%eax
c01002bf:	89 04 24             	mov    %eax,(%esp)
c01002c2:	e8 af ff ff ff       	call   c0100276 <vcprintf>
c01002c7:	89 45 f4             	mov    %eax,-0xc(%ebp)
    va_end(ap);
    return cnt;
c01002ca:	8b 45 f4             	mov    -0xc(%ebp),%eax
}
c01002cd:	c9                   	leave  
c01002ce:	c3                   	ret    

c01002cf <cputchar>:

/* cputchar - writes a single character to stdout */
void
cputchar(int c) {
c01002cf:	55                   	push   %ebp
c01002d0:	89 e5                	mov    %esp,%ebp
c01002d2:	83 ec 18             	sub    $0x18,%esp
    cons_putc(c);
c01002d5:	8b 45 08             	mov    0x8(%ebp),%eax
c01002d8:	89 04 24             	mov    %eax,(%esp)
c01002db:	e8 d9 1a 00 00       	call   c0101db9 <cons_putc>
}
c01002e0:	90                   	nop
c01002e1:	c9                   	leave  
c01002e2:	c3                   	ret    

c01002e3 <cputs>:
/* *
 * cputs- writes the string pointed by @str to stdout and
 * appends a newline character.
 * */
int
cputs(const char *str) {
c01002e3:	55                   	push   %ebp
c01002e4:	89 e5                	mov    %esp,%ebp
c01002e6:	83 ec 28             	sub    $0x28,%esp
    int cnt = 0;
c01002e9:	c7 45 f0 00 00 00 00 	movl   $0x0,-0x10(%ebp)
    char c;
    while ((c = *str ++) != '\0') {
c01002f0:	eb 13                	jmp    c0100305 <cputs+0x22>
        cputch(c, &cnt);
c01002f2:	0f be 45 f7          	movsbl -0x9(%ebp),%eax
c01002f6:	8d 55 f0             	lea    -0x10(%ebp),%edx
c01002f9:	89 54 24 04          	mov    %edx,0x4(%esp)
c01002fd:	89 04 24             	mov    %eax,(%esp)
c0100300:	e8 50 ff ff ff       	call   c0100255 <cputch>
    while ((c = *str ++) != '\0') {
c0100305:	8b 45 08             	mov    0x8(%ebp),%eax
c0100308:	8d 50 01             	lea    0x1(%eax),%edx
c010030b:	89 55 08             	mov    %edx,0x8(%ebp)
c010030e:	0f b6 00             	movzbl (%eax),%eax
c0100311:	88 45 f7             	mov    %al,-0x9(%ebp)
c0100314:	80 7d f7 00          	cmpb   $0x0,-0x9(%ebp)
c0100318:	75 d8                	jne    c01002f2 <cputs+0xf>
    }
    cputch('\n', &cnt);
c010031a:	8d 45 f0             	lea    -0x10(%ebp),%eax
c010031d:	89 44 24 04          	mov    %eax,0x4(%esp)
c0100321:	c7 04 24 0a 00 00 00 	movl   $0xa,(%esp)
c0100328:	e8 28 ff ff ff       	call   c0100255 <cputch>
    return cnt;
c010032d:	8b 45 f0             	mov    -0x10(%ebp),%eax
}
c0100330:	c9                   	leave  
c0100331:	c3                   	ret    

c0100332 <getchar>:

/* getchar - reads a single non-zero character from stdin */
int
getchar(void) {
c0100332:	55                   	push   %ebp
c0100333:	89 e5                	mov    %esp,%ebp
c0100335:	83 ec 18             	sub    $0x18,%esp
    int c;
    while ((c = cons_getc()) == 0)
c0100338:	e8 b9 1a 00 00       	call   c0101df6 <cons_getc>
c010033d:	89 45 f4             	mov    %eax,-0xc(%ebp)
c0100340:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
c0100344:	74 f2                	je     c0100338 <getchar+0x6>
        /* do nothing */;
    return c;
c0100346:	8b 45 f4             	mov    -0xc(%ebp),%eax
}
c0100349:	c9                   	leave  
c010034a:	c3                   	ret    

c010034b <readline>:
 * The readline() function returns the text of the line read. If some errors
 * are happened, NULL is returned. The return value is a global variable,
 * thus it should be copied before it is used.
 * */
char *
readline(const char *prompt) {
c010034b:	55                   	push   %ebp
c010034c:	89 e5                	mov    %esp,%ebp
c010034e:	83 ec 28             	sub    $0x28,%esp
    if (prompt != NULL) {
c0100351:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
c0100355:	74 13                	je     c010036a <readline+0x1f>
        cprintf("%s", prompt);
c0100357:	8b 45 08             	mov    0x8(%ebp),%eax
c010035a:	89 44 24 04          	mov    %eax,0x4(%esp)
c010035e:	c7 04 24 47 9e 10 c0 	movl   $0xc0109e47,(%esp)
c0100365:	e8 3f ff ff ff       	call   c01002a9 <cprintf>
    }
    int i = 0, c;
c010036a:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
    while (1) {
        c = getchar();
c0100371:	e8 bc ff ff ff       	call   c0100332 <getchar>
c0100376:	89 45 f0             	mov    %eax,-0x10(%ebp)
        if (c < 0) {
c0100379:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
c010037d:	79 07                	jns    c0100386 <readline+0x3b>
            return NULL;
c010037f:	b8 00 00 00 00       	mov    $0x0,%eax
c0100384:	eb 78                	jmp    c01003fe <readline+0xb3>
        }
        else if (c >= ' ' && i < BUFSIZE - 1) {
c0100386:	83 7d f0 1f          	cmpl   $0x1f,-0x10(%ebp)
c010038a:	7e 28                	jle    c01003b4 <readline+0x69>
c010038c:	81 7d f4 fe 03 00 00 	cmpl   $0x3fe,-0xc(%ebp)
c0100393:	7f 1f                	jg     c01003b4 <readline+0x69>
            cputchar(c);
c0100395:	8b 45 f0             	mov    -0x10(%ebp),%eax
c0100398:	89 04 24             	mov    %eax,(%esp)
c010039b:	e8 2f ff ff ff       	call   c01002cf <cputchar>
            buf[i ++] = c;
c01003a0:	8b 45 f4             	mov    -0xc(%ebp),%eax
c01003a3:	8d 50 01             	lea    0x1(%eax),%edx
c01003a6:	89 55 f4             	mov    %edx,-0xc(%ebp)
c01003a9:	8b 55 f0             	mov    -0x10(%ebp),%edx
c01003ac:	88 90 20 80 12 c0    	mov    %dl,-0x3fed7fe0(%eax)
c01003b2:	eb 45                	jmp    c01003f9 <readline+0xae>
        }
        else if (c == '\b' && i > 0) {
c01003b4:	83 7d f0 08          	cmpl   $0x8,-0x10(%ebp)
c01003b8:	75 16                	jne    c01003d0 <readline+0x85>
c01003ba:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
c01003be:	7e 10                	jle    c01003d0 <readline+0x85>
            cputchar(c);
c01003c0:	8b 45 f0             	mov    -0x10(%ebp),%eax
c01003c3:	89 04 24             	mov    %eax,(%esp)
c01003c6:	e8 04 ff ff ff       	call   c01002cf <cputchar>
            i --;
c01003cb:	ff 4d f4             	decl   -0xc(%ebp)
c01003ce:	eb 29                	jmp    c01003f9 <readline+0xae>
        }
        else if (c == '\n' || c == '\r') {
c01003d0:	83 7d f0 0a          	cmpl   $0xa,-0x10(%ebp)
c01003d4:	74 06                	je     c01003dc <readline+0x91>
c01003d6:	83 7d f0 0d          	cmpl   $0xd,-0x10(%ebp)
c01003da:	75 95                	jne    c0100371 <readline+0x26>
            cputchar(c);
c01003dc:	8b 45 f0             	mov    -0x10(%ebp),%eax
c01003df:	89 04 24             	mov    %eax,(%esp)
c01003e2:	e8 e8 fe ff ff       	call   c01002cf <cputchar>
            buf[i] = '\0';
c01003e7:	8b 45 f4             	mov    -0xc(%ebp),%eax
c01003ea:	05 20 80 12 c0       	add    $0xc0128020,%eax
c01003ef:	c6 00 00             	movb   $0x0,(%eax)
            return buf;
c01003f2:	b8 20 80 12 c0       	mov    $0xc0128020,%eax
c01003f7:	eb 05                	jmp    c01003fe <readline+0xb3>
        c = getchar();
c01003f9:	e9 73 ff ff ff       	jmp    c0100371 <readline+0x26>
        }
    }
}
c01003fe:	c9                   	leave  
c01003ff:	c3                   	ret    

c0100400 <__panic>:
/* *
 * __panic - __panic is called on unresolvable fatal errors. it prints
 * "panic: 'message'", and then enters the kernel monitor.
 * */
void
__panic(const char *file, int line, const char *fmt, ...) {
c0100400:	55                   	push   %ebp
c0100401:	89 e5                	mov    %esp,%ebp
c0100403:	83 ec 28             	sub    $0x28,%esp
    if (is_panic) {
c0100406:	a1 20 84 12 c0       	mov    0xc0128420,%eax
c010040b:	85 c0                	test   %eax,%eax
c010040d:	75 5b                	jne    c010046a <__panic+0x6a>
        goto panic_dead;
    }
    is_panic = 1;
c010040f:	c7 05 20 84 12 c0 01 	movl   $0x1,0xc0128420
c0100416:	00 00 00 

    // print the 'message'
    va_list ap;
    va_start(ap, fmt);
c0100419:	8d 45 14             	lea    0x14(%ebp),%eax
c010041c:	89 45 f4             	mov    %eax,-0xc(%ebp)
    cprintf("kernel panic at %s:%d:\n    ", file, line);
c010041f:	8b 45 0c             	mov    0xc(%ebp),%eax
c0100422:	89 44 24 08          	mov    %eax,0x8(%esp)
c0100426:	8b 45 08             	mov    0x8(%ebp),%eax
c0100429:	89 44 24 04          	mov    %eax,0x4(%esp)
c010042d:	c7 04 24 4a 9e 10 c0 	movl   $0xc0109e4a,(%esp)
c0100434:	e8 70 fe ff ff       	call   c01002a9 <cprintf>
    vcprintf(fmt, ap);
c0100439:	8b 45 f4             	mov    -0xc(%ebp),%eax
c010043c:	89 44 24 04          	mov    %eax,0x4(%esp)
c0100440:	8b 45 10             	mov    0x10(%ebp),%eax
c0100443:	89 04 24             	mov    %eax,(%esp)
c0100446:	e8 2b fe ff ff       	call   c0100276 <vcprintf>
    cprintf("\n");
c010044b:	c7 04 24 66 9e 10 c0 	movl   $0xc0109e66,(%esp)
c0100452:	e8 52 fe ff ff       	call   c01002a9 <cprintf>
    
    cprintf("stack trackback:\n");
c0100457:	c7 04 24 68 9e 10 c0 	movl   $0xc0109e68,(%esp)
c010045e:	e8 46 fe ff ff       	call   c01002a9 <cprintf>
    print_stackframe();
c0100463:	e8 32 06 00 00       	call   c0100a9a <print_stackframe>
c0100468:	eb 01                	jmp    c010046b <__panic+0x6b>
        goto panic_dead;
c010046a:	90                   	nop
    
    va_end(ap);

panic_dead:
    intr_disable();
c010046b:	e8 c2 1b 00 00       	call   c0102032 <intr_disable>
    while (1) {
        kmonitor(NULL);
c0100470:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
c0100477:	e8 90 07 00 00       	call   c0100c0c <kmonitor>
c010047c:	eb f2                	jmp    c0100470 <__panic+0x70>

c010047e <__warn>:
    }
}

/* __warn - like panic, but don't */
void
__warn(const char *file, int line, const char *fmt, ...) {
c010047e:	55                   	push   %ebp
c010047f:	89 e5                	mov    %esp,%ebp
c0100481:	83 ec 28             	sub    $0x28,%esp
    va_list ap;
    va_start(ap, fmt);
c0100484:	8d 45 14             	lea    0x14(%ebp),%eax
c0100487:	89 45 f4             	mov    %eax,-0xc(%ebp)
    cprintf("kernel warning at %s:%d:\n    ", file, line);
c010048a:	8b 45 0c             	mov    0xc(%ebp),%eax
c010048d:	89 44 24 08          	mov    %eax,0x8(%esp)
c0100491:	8b 45 08             	mov    0x8(%ebp),%eax
c0100494:	89 44 24 04          	mov    %eax,0x4(%esp)
c0100498:	c7 04 24 7a 9e 10 c0 	movl   $0xc0109e7a,(%esp)
c010049f:	e8 05 fe ff ff       	call   c01002a9 <cprintf>
    vcprintf(fmt, ap);
c01004a4:	8b 45 f4             	mov    -0xc(%ebp),%eax
c01004a7:	89 44 24 04          	mov    %eax,0x4(%esp)
c01004ab:	8b 45 10             	mov    0x10(%ebp),%eax
c01004ae:	89 04 24             	mov    %eax,(%esp)
c01004b1:	e8 c0 fd ff ff       	call   c0100276 <vcprintf>
    cprintf("\n");
c01004b6:	c7 04 24 66 9e 10 c0 	movl   $0xc0109e66,(%esp)
c01004bd:	e8 e7 fd ff ff       	call   c01002a9 <cprintf>
    va_end(ap);
}
c01004c2:	90                   	nop
c01004c3:	c9                   	leave  
c01004c4:	c3                   	ret    

c01004c5 <is_kernel_panic>:

bool
is_kernel_panic(void) {
c01004c5:	55                   	push   %ebp
c01004c6:	89 e5                	mov    %esp,%ebp
    return is_panic;
c01004c8:	a1 20 84 12 c0       	mov    0xc0128420,%eax
}
c01004cd:	5d                   	pop    %ebp
c01004ce:	c3                   	ret    

c01004cf <stab_binsearch>:
 *      stab_binsearch(stabs, &left, &right, N_SO, 0xf0100184);
 * will exit setting left = 118, right = 554.
 * */
static void
stab_binsearch(const struct stab *stabs, int *region_left, int *region_right,
           int type, uintptr_t addr) {
c01004cf:	55                   	push   %ebp
c01004d0:	89 e5                	mov    %esp,%ebp
c01004d2:	83 ec 20             	sub    $0x20,%esp
    int l = *region_left, r = *region_right, any_matches = 0;
c01004d5:	8b 45 0c             	mov    0xc(%ebp),%eax
c01004d8:	8b 00                	mov    (%eax),%eax
c01004da:	89 45 fc             	mov    %eax,-0x4(%ebp)
c01004dd:	8b 45 10             	mov    0x10(%ebp),%eax
c01004e0:	8b 00                	mov    (%eax),%eax
c01004e2:	89 45 f8             	mov    %eax,-0x8(%ebp)
c01004e5:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

    while (l <= r) {
c01004ec:	e9 ca 00 00 00       	jmp    c01005bb <stab_binsearch+0xec>
        int true_m = (l + r) / 2, m = true_m;
c01004f1:	8b 55 fc             	mov    -0x4(%ebp),%edx
c01004f4:	8b 45 f8             	mov    -0x8(%ebp),%eax
c01004f7:	01 d0                	add    %edx,%eax
c01004f9:	89 c2                	mov    %eax,%edx
c01004fb:	c1 ea 1f             	shr    $0x1f,%edx
c01004fe:	01 d0                	add    %edx,%eax
c0100500:	d1 f8                	sar    %eax
c0100502:	89 45 ec             	mov    %eax,-0x14(%ebp)
c0100505:	8b 45 ec             	mov    -0x14(%ebp),%eax
c0100508:	89 45 f0             	mov    %eax,-0x10(%ebp)

        // search for earliest stab with right type
        while (m >= l && stabs[m].n_type != type) {
c010050b:	eb 03                	jmp    c0100510 <stab_binsearch+0x41>
            m --;
c010050d:	ff 4d f0             	decl   -0x10(%ebp)
        while (m >= l && stabs[m].n_type != type) {
c0100510:	8b 45 f0             	mov    -0x10(%ebp),%eax
c0100513:	3b 45 fc             	cmp    -0x4(%ebp),%eax
c0100516:	7c 1f                	jl     c0100537 <stab_binsearch+0x68>
c0100518:	8b 55 f0             	mov    -0x10(%ebp),%edx
c010051b:	89 d0                	mov    %edx,%eax
c010051d:	01 c0                	add    %eax,%eax
c010051f:	01 d0                	add    %edx,%eax
c0100521:	c1 e0 02             	shl    $0x2,%eax
c0100524:	89 c2                	mov    %eax,%edx
c0100526:	8b 45 08             	mov    0x8(%ebp),%eax
c0100529:	01 d0                	add    %edx,%eax
c010052b:	0f b6 40 04          	movzbl 0x4(%eax),%eax
c010052f:	0f b6 c0             	movzbl %al,%eax
c0100532:	39 45 14             	cmp    %eax,0x14(%ebp)
c0100535:	75 d6                	jne    c010050d <stab_binsearch+0x3e>
        }
        if (m < l) {    // no match in [l, m]
c0100537:	8b 45 f0             	mov    -0x10(%ebp),%eax
c010053a:	3b 45 fc             	cmp    -0x4(%ebp),%eax
c010053d:	7d 09                	jge    c0100548 <stab_binsearch+0x79>
            l = true_m + 1;
c010053f:	8b 45 ec             	mov    -0x14(%ebp),%eax
c0100542:	40                   	inc    %eax
c0100543:	89 45 fc             	mov    %eax,-0x4(%ebp)
            continue;
c0100546:	eb 73                	jmp    c01005bb <stab_binsearch+0xec>
        }

        // actual binary search
        any_matches = 1;
c0100548:	c7 45 f4 01 00 00 00 	movl   $0x1,-0xc(%ebp)
        if (stabs[m].n_value < addr) {
c010054f:	8b 55 f0             	mov    -0x10(%ebp),%edx
c0100552:	89 d0                	mov    %edx,%eax
c0100554:	01 c0                	add    %eax,%eax
c0100556:	01 d0                	add    %edx,%eax
c0100558:	c1 e0 02             	shl    $0x2,%eax
c010055b:	89 c2                	mov    %eax,%edx
c010055d:	8b 45 08             	mov    0x8(%ebp),%eax
c0100560:	01 d0                	add    %edx,%eax
c0100562:	8b 40 08             	mov    0x8(%eax),%eax
c0100565:	39 45 18             	cmp    %eax,0x18(%ebp)
c0100568:	76 11                	jbe    c010057b <stab_binsearch+0xac>
            *region_left = m;
c010056a:	8b 45 0c             	mov    0xc(%ebp),%eax
c010056d:	8b 55 f0             	mov    -0x10(%ebp),%edx
c0100570:	89 10                	mov    %edx,(%eax)
            l = true_m + 1;
c0100572:	8b 45 ec             	mov    -0x14(%ebp),%eax
c0100575:	40                   	inc    %eax
c0100576:	89 45 fc             	mov    %eax,-0x4(%ebp)
c0100579:	eb 40                	jmp    c01005bb <stab_binsearch+0xec>
        } else if (stabs[m].n_value > addr) {
c010057b:	8b 55 f0             	mov    -0x10(%ebp),%edx
c010057e:	89 d0                	mov    %edx,%eax
c0100580:	01 c0                	add    %eax,%eax
c0100582:	01 d0                	add    %edx,%eax
c0100584:	c1 e0 02             	shl    $0x2,%eax
c0100587:	89 c2                	mov    %eax,%edx
c0100589:	8b 45 08             	mov    0x8(%ebp),%eax
c010058c:	01 d0                	add    %edx,%eax
c010058e:	8b 40 08             	mov    0x8(%eax),%eax
c0100591:	39 45 18             	cmp    %eax,0x18(%ebp)
c0100594:	73 14                	jae    c01005aa <stab_binsearch+0xdb>
            *region_right = m - 1;
c0100596:	8b 45 f0             	mov    -0x10(%ebp),%eax
c0100599:	8d 50 ff             	lea    -0x1(%eax),%edx
c010059c:	8b 45 10             	mov    0x10(%ebp),%eax
c010059f:	89 10                	mov    %edx,(%eax)
            r = m - 1;
c01005a1:	8b 45 f0             	mov    -0x10(%ebp),%eax
c01005a4:	48                   	dec    %eax
c01005a5:	89 45 f8             	mov    %eax,-0x8(%ebp)
c01005a8:	eb 11                	jmp    c01005bb <stab_binsearch+0xec>
        } else {
            // exact match for 'addr', but continue loop to find
            // *region_right
            *region_left = m;
c01005aa:	8b 45 0c             	mov    0xc(%ebp),%eax
c01005ad:	8b 55 f0             	mov    -0x10(%ebp),%edx
c01005b0:	89 10                	mov    %edx,(%eax)
            l = m;
c01005b2:	8b 45 f0             	mov    -0x10(%ebp),%eax
c01005b5:	89 45 fc             	mov    %eax,-0x4(%ebp)
            addr ++;
c01005b8:	ff 45 18             	incl   0x18(%ebp)
    while (l <= r) {
c01005bb:	8b 45 fc             	mov    -0x4(%ebp),%eax
c01005be:	3b 45 f8             	cmp    -0x8(%ebp),%eax
c01005c1:	0f 8e 2a ff ff ff    	jle    c01004f1 <stab_binsearch+0x22>
        }
    }

    if (!any_matches) {
c01005c7:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
c01005cb:	75 0f                	jne    c01005dc <stab_binsearch+0x10d>
        *region_right = *region_left - 1;
c01005cd:	8b 45 0c             	mov    0xc(%ebp),%eax
c01005d0:	8b 00                	mov    (%eax),%eax
c01005d2:	8d 50 ff             	lea    -0x1(%eax),%edx
c01005d5:	8b 45 10             	mov    0x10(%ebp),%eax
c01005d8:	89 10                	mov    %edx,(%eax)
        l = *region_right;
        for (; l > *region_left && stabs[l].n_type != type; l --)
            /* do nothing */;
        *region_left = l;
    }
}
c01005da:	eb 3e                	jmp    c010061a <stab_binsearch+0x14b>
        l = *region_right;
c01005dc:	8b 45 10             	mov    0x10(%ebp),%eax
c01005df:	8b 00                	mov    (%eax),%eax
c01005e1:	89 45 fc             	mov    %eax,-0x4(%ebp)
        for (; l > *region_left && stabs[l].n_type != type; l --)
c01005e4:	eb 03                	jmp    c01005e9 <stab_binsearch+0x11a>
c01005e6:	ff 4d fc             	decl   -0x4(%ebp)
c01005e9:	8b 45 0c             	mov    0xc(%ebp),%eax
c01005ec:	8b 00                	mov    (%eax),%eax
c01005ee:	39 45 fc             	cmp    %eax,-0x4(%ebp)
c01005f1:	7e 1f                	jle    c0100612 <stab_binsearch+0x143>
c01005f3:	8b 55 fc             	mov    -0x4(%ebp),%edx
c01005f6:	89 d0                	mov    %edx,%eax
c01005f8:	01 c0                	add    %eax,%eax
c01005fa:	01 d0                	add    %edx,%eax
c01005fc:	c1 e0 02             	shl    $0x2,%eax
c01005ff:	89 c2                	mov    %eax,%edx
c0100601:	8b 45 08             	mov    0x8(%ebp),%eax
c0100604:	01 d0                	add    %edx,%eax
c0100606:	0f b6 40 04          	movzbl 0x4(%eax),%eax
c010060a:	0f b6 c0             	movzbl %al,%eax
c010060d:	39 45 14             	cmp    %eax,0x14(%ebp)
c0100610:	75 d4                	jne    c01005e6 <stab_binsearch+0x117>
        *region_left = l;
c0100612:	8b 45 0c             	mov    0xc(%ebp),%eax
c0100615:	8b 55 fc             	mov    -0x4(%ebp),%edx
c0100618:	89 10                	mov    %edx,(%eax)
}
c010061a:	90                   	nop
c010061b:	c9                   	leave  
c010061c:	c3                   	ret    

c010061d <debuginfo_eip>:
 * the specified instruction address, @addr.  Returns 0 if information
 * was found, and negative if not.  But even if it returns negative it
 * has stored some information into '*info'.
 * */
int
debuginfo_eip(uintptr_t addr, struct eipdebuginfo *info) {
c010061d:	55                   	push   %ebp
c010061e:	89 e5                	mov    %esp,%ebp
c0100620:	83 ec 58             	sub    $0x58,%esp
    const struct stab *stabs, *stab_end;
    const char *stabstr, *stabstr_end;

    info->eip_file = "<unknown>";
c0100623:	8b 45 0c             	mov    0xc(%ebp),%eax
c0100626:	c7 00 98 9e 10 c0    	movl   $0xc0109e98,(%eax)
    info->eip_line = 0;
c010062c:	8b 45 0c             	mov    0xc(%ebp),%eax
c010062f:	c7 40 04 00 00 00 00 	movl   $0x0,0x4(%eax)
    info->eip_fn_name = "<unknown>";
c0100636:	8b 45 0c             	mov    0xc(%ebp),%eax
c0100639:	c7 40 08 98 9e 10 c0 	movl   $0xc0109e98,0x8(%eax)
    info->eip_fn_namelen = 9;
c0100640:	8b 45 0c             	mov    0xc(%ebp),%eax
c0100643:	c7 40 0c 09 00 00 00 	movl   $0x9,0xc(%eax)
    info->eip_fn_addr = addr;
c010064a:	8b 45 0c             	mov    0xc(%ebp),%eax
c010064d:	8b 55 08             	mov    0x8(%ebp),%edx
c0100650:	89 50 10             	mov    %edx,0x10(%eax)
    info->eip_fn_narg = 0;
c0100653:	8b 45 0c             	mov    0xc(%ebp),%eax
c0100656:	c7 40 14 00 00 00 00 	movl   $0x0,0x14(%eax)

    stabs = __STAB_BEGIN__;
c010065d:	c7 45 f4 78 c0 10 c0 	movl   $0xc010c078,-0xc(%ebp)
    stab_end = __STAB_END__;
c0100664:	c7 45 f0 dc dc 11 c0 	movl   $0xc011dcdc,-0x10(%ebp)
    stabstr = __STABSTR_BEGIN__;
c010066b:	c7 45 ec dd dc 11 c0 	movl   $0xc011dcdd,-0x14(%ebp)
    stabstr_end = __STABSTR_END__;
c0100672:	c7 45 e8 9a 25 12 c0 	movl   $0xc012259a,-0x18(%ebp)

    // String table validity checks
    if (stabstr_end <= stabstr || stabstr_end[-1] != 0) {
c0100679:	8b 45 e8             	mov    -0x18(%ebp),%eax
c010067c:	3b 45 ec             	cmp    -0x14(%ebp),%eax
c010067f:	76 0b                	jbe    c010068c <debuginfo_eip+0x6f>
c0100681:	8b 45 e8             	mov    -0x18(%ebp),%eax
c0100684:	48                   	dec    %eax
c0100685:	0f b6 00             	movzbl (%eax),%eax
c0100688:	84 c0                	test   %al,%al
c010068a:	74 0a                	je     c0100696 <debuginfo_eip+0x79>
        return -1;
c010068c:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
c0100691:	e9 b7 02 00 00       	jmp    c010094d <debuginfo_eip+0x330>
    // 'eip'.  First, we find the basic source file containing 'eip'.
    // Then, we look in that source file for the function.  Then we look
    // for the line number.

    // Search the entire set of stabs for the source file (type N_SO).
    int lfile = 0, rfile = (stab_end - stabs) - 1;
c0100696:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
c010069d:	8b 55 f0             	mov    -0x10(%ebp),%edx
c01006a0:	8b 45 f4             	mov    -0xc(%ebp),%eax
c01006a3:	29 c2                	sub    %eax,%edx
c01006a5:	89 d0                	mov    %edx,%eax
c01006a7:	c1 f8 02             	sar    $0x2,%eax
c01006aa:	69 c0 ab aa aa aa    	imul   $0xaaaaaaab,%eax,%eax
c01006b0:	48                   	dec    %eax
c01006b1:	89 45 e0             	mov    %eax,-0x20(%ebp)
    stab_binsearch(stabs, &lfile, &rfile, N_SO, addr);
c01006b4:	8b 45 08             	mov    0x8(%ebp),%eax
c01006b7:	89 44 24 10          	mov    %eax,0x10(%esp)
c01006bb:	c7 44 24 0c 64 00 00 	movl   $0x64,0xc(%esp)
c01006c2:	00 
c01006c3:	8d 45 e0             	lea    -0x20(%ebp),%eax
c01006c6:	89 44 24 08          	mov    %eax,0x8(%esp)
c01006ca:	8d 45 e4             	lea    -0x1c(%ebp),%eax
c01006cd:	89 44 24 04          	mov    %eax,0x4(%esp)
c01006d1:	8b 45 f4             	mov    -0xc(%ebp),%eax
c01006d4:	89 04 24             	mov    %eax,(%esp)
c01006d7:	e8 f3 fd ff ff       	call   c01004cf <stab_binsearch>
    if (lfile == 0)
c01006dc:	8b 45 e4             	mov    -0x1c(%ebp),%eax
c01006df:	85 c0                	test   %eax,%eax
c01006e1:	75 0a                	jne    c01006ed <debuginfo_eip+0xd0>
        return -1;
c01006e3:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
c01006e8:	e9 60 02 00 00       	jmp    c010094d <debuginfo_eip+0x330>

    // Search within that file's stabs for the function definition
    // (N_FUN).
    int lfun = lfile, rfun = rfile;
c01006ed:	8b 45 e4             	mov    -0x1c(%ebp),%eax
c01006f0:	89 45 dc             	mov    %eax,-0x24(%ebp)
c01006f3:	8b 45 e0             	mov    -0x20(%ebp),%eax
c01006f6:	89 45 d8             	mov    %eax,-0x28(%ebp)
    int lline, rline;
    stab_binsearch(stabs, &lfun, &rfun, N_FUN, addr);
c01006f9:	8b 45 08             	mov    0x8(%ebp),%eax
c01006fc:	89 44 24 10          	mov    %eax,0x10(%esp)
c0100700:	c7 44 24 0c 24 00 00 	movl   $0x24,0xc(%esp)
c0100707:	00 
c0100708:	8d 45 d8             	lea    -0x28(%ebp),%eax
c010070b:	89 44 24 08          	mov    %eax,0x8(%esp)
c010070f:	8d 45 dc             	lea    -0x24(%ebp),%eax
c0100712:	89 44 24 04          	mov    %eax,0x4(%esp)
c0100716:	8b 45 f4             	mov    -0xc(%ebp),%eax
c0100719:	89 04 24             	mov    %eax,(%esp)
c010071c:	e8 ae fd ff ff       	call   c01004cf <stab_binsearch>

    if (lfun <= rfun) {
c0100721:	8b 55 dc             	mov    -0x24(%ebp),%edx
c0100724:	8b 45 d8             	mov    -0x28(%ebp),%eax
c0100727:	39 c2                	cmp    %eax,%edx
c0100729:	7f 7c                	jg     c01007a7 <debuginfo_eip+0x18a>
        // stabs[lfun] points to the function name
        // in the string table, but check bounds just in case.
        if (stabs[lfun].n_strx < stabstr_end - stabstr) {
c010072b:	8b 45 dc             	mov    -0x24(%ebp),%eax
c010072e:	89 c2                	mov    %eax,%edx
c0100730:	89 d0                	mov    %edx,%eax
c0100732:	01 c0                	add    %eax,%eax
c0100734:	01 d0                	add    %edx,%eax
c0100736:	c1 e0 02             	shl    $0x2,%eax
c0100739:	89 c2                	mov    %eax,%edx
c010073b:	8b 45 f4             	mov    -0xc(%ebp),%eax
c010073e:	01 d0                	add    %edx,%eax
c0100740:	8b 00                	mov    (%eax),%eax
c0100742:	8b 4d e8             	mov    -0x18(%ebp),%ecx
c0100745:	8b 55 ec             	mov    -0x14(%ebp),%edx
c0100748:	29 d1                	sub    %edx,%ecx
c010074a:	89 ca                	mov    %ecx,%edx
c010074c:	39 d0                	cmp    %edx,%eax
c010074e:	73 22                	jae    c0100772 <debuginfo_eip+0x155>
            info->eip_fn_name = stabstr + stabs[lfun].n_strx;
c0100750:	8b 45 dc             	mov    -0x24(%ebp),%eax
c0100753:	89 c2                	mov    %eax,%edx
c0100755:	89 d0                	mov    %edx,%eax
c0100757:	01 c0                	add    %eax,%eax
c0100759:	01 d0                	add    %edx,%eax
c010075b:	c1 e0 02             	shl    $0x2,%eax
c010075e:	89 c2                	mov    %eax,%edx
c0100760:	8b 45 f4             	mov    -0xc(%ebp),%eax
c0100763:	01 d0                	add    %edx,%eax
c0100765:	8b 10                	mov    (%eax),%edx
c0100767:	8b 45 ec             	mov    -0x14(%ebp),%eax
c010076a:	01 c2                	add    %eax,%edx
c010076c:	8b 45 0c             	mov    0xc(%ebp),%eax
c010076f:	89 50 08             	mov    %edx,0x8(%eax)
        }
        info->eip_fn_addr = stabs[lfun].n_value;
c0100772:	8b 45 dc             	mov    -0x24(%ebp),%eax
c0100775:	89 c2                	mov    %eax,%edx
c0100777:	89 d0                	mov    %edx,%eax
c0100779:	01 c0                	add    %eax,%eax
c010077b:	01 d0                	add    %edx,%eax
c010077d:	c1 e0 02             	shl    $0x2,%eax
c0100780:	89 c2                	mov    %eax,%edx
c0100782:	8b 45 f4             	mov    -0xc(%ebp),%eax
c0100785:	01 d0                	add    %edx,%eax
c0100787:	8b 50 08             	mov    0x8(%eax),%edx
c010078a:	8b 45 0c             	mov    0xc(%ebp),%eax
c010078d:	89 50 10             	mov    %edx,0x10(%eax)
        addr -= info->eip_fn_addr;
c0100790:	8b 45 0c             	mov    0xc(%ebp),%eax
c0100793:	8b 40 10             	mov    0x10(%eax),%eax
c0100796:	29 45 08             	sub    %eax,0x8(%ebp)
        // Search within the function definition for the line number.
        lline = lfun;
c0100799:	8b 45 dc             	mov    -0x24(%ebp),%eax
c010079c:	89 45 d4             	mov    %eax,-0x2c(%ebp)
        rline = rfun;
c010079f:	8b 45 d8             	mov    -0x28(%ebp),%eax
c01007a2:	89 45 d0             	mov    %eax,-0x30(%ebp)
c01007a5:	eb 15                	jmp    c01007bc <debuginfo_eip+0x19f>
    } else {
        // Couldn't find function stab!  Maybe we're in an assembly
        // file.  Search the whole file for the line number.
        info->eip_fn_addr = addr;
c01007a7:	8b 45 0c             	mov    0xc(%ebp),%eax
c01007aa:	8b 55 08             	mov    0x8(%ebp),%edx
c01007ad:	89 50 10             	mov    %edx,0x10(%eax)
        lline = lfile;
c01007b0:	8b 45 e4             	mov    -0x1c(%ebp),%eax
c01007b3:	89 45 d4             	mov    %eax,-0x2c(%ebp)
        rline = rfile;
c01007b6:	8b 45 e0             	mov    -0x20(%ebp),%eax
c01007b9:	89 45 d0             	mov    %eax,-0x30(%ebp)
    }
    info->eip_fn_namelen = strfind(info->eip_fn_name, ':') - info->eip_fn_name;
c01007bc:	8b 45 0c             	mov    0xc(%ebp),%eax
c01007bf:	8b 40 08             	mov    0x8(%eax),%eax
c01007c2:	c7 44 24 04 3a 00 00 	movl   $0x3a,0x4(%esp)
c01007c9:	00 
c01007ca:	89 04 24             	mov    %eax,(%esp)
c01007cd:	e8 4d 8b 00 00       	call   c010931f <strfind>
c01007d2:	89 c2                	mov    %eax,%edx
c01007d4:	8b 45 0c             	mov    0xc(%ebp),%eax
c01007d7:	8b 40 08             	mov    0x8(%eax),%eax
c01007da:	29 c2                	sub    %eax,%edx
c01007dc:	8b 45 0c             	mov    0xc(%ebp),%eax
c01007df:	89 50 0c             	mov    %edx,0xc(%eax)

    // Search within [lline, rline] for the line number stab.
    // If found, set info->eip_line to the right line number.
    // If not found, return -1.
    stab_binsearch(stabs, &lline, &rline, N_SLINE, addr);
c01007e2:	8b 45 08             	mov    0x8(%ebp),%eax
c01007e5:	89 44 24 10          	mov    %eax,0x10(%esp)
c01007e9:	c7 44 24 0c 44 00 00 	movl   $0x44,0xc(%esp)
c01007f0:	00 
c01007f1:	8d 45 d0             	lea    -0x30(%ebp),%eax
c01007f4:	89 44 24 08          	mov    %eax,0x8(%esp)
c01007f8:	8d 45 d4             	lea    -0x2c(%ebp),%eax
c01007fb:	89 44 24 04          	mov    %eax,0x4(%esp)
c01007ff:	8b 45 f4             	mov    -0xc(%ebp),%eax
c0100802:	89 04 24             	mov    %eax,(%esp)
c0100805:	e8 c5 fc ff ff       	call   c01004cf <stab_binsearch>
    if (lline <= rline) {
c010080a:	8b 55 d4             	mov    -0x2c(%ebp),%edx
c010080d:	8b 45 d0             	mov    -0x30(%ebp),%eax
c0100810:	39 c2                	cmp    %eax,%edx
c0100812:	7f 23                	jg     c0100837 <debuginfo_eip+0x21a>
        info->eip_line = stabs[rline].n_desc;
c0100814:	8b 45 d0             	mov    -0x30(%ebp),%eax
c0100817:	89 c2                	mov    %eax,%edx
c0100819:	89 d0                	mov    %edx,%eax
c010081b:	01 c0                	add    %eax,%eax
c010081d:	01 d0                	add    %edx,%eax
c010081f:	c1 e0 02             	shl    $0x2,%eax
c0100822:	89 c2                	mov    %eax,%edx
c0100824:	8b 45 f4             	mov    -0xc(%ebp),%eax
c0100827:	01 d0                	add    %edx,%eax
c0100829:	0f b7 40 06          	movzwl 0x6(%eax),%eax
c010082d:	89 c2                	mov    %eax,%edx
c010082f:	8b 45 0c             	mov    0xc(%ebp),%eax
c0100832:	89 50 04             	mov    %edx,0x4(%eax)

    // Search backwards from the line number for the relevant filename stab.
    // We can't just use the "lfile" stab because inlined functions
    // can interpolate code from a different file!
    // Such included source files use the N_SOL stab type.
    while (lline >= lfile
c0100835:	eb 11                	jmp    c0100848 <debuginfo_eip+0x22b>
        return -1;
c0100837:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
c010083c:	e9 0c 01 00 00       	jmp    c010094d <debuginfo_eip+0x330>
           && stabs[lline].n_type != N_SOL
           && (stabs[lline].n_type != N_SO || !stabs[lline].n_value)) {
        lline --;
c0100841:	8b 45 d4             	mov    -0x2c(%ebp),%eax
c0100844:	48                   	dec    %eax
c0100845:	89 45 d4             	mov    %eax,-0x2c(%ebp)
    while (lline >= lfile
c0100848:	8b 55 d4             	mov    -0x2c(%ebp),%edx
c010084b:	8b 45 e4             	mov    -0x1c(%ebp),%eax
c010084e:	39 c2                	cmp    %eax,%edx
c0100850:	7c 56                	jl     c01008a8 <debuginfo_eip+0x28b>
           && stabs[lline].n_type != N_SOL
c0100852:	8b 45 d4             	mov    -0x2c(%ebp),%eax
c0100855:	89 c2                	mov    %eax,%edx
c0100857:	89 d0                	mov    %edx,%eax
c0100859:	01 c0                	add    %eax,%eax
c010085b:	01 d0                	add    %edx,%eax
c010085d:	c1 e0 02             	shl    $0x2,%eax
c0100860:	89 c2                	mov    %eax,%edx
c0100862:	8b 45 f4             	mov    -0xc(%ebp),%eax
c0100865:	01 d0                	add    %edx,%eax
c0100867:	0f b6 40 04          	movzbl 0x4(%eax),%eax
c010086b:	3c 84                	cmp    $0x84,%al
c010086d:	74 39                	je     c01008a8 <debuginfo_eip+0x28b>
           && (stabs[lline].n_type != N_SO || !stabs[lline].n_value)) {
c010086f:	8b 45 d4             	mov    -0x2c(%ebp),%eax
c0100872:	89 c2                	mov    %eax,%edx
c0100874:	89 d0                	mov    %edx,%eax
c0100876:	01 c0                	add    %eax,%eax
c0100878:	01 d0                	add    %edx,%eax
c010087a:	c1 e0 02             	shl    $0x2,%eax
c010087d:	89 c2                	mov    %eax,%edx
c010087f:	8b 45 f4             	mov    -0xc(%ebp),%eax
c0100882:	01 d0                	add    %edx,%eax
c0100884:	0f b6 40 04          	movzbl 0x4(%eax),%eax
c0100888:	3c 64                	cmp    $0x64,%al
c010088a:	75 b5                	jne    c0100841 <debuginfo_eip+0x224>
c010088c:	8b 45 d4             	mov    -0x2c(%ebp),%eax
c010088f:	89 c2                	mov    %eax,%edx
c0100891:	89 d0                	mov    %edx,%eax
c0100893:	01 c0                	add    %eax,%eax
c0100895:	01 d0                	add    %edx,%eax
c0100897:	c1 e0 02             	shl    $0x2,%eax
c010089a:	89 c2                	mov    %eax,%edx
c010089c:	8b 45 f4             	mov    -0xc(%ebp),%eax
c010089f:	01 d0                	add    %edx,%eax
c01008a1:	8b 40 08             	mov    0x8(%eax),%eax
c01008a4:	85 c0                	test   %eax,%eax
c01008a6:	74 99                	je     c0100841 <debuginfo_eip+0x224>
    }
    if (lline >= lfile && stabs[lline].n_strx < stabstr_end - stabstr) {
c01008a8:	8b 55 d4             	mov    -0x2c(%ebp),%edx
c01008ab:	8b 45 e4             	mov    -0x1c(%ebp),%eax
c01008ae:	39 c2                	cmp    %eax,%edx
c01008b0:	7c 46                	jl     c01008f8 <debuginfo_eip+0x2db>
c01008b2:	8b 45 d4             	mov    -0x2c(%ebp),%eax
c01008b5:	89 c2                	mov    %eax,%edx
c01008b7:	89 d0                	mov    %edx,%eax
c01008b9:	01 c0                	add    %eax,%eax
c01008bb:	01 d0                	add    %edx,%eax
c01008bd:	c1 e0 02             	shl    $0x2,%eax
c01008c0:	89 c2                	mov    %eax,%edx
c01008c2:	8b 45 f4             	mov    -0xc(%ebp),%eax
c01008c5:	01 d0                	add    %edx,%eax
c01008c7:	8b 00                	mov    (%eax),%eax
c01008c9:	8b 4d e8             	mov    -0x18(%ebp),%ecx
c01008cc:	8b 55 ec             	mov    -0x14(%ebp),%edx
c01008cf:	29 d1                	sub    %edx,%ecx
c01008d1:	89 ca                	mov    %ecx,%edx
c01008d3:	39 d0                	cmp    %edx,%eax
c01008d5:	73 21                	jae    c01008f8 <debuginfo_eip+0x2db>
        info->eip_file = stabstr + stabs[lline].n_strx;
c01008d7:	8b 45 d4             	mov    -0x2c(%ebp),%eax
c01008da:	89 c2                	mov    %eax,%edx
c01008dc:	89 d0                	mov    %edx,%eax
c01008de:	01 c0                	add    %eax,%eax
c01008e0:	01 d0                	add    %edx,%eax
c01008e2:	c1 e0 02             	shl    $0x2,%eax
c01008e5:	89 c2                	mov    %eax,%edx
c01008e7:	8b 45 f4             	mov    -0xc(%ebp),%eax
c01008ea:	01 d0                	add    %edx,%eax
c01008ec:	8b 10                	mov    (%eax),%edx
c01008ee:	8b 45 ec             	mov    -0x14(%ebp),%eax
c01008f1:	01 c2                	add    %eax,%edx
c01008f3:	8b 45 0c             	mov    0xc(%ebp),%eax
c01008f6:	89 10                	mov    %edx,(%eax)
    }

    // Set eip_fn_narg to the number of arguments taken by the function,
    // or 0 if there was no containing function.
    if (lfun < rfun) {
c01008f8:	8b 55 dc             	mov    -0x24(%ebp),%edx
c01008fb:	8b 45 d8             	mov    -0x28(%ebp),%eax
c01008fe:	39 c2                	cmp    %eax,%edx
c0100900:	7d 46                	jge    c0100948 <debuginfo_eip+0x32b>
        for (lline = lfun + 1;
c0100902:	8b 45 dc             	mov    -0x24(%ebp),%eax
c0100905:	40                   	inc    %eax
c0100906:	89 45 d4             	mov    %eax,-0x2c(%ebp)
c0100909:	eb 16                	jmp    c0100921 <debuginfo_eip+0x304>
             lline < rfun && stabs[lline].n_type == N_PSYM;
             lline ++) {
            info->eip_fn_narg ++;
c010090b:	8b 45 0c             	mov    0xc(%ebp),%eax
c010090e:	8b 40 14             	mov    0x14(%eax),%eax
c0100911:	8d 50 01             	lea    0x1(%eax),%edx
c0100914:	8b 45 0c             	mov    0xc(%ebp),%eax
c0100917:	89 50 14             	mov    %edx,0x14(%eax)
             lline ++) {
c010091a:	8b 45 d4             	mov    -0x2c(%ebp),%eax
c010091d:	40                   	inc    %eax
c010091e:	89 45 d4             	mov    %eax,-0x2c(%ebp)
             lline < rfun && stabs[lline].n_type == N_PSYM;
c0100921:	8b 55 d4             	mov    -0x2c(%ebp),%edx
c0100924:	8b 45 d8             	mov    -0x28(%ebp),%eax
        for (lline = lfun + 1;
c0100927:	39 c2                	cmp    %eax,%edx
c0100929:	7d 1d                	jge    c0100948 <debuginfo_eip+0x32b>
             lline < rfun && stabs[lline].n_type == N_PSYM;
c010092b:	8b 45 d4             	mov    -0x2c(%ebp),%eax
c010092e:	89 c2                	mov    %eax,%edx
c0100930:	89 d0                	mov    %edx,%eax
c0100932:	01 c0                	add    %eax,%eax
c0100934:	01 d0                	add    %edx,%eax
c0100936:	c1 e0 02             	shl    $0x2,%eax
c0100939:	89 c2                	mov    %eax,%edx
c010093b:	8b 45 f4             	mov    -0xc(%ebp),%eax
c010093e:	01 d0                	add    %edx,%eax
c0100940:	0f b6 40 04          	movzbl 0x4(%eax),%eax
c0100944:	3c a0                	cmp    $0xa0,%al
c0100946:	74 c3                	je     c010090b <debuginfo_eip+0x2ee>
        }
    }
    return 0;
c0100948:	b8 00 00 00 00       	mov    $0x0,%eax
}
c010094d:	c9                   	leave  
c010094e:	c3                   	ret    

c010094f <print_kerninfo>:
 * print_kerninfo - print the information about kernel, including the location
 * of kernel entry, the start addresses of data and text segements, the start
 * address of free memory and how many memory that kernel has used.
 * */
void
print_kerninfo(void) {
c010094f:	55                   	push   %ebp
c0100950:	89 e5                	mov    %esp,%ebp
c0100952:	83 ec 18             	sub    $0x18,%esp
    extern char etext[], edata[], end[], kern_init[];
    cprintf("Special kernel symbols:\n");
c0100955:	c7 04 24 a2 9e 10 c0 	movl   $0xc0109ea2,(%esp)
c010095c:	e8 48 f9 ff ff       	call   c01002a9 <cprintf>
    cprintf("  entry  0x%08x (phys)\n", kern_init);
c0100961:	c7 44 24 04 36 00 10 	movl   $0xc0100036,0x4(%esp)
c0100968:	c0 
c0100969:	c7 04 24 bb 9e 10 c0 	movl   $0xc0109ebb,(%esp)
c0100970:	e8 34 f9 ff ff       	call   c01002a9 <cprintf>
    cprintf("  etext  0x%08x (phys)\n", etext);
c0100975:	c7 44 24 04 9f 9d 10 	movl   $0xc0109d9f,0x4(%esp)
c010097c:	c0 
c010097d:	c7 04 24 d3 9e 10 c0 	movl   $0xc0109ed3,(%esp)
c0100984:	e8 20 f9 ff ff       	call   c01002a9 <cprintf>
    cprintf("  edata  0x%08x (phys)\n", edata);
c0100989:	c7 44 24 04 00 80 12 	movl   $0xc0128000,0x4(%esp)
c0100990:	c0 
c0100991:	c7 04 24 eb 9e 10 c0 	movl   $0xc0109eeb,(%esp)
c0100998:	e8 0c f9 ff ff       	call   c01002a9 <cprintf>
    cprintf("  end    0x%08x (phys)\n", end);
c010099d:	c7 44 24 04 58 b1 12 	movl   $0xc012b158,0x4(%esp)
c01009a4:	c0 
c01009a5:	c7 04 24 03 9f 10 c0 	movl   $0xc0109f03,(%esp)
c01009ac:	e8 f8 f8 ff ff       	call   c01002a9 <cprintf>
    cprintf("Kernel executable memory footprint: %dKB\n", (end - kern_init + 1023)/1024);
c01009b1:	b8 58 b1 12 c0       	mov    $0xc012b158,%eax
c01009b6:	8d 90 ff 03 00 00    	lea    0x3ff(%eax),%edx
c01009bc:	b8 36 00 10 c0       	mov    $0xc0100036,%eax
c01009c1:	29 c2                	sub    %eax,%edx
c01009c3:	89 d0                	mov    %edx,%eax
c01009c5:	8d 90 ff 03 00 00    	lea    0x3ff(%eax),%edx
c01009cb:	85 c0                	test   %eax,%eax
c01009cd:	0f 48 c2             	cmovs  %edx,%eax
c01009d0:	c1 f8 0a             	sar    $0xa,%eax
c01009d3:	89 44 24 04          	mov    %eax,0x4(%esp)
c01009d7:	c7 04 24 1c 9f 10 c0 	movl   $0xc0109f1c,(%esp)
c01009de:	e8 c6 f8 ff ff       	call   c01002a9 <cprintf>
}
c01009e3:	90                   	nop
c01009e4:	c9                   	leave  
c01009e5:	c3                   	ret    

c01009e6 <print_debuginfo>:
/* *
 * print_debuginfo - read and print the stat information for the address @eip,
 * and info.eip_fn_addr should be the first address of the related function.
 * */
void
print_debuginfo(uintptr_t eip) {
c01009e6:	55                   	push   %ebp
c01009e7:	89 e5                	mov    %esp,%ebp
c01009e9:	81 ec 48 01 00 00    	sub    $0x148,%esp
    struct eipdebuginfo info;
    if (debuginfo_eip(eip, &info) != 0) {
c01009ef:	8d 45 dc             	lea    -0x24(%ebp),%eax
c01009f2:	89 44 24 04          	mov    %eax,0x4(%esp)
c01009f6:	8b 45 08             	mov    0x8(%ebp),%eax
c01009f9:	89 04 24             	mov    %eax,(%esp)
c01009fc:	e8 1c fc ff ff       	call   c010061d <debuginfo_eip>
c0100a01:	85 c0                	test   %eax,%eax
c0100a03:	74 15                	je     c0100a1a <print_debuginfo+0x34>
        cprintf("    <unknow>: -- 0x%08x --\n", eip);
c0100a05:	8b 45 08             	mov    0x8(%ebp),%eax
c0100a08:	89 44 24 04          	mov    %eax,0x4(%esp)
c0100a0c:	c7 04 24 46 9f 10 c0 	movl   $0xc0109f46,(%esp)
c0100a13:	e8 91 f8 ff ff       	call   c01002a9 <cprintf>
        }
        fnname[j] = '\0';
        cprintf("    %s:%d: %s+%d\n", info.eip_file, info.eip_line,
                fnname, eip - info.eip_fn_addr);
    }
}
c0100a18:	eb 6c                	jmp    c0100a86 <print_debuginfo+0xa0>
        for (j = 0; j < info.eip_fn_namelen; j ++) {
c0100a1a:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
c0100a21:	eb 1b                	jmp    c0100a3e <print_debuginfo+0x58>
            fnname[j] = info.eip_fn_name[j];
c0100a23:	8b 55 e4             	mov    -0x1c(%ebp),%edx
c0100a26:	8b 45 f4             	mov    -0xc(%ebp),%eax
c0100a29:	01 d0                	add    %edx,%eax
c0100a2b:	0f b6 00             	movzbl (%eax),%eax
c0100a2e:	8d 8d dc fe ff ff    	lea    -0x124(%ebp),%ecx
c0100a34:	8b 55 f4             	mov    -0xc(%ebp),%edx
c0100a37:	01 ca                	add    %ecx,%edx
c0100a39:	88 02                	mov    %al,(%edx)
        for (j = 0; j < info.eip_fn_namelen; j ++) {
c0100a3b:	ff 45 f4             	incl   -0xc(%ebp)
c0100a3e:	8b 45 e8             	mov    -0x18(%ebp),%eax
c0100a41:	39 45 f4             	cmp    %eax,-0xc(%ebp)
c0100a44:	7c dd                	jl     c0100a23 <print_debuginfo+0x3d>
        fnname[j] = '\0';
c0100a46:	8d 95 dc fe ff ff    	lea    -0x124(%ebp),%edx
c0100a4c:	8b 45 f4             	mov    -0xc(%ebp),%eax
c0100a4f:	01 d0                	add    %edx,%eax
c0100a51:	c6 00 00             	movb   $0x0,(%eax)
                fnname, eip - info.eip_fn_addr);
c0100a54:	8b 45 ec             	mov    -0x14(%ebp),%eax
        cprintf("    %s:%d: %s+%d\n", info.eip_file, info.eip_line,
c0100a57:	8b 55 08             	mov    0x8(%ebp),%edx
c0100a5a:	89 d1                	mov    %edx,%ecx
c0100a5c:	29 c1                	sub    %eax,%ecx
c0100a5e:	8b 55 e0             	mov    -0x20(%ebp),%edx
c0100a61:	8b 45 dc             	mov    -0x24(%ebp),%eax
c0100a64:	89 4c 24 10          	mov    %ecx,0x10(%esp)
c0100a68:	8d 8d dc fe ff ff    	lea    -0x124(%ebp),%ecx
c0100a6e:	89 4c 24 0c          	mov    %ecx,0xc(%esp)
c0100a72:	89 54 24 08          	mov    %edx,0x8(%esp)
c0100a76:	89 44 24 04          	mov    %eax,0x4(%esp)
c0100a7a:	c7 04 24 62 9f 10 c0 	movl   $0xc0109f62,(%esp)
c0100a81:	e8 23 f8 ff ff       	call   c01002a9 <cprintf>
}
c0100a86:	90                   	nop
c0100a87:	c9                   	leave  
c0100a88:	c3                   	ret    

c0100a89 <read_eip>:

static __noinline uint32_t
read_eip(void) {
c0100a89:	55                   	push   %ebp
c0100a8a:	89 e5                	mov    %esp,%ebp
c0100a8c:	83 ec 10             	sub    $0x10,%esp
    uint32_t eip;
    asm volatile("movl 4(%%ebp), %0" : "=r" (eip));
c0100a8f:	8b 45 04             	mov    0x4(%ebp),%eax
c0100a92:	89 45 fc             	mov    %eax,-0x4(%ebp)
    return eip;
c0100a95:	8b 45 fc             	mov    -0x4(%ebp),%eax
}
c0100a98:	c9                   	leave  
c0100a99:	c3                   	ret    

c0100a9a <print_stackframe>:
 *
 * Note that, the length of ebp-chain is limited. In boot/bootasm.S, before jumping
 * to the kernel entry, the value of ebp has been set to zero, that's the boundary.
 * */
void
print_stackframe(void) {
c0100a9a:	55                   	push   %ebp
c0100a9b:	89 e5                	mov    %esp,%ebp
      *    (3.4) call print_debuginfo(eip-1) to print the C calling function name and line number, etc.
      *    (3.5) popup a calling stackframe
      *           NOTICE: the calling funciton's return addr eip  = ss:[ebp+4]
      *                   the calling funciton's ebp = ss:[ebp]
      */
}
c0100a9d:	90                   	nop
c0100a9e:	5d                   	pop    %ebp
c0100a9f:	c3                   	ret    

c0100aa0 <parse>:
#define MAXARGS         16
#define WHITESPACE      " \t\n\r"

/* parse - parse the command buffer into whitespace-separated arguments */
static int
parse(char *buf, char **argv) {
c0100aa0:	55                   	push   %ebp
c0100aa1:	89 e5                	mov    %esp,%ebp
c0100aa3:	83 ec 28             	sub    $0x28,%esp
    int argc = 0;
c0100aa6:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
    while (1) {
        // find global whitespace
        while (*buf != '\0' && strchr(WHITESPACE, *buf) != NULL) {
c0100aad:	eb 0c                	jmp    c0100abb <parse+0x1b>
            *buf ++ = '\0';
c0100aaf:	8b 45 08             	mov    0x8(%ebp),%eax
c0100ab2:	8d 50 01             	lea    0x1(%eax),%edx
c0100ab5:	89 55 08             	mov    %edx,0x8(%ebp)
c0100ab8:	c6 00 00             	movb   $0x0,(%eax)
        while (*buf != '\0' && strchr(WHITESPACE, *buf) != NULL) {
c0100abb:	8b 45 08             	mov    0x8(%ebp),%eax
c0100abe:	0f b6 00             	movzbl (%eax),%eax
c0100ac1:	84 c0                	test   %al,%al
c0100ac3:	74 1d                	je     c0100ae2 <parse+0x42>
c0100ac5:	8b 45 08             	mov    0x8(%ebp),%eax
c0100ac8:	0f b6 00             	movzbl (%eax),%eax
c0100acb:	0f be c0             	movsbl %al,%eax
c0100ace:	89 44 24 04          	mov    %eax,0x4(%esp)
c0100ad2:	c7 04 24 f4 9f 10 c0 	movl   $0xc0109ff4,(%esp)
c0100ad9:	e8 0f 88 00 00       	call   c01092ed <strchr>
c0100ade:	85 c0                	test   %eax,%eax
c0100ae0:	75 cd                	jne    c0100aaf <parse+0xf>
        }
        if (*buf == '\0') {
c0100ae2:	8b 45 08             	mov    0x8(%ebp),%eax
c0100ae5:	0f b6 00             	movzbl (%eax),%eax
c0100ae8:	84 c0                	test   %al,%al
c0100aea:	74 65                	je     c0100b51 <parse+0xb1>
            break;
        }

        // save and scan past next arg
        if (argc == MAXARGS - 1) {
c0100aec:	83 7d f4 0f          	cmpl   $0xf,-0xc(%ebp)
c0100af0:	75 14                	jne    c0100b06 <parse+0x66>
            cprintf("Too many arguments (max %d).\n", MAXARGS);
c0100af2:	c7 44 24 04 10 00 00 	movl   $0x10,0x4(%esp)
c0100af9:	00 
c0100afa:	c7 04 24 f9 9f 10 c0 	movl   $0xc0109ff9,(%esp)
c0100b01:	e8 a3 f7 ff ff       	call   c01002a9 <cprintf>
        }
        argv[argc ++] = buf;
c0100b06:	8b 45 f4             	mov    -0xc(%ebp),%eax
c0100b09:	8d 50 01             	lea    0x1(%eax),%edx
c0100b0c:	89 55 f4             	mov    %edx,-0xc(%ebp)
c0100b0f:	8d 14 85 00 00 00 00 	lea    0x0(,%eax,4),%edx
c0100b16:	8b 45 0c             	mov    0xc(%ebp),%eax
c0100b19:	01 c2                	add    %eax,%edx
c0100b1b:	8b 45 08             	mov    0x8(%ebp),%eax
c0100b1e:	89 02                	mov    %eax,(%edx)
        while (*buf != '\0' && strchr(WHITESPACE, *buf) == NULL) {
c0100b20:	eb 03                	jmp    c0100b25 <parse+0x85>
            buf ++;
c0100b22:	ff 45 08             	incl   0x8(%ebp)
        while (*buf != '\0' && strchr(WHITESPACE, *buf) == NULL) {
c0100b25:	8b 45 08             	mov    0x8(%ebp),%eax
c0100b28:	0f b6 00             	movzbl (%eax),%eax
c0100b2b:	84 c0                	test   %al,%al
c0100b2d:	74 8c                	je     c0100abb <parse+0x1b>
c0100b2f:	8b 45 08             	mov    0x8(%ebp),%eax
c0100b32:	0f b6 00             	movzbl (%eax),%eax
c0100b35:	0f be c0             	movsbl %al,%eax
c0100b38:	89 44 24 04          	mov    %eax,0x4(%esp)
c0100b3c:	c7 04 24 f4 9f 10 c0 	movl   $0xc0109ff4,(%esp)
c0100b43:	e8 a5 87 00 00       	call   c01092ed <strchr>
c0100b48:	85 c0                	test   %eax,%eax
c0100b4a:	74 d6                	je     c0100b22 <parse+0x82>
        while (*buf != '\0' && strchr(WHITESPACE, *buf) != NULL) {
c0100b4c:	e9 6a ff ff ff       	jmp    c0100abb <parse+0x1b>
            break;
c0100b51:	90                   	nop
        }
    }
    return argc;
c0100b52:	8b 45 f4             	mov    -0xc(%ebp),%eax
}
c0100b55:	c9                   	leave  
c0100b56:	c3                   	ret    

c0100b57 <runcmd>:
/* *
 * runcmd - parse the input string, split it into separated arguments
 * and then lookup and invoke some related commands/
 * */
static int
runcmd(char *buf, struct trapframe *tf) {
c0100b57:	55                   	push   %ebp
c0100b58:	89 e5                	mov    %esp,%ebp
c0100b5a:	53                   	push   %ebx
c0100b5b:	83 ec 64             	sub    $0x64,%esp
    char *argv[MAXARGS];
    int argc = parse(buf, argv);
c0100b5e:	8d 45 b0             	lea    -0x50(%ebp),%eax
c0100b61:	89 44 24 04          	mov    %eax,0x4(%esp)
c0100b65:	8b 45 08             	mov    0x8(%ebp),%eax
c0100b68:	89 04 24             	mov    %eax,(%esp)
c0100b6b:	e8 30 ff ff ff       	call   c0100aa0 <parse>
c0100b70:	89 45 f0             	mov    %eax,-0x10(%ebp)
    if (argc == 0) {
c0100b73:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
c0100b77:	75 0a                	jne    c0100b83 <runcmd+0x2c>
        return 0;
c0100b79:	b8 00 00 00 00       	mov    $0x0,%eax
c0100b7e:	e9 83 00 00 00       	jmp    c0100c06 <runcmd+0xaf>
    }
    int i;
    for (i = 0; i < NCOMMANDS; i ++) {
c0100b83:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
c0100b8a:	eb 5a                	jmp    c0100be6 <runcmd+0x8f>
        if (strcmp(commands[i].name, argv[0]) == 0) {
c0100b8c:	8b 4d b0             	mov    -0x50(%ebp),%ecx
c0100b8f:	8b 55 f4             	mov    -0xc(%ebp),%edx
c0100b92:	89 d0                	mov    %edx,%eax
c0100b94:	01 c0                	add    %eax,%eax
c0100b96:	01 d0                	add    %edx,%eax
c0100b98:	c1 e0 02             	shl    $0x2,%eax
c0100b9b:	05 00 50 12 c0       	add    $0xc0125000,%eax
c0100ba0:	8b 00                	mov    (%eax),%eax
c0100ba2:	89 4c 24 04          	mov    %ecx,0x4(%esp)
c0100ba6:	89 04 24             	mov    %eax,(%esp)
c0100ba9:	e8 a2 86 00 00       	call   c0109250 <strcmp>
c0100bae:	85 c0                	test   %eax,%eax
c0100bb0:	75 31                	jne    c0100be3 <runcmd+0x8c>
            return commands[i].func(argc - 1, argv + 1, tf);
c0100bb2:	8b 55 f4             	mov    -0xc(%ebp),%edx
c0100bb5:	89 d0                	mov    %edx,%eax
c0100bb7:	01 c0                	add    %eax,%eax
c0100bb9:	01 d0                	add    %edx,%eax
c0100bbb:	c1 e0 02             	shl    $0x2,%eax
c0100bbe:	05 08 50 12 c0       	add    $0xc0125008,%eax
c0100bc3:	8b 10                	mov    (%eax),%edx
c0100bc5:	8d 45 b0             	lea    -0x50(%ebp),%eax
c0100bc8:	83 c0 04             	add    $0x4,%eax
c0100bcb:	8b 4d f0             	mov    -0x10(%ebp),%ecx
c0100bce:	8d 59 ff             	lea    -0x1(%ecx),%ebx
c0100bd1:	8b 4d 0c             	mov    0xc(%ebp),%ecx
c0100bd4:	89 4c 24 08          	mov    %ecx,0x8(%esp)
c0100bd8:	89 44 24 04          	mov    %eax,0x4(%esp)
c0100bdc:	89 1c 24             	mov    %ebx,(%esp)
c0100bdf:	ff d2                	call   *%edx
c0100be1:	eb 23                	jmp    c0100c06 <runcmd+0xaf>
    for (i = 0; i < NCOMMANDS; i ++) {
c0100be3:	ff 45 f4             	incl   -0xc(%ebp)
c0100be6:	8b 45 f4             	mov    -0xc(%ebp),%eax
c0100be9:	83 f8 02             	cmp    $0x2,%eax
c0100bec:	76 9e                	jbe    c0100b8c <runcmd+0x35>
        }
    }
    cprintf("Unknown command '%s'\n", argv[0]);
c0100bee:	8b 45 b0             	mov    -0x50(%ebp),%eax
c0100bf1:	89 44 24 04          	mov    %eax,0x4(%esp)
c0100bf5:	c7 04 24 17 a0 10 c0 	movl   $0xc010a017,(%esp)
c0100bfc:	e8 a8 f6 ff ff       	call   c01002a9 <cprintf>
    return 0;
c0100c01:	b8 00 00 00 00       	mov    $0x0,%eax
}
c0100c06:	83 c4 64             	add    $0x64,%esp
c0100c09:	5b                   	pop    %ebx
c0100c0a:	5d                   	pop    %ebp
c0100c0b:	c3                   	ret    

c0100c0c <kmonitor>:

/***** Implementations of basic kernel monitor commands *****/

void
kmonitor(struct trapframe *tf) {
c0100c0c:	55                   	push   %ebp
c0100c0d:	89 e5                	mov    %esp,%ebp
c0100c0f:	83 ec 28             	sub    $0x28,%esp
    cprintf("Welcome to the kernel debug monitor!!\n");
c0100c12:	c7 04 24 30 a0 10 c0 	movl   $0xc010a030,(%esp)
c0100c19:	e8 8b f6 ff ff       	call   c01002a9 <cprintf>
    cprintf("Type 'help' for a list of commands.\n");
c0100c1e:	c7 04 24 58 a0 10 c0 	movl   $0xc010a058,(%esp)
c0100c25:	e8 7f f6 ff ff       	call   c01002a9 <cprintf>

    if (tf != NULL) {
c0100c2a:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
c0100c2e:	74 0b                	je     c0100c3b <kmonitor+0x2f>
        print_trapframe(tf);
c0100c30:	8b 45 08             	mov    0x8(%ebp),%eax
c0100c33:	89 04 24             	mov    %eax,(%esp)
c0100c36:	e8 7a 15 00 00       	call   c01021b5 <print_trapframe>
    }

    char *buf;
    while (1) {
        if ((buf = readline("K> ")) != NULL) {
c0100c3b:	c7 04 24 7d a0 10 c0 	movl   $0xc010a07d,(%esp)
c0100c42:	e8 04 f7 ff ff       	call   c010034b <readline>
c0100c47:	89 45 f4             	mov    %eax,-0xc(%ebp)
c0100c4a:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
c0100c4e:	74 eb                	je     c0100c3b <kmonitor+0x2f>
            if (runcmd(buf, tf) < 0) {
c0100c50:	8b 45 08             	mov    0x8(%ebp),%eax
c0100c53:	89 44 24 04          	mov    %eax,0x4(%esp)
c0100c57:	8b 45 f4             	mov    -0xc(%ebp),%eax
c0100c5a:	89 04 24             	mov    %eax,(%esp)
c0100c5d:	e8 f5 fe ff ff       	call   c0100b57 <runcmd>
c0100c62:	85 c0                	test   %eax,%eax
c0100c64:	78 02                	js     c0100c68 <kmonitor+0x5c>
        if ((buf = readline("K> ")) != NULL) {
c0100c66:	eb d3                	jmp    c0100c3b <kmonitor+0x2f>
                break;
c0100c68:	90                   	nop
            }
        }
    }
}
c0100c69:	90                   	nop
c0100c6a:	c9                   	leave  
c0100c6b:	c3                   	ret    

c0100c6c <mon_help>:

/* mon_help - print the information about mon_* functions */
int
mon_help(int argc, char **argv, struct trapframe *tf) {
c0100c6c:	55                   	push   %ebp
c0100c6d:	89 e5                	mov    %esp,%ebp
c0100c6f:	83 ec 28             	sub    $0x28,%esp
    int i;
    for (i = 0; i < NCOMMANDS; i ++) {
c0100c72:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
c0100c79:	eb 3d                	jmp    c0100cb8 <mon_help+0x4c>
        cprintf("%s - %s\n", commands[i].name, commands[i].desc);
c0100c7b:	8b 55 f4             	mov    -0xc(%ebp),%edx
c0100c7e:	89 d0                	mov    %edx,%eax
c0100c80:	01 c0                	add    %eax,%eax
c0100c82:	01 d0                	add    %edx,%eax
c0100c84:	c1 e0 02             	shl    $0x2,%eax
c0100c87:	05 04 50 12 c0       	add    $0xc0125004,%eax
c0100c8c:	8b 08                	mov    (%eax),%ecx
c0100c8e:	8b 55 f4             	mov    -0xc(%ebp),%edx
c0100c91:	89 d0                	mov    %edx,%eax
c0100c93:	01 c0                	add    %eax,%eax
c0100c95:	01 d0                	add    %edx,%eax
c0100c97:	c1 e0 02             	shl    $0x2,%eax
c0100c9a:	05 00 50 12 c0       	add    $0xc0125000,%eax
c0100c9f:	8b 00                	mov    (%eax),%eax
c0100ca1:	89 4c 24 08          	mov    %ecx,0x8(%esp)
c0100ca5:	89 44 24 04          	mov    %eax,0x4(%esp)
c0100ca9:	c7 04 24 81 a0 10 c0 	movl   $0xc010a081,(%esp)
c0100cb0:	e8 f4 f5 ff ff       	call   c01002a9 <cprintf>
    for (i = 0; i < NCOMMANDS; i ++) {
c0100cb5:	ff 45 f4             	incl   -0xc(%ebp)
c0100cb8:	8b 45 f4             	mov    -0xc(%ebp),%eax
c0100cbb:	83 f8 02             	cmp    $0x2,%eax
c0100cbe:	76 bb                	jbe    c0100c7b <mon_help+0xf>
    }
    return 0;
c0100cc0:	b8 00 00 00 00       	mov    $0x0,%eax
}
c0100cc5:	c9                   	leave  
c0100cc6:	c3                   	ret    

c0100cc7 <mon_kerninfo>:
/* *
 * mon_kerninfo - call print_kerninfo in kern/debug/kdebug.c to
 * print the memory occupancy in kernel.
 * */
int
mon_kerninfo(int argc, char **argv, struct trapframe *tf) {
c0100cc7:	55                   	push   %ebp
c0100cc8:	89 e5                	mov    %esp,%ebp
c0100cca:	83 ec 08             	sub    $0x8,%esp
    print_kerninfo();
c0100ccd:	e8 7d fc ff ff       	call   c010094f <print_kerninfo>
    return 0;
c0100cd2:	b8 00 00 00 00       	mov    $0x0,%eax
}
c0100cd7:	c9                   	leave  
c0100cd8:	c3                   	ret    

c0100cd9 <mon_backtrace>:
/* *
 * mon_backtrace - call print_stackframe in kern/debug/kdebug.c to
 * print a backtrace of the stack.
 * */
int
mon_backtrace(int argc, char **argv, struct trapframe *tf) {
c0100cd9:	55                   	push   %ebp
c0100cda:	89 e5                	mov    %esp,%ebp
c0100cdc:	83 ec 08             	sub    $0x8,%esp
    print_stackframe();
c0100cdf:	e8 b6 fd ff ff       	call   c0100a9a <print_stackframe>
    return 0;
c0100ce4:	b8 00 00 00 00       	mov    $0x0,%eax
}
c0100ce9:	c9                   	leave  
c0100cea:	c3                   	ret    

c0100ceb <ide_wait_ready>:
    unsigned int size;          // Size in Sectors
    unsigned char model[41];    // Model in String
} ide_devices[MAX_IDE];         //4个设备

static int
ide_wait_ready(unsigned short iobase, bool check_error) {
c0100ceb:	55                   	push   %ebp
c0100cec:	89 e5                	mov    %esp,%ebp
c0100cee:	83 ec 14             	sub    $0x14,%esp
c0100cf1:	8b 45 08             	mov    0x8(%ebp),%eax
c0100cf4:	66 89 45 ec          	mov    %ax,-0x14(%ebp)
    int r;
    while ((r = inb(iobase + ISA_STATUS)) & IDE_BSY)
c0100cf8:	90                   	nop
c0100cf9:	8b 45 ec             	mov    -0x14(%ebp),%eax
c0100cfc:	83 c0 07             	add    $0x7,%eax
c0100cff:	0f b7 c0             	movzwl %ax,%eax
c0100d02:	66 89 45 fa          	mov    %ax,-0x6(%ebp)
static inline void invlpg(void *addr) __attribute__((always_inline));

static inline uint8_t
inb(uint16_t port) {
    uint8_t data;
    asm volatile ("inb %1, %0" : "=a" (data) : "d" (port) : "memory");
c0100d06:	0f b7 45 fa          	movzwl -0x6(%ebp),%eax
c0100d0a:	89 c2                	mov    %eax,%edx
c0100d0c:	ec                   	in     (%dx),%al
c0100d0d:	88 45 f9             	mov    %al,-0x7(%ebp)
    return data;
c0100d10:	0f b6 45 f9          	movzbl -0x7(%ebp),%eax
c0100d14:	0f b6 c0             	movzbl %al,%eax
c0100d17:	89 45 fc             	mov    %eax,-0x4(%ebp)
c0100d1a:	8b 45 fc             	mov    -0x4(%ebp),%eax
c0100d1d:	25 80 00 00 00       	and    $0x80,%eax
c0100d22:	85 c0                	test   %eax,%eax
c0100d24:	75 d3                	jne    c0100cf9 <ide_wait_ready+0xe>
        /* nothing */;
    if (check_error && (r & (IDE_DF | IDE_ERR)) != 0) {
c0100d26:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
c0100d2a:	74 11                	je     c0100d3d <ide_wait_ready+0x52>
c0100d2c:	8b 45 fc             	mov    -0x4(%ebp),%eax
c0100d2f:	83 e0 21             	and    $0x21,%eax
c0100d32:	85 c0                	test   %eax,%eax
c0100d34:	74 07                	je     c0100d3d <ide_wait_ready+0x52>
        return -1;
c0100d36:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
c0100d3b:	eb 05                	jmp    c0100d42 <ide_wait_ready+0x57>
    }
    return 0;
c0100d3d:	b8 00 00 00 00       	mov    $0x0,%eax
}
c0100d42:	c9                   	leave  
c0100d43:	c3                   	ret    

c0100d44 <ide_init>:

void
ide_init(void) {
c0100d44:	55                   	push   %ebp
c0100d45:	89 e5                	mov    %esp,%ebp
c0100d47:	57                   	push   %edi
c0100d48:	53                   	push   %ebx
c0100d49:	81 ec 50 02 00 00    	sub    $0x250,%esp
    static_assert((SECTSIZE % 4) == 0);
    unsigned short ideno, iobase;
    for (ideno = 0; ideno < MAX_IDE; ideno ++) {    //0.1.2.3
c0100d4f:	66 c7 45 f6 00 00    	movw   $0x0,-0xa(%ebp)
c0100d55:	e9 ba 02 00 00       	jmp    c0101014 <ide_init+0x2d0>
        /* assume that no device here */
        ide_devices[ideno].valid = 0;
c0100d5a:	0f b7 55 f6          	movzwl -0xa(%ebp),%edx
c0100d5e:	89 d0                	mov    %edx,%eax
c0100d60:	c1 e0 03             	shl    $0x3,%eax
c0100d63:	29 d0                	sub    %edx,%eax
c0100d65:	c1 e0 03             	shl    $0x3,%eax
c0100d68:	05 40 84 12 c0       	add    $0xc0128440,%eax
c0100d6d:	c6 00 00             	movb   $0x0,(%eax)

        iobase = IO_BASE(ideno);
c0100d70:	0f b7 45 f6          	movzwl -0xa(%ebp),%eax
c0100d74:	d1 e8                	shr    %eax
c0100d76:	0f b7 c0             	movzwl %ax,%eax
c0100d79:	8b 04 85 8c a0 10 c0 	mov    -0x3fef5f74(,%eax,4),%eax
c0100d80:	66 89 45 ea          	mov    %ax,-0x16(%ebp)

        /* wait device ready */
        ide_wait_ready(iobase, 0);
c0100d84:	0f b7 45 ea          	movzwl -0x16(%ebp),%eax
c0100d88:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
c0100d8f:	00 
c0100d90:	89 04 24             	mov    %eax,(%esp)
c0100d93:	e8 53 ff ff ff       	call   c0100ceb <ide_wait_ready>

        /* step1: select drive */
        outb(iobase + ISA_SDH, 0xE0 | ((ideno & 1) << 4));
c0100d98:	0f b7 45 f6          	movzwl -0xa(%ebp),%eax
c0100d9c:	c1 e0 04             	shl    $0x4,%eax
c0100d9f:	24 10                	and    $0x10,%al
c0100da1:	0c e0                	or     $0xe0,%al
c0100da3:	0f b6 c0             	movzbl %al,%eax
c0100da6:	0f b7 55 ea          	movzwl -0x16(%ebp),%edx
c0100daa:	83 c2 06             	add    $0x6,%edx
c0100dad:	0f b7 d2             	movzwl %dx,%edx
c0100db0:	66 89 55 ca          	mov    %dx,-0x36(%ebp)
c0100db4:	88 45 c9             	mov    %al,-0x37(%ebp)
        : "memory", "cc");
}

static inline void
outb(uint16_t port, uint8_t data) {
    asm volatile ("outb %0, %1" :: "a" (data), "d" (port) : "memory");
c0100db7:	0f b6 45 c9          	movzbl -0x37(%ebp),%eax
c0100dbb:	0f b7 55 ca          	movzwl -0x36(%ebp),%edx
c0100dbf:	ee                   	out    %al,(%dx)
        ide_wait_ready(iobase, 0);
c0100dc0:	0f b7 45 ea          	movzwl -0x16(%ebp),%eax
c0100dc4:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
c0100dcb:	00 
c0100dcc:	89 04 24             	mov    %eax,(%esp)
c0100dcf:	e8 17 ff ff ff       	call   c0100ceb <ide_wait_ready>

        /* step2: send ATA identify command */
        outb(iobase + ISA_COMMAND, IDE_CMD_IDENTIFY);
c0100dd4:	0f b7 45 ea          	movzwl -0x16(%ebp),%eax
c0100dd8:	83 c0 07             	add    $0x7,%eax
c0100ddb:	0f b7 c0             	movzwl %ax,%eax
c0100dde:	66 89 45 ce          	mov    %ax,-0x32(%ebp)
c0100de2:	c6 45 cd ec          	movb   $0xec,-0x33(%ebp)
c0100de6:	0f b6 45 cd          	movzbl -0x33(%ebp),%eax
c0100dea:	0f b7 55 ce          	movzwl -0x32(%ebp),%edx
c0100dee:	ee                   	out    %al,(%dx)
        ide_wait_ready(iobase, 0);
c0100def:	0f b7 45 ea          	movzwl -0x16(%ebp),%eax
c0100df3:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
c0100dfa:	00 
c0100dfb:	89 04 24             	mov    %eax,(%esp)
c0100dfe:	e8 e8 fe ff ff       	call   c0100ceb <ide_wait_ready>

        /* step3: polling */
        if (inb(iobase + ISA_STATUS) == 0 || ide_wait_ready(iobase, 1) != 0) {
c0100e03:	0f b7 45 ea          	movzwl -0x16(%ebp),%eax
c0100e07:	83 c0 07             	add    $0x7,%eax
c0100e0a:	0f b7 c0             	movzwl %ax,%eax
c0100e0d:	66 89 45 d2          	mov    %ax,-0x2e(%ebp)
    asm volatile ("inb %1, %0" : "=a" (data) : "d" (port) : "memory");
c0100e11:	0f b7 45 d2          	movzwl -0x2e(%ebp),%eax
c0100e15:	89 c2                	mov    %eax,%edx
c0100e17:	ec                   	in     (%dx),%al
c0100e18:	88 45 d1             	mov    %al,-0x2f(%ebp)
    return data;
c0100e1b:	0f b6 45 d1          	movzbl -0x2f(%ebp),%eax
c0100e1f:	84 c0                	test   %al,%al
c0100e21:	0f 84 e3 01 00 00    	je     c010100a <ide_init+0x2c6>
c0100e27:	0f b7 45 ea          	movzwl -0x16(%ebp),%eax
c0100e2b:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
c0100e32:	00 
c0100e33:	89 04 24             	mov    %eax,(%esp)
c0100e36:	e8 b0 fe ff ff       	call   c0100ceb <ide_wait_ready>
c0100e3b:	85 c0                	test   %eax,%eax
c0100e3d:	0f 85 c7 01 00 00    	jne    c010100a <ide_init+0x2c6>
            continue ;
        }

        /* device is ok */
        ide_devices[ideno].valid = 1;       //valid为1
c0100e43:	0f b7 55 f6          	movzwl -0xa(%ebp),%edx
c0100e47:	89 d0                	mov    %edx,%eax
c0100e49:	c1 e0 03             	shl    $0x3,%eax
c0100e4c:	29 d0                	sub    %edx,%eax
c0100e4e:	c1 e0 03             	shl    $0x3,%eax
c0100e51:	05 40 84 12 c0       	add    $0xc0128440,%eax
c0100e56:	c6 00 01             	movb   $0x1,(%eax)

        /* read identification space of the device */
        unsigned int buffer[128];
        insl(iobase + ISA_DATA, buffer, sizeof(buffer) / sizeof(unsigned int));
c0100e59:	0f b7 45 ea          	movzwl -0x16(%ebp),%eax
c0100e5d:	89 45 c4             	mov    %eax,-0x3c(%ebp)
c0100e60:	8d 85 bc fd ff ff    	lea    -0x244(%ebp),%eax
c0100e66:	89 45 c0             	mov    %eax,-0x40(%ebp)
c0100e69:	c7 45 bc 80 00 00 00 	movl   $0x80,-0x44(%ebp)
    asm volatile (
c0100e70:	8b 55 c4             	mov    -0x3c(%ebp),%edx
c0100e73:	8b 4d c0             	mov    -0x40(%ebp),%ecx
c0100e76:	8b 45 bc             	mov    -0x44(%ebp),%eax
c0100e79:	89 cb                	mov    %ecx,%ebx
c0100e7b:	89 df                	mov    %ebx,%edi
c0100e7d:	89 c1                	mov    %eax,%ecx
c0100e7f:	fc                   	cld    
c0100e80:	f2 6d                	repnz insl (%dx),%es:(%edi)
c0100e82:	89 c8                	mov    %ecx,%eax
c0100e84:	89 fb                	mov    %edi,%ebx
c0100e86:	89 5d c0             	mov    %ebx,-0x40(%ebp)
c0100e89:	89 45 bc             	mov    %eax,-0x44(%ebp)

        unsigned char *ident = (unsigned char *)buffer;
c0100e8c:	8d 85 bc fd ff ff    	lea    -0x244(%ebp),%eax
c0100e92:	89 45 e4             	mov    %eax,-0x1c(%ebp)
        unsigned int sectors;
        unsigned int cmdsets = *(unsigned int *)(ident + IDE_IDENT_CMDSETS);
c0100e95:	8b 45 e4             	mov    -0x1c(%ebp),%eax
c0100e98:	8b 80 a4 00 00 00    	mov    0xa4(%eax),%eax
c0100e9e:	89 45 e0             	mov    %eax,-0x20(%ebp)
        /* device use 48-bits or 28-bits addressing */
        if (cmdsets & (1 << 26)) {
c0100ea1:	8b 45 e0             	mov    -0x20(%ebp),%eax
c0100ea4:	25 00 00 00 04       	and    $0x4000000,%eax
c0100ea9:	85 c0                	test   %eax,%eax
c0100eab:	74 0e                	je     c0100ebb <ide_init+0x177>
            sectors = *(unsigned int *)(ident + IDE_IDENT_MAX_LBA_EXT);
c0100ead:	8b 45 e4             	mov    -0x1c(%ebp),%eax
c0100eb0:	8b 80 c8 00 00 00    	mov    0xc8(%eax),%eax
c0100eb6:	89 45 f0             	mov    %eax,-0x10(%ebp)
c0100eb9:	eb 09                	jmp    c0100ec4 <ide_init+0x180>
        }
        else {
            sectors = *(unsigned int *)(ident + IDE_IDENT_MAX_LBA);
c0100ebb:	8b 45 e4             	mov    -0x1c(%ebp),%eax
c0100ebe:	8b 40 78             	mov    0x78(%eax),%eax
c0100ec1:	89 45 f0             	mov    %eax,-0x10(%ebp)
        }
        ide_devices[ideno].sets = cmdsets;
c0100ec4:	0f b7 55 f6          	movzwl -0xa(%ebp),%edx
c0100ec8:	89 d0                	mov    %edx,%eax
c0100eca:	c1 e0 03             	shl    $0x3,%eax
c0100ecd:	29 d0                	sub    %edx,%eax
c0100ecf:	c1 e0 03             	shl    $0x3,%eax
c0100ed2:	8d 90 44 84 12 c0    	lea    -0x3fed7bbc(%eax),%edx
c0100ed8:	8b 45 e0             	mov    -0x20(%ebp),%eax
c0100edb:	89 02                	mov    %eax,(%edx)
        ide_devices[ideno].size = sectors;
c0100edd:	0f b7 55 f6          	movzwl -0xa(%ebp),%edx
c0100ee1:	89 d0                	mov    %edx,%eax
c0100ee3:	c1 e0 03             	shl    $0x3,%eax
c0100ee6:	29 d0                	sub    %edx,%eax
c0100ee8:	c1 e0 03             	shl    $0x3,%eax
c0100eeb:	8d 90 48 84 12 c0    	lea    -0x3fed7bb8(%eax),%edx
c0100ef1:	8b 45 f0             	mov    -0x10(%ebp),%eax
c0100ef4:	89 02                	mov    %eax,(%edx)

        /* check if supports LBA */
        assert((*(unsigned short *)(ident + IDE_IDENT_CAPABILITIES) & 0x200) != 0);
c0100ef6:	8b 45 e4             	mov    -0x1c(%ebp),%eax
c0100ef9:	83 c0 62             	add    $0x62,%eax
c0100efc:	0f b7 00             	movzwl (%eax),%eax
c0100eff:	25 00 02 00 00       	and    $0x200,%eax
c0100f04:	85 c0                	test   %eax,%eax
c0100f06:	75 24                	jne    c0100f2c <ide_init+0x1e8>
c0100f08:	c7 44 24 0c 94 a0 10 	movl   $0xc010a094,0xc(%esp)
c0100f0f:	c0 
c0100f10:	c7 44 24 08 d7 a0 10 	movl   $0xc010a0d7,0x8(%esp)
c0100f17:	c0 
c0100f18:	c7 44 24 04 7d 00 00 	movl   $0x7d,0x4(%esp)
c0100f1f:	00 
c0100f20:	c7 04 24 ec a0 10 c0 	movl   $0xc010a0ec,(%esp)
c0100f27:	e8 d4 f4 ff ff       	call   c0100400 <__panic>

        unsigned char *model = ide_devices[ideno].model, *data = ident + IDE_IDENT_MODEL;
c0100f2c:	0f b7 55 f6          	movzwl -0xa(%ebp),%edx
c0100f30:	89 d0                	mov    %edx,%eax
c0100f32:	c1 e0 03             	shl    $0x3,%eax
c0100f35:	29 d0                	sub    %edx,%eax
c0100f37:	c1 e0 03             	shl    $0x3,%eax
c0100f3a:	05 40 84 12 c0       	add    $0xc0128440,%eax
c0100f3f:	83 c0 0c             	add    $0xc,%eax
c0100f42:	89 45 dc             	mov    %eax,-0x24(%ebp)
c0100f45:	8b 45 e4             	mov    -0x1c(%ebp),%eax
c0100f48:	83 c0 36             	add    $0x36,%eax
c0100f4b:	89 45 d8             	mov    %eax,-0x28(%ebp)
        unsigned int i, length = 40;
c0100f4e:	c7 45 d4 28 00 00 00 	movl   $0x28,-0x2c(%ebp)
        for (i = 0; i < length; i += 2) {
c0100f55:	c7 45 ec 00 00 00 00 	movl   $0x0,-0x14(%ebp)
c0100f5c:	eb 34                	jmp    c0100f92 <ide_init+0x24e>
            model[i] = data[i + 1], model[i + 1] = data[i];
c0100f5e:	8b 45 ec             	mov    -0x14(%ebp),%eax
c0100f61:	8d 50 01             	lea    0x1(%eax),%edx
c0100f64:	8b 45 d8             	mov    -0x28(%ebp),%eax
c0100f67:	01 d0                	add    %edx,%eax
c0100f69:	8b 4d dc             	mov    -0x24(%ebp),%ecx
c0100f6c:	8b 55 ec             	mov    -0x14(%ebp),%edx
c0100f6f:	01 ca                	add    %ecx,%edx
c0100f71:	0f b6 00             	movzbl (%eax),%eax
c0100f74:	88 02                	mov    %al,(%edx)
c0100f76:	8b 55 d8             	mov    -0x28(%ebp),%edx
c0100f79:	8b 45 ec             	mov    -0x14(%ebp),%eax
c0100f7c:	01 d0                	add    %edx,%eax
c0100f7e:	8b 55 ec             	mov    -0x14(%ebp),%edx
c0100f81:	8d 4a 01             	lea    0x1(%edx),%ecx
c0100f84:	8b 55 dc             	mov    -0x24(%ebp),%edx
c0100f87:	01 ca                	add    %ecx,%edx
c0100f89:	0f b6 00             	movzbl (%eax),%eax
c0100f8c:	88 02                	mov    %al,(%edx)
        for (i = 0; i < length; i += 2) {
c0100f8e:	83 45 ec 02          	addl   $0x2,-0x14(%ebp)
c0100f92:	8b 45 ec             	mov    -0x14(%ebp),%eax
c0100f95:	3b 45 d4             	cmp    -0x2c(%ebp),%eax
c0100f98:	72 c4                	jb     c0100f5e <ide_init+0x21a>
        }
        do {
            model[i] = '\0';
c0100f9a:	8b 55 dc             	mov    -0x24(%ebp),%edx
c0100f9d:	8b 45 ec             	mov    -0x14(%ebp),%eax
c0100fa0:	01 d0                	add    %edx,%eax
c0100fa2:	c6 00 00             	movb   $0x0,(%eax)
        } while (i -- > 0 && model[i] == ' ');
c0100fa5:	8b 45 ec             	mov    -0x14(%ebp),%eax
c0100fa8:	8d 50 ff             	lea    -0x1(%eax),%edx
c0100fab:	89 55 ec             	mov    %edx,-0x14(%ebp)
c0100fae:	85 c0                	test   %eax,%eax
c0100fb0:	74 0f                	je     c0100fc1 <ide_init+0x27d>
c0100fb2:	8b 55 dc             	mov    -0x24(%ebp),%edx
c0100fb5:	8b 45 ec             	mov    -0x14(%ebp),%eax
c0100fb8:	01 d0                	add    %edx,%eax
c0100fba:	0f b6 00             	movzbl (%eax),%eax
c0100fbd:	3c 20                	cmp    $0x20,%al
c0100fbf:	74 d9                	je     c0100f9a <ide_init+0x256>

        cprintf("ide %d: %10u(sectors), '%s'.\n", ideno, ide_devices[ideno].size, ide_devices[ideno].model);
c0100fc1:	0f b7 55 f6          	movzwl -0xa(%ebp),%edx
c0100fc5:	89 d0                	mov    %edx,%eax
c0100fc7:	c1 e0 03             	shl    $0x3,%eax
c0100fca:	29 d0                	sub    %edx,%eax
c0100fcc:	c1 e0 03             	shl    $0x3,%eax
c0100fcf:	05 40 84 12 c0       	add    $0xc0128440,%eax
c0100fd4:	8d 48 0c             	lea    0xc(%eax),%ecx
c0100fd7:	0f b7 55 f6          	movzwl -0xa(%ebp),%edx
c0100fdb:	89 d0                	mov    %edx,%eax
c0100fdd:	c1 e0 03             	shl    $0x3,%eax
c0100fe0:	29 d0                	sub    %edx,%eax
c0100fe2:	c1 e0 03             	shl    $0x3,%eax
c0100fe5:	05 48 84 12 c0       	add    $0xc0128448,%eax
c0100fea:	8b 10                	mov    (%eax),%edx
c0100fec:	0f b7 45 f6          	movzwl -0xa(%ebp),%eax
c0100ff0:	89 4c 24 0c          	mov    %ecx,0xc(%esp)
c0100ff4:	89 54 24 08          	mov    %edx,0x8(%esp)
c0100ff8:	89 44 24 04          	mov    %eax,0x4(%esp)
c0100ffc:	c7 04 24 fe a0 10 c0 	movl   $0xc010a0fe,(%esp)
c0101003:	e8 a1 f2 ff ff       	call   c01002a9 <cprintf>
c0101008:	eb 01                	jmp    c010100b <ide_init+0x2c7>
            continue ;
c010100a:	90                   	nop
    for (ideno = 0; ideno < MAX_IDE; ideno ++) {    //0.1.2.3
c010100b:	0f b7 45 f6          	movzwl -0xa(%ebp),%eax
c010100f:	40                   	inc    %eax
c0101010:	66 89 45 f6          	mov    %ax,-0xa(%ebp)
c0101014:	0f b7 45 f6          	movzwl -0xa(%ebp),%eax
c0101018:	83 f8 03             	cmp    $0x3,%eax
c010101b:	0f 86 39 fd ff ff    	jbe    c0100d5a <ide_init+0x16>
    }

    // enable ide interrupt
    pic_enable(IRQ_IDE1);
c0101021:	c7 04 24 0e 00 00 00 	movl   $0xe,(%esp)
c0101028:	e8 91 0e 00 00       	call   c0101ebe <pic_enable>
    pic_enable(IRQ_IDE2);
c010102d:	c7 04 24 0f 00 00 00 	movl   $0xf,(%esp)
c0101034:	e8 85 0e 00 00       	call   c0101ebe <pic_enable>
}
c0101039:	90                   	nop
c010103a:	81 c4 50 02 00 00    	add    $0x250,%esp
c0101040:	5b                   	pop    %ebx
c0101041:	5f                   	pop    %edi
c0101042:	5d                   	pop    %ebp
c0101043:	c3                   	ret    

c0101044 <ide_device_valid>:

bool
ide_device_valid(unsigned short ideno) {
c0101044:	55                   	push   %ebp
c0101045:	89 e5                	mov    %esp,%ebp
c0101047:	83 ec 04             	sub    $0x4,%esp
c010104a:	8b 45 08             	mov    0x8(%ebp),%eax
c010104d:	66 89 45 fc          	mov    %ax,-0x4(%ebp)
    return VALID_IDE(ideno);
c0101051:	0f b7 45 fc          	movzwl -0x4(%ebp),%eax
c0101055:	83 f8 03             	cmp    $0x3,%eax
c0101058:	77 21                	ja     c010107b <ide_device_valid+0x37>
c010105a:	0f b7 55 fc          	movzwl -0x4(%ebp),%edx
c010105e:	89 d0                	mov    %edx,%eax
c0101060:	c1 e0 03             	shl    $0x3,%eax
c0101063:	29 d0                	sub    %edx,%eax
c0101065:	c1 e0 03             	shl    $0x3,%eax
c0101068:	05 40 84 12 c0       	add    $0xc0128440,%eax
c010106d:	0f b6 00             	movzbl (%eax),%eax
c0101070:	84 c0                	test   %al,%al
c0101072:	74 07                	je     c010107b <ide_device_valid+0x37>
c0101074:	b8 01 00 00 00       	mov    $0x1,%eax
c0101079:	eb 05                	jmp    c0101080 <ide_device_valid+0x3c>
c010107b:	b8 00 00 00 00       	mov    $0x0,%eax
}
c0101080:	c9                   	leave  
c0101081:	c3                   	ret    

c0101082 <ide_device_size>:

size_t
ide_device_size(unsigned short ideno) {
c0101082:	55                   	push   %ebp
c0101083:	89 e5                	mov    %esp,%ebp
c0101085:	83 ec 08             	sub    $0x8,%esp
c0101088:	8b 45 08             	mov    0x8(%ebp),%eax
c010108b:	66 89 45 fc          	mov    %ax,-0x4(%ebp)
    if (ide_device_valid(ideno)) {
c010108f:	0f b7 45 fc          	movzwl -0x4(%ebp),%eax
c0101093:	89 04 24             	mov    %eax,(%esp)
c0101096:	e8 a9 ff ff ff       	call   c0101044 <ide_device_valid>
c010109b:	85 c0                	test   %eax,%eax
c010109d:	74 17                	je     c01010b6 <ide_device_size+0x34>
        return ide_devices[ideno].size;
c010109f:	0f b7 55 fc          	movzwl -0x4(%ebp),%edx
c01010a3:	89 d0                	mov    %edx,%eax
c01010a5:	c1 e0 03             	shl    $0x3,%eax
c01010a8:	29 d0                	sub    %edx,%eax
c01010aa:	c1 e0 03             	shl    $0x3,%eax
c01010ad:	05 48 84 12 c0       	add    $0xc0128448,%eax
c01010b2:	8b 00                	mov    (%eax),%eax
c01010b4:	eb 05                	jmp    c01010bb <ide_device_size+0x39>
    }
    return 0;
c01010b6:	b8 00 00 00 00       	mov    $0x0,%eax
}
c01010bb:	c9                   	leave  
c01010bc:	c3                   	ret    

c01010bd <ide_read_secs>:

int
ide_read_secs(unsigned short ideno, uint32_t secno, void *dst, size_t nsecs) {
c01010bd:	55                   	push   %ebp
c01010be:	89 e5                	mov    %esp,%ebp
c01010c0:	57                   	push   %edi
c01010c1:	53                   	push   %ebx
c01010c2:	83 ec 50             	sub    $0x50,%esp
c01010c5:	8b 45 08             	mov    0x8(%ebp),%eax
c01010c8:	66 89 45 c4          	mov    %ax,-0x3c(%ebp)
    assert(nsecs <= MAX_NSECS && VALID_IDE(ideno));
c01010cc:	81 7d 14 80 00 00 00 	cmpl   $0x80,0x14(%ebp)
c01010d3:	77 23                	ja     c01010f8 <ide_read_secs+0x3b>
c01010d5:	0f b7 45 c4          	movzwl -0x3c(%ebp),%eax
c01010d9:	83 f8 03             	cmp    $0x3,%eax
c01010dc:	77 1a                	ja     c01010f8 <ide_read_secs+0x3b>
c01010de:	0f b7 55 c4          	movzwl -0x3c(%ebp),%edx
c01010e2:	89 d0                	mov    %edx,%eax
c01010e4:	c1 e0 03             	shl    $0x3,%eax
c01010e7:	29 d0                	sub    %edx,%eax
c01010e9:	c1 e0 03             	shl    $0x3,%eax
c01010ec:	05 40 84 12 c0       	add    $0xc0128440,%eax
c01010f1:	0f b6 00             	movzbl (%eax),%eax
c01010f4:	84 c0                	test   %al,%al
c01010f6:	75 24                	jne    c010111c <ide_read_secs+0x5f>
c01010f8:	c7 44 24 0c 1c a1 10 	movl   $0xc010a11c,0xc(%esp)
c01010ff:	c0 
c0101100:	c7 44 24 08 d7 a0 10 	movl   $0xc010a0d7,0x8(%esp)
c0101107:	c0 
c0101108:	c7 44 24 04 9f 00 00 	movl   $0x9f,0x4(%esp)
c010110f:	00 
c0101110:	c7 04 24 ec a0 10 c0 	movl   $0xc010a0ec,(%esp)
c0101117:	e8 e4 f2 ff ff       	call   c0100400 <__panic>
    assert(secno < MAX_DISK_NSECS && secno + nsecs <= MAX_DISK_NSECS);
c010111c:	81 7d 0c ff ff ff 0f 	cmpl   $0xfffffff,0xc(%ebp)
c0101123:	77 0f                	ja     c0101134 <ide_read_secs+0x77>
c0101125:	8b 55 0c             	mov    0xc(%ebp),%edx
c0101128:	8b 45 14             	mov    0x14(%ebp),%eax
c010112b:	01 d0                	add    %edx,%eax
c010112d:	3d 00 00 00 10       	cmp    $0x10000000,%eax
c0101132:	76 24                	jbe    c0101158 <ide_read_secs+0x9b>
c0101134:	c7 44 24 0c 44 a1 10 	movl   $0xc010a144,0xc(%esp)
c010113b:	c0 
c010113c:	c7 44 24 08 d7 a0 10 	movl   $0xc010a0d7,0x8(%esp)
c0101143:	c0 
c0101144:	c7 44 24 04 a0 00 00 	movl   $0xa0,0x4(%esp)
c010114b:	00 
c010114c:	c7 04 24 ec a0 10 c0 	movl   $0xc010a0ec,(%esp)
c0101153:	e8 a8 f2 ff ff       	call   c0100400 <__panic>
    unsigned short iobase = IO_BASE(ideno), ioctrl = IO_CTRL(ideno);
c0101158:	0f b7 45 c4          	movzwl -0x3c(%ebp),%eax
c010115c:	d1 e8                	shr    %eax
c010115e:	0f b7 c0             	movzwl %ax,%eax
c0101161:	8b 04 85 8c a0 10 c0 	mov    -0x3fef5f74(,%eax,4),%eax
c0101168:	66 89 45 f2          	mov    %ax,-0xe(%ebp)
c010116c:	0f b7 45 c4          	movzwl -0x3c(%ebp),%eax
c0101170:	d1 e8                	shr    %eax
c0101172:	0f b7 c0             	movzwl %ax,%eax
c0101175:	0f b7 04 85 8e a0 10 	movzwl -0x3fef5f72(,%eax,4),%eax
c010117c:	c0 
c010117d:	66 89 45 f0          	mov    %ax,-0x10(%ebp)

    ide_wait_ready(iobase, 0);
c0101181:	0f b7 45 f2          	movzwl -0xe(%ebp),%eax
c0101185:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
c010118c:	00 
c010118d:	89 04 24             	mov    %eax,(%esp)
c0101190:	e8 56 fb ff ff       	call   c0100ceb <ide_wait_ready>

    // generate interrupt
    outb(ioctrl + ISA_CTRL, 0);
c0101195:	8b 45 f0             	mov    -0x10(%ebp),%eax
c0101198:	83 c0 02             	add    $0x2,%eax
c010119b:	0f b7 c0             	movzwl %ax,%eax
c010119e:	66 89 45 d6          	mov    %ax,-0x2a(%ebp)
c01011a2:	c6 45 d5 00          	movb   $0x0,-0x2b(%ebp)
    asm volatile ("outb %0, %1" :: "a" (data), "d" (port) : "memory");
c01011a6:	0f b6 45 d5          	movzbl -0x2b(%ebp),%eax
c01011aa:	0f b7 55 d6          	movzwl -0x2a(%ebp),%edx
c01011ae:	ee                   	out    %al,(%dx)
    outb(iobase + ISA_SECCNT, nsecs);
c01011af:	8b 45 14             	mov    0x14(%ebp),%eax
c01011b2:	0f b6 c0             	movzbl %al,%eax
c01011b5:	0f b7 55 f2          	movzwl -0xe(%ebp),%edx
c01011b9:	83 c2 02             	add    $0x2,%edx
c01011bc:	0f b7 d2             	movzwl %dx,%edx
c01011bf:	66 89 55 da          	mov    %dx,-0x26(%ebp)
c01011c3:	88 45 d9             	mov    %al,-0x27(%ebp)
c01011c6:	0f b6 45 d9          	movzbl -0x27(%ebp),%eax
c01011ca:	0f b7 55 da          	movzwl -0x26(%ebp),%edx
c01011ce:	ee                   	out    %al,(%dx)
    outb(iobase + ISA_SECTOR, secno & 0xFF);
c01011cf:	8b 45 0c             	mov    0xc(%ebp),%eax
c01011d2:	0f b6 c0             	movzbl %al,%eax
c01011d5:	0f b7 55 f2          	movzwl -0xe(%ebp),%edx
c01011d9:	83 c2 03             	add    $0x3,%edx
c01011dc:	0f b7 d2             	movzwl %dx,%edx
c01011df:	66 89 55 de          	mov    %dx,-0x22(%ebp)
c01011e3:	88 45 dd             	mov    %al,-0x23(%ebp)
c01011e6:	0f b6 45 dd          	movzbl -0x23(%ebp),%eax
c01011ea:	0f b7 55 de          	movzwl -0x22(%ebp),%edx
c01011ee:	ee                   	out    %al,(%dx)
    outb(iobase + ISA_CYL_LO, (secno >> 8) & 0xFF);
c01011ef:	8b 45 0c             	mov    0xc(%ebp),%eax
c01011f2:	c1 e8 08             	shr    $0x8,%eax
c01011f5:	0f b6 c0             	movzbl %al,%eax
c01011f8:	0f b7 55 f2          	movzwl -0xe(%ebp),%edx
c01011fc:	83 c2 04             	add    $0x4,%edx
c01011ff:	0f b7 d2             	movzwl %dx,%edx
c0101202:	66 89 55 e2          	mov    %dx,-0x1e(%ebp)
c0101206:	88 45 e1             	mov    %al,-0x1f(%ebp)
c0101209:	0f b6 45 e1          	movzbl -0x1f(%ebp),%eax
c010120d:	0f b7 55 e2          	movzwl -0x1e(%ebp),%edx
c0101211:	ee                   	out    %al,(%dx)
    outb(iobase + ISA_CYL_HI, (secno >> 16) & 0xFF);
c0101212:	8b 45 0c             	mov    0xc(%ebp),%eax
c0101215:	c1 e8 10             	shr    $0x10,%eax
c0101218:	0f b6 c0             	movzbl %al,%eax
c010121b:	0f b7 55 f2          	movzwl -0xe(%ebp),%edx
c010121f:	83 c2 05             	add    $0x5,%edx
c0101222:	0f b7 d2             	movzwl %dx,%edx
c0101225:	66 89 55 e6          	mov    %dx,-0x1a(%ebp)
c0101229:	88 45 e5             	mov    %al,-0x1b(%ebp)
c010122c:	0f b6 45 e5          	movzbl -0x1b(%ebp),%eax
c0101230:	0f b7 55 e6          	movzwl -0x1a(%ebp),%edx
c0101234:	ee                   	out    %al,(%dx)
    outb(iobase + ISA_SDH, 0xE0 | ((ideno & 1) << 4) | ((secno >> 24) & 0xF));
c0101235:	8b 45 c4             	mov    -0x3c(%ebp),%eax
c0101238:	c0 e0 04             	shl    $0x4,%al
c010123b:	24 10                	and    $0x10,%al
c010123d:	88 c2                	mov    %al,%dl
c010123f:	8b 45 0c             	mov    0xc(%ebp),%eax
c0101242:	c1 e8 18             	shr    $0x18,%eax
c0101245:	24 0f                	and    $0xf,%al
c0101247:	08 d0                	or     %dl,%al
c0101249:	0c e0                	or     $0xe0,%al
c010124b:	0f b6 c0             	movzbl %al,%eax
c010124e:	0f b7 55 f2          	movzwl -0xe(%ebp),%edx
c0101252:	83 c2 06             	add    $0x6,%edx
c0101255:	0f b7 d2             	movzwl %dx,%edx
c0101258:	66 89 55 ea          	mov    %dx,-0x16(%ebp)
c010125c:	88 45 e9             	mov    %al,-0x17(%ebp)
c010125f:	0f b6 45 e9          	movzbl -0x17(%ebp),%eax
c0101263:	0f b7 55 ea          	movzwl -0x16(%ebp),%edx
c0101267:	ee                   	out    %al,(%dx)
    outb(iobase + ISA_COMMAND, IDE_CMD_READ);
c0101268:	0f b7 45 f2          	movzwl -0xe(%ebp),%eax
c010126c:	83 c0 07             	add    $0x7,%eax
c010126f:	0f b7 c0             	movzwl %ax,%eax
c0101272:	66 89 45 ee          	mov    %ax,-0x12(%ebp)
c0101276:	c6 45 ed 20          	movb   $0x20,-0x13(%ebp)
c010127a:	0f b6 45 ed          	movzbl -0x13(%ebp),%eax
c010127e:	0f b7 55 ee          	movzwl -0x12(%ebp),%edx
c0101282:	ee                   	out    %al,(%dx)

    int ret = 0;
c0101283:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
    for (; nsecs > 0; nsecs --, dst += SECTSIZE) {
c010128a:	eb 57                	jmp    c01012e3 <ide_read_secs+0x226>
        if ((ret = ide_wait_ready(iobase, 1)) != 0) {
c010128c:	0f b7 45 f2          	movzwl -0xe(%ebp),%eax
c0101290:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
c0101297:	00 
c0101298:	89 04 24             	mov    %eax,(%esp)
c010129b:	e8 4b fa ff ff       	call   c0100ceb <ide_wait_ready>
c01012a0:	89 45 f4             	mov    %eax,-0xc(%ebp)
c01012a3:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
c01012a7:	75 42                	jne    c01012eb <ide_read_secs+0x22e>
            goto out;
        }
        insl(iobase, dst, SECTSIZE / sizeof(uint32_t));
c01012a9:	0f b7 45 f2          	movzwl -0xe(%ebp),%eax
c01012ad:	89 45 d0             	mov    %eax,-0x30(%ebp)
c01012b0:	8b 45 10             	mov    0x10(%ebp),%eax
c01012b3:	89 45 cc             	mov    %eax,-0x34(%ebp)
c01012b6:	c7 45 c8 80 00 00 00 	movl   $0x80,-0x38(%ebp)
    asm volatile (
c01012bd:	8b 55 d0             	mov    -0x30(%ebp),%edx
c01012c0:	8b 4d cc             	mov    -0x34(%ebp),%ecx
c01012c3:	8b 45 c8             	mov    -0x38(%ebp),%eax
c01012c6:	89 cb                	mov    %ecx,%ebx
c01012c8:	89 df                	mov    %ebx,%edi
c01012ca:	89 c1                	mov    %eax,%ecx
c01012cc:	fc                   	cld    
c01012cd:	f2 6d                	repnz insl (%dx),%es:(%edi)
c01012cf:	89 c8                	mov    %ecx,%eax
c01012d1:	89 fb                	mov    %edi,%ebx
c01012d3:	89 5d cc             	mov    %ebx,-0x34(%ebp)
c01012d6:	89 45 c8             	mov    %eax,-0x38(%ebp)
    for (; nsecs > 0; nsecs --, dst += SECTSIZE) {
c01012d9:	ff 4d 14             	decl   0x14(%ebp)
c01012dc:	81 45 10 00 02 00 00 	addl   $0x200,0x10(%ebp)
c01012e3:	83 7d 14 00          	cmpl   $0x0,0x14(%ebp)
c01012e7:	75 a3                	jne    c010128c <ide_read_secs+0x1cf>
    }

out:
c01012e9:	eb 01                	jmp    c01012ec <ide_read_secs+0x22f>
            goto out;
c01012eb:	90                   	nop
    return ret;
c01012ec:	8b 45 f4             	mov    -0xc(%ebp),%eax
}
c01012ef:	83 c4 50             	add    $0x50,%esp
c01012f2:	5b                   	pop    %ebx
c01012f3:	5f                   	pop    %edi
c01012f4:	5d                   	pop    %ebp
c01012f5:	c3                   	ret    

c01012f6 <ide_write_secs>:

int
ide_write_secs(unsigned short ideno, uint32_t secno, const void *src, size_t nsecs) {   //设备号，start，是个result的page ，length
c01012f6:	55                   	push   %ebp
c01012f7:	89 e5                	mov    %esp,%ebp
c01012f9:	56                   	push   %esi
c01012fa:	53                   	push   %ebx
c01012fb:	83 ec 50             	sub    $0x50,%esp
c01012fe:	8b 45 08             	mov    0x8(%ebp),%eax
c0101301:	66 89 45 c4          	mov    %ax,-0x3c(%ebp)
    assert(nsecs <= MAX_NSECS && VALID_IDE(ideno));     //128
c0101305:	81 7d 14 80 00 00 00 	cmpl   $0x80,0x14(%ebp)
c010130c:	77 23                	ja     c0101331 <ide_write_secs+0x3b>
c010130e:	0f b7 45 c4          	movzwl -0x3c(%ebp),%eax
c0101312:	83 f8 03             	cmp    $0x3,%eax
c0101315:	77 1a                	ja     c0101331 <ide_write_secs+0x3b>
c0101317:	0f b7 55 c4          	movzwl -0x3c(%ebp),%edx
c010131b:	89 d0                	mov    %edx,%eax
c010131d:	c1 e0 03             	shl    $0x3,%eax
c0101320:	29 d0                	sub    %edx,%eax
c0101322:	c1 e0 03             	shl    $0x3,%eax
c0101325:	05 40 84 12 c0       	add    $0xc0128440,%eax
c010132a:	0f b6 00             	movzbl (%eax),%eax
c010132d:	84 c0                	test   %al,%al
c010132f:	75 24                	jne    c0101355 <ide_write_secs+0x5f>
c0101331:	c7 44 24 0c 1c a1 10 	movl   $0xc010a11c,0xc(%esp)
c0101338:	c0 
c0101339:	c7 44 24 08 d7 a0 10 	movl   $0xc010a0d7,0x8(%esp)
c0101340:	c0 
c0101341:	c7 44 24 04 bc 00 00 	movl   $0xbc,0x4(%esp)
c0101348:	00 
c0101349:	c7 04 24 ec a0 10 c0 	movl   $0xc010a0ec,(%esp)
c0101350:	e8 ab f0 ff ff       	call   c0100400 <__panic>
    assert(secno < MAX_DISK_NSECS && secno + nsecs <= MAX_DISK_NSECS);      // 0x10000000U
c0101355:	81 7d 0c ff ff ff 0f 	cmpl   $0xfffffff,0xc(%ebp)
c010135c:	77 0f                	ja     c010136d <ide_write_secs+0x77>
c010135e:	8b 55 0c             	mov    0xc(%ebp),%edx
c0101361:	8b 45 14             	mov    0x14(%ebp),%eax
c0101364:	01 d0                	add    %edx,%eax
c0101366:	3d 00 00 00 10       	cmp    $0x10000000,%eax
c010136b:	76 24                	jbe    c0101391 <ide_write_secs+0x9b>
c010136d:	c7 44 24 0c 44 a1 10 	movl   $0xc010a144,0xc(%esp)
c0101374:	c0 
c0101375:	c7 44 24 08 d7 a0 10 	movl   $0xc010a0d7,0x8(%esp)
c010137c:	c0 
c010137d:	c7 44 24 04 bd 00 00 	movl   $0xbd,0x4(%esp)
c0101384:	00 
c0101385:	c7 04 24 ec a0 10 c0 	movl   $0xc010a0ec,(%esp)
c010138c:	e8 6f f0 ff ff       	call   c0100400 <__panic>
    unsigned short iobase = IO_BASE(ideno), ioctrl = IO_CTRL(ideno);
c0101391:	0f b7 45 c4          	movzwl -0x3c(%ebp),%eax
c0101395:	d1 e8                	shr    %eax
c0101397:	0f b7 c0             	movzwl %ax,%eax
c010139a:	8b 04 85 8c a0 10 c0 	mov    -0x3fef5f74(,%eax,4),%eax
c01013a1:	66 89 45 f2          	mov    %ax,-0xe(%ebp)
c01013a5:	0f b7 45 c4          	movzwl -0x3c(%ebp),%eax
c01013a9:	d1 e8                	shr    %eax
c01013ab:	0f b7 c0             	movzwl %ax,%eax
c01013ae:	0f b7 04 85 8e a0 10 	movzwl -0x3fef5f72(,%eax,4),%eax
c01013b5:	c0 
c01013b6:	66 89 45 f0          	mov    %ax,-0x10(%ebp)

    ide_wait_ready(iobase, 0);
c01013ba:	0f b7 45 f2          	movzwl -0xe(%ebp),%eax
c01013be:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
c01013c5:	00 
c01013c6:	89 04 24             	mov    %eax,(%esp)
c01013c9:	e8 1d f9 ff ff       	call   c0100ceb <ide_wait_ready>

    // generate interrupt
    outb(ioctrl + ISA_CTRL, 0);
c01013ce:	8b 45 f0             	mov    -0x10(%ebp),%eax
c01013d1:	83 c0 02             	add    $0x2,%eax
c01013d4:	0f b7 c0             	movzwl %ax,%eax
c01013d7:	66 89 45 d6          	mov    %ax,-0x2a(%ebp)
c01013db:	c6 45 d5 00          	movb   $0x0,-0x2b(%ebp)
    asm volatile ("outb %0, %1" :: "a" (data), "d" (port) : "memory");
c01013df:	0f b6 45 d5          	movzbl -0x2b(%ebp),%eax
c01013e3:	0f b7 55 d6          	movzwl -0x2a(%ebp),%edx
c01013e7:	ee                   	out    %al,(%dx)
    outb(iobase + ISA_SECCNT, nsecs);
c01013e8:	8b 45 14             	mov    0x14(%ebp),%eax
c01013eb:	0f b6 c0             	movzbl %al,%eax
c01013ee:	0f b7 55 f2          	movzwl -0xe(%ebp),%edx
c01013f2:	83 c2 02             	add    $0x2,%edx
c01013f5:	0f b7 d2             	movzwl %dx,%edx
c01013f8:	66 89 55 da          	mov    %dx,-0x26(%ebp)
c01013fc:	88 45 d9             	mov    %al,-0x27(%ebp)
c01013ff:	0f b6 45 d9          	movzbl -0x27(%ebp),%eax
c0101403:	0f b7 55 da          	movzwl -0x26(%ebp),%edx
c0101407:	ee                   	out    %al,(%dx)
    outb(iobase + ISA_SECTOR, secno & 0xFF);
c0101408:	8b 45 0c             	mov    0xc(%ebp),%eax
c010140b:	0f b6 c0             	movzbl %al,%eax
c010140e:	0f b7 55 f2          	movzwl -0xe(%ebp),%edx
c0101412:	83 c2 03             	add    $0x3,%edx
c0101415:	0f b7 d2             	movzwl %dx,%edx
c0101418:	66 89 55 de          	mov    %dx,-0x22(%ebp)
c010141c:	88 45 dd             	mov    %al,-0x23(%ebp)
c010141f:	0f b6 45 dd          	movzbl -0x23(%ebp),%eax
c0101423:	0f b7 55 de          	movzwl -0x22(%ebp),%edx
c0101427:	ee                   	out    %al,(%dx)
    outb(iobase + ISA_CYL_LO, (secno >> 8) & 0xFF);
c0101428:	8b 45 0c             	mov    0xc(%ebp),%eax
c010142b:	c1 e8 08             	shr    $0x8,%eax
c010142e:	0f b6 c0             	movzbl %al,%eax
c0101431:	0f b7 55 f2          	movzwl -0xe(%ebp),%edx
c0101435:	83 c2 04             	add    $0x4,%edx
c0101438:	0f b7 d2             	movzwl %dx,%edx
c010143b:	66 89 55 e2          	mov    %dx,-0x1e(%ebp)
c010143f:	88 45 e1             	mov    %al,-0x1f(%ebp)
c0101442:	0f b6 45 e1          	movzbl -0x1f(%ebp),%eax
c0101446:	0f b7 55 e2          	movzwl -0x1e(%ebp),%edx
c010144a:	ee                   	out    %al,(%dx)
    outb(iobase + ISA_CYL_HI, (secno >> 16) & 0xFF);
c010144b:	8b 45 0c             	mov    0xc(%ebp),%eax
c010144e:	c1 e8 10             	shr    $0x10,%eax
c0101451:	0f b6 c0             	movzbl %al,%eax
c0101454:	0f b7 55 f2          	movzwl -0xe(%ebp),%edx
c0101458:	83 c2 05             	add    $0x5,%edx
c010145b:	0f b7 d2             	movzwl %dx,%edx
c010145e:	66 89 55 e6          	mov    %dx,-0x1a(%ebp)
c0101462:	88 45 e5             	mov    %al,-0x1b(%ebp)
c0101465:	0f b6 45 e5          	movzbl -0x1b(%ebp),%eax
c0101469:	0f b7 55 e6          	movzwl -0x1a(%ebp),%edx
c010146d:	ee                   	out    %al,(%dx)
    outb(iobase + ISA_SDH, 0xE0 | ((ideno & 1) << 4) | ((secno >> 24) & 0xF));
c010146e:	8b 45 c4             	mov    -0x3c(%ebp),%eax
c0101471:	c0 e0 04             	shl    $0x4,%al
c0101474:	24 10                	and    $0x10,%al
c0101476:	88 c2                	mov    %al,%dl
c0101478:	8b 45 0c             	mov    0xc(%ebp),%eax
c010147b:	c1 e8 18             	shr    $0x18,%eax
c010147e:	24 0f                	and    $0xf,%al
c0101480:	08 d0                	or     %dl,%al
c0101482:	0c e0                	or     $0xe0,%al
c0101484:	0f b6 c0             	movzbl %al,%eax
c0101487:	0f b7 55 f2          	movzwl -0xe(%ebp),%edx
c010148b:	83 c2 06             	add    $0x6,%edx
c010148e:	0f b7 d2             	movzwl %dx,%edx
c0101491:	66 89 55 ea          	mov    %dx,-0x16(%ebp)
c0101495:	88 45 e9             	mov    %al,-0x17(%ebp)
c0101498:	0f b6 45 e9          	movzbl -0x17(%ebp),%eax
c010149c:	0f b7 55 ea          	movzwl -0x16(%ebp),%edx
c01014a0:	ee                   	out    %al,(%dx)
    outb(iobase + ISA_COMMAND, IDE_CMD_WRITE);
c01014a1:	0f b7 45 f2          	movzwl -0xe(%ebp),%eax
c01014a5:	83 c0 07             	add    $0x7,%eax
c01014a8:	0f b7 c0             	movzwl %ax,%eax
c01014ab:	66 89 45 ee          	mov    %ax,-0x12(%ebp)
c01014af:	c6 45 ed 30          	movb   $0x30,-0x13(%ebp)
c01014b3:	0f b6 45 ed          	movzbl -0x13(%ebp),%eax
c01014b7:	0f b7 55 ee          	movzwl -0x12(%ebp),%edx
c01014bb:	ee                   	out    %al,(%dx)

    int ret = 0;
c01014bc:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
    for (; nsecs > 0; nsecs --, src += SECTSIZE) {
c01014c3:	eb 57                	jmp    c010151c <ide_write_secs+0x226>
        if ((ret = ide_wait_ready(iobase, 1)) != 0) {
c01014c5:	0f b7 45 f2          	movzwl -0xe(%ebp),%eax
c01014c9:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
c01014d0:	00 
c01014d1:	89 04 24             	mov    %eax,(%esp)
c01014d4:	e8 12 f8 ff ff       	call   c0100ceb <ide_wait_ready>
c01014d9:	89 45 f4             	mov    %eax,-0xc(%ebp)
c01014dc:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
c01014e0:	75 42                	jne    c0101524 <ide_write_secs+0x22e>
            goto out;
        }
        outsl(iobase, src, SECTSIZE / sizeof(uint32_t));
c01014e2:	0f b7 45 f2          	movzwl -0xe(%ebp),%eax
c01014e6:	89 45 d0             	mov    %eax,-0x30(%ebp)
c01014e9:	8b 45 10             	mov    0x10(%ebp),%eax
c01014ec:	89 45 cc             	mov    %eax,-0x34(%ebp)
c01014ef:	c7 45 c8 80 00 00 00 	movl   $0x80,-0x38(%ebp)
    asm volatile ("outw %0, %1" :: "a" (data), "d" (port) : "memory");
}

static inline void
outsl(uint32_t port, const void *addr, int cnt) {
    asm volatile (
c01014f6:	8b 55 d0             	mov    -0x30(%ebp),%edx
c01014f9:	8b 4d cc             	mov    -0x34(%ebp),%ecx
c01014fc:	8b 45 c8             	mov    -0x38(%ebp),%eax
c01014ff:	89 cb                	mov    %ecx,%ebx
c0101501:	89 de                	mov    %ebx,%esi
c0101503:	89 c1                	mov    %eax,%ecx
c0101505:	fc                   	cld    
c0101506:	f2 6f                	repnz outsl %ds:(%esi),(%dx)
c0101508:	89 c8                	mov    %ecx,%eax
c010150a:	89 f3                	mov    %esi,%ebx
c010150c:	89 5d cc             	mov    %ebx,-0x34(%ebp)
c010150f:	89 45 c8             	mov    %eax,-0x38(%ebp)
    for (; nsecs > 0; nsecs --, src += SECTSIZE) {
c0101512:	ff 4d 14             	decl   0x14(%ebp)
c0101515:	81 45 10 00 02 00 00 	addl   $0x200,0x10(%ebp)
c010151c:	83 7d 14 00          	cmpl   $0x0,0x14(%ebp)
c0101520:	75 a3                	jne    c01014c5 <ide_write_secs+0x1cf>
    }

out:
c0101522:	eb 01                	jmp    c0101525 <ide_write_secs+0x22f>
            goto out;
c0101524:	90                   	nop
    return ret;
c0101525:	8b 45 f4             	mov    -0xc(%ebp),%eax
}
c0101528:	83 c4 50             	add    $0x50,%esp
c010152b:	5b                   	pop    %ebx
c010152c:	5e                   	pop    %esi
c010152d:	5d                   	pop    %ebp
c010152e:	c3                   	ret    

c010152f <clock_init>:
/* *
 * clock_init - initialize 8253 clock to interrupt 100 times per second,
 * and then enable IRQ_TIMER.
 * */
void
clock_init(void) {
c010152f:	55                   	push   %ebp
c0101530:	89 e5                	mov    %esp,%ebp
c0101532:	83 ec 28             	sub    $0x28,%esp
c0101535:	66 c7 45 ee 43 00    	movw   $0x43,-0x12(%ebp)
c010153b:	c6 45 ed 34          	movb   $0x34,-0x13(%ebp)
    asm volatile ("outb %0, %1" :: "a" (data), "d" (port) : "memory");
c010153f:	0f b6 45 ed          	movzbl -0x13(%ebp),%eax
c0101543:	0f b7 55 ee          	movzwl -0x12(%ebp),%edx
c0101547:	ee                   	out    %al,(%dx)
c0101548:	66 c7 45 f2 40 00    	movw   $0x40,-0xe(%ebp)
c010154e:	c6 45 f1 9c          	movb   $0x9c,-0xf(%ebp)
c0101552:	0f b6 45 f1          	movzbl -0xf(%ebp),%eax
c0101556:	0f b7 55 f2          	movzwl -0xe(%ebp),%edx
c010155a:	ee                   	out    %al,(%dx)
c010155b:	66 c7 45 f6 40 00    	movw   $0x40,-0xa(%ebp)
c0101561:	c6 45 f5 2e          	movb   $0x2e,-0xb(%ebp)
c0101565:	0f b6 45 f5          	movzbl -0xb(%ebp),%eax
c0101569:	0f b7 55 f6          	movzwl -0xa(%ebp),%edx
c010156d:	ee                   	out    %al,(%dx)
    outb(TIMER_MODE, TIMER_SEL0 | TIMER_RATEGEN | TIMER_16BIT);
    outb(IO_TIMER1, TIMER_DIV(100) % 256);
    outb(IO_TIMER1, TIMER_DIV(100) / 256);

    // initialize time counter 'ticks' to zero
    ticks = 0;
c010156e:	c7 05 54 b0 12 c0 00 	movl   $0x0,0xc012b054
c0101575:	00 00 00 

    cprintf("++ setup timer interrupts\n");
c0101578:	c7 04 24 7e a1 10 c0 	movl   $0xc010a17e,(%esp)
c010157f:	e8 25 ed ff ff       	call   c01002a9 <cprintf>
    pic_enable(IRQ_TIMER);
c0101584:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
c010158b:	e8 2e 09 00 00       	call   c0101ebe <pic_enable>
}
c0101590:	90                   	nop
c0101591:	c9                   	leave  
c0101592:	c3                   	ret    

c0101593 <__intr_save>:
#include <x86.h>
#include <intr.h>
#include <mmu.h>

static inline bool
__intr_save(void) {
c0101593:	55                   	push   %ebp
c0101594:	89 e5                	mov    %esp,%ebp
c0101596:	83 ec 18             	sub    $0x18,%esp
}

static inline uint32_t
read_eflags(void) {
    uint32_t eflags;
    asm volatile ("pushfl; popl %0" : "=r" (eflags));
c0101599:	9c                   	pushf  
c010159a:	58                   	pop    %eax
c010159b:	89 45 f4             	mov    %eax,-0xc(%ebp)
    return eflags;
c010159e:	8b 45 f4             	mov    -0xc(%ebp),%eax
    //x86.h
    if (read_eflags() & FL_IF) {//读操作出现中断
c01015a1:	25 00 02 00 00       	and    $0x200,%eax
c01015a6:	85 c0                	test   %eax,%eax
c01015a8:	74 0c                	je     c01015b6 <__intr_save+0x23>
        intr_disable();//intr.c12->禁用irq中断
c01015aa:	e8 83 0a 00 00       	call   c0102032 <intr_disable>
        return 1;
c01015af:	b8 01 00 00 00       	mov    $0x1,%eax
c01015b4:	eb 05                	jmp    c01015bb <__intr_save+0x28>
    }
    return 0;
c01015b6:	b8 00 00 00 00       	mov    $0x0,%eax
}
c01015bb:	c9                   	leave  
c01015bc:	c3                   	ret    

c01015bd <__intr_restore>:

static inline void
__intr_restore(bool flag) {
c01015bd:	55                   	push   %ebp
c01015be:	89 e5                	mov    %esp,%ebp
c01015c0:	83 ec 08             	sub    $0x8,%esp
    if (flag) {
c01015c3:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
c01015c7:	74 05                	je     c01015ce <__intr_restore+0x11>
        intr_enable();
c01015c9:	e8 5d 0a 00 00       	call   c010202b <intr_enable>
    }
}
c01015ce:	90                   	nop
c01015cf:	c9                   	leave  
c01015d0:	c3                   	ret    

c01015d1 <delay>:
#include <memlayout.h>
#include <sync.h>

/* stupid I/O delay routine necessitated by historical PC design flaws */
static void
delay(void) {
c01015d1:	55                   	push   %ebp
c01015d2:	89 e5                	mov    %esp,%ebp
c01015d4:	83 ec 10             	sub    $0x10,%esp
c01015d7:	66 c7 45 f2 84 00    	movw   $0x84,-0xe(%ebp)
    asm volatile ("inb %1, %0" : "=a" (data) : "d" (port) : "memory");
c01015dd:	0f b7 45 f2          	movzwl -0xe(%ebp),%eax
c01015e1:	89 c2                	mov    %eax,%edx
c01015e3:	ec                   	in     (%dx),%al
c01015e4:	88 45 f1             	mov    %al,-0xf(%ebp)
c01015e7:	66 c7 45 f6 84 00    	movw   $0x84,-0xa(%ebp)
c01015ed:	0f b7 45 f6          	movzwl -0xa(%ebp),%eax
c01015f1:	89 c2                	mov    %eax,%edx
c01015f3:	ec                   	in     (%dx),%al
c01015f4:	88 45 f5             	mov    %al,-0xb(%ebp)
c01015f7:	66 c7 45 fa 84 00    	movw   $0x84,-0x6(%ebp)
c01015fd:	0f b7 45 fa          	movzwl -0x6(%ebp),%eax
c0101601:	89 c2                	mov    %eax,%edx
c0101603:	ec                   	in     (%dx),%al
c0101604:	88 45 f9             	mov    %al,-0x7(%ebp)
c0101607:	66 c7 45 fe 84 00    	movw   $0x84,-0x2(%ebp)
c010160d:	0f b7 45 fe          	movzwl -0x2(%ebp),%eax
c0101611:	89 c2                	mov    %eax,%edx
c0101613:	ec                   	in     (%dx),%al
c0101614:	88 45 fd             	mov    %al,-0x3(%ebp)
    inb(0x84);
    inb(0x84);
    inb(0x84);
    inb(0x84);
}
c0101617:	90                   	nop
c0101618:	c9                   	leave  
c0101619:	c3                   	ret    

c010161a <cga_init>:
static uint16_t addr_6845;

/* TEXT-mode CGA/VGA display output */

static void
cga_init(void) {
c010161a:	55                   	push   %ebp
c010161b:	89 e5                	mov    %esp,%ebp
c010161d:	83 ec 20             	sub    $0x20,%esp
    volatile uint16_t *cp = (uint16_t *)(CGA_BUF + KERNBASE);
c0101620:	c7 45 fc 00 80 0b c0 	movl   $0xc00b8000,-0x4(%ebp)
    uint16_t was = *cp;
c0101627:	8b 45 fc             	mov    -0x4(%ebp),%eax
c010162a:	0f b7 00             	movzwl (%eax),%eax
c010162d:	66 89 45 fa          	mov    %ax,-0x6(%ebp)
    *cp = (uint16_t) 0xA55A;
c0101631:	8b 45 fc             	mov    -0x4(%ebp),%eax
c0101634:	66 c7 00 5a a5       	movw   $0xa55a,(%eax)
    if (*cp != 0xA55A) {
c0101639:	8b 45 fc             	mov    -0x4(%ebp),%eax
c010163c:	0f b7 00             	movzwl (%eax),%eax
c010163f:	0f b7 c0             	movzwl %ax,%eax
c0101642:	3d 5a a5 00 00       	cmp    $0xa55a,%eax
c0101647:	74 12                	je     c010165b <cga_init+0x41>
        cp = (uint16_t*)(MONO_BUF + KERNBASE);
c0101649:	c7 45 fc 00 00 0b c0 	movl   $0xc00b0000,-0x4(%ebp)
        addr_6845 = MONO_BASE;
c0101650:	66 c7 05 26 85 12 c0 	movw   $0x3b4,0xc0128526
c0101657:	b4 03 
c0101659:	eb 13                	jmp    c010166e <cga_init+0x54>
    } else {
        *cp = was;
c010165b:	8b 45 fc             	mov    -0x4(%ebp),%eax
c010165e:	0f b7 55 fa          	movzwl -0x6(%ebp),%edx
c0101662:	66 89 10             	mov    %dx,(%eax)
        addr_6845 = CGA_BASE;
c0101665:	66 c7 05 26 85 12 c0 	movw   $0x3d4,0xc0128526
c010166c:	d4 03 
    }

    // Extract cursor location
    uint32_t pos;
    outb(addr_6845, 14);
c010166e:	0f b7 05 26 85 12 c0 	movzwl 0xc0128526,%eax
c0101675:	66 89 45 e6          	mov    %ax,-0x1a(%ebp)
c0101679:	c6 45 e5 0e          	movb   $0xe,-0x1b(%ebp)
    asm volatile ("outb %0, %1" :: "a" (data), "d" (port) : "memory");
c010167d:	0f b6 45 e5          	movzbl -0x1b(%ebp),%eax
c0101681:	0f b7 55 e6          	movzwl -0x1a(%ebp),%edx
c0101685:	ee                   	out    %al,(%dx)
    pos = inb(addr_6845 + 1) << 8;
c0101686:	0f b7 05 26 85 12 c0 	movzwl 0xc0128526,%eax
c010168d:	40                   	inc    %eax
c010168e:	0f b7 c0             	movzwl %ax,%eax
c0101691:	66 89 45 ea          	mov    %ax,-0x16(%ebp)
    asm volatile ("inb %1, %0" : "=a" (data) : "d" (port) : "memory");
c0101695:	0f b7 45 ea          	movzwl -0x16(%ebp),%eax
c0101699:	89 c2                	mov    %eax,%edx
c010169b:	ec                   	in     (%dx),%al
c010169c:	88 45 e9             	mov    %al,-0x17(%ebp)
    return data;
c010169f:	0f b6 45 e9          	movzbl -0x17(%ebp),%eax
c01016a3:	0f b6 c0             	movzbl %al,%eax
c01016a6:	c1 e0 08             	shl    $0x8,%eax
c01016a9:	89 45 f4             	mov    %eax,-0xc(%ebp)
    outb(addr_6845, 15);
c01016ac:	0f b7 05 26 85 12 c0 	movzwl 0xc0128526,%eax
c01016b3:	66 89 45 ee          	mov    %ax,-0x12(%ebp)
c01016b7:	c6 45 ed 0f          	movb   $0xf,-0x13(%ebp)
    asm volatile ("outb %0, %1" :: "a" (data), "d" (port) : "memory");
c01016bb:	0f b6 45 ed          	movzbl -0x13(%ebp),%eax
c01016bf:	0f b7 55 ee          	movzwl -0x12(%ebp),%edx
c01016c3:	ee                   	out    %al,(%dx)
    pos |= inb(addr_6845 + 1);
c01016c4:	0f b7 05 26 85 12 c0 	movzwl 0xc0128526,%eax
c01016cb:	40                   	inc    %eax
c01016cc:	0f b7 c0             	movzwl %ax,%eax
c01016cf:	66 89 45 f2          	mov    %ax,-0xe(%ebp)
    asm volatile ("inb %1, %0" : "=a" (data) : "d" (port) : "memory");
c01016d3:	0f b7 45 f2          	movzwl -0xe(%ebp),%eax
c01016d7:	89 c2                	mov    %eax,%edx
c01016d9:	ec                   	in     (%dx),%al
c01016da:	88 45 f1             	mov    %al,-0xf(%ebp)
    return data;
c01016dd:	0f b6 45 f1          	movzbl -0xf(%ebp),%eax
c01016e1:	0f b6 c0             	movzbl %al,%eax
c01016e4:	09 45 f4             	or     %eax,-0xc(%ebp)

    crt_buf = (uint16_t*) cp;
c01016e7:	8b 45 fc             	mov    -0x4(%ebp),%eax
c01016ea:	a3 20 85 12 c0       	mov    %eax,0xc0128520
    crt_pos = pos;
c01016ef:	8b 45 f4             	mov    -0xc(%ebp),%eax
c01016f2:	0f b7 c0             	movzwl %ax,%eax
c01016f5:	66 a3 24 85 12 c0    	mov    %ax,0xc0128524
}
c01016fb:	90                   	nop
c01016fc:	c9                   	leave  
c01016fd:	c3                   	ret    

c01016fe <serial_init>:

static bool serial_exists = 0;

static void
serial_init(void) {
c01016fe:	55                   	push   %ebp
c01016ff:	89 e5                	mov    %esp,%ebp
c0101701:	83 ec 48             	sub    $0x48,%esp
c0101704:	66 c7 45 d2 fa 03    	movw   $0x3fa,-0x2e(%ebp)
c010170a:	c6 45 d1 00          	movb   $0x0,-0x2f(%ebp)
    asm volatile ("outb %0, %1" :: "a" (data), "d" (port) : "memory");
c010170e:	0f b6 45 d1          	movzbl -0x2f(%ebp),%eax
c0101712:	0f b7 55 d2          	movzwl -0x2e(%ebp),%edx
c0101716:	ee                   	out    %al,(%dx)
c0101717:	66 c7 45 d6 fb 03    	movw   $0x3fb,-0x2a(%ebp)
c010171d:	c6 45 d5 80          	movb   $0x80,-0x2b(%ebp)
c0101721:	0f b6 45 d5          	movzbl -0x2b(%ebp),%eax
c0101725:	0f b7 55 d6          	movzwl -0x2a(%ebp),%edx
c0101729:	ee                   	out    %al,(%dx)
c010172a:	66 c7 45 da f8 03    	movw   $0x3f8,-0x26(%ebp)
c0101730:	c6 45 d9 0c          	movb   $0xc,-0x27(%ebp)
c0101734:	0f b6 45 d9          	movzbl -0x27(%ebp),%eax
c0101738:	0f b7 55 da          	movzwl -0x26(%ebp),%edx
c010173c:	ee                   	out    %al,(%dx)
c010173d:	66 c7 45 de f9 03    	movw   $0x3f9,-0x22(%ebp)
c0101743:	c6 45 dd 00          	movb   $0x0,-0x23(%ebp)
c0101747:	0f b6 45 dd          	movzbl -0x23(%ebp),%eax
c010174b:	0f b7 55 de          	movzwl -0x22(%ebp),%edx
c010174f:	ee                   	out    %al,(%dx)
c0101750:	66 c7 45 e2 fb 03    	movw   $0x3fb,-0x1e(%ebp)
c0101756:	c6 45 e1 03          	movb   $0x3,-0x1f(%ebp)
c010175a:	0f b6 45 e1          	movzbl -0x1f(%ebp),%eax
c010175e:	0f b7 55 e2          	movzwl -0x1e(%ebp),%edx
c0101762:	ee                   	out    %al,(%dx)
c0101763:	66 c7 45 e6 fc 03    	movw   $0x3fc,-0x1a(%ebp)
c0101769:	c6 45 e5 00          	movb   $0x0,-0x1b(%ebp)
c010176d:	0f b6 45 e5          	movzbl -0x1b(%ebp),%eax
c0101771:	0f b7 55 e6          	movzwl -0x1a(%ebp),%edx
c0101775:	ee                   	out    %al,(%dx)
c0101776:	66 c7 45 ea f9 03    	movw   $0x3f9,-0x16(%ebp)
c010177c:	c6 45 e9 01          	movb   $0x1,-0x17(%ebp)
c0101780:	0f b6 45 e9          	movzbl -0x17(%ebp),%eax
c0101784:	0f b7 55 ea          	movzwl -0x16(%ebp),%edx
c0101788:	ee                   	out    %al,(%dx)
c0101789:	66 c7 45 ee fd 03    	movw   $0x3fd,-0x12(%ebp)
    asm volatile ("inb %1, %0" : "=a" (data) : "d" (port) : "memory");
c010178f:	0f b7 45 ee          	movzwl -0x12(%ebp),%eax
c0101793:	89 c2                	mov    %eax,%edx
c0101795:	ec                   	in     (%dx),%al
c0101796:	88 45 ed             	mov    %al,-0x13(%ebp)
    return data;
c0101799:	0f b6 45 ed          	movzbl -0x13(%ebp),%eax
    // Enable rcv interrupts
    outb(COM1 + COM_IER, COM_IER_RDI);

    // Clear any preexisting overrun indications and interrupts
    // Serial port doesn't exist if COM_LSR returns 0xFF
    serial_exists = (inb(COM1 + COM_LSR) != 0xFF);
c010179d:	3c ff                	cmp    $0xff,%al
c010179f:	0f 95 c0             	setne  %al
c01017a2:	0f b6 c0             	movzbl %al,%eax
c01017a5:	a3 28 85 12 c0       	mov    %eax,0xc0128528
c01017aa:	66 c7 45 f2 fa 03    	movw   $0x3fa,-0xe(%ebp)
    asm volatile ("inb %1, %0" : "=a" (data) : "d" (port) : "memory");
c01017b0:	0f b7 45 f2          	movzwl -0xe(%ebp),%eax
c01017b4:	89 c2                	mov    %eax,%edx
c01017b6:	ec                   	in     (%dx),%al
c01017b7:	88 45 f1             	mov    %al,-0xf(%ebp)
c01017ba:	66 c7 45 f6 f8 03    	movw   $0x3f8,-0xa(%ebp)
c01017c0:	0f b7 45 f6          	movzwl -0xa(%ebp),%eax
c01017c4:	89 c2                	mov    %eax,%edx
c01017c6:	ec                   	in     (%dx),%al
c01017c7:	88 45 f5             	mov    %al,-0xb(%ebp)
    (void) inb(COM1+COM_IIR);
    (void) inb(COM1+COM_RX);

    if (serial_exists) {
c01017ca:	a1 28 85 12 c0       	mov    0xc0128528,%eax
c01017cf:	85 c0                	test   %eax,%eax
c01017d1:	74 0c                	je     c01017df <serial_init+0xe1>
        pic_enable(IRQ_COM1);
c01017d3:	c7 04 24 04 00 00 00 	movl   $0x4,(%esp)
c01017da:	e8 df 06 00 00       	call   c0101ebe <pic_enable>
    }
}
c01017df:	90                   	nop
c01017e0:	c9                   	leave  
c01017e1:	c3                   	ret    

c01017e2 <lpt_putc_sub>:

static void
lpt_putc_sub(int c) {
c01017e2:	55                   	push   %ebp
c01017e3:	89 e5                	mov    %esp,%ebp
c01017e5:	83 ec 20             	sub    $0x20,%esp
    int i;
    for (i = 0; !(inb(LPTPORT + 1) & 0x80) && i < 12800; i ++) {
c01017e8:	c7 45 fc 00 00 00 00 	movl   $0x0,-0x4(%ebp)
c01017ef:	eb 08                	jmp    c01017f9 <lpt_putc_sub+0x17>
        delay();
c01017f1:	e8 db fd ff ff       	call   c01015d1 <delay>
    for (i = 0; !(inb(LPTPORT + 1) & 0x80) && i < 12800; i ++) {
c01017f6:	ff 45 fc             	incl   -0x4(%ebp)
c01017f9:	66 c7 45 fa 79 03    	movw   $0x379,-0x6(%ebp)
c01017ff:	0f b7 45 fa          	movzwl -0x6(%ebp),%eax
c0101803:	89 c2                	mov    %eax,%edx
c0101805:	ec                   	in     (%dx),%al
c0101806:	88 45 f9             	mov    %al,-0x7(%ebp)
    return data;
c0101809:	0f b6 45 f9          	movzbl -0x7(%ebp),%eax
c010180d:	84 c0                	test   %al,%al
c010180f:	78 09                	js     c010181a <lpt_putc_sub+0x38>
c0101811:	81 7d fc ff 31 00 00 	cmpl   $0x31ff,-0x4(%ebp)
c0101818:	7e d7                	jle    c01017f1 <lpt_putc_sub+0xf>
    }
    outb(LPTPORT + 0, c);
c010181a:	8b 45 08             	mov    0x8(%ebp),%eax
c010181d:	0f b6 c0             	movzbl %al,%eax
c0101820:	66 c7 45 ee 78 03    	movw   $0x378,-0x12(%ebp)
c0101826:	88 45 ed             	mov    %al,-0x13(%ebp)
    asm volatile ("outb %0, %1" :: "a" (data), "d" (port) : "memory");
c0101829:	0f b6 45 ed          	movzbl -0x13(%ebp),%eax
c010182d:	0f b7 55 ee          	movzwl -0x12(%ebp),%edx
c0101831:	ee                   	out    %al,(%dx)
c0101832:	66 c7 45 f2 7a 03    	movw   $0x37a,-0xe(%ebp)
c0101838:	c6 45 f1 0d          	movb   $0xd,-0xf(%ebp)
c010183c:	0f b6 45 f1          	movzbl -0xf(%ebp),%eax
c0101840:	0f b7 55 f2          	movzwl -0xe(%ebp),%edx
c0101844:	ee                   	out    %al,(%dx)
c0101845:	66 c7 45 f6 7a 03    	movw   $0x37a,-0xa(%ebp)
c010184b:	c6 45 f5 08          	movb   $0x8,-0xb(%ebp)
c010184f:	0f b6 45 f5          	movzbl -0xb(%ebp),%eax
c0101853:	0f b7 55 f6          	movzwl -0xa(%ebp),%edx
c0101857:	ee                   	out    %al,(%dx)
    outb(LPTPORT + 2, 0x08 | 0x04 | 0x01);
    outb(LPTPORT + 2, 0x08);
}
c0101858:	90                   	nop
c0101859:	c9                   	leave  
c010185a:	c3                   	ret    

c010185b <lpt_putc>:

/* lpt_putc - copy console output to parallel port */
static void
lpt_putc(int c) {
c010185b:	55                   	push   %ebp
c010185c:	89 e5                	mov    %esp,%ebp
c010185e:	83 ec 04             	sub    $0x4,%esp
    if (c != '\b') {
c0101861:	83 7d 08 08          	cmpl   $0x8,0x8(%ebp)
c0101865:	74 0d                	je     c0101874 <lpt_putc+0x19>
        lpt_putc_sub(c);
c0101867:	8b 45 08             	mov    0x8(%ebp),%eax
c010186a:	89 04 24             	mov    %eax,(%esp)
c010186d:	e8 70 ff ff ff       	call   c01017e2 <lpt_putc_sub>
    else {
        lpt_putc_sub('\b');
        lpt_putc_sub(' ');
        lpt_putc_sub('\b');
    }
}
c0101872:	eb 24                	jmp    c0101898 <lpt_putc+0x3d>
        lpt_putc_sub('\b');
c0101874:	c7 04 24 08 00 00 00 	movl   $0x8,(%esp)
c010187b:	e8 62 ff ff ff       	call   c01017e2 <lpt_putc_sub>
        lpt_putc_sub(' ');
c0101880:	c7 04 24 20 00 00 00 	movl   $0x20,(%esp)
c0101887:	e8 56 ff ff ff       	call   c01017e2 <lpt_putc_sub>
        lpt_putc_sub('\b');
c010188c:	c7 04 24 08 00 00 00 	movl   $0x8,(%esp)
c0101893:	e8 4a ff ff ff       	call   c01017e2 <lpt_putc_sub>
}
c0101898:	90                   	nop
c0101899:	c9                   	leave  
c010189a:	c3                   	ret    

c010189b <cga_putc>:

/* cga_putc - print character to console */
static void
cga_putc(int c) {
c010189b:	55                   	push   %ebp
c010189c:	89 e5                	mov    %esp,%ebp
c010189e:	53                   	push   %ebx
c010189f:	83 ec 34             	sub    $0x34,%esp
    // set black on white
    if (!(c & ~0xFF)) {
c01018a2:	8b 45 08             	mov    0x8(%ebp),%eax
c01018a5:	25 00 ff ff ff       	and    $0xffffff00,%eax
c01018aa:	85 c0                	test   %eax,%eax
c01018ac:	75 07                	jne    c01018b5 <cga_putc+0x1a>
        c |= 0x0700;
c01018ae:	81 4d 08 00 07 00 00 	orl    $0x700,0x8(%ebp)
    }

    switch (c & 0xff) {
c01018b5:	8b 45 08             	mov    0x8(%ebp),%eax
c01018b8:	0f b6 c0             	movzbl %al,%eax
c01018bb:	83 f8 0a             	cmp    $0xa,%eax
c01018be:	74 55                	je     c0101915 <cga_putc+0x7a>
c01018c0:	83 f8 0d             	cmp    $0xd,%eax
c01018c3:	74 63                	je     c0101928 <cga_putc+0x8d>
c01018c5:	83 f8 08             	cmp    $0x8,%eax
c01018c8:	0f 85 94 00 00 00    	jne    c0101962 <cga_putc+0xc7>
    case '\b':
        if (crt_pos > 0) {
c01018ce:	0f b7 05 24 85 12 c0 	movzwl 0xc0128524,%eax
c01018d5:	85 c0                	test   %eax,%eax
c01018d7:	0f 84 af 00 00 00    	je     c010198c <cga_putc+0xf1>
            crt_pos --;
c01018dd:	0f b7 05 24 85 12 c0 	movzwl 0xc0128524,%eax
c01018e4:	48                   	dec    %eax
c01018e5:	0f b7 c0             	movzwl %ax,%eax
c01018e8:	66 a3 24 85 12 c0    	mov    %ax,0xc0128524
            crt_buf[crt_pos] = (c & ~0xff) | ' ';
c01018ee:	8b 45 08             	mov    0x8(%ebp),%eax
c01018f1:	98                   	cwtl   
c01018f2:	25 00 ff ff ff       	and    $0xffffff00,%eax
c01018f7:	98                   	cwtl   
c01018f8:	83 c8 20             	or     $0x20,%eax
c01018fb:	98                   	cwtl   
c01018fc:	8b 15 20 85 12 c0    	mov    0xc0128520,%edx
c0101902:	0f b7 0d 24 85 12 c0 	movzwl 0xc0128524,%ecx
c0101909:	01 c9                	add    %ecx,%ecx
c010190b:	01 ca                	add    %ecx,%edx
c010190d:	0f b7 c0             	movzwl %ax,%eax
c0101910:	66 89 02             	mov    %ax,(%edx)
        }
        break;
c0101913:	eb 77                	jmp    c010198c <cga_putc+0xf1>
    case '\n':
        crt_pos += CRT_COLS;
c0101915:	0f b7 05 24 85 12 c0 	movzwl 0xc0128524,%eax
c010191c:	83 c0 50             	add    $0x50,%eax
c010191f:	0f b7 c0             	movzwl %ax,%eax
c0101922:	66 a3 24 85 12 c0    	mov    %ax,0xc0128524
    case '\r':
        crt_pos -= (crt_pos % CRT_COLS);
c0101928:	0f b7 1d 24 85 12 c0 	movzwl 0xc0128524,%ebx
c010192f:	0f b7 0d 24 85 12 c0 	movzwl 0xc0128524,%ecx
c0101936:	ba cd cc cc cc       	mov    $0xcccccccd,%edx
c010193b:	89 c8                	mov    %ecx,%eax
c010193d:	f7 e2                	mul    %edx
c010193f:	c1 ea 06             	shr    $0x6,%edx
c0101942:	89 d0                	mov    %edx,%eax
c0101944:	c1 e0 02             	shl    $0x2,%eax
c0101947:	01 d0                	add    %edx,%eax
c0101949:	c1 e0 04             	shl    $0x4,%eax
c010194c:	29 c1                	sub    %eax,%ecx
c010194e:	89 c8                	mov    %ecx,%eax
c0101950:	0f b7 c0             	movzwl %ax,%eax
c0101953:	29 c3                	sub    %eax,%ebx
c0101955:	89 d8                	mov    %ebx,%eax
c0101957:	0f b7 c0             	movzwl %ax,%eax
c010195a:	66 a3 24 85 12 c0    	mov    %ax,0xc0128524
        break;
c0101960:	eb 2b                	jmp    c010198d <cga_putc+0xf2>
    default:
        crt_buf[crt_pos ++] = c;     // write the character
c0101962:	8b 0d 20 85 12 c0    	mov    0xc0128520,%ecx
c0101968:	0f b7 05 24 85 12 c0 	movzwl 0xc0128524,%eax
c010196f:	8d 50 01             	lea    0x1(%eax),%edx
c0101972:	0f b7 d2             	movzwl %dx,%edx
c0101975:	66 89 15 24 85 12 c0 	mov    %dx,0xc0128524
c010197c:	01 c0                	add    %eax,%eax
c010197e:	8d 14 01             	lea    (%ecx,%eax,1),%edx
c0101981:	8b 45 08             	mov    0x8(%ebp),%eax
c0101984:	0f b7 c0             	movzwl %ax,%eax
c0101987:	66 89 02             	mov    %ax,(%edx)
        break;
c010198a:	eb 01                	jmp    c010198d <cga_putc+0xf2>
        break;
c010198c:	90                   	nop
    }

    // What is the purpose of this?
    if (crt_pos >= CRT_SIZE) {
c010198d:	0f b7 05 24 85 12 c0 	movzwl 0xc0128524,%eax
c0101994:	3d cf 07 00 00       	cmp    $0x7cf,%eax
c0101999:	76 5d                	jbe    c01019f8 <cga_putc+0x15d>
        int i;
        memmove(crt_buf, crt_buf + CRT_COLS, (CRT_SIZE - CRT_COLS) * sizeof(uint16_t));
c010199b:	a1 20 85 12 c0       	mov    0xc0128520,%eax
c01019a0:	8d 90 a0 00 00 00    	lea    0xa0(%eax),%edx
c01019a6:	a1 20 85 12 c0       	mov    0xc0128520,%eax
c01019ab:	c7 44 24 08 00 0f 00 	movl   $0xf00,0x8(%esp)
c01019b2:	00 
c01019b3:	89 54 24 04          	mov    %edx,0x4(%esp)
c01019b7:	89 04 24             	mov    %eax,(%esp)
c01019ba:	e8 24 7b 00 00       	call   c01094e3 <memmove>
        for (i = CRT_SIZE - CRT_COLS; i < CRT_SIZE; i ++) {
c01019bf:	c7 45 f4 80 07 00 00 	movl   $0x780,-0xc(%ebp)
c01019c6:	eb 14                	jmp    c01019dc <cga_putc+0x141>
            crt_buf[i] = 0x0700 | ' ';
c01019c8:	a1 20 85 12 c0       	mov    0xc0128520,%eax
c01019cd:	8b 55 f4             	mov    -0xc(%ebp),%edx
c01019d0:	01 d2                	add    %edx,%edx
c01019d2:	01 d0                	add    %edx,%eax
c01019d4:	66 c7 00 20 07       	movw   $0x720,(%eax)
        for (i = CRT_SIZE - CRT_COLS; i < CRT_SIZE; i ++) {
c01019d9:	ff 45 f4             	incl   -0xc(%ebp)
c01019dc:	81 7d f4 cf 07 00 00 	cmpl   $0x7cf,-0xc(%ebp)
c01019e3:	7e e3                	jle    c01019c8 <cga_putc+0x12d>
        }
        crt_pos -= CRT_COLS;
c01019e5:	0f b7 05 24 85 12 c0 	movzwl 0xc0128524,%eax
c01019ec:	83 e8 50             	sub    $0x50,%eax
c01019ef:	0f b7 c0             	movzwl %ax,%eax
c01019f2:	66 a3 24 85 12 c0    	mov    %ax,0xc0128524
    }

    // move that little blinky thing
    outb(addr_6845, 14);
c01019f8:	0f b7 05 26 85 12 c0 	movzwl 0xc0128526,%eax
c01019ff:	66 89 45 e6          	mov    %ax,-0x1a(%ebp)
c0101a03:	c6 45 e5 0e          	movb   $0xe,-0x1b(%ebp)
c0101a07:	0f b6 45 e5          	movzbl -0x1b(%ebp),%eax
c0101a0b:	0f b7 55 e6          	movzwl -0x1a(%ebp),%edx
c0101a0f:	ee                   	out    %al,(%dx)
    outb(addr_6845 + 1, crt_pos >> 8);
c0101a10:	0f b7 05 24 85 12 c0 	movzwl 0xc0128524,%eax
c0101a17:	c1 e8 08             	shr    $0x8,%eax
c0101a1a:	0f b7 c0             	movzwl %ax,%eax
c0101a1d:	0f b6 c0             	movzbl %al,%eax
c0101a20:	0f b7 15 26 85 12 c0 	movzwl 0xc0128526,%edx
c0101a27:	42                   	inc    %edx
c0101a28:	0f b7 d2             	movzwl %dx,%edx
c0101a2b:	66 89 55 ea          	mov    %dx,-0x16(%ebp)
c0101a2f:	88 45 e9             	mov    %al,-0x17(%ebp)
c0101a32:	0f b6 45 e9          	movzbl -0x17(%ebp),%eax
c0101a36:	0f b7 55 ea          	movzwl -0x16(%ebp),%edx
c0101a3a:	ee                   	out    %al,(%dx)
    outb(addr_6845, 15);
c0101a3b:	0f b7 05 26 85 12 c0 	movzwl 0xc0128526,%eax
c0101a42:	66 89 45 ee          	mov    %ax,-0x12(%ebp)
c0101a46:	c6 45 ed 0f          	movb   $0xf,-0x13(%ebp)
c0101a4a:	0f b6 45 ed          	movzbl -0x13(%ebp),%eax
c0101a4e:	0f b7 55 ee          	movzwl -0x12(%ebp),%edx
c0101a52:	ee                   	out    %al,(%dx)
    outb(addr_6845 + 1, crt_pos);
c0101a53:	0f b7 05 24 85 12 c0 	movzwl 0xc0128524,%eax
c0101a5a:	0f b6 c0             	movzbl %al,%eax
c0101a5d:	0f b7 15 26 85 12 c0 	movzwl 0xc0128526,%edx
c0101a64:	42                   	inc    %edx
c0101a65:	0f b7 d2             	movzwl %dx,%edx
c0101a68:	66 89 55 f2          	mov    %dx,-0xe(%ebp)
c0101a6c:	88 45 f1             	mov    %al,-0xf(%ebp)
c0101a6f:	0f b6 45 f1          	movzbl -0xf(%ebp),%eax
c0101a73:	0f b7 55 f2          	movzwl -0xe(%ebp),%edx
c0101a77:	ee                   	out    %al,(%dx)
}
c0101a78:	90                   	nop
c0101a79:	83 c4 34             	add    $0x34,%esp
c0101a7c:	5b                   	pop    %ebx
c0101a7d:	5d                   	pop    %ebp
c0101a7e:	c3                   	ret    

c0101a7f <serial_putc_sub>:

static void
serial_putc_sub(int c) {
c0101a7f:	55                   	push   %ebp
c0101a80:	89 e5                	mov    %esp,%ebp
c0101a82:	83 ec 10             	sub    $0x10,%esp
    int i;
    for (i = 0; !(inb(COM1 + COM_LSR) & COM_LSR_TXRDY) && i < 12800; i ++) {
c0101a85:	c7 45 fc 00 00 00 00 	movl   $0x0,-0x4(%ebp)
c0101a8c:	eb 08                	jmp    c0101a96 <serial_putc_sub+0x17>
        delay();
c0101a8e:	e8 3e fb ff ff       	call   c01015d1 <delay>
    for (i = 0; !(inb(COM1 + COM_LSR) & COM_LSR_TXRDY) && i < 12800; i ++) {
c0101a93:	ff 45 fc             	incl   -0x4(%ebp)
c0101a96:	66 c7 45 fa fd 03    	movw   $0x3fd,-0x6(%ebp)
    asm volatile ("inb %1, %0" : "=a" (data) : "d" (port) : "memory");
c0101a9c:	0f b7 45 fa          	movzwl -0x6(%ebp),%eax
c0101aa0:	89 c2                	mov    %eax,%edx
c0101aa2:	ec                   	in     (%dx),%al
c0101aa3:	88 45 f9             	mov    %al,-0x7(%ebp)
    return data;
c0101aa6:	0f b6 45 f9          	movzbl -0x7(%ebp),%eax
c0101aaa:	0f b6 c0             	movzbl %al,%eax
c0101aad:	83 e0 20             	and    $0x20,%eax
c0101ab0:	85 c0                	test   %eax,%eax
c0101ab2:	75 09                	jne    c0101abd <serial_putc_sub+0x3e>
c0101ab4:	81 7d fc ff 31 00 00 	cmpl   $0x31ff,-0x4(%ebp)
c0101abb:	7e d1                	jle    c0101a8e <serial_putc_sub+0xf>
    }
    outb(COM1 + COM_TX, c);
c0101abd:	8b 45 08             	mov    0x8(%ebp),%eax
c0101ac0:	0f b6 c0             	movzbl %al,%eax
c0101ac3:	66 c7 45 f6 f8 03    	movw   $0x3f8,-0xa(%ebp)
c0101ac9:	88 45 f5             	mov    %al,-0xb(%ebp)
    asm volatile ("outb %0, %1" :: "a" (data), "d" (port) : "memory");
c0101acc:	0f b6 45 f5          	movzbl -0xb(%ebp),%eax
c0101ad0:	0f b7 55 f6          	movzwl -0xa(%ebp),%edx
c0101ad4:	ee                   	out    %al,(%dx)
}
c0101ad5:	90                   	nop
c0101ad6:	c9                   	leave  
c0101ad7:	c3                   	ret    

c0101ad8 <serial_putc>:

/* serial_putc - print character to serial port */
static void
serial_putc(int c) {
c0101ad8:	55                   	push   %ebp
c0101ad9:	89 e5                	mov    %esp,%ebp
c0101adb:	83 ec 04             	sub    $0x4,%esp
    if (c != '\b') {
c0101ade:	83 7d 08 08          	cmpl   $0x8,0x8(%ebp)
c0101ae2:	74 0d                	je     c0101af1 <serial_putc+0x19>
        serial_putc_sub(c);
c0101ae4:	8b 45 08             	mov    0x8(%ebp),%eax
c0101ae7:	89 04 24             	mov    %eax,(%esp)
c0101aea:	e8 90 ff ff ff       	call   c0101a7f <serial_putc_sub>
    else {
        serial_putc_sub('\b');
        serial_putc_sub(' ');
        serial_putc_sub('\b');
    }
}
c0101aef:	eb 24                	jmp    c0101b15 <serial_putc+0x3d>
        serial_putc_sub('\b');
c0101af1:	c7 04 24 08 00 00 00 	movl   $0x8,(%esp)
c0101af8:	e8 82 ff ff ff       	call   c0101a7f <serial_putc_sub>
        serial_putc_sub(' ');
c0101afd:	c7 04 24 20 00 00 00 	movl   $0x20,(%esp)
c0101b04:	e8 76 ff ff ff       	call   c0101a7f <serial_putc_sub>
        serial_putc_sub('\b');
c0101b09:	c7 04 24 08 00 00 00 	movl   $0x8,(%esp)
c0101b10:	e8 6a ff ff ff       	call   c0101a7f <serial_putc_sub>
}
c0101b15:	90                   	nop
c0101b16:	c9                   	leave  
c0101b17:	c3                   	ret    

c0101b18 <cons_intr>:
/* *
 * cons_intr - called by device interrupt routines to feed input
 * characters into the circular console input buffer.
 * */
static void
cons_intr(int (*proc)(void)) {
c0101b18:	55                   	push   %ebp
c0101b19:	89 e5                	mov    %esp,%ebp
c0101b1b:	83 ec 18             	sub    $0x18,%esp
    int c;
    while ((c = (*proc)()) != -1) {
c0101b1e:	eb 33                	jmp    c0101b53 <cons_intr+0x3b>
        if (c != 0) {
c0101b20:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
c0101b24:	74 2d                	je     c0101b53 <cons_intr+0x3b>
            cons.buf[cons.wpos ++] = c;
c0101b26:	a1 44 87 12 c0       	mov    0xc0128744,%eax
c0101b2b:	8d 50 01             	lea    0x1(%eax),%edx
c0101b2e:	89 15 44 87 12 c0    	mov    %edx,0xc0128744
c0101b34:	8b 55 f4             	mov    -0xc(%ebp),%edx
c0101b37:	88 90 40 85 12 c0    	mov    %dl,-0x3fed7ac0(%eax)
            if (cons.wpos == CONSBUFSIZE) {
c0101b3d:	a1 44 87 12 c0       	mov    0xc0128744,%eax
c0101b42:	3d 00 02 00 00       	cmp    $0x200,%eax
c0101b47:	75 0a                	jne    c0101b53 <cons_intr+0x3b>
                cons.wpos = 0;
c0101b49:	c7 05 44 87 12 c0 00 	movl   $0x0,0xc0128744
c0101b50:	00 00 00 
    while ((c = (*proc)()) != -1) {
c0101b53:	8b 45 08             	mov    0x8(%ebp),%eax
c0101b56:	ff d0                	call   *%eax
c0101b58:	89 45 f4             	mov    %eax,-0xc(%ebp)
c0101b5b:	83 7d f4 ff          	cmpl   $0xffffffff,-0xc(%ebp)
c0101b5f:	75 bf                	jne    c0101b20 <cons_intr+0x8>
            }
        }
    }
}
c0101b61:	90                   	nop
c0101b62:	c9                   	leave  
c0101b63:	c3                   	ret    

c0101b64 <serial_proc_data>:

/* serial_proc_data - get data from serial port */
static int
serial_proc_data(void) {
c0101b64:	55                   	push   %ebp
c0101b65:	89 e5                	mov    %esp,%ebp
c0101b67:	83 ec 10             	sub    $0x10,%esp
c0101b6a:	66 c7 45 fa fd 03    	movw   $0x3fd,-0x6(%ebp)
    asm volatile ("inb %1, %0" : "=a" (data) : "d" (port) : "memory");
c0101b70:	0f b7 45 fa          	movzwl -0x6(%ebp),%eax
c0101b74:	89 c2                	mov    %eax,%edx
c0101b76:	ec                   	in     (%dx),%al
c0101b77:	88 45 f9             	mov    %al,-0x7(%ebp)
    return data;
c0101b7a:	0f b6 45 f9          	movzbl -0x7(%ebp),%eax
    if (!(inb(COM1 + COM_LSR) & COM_LSR_DATA)) {
c0101b7e:	0f b6 c0             	movzbl %al,%eax
c0101b81:	83 e0 01             	and    $0x1,%eax
c0101b84:	85 c0                	test   %eax,%eax
c0101b86:	75 07                	jne    c0101b8f <serial_proc_data+0x2b>
        return -1;
c0101b88:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
c0101b8d:	eb 2a                	jmp    c0101bb9 <serial_proc_data+0x55>
c0101b8f:	66 c7 45 f6 f8 03    	movw   $0x3f8,-0xa(%ebp)
    asm volatile ("inb %1, %0" : "=a" (data) : "d" (port) : "memory");
c0101b95:	0f b7 45 f6          	movzwl -0xa(%ebp),%eax
c0101b99:	89 c2                	mov    %eax,%edx
c0101b9b:	ec                   	in     (%dx),%al
c0101b9c:	88 45 f5             	mov    %al,-0xb(%ebp)
    return data;
c0101b9f:	0f b6 45 f5          	movzbl -0xb(%ebp),%eax
    }
    int c = inb(COM1 + COM_RX);
c0101ba3:	0f b6 c0             	movzbl %al,%eax
c0101ba6:	89 45 fc             	mov    %eax,-0x4(%ebp)
    if (c == 127) {
c0101ba9:	83 7d fc 7f          	cmpl   $0x7f,-0x4(%ebp)
c0101bad:	75 07                	jne    c0101bb6 <serial_proc_data+0x52>
        c = '\b';
c0101baf:	c7 45 fc 08 00 00 00 	movl   $0x8,-0x4(%ebp)
    }
    return c;
c0101bb6:	8b 45 fc             	mov    -0x4(%ebp),%eax
}
c0101bb9:	c9                   	leave  
c0101bba:	c3                   	ret    

c0101bbb <serial_intr>:

/* serial_intr - try to feed input characters from serial port */
void
serial_intr(void) {
c0101bbb:	55                   	push   %ebp
c0101bbc:	89 e5                	mov    %esp,%ebp
c0101bbe:	83 ec 18             	sub    $0x18,%esp
    if (serial_exists) {
c0101bc1:	a1 28 85 12 c0       	mov    0xc0128528,%eax
c0101bc6:	85 c0                	test   %eax,%eax
c0101bc8:	74 0c                	je     c0101bd6 <serial_intr+0x1b>
        cons_intr(serial_proc_data);
c0101bca:	c7 04 24 64 1b 10 c0 	movl   $0xc0101b64,(%esp)
c0101bd1:	e8 42 ff ff ff       	call   c0101b18 <cons_intr>
    }
}
c0101bd6:	90                   	nop
c0101bd7:	c9                   	leave  
c0101bd8:	c3                   	ret    

c0101bd9 <kbd_proc_data>:
 *
 * The kbd_proc_data() function gets data from the keyboard.
 * If we finish a character, return it, else 0. And return -1 if no data.
 * */
static int
kbd_proc_data(void) {
c0101bd9:	55                   	push   %ebp
c0101bda:	89 e5                	mov    %esp,%ebp
c0101bdc:	83 ec 38             	sub    $0x38,%esp
c0101bdf:	66 c7 45 f0 64 00    	movw   $0x64,-0x10(%ebp)
    asm volatile ("inb %1, %0" : "=a" (data) : "d" (port) : "memory");
c0101be5:	8b 45 f0             	mov    -0x10(%ebp),%eax
c0101be8:	89 c2                	mov    %eax,%edx
c0101bea:	ec                   	in     (%dx),%al
c0101beb:	88 45 ef             	mov    %al,-0x11(%ebp)
    return data;
c0101bee:	0f b6 45 ef          	movzbl -0x11(%ebp),%eax
    int c;
    uint8_t data;
    static uint32_t shift;

    if ((inb(KBSTATP) & KBS_DIB) == 0) {
c0101bf2:	0f b6 c0             	movzbl %al,%eax
c0101bf5:	83 e0 01             	and    $0x1,%eax
c0101bf8:	85 c0                	test   %eax,%eax
c0101bfa:	75 0a                	jne    c0101c06 <kbd_proc_data+0x2d>
        return -1;
c0101bfc:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
c0101c01:	e9 55 01 00 00       	jmp    c0101d5b <kbd_proc_data+0x182>
c0101c06:	66 c7 45 ec 60 00    	movw   $0x60,-0x14(%ebp)
    asm volatile ("inb %1, %0" : "=a" (data) : "d" (port) : "memory");
c0101c0c:	8b 45 ec             	mov    -0x14(%ebp),%eax
c0101c0f:	89 c2                	mov    %eax,%edx
c0101c11:	ec                   	in     (%dx),%al
c0101c12:	88 45 eb             	mov    %al,-0x15(%ebp)
    return data;
c0101c15:	0f b6 45 eb          	movzbl -0x15(%ebp),%eax
    }

    data = inb(KBDATAP);
c0101c19:	88 45 f3             	mov    %al,-0xd(%ebp)

    if (data == 0xE0) {
c0101c1c:	80 7d f3 e0          	cmpb   $0xe0,-0xd(%ebp)
c0101c20:	75 17                	jne    c0101c39 <kbd_proc_data+0x60>
        // E0 escape character
        shift |= E0ESC;
c0101c22:	a1 48 87 12 c0       	mov    0xc0128748,%eax
c0101c27:	83 c8 40             	or     $0x40,%eax
c0101c2a:	a3 48 87 12 c0       	mov    %eax,0xc0128748
        return 0;
c0101c2f:	b8 00 00 00 00       	mov    $0x0,%eax
c0101c34:	e9 22 01 00 00       	jmp    c0101d5b <kbd_proc_data+0x182>
    } else if (data & 0x80) {
c0101c39:	0f b6 45 f3          	movzbl -0xd(%ebp),%eax
c0101c3d:	84 c0                	test   %al,%al
c0101c3f:	79 45                	jns    c0101c86 <kbd_proc_data+0xad>
        // Key released
        data = (shift & E0ESC ? data : data & 0x7F);
c0101c41:	a1 48 87 12 c0       	mov    0xc0128748,%eax
c0101c46:	83 e0 40             	and    $0x40,%eax
c0101c49:	85 c0                	test   %eax,%eax
c0101c4b:	75 08                	jne    c0101c55 <kbd_proc_data+0x7c>
c0101c4d:	0f b6 45 f3          	movzbl -0xd(%ebp),%eax
c0101c51:	24 7f                	and    $0x7f,%al
c0101c53:	eb 04                	jmp    c0101c59 <kbd_proc_data+0x80>
c0101c55:	0f b6 45 f3          	movzbl -0xd(%ebp),%eax
c0101c59:	88 45 f3             	mov    %al,-0xd(%ebp)
        shift &= ~(shiftcode[data] | E0ESC);
c0101c5c:	0f b6 45 f3          	movzbl -0xd(%ebp),%eax
c0101c60:	0f b6 80 40 50 12 c0 	movzbl -0x3fedafc0(%eax),%eax
c0101c67:	0c 40                	or     $0x40,%al
c0101c69:	0f b6 c0             	movzbl %al,%eax
c0101c6c:	f7 d0                	not    %eax
c0101c6e:	89 c2                	mov    %eax,%edx
c0101c70:	a1 48 87 12 c0       	mov    0xc0128748,%eax
c0101c75:	21 d0                	and    %edx,%eax
c0101c77:	a3 48 87 12 c0       	mov    %eax,0xc0128748
        return 0;
c0101c7c:	b8 00 00 00 00       	mov    $0x0,%eax
c0101c81:	e9 d5 00 00 00       	jmp    c0101d5b <kbd_proc_data+0x182>
    } else if (shift & E0ESC) {
c0101c86:	a1 48 87 12 c0       	mov    0xc0128748,%eax
c0101c8b:	83 e0 40             	and    $0x40,%eax
c0101c8e:	85 c0                	test   %eax,%eax
c0101c90:	74 11                	je     c0101ca3 <kbd_proc_data+0xca>
        // Last character was an E0 escape; or with 0x80
        data |= 0x80;
c0101c92:	80 4d f3 80          	orb    $0x80,-0xd(%ebp)
        shift &= ~E0ESC;
c0101c96:	a1 48 87 12 c0       	mov    0xc0128748,%eax
c0101c9b:	83 e0 bf             	and    $0xffffffbf,%eax
c0101c9e:	a3 48 87 12 c0       	mov    %eax,0xc0128748
    }

    shift |= shiftcode[data];
c0101ca3:	0f b6 45 f3          	movzbl -0xd(%ebp),%eax
c0101ca7:	0f b6 80 40 50 12 c0 	movzbl -0x3fedafc0(%eax),%eax
c0101cae:	0f b6 d0             	movzbl %al,%edx
c0101cb1:	a1 48 87 12 c0       	mov    0xc0128748,%eax
c0101cb6:	09 d0                	or     %edx,%eax
c0101cb8:	a3 48 87 12 c0       	mov    %eax,0xc0128748
    shift ^= togglecode[data];
c0101cbd:	0f b6 45 f3          	movzbl -0xd(%ebp),%eax
c0101cc1:	0f b6 80 40 51 12 c0 	movzbl -0x3fedaec0(%eax),%eax
c0101cc8:	0f b6 d0             	movzbl %al,%edx
c0101ccb:	a1 48 87 12 c0       	mov    0xc0128748,%eax
c0101cd0:	31 d0                	xor    %edx,%eax
c0101cd2:	a3 48 87 12 c0       	mov    %eax,0xc0128748

    c = charcode[shift & (CTL | SHIFT)][data];
c0101cd7:	a1 48 87 12 c0       	mov    0xc0128748,%eax
c0101cdc:	83 e0 03             	and    $0x3,%eax
c0101cdf:	8b 14 85 40 55 12 c0 	mov    -0x3fedaac0(,%eax,4),%edx
c0101ce6:	0f b6 45 f3          	movzbl -0xd(%ebp),%eax
c0101cea:	01 d0                	add    %edx,%eax
c0101cec:	0f b6 00             	movzbl (%eax),%eax
c0101cef:	0f b6 c0             	movzbl %al,%eax
c0101cf2:	89 45 f4             	mov    %eax,-0xc(%ebp)
    if (shift & CAPSLOCK) {
c0101cf5:	a1 48 87 12 c0       	mov    0xc0128748,%eax
c0101cfa:	83 e0 08             	and    $0x8,%eax
c0101cfd:	85 c0                	test   %eax,%eax
c0101cff:	74 22                	je     c0101d23 <kbd_proc_data+0x14a>
        if ('a' <= c && c <= 'z')
c0101d01:	83 7d f4 60          	cmpl   $0x60,-0xc(%ebp)
c0101d05:	7e 0c                	jle    c0101d13 <kbd_proc_data+0x13a>
c0101d07:	83 7d f4 7a          	cmpl   $0x7a,-0xc(%ebp)
c0101d0b:	7f 06                	jg     c0101d13 <kbd_proc_data+0x13a>
            c += 'A' - 'a';
c0101d0d:	83 6d f4 20          	subl   $0x20,-0xc(%ebp)
c0101d11:	eb 10                	jmp    c0101d23 <kbd_proc_data+0x14a>
        else if ('A' <= c && c <= 'Z')
c0101d13:	83 7d f4 40          	cmpl   $0x40,-0xc(%ebp)
c0101d17:	7e 0a                	jle    c0101d23 <kbd_proc_data+0x14a>
c0101d19:	83 7d f4 5a          	cmpl   $0x5a,-0xc(%ebp)
c0101d1d:	7f 04                	jg     c0101d23 <kbd_proc_data+0x14a>
            c += 'a' - 'A';
c0101d1f:	83 45 f4 20          	addl   $0x20,-0xc(%ebp)
    }

    // Process special keys
    // Ctrl-Alt-Del: reboot
    if (!(~shift & (CTL | ALT)) && c == KEY_DEL) {
c0101d23:	a1 48 87 12 c0       	mov    0xc0128748,%eax
c0101d28:	f7 d0                	not    %eax
c0101d2a:	83 e0 06             	and    $0x6,%eax
c0101d2d:	85 c0                	test   %eax,%eax
c0101d2f:	75 27                	jne    c0101d58 <kbd_proc_data+0x17f>
c0101d31:	81 7d f4 e9 00 00 00 	cmpl   $0xe9,-0xc(%ebp)
c0101d38:	75 1e                	jne    c0101d58 <kbd_proc_data+0x17f>
        cprintf("Rebooting!\n");
c0101d3a:	c7 04 24 99 a1 10 c0 	movl   $0xc010a199,(%esp)
c0101d41:	e8 63 e5 ff ff       	call   c01002a9 <cprintf>
c0101d46:	66 c7 45 e8 92 00    	movw   $0x92,-0x18(%ebp)
c0101d4c:	c6 45 e7 03          	movb   $0x3,-0x19(%ebp)
    asm volatile ("outb %0, %1" :: "a" (data), "d" (port) : "memory");
c0101d50:	0f b6 45 e7          	movzbl -0x19(%ebp),%eax
c0101d54:	8b 55 e8             	mov    -0x18(%ebp),%edx
c0101d57:	ee                   	out    %al,(%dx)
        outb(0x92, 0x3); // courtesy of Chris Frost
    }
    return c;
c0101d58:	8b 45 f4             	mov    -0xc(%ebp),%eax
}
c0101d5b:	c9                   	leave  
c0101d5c:	c3                   	ret    

c0101d5d <kbd_intr>:

/* kbd_intr - try to feed input characters from keyboard */
static void
kbd_intr(void) {
c0101d5d:	55                   	push   %ebp
c0101d5e:	89 e5                	mov    %esp,%ebp
c0101d60:	83 ec 18             	sub    $0x18,%esp
    cons_intr(kbd_proc_data);
c0101d63:	c7 04 24 d9 1b 10 c0 	movl   $0xc0101bd9,(%esp)
c0101d6a:	e8 a9 fd ff ff       	call   c0101b18 <cons_intr>
}
c0101d6f:	90                   	nop
c0101d70:	c9                   	leave  
c0101d71:	c3                   	ret    

c0101d72 <kbd_init>:

static void
kbd_init(void) {
c0101d72:	55                   	push   %ebp
c0101d73:	89 e5                	mov    %esp,%ebp
c0101d75:	83 ec 18             	sub    $0x18,%esp
    // drain the kbd buffer
    kbd_intr();
c0101d78:	e8 e0 ff ff ff       	call   c0101d5d <kbd_intr>
    pic_enable(IRQ_KBD);
c0101d7d:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
c0101d84:	e8 35 01 00 00       	call   c0101ebe <pic_enable>
}
c0101d89:	90                   	nop
c0101d8a:	c9                   	leave  
c0101d8b:	c3                   	ret    

c0101d8c <cons_init>:

/* cons_init - initializes the console devices */
void
cons_init(void) {
c0101d8c:	55                   	push   %ebp
c0101d8d:	89 e5                	mov    %esp,%ebp
c0101d8f:	83 ec 18             	sub    $0x18,%esp
    cga_init();
c0101d92:	e8 83 f8 ff ff       	call   c010161a <cga_init>
    serial_init();
c0101d97:	e8 62 f9 ff ff       	call   c01016fe <serial_init>
    kbd_init();
c0101d9c:	e8 d1 ff ff ff       	call   c0101d72 <kbd_init>
    if (!serial_exists) {
c0101da1:	a1 28 85 12 c0       	mov    0xc0128528,%eax
c0101da6:	85 c0                	test   %eax,%eax
c0101da8:	75 0c                	jne    c0101db6 <cons_init+0x2a>
        cprintf("serial port does not exist!!\n");
c0101daa:	c7 04 24 a5 a1 10 c0 	movl   $0xc010a1a5,(%esp)
c0101db1:	e8 f3 e4 ff ff       	call   c01002a9 <cprintf>
    }
}
c0101db6:	90                   	nop
c0101db7:	c9                   	leave  
c0101db8:	c3                   	ret    

c0101db9 <cons_putc>:

/* cons_putc - print a single character @c to console devices */
void
cons_putc(int c) {
c0101db9:	55                   	push   %ebp
c0101dba:	89 e5                	mov    %esp,%ebp
c0101dbc:	83 ec 28             	sub    $0x28,%esp
    bool intr_flag;
    local_intr_save(intr_flag);
c0101dbf:	e8 cf f7 ff ff       	call   c0101593 <__intr_save>
c0101dc4:	89 45 f4             	mov    %eax,-0xc(%ebp)
    {
        lpt_putc(c);
c0101dc7:	8b 45 08             	mov    0x8(%ebp),%eax
c0101dca:	89 04 24             	mov    %eax,(%esp)
c0101dcd:	e8 89 fa ff ff       	call   c010185b <lpt_putc>
        cga_putc(c);
c0101dd2:	8b 45 08             	mov    0x8(%ebp),%eax
c0101dd5:	89 04 24             	mov    %eax,(%esp)
c0101dd8:	e8 be fa ff ff       	call   c010189b <cga_putc>
        serial_putc(c);
c0101ddd:	8b 45 08             	mov    0x8(%ebp),%eax
c0101de0:	89 04 24             	mov    %eax,(%esp)
c0101de3:	e8 f0 fc ff ff       	call   c0101ad8 <serial_putc>
    }
    local_intr_restore(intr_flag);
c0101de8:	8b 45 f4             	mov    -0xc(%ebp),%eax
c0101deb:	89 04 24             	mov    %eax,(%esp)
c0101dee:	e8 ca f7 ff ff       	call   c01015bd <__intr_restore>
}
c0101df3:	90                   	nop
c0101df4:	c9                   	leave  
c0101df5:	c3                   	ret    

c0101df6 <cons_getc>:
/* *
 * cons_getc - return the next input character from console,
 * or 0 if none waiting.
 * */
int
cons_getc(void) {
c0101df6:	55                   	push   %ebp
c0101df7:	89 e5                	mov    %esp,%ebp
c0101df9:	83 ec 28             	sub    $0x28,%esp
    int c = 0;
c0101dfc:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
    bool intr_flag;
    local_intr_save(intr_flag);
c0101e03:	e8 8b f7 ff ff       	call   c0101593 <__intr_save>
c0101e08:	89 45 f0             	mov    %eax,-0x10(%ebp)
    {
        // poll for any pending input characters,
        // so that this function works even when interrupts are disabled
        // (e.g., when called from the kernel monitor).
        serial_intr();
c0101e0b:	e8 ab fd ff ff       	call   c0101bbb <serial_intr>
        kbd_intr();
c0101e10:	e8 48 ff ff ff       	call   c0101d5d <kbd_intr>

        // grab the next character from the input buffer.
        if (cons.rpos != cons.wpos) {
c0101e15:	8b 15 40 87 12 c0    	mov    0xc0128740,%edx
c0101e1b:	a1 44 87 12 c0       	mov    0xc0128744,%eax
c0101e20:	39 c2                	cmp    %eax,%edx
c0101e22:	74 31                	je     c0101e55 <cons_getc+0x5f>
            c = cons.buf[cons.rpos ++];
c0101e24:	a1 40 87 12 c0       	mov    0xc0128740,%eax
c0101e29:	8d 50 01             	lea    0x1(%eax),%edx
c0101e2c:	89 15 40 87 12 c0    	mov    %edx,0xc0128740
c0101e32:	0f b6 80 40 85 12 c0 	movzbl -0x3fed7ac0(%eax),%eax
c0101e39:	0f b6 c0             	movzbl %al,%eax
c0101e3c:	89 45 f4             	mov    %eax,-0xc(%ebp)
            if (cons.rpos == CONSBUFSIZE) {
c0101e3f:	a1 40 87 12 c0       	mov    0xc0128740,%eax
c0101e44:	3d 00 02 00 00       	cmp    $0x200,%eax
c0101e49:	75 0a                	jne    c0101e55 <cons_getc+0x5f>
                cons.rpos = 0;
c0101e4b:	c7 05 40 87 12 c0 00 	movl   $0x0,0xc0128740
c0101e52:	00 00 00 
            }
        }
    }
    local_intr_restore(intr_flag);
c0101e55:	8b 45 f0             	mov    -0x10(%ebp),%eax
c0101e58:	89 04 24             	mov    %eax,(%esp)
c0101e5b:	e8 5d f7 ff ff       	call   c01015bd <__intr_restore>
    return c;
c0101e60:	8b 45 f4             	mov    -0xc(%ebp),%eax
}
c0101e63:	c9                   	leave  
c0101e64:	c3                   	ret    

c0101e65 <pic_setmask>:
// Initial IRQ mask has interrupt 2 enabled (for slave 8259A).
static uint16_t irq_mask = 0xFFFF & ~(1 << IRQ_SLAVE);
static bool did_init = 0;

static void
pic_setmask(uint16_t mask) {
c0101e65:	55                   	push   %ebp
c0101e66:	89 e5                	mov    %esp,%ebp
c0101e68:	83 ec 14             	sub    $0x14,%esp
c0101e6b:	8b 45 08             	mov    0x8(%ebp),%eax
c0101e6e:	66 89 45 ec          	mov    %ax,-0x14(%ebp)
    irq_mask = mask;
c0101e72:	8b 45 ec             	mov    -0x14(%ebp),%eax
c0101e75:	66 a3 50 55 12 c0    	mov    %ax,0xc0125550
    if (did_init) {
c0101e7b:	a1 4c 87 12 c0       	mov    0xc012874c,%eax
c0101e80:	85 c0                	test   %eax,%eax
c0101e82:	74 37                	je     c0101ebb <pic_setmask+0x56>
        outb(IO_PIC1 + 1, mask);
c0101e84:	8b 45 ec             	mov    -0x14(%ebp),%eax
c0101e87:	0f b6 c0             	movzbl %al,%eax
c0101e8a:	66 c7 45 fa 21 00    	movw   $0x21,-0x6(%ebp)
c0101e90:	88 45 f9             	mov    %al,-0x7(%ebp)
c0101e93:	0f b6 45 f9          	movzbl -0x7(%ebp),%eax
c0101e97:	0f b7 55 fa          	movzwl -0x6(%ebp),%edx
c0101e9b:	ee                   	out    %al,(%dx)
        outb(IO_PIC2 + 1, mask >> 8);
c0101e9c:	0f b7 45 ec          	movzwl -0x14(%ebp),%eax
c0101ea0:	c1 e8 08             	shr    $0x8,%eax
c0101ea3:	0f b7 c0             	movzwl %ax,%eax
c0101ea6:	0f b6 c0             	movzbl %al,%eax
c0101ea9:	66 c7 45 fe a1 00    	movw   $0xa1,-0x2(%ebp)
c0101eaf:	88 45 fd             	mov    %al,-0x3(%ebp)
c0101eb2:	0f b6 45 fd          	movzbl -0x3(%ebp),%eax
c0101eb6:	0f b7 55 fe          	movzwl -0x2(%ebp),%edx
c0101eba:	ee                   	out    %al,(%dx)
    }
}
c0101ebb:	90                   	nop
c0101ebc:	c9                   	leave  
c0101ebd:	c3                   	ret    

c0101ebe <pic_enable>:

void
pic_enable(unsigned int irq) {
c0101ebe:	55                   	push   %ebp
c0101ebf:	89 e5                	mov    %esp,%ebp
c0101ec1:	83 ec 04             	sub    $0x4,%esp
    pic_setmask(irq_mask & ~(1 << irq));
c0101ec4:	8b 45 08             	mov    0x8(%ebp),%eax
c0101ec7:	ba 01 00 00 00       	mov    $0x1,%edx
c0101ecc:	88 c1                	mov    %al,%cl
c0101ece:	d3 e2                	shl    %cl,%edx
c0101ed0:	89 d0                	mov    %edx,%eax
c0101ed2:	98                   	cwtl   
c0101ed3:	f7 d0                	not    %eax
c0101ed5:	0f bf d0             	movswl %ax,%edx
c0101ed8:	0f b7 05 50 55 12 c0 	movzwl 0xc0125550,%eax
c0101edf:	98                   	cwtl   
c0101ee0:	21 d0                	and    %edx,%eax
c0101ee2:	98                   	cwtl   
c0101ee3:	0f b7 c0             	movzwl %ax,%eax
c0101ee6:	89 04 24             	mov    %eax,(%esp)
c0101ee9:	e8 77 ff ff ff       	call   c0101e65 <pic_setmask>
}
c0101eee:	90                   	nop
c0101eef:	c9                   	leave  
c0101ef0:	c3                   	ret    

c0101ef1 <pic_init>:

/* pic_init - initialize the 8259A interrupt controllers */
void
pic_init(void) {
c0101ef1:	55                   	push   %ebp
c0101ef2:	89 e5                	mov    %esp,%ebp
c0101ef4:	83 ec 44             	sub    $0x44,%esp
    did_init = 1;
c0101ef7:	c7 05 4c 87 12 c0 01 	movl   $0x1,0xc012874c
c0101efe:	00 00 00 
c0101f01:	66 c7 45 ca 21 00    	movw   $0x21,-0x36(%ebp)
c0101f07:	c6 45 c9 ff          	movb   $0xff,-0x37(%ebp)
c0101f0b:	0f b6 45 c9          	movzbl -0x37(%ebp),%eax
c0101f0f:	0f b7 55 ca          	movzwl -0x36(%ebp),%edx
c0101f13:	ee                   	out    %al,(%dx)
c0101f14:	66 c7 45 ce a1 00    	movw   $0xa1,-0x32(%ebp)
c0101f1a:	c6 45 cd ff          	movb   $0xff,-0x33(%ebp)
c0101f1e:	0f b6 45 cd          	movzbl -0x33(%ebp),%eax
c0101f22:	0f b7 55 ce          	movzwl -0x32(%ebp),%edx
c0101f26:	ee                   	out    %al,(%dx)
c0101f27:	66 c7 45 d2 20 00    	movw   $0x20,-0x2e(%ebp)
c0101f2d:	c6 45 d1 11          	movb   $0x11,-0x2f(%ebp)
c0101f31:	0f b6 45 d1          	movzbl -0x2f(%ebp),%eax
c0101f35:	0f b7 55 d2          	movzwl -0x2e(%ebp),%edx
c0101f39:	ee                   	out    %al,(%dx)
c0101f3a:	66 c7 45 d6 21 00    	movw   $0x21,-0x2a(%ebp)
c0101f40:	c6 45 d5 20          	movb   $0x20,-0x2b(%ebp)
c0101f44:	0f b6 45 d5          	movzbl -0x2b(%ebp),%eax
c0101f48:	0f b7 55 d6          	movzwl -0x2a(%ebp),%edx
c0101f4c:	ee                   	out    %al,(%dx)
c0101f4d:	66 c7 45 da 21 00    	movw   $0x21,-0x26(%ebp)
c0101f53:	c6 45 d9 04          	movb   $0x4,-0x27(%ebp)
c0101f57:	0f b6 45 d9          	movzbl -0x27(%ebp),%eax
c0101f5b:	0f b7 55 da          	movzwl -0x26(%ebp),%edx
c0101f5f:	ee                   	out    %al,(%dx)
c0101f60:	66 c7 45 de 21 00    	movw   $0x21,-0x22(%ebp)
c0101f66:	c6 45 dd 03          	movb   $0x3,-0x23(%ebp)
c0101f6a:	0f b6 45 dd          	movzbl -0x23(%ebp),%eax
c0101f6e:	0f b7 55 de          	movzwl -0x22(%ebp),%edx
c0101f72:	ee                   	out    %al,(%dx)
c0101f73:	66 c7 45 e2 a0 00    	movw   $0xa0,-0x1e(%ebp)
c0101f79:	c6 45 e1 11          	movb   $0x11,-0x1f(%ebp)
c0101f7d:	0f b6 45 e1          	movzbl -0x1f(%ebp),%eax
c0101f81:	0f b7 55 e2          	movzwl -0x1e(%ebp),%edx
c0101f85:	ee                   	out    %al,(%dx)
c0101f86:	66 c7 45 e6 a1 00    	movw   $0xa1,-0x1a(%ebp)
c0101f8c:	c6 45 e5 28          	movb   $0x28,-0x1b(%ebp)
c0101f90:	0f b6 45 e5          	movzbl -0x1b(%ebp),%eax
c0101f94:	0f b7 55 e6          	movzwl -0x1a(%ebp),%edx
c0101f98:	ee                   	out    %al,(%dx)
c0101f99:	66 c7 45 ea a1 00    	movw   $0xa1,-0x16(%ebp)
c0101f9f:	c6 45 e9 02          	movb   $0x2,-0x17(%ebp)
c0101fa3:	0f b6 45 e9          	movzbl -0x17(%ebp),%eax
c0101fa7:	0f b7 55 ea          	movzwl -0x16(%ebp),%edx
c0101fab:	ee                   	out    %al,(%dx)
c0101fac:	66 c7 45 ee a1 00    	movw   $0xa1,-0x12(%ebp)
c0101fb2:	c6 45 ed 03          	movb   $0x3,-0x13(%ebp)
c0101fb6:	0f b6 45 ed          	movzbl -0x13(%ebp),%eax
c0101fba:	0f b7 55 ee          	movzwl -0x12(%ebp),%edx
c0101fbe:	ee                   	out    %al,(%dx)
c0101fbf:	66 c7 45 f2 20 00    	movw   $0x20,-0xe(%ebp)
c0101fc5:	c6 45 f1 68          	movb   $0x68,-0xf(%ebp)
c0101fc9:	0f b6 45 f1          	movzbl -0xf(%ebp),%eax
c0101fcd:	0f b7 55 f2          	movzwl -0xe(%ebp),%edx
c0101fd1:	ee                   	out    %al,(%dx)
c0101fd2:	66 c7 45 f6 20 00    	movw   $0x20,-0xa(%ebp)
c0101fd8:	c6 45 f5 0a          	movb   $0xa,-0xb(%ebp)
c0101fdc:	0f b6 45 f5          	movzbl -0xb(%ebp),%eax
c0101fe0:	0f b7 55 f6          	movzwl -0xa(%ebp),%edx
c0101fe4:	ee                   	out    %al,(%dx)
c0101fe5:	66 c7 45 fa a0 00    	movw   $0xa0,-0x6(%ebp)
c0101feb:	c6 45 f9 68          	movb   $0x68,-0x7(%ebp)
c0101fef:	0f b6 45 f9          	movzbl -0x7(%ebp),%eax
c0101ff3:	0f b7 55 fa          	movzwl -0x6(%ebp),%edx
c0101ff7:	ee                   	out    %al,(%dx)
c0101ff8:	66 c7 45 fe a0 00    	movw   $0xa0,-0x2(%ebp)
c0101ffe:	c6 45 fd 0a          	movb   $0xa,-0x3(%ebp)
c0102002:	0f b6 45 fd          	movzbl -0x3(%ebp),%eax
c0102006:	0f b7 55 fe          	movzwl -0x2(%ebp),%edx
c010200a:	ee                   	out    %al,(%dx)
    outb(IO_PIC1, 0x0a);    // read IRR by default

    outb(IO_PIC2, 0x68);    // OCW3
    outb(IO_PIC2, 0x0a);    // OCW3

    if (irq_mask != 0xFFFF) {
c010200b:	0f b7 05 50 55 12 c0 	movzwl 0xc0125550,%eax
c0102012:	3d ff ff 00 00       	cmp    $0xffff,%eax
c0102017:	74 0f                	je     c0102028 <pic_init+0x137>
        pic_setmask(irq_mask);
c0102019:	0f b7 05 50 55 12 c0 	movzwl 0xc0125550,%eax
c0102020:	89 04 24             	mov    %eax,(%esp)
c0102023:	e8 3d fe ff ff       	call   c0101e65 <pic_setmask>
    }
}
c0102028:	90                   	nop
c0102029:	c9                   	leave  
c010202a:	c3                   	ret    

c010202b <intr_enable>:
#include <x86.h>
#include <intr.h>

/* intr_enable - enable irq interrupt */
void
intr_enable(void) {
c010202b:	55                   	push   %ebp
c010202c:	89 e5                	mov    %esp,%ebp
    asm volatile ("sti");
c010202e:	fb                   	sti    
    sti();
}
c010202f:	90                   	nop
c0102030:	5d                   	pop    %ebp
c0102031:	c3                   	ret    

c0102032 <intr_disable>:

/* intr_disable - disable irq interrupt */
void
intr_disable(void) {
c0102032:	55                   	push   %ebp
c0102033:	89 e5                	mov    %esp,%ebp
    asm volatile ("cli" ::: "memory");
c0102035:	fa                   	cli    
    cli();
}
c0102036:	90                   	nop
c0102037:	5d                   	pop    %ebp
c0102038:	c3                   	ret    

c0102039 <print_ticks>:
#include <swap.h>
#include <kdebug.h>

#define TICK_NUM 100

static void print_ticks() {
c0102039:	55                   	push   %ebp
c010203a:	89 e5                	mov    %esp,%ebp
c010203c:	83 ec 18             	sub    $0x18,%esp
    cprintf("%d ticks\n",TICK_NUM);
c010203f:	c7 44 24 04 64 00 00 	movl   $0x64,0x4(%esp)
c0102046:	00 
c0102047:	c7 04 24 e0 a1 10 c0 	movl   $0xc010a1e0,(%esp)
c010204e:	e8 56 e2 ff ff       	call   c01002a9 <cprintf>
#ifdef DEBUG_GRADE
    cprintf("End of Test.\n");
c0102053:	c7 04 24 ea a1 10 c0 	movl   $0xc010a1ea,(%esp)
c010205a:	e8 4a e2 ff ff       	call   c01002a9 <cprintf>
    panic("EOT: kernel seems ok.");
c010205f:	c7 44 24 08 f8 a1 10 	movl   $0xc010a1f8,0x8(%esp)
c0102066:	c0 
c0102067:	c7 44 24 04 14 00 00 	movl   $0x14,0x4(%esp)
c010206e:	00 
c010206f:	c7 04 24 0e a2 10 c0 	movl   $0xc010a20e,(%esp)
c0102076:	e8 85 e3 ff ff       	call   c0100400 <__panic>

c010207b <idt_init>:
    sizeof(idt) - 1, (uintptr_t)idt
};

/* idt_init - initialize IDT to each of the entry points in kern/trap/vectors.S */
void
idt_init(void) {
c010207b:	55                   	push   %ebp
c010207c:	89 e5                	mov    %esp,%ebp
c010207e:	83 ec 10             	sub    $0x10,%esp
      *     You don't know the meaning of this instruction? just google it! and check the libs/x86.h to know more.
      *     Notice: the argument of lidt is idt_pd. try to find it!
      */
    extern uintptr_t __vectors[];
    int i;
    for (i = 0; i < sizeof(idt) / sizeof(struct gatedesc); i ++) {
c0102081:	c7 45 fc 00 00 00 00 	movl   $0x0,-0x4(%ebp)
c0102088:	e9 c4 00 00 00       	jmp    c0102151 <idt_init+0xd6>
        SETGATE(idt[i], 0, GD_KTEXT, __vectors[i], DPL_KERNEL);
c010208d:	8b 45 fc             	mov    -0x4(%ebp),%eax
c0102090:	8b 04 85 e0 55 12 c0 	mov    -0x3fedaa20(,%eax,4),%eax
c0102097:	0f b7 d0             	movzwl %ax,%edx
c010209a:	8b 45 fc             	mov    -0x4(%ebp),%eax
c010209d:	66 89 14 c5 60 87 12 	mov    %dx,-0x3fed78a0(,%eax,8)
c01020a4:	c0 
c01020a5:	8b 45 fc             	mov    -0x4(%ebp),%eax
c01020a8:	66 c7 04 c5 62 87 12 	movw   $0x8,-0x3fed789e(,%eax,8)
c01020af:	c0 08 00 
c01020b2:	8b 45 fc             	mov    -0x4(%ebp),%eax
c01020b5:	0f b6 14 c5 64 87 12 	movzbl -0x3fed789c(,%eax,8),%edx
c01020bc:	c0 
c01020bd:	80 e2 e0             	and    $0xe0,%dl
c01020c0:	88 14 c5 64 87 12 c0 	mov    %dl,-0x3fed789c(,%eax,8)
c01020c7:	8b 45 fc             	mov    -0x4(%ebp),%eax
c01020ca:	0f b6 14 c5 64 87 12 	movzbl -0x3fed789c(,%eax,8),%edx
c01020d1:	c0 
c01020d2:	80 e2 1f             	and    $0x1f,%dl
c01020d5:	88 14 c5 64 87 12 c0 	mov    %dl,-0x3fed789c(,%eax,8)
c01020dc:	8b 45 fc             	mov    -0x4(%ebp),%eax
c01020df:	0f b6 14 c5 65 87 12 	movzbl -0x3fed789b(,%eax,8),%edx
c01020e6:	c0 
c01020e7:	80 e2 f0             	and    $0xf0,%dl
c01020ea:	80 ca 0e             	or     $0xe,%dl
c01020ed:	88 14 c5 65 87 12 c0 	mov    %dl,-0x3fed789b(,%eax,8)
c01020f4:	8b 45 fc             	mov    -0x4(%ebp),%eax
c01020f7:	0f b6 14 c5 65 87 12 	movzbl -0x3fed789b(,%eax,8),%edx
c01020fe:	c0 
c01020ff:	80 e2 ef             	and    $0xef,%dl
c0102102:	88 14 c5 65 87 12 c0 	mov    %dl,-0x3fed789b(,%eax,8)
c0102109:	8b 45 fc             	mov    -0x4(%ebp),%eax
c010210c:	0f b6 14 c5 65 87 12 	movzbl -0x3fed789b(,%eax,8),%edx
c0102113:	c0 
c0102114:	80 e2 9f             	and    $0x9f,%dl
c0102117:	88 14 c5 65 87 12 c0 	mov    %dl,-0x3fed789b(,%eax,8)
c010211e:	8b 45 fc             	mov    -0x4(%ebp),%eax
c0102121:	0f b6 14 c5 65 87 12 	movzbl -0x3fed789b(,%eax,8),%edx
c0102128:	c0 
c0102129:	80 ca 80             	or     $0x80,%dl
c010212c:	88 14 c5 65 87 12 c0 	mov    %dl,-0x3fed789b(,%eax,8)
c0102133:	8b 45 fc             	mov    -0x4(%ebp),%eax
c0102136:	8b 04 85 e0 55 12 c0 	mov    -0x3fedaa20(,%eax,4),%eax
c010213d:	c1 e8 10             	shr    $0x10,%eax
c0102140:	0f b7 d0             	movzwl %ax,%edx
c0102143:	8b 45 fc             	mov    -0x4(%ebp),%eax
c0102146:	66 89 14 c5 66 87 12 	mov    %dx,-0x3fed789a(,%eax,8)
c010214d:	c0 
    for (i = 0; i < sizeof(idt) / sizeof(struct gatedesc); i ++) {
c010214e:	ff 45 fc             	incl   -0x4(%ebp)
c0102151:	8b 45 fc             	mov    -0x4(%ebp),%eax
c0102154:	3d ff 00 00 00       	cmp    $0xff,%eax
c0102159:	0f 86 2e ff ff ff    	jbe    c010208d <idt_init+0x12>
c010215f:	c7 45 f8 60 55 12 c0 	movl   $0xc0125560,-0x8(%ebp)
    asm volatile ("lidt (%0)" :: "r" (pd) : "memory");
c0102166:	8b 45 f8             	mov    -0x8(%ebp),%eax
c0102169:	0f 01 18             	lidtl  (%eax)
    }
    lidt(&idt_pd);
}
c010216c:	90                   	nop
c010216d:	c9                   	leave  
c010216e:	c3                   	ret    

c010216f <trapname>:

static const char *
trapname(int trapno) {
c010216f:	55                   	push   %ebp
c0102170:	89 e5                	mov    %esp,%ebp
        "Alignment Check",
        "Machine-Check",
        "SIMD Floating-Point Exception"
    };

    if (trapno < sizeof(excnames)/sizeof(const char * const)) {
c0102172:	8b 45 08             	mov    0x8(%ebp),%eax
c0102175:	83 f8 13             	cmp    $0x13,%eax
c0102178:	77 0c                	ja     c0102186 <trapname+0x17>
        return excnames[trapno];
c010217a:	8b 45 08             	mov    0x8(%ebp),%eax
c010217d:	8b 04 85 e0 a5 10 c0 	mov    -0x3fef5a20(,%eax,4),%eax
c0102184:	eb 18                	jmp    c010219e <trapname+0x2f>
    }
    if (trapno >= IRQ_OFFSET && trapno < IRQ_OFFSET + 16) {
c0102186:	83 7d 08 1f          	cmpl   $0x1f,0x8(%ebp)
c010218a:	7e 0d                	jle    c0102199 <trapname+0x2a>
c010218c:	83 7d 08 2f          	cmpl   $0x2f,0x8(%ebp)
c0102190:	7f 07                	jg     c0102199 <trapname+0x2a>
        return "Hardware Interrupt";
c0102192:	b8 1f a2 10 c0       	mov    $0xc010a21f,%eax
c0102197:	eb 05                	jmp    c010219e <trapname+0x2f>
    }
    return "(unknown trap)";
c0102199:	b8 32 a2 10 c0       	mov    $0xc010a232,%eax
}
c010219e:	5d                   	pop    %ebp
c010219f:	c3                   	ret    

c01021a0 <trap_in_kernel>:

/* trap_in_kernel - test if trap happened in kernel */
bool
trap_in_kernel(struct trapframe *tf) {
c01021a0:	55                   	push   %ebp
c01021a1:	89 e5                	mov    %esp,%ebp
    return (tf->tf_cs == (uint16_t)KERNEL_CS);
c01021a3:	8b 45 08             	mov    0x8(%ebp),%eax
c01021a6:	0f b7 40 3c          	movzwl 0x3c(%eax),%eax
c01021aa:	83 f8 08             	cmp    $0x8,%eax
c01021ad:	0f 94 c0             	sete   %al
c01021b0:	0f b6 c0             	movzbl %al,%eax
}
c01021b3:	5d                   	pop    %ebp
c01021b4:	c3                   	ret    

c01021b5 <print_trapframe>:
    "TF", "IF", "DF", "OF", NULL, NULL, "NT", NULL,
    "RF", "VM", "AC", "VIF", "VIP", "ID", NULL, NULL,
};

void
print_trapframe(struct trapframe *tf) {
c01021b5:	55                   	push   %ebp
c01021b6:	89 e5                	mov    %esp,%ebp
c01021b8:	83 ec 28             	sub    $0x28,%esp
    cprintf("trapframe at %p\n", tf);
c01021bb:	8b 45 08             	mov    0x8(%ebp),%eax
c01021be:	89 44 24 04          	mov    %eax,0x4(%esp)
c01021c2:	c7 04 24 73 a2 10 c0 	movl   $0xc010a273,(%esp)
c01021c9:	e8 db e0 ff ff       	call   c01002a9 <cprintf>
    print_regs(&tf->tf_regs);
c01021ce:	8b 45 08             	mov    0x8(%ebp),%eax
c01021d1:	89 04 24             	mov    %eax,(%esp)
c01021d4:	e8 8f 01 00 00       	call   c0102368 <print_regs>
    cprintf("  ds   0x----%04x\n", tf->tf_ds);
c01021d9:	8b 45 08             	mov    0x8(%ebp),%eax
c01021dc:	0f b7 40 2c          	movzwl 0x2c(%eax),%eax
c01021e0:	89 44 24 04          	mov    %eax,0x4(%esp)
c01021e4:	c7 04 24 84 a2 10 c0 	movl   $0xc010a284,(%esp)
c01021eb:	e8 b9 e0 ff ff       	call   c01002a9 <cprintf>
    cprintf("  es   0x----%04x\n", tf->tf_es);
c01021f0:	8b 45 08             	mov    0x8(%ebp),%eax
c01021f3:	0f b7 40 28          	movzwl 0x28(%eax),%eax
c01021f7:	89 44 24 04          	mov    %eax,0x4(%esp)
c01021fb:	c7 04 24 97 a2 10 c0 	movl   $0xc010a297,(%esp)
c0102202:	e8 a2 e0 ff ff       	call   c01002a9 <cprintf>
    cprintf("  fs   0x----%04x\n", tf->tf_fs);
c0102207:	8b 45 08             	mov    0x8(%ebp),%eax
c010220a:	0f b7 40 24          	movzwl 0x24(%eax),%eax
c010220e:	89 44 24 04          	mov    %eax,0x4(%esp)
c0102212:	c7 04 24 aa a2 10 c0 	movl   $0xc010a2aa,(%esp)
c0102219:	e8 8b e0 ff ff       	call   c01002a9 <cprintf>
    cprintf("  gs   0x----%04x\n", tf->tf_gs);
c010221e:	8b 45 08             	mov    0x8(%ebp),%eax
c0102221:	0f b7 40 20          	movzwl 0x20(%eax),%eax
c0102225:	89 44 24 04          	mov    %eax,0x4(%esp)
c0102229:	c7 04 24 bd a2 10 c0 	movl   $0xc010a2bd,(%esp)
c0102230:	e8 74 e0 ff ff       	call   c01002a9 <cprintf>
    cprintf("  trap 0x%08x %s\n", tf->tf_trapno, trapname(tf->tf_trapno));
c0102235:	8b 45 08             	mov    0x8(%ebp),%eax
c0102238:	8b 40 30             	mov    0x30(%eax),%eax
c010223b:	89 04 24             	mov    %eax,(%esp)
c010223e:	e8 2c ff ff ff       	call   c010216f <trapname>
c0102243:	89 c2                	mov    %eax,%edx
c0102245:	8b 45 08             	mov    0x8(%ebp),%eax
c0102248:	8b 40 30             	mov    0x30(%eax),%eax
c010224b:	89 54 24 08          	mov    %edx,0x8(%esp)
c010224f:	89 44 24 04          	mov    %eax,0x4(%esp)
c0102253:	c7 04 24 d0 a2 10 c0 	movl   $0xc010a2d0,(%esp)
c010225a:	e8 4a e0 ff ff       	call   c01002a9 <cprintf>
    cprintf("  err  0x%08x\n", tf->tf_err);
c010225f:	8b 45 08             	mov    0x8(%ebp),%eax
c0102262:	8b 40 34             	mov    0x34(%eax),%eax
c0102265:	89 44 24 04          	mov    %eax,0x4(%esp)
c0102269:	c7 04 24 e2 a2 10 c0 	movl   $0xc010a2e2,(%esp)
c0102270:	e8 34 e0 ff ff       	call   c01002a9 <cprintf>
    cprintf("  eip  0x%08x\n", tf->tf_eip);
c0102275:	8b 45 08             	mov    0x8(%ebp),%eax
c0102278:	8b 40 38             	mov    0x38(%eax),%eax
c010227b:	89 44 24 04          	mov    %eax,0x4(%esp)
c010227f:	c7 04 24 f1 a2 10 c0 	movl   $0xc010a2f1,(%esp)
c0102286:	e8 1e e0 ff ff       	call   c01002a9 <cprintf>
    cprintf("  cs   0x----%04x\n", tf->tf_cs);
c010228b:	8b 45 08             	mov    0x8(%ebp),%eax
c010228e:	0f b7 40 3c          	movzwl 0x3c(%eax),%eax
c0102292:	89 44 24 04          	mov    %eax,0x4(%esp)
c0102296:	c7 04 24 00 a3 10 c0 	movl   $0xc010a300,(%esp)
c010229d:	e8 07 e0 ff ff       	call   c01002a9 <cprintf>
    cprintf("  flag 0x%08x ", tf->tf_eflags);
c01022a2:	8b 45 08             	mov    0x8(%ebp),%eax
c01022a5:	8b 40 40             	mov    0x40(%eax),%eax
c01022a8:	89 44 24 04          	mov    %eax,0x4(%esp)
c01022ac:	c7 04 24 13 a3 10 c0 	movl   $0xc010a313,(%esp)
c01022b3:	e8 f1 df ff ff       	call   c01002a9 <cprintf>

    int i, j;
    for (i = 0, j = 1; i < sizeof(IA32flags) / sizeof(IA32flags[0]); i ++, j <<= 1) {
c01022b8:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
c01022bf:	c7 45 f0 01 00 00 00 	movl   $0x1,-0x10(%ebp)
c01022c6:	eb 3d                	jmp    c0102305 <print_trapframe+0x150>
        if ((tf->tf_eflags & j) && IA32flags[i] != NULL) {
c01022c8:	8b 45 08             	mov    0x8(%ebp),%eax
c01022cb:	8b 50 40             	mov    0x40(%eax),%edx
c01022ce:	8b 45 f0             	mov    -0x10(%ebp),%eax
c01022d1:	21 d0                	and    %edx,%eax
c01022d3:	85 c0                	test   %eax,%eax
c01022d5:	74 28                	je     c01022ff <print_trapframe+0x14a>
c01022d7:	8b 45 f4             	mov    -0xc(%ebp),%eax
c01022da:	8b 04 85 80 55 12 c0 	mov    -0x3fedaa80(,%eax,4),%eax
c01022e1:	85 c0                	test   %eax,%eax
c01022e3:	74 1a                	je     c01022ff <print_trapframe+0x14a>
            cprintf("%s,", IA32flags[i]);
c01022e5:	8b 45 f4             	mov    -0xc(%ebp),%eax
c01022e8:	8b 04 85 80 55 12 c0 	mov    -0x3fedaa80(,%eax,4),%eax
c01022ef:	89 44 24 04          	mov    %eax,0x4(%esp)
c01022f3:	c7 04 24 22 a3 10 c0 	movl   $0xc010a322,(%esp)
c01022fa:	e8 aa df ff ff       	call   c01002a9 <cprintf>
    for (i = 0, j = 1; i < sizeof(IA32flags) / sizeof(IA32flags[0]); i ++, j <<= 1) {
c01022ff:	ff 45 f4             	incl   -0xc(%ebp)
c0102302:	d1 65 f0             	shll   -0x10(%ebp)
c0102305:	8b 45 f4             	mov    -0xc(%ebp),%eax
c0102308:	83 f8 17             	cmp    $0x17,%eax
c010230b:	76 bb                	jbe    c01022c8 <print_trapframe+0x113>
        }
    }
    cprintf("IOPL=%d\n", (tf->tf_eflags & FL_IOPL_MASK) >> 12);
c010230d:	8b 45 08             	mov    0x8(%ebp),%eax
c0102310:	8b 40 40             	mov    0x40(%eax),%eax
c0102313:	c1 e8 0c             	shr    $0xc,%eax
c0102316:	83 e0 03             	and    $0x3,%eax
c0102319:	89 44 24 04          	mov    %eax,0x4(%esp)
c010231d:	c7 04 24 26 a3 10 c0 	movl   $0xc010a326,(%esp)
c0102324:	e8 80 df ff ff       	call   c01002a9 <cprintf>

    if (!trap_in_kernel(tf)) {
c0102329:	8b 45 08             	mov    0x8(%ebp),%eax
c010232c:	89 04 24             	mov    %eax,(%esp)
c010232f:	e8 6c fe ff ff       	call   c01021a0 <trap_in_kernel>
c0102334:	85 c0                	test   %eax,%eax
c0102336:	75 2d                	jne    c0102365 <print_trapframe+0x1b0>
        cprintf("  esp  0x%08x\n", tf->tf_esp);
c0102338:	8b 45 08             	mov    0x8(%ebp),%eax
c010233b:	8b 40 44             	mov    0x44(%eax),%eax
c010233e:	89 44 24 04          	mov    %eax,0x4(%esp)
c0102342:	c7 04 24 2f a3 10 c0 	movl   $0xc010a32f,(%esp)
c0102349:	e8 5b df ff ff       	call   c01002a9 <cprintf>
        cprintf("  ss   0x----%04x\n", tf->tf_ss);
c010234e:	8b 45 08             	mov    0x8(%ebp),%eax
c0102351:	0f b7 40 48          	movzwl 0x48(%eax),%eax
c0102355:	89 44 24 04          	mov    %eax,0x4(%esp)
c0102359:	c7 04 24 3e a3 10 c0 	movl   $0xc010a33e,(%esp)
c0102360:	e8 44 df ff ff       	call   c01002a9 <cprintf>
    }
}
c0102365:	90                   	nop
c0102366:	c9                   	leave  
c0102367:	c3                   	ret    

c0102368 <print_regs>:

void
print_regs(struct pushregs *regs) {
c0102368:	55                   	push   %ebp
c0102369:	89 e5                	mov    %esp,%ebp
c010236b:	83 ec 18             	sub    $0x18,%esp
    cprintf("  edi  0x%08x\n", regs->reg_edi);
c010236e:	8b 45 08             	mov    0x8(%ebp),%eax
c0102371:	8b 00                	mov    (%eax),%eax
c0102373:	89 44 24 04          	mov    %eax,0x4(%esp)
c0102377:	c7 04 24 51 a3 10 c0 	movl   $0xc010a351,(%esp)
c010237e:	e8 26 df ff ff       	call   c01002a9 <cprintf>
    cprintf("  esi  0x%08x\n", regs->reg_esi);
c0102383:	8b 45 08             	mov    0x8(%ebp),%eax
c0102386:	8b 40 04             	mov    0x4(%eax),%eax
c0102389:	89 44 24 04          	mov    %eax,0x4(%esp)
c010238d:	c7 04 24 60 a3 10 c0 	movl   $0xc010a360,(%esp)
c0102394:	e8 10 df ff ff       	call   c01002a9 <cprintf>
    cprintf("  ebp  0x%08x\n", regs->reg_ebp);
c0102399:	8b 45 08             	mov    0x8(%ebp),%eax
c010239c:	8b 40 08             	mov    0x8(%eax),%eax
c010239f:	89 44 24 04          	mov    %eax,0x4(%esp)
c01023a3:	c7 04 24 6f a3 10 c0 	movl   $0xc010a36f,(%esp)
c01023aa:	e8 fa de ff ff       	call   c01002a9 <cprintf>
    cprintf("  oesp 0x%08x\n", regs->reg_oesp);
c01023af:	8b 45 08             	mov    0x8(%ebp),%eax
c01023b2:	8b 40 0c             	mov    0xc(%eax),%eax
c01023b5:	89 44 24 04          	mov    %eax,0x4(%esp)
c01023b9:	c7 04 24 7e a3 10 c0 	movl   $0xc010a37e,(%esp)
c01023c0:	e8 e4 de ff ff       	call   c01002a9 <cprintf>
    cprintf("  ebx  0x%08x\n", regs->reg_ebx);
c01023c5:	8b 45 08             	mov    0x8(%ebp),%eax
c01023c8:	8b 40 10             	mov    0x10(%eax),%eax
c01023cb:	89 44 24 04          	mov    %eax,0x4(%esp)
c01023cf:	c7 04 24 8d a3 10 c0 	movl   $0xc010a38d,(%esp)
c01023d6:	e8 ce de ff ff       	call   c01002a9 <cprintf>
    cprintf("  edx  0x%08x\n", regs->reg_edx);
c01023db:	8b 45 08             	mov    0x8(%ebp),%eax
c01023de:	8b 40 14             	mov    0x14(%eax),%eax
c01023e1:	89 44 24 04          	mov    %eax,0x4(%esp)
c01023e5:	c7 04 24 9c a3 10 c0 	movl   $0xc010a39c,(%esp)
c01023ec:	e8 b8 de ff ff       	call   c01002a9 <cprintf>
    cprintf("  ecx  0x%08x\n", regs->reg_ecx);
c01023f1:	8b 45 08             	mov    0x8(%ebp),%eax
c01023f4:	8b 40 18             	mov    0x18(%eax),%eax
c01023f7:	89 44 24 04          	mov    %eax,0x4(%esp)
c01023fb:	c7 04 24 ab a3 10 c0 	movl   $0xc010a3ab,(%esp)
c0102402:	e8 a2 de ff ff       	call   c01002a9 <cprintf>
    cprintf("  eax  0x%08x\n", regs->reg_eax);
c0102407:	8b 45 08             	mov    0x8(%ebp),%eax
c010240a:	8b 40 1c             	mov    0x1c(%eax),%eax
c010240d:	89 44 24 04          	mov    %eax,0x4(%esp)
c0102411:	c7 04 24 ba a3 10 c0 	movl   $0xc010a3ba,(%esp)
c0102418:	e8 8c de ff ff       	call   c01002a9 <cprintf>
}
c010241d:	90                   	nop
c010241e:	c9                   	leave  
c010241f:	c3                   	ret    

c0102420 <print_pgfault>:

static inline void
print_pgfault(struct trapframe *tf) {
c0102420:	55                   	push   %ebp
c0102421:	89 e5                	mov    %esp,%ebp
c0102423:	53                   	push   %ebx
c0102424:	83 ec 34             	sub    $0x34,%esp
     * bit 2 == 0 means kernel, 1 means user
     * */
    cprintf("page fault at 0x%08x: %c/%c [%s].\n", rcr2(),
            (tf->tf_err & 4) ? 'U' : 'K',
            (tf->tf_err & 2) ? 'W' : 'R',
            (tf->tf_err & 1) ? "protection fault" : "no page found");
c0102427:	8b 45 08             	mov    0x8(%ebp),%eax
c010242a:	8b 40 34             	mov    0x34(%eax),%eax
c010242d:	83 e0 01             	and    $0x1,%eax
    cprintf("page fault at 0x%08x: %c/%c [%s].\n", rcr2(),
c0102430:	85 c0                	test   %eax,%eax
c0102432:	74 07                	je     c010243b <print_pgfault+0x1b>
c0102434:	bb c9 a3 10 c0       	mov    $0xc010a3c9,%ebx
c0102439:	eb 05                	jmp    c0102440 <print_pgfault+0x20>
c010243b:	bb da a3 10 c0       	mov    $0xc010a3da,%ebx
            (tf->tf_err & 2) ? 'W' : 'R',
c0102440:	8b 45 08             	mov    0x8(%ebp),%eax
c0102443:	8b 40 34             	mov    0x34(%eax),%eax
c0102446:	83 e0 02             	and    $0x2,%eax
    cprintf("page fault at 0x%08x: %c/%c [%s].\n", rcr2(),
c0102449:	85 c0                	test   %eax,%eax
c010244b:	74 07                	je     c0102454 <print_pgfault+0x34>
c010244d:	b9 57 00 00 00       	mov    $0x57,%ecx
c0102452:	eb 05                	jmp    c0102459 <print_pgfault+0x39>
c0102454:	b9 52 00 00 00       	mov    $0x52,%ecx
            (tf->tf_err & 4) ? 'U' : 'K',
c0102459:	8b 45 08             	mov    0x8(%ebp),%eax
c010245c:	8b 40 34             	mov    0x34(%eax),%eax
c010245f:	83 e0 04             	and    $0x4,%eax
    cprintf("page fault at 0x%08x: %c/%c [%s].\n", rcr2(),
c0102462:	85 c0                	test   %eax,%eax
c0102464:	74 07                	je     c010246d <print_pgfault+0x4d>
c0102466:	ba 55 00 00 00       	mov    $0x55,%edx
c010246b:	eb 05                	jmp    c0102472 <print_pgfault+0x52>
c010246d:	ba 4b 00 00 00       	mov    $0x4b,%edx
}

static inline uintptr_t
rcr2(void) {
    uintptr_t cr2;
    asm volatile ("mov %%cr2, %0" : "=r" (cr2) :: "memory");
c0102472:	0f 20 d0             	mov    %cr2,%eax
c0102475:	89 45 f4             	mov    %eax,-0xc(%ebp)
    return cr2;
c0102478:	8b 45 f4             	mov    -0xc(%ebp),%eax
c010247b:	89 5c 24 10          	mov    %ebx,0x10(%esp)
c010247f:	89 4c 24 0c          	mov    %ecx,0xc(%esp)
c0102483:	89 54 24 08          	mov    %edx,0x8(%esp)
c0102487:	89 44 24 04          	mov    %eax,0x4(%esp)
c010248b:	c7 04 24 e8 a3 10 c0 	movl   $0xc010a3e8,(%esp)
c0102492:	e8 12 de ff ff       	call   c01002a9 <cprintf>
}
c0102497:	90                   	nop
c0102498:	83 c4 34             	add    $0x34,%esp
c010249b:	5b                   	pop    %ebx
c010249c:	5d                   	pop    %ebp
c010249d:	c3                   	ret    

c010249e <pgfault_handler>:

static int
pgfault_handler(struct trapframe *tf) {
c010249e:	55                   	push   %ebp
c010249f:	89 e5                	mov    %esp,%ebp
c01024a1:	83 ec 28             	sub    $0x28,%esp
    extern struct mm_struct *check_mm_struct;
    print_pgfault(tf);
c01024a4:	8b 45 08             	mov    0x8(%ebp),%eax
c01024a7:	89 04 24             	mov    %eax,(%esp)
c01024aa:	e8 71 ff ff ff       	call   c0102420 <print_pgfault>
    if (check_mm_struct != NULL) {
c01024af:	a1 6c b0 12 c0       	mov    0xc012b06c,%eax
c01024b4:	85 c0                	test   %eax,%eax
c01024b6:	74 26                	je     c01024de <pgfault_handler+0x40>
    asm volatile ("mov %%cr2, %0" : "=r" (cr2) :: "memory");
c01024b8:	0f 20 d0             	mov    %cr2,%eax
c01024bb:	89 45 f4             	mov    %eax,-0xc(%ebp)
    return cr2;
c01024be:	8b 4d f4             	mov    -0xc(%ebp),%ecx
        return do_pgfault(check_mm_struct, tf->tf_err, rcr2());
c01024c1:	8b 45 08             	mov    0x8(%ebp),%eax
c01024c4:	8b 50 34             	mov    0x34(%eax),%edx
c01024c7:	a1 6c b0 12 c0       	mov    0xc012b06c,%eax
c01024cc:	89 4c 24 08          	mov    %ecx,0x8(%esp)
c01024d0:	89 54 24 04          	mov    %edx,0x4(%esp)
c01024d4:	89 04 24             	mov    %eax,(%esp)
c01024d7:	e8 6d 37 00 00       	call   c0105c49 <do_pgfault>
c01024dc:	eb 1c                	jmp    c01024fa <pgfault_handler+0x5c>
    }
    panic("unhandled page fault.\n");
c01024de:	c7 44 24 08 0b a4 10 	movl   $0xc010a40b,0x8(%esp)
c01024e5:	c0 
c01024e6:	c7 44 24 04 a5 00 00 	movl   $0xa5,0x4(%esp)
c01024ed:	00 
c01024ee:	c7 04 24 0e a2 10 c0 	movl   $0xc010a20e,(%esp)
c01024f5:	e8 06 df ff ff       	call   c0100400 <__panic>
}
c01024fa:	c9                   	leave  
c01024fb:	c3                   	ret    

c01024fc <trap_dispatch>:

static volatile int in_swap_tick_event = 0;
extern struct mm_struct *check_mm_struct;

static void
trap_dispatch(struct trapframe *tf) {
c01024fc:	55                   	push   %ebp
c01024fd:	89 e5                	mov    %esp,%ebp
c01024ff:	83 ec 28             	sub    $0x28,%esp
    char c;

    int ret;

    switch (tf->tf_trapno) {
c0102502:	8b 45 08             	mov    0x8(%ebp),%eax
c0102505:	8b 40 30             	mov    0x30(%eax),%eax
c0102508:	83 f8 24             	cmp    $0x24,%eax
c010250b:	0f 84 cc 00 00 00    	je     c01025dd <trap_dispatch+0xe1>
c0102511:	83 f8 24             	cmp    $0x24,%eax
c0102514:	77 18                	ja     c010252e <trap_dispatch+0x32>
c0102516:	83 f8 20             	cmp    $0x20,%eax
c0102519:	74 7c                	je     c0102597 <trap_dispatch+0x9b>
c010251b:	83 f8 21             	cmp    $0x21,%eax
c010251e:	0f 84 df 00 00 00    	je     c0102603 <trap_dispatch+0x107>
c0102524:	83 f8 0e             	cmp    $0xe,%eax
c0102527:	74 28                	je     c0102551 <trap_dispatch+0x55>
c0102529:	e9 17 01 00 00       	jmp    c0102645 <trap_dispatch+0x149>
c010252e:	83 f8 2e             	cmp    $0x2e,%eax
c0102531:	0f 82 0e 01 00 00    	jb     c0102645 <trap_dispatch+0x149>
c0102537:	83 f8 2f             	cmp    $0x2f,%eax
c010253a:	0f 86 3a 01 00 00    	jbe    c010267a <trap_dispatch+0x17e>
c0102540:	83 e8 78             	sub    $0x78,%eax
c0102543:	83 f8 01             	cmp    $0x1,%eax
c0102546:	0f 87 f9 00 00 00    	ja     c0102645 <trap_dispatch+0x149>
c010254c:	e9 d8 00 00 00       	jmp    c0102629 <trap_dispatch+0x12d>
    case T_PGFLT:  //page fault
        if ((ret = pgfault_handler(tf)) != 0) {
c0102551:	8b 45 08             	mov    0x8(%ebp),%eax
c0102554:	89 04 24             	mov    %eax,(%esp)
c0102557:	e8 42 ff ff ff       	call   c010249e <pgfault_handler>
c010255c:	89 45 f0             	mov    %eax,-0x10(%ebp)
c010255f:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
c0102563:	0f 84 14 01 00 00    	je     c010267d <trap_dispatch+0x181>
            print_trapframe(tf);
c0102569:	8b 45 08             	mov    0x8(%ebp),%eax
c010256c:	89 04 24             	mov    %eax,(%esp)
c010256f:	e8 41 fc ff ff       	call   c01021b5 <print_trapframe>
            panic("handle pgfault failed. %e\n", ret);
c0102574:	8b 45 f0             	mov    -0x10(%ebp),%eax
c0102577:	89 44 24 0c          	mov    %eax,0xc(%esp)
c010257b:	c7 44 24 08 22 a4 10 	movl   $0xc010a422,0x8(%esp)
c0102582:	c0 
c0102583:	c7 44 24 04 b5 00 00 	movl   $0xb5,0x4(%esp)
c010258a:	00 
c010258b:	c7 04 24 0e a2 10 c0 	movl   $0xc010a20e,(%esp)
c0102592:	e8 69 de ff ff       	call   c0100400 <__panic>
        /* handle the timer interrupt */
        /* (1) After a timer interrupt, you should record this event using a global variable (increase it), such as ticks in kern/driver/clock.c
         * (2) Every TICK_NUM cycle, you can print some info using a funciton, such as print_ticks().
         * (3) Too Simple? Yes, I think so!
         */
        ticks ++;
c0102597:	a1 54 b0 12 c0       	mov    0xc012b054,%eax
c010259c:	40                   	inc    %eax
c010259d:	a3 54 b0 12 c0       	mov    %eax,0xc012b054
        if (ticks % TICK_NUM == 0) {
c01025a2:	8b 0d 54 b0 12 c0    	mov    0xc012b054,%ecx
c01025a8:	ba 1f 85 eb 51       	mov    $0x51eb851f,%edx
c01025ad:	89 c8                	mov    %ecx,%eax
c01025af:	f7 e2                	mul    %edx
c01025b1:	c1 ea 05             	shr    $0x5,%edx
c01025b4:	89 d0                	mov    %edx,%eax
c01025b6:	c1 e0 02             	shl    $0x2,%eax
c01025b9:	01 d0                	add    %edx,%eax
c01025bb:	8d 14 85 00 00 00 00 	lea    0x0(,%eax,4),%edx
c01025c2:	01 d0                	add    %edx,%eax
c01025c4:	c1 e0 02             	shl    $0x2,%eax
c01025c7:	29 c1                	sub    %eax,%ecx
c01025c9:	89 ca                	mov    %ecx,%edx
c01025cb:	85 d2                	test   %edx,%edx
c01025cd:	0f 85 ad 00 00 00    	jne    c0102680 <trap_dispatch+0x184>
            print_ticks();
c01025d3:	e8 61 fa ff ff       	call   c0102039 <print_ticks>
        }
        break;
c01025d8:	e9 a3 00 00 00       	jmp    c0102680 <trap_dispatch+0x184>
    case IRQ_OFFSET + IRQ_COM1:
        c = cons_getc();
c01025dd:	e8 14 f8 ff ff       	call   c0101df6 <cons_getc>
c01025e2:	88 45 f7             	mov    %al,-0x9(%ebp)
        cprintf("serial [%03d] %c\n", c, c);
c01025e5:	0f be 55 f7          	movsbl -0x9(%ebp),%edx
c01025e9:	0f be 45 f7          	movsbl -0x9(%ebp),%eax
c01025ed:	89 54 24 08          	mov    %edx,0x8(%esp)
c01025f1:	89 44 24 04          	mov    %eax,0x4(%esp)
c01025f5:	c7 04 24 3d a4 10 c0 	movl   $0xc010a43d,(%esp)
c01025fc:	e8 a8 dc ff ff       	call   c01002a9 <cprintf>
        break;
c0102601:	eb 7e                	jmp    c0102681 <trap_dispatch+0x185>
    case IRQ_OFFSET + IRQ_KBD:
        c = cons_getc();
c0102603:	e8 ee f7 ff ff       	call   c0101df6 <cons_getc>
c0102608:	88 45 f7             	mov    %al,-0x9(%ebp)
        cprintf("kbd [%03d] %c\n", c, c);
c010260b:	0f be 55 f7          	movsbl -0x9(%ebp),%edx
c010260f:	0f be 45 f7          	movsbl -0x9(%ebp),%eax
c0102613:	89 54 24 08          	mov    %edx,0x8(%esp)
c0102617:	89 44 24 04          	mov    %eax,0x4(%esp)
c010261b:	c7 04 24 4f a4 10 c0 	movl   $0xc010a44f,(%esp)
c0102622:	e8 82 dc ff ff       	call   c01002a9 <cprintf>
        break;
c0102627:	eb 58                	jmp    c0102681 <trap_dispatch+0x185>
    //LAB1 CHALLENGE 1 : YOUR CODE you should modify below codes.
    case T_SWITCH_TOU:
    case T_SWITCH_TOK:
        panic("T_SWITCH_** ??\n");
c0102629:	c7 44 24 08 5e a4 10 	movl   $0xc010a45e,0x8(%esp)
c0102630:	c0 
c0102631:	c7 44 24 04 d3 00 00 	movl   $0xd3,0x4(%esp)
c0102638:	00 
c0102639:	c7 04 24 0e a2 10 c0 	movl   $0xc010a20e,(%esp)
c0102640:	e8 bb dd ff ff       	call   c0100400 <__panic>
    case IRQ_OFFSET + IRQ_IDE2:
        /* do nothing */
        break;
    default:
        // in kernel, it must be a mistake
        if ((tf->tf_cs & 3) == 0) {
c0102645:	8b 45 08             	mov    0x8(%ebp),%eax
c0102648:	0f b7 40 3c          	movzwl 0x3c(%eax),%eax
c010264c:	83 e0 03             	and    $0x3,%eax
c010264f:	85 c0                	test   %eax,%eax
c0102651:	75 2e                	jne    c0102681 <trap_dispatch+0x185>
            print_trapframe(tf);
c0102653:	8b 45 08             	mov    0x8(%ebp),%eax
c0102656:	89 04 24             	mov    %eax,(%esp)
c0102659:	e8 57 fb ff ff       	call   c01021b5 <print_trapframe>
            panic("unexpected trap in kernel.\n");
c010265e:	c7 44 24 08 6e a4 10 	movl   $0xc010a46e,0x8(%esp)
c0102665:	c0 
c0102666:	c7 44 24 04 dd 00 00 	movl   $0xdd,0x4(%esp)
c010266d:	00 
c010266e:	c7 04 24 0e a2 10 c0 	movl   $0xc010a20e,(%esp)
c0102675:	e8 86 dd ff ff       	call   c0100400 <__panic>
        break;
c010267a:	90                   	nop
c010267b:	eb 04                	jmp    c0102681 <trap_dispatch+0x185>
        break;
c010267d:	90                   	nop
c010267e:	eb 01                	jmp    c0102681 <trap_dispatch+0x185>
        break;
c0102680:	90                   	nop
        }
    }
}
c0102681:	90                   	nop
c0102682:	c9                   	leave  
c0102683:	c3                   	ret    

c0102684 <trap>:
 * trap - handles or dispatches an exception/interrupt. if and when trap() returns,
 * the code in kern/trap/trapentry.S restores the old CPU state saved in the
 * trapframe and then uses the iret instruction to return from the exception.
 * */
void
trap(struct trapframe *tf) {
c0102684:	55                   	push   %ebp
c0102685:	89 e5                	mov    %esp,%ebp
c0102687:	83 ec 18             	sub    $0x18,%esp
    // dispatch based on what type of trap occurred
    trap_dispatch(tf);
c010268a:	8b 45 08             	mov    0x8(%ebp),%eax
c010268d:	89 04 24             	mov    %eax,(%esp)
c0102690:	e8 67 fe ff ff       	call   c01024fc <trap_dispatch>
}
c0102695:	90                   	nop
c0102696:	c9                   	leave  
c0102697:	c3                   	ret    

c0102698 <vector0>:
# handler
.text
.globl __alltraps
.globl vector0
vector0:
  pushl $0
c0102698:	6a 00                	push   $0x0
  pushl $0
c010269a:	6a 00                	push   $0x0
  jmp __alltraps
c010269c:	e9 69 0a 00 00       	jmp    c010310a <__alltraps>

c01026a1 <vector1>:
.globl vector1
vector1:
  pushl $0
c01026a1:	6a 00                	push   $0x0
  pushl $1
c01026a3:	6a 01                	push   $0x1
  jmp __alltraps
c01026a5:	e9 60 0a 00 00       	jmp    c010310a <__alltraps>

c01026aa <vector2>:
.globl vector2
vector2:
  pushl $0
c01026aa:	6a 00                	push   $0x0
  pushl $2
c01026ac:	6a 02                	push   $0x2
  jmp __alltraps
c01026ae:	e9 57 0a 00 00       	jmp    c010310a <__alltraps>

c01026b3 <vector3>:
.globl vector3
vector3:
  pushl $0
c01026b3:	6a 00                	push   $0x0
  pushl $3
c01026b5:	6a 03                	push   $0x3
  jmp __alltraps
c01026b7:	e9 4e 0a 00 00       	jmp    c010310a <__alltraps>

c01026bc <vector4>:
.globl vector4
vector4:
  pushl $0
c01026bc:	6a 00                	push   $0x0
  pushl $4
c01026be:	6a 04                	push   $0x4
  jmp __alltraps
c01026c0:	e9 45 0a 00 00       	jmp    c010310a <__alltraps>

c01026c5 <vector5>:
.globl vector5
vector5:
  pushl $0
c01026c5:	6a 00                	push   $0x0
  pushl $5
c01026c7:	6a 05                	push   $0x5
  jmp __alltraps
c01026c9:	e9 3c 0a 00 00       	jmp    c010310a <__alltraps>

c01026ce <vector6>:
.globl vector6
vector6:
  pushl $0
c01026ce:	6a 00                	push   $0x0
  pushl $6
c01026d0:	6a 06                	push   $0x6
  jmp __alltraps
c01026d2:	e9 33 0a 00 00       	jmp    c010310a <__alltraps>

c01026d7 <vector7>:
.globl vector7
vector7:
  pushl $0
c01026d7:	6a 00                	push   $0x0
  pushl $7
c01026d9:	6a 07                	push   $0x7
  jmp __alltraps
c01026db:	e9 2a 0a 00 00       	jmp    c010310a <__alltraps>

c01026e0 <vector8>:
.globl vector8
vector8:
  pushl $8
c01026e0:	6a 08                	push   $0x8
  jmp __alltraps
c01026e2:	e9 23 0a 00 00       	jmp    c010310a <__alltraps>

c01026e7 <vector9>:
.globl vector9
vector9:
  pushl $0
c01026e7:	6a 00                	push   $0x0
  pushl $9
c01026e9:	6a 09                	push   $0x9
  jmp __alltraps
c01026eb:	e9 1a 0a 00 00       	jmp    c010310a <__alltraps>

c01026f0 <vector10>:
.globl vector10
vector10:
  pushl $10
c01026f0:	6a 0a                	push   $0xa
  jmp __alltraps
c01026f2:	e9 13 0a 00 00       	jmp    c010310a <__alltraps>

c01026f7 <vector11>:
.globl vector11
vector11:
  pushl $11
c01026f7:	6a 0b                	push   $0xb
  jmp __alltraps
c01026f9:	e9 0c 0a 00 00       	jmp    c010310a <__alltraps>

c01026fe <vector12>:
.globl vector12
vector12:
  pushl $12
c01026fe:	6a 0c                	push   $0xc
  jmp __alltraps
c0102700:	e9 05 0a 00 00       	jmp    c010310a <__alltraps>

c0102705 <vector13>:
.globl vector13
vector13:
  pushl $13
c0102705:	6a 0d                	push   $0xd
  jmp __alltraps
c0102707:	e9 fe 09 00 00       	jmp    c010310a <__alltraps>

c010270c <vector14>:
.globl vector14
vector14:
  pushl $14
c010270c:	6a 0e                	push   $0xe
  jmp __alltraps
c010270e:	e9 f7 09 00 00       	jmp    c010310a <__alltraps>

c0102713 <vector15>:
.globl vector15
vector15:
  pushl $0
c0102713:	6a 00                	push   $0x0
  pushl $15
c0102715:	6a 0f                	push   $0xf
  jmp __alltraps
c0102717:	e9 ee 09 00 00       	jmp    c010310a <__alltraps>

c010271c <vector16>:
.globl vector16
vector16:
  pushl $0
c010271c:	6a 00                	push   $0x0
  pushl $16
c010271e:	6a 10                	push   $0x10
  jmp __alltraps
c0102720:	e9 e5 09 00 00       	jmp    c010310a <__alltraps>

c0102725 <vector17>:
.globl vector17
vector17:
  pushl $17
c0102725:	6a 11                	push   $0x11
  jmp __alltraps
c0102727:	e9 de 09 00 00       	jmp    c010310a <__alltraps>

c010272c <vector18>:
.globl vector18
vector18:
  pushl $0
c010272c:	6a 00                	push   $0x0
  pushl $18
c010272e:	6a 12                	push   $0x12
  jmp __alltraps
c0102730:	e9 d5 09 00 00       	jmp    c010310a <__alltraps>

c0102735 <vector19>:
.globl vector19
vector19:
  pushl $0
c0102735:	6a 00                	push   $0x0
  pushl $19
c0102737:	6a 13                	push   $0x13
  jmp __alltraps
c0102739:	e9 cc 09 00 00       	jmp    c010310a <__alltraps>

c010273e <vector20>:
.globl vector20
vector20:
  pushl $0
c010273e:	6a 00                	push   $0x0
  pushl $20
c0102740:	6a 14                	push   $0x14
  jmp __alltraps
c0102742:	e9 c3 09 00 00       	jmp    c010310a <__alltraps>

c0102747 <vector21>:
.globl vector21
vector21:
  pushl $0
c0102747:	6a 00                	push   $0x0
  pushl $21
c0102749:	6a 15                	push   $0x15
  jmp __alltraps
c010274b:	e9 ba 09 00 00       	jmp    c010310a <__alltraps>

c0102750 <vector22>:
.globl vector22
vector22:
  pushl $0
c0102750:	6a 00                	push   $0x0
  pushl $22
c0102752:	6a 16                	push   $0x16
  jmp __alltraps
c0102754:	e9 b1 09 00 00       	jmp    c010310a <__alltraps>

c0102759 <vector23>:
.globl vector23
vector23:
  pushl $0
c0102759:	6a 00                	push   $0x0
  pushl $23
c010275b:	6a 17                	push   $0x17
  jmp __alltraps
c010275d:	e9 a8 09 00 00       	jmp    c010310a <__alltraps>

c0102762 <vector24>:
.globl vector24
vector24:
  pushl $0
c0102762:	6a 00                	push   $0x0
  pushl $24
c0102764:	6a 18                	push   $0x18
  jmp __alltraps
c0102766:	e9 9f 09 00 00       	jmp    c010310a <__alltraps>

c010276b <vector25>:
.globl vector25
vector25:
  pushl $0
c010276b:	6a 00                	push   $0x0
  pushl $25
c010276d:	6a 19                	push   $0x19
  jmp __alltraps
c010276f:	e9 96 09 00 00       	jmp    c010310a <__alltraps>

c0102774 <vector26>:
.globl vector26
vector26:
  pushl $0
c0102774:	6a 00                	push   $0x0
  pushl $26
c0102776:	6a 1a                	push   $0x1a
  jmp __alltraps
c0102778:	e9 8d 09 00 00       	jmp    c010310a <__alltraps>

c010277d <vector27>:
.globl vector27
vector27:
  pushl $0
c010277d:	6a 00                	push   $0x0
  pushl $27
c010277f:	6a 1b                	push   $0x1b
  jmp __alltraps
c0102781:	e9 84 09 00 00       	jmp    c010310a <__alltraps>

c0102786 <vector28>:
.globl vector28
vector28:
  pushl $0
c0102786:	6a 00                	push   $0x0
  pushl $28
c0102788:	6a 1c                	push   $0x1c
  jmp __alltraps
c010278a:	e9 7b 09 00 00       	jmp    c010310a <__alltraps>

c010278f <vector29>:
.globl vector29
vector29:
  pushl $0
c010278f:	6a 00                	push   $0x0
  pushl $29
c0102791:	6a 1d                	push   $0x1d
  jmp __alltraps
c0102793:	e9 72 09 00 00       	jmp    c010310a <__alltraps>

c0102798 <vector30>:
.globl vector30
vector30:
  pushl $0
c0102798:	6a 00                	push   $0x0
  pushl $30
c010279a:	6a 1e                	push   $0x1e
  jmp __alltraps
c010279c:	e9 69 09 00 00       	jmp    c010310a <__alltraps>

c01027a1 <vector31>:
.globl vector31
vector31:
  pushl $0
c01027a1:	6a 00                	push   $0x0
  pushl $31
c01027a3:	6a 1f                	push   $0x1f
  jmp __alltraps
c01027a5:	e9 60 09 00 00       	jmp    c010310a <__alltraps>

c01027aa <vector32>:
.globl vector32
vector32:
  pushl $0
c01027aa:	6a 00                	push   $0x0
  pushl $32
c01027ac:	6a 20                	push   $0x20
  jmp __alltraps
c01027ae:	e9 57 09 00 00       	jmp    c010310a <__alltraps>

c01027b3 <vector33>:
.globl vector33
vector33:
  pushl $0
c01027b3:	6a 00                	push   $0x0
  pushl $33
c01027b5:	6a 21                	push   $0x21
  jmp __alltraps
c01027b7:	e9 4e 09 00 00       	jmp    c010310a <__alltraps>

c01027bc <vector34>:
.globl vector34
vector34:
  pushl $0
c01027bc:	6a 00                	push   $0x0
  pushl $34
c01027be:	6a 22                	push   $0x22
  jmp __alltraps
c01027c0:	e9 45 09 00 00       	jmp    c010310a <__alltraps>

c01027c5 <vector35>:
.globl vector35
vector35:
  pushl $0
c01027c5:	6a 00                	push   $0x0
  pushl $35
c01027c7:	6a 23                	push   $0x23
  jmp __alltraps
c01027c9:	e9 3c 09 00 00       	jmp    c010310a <__alltraps>

c01027ce <vector36>:
.globl vector36
vector36:
  pushl $0
c01027ce:	6a 00                	push   $0x0
  pushl $36
c01027d0:	6a 24                	push   $0x24
  jmp __alltraps
c01027d2:	e9 33 09 00 00       	jmp    c010310a <__alltraps>

c01027d7 <vector37>:
.globl vector37
vector37:
  pushl $0
c01027d7:	6a 00                	push   $0x0
  pushl $37
c01027d9:	6a 25                	push   $0x25
  jmp __alltraps
c01027db:	e9 2a 09 00 00       	jmp    c010310a <__alltraps>

c01027e0 <vector38>:
.globl vector38
vector38:
  pushl $0
c01027e0:	6a 00                	push   $0x0
  pushl $38
c01027e2:	6a 26                	push   $0x26
  jmp __alltraps
c01027e4:	e9 21 09 00 00       	jmp    c010310a <__alltraps>

c01027e9 <vector39>:
.globl vector39
vector39:
  pushl $0
c01027e9:	6a 00                	push   $0x0
  pushl $39
c01027eb:	6a 27                	push   $0x27
  jmp __alltraps
c01027ed:	e9 18 09 00 00       	jmp    c010310a <__alltraps>

c01027f2 <vector40>:
.globl vector40
vector40:
  pushl $0
c01027f2:	6a 00                	push   $0x0
  pushl $40
c01027f4:	6a 28                	push   $0x28
  jmp __alltraps
c01027f6:	e9 0f 09 00 00       	jmp    c010310a <__alltraps>

c01027fb <vector41>:
.globl vector41
vector41:
  pushl $0
c01027fb:	6a 00                	push   $0x0
  pushl $41
c01027fd:	6a 29                	push   $0x29
  jmp __alltraps
c01027ff:	e9 06 09 00 00       	jmp    c010310a <__alltraps>

c0102804 <vector42>:
.globl vector42
vector42:
  pushl $0
c0102804:	6a 00                	push   $0x0
  pushl $42
c0102806:	6a 2a                	push   $0x2a
  jmp __alltraps
c0102808:	e9 fd 08 00 00       	jmp    c010310a <__alltraps>

c010280d <vector43>:
.globl vector43
vector43:
  pushl $0
c010280d:	6a 00                	push   $0x0
  pushl $43
c010280f:	6a 2b                	push   $0x2b
  jmp __alltraps
c0102811:	e9 f4 08 00 00       	jmp    c010310a <__alltraps>

c0102816 <vector44>:
.globl vector44
vector44:
  pushl $0
c0102816:	6a 00                	push   $0x0
  pushl $44
c0102818:	6a 2c                	push   $0x2c
  jmp __alltraps
c010281a:	e9 eb 08 00 00       	jmp    c010310a <__alltraps>

c010281f <vector45>:
.globl vector45
vector45:
  pushl $0
c010281f:	6a 00                	push   $0x0
  pushl $45
c0102821:	6a 2d                	push   $0x2d
  jmp __alltraps
c0102823:	e9 e2 08 00 00       	jmp    c010310a <__alltraps>

c0102828 <vector46>:
.globl vector46
vector46:
  pushl $0
c0102828:	6a 00                	push   $0x0
  pushl $46
c010282a:	6a 2e                	push   $0x2e
  jmp __alltraps
c010282c:	e9 d9 08 00 00       	jmp    c010310a <__alltraps>

c0102831 <vector47>:
.globl vector47
vector47:
  pushl $0
c0102831:	6a 00                	push   $0x0
  pushl $47
c0102833:	6a 2f                	push   $0x2f
  jmp __alltraps
c0102835:	e9 d0 08 00 00       	jmp    c010310a <__alltraps>

c010283a <vector48>:
.globl vector48
vector48:
  pushl $0
c010283a:	6a 00                	push   $0x0
  pushl $48
c010283c:	6a 30                	push   $0x30
  jmp __alltraps
c010283e:	e9 c7 08 00 00       	jmp    c010310a <__alltraps>

c0102843 <vector49>:
.globl vector49
vector49:
  pushl $0
c0102843:	6a 00                	push   $0x0
  pushl $49
c0102845:	6a 31                	push   $0x31
  jmp __alltraps
c0102847:	e9 be 08 00 00       	jmp    c010310a <__alltraps>

c010284c <vector50>:
.globl vector50
vector50:
  pushl $0
c010284c:	6a 00                	push   $0x0
  pushl $50
c010284e:	6a 32                	push   $0x32
  jmp __alltraps
c0102850:	e9 b5 08 00 00       	jmp    c010310a <__alltraps>

c0102855 <vector51>:
.globl vector51
vector51:
  pushl $0
c0102855:	6a 00                	push   $0x0
  pushl $51
c0102857:	6a 33                	push   $0x33
  jmp __alltraps
c0102859:	e9 ac 08 00 00       	jmp    c010310a <__alltraps>

c010285e <vector52>:
.globl vector52
vector52:
  pushl $0
c010285e:	6a 00                	push   $0x0
  pushl $52
c0102860:	6a 34                	push   $0x34
  jmp __alltraps
c0102862:	e9 a3 08 00 00       	jmp    c010310a <__alltraps>

c0102867 <vector53>:
.globl vector53
vector53:
  pushl $0
c0102867:	6a 00                	push   $0x0
  pushl $53
c0102869:	6a 35                	push   $0x35
  jmp __alltraps
c010286b:	e9 9a 08 00 00       	jmp    c010310a <__alltraps>

c0102870 <vector54>:
.globl vector54
vector54:
  pushl $0
c0102870:	6a 00                	push   $0x0
  pushl $54
c0102872:	6a 36                	push   $0x36
  jmp __alltraps
c0102874:	e9 91 08 00 00       	jmp    c010310a <__alltraps>

c0102879 <vector55>:
.globl vector55
vector55:
  pushl $0
c0102879:	6a 00                	push   $0x0
  pushl $55
c010287b:	6a 37                	push   $0x37
  jmp __alltraps
c010287d:	e9 88 08 00 00       	jmp    c010310a <__alltraps>

c0102882 <vector56>:
.globl vector56
vector56:
  pushl $0
c0102882:	6a 00                	push   $0x0
  pushl $56
c0102884:	6a 38                	push   $0x38
  jmp __alltraps
c0102886:	e9 7f 08 00 00       	jmp    c010310a <__alltraps>

c010288b <vector57>:
.globl vector57
vector57:
  pushl $0
c010288b:	6a 00                	push   $0x0
  pushl $57
c010288d:	6a 39                	push   $0x39
  jmp __alltraps
c010288f:	e9 76 08 00 00       	jmp    c010310a <__alltraps>

c0102894 <vector58>:
.globl vector58
vector58:
  pushl $0
c0102894:	6a 00                	push   $0x0
  pushl $58
c0102896:	6a 3a                	push   $0x3a
  jmp __alltraps
c0102898:	e9 6d 08 00 00       	jmp    c010310a <__alltraps>

c010289d <vector59>:
.globl vector59
vector59:
  pushl $0
c010289d:	6a 00                	push   $0x0
  pushl $59
c010289f:	6a 3b                	push   $0x3b
  jmp __alltraps
c01028a1:	e9 64 08 00 00       	jmp    c010310a <__alltraps>

c01028a6 <vector60>:
.globl vector60
vector60:
  pushl $0
c01028a6:	6a 00                	push   $0x0
  pushl $60
c01028a8:	6a 3c                	push   $0x3c
  jmp __alltraps
c01028aa:	e9 5b 08 00 00       	jmp    c010310a <__alltraps>

c01028af <vector61>:
.globl vector61
vector61:
  pushl $0
c01028af:	6a 00                	push   $0x0
  pushl $61
c01028b1:	6a 3d                	push   $0x3d
  jmp __alltraps
c01028b3:	e9 52 08 00 00       	jmp    c010310a <__alltraps>

c01028b8 <vector62>:
.globl vector62
vector62:
  pushl $0
c01028b8:	6a 00                	push   $0x0
  pushl $62
c01028ba:	6a 3e                	push   $0x3e
  jmp __alltraps
c01028bc:	e9 49 08 00 00       	jmp    c010310a <__alltraps>

c01028c1 <vector63>:
.globl vector63
vector63:
  pushl $0
c01028c1:	6a 00                	push   $0x0
  pushl $63
c01028c3:	6a 3f                	push   $0x3f
  jmp __alltraps
c01028c5:	e9 40 08 00 00       	jmp    c010310a <__alltraps>

c01028ca <vector64>:
.globl vector64
vector64:
  pushl $0
c01028ca:	6a 00                	push   $0x0
  pushl $64
c01028cc:	6a 40                	push   $0x40
  jmp __alltraps
c01028ce:	e9 37 08 00 00       	jmp    c010310a <__alltraps>

c01028d3 <vector65>:
.globl vector65
vector65:
  pushl $0
c01028d3:	6a 00                	push   $0x0
  pushl $65
c01028d5:	6a 41                	push   $0x41
  jmp __alltraps
c01028d7:	e9 2e 08 00 00       	jmp    c010310a <__alltraps>

c01028dc <vector66>:
.globl vector66
vector66:
  pushl $0
c01028dc:	6a 00                	push   $0x0
  pushl $66
c01028de:	6a 42                	push   $0x42
  jmp __alltraps
c01028e0:	e9 25 08 00 00       	jmp    c010310a <__alltraps>

c01028e5 <vector67>:
.globl vector67
vector67:
  pushl $0
c01028e5:	6a 00                	push   $0x0
  pushl $67
c01028e7:	6a 43                	push   $0x43
  jmp __alltraps
c01028e9:	e9 1c 08 00 00       	jmp    c010310a <__alltraps>

c01028ee <vector68>:
.globl vector68
vector68:
  pushl $0
c01028ee:	6a 00                	push   $0x0
  pushl $68
c01028f0:	6a 44                	push   $0x44
  jmp __alltraps
c01028f2:	e9 13 08 00 00       	jmp    c010310a <__alltraps>

c01028f7 <vector69>:
.globl vector69
vector69:
  pushl $0
c01028f7:	6a 00                	push   $0x0
  pushl $69
c01028f9:	6a 45                	push   $0x45
  jmp __alltraps
c01028fb:	e9 0a 08 00 00       	jmp    c010310a <__alltraps>

c0102900 <vector70>:
.globl vector70
vector70:
  pushl $0
c0102900:	6a 00                	push   $0x0
  pushl $70
c0102902:	6a 46                	push   $0x46
  jmp __alltraps
c0102904:	e9 01 08 00 00       	jmp    c010310a <__alltraps>

c0102909 <vector71>:
.globl vector71
vector71:
  pushl $0
c0102909:	6a 00                	push   $0x0
  pushl $71
c010290b:	6a 47                	push   $0x47
  jmp __alltraps
c010290d:	e9 f8 07 00 00       	jmp    c010310a <__alltraps>

c0102912 <vector72>:
.globl vector72
vector72:
  pushl $0
c0102912:	6a 00                	push   $0x0
  pushl $72
c0102914:	6a 48                	push   $0x48
  jmp __alltraps
c0102916:	e9 ef 07 00 00       	jmp    c010310a <__alltraps>

c010291b <vector73>:
.globl vector73
vector73:
  pushl $0
c010291b:	6a 00                	push   $0x0
  pushl $73
c010291d:	6a 49                	push   $0x49
  jmp __alltraps
c010291f:	e9 e6 07 00 00       	jmp    c010310a <__alltraps>

c0102924 <vector74>:
.globl vector74
vector74:
  pushl $0
c0102924:	6a 00                	push   $0x0
  pushl $74
c0102926:	6a 4a                	push   $0x4a
  jmp __alltraps
c0102928:	e9 dd 07 00 00       	jmp    c010310a <__alltraps>

c010292d <vector75>:
.globl vector75
vector75:
  pushl $0
c010292d:	6a 00                	push   $0x0
  pushl $75
c010292f:	6a 4b                	push   $0x4b
  jmp __alltraps
c0102931:	e9 d4 07 00 00       	jmp    c010310a <__alltraps>

c0102936 <vector76>:
.globl vector76
vector76:
  pushl $0
c0102936:	6a 00                	push   $0x0
  pushl $76
c0102938:	6a 4c                	push   $0x4c
  jmp __alltraps
c010293a:	e9 cb 07 00 00       	jmp    c010310a <__alltraps>

c010293f <vector77>:
.globl vector77
vector77:
  pushl $0
c010293f:	6a 00                	push   $0x0
  pushl $77
c0102941:	6a 4d                	push   $0x4d
  jmp __alltraps
c0102943:	e9 c2 07 00 00       	jmp    c010310a <__alltraps>

c0102948 <vector78>:
.globl vector78
vector78:
  pushl $0
c0102948:	6a 00                	push   $0x0
  pushl $78
c010294a:	6a 4e                	push   $0x4e
  jmp __alltraps
c010294c:	e9 b9 07 00 00       	jmp    c010310a <__alltraps>

c0102951 <vector79>:
.globl vector79
vector79:
  pushl $0
c0102951:	6a 00                	push   $0x0
  pushl $79
c0102953:	6a 4f                	push   $0x4f
  jmp __alltraps
c0102955:	e9 b0 07 00 00       	jmp    c010310a <__alltraps>

c010295a <vector80>:
.globl vector80
vector80:
  pushl $0
c010295a:	6a 00                	push   $0x0
  pushl $80
c010295c:	6a 50                	push   $0x50
  jmp __alltraps
c010295e:	e9 a7 07 00 00       	jmp    c010310a <__alltraps>

c0102963 <vector81>:
.globl vector81
vector81:
  pushl $0
c0102963:	6a 00                	push   $0x0
  pushl $81
c0102965:	6a 51                	push   $0x51
  jmp __alltraps
c0102967:	e9 9e 07 00 00       	jmp    c010310a <__alltraps>

c010296c <vector82>:
.globl vector82
vector82:
  pushl $0
c010296c:	6a 00                	push   $0x0
  pushl $82
c010296e:	6a 52                	push   $0x52
  jmp __alltraps
c0102970:	e9 95 07 00 00       	jmp    c010310a <__alltraps>

c0102975 <vector83>:
.globl vector83
vector83:
  pushl $0
c0102975:	6a 00                	push   $0x0
  pushl $83
c0102977:	6a 53                	push   $0x53
  jmp __alltraps
c0102979:	e9 8c 07 00 00       	jmp    c010310a <__alltraps>

c010297e <vector84>:
.globl vector84
vector84:
  pushl $0
c010297e:	6a 00                	push   $0x0
  pushl $84
c0102980:	6a 54                	push   $0x54
  jmp __alltraps
c0102982:	e9 83 07 00 00       	jmp    c010310a <__alltraps>

c0102987 <vector85>:
.globl vector85
vector85:
  pushl $0
c0102987:	6a 00                	push   $0x0
  pushl $85
c0102989:	6a 55                	push   $0x55
  jmp __alltraps
c010298b:	e9 7a 07 00 00       	jmp    c010310a <__alltraps>

c0102990 <vector86>:
.globl vector86
vector86:
  pushl $0
c0102990:	6a 00                	push   $0x0
  pushl $86
c0102992:	6a 56                	push   $0x56
  jmp __alltraps
c0102994:	e9 71 07 00 00       	jmp    c010310a <__alltraps>

c0102999 <vector87>:
.globl vector87
vector87:
  pushl $0
c0102999:	6a 00                	push   $0x0
  pushl $87
c010299b:	6a 57                	push   $0x57
  jmp __alltraps
c010299d:	e9 68 07 00 00       	jmp    c010310a <__alltraps>

c01029a2 <vector88>:
.globl vector88
vector88:
  pushl $0
c01029a2:	6a 00                	push   $0x0
  pushl $88
c01029a4:	6a 58                	push   $0x58
  jmp __alltraps
c01029a6:	e9 5f 07 00 00       	jmp    c010310a <__alltraps>

c01029ab <vector89>:
.globl vector89
vector89:
  pushl $0
c01029ab:	6a 00                	push   $0x0
  pushl $89
c01029ad:	6a 59                	push   $0x59
  jmp __alltraps
c01029af:	e9 56 07 00 00       	jmp    c010310a <__alltraps>

c01029b4 <vector90>:
.globl vector90
vector90:
  pushl $0
c01029b4:	6a 00                	push   $0x0
  pushl $90
c01029b6:	6a 5a                	push   $0x5a
  jmp __alltraps
c01029b8:	e9 4d 07 00 00       	jmp    c010310a <__alltraps>

c01029bd <vector91>:
.globl vector91
vector91:
  pushl $0
c01029bd:	6a 00                	push   $0x0
  pushl $91
c01029bf:	6a 5b                	push   $0x5b
  jmp __alltraps
c01029c1:	e9 44 07 00 00       	jmp    c010310a <__alltraps>

c01029c6 <vector92>:
.globl vector92
vector92:
  pushl $0
c01029c6:	6a 00                	push   $0x0
  pushl $92
c01029c8:	6a 5c                	push   $0x5c
  jmp __alltraps
c01029ca:	e9 3b 07 00 00       	jmp    c010310a <__alltraps>

c01029cf <vector93>:
.globl vector93
vector93:
  pushl $0
c01029cf:	6a 00                	push   $0x0
  pushl $93
c01029d1:	6a 5d                	push   $0x5d
  jmp __alltraps
c01029d3:	e9 32 07 00 00       	jmp    c010310a <__alltraps>

c01029d8 <vector94>:
.globl vector94
vector94:
  pushl $0
c01029d8:	6a 00                	push   $0x0
  pushl $94
c01029da:	6a 5e                	push   $0x5e
  jmp __alltraps
c01029dc:	e9 29 07 00 00       	jmp    c010310a <__alltraps>

c01029e1 <vector95>:
.globl vector95
vector95:
  pushl $0
c01029e1:	6a 00                	push   $0x0
  pushl $95
c01029e3:	6a 5f                	push   $0x5f
  jmp __alltraps
c01029e5:	e9 20 07 00 00       	jmp    c010310a <__alltraps>

c01029ea <vector96>:
.globl vector96
vector96:
  pushl $0
c01029ea:	6a 00                	push   $0x0
  pushl $96
c01029ec:	6a 60                	push   $0x60
  jmp __alltraps
c01029ee:	e9 17 07 00 00       	jmp    c010310a <__alltraps>

c01029f3 <vector97>:
.globl vector97
vector97:
  pushl $0
c01029f3:	6a 00                	push   $0x0
  pushl $97
c01029f5:	6a 61                	push   $0x61
  jmp __alltraps
c01029f7:	e9 0e 07 00 00       	jmp    c010310a <__alltraps>

c01029fc <vector98>:
.globl vector98
vector98:
  pushl $0
c01029fc:	6a 00                	push   $0x0
  pushl $98
c01029fe:	6a 62                	push   $0x62
  jmp __alltraps
c0102a00:	e9 05 07 00 00       	jmp    c010310a <__alltraps>

c0102a05 <vector99>:
.globl vector99
vector99:
  pushl $0
c0102a05:	6a 00                	push   $0x0
  pushl $99
c0102a07:	6a 63                	push   $0x63
  jmp __alltraps
c0102a09:	e9 fc 06 00 00       	jmp    c010310a <__alltraps>

c0102a0e <vector100>:
.globl vector100
vector100:
  pushl $0
c0102a0e:	6a 00                	push   $0x0
  pushl $100
c0102a10:	6a 64                	push   $0x64
  jmp __alltraps
c0102a12:	e9 f3 06 00 00       	jmp    c010310a <__alltraps>

c0102a17 <vector101>:
.globl vector101
vector101:
  pushl $0
c0102a17:	6a 00                	push   $0x0
  pushl $101
c0102a19:	6a 65                	push   $0x65
  jmp __alltraps
c0102a1b:	e9 ea 06 00 00       	jmp    c010310a <__alltraps>

c0102a20 <vector102>:
.globl vector102
vector102:
  pushl $0
c0102a20:	6a 00                	push   $0x0
  pushl $102
c0102a22:	6a 66                	push   $0x66
  jmp __alltraps
c0102a24:	e9 e1 06 00 00       	jmp    c010310a <__alltraps>

c0102a29 <vector103>:
.globl vector103
vector103:
  pushl $0
c0102a29:	6a 00                	push   $0x0
  pushl $103
c0102a2b:	6a 67                	push   $0x67
  jmp __alltraps
c0102a2d:	e9 d8 06 00 00       	jmp    c010310a <__alltraps>

c0102a32 <vector104>:
.globl vector104
vector104:
  pushl $0
c0102a32:	6a 00                	push   $0x0
  pushl $104
c0102a34:	6a 68                	push   $0x68
  jmp __alltraps
c0102a36:	e9 cf 06 00 00       	jmp    c010310a <__alltraps>

c0102a3b <vector105>:
.globl vector105
vector105:
  pushl $0
c0102a3b:	6a 00                	push   $0x0
  pushl $105
c0102a3d:	6a 69                	push   $0x69
  jmp __alltraps
c0102a3f:	e9 c6 06 00 00       	jmp    c010310a <__alltraps>

c0102a44 <vector106>:
.globl vector106
vector106:
  pushl $0
c0102a44:	6a 00                	push   $0x0
  pushl $106
c0102a46:	6a 6a                	push   $0x6a
  jmp __alltraps
c0102a48:	e9 bd 06 00 00       	jmp    c010310a <__alltraps>

c0102a4d <vector107>:
.globl vector107
vector107:
  pushl $0
c0102a4d:	6a 00                	push   $0x0
  pushl $107
c0102a4f:	6a 6b                	push   $0x6b
  jmp __alltraps
c0102a51:	e9 b4 06 00 00       	jmp    c010310a <__alltraps>

c0102a56 <vector108>:
.globl vector108
vector108:
  pushl $0
c0102a56:	6a 00                	push   $0x0
  pushl $108
c0102a58:	6a 6c                	push   $0x6c
  jmp __alltraps
c0102a5a:	e9 ab 06 00 00       	jmp    c010310a <__alltraps>

c0102a5f <vector109>:
.globl vector109
vector109:
  pushl $0
c0102a5f:	6a 00                	push   $0x0
  pushl $109
c0102a61:	6a 6d                	push   $0x6d
  jmp __alltraps
c0102a63:	e9 a2 06 00 00       	jmp    c010310a <__alltraps>

c0102a68 <vector110>:
.globl vector110
vector110:
  pushl $0
c0102a68:	6a 00                	push   $0x0
  pushl $110
c0102a6a:	6a 6e                	push   $0x6e
  jmp __alltraps
c0102a6c:	e9 99 06 00 00       	jmp    c010310a <__alltraps>

c0102a71 <vector111>:
.globl vector111
vector111:
  pushl $0
c0102a71:	6a 00                	push   $0x0
  pushl $111
c0102a73:	6a 6f                	push   $0x6f
  jmp __alltraps
c0102a75:	e9 90 06 00 00       	jmp    c010310a <__alltraps>

c0102a7a <vector112>:
.globl vector112
vector112:
  pushl $0
c0102a7a:	6a 00                	push   $0x0
  pushl $112
c0102a7c:	6a 70                	push   $0x70
  jmp __alltraps
c0102a7e:	e9 87 06 00 00       	jmp    c010310a <__alltraps>

c0102a83 <vector113>:
.globl vector113
vector113:
  pushl $0
c0102a83:	6a 00                	push   $0x0
  pushl $113
c0102a85:	6a 71                	push   $0x71
  jmp __alltraps
c0102a87:	e9 7e 06 00 00       	jmp    c010310a <__alltraps>

c0102a8c <vector114>:
.globl vector114
vector114:
  pushl $0
c0102a8c:	6a 00                	push   $0x0
  pushl $114
c0102a8e:	6a 72                	push   $0x72
  jmp __alltraps
c0102a90:	e9 75 06 00 00       	jmp    c010310a <__alltraps>

c0102a95 <vector115>:
.globl vector115
vector115:
  pushl $0
c0102a95:	6a 00                	push   $0x0
  pushl $115
c0102a97:	6a 73                	push   $0x73
  jmp __alltraps
c0102a99:	e9 6c 06 00 00       	jmp    c010310a <__alltraps>

c0102a9e <vector116>:
.globl vector116
vector116:
  pushl $0
c0102a9e:	6a 00                	push   $0x0
  pushl $116
c0102aa0:	6a 74                	push   $0x74
  jmp __alltraps
c0102aa2:	e9 63 06 00 00       	jmp    c010310a <__alltraps>

c0102aa7 <vector117>:
.globl vector117
vector117:
  pushl $0
c0102aa7:	6a 00                	push   $0x0
  pushl $117
c0102aa9:	6a 75                	push   $0x75
  jmp __alltraps
c0102aab:	e9 5a 06 00 00       	jmp    c010310a <__alltraps>

c0102ab0 <vector118>:
.globl vector118
vector118:
  pushl $0
c0102ab0:	6a 00                	push   $0x0
  pushl $118
c0102ab2:	6a 76                	push   $0x76
  jmp __alltraps
c0102ab4:	e9 51 06 00 00       	jmp    c010310a <__alltraps>

c0102ab9 <vector119>:
.globl vector119
vector119:
  pushl $0
c0102ab9:	6a 00                	push   $0x0
  pushl $119
c0102abb:	6a 77                	push   $0x77
  jmp __alltraps
c0102abd:	e9 48 06 00 00       	jmp    c010310a <__alltraps>

c0102ac2 <vector120>:
.globl vector120
vector120:
  pushl $0
c0102ac2:	6a 00                	push   $0x0
  pushl $120
c0102ac4:	6a 78                	push   $0x78
  jmp __alltraps
c0102ac6:	e9 3f 06 00 00       	jmp    c010310a <__alltraps>

c0102acb <vector121>:
.globl vector121
vector121:
  pushl $0
c0102acb:	6a 00                	push   $0x0
  pushl $121
c0102acd:	6a 79                	push   $0x79
  jmp __alltraps
c0102acf:	e9 36 06 00 00       	jmp    c010310a <__alltraps>

c0102ad4 <vector122>:
.globl vector122
vector122:
  pushl $0
c0102ad4:	6a 00                	push   $0x0
  pushl $122
c0102ad6:	6a 7a                	push   $0x7a
  jmp __alltraps
c0102ad8:	e9 2d 06 00 00       	jmp    c010310a <__alltraps>

c0102add <vector123>:
.globl vector123
vector123:
  pushl $0
c0102add:	6a 00                	push   $0x0
  pushl $123
c0102adf:	6a 7b                	push   $0x7b
  jmp __alltraps
c0102ae1:	e9 24 06 00 00       	jmp    c010310a <__alltraps>

c0102ae6 <vector124>:
.globl vector124
vector124:
  pushl $0
c0102ae6:	6a 00                	push   $0x0
  pushl $124
c0102ae8:	6a 7c                	push   $0x7c
  jmp __alltraps
c0102aea:	e9 1b 06 00 00       	jmp    c010310a <__alltraps>

c0102aef <vector125>:
.globl vector125
vector125:
  pushl $0
c0102aef:	6a 00                	push   $0x0
  pushl $125
c0102af1:	6a 7d                	push   $0x7d
  jmp __alltraps
c0102af3:	e9 12 06 00 00       	jmp    c010310a <__alltraps>

c0102af8 <vector126>:
.globl vector126
vector126:
  pushl $0
c0102af8:	6a 00                	push   $0x0
  pushl $126
c0102afa:	6a 7e                	push   $0x7e
  jmp __alltraps
c0102afc:	e9 09 06 00 00       	jmp    c010310a <__alltraps>

c0102b01 <vector127>:
.globl vector127
vector127:
  pushl $0
c0102b01:	6a 00                	push   $0x0
  pushl $127
c0102b03:	6a 7f                	push   $0x7f
  jmp __alltraps
c0102b05:	e9 00 06 00 00       	jmp    c010310a <__alltraps>

c0102b0a <vector128>:
.globl vector128
vector128:
  pushl $0
c0102b0a:	6a 00                	push   $0x0
  pushl $128
c0102b0c:	68 80 00 00 00       	push   $0x80
  jmp __alltraps
c0102b11:	e9 f4 05 00 00       	jmp    c010310a <__alltraps>

c0102b16 <vector129>:
.globl vector129
vector129:
  pushl $0
c0102b16:	6a 00                	push   $0x0
  pushl $129
c0102b18:	68 81 00 00 00       	push   $0x81
  jmp __alltraps
c0102b1d:	e9 e8 05 00 00       	jmp    c010310a <__alltraps>

c0102b22 <vector130>:
.globl vector130
vector130:
  pushl $0
c0102b22:	6a 00                	push   $0x0
  pushl $130
c0102b24:	68 82 00 00 00       	push   $0x82
  jmp __alltraps
c0102b29:	e9 dc 05 00 00       	jmp    c010310a <__alltraps>

c0102b2e <vector131>:
.globl vector131
vector131:
  pushl $0
c0102b2e:	6a 00                	push   $0x0
  pushl $131
c0102b30:	68 83 00 00 00       	push   $0x83
  jmp __alltraps
c0102b35:	e9 d0 05 00 00       	jmp    c010310a <__alltraps>

c0102b3a <vector132>:
.globl vector132
vector132:
  pushl $0
c0102b3a:	6a 00                	push   $0x0
  pushl $132
c0102b3c:	68 84 00 00 00       	push   $0x84
  jmp __alltraps
c0102b41:	e9 c4 05 00 00       	jmp    c010310a <__alltraps>

c0102b46 <vector133>:
.globl vector133
vector133:
  pushl $0
c0102b46:	6a 00                	push   $0x0
  pushl $133
c0102b48:	68 85 00 00 00       	push   $0x85
  jmp __alltraps
c0102b4d:	e9 b8 05 00 00       	jmp    c010310a <__alltraps>

c0102b52 <vector134>:
.globl vector134
vector134:
  pushl $0
c0102b52:	6a 00                	push   $0x0
  pushl $134
c0102b54:	68 86 00 00 00       	push   $0x86
  jmp __alltraps
c0102b59:	e9 ac 05 00 00       	jmp    c010310a <__alltraps>

c0102b5e <vector135>:
.globl vector135
vector135:
  pushl $0
c0102b5e:	6a 00                	push   $0x0
  pushl $135
c0102b60:	68 87 00 00 00       	push   $0x87
  jmp __alltraps
c0102b65:	e9 a0 05 00 00       	jmp    c010310a <__alltraps>

c0102b6a <vector136>:
.globl vector136
vector136:
  pushl $0
c0102b6a:	6a 00                	push   $0x0
  pushl $136
c0102b6c:	68 88 00 00 00       	push   $0x88
  jmp __alltraps
c0102b71:	e9 94 05 00 00       	jmp    c010310a <__alltraps>

c0102b76 <vector137>:
.globl vector137
vector137:
  pushl $0
c0102b76:	6a 00                	push   $0x0
  pushl $137
c0102b78:	68 89 00 00 00       	push   $0x89
  jmp __alltraps
c0102b7d:	e9 88 05 00 00       	jmp    c010310a <__alltraps>

c0102b82 <vector138>:
.globl vector138
vector138:
  pushl $0
c0102b82:	6a 00                	push   $0x0
  pushl $138
c0102b84:	68 8a 00 00 00       	push   $0x8a
  jmp __alltraps
c0102b89:	e9 7c 05 00 00       	jmp    c010310a <__alltraps>

c0102b8e <vector139>:
.globl vector139
vector139:
  pushl $0
c0102b8e:	6a 00                	push   $0x0
  pushl $139
c0102b90:	68 8b 00 00 00       	push   $0x8b
  jmp __alltraps
c0102b95:	e9 70 05 00 00       	jmp    c010310a <__alltraps>

c0102b9a <vector140>:
.globl vector140
vector140:
  pushl $0
c0102b9a:	6a 00                	push   $0x0
  pushl $140
c0102b9c:	68 8c 00 00 00       	push   $0x8c
  jmp __alltraps
c0102ba1:	e9 64 05 00 00       	jmp    c010310a <__alltraps>

c0102ba6 <vector141>:
.globl vector141
vector141:
  pushl $0
c0102ba6:	6a 00                	push   $0x0
  pushl $141
c0102ba8:	68 8d 00 00 00       	push   $0x8d
  jmp __alltraps
c0102bad:	e9 58 05 00 00       	jmp    c010310a <__alltraps>

c0102bb2 <vector142>:
.globl vector142
vector142:
  pushl $0
c0102bb2:	6a 00                	push   $0x0
  pushl $142
c0102bb4:	68 8e 00 00 00       	push   $0x8e
  jmp __alltraps
c0102bb9:	e9 4c 05 00 00       	jmp    c010310a <__alltraps>

c0102bbe <vector143>:
.globl vector143
vector143:
  pushl $0
c0102bbe:	6a 00                	push   $0x0
  pushl $143
c0102bc0:	68 8f 00 00 00       	push   $0x8f
  jmp __alltraps
c0102bc5:	e9 40 05 00 00       	jmp    c010310a <__alltraps>

c0102bca <vector144>:
.globl vector144
vector144:
  pushl $0
c0102bca:	6a 00                	push   $0x0
  pushl $144
c0102bcc:	68 90 00 00 00       	push   $0x90
  jmp __alltraps
c0102bd1:	e9 34 05 00 00       	jmp    c010310a <__alltraps>

c0102bd6 <vector145>:
.globl vector145
vector145:
  pushl $0
c0102bd6:	6a 00                	push   $0x0
  pushl $145
c0102bd8:	68 91 00 00 00       	push   $0x91
  jmp __alltraps
c0102bdd:	e9 28 05 00 00       	jmp    c010310a <__alltraps>

c0102be2 <vector146>:
.globl vector146
vector146:
  pushl $0
c0102be2:	6a 00                	push   $0x0
  pushl $146
c0102be4:	68 92 00 00 00       	push   $0x92
  jmp __alltraps
c0102be9:	e9 1c 05 00 00       	jmp    c010310a <__alltraps>

c0102bee <vector147>:
.globl vector147
vector147:
  pushl $0
c0102bee:	6a 00                	push   $0x0
  pushl $147
c0102bf0:	68 93 00 00 00       	push   $0x93
  jmp __alltraps
c0102bf5:	e9 10 05 00 00       	jmp    c010310a <__alltraps>

c0102bfa <vector148>:
.globl vector148
vector148:
  pushl $0
c0102bfa:	6a 00                	push   $0x0
  pushl $148
c0102bfc:	68 94 00 00 00       	push   $0x94
  jmp __alltraps
c0102c01:	e9 04 05 00 00       	jmp    c010310a <__alltraps>

c0102c06 <vector149>:
.globl vector149
vector149:
  pushl $0
c0102c06:	6a 00                	push   $0x0
  pushl $149
c0102c08:	68 95 00 00 00       	push   $0x95
  jmp __alltraps
c0102c0d:	e9 f8 04 00 00       	jmp    c010310a <__alltraps>

c0102c12 <vector150>:
.globl vector150
vector150:
  pushl $0
c0102c12:	6a 00                	push   $0x0
  pushl $150
c0102c14:	68 96 00 00 00       	push   $0x96
  jmp __alltraps
c0102c19:	e9 ec 04 00 00       	jmp    c010310a <__alltraps>

c0102c1e <vector151>:
.globl vector151
vector151:
  pushl $0
c0102c1e:	6a 00                	push   $0x0
  pushl $151
c0102c20:	68 97 00 00 00       	push   $0x97
  jmp __alltraps
c0102c25:	e9 e0 04 00 00       	jmp    c010310a <__alltraps>

c0102c2a <vector152>:
.globl vector152
vector152:
  pushl $0
c0102c2a:	6a 00                	push   $0x0
  pushl $152
c0102c2c:	68 98 00 00 00       	push   $0x98
  jmp __alltraps
c0102c31:	e9 d4 04 00 00       	jmp    c010310a <__alltraps>

c0102c36 <vector153>:
.globl vector153
vector153:
  pushl $0
c0102c36:	6a 00                	push   $0x0
  pushl $153
c0102c38:	68 99 00 00 00       	push   $0x99
  jmp __alltraps
c0102c3d:	e9 c8 04 00 00       	jmp    c010310a <__alltraps>

c0102c42 <vector154>:
.globl vector154
vector154:
  pushl $0
c0102c42:	6a 00                	push   $0x0
  pushl $154
c0102c44:	68 9a 00 00 00       	push   $0x9a
  jmp __alltraps
c0102c49:	e9 bc 04 00 00       	jmp    c010310a <__alltraps>

c0102c4e <vector155>:
.globl vector155
vector155:
  pushl $0
c0102c4e:	6a 00                	push   $0x0
  pushl $155
c0102c50:	68 9b 00 00 00       	push   $0x9b
  jmp __alltraps
c0102c55:	e9 b0 04 00 00       	jmp    c010310a <__alltraps>

c0102c5a <vector156>:
.globl vector156
vector156:
  pushl $0
c0102c5a:	6a 00                	push   $0x0
  pushl $156
c0102c5c:	68 9c 00 00 00       	push   $0x9c
  jmp __alltraps
c0102c61:	e9 a4 04 00 00       	jmp    c010310a <__alltraps>

c0102c66 <vector157>:
.globl vector157
vector157:
  pushl $0
c0102c66:	6a 00                	push   $0x0
  pushl $157
c0102c68:	68 9d 00 00 00       	push   $0x9d
  jmp __alltraps
c0102c6d:	e9 98 04 00 00       	jmp    c010310a <__alltraps>

c0102c72 <vector158>:
.globl vector158
vector158:
  pushl $0
c0102c72:	6a 00                	push   $0x0
  pushl $158
c0102c74:	68 9e 00 00 00       	push   $0x9e
  jmp __alltraps
c0102c79:	e9 8c 04 00 00       	jmp    c010310a <__alltraps>

c0102c7e <vector159>:
.globl vector159
vector159:
  pushl $0
c0102c7e:	6a 00                	push   $0x0
  pushl $159
c0102c80:	68 9f 00 00 00       	push   $0x9f
  jmp __alltraps
c0102c85:	e9 80 04 00 00       	jmp    c010310a <__alltraps>

c0102c8a <vector160>:
.globl vector160
vector160:
  pushl $0
c0102c8a:	6a 00                	push   $0x0
  pushl $160
c0102c8c:	68 a0 00 00 00       	push   $0xa0
  jmp __alltraps
c0102c91:	e9 74 04 00 00       	jmp    c010310a <__alltraps>

c0102c96 <vector161>:
.globl vector161
vector161:
  pushl $0
c0102c96:	6a 00                	push   $0x0
  pushl $161
c0102c98:	68 a1 00 00 00       	push   $0xa1
  jmp __alltraps
c0102c9d:	e9 68 04 00 00       	jmp    c010310a <__alltraps>

c0102ca2 <vector162>:
.globl vector162
vector162:
  pushl $0
c0102ca2:	6a 00                	push   $0x0
  pushl $162
c0102ca4:	68 a2 00 00 00       	push   $0xa2
  jmp __alltraps
c0102ca9:	e9 5c 04 00 00       	jmp    c010310a <__alltraps>

c0102cae <vector163>:
.globl vector163
vector163:
  pushl $0
c0102cae:	6a 00                	push   $0x0
  pushl $163
c0102cb0:	68 a3 00 00 00       	push   $0xa3
  jmp __alltraps
c0102cb5:	e9 50 04 00 00       	jmp    c010310a <__alltraps>

c0102cba <vector164>:
.globl vector164
vector164:
  pushl $0
c0102cba:	6a 00                	push   $0x0
  pushl $164
c0102cbc:	68 a4 00 00 00       	push   $0xa4
  jmp __alltraps
c0102cc1:	e9 44 04 00 00       	jmp    c010310a <__alltraps>

c0102cc6 <vector165>:
.globl vector165
vector165:
  pushl $0
c0102cc6:	6a 00                	push   $0x0
  pushl $165
c0102cc8:	68 a5 00 00 00       	push   $0xa5
  jmp __alltraps
c0102ccd:	e9 38 04 00 00       	jmp    c010310a <__alltraps>

c0102cd2 <vector166>:
.globl vector166
vector166:
  pushl $0
c0102cd2:	6a 00                	push   $0x0
  pushl $166
c0102cd4:	68 a6 00 00 00       	push   $0xa6
  jmp __alltraps
c0102cd9:	e9 2c 04 00 00       	jmp    c010310a <__alltraps>

c0102cde <vector167>:
.globl vector167
vector167:
  pushl $0
c0102cde:	6a 00                	push   $0x0
  pushl $167
c0102ce0:	68 a7 00 00 00       	push   $0xa7
  jmp __alltraps
c0102ce5:	e9 20 04 00 00       	jmp    c010310a <__alltraps>

c0102cea <vector168>:
.globl vector168
vector168:
  pushl $0
c0102cea:	6a 00                	push   $0x0
  pushl $168
c0102cec:	68 a8 00 00 00       	push   $0xa8
  jmp __alltraps
c0102cf1:	e9 14 04 00 00       	jmp    c010310a <__alltraps>

c0102cf6 <vector169>:
.globl vector169
vector169:
  pushl $0
c0102cf6:	6a 00                	push   $0x0
  pushl $169
c0102cf8:	68 a9 00 00 00       	push   $0xa9
  jmp __alltraps
c0102cfd:	e9 08 04 00 00       	jmp    c010310a <__alltraps>

c0102d02 <vector170>:
.globl vector170
vector170:
  pushl $0
c0102d02:	6a 00                	push   $0x0
  pushl $170
c0102d04:	68 aa 00 00 00       	push   $0xaa
  jmp __alltraps
c0102d09:	e9 fc 03 00 00       	jmp    c010310a <__alltraps>

c0102d0e <vector171>:
.globl vector171
vector171:
  pushl $0
c0102d0e:	6a 00                	push   $0x0
  pushl $171
c0102d10:	68 ab 00 00 00       	push   $0xab
  jmp __alltraps
c0102d15:	e9 f0 03 00 00       	jmp    c010310a <__alltraps>

c0102d1a <vector172>:
.globl vector172
vector172:
  pushl $0
c0102d1a:	6a 00                	push   $0x0
  pushl $172
c0102d1c:	68 ac 00 00 00       	push   $0xac
  jmp __alltraps
c0102d21:	e9 e4 03 00 00       	jmp    c010310a <__alltraps>

c0102d26 <vector173>:
.globl vector173
vector173:
  pushl $0
c0102d26:	6a 00                	push   $0x0
  pushl $173
c0102d28:	68 ad 00 00 00       	push   $0xad
  jmp __alltraps
c0102d2d:	e9 d8 03 00 00       	jmp    c010310a <__alltraps>

c0102d32 <vector174>:
.globl vector174
vector174:
  pushl $0
c0102d32:	6a 00                	push   $0x0
  pushl $174
c0102d34:	68 ae 00 00 00       	push   $0xae
  jmp __alltraps
c0102d39:	e9 cc 03 00 00       	jmp    c010310a <__alltraps>

c0102d3e <vector175>:
.globl vector175
vector175:
  pushl $0
c0102d3e:	6a 00                	push   $0x0
  pushl $175
c0102d40:	68 af 00 00 00       	push   $0xaf
  jmp __alltraps
c0102d45:	e9 c0 03 00 00       	jmp    c010310a <__alltraps>

c0102d4a <vector176>:
.globl vector176
vector176:
  pushl $0
c0102d4a:	6a 00                	push   $0x0
  pushl $176
c0102d4c:	68 b0 00 00 00       	push   $0xb0
  jmp __alltraps
c0102d51:	e9 b4 03 00 00       	jmp    c010310a <__alltraps>

c0102d56 <vector177>:
.globl vector177
vector177:
  pushl $0
c0102d56:	6a 00                	push   $0x0
  pushl $177
c0102d58:	68 b1 00 00 00       	push   $0xb1
  jmp __alltraps
c0102d5d:	e9 a8 03 00 00       	jmp    c010310a <__alltraps>

c0102d62 <vector178>:
.globl vector178
vector178:
  pushl $0
c0102d62:	6a 00                	push   $0x0
  pushl $178
c0102d64:	68 b2 00 00 00       	push   $0xb2
  jmp __alltraps
c0102d69:	e9 9c 03 00 00       	jmp    c010310a <__alltraps>

c0102d6e <vector179>:
.globl vector179
vector179:
  pushl $0
c0102d6e:	6a 00                	push   $0x0
  pushl $179
c0102d70:	68 b3 00 00 00       	push   $0xb3
  jmp __alltraps
c0102d75:	e9 90 03 00 00       	jmp    c010310a <__alltraps>

c0102d7a <vector180>:
.globl vector180
vector180:
  pushl $0
c0102d7a:	6a 00                	push   $0x0
  pushl $180
c0102d7c:	68 b4 00 00 00       	push   $0xb4
  jmp __alltraps
c0102d81:	e9 84 03 00 00       	jmp    c010310a <__alltraps>

c0102d86 <vector181>:
.globl vector181
vector181:
  pushl $0
c0102d86:	6a 00                	push   $0x0
  pushl $181
c0102d88:	68 b5 00 00 00       	push   $0xb5
  jmp __alltraps
c0102d8d:	e9 78 03 00 00       	jmp    c010310a <__alltraps>

c0102d92 <vector182>:
.globl vector182
vector182:
  pushl $0
c0102d92:	6a 00                	push   $0x0
  pushl $182
c0102d94:	68 b6 00 00 00       	push   $0xb6
  jmp __alltraps
c0102d99:	e9 6c 03 00 00       	jmp    c010310a <__alltraps>

c0102d9e <vector183>:
.globl vector183
vector183:
  pushl $0
c0102d9e:	6a 00                	push   $0x0
  pushl $183
c0102da0:	68 b7 00 00 00       	push   $0xb7
  jmp __alltraps
c0102da5:	e9 60 03 00 00       	jmp    c010310a <__alltraps>

c0102daa <vector184>:
.globl vector184
vector184:
  pushl $0
c0102daa:	6a 00                	push   $0x0
  pushl $184
c0102dac:	68 b8 00 00 00       	push   $0xb8
  jmp __alltraps
c0102db1:	e9 54 03 00 00       	jmp    c010310a <__alltraps>

c0102db6 <vector185>:
.globl vector185
vector185:
  pushl $0
c0102db6:	6a 00                	push   $0x0
  pushl $185
c0102db8:	68 b9 00 00 00       	push   $0xb9
  jmp __alltraps
c0102dbd:	e9 48 03 00 00       	jmp    c010310a <__alltraps>

c0102dc2 <vector186>:
.globl vector186
vector186:
  pushl $0
c0102dc2:	6a 00                	push   $0x0
  pushl $186
c0102dc4:	68 ba 00 00 00       	push   $0xba
  jmp __alltraps
c0102dc9:	e9 3c 03 00 00       	jmp    c010310a <__alltraps>

c0102dce <vector187>:
.globl vector187
vector187:
  pushl $0
c0102dce:	6a 00                	push   $0x0
  pushl $187
c0102dd0:	68 bb 00 00 00       	push   $0xbb
  jmp __alltraps
c0102dd5:	e9 30 03 00 00       	jmp    c010310a <__alltraps>

c0102dda <vector188>:
.globl vector188
vector188:
  pushl $0
c0102dda:	6a 00                	push   $0x0
  pushl $188
c0102ddc:	68 bc 00 00 00       	push   $0xbc
  jmp __alltraps
c0102de1:	e9 24 03 00 00       	jmp    c010310a <__alltraps>

c0102de6 <vector189>:
.globl vector189
vector189:
  pushl $0
c0102de6:	6a 00                	push   $0x0
  pushl $189
c0102de8:	68 bd 00 00 00       	push   $0xbd
  jmp __alltraps
c0102ded:	e9 18 03 00 00       	jmp    c010310a <__alltraps>

c0102df2 <vector190>:
.globl vector190
vector190:
  pushl $0
c0102df2:	6a 00                	push   $0x0
  pushl $190
c0102df4:	68 be 00 00 00       	push   $0xbe
  jmp __alltraps
c0102df9:	e9 0c 03 00 00       	jmp    c010310a <__alltraps>

c0102dfe <vector191>:
.globl vector191
vector191:
  pushl $0
c0102dfe:	6a 00                	push   $0x0
  pushl $191
c0102e00:	68 bf 00 00 00       	push   $0xbf
  jmp __alltraps
c0102e05:	e9 00 03 00 00       	jmp    c010310a <__alltraps>

c0102e0a <vector192>:
.globl vector192
vector192:
  pushl $0
c0102e0a:	6a 00                	push   $0x0
  pushl $192
c0102e0c:	68 c0 00 00 00       	push   $0xc0
  jmp __alltraps
c0102e11:	e9 f4 02 00 00       	jmp    c010310a <__alltraps>

c0102e16 <vector193>:
.globl vector193
vector193:
  pushl $0
c0102e16:	6a 00                	push   $0x0
  pushl $193
c0102e18:	68 c1 00 00 00       	push   $0xc1
  jmp __alltraps
c0102e1d:	e9 e8 02 00 00       	jmp    c010310a <__alltraps>

c0102e22 <vector194>:
.globl vector194
vector194:
  pushl $0
c0102e22:	6a 00                	push   $0x0
  pushl $194
c0102e24:	68 c2 00 00 00       	push   $0xc2
  jmp __alltraps
c0102e29:	e9 dc 02 00 00       	jmp    c010310a <__alltraps>

c0102e2e <vector195>:
.globl vector195
vector195:
  pushl $0
c0102e2e:	6a 00                	push   $0x0
  pushl $195
c0102e30:	68 c3 00 00 00       	push   $0xc3
  jmp __alltraps
c0102e35:	e9 d0 02 00 00       	jmp    c010310a <__alltraps>

c0102e3a <vector196>:
.globl vector196
vector196:
  pushl $0
c0102e3a:	6a 00                	push   $0x0
  pushl $196
c0102e3c:	68 c4 00 00 00       	push   $0xc4
  jmp __alltraps
c0102e41:	e9 c4 02 00 00       	jmp    c010310a <__alltraps>

c0102e46 <vector197>:
.globl vector197
vector197:
  pushl $0
c0102e46:	6a 00                	push   $0x0
  pushl $197
c0102e48:	68 c5 00 00 00       	push   $0xc5
  jmp __alltraps
c0102e4d:	e9 b8 02 00 00       	jmp    c010310a <__alltraps>

c0102e52 <vector198>:
.globl vector198
vector198:
  pushl $0
c0102e52:	6a 00                	push   $0x0
  pushl $198
c0102e54:	68 c6 00 00 00       	push   $0xc6
  jmp __alltraps
c0102e59:	e9 ac 02 00 00       	jmp    c010310a <__alltraps>

c0102e5e <vector199>:
.globl vector199
vector199:
  pushl $0
c0102e5e:	6a 00                	push   $0x0
  pushl $199
c0102e60:	68 c7 00 00 00       	push   $0xc7
  jmp __alltraps
c0102e65:	e9 a0 02 00 00       	jmp    c010310a <__alltraps>

c0102e6a <vector200>:
.globl vector200
vector200:
  pushl $0
c0102e6a:	6a 00                	push   $0x0
  pushl $200
c0102e6c:	68 c8 00 00 00       	push   $0xc8
  jmp __alltraps
c0102e71:	e9 94 02 00 00       	jmp    c010310a <__alltraps>

c0102e76 <vector201>:
.globl vector201
vector201:
  pushl $0
c0102e76:	6a 00                	push   $0x0
  pushl $201
c0102e78:	68 c9 00 00 00       	push   $0xc9
  jmp __alltraps
c0102e7d:	e9 88 02 00 00       	jmp    c010310a <__alltraps>

c0102e82 <vector202>:
.globl vector202
vector202:
  pushl $0
c0102e82:	6a 00                	push   $0x0
  pushl $202
c0102e84:	68 ca 00 00 00       	push   $0xca
  jmp __alltraps
c0102e89:	e9 7c 02 00 00       	jmp    c010310a <__alltraps>

c0102e8e <vector203>:
.globl vector203
vector203:
  pushl $0
c0102e8e:	6a 00                	push   $0x0
  pushl $203
c0102e90:	68 cb 00 00 00       	push   $0xcb
  jmp __alltraps
c0102e95:	e9 70 02 00 00       	jmp    c010310a <__alltraps>

c0102e9a <vector204>:
.globl vector204
vector204:
  pushl $0
c0102e9a:	6a 00                	push   $0x0
  pushl $204
c0102e9c:	68 cc 00 00 00       	push   $0xcc
  jmp __alltraps
c0102ea1:	e9 64 02 00 00       	jmp    c010310a <__alltraps>

c0102ea6 <vector205>:
.globl vector205
vector205:
  pushl $0
c0102ea6:	6a 00                	push   $0x0
  pushl $205
c0102ea8:	68 cd 00 00 00       	push   $0xcd
  jmp __alltraps
c0102ead:	e9 58 02 00 00       	jmp    c010310a <__alltraps>

c0102eb2 <vector206>:
.globl vector206
vector206:
  pushl $0
c0102eb2:	6a 00                	push   $0x0
  pushl $206
c0102eb4:	68 ce 00 00 00       	push   $0xce
  jmp __alltraps
c0102eb9:	e9 4c 02 00 00       	jmp    c010310a <__alltraps>

c0102ebe <vector207>:
.globl vector207
vector207:
  pushl $0
c0102ebe:	6a 00                	push   $0x0
  pushl $207
c0102ec0:	68 cf 00 00 00       	push   $0xcf
  jmp __alltraps
c0102ec5:	e9 40 02 00 00       	jmp    c010310a <__alltraps>

c0102eca <vector208>:
.globl vector208
vector208:
  pushl $0
c0102eca:	6a 00                	push   $0x0
  pushl $208
c0102ecc:	68 d0 00 00 00       	push   $0xd0
  jmp __alltraps
c0102ed1:	e9 34 02 00 00       	jmp    c010310a <__alltraps>

c0102ed6 <vector209>:
.globl vector209
vector209:
  pushl $0
c0102ed6:	6a 00                	push   $0x0
  pushl $209
c0102ed8:	68 d1 00 00 00       	push   $0xd1
  jmp __alltraps
c0102edd:	e9 28 02 00 00       	jmp    c010310a <__alltraps>

c0102ee2 <vector210>:
.globl vector210
vector210:
  pushl $0
c0102ee2:	6a 00                	push   $0x0
  pushl $210
c0102ee4:	68 d2 00 00 00       	push   $0xd2
  jmp __alltraps
c0102ee9:	e9 1c 02 00 00       	jmp    c010310a <__alltraps>

c0102eee <vector211>:
.globl vector211
vector211:
  pushl $0
c0102eee:	6a 00                	push   $0x0
  pushl $211
c0102ef0:	68 d3 00 00 00       	push   $0xd3
  jmp __alltraps
c0102ef5:	e9 10 02 00 00       	jmp    c010310a <__alltraps>

c0102efa <vector212>:
.globl vector212
vector212:
  pushl $0
c0102efa:	6a 00                	push   $0x0
  pushl $212
c0102efc:	68 d4 00 00 00       	push   $0xd4
  jmp __alltraps
c0102f01:	e9 04 02 00 00       	jmp    c010310a <__alltraps>

c0102f06 <vector213>:
.globl vector213
vector213:
  pushl $0
c0102f06:	6a 00                	push   $0x0
  pushl $213
c0102f08:	68 d5 00 00 00       	push   $0xd5
  jmp __alltraps
c0102f0d:	e9 f8 01 00 00       	jmp    c010310a <__alltraps>

c0102f12 <vector214>:
.globl vector214
vector214:
  pushl $0
c0102f12:	6a 00                	push   $0x0
  pushl $214
c0102f14:	68 d6 00 00 00       	push   $0xd6
  jmp __alltraps
c0102f19:	e9 ec 01 00 00       	jmp    c010310a <__alltraps>

c0102f1e <vector215>:
.globl vector215
vector215:
  pushl $0
c0102f1e:	6a 00                	push   $0x0
  pushl $215
c0102f20:	68 d7 00 00 00       	push   $0xd7
  jmp __alltraps
c0102f25:	e9 e0 01 00 00       	jmp    c010310a <__alltraps>

c0102f2a <vector216>:
.globl vector216
vector216:
  pushl $0
c0102f2a:	6a 00                	push   $0x0
  pushl $216
c0102f2c:	68 d8 00 00 00       	push   $0xd8
  jmp __alltraps
c0102f31:	e9 d4 01 00 00       	jmp    c010310a <__alltraps>

c0102f36 <vector217>:
.globl vector217
vector217:
  pushl $0
c0102f36:	6a 00                	push   $0x0
  pushl $217
c0102f38:	68 d9 00 00 00       	push   $0xd9
  jmp __alltraps
c0102f3d:	e9 c8 01 00 00       	jmp    c010310a <__alltraps>

c0102f42 <vector218>:
.globl vector218
vector218:
  pushl $0
c0102f42:	6a 00                	push   $0x0
  pushl $218
c0102f44:	68 da 00 00 00       	push   $0xda
  jmp __alltraps
c0102f49:	e9 bc 01 00 00       	jmp    c010310a <__alltraps>

c0102f4e <vector219>:
.globl vector219
vector219:
  pushl $0
c0102f4e:	6a 00                	push   $0x0
  pushl $219
c0102f50:	68 db 00 00 00       	push   $0xdb
  jmp __alltraps
c0102f55:	e9 b0 01 00 00       	jmp    c010310a <__alltraps>

c0102f5a <vector220>:
.globl vector220
vector220:
  pushl $0
c0102f5a:	6a 00                	push   $0x0
  pushl $220
c0102f5c:	68 dc 00 00 00       	push   $0xdc
  jmp __alltraps
c0102f61:	e9 a4 01 00 00       	jmp    c010310a <__alltraps>

c0102f66 <vector221>:
.globl vector221
vector221:
  pushl $0
c0102f66:	6a 00                	push   $0x0
  pushl $221
c0102f68:	68 dd 00 00 00       	push   $0xdd
  jmp __alltraps
c0102f6d:	e9 98 01 00 00       	jmp    c010310a <__alltraps>

c0102f72 <vector222>:
.globl vector222
vector222:
  pushl $0
c0102f72:	6a 00                	push   $0x0
  pushl $222
c0102f74:	68 de 00 00 00       	push   $0xde
  jmp __alltraps
c0102f79:	e9 8c 01 00 00       	jmp    c010310a <__alltraps>

c0102f7e <vector223>:
.globl vector223
vector223:
  pushl $0
c0102f7e:	6a 00                	push   $0x0
  pushl $223
c0102f80:	68 df 00 00 00       	push   $0xdf
  jmp __alltraps
c0102f85:	e9 80 01 00 00       	jmp    c010310a <__alltraps>

c0102f8a <vector224>:
.globl vector224
vector224:
  pushl $0
c0102f8a:	6a 00                	push   $0x0
  pushl $224
c0102f8c:	68 e0 00 00 00       	push   $0xe0
  jmp __alltraps
c0102f91:	e9 74 01 00 00       	jmp    c010310a <__alltraps>

c0102f96 <vector225>:
.globl vector225
vector225:
  pushl $0
c0102f96:	6a 00                	push   $0x0
  pushl $225
c0102f98:	68 e1 00 00 00       	push   $0xe1
  jmp __alltraps
c0102f9d:	e9 68 01 00 00       	jmp    c010310a <__alltraps>

c0102fa2 <vector226>:
.globl vector226
vector226:
  pushl $0
c0102fa2:	6a 00                	push   $0x0
  pushl $226
c0102fa4:	68 e2 00 00 00       	push   $0xe2
  jmp __alltraps
c0102fa9:	e9 5c 01 00 00       	jmp    c010310a <__alltraps>

c0102fae <vector227>:
.globl vector227
vector227:
  pushl $0
c0102fae:	6a 00                	push   $0x0
  pushl $227
c0102fb0:	68 e3 00 00 00       	push   $0xe3
  jmp __alltraps
c0102fb5:	e9 50 01 00 00       	jmp    c010310a <__alltraps>

c0102fba <vector228>:
.globl vector228
vector228:
  pushl $0
c0102fba:	6a 00                	push   $0x0
  pushl $228
c0102fbc:	68 e4 00 00 00       	push   $0xe4
  jmp __alltraps
c0102fc1:	e9 44 01 00 00       	jmp    c010310a <__alltraps>

c0102fc6 <vector229>:
.globl vector229
vector229:
  pushl $0
c0102fc6:	6a 00                	push   $0x0
  pushl $229
c0102fc8:	68 e5 00 00 00       	push   $0xe5
  jmp __alltraps
c0102fcd:	e9 38 01 00 00       	jmp    c010310a <__alltraps>

c0102fd2 <vector230>:
.globl vector230
vector230:
  pushl $0
c0102fd2:	6a 00                	push   $0x0
  pushl $230
c0102fd4:	68 e6 00 00 00       	push   $0xe6
  jmp __alltraps
c0102fd9:	e9 2c 01 00 00       	jmp    c010310a <__alltraps>

c0102fde <vector231>:
.globl vector231
vector231:
  pushl $0
c0102fde:	6a 00                	push   $0x0
  pushl $231
c0102fe0:	68 e7 00 00 00       	push   $0xe7
  jmp __alltraps
c0102fe5:	e9 20 01 00 00       	jmp    c010310a <__alltraps>

c0102fea <vector232>:
.globl vector232
vector232:
  pushl $0
c0102fea:	6a 00                	push   $0x0
  pushl $232
c0102fec:	68 e8 00 00 00       	push   $0xe8
  jmp __alltraps
c0102ff1:	e9 14 01 00 00       	jmp    c010310a <__alltraps>

c0102ff6 <vector233>:
.globl vector233
vector233:
  pushl $0
c0102ff6:	6a 00                	push   $0x0
  pushl $233
c0102ff8:	68 e9 00 00 00       	push   $0xe9
  jmp __alltraps
c0102ffd:	e9 08 01 00 00       	jmp    c010310a <__alltraps>

c0103002 <vector234>:
.globl vector234
vector234:
  pushl $0
c0103002:	6a 00                	push   $0x0
  pushl $234
c0103004:	68 ea 00 00 00       	push   $0xea
  jmp __alltraps
c0103009:	e9 fc 00 00 00       	jmp    c010310a <__alltraps>

c010300e <vector235>:
.globl vector235
vector235:
  pushl $0
c010300e:	6a 00                	push   $0x0
  pushl $235
c0103010:	68 eb 00 00 00       	push   $0xeb
  jmp __alltraps
c0103015:	e9 f0 00 00 00       	jmp    c010310a <__alltraps>

c010301a <vector236>:
.globl vector236
vector236:
  pushl $0
c010301a:	6a 00                	push   $0x0
  pushl $236
c010301c:	68 ec 00 00 00       	push   $0xec
  jmp __alltraps
c0103021:	e9 e4 00 00 00       	jmp    c010310a <__alltraps>

c0103026 <vector237>:
.globl vector237
vector237:
  pushl $0
c0103026:	6a 00                	push   $0x0
  pushl $237
c0103028:	68 ed 00 00 00       	push   $0xed
  jmp __alltraps
c010302d:	e9 d8 00 00 00       	jmp    c010310a <__alltraps>

c0103032 <vector238>:
.globl vector238
vector238:
  pushl $0
c0103032:	6a 00                	push   $0x0
  pushl $238
c0103034:	68 ee 00 00 00       	push   $0xee
  jmp __alltraps
c0103039:	e9 cc 00 00 00       	jmp    c010310a <__alltraps>

c010303e <vector239>:
.globl vector239
vector239:
  pushl $0
c010303e:	6a 00                	push   $0x0
  pushl $239
c0103040:	68 ef 00 00 00       	push   $0xef
  jmp __alltraps
c0103045:	e9 c0 00 00 00       	jmp    c010310a <__alltraps>

c010304a <vector240>:
.globl vector240
vector240:
  pushl $0
c010304a:	6a 00                	push   $0x0
  pushl $240
c010304c:	68 f0 00 00 00       	push   $0xf0
  jmp __alltraps
c0103051:	e9 b4 00 00 00       	jmp    c010310a <__alltraps>

c0103056 <vector241>:
.globl vector241
vector241:
  pushl $0
c0103056:	6a 00                	push   $0x0
  pushl $241
c0103058:	68 f1 00 00 00       	push   $0xf1
  jmp __alltraps
c010305d:	e9 a8 00 00 00       	jmp    c010310a <__alltraps>

c0103062 <vector242>:
.globl vector242
vector242:
  pushl $0
c0103062:	6a 00                	push   $0x0
  pushl $242
c0103064:	68 f2 00 00 00       	push   $0xf2
  jmp __alltraps
c0103069:	e9 9c 00 00 00       	jmp    c010310a <__alltraps>

c010306e <vector243>:
.globl vector243
vector243:
  pushl $0
c010306e:	6a 00                	push   $0x0
  pushl $243
c0103070:	68 f3 00 00 00       	push   $0xf3
  jmp __alltraps
c0103075:	e9 90 00 00 00       	jmp    c010310a <__alltraps>

c010307a <vector244>:
.globl vector244
vector244:
  pushl $0
c010307a:	6a 00                	push   $0x0
  pushl $244
c010307c:	68 f4 00 00 00       	push   $0xf4
  jmp __alltraps
c0103081:	e9 84 00 00 00       	jmp    c010310a <__alltraps>

c0103086 <vector245>:
.globl vector245
vector245:
  pushl $0
c0103086:	6a 00                	push   $0x0
  pushl $245
c0103088:	68 f5 00 00 00       	push   $0xf5
  jmp __alltraps
c010308d:	e9 78 00 00 00       	jmp    c010310a <__alltraps>

c0103092 <vector246>:
.globl vector246
vector246:
  pushl $0
c0103092:	6a 00                	push   $0x0
  pushl $246
c0103094:	68 f6 00 00 00       	push   $0xf6
  jmp __alltraps
c0103099:	e9 6c 00 00 00       	jmp    c010310a <__alltraps>

c010309e <vector247>:
.globl vector247
vector247:
  pushl $0
c010309e:	6a 00                	push   $0x0
  pushl $247
c01030a0:	68 f7 00 00 00       	push   $0xf7
  jmp __alltraps
c01030a5:	e9 60 00 00 00       	jmp    c010310a <__alltraps>

c01030aa <vector248>:
.globl vector248
vector248:
  pushl $0
c01030aa:	6a 00                	push   $0x0
  pushl $248
c01030ac:	68 f8 00 00 00       	push   $0xf8
  jmp __alltraps
c01030b1:	e9 54 00 00 00       	jmp    c010310a <__alltraps>

c01030b6 <vector249>:
.globl vector249
vector249:
  pushl $0
c01030b6:	6a 00                	push   $0x0
  pushl $249
c01030b8:	68 f9 00 00 00       	push   $0xf9
  jmp __alltraps
c01030bd:	e9 48 00 00 00       	jmp    c010310a <__alltraps>

c01030c2 <vector250>:
.globl vector250
vector250:
  pushl $0
c01030c2:	6a 00                	push   $0x0
  pushl $250
c01030c4:	68 fa 00 00 00       	push   $0xfa
  jmp __alltraps
c01030c9:	e9 3c 00 00 00       	jmp    c010310a <__alltraps>

c01030ce <vector251>:
.globl vector251
vector251:
  pushl $0
c01030ce:	6a 00                	push   $0x0
  pushl $251
c01030d0:	68 fb 00 00 00       	push   $0xfb
  jmp __alltraps
c01030d5:	e9 30 00 00 00       	jmp    c010310a <__alltraps>

c01030da <vector252>:
.globl vector252
vector252:
  pushl $0
c01030da:	6a 00                	push   $0x0
  pushl $252
c01030dc:	68 fc 00 00 00       	push   $0xfc
  jmp __alltraps
c01030e1:	e9 24 00 00 00       	jmp    c010310a <__alltraps>

c01030e6 <vector253>:
.globl vector253
vector253:
  pushl $0
c01030e6:	6a 00                	push   $0x0
  pushl $253
c01030e8:	68 fd 00 00 00       	push   $0xfd
  jmp __alltraps
c01030ed:	e9 18 00 00 00       	jmp    c010310a <__alltraps>

c01030f2 <vector254>:
.globl vector254
vector254:
  pushl $0
c01030f2:	6a 00                	push   $0x0
  pushl $254
c01030f4:	68 fe 00 00 00       	push   $0xfe
  jmp __alltraps
c01030f9:	e9 0c 00 00 00       	jmp    c010310a <__alltraps>

c01030fe <vector255>:
.globl vector255
vector255:
  pushl $0
c01030fe:	6a 00                	push   $0x0
  pushl $255
c0103100:	68 ff 00 00 00       	push   $0xff
  jmp __alltraps
c0103105:	e9 00 00 00 00       	jmp    c010310a <__alltraps>

c010310a <__alltraps>:
.text
.globl __alltraps
__alltraps:
    # push registers to build a trap frame
    # therefore make the stack look like a struct trapframe
    pushl %ds
c010310a:	1e                   	push   %ds
    pushl %es
c010310b:	06                   	push   %es
    pushl %fs
c010310c:	0f a0                	push   %fs
    pushl %gs
c010310e:	0f a8                	push   %gs
    pushal
c0103110:	60                   	pusha  

    # load GD_KDATA into %ds and %es to set up data segments for kernel
    movl $GD_KDATA, %eax
c0103111:	b8 10 00 00 00       	mov    $0x10,%eax
    movw %ax, %ds
c0103116:	8e d8                	mov    %eax,%ds
    movw %ax, %es
c0103118:	8e c0                	mov    %eax,%es

    # push %esp to pass a pointer to the trapframe as an argument to trap()
    pushl %esp
c010311a:	54                   	push   %esp

    # call trap(tf), where tf=%esp
    call trap
c010311b:	e8 64 f5 ff ff       	call   c0102684 <trap>

    # pop the pushed stack pointer
    popl %esp
c0103120:	5c                   	pop    %esp

c0103121 <__trapret>:

    # return falls through to trapret...
.globl __trapret
__trapret:
    # restore registers from stack从_trapret开始执行到iret前，esp指向了current->tf.tf_eip
    popal                   # 顺序EDI,ESI,EBP,EBX,EDX,ECX,EAX:
c0103121:	61                   	popa   

    # restore %ds, %es, %fs and %gs
    popl %gs
c0103122:	0f a9                	pop    %gs
    popl %fs
c0103124:	0f a1                	pop    %fs
    popl %es
c0103126:	07                   	pop    %es
    popl %ds
c0103127:	1f                   	pop    %ds

    # get rid of the trap number and error code
    addl $0x8, %esp         # esp是current->tf,tf eip tf.tf eip =(uint32 t)kernel thread entry;
c0103128:	83 c4 08             	add    $0x8,%esp
    iret                    # 执行完iret后，就开始在内核中执行kernel thread entry医数
c010312b:	cf                   	iret   

c010312c <forkrets>:

.globl forkrets
forkrets:
    # set stack to this new process's trapframe lab4新加！！
    movl 4(%esp), %esp              # 把esp指向当前进程的中断帧
c010312c:	8b 64 24 04          	mov    0x4(%esp),%esp
    jmp __trapret
c0103130:	eb ef                	jmp    c0103121 <__trapret>

c0103132 <page2ppn>:

extern struct Page *pages;  //物理页数组的基址？
extern size_t npage;

static inline ppn_t
page2ppn(struct Page *page) {
c0103132:	55                   	push   %ebp
c0103133:	89 e5                	mov    %esp,%ebp
    return page - pages;         //减去物理页数组的基址，得高20bit的PPN(pa)
c0103135:	8b 45 08             	mov    0x8(%ebp),%eax
c0103138:	8b 15 60 b0 12 c0    	mov    0xc012b060,%edx
c010313e:	29 d0                	sub    %edx,%eax
c0103140:	c1 f8 05             	sar    $0x5,%eax
}
c0103143:	5d                   	pop    %ebp
c0103144:	c3                   	ret    

c0103145 <page2pa>:

static inline uintptr_t
page2pa(struct Page *page) {
c0103145:	55                   	push   %ebp
c0103146:	89 e5                	mov    %esp,%ebp
c0103148:	83 ec 04             	sub    $0x4,%esp
    return page2ppn(page) << PGSHIFT;   //20bit+12bit全0的pa
c010314b:	8b 45 08             	mov    0x8(%ebp),%eax
c010314e:	89 04 24             	mov    %eax,(%esp)
c0103151:	e8 dc ff ff ff       	call   c0103132 <page2ppn>
c0103156:	c1 e0 0c             	shl    $0xc,%eax
}
c0103159:	c9                   	leave  
c010315a:	c3                   	ret    

c010315b <pa2page>:

static inline struct Page *
pa2page(uintptr_t pa) {
c010315b:	55                   	push   %ebp
c010315c:	89 e5                	mov    %esp,%ebp
c010315e:	83 ec 18             	sub    $0x18,%esp
    if (PPN(pa) >= npage) {
c0103161:	8b 45 08             	mov    0x8(%ebp),%eax
c0103164:	c1 e8 0c             	shr    $0xc,%eax
c0103167:	89 c2                	mov    %eax,%edx
c0103169:	a1 80 8f 12 c0       	mov    0xc0128f80,%eax
c010316e:	39 c2                	cmp    %eax,%edx
c0103170:	72 1c                	jb     c010318e <pa2page+0x33>
        panic("pa2page called with invalid pa");
c0103172:	c7 44 24 08 30 a6 10 	movl   $0xc010a630,0x8(%esp)
c0103179:	c0 
c010317a:	c7 44 24 04 5f 00 00 	movl   $0x5f,0x4(%esp)
c0103181:	00 
c0103182:	c7 04 24 4f a6 10 c0 	movl   $0xc010a64f,(%esp)
c0103189:	e8 72 d2 ff ff       	call   c0100400 <__panic>
    }
    return &pages[PPN(pa)];   //pages+pa高20bit索引位 摒弃低12bit全0
c010318e:	a1 60 b0 12 c0       	mov    0xc012b060,%eax
c0103193:	8b 55 08             	mov    0x8(%ebp),%edx
c0103196:	c1 ea 0c             	shr    $0xc,%edx
c0103199:	c1 e2 05             	shl    $0x5,%edx
c010319c:	01 d0                	add    %edx,%eax
}
c010319e:	c9                   	leave  
c010319f:	c3                   	ret    

c01031a0 <page2kva>:

static inline void *
page2kva(struct Page *page) {
c01031a0:	55                   	push   %ebp
c01031a1:	89 e5                	mov    %esp,%ebp
c01031a3:	83 ec 28             	sub    $0x28,%esp
    return KADDR(page2pa(page));
c01031a6:	8b 45 08             	mov    0x8(%ebp),%eax
c01031a9:	89 04 24             	mov    %eax,(%esp)
c01031ac:	e8 94 ff ff ff       	call   c0103145 <page2pa>
c01031b1:	89 45 f4             	mov    %eax,-0xc(%ebp)
c01031b4:	8b 45 f4             	mov    -0xc(%ebp),%eax
c01031b7:	c1 e8 0c             	shr    $0xc,%eax
c01031ba:	89 45 f0             	mov    %eax,-0x10(%ebp)
c01031bd:	a1 80 8f 12 c0       	mov    0xc0128f80,%eax
c01031c2:	39 45 f0             	cmp    %eax,-0x10(%ebp)
c01031c5:	72 23                	jb     c01031ea <page2kva+0x4a>
c01031c7:	8b 45 f4             	mov    -0xc(%ebp),%eax
c01031ca:	89 44 24 0c          	mov    %eax,0xc(%esp)
c01031ce:	c7 44 24 08 60 a6 10 	movl   $0xc010a660,0x8(%esp)
c01031d5:	c0 
c01031d6:	c7 44 24 04 66 00 00 	movl   $0x66,0x4(%esp)
c01031dd:	00 
c01031de:	c7 04 24 4f a6 10 c0 	movl   $0xc010a64f,(%esp)
c01031e5:	e8 16 d2 ff ff       	call   c0100400 <__panic>
c01031ea:	8b 45 f4             	mov    -0xc(%ebp),%eax
c01031ed:	2d 00 00 00 40       	sub    $0x40000000,%eax
}
c01031f2:	c9                   	leave  
c01031f3:	c3                   	ret    

c01031f4 <pte2page>:
kva2page(void *kva) {
    return pa2page(PADDR(kva));
}

static inline struct Page *
pte2page(pte_t pte) {
c01031f4:	55                   	push   %ebp
c01031f5:	89 e5                	mov    %esp,%ebp
c01031f7:	83 ec 18             	sub    $0x18,%esp
    if (!(pte & PTE_P)) {
c01031fa:	8b 45 08             	mov    0x8(%ebp),%eax
c01031fd:	83 e0 01             	and    $0x1,%eax
c0103200:	85 c0                	test   %eax,%eax
c0103202:	75 1c                	jne    c0103220 <pte2page+0x2c>
        panic("pte2page called with invalid pte");
c0103204:	c7 44 24 08 84 a6 10 	movl   $0xc010a684,0x8(%esp)
c010320b:	c0 
c010320c:	c7 44 24 04 71 00 00 	movl   $0x71,0x4(%esp)
c0103213:	00 
c0103214:	c7 04 24 4f a6 10 c0 	movl   $0xc010a64f,(%esp)
c010321b:	e8 e0 d1 ff ff       	call   c0100400 <__panic>
    }
    return pa2page(PTE_ADDR(pte));   //pte的高20bit+12bit全0
c0103220:	8b 45 08             	mov    0x8(%ebp),%eax
c0103223:	25 00 f0 ff ff       	and    $0xfffff000,%eax
c0103228:	89 04 24             	mov    %eax,(%esp)
c010322b:	e8 2b ff ff ff       	call   c010315b <pa2page>
}
c0103230:	c9                   	leave  
c0103231:	c3                   	ret    

c0103232 <pde2page>:

static inline struct Page *
pde2page(pde_t pde) {
c0103232:	55                   	push   %ebp
c0103233:	89 e5                	mov    %esp,%ebp
c0103235:	83 ec 18             	sub    $0x18,%esp
    return pa2page(PDE_ADDR(pde));
c0103238:	8b 45 08             	mov    0x8(%ebp),%eax
c010323b:	25 00 f0 ff ff       	and    $0xfffff000,%eax
c0103240:	89 04 24             	mov    %eax,(%esp)
c0103243:	e8 13 ff ff ff       	call   c010315b <pa2page>
}
c0103248:	c9                   	leave  
c0103249:	c3                   	ret    

c010324a <page_ref>:

static inline int
page_ref(struct Page *page) {
c010324a:	55                   	push   %ebp
c010324b:	89 e5                	mov    %esp,%ebp
    return page->ref;
c010324d:	8b 45 08             	mov    0x8(%ebp),%eax
c0103250:	8b 00                	mov    (%eax),%eax
}
c0103252:	5d                   	pop    %ebp
c0103253:	c3                   	ret    

c0103254 <set_page_ref>:

static inline void
set_page_ref(struct Page *page, int val) {
c0103254:	55                   	push   %ebp
c0103255:	89 e5                	mov    %esp,%ebp
    page->ref = val;
c0103257:	8b 45 08             	mov    0x8(%ebp),%eax
c010325a:	8b 55 0c             	mov    0xc(%ebp),%edx
c010325d:	89 10                	mov    %edx,(%eax)
}
c010325f:	90                   	nop
c0103260:	5d                   	pop    %ebp
c0103261:	c3                   	ret    

c0103262 <page_ref_inc>:

static inline int
page_ref_inc(struct Page *page) {
c0103262:	55                   	push   %ebp
c0103263:	89 e5                	mov    %esp,%ebp
    page->ref += 1;
c0103265:	8b 45 08             	mov    0x8(%ebp),%eax
c0103268:	8b 00                	mov    (%eax),%eax
c010326a:	8d 50 01             	lea    0x1(%eax),%edx
c010326d:	8b 45 08             	mov    0x8(%ebp),%eax
c0103270:	89 10                	mov    %edx,(%eax)
    return page->ref;
c0103272:	8b 45 08             	mov    0x8(%ebp),%eax
c0103275:	8b 00                	mov    (%eax),%eax
}
c0103277:	5d                   	pop    %ebp
c0103278:	c3                   	ret    

c0103279 <page_ref_dec>:

static inline int
page_ref_dec(struct Page *page) {
c0103279:	55                   	push   %ebp
c010327a:	89 e5                	mov    %esp,%ebp
    page->ref -= 1;
c010327c:	8b 45 08             	mov    0x8(%ebp),%eax
c010327f:	8b 00                	mov    (%eax),%eax
c0103281:	8d 50 ff             	lea    -0x1(%eax),%edx
c0103284:	8b 45 08             	mov    0x8(%ebp),%eax
c0103287:	89 10                	mov    %edx,(%eax)
    return page->ref;
c0103289:	8b 45 08             	mov    0x8(%ebp),%eax
c010328c:	8b 00                	mov    (%eax),%eax
}
c010328e:	5d                   	pop    %ebp
c010328f:	c3                   	ret    

c0103290 <__intr_save>:
__intr_save(void) {
c0103290:	55                   	push   %ebp
c0103291:	89 e5                	mov    %esp,%ebp
c0103293:	83 ec 18             	sub    $0x18,%esp
    asm volatile ("pushfl; popl %0" : "=r" (eflags));
c0103296:	9c                   	pushf  
c0103297:	58                   	pop    %eax
c0103298:	89 45 f4             	mov    %eax,-0xc(%ebp)
    return eflags;
c010329b:	8b 45 f4             	mov    -0xc(%ebp),%eax
    if (read_eflags() & FL_IF) {//读操作出现中断
c010329e:	25 00 02 00 00       	and    $0x200,%eax
c01032a3:	85 c0                	test   %eax,%eax
c01032a5:	74 0c                	je     c01032b3 <__intr_save+0x23>
        intr_disable();//intr.c12->禁用irq中断
c01032a7:	e8 86 ed ff ff       	call   c0102032 <intr_disable>
        return 1;
c01032ac:	b8 01 00 00 00       	mov    $0x1,%eax
c01032b1:	eb 05                	jmp    c01032b8 <__intr_save+0x28>
    return 0;
c01032b3:	b8 00 00 00 00       	mov    $0x0,%eax
}
c01032b8:	c9                   	leave  
c01032b9:	c3                   	ret    

c01032ba <__intr_restore>:
__intr_restore(bool flag) {
c01032ba:	55                   	push   %ebp
c01032bb:	89 e5                	mov    %esp,%ebp
c01032bd:	83 ec 08             	sub    $0x8,%esp
    if (flag) {
c01032c0:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
c01032c4:	74 05                	je     c01032cb <__intr_restore+0x11>
        intr_enable();
c01032c6:	e8 60 ed ff ff       	call   c010202b <intr_enable>
}
c01032cb:	90                   	nop
c01032cc:	c9                   	leave  
c01032cd:	c3                   	ret    

c01032ce <lgdt>:
/* *
 * lgdt - load the global descriptor table register and reset the
 * data/code segement registers for kernel.
 * */
static inline void
lgdt(struct pseudodesc *pd) {
c01032ce:	55                   	push   %ebp
c01032cf:	89 e5                	mov    %esp,%ebp
    asm volatile ("lgdt (%0)" :: "r" (pd));
c01032d1:	8b 45 08             	mov    0x8(%ebp),%eax
c01032d4:	0f 01 10             	lgdtl  (%eax)
    asm volatile ("movw %%ax, %%gs" :: "a" (USER_DS));
c01032d7:	b8 23 00 00 00       	mov    $0x23,%eax
c01032dc:	8e e8                	mov    %eax,%gs
    asm volatile ("movw %%ax, %%fs" :: "a" (USER_DS));
c01032de:	b8 23 00 00 00       	mov    $0x23,%eax
c01032e3:	8e e0                	mov    %eax,%fs
    asm volatile ("movw %%ax, %%es" :: "a" (KERNEL_DS));
c01032e5:	b8 10 00 00 00       	mov    $0x10,%eax
c01032ea:	8e c0                	mov    %eax,%es
    asm volatile ("movw %%ax, %%ds" :: "a" (KERNEL_DS));
c01032ec:	b8 10 00 00 00       	mov    $0x10,%eax
c01032f1:	8e d8                	mov    %eax,%ds
    asm volatile ("movw %%ax, %%ss" :: "a" (KERNEL_DS));
c01032f3:	b8 10 00 00 00       	mov    $0x10,%eax
c01032f8:	8e d0                	mov    %eax,%ss
    // reload cs
    asm volatile ("ljmp %0, $1f\n 1:\n" :: "i" (KERNEL_CS));
c01032fa:	ea 01 33 10 c0 08 00 	ljmp   $0x8,$0xc0103301
}
c0103301:	90                   	nop
c0103302:	5d                   	pop    %ebp
c0103303:	c3                   	ret    

c0103304 <load_esp0>:
 * load_esp0 - change the ESP0 in default task state segment,
 * so that we can use different kernel stack when we trap frame
 * user to kernel.
 * */
void
load_esp0(uintptr_t esp0) {
c0103304:	55                   	push   %ebp
c0103305:	89 e5                	mov    %esp,%ebp
    ts.ts_esp0 = esp0;//将tf的esp0赋值
c0103307:	8b 45 08             	mov    0x8(%ebp),%eax
c010330a:	a3 a4 8f 12 c0       	mov    %eax,0xc0128fa4
}
c010330f:	90                   	nop
c0103310:	5d                   	pop    %ebp
c0103311:	c3                   	ret    

c0103312 <gdt_init>:

/* gdt_init - initialize the default GDT and TSS */
static void
gdt_init(void) {
c0103312:	55                   	push   %ebp
c0103313:	89 e5                	mov    %esp,%ebp
c0103315:	83 ec 14             	sub    $0x14,%esp
    // set boot kernel stack and default SS0
    load_esp0((uintptr_t)bootstacktop); //让ts的ts_esp0（栈指针）为bootstacktop
c0103318:	b8 00 50 12 c0       	mov    $0xc0125000,%eax
c010331d:	89 04 24             	mov    %eax,(%esp)
c0103320:	e8 df ff ff ff       	call   c0103304 <load_esp0>
    ts.ts_ss0 = KERNEL_DS;       //让ts的ts_ss0（特权级）为KERNEL_DS
c0103325:	66 c7 05 a8 8f 12 c0 	movw   $0x10,0xc0128fa8
c010332c:	10 00 

    // initialize the TSS filed of the gdt
    gdt[SEG_TSS] = SEGTSS(STS_T32A, (uintptr_t)&ts, sizeof(ts), DPL_KERNEL);
c010332e:	66 c7 05 28 5a 12 c0 	movw   $0x68,0xc0125a28
c0103335:	68 00 
c0103337:	b8 a0 8f 12 c0       	mov    $0xc0128fa0,%eax
c010333c:	0f b7 c0             	movzwl %ax,%eax
c010333f:	66 a3 2a 5a 12 c0    	mov    %ax,0xc0125a2a
c0103345:	b8 a0 8f 12 c0       	mov    $0xc0128fa0,%eax
c010334a:	c1 e8 10             	shr    $0x10,%eax
c010334d:	a2 2c 5a 12 c0       	mov    %al,0xc0125a2c
c0103352:	0f b6 05 2d 5a 12 c0 	movzbl 0xc0125a2d,%eax
c0103359:	24 f0                	and    $0xf0,%al
c010335b:	0c 09                	or     $0x9,%al
c010335d:	a2 2d 5a 12 c0       	mov    %al,0xc0125a2d
c0103362:	0f b6 05 2d 5a 12 c0 	movzbl 0xc0125a2d,%eax
c0103369:	24 ef                	and    $0xef,%al
c010336b:	a2 2d 5a 12 c0       	mov    %al,0xc0125a2d
c0103370:	0f b6 05 2d 5a 12 c0 	movzbl 0xc0125a2d,%eax
c0103377:	24 9f                	and    $0x9f,%al
c0103379:	a2 2d 5a 12 c0       	mov    %al,0xc0125a2d
c010337e:	0f b6 05 2d 5a 12 c0 	movzbl 0xc0125a2d,%eax
c0103385:	0c 80                	or     $0x80,%al
c0103387:	a2 2d 5a 12 c0       	mov    %al,0xc0125a2d
c010338c:	0f b6 05 2e 5a 12 c0 	movzbl 0xc0125a2e,%eax
c0103393:	24 f0                	and    $0xf0,%al
c0103395:	a2 2e 5a 12 c0       	mov    %al,0xc0125a2e
c010339a:	0f b6 05 2e 5a 12 c0 	movzbl 0xc0125a2e,%eax
c01033a1:	24 ef                	and    $0xef,%al
c01033a3:	a2 2e 5a 12 c0       	mov    %al,0xc0125a2e
c01033a8:	0f b6 05 2e 5a 12 c0 	movzbl 0xc0125a2e,%eax
c01033af:	24 df                	and    $0xdf,%al
c01033b1:	a2 2e 5a 12 c0       	mov    %al,0xc0125a2e
c01033b6:	0f b6 05 2e 5a 12 c0 	movzbl 0xc0125a2e,%eax
c01033bd:	0c 40                	or     $0x40,%al
c01033bf:	a2 2e 5a 12 c0       	mov    %al,0xc0125a2e
c01033c4:	0f b6 05 2e 5a 12 c0 	movzbl 0xc0125a2e,%eax
c01033cb:	24 7f                	and    $0x7f,%al
c01033cd:	a2 2e 5a 12 c0       	mov    %al,0xc0125a2e
c01033d2:	b8 a0 8f 12 c0       	mov    $0xc0128fa0,%eax
c01033d7:	c1 e8 18             	shr    $0x18,%eax
c01033da:	a2 2f 5a 12 c0       	mov    %al,0xc0125a2f

    // reload all segment registers
    lgdt(&gdt_pd);
c01033df:	c7 04 24 30 5a 12 c0 	movl   $0xc0125a30,(%esp)
c01033e6:	e8 e3 fe ff ff       	call   c01032ce <lgdt>
c01033eb:	66 c7 45 fe 28 00    	movw   $0x28,-0x2(%ebp)
    asm volatile ("ltr %0" :: "r" (sel) : "memory");
c01033f1:	0f b7 45 fe          	movzwl -0x2(%ebp),%eax
c01033f5:	0f 00 d8             	ltr    %ax

    // load the TSS
    ltr(GD_TSS);
}
c01033f8:	90                   	nop
c01033f9:	c9                   	leave  
c01033fa:	c3                   	ret    

c01033fb <init_pmm_manager>:

//init_pmm_manager - initialize a pmm_manager instance
static void
init_pmm_manager(void) {
c01033fb:	55                   	push   %ebp
c01033fc:	89 e5                	mov    %esp,%ebp
c01033fe:	83 ec 18             	sub    $0x18,%esp
    pmm_manager = &default_pmm_manager;
c0103401:	c7 05 58 b0 12 c0 c8 	movl   $0xc010bbc8,0xc012b058
c0103408:	bb 10 c0 
    cprintf("memory management: %s\n", pmm_manager->name);
c010340b:	a1 58 b0 12 c0       	mov    0xc012b058,%eax
c0103410:	8b 00                	mov    (%eax),%eax
c0103412:	89 44 24 04          	mov    %eax,0x4(%esp)
c0103416:	c7 04 24 b0 a6 10 c0 	movl   $0xc010a6b0,(%esp)
c010341d:	e8 87 ce ff ff       	call   c01002a9 <cprintf>
    pmm_manager->init();
c0103422:	a1 58 b0 12 c0       	mov    0xc012b058,%eax
c0103427:	8b 40 04             	mov    0x4(%eax),%eax
c010342a:	ff d0                	call   *%eax
}
c010342c:	90                   	nop
c010342d:	c9                   	leave  
c010342e:	c3                   	ret    

c010342f <init_memmap>:

//init_memmap - call pmm->init_memmap to build Page struct for free memory  
static void
init_memmap(struct Page *base, size_t n) {
c010342f:	55                   	push   %ebp
c0103430:	89 e5                	mov    %esp,%ebp
c0103432:	83 ec 18             	sub    $0x18,%esp
    pmm_manager->init_memmap(base, n);
c0103435:	a1 58 b0 12 c0       	mov    0xc012b058,%eax
c010343a:	8b 40 08             	mov    0x8(%eax),%eax
c010343d:	8b 55 0c             	mov    0xc(%ebp),%edx
c0103440:	89 54 24 04          	mov    %edx,0x4(%esp)
c0103444:	8b 55 08             	mov    0x8(%ebp),%edx
c0103447:	89 14 24             	mov    %edx,(%esp)
c010344a:	ff d0                	call   *%eax
}
c010344c:	90                   	nop
c010344d:	c9                   	leave  
c010344e:	c3                   	ret    

c010344f <alloc_pages>:

//alloc_pages - call pmm->alloc_pages to allocate a continuous n*PAGESIZE memory 
struct Page *
alloc_pages(size_t n) {   //只是当试图得到空闲页时，发现当前没有空闲的物理页可供分配，这时才开始查找“不常用”页面，并把一个或多个这样的页换出到硬盘上。
c010344f:	55                   	push   %ebp
c0103450:	89 e5                	mov    %esp,%ebp
c0103452:	83 ec 28             	sub    $0x28,%esp
    struct Page *page=NULL;
c0103455:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
    bool intr_flag;
    
    while (1)
    {
        //关闭中断
         local_intr_save(intr_flag);
c010345c:	e8 2f fe ff ff       	call   c0103290 <__intr_save>
c0103461:	89 45 f0             	mov    %eax,-0x10(%ebp)
         {
              page = pmm_manager->alloc_pages(n);
c0103464:	a1 58 b0 12 c0       	mov    0xc012b058,%eax
c0103469:	8b 40 0c             	mov    0xc(%eax),%eax
c010346c:	8b 55 08             	mov    0x8(%ebp),%edx
c010346f:	89 14 24             	mov    %edx,(%esp)
c0103472:	ff d0                	call   *%eax
c0103474:	89 45 f4             	mov    %eax,-0xc(%ebp)
         }
         //开启中断
         local_intr_restore(intr_flag);
c0103477:	8b 45 f0             	mov    -0x10(%ebp),%eax
c010347a:	89 04 24             	mov    %eax,(%esp)
c010347d:	e8 38 fe ff ff       	call   c01032ba <__intr_restore>

         if (page != NULL || n > 1 || swap_init_ok == 0) break;
c0103482:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
c0103486:	75 2d                	jne    c01034b5 <alloc_pages+0x66>
c0103488:	83 7d 08 01          	cmpl   $0x1,0x8(%ebp)
c010348c:	77 27                	ja     c01034b5 <alloc_pages+0x66>
c010348e:	a1 14 90 12 c0       	mov    0xc0129014,%eax
c0103493:	85 c0                	test   %eax,%eax
c0103495:	74 1e                	je     c01034b5 <alloc_pages+0x66>
         
         extern struct mm_struct *check_mm_struct;
         //cprintf("page %x, call swap_out in alloc_pages %d\n",page, n);
         swap_out(check_mm_struct, n, 0);       //注意！页换出（消极）
c0103497:	8b 55 08             	mov    0x8(%ebp),%edx
c010349a:	a1 6c b0 12 c0       	mov    0xc012b06c,%eax
c010349f:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
c01034a6:	00 
c01034a7:	89 54 24 04          	mov    %edx,0x4(%esp)
c01034ab:	89 04 24             	mov    %eax,(%esp)
c01034ae:	e8 96 32 00 00       	call   c0106749 <swap_out>
    {
c01034b3:	eb a7                	jmp    c010345c <alloc_pages+0xd>
    }
    //cprintf("n %d,get page %x, No %d in alloc_pages\n",n,page,(page-pages));
    return page;
c01034b5:	8b 45 f4             	mov    -0xc(%ebp),%eax
}
c01034b8:	c9                   	leave  
c01034b9:	c3                   	ret    

c01034ba <free_pages>:

//free_pages - call pmm->free_pages to free a continuous n*PAGESIZE memory 
void
free_pages(struct Page *base, size_t n) {
c01034ba:	55                   	push   %ebp
c01034bb:	89 e5                	mov    %esp,%ebp
c01034bd:	83 ec 28             	sub    $0x28,%esp
    bool intr_flag;
    local_intr_save(intr_flag);
c01034c0:	e8 cb fd ff ff       	call   c0103290 <__intr_save>
c01034c5:	89 45 f4             	mov    %eax,-0xc(%ebp)
    {
        pmm_manager->free_pages(base, n);
c01034c8:	a1 58 b0 12 c0       	mov    0xc012b058,%eax
c01034cd:	8b 40 10             	mov    0x10(%eax),%eax
c01034d0:	8b 55 0c             	mov    0xc(%ebp),%edx
c01034d3:	89 54 24 04          	mov    %edx,0x4(%esp)
c01034d7:	8b 55 08             	mov    0x8(%ebp),%edx
c01034da:	89 14 24             	mov    %edx,(%esp)
c01034dd:	ff d0                	call   *%eax
    }
    local_intr_restore(intr_flag);
c01034df:	8b 45 f4             	mov    -0xc(%ebp),%eax
c01034e2:	89 04 24             	mov    %eax,(%esp)
c01034e5:	e8 d0 fd ff ff       	call   c01032ba <__intr_restore>
}
c01034ea:	90                   	nop
c01034eb:	c9                   	leave  
c01034ec:	c3                   	ret    

c01034ed <nr_free_pages>:

//nr_free_pages - call pmm->nr_free_pages to get the size (nr*PAGESIZE) 
//of current free memory
size_t
nr_free_pages(void) {
c01034ed:	55                   	push   %ebp
c01034ee:	89 e5                	mov    %esp,%ebp
c01034f0:	83 ec 28             	sub    $0x28,%esp
    size_t ret;
    bool intr_flag;
    local_intr_save(intr_flag);
c01034f3:	e8 98 fd ff ff       	call   c0103290 <__intr_save>
c01034f8:	89 45 f4             	mov    %eax,-0xc(%ebp)
    {
        ret = pmm_manager->nr_free_pages();
c01034fb:	a1 58 b0 12 c0       	mov    0xc012b058,%eax
c0103500:	8b 40 14             	mov    0x14(%eax),%eax
c0103503:	ff d0                	call   *%eax
c0103505:	89 45 f0             	mov    %eax,-0x10(%ebp)
    }
    local_intr_restore(intr_flag);
c0103508:	8b 45 f4             	mov    -0xc(%ebp),%eax
c010350b:	89 04 24             	mov    %eax,(%esp)
c010350e:	e8 a7 fd ff ff       	call   c01032ba <__intr_restore>
    return ret;
c0103513:	8b 45 f0             	mov    -0x10(%ebp),%eax
}
c0103516:	c9                   	leave  
c0103517:	c3                   	ret    

c0103518 <page_init>:

/* pmm_init - initialize the physical memory management */
static void
page_init(void) {
c0103518:	55                   	push   %ebp
c0103519:	89 e5                	mov    %esp,%ebp
c010351b:	57                   	push   %edi
c010351c:	56                   	push   %esi
c010351d:	53                   	push   %ebx
c010351e:	81 ec 9c 00 00 00    	sub    $0x9c,%esp
    struct e820map *memmap = (struct e820map *)(0x8000 + KERNBASE);  // layout.h里KERNBASE:0xC0000000(3G处)
c0103524:	c7 45 c4 00 80 00 c0 	movl   $0xc0008000,-0x3c(%ebp)
    uint64_t maxpa = 0;
c010352b:	c7 45 e0 00 00 00 00 	movl   $0x0,-0x20(%ebp)
c0103532:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)

    cprintf("e820map:\n");
c0103539:	c7 04 24 c7 a6 10 c0 	movl   $0xc010a6c7,(%esp)
c0103540:	e8 64 cd ff ff       	call   c01002a9 <cprintf>
    int i;
    for (i = 0; i < memmap->nr_map; i ++) {      //nr_map是实际填的ARD个数
c0103545:	c7 45 dc 00 00 00 00 	movl   $0x0,-0x24(%ebp)
c010354c:	e9 22 01 00 00       	jmp    c0103673 <page_init+0x15b>
        uint64_t begin = memmap->map[i].addr, end = begin + memmap->map[i].size;    //针对某一个ARD
c0103551:	8b 4d c4             	mov    -0x3c(%ebp),%ecx
c0103554:	8b 55 dc             	mov    -0x24(%ebp),%edx
c0103557:	89 d0                	mov    %edx,%eax
c0103559:	c1 e0 02             	shl    $0x2,%eax
c010355c:	01 d0                	add    %edx,%eax
c010355e:	c1 e0 02             	shl    $0x2,%eax
c0103561:	01 c8                	add    %ecx,%eax
c0103563:	8b 50 08             	mov    0x8(%eax),%edx
c0103566:	8b 40 04             	mov    0x4(%eax),%eax
c0103569:	89 45 a0             	mov    %eax,-0x60(%ebp)
c010356c:	89 55 a4             	mov    %edx,-0x5c(%ebp)
c010356f:	8b 4d c4             	mov    -0x3c(%ebp),%ecx
c0103572:	8b 55 dc             	mov    -0x24(%ebp),%edx
c0103575:	89 d0                	mov    %edx,%eax
c0103577:	c1 e0 02             	shl    $0x2,%eax
c010357a:	01 d0                	add    %edx,%eax
c010357c:	c1 e0 02             	shl    $0x2,%eax
c010357f:	01 c8                	add    %ecx,%eax
c0103581:	8b 48 0c             	mov    0xc(%eax),%ecx
c0103584:	8b 58 10             	mov    0x10(%eax),%ebx
c0103587:	8b 45 a0             	mov    -0x60(%ebp),%eax
c010358a:	8b 55 a4             	mov    -0x5c(%ebp),%edx
c010358d:	01 c8                	add    %ecx,%eax
c010358f:	11 da                	adc    %ebx,%edx
c0103591:	89 45 98             	mov    %eax,-0x68(%ebp)
c0103594:	89 55 9c             	mov    %edx,-0x64(%ebp)
        cprintf("  memory: %08llx, [%08llx, %08llx], type = %d.\n",
c0103597:	8b 4d c4             	mov    -0x3c(%ebp),%ecx
c010359a:	8b 55 dc             	mov    -0x24(%ebp),%edx
c010359d:	89 d0                	mov    %edx,%eax
c010359f:	c1 e0 02             	shl    $0x2,%eax
c01035a2:	01 d0                	add    %edx,%eax
c01035a4:	c1 e0 02             	shl    $0x2,%eax
c01035a7:	01 c8                	add    %ecx,%eax
c01035a9:	83 c0 14             	add    $0x14,%eax
c01035ac:	8b 00                	mov    (%eax),%eax
c01035ae:	89 45 84             	mov    %eax,-0x7c(%ebp)
c01035b1:	8b 45 98             	mov    -0x68(%ebp),%eax
c01035b4:	8b 55 9c             	mov    -0x64(%ebp),%edx
c01035b7:	83 c0 ff             	add    $0xffffffff,%eax
c01035ba:	83 d2 ff             	adc    $0xffffffff,%edx
c01035bd:	89 85 78 ff ff ff    	mov    %eax,-0x88(%ebp)
c01035c3:	89 95 7c ff ff ff    	mov    %edx,-0x84(%ebp)
c01035c9:	8b 4d c4             	mov    -0x3c(%ebp),%ecx
c01035cc:	8b 55 dc             	mov    -0x24(%ebp),%edx
c01035cf:	89 d0                	mov    %edx,%eax
c01035d1:	c1 e0 02             	shl    $0x2,%eax
c01035d4:	01 d0                	add    %edx,%eax
c01035d6:	c1 e0 02             	shl    $0x2,%eax
c01035d9:	01 c8                	add    %ecx,%eax
c01035db:	8b 48 0c             	mov    0xc(%eax),%ecx
c01035de:	8b 58 10             	mov    0x10(%eax),%ebx
c01035e1:	8b 55 84             	mov    -0x7c(%ebp),%edx
c01035e4:	89 54 24 1c          	mov    %edx,0x1c(%esp)
c01035e8:	8b 85 78 ff ff ff    	mov    -0x88(%ebp),%eax
c01035ee:	8b 95 7c ff ff ff    	mov    -0x84(%ebp),%edx
c01035f4:	89 44 24 14          	mov    %eax,0x14(%esp)
c01035f8:	89 54 24 18          	mov    %edx,0x18(%esp)
c01035fc:	8b 45 a0             	mov    -0x60(%ebp),%eax
c01035ff:	8b 55 a4             	mov    -0x5c(%ebp),%edx
c0103602:	89 44 24 0c          	mov    %eax,0xc(%esp)
c0103606:	89 54 24 10          	mov    %edx,0x10(%esp)
c010360a:	89 4c 24 04          	mov    %ecx,0x4(%esp)
c010360e:	89 5c 24 08          	mov    %ebx,0x8(%esp)
c0103612:	c7 04 24 d4 a6 10 c0 	movl   $0xc010a6d4,(%esp)
c0103619:	e8 8b cc ff ff       	call   c01002a9 <cprintf>
                memmap->map[i].size, begin, end - 1, memmap->map[i].type);  //%08llx：用8位数字表达一个十六进制指针地址
        if (memmap->map[i].type == E820_ARM) {          //E820_ARM：1，表示可用内存
c010361e:	8b 4d c4             	mov    -0x3c(%ebp),%ecx
c0103621:	8b 55 dc             	mov    -0x24(%ebp),%edx
c0103624:	89 d0                	mov    %edx,%eax
c0103626:	c1 e0 02             	shl    $0x2,%eax
c0103629:	01 d0                	add    %edx,%eax
c010362b:	c1 e0 02             	shl    $0x2,%eax
c010362e:	01 c8                	add    %ecx,%eax
c0103630:	83 c0 14             	add    $0x14,%eax
c0103633:	8b 00                	mov    (%eax),%eax
c0103635:	83 f8 01             	cmp    $0x1,%eax
c0103638:	75 36                	jne    c0103670 <page_init+0x158>
            if (maxpa < end && begin < KMEMSIZE) {      //KMEMSIZE：0x38000000 比1G小一点
c010363a:	8b 45 e0             	mov    -0x20(%ebp),%eax
c010363d:	8b 55 e4             	mov    -0x1c(%ebp),%edx
c0103640:	3b 55 9c             	cmp    -0x64(%ebp),%edx
c0103643:	77 2b                	ja     c0103670 <page_init+0x158>
c0103645:	3b 55 9c             	cmp    -0x64(%ebp),%edx
c0103648:	72 05                	jb     c010364f <page_init+0x137>
c010364a:	3b 45 98             	cmp    -0x68(%ebp),%eax
c010364d:	73 21                	jae    c0103670 <page_init+0x158>
c010364f:	83 7d a4 00          	cmpl   $0x0,-0x5c(%ebp)
c0103653:	77 1b                	ja     c0103670 <page_init+0x158>
c0103655:	83 7d a4 00          	cmpl   $0x0,-0x5c(%ebp)
c0103659:	72 09                	jb     c0103664 <page_init+0x14c>
c010365b:	81 7d a0 ff ff ff 37 	cmpl   $0x37ffffff,-0x60(%ebp)
c0103662:	77 0c                	ja     c0103670 <page_init+0x158>
                maxpa = end;                            //更新maxpa，使之为pm最大址
c0103664:	8b 45 98             	mov    -0x68(%ebp),%eax
c0103667:	8b 55 9c             	mov    -0x64(%ebp),%edx
c010366a:	89 45 e0             	mov    %eax,-0x20(%ebp)
c010366d:	89 55 e4             	mov    %edx,-0x1c(%ebp)
    for (i = 0; i < memmap->nr_map; i ++) {      //nr_map是实际填的ARD个数
c0103670:	ff 45 dc             	incl   -0x24(%ebp)
c0103673:	8b 45 c4             	mov    -0x3c(%ebp),%eax
c0103676:	8b 00                	mov    (%eax),%eax
c0103678:	39 45 dc             	cmp    %eax,-0x24(%ebp)
c010367b:	0f 8c d0 fe ff ff    	jl     c0103551 <page_init+0x39>
            }
        }
    }
    if (maxpa > KMEMSIZE) {
c0103681:	83 7d e4 00          	cmpl   $0x0,-0x1c(%ebp)
c0103685:	72 1d                	jb     c01036a4 <page_init+0x18c>
c0103687:	83 7d e4 00          	cmpl   $0x0,-0x1c(%ebp)
c010368b:	77 09                	ja     c0103696 <page_init+0x17e>
c010368d:	81 7d e0 00 00 00 38 	cmpl   $0x38000000,-0x20(%ebp)
c0103694:	76 0e                	jbe    c01036a4 <page_init+0x18c>
        maxpa = KMEMSIZE;                               //maxpa约束，不能超出kernel区域
c0103696:	c7 45 e0 00 00 00 38 	movl   $0x38000000,-0x20(%ebp)
c010369d:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
    }

    extern char end[];

    npage = maxpa / PGSIZE;          //需要管理的物理页个数：（maxpa-0）/4kB tip：x86的起始物理内存地址为0
c01036a4:	8b 45 e0             	mov    -0x20(%ebp),%eax
c01036a7:	8b 55 e4             	mov    -0x1c(%ebp),%edx
c01036aa:	0f ac d0 0c          	shrd   $0xc,%edx,%eax
c01036ae:	c1 ea 0c             	shr    $0xc,%edx
c01036b1:	89 c1                	mov    %eax,%ecx
c01036b3:	89 d3                	mov    %edx,%ebx
c01036b5:	89 c8                	mov    %ecx,%eax
c01036b7:	a3 80 8f 12 c0       	mov    %eax,0xc0128f80
    pages = (struct Page *)ROUNDUP((void *)end, PGSIZE);     //管理页级物理内存空间所需的Page结构的内存空间大小 ucore结束地址end对4KB取整，作为起始
c01036bc:	c7 45 c0 00 10 00 00 	movl   $0x1000,-0x40(%ebp)
c01036c3:	b8 58 b1 12 c0       	mov    $0xc012b158,%eax
c01036c8:	8d 50 ff             	lea    -0x1(%eax),%edx
c01036cb:	8b 45 c0             	mov    -0x40(%ebp),%eax
c01036ce:	01 d0                	add    %edx,%eax
c01036d0:	89 45 bc             	mov    %eax,-0x44(%ebp)
c01036d3:	8b 45 bc             	mov    -0x44(%ebp),%eax
c01036d6:	ba 00 00 00 00       	mov    $0x0,%edx
c01036db:	f7 75 c0             	divl   -0x40(%ebp)
c01036de:	8b 45 bc             	mov    -0x44(%ebp),%eax
c01036e1:	29 d0                	sub    %edx,%eax
c01036e3:	a3 60 b0 12 c0       	mov    %eax,0xc012b060

    for (i = 0; i < npage; i ++) {      //从起始处，开始为Page结构的内存空间设置已预订
c01036e8:	c7 45 dc 00 00 00 00 	movl   $0x0,-0x24(%ebp)
c01036ef:	eb 26                	jmp    c0103717 <page_init+0x1ff>
        SetPageReserved(pages + i);
c01036f1:	a1 60 b0 12 c0       	mov    0xc012b060,%eax
c01036f6:	8b 55 dc             	mov    -0x24(%ebp),%edx
c01036f9:	c1 e2 05             	shl    $0x5,%edx
c01036fc:	01 d0                	add    %edx,%eax
c01036fe:	83 c0 04             	add    $0x4,%eax
c0103701:	c7 45 94 00 00 00 00 	movl   $0x0,-0x6c(%ebp)
c0103708:	89 45 90             	mov    %eax,-0x70(%ebp)
 * Note that @nr may be almost arbitrarily large; this function is not
 * restricted to acting on a single-word quantity.
 * */
static inline void
set_bit(int nr, volatile void *addr) {
    asm volatile ("btsl %1, %0" :"=m" (*(volatile long *)addr) : "Ir" (nr));
c010370b:	8b 45 90             	mov    -0x70(%ebp),%eax
c010370e:	8b 55 94             	mov    -0x6c(%ebp),%edx
c0103711:	0f ab 10             	bts    %edx,(%eax)
    for (i = 0; i < npage; i ++) {      //从起始处，开始为Page结构的内存空间设置已预订
c0103714:	ff 45 dc             	incl   -0x24(%ebp)
c0103717:	8b 55 dc             	mov    -0x24(%ebp),%edx
c010371a:	a1 80 8f 12 c0       	mov    0xc0128f80,%eax
c010371f:	39 c2                	cmp    %eax,%edx
c0103721:	72 ce                	jb     c01036f1 <page_init+0x1d9>
    }

    uintptr_t freemem = PADDR((uintptr_t)pages + sizeof(struct Page) * npage);  //空闲起始处
c0103723:	a1 80 8f 12 c0       	mov    0xc0128f80,%eax
c0103728:	c1 e0 05             	shl    $0x5,%eax
c010372b:	89 c2                	mov    %eax,%edx
c010372d:	a1 60 b0 12 c0       	mov    0xc012b060,%eax
c0103732:	01 d0                	add    %edx,%eax
c0103734:	89 45 b8             	mov    %eax,-0x48(%ebp)
c0103737:	81 7d b8 ff ff ff bf 	cmpl   $0xbfffffff,-0x48(%ebp)
c010373e:	77 23                	ja     c0103763 <page_init+0x24b>
c0103740:	8b 45 b8             	mov    -0x48(%ebp),%eax
c0103743:	89 44 24 0c          	mov    %eax,0xc(%esp)
c0103747:	c7 44 24 08 04 a7 10 	movl   $0xc010a704,0x8(%esp)
c010374e:	c0 
c010374f:	c7 44 24 04 ec 00 00 	movl   $0xec,0x4(%esp)
c0103756:	00 
c0103757:	c7 04 24 28 a7 10 c0 	movl   $0xc010a728,(%esp)
c010375e:	e8 9d cc ff ff       	call   c0100400 <__panic>
c0103763:	8b 45 b8             	mov    -0x48(%ebp),%eax
c0103766:	05 00 00 00 40       	add    $0x40000000,%eax
c010376b:	89 45 b4             	mov    %eax,-0x4c(%ebp)

    for (i = 0; i < memmap->nr_map; i ++) {
c010376e:	c7 45 dc 00 00 00 00 	movl   $0x0,-0x24(%ebp)
c0103775:	e9 69 01 00 00       	jmp    c01038e3 <page_init+0x3cb>
        uint64_t begin = memmap->map[i].addr, end = begin + memmap->map[i].size;
c010377a:	8b 4d c4             	mov    -0x3c(%ebp),%ecx
c010377d:	8b 55 dc             	mov    -0x24(%ebp),%edx
c0103780:	89 d0                	mov    %edx,%eax
c0103782:	c1 e0 02             	shl    $0x2,%eax
c0103785:	01 d0                	add    %edx,%eax
c0103787:	c1 e0 02             	shl    $0x2,%eax
c010378a:	01 c8                	add    %ecx,%eax
c010378c:	8b 50 08             	mov    0x8(%eax),%edx
c010378f:	8b 40 04             	mov    0x4(%eax),%eax
c0103792:	89 45 d0             	mov    %eax,-0x30(%ebp)
c0103795:	89 55 d4             	mov    %edx,-0x2c(%ebp)
c0103798:	8b 4d c4             	mov    -0x3c(%ebp),%ecx
c010379b:	8b 55 dc             	mov    -0x24(%ebp),%edx
c010379e:	89 d0                	mov    %edx,%eax
c01037a0:	c1 e0 02             	shl    $0x2,%eax
c01037a3:	01 d0                	add    %edx,%eax
c01037a5:	c1 e0 02             	shl    $0x2,%eax
c01037a8:	01 c8                	add    %ecx,%eax
c01037aa:	8b 48 0c             	mov    0xc(%eax),%ecx
c01037ad:	8b 58 10             	mov    0x10(%eax),%ebx
c01037b0:	8b 45 d0             	mov    -0x30(%ebp),%eax
c01037b3:	8b 55 d4             	mov    -0x2c(%ebp),%edx
c01037b6:	01 c8                	add    %ecx,%eax
c01037b8:	11 da                	adc    %ebx,%edx
c01037ba:	89 45 c8             	mov    %eax,-0x38(%ebp)
c01037bd:	89 55 cc             	mov    %edx,-0x34(%ebp)
        if (memmap->map[i].type == E820_ARM) {       //针对某一个ARD，是可用内存时
c01037c0:	8b 4d c4             	mov    -0x3c(%ebp),%ecx
c01037c3:	8b 55 dc             	mov    -0x24(%ebp),%edx
c01037c6:	89 d0                	mov    %edx,%eax
c01037c8:	c1 e0 02             	shl    $0x2,%eax
c01037cb:	01 d0                	add    %edx,%eax
c01037cd:	c1 e0 02             	shl    $0x2,%eax
c01037d0:	01 c8                	add    %ecx,%eax
c01037d2:	83 c0 14             	add    $0x14,%eax
c01037d5:	8b 00                	mov    (%eax),%eax
c01037d7:	83 f8 01             	cmp    $0x1,%eax
c01037da:	0f 85 00 01 00 00    	jne    c01038e0 <page_init+0x3c8>
            if (begin < freemem) {
c01037e0:	8b 45 b4             	mov    -0x4c(%ebp),%eax
c01037e3:	ba 00 00 00 00       	mov    $0x0,%edx
c01037e8:	39 55 d4             	cmp    %edx,-0x2c(%ebp)
c01037eb:	77 17                	ja     c0103804 <page_init+0x2ec>
c01037ed:	39 55 d4             	cmp    %edx,-0x2c(%ebp)
c01037f0:	72 05                	jb     c01037f7 <page_init+0x2df>
c01037f2:	39 45 d0             	cmp    %eax,-0x30(%ebp)
c01037f5:	73 0d                	jae    c0103804 <page_init+0x2ec>
                begin = freemem;
c01037f7:	8b 45 b4             	mov    -0x4c(%ebp),%eax
c01037fa:	89 45 d0             	mov    %eax,-0x30(%ebp)
c01037fd:	c7 45 d4 00 00 00 00 	movl   $0x0,-0x2c(%ebp)
            }
            if (end > KMEMSIZE) {
c0103804:	83 7d cc 00          	cmpl   $0x0,-0x34(%ebp)
c0103808:	72 1d                	jb     c0103827 <page_init+0x30f>
c010380a:	83 7d cc 00          	cmpl   $0x0,-0x34(%ebp)
c010380e:	77 09                	ja     c0103819 <page_init+0x301>
c0103810:	81 7d c8 00 00 00 38 	cmpl   $0x38000000,-0x38(%ebp)
c0103817:	76 0e                	jbe    c0103827 <page_init+0x30f>
                end = KMEMSIZE;
c0103819:	c7 45 c8 00 00 00 38 	movl   $0x38000000,-0x38(%ebp)
c0103820:	c7 45 cc 00 00 00 00 	movl   $0x0,-0x34(%ebp)
            }
            if (begin < end) {      //保证该ADR约束在了空闲区域内
c0103827:	8b 45 d0             	mov    -0x30(%ebp),%eax
c010382a:	8b 55 d4             	mov    -0x2c(%ebp),%edx
c010382d:	3b 55 cc             	cmp    -0x34(%ebp),%edx
c0103830:	0f 87 aa 00 00 00    	ja     c01038e0 <page_init+0x3c8>
c0103836:	3b 55 cc             	cmp    -0x34(%ebp),%edx
c0103839:	72 09                	jb     c0103844 <page_init+0x32c>
c010383b:	3b 45 c8             	cmp    -0x38(%ebp),%eax
c010383e:	0f 83 9c 00 00 00    	jae    c01038e0 <page_init+0x3c8>
                begin = ROUNDUP(begin, PGSIZE);
c0103844:	c7 45 b0 00 10 00 00 	movl   $0x1000,-0x50(%ebp)
c010384b:	8b 55 d0             	mov    -0x30(%ebp),%edx
c010384e:	8b 45 b0             	mov    -0x50(%ebp),%eax
c0103851:	01 d0                	add    %edx,%eax
c0103853:	48                   	dec    %eax
c0103854:	89 45 ac             	mov    %eax,-0x54(%ebp)
c0103857:	8b 45 ac             	mov    -0x54(%ebp),%eax
c010385a:	ba 00 00 00 00       	mov    $0x0,%edx
c010385f:	f7 75 b0             	divl   -0x50(%ebp)
c0103862:	8b 45 ac             	mov    -0x54(%ebp),%eax
c0103865:	29 d0                	sub    %edx,%eax
c0103867:	ba 00 00 00 00       	mov    $0x0,%edx
c010386c:	89 45 d0             	mov    %eax,-0x30(%ebp)
c010386f:	89 55 d4             	mov    %edx,-0x2c(%ebp)
                end = ROUNDDOWN(end, PGSIZE);
c0103872:	8b 45 c8             	mov    -0x38(%ebp),%eax
c0103875:	89 45 a8             	mov    %eax,-0x58(%ebp)
c0103878:	8b 45 a8             	mov    -0x58(%ebp),%eax
c010387b:	ba 00 00 00 00       	mov    $0x0,%edx
c0103880:	89 c3                	mov    %eax,%ebx
c0103882:	81 e3 00 f0 ff ff    	and    $0xfffff000,%ebx
c0103888:	89 de                	mov    %ebx,%esi
c010388a:	89 d0                	mov    %edx,%eax
c010388c:	83 e0 00             	and    $0x0,%eax
c010388f:	89 c7                	mov    %eax,%edi
c0103891:	89 75 c8             	mov    %esi,-0x38(%ebp)
c0103894:	89 7d cc             	mov    %edi,-0x34(%ebp)
                if (begin < end) {
c0103897:	8b 45 d0             	mov    -0x30(%ebp),%eax
c010389a:	8b 55 d4             	mov    -0x2c(%ebp),%edx
c010389d:	3b 55 cc             	cmp    -0x34(%ebp),%edx
c01038a0:	77 3e                	ja     c01038e0 <page_init+0x3c8>
c01038a2:	3b 55 cc             	cmp    -0x34(%ebp),%edx
c01038a5:	72 05                	jb     c01038ac <page_init+0x394>
c01038a7:	3b 45 c8             	cmp    -0x38(%ebp),%eax
c01038aa:	73 34                	jae    c01038e0 <page_init+0x3c8>
                    init_memmap(pa2page(begin), (end - begin) / PGSIZE);    //把空闲物理页对应的Page结构中的flags和引用计数ref清零，并加到free_area.free_list指向的双向列表中
c01038ac:	8b 45 c8             	mov    -0x38(%ebp),%eax
c01038af:	8b 55 cc             	mov    -0x34(%ebp),%edx
c01038b2:	2b 45 d0             	sub    -0x30(%ebp),%eax
c01038b5:	1b 55 d4             	sbb    -0x2c(%ebp),%edx
c01038b8:	89 c1                	mov    %eax,%ecx
c01038ba:	89 d3                	mov    %edx,%ebx
c01038bc:	89 c8                	mov    %ecx,%eax
c01038be:	89 da                	mov    %ebx,%edx
c01038c0:	0f ac d0 0c          	shrd   $0xc,%edx,%eax
c01038c4:	c1 ea 0c             	shr    $0xc,%edx
c01038c7:	89 c3                	mov    %eax,%ebx
c01038c9:	8b 45 d0             	mov    -0x30(%ebp),%eax
c01038cc:	89 04 24             	mov    %eax,(%esp)
c01038cf:	e8 87 f8 ff ff       	call   c010315b <pa2page>
c01038d4:	89 5c 24 04          	mov    %ebx,0x4(%esp)
c01038d8:	89 04 24             	mov    %eax,(%esp)
c01038db:	e8 4f fb ff ff       	call   c010342f <init_memmap>
    for (i = 0; i < memmap->nr_map; i ++) {
c01038e0:	ff 45 dc             	incl   -0x24(%ebp)
c01038e3:	8b 45 c4             	mov    -0x3c(%ebp),%eax
c01038e6:	8b 00                	mov    (%eax),%eax
c01038e8:	39 45 dc             	cmp    %eax,-0x24(%ebp)
c01038eb:	0f 8c 89 fe ff ff    	jl     c010377a <page_init+0x262>
                }    //pa2page:物理地址转为一个页
            }
        }
    }
}
c01038f1:	90                   	nop
c01038f2:	81 c4 9c 00 00 00    	add    $0x9c,%esp
c01038f8:	5b                   	pop    %ebx
c01038f9:	5e                   	pop    %esi
c01038fa:	5f                   	pop    %edi
c01038fb:	5d                   	pop    %ebp
c01038fc:	c3                   	ret    

c01038fd <boot_map_segment>:
//  la:   linear address of this memory need to map (after x86 segment map)
//  size: memory size
//  pa:   physical address of this memory
//  perm: permission of this memory  
static void
boot_map_segment(pde_t *pgdir, uintptr_t la, size_t size, uintptr_t pa, uint32_t perm) {    //实参：(boot_pgdir, KERNBASE, KMEMSIZE, 0, PTE_W)
c01038fd:	55                   	push   %ebp
c01038fe:	89 e5                	mov    %esp,%ebp
c0103900:	83 ec 38             	sub    $0x38,%esp
    assert(PGOFF(la) == PGOFF(pa));
c0103903:	8b 45 0c             	mov    0xc(%ebp),%eax
c0103906:	33 45 14             	xor    0x14(%ebp),%eax
c0103909:	25 ff 0f 00 00       	and    $0xfff,%eax
c010390e:	85 c0                	test   %eax,%eax
c0103910:	74 24                	je     c0103936 <boot_map_segment+0x39>
c0103912:	c7 44 24 0c 36 a7 10 	movl   $0xc010a736,0xc(%esp)
c0103919:	c0 
c010391a:	c7 44 24 08 4d a7 10 	movl   $0xc010a74d,0x8(%esp)
c0103921:	c0 
c0103922:	c7 44 24 04 0a 01 00 	movl   $0x10a,0x4(%esp)
c0103929:	00 
c010392a:	c7 04 24 28 a7 10 c0 	movl   $0xc010a728,(%esp)
c0103931:	e8 ca ca ff ff       	call   c0100400 <__panic>
    size_t n = ROUNDUP(size + PGOFF(la), PGSIZE) / PGSIZE;  //KMEMSIZE+KERNBASE低12位，算出的va按页边距对齐，除以页大小，得到总页数
c0103936:	c7 45 f0 00 10 00 00 	movl   $0x1000,-0x10(%ebp)
c010393d:	8b 45 0c             	mov    0xc(%ebp),%eax
c0103940:	25 ff 0f 00 00       	and    $0xfff,%eax
c0103945:	89 c2                	mov    %eax,%edx
c0103947:	8b 45 10             	mov    0x10(%ebp),%eax
c010394a:	01 c2                	add    %eax,%edx
c010394c:	8b 45 f0             	mov    -0x10(%ebp),%eax
c010394f:	01 d0                	add    %edx,%eax
c0103951:	48                   	dec    %eax
c0103952:	89 45 ec             	mov    %eax,-0x14(%ebp)
c0103955:	8b 45 ec             	mov    -0x14(%ebp),%eax
c0103958:	ba 00 00 00 00       	mov    $0x0,%edx
c010395d:	f7 75 f0             	divl   -0x10(%ebp)
c0103960:	8b 45 ec             	mov    -0x14(%ebp),%eax
c0103963:	29 d0                	sub    %edx,%eax
c0103965:	c1 e8 0c             	shr    $0xc,%eax
c0103968:	89 45 f4             	mov    %eax,-0xc(%ebp)
    la = ROUNDDOWN(la, PGSIZE);
c010396b:	8b 45 0c             	mov    0xc(%ebp),%eax
c010396e:	89 45 e8             	mov    %eax,-0x18(%ebp)
c0103971:	8b 45 e8             	mov    -0x18(%ebp),%eax
c0103974:	25 00 f0 ff ff       	and    $0xfffff000,%eax
c0103979:	89 45 0c             	mov    %eax,0xc(%ebp)
    pa = ROUNDDOWN(pa, PGSIZE);
c010397c:	8b 45 14             	mov    0x14(%ebp),%eax
c010397f:	89 45 e4             	mov    %eax,-0x1c(%ebp)
c0103982:	8b 45 e4             	mov    -0x1c(%ebp),%eax
c0103985:	25 00 f0 ff ff       	and    $0xfffff000,%eax
c010398a:	89 45 14             	mov    %eax,0x14(%ebp)
    for (; n > 0; n --, la += PGSIZE, pa += PGSIZE) {
c010398d:	eb 68                	jmp    c01039f7 <boot_map_segment+0xfa>
        pte_t *ptep = get_pte(pgdir, la, 1);            //根据la得到一个pte
c010398f:	c7 44 24 08 01 00 00 	movl   $0x1,0x8(%esp)
c0103996:	00 
c0103997:	8b 45 0c             	mov    0xc(%ebp),%eax
c010399a:	89 44 24 04          	mov    %eax,0x4(%esp)
c010399e:	8b 45 08             	mov    0x8(%ebp),%eax
c01039a1:	89 04 24             	mov    %eax,(%esp)
c01039a4:	e8 86 01 00 00       	call   c0103b2f <get_pte>
c01039a9:	89 45 e0             	mov    %eax,-0x20(%ebp)
        assert(ptep != NULL);
c01039ac:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
c01039b0:	75 24                	jne    c01039d6 <boot_map_segment+0xd9>
c01039b2:	c7 44 24 0c 62 a7 10 	movl   $0xc010a762,0xc(%esp)
c01039b9:	c0 
c01039ba:	c7 44 24 08 4d a7 10 	movl   $0xc010a74d,0x8(%esp)
c01039c1:	c0 
c01039c2:	c7 44 24 04 10 01 00 	movl   $0x110,0x4(%esp)
c01039c9:	00 
c01039ca:	c7 04 24 28 a7 10 c0 	movl   $0xc010a728,(%esp)
c01039d1:	e8 2a ca ff ff       	call   c0100400 <__panic>
        *ptep = pa | PTE_P | perm;                      //往pte里写pa+标记
c01039d6:	8b 45 14             	mov    0x14(%ebp),%eax
c01039d9:	0b 45 18             	or     0x18(%ebp),%eax
c01039dc:	83 c8 01             	or     $0x1,%eax
c01039df:	89 c2                	mov    %eax,%edx
c01039e1:	8b 45 e0             	mov    -0x20(%ebp),%eax
c01039e4:	89 10                	mov    %edx,(%eax)
    for (; n > 0; n --, la += PGSIZE, pa += PGSIZE) {
c01039e6:	ff 4d f4             	decl   -0xc(%ebp)
c01039e9:	81 45 0c 00 10 00 00 	addl   $0x1000,0xc(%ebp)
c01039f0:	81 45 14 00 10 00 00 	addl   $0x1000,0x14(%ebp)
c01039f7:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
c01039fb:	75 92                	jne    c010398f <boot_map_segment+0x92>
    }
}
c01039fd:	90                   	nop
c01039fe:	c9                   	leave  
c01039ff:	c3                   	ret    

c0103a00 <boot_alloc_page>:

//boot_alloc_page - allocate one page using pmm->alloc_pages(1) 
// return value: the kernel virtual address of this allocated page
//note: this function is used to get the memory for PDT(Page Directory Table)&PT(Page Table)
static void *
boot_alloc_page(void) {
c0103a00:	55                   	push   %ebp
c0103a01:	89 e5                	mov    %esp,%ebp
c0103a03:	83 ec 28             	sub    $0x28,%esp
    struct Page *p = alloc_page();
c0103a06:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
c0103a0d:	e8 3d fa ff ff       	call   c010344f <alloc_pages>
c0103a12:	89 45 f4             	mov    %eax,-0xc(%ebp)
    if (p == NULL) {
c0103a15:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
c0103a19:	75 1c                	jne    c0103a37 <boot_alloc_page+0x37>
        panic("boot_alloc_page failed.\n");
c0103a1b:	c7 44 24 08 6f a7 10 	movl   $0xc010a76f,0x8(%esp)
c0103a22:	c0 
c0103a23:	c7 44 24 04 1c 01 00 	movl   $0x11c,0x4(%esp)
c0103a2a:	00 
c0103a2b:	c7 04 24 28 a7 10 c0 	movl   $0xc010a728,(%esp)
c0103a32:	e8 c9 c9 ff ff       	call   c0100400 <__panic>
    }
    return page2kva(p);
c0103a37:	8b 45 f4             	mov    -0xc(%ebp),%eax
c0103a3a:	89 04 24             	mov    %eax,(%esp)
c0103a3d:	e8 5e f7 ff ff       	call   c01031a0 <page2kva>
}
c0103a42:	c9                   	leave  
c0103a43:	c3                   	ret    

c0103a44 <pmm_init>:

//pmm_init - setup a pmm to manage physical memory, build PDT&PT to setup paging mechanism 
//         - check the correctness of pmm & paging mechanism, print PDT&PT
void
pmm_init(void) {
c0103a44:	55                   	push   %ebp
c0103a45:	89 e5                	mov    %esp,%ebp
c0103a47:	83 ec 38             	sub    $0x38,%esp
    // We've already enabled paging     1.bootasm.S分段 2.entry.S分页   3.pmm_init将页目录表项补充完成（从0~4M扩充到0~KMEMSIZE）；更新段映射机制，使用了一个新的段表。
    boot_cr3 = PADDR(boot_pgdir);    //boot_pgdir是页目录起始的页目录项指针，是个va，转化为pa给cr3 寄存器（低12位必须为0）
c0103a4a:	a1 e0 59 12 c0       	mov    0xc01259e0,%eax
c0103a4f:	89 45 f4             	mov    %eax,-0xc(%ebp)
c0103a52:	81 7d f4 ff ff ff bf 	cmpl   $0xbfffffff,-0xc(%ebp)
c0103a59:	77 23                	ja     c0103a7e <pmm_init+0x3a>
c0103a5b:	8b 45 f4             	mov    -0xc(%ebp),%eax
c0103a5e:	89 44 24 0c          	mov    %eax,0xc(%esp)
c0103a62:	c7 44 24 08 04 a7 10 	movl   $0xc010a704,0x8(%esp)
c0103a69:	c0 
c0103a6a:	c7 44 24 04 26 01 00 	movl   $0x126,0x4(%esp)
c0103a71:	00 
c0103a72:	c7 04 24 28 a7 10 c0 	movl   $0xc010a728,(%esp)
c0103a79:	e8 82 c9 ff ff       	call   c0100400 <__panic>
c0103a7e:	8b 45 f4             	mov    -0xc(%ebp),%eax
c0103a81:	05 00 00 00 40       	add    $0x40000000,%eax
c0103a86:	a3 5c b0 12 c0       	mov    %eax,0xc012b05c
    //We need to alloc/free the physical memory (granularity is 4KB or other size). 
    //So a framework of physical memory manager (struct pmm_manager)is defined in pmm.h
    //First we should init a physical memory manager(pmm) based on the framework.
    //Then pmm can alloc/free the physical memory. 
    //Now the first_fit/best_fit/worst_fit/buddy_system pmm are available.
    init_pmm_manager();     //1.初始化物理内存页管理器框架pmm_manager；init一下free_area结构体
c0103a8b:	e8 6b f9 ff ff       	call   c01033fb <init_pmm_manager>

    // detect physical memory space, reserve already used memory,
    // then use pmm->init_memmap to create free page list
    page_init();             //2.建立空闲的page链表，这样就可以分配以页（4KB）为单位的空闲内存了；
c0103a90:	e8 83 fa ff ff       	call   c0103518 <page_init>

    //use pmm->check to verify the correctness of the alloc/free function in a pmm
    check_alloc_page();     //3.检查物理内存页分配算法；//4.为确保切换到分页机制后，代码能够正常执行，先建立一个临时二级页表；(0-4MB在entry.S)
c0103a95:	e8 ae 04 00 00       	call   c0103f48 <check_alloc_page>

    check_pgdir();
c0103a9a:	e8 c8 04 00 00       	call   c0103f67 <check_pgdir>

    static_assert(KERNBASE % PTSIZE == 0 && KERNTOP % PTSIZE == 0);

    // recursively insert boot_pgdir in itself
    // to form a virtual page table at virtual address VPT
    boot_pgdir[PDX(VPT)] = PADDR(boot_pgdir) | PTE_P | PTE_W;    //在VPT处形成虚拟页表；自映射机制  在pde中装填pa
c0103a9f:	a1 e0 59 12 c0       	mov    0xc01259e0,%eax
c0103aa4:	89 45 f0             	mov    %eax,-0x10(%ebp)
c0103aa7:	81 7d f0 ff ff ff bf 	cmpl   $0xbfffffff,-0x10(%ebp)
c0103aae:	77 23                	ja     c0103ad3 <pmm_init+0x8f>
c0103ab0:	8b 45 f0             	mov    -0x10(%ebp),%eax
c0103ab3:	89 44 24 0c          	mov    %eax,0xc(%esp)
c0103ab7:	c7 44 24 08 04 a7 10 	movl   $0xc010a704,0x8(%esp)
c0103abe:	c0 
c0103abf:	c7 44 24 04 3c 01 00 	movl   $0x13c,0x4(%esp)
c0103ac6:	00 
c0103ac7:	c7 04 24 28 a7 10 c0 	movl   $0xc010a728,(%esp)
c0103ace:	e8 2d c9 ff ff       	call   c0100400 <__panic>
c0103ad3:	8b 45 f0             	mov    -0x10(%ebp),%eax
c0103ad6:	8d 90 00 00 00 40    	lea    0x40000000(%eax),%edx
c0103adc:	a1 e0 59 12 c0       	mov    0xc01259e0,%eax
c0103ae1:	05 ac 0f 00 00       	add    $0xfac,%eax
c0103ae6:	83 ca 03             	or     $0x3,%edx
c0103ae9:	89 10                	mov    %edx,(%eax)

    // map all physical memory to linear memory with base linear addr KERNBASE
    // linear_addr KERNBASE ~ KERNBASE + KMEMSIZE = phy_addr 0 ~ KMEMSIZE
    boot_map_segment(boot_pgdir, KERNBASE, KMEMSIZE, 0, PTE_W); //5.建立一一映射关系的二级页表；    //6.使能分页机制(在entry.S)
c0103aeb:	a1 e0 59 12 c0       	mov    0xc01259e0,%eax
c0103af0:	c7 44 24 10 02 00 00 	movl   $0x2,0x10(%esp)
c0103af7:	00 
c0103af8:	c7 44 24 0c 00 00 00 	movl   $0x0,0xc(%esp)
c0103aff:	00 
c0103b00:	c7 44 24 08 00 00 00 	movl   $0x38000000,0x8(%esp)
c0103b07:	38 
c0103b08:	c7 44 24 04 00 00 00 	movl   $0xc0000000,0x4(%esp)
c0103b0f:	c0 
c0103b10:	89 04 24             	mov    %eax,(%esp)
c0103b13:	e8 e5 fd ff ff       	call   c01038fd <boot_map_segment>

    // Since we are using bootloader's GDT,
    // we should reload gdt (second time, the last time) to get user segments and the TSS
    // map virtual_addr 0 ~ 4G = linear_addr 0 ~ 4G
    // then set kernel stack (ss:esp) in TSS, setup TSS in gdt, load TSS
    gdt_init();     //7.重新设置全局段描述符表；    //8.取消临时二级页表(在entry.S)
c0103b18:	e8 f5 f7 ff ff       	call   c0103312 <gdt_init>

    //now the basic virtual memory map(see memalyout.h) is established.
    //check the correctness of the basic virtual memory map.
    check_boot_pgdir();      //9.检查页表建立是否正确；
c0103b1d:	e8 e1 0a 00 00       	call   c0104603 <check_boot_pgdir>

    print_pgdir();          //10.通过自映射机制完成页表的打印输出（这部分是扩展知识）
c0103b22:	e8 5a 0f 00 00       	call   c0104a81 <print_pgdir>

    kmalloc_init();         //新加的！！
c0103b27:	e8 ee 27 00 00       	call   c010631a <kmalloc_init>
}
c0103b2c:	90                   	nop
c0103b2d:	c9                   	leave  
c0103b2e:	c3                   	ret    

c0103b2f <get_pte>:
//  pgdir:  the kernel virtual base address of PDT
//  la:     the linear address need to map
//  create: a logical value to decide if alloc a page for PT
// return vaule: the kernel virtual address of this pte
pte_t *
get_pte(pde_t *pgdir, uintptr_t la, bool create) {
c0103b2f:	55                   	push   %ebp
c0103b30:	89 e5                	mov    %esp,%ebp
c0103b32:	83 ec 38             	sub    $0x38,%esp
                          // (6) clear page content using memset
                          // (7) set page directory entry's permission
    }
    return NULL;          // (8) return page table entry
#endif
    pde_t *pdep = &pgdir[PDX(la)];      //页目录base+la线性地址高10位，得到pde指针
c0103b35:	8b 45 0c             	mov    0xc(%ebp),%eax
c0103b38:	c1 e8 16             	shr    $0x16,%eax
c0103b3b:	8d 14 85 00 00 00 00 	lea    0x0(,%eax,4),%edx
c0103b42:	8b 45 08             	mov    0x8(%ebp),%eax
c0103b45:	01 d0                	add    %edx,%eax
c0103b47:	89 45 f4             	mov    %eax,-0xc(%ebp)
    if (!(*pdep & PTE_P)) {             //判断其Present位是否为1(若不为1则需要为其创建新的PTT)
c0103b4a:	8b 45 f4             	mov    -0xc(%ebp),%eax
c0103b4d:	8b 00                	mov    (%eax),%eax
c0103b4f:	83 e0 01             	and    $0x1,%eax
c0103b52:	85 c0                	test   %eax,%eax
c0103b54:	0f 85 af 00 00 00    	jne    c0103c09 <get_pte+0xda>
        struct Page *page;
        if (!create || (page = alloc_page()) == NULL) {     //创建标志为0或者分配物理内存页失败
c0103b5a:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
c0103b5e:	74 15                	je     c0103b75 <get_pte+0x46>
c0103b60:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
c0103b67:	e8 e3 f8 ff ff       	call   c010344f <alloc_pages>
c0103b6c:	89 45 f0             	mov    %eax,-0x10(%ebp)
c0103b6f:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
c0103b73:	75 0a                	jne    c0103b7f <get_pte+0x50>
            return NULL;
c0103b75:	b8 00 00 00 00       	mov    $0x0,%eax
c0103b7a:	e9 e7 00 00 00       	jmp    c0103c66 <get_pte+0x137>
        }
        set_page_ref(page, 1);                              //给分配的物理内存页引用的计数更新
c0103b7f:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
c0103b86:	00 
c0103b87:	8b 45 f0             	mov    -0x10(%ebp),%eax
c0103b8a:	89 04 24             	mov    %eax,(%esp)
c0103b8d:	e8 c2 f6 ff ff       	call   c0103254 <set_page_ref>
        uintptr_t pa = page2pa(page);                       //该物理页对应的pa
c0103b92:	8b 45 f0             	mov    -0x10(%ebp),%eax
c0103b95:	89 04 24             	mov    %eax,(%esp)
c0103b98:	e8 a8 f5 ff ff       	call   c0103145 <page2pa>
c0103b9d:	89 45 ec             	mov    %eax,-0x14(%ebp)
        memset(KADDR(pa), 0, PGSIZE);                       //物理页全部初始化为0(需要先用KADDR转换为内核虚拟地址) 这里面都是用va做运算的，所以转换为va
c0103ba0:	8b 45 ec             	mov    -0x14(%ebp),%eax
c0103ba3:	89 45 e8             	mov    %eax,-0x18(%ebp)
c0103ba6:	8b 45 e8             	mov    -0x18(%ebp),%eax
c0103ba9:	c1 e8 0c             	shr    $0xc,%eax
c0103bac:	89 45 e4             	mov    %eax,-0x1c(%ebp)
c0103baf:	a1 80 8f 12 c0       	mov    0xc0128f80,%eax
c0103bb4:	39 45 e4             	cmp    %eax,-0x1c(%ebp)
c0103bb7:	72 23                	jb     c0103bdc <get_pte+0xad>
c0103bb9:	8b 45 e8             	mov    -0x18(%ebp),%eax
c0103bbc:	89 44 24 0c          	mov    %eax,0xc(%esp)
c0103bc0:	c7 44 24 08 60 a6 10 	movl   $0xc010a660,0x8(%esp)
c0103bc7:	c0 
c0103bc8:	c7 44 24 04 83 01 00 	movl   $0x183,0x4(%esp)
c0103bcf:	00 
c0103bd0:	c7 04 24 28 a7 10 c0 	movl   $0xc010a728,(%esp)
c0103bd7:	e8 24 c8 ff ff       	call   c0100400 <__panic>
c0103bdc:	8b 45 e8             	mov    -0x18(%ebp),%eax
c0103bdf:	2d 00 00 00 40       	sub    $0x40000000,%eax
c0103be4:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
c0103beb:	00 
c0103bec:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
c0103bf3:	00 
c0103bf4:	89 04 24             	mov    %eax,(%esp)
c0103bf7:	e8 a7 58 00 00       	call   c01094a3 <memset>
        *pdep = pa | PTE_U | PTE_W | PTE_P;                 //pa的地址，用户级，可写，存在，得到pde指针
c0103bfc:	8b 45 ec             	mov    -0x14(%ebp),%eax
c0103bff:	83 c8 07             	or     $0x7,%eax
c0103c02:	89 c2                	mov    %eax,%edx
c0103c04:	8b 45 f4             	mov    -0xc(%ebp),%eax
c0103c07:	89 10                	mov    %edx,(%eax)
    }
    return &((pte_t *)KADDR(PDE_ADDR(*pdep)))[PTX(la)];     //*pdep存页表基址（低12位为0），转为虚拟基址，加上la中间10位偏移得到pte指针
c0103c09:	8b 45 f4             	mov    -0xc(%ebp),%eax
c0103c0c:	8b 00                	mov    (%eax),%eax
c0103c0e:	25 00 f0 ff ff       	and    $0xfffff000,%eax
c0103c13:	89 45 e0             	mov    %eax,-0x20(%ebp)
c0103c16:	8b 45 e0             	mov    -0x20(%ebp),%eax
c0103c19:	c1 e8 0c             	shr    $0xc,%eax
c0103c1c:	89 45 dc             	mov    %eax,-0x24(%ebp)
c0103c1f:	a1 80 8f 12 c0       	mov    0xc0128f80,%eax
c0103c24:	39 45 dc             	cmp    %eax,-0x24(%ebp)
c0103c27:	72 23                	jb     c0103c4c <get_pte+0x11d>
c0103c29:	8b 45 e0             	mov    -0x20(%ebp),%eax
c0103c2c:	89 44 24 0c          	mov    %eax,0xc(%esp)
c0103c30:	c7 44 24 08 60 a6 10 	movl   $0xc010a660,0x8(%esp)
c0103c37:	c0 
c0103c38:	c7 44 24 04 86 01 00 	movl   $0x186,0x4(%esp)
c0103c3f:	00 
c0103c40:	c7 04 24 28 a7 10 c0 	movl   $0xc010a728,(%esp)
c0103c47:	e8 b4 c7 ff ff       	call   c0100400 <__panic>
c0103c4c:	8b 45 e0             	mov    -0x20(%ebp),%eax
c0103c4f:	2d 00 00 00 40       	sub    $0x40000000,%eax
c0103c54:	89 c2                	mov    %eax,%edx
c0103c56:	8b 45 0c             	mov    0xc(%ebp),%eax
c0103c59:	c1 e8 0c             	shr    $0xc,%eax
c0103c5c:	25 ff 03 00 00       	and    $0x3ff,%eax
c0103c61:	c1 e0 02             	shl    $0x2,%eax
c0103c64:	01 d0                	add    %edx,%eax
}
c0103c66:	c9                   	leave  
c0103c67:	c3                   	ret    

c0103c68 <get_page>:

//get_page - get related Page struct for linear address la using PDT pgdir
struct Page *
get_page(pde_t *pgdir, uintptr_t la, pte_t **ptep_store) {
c0103c68:	55                   	push   %ebp
c0103c69:	89 e5                	mov    %esp,%ebp
c0103c6b:	83 ec 28             	sub    $0x28,%esp
    pte_t *ptep = get_pte(pgdir, la, 0);     //为啥create是0？ 找不着不创建（page_insert才会创建）
c0103c6e:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
c0103c75:	00 
c0103c76:	8b 45 0c             	mov    0xc(%ebp),%eax
c0103c79:	89 44 24 04          	mov    %eax,0x4(%esp)
c0103c7d:	8b 45 08             	mov    0x8(%ebp),%eax
c0103c80:	89 04 24             	mov    %eax,(%esp)
c0103c83:	e8 a7 fe ff ff       	call   c0103b2f <get_pte>
c0103c88:	89 45 f4             	mov    %eax,-0xc(%ebp)
    if (ptep_store != NULL) {
c0103c8b:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
c0103c8f:	74 08                	je     c0103c99 <get_page+0x31>
        *ptep_store = ptep;
c0103c91:	8b 45 10             	mov    0x10(%ebp),%eax
c0103c94:	8b 55 f4             	mov    -0xc(%ebp),%edx
c0103c97:	89 10                	mov    %edx,(%eax)
    }
    if (ptep != NULL && *ptep & PTE_P) {
c0103c99:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
c0103c9d:	74 1b                	je     c0103cba <get_page+0x52>
c0103c9f:	8b 45 f4             	mov    -0xc(%ebp),%eax
c0103ca2:	8b 00                	mov    (%eax),%eax
c0103ca4:	83 e0 01             	and    $0x1,%eax
c0103ca7:	85 c0                	test   %eax,%eax
c0103ca9:	74 0f                	je     c0103cba <get_page+0x52>
        return pte2page(*ptep);
c0103cab:	8b 45 f4             	mov    -0xc(%ebp),%eax
c0103cae:	8b 00                	mov    (%eax),%eax
c0103cb0:	89 04 24             	mov    %eax,(%esp)
c0103cb3:	e8 3c f5 ff ff       	call   c01031f4 <pte2page>
c0103cb8:	eb 05                	jmp    c0103cbf <get_page+0x57>
    }
    return NULL;
c0103cba:	b8 00 00 00 00       	mov    $0x0,%eax
}
c0103cbf:	c9                   	leave  
c0103cc0:	c3                   	ret    

c0103cc1 <page_remove_pte>:

//page_remove_pte - free an Page sturct which is related linear address la
//                - and clean(invalidate) pte which is related linear address la
//note: PT is changed, so the TLB need to be invalidate 
static inline void
page_remove_pte(pde_t *pgdir, uintptr_t la, pte_t *ptep) {
c0103cc1:	55                   	push   %ebp
c0103cc2:	89 e5                	mov    %esp,%ebp
c0103cc4:	83 ec 28             	sub    $0x28,%esp
                                  //(4) and free this page when page reference reachs 0
                                  //(5) clear second page table entry
                                  //(6) flush tlb
    }
#endif
    if (*ptep & PTE_P) {                        //按位与，检查PTE_P
c0103cc7:	8b 45 10             	mov    0x10(%ebp),%eax
c0103cca:	8b 00                	mov    (%eax),%eax
c0103ccc:	83 e0 01             	and    $0x1,%eax
c0103ccf:	85 c0                	test   %eax,%eax
c0103cd1:	74 4d                	je     c0103d20 <page_remove_pte+0x5f>
        struct Page *page = pte2page(*ptep);    //获得*ptep对应的Page结构
c0103cd3:	8b 45 10             	mov    0x10(%ebp),%eax
c0103cd6:	8b 00                	mov    (%eax),%eax
c0103cd8:	89 04 24             	mov    %eax,(%esp)
c0103cdb:	e8 14 f5 ff ff       	call   c01031f4 <pte2page>
c0103ce0:	89 45 f4             	mov    %eax,-0xc(%ebp)
        if (page_ref_dec(page) == 0) {          //page引用数自减1，page_ref_dec的返回值是现在的page->ref
c0103ce3:	8b 45 f4             	mov    -0xc(%ebp),%eax
c0103ce6:	89 04 24             	mov    %eax,(%esp)
c0103ce9:	e8 8b f5 ff ff       	call   c0103279 <page_ref_dec>
c0103cee:	85 c0                	test   %eax,%eax
c0103cf0:	75 13                	jne    c0103d05 <page_remove_pte+0x44>
            free_page(page);                    // 如果自减1后，引用数为0，需要free释放掉该物理页
c0103cf2:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
c0103cf9:	00 
c0103cfa:	8b 45 f4             	mov    -0xc(%ebp),%eax
c0103cfd:	89 04 24             	mov    %eax,(%esp)
c0103d00:	e8 b5 f7 ff ff       	call   c01034ba <free_pages>
        }
        *ptep = 0;                              //把虚地址与物理地址对应关系的二级页表项清除(通过把整体设置为0)
c0103d05:	8b 45 10             	mov    0x10(%ebp),%eax
c0103d08:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
        tlb_invalidate(pgdir, la);              //由于页表项发生了改变，需要使TLB快表无效
c0103d0e:	8b 45 0c             	mov    0xc(%ebp),%eax
c0103d11:	89 44 24 04          	mov    %eax,0x4(%esp)
c0103d15:	8b 45 08             	mov    0x8(%ebp),%eax
c0103d18:	89 04 24             	mov    %eax,(%esp)
c0103d1b:	e8 01 01 00 00       	call   c0103e21 <tlb_invalidate>
    }
}
c0103d20:	90                   	nop
c0103d21:	c9                   	leave  
c0103d22:	c3                   	ret    

c0103d23 <page_remove>:

//page_remove - free an Page which is related linear address la and has an validated pte
void
page_remove(pde_t *pgdir, uintptr_t la) {
c0103d23:	55                   	push   %ebp
c0103d24:	89 e5                	mov    %esp,%ebp
c0103d26:	83 ec 28             	sub    $0x28,%esp
    pte_t *ptep = get_pte(pgdir, la, 0);     //找不着不创建（page_insert才会创建）
c0103d29:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
c0103d30:	00 
c0103d31:	8b 45 0c             	mov    0xc(%ebp),%eax
c0103d34:	89 44 24 04          	mov    %eax,0x4(%esp)
c0103d38:	8b 45 08             	mov    0x8(%ebp),%eax
c0103d3b:	89 04 24             	mov    %eax,(%esp)
c0103d3e:	e8 ec fd ff ff       	call   c0103b2f <get_pte>
c0103d43:	89 45 f4             	mov    %eax,-0xc(%ebp)
    if (ptep != NULL) {
c0103d46:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
c0103d4a:	74 19                	je     c0103d65 <page_remove+0x42>
        page_remove_pte(pgdir, la, ptep);    //移除这个查到的pte
c0103d4c:	8b 45 f4             	mov    -0xc(%ebp),%eax
c0103d4f:	89 44 24 08          	mov    %eax,0x8(%esp)
c0103d53:	8b 45 0c             	mov    0xc(%ebp),%eax
c0103d56:	89 44 24 04          	mov    %eax,0x4(%esp)
c0103d5a:	8b 45 08             	mov    0x8(%ebp),%eax
c0103d5d:	89 04 24             	mov    %eax,(%esp)
c0103d60:	e8 5c ff ff ff       	call   c0103cc1 <page_remove_pte>
    }
}
c0103d65:	90                   	nop
c0103d66:	c9                   	leave  
c0103d67:	c3                   	ret    

c0103d68 <page_insert>:
//  la:    the linear address need to map
//  perm:  the permission of this Page which is setted in related pte
// return value: always 0
//note: PT is changed, so the TLB need to be invalidate 
int
page_insert(pde_t *pgdir, struct Page *page, uintptr_t la, uint32_t perm) {
c0103d68:	55                   	push   %ebp
c0103d69:	89 e5                	mov    %esp,%ebp
c0103d6b:	83 ec 28             	sub    $0x28,%esp
    pte_t *ptep = get_pte(pgdir, la, 1);        //creat为1，找不着不创建
c0103d6e:	c7 44 24 08 01 00 00 	movl   $0x1,0x8(%esp)
c0103d75:	00 
c0103d76:	8b 45 10             	mov    0x10(%ebp),%eax
c0103d79:	89 44 24 04          	mov    %eax,0x4(%esp)
c0103d7d:	8b 45 08             	mov    0x8(%ebp),%eax
c0103d80:	89 04 24             	mov    %eax,(%esp)
c0103d83:	e8 a7 fd ff ff       	call   c0103b2f <get_pte>
c0103d88:	89 45 f4             	mov    %eax,-0xc(%ebp)
    if (ptep == NULL) {
c0103d8b:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
c0103d8f:	75 0a                	jne    c0103d9b <page_insert+0x33>
        return -E_NO_MEM;
c0103d91:	b8 fc ff ff ff       	mov    $0xfffffffc,%eax
c0103d96:	e9 84 00 00 00       	jmp    c0103e1f <page_insert+0xb7>
    }
    page_ref_inc(page);                         //ref暂且++
c0103d9b:	8b 45 0c             	mov    0xc(%ebp),%eax
c0103d9e:	89 04 24             	mov    %eax,(%esp)
c0103da1:	e8 bc f4 ff ff       	call   c0103262 <page_ref_inc>
    if (*ptep & PTE_P) {                        //若get_pte找着了
c0103da6:	8b 45 f4             	mov    -0xc(%ebp),%eax
c0103da9:	8b 00                	mov    (%eax),%eax
c0103dab:	83 e0 01             	and    $0x1,%eax
c0103dae:	85 c0                	test   %eax,%eax
c0103db0:	74 3e                	je     c0103df0 <page_insert+0x88>
        struct Page *p = pte2page(*ptep);
c0103db2:	8b 45 f4             	mov    -0xc(%ebp),%eax
c0103db5:	8b 00                	mov    (%eax),%eax
c0103db7:	89 04 24             	mov    %eax,(%esp)
c0103dba:	e8 35 f4 ff ff       	call   c01031f4 <pte2page>
c0103dbf:	89 45 f0             	mov    %eax,-0x10(%ebp)
        if (p == page) {                        //比较旧pte对应的p和要加的page等不等
c0103dc2:	8b 45 f0             	mov    -0x10(%ebp),%eax
c0103dc5:	3b 45 0c             	cmp    0xc(%ebp),%eax
c0103dc8:	75 0d                	jne    c0103dd7 <page_insert+0x6f>
            page_ref_dec(page);                 //相等，还是原来map映射，把多加的ref减回去
c0103dca:	8b 45 0c             	mov    0xc(%ebp),%eax
c0103dcd:	89 04 24             	mov    %eax,(%esp)
c0103dd0:	e8 a4 f4 ff ff       	call   c0103279 <page_ref_dec>
c0103dd5:	eb 19                	jmp    c0103df0 <page_insert+0x88>
        }
        else {
            page_remove_pte(pgdir, la, ptep);   //不等，删掉旧pte，换成新的pte
c0103dd7:	8b 45 f4             	mov    -0xc(%ebp),%eax
c0103dda:	89 44 24 08          	mov    %eax,0x8(%esp)
c0103dde:	8b 45 10             	mov    0x10(%ebp),%eax
c0103de1:	89 44 24 04          	mov    %eax,0x4(%esp)
c0103de5:	8b 45 08             	mov    0x8(%ebp),%eax
c0103de8:	89 04 24             	mov    %eax,(%esp)
c0103deb:	e8 d1 fe ff ff       	call   c0103cc1 <page_remove_pte>
        }
    }
    *ptep = page2pa(page) | PTE_P | perm;       //创pte或换新的pte
c0103df0:	8b 45 0c             	mov    0xc(%ebp),%eax
c0103df3:	89 04 24             	mov    %eax,(%esp)
c0103df6:	e8 4a f3 ff ff       	call   c0103145 <page2pa>
c0103dfb:	0b 45 14             	or     0x14(%ebp),%eax
c0103dfe:	83 c8 01             	or     $0x1,%eax
c0103e01:	89 c2                	mov    %eax,%edx
c0103e03:	8b 45 f4             	mov    -0xc(%ebp),%eax
c0103e06:	89 10                	mov    %edx,(%eax)
    tlb_invalidate(pgdir, la);                  //由于页表项发生了改变，需要使TLB快表无效
c0103e08:	8b 45 10             	mov    0x10(%ebp),%eax
c0103e0b:	89 44 24 04          	mov    %eax,0x4(%esp)
c0103e0f:	8b 45 08             	mov    0x8(%ebp),%eax
c0103e12:	89 04 24             	mov    %eax,(%esp)
c0103e15:	e8 07 00 00 00       	call   c0103e21 <tlb_invalidate>
    return 0;
c0103e1a:	b8 00 00 00 00       	mov    $0x0,%eax
}
c0103e1f:	c9                   	leave  
c0103e20:	c3                   	ret    

c0103e21 <tlb_invalidate>:

// invalidate a TLB entry, but only if the page tables being
// edited are the ones currently in use by the processor.
void
tlb_invalidate(pde_t *pgdir, uintptr_t la) {
c0103e21:	55                   	push   %ebp
c0103e22:	89 e5                	mov    %esp,%ebp
c0103e24:	83 ec 28             	sub    $0x28,%esp
}

static inline uintptr_t
rcr3(void) {
    uintptr_t cr3;
    asm volatile ("mov %%cr3, %0" : "=r" (cr3) :: "memory");
c0103e27:	0f 20 d8             	mov    %cr3,%eax
c0103e2a:	89 45 f0             	mov    %eax,-0x10(%ebp)
    return cr3;
c0103e2d:	8b 55 f0             	mov    -0x10(%ebp),%edx
    if (rcr3() == PADDR(pgdir)) {
c0103e30:	8b 45 08             	mov    0x8(%ebp),%eax
c0103e33:	89 45 f4             	mov    %eax,-0xc(%ebp)
c0103e36:	81 7d f4 ff ff ff bf 	cmpl   $0xbfffffff,-0xc(%ebp)
c0103e3d:	77 23                	ja     c0103e62 <tlb_invalidate+0x41>
c0103e3f:	8b 45 f4             	mov    -0xc(%ebp),%eax
c0103e42:	89 44 24 0c          	mov    %eax,0xc(%esp)
c0103e46:	c7 44 24 08 04 a7 10 	movl   $0xc010a704,0x8(%esp)
c0103e4d:	c0 
c0103e4e:	c7 44 24 04 e8 01 00 	movl   $0x1e8,0x4(%esp)
c0103e55:	00 
c0103e56:	c7 04 24 28 a7 10 c0 	movl   $0xc010a728,(%esp)
c0103e5d:	e8 9e c5 ff ff       	call   c0100400 <__panic>
c0103e62:	8b 45 f4             	mov    -0xc(%ebp),%eax
c0103e65:	05 00 00 00 40       	add    $0x40000000,%eax
c0103e6a:	39 d0                	cmp    %edx,%eax
c0103e6c:	75 0c                	jne    c0103e7a <tlb_invalidate+0x59>
        invlpg((void *)la);
c0103e6e:	8b 45 0c             	mov    0xc(%ebp),%eax
c0103e71:	89 45 ec             	mov    %eax,-0x14(%ebp)
}

static inline void
invlpg(void *addr) {
    asm volatile ("invlpg (%0)" :: "r" (addr) : "memory");
c0103e74:	8b 45 ec             	mov    -0x14(%ebp),%eax
c0103e77:	0f 01 38             	invlpg (%eax)
    }
}
c0103e7a:	90                   	nop
c0103e7b:	c9                   	leave  
c0103e7c:	c3                   	ret    

c0103e7d <pgdir_alloc_page>:

// pgdir_alloc_page - call alloc_page & page_insert functions to 
//                  - allocate a page size memory & setup an addr map
//                  - pa<->la with linear address la and the PDT pgdir
struct Page *
pgdir_alloc_page(pde_t *pgdir, uintptr_t la, uint32_t perm) {
c0103e7d:	55                   	push   %ebp
c0103e7e:	89 e5                	mov    %esp,%ebp
c0103e80:	83 ec 28             	sub    $0x28,%esp
    struct Page *page = alloc_page();   //可能没空闲，会消极换出
c0103e83:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
c0103e8a:	e8 c0 f5 ff ff       	call   c010344f <alloc_pages>
c0103e8f:	89 45 f4             	mov    %eax,-0xc(%ebp)
    if (page != NULL) {
c0103e92:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
c0103e96:	0f 84 a7 00 00 00    	je     c0103f43 <pgdir_alloc_page+0xc6>
        if (page_insert(pgdir, page, la, perm) != 0) {      //正常返回0，表示成功插入页，正确建立va-pa的映射关系
c0103e9c:	8b 45 10             	mov    0x10(%ebp),%eax
c0103e9f:	89 44 24 0c          	mov    %eax,0xc(%esp)
c0103ea3:	8b 45 0c             	mov    0xc(%ebp),%eax
c0103ea6:	89 44 24 08          	mov    %eax,0x8(%esp)
c0103eaa:	8b 45 f4             	mov    -0xc(%ebp),%eax
c0103ead:	89 44 24 04          	mov    %eax,0x4(%esp)
c0103eb1:	8b 45 08             	mov    0x8(%ebp),%eax
c0103eb4:	89 04 24             	mov    %eax,(%esp)
c0103eb7:	e8 ac fe ff ff       	call   c0103d68 <page_insert>
c0103ebc:	85 c0                	test   %eax,%eax
c0103ebe:	74 1a                	je     c0103eda <pgdir_alloc_page+0x5d>
            free_page(page);
c0103ec0:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
c0103ec7:	00 
c0103ec8:	8b 45 f4             	mov    -0xc(%ebp),%eax
c0103ecb:	89 04 24             	mov    %eax,(%esp)
c0103ece:	e8 e7 f5 ff ff       	call   c01034ba <free_pages>
            return NULL;
c0103ed3:	b8 00 00 00 00       	mov    $0x0,%eax
c0103ed8:	eb 6c                	jmp    c0103f46 <pgdir_alloc_page+0xc9>
        }
        if (swap_init_ok){
c0103eda:	a1 14 90 12 c0       	mov    0xc0129014,%eax
c0103edf:	85 c0                	test   %eax,%eax
c0103ee1:	74 60                	je     c0103f43 <pgdir_alloc_page+0xc6>
            swap_map_swappable(check_mm_struct, la, page, 0);//把page链表项加入构造访问的队列
c0103ee3:	a1 6c b0 12 c0       	mov    0xc012b06c,%eax
c0103ee8:	c7 44 24 0c 00 00 00 	movl   $0x0,0xc(%esp)
c0103eef:	00 
c0103ef0:	8b 55 f4             	mov    -0xc(%ebp),%edx
c0103ef3:	89 54 24 08          	mov    %edx,0x8(%esp)
c0103ef7:	8b 55 0c             	mov    0xc(%ebp),%edx
c0103efa:	89 54 24 04          	mov    %edx,0x4(%esp)
c0103efe:	89 04 24             	mov    %eax,(%esp)
c0103f01:	e8 f7 27 00 00       	call   c01066fd <swap_map_swappable>
            page->pra_vaddr=la;
c0103f06:	8b 45 f4             	mov    -0xc(%ebp),%eax
c0103f09:	8b 55 0c             	mov    0xc(%ebp),%edx
c0103f0c:	89 50 1c             	mov    %edx,0x1c(%eax)
            assert(page_ref(page) == 1);
c0103f0f:	8b 45 f4             	mov    -0xc(%ebp),%eax
c0103f12:	89 04 24             	mov    %eax,(%esp)
c0103f15:	e8 30 f3 ff ff       	call   c010324a <page_ref>
c0103f1a:	83 f8 01             	cmp    $0x1,%eax
c0103f1d:	74 24                	je     c0103f43 <pgdir_alloc_page+0xc6>
c0103f1f:	c7 44 24 0c 88 a7 10 	movl   $0xc010a788,0xc(%esp)
c0103f26:	c0 
c0103f27:	c7 44 24 08 4d a7 10 	movl   $0xc010a74d,0x8(%esp)
c0103f2e:	c0 
c0103f2f:	c7 44 24 04 fb 01 00 	movl   $0x1fb,0x4(%esp)
c0103f36:	00 
c0103f37:	c7 04 24 28 a7 10 c0 	movl   $0xc010a728,(%esp)
c0103f3e:	e8 bd c4 ff ff       	call   c0100400 <__panic>
            //cprintf("get No. %d  page: pra_vaddr %x, pra_link.prev %x, pra_link_next %x in pgdir_alloc_page\n", (page-pages), page->pra_vaddr,page->pra_page_link.prev, page->pra_page_link.next);
        }

    }

    return page;
c0103f43:	8b 45 f4             	mov    -0xc(%ebp),%eax
}
c0103f46:	c9                   	leave  
c0103f47:	c3                   	ret    

c0103f48 <check_alloc_page>:

static void
check_alloc_page(void) {
c0103f48:	55                   	push   %ebp
c0103f49:	89 e5                	mov    %esp,%ebp
c0103f4b:	83 ec 18             	sub    $0x18,%esp
    pmm_manager->check();
c0103f4e:	a1 58 b0 12 c0       	mov    0xc012b058,%eax
c0103f53:	8b 40 18             	mov    0x18(%eax),%eax
c0103f56:	ff d0                	call   *%eax
    cprintf("check_alloc_page() succeeded!\n");
c0103f58:	c7 04 24 9c a7 10 c0 	movl   $0xc010a79c,(%esp)
c0103f5f:	e8 45 c3 ff ff       	call   c01002a9 <cprintf>
}
c0103f64:	90                   	nop
c0103f65:	c9                   	leave  
c0103f66:	c3                   	ret    

c0103f67 <check_pgdir>:

static void
check_pgdir(void) {
c0103f67:	55                   	push   %ebp
c0103f68:	89 e5                	mov    %esp,%ebp
c0103f6a:	83 ec 38             	sub    $0x38,%esp
    assert(npage <= KMEMSIZE / PGSIZE);
c0103f6d:	a1 80 8f 12 c0       	mov    0xc0128f80,%eax
c0103f72:	3d 00 80 03 00       	cmp    $0x38000,%eax
c0103f77:	76 24                	jbe    c0103f9d <check_pgdir+0x36>
c0103f79:	c7 44 24 0c bb a7 10 	movl   $0xc010a7bb,0xc(%esp)
c0103f80:	c0 
c0103f81:	c7 44 24 08 4d a7 10 	movl   $0xc010a74d,0x8(%esp)
c0103f88:	c0 
c0103f89:	c7 44 24 04 0c 02 00 	movl   $0x20c,0x4(%esp)
c0103f90:	00 
c0103f91:	c7 04 24 28 a7 10 c0 	movl   $0xc010a728,(%esp)
c0103f98:	e8 63 c4 ff ff       	call   c0100400 <__panic>
    assert(boot_pgdir != NULL && (uint32_t)PGOFF(boot_pgdir) == 0);
c0103f9d:	a1 e0 59 12 c0       	mov    0xc01259e0,%eax
c0103fa2:	85 c0                	test   %eax,%eax
c0103fa4:	74 0e                	je     c0103fb4 <check_pgdir+0x4d>
c0103fa6:	a1 e0 59 12 c0       	mov    0xc01259e0,%eax
c0103fab:	25 ff 0f 00 00       	and    $0xfff,%eax
c0103fb0:	85 c0                	test   %eax,%eax
c0103fb2:	74 24                	je     c0103fd8 <check_pgdir+0x71>
c0103fb4:	c7 44 24 0c d8 a7 10 	movl   $0xc010a7d8,0xc(%esp)
c0103fbb:	c0 
c0103fbc:	c7 44 24 08 4d a7 10 	movl   $0xc010a74d,0x8(%esp)
c0103fc3:	c0 
c0103fc4:	c7 44 24 04 0d 02 00 	movl   $0x20d,0x4(%esp)
c0103fcb:	00 
c0103fcc:	c7 04 24 28 a7 10 c0 	movl   $0xc010a728,(%esp)
c0103fd3:	e8 28 c4 ff ff       	call   c0100400 <__panic>
    assert(get_page(boot_pgdir, 0x0, NULL) == NULL);
c0103fd8:	a1 e0 59 12 c0       	mov    0xc01259e0,%eax
c0103fdd:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
c0103fe4:	00 
c0103fe5:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
c0103fec:	00 
c0103fed:	89 04 24             	mov    %eax,(%esp)
c0103ff0:	e8 73 fc ff ff       	call   c0103c68 <get_page>
c0103ff5:	85 c0                	test   %eax,%eax
c0103ff7:	74 24                	je     c010401d <check_pgdir+0xb6>
c0103ff9:	c7 44 24 0c 10 a8 10 	movl   $0xc010a810,0xc(%esp)
c0104000:	c0 
c0104001:	c7 44 24 08 4d a7 10 	movl   $0xc010a74d,0x8(%esp)
c0104008:	c0 
c0104009:	c7 44 24 04 0e 02 00 	movl   $0x20e,0x4(%esp)
c0104010:	00 
c0104011:	c7 04 24 28 a7 10 c0 	movl   $0xc010a728,(%esp)
c0104018:	e8 e3 c3 ff ff       	call   c0100400 <__panic>

    struct Page *p1, *p2;
    p1 = alloc_page();
c010401d:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
c0104024:	e8 26 f4 ff ff       	call   c010344f <alloc_pages>
c0104029:	89 45 f4             	mov    %eax,-0xc(%ebp)
    assert(page_insert(boot_pgdir, p1, 0x0, 0) == 0);
c010402c:	a1 e0 59 12 c0       	mov    0xc01259e0,%eax
c0104031:	c7 44 24 0c 00 00 00 	movl   $0x0,0xc(%esp)
c0104038:	00 
c0104039:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
c0104040:	00 
c0104041:	8b 55 f4             	mov    -0xc(%ebp),%edx
c0104044:	89 54 24 04          	mov    %edx,0x4(%esp)
c0104048:	89 04 24             	mov    %eax,(%esp)
c010404b:	e8 18 fd ff ff       	call   c0103d68 <page_insert>
c0104050:	85 c0                	test   %eax,%eax
c0104052:	74 24                	je     c0104078 <check_pgdir+0x111>
c0104054:	c7 44 24 0c 38 a8 10 	movl   $0xc010a838,0xc(%esp)
c010405b:	c0 
c010405c:	c7 44 24 08 4d a7 10 	movl   $0xc010a74d,0x8(%esp)
c0104063:	c0 
c0104064:	c7 44 24 04 12 02 00 	movl   $0x212,0x4(%esp)
c010406b:	00 
c010406c:	c7 04 24 28 a7 10 c0 	movl   $0xc010a728,(%esp)
c0104073:	e8 88 c3 ff ff       	call   c0100400 <__panic>

    pte_t *ptep;
    assert((ptep = get_pte(boot_pgdir, 0x0, 0)) != NULL);
c0104078:	a1 e0 59 12 c0       	mov    0xc01259e0,%eax
c010407d:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
c0104084:	00 
c0104085:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
c010408c:	00 
c010408d:	89 04 24             	mov    %eax,(%esp)
c0104090:	e8 9a fa ff ff       	call   c0103b2f <get_pte>
c0104095:	89 45 f0             	mov    %eax,-0x10(%ebp)
c0104098:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
c010409c:	75 24                	jne    c01040c2 <check_pgdir+0x15b>
c010409e:	c7 44 24 0c 64 a8 10 	movl   $0xc010a864,0xc(%esp)
c01040a5:	c0 
c01040a6:	c7 44 24 08 4d a7 10 	movl   $0xc010a74d,0x8(%esp)
c01040ad:	c0 
c01040ae:	c7 44 24 04 15 02 00 	movl   $0x215,0x4(%esp)
c01040b5:	00 
c01040b6:	c7 04 24 28 a7 10 c0 	movl   $0xc010a728,(%esp)
c01040bd:	e8 3e c3 ff ff       	call   c0100400 <__panic>
    assert(pte2page(*ptep) == p1);
c01040c2:	8b 45 f0             	mov    -0x10(%ebp),%eax
c01040c5:	8b 00                	mov    (%eax),%eax
c01040c7:	89 04 24             	mov    %eax,(%esp)
c01040ca:	e8 25 f1 ff ff       	call   c01031f4 <pte2page>
c01040cf:	39 45 f4             	cmp    %eax,-0xc(%ebp)
c01040d2:	74 24                	je     c01040f8 <check_pgdir+0x191>
c01040d4:	c7 44 24 0c 91 a8 10 	movl   $0xc010a891,0xc(%esp)
c01040db:	c0 
c01040dc:	c7 44 24 08 4d a7 10 	movl   $0xc010a74d,0x8(%esp)
c01040e3:	c0 
c01040e4:	c7 44 24 04 16 02 00 	movl   $0x216,0x4(%esp)
c01040eb:	00 
c01040ec:	c7 04 24 28 a7 10 c0 	movl   $0xc010a728,(%esp)
c01040f3:	e8 08 c3 ff ff       	call   c0100400 <__panic>
    assert(page_ref(p1) == 1);
c01040f8:	8b 45 f4             	mov    -0xc(%ebp),%eax
c01040fb:	89 04 24             	mov    %eax,(%esp)
c01040fe:	e8 47 f1 ff ff       	call   c010324a <page_ref>
c0104103:	83 f8 01             	cmp    $0x1,%eax
c0104106:	74 24                	je     c010412c <check_pgdir+0x1c5>
c0104108:	c7 44 24 0c a7 a8 10 	movl   $0xc010a8a7,0xc(%esp)
c010410f:	c0 
c0104110:	c7 44 24 08 4d a7 10 	movl   $0xc010a74d,0x8(%esp)
c0104117:	c0 
c0104118:	c7 44 24 04 17 02 00 	movl   $0x217,0x4(%esp)
c010411f:	00 
c0104120:	c7 04 24 28 a7 10 c0 	movl   $0xc010a728,(%esp)
c0104127:	e8 d4 c2 ff ff       	call   c0100400 <__panic>

    ptep = &((pte_t *)KADDR(PDE_ADDR(boot_pgdir[0])))[1];
c010412c:	a1 e0 59 12 c0       	mov    0xc01259e0,%eax
c0104131:	8b 00                	mov    (%eax),%eax
c0104133:	25 00 f0 ff ff       	and    $0xfffff000,%eax
c0104138:	89 45 ec             	mov    %eax,-0x14(%ebp)
c010413b:	8b 45 ec             	mov    -0x14(%ebp),%eax
c010413e:	c1 e8 0c             	shr    $0xc,%eax
c0104141:	89 45 e8             	mov    %eax,-0x18(%ebp)
c0104144:	a1 80 8f 12 c0       	mov    0xc0128f80,%eax
c0104149:	39 45 e8             	cmp    %eax,-0x18(%ebp)
c010414c:	72 23                	jb     c0104171 <check_pgdir+0x20a>
c010414e:	8b 45 ec             	mov    -0x14(%ebp),%eax
c0104151:	89 44 24 0c          	mov    %eax,0xc(%esp)
c0104155:	c7 44 24 08 60 a6 10 	movl   $0xc010a660,0x8(%esp)
c010415c:	c0 
c010415d:	c7 44 24 04 19 02 00 	movl   $0x219,0x4(%esp)
c0104164:	00 
c0104165:	c7 04 24 28 a7 10 c0 	movl   $0xc010a728,(%esp)
c010416c:	e8 8f c2 ff ff       	call   c0100400 <__panic>
c0104171:	8b 45 ec             	mov    -0x14(%ebp),%eax
c0104174:	2d 00 00 00 40       	sub    $0x40000000,%eax
c0104179:	83 c0 04             	add    $0x4,%eax
c010417c:	89 45 f0             	mov    %eax,-0x10(%ebp)
    assert(get_pte(boot_pgdir, PGSIZE, 0) == ptep);
c010417f:	a1 e0 59 12 c0       	mov    0xc01259e0,%eax
c0104184:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
c010418b:	00 
c010418c:	c7 44 24 04 00 10 00 	movl   $0x1000,0x4(%esp)
c0104193:	00 
c0104194:	89 04 24             	mov    %eax,(%esp)
c0104197:	e8 93 f9 ff ff       	call   c0103b2f <get_pte>
c010419c:	39 45 f0             	cmp    %eax,-0x10(%ebp)
c010419f:	74 24                	je     c01041c5 <check_pgdir+0x25e>
c01041a1:	c7 44 24 0c bc a8 10 	movl   $0xc010a8bc,0xc(%esp)
c01041a8:	c0 
c01041a9:	c7 44 24 08 4d a7 10 	movl   $0xc010a74d,0x8(%esp)
c01041b0:	c0 
c01041b1:	c7 44 24 04 1a 02 00 	movl   $0x21a,0x4(%esp)
c01041b8:	00 
c01041b9:	c7 04 24 28 a7 10 c0 	movl   $0xc010a728,(%esp)
c01041c0:	e8 3b c2 ff ff       	call   c0100400 <__panic>

    p2 = alloc_page();
c01041c5:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
c01041cc:	e8 7e f2 ff ff       	call   c010344f <alloc_pages>
c01041d1:	89 45 e4             	mov    %eax,-0x1c(%ebp)
    assert(page_insert(boot_pgdir, p2, PGSIZE, PTE_U | PTE_W) == 0);
c01041d4:	a1 e0 59 12 c0       	mov    0xc01259e0,%eax
c01041d9:	c7 44 24 0c 06 00 00 	movl   $0x6,0xc(%esp)
c01041e0:	00 
c01041e1:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
c01041e8:	00 
c01041e9:	8b 55 e4             	mov    -0x1c(%ebp),%edx
c01041ec:	89 54 24 04          	mov    %edx,0x4(%esp)
c01041f0:	89 04 24             	mov    %eax,(%esp)
c01041f3:	e8 70 fb ff ff       	call   c0103d68 <page_insert>
c01041f8:	85 c0                	test   %eax,%eax
c01041fa:	74 24                	je     c0104220 <check_pgdir+0x2b9>
c01041fc:	c7 44 24 0c e4 a8 10 	movl   $0xc010a8e4,0xc(%esp)
c0104203:	c0 
c0104204:	c7 44 24 08 4d a7 10 	movl   $0xc010a74d,0x8(%esp)
c010420b:	c0 
c010420c:	c7 44 24 04 1d 02 00 	movl   $0x21d,0x4(%esp)
c0104213:	00 
c0104214:	c7 04 24 28 a7 10 c0 	movl   $0xc010a728,(%esp)
c010421b:	e8 e0 c1 ff ff       	call   c0100400 <__panic>
    assert((ptep = get_pte(boot_pgdir, PGSIZE, 0)) != NULL);
c0104220:	a1 e0 59 12 c0       	mov    0xc01259e0,%eax
c0104225:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
c010422c:	00 
c010422d:	c7 44 24 04 00 10 00 	movl   $0x1000,0x4(%esp)
c0104234:	00 
c0104235:	89 04 24             	mov    %eax,(%esp)
c0104238:	e8 f2 f8 ff ff       	call   c0103b2f <get_pte>
c010423d:	89 45 f0             	mov    %eax,-0x10(%ebp)
c0104240:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
c0104244:	75 24                	jne    c010426a <check_pgdir+0x303>
c0104246:	c7 44 24 0c 1c a9 10 	movl   $0xc010a91c,0xc(%esp)
c010424d:	c0 
c010424e:	c7 44 24 08 4d a7 10 	movl   $0xc010a74d,0x8(%esp)
c0104255:	c0 
c0104256:	c7 44 24 04 1e 02 00 	movl   $0x21e,0x4(%esp)
c010425d:	00 
c010425e:	c7 04 24 28 a7 10 c0 	movl   $0xc010a728,(%esp)
c0104265:	e8 96 c1 ff ff       	call   c0100400 <__panic>
    assert(*ptep & PTE_U);
c010426a:	8b 45 f0             	mov    -0x10(%ebp),%eax
c010426d:	8b 00                	mov    (%eax),%eax
c010426f:	83 e0 04             	and    $0x4,%eax
c0104272:	85 c0                	test   %eax,%eax
c0104274:	75 24                	jne    c010429a <check_pgdir+0x333>
c0104276:	c7 44 24 0c 4c a9 10 	movl   $0xc010a94c,0xc(%esp)
c010427d:	c0 
c010427e:	c7 44 24 08 4d a7 10 	movl   $0xc010a74d,0x8(%esp)
c0104285:	c0 
c0104286:	c7 44 24 04 1f 02 00 	movl   $0x21f,0x4(%esp)
c010428d:	00 
c010428e:	c7 04 24 28 a7 10 c0 	movl   $0xc010a728,(%esp)
c0104295:	e8 66 c1 ff ff       	call   c0100400 <__panic>
    assert(*ptep & PTE_W);
c010429a:	8b 45 f0             	mov    -0x10(%ebp),%eax
c010429d:	8b 00                	mov    (%eax),%eax
c010429f:	83 e0 02             	and    $0x2,%eax
c01042a2:	85 c0                	test   %eax,%eax
c01042a4:	75 24                	jne    c01042ca <check_pgdir+0x363>
c01042a6:	c7 44 24 0c 5a a9 10 	movl   $0xc010a95a,0xc(%esp)
c01042ad:	c0 
c01042ae:	c7 44 24 08 4d a7 10 	movl   $0xc010a74d,0x8(%esp)
c01042b5:	c0 
c01042b6:	c7 44 24 04 20 02 00 	movl   $0x220,0x4(%esp)
c01042bd:	00 
c01042be:	c7 04 24 28 a7 10 c0 	movl   $0xc010a728,(%esp)
c01042c5:	e8 36 c1 ff ff       	call   c0100400 <__panic>
    assert(boot_pgdir[0] & PTE_U);
c01042ca:	a1 e0 59 12 c0       	mov    0xc01259e0,%eax
c01042cf:	8b 00                	mov    (%eax),%eax
c01042d1:	83 e0 04             	and    $0x4,%eax
c01042d4:	85 c0                	test   %eax,%eax
c01042d6:	75 24                	jne    c01042fc <check_pgdir+0x395>
c01042d8:	c7 44 24 0c 68 a9 10 	movl   $0xc010a968,0xc(%esp)
c01042df:	c0 
c01042e0:	c7 44 24 08 4d a7 10 	movl   $0xc010a74d,0x8(%esp)
c01042e7:	c0 
c01042e8:	c7 44 24 04 21 02 00 	movl   $0x221,0x4(%esp)
c01042ef:	00 
c01042f0:	c7 04 24 28 a7 10 c0 	movl   $0xc010a728,(%esp)
c01042f7:	e8 04 c1 ff ff       	call   c0100400 <__panic>
    assert(page_ref(p2) == 1);
c01042fc:	8b 45 e4             	mov    -0x1c(%ebp),%eax
c01042ff:	89 04 24             	mov    %eax,(%esp)
c0104302:	e8 43 ef ff ff       	call   c010324a <page_ref>
c0104307:	83 f8 01             	cmp    $0x1,%eax
c010430a:	74 24                	je     c0104330 <check_pgdir+0x3c9>
c010430c:	c7 44 24 0c 7e a9 10 	movl   $0xc010a97e,0xc(%esp)
c0104313:	c0 
c0104314:	c7 44 24 08 4d a7 10 	movl   $0xc010a74d,0x8(%esp)
c010431b:	c0 
c010431c:	c7 44 24 04 22 02 00 	movl   $0x222,0x4(%esp)
c0104323:	00 
c0104324:	c7 04 24 28 a7 10 c0 	movl   $0xc010a728,(%esp)
c010432b:	e8 d0 c0 ff ff       	call   c0100400 <__panic>

    assert(page_insert(boot_pgdir, p1, PGSIZE, 0) == 0);
c0104330:	a1 e0 59 12 c0       	mov    0xc01259e0,%eax
c0104335:	c7 44 24 0c 00 00 00 	movl   $0x0,0xc(%esp)
c010433c:	00 
c010433d:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
c0104344:	00 
c0104345:	8b 55 f4             	mov    -0xc(%ebp),%edx
c0104348:	89 54 24 04          	mov    %edx,0x4(%esp)
c010434c:	89 04 24             	mov    %eax,(%esp)
c010434f:	e8 14 fa ff ff       	call   c0103d68 <page_insert>
c0104354:	85 c0                	test   %eax,%eax
c0104356:	74 24                	je     c010437c <check_pgdir+0x415>
c0104358:	c7 44 24 0c 90 a9 10 	movl   $0xc010a990,0xc(%esp)
c010435f:	c0 
c0104360:	c7 44 24 08 4d a7 10 	movl   $0xc010a74d,0x8(%esp)
c0104367:	c0 
c0104368:	c7 44 24 04 24 02 00 	movl   $0x224,0x4(%esp)
c010436f:	00 
c0104370:	c7 04 24 28 a7 10 c0 	movl   $0xc010a728,(%esp)
c0104377:	e8 84 c0 ff ff       	call   c0100400 <__panic>
    assert(page_ref(p1) == 2);
c010437c:	8b 45 f4             	mov    -0xc(%ebp),%eax
c010437f:	89 04 24             	mov    %eax,(%esp)
c0104382:	e8 c3 ee ff ff       	call   c010324a <page_ref>
c0104387:	83 f8 02             	cmp    $0x2,%eax
c010438a:	74 24                	je     c01043b0 <check_pgdir+0x449>
c010438c:	c7 44 24 0c bc a9 10 	movl   $0xc010a9bc,0xc(%esp)
c0104393:	c0 
c0104394:	c7 44 24 08 4d a7 10 	movl   $0xc010a74d,0x8(%esp)
c010439b:	c0 
c010439c:	c7 44 24 04 25 02 00 	movl   $0x225,0x4(%esp)
c01043a3:	00 
c01043a4:	c7 04 24 28 a7 10 c0 	movl   $0xc010a728,(%esp)
c01043ab:	e8 50 c0 ff ff       	call   c0100400 <__panic>
    assert(page_ref(p2) == 0);
c01043b0:	8b 45 e4             	mov    -0x1c(%ebp),%eax
c01043b3:	89 04 24             	mov    %eax,(%esp)
c01043b6:	e8 8f ee ff ff       	call   c010324a <page_ref>
c01043bb:	85 c0                	test   %eax,%eax
c01043bd:	74 24                	je     c01043e3 <check_pgdir+0x47c>
c01043bf:	c7 44 24 0c ce a9 10 	movl   $0xc010a9ce,0xc(%esp)
c01043c6:	c0 
c01043c7:	c7 44 24 08 4d a7 10 	movl   $0xc010a74d,0x8(%esp)
c01043ce:	c0 
c01043cf:	c7 44 24 04 26 02 00 	movl   $0x226,0x4(%esp)
c01043d6:	00 
c01043d7:	c7 04 24 28 a7 10 c0 	movl   $0xc010a728,(%esp)
c01043de:	e8 1d c0 ff ff       	call   c0100400 <__panic>
    assert((ptep = get_pte(boot_pgdir, PGSIZE, 0)) != NULL);
c01043e3:	a1 e0 59 12 c0       	mov    0xc01259e0,%eax
c01043e8:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
c01043ef:	00 
c01043f0:	c7 44 24 04 00 10 00 	movl   $0x1000,0x4(%esp)
c01043f7:	00 
c01043f8:	89 04 24             	mov    %eax,(%esp)
c01043fb:	e8 2f f7 ff ff       	call   c0103b2f <get_pte>
c0104400:	89 45 f0             	mov    %eax,-0x10(%ebp)
c0104403:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
c0104407:	75 24                	jne    c010442d <check_pgdir+0x4c6>
c0104409:	c7 44 24 0c 1c a9 10 	movl   $0xc010a91c,0xc(%esp)
c0104410:	c0 
c0104411:	c7 44 24 08 4d a7 10 	movl   $0xc010a74d,0x8(%esp)
c0104418:	c0 
c0104419:	c7 44 24 04 27 02 00 	movl   $0x227,0x4(%esp)
c0104420:	00 
c0104421:	c7 04 24 28 a7 10 c0 	movl   $0xc010a728,(%esp)
c0104428:	e8 d3 bf ff ff       	call   c0100400 <__panic>
    assert(pte2page(*ptep) == p1);
c010442d:	8b 45 f0             	mov    -0x10(%ebp),%eax
c0104430:	8b 00                	mov    (%eax),%eax
c0104432:	89 04 24             	mov    %eax,(%esp)
c0104435:	e8 ba ed ff ff       	call   c01031f4 <pte2page>
c010443a:	39 45 f4             	cmp    %eax,-0xc(%ebp)
c010443d:	74 24                	je     c0104463 <check_pgdir+0x4fc>
c010443f:	c7 44 24 0c 91 a8 10 	movl   $0xc010a891,0xc(%esp)
c0104446:	c0 
c0104447:	c7 44 24 08 4d a7 10 	movl   $0xc010a74d,0x8(%esp)
c010444e:	c0 
c010444f:	c7 44 24 04 28 02 00 	movl   $0x228,0x4(%esp)
c0104456:	00 
c0104457:	c7 04 24 28 a7 10 c0 	movl   $0xc010a728,(%esp)
c010445e:	e8 9d bf ff ff       	call   c0100400 <__panic>
    assert((*ptep & PTE_U) == 0);
c0104463:	8b 45 f0             	mov    -0x10(%ebp),%eax
c0104466:	8b 00                	mov    (%eax),%eax
c0104468:	83 e0 04             	and    $0x4,%eax
c010446b:	85 c0                	test   %eax,%eax
c010446d:	74 24                	je     c0104493 <check_pgdir+0x52c>
c010446f:	c7 44 24 0c e0 a9 10 	movl   $0xc010a9e0,0xc(%esp)
c0104476:	c0 
c0104477:	c7 44 24 08 4d a7 10 	movl   $0xc010a74d,0x8(%esp)
c010447e:	c0 
c010447f:	c7 44 24 04 29 02 00 	movl   $0x229,0x4(%esp)
c0104486:	00 
c0104487:	c7 04 24 28 a7 10 c0 	movl   $0xc010a728,(%esp)
c010448e:	e8 6d bf ff ff       	call   c0100400 <__panic>

    page_remove(boot_pgdir, 0x0);
c0104493:	a1 e0 59 12 c0       	mov    0xc01259e0,%eax
c0104498:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
c010449f:	00 
c01044a0:	89 04 24             	mov    %eax,(%esp)
c01044a3:	e8 7b f8 ff ff       	call   c0103d23 <page_remove>
    assert(page_ref(p1) == 1);
c01044a8:	8b 45 f4             	mov    -0xc(%ebp),%eax
c01044ab:	89 04 24             	mov    %eax,(%esp)
c01044ae:	e8 97 ed ff ff       	call   c010324a <page_ref>
c01044b3:	83 f8 01             	cmp    $0x1,%eax
c01044b6:	74 24                	je     c01044dc <check_pgdir+0x575>
c01044b8:	c7 44 24 0c a7 a8 10 	movl   $0xc010a8a7,0xc(%esp)
c01044bf:	c0 
c01044c0:	c7 44 24 08 4d a7 10 	movl   $0xc010a74d,0x8(%esp)
c01044c7:	c0 
c01044c8:	c7 44 24 04 2c 02 00 	movl   $0x22c,0x4(%esp)
c01044cf:	00 
c01044d0:	c7 04 24 28 a7 10 c0 	movl   $0xc010a728,(%esp)
c01044d7:	e8 24 bf ff ff       	call   c0100400 <__panic>
    assert(page_ref(p2) == 0);
c01044dc:	8b 45 e4             	mov    -0x1c(%ebp),%eax
c01044df:	89 04 24             	mov    %eax,(%esp)
c01044e2:	e8 63 ed ff ff       	call   c010324a <page_ref>
c01044e7:	85 c0                	test   %eax,%eax
c01044e9:	74 24                	je     c010450f <check_pgdir+0x5a8>
c01044eb:	c7 44 24 0c ce a9 10 	movl   $0xc010a9ce,0xc(%esp)
c01044f2:	c0 
c01044f3:	c7 44 24 08 4d a7 10 	movl   $0xc010a74d,0x8(%esp)
c01044fa:	c0 
c01044fb:	c7 44 24 04 2d 02 00 	movl   $0x22d,0x4(%esp)
c0104502:	00 
c0104503:	c7 04 24 28 a7 10 c0 	movl   $0xc010a728,(%esp)
c010450a:	e8 f1 be ff ff       	call   c0100400 <__panic>

    page_remove(boot_pgdir, PGSIZE);
c010450f:	a1 e0 59 12 c0       	mov    0xc01259e0,%eax
c0104514:	c7 44 24 04 00 10 00 	movl   $0x1000,0x4(%esp)
c010451b:	00 
c010451c:	89 04 24             	mov    %eax,(%esp)
c010451f:	e8 ff f7 ff ff       	call   c0103d23 <page_remove>
    assert(page_ref(p1) == 0);
c0104524:	8b 45 f4             	mov    -0xc(%ebp),%eax
c0104527:	89 04 24             	mov    %eax,(%esp)
c010452a:	e8 1b ed ff ff       	call   c010324a <page_ref>
c010452f:	85 c0                	test   %eax,%eax
c0104531:	74 24                	je     c0104557 <check_pgdir+0x5f0>
c0104533:	c7 44 24 0c f5 a9 10 	movl   $0xc010a9f5,0xc(%esp)
c010453a:	c0 
c010453b:	c7 44 24 08 4d a7 10 	movl   $0xc010a74d,0x8(%esp)
c0104542:	c0 
c0104543:	c7 44 24 04 30 02 00 	movl   $0x230,0x4(%esp)
c010454a:	00 
c010454b:	c7 04 24 28 a7 10 c0 	movl   $0xc010a728,(%esp)
c0104552:	e8 a9 be ff ff       	call   c0100400 <__panic>
    assert(page_ref(p2) == 0);
c0104557:	8b 45 e4             	mov    -0x1c(%ebp),%eax
c010455a:	89 04 24             	mov    %eax,(%esp)
c010455d:	e8 e8 ec ff ff       	call   c010324a <page_ref>
c0104562:	85 c0                	test   %eax,%eax
c0104564:	74 24                	je     c010458a <check_pgdir+0x623>
c0104566:	c7 44 24 0c ce a9 10 	movl   $0xc010a9ce,0xc(%esp)
c010456d:	c0 
c010456e:	c7 44 24 08 4d a7 10 	movl   $0xc010a74d,0x8(%esp)
c0104575:	c0 
c0104576:	c7 44 24 04 31 02 00 	movl   $0x231,0x4(%esp)
c010457d:	00 
c010457e:	c7 04 24 28 a7 10 c0 	movl   $0xc010a728,(%esp)
c0104585:	e8 76 be ff ff       	call   c0100400 <__panic>

    assert(page_ref(pde2page(boot_pgdir[0])) == 1);
c010458a:	a1 e0 59 12 c0       	mov    0xc01259e0,%eax
c010458f:	8b 00                	mov    (%eax),%eax
c0104591:	89 04 24             	mov    %eax,(%esp)
c0104594:	e8 99 ec ff ff       	call   c0103232 <pde2page>
c0104599:	89 04 24             	mov    %eax,(%esp)
c010459c:	e8 a9 ec ff ff       	call   c010324a <page_ref>
c01045a1:	83 f8 01             	cmp    $0x1,%eax
c01045a4:	74 24                	je     c01045ca <check_pgdir+0x663>
c01045a6:	c7 44 24 0c 08 aa 10 	movl   $0xc010aa08,0xc(%esp)
c01045ad:	c0 
c01045ae:	c7 44 24 08 4d a7 10 	movl   $0xc010a74d,0x8(%esp)
c01045b5:	c0 
c01045b6:	c7 44 24 04 33 02 00 	movl   $0x233,0x4(%esp)
c01045bd:	00 
c01045be:	c7 04 24 28 a7 10 c0 	movl   $0xc010a728,(%esp)
c01045c5:	e8 36 be ff ff       	call   c0100400 <__panic>
    free_page(pde2page(boot_pgdir[0]));
c01045ca:	a1 e0 59 12 c0       	mov    0xc01259e0,%eax
c01045cf:	8b 00                	mov    (%eax),%eax
c01045d1:	89 04 24             	mov    %eax,(%esp)
c01045d4:	e8 59 ec ff ff       	call   c0103232 <pde2page>
c01045d9:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
c01045e0:	00 
c01045e1:	89 04 24             	mov    %eax,(%esp)
c01045e4:	e8 d1 ee ff ff       	call   c01034ba <free_pages>
    boot_pgdir[0] = 0;
c01045e9:	a1 e0 59 12 c0       	mov    0xc01259e0,%eax
c01045ee:	c7 00 00 00 00 00    	movl   $0x0,(%eax)

    cprintf("check_pgdir() succeeded!\n");
c01045f4:	c7 04 24 2f aa 10 c0 	movl   $0xc010aa2f,(%esp)
c01045fb:	e8 a9 bc ff ff       	call   c01002a9 <cprintf>
}
c0104600:	90                   	nop
c0104601:	c9                   	leave  
c0104602:	c3                   	ret    

c0104603 <check_boot_pgdir>:

static void
check_boot_pgdir(void) {
c0104603:	55                   	push   %ebp
c0104604:	89 e5                	mov    %esp,%ebp
c0104606:	83 ec 38             	sub    $0x38,%esp
    pte_t *ptep;
    int i;
    for (i = 0; i < npage; i += PGSIZE) {
c0104609:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
c0104610:	e9 ca 00 00 00       	jmp    c01046df <check_boot_pgdir+0xdc>
        assert((ptep = get_pte(boot_pgdir, (uintptr_t)KADDR(i), 0)) != NULL);
c0104615:	8b 45 f4             	mov    -0xc(%ebp),%eax
c0104618:	89 45 e4             	mov    %eax,-0x1c(%ebp)
c010461b:	8b 45 e4             	mov    -0x1c(%ebp),%eax
c010461e:	c1 e8 0c             	shr    $0xc,%eax
c0104621:	89 45 e0             	mov    %eax,-0x20(%ebp)
c0104624:	a1 80 8f 12 c0       	mov    0xc0128f80,%eax
c0104629:	39 45 e0             	cmp    %eax,-0x20(%ebp)
c010462c:	72 23                	jb     c0104651 <check_boot_pgdir+0x4e>
c010462e:	8b 45 e4             	mov    -0x1c(%ebp),%eax
c0104631:	89 44 24 0c          	mov    %eax,0xc(%esp)
c0104635:	c7 44 24 08 60 a6 10 	movl   $0xc010a660,0x8(%esp)
c010463c:	c0 
c010463d:	c7 44 24 04 3f 02 00 	movl   $0x23f,0x4(%esp)
c0104644:	00 
c0104645:	c7 04 24 28 a7 10 c0 	movl   $0xc010a728,(%esp)
c010464c:	e8 af bd ff ff       	call   c0100400 <__panic>
c0104651:	8b 45 e4             	mov    -0x1c(%ebp),%eax
c0104654:	2d 00 00 00 40       	sub    $0x40000000,%eax
c0104659:	89 c2                	mov    %eax,%edx
c010465b:	a1 e0 59 12 c0       	mov    0xc01259e0,%eax
c0104660:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
c0104667:	00 
c0104668:	89 54 24 04          	mov    %edx,0x4(%esp)
c010466c:	89 04 24             	mov    %eax,(%esp)
c010466f:	e8 bb f4 ff ff       	call   c0103b2f <get_pte>
c0104674:	89 45 dc             	mov    %eax,-0x24(%ebp)
c0104677:	83 7d dc 00          	cmpl   $0x0,-0x24(%ebp)
c010467b:	75 24                	jne    c01046a1 <check_boot_pgdir+0x9e>
c010467d:	c7 44 24 0c 4c aa 10 	movl   $0xc010aa4c,0xc(%esp)
c0104684:	c0 
c0104685:	c7 44 24 08 4d a7 10 	movl   $0xc010a74d,0x8(%esp)
c010468c:	c0 
c010468d:	c7 44 24 04 3f 02 00 	movl   $0x23f,0x4(%esp)
c0104694:	00 
c0104695:	c7 04 24 28 a7 10 c0 	movl   $0xc010a728,(%esp)
c010469c:	e8 5f bd ff ff       	call   c0100400 <__panic>
        assert(PTE_ADDR(*ptep) == i);
c01046a1:	8b 45 dc             	mov    -0x24(%ebp),%eax
c01046a4:	8b 00                	mov    (%eax),%eax
c01046a6:	25 00 f0 ff ff       	and    $0xfffff000,%eax
c01046ab:	89 c2                	mov    %eax,%edx
c01046ad:	8b 45 f4             	mov    -0xc(%ebp),%eax
c01046b0:	39 c2                	cmp    %eax,%edx
c01046b2:	74 24                	je     c01046d8 <check_boot_pgdir+0xd5>
c01046b4:	c7 44 24 0c 89 aa 10 	movl   $0xc010aa89,0xc(%esp)
c01046bb:	c0 
c01046bc:	c7 44 24 08 4d a7 10 	movl   $0xc010a74d,0x8(%esp)
c01046c3:	c0 
c01046c4:	c7 44 24 04 40 02 00 	movl   $0x240,0x4(%esp)
c01046cb:	00 
c01046cc:	c7 04 24 28 a7 10 c0 	movl   $0xc010a728,(%esp)
c01046d3:	e8 28 bd ff ff       	call   c0100400 <__panic>
    for (i = 0; i < npage; i += PGSIZE) {
c01046d8:	81 45 f4 00 10 00 00 	addl   $0x1000,-0xc(%ebp)
c01046df:	8b 55 f4             	mov    -0xc(%ebp),%edx
c01046e2:	a1 80 8f 12 c0       	mov    0xc0128f80,%eax
c01046e7:	39 c2                	cmp    %eax,%edx
c01046e9:	0f 82 26 ff ff ff    	jb     c0104615 <check_boot_pgdir+0x12>
    }

    assert(PDE_ADDR(boot_pgdir[PDX(VPT)]) == PADDR(boot_pgdir));
c01046ef:	a1 e0 59 12 c0       	mov    0xc01259e0,%eax
c01046f4:	05 ac 0f 00 00       	add    $0xfac,%eax
c01046f9:	8b 00                	mov    (%eax),%eax
c01046fb:	25 00 f0 ff ff       	and    $0xfffff000,%eax
c0104700:	89 c2                	mov    %eax,%edx
c0104702:	a1 e0 59 12 c0       	mov    0xc01259e0,%eax
c0104707:	89 45 f0             	mov    %eax,-0x10(%ebp)
c010470a:	81 7d f0 ff ff ff bf 	cmpl   $0xbfffffff,-0x10(%ebp)
c0104711:	77 23                	ja     c0104736 <check_boot_pgdir+0x133>
c0104713:	8b 45 f0             	mov    -0x10(%ebp),%eax
c0104716:	89 44 24 0c          	mov    %eax,0xc(%esp)
c010471a:	c7 44 24 08 04 a7 10 	movl   $0xc010a704,0x8(%esp)
c0104721:	c0 
c0104722:	c7 44 24 04 43 02 00 	movl   $0x243,0x4(%esp)
c0104729:	00 
c010472a:	c7 04 24 28 a7 10 c0 	movl   $0xc010a728,(%esp)
c0104731:	e8 ca bc ff ff       	call   c0100400 <__panic>
c0104736:	8b 45 f0             	mov    -0x10(%ebp),%eax
c0104739:	05 00 00 00 40       	add    $0x40000000,%eax
c010473e:	39 d0                	cmp    %edx,%eax
c0104740:	74 24                	je     c0104766 <check_boot_pgdir+0x163>
c0104742:	c7 44 24 0c a0 aa 10 	movl   $0xc010aaa0,0xc(%esp)
c0104749:	c0 
c010474a:	c7 44 24 08 4d a7 10 	movl   $0xc010a74d,0x8(%esp)
c0104751:	c0 
c0104752:	c7 44 24 04 43 02 00 	movl   $0x243,0x4(%esp)
c0104759:	00 
c010475a:	c7 04 24 28 a7 10 c0 	movl   $0xc010a728,(%esp)
c0104761:	e8 9a bc ff ff       	call   c0100400 <__panic>

    assert(boot_pgdir[0] == 0);
c0104766:	a1 e0 59 12 c0       	mov    0xc01259e0,%eax
c010476b:	8b 00                	mov    (%eax),%eax
c010476d:	85 c0                	test   %eax,%eax
c010476f:	74 24                	je     c0104795 <check_boot_pgdir+0x192>
c0104771:	c7 44 24 0c d4 aa 10 	movl   $0xc010aad4,0xc(%esp)
c0104778:	c0 
c0104779:	c7 44 24 08 4d a7 10 	movl   $0xc010a74d,0x8(%esp)
c0104780:	c0 
c0104781:	c7 44 24 04 45 02 00 	movl   $0x245,0x4(%esp)
c0104788:	00 
c0104789:	c7 04 24 28 a7 10 c0 	movl   $0xc010a728,(%esp)
c0104790:	e8 6b bc ff ff       	call   c0100400 <__panic>

    struct Page *p;
    p = alloc_page();
c0104795:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
c010479c:	e8 ae ec ff ff       	call   c010344f <alloc_pages>
c01047a1:	89 45 ec             	mov    %eax,-0x14(%ebp)
    assert(page_insert(boot_pgdir, p, 0x100, PTE_W) == 0);
c01047a4:	a1 e0 59 12 c0       	mov    0xc01259e0,%eax
c01047a9:	c7 44 24 0c 02 00 00 	movl   $0x2,0xc(%esp)
c01047b0:	00 
c01047b1:	c7 44 24 08 00 01 00 	movl   $0x100,0x8(%esp)
c01047b8:	00 
c01047b9:	8b 55 ec             	mov    -0x14(%ebp),%edx
c01047bc:	89 54 24 04          	mov    %edx,0x4(%esp)
c01047c0:	89 04 24             	mov    %eax,(%esp)
c01047c3:	e8 a0 f5 ff ff       	call   c0103d68 <page_insert>
c01047c8:	85 c0                	test   %eax,%eax
c01047ca:	74 24                	je     c01047f0 <check_boot_pgdir+0x1ed>
c01047cc:	c7 44 24 0c e8 aa 10 	movl   $0xc010aae8,0xc(%esp)
c01047d3:	c0 
c01047d4:	c7 44 24 08 4d a7 10 	movl   $0xc010a74d,0x8(%esp)
c01047db:	c0 
c01047dc:	c7 44 24 04 49 02 00 	movl   $0x249,0x4(%esp)
c01047e3:	00 
c01047e4:	c7 04 24 28 a7 10 c0 	movl   $0xc010a728,(%esp)
c01047eb:	e8 10 bc ff ff       	call   c0100400 <__panic>
    assert(page_ref(p) == 1);
c01047f0:	8b 45 ec             	mov    -0x14(%ebp),%eax
c01047f3:	89 04 24             	mov    %eax,(%esp)
c01047f6:	e8 4f ea ff ff       	call   c010324a <page_ref>
c01047fb:	83 f8 01             	cmp    $0x1,%eax
c01047fe:	74 24                	je     c0104824 <check_boot_pgdir+0x221>
c0104800:	c7 44 24 0c 16 ab 10 	movl   $0xc010ab16,0xc(%esp)
c0104807:	c0 
c0104808:	c7 44 24 08 4d a7 10 	movl   $0xc010a74d,0x8(%esp)
c010480f:	c0 
c0104810:	c7 44 24 04 4a 02 00 	movl   $0x24a,0x4(%esp)
c0104817:	00 
c0104818:	c7 04 24 28 a7 10 c0 	movl   $0xc010a728,(%esp)
c010481f:	e8 dc bb ff ff       	call   c0100400 <__panic>
    assert(page_insert(boot_pgdir, p, 0x100 + PGSIZE, PTE_W) == 0);
c0104824:	a1 e0 59 12 c0       	mov    0xc01259e0,%eax
c0104829:	c7 44 24 0c 02 00 00 	movl   $0x2,0xc(%esp)
c0104830:	00 
c0104831:	c7 44 24 08 00 11 00 	movl   $0x1100,0x8(%esp)
c0104838:	00 
c0104839:	8b 55 ec             	mov    -0x14(%ebp),%edx
c010483c:	89 54 24 04          	mov    %edx,0x4(%esp)
c0104840:	89 04 24             	mov    %eax,(%esp)
c0104843:	e8 20 f5 ff ff       	call   c0103d68 <page_insert>
c0104848:	85 c0                	test   %eax,%eax
c010484a:	74 24                	je     c0104870 <check_boot_pgdir+0x26d>
c010484c:	c7 44 24 0c 28 ab 10 	movl   $0xc010ab28,0xc(%esp)
c0104853:	c0 
c0104854:	c7 44 24 08 4d a7 10 	movl   $0xc010a74d,0x8(%esp)
c010485b:	c0 
c010485c:	c7 44 24 04 4b 02 00 	movl   $0x24b,0x4(%esp)
c0104863:	00 
c0104864:	c7 04 24 28 a7 10 c0 	movl   $0xc010a728,(%esp)
c010486b:	e8 90 bb ff ff       	call   c0100400 <__panic>
    assert(page_ref(p) == 2);
c0104870:	8b 45 ec             	mov    -0x14(%ebp),%eax
c0104873:	89 04 24             	mov    %eax,(%esp)
c0104876:	e8 cf e9 ff ff       	call   c010324a <page_ref>
c010487b:	83 f8 02             	cmp    $0x2,%eax
c010487e:	74 24                	je     c01048a4 <check_boot_pgdir+0x2a1>
c0104880:	c7 44 24 0c 5f ab 10 	movl   $0xc010ab5f,0xc(%esp)
c0104887:	c0 
c0104888:	c7 44 24 08 4d a7 10 	movl   $0xc010a74d,0x8(%esp)
c010488f:	c0 
c0104890:	c7 44 24 04 4c 02 00 	movl   $0x24c,0x4(%esp)
c0104897:	00 
c0104898:	c7 04 24 28 a7 10 c0 	movl   $0xc010a728,(%esp)
c010489f:	e8 5c bb ff ff       	call   c0100400 <__panic>

    const char *str = "ucore: Hello world!!";
c01048a4:	c7 45 e8 70 ab 10 c0 	movl   $0xc010ab70,-0x18(%ebp)
    strcpy((void *)0x100, str);
c01048ab:	8b 45 e8             	mov    -0x18(%ebp),%eax
c01048ae:	89 44 24 04          	mov    %eax,0x4(%esp)
c01048b2:	c7 04 24 00 01 00 00 	movl   $0x100,(%esp)
c01048b9:	e8 1b 49 00 00       	call   c01091d9 <strcpy>
    assert(strcmp((void *)0x100, (void *)(0x100 + PGSIZE)) == 0);
c01048be:	c7 44 24 04 00 11 00 	movl   $0x1100,0x4(%esp)
c01048c5:	00 
c01048c6:	c7 04 24 00 01 00 00 	movl   $0x100,(%esp)
c01048cd:	e8 7e 49 00 00       	call   c0109250 <strcmp>
c01048d2:	85 c0                	test   %eax,%eax
c01048d4:	74 24                	je     c01048fa <check_boot_pgdir+0x2f7>
c01048d6:	c7 44 24 0c 88 ab 10 	movl   $0xc010ab88,0xc(%esp)
c01048dd:	c0 
c01048de:	c7 44 24 08 4d a7 10 	movl   $0xc010a74d,0x8(%esp)
c01048e5:	c0 
c01048e6:	c7 44 24 04 50 02 00 	movl   $0x250,0x4(%esp)
c01048ed:	00 
c01048ee:	c7 04 24 28 a7 10 c0 	movl   $0xc010a728,(%esp)
c01048f5:	e8 06 bb ff ff       	call   c0100400 <__panic>

    *(char *)(page2kva(p) + 0x100) = '\0';
c01048fa:	8b 45 ec             	mov    -0x14(%ebp),%eax
c01048fd:	89 04 24             	mov    %eax,(%esp)
c0104900:	e8 9b e8 ff ff       	call   c01031a0 <page2kva>
c0104905:	05 00 01 00 00       	add    $0x100,%eax
c010490a:	c6 00 00             	movb   $0x0,(%eax)
    assert(strlen((const char *)0x100) == 0);
c010490d:	c7 04 24 00 01 00 00 	movl   $0x100,(%esp)
c0104914:	e8 6a 48 00 00       	call   c0109183 <strlen>
c0104919:	85 c0                	test   %eax,%eax
c010491b:	74 24                	je     c0104941 <check_boot_pgdir+0x33e>
c010491d:	c7 44 24 0c c0 ab 10 	movl   $0xc010abc0,0xc(%esp)
c0104924:	c0 
c0104925:	c7 44 24 08 4d a7 10 	movl   $0xc010a74d,0x8(%esp)
c010492c:	c0 
c010492d:	c7 44 24 04 53 02 00 	movl   $0x253,0x4(%esp)
c0104934:	00 
c0104935:	c7 04 24 28 a7 10 c0 	movl   $0xc010a728,(%esp)
c010493c:	e8 bf ba ff ff       	call   c0100400 <__panic>

    free_page(p);
c0104941:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
c0104948:	00 
c0104949:	8b 45 ec             	mov    -0x14(%ebp),%eax
c010494c:	89 04 24             	mov    %eax,(%esp)
c010494f:	e8 66 eb ff ff       	call   c01034ba <free_pages>
    free_page(pde2page(boot_pgdir[0]));
c0104954:	a1 e0 59 12 c0       	mov    0xc01259e0,%eax
c0104959:	8b 00                	mov    (%eax),%eax
c010495b:	89 04 24             	mov    %eax,(%esp)
c010495e:	e8 cf e8 ff ff       	call   c0103232 <pde2page>
c0104963:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
c010496a:	00 
c010496b:	89 04 24             	mov    %eax,(%esp)
c010496e:	e8 47 eb ff ff       	call   c01034ba <free_pages>
    boot_pgdir[0] = 0;
c0104973:	a1 e0 59 12 c0       	mov    0xc01259e0,%eax
c0104978:	c7 00 00 00 00 00    	movl   $0x0,(%eax)

    cprintf("check_boot_pgdir() succeeded!\n");
c010497e:	c7 04 24 e4 ab 10 c0 	movl   $0xc010abe4,(%esp)
c0104985:	e8 1f b9 ff ff       	call   c01002a9 <cprintf>
}
c010498a:	90                   	nop
c010498b:	c9                   	leave  
c010498c:	c3                   	ret    

c010498d <perm2str>:

//perm2str - use string 'u,r,w,-' to present the permission
static const char *
perm2str(int perm) {
c010498d:	55                   	push   %ebp
c010498e:	89 e5                	mov    %esp,%ebp
    static char str[4];
    str[0] = (perm & PTE_U) ? 'u' : '-';
c0104990:	8b 45 08             	mov    0x8(%ebp),%eax
c0104993:	83 e0 04             	and    $0x4,%eax
c0104996:	85 c0                	test   %eax,%eax
c0104998:	74 04                	je     c010499e <perm2str+0x11>
c010499a:	b0 75                	mov    $0x75,%al
c010499c:	eb 02                	jmp    c01049a0 <perm2str+0x13>
c010499e:	b0 2d                	mov    $0x2d,%al
c01049a0:	a2 08 90 12 c0       	mov    %al,0xc0129008
    str[1] = 'r';
c01049a5:	c6 05 09 90 12 c0 72 	movb   $0x72,0xc0129009
    str[2] = (perm & PTE_W) ? 'w' : '-';
c01049ac:	8b 45 08             	mov    0x8(%ebp),%eax
c01049af:	83 e0 02             	and    $0x2,%eax
c01049b2:	85 c0                	test   %eax,%eax
c01049b4:	74 04                	je     c01049ba <perm2str+0x2d>
c01049b6:	b0 77                	mov    $0x77,%al
c01049b8:	eb 02                	jmp    c01049bc <perm2str+0x2f>
c01049ba:	b0 2d                	mov    $0x2d,%al
c01049bc:	a2 0a 90 12 c0       	mov    %al,0xc012900a
    str[3] = '\0';
c01049c1:	c6 05 0b 90 12 c0 00 	movb   $0x0,0xc012900b
    return str;
c01049c8:	b8 08 90 12 c0       	mov    $0xc0129008,%eax
}
c01049cd:	5d                   	pop    %ebp
c01049ce:	c3                   	ret    

c01049cf <get_pgtable_items>:
//  table:       the beginning addr of table
//  left_store:  the pointer of the high side of table's next range
//  right_store: the pointer of the low side of table's next range
// return value: 0 - not a invalid item range, perm - a valid item range with perm permission 
static int
get_pgtable_items(size_t left, size_t right, size_t start, uintptr_t *table, size_t *left_store, size_t *right_store) {
c01049cf:	55                   	push   %ebp
c01049d0:	89 e5                	mov    %esp,%ebp
c01049d2:	83 ec 10             	sub    $0x10,%esp
    if (start >= right) {
c01049d5:	8b 45 10             	mov    0x10(%ebp),%eax
c01049d8:	3b 45 0c             	cmp    0xc(%ebp),%eax
c01049db:	72 0d                	jb     c01049ea <get_pgtable_items+0x1b>
        return 0;
c01049dd:	b8 00 00 00 00       	mov    $0x0,%eax
c01049e2:	e9 98 00 00 00       	jmp    c0104a7f <get_pgtable_items+0xb0>
    }
    while (start < right && !(table[start] & PTE_P)) {
        start ++;
c01049e7:	ff 45 10             	incl   0x10(%ebp)
    while (start < right && !(table[start] & PTE_P)) {
c01049ea:	8b 45 10             	mov    0x10(%ebp),%eax
c01049ed:	3b 45 0c             	cmp    0xc(%ebp),%eax
c01049f0:	73 18                	jae    c0104a0a <get_pgtable_items+0x3b>
c01049f2:	8b 45 10             	mov    0x10(%ebp),%eax
c01049f5:	8d 14 85 00 00 00 00 	lea    0x0(,%eax,4),%edx
c01049fc:	8b 45 14             	mov    0x14(%ebp),%eax
c01049ff:	01 d0                	add    %edx,%eax
c0104a01:	8b 00                	mov    (%eax),%eax
c0104a03:	83 e0 01             	and    $0x1,%eax
c0104a06:	85 c0                	test   %eax,%eax
c0104a08:	74 dd                	je     c01049e7 <get_pgtable_items+0x18>
    }
    if (start < right) {
c0104a0a:	8b 45 10             	mov    0x10(%ebp),%eax
c0104a0d:	3b 45 0c             	cmp    0xc(%ebp),%eax
c0104a10:	73 68                	jae    c0104a7a <get_pgtable_items+0xab>
        if (left_store != NULL) {
c0104a12:	83 7d 18 00          	cmpl   $0x0,0x18(%ebp)
c0104a16:	74 08                	je     c0104a20 <get_pgtable_items+0x51>
            *left_store = start;
c0104a18:	8b 45 18             	mov    0x18(%ebp),%eax
c0104a1b:	8b 55 10             	mov    0x10(%ebp),%edx
c0104a1e:	89 10                	mov    %edx,(%eax)
        }
        int perm = (table[start ++] & PTE_USER);
c0104a20:	8b 45 10             	mov    0x10(%ebp),%eax
c0104a23:	8d 50 01             	lea    0x1(%eax),%edx
c0104a26:	89 55 10             	mov    %edx,0x10(%ebp)
c0104a29:	8d 14 85 00 00 00 00 	lea    0x0(,%eax,4),%edx
c0104a30:	8b 45 14             	mov    0x14(%ebp),%eax
c0104a33:	01 d0                	add    %edx,%eax
c0104a35:	8b 00                	mov    (%eax),%eax
c0104a37:	83 e0 07             	and    $0x7,%eax
c0104a3a:	89 45 fc             	mov    %eax,-0x4(%ebp)
        while (start < right && (table[start] & PTE_USER) == perm) {
c0104a3d:	eb 03                	jmp    c0104a42 <get_pgtable_items+0x73>
            start ++;
c0104a3f:	ff 45 10             	incl   0x10(%ebp)
        while (start < right && (table[start] & PTE_USER) == perm) {
c0104a42:	8b 45 10             	mov    0x10(%ebp),%eax
c0104a45:	3b 45 0c             	cmp    0xc(%ebp),%eax
c0104a48:	73 1d                	jae    c0104a67 <get_pgtable_items+0x98>
c0104a4a:	8b 45 10             	mov    0x10(%ebp),%eax
c0104a4d:	8d 14 85 00 00 00 00 	lea    0x0(,%eax,4),%edx
c0104a54:	8b 45 14             	mov    0x14(%ebp),%eax
c0104a57:	01 d0                	add    %edx,%eax
c0104a59:	8b 00                	mov    (%eax),%eax
c0104a5b:	83 e0 07             	and    $0x7,%eax
c0104a5e:	89 c2                	mov    %eax,%edx
c0104a60:	8b 45 fc             	mov    -0x4(%ebp),%eax
c0104a63:	39 c2                	cmp    %eax,%edx
c0104a65:	74 d8                	je     c0104a3f <get_pgtable_items+0x70>
        }
        if (right_store != NULL) {
c0104a67:	83 7d 1c 00          	cmpl   $0x0,0x1c(%ebp)
c0104a6b:	74 08                	je     c0104a75 <get_pgtable_items+0xa6>
            *right_store = start;
c0104a6d:	8b 45 1c             	mov    0x1c(%ebp),%eax
c0104a70:	8b 55 10             	mov    0x10(%ebp),%edx
c0104a73:	89 10                	mov    %edx,(%eax)
        }
        return perm;
c0104a75:	8b 45 fc             	mov    -0x4(%ebp),%eax
c0104a78:	eb 05                	jmp    c0104a7f <get_pgtable_items+0xb0>
    }
    return 0;
c0104a7a:	b8 00 00 00 00       	mov    $0x0,%eax
}
c0104a7f:	c9                   	leave  
c0104a80:	c3                   	ret    

c0104a81 <print_pgdir>:

//print_pgdir - print the PDT&PT
void
print_pgdir(void) {
c0104a81:	55                   	push   %ebp
c0104a82:	89 e5                	mov    %esp,%ebp
c0104a84:	57                   	push   %edi
c0104a85:	56                   	push   %esi
c0104a86:	53                   	push   %ebx
c0104a87:	83 ec 4c             	sub    $0x4c,%esp
    cprintf("-------------------- BEGIN --------------------\n");
c0104a8a:	c7 04 24 04 ac 10 c0 	movl   $0xc010ac04,(%esp)
c0104a91:	e8 13 b8 ff ff       	call   c01002a9 <cprintf>
    size_t left, right = 0, perm;
c0104a96:	c7 45 dc 00 00 00 00 	movl   $0x0,-0x24(%ebp)
    while ((perm = get_pgtable_items(0, NPDEENTRY, right, vpd, &left, &right)) != 0) {
c0104a9d:	e9 fa 00 00 00       	jmp    c0104b9c <print_pgdir+0x11b>
        cprintf("PDE(%03x) %08x-%08x %08x %s\n", right - left,
c0104aa2:	8b 45 e4             	mov    -0x1c(%ebp),%eax
c0104aa5:	89 04 24             	mov    %eax,(%esp)
c0104aa8:	e8 e0 fe ff ff       	call   c010498d <perm2str>
                left * PTSIZE, right * PTSIZE, (right - left) * PTSIZE, perm2str(perm));
c0104aad:	8b 4d dc             	mov    -0x24(%ebp),%ecx
c0104ab0:	8b 55 e0             	mov    -0x20(%ebp),%edx
c0104ab3:	29 d1                	sub    %edx,%ecx
c0104ab5:	89 ca                	mov    %ecx,%edx
        cprintf("PDE(%03x) %08x-%08x %08x %s\n", right - left,
c0104ab7:	89 d6                	mov    %edx,%esi
c0104ab9:	c1 e6 16             	shl    $0x16,%esi
c0104abc:	8b 55 dc             	mov    -0x24(%ebp),%edx
c0104abf:	89 d3                	mov    %edx,%ebx
c0104ac1:	c1 e3 16             	shl    $0x16,%ebx
c0104ac4:	8b 55 e0             	mov    -0x20(%ebp),%edx
c0104ac7:	89 d1                	mov    %edx,%ecx
c0104ac9:	c1 e1 16             	shl    $0x16,%ecx
c0104acc:	8b 7d dc             	mov    -0x24(%ebp),%edi
c0104acf:	8b 55 e0             	mov    -0x20(%ebp),%edx
c0104ad2:	29 d7                	sub    %edx,%edi
c0104ad4:	89 fa                	mov    %edi,%edx
c0104ad6:	89 44 24 14          	mov    %eax,0x14(%esp)
c0104ada:	89 74 24 10          	mov    %esi,0x10(%esp)
c0104ade:	89 5c 24 0c          	mov    %ebx,0xc(%esp)
c0104ae2:	89 4c 24 08          	mov    %ecx,0x8(%esp)
c0104ae6:	89 54 24 04          	mov    %edx,0x4(%esp)
c0104aea:	c7 04 24 35 ac 10 c0 	movl   $0xc010ac35,(%esp)
c0104af1:	e8 b3 b7 ff ff       	call   c01002a9 <cprintf>
        size_t l, r = left * NPTEENTRY;
c0104af6:	8b 45 e0             	mov    -0x20(%ebp),%eax
c0104af9:	c1 e0 0a             	shl    $0xa,%eax
c0104afc:	89 45 d4             	mov    %eax,-0x2c(%ebp)
        while ((perm = get_pgtable_items(left * NPTEENTRY, right * NPTEENTRY, r, vpt, &l, &r)) != 0) {
c0104aff:	eb 54                	jmp    c0104b55 <print_pgdir+0xd4>
            cprintf("  |-- PTE(%05x) %08x-%08x %08x %s\n", r - l,
c0104b01:	8b 45 e4             	mov    -0x1c(%ebp),%eax
c0104b04:	89 04 24             	mov    %eax,(%esp)
c0104b07:	e8 81 fe ff ff       	call   c010498d <perm2str>
                    l * PGSIZE, r * PGSIZE, (r - l) * PGSIZE, perm2str(perm));
c0104b0c:	8b 4d d4             	mov    -0x2c(%ebp),%ecx
c0104b0f:	8b 55 d8             	mov    -0x28(%ebp),%edx
c0104b12:	29 d1                	sub    %edx,%ecx
c0104b14:	89 ca                	mov    %ecx,%edx
            cprintf("  |-- PTE(%05x) %08x-%08x %08x %s\n", r - l,
c0104b16:	89 d6                	mov    %edx,%esi
c0104b18:	c1 e6 0c             	shl    $0xc,%esi
c0104b1b:	8b 55 d4             	mov    -0x2c(%ebp),%edx
c0104b1e:	89 d3                	mov    %edx,%ebx
c0104b20:	c1 e3 0c             	shl    $0xc,%ebx
c0104b23:	8b 55 d8             	mov    -0x28(%ebp),%edx
c0104b26:	89 d1                	mov    %edx,%ecx
c0104b28:	c1 e1 0c             	shl    $0xc,%ecx
c0104b2b:	8b 7d d4             	mov    -0x2c(%ebp),%edi
c0104b2e:	8b 55 d8             	mov    -0x28(%ebp),%edx
c0104b31:	29 d7                	sub    %edx,%edi
c0104b33:	89 fa                	mov    %edi,%edx
c0104b35:	89 44 24 14          	mov    %eax,0x14(%esp)
c0104b39:	89 74 24 10          	mov    %esi,0x10(%esp)
c0104b3d:	89 5c 24 0c          	mov    %ebx,0xc(%esp)
c0104b41:	89 4c 24 08          	mov    %ecx,0x8(%esp)
c0104b45:	89 54 24 04          	mov    %edx,0x4(%esp)
c0104b49:	c7 04 24 54 ac 10 c0 	movl   $0xc010ac54,(%esp)
c0104b50:	e8 54 b7 ff ff       	call   c01002a9 <cprintf>
        while ((perm = get_pgtable_items(left * NPTEENTRY, right * NPTEENTRY, r, vpt, &l, &r)) != 0) {
c0104b55:	be 00 00 c0 fa       	mov    $0xfac00000,%esi
c0104b5a:	8b 45 d4             	mov    -0x2c(%ebp),%eax
c0104b5d:	8b 55 dc             	mov    -0x24(%ebp),%edx
c0104b60:	89 d3                	mov    %edx,%ebx
c0104b62:	c1 e3 0a             	shl    $0xa,%ebx
c0104b65:	8b 55 e0             	mov    -0x20(%ebp),%edx
c0104b68:	89 d1                	mov    %edx,%ecx
c0104b6a:	c1 e1 0a             	shl    $0xa,%ecx
c0104b6d:	8d 55 d4             	lea    -0x2c(%ebp),%edx
c0104b70:	89 54 24 14          	mov    %edx,0x14(%esp)
c0104b74:	8d 55 d8             	lea    -0x28(%ebp),%edx
c0104b77:	89 54 24 10          	mov    %edx,0x10(%esp)
c0104b7b:	89 74 24 0c          	mov    %esi,0xc(%esp)
c0104b7f:	89 44 24 08          	mov    %eax,0x8(%esp)
c0104b83:	89 5c 24 04          	mov    %ebx,0x4(%esp)
c0104b87:	89 0c 24             	mov    %ecx,(%esp)
c0104b8a:	e8 40 fe ff ff       	call   c01049cf <get_pgtable_items>
c0104b8f:	89 45 e4             	mov    %eax,-0x1c(%ebp)
c0104b92:	83 7d e4 00          	cmpl   $0x0,-0x1c(%ebp)
c0104b96:	0f 85 65 ff ff ff    	jne    c0104b01 <print_pgdir+0x80>
    while ((perm = get_pgtable_items(0, NPDEENTRY, right, vpd, &left, &right)) != 0) {
c0104b9c:	b9 00 b0 fe fa       	mov    $0xfafeb000,%ecx
c0104ba1:	8b 45 dc             	mov    -0x24(%ebp),%eax
c0104ba4:	8d 55 dc             	lea    -0x24(%ebp),%edx
c0104ba7:	89 54 24 14          	mov    %edx,0x14(%esp)
c0104bab:	8d 55 e0             	lea    -0x20(%ebp),%edx
c0104bae:	89 54 24 10          	mov    %edx,0x10(%esp)
c0104bb2:	89 4c 24 0c          	mov    %ecx,0xc(%esp)
c0104bb6:	89 44 24 08          	mov    %eax,0x8(%esp)
c0104bba:	c7 44 24 04 00 04 00 	movl   $0x400,0x4(%esp)
c0104bc1:	00 
c0104bc2:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
c0104bc9:	e8 01 fe ff ff       	call   c01049cf <get_pgtable_items>
c0104bce:	89 45 e4             	mov    %eax,-0x1c(%ebp)
c0104bd1:	83 7d e4 00          	cmpl   $0x0,-0x1c(%ebp)
c0104bd5:	0f 85 c7 fe ff ff    	jne    c0104aa2 <print_pgdir+0x21>
        }
    }
    cprintf("--------------------- END ---------------------\n");
c0104bdb:	c7 04 24 78 ac 10 c0 	movl   $0xc010ac78,(%esp)
c0104be2:	e8 c2 b6 ff ff       	call   c01002a9 <cprintf>
}
c0104be7:	90                   	nop
c0104be8:	83 c4 4c             	add    $0x4c,%esp
c0104beb:	5b                   	pop    %ebx
c0104bec:	5e                   	pop    %esi
c0104bed:	5f                   	pop    %edi
c0104bee:	5d                   	pop    %ebp
c0104bef:	c3                   	ret    

c0104bf0 <_fifo_init_mm>:
 * (2) _fifo_init_mm: init pra_list_head and let  mm->sm_priv point to the addr of pra_list_head.
 *              Now, From the memory control struct mm_struct, we can access FIFO PRA
 */
static int
_fifo_init_mm(struct mm_struct *mm)
{     
c0104bf0:	55                   	push   %ebp
c0104bf1:	89 e5                	mov    %esp,%ebp
c0104bf3:	83 ec 10             	sub    $0x10,%esp
c0104bf6:	c7 45 fc 64 b0 12 c0 	movl   $0xc012b064,-0x4(%ebp)
 * list_init - initialize a new entry
 * @elm:        new entry to be initialized
 * */
static inline void
list_init(list_entry_t *elm) {
    elm->prev = elm->next = elm;
c0104bfd:	8b 45 fc             	mov    -0x4(%ebp),%eax
c0104c00:	8b 55 fc             	mov    -0x4(%ebp),%edx
c0104c03:	89 50 04             	mov    %edx,0x4(%eax)
c0104c06:	8b 45 fc             	mov    -0x4(%ebp),%eax
c0104c09:	8b 50 04             	mov    0x4(%eax),%edx
c0104c0c:	8b 45 fc             	mov    -0x4(%ebp),%eax
c0104c0f:	89 10                	mov    %edx,(%eax)
     list_init(&pra_list_head);    //链表头初始化
     mm->sm_priv = &pra_list_head;  //给mm的priv初始化
c0104c11:	8b 45 08             	mov    0x8(%ebp),%eax
c0104c14:	c7 40 14 64 b0 12 c0 	movl   $0xc012b064,0x14(%eax)
     //cprintf(" mm->sm_priv %x in fifo_init_mm\n",mm->sm_priv);
     return 0;
c0104c1b:	b8 00 00 00 00       	mov    $0x0,%eax
}
c0104c20:	c9                   	leave  
c0104c21:	c3                   	ret    

c0104c22 <_fifo_map_swappable>:
/*
 * (3)_fifo_map_swappable: According FIFO PRA, 就是把参数这个页插进mm的priv变量所维护链表的表头（队尾）；是最近访问的页
 */
static int
_fifo_map_swappable(struct mm_struct *mm, uintptr_t addr, struct Page *page, int swap_in)       //2、4参数在fifo的时间访问链表中没有用到
{
c0104c22:	55                   	push   %ebp
c0104c23:	89 e5                	mov    %esp,%ebp
c0104c25:	83 ec 48             	sub    $0x48,%esp
    list_entry_t *head=(list_entry_t*) mm->sm_priv;     //（按页的第一次访问时间排序）的表头
c0104c28:	8b 45 08             	mov    0x8(%ebp),%eax
c0104c2b:	8b 40 14             	mov    0x14(%eax),%eax
c0104c2e:	89 45 f4             	mov    %eax,-0xc(%ebp)
    list_entry_t *entry=&(page->pra_page_link);
c0104c31:	8b 45 10             	mov    0x10(%ebp),%eax
c0104c34:	83 c0 14             	add    $0x14,%eax
c0104c37:	89 45 f0             	mov    %eax,-0x10(%ebp)
 
    assert(entry != NULL && head != NULL);
c0104c3a:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
c0104c3e:	74 06                	je     c0104c46 <_fifo_map_swappable+0x24>
c0104c40:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
c0104c44:	75 24                	jne    c0104c6a <_fifo_map_swappable+0x48>
c0104c46:	c7 44 24 0c ac ac 10 	movl   $0xc010acac,0xc(%esp)
c0104c4d:	c0 
c0104c4e:	c7 44 24 08 ca ac 10 	movl   $0xc010acca,0x8(%esp)
c0104c55:	c0 
c0104c56:	c7 44 24 04 32 00 00 	movl   $0x32,0x4(%esp)
c0104c5d:	00 
c0104c5e:	c7 04 24 df ac 10 c0 	movl   $0xc010acdf,(%esp)
c0104c65:	e8 96 b7 ff ff       	call   c0100400 <__panic>
c0104c6a:	8b 45 f4             	mov    -0xc(%ebp),%eax
c0104c6d:	89 45 ec             	mov    %eax,-0x14(%ebp)
c0104c70:	8b 45 f0             	mov    -0x10(%ebp),%eax
c0104c73:	89 45 e8             	mov    %eax,-0x18(%ebp)
c0104c76:	8b 45 ec             	mov    -0x14(%ebp),%eax
c0104c79:	89 45 e4             	mov    %eax,-0x1c(%ebp)
c0104c7c:	8b 45 e8             	mov    -0x18(%ebp),%eax
c0104c7f:	89 45 e0             	mov    %eax,-0x20(%ebp)
 * Insert the new element @elm *after* the element @listelm which
 * is already in the list.
 * */
static inline void
list_add_after(list_entry_t *listelm, list_entry_t *elm) {
    __list_add(elm, listelm, listelm->next);
c0104c82:	8b 45 e4             	mov    -0x1c(%ebp),%eax
c0104c85:	8b 40 04             	mov    0x4(%eax),%eax
c0104c88:	8b 55 e0             	mov    -0x20(%ebp),%edx
c0104c8b:	89 55 dc             	mov    %edx,-0x24(%ebp)
c0104c8e:	8b 55 e4             	mov    -0x1c(%ebp),%edx
c0104c91:	89 55 d8             	mov    %edx,-0x28(%ebp)
c0104c94:	89 45 d4             	mov    %eax,-0x2c(%ebp)
 * This is only for internal list manipulation where we know
 * the prev/next entries already!
 * */
static inline void
__list_add(list_entry_t *elm, list_entry_t *prev, list_entry_t *next) {
    prev->next = next->prev = elm;
c0104c97:	8b 45 d4             	mov    -0x2c(%ebp),%eax
c0104c9a:	8b 55 dc             	mov    -0x24(%ebp),%edx
c0104c9d:	89 10                	mov    %edx,(%eax)
c0104c9f:	8b 45 d4             	mov    -0x2c(%ebp),%eax
c0104ca2:	8b 10                	mov    (%eax),%edx
c0104ca4:	8b 45 d8             	mov    -0x28(%ebp),%eax
c0104ca7:	89 50 04             	mov    %edx,0x4(%eax)
    elm->next = next;
c0104caa:	8b 45 dc             	mov    -0x24(%ebp),%eax
c0104cad:	8b 55 d4             	mov    -0x2c(%ebp),%edx
c0104cb0:	89 50 04             	mov    %edx,0x4(%eax)
    elm->prev = prev;
c0104cb3:	8b 45 dc             	mov    -0x24(%ebp),%eax
c0104cb6:	8b 55 d8             	mov    -0x28(%ebp),%edx
c0104cb9:	89 10                	mov    %edx,(%eax)
    //record the page access situlation
    /*LAB3 EXERCISE 2: YOUR CODE*/ 
    //(1)link the most recent arrival page at the back of the pra_list_head qeueue.
    list_add(head, entry);     //练习二，看似插进entry，实则把这个访问的页排好了序
    return 0;
c0104cbb:	b8 00 00 00 00       	mov    $0x0,%eax
}
c0104cc0:	c9                   	leave  
c0104cc1:	c3                   	ret    

c0104cc2 <_fifo_swap_out_victim>:
 *  (4)_fifo_swap_out_victim: According FIFO PRA, we should unlink the  earliest arrival page in front of pra_list_head qeueue,
 *                            then assign the value of *ptr_page to the addr of this page.
 */
static int      //只是选中了最老页，然后剔除它
_fifo_swap_out_victim(struct mm_struct *mm, struct Page ** ptr_page, int in_tick)
{
c0104cc2:	55                   	push   %ebp
c0104cc3:	89 e5                	mov    %esp,%ebp
c0104cc5:	83 ec 38             	sub    $0x38,%esp
     list_entry_t *head=(list_entry_t*) mm->sm_priv;
c0104cc8:	8b 45 08             	mov    0x8(%ebp),%eax
c0104ccb:	8b 40 14             	mov    0x14(%eax),%eax
c0104cce:	89 45 f4             	mov    %eax,-0xc(%ebp)
         assert(head != NULL);
c0104cd1:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
c0104cd5:	75 24                	jne    c0104cfb <_fifo_swap_out_victim+0x39>
c0104cd7:	c7 44 24 0c f3 ac 10 	movl   $0xc010acf3,0xc(%esp)
c0104cde:	c0 
c0104cdf:	c7 44 24 08 ca ac 10 	movl   $0xc010acca,0x8(%esp)
c0104ce6:	c0 
c0104ce7:	c7 44 24 04 41 00 00 	movl   $0x41,0x4(%esp)
c0104cee:	00 
c0104cef:	c7 04 24 df ac 10 c0 	movl   $0xc010acdf,(%esp)
c0104cf6:	e8 05 b7 ff ff       	call   c0100400 <__panic>
     assert(in_tick==0);                             //应该是0，表示没有积极替换；tick：结合定时产生的中断，可以实现一种积极的换页策略。
c0104cfb:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
c0104cff:	74 24                	je     c0104d25 <_fifo_swap_out_victim+0x63>
c0104d01:	c7 44 24 0c 00 ad 10 	movl   $0xc010ad00,0xc(%esp)
c0104d08:	c0 
c0104d09:	c7 44 24 08 ca ac 10 	movl   $0xc010acca,0x8(%esp)
c0104d10:	c0 
c0104d11:	c7 44 24 04 42 00 00 	movl   $0x42,0x4(%esp)
c0104d18:	00 
c0104d19:	c7 04 24 df ac 10 c0 	movl   $0xc010acdf,(%esp)
c0104d20:	e8 db b6 ff ff       	call   c0100400 <__panic>
     /* Select the victim */
     /*LAB3 EXERCISE 2: YOUR CODE*/ 
     //(1)  unlink the  earliest arrival page in front of pra_list_head qeueue
     //(2)  assign the value of *ptr_page to the addr of this page
      /* Select the tail */
     list_entry_t *le = head->prev;                 //头部之前是表尾（队头）
c0104d25:	8b 45 f4             	mov    -0xc(%ebp),%eax
c0104d28:	8b 00                	mov    (%eax),%eax
c0104d2a:	89 45 f0             	mov    %eax,-0x10(%ebp)
     assert(head!=le);
c0104d2d:	8b 45 f4             	mov    -0xc(%ebp),%eax
c0104d30:	3b 45 f0             	cmp    -0x10(%ebp),%eax
c0104d33:	75 24                	jne    c0104d59 <_fifo_swap_out_victim+0x97>
c0104d35:	c7 44 24 0c 0b ad 10 	movl   $0xc010ad0b,0xc(%esp)
c0104d3c:	c0 
c0104d3d:	c7 44 24 08 ca ac 10 	movl   $0xc010acca,0x8(%esp)
c0104d44:	c0 
c0104d45:	c7 44 24 04 49 00 00 	movl   $0x49,0x4(%esp)
c0104d4c:	00 
c0104d4d:	c7 04 24 df ac 10 c0 	movl   $0xc010acdf,(%esp)
c0104d54:	e8 a7 b6 ff ff       	call   c0100400 <__panic>
     struct Page *p = le2page(le, pra_page_link);   //选中表尾链表项对应的page页，把它换出
c0104d59:	8b 45 f0             	mov    -0x10(%ebp),%eax
c0104d5c:	83 e8 14             	sub    $0x14,%eax
c0104d5f:	89 45 ec             	mov    %eax,-0x14(%ebp)
c0104d62:	8b 45 f0             	mov    -0x10(%ebp),%eax
c0104d65:	89 45 e8             	mov    %eax,-0x18(%ebp)
    __list_del(listelm->prev, listelm->next);
c0104d68:	8b 45 e8             	mov    -0x18(%ebp),%eax
c0104d6b:	8b 40 04             	mov    0x4(%eax),%eax
c0104d6e:	8b 55 e8             	mov    -0x18(%ebp),%edx
c0104d71:	8b 12                	mov    (%edx),%edx
c0104d73:	89 55 e4             	mov    %edx,-0x1c(%ebp)
c0104d76:	89 45 e0             	mov    %eax,-0x20(%ebp)
 * This is only for internal list manipulation where we know
 * the prev/next entries already!
 * */
static inline void
__list_del(list_entry_t *prev, list_entry_t *next) {
    prev->next = next;
c0104d79:	8b 45 e4             	mov    -0x1c(%ebp),%eax
c0104d7c:	8b 55 e0             	mov    -0x20(%ebp),%edx
c0104d7f:	89 50 04             	mov    %edx,0x4(%eax)
    next->prev = prev;
c0104d82:	8b 45 e0             	mov    -0x20(%ebp),%eax
c0104d85:	8b 55 e4             	mov    -0x1c(%ebp),%edx
c0104d88:	89 10                	mov    %edx,(%eax)
     list_del(le);                                  //一个页的换出：就只是把它的链表项从链表（（按页的第一次访问时间排序））中剔除
     assert(p !=NULL);
c0104d8a:	83 7d ec 00          	cmpl   $0x0,-0x14(%ebp)
c0104d8e:	75 24                	jne    c0104db4 <_fifo_swap_out_victim+0xf2>
c0104d90:	c7 44 24 0c 14 ad 10 	movl   $0xc010ad14,0xc(%esp)
c0104d97:	c0 
c0104d98:	c7 44 24 08 ca ac 10 	movl   $0xc010acca,0x8(%esp)
c0104d9f:	c0 
c0104da0:	c7 44 24 04 4c 00 00 	movl   $0x4c,0x4(%esp)
c0104da7:	00 
c0104da8:	c7 04 24 df ac 10 c0 	movl   $0xc010acdf,(%esp)
c0104daf:	e8 4c b6 ff ff       	call   c0100400 <__panic>
     *ptr_page = p;                                 //看实参咋用，后续这个ptr_page在哪用，存的是被剔除的页
c0104db4:	8b 45 0c             	mov    0xc(%ebp),%eax
c0104db7:	8b 55 ec             	mov    -0x14(%ebp),%edx
c0104dba:	89 10                	mov    %edx,(%eax)
     return 0;
c0104dbc:	b8 00 00 00 00       	mov    $0x0,%eax
}
c0104dc1:	c9                   	leave  
c0104dc2:	c3                   	ret    

c0104dc3 <_fifo_check_swap>:

static int
_fifo_check_swap(void) {        //练习二vmm.c的check_swap()会用到
c0104dc3:	55                   	push   %ebp
c0104dc4:	89 e5                	mov    %esp,%ebp
c0104dc6:	83 ec 18             	sub    $0x18,%esp
    cprintf("write Virt Page c in fifo_check_swap\n");
c0104dc9:	c7 04 24 20 ad 10 c0 	movl   $0xc010ad20,(%esp)
c0104dd0:	e8 d4 b4 ff ff       	call   c01002a9 <cprintf>
    *(unsigned char *)0x3000 = 0x0c;//h
c0104dd5:	b8 00 30 00 00       	mov    $0x3000,%eax
c0104dda:	c6 00 0c             	movb   $0xc,(%eax)
    assert(pgfault_num==4);
c0104ddd:	a1 0c 90 12 c0       	mov    0xc012900c,%eax
c0104de2:	83 f8 04             	cmp    $0x4,%eax
c0104de5:	74 24                	je     c0104e0b <_fifo_check_swap+0x48>
c0104de7:	c7 44 24 0c 46 ad 10 	movl   $0xc010ad46,0xc(%esp)
c0104dee:	c0 
c0104def:	c7 44 24 08 ca ac 10 	movl   $0xc010acca,0x8(%esp)
c0104df6:	c0 
c0104df7:	c7 44 24 04 55 00 00 	movl   $0x55,0x4(%esp)
c0104dfe:	00 
c0104dff:	c7 04 24 df ac 10 c0 	movl   $0xc010acdf,(%esp)
c0104e06:	e8 f5 b5 ff ff       	call   c0100400 <__panic>
    cprintf("write Virt Page a in fifo_check_swap\n");
c0104e0b:	c7 04 24 58 ad 10 c0 	movl   $0xc010ad58,(%esp)
c0104e12:	e8 92 b4 ff ff       	call   c01002a9 <cprintf>
    *(unsigned char *)0x1000 = 0x0a;//h
c0104e17:	b8 00 10 00 00       	mov    $0x1000,%eax
c0104e1c:	c6 00 0a             	movb   $0xa,(%eax)
    assert(pgfault_num==4);
c0104e1f:	a1 0c 90 12 c0       	mov    0xc012900c,%eax
c0104e24:	83 f8 04             	cmp    $0x4,%eax
c0104e27:	74 24                	je     c0104e4d <_fifo_check_swap+0x8a>
c0104e29:	c7 44 24 0c 46 ad 10 	movl   $0xc010ad46,0xc(%esp)
c0104e30:	c0 
c0104e31:	c7 44 24 08 ca ac 10 	movl   $0xc010acca,0x8(%esp)
c0104e38:	c0 
c0104e39:	c7 44 24 04 58 00 00 	movl   $0x58,0x4(%esp)
c0104e40:	00 
c0104e41:	c7 04 24 df ac 10 c0 	movl   $0xc010acdf,(%esp)
c0104e48:	e8 b3 b5 ff ff       	call   c0100400 <__panic>
    cprintf("write Virt Page d in fifo_check_swap\n");
c0104e4d:	c7 04 24 80 ad 10 c0 	movl   $0xc010ad80,(%esp)
c0104e54:	e8 50 b4 ff ff       	call   c01002a9 <cprintf>
    *(unsigned char *)0x4000 = 0x0d;//h
c0104e59:	b8 00 40 00 00       	mov    $0x4000,%eax
c0104e5e:	c6 00 0d             	movb   $0xd,(%eax)
    assert(pgfault_num==4);
c0104e61:	a1 0c 90 12 c0       	mov    0xc012900c,%eax
c0104e66:	83 f8 04             	cmp    $0x4,%eax
c0104e69:	74 24                	je     c0104e8f <_fifo_check_swap+0xcc>
c0104e6b:	c7 44 24 0c 46 ad 10 	movl   $0xc010ad46,0xc(%esp)
c0104e72:	c0 
c0104e73:	c7 44 24 08 ca ac 10 	movl   $0xc010acca,0x8(%esp)
c0104e7a:	c0 
c0104e7b:	c7 44 24 04 5b 00 00 	movl   $0x5b,0x4(%esp)
c0104e82:	00 
c0104e83:	c7 04 24 df ac 10 c0 	movl   $0xc010acdf,(%esp)
c0104e8a:	e8 71 b5 ff ff       	call   c0100400 <__panic>
    cprintf("write Virt Page b in fifo_check_swap\n");
c0104e8f:	c7 04 24 a8 ad 10 c0 	movl   $0xc010ada8,(%esp)
c0104e96:	e8 0e b4 ff ff       	call   c01002a9 <cprintf>
    *(unsigned char *)0x2000 = 0x0b;//h
c0104e9b:	b8 00 20 00 00       	mov    $0x2000,%eax
c0104ea0:	c6 00 0b             	movb   $0xb,(%eax)
    assert(pgfault_num==4);
c0104ea3:	a1 0c 90 12 c0       	mov    0xc012900c,%eax
c0104ea8:	83 f8 04             	cmp    $0x4,%eax
c0104eab:	74 24                	je     c0104ed1 <_fifo_check_swap+0x10e>
c0104ead:	c7 44 24 0c 46 ad 10 	movl   $0xc010ad46,0xc(%esp)
c0104eb4:	c0 
c0104eb5:	c7 44 24 08 ca ac 10 	movl   $0xc010acca,0x8(%esp)
c0104ebc:	c0 
c0104ebd:	c7 44 24 04 5e 00 00 	movl   $0x5e,0x4(%esp)
c0104ec4:	00 
c0104ec5:	c7 04 24 df ac 10 c0 	movl   $0xc010acdf,(%esp)
c0104ecc:	e8 2f b5 ff ff       	call   c0100400 <__panic>
    cprintf("write Virt Page e in fifo_check_swap\n");
c0104ed1:	c7 04 24 d0 ad 10 c0 	movl   $0xc010add0,(%esp)
c0104ed8:	e8 cc b3 ff ff       	call   c01002a9 <cprintf>
    *(unsigned char *)0x5000 = 0x0e;//m  换走a，进来e                          //0x5000还没访问过，所以缺页
c0104edd:	b8 00 50 00 00       	mov    $0x5000,%eax
c0104ee2:	c6 00 0e             	movb   $0xe,(%eax)
    assert(pgfault_num==5);
c0104ee5:	a1 0c 90 12 c0       	mov    0xc012900c,%eax
c0104eea:	83 f8 05             	cmp    $0x5,%eax
c0104eed:	74 24                	je     c0104f13 <_fifo_check_swap+0x150>
c0104eef:	c7 44 24 0c f6 ad 10 	movl   $0xc010adf6,0xc(%esp)
c0104ef6:	c0 
c0104ef7:	c7 44 24 08 ca ac 10 	movl   $0xc010acca,0x8(%esp)
c0104efe:	c0 
c0104eff:	c7 44 24 04 61 00 00 	movl   $0x61,0x4(%esp)
c0104f06:	00 
c0104f07:	c7 04 24 df ac 10 c0 	movl   $0xc010acdf,(%esp)
c0104f0e:	e8 ed b4 ff ff       	call   c0100400 <__panic>
    cprintf("write Virt Page b in fifo_check_swap\n");
c0104f13:	c7 04 24 a8 ad 10 c0 	movl   $0xc010ada8,(%esp)
c0104f1a:	e8 8a b3 ff ff       	call   c01002a9 <cprintf>
    *(unsigned char *)0x2000 = 0x0b;
c0104f1f:	b8 00 20 00 00       	mov    $0x2000,%eax
c0104f24:	c6 00 0b             	movb   $0xb,(%eax)
    assert(pgfault_num==5);
c0104f27:	a1 0c 90 12 c0       	mov    0xc012900c,%eax
c0104f2c:	83 f8 05             	cmp    $0x5,%eax
c0104f2f:	74 24                	je     c0104f55 <_fifo_check_swap+0x192>
c0104f31:	c7 44 24 0c f6 ad 10 	movl   $0xc010adf6,0xc(%esp)
c0104f38:	c0 
c0104f39:	c7 44 24 08 ca ac 10 	movl   $0xc010acca,0x8(%esp)
c0104f40:	c0 
c0104f41:	c7 44 24 04 64 00 00 	movl   $0x64,0x4(%esp)
c0104f48:	00 
c0104f49:	c7 04 24 df ac 10 c0 	movl   $0xc010acdf,(%esp)
c0104f50:	e8 ab b4 ff ff       	call   c0100400 <__panic>
    cprintf("write Virt Page a in fifo_check_swap\n");
c0104f55:	c7 04 24 58 ad 10 c0 	movl   $0xc010ad58,(%esp)
c0104f5c:	e8 48 b3 ff ff       	call   c01002a9 <cprintf>
    *(unsigned char *)0x1000 = 0x0a;//m 换走b，进来a
c0104f61:	b8 00 10 00 00       	mov    $0x1000,%eax
c0104f66:	c6 00 0a             	movb   $0xa,(%eax)
    assert(pgfault_num==6);
c0104f69:	a1 0c 90 12 c0       	mov    0xc012900c,%eax
c0104f6e:	83 f8 06             	cmp    $0x6,%eax
c0104f71:	74 24                	je     c0104f97 <_fifo_check_swap+0x1d4>
c0104f73:	c7 44 24 0c 05 ae 10 	movl   $0xc010ae05,0xc(%esp)
c0104f7a:	c0 
c0104f7b:	c7 44 24 08 ca ac 10 	movl   $0xc010acca,0x8(%esp)
c0104f82:	c0 
c0104f83:	c7 44 24 04 67 00 00 	movl   $0x67,0x4(%esp)
c0104f8a:	00 
c0104f8b:	c7 04 24 df ac 10 c0 	movl   $0xc010acdf,(%esp)
c0104f92:	e8 69 b4 ff ff       	call   c0100400 <__panic>
    cprintf("write Virt Page b in fifo_check_swap\n");
c0104f97:	c7 04 24 a8 ad 10 c0 	movl   $0xc010ada8,(%esp)
c0104f9e:	e8 06 b3 ff ff       	call   c01002a9 <cprintf>
    *(unsigned char *)0x2000 = 0x0b;//m 换走c，进来b
c0104fa3:	b8 00 20 00 00       	mov    $0x2000,%eax
c0104fa8:	c6 00 0b             	movb   $0xb,(%eax)
    assert(pgfault_num==7);
c0104fab:	a1 0c 90 12 c0       	mov    0xc012900c,%eax
c0104fb0:	83 f8 07             	cmp    $0x7,%eax
c0104fb3:	74 24                	je     c0104fd9 <_fifo_check_swap+0x216>
c0104fb5:	c7 44 24 0c 14 ae 10 	movl   $0xc010ae14,0xc(%esp)
c0104fbc:	c0 
c0104fbd:	c7 44 24 08 ca ac 10 	movl   $0xc010acca,0x8(%esp)
c0104fc4:	c0 
c0104fc5:	c7 44 24 04 6a 00 00 	movl   $0x6a,0x4(%esp)
c0104fcc:	00 
c0104fcd:	c7 04 24 df ac 10 c0 	movl   $0xc010acdf,(%esp)
c0104fd4:	e8 27 b4 ff ff       	call   c0100400 <__panic>
    cprintf("write Virt Page c in fifo_check_swap\n");
c0104fd9:	c7 04 24 20 ad 10 c0 	movl   $0xc010ad20,(%esp)
c0104fe0:	e8 c4 b2 ff ff       	call   c01002a9 <cprintf>
    *(unsigned char *)0x3000 = 0x0c;
c0104fe5:	b8 00 30 00 00       	mov    $0x3000,%eax
c0104fea:	c6 00 0c             	movb   $0xc,(%eax)
    assert(pgfault_num==8);
c0104fed:	a1 0c 90 12 c0       	mov    0xc012900c,%eax
c0104ff2:	83 f8 08             	cmp    $0x8,%eax
c0104ff5:	74 24                	je     c010501b <_fifo_check_swap+0x258>
c0104ff7:	c7 44 24 0c 23 ae 10 	movl   $0xc010ae23,0xc(%esp)
c0104ffe:	c0 
c0104fff:	c7 44 24 08 ca ac 10 	movl   $0xc010acca,0x8(%esp)
c0105006:	c0 
c0105007:	c7 44 24 04 6d 00 00 	movl   $0x6d,0x4(%esp)
c010500e:	00 
c010500f:	c7 04 24 df ac 10 c0 	movl   $0xc010acdf,(%esp)
c0105016:	e8 e5 b3 ff ff       	call   c0100400 <__panic>
    cprintf("write Virt Page d in fifo_check_swap\n");
c010501b:	c7 04 24 80 ad 10 c0 	movl   $0xc010ad80,(%esp)
c0105022:	e8 82 b2 ff ff       	call   c01002a9 <cprintf>
    *(unsigned char *)0x4000 = 0x0d;
c0105027:	b8 00 40 00 00       	mov    $0x4000,%eax
c010502c:	c6 00 0d             	movb   $0xd,(%eax)
    assert(pgfault_num==9);
c010502f:	a1 0c 90 12 c0       	mov    0xc012900c,%eax
c0105034:	83 f8 09             	cmp    $0x9,%eax
c0105037:	74 24                	je     c010505d <_fifo_check_swap+0x29a>
c0105039:	c7 44 24 0c 32 ae 10 	movl   $0xc010ae32,0xc(%esp)
c0105040:	c0 
c0105041:	c7 44 24 08 ca ac 10 	movl   $0xc010acca,0x8(%esp)
c0105048:	c0 
c0105049:	c7 44 24 04 70 00 00 	movl   $0x70,0x4(%esp)
c0105050:	00 
c0105051:	c7 04 24 df ac 10 c0 	movl   $0xc010acdf,(%esp)
c0105058:	e8 a3 b3 ff ff       	call   c0100400 <__panic>
    cprintf("write Virt Page e in fifo_check_swap\n");
c010505d:	c7 04 24 d0 ad 10 c0 	movl   $0xc010add0,(%esp)
c0105064:	e8 40 b2 ff ff       	call   c01002a9 <cprintf>
    *(unsigned char *)0x5000 = 0x0e;
c0105069:	b8 00 50 00 00       	mov    $0x5000,%eax
c010506e:	c6 00 0e             	movb   $0xe,(%eax)
    assert(pgfault_num==10);
c0105071:	a1 0c 90 12 c0       	mov    0xc012900c,%eax
c0105076:	83 f8 0a             	cmp    $0xa,%eax
c0105079:	74 24                	je     c010509f <_fifo_check_swap+0x2dc>
c010507b:	c7 44 24 0c 41 ae 10 	movl   $0xc010ae41,0xc(%esp)
c0105082:	c0 
c0105083:	c7 44 24 08 ca ac 10 	movl   $0xc010acca,0x8(%esp)
c010508a:	c0 
c010508b:	c7 44 24 04 73 00 00 	movl   $0x73,0x4(%esp)
c0105092:	00 
c0105093:	c7 04 24 df ac 10 c0 	movl   $0xc010acdf,(%esp)
c010509a:	e8 61 b3 ff ff       	call   c0100400 <__panic>
    cprintf("write Virt Page a in fifo_check_swap\n");
c010509f:	c7 04 24 58 ad 10 c0 	movl   $0xc010ad58,(%esp)
c01050a6:	e8 fe b1 ff ff       	call   c01002a9 <cprintf>
    assert(*(unsigned char *)0x1000 == 0x0a);
c01050ab:	b8 00 10 00 00       	mov    $0x1000,%eax
c01050b0:	0f b6 00             	movzbl (%eax),%eax
c01050b3:	3c 0a                	cmp    $0xa,%al
c01050b5:	74 24                	je     c01050db <_fifo_check_swap+0x318>
c01050b7:	c7 44 24 0c 54 ae 10 	movl   $0xc010ae54,0xc(%esp)
c01050be:	c0 
c01050bf:	c7 44 24 08 ca ac 10 	movl   $0xc010acca,0x8(%esp)
c01050c6:	c0 
c01050c7:	c7 44 24 04 75 00 00 	movl   $0x75,0x4(%esp)
c01050ce:	00 
c01050cf:	c7 04 24 df ac 10 c0 	movl   $0xc010acdf,(%esp)
c01050d6:	e8 25 b3 ff ff       	call   c0100400 <__panic>
    *(unsigned char *)0x1000 = 0x0a;
c01050db:	b8 00 10 00 00       	mov    $0x1000,%eax
c01050e0:	c6 00 0a             	movb   $0xa,(%eax)
    assert(pgfault_num==11);
c01050e3:	a1 0c 90 12 c0       	mov    0xc012900c,%eax
c01050e8:	83 f8 0b             	cmp    $0xb,%eax
c01050eb:	74 24                	je     c0105111 <_fifo_check_swap+0x34e>
c01050ed:	c7 44 24 0c 75 ae 10 	movl   $0xc010ae75,0xc(%esp)
c01050f4:	c0 
c01050f5:	c7 44 24 08 ca ac 10 	movl   $0xc010acca,0x8(%esp)
c01050fc:	c0 
c01050fd:	c7 44 24 04 77 00 00 	movl   $0x77,0x4(%esp)
c0105104:	00 
c0105105:	c7 04 24 df ac 10 c0 	movl   $0xc010acdf,(%esp)
c010510c:	e8 ef b2 ff ff       	call   c0100400 <__panic>
    return 0;
c0105111:	b8 00 00 00 00       	mov    $0x0,%eax
}
c0105116:	c9                   	leave  
c0105117:	c3                   	ret    

c0105118 <_fifo_init>:


static int
_fifo_init(void)
{
c0105118:	55                   	push   %ebp
c0105119:	89 e5                	mov    %esp,%ebp
    return 0;
c010511b:	b8 00 00 00 00       	mov    $0x0,%eax
}
c0105120:	5d                   	pop    %ebp
c0105121:	c3                   	ret    

c0105122 <_fifo_set_unswappable>:

static int
_fifo_set_unswappable(struct mm_struct *mm, uintptr_t addr)
{
c0105122:	55                   	push   %ebp
c0105123:	89 e5                	mov    %esp,%ebp
    return 0;
c0105125:	b8 00 00 00 00       	mov    $0x0,%eax
}
c010512a:	5d                   	pop    %ebp
c010512b:	c3                   	ret    

c010512c <_fifo_tick_event>:

static int
_fifo_tick_event(struct mm_struct *mm)
{ return 0; }
c010512c:	55                   	push   %ebp
c010512d:	89 e5                	mov    %esp,%ebp
c010512f:	b8 00 00 00 00       	mov    $0x0,%eax
c0105134:	5d                   	pop    %ebp
c0105135:	c3                   	ret    

c0105136 <pa2page>:
pa2page(uintptr_t pa) {
c0105136:	55                   	push   %ebp
c0105137:	89 e5                	mov    %esp,%ebp
c0105139:	83 ec 18             	sub    $0x18,%esp
    if (PPN(pa) >= npage) {
c010513c:	8b 45 08             	mov    0x8(%ebp),%eax
c010513f:	c1 e8 0c             	shr    $0xc,%eax
c0105142:	89 c2                	mov    %eax,%edx
c0105144:	a1 80 8f 12 c0       	mov    0xc0128f80,%eax
c0105149:	39 c2                	cmp    %eax,%edx
c010514b:	72 1c                	jb     c0105169 <pa2page+0x33>
        panic("pa2page called with invalid pa");
c010514d:	c7 44 24 08 98 ae 10 	movl   $0xc010ae98,0x8(%esp)
c0105154:	c0 
c0105155:	c7 44 24 04 5f 00 00 	movl   $0x5f,0x4(%esp)
c010515c:	00 
c010515d:	c7 04 24 b7 ae 10 c0 	movl   $0xc010aeb7,(%esp)
c0105164:	e8 97 b2 ff ff       	call   c0100400 <__panic>
    return &pages[PPN(pa)];   //pages+pa高20bit索引位 摒弃低12bit全0
c0105169:	a1 60 b0 12 c0       	mov    0xc012b060,%eax
c010516e:	8b 55 08             	mov    0x8(%ebp),%edx
c0105171:	c1 ea 0c             	shr    $0xc,%edx
c0105174:	c1 e2 05             	shl    $0x5,%edx
c0105177:	01 d0                	add    %edx,%eax
}
c0105179:	c9                   	leave  
c010517a:	c3                   	ret    

c010517b <pde2page>:
pde2page(pde_t pde) {
c010517b:	55                   	push   %ebp
c010517c:	89 e5                	mov    %esp,%ebp
c010517e:	83 ec 18             	sub    $0x18,%esp
    return pa2page(PDE_ADDR(pde));
c0105181:	8b 45 08             	mov    0x8(%ebp),%eax
c0105184:	25 00 f0 ff ff       	and    $0xfffff000,%eax
c0105189:	89 04 24             	mov    %eax,(%esp)
c010518c:	e8 a5 ff ff ff       	call   c0105136 <pa2page>
}
c0105191:	c9                   	leave  
c0105192:	c3                   	ret    

c0105193 <mm_create>:
static void check_vma_struct(void);
static void check_pgfault(void);

// mm_create -  alloc a mm_struct & initialize it.
struct mm_struct *
mm_create(void) {
c0105193:	55                   	push   %ebp
c0105194:	89 e5                	mov    %esp,%ebp
c0105196:	83 ec 28             	sub    $0x28,%esp
    struct mm_struct *mm = kmalloc(sizeof(struct mm_struct));   //kmalloc在pmm.c，返回一个kva地址
c0105199:	c7 04 24 18 00 00 00 	movl   $0x18,(%esp)
c01051a0:	e8 bc 12 00 00       	call   c0106461 <kmalloc>
c01051a5:	89 45 f4             	mov    %eax,-0xc(%ebp)

    if (mm != NULL) {
c01051a8:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
c01051ac:	74 58                	je     c0105206 <mm_create+0x73>
        list_init(&(mm->mmap_list));
c01051ae:	8b 45 f4             	mov    -0xc(%ebp),%eax
c01051b1:	89 45 f0             	mov    %eax,-0x10(%ebp)
    elm->prev = elm->next = elm;
c01051b4:	8b 45 f0             	mov    -0x10(%ebp),%eax
c01051b7:	8b 55 f0             	mov    -0x10(%ebp),%edx
c01051ba:	89 50 04             	mov    %edx,0x4(%eax)
c01051bd:	8b 45 f0             	mov    -0x10(%ebp),%eax
c01051c0:	8b 50 04             	mov    0x4(%eax),%edx
c01051c3:	8b 45 f0             	mov    -0x10(%ebp),%eax
c01051c6:	89 10                	mov    %edx,(%eax)
        mm->mmap_cache = NULL;                  //find_vma里更新cache
c01051c8:	8b 45 f4             	mov    -0xc(%ebp),%eax
c01051cb:	c7 40 08 00 00 00 00 	movl   $0x0,0x8(%eax)
        mm->pgdir = NULL;
c01051d2:	8b 45 f4             	mov    -0xc(%ebp),%eax
c01051d5:	c7 40 0c 00 00 00 00 	movl   $0x0,0xc(%eax)
        mm->map_count = 0;                      //insert vma会：mm->map_count++
c01051dc:	8b 45 f4             	mov    -0xc(%ebp),%eax
c01051df:	c7 40 10 00 00 00 00 	movl   $0x0,0x10(%eax)

        if (swap_init_ok) swap_init_mm(mm);     //swap_fifo.c的37行 mm->sm_priv = &pra_list_head;
c01051e6:	a1 14 90 12 c0       	mov    0xc0129014,%eax
c01051eb:	85 c0                	test   %eax,%eax
c01051ed:	74 0d                	je     c01051fc <mm_create+0x69>
c01051ef:	8b 45 f4             	mov    -0xc(%ebp),%eax
c01051f2:	89 04 24             	mov    %eax,(%esp)
c01051f5:	e8 d3 14 00 00       	call   c01066cd <swap_init_mm>
c01051fa:	eb 0a                	jmp    c0105206 <mm_create+0x73>
        else mm->sm_priv = NULL;
c01051fc:	8b 45 f4             	mov    -0xc(%ebp),%eax
c01051ff:	c7 40 14 00 00 00 00 	movl   $0x0,0x14(%eax)
    }
    return mm;
c0105206:	8b 45 f4             	mov    -0xc(%ebp),%eax
}
c0105209:	c9                   	leave  
c010520a:	c3                   	ret    

c010520b <vma_create>:

// vma_create - alloc a vma_struct & initialize it. (addr range: vm_start~vm_end)
struct vma_struct *
vma_create(uintptr_t vm_start, uintptr_t vm_end, uint32_t vm_flags) {
c010520b:	55                   	push   %ebp
c010520c:	89 e5                	mov    %esp,%ebp
c010520e:	83 ec 28             	sub    $0x28,%esp
    struct vma_struct *vma = kmalloc(sizeof(struct vma_struct));
c0105211:	c7 04 24 18 00 00 00 	movl   $0x18,(%esp)
c0105218:	e8 44 12 00 00       	call   c0106461 <kmalloc>
c010521d:	89 45 f4             	mov    %eax,-0xc(%ebp)

    if (vma != NULL) {
c0105220:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
c0105224:	74 1b                	je     c0105241 <vma_create+0x36>
        vma->vm_start = vm_start;
c0105226:	8b 45 f4             	mov    -0xc(%ebp),%eax
c0105229:	8b 55 08             	mov    0x8(%ebp),%edx
c010522c:	89 50 04             	mov    %edx,0x4(%eax)
        vma->vm_end = vm_end;
c010522f:	8b 45 f4             	mov    -0xc(%ebp),%eax
c0105232:	8b 55 0c             	mov    0xc(%ebp),%edx
c0105235:	89 50 08             	mov    %edx,0x8(%eax)
        vma->vm_flags = vm_flags;   //list初始化捏？ insert vma会：vma->vm_mm = mm;
c0105238:	8b 45 f4             	mov    -0xc(%ebp),%eax
c010523b:	8b 55 10             	mov    0x10(%ebp),%edx
c010523e:	89 50 0c             	mov    %edx,0xc(%eax)
    }
    return vma;
c0105241:	8b 45 f4             	mov    -0xc(%ebp),%eax
}
c0105244:	c9                   	leave  
c0105245:	c3                   	ret    

c0105246 <find_vma>:


// find_vma - find a vma  (vma->vm_start <= addr <= vma_vm_end)     //在给定的mm里找到addr所属的vma
struct vma_struct *
find_vma(struct mm_struct *mm, uintptr_t addr) {
c0105246:	55                   	push   %ebp
c0105247:	89 e5                	mov    %esp,%ebp
c0105249:	83 ec 20             	sub    $0x20,%esp
    struct vma_struct *vma = NULL;
c010524c:	c7 45 fc 00 00 00 00 	movl   $0x0,-0x4(%ebp)
    if (mm != NULL) {
c0105253:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
c0105257:	0f 84 95 00 00 00    	je     c01052f2 <find_vma+0xac>
        vma = mm->mmap_cache;                                       //先看cache里的vma符不符合，加快速度
c010525d:	8b 45 08             	mov    0x8(%ebp),%eax
c0105260:	8b 40 08             	mov    0x8(%eax),%eax
c0105263:	89 45 fc             	mov    %eax,-0x4(%ebp)
        if (!(vma != NULL && vma->vm_start <= addr && vma->vm_end > addr)) {    //cache里的vma不符合
c0105266:	83 7d fc 00          	cmpl   $0x0,-0x4(%ebp)
c010526a:	74 16                	je     c0105282 <find_vma+0x3c>
c010526c:	8b 45 fc             	mov    -0x4(%ebp),%eax
c010526f:	8b 40 04             	mov    0x4(%eax),%eax
c0105272:	39 45 0c             	cmp    %eax,0xc(%ebp)
c0105275:	72 0b                	jb     c0105282 <find_vma+0x3c>
c0105277:	8b 45 fc             	mov    -0x4(%ebp),%eax
c010527a:	8b 40 08             	mov    0x8(%eax),%eax
c010527d:	39 45 0c             	cmp    %eax,0xc(%ebp)
c0105280:	72 61                	jb     c01052e3 <find_vma+0x9d>
                bool found = 0;
c0105282:	c7 45 f8 00 00 00 00 	movl   $0x0,-0x8(%ebp)
                list_entry_t *list = &(mm->mmap_list), *le = list;              //从mm的一堆vma里遍历
c0105289:	8b 45 08             	mov    0x8(%ebp),%eax
c010528c:	89 45 f0             	mov    %eax,-0x10(%ebp)
c010528f:	8b 45 f0             	mov    -0x10(%ebp),%eax
c0105292:	89 45 f4             	mov    %eax,-0xc(%ebp)
                while ((le = list_next(le)) != list) {
c0105295:	eb 28                	jmp    c01052bf <find_vma+0x79>
                    vma = le2vma(le, list_link);                                //当前遍历到的vma做检查
c0105297:	8b 45 f4             	mov    -0xc(%ebp),%eax
c010529a:	83 e8 10             	sub    $0x10,%eax
c010529d:	89 45 fc             	mov    %eax,-0x4(%ebp)
                    if (vma->vm_start<=addr && addr < vma->vm_end) {
c01052a0:	8b 45 fc             	mov    -0x4(%ebp),%eax
c01052a3:	8b 40 04             	mov    0x4(%eax),%eax
c01052a6:	39 45 0c             	cmp    %eax,0xc(%ebp)
c01052a9:	72 14                	jb     c01052bf <find_vma+0x79>
c01052ab:	8b 45 fc             	mov    -0x4(%ebp),%eax
c01052ae:	8b 40 08             	mov    0x8(%eax),%eax
c01052b1:	39 45 0c             	cmp    %eax,0xc(%ebp)
c01052b4:	73 09                	jae    c01052bf <find_vma+0x79>
                        found = 1;                                              //当前vma符合
c01052b6:	c7 45 f8 01 00 00 00 	movl   $0x1,-0x8(%ebp)
                        break;
c01052bd:	eb 17                	jmp    c01052d6 <find_vma+0x90>
c01052bf:	8b 45 f4             	mov    -0xc(%ebp),%eax
c01052c2:	89 45 ec             	mov    %eax,-0x14(%ebp)
    return listelm->next;
c01052c5:	8b 45 ec             	mov    -0x14(%ebp),%eax
c01052c8:	8b 40 04             	mov    0x4(%eax),%eax
                while ((le = list_next(le)) != list) {
c01052cb:	89 45 f4             	mov    %eax,-0xc(%ebp)
c01052ce:	8b 45 f4             	mov    -0xc(%ebp),%eax
c01052d1:	3b 45 f0             	cmp    -0x10(%ebp),%eax
c01052d4:	75 c1                	jne    c0105297 <find_vma+0x51>
                    }
                }
                if (!found) {
c01052d6:	83 7d f8 00          	cmpl   $0x0,-0x8(%ebp)
c01052da:	75 07                	jne    c01052e3 <find_vma+0x9d>
                    vma = NULL;
c01052dc:	c7 45 fc 00 00 00 00 	movl   $0x0,-0x4(%ebp)
                }
        }
        if (vma != NULL) {                                          //更新cache（不为空时） 要么是原cache中vma要么是遍历到的vma
c01052e3:	83 7d fc 00          	cmpl   $0x0,-0x4(%ebp)
c01052e7:	74 09                	je     c01052f2 <find_vma+0xac>
            mm->mmap_cache = vma;
c01052e9:	8b 45 08             	mov    0x8(%ebp),%eax
c01052ec:	8b 55 fc             	mov    -0x4(%ebp),%edx
c01052ef:	89 50 08             	mov    %edx,0x8(%eax)
        }
    }
    return vma;
c01052f2:	8b 45 fc             	mov    -0x4(%ebp),%eax
}
c01052f5:	c9                   	leave  
c01052f6:	c3                   	ret    

c01052f7 <check_vma_overlap>:


// check_vma_overlap - check if vma1 overlaps vma2 ?
static inline void
check_vma_overlap(struct vma_struct *prev, struct vma_struct *next) {   //保证vma之间区域没有重合！
c01052f7:	55                   	push   %ebp
c01052f8:	89 e5                	mov    %esp,%ebp
c01052fa:	83 ec 18             	sub    $0x18,%esp
    assert(prev->vm_start < prev->vm_end);
c01052fd:	8b 45 08             	mov    0x8(%ebp),%eax
c0105300:	8b 50 04             	mov    0x4(%eax),%edx
c0105303:	8b 45 08             	mov    0x8(%ebp),%eax
c0105306:	8b 40 08             	mov    0x8(%eax),%eax
c0105309:	39 c2                	cmp    %eax,%edx
c010530b:	72 24                	jb     c0105331 <check_vma_overlap+0x3a>
c010530d:	c7 44 24 0c c5 ae 10 	movl   $0xc010aec5,0xc(%esp)
c0105314:	c0 
c0105315:	c7 44 24 08 e3 ae 10 	movl   $0xc010aee3,0x8(%esp)
c010531c:	c0 
c010531d:	c7 44 24 04 68 00 00 	movl   $0x68,0x4(%esp)
c0105324:	00 
c0105325:	c7 04 24 f8 ae 10 c0 	movl   $0xc010aef8,(%esp)
c010532c:	e8 cf b0 ff ff       	call   c0100400 <__panic>
    assert(prev->vm_end <= next->vm_start);
c0105331:	8b 45 08             	mov    0x8(%ebp),%eax
c0105334:	8b 50 08             	mov    0x8(%eax),%edx
c0105337:	8b 45 0c             	mov    0xc(%ebp),%eax
c010533a:	8b 40 04             	mov    0x4(%eax),%eax
c010533d:	39 c2                	cmp    %eax,%edx
c010533f:	76 24                	jbe    c0105365 <check_vma_overlap+0x6e>
c0105341:	c7 44 24 0c 08 af 10 	movl   $0xc010af08,0xc(%esp)
c0105348:	c0 
c0105349:	c7 44 24 08 e3 ae 10 	movl   $0xc010aee3,0x8(%esp)
c0105350:	c0 
c0105351:	c7 44 24 04 69 00 00 	movl   $0x69,0x4(%esp)
c0105358:	00 
c0105359:	c7 04 24 f8 ae 10 c0 	movl   $0xc010aef8,(%esp)
c0105360:	e8 9b b0 ff ff       	call   c0100400 <__panic>
    assert(next->vm_start < next->vm_end);
c0105365:	8b 45 0c             	mov    0xc(%ebp),%eax
c0105368:	8b 50 04             	mov    0x4(%eax),%edx
c010536b:	8b 45 0c             	mov    0xc(%ebp),%eax
c010536e:	8b 40 08             	mov    0x8(%eax),%eax
c0105371:	39 c2                	cmp    %eax,%edx
c0105373:	72 24                	jb     c0105399 <check_vma_overlap+0xa2>
c0105375:	c7 44 24 0c 27 af 10 	movl   $0xc010af27,0xc(%esp)
c010537c:	c0 
c010537d:	c7 44 24 08 e3 ae 10 	movl   $0xc010aee3,0x8(%esp)
c0105384:	c0 
c0105385:	c7 44 24 04 6a 00 00 	movl   $0x6a,0x4(%esp)
c010538c:	00 
c010538d:	c7 04 24 f8 ae 10 c0 	movl   $0xc010aef8,(%esp)
c0105394:	e8 67 b0 ff ff       	call   c0100400 <__panic>
}
c0105399:	90                   	nop
c010539a:	c9                   	leave  
c010539b:	c3                   	ret    

c010539c <insert_vma_struct>:


// insert_vma_struct -insert vma in mm's list link
void
insert_vma_struct(struct mm_struct *mm, struct vma_struct *vma) {
c010539c:	55                   	push   %ebp
c010539d:	89 e5                	mov    %esp,%ebp
c010539f:	83 ec 48             	sub    $0x48,%esp
    assert(vma->vm_start < vma->vm_end);
c01053a2:	8b 45 0c             	mov    0xc(%ebp),%eax
c01053a5:	8b 50 04             	mov    0x4(%eax),%edx
c01053a8:	8b 45 0c             	mov    0xc(%ebp),%eax
c01053ab:	8b 40 08             	mov    0x8(%eax),%eax
c01053ae:	39 c2                	cmp    %eax,%edx
c01053b0:	72 24                	jb     c01053d6 <insert_vma_struct+0x3a>
c01053b2:	c7 44 24 0c 45 af 10 	movl   $0xc010af45,0xc(%esp)
c01053b9:	c0 
c01053ba:	c7 44 24 08 e3 ae 10 	movl   $0xc010aee3,0x8(%esp)
c01053c1:	c0 
c01053c2:	c7 44 24 04 71 00 00 	movl   $0x71,0x4(%esp)
c01053c9:	00 
c01053ca:	c7 04 24 f8 ae 10 c0 	movl   $0xc010aef8,(%esp)
c01053d1:	e8 2a b0 ff ff       	call   c0100400 <__panic>
    list_entry_t *list = &(mm->mmap_list);
c01053d6:	8b 45 08             	mov    0x8(%ebp),%eax
c01053d9:	89 45 ec             	mov    %eax,-0x14(%ebp)
    list_entry_t *le_prev = list, *le_next;     //prev、next为了做vma重合检查
c01053dc:	8b 45 ec             	mov    -0x14(%ebp),%eax
c01053df:	89 45 f4             	mov    %eax,-0xc(%ebp)

        list_entry_t *le = list;
c01053e2:	8b 45 ec             	mov    -0x14(%ebp),%eax
c01053e5:	89 45 f0             	mov    %eax,-0x10(%ebp)
        while ((le = list_next(le)) != list) {
c01053e8:	eb 1f                	jmp    c0105409 <insert_vma_struct+0x6d>
            struct vma_struct *mmap_prev = le2vma(le, list_link);       //遍历到的叫prev
c01053ea:	8b 45 f0             	mov    -0x10(%ebp),%eax
c01053ed:	83 e8 10             	sub    $0x10,%eax
c01053f0:	89 45 e8             	mov    %eax,-0x18(%ebp)
            if (mmap_prev->vm_start > vma->vm_start) {                  //关键插入条件
c01053f3:	8b 45 e8             	mov    -0x18(%ebp),%eax
c01053f6:	8b 50 04             	mov    0x4(%eax),%edx
c01053f9:	8b 45 0c             	mov    0xc(%ebp),%eax
c01053fc:	8b 40 04             	mov    0x4(%eax),%eax
c01053ff:	39 c2                	cmp    %eax,%edx
c0105401:	77 1f                	ja     c0105422 <insert_vma_struct+0x86>
                break;
            }
            le_prev = le;
c0105403:	8b 45 f0             	mov    -0x10(%ebp),%eax
c0105406:	89 45 f4             	mov    %eax,-0xc(%ebp)
c0105409:	8b 45 f0             	mov    -0x10(%ebp),%eax
c010540c:	89 45 e0             	mov    %eax,-0x20(%ebp)
c010540f:	8b 45 e0             	mov    -0x20(%ebp),%eax
c0105412:	8b 40 04             	mov    0x4(%eax),%eax
        while ((le = list_next(le)) != list) {
c0105415:	89 45 f0             	mov    %eax,-0x10(%ebp)
c0105418:	8b 45 f0             	mov    -0x10(%ebp),%eax
c010541b:	3b 45 ec             	cmp    -0x14(%ebp),%eax
c010541e:	75 ca                	jne    c01053ea <insert_vma_struct+0x4e>
c0105420:	eb 01                	jmp    c0105423 <insert_vma_struct+0x87>
                break;
c0105422:	90                   	nop
c0105423:	8b 45 f4             	mov    -0xc(%ebp),%eax
c0105426:	89 45 dc             	mov    %eax,-0x24(%ebp)
c0105429:	8b 45 dc             	mov    -0x24(%ebp),%eax
c010542c:	8b 40 04             	mov    0x4(%eax),%eax
        }

    le_next = list_next(le_prev);
c010542f:	89 45 e4             	mov    %eax,-0x1c(%ebp)

    /* check overlap */
    if (le_prev != list) {
c0105432:	8b 45 f4             	mov    -0xc(%ebp),%eax
c0105435:	3b 45 ec             	cmp    -0x14(%ebp),%eax
c0105438:	74 15                	je     c010544f <insert_vma_struct+0xb3>
        check_vma_overlap(le2vma(le_prev, list_link), vma);     //prev-vma-next不重合
c010543a:	8b 45 f4             	mov    -0xc(%ebp),%eax
c010543d:	8d 50 f0             	lea    -0x10(%eax),%edx
c0105440:	8b 45 0c             	mov    0xc(%ebp),%eax
c0105443:	89 44 24 04          	mov    %eax,0x4(%esp)
c0105447:	89 14 24             	mov    %edx,(%esp)
c010544a:	e8 a8 fe ff ff       	call   c01052f7 <check_vma_overlap>
    }
    if (le_next != list) {
c010544f:	8b 45 e4             	mov    -0x1c(%ebp),%eax
c0105452:	3b 45 ec             	cmp    -0x14(%ebp),%eax
c0105455:	74 15                	je     c010546c <insert_vma_struct+0xd0>
        check_vma_overlap(vma, le2vma(le_next, list_link));
c0105457:	8b 45 e4             	mov    -0x1c(%ebp),%eax
c010545a:	83 e8 10             	sub    $0x10,%eax
c010545d:	89 44 24 04          	mov    %eax,0x4(%esp)
c0105461:	8b 45 0c             	mov    0xc(%ebp),%eax
c0105464:	89 04 24             	mov    %eax,(%esp)
c0105467:	e8 8b fe ff ff       	call   c01052f7 <check_vma_overlap>
    }

    vma->vm_mm = mm;                                        //vma加入小组mm
c010546c:	8b 45 0c             	mov    0xc(%ebp),%eax
c010546f:	8b 55 08             	mov    0x8(%ebp),%edx
c0105472:	89 10                	mov    %edx,(%eax)
    list_add_after(le_prev, &(vma->list_link));             //prev-vma-next
c0105474:	8b 45 0c             	mov    0xc(%ebp),%eax
c0105477:	8d 50 10             	lea    0x10(%eax),%edx
c010547a:	8b 45 f4             	mov    -0xc(%ebp),%eax
c010547d:	89 45 d8             	mov    %eax,-0x28(%ebp)
c0105480:	89 55 d4             	mov    %edx,-0x2c(%ebp)
    __list_add(elm, listelm, listelm->next);
c0105483:	8b 45 d8             	mov    -0x28(%ebp),%eax
c0105486:	8b 40 04             	mov    0x4(%eax),%eax
c0105489:	8b 55 d4             	mov    -0x2c(%ebp),%edx
c010548c:	89 55 d0             	mov    %edx,-0x30(%ebp)
c010548f:	8b 55 d8             	mov    -0x28(%ebp),%edx
c0105492:	89 55 cc             	mov    %edx,-0x34(%ebp)
c0105495:	89 45 c8             	mov    %eax,-0x38(%ebp)
    prev->next = next->prev = elm;
c0105498:	8b 45 c8             	mov    -0x38(%ebp),%eax
c010549b:	8b 55 d0             	mov    -0x30(%ebp),%edx
c010549e:	89 10                	mov    %edx,(%eax)
c01054a0:	8b 45 c8             	mov    -0x38(%ebp),%eax
c01054a3:	8b 10                	mov    (%eax),%edx
c01054a5:	8b 45 cc             	mov    -0x34(%ebp),%eax
c01054a8:	89 50 04             	mov    %edx,0x4(%eax)
    elm->next = next;
c01054ab:	8b 45 d0             	mov    -0x30(%ebp),%eax
c01054ae:	8b 55 c8             	mov    -0x38(%ebp),%edx
c01054b1:	89 50 04             	mov    %edx,0x4(%eax)
    elm->prev = prev;
c01054b4:	8b 45 d0             	mov    -0x30(%ebp),%eax
c01054b7:	8b 55 cc             	mov    -0x34(%ebp),%edx
c01054ba:	89 10                	mov    %edx,(%eax)

    mm->map_count ++;                                       //小组成员数目++
c01054bc:	8b 45 08             	mov    0x8(%ebp),%eax
c01054bf:	8b 40 10             	mov    0x10(%eax),%eax
c01054c2:	8d 50 01             	lea    0x1(%eax),%edx
c01054c5:	8b 45 08             	mov    0x8(%ebp),%eax
c01054c8:	89 50 10             	mov    %edx,0x10(%eax)
}
c01054cb:	90                   	nop
c01054cc:	c9                   	leave  
c01054cd:	c3                   	ret    

c01054ce <mm_destroy>:

// mm_destroy - free mm and mm internal fields
void
mm_destroy(struct mm_struct *mm) {
c01054ce:	55                   	push   %ebp
c01054cf:	89 e5                	mov    %esp,%ebp
c01054d1:	83 ec 38             	sub    $0x38,%esp

    list_entry_t *list = &(mm->mmap_list), *le;
c01054d4:	8b 45 08             	mov    0x8(%ebp),%eax
c01054d7:	89 45 f4             	mov    %eax,-0xc(%ebp)
    while ((le = list_next(list)) != list) {
c01054da:	eb 36                	jmp    c0105512 <mm_destroy+0x44>
c01054dc:	8b 45 f0             	mov    -0x10(%ebp),%eax
c01054df:	89 45 ec             	mov    %eax,-0x14(%ebp)
    __list_del(listelm->prev, listelm->next);
c01054e2:	8b 45 ec             	mov    -0x14(%ebp),%eax
c01054e5:	8b 40 04             	mov    0x4(%eax),%eax
c01054e8:	8b 55 ec             	mov    -0x14(%ebp),%edx
c01054eb:	8b 12                	mov    (%edx),%edx
c01054ed:	89 55 e8             	mov    %edx,-0x18(%ebp)
c01054f0:	89 45 e4             	mov    %eax,-0x1c(%ebp)
    prev->next = next;
c01054f3:	8b 45 e8             	mov    -0x18(%ebp),%eax
c01054f6:	8b 55 e4             	mov    -0x1c(%ebp),%edx
c01054f9:	89 50 04             	mov    %edx,0x4(%eax)
    next->prev = prev;
c01054fc:	8b 45 e4             	mov    -0x1c(%ebp),%eax
c01054ff:	8b 55 e8             	mov    -0x18(%ebp),%edx
c0105502:	89 10                	mov    %edx,(%eax)
        list_del(le);
        kfree(le2vma(le, list_link));  //kfree vma        
c0105504:	8b 45 f0             	mov    -0x10(%ebp),%eax
c0105507:	83 e8 10             	sub    $0x10,%eax
c010550a:	89 04 24             	mov    %eax,(%esp)
c010550d:	e8 6a 0f 00 00       	call   c010647c <kfree>
c0105512:	8b 45 f4             	mov    -0xc(%ebp),%eax
c0105515:	89 45 e0             	mov    %eax,-0x20(%ebp)
    return listelm->next;
c0105518:	8b 45 e0             	mov    -0x20(%ebp),%eax
c010551b:	8b 40 04             	mov    0x4(%eax),%eax
    while ((le = list_next(list)) != list) {
c010551e:	89 45 f0             	mov    %eax,-0x10(%ebp)
c0105521:	8b 45 f0             	mov    -0x10(%ebp),%eax
c0105524:	3b 45 f4             	cmp    -0xc(%ebp),%eax
c0105527:	75 b3                	jne    c01054dc <mm_destroy+0xe>
    }
    kfree(mm); //kfree mm
c0105529:	8b 45 08             	mov    0x8(%ebp),%eax
c010552c:	89 04 24             	mov    %eax,(%esp)
c010552f:	e8 48 0f 00 00       	call   c010647c <kfree>
    mm=NULL;
c0105534:	c7 45 08 00 00 00 00 	movl   $0x0,0x8(%ebp)
}
c010553b:	90                   	nop
c010553c:	c9                   	leave  
c010553d:	c3                   	ret    

c010553e <vmm_init>:

// vmm_init - initialize virtual memory management
//          - now just call check_vmm to check correctness of vmm
void
vmm_init(void) {
c010553e:	55                   	push   %ebp
c010553f:	89 e5                	mov    %esp,%ebp
c0105541:	83 ec 08             	sub    $0x8,%esp
    check_vmm();
c0105544:	e8 03 00 00 00       	call   c010554c <check_vmm>
}
c0105549:	90                   	nop
c010554a:	c9                   	leave  
c010554b:	c3                   	ret    

c010554c <check_vmm>:

// check_vmm - check correctness of vmm
static void
check_vmm(void) {
c010554c:	55                   	push   %ebp
c010554d:	89 e5                	mov    %esp,%ebp
c010554f:	83 ec 28             	sub    $0x28,%esp
    size_t nr_free_pages_store = nr_free_pages();   //空闲页个数
c0105552:	e8 96 df ff ff       	call   c01034ed <nr_free_pages>
c0105557:	89 45 f4             	mov    %eax,-0xc(%ebp)
    
    check_vma_struct();
c010555a:	e8 14 00 00 00       	call   c0105573 <check_vma_struct>
    check_pgfault();
c010555f:	e8 a1 04 00 00       	call   c0105a05 <check_pgfault>

    cprintf("check_vmm() succeeded.\n");
c0105564:	c7 04 24 61 af 10 c0 	movl   $0xc010af61,(%esp)
c010556b:	e8 39 ad ff ff       	call   c01002a9 <cprintf>
}
c0105570:	90                   	nop
c0105571:	c9                   	leave  
c0105572:	c3                   	ret    

c0105573 <check_vma_struct>:

static void
check_vma_struct(void) {
c0105573:	55                   	push   %ebp
c0105574:	89 e5                	mov    %esp,%ebp
c0105576:	83 ec 68             	sub    $0x68,%esp
    size_t nr_free_pages_store = nr_free_pages();
c0105579:	e8 6f df ff ff       	call   c01034ed <nr_free_pages>
c010557e:	89 45 ec             	mov    %eax,-0x14(%ebp)

    struct mm_struct *mm = mm_create();
c0105581:	e8 0d fc ff ff       	call   c0105193 <mm_create>
c0105586:	89 45 e8             	mov    %eax,-0x18(%ebp)
    assert(mm != NULL);
c0105589:	83 7d e8 00          	cmpl   $0x0,-0x18(%ebp)
c010558d:	75 24                	jne    c01055b3 <check_vma_struct+0x40>
c010558f:	c7 44 24 0c 79 af 10 	movl   $0xc010af79,0xc(%esp)
c0105596:	c0 
c0105597:	c7 44 24 08 e3 ae 10 	movl   $0xc010aee3,0x8(%esp)
c010559e:	c0 
c010559f:	c7 44 24 04 b2 00 00 	movl   $0xb2,0x4(%esp)
c01055a6:	00 
c01055a7:	c7 04 24 f8 ae 10 c0 	movl   $0xc010aef8,(%esp)
c01055ae:	e8 4d ae ff ff       	call   c0100400 <__panic>

    int step1 = 10, step2 = step1 * 10;
c01055b3:	c7 45 e4 0a 00 00 00 	movl   $0xa,-0x1c(%ebp)
c01055ba:	8b 55 e4             	mov    -0x1c(%ebp),%edx
c01055bd:	89 d0                	mov    %edx,%eax
c01055bf:	c1 e0 02             	shl    $0x2,%eax
c01055c2:	01 d0                	add    %edx,%eax
c01055c4:	01 c0                	add    %eax,%eax
c01055c6:	89 45 e0             	mov    %eax,-0x20(%ebp)

    int i;
    for (i = step1; i >= 1; i --) {      //10次 5052 4547 4042...57
c01055c9:	8b 45 e4             	mov    -0x1c(%ebp),%eax
c01055cc:	89 45 f4             	mov    %eax,-0xc(%ebp)
c01055cf:	eb 6f                	jmp    c0105640 <check_vma_struct+0xcd>
        struct vma_struct *vma = vma_create(i * 5, i * 5 + 2, 0);
c01055d1:	8b 55 f4             	mov    -0xc(%ebp),%edx
c01055d4:	89 d0                	mov    %edx,%eax
c01055d6:	c1 e0 02             	shl    $0x2,%eax
c01055d9:	01 d0                	add    %edx,%eax
c01055db:	83 c0 02             	add    $0x2,%eax
c01055de:	89 c1                	mov    %eax,%ecx
c01055e0:	8b 55 f4             	mov    -0xc(%ebp),%edx
c01055e3:	89 d0                	mov    %edx,%eax
c01055e5:	c1 e0 02             	shl    $0x2,%eax
c01055e8:	01 d0                	add    %edx,%eax
c01055ea:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
c01055f1:	00 
c01055f2:	89 4c 24 04          	mov    %ecx,0x4(%esp)
c01055f6:	89 04 24             	mov    %eax,(%esp)
c01055f9:	e8 0d fc ff ff       	call   c010520b <vma_create>
c01055fe:	89 45 bc             	mov    %eax,-0x44(%ebp)
        assert(vma != NULL);
c0105601:	83 7d bc 00          	cmpl   $0x0,-0x44(%ebp)
c0105605:	75 24                	jne    c010562b <check_vma_struct+0xb8>
c0105607:	c7 44 24 0c 84 af 10 	movl   $0xc010af84,0xc(%esp)
c010560e:	c0 
c010560f:	c7 44 24 08 e3 ae 10 	movl   $0xc010aee3,0x8(%esp)
c0105616:	c0 
c0105617:	c7 44 24 04 b9 00 00 	movl   $0xb9,0x4(%esp)
c010561e:	00 
c010561f:	c7 04 24 f8 ae 10 c0 	movl   $0xc010aef8,(%esp)
c0105626:	e8 d5 ad ff ff       	call   c0100400 <__panic>
        insert_vma_struct(mm, vma);
c010562b:	8b 45 bc             	mov    -0x44(%ebp),%eax
c010562e:	89 44 24 04          	mov    %eax,0x4(%esp)
c0105632:	8b 45 e8             	mov    -0x18(%ebp),%eax
c0105635:	89 04 24             	mov    %eax,(%esp)
c0105638:	e8 5f fd ff ff       	call   c010539c <insert_vma_struct>
    for (i = step1; i >= 1; i --) {      //10次 5052 4547 4042...57
c010563d:	ff 4d f4             	decl   -0xc(%ebp)
c0105640:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
c0105644:	7f 8b                	jg     c01055d1 <check_vma_struct+0x5e>
    }

    for (i = step1 + 1; i <= step2; i ++) { //90次  5557 6062 ... 500502
c0105646:	8b 45 e4             	mov    -0x1c(%ebp),%eax
c0105649:	40                   	inc    %eax
c010564a:	89 45 f4             	mov    %eax,-0xc(%ebp)
c010564d:	eb 6f                	jmp    c01056be <check_vma_struct+0x14b>
        struct vma_struct *vma = vma_create(i * 5, i * 5 + 2, 0);
c010564f:	8b 55 f4             	mov    -0xc(%ebp),%edx
c0105652:	89 d0                	mov    %edx,%eax
c0105654:	c1 e0 02             	shl    $0x2,%eax
c0105657:	01 d0                	add    %edx,%eax
c0105659:	83 c0 02             	add    $0x2,%eax
c010565c:	89 c1                	mov    %eax,%ecx
c010565e:	8b 55 f4             	mov    -0xc(%ebp),%edx
c0105661:	89 d0                	mov    %edx,%eax
c0105663:	c1 e0 02             	shl    $0x2,%eax
c0105666:	01 d0                	add    %edx,%eax
c0105668:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
c010566f:	00 
c0105670:	89 4c 24 04          	mov    %ecx,0x4(%esp)
c0105674:	89 04 24             	mov    %eax,(%esp)
c0105677:	e8 8f fb ff ff       	call   c010520b <vma_create>
c010567c:	89 45 c0             	mov    %eax,-0x40(%ebp)
        assert(vma != NULL);
c010567f:	83 7d c0 00          	cmpl   $0x0,-0x40(%ebp)
c0105683:	75 24                	jne    c01056a9 <check_vma_struct+0x136>
c0105685:	c7 44 24 0c 84 af 10 	movl   $0xc010af84,0xc(%esp)
c010568c:	c0 
c010568d:	c7 44 24 08 e3 ae 10 	movl   $0xc010aee3,0x8(%esp)
c0105694:	c0 
c0105695:	c7 44 24 04 bf 00 00 	movl   $0xbf,0x4(%esp)
c010569c:	00 
c010569d:	c7 04 24 f8 ae 10 c0 	movl   $0xc010aef8,(%esp)
c01056a4:	e8 57 ad ff ff       	call   c0100400 <__panic>
        insert_vma_struct(mm, vma);
c01056a9:	8b 45 c0             	mov    -0x40(%ebp),%eax
c01056ac:	89 44 24 04          	mov    %eax,0x4(%esp)
c01056b0:	8b 45 e8             	mov    -0x18(%ebp),%eax
c01056b3:	89 04 24             	mov    %eax,(%esp)
c01056b6:	e8 e1 fc ff ff       	call   c010539c <insert_vma_struct>
    for (i = step1 + 1; i <= step2; i ++) { //90次  5557 6062 ... 500502
c01056bb:	ff 45 f4             	incl   -0xc(%ebp)
c01056be:	8b 45 f4             	mov    -0xc(%ebp),%eax
c01056c1:	3b 45 e0             	cmp    -0x20(%ebp),%eax
c01056c4:	7e 89                	jle    c010564f <check_vma_struct+0xdc>
    }

    list_entry_t *le = list_next(&(mm->mmap_list));
c01056c6:	8b 45 e8             	mov    -0x18(%ebp),%eax
c01056c9:	89 45 b8             	mov    %eax,-0x48(%ebp)
c01056cc:	8b 45 b8             	mov    -0x48(%ebp),%eax
c01056cf:	8b 40 04             	mov    0x4(%eax),%eax
c01056d2:	89 45 f0             	mov    %eax,-0x10(%ebp)

    for (i = 1; i <= step2; i ++) {
c01056d5:	c7 45 f4 01 00 00 00 	movl   $0x1,-0xc(%ebp)
c01056dc:	e9 96 00 00 00       	jmp    c0105777 <check_vma_struct+0x204>
        assert(le != &(mm->mmap_list));
c01056e1:	8b 45 e8             	mov    -0x18(%ebp),%eax
c01056e4:	39 45 f0             	cmp    %eax,-0x10(%ebp)
c01056e7:	75 24                	jne    c010570d <check_vma_struct+0x19a>
c01056e9:	c7 44 24 0c 90 af 10 	movl   $0xc010af90,0xc(%esp)
c01056f0:	c0 
c01056f1:	c7 44 24 08 e3 ae 10 	movl   $0xc010aee3,0x8(%esp)
c01056f8:	c0 
c01056f9:	c7 44 24 04 c6 00 00 	movl   $0xc6,0x4(%esp)
c0105700:	00 
c0105701:	c7 04 24 f8 ae 10 c0 	movl   $0xc010aef8,(%esp)
c0105708:	e8 f3 ac ff ff       	call   c0100400 <__panic>
        struct vma_struct *mmap = le2vma(le, list_link);
c010570d:	8b 45 f0             	mov    -0x10(%ebp),%eax
c0105710:	83 e8 10             	sub    $0x10,%eax
c0105713:	89 45 c4             	mov    %eax,-0x3c(%ebp)
        assert(mmap->vm_start == i * 5 && mmap->vm_end == i * 5 + 2);   //检查每个vma的起终是否是设定值
c0105716:	8b 45 c4             	mov    -0x3c(%ebp),%eax
c0105719:	8b 48 04             	mov    0x4(%eax),%ecx
c010571c:	8b 55 f4             	mov    -0xc(%ebp),%edx
c010571f:	89 d0                	mov    %edx,%eax
c0105721:	c1 e0 02             	shl    $0x2,%eax
c0105724:	01 d0                	add    %edx,%eax
c0105726:	39 c1                	cmp    %eax,%ecx
c0105728:	75 17                	jne    c0105741 <check_vma_struct+0x1ce>
c010572a:	8b 45 c4             	mov    -0x3c(%ebp),%eax
c010572d:	8b 48 08             	mov    0x8(%eax),%ecx
c0105730:	8b 55 f4             	mov    -0xc(%ebp),%edx
c0105733:	89 d0                	mov    %edx,%eax
c0105735:	c1 e0 02             	shl    $0x2,%eax
c0105738:	01 d0                	add    %edx,%eax
c010573a:	83 c0 02             	add    $0x2,%eax
c010573d:	39 c1                	cmp    %eax,%ecx
c010573f:	74 24                	je     c0105765 <check_vma_struct+0x1f2>
c0105741:	c7 44 24 0c a8 af 10 	movl   $0xc010afa8,0xc(%esp)
c0105748:	c0 
c0105749:	c7 44 24 08 e3 ae 10 	movl   $0xc010aee3,0x8(%esp)
c0105750:	c0 
c0105751:	c7 44 24 04 c8 00 00 	movl   $0xc8,0x4(%esp)
c0105758:	00 
c0105759:	c7 04 24 f8 ae 10 c0 	movl   $0xc010aef8,(%esp)
c0105760:	e8 9b ac ff ff       	call   c0100400 <__panic>
c0105765:	8b 45 f0             	mov    -0x10(%ebp),%eax
c0105768:	89 45 b4             	mov    %eax,-0x4c(%ebp)
c010576b:	8b 45 b4             	mov    -0x4c(%ebp),%eax
c010576e:	8b 40 04             	mov    0x4(%eax),%eax
        le = list_next(le);
c0105771:	89 45 f0             	mov    %eax,-0x10(%ebp)
    for (i = 1; i <= step2; i ++) {
c0105774:	ff 45 f4             	incl   -0xc(%ebp)
c0105777:	8b 45 f4             	mov    -0xc(%ebp),%eax
c010577a:	3b 45 e0             	cmp    -0x20(%ebp),%eax
c010577d:	0f 8e 5e ff ff ff    	jle    c01056e1 <check_vma_struct+0x16e>
    }

    for (i = 5; i <= 5 * step2; i +=5) {
c0105783:	c7 45 f4 05 00 00 00 	movl   $0x5,-0xc(%ebp)
c010578a:	e9 cb 01 00 00       	jmp    c010595a <check_vma_struct+0x3e7>
        struct vma_struct *vma1 = find_vma(mm, i);
c010578f:	8b 45 f4             	mov    -0xc(%ebp),%eax
c0105792:	89 44 24 04          	mov    %eax,0x4(%esp)
c0105796:	8b 45 e8             	mov    -0x18(%ebp),%eax
c0105799:	89 04 24             	mov    %eax,(%esp)
c010579c:	e8 a5 fa ff ff       	call   c0105246 <find_vma>
c01057a1:	89 45 d8             	mov    %eax,-0x28(%ebp)
        assert(vma1 != NULL);
c01057a4:	83 7d d8 00          	cmpl   $0x0,-0x28(%ebp)
c01057a8:	75 24                	jne    c01057ce <check_vma_struct+0x25b>
c01057aa:	c7 44 24 0c dd af 10 	movl   $0xc010afdd,0xc(%esp)
c01057b1:	c0 
c01057b2:	c7 44 24 08 e3 ae 10 	movl   $0xc010aee3,0x8(%esp)
c01057b9:	c0 
c01057ba:	c7 44 24 04 ce 00 00 	movl   $0xce,0x4(%esp)
c01057c1:	00 
c01057c2:	c7 04 24 f8 ae 10 c0 	movl   $0xc010aef8,(%esp)
c01057c9:	e8 32 ac ff ff       	call   c0100400 <__panic>
        struct vma_struct *vma2 = find_vma(mm, i+1);
c01057ce:	8b 45 f4             	mov    -0xc(%ebp),%eax
c01057d1:	40                   	inc    %eax
c01057d2:	89 44 24 04          	mov    %eax,0x4(%esp)
c01057d6:	8b 45 e8             	mov    -0x18(%ebp),%eax
c01057d9:	89 04 24             	mov    %eax,(%esp)
c01057dc:	e8 65 fa ff ff       	call   c0105246 <find_vma>
c01057e1:	89 45 d4             	mov    %eax,-0x2c(%ebp)
        assert(vma2 != NULL);
c01057e4:	83 7d d4 00          	cmpl   $0x0,-0x2c(%ebp)
c01057e8:	75 24                	jne    c010580e <check_vma_struct+0x29b>
c01057ea:	c7 44 24 0c ea af 10 	movl   $0xc010afea,0xc(%esp)
c01057f1:	c0 
c01057f2:	c7 44 24 08 e3 ae 10 	movl   $0xc010aee3,0x8(%esp)
c01057f9:	c0 
c01057fa:	c7 44 24 04 d0 00 00 	movl   $0xd0,0x4(%esp)
c0105801:	00 
c0105802:	c7 04 24 f8 ae 10 c0 	movl   $0xc010aef8,(%esp)
c0105809:	e8 f2 ab ff ff       	call   c0100400 <__panic>
        struct vma_struct *vma3 = find_vma(mm, i+2);
c010580e:	8b 45 f4             	mov    -0xc(%ebp),%eax
c0105811:	83 c0 02             	add    $0x2,%eax
c0105814:	89 44 24 04          	mov    %eax,0x4(%esp)
c0105818:	8b 45 e8             	mov    -0x18(%ebp),%eax
c010581b:	89 04 24             	mov    %eax,(%esp)
c010581e:	e8 23 fa ff ff       	call   c0105246 <find_vma>
c0105823:	89 45 d0             	mov    %eax,-0x30(%ebp)
        assert(vma3 == NULL);
c0105826:	83 7d d0 00          	cmpl   $0x0,-0x30(%ebp)
c010582a:	74 24                	je     c0105850 <check_vma_struct+0x2dd>
c010582c:	c7 44 24 0c f7 af 10 	movl   $0xc010aff7,0xc(%esp)
c0105833:	c0 
c0105834:	c7 44 24 08 e3 ae 10 	movl   $0xc010aee3,0x8(%esp)
c010583b:	c0 
c010583c:	c7 44 24 04 d2 00 00 	movl   $0xd2,0x4(%esp)
c0105843:	00 
c0105844:	c7 04 24 f8 ae 10 c0 	movl   $0xc010aef8,(%esp)
c010584b:	e8 b0 ab ff ff       	call   c0100400 <__panic>
        struct vma_struct *vma4 = find_vma(mm, i+3);
c0105850:	8b 45 f4             	mov    -0xc(%ebp),%eax
c0105853:	83 c0 03             	add    $0x3,%eax
c0105856:	89 44 24 04          	mov    %eax,0x4(%esp)
c010585a:	8b 45 e8             	mov    -0x18(%ebp),%eax
c010585d:	89 04 24             	mov    %eax,(%esp)
c0105860:	e8 e1 f9 ff ff       	call   c0105246 <find_vma>
c0105865:	89 45 cc             	mov    %eax,-0x34(%ebp)
        assert(vma4 == NULL);
c0105868:	83 7d cc 00          	cmpl   $0x0,-0x34(%ebp)
c010586c:	74 24                	je     c0105892 <check_vma_struct+0x31f>
c010586e:	c7 44 24 0c 04 b0 10 	movl   $0xc010b004,0xc(%esp)
c0105875:	c0 
c0105876:	c7 44 24 08 e3 ae 10 	movl   $0xc010aee3,0x8(%esp)
c010587d:	c0 
c010587e:	c7 44 24 04 d4 00 00 	movl   $0xd4,0x4(%esp)
c0105885:	00 
c0105886:	c7 04 24 f8 ae 10 c0 	movl   $0xc010aef8,(%esp)
c010588d:	e8 6e ab ff ff       	call   c0100400 <__panic>
        struct vma_struct *vma5 = find_vma(mm, i+4);
c0105892:	8b 45 f4             	mov    -0xc(%ebp),%eax
c0105895:	83 c0 04             	add    $0x4,%eax
c0105898:	89 44 24 04          	mov    %eax,0x4(%esp)
c010589c:	8b 45 e8             	mov    -0x18(%ebp),%eax
c010589f:	89 04 24             	mov    %eax,(%esp)
c01058a2:	e8 9f f9 ff ff       	call   c0105246 <find_vma>
c01058a7:	89 45 c8             	mov    %eax,-0x38(%ebp)
        assert(vma5 == NULL);
c01058aa:	83 7d c8 00          	cmpl   $0x0,-0x38(%ebp)
c01058ae:	74 24                	je     c01058d4 <check_vma_struct+0x361>
c01058b0:	c7 44 24 0c 11 b0 10 	movl   $0xc010b011,0xc(%esp)
c01058b7:	c0 
c01058b8:	c7 44 24 08 e3 ae 10 	movl   $0xc010aee3,0x8(%esp)
c01058bf:	c0 
c01058c0:	c7 44 24 04 d6 00 00 	movl   $0xd6,0x4(%esp)
c01058c7:	00 
c01058c8:	c7 04 24 f8 ae 10 c0 	movl   $0xc010aef8,(%esp)
c01058cf:	e8 2c ab ff ff       	call   c0100400 <__panic>

        assert(vma1->vm_start == i  && vma1->vm_end == i  + 2);
c01058d4:	8b 45 d8             	mov    -0x28(%ebp),%eax
c01058d7:	8b 50 04             	mov    0x4(%eax),%edx
c01058da:	8b 45 f4             	mov    -0xc(%ebp),%eax
c01058dd:	39 c2                	cmp    %eax,%edx
c01058df:	75 10                	jne    c01058f1 <check_vma_struct+0x37e>
c01058e1:	8b 45 d8             	mov    -0x28(%ebp),%eax
c01058e4:	8b 40 08             	mov    0x8(%eax),%eax
c01058e7:	8b 55 f4             	mov    -0xc(%ebp),%edx
c01058ea:	83 c2 02             	add    $0x2,%edx
c01058ed:	39 d0                	cmp    %edx,%eax
c01058ef:	74 24                	je     c0105915 <check_vma_struct+0x3a2>
c01058f1:	c7 44 24 0c 20 b0 10 	movl   $0xc010b020,0xc(%esp)
c01058f8:	c0 
c01058f9:	c7 44 24 08 e3 ae 10 	movl   $0xc010aee3,0x8(%esp)
c0105900:	c0 
c0105901:	c7 44 24 04 d8 00 00 	movl   $0xd8,0x4(%esp)
c0105908:	00 
c0105909:	c7 04 24 f8 ae 10 c0 	movl   $0xc010aef8,(%esp)
c0105910:	e8 eb aa ff ff       	call   c0100400 <__panic>
        assert(vma2->vm_start == i  && vma2->vm_end == i  + 2);
c0105915:	8b 45 d4             	mov    -0x2c(%ebp),%eax
c0105918:	8b 50 04             	mov    0x4(%eax),%edx
c010591b:	8b 45 f4             	mov    -0xc(%ebp),%eax
c010591e:	39 c2                	cmp    %eax,%edx
c0105920:	75 10                	jne    c0105932 <check_vma_struct+0x3bf>
c0105922:	8b 45 d4             	mov    -0x2c(%ebp),%eax
c0105925:	8b 40 08             	mov    0x8(%eax),%eax
c0105928:	8b 55 f4             	mov    -0xc(%ebp),%edx
c010592b:	83 c2 02             	add    $0x2,%edx
c010592e:	39 d0                	cmp    %edx,%eax
c0105930:	74 24                	je     c0105956 <check_vma_struct+0x3e3>
c0105932:	c7 44 24 0c 50 b0 10 	movl   $0xc010b050,0xc(%esp)
c0105939:	c0 
c010593a:	c7 44 24 08 e3 ae 10 	movl   $0xc010aee3,0x8(%esp)
c0105941:	c0 
c0105942:	c7 44 24 04 d9 00 00 	movl   $0xd9,0x4(%esp)
c0105949:	00 
c010594a:	c7 04 24 f8 ae 10 c0 	movl   $0xc010aef8,(%esp)
c0105951:	e8 aa aa ff ff       	call   c0100400 <__panic>
    for (i = 5; i <= 5 * step2; i +=5) {
c0105956:	83 45 f4 05          	addl   $0x5,-0xc(%ebp)
c010595a:	8b 55 e0             	mov    -0x20(%ebp),%edx
c010595d:	89 d0                	mov    %edx,%eax
c010595f:	c1 e0 02             	shl    $0x2,%eax
c0105962:	01 d0                	add    %edx,%eax
c0105964:	39 45 f4             	cmp    %eax,-0xc(%ebp)
c0105967:	0f 8e 22 fe ff ff    	jle    c010578f <check_vma_struct+0x21c>
    }

    for (i =4; i>=0; i--) {
c010596d:	c7 45 f4 04 00 00 00 	movl   $0x4,-0xc(%ebp)
c0105974:	eb 6f                	jmp    c01059e5 <check_vma_struct+0x472>
        struct vma_struct *vma_below_5= find_vma(mm,i);
c0105976:	8b 45 f4             	mov    -0xc(%ebp),%eax
c0105979:	89 44 24 04          	mov    %eax,0x4(%esp)
c010597d:	8b 45 e8             	mov    -0x18(%ebp),%eax
c0105980:	89 04 24             	mov    %eax,(%esp)
c0105983:	e8 be f8 ff ff       	call   c0105246 <find_vma>
c0105988:	89 45 dc             	mov    %eax,-0x24(%ebp)
        if (vma_below_5 != NULL ) {
c010598b:	83 7d dc 00          	cmpl   $0x0,-0x24(%ebp)
c010598f:	74 27                	je     c01059b8 <check_vma_struct+0x445>
           cprintf("vma_below_5: i %x, start %x, end %x\n",i, vma_below_5->vm_start, vma_below_5->vm_end); 
c0105991:	8b 45 dc             	mov    -0x24(%ebp),%eax
c0105994:	8b 50 08             	mov    0x8(%eax),%edx
c0105997:	8b 45 dc             	mov    -0x24(%ebp),%eax
c010599a:	8b 40 04             	mov    0x4(%eax),%eax
c010599d:	89 54 24 0c          	mov    %edx,0xc(%esp)
c01059a1:	89 44 24 08          	mov    %eax,0x8(%esp)
c01059a5:	8b 45 f4             	mov    -0xc(%ebp),%eax
c01059a8:	89 44 24 04          	mov    %eax,0x4(%esp)
c01059ac:	c7 04 24 80 b0 10 c0 	movl   $0xc010b080,(%esp)
c01059b3:	e8 f1 a8 ff ff       	call   c01002a9 <cprintf>
        }
        assert(vma_below_5 == NULL);
c01059b8:	83 7d dc 00          	cmpl   $0x0,-0x24(%ebp)
c01059bc:	74 24                	je     c01059e2 <check_vma_struct+0x46f>
c01059be:	c7 44 24 0c a5 b0 10 	movl   $0xc010b0a5,0xc(%esp)
c01059c5:	c0 
c01059c6:	c7 44 24 08 e3 ae 10 	movl   $0xc010aee3,0x8(%esp)
c01059cd:	c0 
c01059ce:	c7 44 24 04 e1 00 00 	movl   $0xe1,0x4(%esp)
c01059d5:	00 
c01059d6:	c7 04 24 f8 ae 10 c0 	movl   $0xc010aef8,(%esp)
c01059dd:	e8 1e aa ff ff       	call   c0100400 <__panic>
    for (i =4; i>=0; i--) {
c01059e2:	ff 4d f4             	decl   -0xc(%ebp)
c01059e5:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
c01059e9:	79 8b                	jns    c0105976 <check_vma_struct+0x403>
    }

    mm_destroy(mm);
c01059eb:	8b 45 e8             	mov    -0x18(%ebp),%eax
c01059ee:	89 04 24             	mov    %eax,(%esp)
c01059f1:	e8 d8 fa ff ff       	call   c01054ce <mm_destroy>

    cprintf("check_vma_struct() succeeded!\n");
c01059f6:	c7 04 24 bc b0 10 c0 	movl   $0xc010b0bc,(%esp)
c01059fd:	e8 a7 a8 ff ff       	call   c01002a9 <cprintf>
}
c0105a02:	90                   	nop
c0105a03:	c9                   	leave  
c0105a04:	c3                   	ret    

c0105a05 <check_pgfault>:

struct mm_struct *check_mm_struct;

// check_pgfault - check correctness of pgfault handler
static void
check_pgfault(void) {
c0105a05:	55                   	push   %ebp
c0105a06:	89 e5                	mov    %esp,%ebp
c0105a08:	83 ec 38             	sub    $0x38,%esp
    size_t nr_free_pages_store = nr_free_pages();
c0105a0b:	e8 dd da ff ff       	call   c01034ed <nr_free_pages>
c0105a10:	89 45 ec             	mov    %eax,-0x14(%ebp)

    check_mm_struct = mm_create();
c0105a13:	e8 7b f7 ff ff       	call   c0105193 <mm_create>
c0105a18:	a3 6c b0 12 c0       	mov    %eax,0xc012b06c
    assert(check_mm_struct != NULL);
c0105a1d:	a1 6c b0 12 c0       	mov    0xc012b06c,%eax
c0105a22:	85 c0                	test   %eax,%eax
c0105a24:	75 24                	jne    c0105a4a <check_pgfault+0x45>
c0105a26:	c7 44 24 0c db b0 10 	movl   $0xc010b0db,0xc(%esp)
c0105a2d:	c0 
c0105a2e:	c7 44 24 08 e3 ae 10 	movl   $0xc010aee3,0x8(%esp)
c0105a35:	c0 
c0105a36:	c7 44 24 04 f1 00 00 	movl   $0xf1,0x4(%esp)
c0105a3d:	00 
c0105a3e:	c7 04 24 f8 ae 10 c0 	movl   $0xc010aef8,(%esp)
c0105a45:	e8 b6 a9 ff ff       	call   c0100400 <__panic>

    struct mm_struct *mm = check_mm_struct;
c0105a4a:	a1 6c b0 12 c0       	mov    0xc012b06c,%eax
c0105a4f:	89 45 e8             	mov    %eax,-0x18(%ebp)
    pde_t *pgdir = mm->pgdir = boot_pgdir;      //PDT设为boot那个
c0105a52:	8b 15 e0 59 12 c0    	mov    0xc01259e0,%edx
c0105a58:	8b 45 e8             	mov    -0x18(%ebp),%eax
c0105a5b:	89 50 0c             	mov    %edx,0xc(%eax)
c0105a5e:	8b 45 e8             	mov    -0x18(%ebp),%eax
c0105a61:	8b 40 0c             	mov    0xc(%eax),%eax
c0105a64:	89 45 e4             	mov    %eax,-0x1c(%ebp)
    assert(pgdir[0] == 0);                      //刚开始boot那个还是0
c0105a67:	8b 45 e4             	mov    -0x1c(%ebp),%eax
c0105a6a:	8b 00                	mov    (%eax),%eax
c0105a6c:	85 c0                	test   %eax,%eax
c0105a6e:	74 24                	je     c0105a94 <check_pgfault+0x8f>
c0105a70:	c7 44 24 0c f3 b0 10 	movl   $0xc010b0f3,0xc(%esp)
c0105a77:	c0 
c0105a78:	c7 44 24 08 e3 ae 10 	movl   $0xc010aee3,0x8(%esp)
c0105a7f:	c0 
c0105a80:	c7 44 24 04 f5 00 00 	movl   $0xf5,0x4(%esp)
c0105a87:	00 
c0105a88:	c7 04 24 f8 ae 10 c0 	movl   $0xc010aef8,(%esp)
c0105a8f:	e8 6c a9 ff ff       	call   c0100400 <__panic>

    struct vma_struct *vma = vma_create(0, PTSIZE, VM_WRITE);
c0105a94:	c7 44 24 08 02 00 00 	movl   $0x2,0x8(%esp)
c0105a9b:	00 
c0105a9c:	c7 44 24 04 00 00 40 	movl   $0x400000,0x4(%esp)
c0105aa3:	00 
c0105aa4:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
c0105aab:	e8 5b f7 ff ff       	call   c010520b <vma_create>
c0105ab0:	89 45 e0             	mov    %eax,-0x20(%ebp)
    assert(vma != NULL);
c0105ab3:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
c0105ab7:	75 24                	jne    c0105add <check_pgfault+0xd8>
c0105ab9:	c7 44 24 0c 84 af 10 	movl   $0xc010af84,0xc(%esp)
c0105ac0:	c0 
c0105ac1:	c7 44 24 08 e3 ae 10 	movl   $0xc010aee3,0x8(%esp)
c0105ac8:	c0 
c0105ac9:	c7 44 24 04 f8 00 00 	movl   $0xf8,0x4(%esp)
c0105ad0:	00 
c0105ad1:	c7 04 24 f8 ae 10 c0 	movl   $0xc010aef8,(%esp)
c0105ad8:	e8 23 a9 ff ff       	call   c0100400 <__panic>

    insert_vma_struct(mm, vma);
c0105add:	8b 45 e0             	mov    -0x20(%ebp),%eax
c0105ae0:	89 44 24 04          	mov    %eax,0x4(%esp)
c0105ae4:	8b 45 e8             	mov    -0x18(%ebp),%eax
c0105ae7:	89 04 24             	mov    %eax,(%esp)
c0105aea:	e8 ad f8 ff ff       	call   c010539c <insert_vma_struct>

    uintptr_t addr = 0x100;                 // the valid vaddr for check is between 0~CHECK_VALID_VADDR-1   CHECK_VALID_VADDR就是0x1000（swap.c）
c0105aef:	c7 45 dc 00 01 00 00 	movl   $0x100,-0x24(%ebp)
    assert(find_vma(mm, addr) == vma);     
c0105af6:	8b 45 dc             	mov    -0x24(%ebp),%eax
c0105af9:	89 44 24 04          	mov    %eax,0x4(%esp)
c0105afd:	8b 45 e8             	mov    -0x18(%ebp),%eax
c0105b00:	89 04 24             	mov    %eax,(%esp)
c0105b03:	e8 3e f7 ff ff       	call   c0105246 <find_vma>
c0105b08:	39 45 e0             	cmp    %eax,-0x20(%ebp)
c0105b0b:	74 24                	je     c0105b31 <check_pgfault+0x12c>
c0105b0d:	c7 44 24 0c 01 b1 10 	movl   $0xc010b101,0xc(%esp)
c0105b14:	c0 
c0105b15:	c7 44 24 08 e3 ae 10 	movl   $0xc010aee3,0x8(%esp)
c0105b1c:	c0 
c0105b1d:	c7 44 24 04 fd 00 00 	movl   $0xfd,0x4(%esp)
c0105b24:	00 
c0105b25:	c7 04 24 f8 ae 10 c0 	movl   $0xc010aef8,(%esp)
c0105b2c:	e8 cf a8 ff ff       	call   c0100400 <__panic>

    int i, sum = 0;
c0105b31:	c7 45 f0 00 00 00 00 	movl   $0x0,-0x10(%ebp)
    for (i = 0; i < 100; i ++) {
c0105b38:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
c0105b3f:	eb 16                	jmp    c0105b57 <check_pgfault+0x152>
        *(char *)(addr + i) = i;         //page fault at 0x00000100: K/W [no page found]. 产生中断，最后绕一大圈执行下面的do_pgfault
c0105b41:	8b 55 f4             	mov    -0xc(%ebp),%edx
c0105b44:	8b 45 dc             	mov    -0x24(%ebp),%eax
c0105b47:	01 d0                	add    %edx,%eax
c0105b49:	8b 55 f4             	mov    -0xc(%ebp),%edx
c0105b4c:	88 10                	mov    %dl,(%eax)
        sum += i;
c0105b4e:	8b 45 f4             	mov    -0xc(%ebp),%eax
c0105b51:	01 45 f0             	add    %eax,-0x10(%ebp)
    for (i = 0; i < 100; i ++) {
c0105b54:	ff 45 f4             	incl   -0xc(%ebp)
c0105b57:	83 7d f4 63          	cmpl   $0x63,-0xc(%ebp)
c0105b5b:	7e e4                	jle    c0105b41 <check_pgfault+0x13c>
    }
    for (i = 0; i < 100; i ++) {
c0105b5d:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
c0105b64:	eb 14                	jmp    c0105b7a <check_pgfault+0x175>
        sum -= *(char *)(addr + i);
c0105b66:	8b 55 f4             	mov    -0xc(%ebp),%edx
c0105b69:	8b 45 dc             	mov    -0x24(%ebp),%eax
c0105b6c:	01 d0                	add    %edx,%eax
c0105b6e:	0f b6 00             	movzbl (%eax),%eax
c0105b71:	0f be c0             	movsbl %al,%eax
c0105b74:	29 45 f0             	sub    %eax,-0x10(%ebp)
    for (i = 0; i < 100; i ++) {
c0105b77:	ff 45 f4             	incl   -0xc(%ebp)
c0105b7a:	83 7d f4 63          	cmpl   $0x63,-0xc(%ebp)
c0105b7e:	7e e6                	jle    c0105b66 <check_pgfault+0x161>
    }
    assert(sum == 0);
c0105b80:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
c0105b84:	74 24                	je     c0105baa <check_pgfault+0x1a5>
c0105b86:	c7 44 24 0c 1b b1 10 	movl   $0xc010b11b,0xc(%esp)
c0105b8d:	c0 
c0105b8e:	c7 44 24 08 e3 ae 10 	movl   $0xc010aee3,0x8(%esp)
c0105b95:	c0 
c0105b96:	c7 44 24 04 07 01 00 	movl   $0x107,0x4(%esp)
c0105b9d:	00 
c0105b9e:	c7 04 24 f8 ae 10 c0 	movl   $0xc010aef8,(%esp)
c0105ba5:	e8 56 a8 ff ff       	call   c0100400 <__panic>

    page_remove(pgdir, ROUNDDOWN(addr, PGSIZE));
c0105baa:	8b 45 dc             	mov    -0x24(%ebp),%eax
c0105bad:	89 45 d8             	mov    %eax,-0x28(%ebp)
c0105bb0:	8b 45 d8             	mov    -0x28(%ebp),%eax
c0105bb3:	25 00 f0 ff ff       	and    $0xfffff000,%eax
c0105bb8:	89 44 24 04          	mov    %eax,0x4(%esp)
c0105bbc:	8b 45 e4             	mov    -0x1c(%ebp),%eax
c0105bbf:	89 04 24             	mov    %eax,(%esp)
c0105bc2:	e8 5c e1 ff ff       	call   c0103d23 <page_remove>
    free_page(pde2page(pgdir[0]));      //释放一页
c0105bc7:	8b 45 e4             	mov    -0x1c(%ebp),%eax
c0105bca:	8b 00                	mov    (%eax),%eax
c0105bcc:	89 04 24             	mov    %eax,(%esp)
c0105bcf:	e8 a7 f5 ff ff       	call   c010517b <pde2page>
c0105bd4:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
c0105bdb:	00 
c0105bdc:	89 04 24             	mov    %eax,(%esp)
c0105bdf:	e8 d6 d8 ff ff       	call   c01034ba <free_pages>
    pgdir[0] = 0;
c0105be4:	8b 45 e4             	mov    -0x1c(%ebp),%eax
c0105be7:	c7 00 00 00 00 00    	movl   $0x0,(%eax)

    mm->pgdir = NULL;
c0105bed:	8b 45 e8             	mov    -0x18(%ebp),%eax
c0105bf0:	c7 40 0c 00 00 00 00 	movl   $0x0,0xc(%eax)
    mm_destroy(mm);
c0105bf7:	8b 45 e8             	mov    -0x18(%ebp),%eax
c0105bfa:	89 04 24             	mov    %eax,(%esp)
c0105bfd:	e8 cc f8 ff ff       	call   c01054ce <mm_destroy>
    check_mm_struct = NULL;
c0105c02:	c7 05 6c b0 12 c0 00 	movl   $0x0,0xc012b06c
c0105c09:	00 00 00 

    assert(nr_free_pages_store == nr_free_pages());     //释放后看看空闲页是是否和分配前一致
c0105c0c:	e8 dc d8 ff ff       	call   c01034ed <nr_free_pages>
c0105c11:	39 45 ec             	cmp    %eax,-0x14(%ebp)
c0105c14:	74 24                	je     c0105c3a <check_pgfault+0x235>
c0105c16:	c7 44 24 0c 24 b1 10 	movl   $0xc010b124,0xc(%esp)
c0105c1d:	c0 
c0105c1e:	c7 44 24 08 e3 ae 10 	movl   $0xc010aee3,0x8(%esp)
c0105c25:	c0 
c0105c26:	c7 44 24 04 11 01 00 	movl   $0x111,0x4(%esp)
c0105c2d:	00 
c0105c2e:	c7 04 24 f8 ae 10 c0 	movl   $0xc010aef8,(%esp)
c0105c35:	e8 c6 a7 ff ff       	call   c0100400 <__panic>

    cprintf("check_pgfault() succeeded!\n");
c0105c3a:	c7 04 24 4b b1 10 c0 	movl   $0xc010b14b,(%esp)
c0105c41:	e8 63 a6 ff ff       	call   c01002a9 <cprintf>
}
c0105c46:	90                   	nop
c0105c47:	c9                   	leave  
c0105c48:	c3                   	ret    

c0105c49 <do_pgfault>:
 *            was a read (0) or write (1).
 *         -- The U/S flag (bit 2) indicates whether the processor was executing at user mode (1)
 *            or supervisor mode (0) at the time of the exception.
 */
int
do_pgfault(struct mm_struct *mm, uint32_t error_code, uintptr_t addr) {//trap.c: do_pgfault(check_mm_struct, tf->tf_err, rcr2());
c0105c49:	55                   	push   %ebp
c0105c4a:	89 e5                	mov    %esp,%ebp
c0105c4c:	83 ec 38             	sub    $0x38,%esp
    int ret = -E_INVAL;
c0105c4f:	c7 45 f4 fd ff ff ff 	movl   $0xfffffffd,-0xc(%ebp)
    //try to find a vma which include addr
    struct vma_struct *vma = find_vma(mm, addr);
c0105c56:	8b 45 10             	mov    0x10(%ebp),%eax
c0105c59:	89 44 24 04          	mov    %eax,0x4(%esp)
c0105c5d:	8b 45 08             	mov    0x8(%ebp),%eax
c0105c60:	89 04 24             	mov    %eax,(%esp)
c0105c63:	e8 de f5 ff ff       	call   c0105246 <find_vma>
c0105c68:	89 45 ec             	mov    %eax,-0x14(%ebp)

    pgfault_num++;  //记录缺页异常的次数
c0105c6b:	a1 0c 90 12 c0       	mov    0xc012900c,%eax
c0105c70:	40                   	inc    %eax
c0105c71:	a3 0c 90 12 c0       	mov    %eax,0xc012900c
    //If the addr is in the range of a mm's vma?
    if (vma == NULL || vma->vm_start > addr) {  //找到的vma不能为空并且起始地址小于等于addr才行
c0105c76:	83 7d ec 00          	cmpl   $0x0,-0x14(%ebp)
c0105c7a:	74 0b                	je     c0105c87 <do_pgfault+0x3e>
c0105c7c:	8b 45 ec             	mov    -0x14(%ebp),%eax
c0105c7f:	8b 40 04             	mov    0x4(%eax),%eax
c0105c82:	39 45 10             	cmp    %eax,0x10(%ebp)
c0105c85:	73 18                	jae    c0105c9f <do_pgfault+0x56>
        cprintf("not valid addr %x, and  can not find it in vma\n", addr);
c0105c87:	8b 45 10             	mov    0x10(%ebp),%eax
c0105c8a:	89 44 24 04          	mov    %eax,0x4(%esp)
c0105c8e:	c7 04 24 68 b1 10 c0 	movl   $0xc010b168,(%esp)
c0105c95:	e8 0f a6 ff ff       	call   c01002a9 <cprintf>
        goto failed;
c0105c9a:	e9 ba 01 00 00       	jmp    c0105e59 <do_pgfault+0x210>
    }
    //check the error_code
    switch (error_code & 3) {       //只看低两位的errorcode
c0105c9f:	8b 45 0c             	mov    0xc(%ebp),%eax
c0105ca2:	83 e0 03             	and    $0x3,%eax
c0105ca5:	85 c0                	test   %eax,%eax
c0105ca7:	74 34                	je     c0105cdd <do_pgfault+0x94>
c0105ca9:	83 f8 01             	cmp    $0x1,%eax
c0105cac:	74 1e                	je     c0105ccc <do_pgfault+0x83>
    default:
            /* error code flag : default is 3 ( W/R=1, P=1): write, present */
    case 2: /* error code flag : (W/R=1, P=0): write, not present */
        if (!(vma->vm_flags & VM_WRITE)) {
c0105cae:	8b 45 ec             	mov    -0x14(%ebp),%eax
c0105cb1:	8b 40 0c             	mov    0xc(%eax),%eax
c0105cb4:	83 e0 02             	and    $0x2,%eax
c0105cb7:	85 c0                	test   %eax,%eax
c0105cb9:	75 40                	jne    c0105cfb <do_pgfault+0xb2>
            cprintf("do_pgfault failed: error code flag = write AND not present, but the addr's vma cannot write\n");
c0105cbb:	c7 04 24 98 b1 10 c0 	movl   $0xc010b198,(%esp)
c0105cc2:	e8 e2 a5 ff ff       	call   c01002a9 <cprintf>
            goto failed;
c0105cc7:	e9 8d 01 00 00       	jmp    c0105e59 <do_pgfault+0x210>
        }
        break;
    case 1: /* error code flag : (W/R=0, P=1): read, present */
        cprintf("do_pgfault failed: error code flag = read AND present\n");
c0105ccc:	c7 04 24 f8 b1 10 c0 	movl   $0xc010b1f8,(%esp)
c0105cd3:	e8 d1 a5 ff ff       	call   c01002a9 <cprintf>
        goto failed;
c0105cd8:	e9 7c 01 00 00       	jmp    c0105e59 <do_pgfault+0x210>
    case 0: /* error code flag : (W/R=0, P=0): read, not present */
        if (!(vma->vm_flags & (VM_READ | VM_EXEC))) {
c0105cdd:	8b 45 ec             	mov    -0x14(%ebp),%eax
c0105ce0:	8b 40 0c             	mov    0xc(%eax),%eax
c0105ce3:	83 e0 05             	and    $0x5,%eax
c0105ce6:	85 c0                	test   %eax,%eax
c0105ce8:	75 12                	jne    c0105cfc <do_pgfault+0xb3>
            cprintf("do_pgfault failed: error code flag = read AND not present, but the addr's vma cannot read or exec\n");
c0105cea:	c7 04 24 30 b2 10 c0 	movl   $0xc010b230,(%esp)
c0105cf1:	e8 b3 a5 ff ff       	call   c01002a9 <cprintf>
            goto failed;
c0105cf6:	e9 5e 01 00 00       	jmp    c0105e59 <do_pgfault+0x210>
        break;
c0105cfb:	90                   	nop
     *    (write an non_existed addr && addr is writable) OR
     *    (read  an non_existed addr && addr is readable)
     * THEN
     *    continue process
     */
    uint32_t perm = PTE_U;      //给它用户权限（给了一些类似读的权限）
c0105cfc:	c7 45 f0 04 00 00 00 	movl   $0x4,-0x10(%ebp)
    if (vma->vm_flags & VM_WRITE) { //是否可写
c0105d03:	8b 45 ec             	mov    -0x14(%ebp),%eax
c0105d06:	8b 40 0c             	mov    0xc(%eax),%eax
c0105d09:	83 e0 02             	and    $0x2,%eax
c0105d0c:	85 c0                	test   %eax,%eax
c0105d0e:	74 04                	je     c0105d14 <do_pgfault+0xcb>
        perm |= PTE_W;
c0105d10:	83 4d f0 02          	orl    $0x2,-0x10(%ebp)
    }
    addr = ROUNDDOWN(addr, PGSIZE);//作为页的起始地址
c0105d14:	8b 45 10             	mov    0x10(%ebp),%eax
c0105d17:	89 45 e8             	mov    %eax,-0x18(%ebp)
c0105d1a:	8b 45 e8             	mov    -0x18(%ebp),%eax
c0105d1d:	25 00 f0 ff ff       	and    $0xfffff000,%eax
c0105d22:	89 45 10             	mov    %eax,0x10(%ebp)

    ret = -E_NO_MEM;
c0105d25:	c7 45 f4 fc ff ff ff 	movl   $0xfffffffc,-0xc(%ebp)

    pte_t *ptep=NULL;
c0105d2c:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
        }
   }
#endif
    //1. try to find a pte, if pte's PT(Page Table) isn't existed, then create a PT. (notice the 3th parameter '1')
    // 获取addr线性地址在mm所关联页表中的页表项;第三个参数=1 表示如果对应页表项不存在，则需要新创建这个页表项（按需分配！！！！！！）
    if ((ptep = get_pte(mm->pgdir, addr, 1)) == NULL) { //正常不为null，若原先存在，直接get；若原先不存在，新建一个pte（之后需要建立映射）
c0105d33:	8b 45 08             	mov    0x8(%ebp),%eax
c0105d36:	8b 40 0c             	mov    0xc(%eax),%eax
c0105d39:	c7 44 24 08 01 00 00 	movl   $0x1,0x8(%esp)
c0105d40:	00 
c0105d41:	8b 55 10             	mov    0x10(%ebp),%edx
c0105d44:	89 54 24 04          	mov    %edx,0x4(%esp)
c0105d48:	89 04 24             	mov    %eax,(%esp)
c0105d4b:	e8 df dd ff ff       	call   c0103b2f <get_pte>
c0105d50:	89 45 e4             	mov    %eax,-0x1c(%ebp)
c0105d53:	83 7d e4 00          	cmpl   $0x0,-0x1c(%ebp)
c0105d57:	75 11                	jne    c0105d6a <do_pgfault+0x121>
        cprintf("get_pte in do_pgfault failed\n");
c0105d59:	c7 04 24 93 b2 10 c0 	movl   $0xc010b293,(%esp)
c0105d60:	e8 44 a5 ff ff       	call   c01002a9 <cprintf>
        goto failed;
c0105d65:	e9 ef 00 00 00       	jmp    c0105e59 <do_pgfault+0x210>
    }
    //2.if the phy addr isn't exist, then alloc a page & map the phy addr with logical addr
    //如果对应页表项的内容每一位都全为0，说明之前并不存在，需要设置对应的数据，进行线性地址与物理地址的映射
    if (*ptep == 0) {   //原先不存在，新建一个pte，然后需要建立映射
c0105d6a:	8b 45 e4             	mov    -0x1c(%ebp),%eax
c0105d6d:	8b 00                	mov    (%eax),%eax
c0105d6f:	85 c0                	test   %eax,%eax
c0105d71:	75 35                	jne    c0105da8 <do_pgfault+0x15f>
        if (pgdir_alloc_page(mm->pgdir, addr, perm) == NULL) {   //2.3.4.令pgdir指向的页表中，la线性地址对应的二级页表项与一个新分配的物理页Page进行虚实地址的映射
c0105d73:	8b 45 08             	mov    0x8(%ebp),%eax
c0105d76:	8b 40 0c             	mov    0xc(%eax),%eax
c0105d79:	8b 55 f0             	mov    -0x10(%ebp),%edx
c0105d7c:	89 54 24 08          	mov    %edx,0x8(%esp)
c0105d80:	8b 55 10             	mov    0x10(%ebp),%edx
c0105d83:	89 54 24 04          	mov    %edx,0x4(%esp)
c0105d87:	89 04 24             	mov    %eax,(%esp)
c0105d8a:	e8 ee e0 ff ff       	call   c0103e7d <pgdir_alloc_page>
c0105d8f:	85 c0                	test   %eax,%eax
c0105d91:	0f 85 bb 00 00 00    	jne    c0105e52 <do_pgfault+0x209>
            cprintf("pgdir_alloc_page in do_pgfault failed\n");
c0105d97:	c7 04 24 b4 b2 10 c0 	movl   $0xc010b2b4,(%esp)
c0105d9e:	e8 06 a5 ff ff       	call   c01002a9 <cprintf>
            goto failed;
c0105da3:	e9 b1 00 00 00       	jmp    c0105e59 <do_pgfault+0x210>
        }
    }

    //练习2的内容
    else {   // 如果不是全为0，说明可能是之前被交换到了swap磁盘中
        if(swap_init_ok) {       //如果开启了swap磁盘虚拟内存交换机制 swap里的init置1
c0105da8:	a1 14 90 12 c0       	mov    0xc0129014,%eax
c0105dad:	85 c0                	test   %eax,%eax
c0105daf:	0f 84 86 00 00 00    	je     c0105e3b <do_pgfault+0x1f2>
            struct Page *page=NULL;
c0105db5:	c7 45 e0 00 00 00 00 	movl   $0x0,-0x20(%ebp)
            if ((ret = swap_in(mm, addr, &page)) != 0) {    //1.将addr线性地址对应的物理页数据从磁盘交换到物理内存中(令Page指针指向交换成功后的物理页)
c0105dbc:	8d 45 e0             	lea    -0x20(%ebp),%eax
c0105dbf:	89 44 24 08          	mov    %eax,0x8(%esp)
c0105dc3:	8b 45 10             	mov    0x10(%ebp),%eax
c0105dc6:	89 44 24 04          	mov    %eax,0x4(%esp)
c0105dca:	8b 45 08             	mov    0x8(%ebp),%eax
c0105dcd:	89 04 24             	mov    %eax,(%esp)
c0105dd0:	e8 ea 0a 00 00       	call   c01068bf <swap_in>
c0105dd5:	89 45 f4             	mov    %eax,-0xc(%ebp)
c0105dd8:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
c0105ddc:	74 0e                	je     c0105dec <do_pgfault+0x1a3>
                cprintf("swap_in in do_pgfault failed\n");   //swap_in返回值不为0，表示换入失败
c0105dde:	c7 04 24 db b2 10 c0 	movl   $0xc010b2db,(%esp)
c0105de5:	e8 bf a4 ff ff       	call   c01002a9 <cprintf>
c0105dea:	eb 6d                	jmp    c0105e59 <do_pgfault+0x210>
                goto failed;
            }    
            page_insert(mm->pgdir, page, addr, perm);    //2.将交换进来的page页与mm->pgdir页表中对应addr的二级页表项建立映射关系(perm标识这个二级页表的各个权限位)
c0105dec:	8b 55 e0             	mov    -0x20(%ebp),%edx
c0105def:	8b 45 08             	mov    0x8(%ebp),%eax
c0105df2:	8b 40 0c             	mov    0xc(%eax),%eax
c0105df5:	8b 4d f0             	mov    -0x10(%ebp),%ecx
c0105df8:	89 4c 24 0c          	mov    %ecx,0xc(%esp)
c0105dfc:	8b 4d 10             	mov    0x10(%ebp),%ecx
c0105dff:	89 4c 24 08          	mov    %ecx,0x8(%esp)
c0105e03:	89 54 24 04          	mov    %edx,0x4(%esp)
c0105e07:	89 04 24             	mov    %eax,(%esp)
c0105e0a:	e8 59 df ff ff       	call   c0103d68 <page_insert>
            swap_map_swappable(mm, addr, page, 1);      //3.当前page是为可交换的，将其加入全局虚拟内存交换管理器的管理    //插进访问队列里
c0105e0f:	8b 45 e0             	mov    -0x20(%ebp),%eax
c0105e12:	c7 44 24 0c 01 00 00 	movl   $0x1,0xc(%esp)
c0105e19:	00 
c0105e1a:	89 44 24 08          	mov    %eax,0x8(%esp)
c0105e1e:	8b 45 10             	mov    0x10(%ebp),%eax
c0105e21:	89 44 24 04          	mov    %eax,0x4(%esp)
c0105e25:	8b 45 08             	mov    0x8(%ebp),%eax
c0105e28:	89 04 24             	mov    %eax,(%esp)
c0105e2b:	e8 cd 08 00 00       	call   c01066fd <swap_map_swappable>
            page->pra_vaddr = addr;//终于这个属性的赋值
c0105e30:	8b 45 e0             	mov    -0x20(%ebp),%eax
c0105e33:	8b 55 10             	mov    0x10(%ebp),%edx
c0105e36:	89 50 1c             	mov    %edx,0x1c(%eax)
c0105e39:	eb 17                	jmp    c0105e52 <do_pgfault+0x209>
                                                     //4.swap_out(check_mm_struct,n,0);是在alloc里实现的
        }
        else {  //如果没有开启swap磁盘虚拟内存交换机制，但是却执行至此，则出现了问题
            cprintf("no swap_init_ok but ptep is %x, failed\n",*ptep);
c0105e3b:	8b 45 e4             	mov    -0x1c(%ebp),%eax
c0105e3e:	8b 00                	mov    (%eax),%eax
c0105e40:	89 44 24 04          	mov    %eax,0x4(%esp)
c0105e44:	c7 04 24 fc b2 10 c0 	movl   $0xc010b2fc,(%esp)
c0105e4b:	e8 59 a4 ff ff       	call   c01002a9 <cprintf>
            goto failed;
c0105e50:	eb 07                	jmp    c0105e59 <do_pgfault+0x210>
        }
   }
   ret = 0;
c0105e52:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
failed:
    return ret; //非法va或越权，ret为-E_INVAL；缺页异常处理中出现异常，ret为-E_NO_MEM；缺页异常处理中完美解决，ret为0
c0105e59:	8b 45 f4             	mov    -0xc(%ebp),%eax
}
c0105e5c:	c9                   	leave  
c0105e5d:	c3                   	ret    

c0105e5e <__intr_save>:
__intr_save(void) {
c0105e5e:	55                   	push   %ebp
c0105e5f:	89 e5                	mov    %esp,%ebp
c0105e61:	83 ec 18             	sub    $0x18,%esp
    asm volatile ("pushfl; popl %0" : "=r" (eflags));
c0105e64:	9c                   	pushf  
c0105e65:	58                   	pop    %eax
c0105e66:	89 45 f4             	mov    %eax,-0xc(%ebp)
    return eflags;
c0105e69:	8b 45 f4             	mov    -0xc(%ebp),%eax
    if (read_eflags() & FL_IF) {//读操作出现中断
c0105e6c:	25 00 02 00 00       	and    $0x200,%eax
c0105e71:	85 c0                	test   %eax,%eax
c0105e73:	74 0c                	je     c0105e81 <__intr_save+0x23>
        intr_disable();//intr.c12->禁用irq中断
c0105e75:	e8 b8 c1 ff ff       	call   c0102032 <intr_disable>
        return 1;
c0105e7a:	b8 01 00 00 00       	mov    $0x1,%eax
c0105e7f:	eb 05                	jmp    c0105e86 <__intr_save+0x28>
    return 0;
c0105e81:	b8 00 00 00 00       	mov    $0x0,%eax
}
c0105e86:	c9                   	leave  
c0105e87:	c3                   	ret    

c0105e88 <__intr_restore>:
__intr_restore(bool flag) {
c0105e88:	55                   	push   %ebp
c0105e89:	89 e5                	mov    %esp,%ebp
c0105e8b:	83 ec 08             	sub    $0x8,%esp
    if (flag) {
c0105e8e:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
c0105e92:	74 05                	je     c0105e99 <__intr_restore+0x11>
        intr_enable();
c0105e94:	e8 92 c1 ff ff       	call   c010202b <intr_enable>
}
c0105e99:	90                   	nop
c0105e9a:	c9                   	leave  
c0105e9b:	c3                   	ret    

c0105e9c <page2ppn>:
page2ppn(struct Page *page) {
c0105e9c:	55                   	push   %ebp
c0105e9d:	89 e5                	mov    %esp,%ebp
    return page - pages;         //减去物理页数组的基址，得高20bit的PPN(pa)
c0105e9f:	8b 45 08             	mov    0x8(%ebp),%eax
c0105ea2:	8b 15 60 b0 12 c0    	mov    0xc012b060,%edx
c0105ea8:	29 d0                	sub    %edx,%eax
c0105eaa:	c1 f8 05             	sar    $0x5,%eax
}
c0105ead:	5d                   	pop    %ebp
c0105eae:	c3                   	ret    

c0105eaf <page2pa>:
page2pa(struct Page *page) {
c0105eaf:	55                   	push   %ebp
c0105eb0:	89 e5                	mov    %esp,%ebp
c0105eb2:	83 ec 04             	sub    $0x4,%esp
    return page2ppn(page) << PGSHIFT;   //20bit+12bit全0的pa
c0105eb5:	8b 45 08             	mov    0x8(%ebp),%eax
c0105eb8:	89 04 24             	mov    %eax,(%esp)
c0105ebb:	e8 dc ff ff ff       	call   c0105e9c <page2ppn>
c0105ec0:	c1 e0 0c             	shl    $0xc,%eax
}
c0105ec3:	c9                   	leave  
c0105ec4:	c3                   	ret    

c0105ec5 <pa2page>:
pa2page(uintptr_t pa) {
c0105ec5:	55                   	push   %ebp
c0105ec6:	89 e5                	mov    %esp,%ebp
c0105ec8:	83 ec 18             	sub    $0x18,%esp
    if (PPN(pa) >= npage) {
c0105ecb:	8b 45 08             	mov    0x8(%ebp),%eax
c0105ece:	c1 e8 0c             	shr    $0xc,%eax
c0105ed1:	89 c2                	mov    %eax,%edx
c0105ed3:	a1 80 8f 12 c0       	mov    0xc0128f80,%eax
c0105ed8:	39 c2                	cmp    %eax,%edx
c0105eda:	72 1c                	jb     c0105ef8 <pa2page+0x33>
        panic("pa2page called with invalid pa");
c0105edc:	c7 44 24 08 24 b3 10 	movl   $0xc010b324,0x8(%esp)
c0105ee3:	c0 
c0105ee4:	c7 44 24 04 5f 00 00 	movl   $0x5f,0x4(%esp)
c0105eeb:	00 
c0105eec:	c7 04 24 43 b3 10 c0 	movl   $0xc010b343,(%esp)
c0105ef3:	e8 08 a5 ff ff       	call   c0100400 <__panic>
    return &pages[PPN(pa)];   //pages+pa高20bit索引位 摒弃低12bit全0
c0105ef8:	a1 60 b0 12 c0       	mov    0xc012b060,%eax
c0105efd:	8b 55 08             	mov    0x8(%ebp),%edx
c0105f00:	c1 ea 0c             	shr    $0xc,%edx
c0105f03:	c1 e2 05             	shl    $0x5,%edx
c0105f06:	01 d0                	add    %edx,%eax
}
c0105f08:	c9                   	leave  
c0105f09:	c3                   	ret    

c0105f0a <page2kva>:
page2kva(struct Page *page) {
c0105f0a:	55                   	push   %ebp
c0105f0b:	89 e5                	mov    %esp,%ebp
c0105f0d:	83 ec 28             	sub    $0x28,%esp
    return KADDR(page2pa(page));
c0105f10:	8b 45 08             	mov    0x8(%ebp),%eax
c0105f13:	89 04 24             	mov    %eax,(%esp)
c0105f16:	e8 94 ff ff ff       	call   c0105eaf <page2pa>
c0105f1b:	89 45 f4             	mov    %eax,-0xc(%ebp)
c0105f1e:	8b 45 f4             	mov    -0xc(%ebp),%eax
c0105f21:	c1 e8 0c             	shr    $0xc,%eax
c0105f24:	89 45 f0             	mov    %eax,-0x10(%ebp)
c0105f27:	a1 80 8f 12 c0       	mov    0xc0128f80,%eax
c0105f2c:	39 45 f0             	cmp    %eax,-0x10(%ebp)
c0105f2f:	72 23                	jb     c0105f54 <page2kva+0x4a>
c0105f31:	8b 45 f4             	mov    -0xc(%ebp),%eax
c0105f34:	89 44 24 0c          	mov    %eax,0xc(%esp)
c0105f38:	c7 44 24 08 54 b3 10 	movl   $0xc010b354,0x8(%esp)
c0105f3f:	c0 
c0105f40:	c7 44 24 04 66 00 00 	movl   $0x66,0x4(%esp)
c0105f47:	00 
c0105f48:	c7 04 24 43 b3 10 c0 	movl   $0xc010b343,(%esp)
c0105f4f:	e8 ac a4 ff ff       	call   c0100400 <__panic>
c0105f54:	8b 45 f4             	mov    -0xc(%ebp),%eax
c0105f57:	2d 00 00 00 40       	sub    $0x40000000,%eax
}
c0105f5c:	c9                   	leave  
c0105f5d:	c3                   	ret    

c0105f5e <kva2page>:
kva2page(void *kva) {
c0105f5e:	55                   	push   %ebp
c0105f5f:	89 e5                	mov    %esp,%ebp
c0105f61:	83 ec 28             	sub    $0x28,%esp
    return pa2page(PADDR(kva));
c0105f64:	8b 45 08             	mov    0x8(%ebp),%eax
c0105f67:	89 45 f4             	mov    %eax,-0xc(%ebp)
c0105f6a:	81 7d f4 ff ff ff bf 	cmpl   $0xbfffffff,-0xc(%ebp)
c0105f71:	77 23                	ja     c0105f96 <kva2page+0x38>
c0105f73:	8b 45 f4             	mov    -0xc(%ebp),%eax
c0105f76:	89 44 24 0c          	mov    %eax,0xc(%esp)
c0105f7a:	c7 44 24 08 78 b3 10 	movl   $0xc010b378,0x8(%esp)
c0105f81:	c0 
c0105f82:	c7 44 24 04 6b 00 00 	movl   $0x6b,0x4(%esp)
c0105f89:	00 
c0105f8a:	c7 04 24 43 b3 10 c0 	movl   $0xc010b343,(%esp)
c0105f91:	e8 6a a4 ff ff       	call   c0100400 <__panic>
c0105f96:	8b 45 f4             	mov    -0xc(%ebp),%eax
c0105f99:	05 00 00 00 40       	add    $0x40000000,%eax
c0105f9e:	89 04 24             	mov    %eax,(%esp)
c0105fa1:	e8 1f ff ff ff       	call   c0105ec5 <pa2page>
}
c0105fa6:	c9                   	leave  
c0105fa7:	c3                   	ret    

c0105fa8 <__slob_get_free_pages>:
static slob_t *slobfree = &arena;
static bigblock_t *bigblocks;


static void* __slob_get_free_pages(gfp_t gfp, int order)
{
c0105fa8:	55                   	push   %ebp
c0105fa9:	89 e5                	mov    %esp,%ebp
c0105fab:	83 ec 28             	sub    $0x28,%esp
  struct Page * page = alloc_pages(1 << order);
c0105fae:	8b 45 0c             	mov    0xc(%ebp),%eax
c0105fb1:	ba 01 00 00 00       	mov    $0x1,%edx
c0105fb6:	88 c1                	mov    %al,%cl
c0105fb8:	d3 e2                	shl    %cl,%edx
c0105fba:	89 d0                	mov    %edx,%eax
c0105fbc:	89 04 24             	mov    %eax,(%esp)
c0105fbf:	e8 8b d4 ff ff       	call   c010344f <alloc_pages>
c0105fc4:	89 45 f4             	mov    %eax,-0xc(%ebp)
  if(!page)
c0105fc7:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
c0105fcb:	75 07                	jne    c0105fd4 <__slob_get_free_pages+0x2c>
    return NULL;
c0105fcd:	b8 00 00 00 00       	mov    $0x0,%eax
c0105fd2:	eb 0b                	jmp    c0105fdf <__slob_get_free_pages+0x37>
  return page2kva(page);
c0105fd4:	8b 45 f4             	mov    -0xc(%ebp),%eax
c0105fd7:	89 04 24             	mov    %eax,(%esp)
c0105fda:	e8 2b ff ff ff       	call   c0105f0a <page2kva>
}
c0105fdf:	c9                   	leave  
c0105fe0:	c3                   	ret    

c0105fe1 <__slob_free_pages>:

#define __slob_get_free_page(gfp) __slob_get_free_pages(gfp, 0)

static inline void __slob_free_pages(unsigned long kva, int order)
{
c0105fe1:	55                   	push   %ebp
c0105fe2:	89 e5                	mov    %esp,%ebp
c0105fe4:	53                   	push   %ebx
c0105fe5:	83 ec 14             	sub    $0x14,%esp
  free_pages(kva2page(kva), 1 << order);
c0105fe8:	8b 45 0c             	mov    0xc(%ebp),%eax
c0105feb:	ba 01 00 00 00       	mov    $0x1,%edx
c0105ff0:	88 c1                	mov    %al,%cl
c0105ff2:	d3 e2                	shl    %cl,%edx
c0105ff4:	89 d0                	mov    %edx,%eax
c0105ff6:	89 c3                	mov    %eax,%ebx
c0105ff8:	8b 45 08             	mov    0x8(%ebp),%eax
c0105ffb:	89 04 24             	mov    %eax,(%esp)
c0105ffe:	e8 5b ff ff ff       	call   c0105f5e <kva2page>
c0106003:	89 5c 24 04          	mov    %ebx,0x4(%esp)
c0106007:	89 04 24             	mov    %eax,(%esp)
c010600a:	e8 ab d4 ff ff       	call   c01034ba <free_pages>
}
c010600f:	90                   	nop
c0106010:	83 c4 14             	add    $0x14,%esp
c0106013:	5b                   	pop    %ebx
c0106014:	5d                   	pop    %ebp
c0106015:	c3                   	ret    

c0106016 <slob_alloc>:

static void slob_free(void *b, int size);

static void *slob_alloc(size_t size, gfp_t gfp, int align)
{
c0106016:	55                   	push   %ebp
c0106017:	89 e5                	mov    %esp,%ebp
c0106019:	83 ec 38             	sub    $0x38,%esp
  assert( (size + SLOB_UNIT) < PAGE_SIZE );
c010601c:	8b 45 08             	mov    0x8(%ebp),%eax
c010601f:	83 c0 08             	add    $0x8,%eax
c0106022:	3d ff 0f 00 00       	cmp    $0xfff,%eax
c0106027:	76 24                	jbe    c010604d <slob_alloc+0x37>
c0106029:	c7 44 24 0c 9c b3 10 	movl   $0xc010b39c,0xc(%esp)
c0106030:	c0 
c0106031:	c7 44 24 08 bb b3 10 	movl   $0xc010b3bb,0x8(%esp)
c0106038:	c0 
c0106039:	c7 44 24 04 64 00 00 	movl   $0x64,0x4(%esp)
c0106040:	00 
c0106041:	c7 04 24 d0 b3 10 c0 	movl   $0xc010b3d0,(%esp)
c0106048:	e8 b3 a3 ff ff       	call   c0100400 <__panic>

	slob_t *prev, *cur, *aligned = 0;
c010604d:	c7 45 ec 00 00 00 00 	movl   $0x0,-0x14(%ebp)
	int delta = 0, units = SLOB_UNITS(size);
c0106054:	c7 45 e8 00 00 00 00 	movl   $0x0,-0x18(%ebp)
c010605b:	8b 45 08             	mov    0x8(%ebp),%eax
c010605e:	83 c0 07             	add    $0x7,%eax
c0106061:	c1 e8 03             	shr    $0x3,%eax
c0106064:	89 45 e0             	mov    %eax,-0x20(%ebp)
	unsigned long flags;

	spin_lock_irqsave(&slob_lock, flags);
c0106067:	e8 f2 fd ff ff       	call   c0105e5e <__intr_save>
c010606c:	89 45 e4             	mov    %eax,-0x1c(%ebp)
	prev = slobfree;
c010606f:	a1 68 5a 12 c0       	mov    0xc0125a68,%eax
c0106074:	89 45 f4             	mov    %eax,-0xc(%ebp)
	for (cur = prev->next; ; prev = cur, cur = cur->next) {
c0106077:	8b 45 f4             	mov    -0xc(%ebp),%eax
c010607a:	8b 40 04             	mov    0x4(%eax),%eax
c010607d:	89 45 f0             	mov    %eax,-0x10(%ebp)
		if (align) {
c0106080:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
c0106084:	74 25                	je     c01060ab <slob_alloc+0x95>
			aligned = (slob_t *)ALIGN((unsigned long)cur, align);
c0106086:	8b 55 f0             	mov    -0x10(%ebp),%edx
c0106089:	8b 45 10             	mov    0x10(%ebp),%eax
c010608c:	01 d0                	add    %edx,%eax
c010608e:	8d 50 ff             	lea    -0x1(%eax),%edx
c0106091:	8b 45 10             	mov    0x10(%ebp),%eax
c0106094:	f7 d8                	neg    %eax
c0106096:	21 d0                	and    %edx,%eax
c0106098:	89 45 ec             	mov    %eax,-0x14(%ebp)
			delta = aligned - cur;
c010609b:	8b 55 ec             	mov    -0x14(%ebp),%edx
c010609e:	8b 45 f0             	mov    -0x10(%ebp),%eax
c01060a1:	29 c2                	sub    %eax,%edx
c01060a3:	89 d0                	mov    %edx,%eax
c01060a5:	c1 f8 03             	sar    $0x3,%eax
c01060a8:	89 45 e8             	mov    %eax,-0x18(%ebp)
		}
		if (cur->units >= units + delta) { /* room enough? */
c01060ab:	8b 45 f0             	mov    -0x10(%ebp),%eax
c01060ae:	8b 00                	mov    (%eax),%eax
c01060b0:	8b 4d e0             	mov    -0x20(%ebp),%ecx
c01060b3:	8b 55 e8             	mov    -0x18(%ebp),%edx
c01060b6:	01 ca                	add    %ecx,%edx
c01060b8:	39 d0                	cmp    %edx,%eax
c01060ba:	0f 8c aa 00 00 00    	jl     c010616a <slob_alloc+0x154>
			if (delta) { /* need to fragment head to align? */
c01060c0:	83 7d e8 00          	cmpl   $0x0,-0x18(%ebp)
c01060c4:	74 38                	je     c01060fe <slob_alloc+0xe8>
				aligned->units = cur->units - delta;
c01060c6:	8b 45 f0             	mov    -0x10(%ebp),%eax
c01060c9:	8b 00                	mov    (%eax),%eax
c01060cb:	2b 45 e8             	sub    -0x18(%ebp),%eax
c01060ce:	89 c2                	mov    %eax,%edx
c01060d0:	8b 45 ec             	mov    -0x14(%ebp),%eax
c01060d3:	89 10                	mov    %edx,(%eax)
				aligned->next = cur->next;
c01060d5:	8b 45 f0             	mov    -0x10(%ebp),%eax
c01060d8:	8b 50 04             	mov    0x4(%eax),%edx
c01060db:	8b 45 ec             	mov    -0x14(%ebp),%eax
c01060de:	89 50 04             	mov    %edx,0x4(%eax)
				cur->next = aligned;
c01060e1:	8b 45 f0             	mov    -0x10(%ebp),%eax
c01060e4:	8b 55 ec             	mov    -0x14(%ebp),%edx
c01060e7:	89 50 04             	mov    %edx,0x4(%eax)
				cur->units = delta;
c01060ea:	8b 45 f0             	mov    -0x10(%ebp),%eax
c01060ed:	8b 55 e8             	mov    -0x18(%ebp),%edx
c01060f0:	89 10                	mov    %edx,(%eax)
				prev = cur;
c01060f2:	8b 45 f0             	mov    -0x10(%ebp),%eax
c01060f5:	89 45 f4             	mov    %eax,-0xc(%ebp)
				cur = aligned;
c01060f8:	8b 45 ec             	mov    -0x14(%ebp),%eax
c01060fb:	89 45 f0             	mov    %eax,-0x10(%ebp)
			}

			if (cur->units == units) /* exact fit? */
c01060fe:	8b 45 f0             	mov    -0x10(%ebp),%eax
c0106101:	8b 00                	mov    (%eax),%eax
c0106103:	39 45 e0             	cmp    %eax,-0x20(%ebp)
c0106106:	75 0e                	jne    c0106116 <slob_alloc+0x100>
				prev->next = cur->next; /* unlink */
c0106108:	8b 45 f0             	mov    -0x10(%ebp),%eax
c010610b:	8b 50 04             	mov    0x4(%eax),%edx
c010610e:	8b 45 f4             	mov    -0xc(%ebp),%eax
c0106111:	89 50 04             	mov    %edx,0x4(%eax)
c0106114:	eb 3c                	jmp    c0106152 <slob_alloc+0x13c>
			else { /* fragment */
				prev->next = cur + units;
c0106116:	8b 45 e0             	mov    -0x20(%ebp),%eax
c0106119:	8d 14 c5 00 00 00 00 	lea    0x0(,%eax,8),%edx
c0106120:	8b 45 f0             	mov    -0x10(%ebp),%eax
c0106123:	01 c2                	add    %eax,%edx
c0106125:	8b 45 f4             	mov    -0xc(%ebp),%eax
c0106128:	89 50 04             	mov    %edx,0x4(%eax)
				prev->next->units = cur->units - units;
c010612b:	8b 45 f0             	mov    -0x10(%ebp),%eax
c010612e:	8b 10                	mov    (%eax),%edx
c0106130:	8b 45 f4             	mov    -0xc(%ebp),%eax
c0106133:	8b 40 04             	mov    0x4(%eax),%eax
c0106136:	2b 55 e0             	sub    -0x20(%ebp),%edx
c0106139:	89 10                	mov    %edx,(%eax)
				prev->next->next = cur->next;
c010613b:	8b 45 f4             	mov    -0xc(%ebp),%eax
c010613e:	8b 40 04             	mov    0x4(%eax),%eax
c0106141:	8b 55 f0             	mov    -0x10(%ebp),%edx
c0106144:	8b 52 04             	mov    0x4(%edx),%edx
c0106147:	89 50 04             	mov    %edx,0x4(%eax)
				cur->units = units;
c010614a:	8b 45 f0             	mov    -0x10(%ebp),%eax
c010614d:	8b 55 e0             	mov    -0x20(%ebp),%edx
c0106150:	89 10                	mov    %edx,(%eax)
			}

			slobfree = prev;
c0106152:	8b 45 f4             	mov    -0xc(%ebp),%eax
c0106155:	a3 68 5a 12 c0       	mov    %eax,0xc0125a68
			spin_unlock_irqrestore(&slob_lock, flags);
c010615a:	8b 45 e4             	mov    -0x1c(%ebp),%eax
c010615d:	89 04 24             	mov    %eax,(%esp)
c0106160:	e8 23 fd ff ff       	call   c0105e88 <__intr_restore>
			return cur;
c0106165:	8b 45 f0             	mov    -0x10(%ebp),%eax
c0106168:	eb 7f                	jmp    c01061e9 <slob_alloc+0x1d3>
		}
		if (cur == slobfree) {
c010616a:	a1 68 5a 12 c0       	mov    0xc0125a68,%eax
c010616f:	39 45 f0             	cmp    %eax,-0x10(%ebp)
c0106172:	75 61                	jne    c01061d5 <slob_alloc+0x1bf>
			spin_unlock_irqrestore(&slob_lock, flags);
c0106174:	8b 45 e4             	mov    -0x1c(%ebp),%eax
c0106177:	89 04 24             	mov    %eax,(%esp)
c010617a:	e8 09 fd ff ff       	call   c0105e88 <__intr_restore>

			if (size == PAGE_SIZE) /* trying to shrink arena? */
c010617f:	81 7d 08 00 10 00 00 	cmpl   $0x1000,0x8(%ebp)
c0106186:	75 07                	jne    c010618f <slob_alloc+0x179>
				return 0;
c0106188:	b8 00 00 00 00       	mov    $0x0,%eax
c010618d:	eb 5a                	jmp    c01061e9 <slob_alloc+0x1d3>

			cur = (slob_t *)__slob_get_free_page(gfp);
c010618f:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
c0106196:	00 
c0106197:	8b 45 0c             	mov    0xc(%ebp),%eax
c010619a:	89 04 24             	mov    %eax,(%esp)
c010619d:	e8 06 fe ff ff       	call   c0105fa8 <__slob_get_free_pages>
c01061a2:	89 45 f0             	mov    %eax,-0x10(%ebp)
			if (!cur)
c01061a5:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
c01061a9:	75 07                	jne    c01061b2 <slob_alloc+0x19c>
				return 0;
c01061ab:	b8 00 00 00 00       	mov    $0x0,%eax
c01061b0:	eb 37                	jmp    c01061e9 <slob_alloc+0x1d3>

			slob_free(cur, PAGE_SIZE);
c01061b2:	c7 44 24 04 00 10 00 	movl   $0x1000,0x4(%esp)
c01061b9:	00 
c01061ba:	8b 45 f0             	mov    -0x10(%ebp),%eax
c01061bd:	89 04 24             	mov    %eax,(%esp)
c01061c0:	e8 26 00 00 00       	call   c01061eb <slob_free>
			spin_lock_irqsave(&slob_lock, flags);
c01061c5:	e8 94 fc ff ff       	call   c0105e5e <__intr_save>
c01061ca:	89 45 e4             	mov    %eax,-0x1c(%ebp)
			cur = slobfree;
c01061cd:	a1 68 5a 12 c0       	mov    0xc0125a68,%eax
c01061d2:	89 45 f0             	mov    %eax,-0x10(%ebp)
	for (cur = prev->next; ; prev = cur, cur = cur->next) {
c01061d5:	8b 45 f0             	mov    -0x10(%ebp),%eax
c01061d8:	89 45 f4             	mov    %eax,-0xc(%ebp)
c01061db:	8b 45 f0             	mov    -0x10(%ebp),%eax
c01061de:	8b 40 04             	mov    0x4(%eax),%eax
c01061e1:	89 45 f0             	mov    %eax,-0x10(%ebp)
		if (align) {
c01061e4:	e9 97 fe ff ff       	jmp    c0106080 <slob_alloc+0x6a>
		}
	}
}
c01061e9:	c9                   	leave  
c01061ea:	c3                   	ret    

c01061eb <slob_free>:

static void slob_free(void *block, int size)
{
c01061eb:	55                   	push   %ebp
c01061ec:	89 e5                	mov    %esp,%ebp
c01061ee:	83 ec 28             	sub    $0x28,%esp
	slob_t *cur, *b = (slob_t *)block;
c01061f1:	8b 45 08             	mov    0x8(%ebp),%eax
c01061f4:	89 45 f0             	mov    %eax,-0x10(%ebp)
	unsigned long flags;

	if (!block)
c01061f7:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
c01061fb:	0f 84 01 01 00 00    	je     c0106302 <slob_free+0x117>
		return;

	if (size)
c0106201:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
c0106205:	74 10                	je     c0106217 <slob_free+0x2c>
		b->units = SLOB_UNITS(size);
c0106207:	8b 45 0c             	mov    0xc(%ebp),%eax
c010620a:	83 c0 07             	add    $0x7,%eax
c010620d:	c1 e8 03             	shr    $0x3,%eax
c0106210:	89 c2                	mov    %eax,%edx
c0106212:	8b 45 f0             	mov    -0x10(%ebp),%eax
c0106215:	89 10                	mov    %edx,(%eax)

	/* Find reinsertion point */
	spin_lock_irqsave(&slob_lock, flags);
c0106217:	e8 42 fc ff ff       	call   c0105e5e <__intr_save>
c010621c:	89 45 ec             	mov    %eax,-0x14(%ebp)
	for (cur = slobfree; !(b > cur && b < cur->next); cur = cur->next)
c010621f:	a1 68 5a 12 c0       	mov    0xc0125a68,%eax
c0106224:	89 45 f4             	mov    %eax,-0xc(%ebp)
c0106227:	eb 27                	jmp    c0106250 <slob_free+0x65>
		if (cur >= cur->next && (b > cur || b < cur->next))
c0106229:	8b 45 f4             	mov    -0xc(%ebp),%eax
c010622c:	8b 40 04             	mov    0x4(%eax),%eax
c010622f:	39 45 f4             	cmp    %eax,-0xc(%ebp)
c0106232:	72 13                	jb     c0106247 <slob_free+0x5c>
c0106234:	8b 45 f0             	mov    -0x10(%ebp),%eax
c0106237:	3b 45 f4             	cmp    -0xc(%ebp),%eax
c010623a:	77 27                	ja     c0106263 <slob_free+0x78>
c010623c:	8b 45 f4             	mov    -0xc(%ebp),%eax
c010623f:	8b 40 04             	mov    0x4(%eax),%eax
c0106242:	39 45 f0             	cmp    %eax,-0x10(%ebp)
c0106245:	72 1c                	jb     c0106263 <slob_free+0x78>
	for (cur = slobfree; !(b > cur && b < cur->next); cur = cur->next)
c0106247:	8b 45 f4             	mov    -0xc(%ebp),%eax
c010624a:	8b 40 04             	mov    0x4(%eax),%eax
c010624d:	89 45 f4             	mov    %eax,-0xc(%ebp)
c0106250:	8b 45 f0             	mov    -0x10(%ebp),%eax
c0106253:	3b 45 f4             	cmp    -0xc(%ebp),%eax
c0106256:	76 d1                	jbe    c0106229 <slob_free+0x3e>
c0106258:	8b 45 f4             	mov    -0xc(%ebp),%eax
c010625b:	8b 40 04             	mov    0x4(%eax),%eax
c010625e:	39 45 f0             	cmp    %eax,-0x10(%ebp)
c0106261:	73 c6                	jae    c0106229 <slob_free+0x3e>
			break;

	if (b + b->units == cur->next) {
c0106263:	8b 45 f0             	mov    -0x10(%ebp),%eax
c0106266:	8b 00                	mov    (%eax),%eax
c0106268:	8d 14 c5 00 00 00 00 	lea    0x0(,%eax,8),%edx
c010626f:	8b 45 f0             	mov    -0x10(%ebp),%eax
c0106272:	01 c2                	add    %eax,%edx
c0106274:	8b 45 f4             	mov    -0xc(%ebp),%eax
c0106277:	8b 40 04             	mov    0x4(%eax),%eax
c010627a:	39 c2                	cmp    %eax,%edx
c010627c:	75 25                	jne    c01062a3 <slob_free+0xb8>
		b->units += cur->next->units;
c010627e:	8b 45 f0             	mov    -0x10(%ebp),%eax
c0106281:	8b 10                	mov    (%eax),%edx
c0106283:	8b 45 f4             	mov    -0xc(%ebp),%eax
c0106286:	8b 40 04             	mov    0x4(%eax),%eax
c0106289:	8b 00                	mov    (%eax),%eax
c010628b:	01 c2                	add    %eax,%edx
c010628d:	8b 45 f0             	mov    -0x10(%ebp),%eax
c0106290:	89 10                	mov    %edx,(%eax)
		b->next = cur->next->next;
c0106292:	8b 45 f4             	mov    -0xc(%ebp),%eax
c0106295:	8b 40 04             	mov    0x4(%eax),%eax
c0106298:	8b 50 04             	mov    0x4(%eax),%edx
c010629b:	8b 45 f0             	mov    -0x10(%ebp),%eax
c010629e:	89 50 04             	mov    %edx,0x4(%eax)
c01062a1:	eb 0c                	jmp    c01062af <slob_free+0xc4>
	} else
		b->next = cur->next;
c01062a3:	8b 45 f4             	mov    -0xc(%ebp),%eax
c01062a6:	8b 50 04             	mov    0x4(%eax),%edx
c01062a9:	8b 45 f0             	mov    -0x10(%ebp),%eax
c01062ac:	89 50 04             	mov    %edx,0x4(%eax)

	if (cur + cur->units == b) {
c01062af:	8b 45 f4             	mov    -0xc(%ebp),%eax
c01062b2:	8b 00                	mov    (%eax),%eax
c01062b4:	8d 14 c5 00 00 00 00 	lea    0x0(,%eax,8),%edx
c01062bb:	8b 45 f4             	mov    -0xc(%ebp),%eax
c01062be:	01 d0                	add    %edx,%eax
c01062c0:	39 45 f0             	cmp    %eax,-0x10(%ebp)
c01062c3:	75 1f                	jne    c01062e4 <slob_free+0xf9>
		cur->units += b->units;
c01062c5:	8b 45 f4             	mov    -0xc(%ebp),%eax
c01062c8:	8b 10                	mov    (%eax),%edx
c01062ca:	8b 45 f0             	mov    -0x10(%ebp),%eax
c01062cd:	8b 00                	mov    (%eax),%eax
c01062cf:	01 c2                	add    %eax,%edx
c01062d1:	8b 45 f4             	mov    -0xc(%ebp),%eax
c01062d4:	89 10                	mov    %edx,(%eax)
		cur->next = b->next;
c01062d6:	8b 45 f0             	mov    -0x10(%ebp),%eax
c01062d9:	8b 50 04             	mov    0x4(%eax),%edx
c01062dc:	8b 45 f4             	mov    -0xc(%ebp),%eax
c01062df:	89 50 04             	mov    %edx,0x4(%eax)
c01062e2:	eb 09                	jmp    c01062ed <slob_free+0x102>
	} else
		cur->next = b;
c01062e4:	8b 45 f4             	mov    -0xc(%ebp),%eax
c01062e7:	8b 55 f0             	mov    -0x10(%ebp),%edx
c01062ea:	89 50 04             	mov    %edx,0x4(%eax)

	slobfree = cur;
c01062ed:	8b 45 f4             	mov    -0xc(%ebp),%eax
c01062f0:	a3 68 5a 12 c0       	mov    %eax,0xc0125a68

	spin_unlock_irqrestore(&slob_lock, flags);
c01062f5:	8b 45 ec             	mov    -0x14(%ebp),%eax
c01062f8:	89 04 24             	mov    %eax,(%esp)
c01062fb:	e8 88 fb ff ff       	call   c0105e88 <__intr_restore>
c0106300:	eb 01                	jmp    c0106303 <slob_free+0x118>
		return;
c0106302:	90                   	nop
}
c0106303:	c9                   	leave  
c0106304:	c3                   	ret    

c0106305 <slob_init>:



void
slob_init(void) {
c0106305:	55                   	push   %ebp
c0106306:	89 e5                	mov    %esp,%ebp
c0106308:	83 ec 18             	sub    $0x18,%esp
  cprintf("use SLOB allocator\n");
c010630b:	c7 04 24 e2 b3 10 c0 	movl   $0xc010b3e2,(%esp)
c0106312:	e8 92 9f ff ff       	call   c01002a9 <cprintf>
}
c0106317:	90                   	nop
c0106318:	c9                   	leave  
c0106319:	c3                   	ret    

c010631a <kmalloc_init>:

inline void 
kmalloc_init(void) {
c010631a:	55                   	push   %ebp
c010631b:	89 e5                	mov    %esp,%ebp
c010631d:	83 ec 18             	sub    $0x18,%esp
    slob_init();
c0106320:	e8 e0 ff ff ff       	call   c0106305 <slob_init>
    cprintf("kmalloc_init() succeeded!\n");
c0106325:	c7 04 24 f6 b3 10 c0 	movl   $0xc010b3f6,(%esp)
c010632c:	e8 78 9f ff ff       	call   c01002a9 <cprintf>
}
c0106331:	90                   	nop
c0106332:	c9                   	leave  
c0106333:	c3                   	ret    

c0106334 <slob_allocated>:

size_t
slob_allocated(void) {
c0106334:	55                   	push   %ebp
c0106335:	89 e5                	mov    %esp,%ebp
  return 0;
c0106337:	b8 00 00 00 00       	mov    $0x0,%eax
}
c010633c:	5d                   	pop    %ebp
c010633d:	c3                   	ret    

c010633e <kallocated>:

size_t
kallocated(void) {
c010633e:	55                   	push   %ebp
c010633f:	89 e5                	mov    %esp,%ebp
   return slob_allocated();
c0106341:	e8 ee ff ff ff       	call   c0106334 <slob_allocated>
}
c0106346:	5d                   	pop    %ebp
c0106347:	c3                   	ret    

c0106348 <find_order>:

static int find_order(int size)
{
c0106348:	55                   	push   %ebp
c0106349:	89 e5                	mov    %esp,%ebp
c010634b:	83 ec 10             	sub    $0x10,%esp
	int order = 0;
c010634e:	c7 45 fc 00 00 00 00 	movl   $0x0,-0x4(%ebp)
	for ( ; size > 4096 ; size >>=1)
c0106355:	eb 06                	jmp    c010635d <find_order+0x15>
		order++;
c0106357:	ff 45 fc             	incl   -0x4(%ebp)
	for ( ; size > 4096 ; size >>=1)
c010635a:	d1 7d 08             	sarl   0x8(%ebp)
c010635d:	81 7d 08 00 10 00 00 	cmpl   $0x1000,0x8(%ebp)
c0106364:	7f f1                	jg     c0106357 <find_order+0xf>
	return order;
c0106366:	8b 45 fc             	mov    -0x4(%ebp),%eax
}
c0106369:	c9                   	leave  
c010636a:	c3                   	ret    

c010636b <__kmalloc>:

static void *__kmalloc(size_t size, gfp_t gfp)
{
c010636b:	55                   	push   %ebp
c010636c:	89 e5                	mov    %esp,%ebp
c010636e:	83 ec 28             	sub    $0x28,%esp
	slob_t *m;
	bigblock_t *bb;
	unsigned long flags;

	if (size < PAGE_SIZE - SLOB_UNIT) {
c0106371:	81 7d 08 f7 0f 00 00 	cmpl   $0xff7,0x8(%ebp)
c0106378:	77 3b                	ja     c01063b5 <__kmalloc+0x4a>
		m = slob_alloc(size + SLOB_UNIT, gfp, 0);
c010637a:	8b 45 08             	mov    0x8(%ebp),%eax
c010637d:	8d 50 08             	lea    0x8(%eax),%edx
c0106380:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
c0106387:	00 
c0106388:	8b 45 0c             	mov    0xc(%ebp),%eax
c010638b:	89 44 24 04          	mov    %eax,0x4(%esp)
c010638f:	89 14 24             	mov    %edx,(%esp)
c0106392:	e8 7f fc ff ff       	call   c0106016 <slob_alloc>
c0106397:	89 45 ec             	mov    %eax,-0x14(%ebp)
		return m ? (void *)(m + 1) : 0;
c010639a:	83 7d ec 00          	cmpl   $0x0,-0x14(%ebp)
c010639e:	74 0b                	je     c01063ab <__kmalloc+0x40>
c01063a0:	8b 45 ec             	mov    -0x14(%ebp),%eax
c01063a3:	83 c0 08             	add    $0x8,%eax
c01063a6:	e9 b4 00 00 00       	jmp    c010645f <__kmalloc+0xf4>
c01063ab:	b8 00 00 00 00       	mov    $0x0,%eax
c01063b0:	e9 aa 00 00 00       	jmp    c010645f <__kmalloc+0xf4>
	}

	bb = slob_alloc(sizeof(bigblock_t), gfp, 0);
c01063b5:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
c01063bc:	00 
c01063bd:	8b 45 0c             	mov    0xc(%ebp),%eax
c01063c0:	89 44 24 04          	mov    %eax,0x4(%esp)
c01063c4:	c7 04 24 0c 00 00 00 	movl   $0xc,(%esp)
c01063cb:	e8 46 fc ff ff       	call   c0106016 <slob_alloc>
c01063d0:	89 45 f4             	mov    %eax,-0xc(%ebp)
	if (!bb)
c01063d3:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
c01063d7:	75 07                	jne    c01063e0 <__kmalloc+0x75>
		return 0;
c01063d9:	b8 00 00 00 00       	mov    $0x0,%eax
c01063de:	eb 7f                	jmp    c010645f <__kmalloc+0xf4>

	bb->order = find_order(size);
c01063e0:	8b 45 08             	mov    0x8(%ebp),%eax
c01063e3:	89 04 24             	mov    %eax,(%esp)
c01063e6:	e8 5d ff ff ff       	call   c0106348 <find_order>
c01063eb:	89 c2                	mov    %eax,%edx
c01063ed:	8b 45 f4             	mov    -0xc(%ebp),%eax
c01063f0:	89 10                	mov    %edx,(%eax)
	bb->pages = (void *)__slob_get_free_pages(gfp, bb->order);
c01063f2:	8b 45 f4             	mov    -0xc(%ebp),%eax
c01063f5:	8b 00                	mov    (%eax),%eax
c01063f7:	89 44 24 04          	mov    %eax,0x4(%esp)
c01063fb:	8b 45 0c             	mov    0xc(%ebp),%eax
c01063fe:	89 04 24             	mov    %eax,(%esp)
c0106401:	e8 a2 fb ff ff       	call   c0105fa8 <__slob_get_free_pages>
c0106406:	89 c2                	mov    %eax,%edx
c0106408:	8b 45 f4             	mov    -0xc(%ebp),%eax
c010640b:	89 50 04             	mov    %edx,0x4(%eax)

	if (bb->pages) {
c010640e:	8b 45 f4             	mov    -0xc(%ebp),%eax
c0106411:	8b 40 04             	mov    0x4(%eax),%eax
c0106414:	85 c0                	test   %eax,%eax
c0106416:	74 2f                	je     c0106447 <__kmalloc+0xdc>
		spin_lock_irqsave(&block_lock, flags);
c0106418:	e8 41 fa ff ff       	call   c0105e5e <__intr_save>
c010641d:	89 45 f0             	mov    %eax,-0x10(%ebp)
		bb->next = bigblocks;
c0106420:	8b 15 10 90 12 c0    	mov    0xc0129010,%edx
c0106426:	8b 45 f4             	mov    -0xc(%ebp),%eax
c0106429:	89 50 08             	mov    %edx,0x8(%eax)
		bigblocks = bb;
c010642c:	8b 45 f4             	mov    -0xc(%ebp),%eax
c010642f:	a3 10 90 12 c0       	mov    %eax,0xc0129010
		spin_unlock_irqrestore(&block_lock, flags);
c0106434:	8b 45 f0             	mov    -0x10(%ebp),%eax
c0106437:	89 04 24             	mov    %eax,(%esp)
c010643a:	e8 49 fa ff ff       	call   c0105e88 <__intr_restore>
		return bb->pages;
c010643f:	8b 45 f4             	mov    -0xc(%ebp),%eax
c0106442:	8b 40 04             	mov    0x4(%eax),%eax
c0106445:	eb 18                	jmp    c010645f <__kmalloc+0xf4>
	}

	slob_free(bb, sizeof(bigblock_t));
c0106447:	c7 44 24 04 0c 00 00 	movl   $0xc,0x4(%esp)
c010644e:	00 
c010644f:	8b 45 f4             	mov    -0xc(%ebp),%eax
c0106452:	89 04 24             	mov    %eax,(%esp)
c0106455:	e8 91 fd ff ff       	call   c01061eb <slob_free>
	return 0;
c010645a:	b8 00 00 00 00       	mov    $0x0,%eax
}
c010645f:	c9                   	leave  
c0106460:	c3                   	ret    

c0106461 <kmalloc>:

void *
kmalloc(size_t size)
{
c0106461:	55                   	push   %ebp
c0106462:	89 e5                	mov    %esp,%ebp
c0106464:	83 ec 18             	sub    $0x18,%esp
  return __kmalloc(size, 0);
c0106467:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
c010646e:	00 
c010646f:	8b 45 08             	mov    0x8(%ebp),%eax
c0106472:	89 04 24             	mov    %eax,(%esp)
c0106475:	e8 f1 fe ff ff       	call   c010636b <__kmalloc>
}
c010647a:	c9                   	leave  
c010647b:	c3                   	ret    

c010647c <kfree>:


void kfree(void *block)
{
c010647c:	55                   	push   %ebp
c010647d:	89 e5                	mov    %esp,%ebp
c010647f:	83 ec 28             	sub    $0x28,%esp
	bigblock_t *bb, **last = &bigblocks;
c0106482:	c7 45 f0 10 90 12 c0 	movl   $0xc0129010,-0x10(%ebp)
	unsigned long flags;

	if (!block)
c0106489:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
c010648d:	0f 84 a4 00 00 00    	je     c0106537 <kfree+0xbb>
		return;

	if (!((unsigned long)block & (PAGE_SIZE-1))) {
c0106493:	8b 45 08             	mov    0x8(%ebp),%eax
c0106496:	25 ff 0f 00 00       	and    $0xfff,%eax
c010649b:	85 c0                	test   %eax,%eax
c010649d:	75 7f                	jne    c010651e <kfree+0xa2>
		/* might be on the big block list */
		spin_lock_irqsave(&block_lock, flags);
c010649f:	e8 ba f9 ff ff       	call   c0105e5e <__intr_save>
c01064a4:	89 45 ec             	mov    %eax,-0x14(%ebp)
		for (bb = bigblocks; bb; last = &bb->next, bb = bb->next) {
c01064a7:	a1 10 90 12 c0       	mov    0xc0129010,%eax
c01064ac:	89 45 f4             	mov    %eax,-0xc(%ebp)
c01064af:	eb 5c                	jmp    c010650d <kfree+0x91>
			if (bb->pages == block) {
c01064b1:	8b 45 f4             	mov    -0xc(%ebp),%eax
c01064b4:	8b 40 04             	mov    0x4(%eax),%eax
c01064b7:	39 45 08             	cmp    %eax,0x8(%ebp)
c01064ba:	75 3f                	jne    c01064fb <kfree+0x7f>
				*last = bb->next;
c01064bc:	8b 45 f4             	mov    -0xc(%ebp),%eax
c01064bf:	8b 50 08             	mov    0x8(%eax),%edx
c01064c2:	8b 45 f0             	mov    -0x10(%ebp),%eax
c01064c5:	89 10                	mov    %edx,(%eax)
				spin_unlock_irqrestore(&block_lock, flags);
c01064c7:	8b 45 ec             	mov    -0x14(%ebp),%eax
c01064ca:	89 04 24             	mov    %eax,(%esp)
c01064cd:	e8 b6 f9 ff ff       	call   c0105e88 <__intr_restore>
				__slob_free_pages((unsigned long)block, bb->order);
c01064d2:	8b 45 f4             	mov    -0xc(%ebp),%eax
c01064d5:	8b 10                	mov    (%eax),%edx
c01064d7:	8b 45 08             	mov    0x8(%ebp),%eax
c01064da:	89 54 24 04          	mov    %edx,0x4(%esp)
c01064de:	89 04 24             	mov    %eax,(%esp)
c01064e1:	e8 fb fa ff ff       	call   c0105fe1 <__slob_free_pages>
				slob_free(bb, sizeof(bigblock_t));
c01064e6:	c7 44 24 04 0c 00 00 	movl   $0xc,0x4(%esp)
c01064ed:	00 
c01064ee:	8b 45 f4             	mov    -0xc(%ebp),%eax
c01064f1:	89 04 24             	mov    %eax,(%esp)
c01064f4:	e8 f2 fc ff ff       	call   c01061eb <slob_free>
				return;
c01064f9:	eb 3d                	jmp    c0106538 <kfree+0xbc>
		for (bb = bigblocks; bb; last = &bb->next, bb = bb->next) {
c01064fb:	8b 45 f4             	mov    -0xc(%ebp),%eax
c01064fe:	83 c0 08             	add    $0x8,%eax
c0106501:	89 45 f0             	mov    %eax,-0x10(%ebp)
c0106504:	8b 45 f4             	mov    -0xc(%ebp),%eax
c0106507:	8b 40 08             	mov    0x8(%eax),%eax
c010650a:	89 45 f4             	mov    %eax,-0xc(%ebp)
c010650d:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
c0106511:	75 9e                	jne    c01064b1 <kfree+0x35>
			}
		}
		spin_unlock_irqrestore(&block_lock, flags);
c0106513:	8b 45 ec             	mov    -0x14(%ebp),%eax
c0106516:	89 04 24             	mov    %eax,(%esp)
c0106519:	e8 6a f9 ff ff       	call   c0105e88 <__intr_restore>
	}

	slob_free((slob_t *)block - 1, 0);
c010651e:	8b 45 08             	mov    0x8(%ebp),%eax
c0106521:	83 e8 08             	sub    $0x8,%eax
c0106524:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
c010652b:	00 
c010652c:	89 04 24             	mov    %eax,(%esp)
c010652f:	e8 b7 fc ff ff       	call   c01061eb <slob_free>
	return;
c0106534:	90                   	nop
c0106535:	eb 01                	jmp    c0106538 <kfree+0xbc>
		return;
c0106537:	90                   	nop
}
c0106538:	c9                   	leave  
c0106539:	c3                   	ret    

c010653a <ksize>:


unsigned int ksize(const void *block)
{
c010653a:	55                   	push   %ebp
c010653b:	89 e5                	mov    %esp,%ebp
c010653d:	83 ec 28             	sub    $0x28,%esp
	bigblock_t *bb;
	unsigned long flags;

	if (!block)
c0106540:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
c0106544:	75 07                	jne    c010654d <ksize+0x13>
		return 0;
c0106546:	b8 00 00 00 00       	mov    $0x0,%eax
c010654b:	eb 6b                	jmp    c01065b8 <ksize+0x7e>

	if (!((unsigned long)block & (PAGE_SIZE-1))) {
c010654d:	8b 45 08             	mov    0x8(%ebp),%eax
c0106550:	25 ff 0f 00 00       	and    $0xfff,%eax
c0106555:	85 c0                	test   %eax,%eax
c0106557:	75 54                	jne    c01065ad <ksize+0x73>
		spin_lock_irqsave(&block_lock, flags);
c0106559:	e8 00 f9 ff ff       	call   c0105e5e <__intr_save>
c010655e:	89 45 f0             	mov    %eax,-0x10(%ebp)
		for (bb = bigblocks; bb; bb = bb->next)
c0106561:	a1 10 90 12 c0       	mov    0xc0129010,%eax
c0106566:	89 45 f4             	mov    %eax,-0xc(%ebp)
c0106569:	eb 31                	jmp    c010659c <ksize+0x62>
			if (bb->pages == block) {
c010656b:	8b 45 f4             	mov    -0xc(%ebp),%eax
c010656e:	8b 40 04             	mov    0x4(%eax),%eax
c0106571:	39 45 08             	cmp    %eax,0x8(%ebp)
c0106574:	75 1d                	jne    c0106593 <ksize+0x59>
				spin_unlock_irqrestore(&slob_lock, flags);
c0106576:	8b 45 f0             	mov    -0x10(%ebp),%eax
c0106579:	89 04 24             	mov    %eax,(%esp)
c010657c:	e8 07 f9 ff ff       	call   c0105e88 <__intr_restore>
				return PAGE_SIZE << bb->order;
c0106581:	8b 45 f4             	mov    -0xc(%ebp),%eax
c0106584:	8b 00                	mov    (%eax),%eax
c0106586:	ba 00 10 00 00       	mov    $0x1000,%edx
c010658b:	88 c1                	mov    %al,%cl
c010658d:	d3 e2                	shl    %cl,%edx
c010658f:	89 d0                	mov    %edx,%eax
c0106591:	eb 25                	jmp    c01065b8 <ksize+0x7e>
		for (bb = bigblocks; bb; bb = bb->next)
c0106593:	8b 45 f4             	mov    -0xc(%ebp),%eax
c0106596:	8b 40 08             	mov    0x8(%eax),%eax
c0106599:	89 45 f4             	mov    %eax,-0xc(%ebp)
c010659c:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
c01065a0:	75 c9                	jne    c010656b <ksize+0x31>
			}
		spin_unlock_irqrestore(&block_lock, flags);
c01065a2:	8b 45 f0             	mov    -0x10(%ebp),%eax
c01065a5:	89 04 24             	mov    %eax,(%esp)
c01065a8:	e8 db f8 ff ff       	call   c0105e88 <__intr_restore>
	}

	return ((slob_t *)block - 1)->units * SLOB_UNIT;
c01065ad:	8b 45 08             	mov    0x8(%ebp),%eax
c01065b0:	83 e8 08             	sub    $0x8,%eax
c01065b3:	8b 00                	mov    (%eax),%eax
c01065b5:	c1 e0 03             	shl    $0x3,%eax
}
c01065b8:	c9                   	leave  
c01065b9:	c3                   	ret    

c01065ba <pa2page>:
pa2page(uintptr_t pa) {
c01065ba:	55                   	push   %ebp
c01065bb:	89 e5                	mov    %esp,%ebp
c01065bd:	83 ec 18             	sub    $0x18,%esp
    if (PPN(pa) >= npage) {
c01065c0:	8b 45 08             	mov    0x8(%ebp),%eax
c01065c3:	c1 e8 0c             	shr    $0xc,%eax
c01065c6:	89 c2                	mov    %eax,%edx
c01065c8:	a1 80 8f 12 c0       	mov    0xc0128f80,%eax
c01065cd:	39 c2                	cmp    %eax,%edx
c01065cf:	72 1c                	jb     c01065ed <pa2page+0x33>
        panic("pa2page called with invalid pa");
c01065d1:	c7 44 24 08 14 b4 10 	movl   $0xc010b414,0x8(%esp)
c01065d8:	c0 
c01065d9:	c7 44 24 04 5f 00 00 	movl   $0x5f,0x4(%esp)
c01065e0:	00 
c01065e1:	c7 04 24 33 b4 10 c0 	movl   $0xc010b433,(%esp)
c01065e8:	e8 13 9e ff ff       	call   c0100400 <__panic>
    return &pages[PPN(pa)];   //pages+pa高20bit索引位 摒弃低12bit全0
c01065ed:	a1 60 b0 12 c0       	mov    0xc012b060,%eax
c01065f2:	8b 55 08             	mov    0x8(%ebp),%edx
c01065f5:	c1 ea 0c             	shr    $0xc,%edx
c01065f8:	c1 e2 05             	shl    $0x5,%edx
c01065fb:	01 d0                	add    %edx,%eax
}
c01065fd:	c9                   	leave  
c01065fe:	c3                   	ret    

c01065ff <pte2page>:
pte2page(pte_t pte) {
c01065ff:	55                   	push   %ebp
c0106600:	89 e5                	mov    %esp,%ebp
c0106602:	83 ec 18             	sub    $0x18,%esp
    if (!(pte & PTE_P)) {
c0106605:	8b 45 08             	mov    0x8(%ebp),%eax
c0106608:	83 e0 01             	and    $0x1,%eax
c010660b:	85 c0                	test   %eax,%eax
c010660d:	75 1c                	jne    c010662b <pte2page+0x2c>
        panic("pte2page called with invalid pte");
c010660f:	c7 44 24 08 44 b4 10 	movl   $0xc010b444,0x8(%esp)
c0106616:	c0 
c0106617:	c7 44 24 04 71 00 00 	movl   $0x71,0x4(%esp)
c010661e:	00 
c010661f:	c7 04 24 33 b4 10 c0 	movl   $0xc010b433,(%esp)
c0106626:	e8 d5 9d ff ff       	call   c0100400 <__panic>
    return pa2page(PTE_ADDR(pte));   //pte的高20bit+12bit全0
c010662b:	8b 45 08             	mov    0x8(%ebp),%eax
c010662e:	25 00 f0 ff ff       	and    $0xfffff000,%eax
c0106633:	89 04 24             	mov    %eax,(%esp)
c0106636:	e8 7f ff ff ff       	call   c01065ba <pa2page>
}
c010663b:	c9                   	leave  
c010663c:	c3                   	ret    

c010663d <swap_init>:

static void check_swap(void);      //练习二最终check

int
swap_init(void)
{
c010663d:	55                   	push   %ebp
c010663e:	89 e5                	mov    %esp,%ebp
c0106640:	83 ec 28             	sub    $0x28,%esp
     swapfs_init();      //fs.c：看下这个设备能放几个页（不常用的数据放在磁盘）max_swap_offset = ide_device_size(SWAP_DEV_NO) / (PGSIZE / SECTSIZE); 
c0106643:	e8 de 1d 00 00       	call   c0108426 <swapfs_init>

     if (!(1024 <= max_swap_offset && max_swap_offset < MAX_SWAP_OFFSET_LIMIT))      //[  1024~   (1 << 24)  )     扇区号=页号（off）*8  8=4KB/512B
c0106648:	a1 1c b1 12 c0       	mov    0xc012b11c,%eax
c010664d:	3d ff 03 00 00       	cmp    $0x3ff,%eax
c0106652:	76 0c                	jbe    c0106660 <swap_init+0x23>
c0106654:	a1 1c b1 12 c0       	mov    0xc012b11c,%eax
c0106659:	3d ff ff ff 00       	cmp    $0xffffff,%eax
c010665e:	76 25                	jbe    c0106685 <swap_init+0x48>
     {
          panic("bad max_swap_offset %08x.\n", max_swap_offset);
c0106660:	a1 1c b1 12 c0       	mov    0xc012b11c,%eax
c0106665:	89 44 24 0c          	mov    %eax,0xc(%esp)
c0106669:	c7 44 24 08 65 b4 10 	movl   $0xc010b465,0x8(%esp)
c0106670:	c0 
c0106671:	c7 44 24 04 25 00 00 	movl   $0x25,0x4(%esp)
c0106678:	00 
c0106679:	c7 04 24 80 b4 10 c0 	movl   $0xc010b480,(%esp)
c0106680:	e8 7b 9d ff ff       	call   c0100400 <__panic>
     }
     

     sm = &swap_manager_fifo;           //更换页替换算法
c0106685:	c7 05 1c 90 12 c0 40 	movl   $0xc0125a40,0xc012901c
c010668c:	5a 12 c0 
     int r = sm->init();      //fifo啥事不干返回0
c010668f:	a1 1c 90 12 c0       	mov    0xc012901c,%eax
c0106694:	8b 40 04             	mov    0x4(%eax),%eax
c0106697:	ff d0                	call   *%eax
c0106699:	89 45 f4             	mov    %eax,-0xc(%ebp)
     
     if (r == 0)
c010669c:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
c01066a0:	75 26                	jne    c01066c8 <swap_init+0x8b>
     {
          swap_init_ok = 1;
c01066a2:	c7 05 14 90 12 c0 01 	movl   $0x1,0xc0129014
c01066a9:	00 00 00 
          cprintf("SWAP: manager = %s\n", sm->name);
c01066ac:	a1 1c 90 12 c0       	mov    0xc012901c,%eax
c01066b1:	8b 00                	mov    (%eax),%eax
c01066b3:	89 44 24 04          	mov    %eax,0x4(%esp)
c01066b7:	c7 04 24 8f b4 10 c0 	movl   $0xc010b48f,(%esp)
c01066be:	e8 e6 9b ff ff       	call   c01002a9 <cprintf>
          check_swap();
c01066c3:	e8 9e 04 00 00       	call   c0106b66 <check_swap>
     }

     return r;
c01066c8:	8b 45 f4             	mov    -0xc(%ebp),%eax
}
c01066cb:	c9                   	leave  
c01066cc:	c3                   	ret    

c01066cd <swap_init_mm>:

int
swap_init_mm(struct mm_struct *mm)
{
c01066cd:	55                   	push   %ebp
c01066ce:	89 e5                	mov    %esp,%ebp
c01066d0:	83 ec 18             	sub    $0x18,%esp
     return sm->init_mm(mm);  //priv初始化
c01066d3:	a1 1c 90 12 c0       	mov    0xc012901c,%eax
c01066d8:	8b 40 08             	mov    0x8(%eax),%eax
c01066db:	8b 55 08             	mov    0x8(%ebp),%edx
c01066de:	89 14 24             	mov    %edx,(%esp)
c01066e1:	ff d0                	call   *%eax
}
c01066e3:	c9                   	leave  
c01066e4:	c3                   	ret    

c01066e5 <swap_tick_event>:

int
swap_tick_event(struct mm_struct *mm)
{
c01066e5:	55                   	push   %ebp
c01066e6:	89 e5                	mov    %esp,%ebp
c01066e8:	83 ec 18             	sub    $0x18,%esp
     return sm->tick_event(mm); //fifo啥事不干返回0
c01066eb:	a1 1c 90 12 c0       	mov    0xc012901c,%eax
c01066f0:	8b 40 0c             	mov    0xc(%eax),%eax
c01066f3:	8b 55 08             	mov    0x8(%ebp),%edx
c01066f6:	89 14 24             	mov    %edx,(%esp)
c01066f9:	ff d0                	call   *%eax
}
c01066fb:	c9                   	leave  
c01066fc:	c3                   	ret    

c01066fd <swap_map_swappable>:

int
swap_map_swappable(struct mm_struct *mm, uintptr_t addr, struct Page *page, int swap_in)
{
c01066fd:	55                   	push   %ebp
c01066fe:	89 e5                	mov    %esp,%ebp
c0106700:	83 ec 18             	sub    $0x18,%esp
     return sm->map_swappable(mm, addr, page, swap_in);      //fifo把这个参数page插队列里
c0106703:	a1 1c 90 12 c0       	mov    0xc012901c,%eax
c0106708:	8b 40 10             	mov    0x10(%eax),%eax
c010670b:	8b 55 14             	mov    0x14(%ebp),%edx
c010670e:	89 54 24 0c          	mov    %edx,0xc(%esp)
c0106712:	8b 55 10             	mov    0x10(%ebp),%edx
c0106715:	89 54 24 08          	mov    %edx,0x8(%esp)
c0106719:	8b 55 0c             	mov    0xc(%ebp),%edx
c010671c:	89 54 24 04          	mov    %edx,0x4(%esp)
c0106720:	8b 55 08             	mov    0x8(%ebp),%edx
c0106723:	89 14 24             	mov    %edx,(%esp)
c0106726:	ff d0                	call   *%eax
}
c0106728:	c9                   	leave  
c0106729:	c3                   	ret    

c010672a <swap_set_unswappable>:

int
swap_set_unswappable(struct mm_struct *mm, uintptr_t addr)
{
c010672a:	55                   	push   %ebp
c010672b:	89 e5                	mov    %esp,%ebp
c010672d:	83 ec 18             	sub    $0x18,%esp
     return sm->set_unswappable(mm, addr);   //fifo啥事不干返回0
c0106730:	a1 1c 90 12 c0       	mov    0xc012901c,%eax
c0106735:	8b 40 14             	mov    0x14(%eax),%eax
c0106738:	8b 55 0c             	mov    0xc(%ebp),%edx
c010673b:	89 54 24 04          	mov    %edx,0x4(%esp)
c010673f:	8b 55 08             	mov    0x8(%ebp),%edx
c0106742:	89 14 24             	mov    %edx,(%esp)
c0106745:	ff d0                	call   *%eax
}
c0106747:	c9                   	leave  
c0106748:	c3                   	ret    

c0106749 <swap_out>:

volatile unsigned int swap_out_num=0;

int
swap_out(struct mm_struct *mm, int n, int in_tick)     //swap_out(check_mm_struct, n, 0); 在allocpage里面（消极）n为需要分配的页数
{
c0106749:	55                   	push   %ebp
c010674a:	89 e5                	mov    %esp,%ebp
c010674c:	83 ec 38             	sub    $0x38,%esp
     int i;
     for (i = 0; i != n; ++ i)
c010674f:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
c0106756:	e9 53 01 00 00       	jmp    c01068ae <swap_out+0x165>
     {
          uintptr_t v;
          //struct Page **ptr_page=NULL;
          struct Page *page;
          // cprintf("i %d, SWAP: call swap_out_victim\n",i);
          int r = sm->swap_out_victim(mm, &page, in_tick);                      //1.剔除表尾，page被复制为表尾项对应的page（被换出的页）
c010675b:	a1 1c 90 12 c0       	mov    0xc012901c,%eax
c0106760:	8b 40 18             	mov    0x18(%eax),%eax
c0106763:	8b 55 10             	mov    0x10(%ebp),%edx
c0106766:	89 54 24 08          	mov    %edx,0x8(%esp)
c010676a:	8d 55 e4             	lea    -0x1c(%ebp),%edx
c010676d:	89 54 24 04          	mov    %edx,0x4(%esp)
c0106771:	8b 55 08             	mov    0x8(%ebp),%edx
c0106774:	89 14 24             	mov    %edx,(%esp)
c0106777:	ff d0                	call   *%eax
c0106779:	89 45 f0             	mov    %eax,-0x10(%ebp)
          if (r != 0) {
c010677c:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
c0106780:	74 18                	je     c010679a <swap_out+0x51>
                    cprintf("i %d, swap_out: call swap_out_victim failed\n",i);
c0106782:	8b 45 f4             	mov    -0xc(%ebp),%eax
c0106785:	89 44 24 04          	mov    %eax,0x4(%esp)
c0106789:	c7 04 24 a4 b4 10 c0 	movl   $0xc010b4a4,(%esp)
c0106790:	e8 14 9b ff ff       	call   c01002a9 <cprintf>
c0106795:	e9 20 01 00 00       	jmp    c01068ba <swap_out+0x171>
          }          
          //assert(!PageReserved(page));

          //cprintf("SWAP: choose victim page 0x%08x\n", page);
          //2.要把被换出页的内容写进磁盘里去
          v=page->pra_vaddr;       //2.1被换出页的虚拟页起始处 ，
c010679a:	8b 45 e4             	mov    -0x1c(%ebp),%eax
c010679d:	8b 40 1c             	mov    0x1c(%eax),%eax
c01067a0:	89 45 ec             	mov    %eax,-0x14(%ebp)
          pte_t *ptep = get_pte(mm->pgdir, v, 0);      //2.2找到对应pte
c01067a3:	8b 45 08             	mov    0x8(%ebp),%eax
c01067a6:	8b 40 0c             	mov    0xc(%eax),%eax
c01067a9:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
c01067b0:	00 
c01067b1:	8b 55 ec             	mov    -0x14(%ebp),%edx
c01067b4:	89 54 24 04          	mov    %edx,0x4(%esp)
c01067b8:	89 04 24             	mov    %eax,(%esp)
c01067bb:	e8 6f d3 ff ff       	call   c0103b2f <get_pte>
c01067c0:	89 45 e8             	mov    %eax,-0x18(%ebp)
          assert((*ptep & PTE_P) != 0);                //最后一位PTE_P这里还是为1，表示还在物理内存！
c01067c3:	8b 45 e8             	mov    -0x18(%ebp),%eax
c01067c6:	8b 00                	mov    (%eax),%eax
c01067c8:	83 e0 01             	and    $0x1,%eax
c01067cb:	85 c0                	test   %eax,%eax
c01067cd:	75 24                	jne    c01067f3 <swap_out+0xaa>
c01067cf:	c7 44 24 0c d1 b4 10 	movl   $0xc010b4d1,0xc(%esp)
c01067d6:	c0 
c01067d7:	c7 44 24 08 e6 b4 10 	movl   $0xc010b4e6,0x8(%esp)
c01067de:	c0 
c01067df:	c7 44 24 04 65 00 00 	movl   $0x65,0x4(%esp)
c01067e6:	00 
c01067e7:	c7 04 24 80 b4 10 c0 	movl   $0xc010b480,(%esp)
c01067ee:	e8 0d 9c ff ff       	call   c0100400 <__panic>
          //3.执行写被换出页到磁盘 //被换出页的起始址addr对应的pte，前20位为页号，乘8得到读取的扇区号；在这个扇区起的8个扇区，把换出的page写进去
          if (swapfs_write( (page->pra_vaddr/PGSIZE+1)<<8, page) != 0) {   //swapfs_write(swap_entry_t entry, struct Page *page)  return ide_write_secs(SWAP_DEV_NO, swap_offset(entry) * PAGE_NSECT, page2kva(page), PAGE_NSECT); 
c01067f3:	8b 45 e4             	mov    -0x1c(%ebp),%eax
c01067f6:	8b 55 e4             	mov    -0x1c(%ebp),%edx
c01067f9:	8b 52 1c             	mov    0x1c(%edx),%edx
c01067fc:	c1 ea 0c             	shr    $0xc,%edx
c01067ff:	42                   	inc    %edx
c0106800:	c1 e2 08             	shl    $0x8,%edx
c0106803:	89 44 24 04          	mov    %eax,0x4(%esp)
c0106807:	89 14 24             	mov    %edx,(%esp)
c010680a:	e8 d2 1c 00 00       	call   c01084e1 <swapfs_write>
c010680f:	85 c0                	test   %eax,%eax
c0106811:	74 34                	je     c0106847 <swap_out+0xfe>
                    cprintf("SWAP: failed to save\n");
c0106813:	c7 04 24 fb b4 10 c0 	movl   $0xc010b4fb,(%esp)
c010681a:	e8 8a 9a ff ff       	call   c01002a9 <cprintf>
                    sm->map_swappable(mm, v, page, 0);      //如果写失败，恢复剔除前状态，即加回去
c010681f:	a1 1c 90 12 c0       	mov    0xc012901c,%eax
c0106824:	8b 40 10             	mov    0x10(%eax),%eax
c0106827:	8b 55 e4             	mov    -0x1c(%ebp),%edx
c010682a:	c7 44 24 0c 00 00 00 	movl   $0x0,0xc(%esp)
c0106831:	00 
c0106832:	89 54 24 08          	mov    %edx,0x8(%esp)
c0106836:	8b 55 ec             	mov    -0x14(%ebp),%edx
c0106839:	89 54 24 04          	mov    %edx,0x4(%esp)
c010683d:	8b 55 08             	mov    0x8(%ebp),%edx
c0106840:	89 14 24             	mov    %edx,(%esp)
c0106843:	ff d0                	call   *%eax
c0106845:	eb 64                	jmp    c01068ab <swap_out+0x162>
                    continue;
          }
          else {
                    cprintf("swap_out: i %d, store page in vaddr 0x%x to disk swap entry %d\n", i, v, page->pra_vaddr/PGSIZE+1);
c0106847:	8b 45 e4             	mov    -0x1c(%ebp),%eax
c010684a:	8b 40 1c             	mov    0x1c(%eax),%eax
c010684d:	c1 e8 0c             	shr    $0xc,%eax
c0106850:	40                   	inc    %eax
c0106851:	89 44 24 0c          	mov    %eax,0xc(%esp)
c0106855:	8b 45 ec             	mov    -0x14(%ebp),%eax
c0106858:	89 44 24 08          	mov    %eax,0x8(%esp)
c010685c:	8b 45 f4             	mov    -0xc(%ebp),%eax
c010685f:	89 44 24 04          	mov    %eax,0x4(%esp)
c0106863:	c7 04 24 14 b5 10 c0 	movl   $0xc010b514,(%esp)
c010686a:	e8 3a 9a ff ff       	call   c01002a9 <cprintf>
                    *ptep = (page->pra_vaddr/PGSIZE+1)<<8;  //页表项就是这个被换出的页对应的vaddr/12，左移8，生成了swap_entry_t的格式，最后一位PTE_P当然变成0了，不在物理内存！！！
c010686f:	8b 45 e4             	mov    -0x1c(%ebp),%eax
c0106872:	8b 40 1c             	mov    0x1c(%eax),%eax
c0106875:	c1 e8 0c             	shr    $0xc,%eax
c0106878:	40                   	inc    %eax
c0106879:	c1 e0 08             	shl    $0x8,%eax
c010687c:	89 c2                	mov    %eax,%edx
c010687e:	8b 45 e8             	mov    -0x18(%ebp),%eax
c0106881:	89 10                	mov    %edx,(%eax)
                    free_page(page);    //释放一个页，看分配几个页咯
c0106883:	8b 45 e4             	mov    -0x1c(%ebp),%eax
c0106886:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
c010688d:	00 
c010688e:	89 04 24             	mov    %eax,(%esp)
c0106891:	e8 24 cc ff ff       	call   c01034ba <free_pages>
          }
          
          tlb_invalidate(mm->pgdir, v); //更新tlb，访问了这个被换出页的va
c0106896:	8b 45 08             	mov    0x8(%ebp),%eax
c0106899:	8b 40 0c             	mov    0xc(%eax),%eax
c010689c:	8b 55 ec             	mov    -0x14(%ebp),%edx
c010689f:	89 54 24 04          	mov    %edx,0x4(%esp)
c01068a3:	89 04 24             	mov    %eax,(%esp)
c01068a6:	e8 76 d5 ff ff       	call   c0103e21 <tlb_invalidate>
     for (i = 0; i != n; ++ i)
c01068ab:	ff 45 f4             	incl   -0xc(%ebp)
c01068ae:	8b 45 f4             	mov    -0xc(%ebp),%eax
c01068b1:	3b 45 0c             	cmp    0xc(%ebp),%eax
c01068b4:	0f 85 a1 fe ff ff    	jne    c010675b <swap_out+0x12>
     }
     return i;
c01068ba:	8b 45 f4             	mov    -0xc(%ebp),%eax
}
c01068bd:	c9                   	leave  
c01068be:	c3                   	ret    

c01068bf <swap_in>:

int
swap_in(struct mm_struct *mm, uintptr_t addr, struct Page **ptr_result)    //练习一的else：swap_in(mm, addr, &page)) != 0
{
c01068bf:	55                   	push   %ebp
c01068c0:	89 e5                	mov    %esp,%ebp
c01068c2:	83 ec 28             	sub    $0x28,%esp
     struct Page *result = alloc_page();
c01068c5:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
c01068cc:	e8 7e cb ff ff       	call   c010344f <alloc_pages>
c01068d1:	89 45 f4             	mov    %eax,-0xc(%ebp)
     assert(result!=NULL);
c01068d4:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
c01068d8:	75 24                	jne    c01068fe <swap_in+0x3f>
c01068da:	c7 44 24 0c 54 b5 10 	movl   $0xc010b554,0xc(%esp)
c01068e1:	c0 
c01068e2:	c7 44 24 08 e6 b4 10 	movl   $0xc010b4e6,0x8(%esp)
c01068e9:	c0 
c01068ea:	c7 44 24 04 7b 00 00 	movl   $0x7b,0x4(%esp)
c01068f1:	00 
c01068f2:	c7 04 24 80 b4 10 c0 	movl   $0xc010b480,(%esp)
c01068f9:	e8 02 9b ff ff       	call   c0100400 <__panic>

     pte_t *ptep = get_pte(mm->pgdir, addr, 0);   //这里的pte一定有值，因为之前是建立过映射的，否则不可能进练习一的else
c01068fe:	8b 45 08             	mov    0x8(%ebp),%eax
c0106901:	8b 40 0c             	mov    0xc(%eax),%eax
c0106904:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
c010690b:	00 
c010690c:	8b 55 0c             	mov    0xc(%ebp),%edx
c010690f:	89 54 24 04          	mov    %edx,0x4(%esp)
c0106913:	89 04 24             	mov    %eax,(%esp)
c0106916:	e8 14 d2 ff ff       	call   c0103b2f <get_pte>
c010691b:	89 45 f0             	mov    %eax,-0x10(%ebp)
     // cprintf("SWAP: load ptep %x swap entry %d to vaddr 0x%08x, page %x, No %d\n", ptep, (*ptep)>>8, addr, result, (result-pages));
    
     int r;    //之前建立过映射的addr对应的pte，前24位为页号，乘8得到读取的扇区号；从磁盘中读取8个扇区到这个result的page里面
     if ((r = swapfs_read((*ptep), result)) != 0)  //swapfs_read(swap_entry_t entry, struct Page *page)  return ide_read_secs(SWAP_DEV_NO, swap_offset(entry) * PAGE_NSECT, page2kva(page), PAGE_NSECT); 
c010691e:	8b 45 f0             	mov    -0x10(%ebp),%eax
c0106921:	8b 00                	mov    (%eax),%eax
c0106923:	8b 55 f4             	mov    -0xc(%ebp),%edx
c0106926:	89 54 24 04          	mov    %edx,0x4(%esp)
c010692a:	89 04 24             	mov    %eax,(%esp)
c010692d:	e8 3d 1b 00 00       	call   c010846f <swapfs_read>
c0106932:	89 45 ec             	mov    %eax,-0x14(%ebp)
c0106935:	83 7d ec 00          	cmpl   $0x0,-0x14(%ebp)
c0106939:	74 2a                	je     c0106965 <swap_in+0xa6>
     {
        assert(r!=0);
c010693b:	83 7d ec 00          	cmpl   $0x0,-0x14(%ebp)
c010693f:	75 24                	jne    c0106965 <swap_in+0xa6>
c0106941:	c7 44 24 0c 61 b5 10 	movl   $0xc010b561,0xc(%esp)
c0106948:	c0 
c0106949:	c7 44 24 08 e6 b4 10 	movl   $0xc010b4e6,0x8(%esp)
c0106950:	c0 
c0106951:	c7 44 24 04 83 00 00 	movl   $0x83,0x4(%esp)
c0106958:	00 
c0106959:	c7 04 24 80 b4 10 c0 	movl   $0xc010b480,(%esp)
c0106960:	e8 9b 9a ff ff       	call   c0100400 <__panic>
     }
     cprintf("swap_in: load disk swap entry %d with swap_page in vadr 0x%x\n", (*ptep)>>8, addr);
c0106965:	8b 45 f0             	mov    -0x10(%ebp),%eax
c0106968:	8b 00                	mov    (%eax),%eax
c010696a:	c1 e8 08             	shr    $0x8,%eax
c010696d:	89 c2                	mov    %eax,%edx
c010696f:	8b 45 0c             	mov    0xc(%ebp),%eax
c0106972:	89 44 24 08          	mov    %eax,0x8(%esp)
c0106976:	89 54 24 04          	mov    %edx,0x4(%esp)
c010697a:	c7 04 24 68 b5 10 c0 	movl   $0xc010b568,(%esp)
c0106981:	e8 23 99 ff ff       	call   c01002a9 <cprintf>
     *ptr_result=result;      //把result返回给实参page
c0106986:	8b 45 10             	mov    0x10(%ebp),%eax
c0106989:	8b 55 f4             	mov    -0xc(%ebp),%edx
c010698c:	89 10                	mov    %edx,(%eax)
     return 0;
c010698e:	b8 00 00 00 00       	mov    $0x0,%eax
}
c0106993:	c9                   	leave  
c0106994:	c3                   	ret    

c0106995 <check_content_set>:



static inline void
check_content_set(void)
{
c0106995:	55                   	push   %ebp
c0106996:	89 e5                	mov    %esp,%ebp
c0106998:	83 ec 18             	sub    $0x18,%esp
     *(unsigned char *)0x1000 = 0x0a;             //分别对起始地址为0x1000, 0x2000, 0x3000, 0x4000的虚拟页（一个页size为0x1000）按时间顺序先后执行写操作
c010699b:	b8 00 10 00 00       	mov    $0x1000,%eax
c01069a0:	c6 00 0a             	movb   $0xa,(%eax)
     assert(pgfault_num==1);                      //vmm.c的全局变量，在do_pgfault里++；由于之前没有建立页表，所以会产生page fault异常
c01069a3:	a1 0c 90 12 c0       	mov    0xc012900c,%eax
c01069a8:	83 f8 01             	cmp    $0x1,%eax
c01069ab:	74 24                	je     c01069d1 <check_content_set+0x3c>
c01069ad:	c7 44 24 0c a6 b5 10 	movl   $0xc010b5a6,0xc(%esp)
c01069b4:	c0 
c01069b5:	c7 44 24 08 e6 b4 10 	movl   $0xc010b4e6,0x8(%esp)
c01069bc:	c0 
c01069bd:	c7 44 24 04 90 00 00 	movl   $0x90,0x4(%esp)
c01069c4:	00 
c01069c5:	c7 04 24 80 b4 10 c0 	movl   $0xc010b480,(%esp)
c01069cc:	e8 2f 9a ff ff       	call   c0100400 <__panic>
     *(unsigned char *)0x1010 = 0x0a;             
c01069d1:	b8 10 10 00 00       	mov    $0x1010,%eax
c01069d6:	c6 00 0a             	movb   $0xa,(%eax)
     assert(pgfault_num==1);
c01069d9:	a1 0c 90 12 c0       	mov    0xc012900c,%eax
c01069de:	83 f8 01             	cmp    $0x1,%eax
c01069e1:	74 24                	je     c0106a07 <check_content_set+0x72>
c01069e3:	c7 44 24 0c a6 b5 10 	movl   $0xc010b5a6,0xc(%esp)
c01069ea:	c0 
c01069eb:	c7 44 24 08 e6 b4 10 	movl   $0xc010b4e6,0x8(%esp)
c01069f2:	c0 
c01069f3:	c7 44 24 04 92 00 00 	movl   $0x92,0x4(%esp)
c01069fa:	00 
c01069fb:	c7 04 24 80 b4 10 c0 	movl   $0xc010b480,(%esp)
c0106a02:	e8 f9 99 ff ff       	call   c0100400 <__panic>
     *(unsigned char *)0x2000 = 0x0b;             //第二个页
c0106a07:	b8 00 20 00 00       	mov    $0x2000,%eax
c0106a0c:	c6 00 0b             	movb   $0xb,(%eax)
     assert(pgfault_num==2);
c0106a0f:	a1 0c 90 12 c0       	mov    0xc012900c,%eax
c0106a14:	83 f8 02             	cmp    $0x2,%eax
c0106a17:	74 24                	je     c0106a3d <check_content_set+0xa8>
c0106a19:	c7 44 24 0c b5 b5 10 	movl   $0xc010b5b5,0xc(%esp)
c0106a20:	c0 
c0106a21:	c7 44 24 08 e6 b4 10 	movl   $0xc010b4e6,0x8(%esp)
c0106a28:	c0 
c0106a29:	c7 44 24 04 94 00 00 	movl   $0x94,0x4(%esp)
c0106a30:	00 
c0106a31:	c7 04 24 80 b4 10 c0 	movl   $0xc010b480,(%esp)
c0106a38:	e8 c3 99 ff ff       	call   c0100400 <__panic>
     *(unsigned char *)0x2010 = 0x0b;
c0106a3d:	b8 10 20 00 00       	mov    $0x2010,%eax
c0106a42:	c6 00 0b             	movb   $0xb,(%eax)
     assert(pgfault_num==2);
c0106a45:	a1 0c 90 12 c0       	mov    0xc012900c,%eax
c0106a4a:	83 f8 02             	cmp    $0x2,%eax
c0106a4d:	74 24                	je     c0106a73 <check_content_set+0xde>
c0106a4f:	c7 44 24 0c b5 b5 10 	movl   $0xc010b5b5,0xc(%esp)
c0106a56:	c0 
c0106a57:	c7 44 24 08 e6 b4 10 	movl   $0xc010b4e6,0x8(%esp)
c0106a5e:	c0 
c0106a5f:	c7 44 24 04 96 00 00 	movl   $0x96,0x4(%esp)
c0106a66:	00 
c0106a67:	c7 04 24 80 b4 10 c0 	movl   $0xc010b480,(%esp)
c0106a6e:	e8 8d 99 ff ff       	call   c0100400 <__panic>
     *(unsigned char *)0x3000 = 0x0c;             //第三个页
c0106a73:	b8 00 30 00 00       	mov    $0x3000,%eax
c0106a78:	c6 00 0c             	movb   $0xc,(%eax)
     assert(pgfault_num==3);
c0106a7b:	a1 0c 90 12 c0       	mov    0xc012900c,%eax
c0106a80:	83 f8 03             	cmp    $0x3,%eax
c0106a83:	74 24                	je     c0106aa9 <check_content_set+0x114>
c0106a85:	c7 44 24 0c c4 b5 10 	movl   $0xc010b5c4,0xc(%esp)
c0106a8c:	c0 
c0106a8d:	c7 44 24 08 e6 b4 10 	movl   $0xc010b4e6,0x8(%esp)
c0106a94:	c0 
c0106a95:	c7 44 24 04 98 00 00 	movl   $0x98,0x4(%esp)
c0106a9c:	00 
c0106a9d:	c7 04 24 80 b4 10 c0 	movl   $0xc010b480,(%esp)
c0106aa4:	e8 57 99 ff ff       	call   c0100400 <__panic>
     *(unsigned char *)0x3010 = 0x0c;
c0106aa9:	b8 10 30 00 00       	mov    $0x3010,%eax
c0106aae:	c6 00 0c             	movb   $0xc,(%eax)
     assert(pgfault_num==3);
c0106ab1:	a1 0c 90 12 c0       	mov    0xc012900c,%eax
c0106ab6:	83 f8 03             	cmp    $0x3,%eax
c0106ab9:	74 24                	je     c0106adf <check_content_set+0x14a>
c0106abb:	c7 44 24 0c c4 b5 10 	movl   $0xc010b5c4,0xc(%esp)
c0106ac2:	c0 
c0106ac3:	c7 44 24 08 e6 b4 10 	movl   $0xc010b4e6,0x8(%esp)
c0106aca:	c0 
c0106acb:	c7 44 24 04 9a 00 00 	movl   $0x9a,0x4(%esp)
c0106ad2:	00 
c0106ad3:	c7 04 24 80 b4 10 c0 	movl   $0xc010b480,(%esp)
c0106ada:	e8 21 99 ff ff       	call   c0100400 <__panic>
     *(unsigned char *)0x4000 = 0x0d;             //第四个页
c0106adf:	b8 00 40 00 00       	mov    $0x4000,%eax
c0106ae4:	c6 00 0d             	movb   $0xd,(%eax)
     assert(pgfault_num==4);
c0106ae7:	a1 0c 90 12 c0       	mov    0xc012900c,%eax
c0106aec:	83 f8 04             	cmp    $0x4,%eax
c0106aef:	74 24                	je     c0106b15 <check_content_set+0x180>
c0106af1:	c7 44 24 0c d3 b5 10 	movl   $0xc010b5d3,0xc(%esp)
c0106af8:	c0 
c0106af9:	c7 44 24 08 e6 b4 10 	movl   $0xc010b4e6,0x8(%esp)
c0106b00:	c0 
c0106b01:	c7 44 24 04 9c 00 00 	movl   $0x9c,0x4(%esp)
c0106b08:	00 
c0106b09:	c7 04 24 80 b4 10 c0 	movl   $0xc010b480,(%esp)
c0106b10:	e8 eb 98 ff ff       	call   c0100400 <__panic>
     *(unsigned char *)0x4010 = 0x0d;             //这些从4KB~20KB的4虚拟页会与ucore保存的4个物理页帧建立映射关系；
c0106b15:	b8 10 40 00 00       	mov    $0x4010,%eax
c0106b1a:	c6 00 0d             	movb   $0xd,(%eax)
     assert(pgfault_num==4);
c0106b1d:	a1 0c 90 12 c0       	mov    0xc012900c,%eax
c0106b22:	83 f8 04             	cmp    $0x4,%eax
c0106b25:	74 24                	je     c0106b4b <check_content_set+0x1b6>
c0106b27:	c7 44 24 0c d3 b5 10 	movl   $0xc010b5d3,0xc(%esp)
c0106b2e:	c0 
c0106b2f:	c7 44 24 08 e6 b4 10 	movl   $0xc010b4e6,0x8(%esp)
c0106b36:	c0 
c0106b37:	c7 44 24 04 9e 00 00 	movl   $0x9e,0x4(%esp)
c0106b3e:	00 
c0106b3f:	c7 04 24 80 b4 10 c0 	movl   $0xc010b480,(%esp)
c0106b46:	e8 b5 98 ff ff       	call   c0100400 <__panic>
}
c0106b4b:	90                   	nop
c0106b4c:	c9                   	leave  
c0106b4d:	c3                   	ret    

c0106b4e <check_content_access>:

static inline int
check_content_access(void)
{
c0106b4e:	55                   	push   %ebp
c0106b4f:	89 e5                	mov    %esp,%ebp
c0106b51:	83 ec 18             	sub    $0x18,%esp
    int ret = sm->check_swap();                   //调用fifio的swap
c0106b54:	a1 1c 90 12 c0       	mov    0xc012901c,%eax
c0106b59:	8b 40 1c             	mov    0x1c(%eax),%eax
c0106b5c:	ff d0                	call   *%eax
c0106b5e:	89 45 f4             	mov    %eax,-0xc(%ebp)
    return ret;
c0106b61:	8b 45 f4             	mov    -0xc(%ebp),%eax
}
c0106b64:	c9                   	leave  
c0106b65:	c3                   	ret    

c0106b66 <check_swap>:
#define free_list (free_area.free_list)
#define nr_free (free_area.nr_free)

static void
check_swap(void)         //init里面调
{
c0106b66:	55                   	push   %ebp
c0106b67:	89 e5                	mov    %esp,%ebp
c0106b69:	83 ec 78             	sub    $0x78,%esp
    //backup mem env
     int ret, count = 0, total = 0, i;
c0106b6c:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
c0106b73:	c7 45 f0 00 00 00 00 	movl   $0x0,-0x10(%ebp)
     list_entry_t *le = &free_list;
c0106b7a:	c7 45 e8 44 b1 12 c0 	movl   $0xc012b144,-0x18(%ebp)
     while ((le = list_next(le)) != &free_list) {
c0106b81:	eb 6a                	jmp    c0106bed <check_swap+0x87>
        struct Page *p = le2page(le, page_link);
c0106b83:	8b 45 e8             	mov    -0x18(%ebp),%eax
c0106b86:	83 e8 0c             	sub    $0xc,%eax
c0106b89:	89 45 c8             	mov    %eax,-0x38(%ebp)
        assert(PageProperty(p));
c0106b8c:	8b 45 c8             	mov    -0x38(%ebp),%eax
c0106b8f:	83 c0 04             	add    $0x4,%eax
c0106b92:	c7 45 c4 01 00 00 00 	movl   $0x1,-0x3c(%ebp)
c0106b99:	89 45 c0             	mov    %eax,-0x40(%ebp)
 * @addr:   the address to count from
 * */
static inline bool
test_bit(int nr, volatile void *addr) {
    int oldbit;
    asm volatile ("btl %2, %1; sbbl %0,%0" : "=r" (oldbit) : "m" (*(volatile long *)addr), "Ir" (nr));
c0106b9c:	8b 45 c0             	mov    -0x40(%ebp),%eax
c0106b9f:	8b 55 c4             	mov    -0x3c(%ebp),%edx
c0106ba2:	0f a3 10             	bt     %edx,(%eax)
c0106ba5:	19 c0                	sbb    %eax,%eax
c0106ba7:	89 45 bc             	mov    %eax,-0x44(%ebp)
    return oldbit != 0;
c0106baa:	83 7d bc 00          	cmpl   $0x0,-0x44(%ebp)
c0106bae:	0f 95 c0             	setne  %al
c0106bb1:	0f b6 c0             	movzbl %al,%eax
c0106bb4:	85 c0                	test   %eax,%eax
c0106bb6:	75 24                	jne    c0106bdc <check_swap+0x76>
c0106bb8:	c7 44 24 0c e2 b5 10 	movl   $0xc010b5e2,0xc(%esp)
c0106bbf:	c0 
c0106bc0:	c7 44 24 08 e6 b4 10 	movl   $0xc010b4e6,0x8(%esp)
c0106bc7:	c0 
c0106bc8:	c7 44 24 04 b9 00 00 	movl   $0xb9,0x4(%esp)
c0106bcf:	00 
c0106bd0:	c7 04 24 80 b4 10 c0 	movl   $0xc010b480,(%esp)
c0106bd7:	e8 24 98 ff ff       	call   c0100400 <__panic>
        count ++, total += p->property;
c0106bdc:	ff 45 f4             	incl   -0xc(%ebp)
c0106bdf:	8b 45 c8             	mov    -0x38(%ebp),%eax
c0106be2:	8b 50 08             	mov    0x8(%eax),%edx
c0106be5:	8b 45 f0             	mov    -0x10(%ebp),%eax
c0106be8:	01 d0                	add    %edx,%eax
c0106bea:	89 45 f0             	mov    %eax,-0x10(%ebp)
c0106bed:	8b 45 e8             	mov    -0x18(%ebp),%eax
c0106bf0:	89 45 b8             	mov    %eax,-0x48(%ebp)
c0106bf3:	8b 45 b8             	mov    -0x48(%ebp),%eax
c0106bf6:	8b 40 04             	mov    0x4(%eax),%eax
     while ((le = list_next(le)) != &free_list) {
c0106bf9:	89 45 e8             	mov    %eax,-0x18(%ebp)
c0106bfc:	81 7d e8 44 b1 12 c0 	cmpl   $0xc012b144,-0x18(%ebp)
c0106c03:	0f 85 7a ff ff ff    	jne    c0106b83 <check_swap+0x1d>
     }
     assert(total == nr_free_pages());
c0106c09:	e8 df c8 ff ff       	call   c01034ed <nr_free_pages>
c0106c0e:	89 c2                	mov    %eax,%edx
c0106c10:	8b 45 f0             	mov    -0x10(%ebp),%eax
c0106c13:	39 c2                	cmp    %eax,%edx
c0106c15:	74 24                	je     c0106c3b <check_swap+0xd5>
c0106c17:	c7 44 24 0c f2 b5 10 	movl   $0xc010b5f2,0xc(%esp)
c0106c1e:	c0 
c0106c1f:	c7 44 24 08 e6 b4 10 	movl   $0xc010b4e6,0x8(%esp)
c0106c26:	c0 
c0106c27:	c7 44 24 04 bc 00 00 	movl   $0xbc,0x4(%esp)
c0106c2e:	00 
c0106c2f:	c7 04 24 80 b4 10 c0 	movl   $0xc010b480,(%esp)
c0106c36:	e8 c5 97 ff ff       	call   c0100400 <__panic>
     cprintf("BEGIN check_swap: count %d, total %d\n",count,total);
c0106c3b:	8b 45 f0             	mov    -0x10(%ebp),%eax
c0106c3e:	89 44 24 08          	mov    %eax,0x8(%esp)
c0106c42:	8b 45 f4             	mov    -0xc(%ebp),%eax
c0106c45:	89 44 24 04          	mov    %eax,0x4(%esp)
c0106c49:	c7 04 24 0c b6 10 c0 	movl   $0xc010b60c,(%esp)
c0106c50:	e8 54 96 ff ff       	call   c01002a9 <cprintf>
     
     //now we set the phy pages env     
     struct mm_struct *mm = mm_create();
c0106c55:	e8 39 e5 ff ff       	call   c0105193 <mm_create>
c0106c5a:	89 45 e4             	mov    %eax,-0x1c(%ebp)
     assert(mm != NULL);
c0106c5d:	83 7d e4 00          	cmpl   $0x0,-0x1c(%ebp)
c0106c61:	75 24                	jne    c0106c87 <check_swap+0x121>
c0106c63:	c7 44 24 0c 32 b6 10 	movl   $0xc010b632,0xc(%esp)
c0106c6a:	c0 
c0106c6b:	c7 44 24 08 e6 b4 10 	movl   $0xc010b4e6,0x8(%esp)
c0106c72:	c0 
c0106c73:	c7 44 24 04 c1 00 00 	movl   $0xc1,0x4(%esp)
c0106c7a:	00 
c0106c7b:	c7 04 24 80 b4 10 c0 	movl   $0xc010b480,(%esp)
c0106c82:	e8 79 97 ff ff       	call   c0100400 <__panic>

     extern struct mm_struct *check_mm_struct;
     assert(check_mm_struct == NULL);
c0106c87:	a1 6c b0 12 c0       	mov    0xc012b06c,%eax
c0106c8c:	85 c0                	test   %eax,%eax
c0106c8e:	74 24                	je     c0106cb4 <check_swap+0x14e>
c0106c90:	c7 44 24 0c 3d b6 10 	movl   $0xc010b63d,0xc(%esp)
c0106c97:	c0 
c0106c98:	c7 44 24 08 e6 b4 10 	movl   $0xc010b4e6,0x8(%esp)
c0106c9f:	c0 
c0106ca0:	c7 44 24 04 c4 00 00 	movl   $0xc4,0x4(%esp)
c0106ca7:	00 
c0106ca8:	c7 04 24 80 b4 10 c0 	movl   $0xc010b480,(%esp)
c0106caf:	e8 4c 97 ff ff       	call   c0100400 <__panic>

     check_mm_struct = mm;
c0106cb4:	8b 45 e4             	mov    -0x1c(%ebp),%eax
c0106cb7:	a3 6c b0 12 c0       	mov    %eax,0xc012b06c

     pde_t *pgdir = mm->pgdir = boot_pgdir;
c0106cbc:	8b 15 e0 59 12 c0    	mov    0xc01259e0,%edx
c0106cc2:	8b 45 e4             	mov    -0x1c(%ebp),%eax
c0106cc5:	89 50 0c             	mov    %edx,0xc(%eax)
c0106cc8:	8b 45 e4             	mov    -0x1c(%ebp),%eax
c0106ccb:	8b 40 0c             	mov    0xc(%eax),%eax
c0106cce:	89 45 e0             	mov    %eax,-0x20(%ebp)
     assert(pgdir[0] == 0);
c0106cd1:	8b 45 e0             	mov    -0x20(%ebp),%eax
c0106cd4:	8b 00                	mov    (%eax),%eax
c0106cd6:	85 c0                	test   %eax,%eax
c0106cd8:	74 24                	je     c0106cfe <check_swap+0x198>
c0106cda:	c7 44 24 0c 55 b6 10 	movl   $0xc010b655,0xc(%esp)
c0106ce1:	c0 
c0106ce2:	c7 44 24 08 e6 b4 10 	movl   $0xc010b4e6,0x8(%esp)
c0106ce9:	c0 
c0106cea:	c7 44 24 04 c9 00 00 	movl   $0xc9,0x4(%esp)
c0106cf1:	00 
c0106cf2:	c7 04 24 80 b4 10 c0 	movl   $0xc010b480,(%esp)
c0106cf9:	e8 02 97 ff ff       	call   c0100400 <__panic>

     struct vma_struct *vma = vma_create(BEING_CHECK_VALID_VADDR, CHECK_VALID_VADDR, VM_WRITE | VM_READ);     //0X1000，0x1000*6，设置合法的访问范围为4KB~24KB；
c0106cfe:	c7 44 24 08 03 00 00 	movl   $0x3,0x8(%esp)
c0106d05:	00 
c0106d06:	c7 44 24 04 00 60 00 	movl   $0x6000,0x4(%esp)
c0106d0d:	00 
c0106d0e:	c7 04 24 00 10 00 00 	movl   $0x1000,(%esp)
c0106d15:	e8 f1 e4 ff ff       	call   c010520b <vma_create>
c0106d1a:	89 45 dc             	mov    %eax,-0x24(%ebp)
     assert(vma != NULL);
c0106d1d:	83 7d dc 00          	cmpl   $0x0,-0x24(%ebp)
c0106d21:	75 24                	jne    c0106d47 <check_swap+0x1e1>
c0106d23:	c7 44 24 0c 63 b6 10 	movl   $0xc010b663,0xc(%esp)
c0106d2a:	c0 
c0106d2b:	c7 44 24 08 e6 b4 10 	movl   $0xc010b4e6,0x8(%esp)
c0106d32:	c0 
c0106d33:	c7 44 24 04 cc 00 00 	movl   $0xcc,0x4(%esp)
c0106d3a:	00 
c0106d3b:	c7 04 24 80 b4 10 c0 	movl   $0xc010b480,(%esp)
c0106d42:	e8 b9 96 ff ff       	call   c0100400 <__panic>

     insert_vma_struct(mm, vma);
c0106d47:	8b 45 dc             	mov    -0x24(%ebp),%eax
c0106d4a:	89 44 24 04          	mov    %eax,0x4(%esp)
c0106d4e:	8b 45 e4             	mov    -0x1c(%ebp),%eax
c0106d51:	89 04 24             	mov    %eax,(%esp)
c0106d54:	e8 43 e6 ff ff       	call   c010539c <insert_vma_struct>

     //setup the temp Page Table vaddr 0~4MB
     cprintf("setup Page Table for vaddr 0X1000, so alloc a page\n");
c0106d59:	c7 04 24 70 b6 10 c0 	movl   $0xc010b670,(%esp)
c0106d60:	e8 44 95 ff ff       	call   c01002a9 <cprintf>
     pte_t *temp_ptep=NULL;
c0106d65:	c7 45 d8 00 00 00 00 	movl   $0x0,-0x28(%ebp)
     //mm->pgdir[PDX(BEING CHECK_VALID_VADDR)]在这里，0
     temp_ptep = get_pte(mm->pgdir, BEING_CHECK_VALID_VADDR, 1);      //拿到0X1000对应的pte，没有就创建
c0106d6c:	8b 45 e4             	mov    -0x1c(%ebp),%eax
c0106d6f:	8b 40 0c             	mov    0xc(%eax),%eax
c0106d72:	c7 44 24 08 01 00 00 	movl   $0x1,0x8(%esp)
c0106d79:	00 
c0106d7a:	c7 44 24 04 00 10 00 	movl   $0x1000,0x4(%esp)
c0106d81:	00 
c0106d82:	89 04 24             	mov    %eax,(%esp)
c0106d85:	e8 a5 cd ff ff       	call   c0103b2f <get_pte>
c0106d8a:	89 45 d8             	mov    %eax,-0x28(%ebp)
     //mm->pgdir[PDX(BEING CHECK_VALID_VADDR)]在这里，30a097          //在页目录表中索引第0项，然后新开了一张一级页表
     assert(temp_ptep!= NULL);
c0106d8d:	83 7d d8 00          	cmpl   $0x0,-0x28(%ebp)
c0106d91:	75 24                	jne    c0106db7 <check_swap+0x251>
c0106d93:	c7 44 24 0c a4 b6 10 	movl   $0xc010b6a4,0xc(%esp)
c0106d9a:	c0 
c0106d9b:	c7 44 24 08 e6 b4 10 	movl   $0xc010b4e6,0x8(%esp)
c0106da2:	c0 
c0106da3:	c7 44 24 04 d6 00 00 	movl   $0xd6,0x4(%esp)
c0106daa:	00 
c0106dab:	c7 04 24 80 b4 10 c0 	movl   $0xc010b480,(%esp)
c0106db2:	e8 49 96 ff ff       	call   c0100400 <__panic>
     cprintf("setup Page Table vaddr 0~4MB OVER!\n");                 
c0106db7:	c7 04 24 b8 b6 10 c0 	movl   $0xc010b6b8,(%esp)
c0106dbe:	e8 e6 94 ff ff       	call   c01002a9 <cprintf>
     
     for (i=0;i<CHECK_VALID_PHY_PAGE_NUM;i++) {        //4.
c0106dc3:	c7 45 ec 00 00 00 00 	movl   $0x0,-0x14(%ebp)
c0106dca:	e9 a4 00 00 00       	jmp    c0106e73 <check_swap+0x30d>
          check_rp[i] = alloc_page();
c0106dcf:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
c0106dd6:	e8 74 c6 ff ff       	call   c010344f <alloc_pages>
c0106ddb:	89 c2                	mov    %eax,%edx
c0106ddd:	8b 45 ec             	mov    -0x14(%ebp),%eax
c0106de0:	89 14 85 80 b0 12 c0 	mov    %edx,-0x3fed4f80(,%eax,4)
          assert(check_rp[i] != NULL );
c0106de7:	8b 45 ec             	mov    -0x14(%ebp),%eax
c0106dea:	8b 04 85 80 b0 12 c0 	mov    -0x3fed4f80(,%eax,4),%eax
c0106df1:	85 c0                	test   %eax,%eax
c0106df3:	75 24                	jne    c0106e19 <check_swap+0x2b3>
c0106df5:	c7 44 24 0c dc b6 10 	movl   $0xc010b6dc,0xc(%esp)
c0106dfc:	c0 
c0106dfd:	c7 44 24 08 e6 b4 10 	movl   $0xc010b4e6,0x8(%esp)
c0106e04:	c0 
c0106e05:	c7 44 24 04 db 00 00 	movl   $0xdb,0x4(%esp)
c0106e0c:	00 
c0106e0d:	c7 04 24 80 b4 10 c0 	movl   $0xc010b480,(%esp)
c0106e14:	e8 e7 95 ff ff       	call   c0100400 <__panic>
          assert(!PageProperty(check_rp[i]));
c0106e19:	8b 45 ec             	mov    -0x14(%ebp),%eax
c0106e1c:	8b 04 85 80 b0 12 c0 	mov    -0x3fed4f80(,%eax,4),%eax
c0106e23:	83 c0 04             	add    $0x4,%eax
c0106e26:	c7 45 b4 01 00 00 00 	movl   $0x1,-0x4c(%ebp)
c0106e2d:	89 45 b0             	mov    %eax,-0x50(%ebp)
    asm volatile ("btl %2, %1; sbbl %0,%0" : "=r" (oldbit) : "m" (*(volatile long *)addr), "Ir" (nr));
c0106e30:	8b 45 b0             	mov    -0x50(%ebp),%eax
c0106e33:	8b 55 b4             	mov    -0x4c(%ebp),%edx
c0106e36:	0f a3 10             	bt     %edx,(%eax)
c0106e39:	19 c0                	sbb    %eax,%eax
c0106e3b:	89 45 ac             	mov    %eax,-0x54(%ebp)
    return oldbit != 0;
c0106e3e:	83 7d ac 00          	cmpl   $0x0,-0x54(%ebp)
c0106e42:	0f 95 c0             	setne  %al
c0106e45:	0f b6 c0             	movzbl %al,%eax
c0106e48:	85 c0                	test   %eax,%eax
c0106e4a:	74 24                	je     c0106e70 <check_swap+0x30a>
c0106e4c:	c7 44 24 0c f0 b6 10 	movl   $0xc010b6f0,0xc(%esp)
c0106e53:	c0 
c0106e54:	c7 44 24 08 e6 b4 10 	movl   $0xc010b4e6,0x8(%esp)
c0106e5b:	c0 
c0106e5c:	c7 44 24 04 dc 00 00 	movl   $0xdc,0x4(%esp)
c0106e63:	00 
c0106e64:	c7 04 24 80 b4 10 c0 	movl   $0xc010b480,(%esp)
c0106e6b:	e8 90 95 ff ff       	call   c0100400 <__panic>
     for (i=0;i<CHECK_VALID_PHY_PAGE_NUM;i++) {        //4.
c0106e70:	ff 45 ec             	incl   -0x14(%ebp)
c0106e73:	83 7d ec 03          	cmpl   $0x3,-0x14(%ebp)
c0106e77:	0f 8e 52 ff ff ff    	jle    c0106dcf <check_swap+0x269>
     }
     list_entry_t free_list_store = free_list;
c0106e7d:	a1 44 b1 12 c0       	mov    0xc012b144,%eax
c0106e82:	8b 15 48 b1 12 c0    	mov    0xc012b148,%edx
c0106e88:	89 45 98             	mov    %eax,-0x68(%ebp)
c0106e8b:	89 55 9c             	mov    %edx,-0x64(%ebp)
c0106e8e:	c7 45 a4 44 b1 12 c0 	movl   $0xc012b144,-0x5c(%ebp)
    elm->prev = elm->next = elm;
c0106e95:	8b 45 a4             	mov    -0x5c(%ebp),%eax
c0106e98:	8b 55 a4             	mov    -0x5c(%ebp),%edx
c0106e9b:	89 50 04             	mov    %edx,0x4(%eax)
c0106e9e:	8b 45 a4             	mov    -0x5c(%ebp),%eax
c0106ea1:	8b 50 04             	mov    0x4(%eax),%edx
c0106ea4:	8b 45 a4             	mov    -0x5c(%ebp),%eax
c0106ea7:	89 10                	mov    %edx,(%eax)
c0106ea9:	c7 45 a8 44 b1 12 c0 	movl   $0xc012b144,-0x58(%ebp)
    return list->next == list;
c0106eb0:	8b 45 a8             	mov    -0x58(%ebp),%eax
c0106eb3:	8b 40 04             	mov    0x4(%eax),%eax
c0106eb6:	39 45 a8             	cmp    %eax,-0x58(%ebp)
c0106eb9:	0f 94 c0             	sete   %al
c0106ebc:	0f b6 c0             	movzbl %al,%eax
     list_init(&free_list);                       //清掉了
     assert(list_empty(&free_list));
c0106ebf:	85 c0                	test   %eax,%eax
c0106ec1:	75 24                	jne    c0106ee7 <check_swap+0x381>
c0106ec3:	c7 44 24 0c 0b b7 10 	movl   $0xc010b70b,0xc(%esp)
c0106eca:	c0 
c0106ecb:	c7 44 24 08 e6 b4 10 	movl   $0xc010b4e6,0x8(%esp)
c0106ed2:	c0 
c0106ed3:	c7 44 24 04 e0 00 00 	movl   $0xe0,0x4(%esp)
c0106eda:	00 
c0106edb:	c7 04 24 80 b4 10 c0 	movl   $0xc010b480,(%esp)
c0106ee2:	e8 19 95 ff ff       	call   c0100400 <__panic>
     
     //assert(alloc_page() == NULL);
     
     unsigned int nr_free_store = nr_free;
c0106ee7:	a1 4c b1 12 c0       	mov    0xc012b14c,%eax
c0106eec:	89 45 d4             	mov    %eax,-0x2c(%ebp)
     nr_free = 0;                                 //清0
c0106eef:	c7 05 4c b1 12 c0 00 	movl   $0x0,0xc012b14c
c0106ef6:	00 00 00 
     for (i=0;i<CHECK_VALID_PHY_PAGE_NUM;i++) {
c0106ef9:	c7 45 ec 00 00 00 00 	movl   $0x0,-0x14(%ebp)
c0106f00:	eb 1d                	jmp    c0106f1f <check_swap+0x3b9>
        free_pages(check_rp[i],1);                //释放四个页 调用free_page等操作，模拟形成一个只有4个空闲 physical page；并设置了从4KB~24KB的连续5个虚拟页的访问操作；
c0106f02:	8b 45 ec             	mov    -0x14(%ebp),%eax
c0106f05:	8b 04 85 80 b0 12 c0 	mov    -0x3fed4f80(,%eax,4),%eax
c0106f0c:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
c0106f13:	00 
c0106f14:	89 04 24             	mov    %eax,(%esp)
c0106f17:	e8 9e c5 ff ff       	call   c01034ba <free_pages>
     for (i=0;i<CHECK_VALID_PHY_PAGE_NUM;i++) {
c0106f1c:	ff 45 ec             	incl   -0x14(%ebp)
c0106f1f:	83 7d ec 03          	cmpl   $0x3,-0x14(%ebp)
c0106f23:	7e dd                	jle    c0106f02 <check_swap+0x39c>
     }
     assert(nr_free==CHECK_VALID_PHY_PAGE_NUM);   //nr_free为4个空闲页
c0106f25:	a1 4c b1 12 c0       	mov    0xc012b14c,%eax
c0106f2a:	83 f8 04             	cmp    $0x4,%eax
c0106f2d:	74 24                	je     c0106f53 <check_swap+0x3ed>
c0106f2f:	c7 44 24 0c 24 b7 10 	movl   $0xc010b724,0xc(%esp)
c0106f36:	c0 
c0106f37:	c7 44 24 08 e6 b4 10 	movl   $0xc010b4e6,0x8(%esp)
c0106f3e:	c0 
c0106f3f:	c7 44 24 04 e9 00 00 	movl   $0xe9,0x4(%esp)
c0106f46:	00 
c0106f47:	c7 04 24 80 b4 10 c0 	movl   $0xc010b480,(%esp)
c0106f4e:	e8 ad 94 ff ff       	call   c0100400 <__panic>
     
     cprintf("set up init env for check_swap begin!\n");
c0106f53:	c7 04 24 48 b7 10 c0 	movl   $0xc010b748,(%esp)
c0106f5a:	e8 4a 93 ff ff       	call   c01002a9 <cprintf>
     //setup initial vir_page<->phy_page environment for page relpacement algorithm 

     
     pgfault_num=0;
c0106f5f:	c7 05 0c 90 12 c0 00 	movl   $0x0,0xc012900c
c0106f66:	00 00 00 
     
     check_content_set();               //1.连续访问4个页，缺四次，然后建立四个映射
c0106f69:	e8 27 fa ff ff       	call   c0106995 <check_content_set>
     assert( nr_free == 0);         
c0106f6e:	a1 4c b1 12 c0       	mov    0xc012b14c,%eax
c0106f73:	85 c0                	test   %eax,%eax
c0106f75:	74 24                	je     c0106f9b <check_swap+0x435>
c0106f77:	c7 44 24 0c 6f b7 10 	movl   $0xc010b76f,0xc(%esp)
c0106f7e:	c0 
c0106f7f:	c7 44 24 08 e6 b4 10 	movl   $0xc010b4e6,0x8(%esp)
c0106f86:	c0 
c0106f87:	c7 44 24 04 f2 00 00 	movl   $0xf2,0x4(%esp)
c0106f8e:	00 
c0106f8f:	c7 04 24 80 b4 10 c0 	movl   $0xc010b480,(%esp)
c0106f96:	e8 65 94 ff ff       	call   c0100400 <__panic>
     for(i = 0; i<MAX_SEQ_NO ; i++)          //10
c0106f9b:	c7 45 ec 00 00 00 00 	movl   $0x0,-0x14(%ebp)
c0106fa2:	eb 25                	jmp    c0106fc9 <check_swap+0x463>
         swap_out_seq_no[i]=swap_in_seq_no[i]=-1;
c0106fa4:	8b 45 ec             	mov    -0x14(%ebp),%eax
c0106fa7:	c7 04 85 a0 b0 12 c0 	movl   $0xffffffff,-0x3fed4f60(,%eax,4)
c0106fae:	ff ff ff ff 
c0106fb2:	8b 45 ec             	mov    -0x14(%ebp),%eax
c0106fb5:	8b 14 85 a0 b0 12 c0 	mov    -0x3fed4f60(,%eax,4),%edx
c0106fbc:	8b 45 ec             	mov    -0x14(%ebp),%eax
c0106fbf:	89 14 85 e0 b0 12 c0 	mov    %edx,-0x3fed4f20(,%eax,4)
     for(i = 0; i<MAX_SEQ_NO ; i++)          //10
c0106fc6:	ff 45 ec             	incl   -0x14(%ebp)
c0106fc9:	83 7d ec 09          	cmpl   $0x9,-0x14(%ebp)
c0106fcd:	7e d5                	jle    c0106fa4 <check_swap+0x43e>
     
     for (i= 0;i<CHECK_VALID_PHY_PAGE_NUM;i++) {  //4
c0106fcf:	c7 45 ec 00 00 00 00 	movl   $0x0,-0x14(%ebp)
c0106fd6:	e9 ec 00 00 00       	jmp    c01070c7 <check_swap+0x561>
         check_ptep[i]=0;
c0106fdb:	8b 45 ec             	mov    -0x14(%ebp),%eax
c0106fde:	c7 04 85 34 b1 12 c0 	movl   $0x0,-0x3fed4ecc(,%eax,4)
c0106fe5:	00 00 00 00 
         check_ptep[i] = get_pte(pgdir, (i+1)*0x1000, 0);   //对应这四个la的pte，已经建好映射，就能拿到
c0106fe9:	8b 45 ec             	mov    -0x14(%ebp),%eax
c0106fec:	40                   	inc    %eax
c0106fed:	c1 e0 0c             	shl    $0xc,%eax
c0106ff0:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
c0106ff7:	00 
c0106ff8:	89 44 24 04          	mov    %eax,0x4(%esp)
c0106ffc:	8b 45 e0             	mov    -0x20(%ebp),%eax
c0106fff:	89 04 24             	mov    %eax,(%esp)
c0107002:	e8 28 cb ff ff       	call   c0103b2f <get_pte>
c0107007:	89 c2                	mov    %eax,%edx
c0107009:	8b 45 ec             	mov    -0x14(%ebp),%eax
c010700c:	89 14 85 34 b1 12 c0 	mov    %edx,-0x3fed4ecc(,%eax,4)
         //cprintf("i %d, check_ptep addr %x, value %x\n", i, check_ptep[i], *check_ptep[i]);
         assert(check_ptep[i] != NULL);
c0107013:	8b 45 ec             	mov    -0x14(%ebp),%eax
c0107016:	8b 04 85 34 b1 12 c0 	mov    -0x3fed4ecc(,%eax,4),%eax
c010701d:	85 c0                	test   %eax,%eax
c010701f:	75 24                	jne    c0107045 <check_swap+0x4df>
c0107021:	c7 44 24 0c 7c b7 10 	movl   $0xc010b77c,0xc(%esp)
c0107028:	c0 
c0107029:	c7 44 24 08 e6 b4 10 	movl   $0xc010b4e6,0x8(%esp)
c0107030:	c0 
c0107031:	c7 44 24 04 fa 00 00 	movl   $0xfa,0x4(%esp)
c0107038:	00 
c0107039:	c7 04 24 80 b4 10 c0 	movl   $0xc010b480,(%esp)
c0107040:	e8 bb 93 ff ff       	call   c0100400 <__panic>
         assert(pte2page(*check_ptep[i]) == check_rp[i]);
c0107045:	8b 45 ec             	mov    -0x14(%ebp),%eax
c0107048:	8b 04 85 34 b1 12 c0 	mov    -0x3fed4ecc(,%eax,4),%eax
c010704f:	8b 00                	mov    (%eax),%eax
c0107051:	89 04 24             	mov    %eax,(%esp)
c0107054:	e8 a6 f5 ff ff       	call   c01065ff <pte2page>
c0107059:	89 c2                	mov    %eax,%edx
c010705b:	8b 45 ec             	mov    -0x14(%ebp),%eax
c010705e:	8b 04 85 80 b0 12 c0 	mov    -0x3fed4f80(,%eax,4),%eax
c0107065:	39 c2                	cmp    %eax,%edx
c0107067:	74 24                	je     c010708d <check_swap+0x527>
c0107069:	c7 44 24 0c 94 b7 10 	movl   $0xc010b794,0xc(%esp)
c0107070:	c0 
c0107071:	c7 44 24 08 e6 b4 10 	movl   $0xc010b4e6,0x8(%esp)
c0107078:	c0 
c0107079:	c7 44 24 04 fb 00 00 	movl   $0xfb,0x4(%esp)
c0107080:	00 
c0107081:	c7 04 24 80 b4 10 c0 	movl   $0xc010b480,(%esp)
c0107088:	e8 73 93 ff ff       	call   c0100400 <__panic>
         assert((*check_ptep[i] & PTE_P));          
c010708d:	8b 45 ec             	mov    -0x14(%ebp),%eax
c0107090:	8b 04 85 34 b1 12 c0 	mov    -0x3fed4ecc(,%eax,4),%eax
c0107097:	8b 00                	mov    (%eax),%eax
c0107099:	83 e0 01             	and    $0x1,%eax
c010709c:	85 c0                	test   %eax,%eax
c010709e:	75 24                	jne    c01070c4 <check_swap+0x55e>
c01070a0:	c7 44 24 0c bc b7 10 	movl   $0xc010b7bc,0xc(%esp)
c01070a7:	c0 
c01070a8:	c7 44 24 08 e6 b4 10 	movl   $0xc010b4e6,0x8(%esp)
c01070af:	c0 
c01070b0:	c7 44 24 04 fc 00 00 	movl   $0xfc,0x4(%esp)
c01070b7:	00 
c01070b8:	c7 04 24 80 b4 10 c0 	movl   $0xc010b480,(%esp)
c01070bf:	e8 3c 93 ff ff       	call   c0100400 <__panic>
     for (i= 0;i<CHECK_VALID_PHY_PAGE_NUM;i++) {  //4
c01070c4:	ff 45 ec             	incl   -0x14(%ebp)
c01070c7:	83 7d ec 03          	cmpl   $0x3,-0x14(%ebp)
c01070cb:	0f 8e 0a ff ff ff    	jle    c0106fdb <check_swap+0x475>
     }
     cprintf("set up init env for check_swap over!\n");
c01070d1:	c7 04 24 d8 b7 10 c0 	movl   $0xc010b7d8,(%esp)
c01070d8:	e8 cc 91 ff ff       	call   c01002a9 <cprintf>
     // now access the virt pages to test  page relpacement algorithm 
     ret=check_content_access();   //2.访问虚页测试fifo
c01070dd:	e8 6c fa ff ff       	call   c0106b4e <check_content_access>
c01070e2:	89 45 d0             	mov    %eax,-0x30(%ebp)
     assert(ret==0);
c01070e5:	83 7d d0 00          	cmpl   $0x0,-0x30(%ebp)
c01070e9:	74 24                	je     c010710f <check_swap+0x5a9>
c01070eb:	c7 44 24 0c fe b7 10 	movl   $0xc010b7fe,0xc(%esp)
c01070f2:	c0 
c01070f3:	c7 44 24 08 e6 b4 10 	movl   $0xc010b4e6,0x8(%esp)
c01070fa:	c0 
c01070fb:	c7 44 24 04 01 01 00 	movl   $0x101,0x4(%esp)
c0107102:	00 
c0107103:	c7 04 24 80 b4 10 c0 	movl   $0xc010b480,(%esp)
c010710a:	e8 f1 92 ff ff       	call   c0100400 <__panic>
     
     //restore kernel mem env
     for (i=0;i<CHECK_VALID_PHY_PAGE_NUM;i++) {
c010710f:	c7 45 ec 00 00 00 00 	movl   $0x0,-0x14(%ebp)
c0107116:	eb 1d                	jmp    c0107135 <check_swap+0x5cf>
         free_pages(check_rp[i],1);
c0107118:	8b 45 ec             	mov    -0x14(%ebp),%eax
c010711b:	8b 04 85 80 b0 12 c0 	mov    -0x3fed4f80(,%eax,4),%eax
c0107122:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
c0107129:	00 
c010712a:	89 04 24             	mov    %eax,(%esp)
c010712d:	e8 88 c3 ff ff       	call   c01034ba <free_pages>
     for (i=0;i<CHECK_VALID_PHY_PAGE_NUM;i++) {
c0107132:	ff 45 ec             	incl   -0x14(%ebp)
c0107135:	83 7d ec 03          	cmpl   $0x3,-0x14(%ebp)
c0107139:	7e dd                	jle    c0107118 <check_swap+0x5b2>
     } 

     //free_page(pte2page(*temp_ptep));
     
     mm_destroy(mm);
c010713b:	8b 45 e4             	mov    -0x1c(%ebp),%eax
c010713e:	89 04 24             	mov    %eax,(%esp)
c0107141:	e8 88 e3 ff ff       	call   c01054ce <mm_destroy>
         
     nr_free = nr_free_store;
c0107146:	8b 45 d4             	mov    -0x2c(%ebp),%eax
c0107149:	a3 4c b1 12 c0       	mov    %eax,0xc012b14c
     free_list = free_list_store;
c010714e:	8b 45 98             	mov    -0x68(%ebp),%eax
c0107151:	8b 55 9c             	mov    -0x64(%ebp),%edx
c0107154:	a3 44 b1 12 c0       	mov    %eax,0xc012b144
c0107159:	89 15 48 b1 12 c0    	mov    %edx,0xc012b148

     
     le = &free_list;
c010715f:	c7 45 e8 44 b1 12 c0 	movl   $0xc012b144,-0x18(%ebp)
     while ((le = list_next(le)) != &free_list) {
c0107166:	eb 1c                	jmp    c0107184 <check_swap+0x61e>
         struct Page *p = le2page(le, page_link);
c0107168:	8b 45 e8             	mov    -0x18(%ebp),%eax
c010716b:	83 e8 0c             	sub    $0xc,%eax
c010716e:	89 45 cc             	mov    %eax,-0x34(%ebp)
         count --, total -= p->property;
c0107171:	ff 4d f4             	decl   -0xc(%ebp)
c0107174:	8b 55 f0             	mov    -0x10(%ebp),%edx
c0107177:	8b 45 cc             	mov    -0x34(%ebp),%eax
c010717a:	8b 40 08             	mov    0x8(%eax),%eax
c010717d:	29 c2                	sub    %eax,%edx
c010717f:	89 d0                	mov    %edx,%eax
c0107181:	89 45 f0             	mov    %eax,-0x10(%ebp)
c0107184:	8b 45 e8             	mov    -0x18(%ebp),%eax
c0107187:	89 45 a0             	mov    %eax,-0x60(%ebp)
    return listelm->next;
c010718a:	8b 45 a0             	mov    -0x60(%ebp),%eax
c010718d:	8b 40 04             	mov    0x4(%eax),%eax
     while ((le = list_next(le)) != &free_list) {
c0107190:	89 45 e8             	mov    %eax,-0x18(%ebp)
c0107193:	81 7d e8 44 b1 12 c0 	cmpl   $0xc012b144,-0x18(%ebp)
c010719a:	75 cc                	jne    c0107168 <check_swap+0x602>
     }
     cprintf("count is %d, total is %d\n",count,total);
c010719c:	8b 45 f0             	mov    -0x10(%ebp),%eax
c010719f:	89 44 24 08          	mov    %eax,0x8(%esp)
c01071a3:	8b 45 f4             	mov    -0xc(%ebp),%eax
c01071a6:	89 44 24 04          	mov    %eax,0x4(%esp)
c01071aa:	c7 04 24 05 b8 10 c0 	movl   $0xc010b805,(%esp)
c01071b1:	e8 f3 90 ff ff       	call   c01002a9 <cprintf>
     //assert(count == 0);
     
     cprintf("check_swap() succeeded!\n");
c01071b6:	c7 04 24 1f b8 10 c0 	movl   $0xc010b81f,(%esp)
c01071bd:	e8 e7 90 ff ff       	call   c01002a9 <cprintf>
}
c01071c2:	90                   	nop
c01071c3:	c9                   	leave  
c01071c4:	c3                   	ret    

c01071c5 <page2ppn>:
page2ppn(struct Page *page) {
c01071c5:	55                   	push   %ebp
c01071c6:	89 e5                	mov    %esp,%ebp
    return page - pages;         //减去物理页数组的基址，得高20bit的PPN(pa)
c01071c8:	8b 45 08             	mov    0x8(%ebp),%eax
c01071cb:	8b 15 60 b0 12 c0    	mov    0xc012b060,%edx
c01071d1:	29 d0                	sub    %edx,%eax
c01071d3:	c1 f8 05             	sar    $0x5,%eax
}
c01071d6:	5d                   	pop    %ebp
c01071d7:	c3                   	ret    

c01071d8 <page2pa>:
page2pa(struct Page *page) {
c01071d8:	55                   	push   %ebp
c01071d9:	89 e5                	mov    %esp,%ebp
c01071db:	83 ec 04             	sub    $0x4,%esp
    return page2ppn(page) << PGSHIFT;   //20bit+12bit全0的pa
c01071de:	8b 45 08             	mov    0x8(%ebp),%eax
c01071e1:	89 04 24             	mov    %eax,(%esp)
c01071e4:	e8 dc ff ff ff       	call   c01071c5 <page2ppn>
c01071e9:	c1 e0 0c             	shl    $0xc,%eax
}
c01071ec:	c9                   	leave  
c01071ed:	c3                   	ret    

c01071ee <page_ref>:
page_ref(struct Page *page) {
c01071ee:	55                   	push   %ebp
c01071ef:	89 e5                	mov    %esp,%ebp
    return page->ref;
c01071f1:	8b 45 08             	mov    0x8(%ebp),%eax
c01071f4:	8b 00                	mov    (%eax),%eax
}
c01071f6:	5d                   	pop    %ebp
c01071f7:	c3                   	ret    

c01071f8 <set_page_ref>:
set_page_ref(struct Page *page, int val) {
c01071f8:	55                   	push   %ebp
c01071f9:	89 e5                	mov    %esp,%ebp
    page->ref = val;
c01071fb:	8b 45 08             	mov    0x8(%ebp),%eax
c01071fe:	8b 55 0c             	mov    0xc(%ebp),%edx
c0107201:	89 10                	mov    %edx,(%eax)
}
c0107203:	90                   	nop
c0107204:	5d                   	pop    %ebp
c0107205:	c3                   	ret    

c0107206 <default_init>:

#define free_list (free_area.free_list)
#define nr_free (free_area.nr_free)

static void
default_init(void) {         //初始化结构体对象free_area（空闲双向链表指针与空闲块个数）
c0107206:	55                   	push   %ebp
c0107207:	89 e5                	mov    %esp,%ebp
c0107209:	83 ec 10             	sub    $0x10,%esp
c010720c:	c7 45 fc 44 b1 12 c0 	movl   $0xc012b144,-0x4(%ebp)
    elm->prev = elm->next = elm;
c0107213:	8b 45 fc             	mov    -0x4(%ebp),%eax
c0107216:	8b 55 fc             	mov    -0x4(%ebp),%edx
c0107219:	89 50 04             	mov    %edx,0x4(%eax)
c010721c:	8b 45 fc             	mov    -0x4(%ebp),%eax
c010721f:	8b 50 04             	mov    0x4(%eax),%edx
c0107222:	8b 45 fc             	mov    -0x4(%ebp),%eax
c0107225:	89 10                	mov    %edx,(%eax)
    list_init(&free_list);
    nr_free = 0;
c0107227:	c7 05 4c b1 12 c0 00 	movl   $0x0,0xc012b14c
c010722e:	00 00 00 
}
c0107231:	90                   	nop
c0107232:	c9                   	leave  
c0107233:	c3                   	ret    

c0107234 <default_init_memmap>:

static void
default_init_memmap(struct Page *base, size_t n) {
c0107234:	55                   	push   %ebp
c0107235:	89 e5                	mov    %esp,%ebp
c0107237:	83 ec 48             	sub    $0x48,%esp
    assert(n > 0);
c010723a:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
c010723e:	75 24                	jne    c0107264 <default_init_memmap+0x30>
c0107240:	c7 44 24 0c 38 b8 10 	movl   $0xc010b838,0xc(%esp)
c0107247:	c0 
c0107248:	c7 44 24 08 3e b8 10 	movl   $0xc010b83e,0x8(%esp)
c010724f:	c0 
c0107250:	c7 44 24 04 6d 00 00 	movl   $0x6d,0x4(%esp)
c0107257:	00 
c0107258:	c7 04 24 53 b8 10 c0 	movl   $0xc010b853,(%esp)
c010725f:	e8 9c 91 ff ff       	call   c0100400 <__panic>
    struct Page *p = base;
c0107264:	8b 45 08             	mov    0x8(%ebp),%eax
c0107267:	89 45 f4             	mov    %eax,-0xc(%ebp)
    for (; p != base + n; p ++) {
c010726a:	eb 7d                	jmp    c01072e9 <default_init_memmap+0xb5>
        assert(PageReserved(p));        //page_init中，PG_reserved已置位 pmm.c的217行
c010726c:	8b 45 f4             	mov    -0xc(%ebp),%eax
c010726f:	83 c0 04             	add    $0x4,%eax
c0107272:	c7 45 f0 00 00 00 00 	movl   $0x0,-0x10(%ebp)
c0107279:	89 45 ec             	mov    %eax,-0x14(%ebp)
    asm volatile ("btl %2, %1; sbbl %0,%0" : "=r" (oldbit) : "m" (*(volatile long *)addr), "Ir" (nr));
c010727c:	8b 45 ec             	mov    -0x14(%ebp),%eax
c010727f:	8b 55 f0             	mov    -0x10(%ebp),%edx
c0107282:	0f a3 10             	bt     %edx,(%eax)
c0107285:	19 c0                	sbb    %eax,%eax
c0107287:	89 45 e8             	mov    %eax,-0x18(%ebp)
    return oldbit != 0;
c010728a:	83 7d e8 00          	cmpl   $0x0,-0x18(%ebp)
c010728e:	0f 95 c0             	setne  %al
c0107291:	0f b6 c0             	movzbl %al,%eax
c0107294:	85 c0                	test   %eax,%eax
c0107296:	75 24                	jne    c01072bc <default_init_memmap+0x88>
c0107298:	c7 44 24 0c 69 b8 10 	movl   $0xc010b869,0xc(%esp)
c010729f:	c0 
c01072a0:	c7 44 24 08 3e b8 10 	movl   $0xc010b83e,0x8(%esp)
c01072a7:	c0 
c01072a8:	c7 44 24 04 70 00 00 	movl   $0x70,0x4(%esp)
c01072af:	00 
c01072b0:	c7 04 24 53 b8 10 c0 	movl   $0xc010b853,(%esp)
c01072b7:	e8 44 91 ff ff       	call   c0100400 <__panic>
        p->flags = p->property = 0;     //非head page
c01072bc:	8b 45 f4             	mov    -0xc(%ebp),%eax
c01072bf:	c7 40 08 00 00 00 00 	movl   $0x0,0x8(%eax)
c01072c6:	8b 45 f4             	mov    -0xc(%ebp),%eax
c01072c9:	8b 50 08             	mov    0x8(%eax),%edx
c01072cc:	8b 45 f4             	mov    -0xc(%ebp),%eax
c01072cf:	89 50 04             	mov    %edx,0x4(%eax)
        set_page_ref(p, 0);             //虚页映射数初始化
c01072d2:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
c01072d9:	00 
c01072da:	8b 45 f4             	mov    -0xc(%ebp),%eax
c01072dd:	89 04 24             	mov    %eax,(%esp)
c01072e0:	e8 13 ff ff ff       	call   c01071f8 <set_page_ref>
    for (; p != base + n; p ++) {
c01072e5:	83 45 f4 20          	addl   $0x20,-0xc(%ebp)
c01072e9:	8b 45 0c             	mov    0xc(%ebp),%eax
c01072ec:	c1 e0 05             	shl    $0x5,%eax
c01072ef:	89 c2                	mov    %eax,%edx
c01072f1:	8b 45 08             	mov    0x8(%ebp),%eax
c01072f4:	01 d0                	add    %edx,%eax
c01072f6:	39 45 f4             	cmp    %eax,-0xc(%ebp)
c01072f9:	0f 85 6d ff ff ff    	jne    c010726c <default_init_memmap+0x38>
    }
    base->property = n;                //head page，空闲页个数
c01072ff:	8b 45 08             	mov    0x8(%ebp),%eax
c0107302:	8b 55 0c             	mov    0xc(%ebp),%edx
c0107305:	89 50 08             	mov    %edx,0x8(%eax)
    SetPageProperty(base);
c0107308:	8b 45 08             	mov    0x8(%ebp),%eax
c010730b:	83 c0 04             	add    $0x4,%eax
c010730e:	c7 45 d0 01 00 00 00 	movl   $0x1,-0x30(%ebp)
c0107315:	89 45 cc             	mov    %eax,-0x34(%ebp)
    asm volatile ("btsl %1, %0" :"=m" (*(volatile long *)addr) : "Ir" (nr));
c0107318:	8b 45 cc             	mov    -0x34(%ebp),%eax
c010731b:	8b 55 d0             	mov    -0x30(%ebp),%edx
c010731e:	0f ab 10             	bts    %edx,(%eax)
    nr_free += n;
c0107321:	8b 15 4c b1 12 c0    	mov    0xc012b14c,%edx
c0107327:	8b 45 0c             	mov    0xc(%ebp),%eax
c010732a:	01 d0                	add    %edx,%eax
c010732c:	a3 4c b1 12 c0       	mov    %eax,0xc012b14c
    list_add_before(&free_list, &(base->page_link));       //将这个空闲块的head page的link链入双向链表
c0107331:	8b 45 08             	mov    0x8(%ebp),%eax
c0107334:	83 c0 0c             	add    $0xc,%eax
c0107337:	c7 45 e4 44 b1 12 c0 	movl   $0xc012b144,-0x1c(%ebp)
c010733e:	89 45 e0             	mov    %eax,-0x20(%ebp)
    __list_add(elm, listelm->prev, listelm);
c0107341:	8b 45 e4             	mov    -0x1c(%ebp),%eax
c0107344:	8b 00                	mov    (%eax),%eax
c0107346:	8b 55 e0             	mov    -0x20(%ebp),%edx
c0107349:	89 55 dc             	mov    %edx,-0x24(%ebp)
c010734c:	89 45 d8             	mov    %eax,-0x28(%ebp)
c010734f:	8b 45 e4             	mov    -0x1c(%ebp),%eax
c0107352:	89 45 d4             	mov    %eax,-0x2c(%ebp)
    prev->next = next->prev = elm;
c0107355:	8b 45 d4             	mov    -0x2c(%ebp),%eax
c0107358:	8b 55 dc             	mov    -0x24(%ebp),%edx
c010735b:	89 10                	mov    %edx,(%eax)
c010735d:	8b 45 d4             	mov    -0x2c(%ebp),%eax
c0107360:	8b 10                	mov    (%eax),%edx
c0107362:	8b 45 d8             	mov    -0x28(%ebp),%eax
c0107365:	89 50 04             	mov    %edx,0x4(%eax)
    elm->next = next;
c0107368:	8b 45 dc             	mov    -0x24(%ebp),%eax
c010736b:	8b 55 d4             	mov    -0x2c(%ebp),%edx
c010736e:	89 50 04             	mov    %edx,0x4(%eax)
    elm->prev = prev;
c0107371:	8b 45 dc             	mov    -0x24(%ebp),%eax
c0107374:	8b 55 d8             	mov    -0x28(%ebp),%edx
c0107377:	89 10                	mov    %edx,(%eax)
}   //注意是向前加
c0107379:	90                   	nop
c010737a:	c9                   	leave  
c010737b:	c3                   	ret    

c010737c <default_alloc_pages>:

static struct Page *
default_alloc_pages(size_t n) {     //返回分配的空间块中第一页的Page结构的指针
c010737c:	55                   	push   %ebp
c010737d:	89 e5                	mov    %esp,%ebp
c010737f:	83 ec 68             	sub    $0x68,%esp
    assert(n > 0);
c0107382:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
c0107386:	75 24                	jne    c01073ac <default_alloc_pages+0x30>
c0107388:	c7 44 24 0c 38 b8 10 	movl   $0xc010b838,0xc(%esp)
c010738f:	c0 
c0107390:	c7 44 24 08 3e b8 10 	movl   $0xc010b83e,0x8(%esp)
c0107397:	c0 
c0107398:	c7 44 24 04 7c 00 00 	movl   $0x7c,0x4(%esp)
c010739f:	00 
c01073a0:	c7 04 24 53 b8 10 c0 	movl   $0xc010b853,(%esp)
c01073a7:	e8 54 90 ff ff       	call   c0100400 <__panic>
    if (n > nr_free) {              //请求的页数比实际的要多，不予分配
c01073ac:	a1 4c b1 12 c0       	mov    0xc012b14c,%eax
c01073b1:	39 45 08             	cmp    %eax,0x8(%ebp)
c01073b4:	76 0a                	jbe    c01073c0 <default_alloc_pages+0x44>
        return NULL;
c01073b6:	b8 00 00 00 00       	mov    $0x0,%eax
c01073bb:	e9 42 01 00 00       	jmp    c0107502 <default_alloc_pages+0x186>
    }
    struct Page *page = NULL;
c01073c0:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
    list_entry_t *le = &free_list;
c01073c7:	c7 45 f0 44 b1 12 c0 	movl   $0xc012b144,-0x10(%ebp)
    while ((le = list_next(le)) != &free_list) {
c01073ce:	eb 1c                	jmp    c01073ec <default_alloc_pages+0x70>
        struct Page *p = le2page(le, page_link);    //将现在的链表项对应到相应空闲块的head page
c01073d0:	8b 45 f0             	mov    -0x10(%ebp),%eax
c01073d3:	83 e8 0c             	sub    $0xc,%eax
c01073d6:	89 45 ec             	mov    %eax,-0x14(%ebp)
        if (p->property >= n) {                 //first fit！该空闲块的页数比需求的多或相等，给予分配
c01073d9:	8b 45 ec             	mov    -0x14(%ebp),%eax
c01073dc:	8b 40 08             	mov    0x8(%eax),%eax
c01073df:	39 45 08             	cmp    %eax,0x8(%ebp)
c01073e2:	77 08                	ja     c01073ec <default_alloc_pages+0x70>
            page = p;
c01073e4:	8b 45 ec             	mov    -0x14(%ebp),%eax
c01073e7:	89 45 f4             	mov    %eax,-0xc(%ebp)
            break;
c01073ea:	eb 18                	jmp    c0107404 <default_alloc_pages+0x88>
c01073ec:	8b 45 f0             	mov    -0x10(%ebp),%eax
c01073ef:	89 45 e4             	mov    %eax,-0x1c(%ebp)
    return listelm->next;
c01073f2:	8b 45 e4             	mov    -0x1c(%ebp),%eax
c01073f5:	8b 40 04             	mov    0x4(%eax),%eax
    while ((le = list_next(le)) != &free_list) {
c01073f8:	89 45 f0             	mov    %eax,-0x10(%ebp)
c01073fb:	81 7d f0 44 b1 12 c0 	cmpl   $0xc012b144,-0x10(%ebp)
c0107402:	75 cc                	jne    c01073d0 <default_alloc_pages+0x54>
        }
    }
    if (page != NULL) {
c0107404:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
c0107408:	0f 84 f1 00 00 00    	je     c01074ff <default_alloc_pages+0x183>
        if (page->property > n) {               //如果块中空闲页还有富余，将剩下的页组成的新空闲块链入链表中
c010740e:	8b 45 f4             	mov    -0xc(%ebp),%eax
c0107411:	8b 40 08             	mov    0x8(%eax),%eax
c0107414:	39 45 08             	cmp    %eax,0x8(%ebp)
c0107417:	0f 83 91 00 00 00    	jae    c01074ae <default_alloc_pages+0x132>
            struct Page *p = page + n;          //p成为新的空闲块的head page
c010741d:	8b 45 08             	mov    0x8(%ebp),%eax
c0107420:	c1 e0 05             	shl    $0x5,%eax
c0107423:	89 c2                	mov    %eax,%edx
c0107425:	8b 45 f4             	mov    -0xc(%ebp),%eax
c0107428:	01 d0                	add    %edx,%eax
c010742a:	89 45 e8             	mov    %eax,-0x18(%ebp)
            p->property = page->property - n;
c010742d:	8b 45 f4             	mov    -0xc(%ebp),%eax
c0107430:	8b 40 08             	mov    0x8(%eax),%eax
c0107433:	2b 45 08             	sub    0x8(%ebp),%eax
c0107436:	89 c2                	mov    %eax,%edx
c0107438:	8b 45 e8             	mov    -0x18(%ebp),%eax
c010743b:	89 50 08             	mov    %edx,0x8(%eax)
            SetPageProperty(p);
c010743e:	8b 45 e8             	mov    -0x18(%ebp),%eax
c0107441:	83 c0 04             	add    $0x4,%eax
c0107444:	c7 45 c4 01 00 00 00 	movl   $0x1,-0x3c(%ebp)
c010744b:	89 45 c0             	mov    %eax,-0x40(%ebp)
c010744e:	8b 45 c0             	mov    -0x40(%ebp),%eax
c0107451:	8b 55 c4             	mov    -0x3c(%ebp),%edx
c0107454:	0f ab 10             	bts    %edx,(%eax)
            list_add(&(page->page_link), &(p->page_link));  //新的空闲块直接链在原先“空闲块”的后面（符合地址小大）
c0107457:	8b 45 e8             	mov    -0x18(%ebp),%eax
c010745a:	83 c0 0c             	add    $0xc,%eax
c010745d:	8b 55 f4             	mov    -0xc(%ebp),%edx
c0107460:	83 c2 0c             	add    $0xc,%edx
c0107463:	89 55 e0             	mov    %edx,-0x20(%ebp)
c0107466:	89 45 dc             	mov    %eax,-0x24(%ebp)
c0107469:	8b 45 e0             	mov    -0x20(%ebp),%eax
c010746c:	89 45 d8             	mov    %eax,-0x28(%ebp)
c010746f:	8b 45 dc             	mov    -0x24(%ebp),%eax
c0107472:	89 45 d4             	mov    %eax,-0x2c(%ebp)
    __list_add(elm, listelm, listelm->next);
c0107475:	8b 45 d8             	mov    -0x28(%ebp),%eax
c0107478:	8b 40 04             	mov    0x4(%eax),%eax
c010747b:	8b 55 d4             	mov    -0x2c(%ebp),%edx
c010747e:	89 55 d0             	mov    %edx,-0x30(%ebp)
c0107481:	8b 55 d8             	mov    -0x28(%ebp),%edx
c0107484:	89 55 cc             	mov    %edx,-0x34(%ebp)
c0107487:	89 45 c8             	mov    %eax,-0x38(%ebp)
    prev->next = next->prev = elm;
c010748a:	8b 45 c8             	mov    -0x38(%ebp),%eax
c010748d:	8b 55 d0             	mov    -0x30(%ebp),%edx
c0107490:	89 10                	mov    %edx,(%eax)
c0107492:	8b 45 c8             	mov    -0x38(%ebp),%eax
c0107495:	8b 10                	mov    (%eax),%edx
c0107497:	8b 45 cc             	mov    -0x34(%ebp),%eax
c010749a:	89 50 04             	mov    %edx,0x4(%eax)
    elm->next = next;
c010749d:	8b 45 d0             	mov    -0x30(%ebp),%eax
c01074a0:	8b 55 c8             	mov    -0x38(%ebp),%edx
c01074a3:	89 50 04             	mov    %edx,0x4(%eax)
    elm->prev = prev;
c01074a6:	8b 45 d0             	mov    -0x30(%ebp),%eax
c01074a9:	8b 55 cc             	mov    -0x34(%ebp),%edx
c01074ac:	89 10                	mov    %edx,(%eax)
        }
        list_del(&(page->page_link));           //把该“空闲块”对应的链表项删除 tip：改到下面
c01074ae:	8b 45 f4             	mov    -0xc(%ebp),%eax
c01074b1:	83 c0 0c             	add    $0xc,%eax
c01074b4:	89 45 b4             	mov    %eax,-0x4c(%ebp)
    __list_del(listelm->prev, listelm->next);
c01074b7:	8b 45 b4             	mov    -0x4c(%ebp),%eax
c01074ba:	8b 40 04             	mov    0x4(%eax),%eax
c01074bd:	8b 55 b4             	mov    -0x4c(%ebp),%edx
c01074c0:	8b 12                	mov    (%edx),%edx
c01074c2:	89 55 b0             	mov    %edx,-0x50(%ebp)
c01074c5:	89 45 ac             	mov    %eax,-0x54(%ebp)
    prev->next = next;
c01074c8:	8b 45 b0             	mov    -0x50(%ebp),%eax
c01074cb:	8b 55 ac             	mov    -0x54(%ebp),%edx
c01074ce:	89 50 04             	mov    %edx,0x4(%eax)
    next->prev = prev;
c01074d1:	8b 45 ac             	mov    -0x54(%ebp),%eax
c01074d4:	8b 55 b0             	mov    -0x50(%ebp),%edx
c01074d7:	89 10                	mov    %edx,(%eax)
        nr_free -= n;
c01074d9:	a1 4c b1 12 c0       	mov    0xc012b14c,%eax
c01074de:	2b 45 08             	sub    0x8(%ebp),%eax
c01074e1:	a3 4c b1 12 c0       	mov    %eax,0xc012b14c
        ClearPageProperty(page);
c01074e6:	8b 45 f4             	mov    -0xc(%ebp),%eax
c01074e9:	83 c0 04             	add    $0x4,%eax
c01074ec:	c7 45 bc 01 00 00 00 	movl   $0x1,-0x44(%ebp)
c01074f3:	89 45 b8             	mov    %eax,-0x48(%ebp)
    asm volatile ("btrl %1, %0" :"=m" (*(volatile long *)addr) : "Ir" (nr));
c01074f6:	8b 45 b8             	mov    -0x48(%ebp),%eax
c01074f9:	8b 55 bc             	mov    -0x44(%ebp),%edx
c01074fc:	0f b3 10             	btr    %edx,(%eax)
    }
    return page;
c01074ff:	8b 45 f4             	mov    -0xc(%ebp),%eax
}
c0107502:	c9                   	leave  
c0107503:	c3                   	ret    

c0107504 <default_free_pages>:

static void
default_free_pages(struct Page *base, size_t n) {
c0107504:	55                   	push   %ebp
c0107505:	89 e5                	mov    %esp,%ebp
c0107507:	81 ec 98 00 00 00    	sub    $0x98,%esp
    assert(n > 0);
c010750d:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
c0107511:	75 24                	jne    c0107537 <default_free_pages+0x33>
c0107513:	c7 44 24 0c 38 b8 10 	movl   $0xc010b838,0xc(%esp)
c010751a:	c0 
c010751b:	c7 44 24 08 3e b8 10 	movl   $0xc010b83e,0x8(%esp)
c0107522:	c0 
c0107523:	c7 44 24 04 99 00 00 	movl   $0x99,0x4(%esp)
c010752a:	00 
c010752b:	c7 04 24 53 b8 10 c0 	movl   $0xc010b853,(%esp)
c0107532:	e8 c9 8e ff ff       	call   c0100400 <__panic>
    struct Page *p = base;
c0107537:	8b 45 08             	mov    0x8(%ebp),%eax
c010753a:	89 45 f4             	mov    %eax,-0xc(%ebp)
    for (; p != base + n; p ++) {
c010753d:	e9 9d 00 00 00       	jmp    c01075df <default_free_pages+0xdb>
        assert(!PageReserved(p) && !PageProperty(p));   //确认各个页状态是被OS占用的或是已分配的，如果释放了空闲的内存则产生异常，占用0，空闲0
c0107542:	8b 45 f4             	mov    -0xc(%ebp),%eax
c0107545:	83 c0 04             	add    $0x4,%eax
c0107548:	c7 45 ec 00 00 00 00 	movl   $0x0,-0x14(%ebp)
c010754f:	89 45 e8             	mov    %eax,-0x18(%ebp)
    asm volatile ("btl %2, %1; sbbl %0,%0" : "=r" (oldbit) : "m" (*(volatile long *)addr), "Ir" (nr));
c0107552:	8b 45 e8             	mov    -0x18(%ebp),%eax
c0107555:	8b 55 ec             	mov    -0x14(%ebp),%edx
c0107558:	0f a3 10             	bt     %edx,(%eax)
c010755b:	19 c0                	sbb    %eax,%eax
c010755d:	89 45 e4             	mov    %eax,-0x1c(%ebp)
    return oldbit != 0;
c0107560:	83 7d e4 00          	cmpl   $0x0,-0x1c(%ebp)
c0107564:	0f 95 c0             	setne  %al
c0107567:	0f b6 c0             	movzbl %al,%eax
c010756a:	85 c0                	test   %eax,%eax
c010756c:	75 2c                	jne    c010759a <default_free_pages+0x96>
c010756e:	8b 45 f4             	mov    -0xc(%ebp),%eax
c0107571:	83 c0 04             	add    $0x4,%eax
c0107574:	c7 45 e0 01 00 00 00 	movl   $0x1,-0x20(%ebp)
c010757b:	89 45 dc             	mov    %eax,-0x24(%ebp)
    asm volatile ("btl %2, %1; sbbl %0,%0" : "=r" (oldbit) : "m" (*(volatile long *)addr), "Ir" (nr));
c010757e:	8b 45 dc             	mov    -0x24(%ebp),%eax
c0107581:	8b 55 e0             	mov    -0x20(%ebp),%edx
c0107584:	0f a3 10             	bt     %edx,(%eax)
c0107587:	19 c0                	sbb    %eax,%eax
c0107589:	89 45 d8             	mov    %eax,-0x28(%ebp)
    return oldbit != 0;
c010758c:	83 7d d8 00          	cmpl   $0x0,-0x28(%ebp)
c0107590:	0f 95 c0             	setne  %al
c0107593:	0f b6 c0             	movzbl %al,%eax
c0107596:	85 c0                	test   %eax,%eax
c0107598:	74 24                	je     c01075be <default_free_pages+0xba>
c010759a:	c7 44 24 0c 7c b8 10 	movl   $0xc010b87c,0xc(%esp)
c01075a1:	c0 
c01075a2:	c7 44 24 08 3e b8 10 	movl   $0xc010b83e,0x8(%esp)
c01075a9:	c0 
c01075aa:	c7 44 24 04 9c 00 00 	movl   $0x9c,0x4(%esp)
c01075b1:	00 
c01075b2:	c7 04 24 53 b8 10 c0 	movl   $0xc010b853,(%esp)
c01075b9:	e8 42 8e ff ff       	call   c0100400 <__panic>
        p->flags = 0;      
c01075be:	8b 45 f4             	mov    -0xc(%ebp),%eax
c01075c1:	c7 40 04 00 00 00 00 	movl   $0x0,0x4(%eax)
        set_page_ref(p, 0);
c01075c8:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
c01075cf:	00 
c01075d0:	8b 45 f4             	mov    -0xc(%ebp),%eax
c01075d3:	89 04 24             	mov    %eax,(%esp)
c01075d6:	e8 1d fc ff ff       	call   c01071f8 <set_page_ref>
    for (; p != base + n; p ++) {
c01075db:	83 45 f4 20          	addl   $0x20,-0xc(%ebp)
c01075df:	8b 45 0c             	mov    0xc(%ebp),%eax
c01075e2:	c1 e0 05             	shl    $0x5,%eax
c01075e5:	89 c2                	mov    %eax,%edx
c01075e7:	8b 45 08             	mov    0x8(%ebp),%eax
c01075ea:	01 d0                	add    %edx,%eax
c01075ec:	39 45 f4             	cmp    %eax,-0xc(%ebp)
c01075ef:	0f 85 4d ff ff ff    	jne    c0107542 <default_free_pages+0x3e>
    }
    base->property = n;
c01075f5:	8b 45 08             	mov    0x8(%ebp),%eax
c01075f8:	8b 55 0c             	mov    0xc(%ebp),%edx
c01075fb:	89 50 08             	mov    %edx,0x8(%eax)
    SetPageProperty(base);
c01075fe:	8b 45 08             	mov    0x8(%ebp),%eax
c0107601:	83 c0 04             	add    $0x4,%eax
c0107604:	c7 45 d0 01 00 00 00 	movl   $0x1,-0x30(%ebp)
c010760b:	89 45 cc             	mov    %eax,-0x34(%ebp)
    asm volatile ("btsl %1, %0" :"=m" (*(volatile long *)addr) : "Ir" (nr));
c010760e:	8b 45 cc             	mov    -0x34(%ebp),%eax
c0107611:	8b 55 d0             	mov    -0x30(%ebp),%edx
c0107614:	0f ab 10             	bts    %edx,(%eax)
c0107617:	c7 45 d4 44 b1 12 c0 	movl   $0xc012b144,-0x2c(%ebp)
    return listelm->next;
c010761e:	8b 45 d4             	mov    -0x2c(%ebp),%eax
c0107621:	8b 40 04             	mov    0x4(%eax),%eax
    list_entry_t *le = list_next(&free_list);
c0107624:	89 45 f0             	mov    %eax,-0x10(%ebp)
    while (le != &free_list) {
c0107627:	e9 fa 00 00 00       	jmp    c0107726 <default_free_pages+0x222>
        p = le2page(le, page_link);
c010762c:	8b 45 f0             	mov    -0x10(%ebp),%eax
c010762f:	83 e8 0c             	sub    $0xc,%eax
c0107632:	89 45 f4             	mov    %eax,-0xc(%ebp)
c0107635:	8b 45 f0             	mov    -0x10(%ebp),%eax
c0107638:	89 45 c8             	mov    %eax,-0x38(%ebp)
c010763b:	8b 45 c8             	mov    -0x38(%ebp),%eax
c010763e:	8b 40 04             	mov    0x4(%eax),%eax
        le = list_next(le);
c0107641:	89 45 f0             	mov    %eax,-0x10(%ebp)
        if (base + base->property == p) {       //向上合并
c0107644:	8b 45 08             	mov    0x8(%ebp),%eax
c0107647:	8b 40 08             	mov    0x8(%eax),%eax
c010764a:	c1 e0 05             	shl    $0x5,%eax
c010764d:	89 c2                	mov    %eax,%edx
c010764f:	8b 45 08             	mov    0x8(%ebp),%eax
c0107652:	01 d0                	add    %edx,%eax
c0107654:	39 45 f4             	cmp    %eax,-0xc(%ebp)
c0107657:	75 5a                	jne    c01076b3 <default_free_pages+0x1af>
            base->property += p->property;
c0107659:	8b 45 08             	mov    0x8(%ebp),%eax
c010765c:	8b 50 08             	mov    0x8(%eax),%edx
c010765f:	8b 45 f4             	mov    -0xc(%ebp),%eax
c0107662:	8b 40 08             	mov    0x8(%eax),%eax
c0107665:	01 c2                	add    %eax,%edx
c0107667:	8b 45 08             	mov    0x8(%ebp),%eax
c010766a:	89 50 08             	mov    %edx,0x8(%eax)
            ClearPageProperty(p);               //p不再是head page
c010766d:	8b 45 f4             	mov    -0xc(%ebp),%eax
c0107670:	83 c0 04             	add    $0x4,%eax
c0107673:	c7 45 b8 01 00 00 00 	movl   $0x1,-0x48(%ebp)
c010767a:	89 45 b4             	mov    %eax,-0x4c(%ebp)
    asm volatile ("btrl %1, %0" :"=m" (*(volatile long *)addr) : "Ir" (nr));
c010767d:	8b 45 b4             	mov    -0x4c(%ebp),%eax
c0107680:	8b 55 b8             	mov    -0x48(%ebp),%edx
c0107683:	0f b3 10             	btr    %edx,(%eax)
            list_del(&(p->page_link));
c0107686:	8b 45 f4             	mov    -0xc(%ebp),%eax
c0107689:	83 c0 0c             	add    $0xc,%eax
c010768c:	89 45 c4             	mov    %eax,-0x3c(%ebp)
    __list_del(listelm->prev, listelm->next);
c010768f:	8b 45 c4             	mov    -0x3c(%ebp),%eax
c0107692:	8b 40 04             	mov    0x4(%eax),%eax
c0107695:	8b 55 c4             	mov    -0x3c(%ebp),%edx
c0107698:	8b 12                	mov    (%edx),%edx
c010769a:	89 55 c0             	mov    %edx,-0x40(%ebp)
c010769d:	89 45 bc             	mov    %eax,-0x44(%ebp)
    prev->next = next;
c01076a0:	8b 45 c0             	mov    -0x40(%ebp),%eax
c01076a3:	8b 55 bc             	mov    -0x44(%ebp),%edx
c01076a6:	89 50 04             	mov    %edx,0x4(%eax)
    next->prev = prev;
c01076a9:	8b 45 bc             	mov    -0x44(%ebp),%eax
c01076ac:	8b 55 c0             	mov    -0x40(%ebp),%edx
c01076af:	89 10                	mov    %edx,(%eax)
c01076b1:	eb 73                	jmp    c0107726 <default_free_pages+0x222>
        }
        else if (p + p->property == base) {     //向下合并
c01076b3:	8b 45 f4             	mov    -0xc(%ebp),%eax
c01076b6:	8b 40 08             	mov    0x8(%eax),%eax
c01076b9:	c1 e0 05             	shl    $0x5,%eax
c01076bc:	89 c2                	mov    %eax,%edx
c01076be:	8b 45 f4             	mov    -0xc(%ebp),%eax
c01076c1:	01 d0                	add    %edx,%eax
c01076c3:	39 45 08             	cmp    %eax,0x8(%ebp)
c01076c6:	75 5e                	jne    c0107726 <default_free_pages+0x222>
            p->property += base->property;
c01076c8:	8b 45 f4             	mov    -0xc(%ebp),%eax
c01076cb:	8b 50 08             	mov    0x8(%eax),%edx
c01076ce:	8b 45 08             	mov    0x8(%ebp),%eax
c01076d1:	8b 40 08             	mov    0x8(%eax),%eax
c01076d4:	01 c2                	add    %eax,%edx
c01076d6:	8b 45 f4             	mov    -0xc(%ebp),%eax
c01076d9:	89 50 08             	mov    %edx,0x8(%eax)
            ClearPageProperty(base);            //base不再是head page
c01076dc:	8b 45 08             	mov    0x8(%ebp),%eax
c01076df:	83 c0 04             	add    $0x4,%eax
c01076e2:	c7 45 a4 01 00 00 00 	movl   $0x1,-0x5c(%ebp)
c01076e9:	89 45 a0             	mov    %eax,-0x60(%ebp)
c01076ec:	8b 45 a0             	mov    -0x60(%ebp),%eax
c01076ef:	8b 55 a4             	mov    -0x5c(%ebp),%edx
c01076f2:	0f b3 10             	btr    %edx,(%eax)
            base = p;                           //为了遍历，还用base
c01076f5:	8b 45 f4             	mov    -0xc(%ebp),%eax
c01076f8:	89 45 08             	mov    %eax,0x8(%ebp)
            list_del(&(p->page_link));
c01076fb:	8b 45 f4             	mov    -0xc(%ebp),%eax
c01076fe:	83 c0 0c             	add    $0xc,%eax
c0107701:	89 45 b0             	mov    %eax,-0x50(%ebp)
    __list_del(listelm->prev, listelm->next);
c0107704:	8b 45 b0             	mov    -0x50(%ebp),%eax
c0107707:	8b 40 04             	mov    0x4(%eax),%eax
c010770a:	8b 55 b0             	mov    -0x50(%ebp),%edx
c010770d:	8b 12                	mov    (%edx),%edx
c010770f:	89 55 ac             	mov    %edx,-0x54(%ebp)
c0107712:	89 45 a8             	mov    %eax,-0x58(%ebp)
    prev->next = next;
c0107715:	8b 45 ac             	mov    -0x54(%ebp),%eax
c0107718:	8b 55 a8             	mov    -0x58(%ebp),%edx
c010771b:	89 50 04             	mov    %edx,0x4(%eax)
    next->prev = prev;
c010771e:	8b 45 a8             	mov    -0x58(%ebp),%eax
c0107721:	8b 55 ac             	mov    -0x54(%ebp),%edx
c0107724:	89 10                	mov    %edx,(%eax)
    while (le != &free_list) {
c0107726:	81 7d f0 44 b1 12 c0 	cmpl   $0xc012b144,-0x10(%ebp)
c010772d:	0f 85 f9 fe ff ff    	jne    c010762c <default_free_pages+0x128>
        }
    }
    nr_free += n;
c0107733:	8b 15 4c b1 12 c0    	mov    0xc012b14c,%edx
c0107739:	8b 45 0c             	mov    0xc(%ebp),%eax
c010773c:	01 d0                	add    %edx,%eax
c010773e:	a3 4c b1 12 c0       	mov    %eax,0xc012b14c
c0107743:	c7 45 9c 44 b1 12 c0 	movl   $0xc012b144,-0x64(%ebp)
    return listelm->next;
c010774a:	8b 45 9c             	mov    -0x64(%ebp),%eax
c010774d:	8b 40 04             	mov    0x4(%eax),%eax
    le = list_next(&free_list);
c0107750:	89 45 f0             	mov    %eax,-0x10(%ebp)
    while (le != &free_list) {
c0107753:	eb 66                	jmp    c01077bb <default_free_pages+0x2b7>
        p = le2page(le, page_link);
c0107755:	8b 45 f0             	mov    -0x10(%ebp),%eax
c0107758:	83 e8 0c             	sub    $0xc,%eax
c010775b:	89 45 f4             	mov    %eax,-0xc(%ebp)
        if (base + base->property <= p) {       //不断遍历le对应的p页，当p比base + base->property 大了，就在前面插进来新的这个空闲块
c010775e:	8b 45 08             	mov    0x8(%ebp),%eax
c0107761:	8b 40 08             	mov    0x8(%eax),%eax
c0107764:	c1 e0 05             	shl    $0x5,%eax
c0107767:	89 c2                	mov    %eax,%edx
c0107769:	8b 45 08             	mov    0x8(%ebp),%eax
c010776c:	01 d0                	add    %edx,%eax
c010776e:	39 45 f4             	cmp    %eax,-0xc(%ebp)
c0107771:	72 39                	jb     c01077ac <default_free_pages+0x2a8>
            assert(base + base->property != p);     //如果相等，还需要合并，之前已做过合并检查，所以不应该相等
c0107773:	8b 45 08             	mov    0x8(%ebp),%eax
c0107776:	8b 40 08             	mov    0x8(%eax),%eax
c0107779:	c1 e0 05             	shl    $0x5,%eax
c010777c:	89 c2                	mov    %eax,%edx
c010777e:	8b 45 08             	mov    0x8(%ebp),%eax
c0107781:	01 d0                	add    %edx,%eax
c0107783:	39 45 f4             	cmp    %eax,-0xc(%ebp)
c0107786:	75 3e                	jne    c01077c6 <default_free_pages+0x2c2>
c0107788:	c7 44 24 0c a1 b8 10 	movl   $0xc010b8a1,0xc(%esp)
c010778f:	c0 
c0107790:	c7 44 24 08 3e b8 10 	movl   $0xc010b83e,0x8(%esp)
c0107797:	c0 
c0107798:	c7 44 24 04 b7 00 00 	movl   $0xb7,0x4(%esp)
c010779f:	00 
c01077a0:	c7 04 24 53 b8 10 c0 	movl   $0xc010b853,(%esp)
c01077a7:	e8 54 8c ff ff       	call   c0100400 <__panic>
c01077ac:	8b 45 f0             	mov    -0x10(%ebp),%eax
c01077af:	89 45 98             	mov    %eax,-0x68(%ebp)
c01077b2:	8b 45 98             	mov    -0x68(%ebp),%eax
c01077b5:	8b 40 04             	mov    0x4(%eax),%eax
            break;
        }
        le = list_next(le);
c01077b8:	89 45 f0             	mov    %eax,-0x10(%ebp)
    while (le != &free_list) {
c01077bb:	81 7d f0 44 b1 12 c0 	cmpl   $0xc012b144,-0x10(%ebp)
c01077c2:	75 91                	jne    c0107755 <default_free_pages+0x251>
c01077c4:	eb 01                	jmp    c01077c7 <default_free_pages+0x2c3>
            break;
c01077c6:	90                   	nop
    }
    list_add_before(le, &(base->page_link));        //在p对应的链表项前插入base对应的链表项
c01077c7:	8b 45 08             	mov    0x8(%ebp),%eax
c01077ca:	8d 50 0c             	lea    0xc(%eax),%edx
c01077cd:	8b 45 f0             	mov    -0x10(%ebp),%eax
c01077d0:	89 45 94             	mov    %eax,-0x6c(%ebp)
c01077d3:	89 55 90             	mov    %edx,-0x70(%ebp)
    __list_add(elm, listelm->prev, listelm);
c01077d6:	8b 45 94             	mov    -0x6c(%ebp),%eax
c01077d9:	8b 00                	mov    (%eax),%eax
c01077db:	8b 55 90             	mov    -0x70(%ebp),%edx
c01077de:	89 55 8c             	mov    %edx,-0x74(%ebp)
c01077e1:	89 45 88             	mov    %eax,-0x78(%ebp)
c01077e4:	8b 45 94             	mov    -0x6c(%ebp),%eax
c01077e7:	89 45 84             	mov    %eax,-0x7c(%ebp)
    prev->next = next->prev = elm;
c01077ea:	8b 45 84             	mov    -0x7c(%ebp),%eax
c01077ed:	8b 55 8c             	mov    -0x74(%ebp),%edx
c01077f0:	89 10                	mov    %edx,(%eax)
c01077f2:	8b 45 84             	mov    -0x7c(%ebp),%eax
c01077f5:	8b 10                	mov    (%eax),%edx
c01077f7:	8b 45 88             	mov    -0x78(%ebp),%eax
c01077fa:	89 50 04             	mov    %edx,0x4(%eax)
    elm->next = next;
c01077fd:	8b 45 8c             	mov    -0x74(%ebp),%eax
c0107800:	8b 55 84             	mov    -0x7c(%ebp),%edx
c0107803:	89 50 04             	mov    %edx,0x4(%eax)
    elm->prev = prev;
c0107806:	8b 45 8c             	mov    -0x74(%ebp),%eax
c0107809:	8b 55 88             	mov    -0x78(%ebp),%edx
c010780c:	89 10                	mov    %edx,(%eax)
}
c010780e:	90                   	nop
c010780f:	c9                   	leave  
c0107810:	c3                   	ret    

c0107811 <default_nr_free_pages>:

static size_t
default_nr_free_pages(void) {
c0107811:	55                   	push   %ebp
c0107812:	89 e5                	mov    %esp,%ebp
    return nr_free;
c0107814:	a1 4c b1 12 c0       	mov    0xc012b14c,%eax
}
c0107819:	5d                   	pop    %ebp
c010781a:	c3                   	ret    

c010781b <basic_check>:

static void
basic_check(void) {
c010781b:	55                   	push   %ebp
c010781c:	89 e5                	mov    %esp,%ebp
c010781e:	83 ec 48             	sub    $0x48,%esp
    struct Page *p0, *p1, *p2;
    p0 = p1 = p2 = NULL;
c0107821:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
c0107828:	8b 45 f4             	mov    -0xc(%ebp),%eax
c010782b:	89 45 f0             	mov    %eax,-0x10(%ebp)
c010782e:	8b 45 f0             	mov    -0x10(%ebp),%eax
c0107831:	89 45 ec             	mov    %eax,-0x14(%ebp)
    assert((p0 = alloc_page()) != NULL);
c0107834:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
c010783b:	e8 0f bc ff ff       	call   c010344f <alloc_pages>
c0107840:	89 45 ec             	mov    %eax,-0x14(%ebp)
c0107843:	83 7d ec 00          	cmpl   $0x0,-0x14(%ebp)
c0107847:	75 24                	jne    c010786d <basic_check+0x52>
c0107849:	c7 44 24 0c bc b8 10 	movl   $0xc010b8bc,0xc(%esp)
c0107850:	c0 
c0107851:	c7 44 24 08 3e b8 10 	movl   $0xc010b83e,0x8(%esp)
c0107858:	c0 
c0107859:	c7 44 24 04 c8 00 00 	movl   $0xc8,0x4(%esp)
c0107860:	00 
c0107861:	c7 04 24 53 b8 10 c0 	movl   $0xc010b853,(%esp)
c0107868:	e8 93 8b ff ff       	call   c0100400 <__panic>
    assert((p1 = alloc_page()) != NULL);
c010786d:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
c0107874:	e8 d6 bb ff ff       	call   c010344f <alloc_pages>
c0107879:	89 45 f0             	mov    %eax,-0x10(%ebp)
c010787c:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
c0107880:	75 24                	jne    c01078a6 <basic_check+0x8b>
c0107882:	c7 44 24 0c d8 b8 10 	movl   $0xc010b8d8,0xc(%esp)
c0107889:	c0 
c010788a:	c7 44 24 08 3e b8 10 	movl   $0xc010b83e,0x8(%esp)
c0107891:	c0 
c0107892:	c7 44 24 04 c9 00 00 	movl   $0xc9,0x4(%esp)
c0107899:	00 
c010789a:	c7 04 24 53 b8 10 c0 	movl   $0xc010b853,(%esp)
c01078a1:	e8 5a 8b ff ff       	call   c0100400 <__panic>
    assert((p2 = alloc_page()) != NULL);
c01078a6:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
c01078ad:	e8 9d bb ff ff       	call   c010344f <alloc_pages>
c01078b2:	89 45 f4             	mov    %eax,-0xc(%ebp)
c01078b5:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
c01078b9:	75 24                	jne    c01078df <basic_check+0xc4>
c01078bb:	c7 44 24 0c f4 b8 10 	movl   $0xc010b8f4,0xc(%esp)
c01078c2:	c0 
c01078c3:	c7 44 24 08 3e b8 10 	movl   $0xc010b83e,0x8(%esp)
c01078ca:	c0 
c01078cb:	c7 44 24 04 ca 00 00 	movl   $0xca,0x4(%esp)
c01078d2:	00 
c01078d3:	c7 04 24 53 b8 10 c0 	movl   $0xc010b853,(%esp)
c01078da:	e8 21 8b ff ff       	call   c0100400 <__panic>

    assert(p0 != p1 && p0 != p2 && p1 != p2);
c01078df:	8b 45 ec             	mov    -0x14(%ebp),%eax
c01078e2:	3b 45 f0             	cmp    -0x10(%ebp),%eax
c01078e5:	74 10                	je     c01078f7 <basic_check+0xdc>
c01078e7:	8b 45 ec             	mov    -0x14(%ebp),%eax
c01078ea:	3b 45 f4             	cmp    -0xc(%ebp),%eax
c01078ed:	74 08                	je     c01078f7 <basic_check+0xdc>
c01078ef:	8b 45 f0             	mov    -0x10(%ebp),%eax
c01078f2:	3b 45 f4             	cmp    -0xc(%ebp),%eax
c01078f5:	75 24                	jne    c010791b <basic_check+0x100>
c01078f7:	c7 44 24 0c 10 b9 10 	movl   $0xc010b910,0xc(%esp)
c01078fe:	c0 
c01078ff:	c7 44 24 08 3e b8 10 	movl   $0xc010b83e,0x8(%esp)
c0107906:	c0 
c0107907:	c7 44 24 04 cc 00 00 	movl   $0xcc,0x4(%esp)
c010790e:	00 
c010790f:	c7 04 24 53 b8 10 c0 	movl   $0xc010b853,(%esp)
c0107916:	e8 e5 8a ff ff       	call   c0100400 <__panic>
    assert(page_ref(p0) == 0 && page_ref(p1) == 0 && page_ref(p2) == 0);
c010791b:	8b 45 ec             	mov    -0x14(%ebp),%eax
c010791e:	89 04 24             	mov    %eax,(%esp)
c0107921:	e8 c8 f8 ff ff       	call   c01071ee <page_ref>
c0107926:	85 c0                	test   %eax,%eax
c0107928:	75 1e                	jne    c0107948 <basic_check+0x12d>
c010792a:	8b 45 f0             	mov    -0x10(%ebp),%eax
c010792d:	89 04 24             	mov    %eax,(%esp)
c0107930:	e8 b9 f8 ff ff       	call   c01071ee <page_ref>
c0107935:	85 c0                	test   %eax,%eax
c0107937:	75 0f                	jne    c0107948 <basic_check+0x12d>
c0107939:	8b 45 f4             	mov    -0xc(%ebp),%eax
c010793c:	89 04 24             	mov    %eax,(%esp)
c010793f:	e8 aa f8 ff ff       	call   c01071ee <page_ref>
c0107944:	85 c0                	test   %eax,%eax
c0107946:	74 24                	je     c010796c <basic_check+0x151>
c0107948:	c7 44 24 0c 34 b9 10 	movl   $0xc010b934,0xc(%esp)
c010794f:	c0 
c0107950:	c7 44 24 08 3e b8 10 	movl   $0xc010b83e,0x8(%esp)
c0107957:	c0 
c0107958:	c7 44 24 04 cd 00 00 	movl   $0xcd,0x4(%esp)
c010795f:	00 
c0107960:	c7 04 24 53 b8 10 c0 	movl   $0xc010b853,(%esp)
c0107967:	e8 94 8a ff ff       	call   c0100400 <__panic>

    assert(page2pa(p0) < npage * PGSIZE);
c010796c:	8b 45 ec             	mov    -0x14(%ebp),%eax
c010796f:	89 04 24             	mov    %eax,(%esp)
c0107972:	e8 61 f8 ff ff       	call   c01071d8 <page2pa>
c0107977:	8b 15 80 8f 12 c0    	mov    0xc0128f80,%edx
c010797d:	c1 e2 0c             	shl    $0xc,%edx
c0107980:	39 d0                	cmp    %edx,%eax
c0107982:	72 24                	jb     c01079a8 <basic_check+0x18d>
c0107984:	c7 44 24 0c 70 b9 10 	movl   $0xc010b970,0xc(%esp)
c010798b:	c0 
c010798c:	c7 44 24 08 3e b8 10 	movl   $0xc010b83e,0x8(%esp)
c0107993:	c0 
c0107994:	c7 44 24 04 cf 00 00 	movl   $0xcf,0x4(%esp)
c010799b:	00 
c010799c:	c7 04 24 53 b8 10 c0 	movl   $0xc010b853,(%esp)
c01079a3:	e8 58 8a ff ff       	call   c0100400 <__panic>
    assert(page2pa(p1) < npage * PGSIZE);
c01079a8:	8b 45 f0             	mov    -0x10(%ebp),%eax
c01079ab:	89 04 24             	mov    %eax,(%esp)
c01079ae:	e8 25 f8 ff ff       	call   c01071d8 <page2pa>
c01079b3:	8b 15 80 8f 12 c0    	mov    0xc0128f80,%edx
c01079b9:	c1 e2 0c             	shl    $0xc,%edx
c01079bc:	39 d0                	cmp    %edx,%eax
c01079be:	72 24                	jb     c01079e4 <basic_check+0x1c9>
c01079c0:	c7 44 24 0c 8d b9 10 	movl   $0xc010b98d,0xc(%esp)
c01079c7:	c0 
c01079c8:	c7 44 24 08 3e b8 10 	movl   $0xc010b83e,0x8(%esp)
c01079cf:	c0 
c01079d0:	c7 44 24 04 d0 00 00 	movl   $0xd0,0x4(%esp)
c01079d7:	00 
c01079d8:	c7 04 24 53 b8 10 c0 	movl   $0xc010b853,(%esp)
c01079df:	e8 1c 8a ff ff       	call   c0100400 <__panic>
    assert(page2pa(p2) < npage * PGSIZE);
c01079e4:	8b 45 f4             	mov    -0xc(%ebp),%eax
c01079e7:	89 04 24             	mov    %eax,(%esp)
c01079ea:	e8 e9 f7 ff ff       	call   c01071d8 <page2pa>
c01079ef:	8b 15 80 8f 12 c0    	mov    0xc0128f80,%edx
c01079f5:	c1 e2 0c             	shl    $0xc,%edx
c01079f8:	39 d0                	cmp    %edx,%eax
c01079fa:	72 24                	jb     c0107a20 <basic_check+0x205>
c01079fc:	c7 44 24 0c aa b9 10 	movl   $0xc010b9aa,0xc(%esp)
c0107a03:	c0 
c0107a04:	c7 44 24 08 3e b8 10 	movl   $0xc010b83e,0x8(%esp)
c0107a0b:	c0 
c0107a0c:	c7 44 24 04 d1 00 00 	movl   $0xd1,0x4(%esp)
c0107a13:	00 
c0107a14:	c7 04 24 53 b8 10 c0 	movl   $0xc010b853,(%esp)
c0107a1b:	e8 e0 89 ff ff       	call   c0100400 <__panic>

    list_entry_t free_list_store = free_list;
c0107a20:	a1 44 b1 12 c0       	mov    0xc012b144,%eax
c0107a25:	8b 15 48 b1 12 c0    	mov    0xc012b148,%edx
c0107a2b:	89 45 d0             	mov    %eax,-0x30(%ebp)
c0107a2e:	89 55 d4             	mov    %edx,-0x2c(%ebp)
c0107a31:	c7 45 dc 44 b1 12 c0 	movl   $0xc012b144,-0x24(%ebp)
    elm->prev = elm->next = elm;
c0107a38:	8b 45 dc             	mov    -0x24(%ebp),%eax
c0107a3b:	8b 55 dc             	mov    -0x24(%ebp),%edx
c0107a3e:	89 50 04             	mov    %edx,0x4(%eax)
c0107a41:	8b 45 dc             	mov    -0x24(%ebp),%eax
c0107a44:	8b 50 04             	mov    0x4(%eax),%edx
c0107a47:	8b 45 dc             	mov    -0x24(%ebp),%eax
c0107a4a:	89 10                	mov    %edx,(%eax)
c0107a4c:	c7 45 e0 44 b1 12 c0 	movl   $0xc012b144,-0x20(%ebp)
    return list->next == list;
c0107a53:	8b 45 e0             	mov    -0x20(%ebp),%eax
c0107a56:	8b 40 04             	mov    0x4(%eax),%eax
c0107a59:	39 45 e0             	cmp    %eax,-0x20(%ebp)
c0107a5c:	0f 94 c0             	sete   %al
c0107a5f:	0f b6 c0             	movzbl %al,%eax
    list_init(&free_list);
    assert(list_empty(&free_list));
c0107a62:	85 c0                	test   %eax,%eax
c0107a64:	75 24                	jne    c0107a8a <basic_check+0x26f>
c0107a66:	c7 44 24 0c c7 b9 10 	movl   $0xc010b9c7,0xc(%esp)
c0107a6d:	c0 
c0107a6e:	c7 44 24 08 3e b8 10 	movl   $0xc010b83e,0x8(%esp)
c0107a75:	c0 
c0107a76:	c7 44 24 04 d5 00 00 	movl   $0xd5,0x4(%esp)
c0107a7d:	00 
c0107a7e:	c7 04 24 53 b8 10 c0 	movl   $0xc010b853,(%esp)
c0107a85:	e8 76 89 ff ff       	call   c0100400 <__panic>

    unsigned int nr_free_store = nr_free;
c0107a8a:	a1 4c b1 12 c0       	mov    0xc012b14c,%eax
c0107a8f:	89 45 e8             	mov    %eax,-0x18(%ebp)
    nr_free = 0;
c0107a92:	c7 05 4c b1 12 c0 00 	movl   $0x0,0xc012b14c
c0107a99:	00 00 00 

    assert(alloc_page() == NULL);
c0107a9c:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
c0107aa3:	e8 a7 b9 ff ff       	call   c010344f <alloc_pages>
c0107aa8:	85 c0                	test   %eax,%eax
c0107aaa:	74 24                	je     c0107ad0 <basic_check+0x2b5>
c0107aac:	c7 44 24 0c de b9 10 	movl   $0xc010b9de,0xc(%esp)
c0107ab3:	c0 
c0107ab4:	c7 44 24 08 3e b8 10 	movl   $0xc010b83e,0x8(%esp)
c0107abb:	c0 
c0107abc:	c7 44 24 04 da 00 00 	movl   $0xda,0x4(%esp)
c0107ac3:	00 
c0107ac4:	c7 04 24 53 b8 10 c0 	movl   $0xc010b853,(%esp)
c0107acb:	e8 30 89 ff ff       	call   c0100400 <__panic>

    free_page(p0);
c0107ad0:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
c0107ad7:	00 
c0107ad8:	8b 45 ec             	mov    -0x14(%ebp),%eax
c0107adb:	89 04 24             	mov    %eax,(%esp)
c0107ade:	e8 d7 b9 ff ff       	call   c01034ba <free_pages>
    free_page(p1);
c0107ae3:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
c0107aea:	00 
c0107aeb:	8b 45 f0             	mov    -0x10(%ebp),%eax
c0107aee:	89 04 24             	mov    %eax,(%esp)
c0107af1:	e8 c4 b9 ff ff       	call   c01034ba <free_pages>
    free_page(p2);
c0107af6:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
c0107afd:	00 
c0107afe:	8b 45 f4             	mov    -0xc(%ebp),%eax
c0107b01:	89 04 24             	mov    %eax,(%esp)
c0107b04:	e8 b1 b9 ff ff       	call   c01034ba <free_pages>
    assert(nr_free == 3);
c0107b09:	a1 4c b1 12 c0       	mov    0xc012b14c,%eax
c0107b0e:	83 f8 03             	cmp    $0x3,%eax
c0107b11:	74 24                	je     c0107b37 <basic_check+0x31c>
c0107b13:	c7 44 24 0c f3 b9 10 	movl   $0xc010b9f3,0xc(%esp)
c0107b1a:	c0 
c0107b1b:	c7 44 24 08 3e b8 10 	movl   $0xc010b83e,0x8(%esp)
c0107b22:	c0 
c0107b23:	c7 44 24 04 df 00 00 	movl   $0xdf,0x4(%esp)
c0107b2a:	00 
c0107b2b:	c7 04 24 53 b8 10 c0 	movl   $0xc010b853,(%esp)
c0107b32:	e8 c9 88 ff ff       	call   c0100400 <__panic>

    assert((p0 = alloc_page()) != NULL);
c0107b37:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
c0107b3e:	e8 0c b9 ff ff       	call   c010344f <alloc_pages>
c0107b43:	89 45 ec             	mov    %eax,-0x14(%ebp)
c0107b46:	83 7d ec 00          	cmpl   $0x0,-0x14(%ebp)
c0107b4a:	75 24                	jne    c0107b70 <basic_check+0x355>
c0107b4c:	c7 44 24 0c bc b8 10 	movl   $0xc010b8bc,0xc(%esp)
c0107b53:	c0 
c0107b54:	c7 44 24 08 3e b8 10 	movl   $0xc010b83e,0x8(%esp)
c0107b5b:	c0 
c0107b5c:	c7 44 24 04 e1 00 00 	movl   $0xe1,0x4(%esp)
c0107b63:	00 
c0107b64:	c7 04 24 53 b8 10 c0 	movl   $0xc010b853,(%esp)
c0107b6b:	e8 90 88 ff ff       	call   c0100400 <__panic>
    assert((p1 = alloc_page()) != NULL);
c0107b70:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
c0107b77:	e8 d3 b8 ff ff       	call   c010344f <alloc_pages>
c0107b7c:	89 45 f0             	mov    %eax,-0x10(%ebp)
c0107b7f:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
c0107b83:	75 24                	jne    c0107ba9 <basic_check+0x38e>
c0107b85:	c7 44 24 0c d8 b8 10 	movl   $0xc010b8d8,0xc(%esp)
c0107b8c:	c0 
c0107b8d:	c7 44 24 08 3e b8 10 	movl   $0xc010b83e,0x8(%esp)
c0107b94:	c0 
c0107b95:	c7 44 24 04 e2 00 00 	movl   $0xe2,0x4(%esp)
c0107b9c:	00 
c0107b9d:	c7 04 24 53 b8 10 c0 	movl   $0xc010b853,(%esp)
c0107ba4:	e8 57 88 ff ff       	call   c0100400 <__panic>
    assert((p2 = alloc_page()) != NULL);
c0107ba9:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
c0107bb0:	e8 9a b8 ff ff       	call   c010344f <alloc_pages>
c0107bb5:	89 45 f4             	mov    %eax,-0xc(%ebp)
c0107bb8:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
c0107bbc:	75 24                	jne    c0107be2 <basic_check+0x3c7>
c0107bbe:	c7 44 24 0c f4 b8 10 	movl   $0xc010b8f4,0xc(%esp)
c0107bc5:	c0 
c0107bc6:	c7 44 24 08 3e b8 10 	movl   $0xc010b83e,0x8(%esp)
c0107bcd:	c0 
c0107bce:	c7 44 24 04 e3 00 00 	movl   $0xe3,0x4(%esp)
c0107bd5:	00 
c0107bd6:	c7 04 24 53 b8 10 c0 	movl   $0xc010b853,(%esp)
c0107bdd:	e8 1e 88 ff ff       	call   c0100400 <__panic>

    assert(alloc_page() == NULL);
c0107be2:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
c0107be9:	e8 61 b8 ff ff       	call   c010344f <alloc_pages>
c0107bee:	85 c0                	test   %eax,%eax
c0107bf0:	74 24                	je     c0107c16 <basic_check+0x3fb>
c0107bf2:	c7 44 24 0c de b9 10 	movl   $0xc010b9de,0xc(%esp)
c0107bf9:	c0 
c0107bfa:	c7 44 24 08 3e b8 10 	movl   $0xc010b83e,0x8(%esp)
c0107c01:	c0 
c0107c02:	c7 44 24 04 e5 00 00 	movl   $0xe5,0x4(%esp)
c0107c09:	00 
c0107c0a:	c7 04 24 53 b8 10 c0 	movl   $0xc010b853,(%esp)
c0107c11:	e8 ea 87 ff ff       	call   c0100400 <__panic>

    free_page(p0);
c0107c16:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
c0107c1d:	00 
c0107c1e:	8b 45 ec             	mov    -0x14(%ebp),%eax
c0107c21:	89 04 24             	mov    %eax,(%esp)
c0107c24:	e8 91 b8 ff ff       	call   c01034ba <free_pages>
c0107c29:	c7 45 d8 44 b1 12 c0 	movl   $0xc012b144,-0x28(%ebp)
c0107c30:	8b 45 d8             	mov    -0x28(%ebp),%eax
c0107c33:	8b 40 04             	mov    0x4(%eax),%eax
c0107c36:	39 45 d8             	cmp    %eax,-0x28(%ebp)
c0107c39:	0f 94 c0             	sete   %al
c0107c3c:	0f b6 c0             	movzbl %al,%eax
    assert(!list_empty(&free_list));
c0107c3f:	85 c0                	test   %eax,%eax
c0107c41:	74 24                	je     c0107c67 <basic_check+0x44c>
c0107c43:	c7 44 24 0c 00 ba 10 	movl   $0xc010ba00,0xc(%esp)
c0107c4a:	c0 
c0107c4b:	c7 44 24 08 3e b8 10 	movl   $0xc010b83e,0x8(%esp)
c0107c52:	c0 
c0107c53:	c7 44 24 04 e8 00 00 	movl   $0xe8,0x4(%esp)
c0107c5a:	00 
c0107c5b:	c7 04 24 53 b8 10 c0 	movl   $0xc010b853,(%esp)
c0107c62:	e8 99 87 ff ff       	call   c0100400 <__panic>

    struct Page *p;
    assert((p = alloc_page()) == p0);
c0107c67:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
c0107c6e:	e8 dc b7 ff ff       	call   c010344f <alloc_pages>
c0107c73:	89 45 e4             	mov    %eax,-0x1c(%ebp)
c0107c76:	8b 45 e4             	mov    -0x1c(%ebp),%eax
c0107c79:	3b 45 ec             	cmp    -0x14(%ebp),%eax
c0107c7c:	74 24                	je     c0107ca2 <basic_check+0x487>
c0107c7e:	c7 44 24 0c 18 ba 10 	movl   $0xc010ba18,0xc(%esp)
c0107c85:	c0 
c0107c86:	c7 44 24 08 3e b8 10 	movl   $0xc010b83e,0x8(%esp)
c0107c8d:	c0 
c0107c8e:	c7 44 24 04 eb 00 00 	movl   $0xeb,0x4(%esp)
c0107c95:	00 
c0107c96:	c7 04 24 53 b8 10 c0 	movl   $0xc010b853,(%esp)
c0107c9d:	e8 5e 87 ff ff       	call   c0100400 <__panic>
    assert(alloc_page() == NULL);
c0107ca2:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
c0107ca9:	e8 a1 b7 ff ff       	call   c010344f <alloc_pages>
c0107cae:	85 c0                	test   %eax,%eax
c0107cb0:	74 24                	je     c0107cd6 <basic_check+0x4bb>
c0107cb2:	c7 44 24 0c de b9 10 	movl   $0xc010b9de,0xc(%esp)
c0107cb9:	c0 
c0107cba:	c7 44 24 08 3e b8 10 	movl   $0xc010b83e,0x8(%esp)
c0107cc1:	c0 
c0107cc2:	c7 44 24 04 ec 00 00 	movl   $0xec,0x4(%esp)
c0107cc9:	00 
c0107cca:	c7 04 24 53 b8 10 c0 	movl   $0xc010b853,(%esp)
c0107cd1:	e8 2a 87 ff ff       	call   c0100400 <__panic>

    assert(nr_free == 0);
c0107cd6:	a1 4c b1 12 c0       	mov    0xc012b14c,%eax
c0107cdb:	85 c0                	test   %eax,%eax
c0107cdd:	74 24                	je     c0107d03 <basic_check+0x4e8>
c0107cdf:	c7 44 24 0c 31 ba 10 	movl   $0xc010ba31,0xc(%esp)
c0107ce6:	c0 
c0107ce7:	c7 44 24 08 3e b8 10 	movl   $0xc010b83e,0x8(%esp)
c0107cee:	c0 
c0107cef:	c7 44 24 04 ee 00 00 	movl   $0xee,0x4(%esp)
c0107cf6:	00 
c0107cf7:	c7 04 24 53 b8 10 c0 	movl   $0xc010b853,(%esp)
c0107cfe:	e8 fd 86 ff ff       	call   c0100400 <__panic>
    free_list = free_list_store;
c0107d03:	8b 45 d0             	mov    -0x30(%ebp),%eax
c0107d06:	8b 55 d4             	mov    -0x2c(%ebp),%edx
c0107d09:	a3 44 b1 12 c0       	mov    %eax,0xc012b144
c0107d0e:	89 15 48 b1 12 c0    	mov    %edx,0xc012b148
    nr_free = nr_free_store;
c0107d14:	8b 45 e8             	mov    -0x18(%ebp),%eax
c0107d17:	a3 4c b1 12 c0       	mov    %eax,0xc012b14c

    free_page(p);
c0107d1c:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
c0107d23:	00 
c0107d24:	8b 45 e4             	mov    -0x1c(%ebp),%eax
c0107d27:	89 04 24             	mov    %eax,(%esp)
c0107d2a:	e8 8b b7 ff ff       	call   c01034ba <free_pages>
    free_page(p1);
c0107d2f:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
c0107d36:	00 
c0107d37:	8b 45 f0             	mov    -0x10(%ebp),%eax
c0107d3a:	89 04 24             	mov    %eax,(%esp)
c0107d3d:	e8 78 b7 ff ff       	call   c01034ba <free_pages>
    free_page(p2);
c0107d42:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
c0107d49:	00 
c0107d4a:	8b 45 f4             	mov    -0xc(%ebp),%eax
c0107d4d:	89 04 24             	mov    %eax,(%esp)
c0107d50:	e8 65 b7 ff ff       	call   c01034ba <free_pages>
}
c0107d55:	90                   	nop
c0107d56:	c9                   	leave  
c0107d57:	c3                   	ret    

c0107d58 <default_check>:

// LAB2: below code is used to check the first fit allocation algorithm (your EXERCISE 1) 
// NOTICE: You SHOULD NOT CHANGE basic_check, default_check functions!
static void
default_check(void) {
c0107d58:	55                   	push   %ebp
c0107d59:	89 e5                	mov    %esp,%ebp
c0107d5b:	81 ec 98 00 00 00    	sub    $0x98,%esp
    int count = 0, total = 0;
c0107d61:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
c0107d68:	c7 45 f0 00 00 00 00 	movl   $0x0,-0x10(%ebp)
    list_entry_t *le = &free_list;
c0107d6f:	c7 45 ec 44 b1 12 c0 	movl   $0xc012b144,-0x14(%ebp)
    while ((le = list_next(le)) != &free_list) {
c0107d76:	eb 6a                	jmp    c0107de2 <default_check+0x8a>
        struct Page *p = le2page(le, page_link);
c0107d78:	8b 45 ec             	mov    -0x14(%ebp),%eax
c0107d7b:	83 e8 0c             	sub    $0xc,%eax
c0107d7e:	89 45 d4             	mov    %eax,-0x2c(%ebp)
        assert(PageProperty(p));
c0107d81:	8b 45 d4             	mov    -0x2c(%ebp),%eax
c0107d84:	83 c0 04             	add    $0x4,%eax
c0107d87:	c7 45 d0 01 00 00 00 	movl   $0x1,-0x30(%ebp)
c0107d8e:	89 45 cc             	mov    %eax,-0x34(%ebp)
    asm volatile ("btl %2, %1; sbbl %0,%0" : "=r" (oldbit) : "m" (*(volatile long *)addr), "Ir" (nr));
c0107d91:	8b 45 cc             	mov    -0x34(%ebp),%eax
c0107d94:	8b 55 d0             	mov    -0x30(%ebp),%edx
c0107d97:	0f a3 10             	bt     %edx,(%eax)
c0107d9a:	19 c0                	sbb    %eax,%eax
c0107d9c:	89 45 c8             	mov    %eax,-0x38(%ebp)
    return oldbit != 0;
c0107d9f:	83 7d c8 00          	cmpl   $0x0,-0x38(%ebp)
c0107da3:	0f 95 c0             	setne  %al
c0107da6:	0f b6 c0             	movzbl %al,%eax
c0107da9:	85 c0                	test   %eax,%eax
c0107dab:	75 24                	jne    c0107dd1 <default_check+0x79>
c0107dad:	c7 44 24 0c 3e ba 10 	movl   $0xc010ba3e,0xc(%esp)
c0107db4:	c0 
c0107db5:	c7 44 24 08 3e b8 10 	movl   $0xc010b83e,0x8(%esp)
c0107dbc:	c0 
c0107dbd:	c7 44 24 04 ff 00 00 	movl   $0xff,0x4(%esp)
c0107dc4:	00 
c0107dc5:	c7 04 24 53 b8 10 c0 	movl   $0xc010b853,(%esp)
c0107dcc:	e8 2f 86 ff ff       	call   c0100400 <__panic>
        count ++, total += p->property;
c0107dd1:	ff 45 f4             	incl   -0xc(%ebp)
c0107dd4:	8b 45 d4             	mov    -0x2c(%ebp),%eax
c0107dd7:	8b 50 08             	mov    0x8(%eax),%edx
c0107dda:	8b 45 f0             	mov    -0x10(%ebp),%eax
c0107ddd:	01 d0                	add    %edx,%eax
c0107ddf:	89 45 f0             	mov    %eax,-0x10(%ebp)
c0107de2:	8b 45 ec             	mov    -0x14(%ebp),%eax
c0107de5:	89 45 c4             	mov    %eax,-0x3c(%ebp)
    return listelm->next;
c0107de8:	8b 45 c4             	mov    -0x3c(%ebp),%eax
c0107deb:	8b 40 04             	mov    0x4(%eax),%eax
    while ((le = list_next(le)) != &free_list) {
c0107dee:	89 45 ec             	mov    %eax,-0x14(%ebp)
c0107df1:	81 7d ec 44 b1 12 c0 	cmpl   $0xc012b144,-0x14(%ebp)
c0107df8:	0f 85 7a ff ff ff    	jne    c0107d78 <default_check+0x20>
    }
    assert(total == nr_free_pages());
c0107dfe:	e8 ea b6 ff ff       	call   c01034ed <nr_free_pages>
c0107e03:	89 c2                	mov    %eax,%edx
c0107e05:	8b 45 f0             	mov    -0x10(%ebp),%eax
c0107e08:	39 c2                	cmp    %eax,%edx
c0107e0a:	74 24                	je     c0107e30 <default_check+0xd8>
c0107e0c:	c7 44 24 0c 4e ba 10 	movl   $0xc010ba4e,0xc(%esp)
c0107e13:	c0 
c0107e14:	c7 44 24 08 3e b8 10 	movl   $0xc010b83e,0x8(%esp)
c0107e1b:	c0 
c0107e1c:	c7 44 24 04 02 01 00 	movl   $0x102,0x4(%esp)
c0107e23:	00 
c0107e24:	c7 04 24 53 b8 10 c0 	movl   $0xc010b853,(%esp)
c0107e2b:	e8 d0 85 ff ff       	call   c0100400 <__panic>

    basic_check();
c0107e30:	e8 e6 f9 ff ff       	call   c010781b <basic_check>

    struct Page *p0 = alloc_pages(5), *p1, *p2;
c0107e35:	c7 04 24 05 00 00 00 	movl   $0x5,(%esp)
c0107e3c:	e8 0e b6 ff ff       	call   c010344f <alloc_pages>
c0107e41:	89 45 e8             	mov    %eax,-0x18(%ebp)
    assert(p0 != NULL);
c0107e44:	83 7d e8 00          	cmpl   $0x0,-0x18(%ebp)
c0107e48:	75 24                	jne    c0107e6e <default_check+0x116>
c0107e4a:	c7 44 24 0c 67 ba 10 	movl   $0xc010ba67,0xc(%esp)
c0107e51:	c0 
c0107e52:	c7 44 24 08 3e b8 10 	movl   $0xc010b83e,0x8(%esp)
c0107e59:	c0 
c0107e5a:	c7 44 24 04 07 01 00 	movl   $0x107,0x4(%esp)
c0107e61:	00 
c0107e62:	c7 04 24 53 b8 10 c0 	movl   $0xc010b853,(%esp)
c0107e69:	e8 92 85 ff ff       	call   c0100400 <__panic>
    assert(!PageProperty(p0));
c0107e6e:	8b 45 e8             	mov    -0x18(%ebp),%eax
c0107e71:	83 c0 04             	add    $0x4,%eax
c0107e74:	c7 45 c0 01 00 00 00 	movl   $0x1,-0x40(%ebp)
c0107e7b:	89 45 bc             	mov    %eax,-0x44(%ebp)
    asm volatile ("btl %2, %1; sbbl %0,%0" : "=r" (oldbit) : "m" (*(volatile long *)addr), "Ir" (nr));
c0107e7e:	8b 45 bc             	mov    -0x44(%ebp),%eax
c0107e81:	8b 55 c0             	mov    -0x40(%ebp),%edx
c0107e84:	0f a3 10             	bt     %edx,(%eax)
c0107e87:	19 c0                	sbb    %eax,%eax
c0107e89:	89 45 b8             	mov    %eax,-0x48(%ebp)
    return oldbit != 0;
c0107e8c:	83 7d b8 00          	cmpl   $0x0,-0x48(%ebp)
c0107e90:	0f 95 c0             	setne  %al
c0107e93:	0f b6 c0             	movzbl %al,%eax
c0107e96:	85 c0                	test   %eax,%eax
c0107e98:	74 24                	je     c0107ebe <default_check+0x166>
c0107e9a:	c7 44 24 0c 72 ba 10 	movl   $0xc010ba72,0xc(%esp)
c0107ea1:	c0 
c0107ea2:	c7 44 24 08 3e b8 10 	movl   $0xc010b83e,0x8(%esp)
c0107ea9:	c0 
c0107eaa:	c7 44 24 04 08 01 00 	movl   $0x108,0x4(%esp)
c0107eb1:	00 
c0107eb2:	c7 04 24 53 b8 10 c0 	movl   $0xc010b853,(%esp)
c0107eb9:	e8 42 85 ff ff       	call   c0100400 <__panic>

    list_entry_t free_list_store = free_list;
c0107ebe:	a1 44 b1 12 c0       	mov    0xc012b144,%eax
c0107ec3:	8b 15 48 b1 12 c0    	mov    0xc012b148,%edx
c0107ec9:	89 45 80             	mov    %eax,-0x80(%ebp)
c0107ecc:	89 55 84             	mov    %edx,-0x7c(%ebp)
c0107ecf:	c7 45 b0 44 b1 12 c0 	movl   $0xc012b144,-0x50(%ebp)
    elm->prev = elm->next = elm;
c0107ed6:	8b 45 b0             	mov    -0x50(%ebp),%eax
c0107ed9:	8b 55 b0             	mov    -0x50(%ebp),%edx
c0107edc:	89 50 04             	mov    %edx,0x4(%eax)
c0107edf:	8b 45 b0             	mov    -0x50(%ebp),%eax
c0107ee2:	8b 50 04             	mov    0x4(%eax),%edx
c0107ee5:	8b 45 b0             	mov    -0x50(%ebp),%eax
c0107ee8:	89 10                	mov    %edx,(%eax)
c0107eea:	c7 45 b4 44 b1 12 c0 	movl   $0xc012b144,-0x4c(%ebp)
    return list->next == list;
c0107ef1:	8b 45 b4             	mov    -0x4c(%ebp),%eax
c0107ef4:	8b 40 04             	mov    0x4(%eax),%eax
c0107ef7:	39 45 b4             	cmp    %eax,-0x4c(%ebp)
c0107efa:	0f 94 c0             	sete   %al
c0107efd:	0f b6 c0             	movzbl %al,%eax
    list_init(&free_list);
    assert(list_empty(&free_list));
c0107f00:	85 c0                	test   %eax,%eax
c0107f02:	75 24                	jne    c0107f28 <default_check+0x1d0>
c0107f04:	c7 44 24 0c c7 b9 10 	movl   $0xc010b9c7,0xc(%esp)
c0107f0b:	c0 
c0107f0c:	c7 44 24 08 3e b8 10 	movl   $0xc010b83e,0x8(%esp)
c0107f13:	c0 
c0107f14:	c7 44 24 04 0c 01 00 	movl   $0x10c,0x4(%esp)
c0107f1b:	00 
c0107f1c:	c7 04 24 53 b8 10 c0 	movl   $0xc010b853,(%esp)
c0107f23:	e8 d8 84 ff ff       	call   c0100400 <__panic>
    assert(alloc_page() == NULL);
c0107f28:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
c0107f2f:	e8 1b b5 ff ff       	call   c010344f <alloc_pages>
c0107f34:	85 c0                	test   %eax,%eax
c0107f36:	74 24                	je     c0107f5c <default_check+0x204>
c0107f38:	c7 44 24 0c de b9 10 	movl   $0xc010b9de,0xc(%esp)
c0107f3f:	c0 
c0107f40:	c7 44 24 08 3e b8 10 	movl   $0xc010b83e,0x8(%esp)
c0107f47:	c0 
c0107f48:	c7 44 24 04 0d 01 00 	movl   $0x10d,0x4(%esp)
c0107f4f:	00 
c0107f50:	c7 04 24 53 b8 10 c0 	movl   $0xc010b853,(%esp)
c0107f57:	e8 a4 84 ff ff       	call   c0100400 <__panic>

    unsigned int nr_free_store = nr_free;
c0107f5c:	a1 4c b1 12 c0       	mov    0xc012b14c,%eax
c0107f61:	89 45 e4             	mov    %eax,-0x1c(%ebp)
    nr_free = 0;
c0107f64:	c7 05 4c b1 12 c0 00 	movl   $0x0,0xc012b14c
c0107f6b:	00 00 00 

    free_pages(p0 + 2, 3);
c0107f6e:	8b 45 e8             	mov    -0x18(%ebp),%eax
c0107f71:	83 c0 40             	add    $0x40,%eax
c0107f74:	c7 44 24 04 03 00 00 	movl   $0x3,0x4(%esp)
c0107f7b:	00 
c0107f7c:	89 04 24             	mov    %eax,(%esp)
c0107f7f:	e8 36 b5 ff ff       	call   c01034ba <free_pages>
    assert(alloc_pages(4) == NULL);
c0107f84:	c7 04 24 04 00 00 00 	movl   $0x4,(%esp)
c0107f8b:	e8 bf b4 ff ff       	call   c010344f <alloc_pages>
c0107f90:	85 c0                	test   %eax,%eax
c0107f92:	74 24                	je     c0107fb8 <default_check+0x260>
c0107f94:	c7 44 24 0c 84 ba 10 	movl   $0xc010ba84,0xc(%esp)
c0107f9b:	c0 
c0107f9c:	c7 44 24 08 3e b8 10 	movl   $0xc010b83e,0x8(%esp)
c0107fa3:	c0 
c0107fa4:	c7 44 24 04 13 01 00 	movl   $0x113,0x4(%esp)
c0107fab:	00 
c0107fac:	c7 04 24 53 b8 10 c0 	movl   $0xc010b853,(%esp)
c0107fb3:	e8 48 84 ff ff       	call   c0100400 <__panic>
    assert(PageProperty(p0 + 2) && p0[2].property == 3);
c0107fb8:	8b 45 e8             	mov    -0x18(%ebp),%eax
c0107fbb:	83 c0 40             	add    $0x40,%eax
c0107fbe:	83 c0 04             	add    $0x4,%eax
c0107fc1:	c7 45 ac 01 00 00 00 	movl   $0x1,-0x54(%ebp)
c0107fc8:	89 45 a8             	mov    %eax,-0x58(%ebp)
    asm volatile ("btl %2, %1; sbbl %0,%0" : "=r" (oldbit) : "m" (*(volatile long *)addr), "Ir" (nr));
c0107fcb:	8b 45 a8             	mov    -0x58(%ebp),%eax
c0107fce:	8b 55 ac             	mov    -0x54(%ebp),%edx
c0107fd1:	0f a3 10             	bt     %edx,(%eax)
c0107fd4:	19 c0                	sbb    %eax,%eax
c0107fd6:	89 45 a4             	mov    %eax,-0x5c(%ebp)
    return oldbit != 0;
c0107fd9:	83 7d a4 00          	cmpl   $0x0,-0x5c(%ebp)
c0107fdd:	0f 95 c0             	setne  %al
c0107fe0:	0f b6 c0             	movzbl %al,%eax
c0107fe3:	85 c0                	test   %eax,%eax
c0107fe5:	74 0e                	je     c0107ff5 <default_check+0x29d>
c0107fe7:	8b 45 e8             	mov    -0x18(%ebp),%eax
c0107fea:	83 c0 40             	add    $0x40,%eax
c0107fed:	8b 40 08             	mov    0x8(%eax),%eax
c0107ff0:	83 f8 03             	cmp    $0x3,%eax
c0107ff3:	74 24                	je     c0108019 <default_check+0x2c1>
c0107ff5:	c7 44 24 0c 9c ba 10 	movl   $0xc010ba9c,0xc(%esp)
c0107ffc:	c0 
c0107ffd:	c7 44 24 08 3e b8 10 	movl   $0xc010b83e,0x8(%esp)
c0108004:	c0 
c0108005:	c7 44 24 04 14 01 00 	movl   $0x114,0x4(%esp)
c010800c:	00 
c010800d:	c7 04 24 53 b8 10 c0 	movl   $0xc010b853,(%esp)
c0108014:	e8 e7 83 ff ff       	call   c0100400 <__panic>
    assert((p1 = alloc_pages(3)) != NULL);
c0108019:	c7 04 24 03 00 00 00 	movl   $0x3,(%esp)
c0108020:	e8 2a b4 ff ff       	call   c010344f <alloc_pages>
c0108025:	89 45 e0             	mov    %eax,-0x20(%ebp)
c0108028:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
c010802c:	75 24                	jne    c0108052 <default_check+0x2fa>
c010802e:	c7 44 24 0c c8 ba 10 	movl   $0xc010bac8,0xc(%esp)
c0108035:	c0 
c0108036:	c7 44 24 08 3e b8 10 	movl   $0xc010b83e,0x8(%esp)
c010803d:	c0 
c010803e:	c7 44 24 04 15 01 00 	movl   $0x115,0x4(%esp)
c0108045:	00 
c0108046:	c7 04 24 53 b8 10 c0 	movl   $0xc010b853,(%esp)
c010804d:	e8 ae 83 ff ff       	call   c0100400 <__panic>
    assert(alloc_page() == NULL);
c0108052:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
c0108059:	e8 f1 b3 ff ff       	call   c010344f <alloc_pages>
c010805e:	85 c0                	test   %eax,%eax
c0108060:	74 24                	je     c0108086 <default_check+0x32e>
c0108062:	c7 44 24 0c de b9 10 	movl   $0xc010b9de,0xc(%esp)
c0108069:	c0 
c010806a:	c7 44 24 08 3e b8 10 	movl   $0xc010b83e,0x8(%esp)
c0108071:	c0 
c0108072:	c7 44 24 04 16 01 00 	movl   $0x116,0x4(%esp)
c0108079:	00 
c010807a:	c7 04 24 53 b8 10 c0 	movl   $0xc010b853,(%esp)
c0108081:	e8 7a 83 ff ff       	call   c0100400 <__panic>
    assert(p0 + 2 == p1);
c0108086:	8b 45 e8             	mov    -0x18(%ebp),%eax
c0108089:	83 c0 40             	add    $0x40,%eax
c010808c:	39 45 e0             	cmp    %eax,-0x20(%ebp)
c010808f:	74 24                	je     c01080b5 <default_check+0x35d>
c0108091:	c7 44 24 0c e6 ba 10 	movl   $0xc010bae6,0xc(%esp)
c0108098:	c0 
c0108099:	c7 44 24 08 3e b8 10 	movl   $0xc010b83e,0x8(%esp)
c01080a0:	c0 
c01080a1:	c7 44 24 04 17 01 00 	movl   $0x117,0x4(%esp)
c01080a8:	00 
c01080a9:	c7 04 24 53 b8 10 c0 	movl   $0xc010b853,(%esp)
c01080b0:	e8 4b 83 ff ff       	call   c0100400 <__panic>

    p2 = p0 + 1;
c01080b5:	8b 45 e8             	mov    -0x18(%ebp),%eax
c01080b8:	83 c0 20             	add    $0x20,%eax
c01080bb:	89 45 dc             	mov    %eax,-0x24(%ebp)
    free_page(p0);
c01080be:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
c01080c5:	00 
c01080c6:	8b 45 e8             	mov    -0x18(%ebp),%eax
c01080c9:	89 04 24             	mov    %eax,(%esp)
c01080cc:	e8 e9 b3 ff ff       	call   c01034ba <free_pages>
    free_pages(p1, 3);
c01080d1:	c7 44 24 04 03 00 00 	movl   $0x3,0x4(%esp)
c01080d8:	00 
c01080d9:	8b 45 e0             	mov    -0x20(%ebp),%eax
c01080dc:	89 04 24             	mov    %eax,(%esp)
c01080df:	e8 d6 b3 ff ff       	call   c01034ba <free_pages>
    assert(PageProperty(p0) && p0->property == 1);
c01080e4:	8b 45 e8             	mov    -0x18(%ebp),%eax
c01080e7:	83 c0 04             	add    $0x4,%eax
c01080ea:	c7 45 a0 01 00 00 00 	movl   $0x1,-0x60(%ebp)
c01080f1:	89 45 9c             	mov    %eax,-0x64(%ebp)
    asm volatile ("btl %2, %1; sbbl %0,%0" : "=r" (oldbit) : "m" (*(volatile long *)addr), "Ir" (nr));
c01080f4:	8b 45 9c             	mov    -0x64(%ebp),%eax
c01080f7:	8b 55 a0             	mov    -0x60(%ebp),%edx
c01080fa:	0f a3 10             	bt     %edx,(%eax)
c01080fd:	19 c0                	sbb    %eax,%eax
c01080ff:	89 45 98             	mov    %eax,-0x68(%ebp)
    return oldbit != 0;
c0108102:	83 7d 98 00          	cmpl   $0x0,-0x68(%ebp)
c0108106:	0f 95 c0             	setne  %al
c0108109:	0f b6 c0             	movzbl %al,%eax
c010810c:	85 c0                	test   %eax,%eax
c010810e:	74 0b                	je     c010811b <default_check+0x3c3>
c0108110:	8b 45 e8             	mov    -0x18(%ebp),%eax
c0108113:	8b 40 08             	mov    0x8(%eax),%eax
c0108116:	83 f8 01             	cmp    $0x1,%eax
c0108119:	74 24                	je     c010813f <default_check+0x3e7>
c010811b:	c7 44 24 0c f4 ba 10 	movl   $0xc010baf4,0xc(%esp)
c0108122:	c0 
c0108123:	c7 44 24 08 3e b8 10 	movl   $0xc010b83e,0x8(%esp)
c010812a:	c0 
c010812b:	c7 44 24 04 1c 01 00 	movl   $0x11c,0x4(%esp)
c0108132:	00 
c0108133:	c7 04 24 53 b8 10 c0 	movl   $0xc010b853,(%esp)
c010813a:	e8 c1 82 ff ff       	call   c0100400 <__panic>
    assert(PageProperty(p1) && p1->property == 3);
c010813f:	8b 45 e0             	mov    -0x20(%ebp),%eax
c0108142:	83 c0 04             	add    $0x4,%eax
c0108145:	c7 45 94 01 00 00 00 	movl   $0x1,-0x6c(%ebp)
c010814c:	89 45 90             	mov    %eax,-0x70(%ebp)
    asm volatile ("btl %2, %1; sbbl %0,%0" : "=r" (oldbit) : "m" (*(volatile long *)addr), "Ir" (nr));
c010814f:	8b 45 90             	mov    -0x70(%ebp),%eax
c0108152:	8b 55 94             	mov    -0x6c(%ebp),%edx
c0108155:	0f a3 10             	bt     %edx,(%eax)
c0108158:	19 c0                	sbb    %eax,%eax
c010815a:	89 45 8c             	mov    %eax,-0x74(%ebp)
    return oldbit != 0;
c010815d:	83 7d 8c 00          	cmpl   $0x0,-0x74(%ebp)
c0108161:	0f 95 c0             	setne  %al
c0108164:	0f b6 c0             	movzbl %al,%eax
c0108167:	85 c0                	test   %eax,%eax
c0108169:	74 0b                	je     c0108176 <default_check+0x41e>
c010816b:	8b 45 e0             	mov    -0x20(%ebp),%eax
c010816e:	8b 40 08             	mov    0x8(%eax),%eax
c0108171:	83 f8 03             	cmp    $0x3,%eax
c0108174:	74 24                	je     c010819a <default_check+0x442>
c0108176:	c7 44 24 0c 1c bb 10 	movl   $0xc010bb1c,0xc(%esp)
c010817d:	c0 
c010817e:	c7 44 24 08 3e b8 10 	movl   $0xc010b83e,0x8(%esp)
c0108185:	c0 
c0108186:	c7 44 24 04 1d 01 00 	movl   $0x11d,0x4(%esp)
c010818d:	00 
c010818e:	c7 04 24 53 b8 10 c0 	movl   $0xc010b853,(%esp)
c0108195:	e8 66 82 ff ff       	call   c0100400 <__panic>

    assert((p0 = alloc_page()) == p2 - 1);
c010819a:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
c01081a1:	e8 a9 b2 ff ff       	call   c010344f <alloc_pages>
c01081a6:	89 45 e8             	mov    %eax,-0x18(%ebp)
c01081a9:	8b 45 dc             	mov    -0x24(%ebp),%eax
c01081ac:	83 e8 20             	sub    $0x20,%eax
c01081af:	39 45 e8             	cmp    %eax,-0x18(%ebp)
c01081b2:	74 24                	je     c01081d8 <default_check+0x480>
c01081b4:	c7 44 24 0c 42 bb 10 	movl   $0xc010bb42,0xc(%esp)
c01081bb:	c0 
c01081bc:	c7 44 24 08 3e b8 10 	movl   $0xc010b83e,0x8(%esp)
c01081c3:	c0 
c01081c4:	c7 44 24 04 1f 01 00 	movl   $0x11f,0x4(%esp)
c01081cb:	00 
c01081cc:	c7 04 24 53 b8 10 c0 	movl   $0xc010b853,(%esp)
c01081d3:	e8 28 82 ff ff       	call   c0100400 <__panic>
    free_page(p0);
c01081d8:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
c01081df:	00 
c01081e0:	8b 45 e8             	mov    -0x18(%ebp),%eax
c01081e3:	89 04 24             	mov    %eax,(%esp)
c01081e6:	e8 cf b2 ff ff       	call   c01034ba <free_pages>
    assert((p0 = alloc_pages(2)) == p2 + 1);
c01081eb:	c7 04 24 02 00 00 00 	movl   $0x2,(%esp)
c01081f2:	e8 58 b2 ff ff       	call   c010344f <alloc_pages>
c01081f7:	89 45 e8             	mov    %eax,-0x18(%ebp)
c01081fa:	8b 45 dc             	mov    -0x24(%ebp),%eax
c01081fd:	83 c0 20             	add    $0x20,%eax
c0108200:	39 45 e8             	cmp    %eax,-0x18(%ebp)
c0108203:	74 24                	je     c0108229 <default_check+0x4d1>
c0108205:	c7 44 24 0c 60 bb 10 	movl   $0xc010bb60,0xc(%esp)
c010820c:	c0 
c010820d:	c7 44 24 08 3e b8 10 	movl   $0xc010b83e,0x8(%esp)
c0108214:	c0 
c0108215:	c7 44 24 04 21 01 00 	movl   $0x121,0x4(%esp)
c010821c:	00 
c010821d:	c7 04 24 53 b8 10 c0 	movl   $0xc010b853,(%esp)
c0108224:	e8 d7 81 ff ff       	call   c0100400 <__panic>

    free_pages(p0, 2);
c0108229:	c7 44 24 04 02 00 00 	movl   $0x2,0x4(%esp)
c0108230:	00 
c0108231:	8b 45 e8             	mov    -0x18(%ebp),%eax
c0108234:	89 04 24             	mov    %eax,(%esp)
c0108237:	e8 7e b2 ff ff       	call   c01034ba <free_pages>
    free_page(p2);
c010823c:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
c0108243:	00 
c0108244:	8b 45 dc             	mov    -0x24(%ebp),%eax
c0108247:	89 04 24             	mov    %eax,(%esp)
c010824a:	e8 6b b2 ff ff       	call   c01034ba <free_pages>

    assert((p0 = alloc_pages(5)) != NULL);
c010824f:	c7 04 24 05 00 00 00 	movl   $0x5,(%esp)
c0108256:	e8 f4 b1 ff ff       	call   c010344f <alloc_pages>
c010825b:	89 45 e8             	mov    %eax,-0x18(%ebp)
c010825e:	83 7d e8 00          	cmpl   $0x0,-0x18(%ebp)
c0108262:	75 24                	jne    c0108288 <default_check+0x530>
c0108264:	c7 44 24 0c 80 bb 10 	movl   $0xc010bb80,0xc(%esp)
c010826b:	c0 
c010826c:	c7 44 24 08 3e b8 10 	movl   $0xc010b83e,0x8(%esp)
c0108273:	c0 
c0108274:	c7 44 24 04 26 01 00 	movl   $0x126,0x4(%esp)
c010827b:	00 
c010827c:	c7 04 24 53 b8 10 c0 	movl   $0xc010b853,(%esp)
c0108283:	e8 78 81 ff ff       	call   c0100400 <__panic>
    assert(alloc_page() == NULL);
c0108288:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
c010828f:	e8 bb b1 ff ff       	call   c010344f <alloc_pages>
c0108294:	85 c0                	test   %eax,%eax
c0108296:	74 24                	je     c01082bc <default_check+0x564>
c0108298:	c7 44 24 0c de b9 10 	movl   $0xc010b9de,0xc(%esp)
c010829f:	c0 
c01082a0:	c7 44 24 08 3e b8 10 	movl   $0xc010b83e,0x8(%esp)
c01082a7:	c0 
c01082a8:	c7 44 24 04 27 01 00 	movl   $0x127,0x4(%esp)
c01082af:	00 
c01082b0:	c7 04 24 53 b8 10 c0 	movl   $0xc010b853,(%esp)
c01082b7:	e8 44 81 ff ff       	call   c0100400 <__panic>

    assert(nr_free == 0);
c01082bc:	a1 4c b1 12 c0       	mov    0xc012b14c,%eax
c01082c1:	85 c0                	test   %eax,%eax
c01082c3:	74 24                	je     c01082e9 <default_check+0x591>
c01082c5:	c7 44 24 0c 31 ba 10 	movl   $0xc010ba31,0xc(%esp)
c01082cc:	c0 
c01082cd:	c7 44 24 08 3e b8 10 	movl   $0xc010b83e,0x8(%esp)
c01082d4:	c0 
c01082d5:	c7 44 24 04 29 01 00 	movl   $0x129,0x4(%esp)
c01082dc:	00 
c01082dd:	c7 04 24 53 b8 10 c0 	movl   $0xc010b853,(%esp)
c01082e4:	e8 17 81 ff ff       	call   c0100400 <__panic>
    nr_free = nr_free_store;
c01082e9:	8b 45 e4             	mov    -0x1c(%ebp),%eax
c01082ec:	a3 4c b1 12 c0       	mov    %eax,0xc012b14c

    free_list = free_list_store;
c01082f1:	8b 45 80             	mov    -0x80(%ebp),%eax
c01082f4:	8b 55 84             	mov    -0x7c(%ebp),%edx
c01082f7:	a3 44 b1 12 c0       	mov    %eax,0xc012b144
c01082fc:	89 15 48 b1 12 c0    	mov    %edx,0xc012b148
    free_pages(p0, 5);
c0108302:	c7 44 24 04 05 00 00 	movl   $0x5,0x4(%esp)
c0108309:	00 
c010830a:	8b 45 e8             	mov    -0x18(%ebp),%eax
c010830d:	89 04 24             	mov    %eax,(%esp)
c0108310:	e8 a5 b1 ff ff       	call   c01034ba <free_pages>

    le = &free_list;
c0108315:	c7 45 ec 44 b1 12 c0 	movl   $0xc012b144,-0x14(%ebp)
    while ((le = list_next(le)) != &free_list) {
c010831c:	eb 1c                	jmp    c010833a <default_check+0x5e2>
        struct Page *p = le2page(le, page_link);    //删掉了assert(le->next->prev == le && le->prev->next == le); 
c010831e:	8b 45 ec             	mov    -0x14(%ebp),%eax
c0108321:	83 e8 0c             	sub    $0xc,%eax
c0108324:	89 45 d8             	mov    %eax,-0x28(%ebp)
        count --, total -= p->property;
c0108327:	ff 4d f4             	decl   -0xc(%ebp)
c010832a:	8b 55 f0             	mov    -0x10(%ebp),%edx
c010832d:	8b 45 d8             	mov    -0x28(%ebp),%eax
c0108330:	8b 40 08             	mov    0x8(%eax),%eax
c0108333:	29 c2                	sub    %eax,%edx
c0108335:	89 d0                	mov    %edx,%eax
c0108337:	89 45 f0             	mov    %eax,-0x10(%ebp)
c010833a:	8b 45 ec             	mov    -0x14(%ebp),%eax
c010833d:	89 45 88             	mov    %eax,-0x78(%ebp)
    return listelm->next;
c0108340:	8b 45 88             	mov    -0x78(%ebp),%eax
c0108343:	8b 40 04             	mov    0x4(%eax),%eax
    while ((le = list_next(le)) != &free_list) {
c0108346:	89 45 ec             	mov    %eax,-0x14(%ebp)
c0108349:	81 7d ec 44 b1 12 c0 	cmpl   $0xc012b144,-0x14(%ebp)
c0108350:	75 cc                	jne    c010831e <default_check+0x5c6>
    }
    assert(count == 0);
c0108352:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
c0108356:	74 24                	je     c010837c <default_check+0x624>
c0108358:	c7 44 24 0c 9e bb 10 	movl   $0xc010bb9e,0xc(%esp)
c010835f:	c0 
c0108360:	c7 44 24 08 3e b8 10 	movl   $0xc010b83e,0x8(%esp)
c0108367:	c0 
c0108368:	c7 44 24 04 34 01 00 	movl   $0x134,0x4(%esp)
c010836f:	00 
c0108370:	c7 04 24 53 b8 10 c0 	movl   $0xc010b853,(%esp)
c0108377:	e8 84 80 ff ff       	call   c0100400 <__panic>
    assert(total == 0);
c010837c:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
c0108380:	74 24                	je     c01083a6 <default_check+0x64e>
c0108382:	c7 44 24 0c a9 bb 10 	movl   $0xc010bba9,0xc(%esp)
c0108389:	c0 
c010838a:	c7 44 24 08 3e b8 10 	movl   $0xc010b83e,0x8(%esp)
c0108391:	c0 
c0108392:	c7 44 24 04 35 01 00 	movl   $0x135,0x4(%esp)
c0108399:	00 
c010839a:	c7 04 24 53 b8 10 c0 	movl   $0xc010b853,(%esp)
c01083a1:	e8 5a 80 ff ff       	call   c0100400 <__panic>
}
c01083a6:	90                   	nop
c01083a7:	c9                   	leave  
c01083a8:	c3                   	ret    

c01083a9 <page2ppn>:
page2ppn(struct Page *page) {
c01083a9:	55                   	push   %ebp
c01083aa:	89 e5                	mov    %esp,%ebp
    return page - pages;         //减去物理页数组的基址，得高20bit的PPN(pa)
c01083ac:	8b 45 08             	mov    0x8(%ebp),%eax
c01083af:	8b 15 60 b0 12 c0    	mov    0xc012b060,%edx
c01083b5:	29 d0                	sub    %edx,%eax
c01083b7:	c1 f8 05             	sar    $0x5,%eax
}
c01083ba:	5d                   	pop    %ebp
c01083bb:	c3                   	ret    

c01083bc <page2pa>:
page2pa(struct Page *page) {
c01083bc:	55                   	push   %ebp
c01083bd:	89 e5                	mov    %esp,%ebp
c01083bf:	83 ec 04             	sub    $0x4,%esp
    return page2ppn(page) << PGSHIFT;   //20bit+12bit全0的pa
c01083c2:	8b 45 08             	mov    0x8(%ebp),%eax
c01083c5:	89 04 24             	mov    %eax,(%esp)
c01083c8:	e8 dc ff ff ff       	call   c01083a9 <page2ppn>
c01083cd:	c1 e0 0c             	shl    $0xc,%eax
}
c01083d0:	c9                   	leave  
c01083d1:	c3                   	ret    

c01083d2 <page2kva>:
page2kva(struct Page *page) {
c01083d2:	55                   	push   %ebp
c01083d3:	89 e5                	mov    %esp,%ebp
c01083d5:	83 ec 28             	sub    $0x28,%esp
    return KADDR(page2pa(page));
c01083d8:	8b 45 08             	mov    0x8(%ebp),%eax
c01083db:	89 04 24             	mov    %eax,(%esp)
c01083de:	e8 d9 ff ff ff       	call   c01083bc <page2pa>
c01083e3:	89 45 f4             	mov    %eax,-0xc(%ebp)
c01083e6:	8b 45 f4             	mov    -0xc(%ebp),%eax
c01083e9:	c1 e8 0c             	shr    $0xc,%eax
c01083ec:	89 45 f0             	mov    %eax,-0x10(%ebp)
c01083ef:	a1 80 8f 12 c0       	mov    0xc0128f80,%eax
c01083f4:	39 45 f0             	cmp    %eax,-0x10(%ebp)
c01083f7:	72 23                	jb     c010841c <page2kva+0x4a>
c01083f9:	8b 45 f4             	mov    -0xc(%ebp),%eax
c01083fc:	89 44 24 0c          	mov    %eax,0xc(%esp)
c0108400:	c7 44 24 08 e4 bb 10 	movl   $0xc010bbe4,0x8(%esp)
c0108407:	c0 
c0108408:	c7 44 24 04 66 00 00 	movl   $0x66,0x4(%esp)
c010840f:	00 
c0108410:	c7 04 24 07 bc 10 c0 	movl   $0xc010bc07,(%esp)
c0108417:	e8 e4 7f ff ff       	call   c0100400 <__panic>
c010841c:	8b 45 f4             	mov    -0xc(%ebp),%eax
c010841f:	2d 00 00 00 40       	sub    $0x40000000,%eax
}
c0108424:	c9                   	leave  
c0108425:	c3                   	ret    

c0108426 <swapfs_init>:
#include <ide.h>
#include <pmm.h>
#include <assert.h>

void
swapfs_init(void) {
c0108426:	55                   	push   %ebp
c0108427:	89 e5                	mov    %esp,%ebp
c0108429:	83 ec 18             	sub    $0x18,%esp
    static_assert((PGSIZE % SECTSIZE) == 0);    //4096/512=8
    if (!ide_device_valid(SWAP_DEV_NO)) {   //设备有效不
c010842c:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
c0108433:	e8 0c 8c ff ff       	call   c0101044 <ide_device_valid>
c0108438:	85 c0                	test   %eax,%eax
c010843a:	75 1c                	jne    c0108458 <swapfs_init+0x32>
        panic("swap fs isn't available.\n");
c010843c:	c7 44 24 08 15 bc 10 	movl   $0xc010bc15,0x8(%esp)
c0108443:	c0 
c0108444:	c7 44 24 04 0d 00 00 	movl   $0xd,0x4(%esp)
c010844b:	00 
c010844c:	c7 04 24 2f bc 10 c0 	movl   $0xc010bc2f,(%esp)
c0108453:	e8 a8 7f ff ff       	call   c0100400 <__panic>
    }
    max_swap_offset = ide_device_size(SWAP_DEV_NO) / (PGSIZE / SECTSIZE);   //看下这个设备能放几个页（不常用的数据放在磁盘）    设备扇区数/8扇区
c0108458:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
c010845f:	e8 1e 8c ff ff       	call   c0101082 <ide_device_size>
c0108464:	c1 e8 03             	shr    $0x3,%eax
c0108467:	a3 1c b1 12 c0       	mov    %eax,0xc012b11c
}
c010846c:	90                   	nop
c010846d:	c9                   	leave  
c010846e:	c3                   	ret    

c010846f <swapfs_read>:

int
swapfs_read(swap_entry_t entry, struct Page *page) {
c010846f:	55                   	push   %ebp
c0108470:	89 e5                	mov    %esp,%ebp
c0108472:	83 ec 28             	sub    $0x28,%esp
    return ide_read_secs(SWAP_DEV_NO, swap_offset(entry) * PAGE_NSECT, page2kva(page), PAGE_NSECT); //页换入，把读（根据pte的24bit*8）到的东西存进page里
c0108475:	8b 45 0c             	mov    0xc(%ebp),%eax
c0108478:	89 04 24             	mov    %eax,(%esp)
c010847b:	e8 52 ff ff ff       	call   c01083d2 <page2kva>
c0108480:	8b 55 08             	mov    0x8(%ebp),%edx
c0108483:	c1 ea 08             	shr    $0x8,%edx
c0108486:	89 55 f4             	mov    %edx,-0xc(%ebp)
c0108489:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
c010848d:	74 0b                	je     c010849a <swapfs_read+0x2b>
c010848f:	8b 15 1c b1 12 c0    	mov    0xc012b11c,%edx
c0108495:	39 55 f4             	cmp    %edx,-0xc(%ebp)
c0108498:	72 23                	jb     c01084bd <swapfs_read+0x4e>
c010849a:	8b 45 08             	mov    0x8(%ebp),%eax
c010849d:	89 44 24 0c          	mov    %eax,0xc(%esp)
c01084a1:	c7 44 24 08 40 bc 10 	movl   $0xc010bc40,0x8(%esp)
c01084a8:	c0 
c01084a9:	c7 44 24 04 14 00 00 	movl   $0x14,0x4(%esp)
c01084b0:	00 
c01084b1:	c7 04 24 2f bc 10 c0 	movl   $0xc010bc2f,(%esp)
c01084b8:	e8 43 7f ff ff       	call   c0100400 <__panic>
c01084bd:	8b 55 f4             	mov    -0xc(%ebp),%edx
c01084c0:	c1 e2 03             	shl    $0x3,%edx
c01084c3:	c7 44 24 0c 08 00 00 	movl   $0x8,0xc(%esp)
c01084ca:	00 
c01084cb:	89 44 24 08          	mov    %eax,0x8(%esp)
c01084cf:	89 54 24 04          	mov    %edx,0x4(%esp)
c01084d3:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
c01084da:	e8 de 8b ff ff       	call   c01010bd <ide_read_secs>
}
c01084df:	c9                   	leave  
c01084e0:	c3                   	ret    

c01084e1 <swapfs_write>:

int
swapfs_write(swap_entry_t entry, struct Page *page) {
c01084e1:	55                   	push   %ebp
c01084e2:	89 e5                	mov    %esp,%ebp
c01084e4:	83 ec 28             	sub    $0x28,%esp
    return ide_write_secs(SWAP_DEV_NO, swap_offset(entry) * PAGE_NSECT, page2kva(page), PAGE_NSECT);//页换出，把page的东西写（根据pte的24bit*8）进去
c01084e7:	8b 45 0c             	mov    0xc(%ebp),%eax
c01084ea:	89 04 24             	mov    %eax,(%esp)
c01084ed:	e8 e0 fe ff ff       	call   c01083d2 <page2kva>
c01084f2:	8b 55 08             	mov    0x8(%ebp),%edx
c01084f5:	c1 ea 08             	shr    $0x8,%edx
c01084f8:	89 55 f4             	mov    %edx,-0xc(%ebp)
c01084fb:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
c01084ff:	74 0b                	je     c010850c <swapfs_write+0x2b>
c0108501:	8b 15 1c b1 12 c0    	mov    0xc012b11c,%edx
c0108507:	39 55 f4             	cmp    %edx,-0xc(%ebp)
c010850a:	72 23                	jb     c010852f <swapfs_write+0x4e>
c010850c:	8b 45 08             	mov    0x8(%ebp),%eax
c010850f:	89 44 24 0c          	mov    %eax,0xc(%esp)
c0108513:	c7 44 24 08 40 bc 10 	movl   $0xc010bc40,0x8(%esp)
c010851a:	c0 
c010851b:	c7 44 24 04 19 00 00 	movl   $0x19,0x4(%esp)
c0108522:	00 
c0108523:	c7 04 24 2f bc 10 c0 	movl   $0xc010bc2f,(%esp)
c010852a:	e8 d1 7e ff ff       	call   c0100400 <__panic>
c010852f:	8b 55 f4             	mov    -0xc(%ebp),%edx
c0108532:	c1 e2 03             	shl    $0x3,%edx
c0108535:	c7 44 24 0c 08 00 00 	movl   $0x8,0xc(%esp)
c010853c:	00 
c010853d:	89 44 24 08          	mov    %eax,0x8(%esp)
c0108541:	89 54 24 04          	mov    %edx,0x4(%esp)
c0108545:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
c010854c:	e8 a5 8d ff ff       	call   c01012f6 <ide_write_secs>
}
c0108551:	c9                   	leave  
c0108552:	c3                   	ret    

c0108553 <kernel_thread_entry>:
.text
.globl kernel_thread_entry
kernel_thread_entry:        # void kernel_thread(void)

    pushl %edx              # push arg把函数fn的参数arg（保存在edx寄存器中）压栈
c0108553:	52                   	push   %edx
    call *%ebx              # call fn
c0108554:	ff d3                	call   *%ebx

    pushl %eax              # save the return value of fn(arg)把函数返回值eax寄存器内容压栈
c0108556:	50                   	push   %eax
    call do_exit            # call do_exit to terminate current thread退出
c0108557:	e8 88 08 00 00       	call   c0108de4 <do_exit>

c010855c <switch_to>:
.text
.globl switch_to
switch_to:                      # switch_to(from, to)

    # save from's registers先保存原本寄存器的值
    movl 4(%esp), %eax          # eax points to from将esp+4的值赋给eax，这样eax就指向了from，此时to是esp+8
c010855c:	8b 44 24 04          	mov    0x4(%esp),%eax
    popl 0(%eax)                # save eip !popl 弹出eax，这样就完成了对eip的赋值，弹出后to变成了esp+4,from为esp
c0108560:	8f 00                	popl   (%eax)
    movl %esp, 4(%eax)          # save esp::context of from
c0108562:	89 60 04             	mov    %esp,0x4(%eax)
    movl %ebx, 8(%eax)          # save ebx::context of from
c0108565:	89 58 08             	mov    %ebx,0x8(%eax)
    movl %ecx, 12(%eax)         # save ecx::context of from
c0108568:	89 48 0c             	mov    %ecx,0xc(%eax)
    movl %edx, 16(%eax)         # save edx::context of from
c010856b:	89 50 10             	mov    %edx,0x10(%eax)
    movl %esi, 20(%eax)         # save esi::context of from
c010856e:	89 70 14             	mov    %esi,0x14(%eax)
    movl %edi, 24(%eax)         # save edi::context of from
c0108571:	89 78 18             	mov    %edi,0x18(%eax)
    movl %ebp, 28(%eax)         # save ebp::context of from
c0108574:	89 68 1c             	mov    %ebp,0x1c(%eax)

    # restore to's registers
    movl 4(%esp), %eax          # not 8(%esp): popped return address already
c0108577:	8b 44 24 04          	mov    0x4(%esp),%eax
                                # eax now points to to
    movl 28(%eax), %ebp         # restore ebp::context of to
c010857b:	8b 68 1c             	mov    0x1c(%eax),%ebp
    movl 24(%eax), %edi         # restore edi::context of to
c010857e:	8b 78 18             	mov    0x18(%eax),%edi
    movl 20(%eax), %esi         # restore esi::context of to
c0108581:	8b 70 14             	mov    0x14(%eax),%esi
    movl 16(%eax), %edx         # restore edx::context of to
c0108584:	8b 50 10             	mov    0x10(%eax),%edx
    movl 12(%eax), %ecx         # restore ecx::context of to
c0108587:	8b 48 0c             	mov    0xc(%eax),%ecx
    movl 8(%eax), %ebx          # restore ebx::context of to
c010858a:	8b 58 08             	mov    0x8(%eax),%ebx
    movl 4(%eax), %esp          # restore esp::context of to
c010858d:	8b 60 04             	mov    0x4(%eax),%esp

    pushl 0(%eax)               # push eip把context中保存的下一个进程要执行的指令地址context.eip放到了堆栈顶
c0108590:	ff 30                	pushl  (%eax)

    ret
c0108592:	c3                   	ret    

c0108593 <__intr_save>:
__intr_save(void) {
c0108593:	55                   	push   %ebp
c0108594:	89 e5                	mov    %esp,%ebp
c0108596:	83 ec 18             	sub    $0x18,%esp
    asm volatile ("pushfl; popl %0" : "=r" (eflags));
c0108599:	9c                   	pushf  
c010859a:	58                   	pop    %eax
c010859b:	89 45 f4             	mov    %eax,-0xc(%ebp)
    return eflags;
c010859e:	8b 45 f4             	mov    -0xc(%ebp),%eax
    if (read_eflags() & FL_IF) {//读操作出现中断
c01085a1:	25 00 02 00 00       	and    $0x200,%eax
c01085a6:	85 c0                	test   %eax,%eax
c01085a8:	74 0c                	je     c01085b6 <__intr_save+0x23>
        intr_disable();//intr.c12->禁用irq中断
c01085aa:	e8 83 9a ff ff       	call   c0102032 <intr_disable>
        return 1;
c01085af:	b8 01 00 00 00       	mov    $0x1,%eax
c01085b4:	eb 05                	jmp    c01085bb <__intr_save+0x28>
    return 0;
c01085b6:	b8 00 00 00 00       	mov    $0x0,%eax
}
c01085bb:	c9                   	leave  
c01085bc:	c3                   	ret    

c01085bd <__intr_restore>:
__intr_restore(bool flag) {
c01085bd:	55                   	push   %ebp
c01085be:	89 e5                	mov    %esp,%ebp
c01085c0:	83 ec 08             	sub    $0x8,%esp
    if (flag) {
c01085c3:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
c01085c7:	74 05                	je     c01085ce <__intr_restore+0x11>
        intr_enable();
c01085c9:	e8 5d 9a ff ff       	call   c010202b <intr_enable>
}
c01085ce:	90                   	nop
c01085cf:	c9                   	leave  
c01085d0:	c3                   	ret    

c01085d1 <page2ppn>:
page2ppn(struct Page *page) {
c01085d1:	55                   	push   %ebp
c01085d2:	89 e5                	mov    %esp,%ebp
    return page - pages;         //减去物理页数组的基址，得高20bit的PPN(pa)
c01085d4:	8b 45 08             	mov    0x8(%ebp),%eax
c01085d7:	8b 15 60 b0 12 c0    	mov    0xc012b060,%edx
c01085dd:	29 d0                	sub    %edx,%eax
c01085df:	c1 f8 05             	sar    $0x5,%eax
}
c01085e2:	5d                   	pop    %ebp
c01085e3:	c3                   	ret    

c01085e4 <page2pa>:
page2pa(struct Page *page) {
c01085e4:	55                   	push   %ebp
c01085e5:	89 e5                	mov    %esp,%ebp
c01085e7:	83 ec 04             	sub    $0x4,%esp
    return page2ppn(page) << PGSHIFT;   //20bit+12bit全0的pa
c01085ea:	8b 45 08             	mov    0x8(%ebp),%eax
c01085ed:	89 04 24             	mov    %eax,(%esp)
c01085f0:	e8 dc ff ff ff       	call   c01085d1 <page2ppn>
c01085f5:	c1 e0 0c             	shl    $0xc,%eax
}
c01085f8:	c9                   	leave  
c01085f9:	c3                   	ret    

c01085fa <pa2page>:
pa2page(uintptr_t pa) {
c01085fa:	55                   	push   %ebp
c01085fb:	89 e5                	mov    %esp,%ebp
c01085fd:	83 ec 18             	sub    $0x18,%esp
    if (PPN(pa) >= npage) {
c0108600:	8b 45 08             	mov    0x8(%ebp),%eax
c0108603:	c1 e8 0c             	shr    $0xc,%eax
c0108606:	89 c2                	mov    %eax,%edx
c0108608:	a1 80 8f 12 c0       	mov    0xc0128f80,%eax
c010860d:	39 c2                	cmp    %eax,%edx
c010860f:	72 1c                	jb     c010862d <pa2page+0x33>
        panic("pa2page called with invalid pa");
c0108611:	c7 44 24 08 60 bc 10 	movl   $0xc010bc60,0x8(%esp)
c0108618:	c0 
c0108619:	c7 44 24 04 5f 00 00 	movl   $0x5f,0x4(%esp)
c0108620:	00 
c0108621:	c7 04 24 7f bc 10 c0 	movl   $0xc010bc7f,(%esp)
c0108628:	e8 d3 7d ff ff       	call   c0100400 <__panic>
    return &pages[PPN(pa)];   //pages+pa高20bit索引位 摒弃低12bit全0
c010862d:	a1 60 b0 12 c0       	mov    0xc012b060,%eax
c0108632:	8b 55 08             	mov    0x8(%ebp),%edx
c0108635:	c1 ea 0c             	shr    $0xc,%edx
c0108638:	c1 e2 05             	shl    $0x5,%edx
c010863b:	01 d0                	add    %edx,%eax
}
c010863d:	c9                   	leave  
c010863e:	c3                   	ret    

c010863f <page2kva>:
page2kva(struct Page *page) {
c010863f:	55                   	push   %ebp
c0108640:	89 e5                	mov    %esp,%ebp
c0108642:	83 ec 28             	sub    $0x28,%esp
    return KADDR(page2pa(page));
c0108645:	8b 45 08             	mov    0x8(%ebp),%eax
c0108648:	89 04 24             	mov    %eax,(%esp)
c010864b:	e8 94 ff ff ff       	call   c01085e4 <page2pa>
c0108650:	89 45 f4             	mov    %eax,-0xc(%ebp)
c0108653:	8b 45 f4             	mov    -0xc(%ebp),%eax
c0108656:	c1 e8 0c             	shr    $0xc,%eax
c0108659:	89 45 f0             	mov    %eax,-0x10(%ebp)
c010865c:	a1 80 8f 12 c0       	mov    0xc0128f80,%eax
c0108661:	39 45 f0             	cmp    %eax,-0x10(%ebp)
c0108664:	72 23                	jb     c0108689 <page2kva+0x4a>
c0108666:	8b 45 f4             	mov    -0xc(%ebp),%eax
c0108669:	89 44 24 0c          	mov    %eax,0xc(%esp)
c010866d:	c7 44 24 08 90 bc 10 	movl   $0xc010bc90,0x8(%esp)
c0108674:	c0 
c0108675:	c7 44 24 04 66 00 00 	movl   $0x66,0x4(%esp)
c010867c:	00 
c010867d:	c7 04 24 7f bc 10 c0 	movl   $0xc010bc7f,(%esp)
c0108684:	e8 77 7d ff ff       	call   c0100400 <__panic>
c0108689:	8b 45 f4             	mov    -0xc(%ebp),%eax
c010868c:	2d 00 00 00 40       	sub    $0x40000000,%eax
}
c0108691:	c9                   	leave  
c0108692:	c3                   	ret    

c0108693 <kva2page>:
kva2page(void *kva) {
c0108693:	55                   	push   %ebp
c0108694:	89 e5                	mov    %esp,%ebp
c0108696:	83 ec 28             	sub    $0x28,%esp
    return pa2page(PADDR(kva));
c0108699:	8b 45 08             	mov    0x8(%ebp),%eax
c010869c:	89 45 f4             	mov    %eax,-0xc(%ebp)
c010869f:	81 7d f4 ff ff ff bf 	cmpl   $0xbfffffff,-0xc(%ebp)
c01086a6:	77 23                	ja     c01086cb <kva2page+0x38>
c01086a8:	8b 45 f4             	mov    -0xc(%ebp),%eax
c01086ab:	89 44 24 0c          	mov    %eax,0xc(%esp)
c01086af:	c7 44 24 08 b4 bc 10 	movl   $0xc010bcb4,0x8(%esp)
c01086b6:	c0 
c01086b7:	c7 44 24 04 6b 00 00 	movl   $0x6b,0x4(%esp)
c01086be:	00 
c01086bf:	c7 04 24 7f bc 10 c0 	movl   $0xc010bc7f,(%esp)
c01086c6:	e8 35 7d ff ff       	call   c0100400 <__panic>
c01086cb:	8b 45 f4             	mov    -0xc(%ebp),%eax
c01086ce:	05 00 00 00 40       	add    $0x40000000,%eax
c01086d3:	89 04 24             	mov    %eax,(%esp)
c01086d6:	e8 1f ff ff ff       	call   c01085fa <pa2page>
}
c01086db:	c9                   	leave  
c01086dc:	c3                   	ret    

c01086dd <alloc_proc>:
void forkrets(struct trapframe *tf);
void switch_to(struct context *from, struct context *to);

// alloc_proc - alloc a proc_struct and init all fields of proc_struct
static struct proc_struct *
alloc_proc(void) {
c01086dd:	55                   	push   %ebp
c01086de:	89 e5                	mov    %esp,%ebp
c01086e0:	83 ec 28             	sub    $0x28,%esp
    struct proc_struct *proc = kmalloc(sizeof(struct proc_struct));
c01086e3:	c7 04 24 68 00 00 00 	movl   $0x68,(%esp)
c01086ea:	e8 72 dd ff ff       	call   c0106461 <kmalloc>
c01086ef:	89 45 f4             	mov    %eax,-0xc(%ebp)
    if (proc != NULL) {
c01086f2:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
c01086f6:	0f 84 a1 00 00 00    	je     c010879d <alloc_proc+0xc0>
     *       struct trapframe *tf;                       // Trap frame for current interrupt
     *       uintptr_t cr3;                              // CR3 register: the base addr of Page Directroy Table(PDT)
     *       uint32_t flags;                             // Process flag
     *       char name[PROC_NAME_LEN + 1];               // Process name
     */
        proc->state = PROC_UNINIT;//未初始化
c01086fc:	8b 45 f4             	mov    -0xc(%ebp),%eax
c01086ff:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
        proc->pid = -1;
c0108705:	8b 45 f4             	mov    -0xc(%ebp),%eax
c0108708:	c7 40 04 ff ff ff ff 	movl   $0xffffffff,0x4(%eax)
        proc->runs = 0;
c010870f:	8b 45 f4             	mov    -0xc(%ebp),%eax
c0108712:	c7 40 08 00 00 00 00 	movl   $0x0,0x8(%eax)
        proc->kstack = 0;
c0108719:	8b 45 f4             	mov    -0xc(%ebp),%eax
c010871c:	c7 40 0c 00 00 00 00 	movl   $0x0,0xc(%eax)
        proc->need_resched = 0;
c0108723:	8b 45 f4             	mov    -0xc(%ebp),%eax
c0108726:	c7 40 10 00 00 00 00 	movl   $0x0,0x10(%eax)
        proc->parent = NULL;
c010872d:	8b 45 f4             	mov    -0xc(%ebp),%eax
c0108730:	c7 40 14 00 00 00 00 	movl   $0x0,0x14(%eax)
        proc->mm = NULL;
c0108737:	8b 45 f4             	mov    -0xc(%ebp),%eax
c010873a:	c7 40 18 00 00 00 00 	movl   $0x0,0x18(%eax)
        memset(&(proc->context), 0, sizeof(struct context));
c0108741:	8b 45 f4             	mov    -0xc(%ebp),%eax
c0108744:	83 c0 1c             	add    $0x1c,%eax
c0108747:	c7 44 24 08 20 00 00 	movl   $0x20,0x8(%esp)
c010874e:	00 
c010874f:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
c0108756:	00 
c0108757:	89 04 24             	mov    %eax,(%esp)
c010875a:	e8 44 0d 00 00       	call   c01094a3 <memset>
        proc->tf = NULL;
c010875f:	8b 45 f4             	mov    -0xc(%ebp),%eax
c0108762:	c7 40 3c 00 00 00 00 	movl   $0x0,0x3c(%eax)
        proc->cr3 = boot_cr3;//该进程页目录表的基址寄存器 pmm_init()里面boot_cr3 = PADDR(boot_pgdir);
c0108769:	8b 15 5c b0 12 c0    	mov    0xc012b05c,%edx
c010876f:	8b 45 f4             	mov    -0xc(%ebp),%eax
c0108772:	89 50 40             	mov    %edx,0x40(%eax)
        proc->flags = 0;
c0108775:	8b 45 f4             	mov    -0xc(%ebp),%eax
c0108778:	c7 40 44 00 00 00 00 	movl   $0x0,0x44(%eax)
        memset(proc->name, 0, PROC_NAME_LEN);
c010877f:	8b 45 f4             	mov    -0xc(%ebp),%eax
c0108782:	83 c0 48             	add    $0x48,%eax
c0108785:	c7 44 24 08 0f 00 00 	movl   $0xf,0x8(%esp)
c010878c:	00 
c010878d:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
c0108794:	00 
c0108795:	89 04 24             	mov    %eax,(%esp)
c0108798:	e8 06 0d 00 00       	call   c01094a3 <memset>
    }
    return proc;
c010879d:	8b 45 f4             	mov    -0xc(%ebp),%eax
}
c01087a0:	c9                   	leave  
c01087a1:	c3                   	ret    

c01087a2 <set_proc_name>:

// set_proc_name - set the name of proc
char *
set_proc_name(struct proc_struct *proc, const char *name) {
c01087a2:	55                   	push   %ebp
c01087a3:	89 e5                	mov    %esp,%ebp
c01087a5:	83 ec 18             	sub    $0x18,%esp
    memset(proc->name, 0, sizeof(proc->name));
c01087a8:	8b 45 08             	mov    0x8(%ebp),%eax
c01087ab:	83 c0 48             	add    $0x48,%eax
c01087ae:	c7 44 24 08 10 00 00 	movl   $0x10,0x8(%esp)
c01087b5:	00 
c01087b6:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
c01087bd:	00 
c01087be:	89 04 24             	mov    %eax,(%esp)
c01087c1:	e8 dd 0c 00 00       	call   c01094a3 <memset>
    return memcpy(proc->name, name, PROC_NAME_LEN);
c01087c6:	8b 45 08             	mov    0x8(%ebp),%eax
c01087c9:	8d 50 48             	lea    0x48(%eax),%edx
c01087cc:	c7 44 24 08 0f 00 00 	movl   $0xf,0x8(%esp)
c01087d3:	00 
c01087d4:	8b 45 0c             	mov    0xc(%ebp),%eax
c01087d7:	89 44 24 04          	mov    %eax,0x4(%esp)
c01087db:	89 14 24             	mov    %edx,(%esp)
c01087de:	e8 a3 0d 00 00       	call   c0109586 <memcpy>
}
c01087e3:	c9                   	leave  
c01087e4:	c3                   	ret    

c01087e5 <get_proc_name>:

// get_proc_name - get the name of proc
char *
get_proc_name(struct proc_struct *proc) {
c01087e5:	55                   	push   %ebp
c01087e6:	89 e5                	mov    %esp,%ebp
c01087e8:	83 ec 18             	sub    $0x18,%esp
    static char name[PROC_NAME_LEN + 1];
    memset(name, 0, sizeof(name));
c01087eb:	c7 44 24 08 10 00 00 	movl   $0x10,0x8(%esp)
c01087f2:	00 
c01087f3:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
c01087fa:	00 
c01087fb:	c7 04 24 44 b0 12 c0 	movl   $0xc012b044,(%esp)
c0108802:	e8 9c 0c 00 00       	call   c01094a3 <memset>
    return memcpy(name, proc->name, PROC_NAME_LEN);
c0108807:	8b 45 08             	mov    0x8(%ebp),%eax
c010880a:	83 c0 48             	add    $0x48,%eax
c010880d:	c7 44 24 08 0f 00 00 	movl   $0xf,0x8(%esp)
c0108814:	00 
c0108815:	89 44 24 04          	mov    %eax,0x4(%esp)
c0108819:	c7 04 24 44 b0 12 c0 	movl   $0xc012b044,(%esp)
c0108820:	e8 61 0d 00 00       	call   c0109586 <memcpy>
}
c0108825:	c9                   	leave  
c0108826:	c3                   	ret    

c0108827 <get_pid>:

// get_pid - alloc a unique pid for process
static int
get_pid(void) {
c0108827:	55                   	push   %ebp
c0108828:	89 e5                	mov    %esp,%ebp
c010882a:	83 ec 10             	sub    $0x10,%esp
    //实际上，之前定义了 MAX_PID=2*MAX_PROCESS，意味着ID的总数目是大于PROCESS的总数目的
    //因此不会出现部分PROCESS无ID可分的情况
    static_assert(MAX_PID > MAX_PROCESS);
    struct proc_struct *proc;
    list_entry_t *list = &proc_list, *le;
c010882d:	c7 45 f8 50 b1 12 c0 	movl   $0xc012b150,-0x8(%ebp)
    //next_safe和last_pid两个变量，这里需要注意！ 它们是static全局变量！！！
    static int next_safe = MAX_PID, last_pid = MAX_PID;
    //++last_pid>-MAX_PID,说明pid以及分到尽头，需要从头再来
    if (++ last_pid >= MAX_PID) 
c0108834:	a1 6c 5a 12 c0       	mov    0xc0125a6c,%eax
c0108839:	40                   	inc    %eax
c010883a:	a3 6c 5a 12 c0       	mov    %eax,0xc0125a6c
c010883f:	a1 6c 5a 12 c0       	mov    0xc0125a6c,%eax
c0108844:	3d ff 1f 00 00       	cmp    $0x1fff,%eax
c0108849:	7e 0c                	jle    c0108857 <get_pid+0x30>
    {
        last_pid = 1;
c010884b:	c7 05 6c 5a 12 c0 01 	movl   $0x1,0xc0125a6c
c0108852:	00 00 00 
        goto inside;
c0108855:	eb 14                	jmp    c010886b <get_pid+0x44>
    }
    if (last_pid >= next_safe) 
c0108857:	8b 15 6c 5a 12 c0    	mov    0xc0125a6c,%edx
c010885d:	a1 70 5a 12 c0       	mov    0xc0125a70,%eax
c0108862:	39 c2                	cmp    %eax,%edx
c0108864:	0f 8c ab 00 00 00    	jl     c0108915 <get_pid+0xee>
    {
    inside:
c010886a:	90                   	nop
        next_safe = MAX_PID;
c010886b:	c7 05 70 5a 12 c0 00 	movl   $0x2000,0xc0125a70
c0108872:	20 00 00 
    repeat:
        //le等于线程的链表头
        le = list;
c0108875:	8b 45 f8             	mov    -0x8(%ebp),%eax
c0108878:	89 45 fc             	mov    %eax,-0x4(%ebp)
        //遍历一遍链表
        //循环扫描每一个当前进程：当一个现有的进程号和last_pid相等时，则将last_pid+1；
        //当现有的进程号大于last_pid时，这意味着在已经扫描的进程中
        //[last_pid,min(next_safe, proc->pid)] 这段进程号尚未被占用，继续扫描。
        while ((le = list_next(le)) != list) 
c010887b:	eb 7d                	jmp    c01088fa <get_pid+0xd3>
        { 
            proc = le2proc(le, list_link);//proc为le在list_link中对应的程序
c010887d:	8b 45 fc             	mov    -0x4(%ebp),%eax
c0108880:	83 e8 58             	sub    $0x58,%eax
c0108883:	89 45 f4             	mov    %eax,-0xc(%ebp)
            //如果proc的pid与last_pid相等，则将last_pid加1
            //当然，如果last_pid>=MAX_PID,then 将其变为1
            //确保了没有一个进程的pid与last_pid重合
            if (proc->pid == last_pid) 
c0108886:	8b 45 f4             	mov    -0xc(%ebp),%eax
c0108889:	8b 50 04             	mov    0x4(%eax),%edx
c010888c:	a1 6c 5a 12 c0       	mov    0xc0125a6c,%eax
c0108891:	39 c2                	cmp    %eax,%edx
c0108893:	75 3c                	jne    c01088d1 <get_pid+0xaa>
            {
                if (++ last_pid >= next_safe) 
c0108895:	a1 6c 5a 12 c0       	mov    0xc0125a6c,%eax
c010889a:	40                   	inc    %eax
c010889b:	a3 6c 5a 12 c0       	mov    %eax,0xc0125a6c
c01088a0:	8b 15 6c 5a 12 c0    	mov    0xc0125a6c,%edx
c01088a6:	a1 70 5a 12 c0       	mov    0xc0125a70,%eax
c01088ab:	39 c2                	cmp    %eax,%edx
c01088ad:	7c 4b                	jl     c01088fa <get_pid+0xd3>
                {
                    if (last_pid >= MAX_PID) 
c01088af:	a1 6c 5a 12 c0       	mov    0xc0125a6c,%eax
c01088b4:	3d ff 1f 00 00       	cmp    $0x1fff,%eax
c01088b9:	7e 0a                	jle    c01088c5 <get_pid+0x9e>
                    {
                        last_pid = 1;
c01088bb:	c7 05 6c 5a 12 c0 01 	movl   $0x1,0xc0125a6c
c01088c2:	00 00 00 
                    }
                    next_safe = MAX_PID;
c01088c5:	c7 05 70 5a 12 c0 00 	movl   $0x2000,0xc0125a70
c01088cc:	20 00 00 
                    goto repeat;
c01088cf:	eb a4                	jmp    c0108875 <get_pid+0x4e>
                }
            }
            //last_pid<pid<next_safe，确保最后能够找到这么一个满足条件的区间，获得合法的pid；
            else if (proc->pid > last_pid && next_safe > proc->pid) 
c01088d1:	8b 45 f4             	mov    -0xc(%ebp),%eax
c01088d4:	8b 50 04             	mov    0x4(%eax),%edx
c01088d7:	a1 6c 5a 12 c0       	mov    0xc0125a6c,%eax
c01088dc:	39 c2                	cmp    %eax,%edx
c01088de:	7e 1a                	jle    c01088fa <get_pid+0xd3>
c01088e0:	8b 45 f4             	mov    -0xc(%ebp),%eax
c01088e3:	8b 50 04             	mov    0x4(%eax),%edx
c01088e6:	a1 70 5a 12 c0       	mov    0xc0125a70,%eax
c01088eb:	39 c2                	cmp    %eax,%edx
c01088ed:	7d 0b                	jge    c01088fa <get_pid+0xd3>
            {
                next_safe = proc->pid;
c01088ef:	8b 45 f4             	mov    -0xc(%ebp),%eax
c01088f2:	8b 40 04             	mov    0x4(%eax),%eax
c01088f5:	a3 70 5a 12 c0       	mov    %eax,0xc0125a70
c01088fa:	8b 45 fc             	mov    -0x4(%ebp),%eax
c01088fd:	89 45 f0             	mov    %eax,-0x10(%ebp)
c0108900:	8b 45 f0             	mov    -0x10(%ebp),%eax
c0108903:	8b 40 04             	mov    0x4(%eax),%eax
        while ((le = list_next(le)) != list) 
c0108906:	89 45 fc             	mov    %eax,-0x4(%ebp)
c0108909:	8b 45 fc             	mov    -0x4(%ebp),%eax
c010890c:	3b 45 f8             	cmp    -0x8(%ebp),%eax
c010890f:	0f 85 68 ff ff ff    	jne    c010887d <get_pid+0x56>
            }
        }
    }
    return last_pid;
c0108915:	a1 6c 5a 12 c0       	mov    0xc0125a6c,%eax
}
c010891a:	c9                   	leave  
c010891b:	c3                   	ret    

c010891c <proc_run>:

// proc_run - make process "proc" running on cpu
// NOTE: before call switch_to, should load  base addr of "proc"'s new PDT
//注意：在执行上下文切换之前需要先load 这个进程的新的PDT的地址
void proc_run(struct proc_struct *proc) 
{  
c010891c:	55                   	push   %ebp
c010891d:	89 e5                	mov    %esp,%ebp
c010891f:	83 ec 28             	sub    $0x28,%esp
    //判断一下要调度的进程是不是当前进程
    if (proc != current) 
c0108922:	a1 28 90 12 c0       	mov    0xc0129028,%eax
c0108927:	39 45 08             	cmp    %eax,0x8(%ebp)
c010892a:	74 63                	je     c010898f <proc_run+0x73>
    {
        bool intr_flag;
        struct proc_struct *prev = current, *next = proc;
c010892c:	a1 28 90 12 c0       	mov    0xc0129028,%eax
c0108931:	89 45 f4             	mov    %eax,-0xc(%ebp)
c0108934:	8b 45 08             	mov    0x8(%ebp),%eax
c0108937:	89 45 f0             	mov    %eax,-0x10(%ebp)
        // 关闭中断,进行进程切换sync.h
        local_intr_save(intr_flag);
c010893a:	e8 54 fc ff ff       	call   c0108593 <__intr_save>
c010893f:	89 45 ec             	mov    %eax,-0x14(%ebp)
        {
            //当前进程设为待调度的进程
            current = proc;
c0108942:	8b 45 08             	mov    0x8(%ebp),%eax
c0108945:	a3 28 90 12 c0       	mov    %eax,0xc0129028
            //加载待调度进程的内核栈基地址
            //设置任务状态段ts中特权态0下的栈顶指针esp0为next内核线程initproc的内核栈的栈顶
            load_esp0(next->kstack + KSTACKSIZE);//pmm.c118
c010894a:	8b 45 f0             	mov    -0x10(%ebp),%eax
c010894d:	8b 40 0c             	mov    0xc(%eax),%eax
c0108950:	05 00 20 00 00       	add    $0x2000,%eax
c0108955:	89 04 24             	mov    %eax,(%esp)
c0108958:	e8 a7 a9 ff ff       	call   c0103304 <load_esp0>
            //将当前的cr3寄存器改为需要运行进程的页目录表，完成进程间的页表切换；
            lcr3(next->cr3);
c010895d:	8b 45 f0             	mov    -0x10(%ebp),%eax
c0108960:	8b 40 40             	mov    0x40(%eax),%eax
c0108963:	89 45 e8             	mov    %eax,-0x18(%ebp)
    asm volatile ("mov %0, %%cr3" :: "r" (cr3) : "memory");
c0108966:	8b 45 e8             	mov    -0x18(%ebp),%eax
c0108969:	0f 22 d8             	mov    %eax,%cr3
            //进行上下文切换，保存原线程的寄存器并恢复待调度线程的寄存器
            //Switch.S
            switch_to(&(prev->context), &(next->context));
c010896c:	8b 45 f0             	mov    -0x10(%ebp),%eax
c010896f:	8d 50 1c             	lea    0x1c(%eax),%edx
c0108972:	8b 45 f4             	mov    -0xc(%ebp),%eax
c0108975:	83 c0 1c             	add    $0x1c,%eax
c0108978:	89 54 24 04          	mov    %edx,0x4(%esp)
c010897c:	89 04 24             	mov    %eax,(%esp)
c010897f:	e8 d8 fb ff ff       	call   c010855c <switch_to>
        }
        //恢复中断
        local_intr_restore(intr_flag);
c0108984:	8b 45 ec             	mov    -0x14(%ebp),%eax
c0108987:	89 04 24             	mov    %eax,(%esp)
c010898a:	e8 2e fc ff ff       	call   c01085bd <__intr_restore>
    }
}
c010898f:	90                   	nop
c0108990:	c9                   	leave  
c0108991:	c3                   	ret    

c0108992 <forkret>:
//新线程/进程的第一个内核入口点
// forkret -- the first kernel entry point of a new thread/process
// NOTE: the addr of forkret is setted in copy_thread function
//       after switch_to, the current proc will execute here.
static void
forkret(void) {
c0108992:	55                   	push   %ebp
c0108993:	89 e5                	mov    %esp,%ebp
c0108995:	83 ec 18             	sub    $0x18,%esp
    forkrets(current->tf);
c0108998:	a1 28 90 12 c0       	mov    0xc0129028,%eax
c010899d:	8b 40 3c             	mov    0x3c(%eax),%eax
c01089a0:	89 04 24             	mov    %eax,(%esp)
c01089a3:	e8 84 a7 ff ff       	call   c010312c <forkrets>
}
c01089a8:	90                   	nop
c01089a9:	c9                   	leave  
c01089aa:	c3                   	ret    

c01089ab <hash_proc>:

// hash_proc - add proc into proc hash_list将进程放入进程哈希列表
static void
hash_proc(struct proc_struct *proc) {
c01089ab:	55                   	push   %ebp
c01089ac:	89 e5                	mov    %esp,%ebp
c01089ae:	53                   	push   %ebx
c01089af:	83 ec 34             	sub    $0x34,%esp
    list_add(hash_list + pid_hashfn(proc->pid), &(proc->hash_link));
c01089b2:	8b 45 08             	mov    0x8(%ebp),%eax
c01089b5:	8d 58 60             	lea    0x60(%eax),%ebx
c01089b8:	8b 45 08             	mov    0x8(%ebp),%eax
c01089bb:	8b 40 04             	mov    0x4(%eax),%eax
c01089be:	c7 44 24 04 0a 00 00 	movl   $0xa,0x4(%esp)
c01089c5:	00 
c01089c6:	89 04 24             	mov    %eax,(%esp)
c01089c9:	e8 cf 12 00 00       	call   c0109c9d <hash32>
c01089ce:	c1 e0 03             	shl    $0x3,%eax
c01089d1:	05 40 90 12 c0       	add    $0xc0129040,%eax
c01089d6:	89 45 f4             	mov    %eax,-0xc(%ebp)
c01089d9:	89 5d f0             	mov    %ebx,-0x10(%ebp)
c01089dc:	8b 45 f4             	mov    -0xc(%ebp),%eax
c01089df:	89 45 ec             	mov    %eax,-0x14(%ebp)
c01089e2:	8b 45 f0             	mov    -0x10(%ebp),%eax
c01089e5:	89 45 e8             	mov    %eax,-0x18(%ebp)
    __list_add(elm, listelm, listelm->next);
c01089e8:	8b 45 ec             	mov    -0x14(%ebp),%eax
c01089eb:	8b 40 04             	mov    0x4(%eax),%eax
c01089ee:	8b 55 e8             	mov    -0x18(%ebp),%edx
c01089f1:	89 55 e4             	mov    %edx,-0x1c(%ebp)
c01089f4:	8b 55 ec             	mov    -0x14(%ebp),%edx
c01089f7:	89 55 e0             	mov    %edx,-0x20(%ebp)
c01089fa:	89 45 dc             	mov    %eax,-0x24(%ebp)
    prev->next = next->prev = elm;
c01089fd:	8b 45 dc             	mov    -0x24(%ebp),%eax
c0108a00:	8b 55 e4             	mov    -0x1c(%ebp),%edx
c0108a03:	89 10                	mov    %edx,(%eax)
c0108a05:	8b 45 dc             	mov    -0x24(%ebp),%eax
c0108a08:	8b 10                	mov    (%eax),%edx
c0108a0a:	8b 45 e0             	mov    -0x20(%ebp),%eax
c0108a0d:	89 50 04             	mov    %edx,0x4(%eax)
    elm->next = next;
c0108a10:	8b 45 e4             	mov    -0x1c(%ebp),%eax
c0108a13:	8b 55 dc             	mov    -0x24(%ebp),%edx
c0108a16:	89 50 04             	mov    %edx,0x4(%eax)
    elm->prev = prev;
c0108a19:	8b 45 e4             	mov    -0x1c(%ebp),%eax
c0108a1c:	8b 55 e0             	mov    -0x20(%ebp),%edx
c0108a1f:	89 10                	mov    %edx,(%eax)
}
c0108a21:	90                   	nop
c0108a22:	83 c4 34             	add    $0x34,%esp
c0108a25:	5b                   	pop    %ebx
c0108a26:	5d                   	pop    %ebp
c0108a27:	c3                   	ret    

c0108a28 <find_proc>:

// find_proc - find proc frome proc hash_list according to pid
struct proc_struct *
find_proc(int pid) {
c0108a28:	55                   	push   %ebp
c0108a29:	89 e5                	mov    %esp,%ebp
c0108a2b:	83 ec 28             	sub    $0x28,%esp
    if (0 < pid && pid < MAX_PID) {
c0108a2e:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
c0108a32:	7e 5f                	jle    c0108a93 <find_proc+0x6b>
c0108a34:	81 7d 08 ff 1f 00 00 	cmpl   $0x1fff,0x8(%ebp)
c0108a3b:	7f 56                	jg     c0108a93 <find_proc+0x6b>
        list_entry_t *list = hash_list + pid_hashfn(pid), *le = list;
c0108a3d:	8b 45 08             	mov    0x8(%ebp),%eax
c0108a40:	c7 44 24 04 0a 00 00 	movl   $0xa,0x4(%esp)
c0108a47:	00 
c0108a48:	89 04 24             	mov    %eax,(%esp)
c0108a4b:	e8 4d 12 00 00       	call   c0109c9d <hash32>
c0108a50:	c1 e0 03             	shl    $0x3,%eax
c0108a53:	05 40 90 12 c0       	add    $0xc0129040,%eax
c0108a58:	89 45 f0             	mov    %eax,-0x10(%ebp)
c0108a5b:	8b 45 f0             	mov    -0x10(%ebp),%eax
c0108a5e:	89 45 f4             	mov    %eax,-0xc(%ebp)
        while ((le = list_next(le)) != list) {
c0108a61:	eb 19                	jmp    c0108a7c <find_proc+0x54>
            struct proc_struct *proc = le2proc(le, hash_link);
c0108a63:	8b 45 f4             	mov    -0xc(%ebp),%eax
c0108a66:	83 e8 60             	sub    $0x60,%eax
c0108a69:	89 45 ec             	mov    %eax,-0x14(%ebp)
            if (proc->pid == pid) {
c0108a6c:	8b 45 ec             	mov    -0x14(%ebp),%eax
c0108a6f:	8b 40 04             	mov    0x4(%eax),%eax
c0108a72:	39 45 08             	cmp    %eax,0x8(%ebp)
c0108a75:	75 05                	jne    c0108a7c <find_proc+0x54>
                return proc;
c0108a77:	8b 45 ec             	mov    -0x14(%ebp),%eax
c0108a7a:	eb 1c                	jmp    c0108a98 <find_proc+0x70>
c0108a7c:	8b 45 f4             	mov    -0xc(%ebp),%eax
c0108a7f:	89 45 e8             	mov    %eax,-0x18(%ebp)
    return listelm->next;
c0108a82:	8b 45 e8             	mov    -0x18(%ebp),%eax
c0108a85:	8b 40 04             	mov    0x4(%eax),%eax
        while ((le = list_next(le)) != list) {
c0108a88:	89 45 f4             	mov    %eax,-0xc(%ebp)
c0108a8b:	8b 45 f4             	mov    -0xc(%ebp),%eax
c0108a8e:	3b 45 f0             	cmp    -0x10(%ebp),%eax
c0108a91:	75 d0                	jne    c0108a63 <find_proc+0x3b>
            }
        }
    }
    return NULL;
c0108a93:	b8 00 00 00 00       	mov    $0x0,%eax
}
c0108a98:	c9                   	leave  
c0108a99:	c3                   	ret    

c0108a9a <kernel_thread>:

// kernel_thread - create a kernel thread using "fn" function
// NOTE: the contents of temp trapframe tf will be copied to 
//       proc->tf in do_fork-->copy_thread function
int
kernel_thread(int (*fn)(void *), void *arg, uint32_t clone_flags) {
c0108a9a:	55                   	push   %ebp
c0108a9b:	89 e5                	mov    %esp,%ebp
c0108a9d:	83 ec 68             	sub    $0x68,%esp
    //1.首先设置initproc的中断帧，创建一个tf中断帧，记录了进程在被中断前的状态
    struct trapframe tf;//结构体在trap.h
    memset(&tf, 0, sizeof(struct trapframe));//将tf清零
c0108aa0:	c7 44 24 08 4c 00 00 	movl   $0x4c,0x8(%esp)
c0108aa7:	00 
c0108aa8:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
c0108aaf:	00 
c0108ab0:	8d 45 ac             	lea    -0x54(%ebp),%eax
c0108ab3:	89 04 24             	mov    %eax,(%esp)
c0108ab6:	e8 e8 09 00 00       	call   c01094a3 <memset>
    //2.之后进行相关的参数的赋值
    tf.tf_cs = KERNEL_CS;//代码段是在内核里
c0108abb:	66 c7 45 e8 08 00    	movw   $0x8,-0x18(%ebp)
    tf.tf_ds = tf.tf_es = tf.tf_ss = KERNEL_DS;//数据段在内核里
c0108ac1:	66 c7 45 f4 10 00    	movw   $0x10,-0xc(%ebp)
c0108ac7:	0f b7 45 f4          	movzwl -0xc(%ebp),%eax
c0108acb:	66 89 45 d4          	mov    %ax,-0x2c(%ebp)
c0108acf:	0f b7 45 d4          	movzwl -0x2c(%ebp),%eax
c0108ad3:	66 89 45 d8          	mov    %ax,-0x28(%ebp)
    tf.tf_regs.reg_ebx = (uint32_t)fn;//fn代表实际的入口地址/* ebx指向函数地址 */
c0108ad7:	8b 45 08             	mov    0x8(%ebp),%eax
c0108ada:	89 45 bc             	mov    %eax,-0x44(%ebp)
    tf.tf_regs.reg_edx = (uint32_t)arg;/* edx指向参数 */ 
c0108add:	8b 45 0c             	mov    0xc(%ebp),%eax
c0108ae0:	89 45 c0             	mov    %eax,-0x40(%ebp)
    tf.tf_eip = (uint32_t)kernel_thread_entry;//entry.S中
c0108ae3:	b8 53 85 10 c0       	mov    $0xc0108553,%eax
c0108ae8:	89 45 e4             	mov    %eax,-0x1c(%ebp)
    //CLONE_VM pmm.h 11->0x00000100
    //clone_flags在init时传入的参数是 0
    //3.调用dofork函数进行线程创建
    return do_fork(clone_flags | CLONE_VM, 0, &tf);//308
c0108aeb:	8b 45 10             	mov    0x10(%ebp),%eax
c0108aee:	0d 00 01 00 00       	or     $0x100,%eax
c0108af3:	89 c2                	mov    %eax,%edx
c0108af5:	8d 45 ac             	lea    -0x54(%ebp),%eax
c0108af8:	89 44 24 08          	mov    %eax,0x8(%esp)
c0108afc:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
c0108b03:	00 
c0108b04:	89 14 24             	mov    %edx,(%esp)
c0108b07:	e8 88 01 00 00       	call   c0108c94 <do_fork>
}
c0108b0c:	c9                   	leave  
c0108b0d:	c3                   	ret    

c0108b0e <setup_kstack>:

// setup_kstack - alloc pages with size KSTACKPAGE as process kernel stack
static int
setup_kstack(struct proc_struct *proc) {
c0108b0e:	55                   	push   %ebp
c0108b0f:	89 e5                	mov    %esp,%ebp
c0108b11:	83 ec 28             	sub    $0x28,%esp
    //memlayout.h->2
    //1.为该线程分配空间——两页
    struct Page *page = alloc_pages(KSTACKPAGE);//分配页
c0108b14:	c7 04 24 02 00 00 00 	movl   $0x2,(%esp)
c0108b1b:	e8 2f a9 ff ff       	call   c010344f <alloc_pages>
c0108b20:	89 45 f4             	mov    %eax,-0xc(%ebp)
    if (page != NULL) {
c0108b23:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
c0108b27:	74 1a                	je     c0108b43 <setup_kstack+0x35>
        proc->kstack = (uintptr_t)page2kva(page);//设置内核栈空间地址 
c0108b29:	8b 45 f4             	mov    -0xc(%ebp),%eax
c0108b2c:	89 04 24             	mov    %eax,(%esp)
c0108b2f:	e8 0b fb ff ff       	call   c010863f <page2kva>
c0108b34:	89 c2                	mov    %eax,%edx
c0108b36:	8b 45 08             	mov    0x8(%ebp),%eax
c0108b39:	89 50 0c             	mov    %edx,0xc(%eax)
        return 0;
c0108b3c:	b8 00 00 00 00       	mov    $0x0,%eax
c0108b41:	eb 05                	jmp    c0108b48 <setup_kstack+0x3a>
    }
    return -E_NO_MEM;
c0108b43:	b8 fc ff ff ff       	mov    $0xfffffffc,%eax
}
c0108b48:	c9                   	leave  
c0108b49:	c3                   	ret    

c0108b4a <put_kstack>:

// put_kstack - free the memory space of process kernel stack
static void
put_kstack(struct proc_struct *proc) {
c0108b4a:	55                   	push   %ebp
c0108b4b:	89 e5                	mov    %esp,%ebp
c0108b4d:	83 ec 18             	sub    $0x18,%esp
    free_pages(kva2page((void *)(proc->kstack)), KSTACKPAGE);
c0108b50:	8b 45 08             	mov    0x8(%ebp),%eax
c0108b53:	8b 40 0c             	mov    0xc(%eax),%eax
c0108b56:	89 04 24             	mov    %eax,(%esp)
c0108b59:	e8 35 fb ff ff       	call   c0108693 <kva2page>
c0108b5e:	c7 44 24 04 02 00 00 	movl   $0x2,0x4(%esp)
c0108b65:	00 
c0108b66:	89 04 24             	mov    %eax,(%esp)
c0108b69:	e8 4c a9 ff ff       	call   c01034ba <free_pages>
}
c0108b6e:	90                   	nop
c0108b6f:	c9                   	leave  
c0108b70:	c3                   	ret    

c0108b71 <copy_mm>:

// copy_mm - process "proc" duplicate OR share process "current"'s mm according clone_flags
//         - if clone_flags & CLONE_VM, then "share" ; else "duplicate"
static int
copy_mm(uint32_t clone_flags, struct proc_struct *proc) {
c0108b71:	55                   	push   %ebp
c0108b72:	89 e5                	mov    %esp,%ebp
c0108b74:	83 ec 18             	sub    $0x18,%esp
    assert(current->mm == NULL);//由于系统！进程没有虚存，其值为NULL
c0108b77:	a1 28 90 12 c0       	mov    0xc0129028,%eax
c0108b7c:	8b 40 18             	mov    0x18(%eax),%eax
c0108b7f:	85 c0                	test   %eax,%eax
c0108b81:	74 24                	je     c0108ba7 <copy_mm+0x36>
c0108b83:	c7 44 24 0c d8 bc 10 	movl   $0xc010bcd8,0xc(%esp)
c0108b8a:	c0 
c0108b8b:	c7 44 24 08 ec bc 10 	movl   $0xc010bcec,0x8(%esp)
c0108b92:	c0 
c0108b93:	c7 44 24 04 25 01 00 	movl   $0x125,0x4(%esp)
c0108b9a:	00 
c0108b9b:	c7 04 24 01 bd 10 c0 	movl   $0xc010bd01,(%esp)
c0108ba2:	e8 59 78 ff ff       	call   c0100400 <__panic>
    /* do nothing in this project */
    return 0;
c0108ba7:	b8 00 00 00 00       	mov    $0x0,%eax
}
c0108bac:	c9                   	leave  
c0108bad:	c3                   	ret    

c0108bae <copy_thread>:

// copy_thread - setup the trapframe on the  process's kernel stack top and
//             - setup the kernel entry point and stack of process
static void
copy_thread(struct proc_struct *proc, uintptr_t esp, struct trapframe *tf) {
c0108bae:	55                   	push   %ebp
c0108baf:	89 e5                	mov    %esp,%ebp
c0108bb1:	57                   	push   %edi
c0108bb2:	56                   	push   %esi
c0108bb3:	53                   	push   %ebx
    //在内核堆栈的顶部设置中断帧大小的一块栈空间
    proc->tf = (struct trapframe *)(proc->kstack + KSTACKSIZE) - 1;
c0108bb4:	8b 45 08             	mov    0x8(%ebp),%eax
c0108bb7:	8b 40 0c             	mov    0xc(%eax),%eax
c0108bba:	05 b4 1f 00 00       	add    $0x1fb4,%eax
c0108bbf:	89 c2                	mov    %eax,%edx
c0108bc1:	8b 45 08             	mov    0x8(%ebp),%eax
c0108bc4:	89 50 3c             	mov    %edx,0x3c(%eax)
    *(proc->tf) = *tf;//拷贝在kernel_thread函数建立的临时中断帧的初始值
c0108bc7:	8b 45 08             	mov    0x8(%ebp),%eax
c0108bca:	8b 40 3c             	mov    0x3c(%eax),%eax
c0108bcd:	8b 55 10             	mov    0x10(%ebp),%edx
c0108bd0:	bb 4c 00 00 00       	mov    $0x4c,%ebx
c0108bd5:	89 c1                	mov    %eax,%ecx
c0108bd7:	83 e1 01             	and    $0x1,%ecx
c0108bda:	85 c9                	test   %ecx,%ecx
c0108bdc:	74 0c                	je     c0108bea <copy_thread+0x3c>
c0108bde:	0f b6 0a             	movzbl (%edx),%ecx
c0108be1:	88 08                	mov    %cl,(%eax)
c0108be3:	8d 40 01             	lea    0x1(%eax),%eax
c0108be6:	8d 52 01             	lea    0x1(%edx),%edx
c0108be9:	4b                   	dec    %ebx
c0108bea:	89 c1                	mov    %eax,%ecx
c0108bec:	83 e1 02             	and    $0x2,%ecx
c0108bef:	85 c9                	test   %ecx,%ecx
c0108bf1:	74 0f                	je     c0108c02 <copy_thread+0x54>
c0108bf3:	0f b7 0a             	movzwl (%edx),%ecx
c0108bf6:	66 89 08             	mov    %cx,(%eax)
c0108bf9:	8d 40 02             	lea    0x2(%eax),%eax
c0108bfc:	8d 52 02             	lea    0x2(%edx),%edx
c0108bff:	83 eb 02             	sub    $0x2,%ebx
c0108c02:	89 df                	mov    %ebx,%edi
c0108c04:	83 e7 fc             	and    $0xfffffffc,%edi
c0108c07:	b9 00 00 00 00       	mov    $0x0,%ecx
c0108c0c:	8b 34 0a             	mov    (%edx,%ecx,1),%esi
c0108c0f:	89 34 08             	mov    %esi,(%eax,%ecx,1)
c0108c12:	83 c1 04             	add    $0x4,%ecx
c0108c15:	39 f9                	cmp    %edi,%ecx
c0108c17:	72 f3                	jb     c0108c0c <copy_thread+0x5e>
c0108c19:	01 c8                	add    %ecx,%eax
c0108c1b:	01 ca                	add    %ecx,%edx
c0108c1d:	b9 00 00 00 00       	mov    $0x0,%ecx
c0108c22:	89 de                	mov    %ebx,%esi
c0108c24:	83 e6 02             	and    $0x2,%esi
c0108c27:	85 f6                	test   %esi,%esi
c0108c29:	74 0b                	je     c0108c36 <copy_thread+0x88>
c0108c2b:	0f b7 34 0a          	movzwl (%edx,%ecx,1),%esi
c0108c2f:	66 89 34 08          	mov    %si,(%eax,%ecx,1)
c0108c33:	83 c1 02             	add    $0x2,%ecx
c0108c36:	83 e3 01             	and    $0x1,%ebx
c0108c39:	85 db                	test   %ebx,%ebx
c0108c3b:	74 07                	je     c0108c44 <copy_thread+0x96>
c0108c3d:	0f b6 14 0a          	movzbl (%edx,%ecx,1),%edx
c0108c41:	88 14 08             	mov    %dl,(%eax,%ecx,1)
    proc->tf->tf_regs.reg_eax = 0;
c0108c44:	8b 45 08             	mov    0x8(%ebp),%eax
c0108c47:	8b 40 3c             	mov    0x3c(%eax),%eax
c0108c4a:	c7 40 1c 00 00 00 00 	movl   $0x0,0x1c(%eax)
    //设置子进程执行完do_fork后的返回值
    proc->tf->tf_esp = esp;//设置中断帧中的栈指针esp
c0108c51:	8b 45 08             	mov    0x8(%ebp),%eax
c0108c54:	8b 40 3c             	mov    0x3c(%eax),%eax
c0108c57:	8b 55 0c             	mov    0xc(%ebp),%edx
c0108c5a:	89 50 44             	mov    %edx,0x44(%eax)
    proc->tf->tf_eflags |= FL_IF;//使能中断mmu.h->0x00000200
c0108c5d:	8b 45 08             	mov    0x8(%ebp),%eax
c0108c60:	8b 40 3c             	mov    0x3c(%eax),%eax
c0108c63:	8b 50 40             	mov    0x40(%eax),%edx
c0108c66:	8b 45 08             	mov    0x8(%ebp),%eax
c0108c69:	8b 40 3c             	mov    0x3c(%eax),%eax
c0108c6c:	81 ca 00 02 00 00    	or     $0x200,%edx
c0108c72:	89 50 40             	mov    %edx,0x40(%eax)

    proc->context.eip = (uintptr_t)forkret;//完成对返回中断的一个处理过程
c0108c75:	ba 92 89 10 c0       	mov    $0xc0108992,%edx
c0108c7a:	8b 45 08             	mov    0x8(%ebp),%eax
c0108c7d:	89 50 1c             	mov    %edx,0x1c(%eax)
    //forkret主要对返回的中断处理，基本可以认为是一个中断处理并恢复
    //在trapentry.S

    proc->context.esp = (uintptr_t)(proc->tf);//当前的栈顶指针指向proc->tf
c0108c80:	8b 45 08             	mov    0x8(%ebp),%eax
c0108c83:	8b 40 3c             	mov    0x3c(%eax),%eax
c0108c86:	89 c2                	mov    %eax,%edx
c0108c88:	8b 45 08             	mov    0x8(%ebp),%eax
c0108c8b:	89 50 20             	mov    %edx,0x20(%eax)
}
c0108c8e:	90                   	nop
c0108c8f:	5b                   	pop    %ebx
c0108c90:	5e                   	pop    %esi
c0108c91:	5f                   	pop    %edi
c0108c92:	5d                   	pop    %ebp
c0108c93:	c3                   	ret    

c0108c94 <do_fork>:
 * @stack:       the parent's user stack pointer. if stack==0, It means to fork a kernel thread.
 * @tf:          the trapframe info, which will be copied to child process's proc->tf
 */
 //实现具体的尤其针对init_proc的内核进程控制块的初始化
int
do_fork(uint32_t clone_flags, uintptr_t stack, struct trapframe *tf) {
c0108c94:	55                   	push   %ebp
c0108c95:	89 e5                	mov    %esp,%ebp
c0108c97:	83 ec 48             	sub    $0x48,%esp
    //error.h9->5
    int ret = -E_NO_FREE_PROC;//ret=-5
c0108c9a:	c7 45 f4 fb ff ff ff 	movl   $0xfffffffb,-0xc(%ebp)
    struct proc_struct *proc;
    //线程数已经到达最大值
    if (nr_process >= MAX_PROCESS) {
c0108ca1:	a1 40 b0 12 c0       	mov    0xc012b040,%eax
c0108ca6:	3d ff 0f 00 00       	cmp    $0xfff,%eax
c0108cab:	0f 8f 0c 01 00 00    	jg     c0108dbd <do_fork+0x129>
        goto fork_out;
    }
    //error.h9->4
    ret = -E_NO_MEM;
c0108cb1:	c7 45 f4 fc ff ff ff 	movl   $0xfffffffc,-0xc(%ebp)
    //    4. call copy_thread to setup tf & context in proc_struct
    //    5. insert proc_struct into hash_list && proc_list
    //    6. call wakeup_proc to make the new child process RUNNABLE
    //    7. set ret vaule using child proc's pid
    //第一步：申请进程块，如果失败，直接返回处理
    if ((proc = alloc_proc()) == NULL) {
c0108cb8:	e8 20 fa ff ff       	call   c01086dd <alloc_proc>
c0108cbd:	89 45 f0             	mov    %eax,-0x10(%ebp)
c0108cc0:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
c0108cc4:	0f 84 f6 00 00 00    	je     c0108dc0 <do_fork+0x12c>
        goto fork_out;
    }
    //申请成功，则新的线程的父进程是当前进程，也就对应着init_proc的父进程是idleproc
    proc->parent = current;
c0108cca:	8b 15 28 90 12 c0    	mov    0xc0129028,%edx
c0108cd0:	8b 45 f0             	mov    -0x10(%ebp),%eax
c0108cd3:	89 50 14             	mov    %edx,0x14(%eax)
    //第二步：为进程分配一个内核栈，若失败则将分配的页释放
    //274行
    if (setup_kstack(proc) != 0) {
c0108cd6:	8b 45 f0             	mov    -0x10(%ebp),%eax
c0108cd9:	89 04 24             	mov    %eax,(%esp)
c0108cdc:	e8 2d fe ff ff       	call   c0108b0e <setup_kstack>
c0108ce1:	85 c0                	test   %eax,%eax
c0108ce3:	0f 85 eb 00 00 00    	jne    c0108dd4 <do_fork+0x140>
        goto bad_fork_cleanup_proc;
    }
    //call copy_mm to dup OR share mm according clone_flag
    //292
    //3.根据cloneflags来设置复制/共享内存空间——在本次实验中因为系统进程没有虚存，mm为null
    if (copy_mm(clone_flags, proc) != 0) {
c0108ce9:	8b 45 f0             	mov    -0x10(%ebp),%eax
c0108cec:	89 44 24 04          	mov    %eax,0x4(%esp)
c0108cf0:	8b 45 08             	mov    0x8(%ebp),%eax
c0108cf3:	89 04 24             	mov    %eax,(%esp)
c0108cf6:	e8 76 fe ff ff       	call   c0108b71 <copy_mm>
c0108cfb:	85 c0                	test   %eax,%eax
c0108cfd:	0f 85 c3 00 00 00    	jne    c0108dc6 <do_fork+0x132>
        goto bad_fork_cleanup_kstack;
    }
    //301
    //4.设置进程在内核（将来也包括用户态）正常运行和调度所需的中断帧和执行上下文
    copy_thread(proc, stack, tf);
c0108d03:	8b 45 10             	mov    0x10(%ebp),%eax
c0108d06:	89 44 24 08          	mov    %eax,0x8(%esp)
c0108d0a:	8b 45 0c             	mov    0xc(%ebp),%eax
c0108d0d:	89 44 24 04          	mov    %eax,0x4(%esp)
c0108d11:	8b 45 f0             	mov    -0x10(%ebp),%eax
c0108d14:	89 04 24             	mov    %eax,(%esp)
c0108d17:	e8 92 fe ff ff       	call   c0108bae <copy_thread>

    //5.原子性执行以下操作：
    bool intr_flag;
    local_intr_save(intr_flag);//sync.h24
c0108d1c:	e8 72 f8 ff ff       	call   c0108593 <__intr_save>
c0108d21:	89 45 ec             	mov    %eax,-0x14(%ebp)
    {
        proc->pid = get_pid();//138，为进程分配一个独一无二的进程号
c0108d24:	e8 fe fa ff ff       	call   c0108827 <get_pid>
c0108d29:	89 c2                	mov    %eax,%edx
c0108d2b:	8b 45 f0             	mov    -0x10(%ebp),%eax
c0108d2e:	89 50 04             	mov    %edx,0x4(%eax)
        hash_proc(proc);//220将进程id进行哈希运算后放入proc的哈希列表
c0108d31:	8b 45 f0             	mov    -0x10(%ebp),%eax
c0108d34:	89 04 24             	mov    %eax,(%esp)
c0108d37:	e8 6f fc ff ff       	call   c01089ab <hash_proc>
        list_add(&proc_list, &(proc->list_link));//将proc放入proc链表
c0108d3c:	8b 45 f0             	mov    -0x10(%ebp),%eax
c0108d3f:	83 c0 58             	add    $0x58,%eax
c0108d42:	c7 45 e8 50 b1 12 c0 	movl   $0xc012b150,-0x18(%ebp)
c0108d49:	89 45 e4             	mov    %eax,-0x1c(%ebp)
c0108d4c:	8b 45 e8             	mov    -0x18(%ebp),%eax
c0108d4f:	89 45 e0             	mov    %eax,-0x20(%ebp)
c0108d52:	8b 45 e4             	mov    -0x1c(%ebp),%eax
c0108d55:	89 45 dc             	mov    %eax,-0x24(%ebp)
    __list_add(elm, listelm, listelm->next);
c0108d58:	8b 45 e0             	mov    -0x20(%ebp),%eax
c0108d5b:	8b 40 04             	mov    0x4(%eax),%eax
c0108d5e:	8b 55 dc             	mov    -0x24(%ebp),%edx
c0108d61:	89 55 d8             	mov    %edx,-0x28(%ebp)
c0108d64:	8b 55 e0             	mov    -0x20(%ebp),%edx
c0108d67:	89 55 d4             	mov    %edx,-0x2c(%ebp)
c0108d6a:	89 45 d0             	mov    %eax,-0x30(%ebp)
    prev->next = next->prev = elm;
c0108d6d:	8b 45 d0             	mov    -0x30(%ebp),%eax
c0108d70:	8b 55 d8             	mov    -0x28(%ebp),%edx
c0108d73:	89 10                	mov    %edx,(%eax)
c0108d75:	8b 45 d0             	mov    -0x30(%ebp),%eax
c0108d78:	8b 10                	mov    (%eax),%edx
c0108d7a:	8b 45 d4             	mov    -0x2c(%ebp),%eax
c0108d7d:	89 50 04             	mov    %edx,0x4(%eax)
    elm->next = next;
c0108d80:	8b 45 d8             	mov    -0x28(%ebp),%eax
c0108d83:	8b 55 d0             	mov    -0x30(%ebp),%edx
c0108d86:	89 50 04             	mov    %edx,0x4(%eax)
    elm->prev = prev;
c0108d89:	8b 45 d8             	mov    -0x28(%ebp),%eax
c0108d8c:	8b 55 d4             	mov    -0x2c(%ebp),%edx
c0108d8f:	89 10                	mov    %edx,(%eax)
        nr_process ++;
c0108d91:	a1 40 b0 12 c0       	mov    0xc012b040,%eax
c0108d96:	40                   	inc    %eax
c0108d97:	a3 40 b0 12 c0       	mov    %eax,0xc012b040
    }
    local_intr_restore(intr_flag);//恢复中断
c0108d9c:	8b 45 ec             	mov    -0x14(%ebp),%eax
c0108d9f:	89 04 24             	mov    %eax,(%esp)
c0108da2:	e8 16 f8 ff ff       	call   c01085bd <__intr_restore>

    wakeup_proc(proc);//sched.c将proc的状态设置为可执行runnable
c0108da7:	8b 45 f0             	mov    -0x10(%ebp),%eax
c0108daa:	89 04 24             	mov    %eax,(%esp)
c0108dad:	e8 bf 02 00 00       	call   c0109071 <wakeup_proc>
    //返回值为子进程的id
    ret = proc->pid;
c0108db2:	8b 45 f0             	mov    -0x10(%ebp),%eax
c0108db5:	8b 40 04             	mov    0x4(%eax),%eax
c0108db8:	89 45 f4             	mov    %eax,-0xc(%ebp)
c0108dbb:	eb 04                	jmp    c0108dc1 <do_fork+0x12d>
        goto fork_out;
c0108dbd:	90                   	nop
c0108dbe:	eb 01                	jmp    c0108dc1 <do_fork+0x12d>
        goto fork_out;
c0108dc0:	90                   	nop
    //之后回到proc_init
fork_out:
    return ret;
c0108dc1:	8b 45 f4             	mov    -0xc(%ebp),%eax
c0108dc4:	eb 1c                	jmp    c0108de2 <do_fork+0x14e>
        goto bad_fork_cleanup_kstack;
c0108dc6:	90                   	nop

bad_fork_cleanup_kstack:
    put_kstack(proc);
c0108dc7:	8b 45 f0             	mov    -0x10(%ebp),%eax
c0108dca:	89 04 24             	mov    %eax,(%esp)
c0108dcd:	e8 78 fd ff ff       	call   c0108b4a <put_kstack>
c0108dd2:	eb 01                	jmp    c0108dd5 <do_fork+0x141>
        goto bad_fork_cleanup_proc;
c0108dd4:	90                   	nop
bad_fork_cleanup_proc:
    kfree(proc);
c0108dd5:	8b 45 f0             	mov    -0x10(%ebp),%eax
c0108dd8:	89 04 24             	mov    %eax,(%esp)
c0108ddb:	e8 9c d6 ff ff       	call   c010647c <kfree>
    goto fork_out;
c0108de0:	eb df                	jmp    c0108dc1 <do_fork+0x12d>
}
c0108de2:	c9                   	leave  
c0108de3:	c3                   	ret    

c0108de4 <do_exit>:
// do_exit - called by sys_exit
//   1. call exit_mmap & put_pgdir & mm_destroy to free the almost all memory space of process
//   2. set process' state as PROC_ZOMBIE, then call wakeup_proc(parent) to ask parent reclaim itself.
//   3. call scheduler to switch to other process
int
do_exit(int error_code) {
c0108de4:	55                   	push   %ebp
c0108de5:	89 e5                	mov    %esp,%ebp
c0108de7:	83 ec 18             	sub    $0x18,%esp
    panic("process exit!!.\n");
c0108dea:	c7 44 24 08 15 bd 10 	movl   $0xc010bd15,0x8(%esp)
c0108df1:	c0 
c0108df2:	c7 44 24 04 9b 01 00 	movl   $0x19b,0x4(%esp)
c0108df9:	00 
c0108dfa:	c7 04 24 01 bd 10 c0 	movl   $0xc010bd01,(%esp)
c0108e01:	e8 fa 75 ff ff       	call   c0100400 <__panic>

c0108e06 <init_main>:
}

// init_main - the second kernel thread used to create user_main kernel threads
static int
init_main(void *arg) {
c0108e06:	55                   	push   %ebp
c0108e07:	89 e5                	mov    %esp,%ebp
c0108e09:	83 ec 18             	sub    $0x18,%esp
    cprintf("this initproc, pid = %d, name = \"%s\"\n", current->pid, get_proc_name(current));
c0108e0c:	a1 28 90 12 c0       	mov    0xc0129028,%eax
c0108e11:	89 04 24             	mov    %eax,(%esp)
c0108e14:	e8 cc f9 ff ff       	call   c01087e5 <get_proc_name>
c0108e19:	89 c2                	mov    %eax,%edx
c0108e1b:	a1 28 90 12 c0       	mov    0xc0129028,%eax
c0108e20:	8b 40 04             	mov    0x4(%eax),%eax
c0108e23:	89 54 24 08          	mov    %edx,0x8(%esp)
c0108e27:	89 44 24 04          	mov    %eax,0x4(%esp)
c0108e2b:	c7 04 24 28 bd 10 c0 	movl   $0xc010bd28,(%esp)
c0108e32:	e8 72 74 ff ff       	call   c01002a9 <cprintf>
    cprintf("To U: \"%s\".\n", (const char *)arg);
c0108e37:	8b 45 08             	mov    0x8(%ebp),%eax
c0108e3a:	89 44 24 04          	mov    %eax,0x4(%esp)
c0108e3e:	c7 04 24 4e bd 10 c0 	movl   $0xc010bd4e,(%esp)
c0108e45:	e8 5f 74 ff ff       	call   c01002a9 <cprintf>
    cprintf("To U: \"en.., Bye, Bye. :)\"\n");
c0108e4a:	c7 04 24 5b bd 10 c0 	movl   $0xc010bd5b,(%esp)
c0108e51:	e8 53 74 ff ff       	call   c01002a9 <cprintf>
    return 0;
c0108e56:	b8 00 00 00 00       	mov    $0x0,%eax
}
c0108e5b:	c9                   	leave  
c0108e5c:	c3                   	ret    

c0108e5d <proc_init>:

// proc_init - set up the first kernel thread idleproc "idle" by itself and 
//           - create the second kernel thread init_main
//设置第一个内核线程空闲进程“idle”，并创建第二个内核线程init_main
void
proc_init(void) {
c0108e5d:	55                   	push   %ebp
c0108e5e:	89 e5                	mov    %esp,%ebp
c0108e60:	83 ec 28             	sub    $0x28,%esp
c0108e63:	c7 45 ec 50 b1 12 c0 	movl   $0xc012b150,-0x14(%ebp)
    elm->prev = elm->next = elm;
c0108e6a:	8b 45 ec             	mov    -0x14(%ebp),%eax
c0108e6d:	8b 55 ec             	mov    -0x14(%ebp),%edx
c0108e70:	89 50 04             	mov    %edx,0x4(%eax)
c0108e73:	8b 45 ec             	mov    -0x14(%ebp),%eax
c0108e76:	8b 50 04             	mov    0x4(%eax),%edx
c0108e79:	8b 45 ec             	mov    -0x14(%ebp),%eax
c0108e7c:	89 10                	mov    %edx,(%eax)
    int i;

    list_init(&proc_list);//将进程集合列表初始化（将proc_list的prev和next指向自己）
    for (i = 0; i < HASH_LIST_SIZE; i ++) {
c0108e7e:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
c0108e85:	eb 25                	jmp    c0108eac <proc_init+0x4f>
        list_init(hash_list + i);
c0108e87:	8b 45 f4             	mov    -0xc(%ebp),%eax
c0108e8a:	c1 e0 03             	shl    $0x3,%eax
c0108e8d:	05 40 90 12 c0       	add    $0xc0129040,%eax
c0108e92:	89 45 e8             	mov    %eax,-0x18(%ebp)
c0108e95:	8b 45 e8             	mov    -0x18(%ebp),%eax
c0108e98:	8b 55 e8             	mov    -0x18(%ebp),%edx
c0108e9b:	89 50 04             	mov    %edx,0x4(%eax)
c0108e9e:	8b 45 e8             	mov    -0x18(%ebp),%eax
c0108ea1:	8b 50 04             	mov    0x4(%eax),%edx
c0108ea4:	8b 45 e8             	mov    -0x18(%ebp),%eax
c0108ea7:	89 10                	mov    %edx,(%eax)
    for (i = 0; i < HASH_LIST_SIZE; i ++) {
c0108ea9:	ff 45 f4             	incl   -0xc(%ebp)
c0108eac:	81 7d f4 ff 03 00 00 	cmpl   $0x3ff,-0xc(%ebp)
c0108eb3:	7e d2                	jle    c0108e87 <proc_init+0x2a>
    }
    //86行
    if ((idleproc = alloc_proc()) == NULL) {
c0108eb5:	e8 23 f8 ff ff       	call   c01086dd <alloc_proc>
c0108eba:	a3 20 90 12 c0       	mov    %eax,0xc0129020
c0108ebf:	a1 20 90 12 c0       	mov    0xc0129020,%eax
c0108ec4:	85 c0                	test   %eax,%eax
c0108ec6:	75 1c                	jne    c0108ee4 <proc_init+0x87>
        panic("cannot alloc idleproc.\n");
c0108ec8:	c7 44 24 08 77 bd 10 	movl   $0xc010bd77,0x8(%esp)
c0108ecf:	c0 
c0108ed0:	c7 44 24 04 b4 01 00 	movl   $0x1b4,0x4(%esp)
c0108ed7:	00 
c0108ed8:	c7 04 24 01 bd 10 c0 	movl   $0xc010bd01,(%esp)
c0108edf:	e8 1c 75 ff ff       	call   c0100400 <__panic>
    }
    //初始化idleproc后进行相关状态的变更
    idleproc->pid = 0;//进程id=0
c0108ee4:	a1 20 90 12 c0       	mov    0xc0129020,%eax
c0108ee9:	c7 40 04 00 00 00 00 	movl   $0x0,0x4(%eax)
    idleproc->state = PROC_RUNNABLE;//可执行状态
c0108ef0:	a1 20 90 12 c0       	mov    0xc0129020,%eax
c0108ef5:	c7 00 02 00 00 00    	movl   $0x2,(%eax)
    idleproc->kstack = (uintptr_t)bootstack;//内核栈位置为entry.s的bootstack
c0108efb:	a1 20 90 12 c0       	mov    0xc0129020,%eax
c0108f00:	ba 00 30 12 c0       	mov    $0xc0123000,%edx
c0108f05:	89 50 0c             	mov    %edx,0xc(%eax)
    idleproc->need_resched = 1;//需要重新参与调度以释放CPU
c0108f08:	a1 20 90 12 c0       	mov    0xc0129020,%eax
c0108f0d:	c7 40 10 01 00 00 00 	movl   $0x1,0x10(%eax)
    set_proc_name(idleproc, "idle");
c0108f14:	a1 20 90 12 c0       	mov    0xc0129020,%eax
c0108f19:	c7 44 24 04 8f bd 10 	movl   $0xc010bd8f,0x4(%esp)
c0108f20:	c0 
c0108f21:	89 04 24             	mov    %eax,(%esp)
c0108f24:	e8 79 f8 ff ff       	call   c01087a2 <set_proc_name>
    nr_process ++;//当前进程数量
c0108f29:	a1 40 b0 12 c0       	mov    0xc012b040,%eax
c0108f2e:	40                   	inc    %eax
c0108f2f:	a3 40 b0 12 c0       	mov    %eax,0xc012b040

    current = idleproc;//当前进程为idleproc
c0108f34:	a1 20 90 12 c0       	mov    0xc0129020,%eax
c0108f39:	a3 28 90 12 c0       	mov    %eax,0xc0129028
    
    //得到的pid是init_proc的
    int pid = kernel_thread(init_main, "Hello world!!", 0);//254
c0108f3e:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
c0108f45:	00 
c0108f46:	c7 44 24 04 94 bd 10 	movl   $0xc010bd94,0x4(%esp)
c0108f4d:	c0 
c0108f4e:	c7 04 24 06 8e 10 c0 	movl   $0xc0108e06,(%esp)
c0108f55:	e8 40 fb ff ff       	call   c0108a9a <kernel_thread>
c0108f5a:	89 45 f0             	mov    %eax,-0x10(%ebp)
    if (pid <= 0) {//说明未创建成功
c0108f5d:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
c0108f61:	7f 1c                	jg     c0108f7f <proc_init+0x122>
        panic("create init_main failed.\n");
c0108f63:	c7 44 24 08 a2 bd 10 	movl   $0xc010bda2,0x8(%esp)
c0108f6a:	c0 
c0108f6b:	c7 44 24 04 c3 01 00 	movl   $0x1c3,0x4(%esp)
c0108f72:	00 
c0108f73:	c7 04 24 01 bd 10 c0 	movl   $0xc010bd01,(%esp)
c0108f7a:	e8 81 74 ff ff       	call   c0100400 <__panic>
    }

    initproc = find_proc(pid);//找到initproc
c0108f7f:	8b 45 f0             	mov    -0x10(%ebp),%eax
c0108f82:	89 04 24             	mov    %eax,(%esp)
c0108f85:	e8 9e fa ff ff       	call   c0108a28 <find_proc>
c0108f8a:	a3 24 90 12 c0       	mov    %eax,0xc0129024
    set_proc_name(initproc, "init");
c0108f8f:	a1 24 90 12 c0       	mov    0xc0129024,%eax
c0108f94:	c7 44 24 04 bc bd 10 	movl   $0xc010bdbc,0x4(%esp)
c0108f9b:	c0 
c0108f9c:	89 04 24             	mov    %eax,(%esp)
c0108f9f:	e8 fe f7 ff ff       	call   c01087a2 <set_proc_name>

    assert(idleproc != NULL && idleproc->pid == 0);
c0108fa4:	a1 20 90 12 c0       	mov    0xc0129020,%eax
c0108fa9:	85 c0                	test   %eax,%eax
c0108fab:	74 0c                	je     c0108fb9 <proc_init+0x15c>
c0108fad:	a1 20 90 12 c0       	mov    0xc0129020,%eax
c0108fb2:	8b 40 04             	mov    0x4(%eax),%eax
c0108fb5:	85 c0                	test   %eax,%eax
c0108fb7:	74 24                	je     c0108fdd <proc_init+0x180>
c0108fb9:	c7 44 24 0c c4 bd 10 	movl   $0xc010bdc4,0xc(%esp)
c0108fc0:	c0 
c0108fc1:	c7 44 24 08 ec bc 10 	movl   $0xc010bcec,0x8(%esp)
c0108fc8:	c0 
c0108fc9:	c7 44 24 04 c9 01 00 	movl   $0x1c9,0x4(%esp)
c0108fd0:	00 
c0108fd1:	c7 04 24 01 bd 10 c0 	movl   $0xc010bd01,(%esp)
c0108fd8:	e8 23 74 ff ff       	call   c0100400 <__panic>
    assert(initproc != NULL && initproc->pid == 1);
c0108fdd:	a1 24 90 12 c0       	mov    0xc0129024,%eax
c0108fe2:	85 c0                	test   %eax,%eax
c0108fe4:	74 0d                	je     c0108ff3 <proc_init+0x196>
c0108fe6:	a1 24 90 12 c0       	mov    0xc0129024,%eax
c0108feb:	8b 40 04             	mov    0x4(%eax),%eax
c0108fee:	83 f8 01             	cmp    $0x1,%eax
c0108ff1:	74 24                	je     c0109017 <proc_init+0x1ba>
c0108ff3:	c7 44 24 0c ec bd 10 	movl   $0xc010bdec,0xc(%esp)
c0108ffa:	c0 
c0108ffb:	c7 44 24 08 ec bc 10 	movl   $0xc010bcec,0x8(%esp)
c0109002:	c0 
c0109003:	c7 44 24 04 ca 01 00 	movl   $0x1ca,0x4(%esp)
c010900a:	00 
c010900b:	c7 04 24 01 bd 10 c0 	movl   $0xc010bd01,(%esp)
c0109012:	e8 e9 73 ff ff       	call   c0100400 <__panic>
}
c0109017:	90                   	nop
c0109018:	c9                   	leave  
c0109019:	c3                   	ret    

c010901a <cpu_idle>:

// cpu_idle - at the end of kern_init, the first kernel thread idleproc will do below works
void
cpu_idle(void) {
c010901a:	55                   	push   %ebp
c010901b:	89 e5                	mov    %esp,%ebp
c010901d:	83 ec 08             	sub    $0x8,%esp
    while (1) {
        //一旦当前进程需要重新调度
        //sched.c
        if (current->need_resched) {
c0109020:	a1 28 90 12 c0       	mov    0xc0129028,%eax
c0109025:	8b 40 10             	mov    0x10(%eax),%eax
c0109028:	85 c0                	test   %eax,%eax
c010902a:	74 f4                	je     c0109020 <cpu_idle+0x6>
            schedule();
c010902c:	e8 8a 00 00 00       	call   c01090bb <schedule>
        if (current->need_resched) {
c0109031:	eb ed                	jmp    c0109020 <cpu_idle+0x6>

c0109033 <__intr_save>:
__intr_save(void) {
c0109033:	55                   	push   %ebp
c0109034:	89 e5                	mov    %esp,%ebp
c0109036:	83 ec 18             	sub    $0x18,%esp
    asm volatile ("pushfl; popl %0" : "=r" (eflags));
c0109039:	9c                   	pushf  
c010903a:	58                   	pop    %eax
c010903b:	89 45 f4             	mov    %eax,-0xc(%ebp)
    return eflags;
c010903e:	8b 45 f4             	mov    -0xc(%ebp),%eax
    if (read_eflags() & FL_IF) {//读操作出现中断
c0109041:	25 00 02 00 00       	and    $0x200,%eax
c0109046:	85 c0                	test   %eax,%eax
c0109048:	74 0c                	je     c0109056 <__intr_save+0x23>
        intr_disable();//intr.c12->禁用irq中断
c010904a:	e8 e3 8f ff ff       	call   c0102032 <intr_disable>
        return 1;
c010904f:	b8 01 00 00 00       	mov    $0x1,%eax
c0109054:	eb 05                	jmp    c010905b <__intr_save+0x28>
    return 0;
c0109056:	b8 00 00 00 00       	mov    $0x0,%eax
}
c010905b:	c9                   	leave  
c010905c:	c3                   	ret    

c010905d <__intr_restore>:
__intr_restore(bool flag) {
c010905d:	55                   	push   %ebp
c010905e:	89 e5                	mov    %esp,%ebp
c0109060:	83 ec 08             	sub    $0x8,%esp
    if (flag) {
c0109063:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
c0109067:	74 05                	je     c010906e <__intr_restore+0x11>
        intr_enable();
c0109069:	e8 bd 8f ff ff       	call   c010202b <intr_enable>
}
c010906e:	90                   	nop
c010906f:	c9                   	leave  
c0109070:	c3                   	ret    

c0109071 <wakeup_proc>:
#include <proc.h>
#include <sched.h>
#include <assert.h>

void
wakeup_proc(struct proc_struct *proc) {
c0109071:	55                   	push   %ebp
c0109072:	89 e5                	mov    %esp,%ebp
c0109074:	83 ec 18             	sub    $0x18,%esp
    assert(proc->state != PROC_ZOMBIE && proc->state != PROC_RUNNABLE);
c0109077:	8b 45 08             	mov    0x8(%ebp),%eax
c010907a:	8b 00                	mov    (%eax),%eax
c010907c:	83 f8 03             	cmp    $0x3,%eax
c010907f:	74 0a                	je     c010908b <wakeup_proc+0x1a>
c0109081:	8b 45 08             	mov    0x8(%ebp),%eax
c0109084:	8b 00                	mov    (%eax),%eax
c0109086:	83 f8 02             	cmp    $0x2,%eax
c0109089:	75 24                	jne    c01090af <wakeup_proc+0x3e>
c010908b:	c7 44 24 0c 14 be 10 	movl   $0xc010be14,0xc(%esp)
c0109092:	c0 
c0109093:	c7 44 24 08 4f be 10 	movl   $0xc010be4f,0x8(%esp)
c010909a:	c0 
c010909b:	c7 44 24 04 09 00 00 	movl   $0x9,0x4(%esp)
c01090a2:	00 
c01090a3:	c7 04 24 64 be 10 c0 	movl   $0xc010be64,(%esp)
c01090aa:	e8 51 73 ff ff       	call   c0100400 <__panic>
    proc->state = PROC_RUNNABLE;
c01090af:	8b 45 08             	mov    0x8(%ebp),%eax
c01090b2:	c7 00 02 00 00 00    	movl   $0x2,(%eax)
}
c01090b8:	90                   	nop
c01090b9:	c9                   	leave  
c01090ba:	c3                   	ret    

c01090bb <schedule>:

void
schedule(void) {
c01090bb:	55                   	push   %ebp
c01090bc:	89 e5                	mov    %esp,%ebp
c01090be:	83 ec 38             	sub    $0x38,%esp
    bool intr_flag; //定义中断变量
    list_entry_t *le, *last; //当前list，下一list
    struct proc_struct *next = NULL; //下一进程
c01090c1:	c7 45 f0 00 00 00 00 	movl   $0x0,-0x10(%ebp)
    //关闭中断
    local_intr_save(intr_flag); 
c01090c8:	e8 66 ff ff ff       	call   c0109033 <__intr_save>
c01090cd:	89 45 ec             	mov    %eax,-0x14(%ebp)
    {
        current->need_resched = 0; //保护进程切换不会被中断，以免进程切换时其他进程再进行调度，相当于互斥锁
c01090d0:	a1 28 90 12 c0       	mov    0xc0129028,%eax
c01090d5:	c7 40 10 00 00 00 00 	movl   $0x0,0x10(%eax)
        //last是否是idle进程(第一个创建的进程),如果是，则从表头开始搜索  否则获取下一链表
        last = (current == idleproc) ? &proc_list : &(current->list_link);
c01090dc:	8b 15 28 90 12 c0    	mov    0xc0129028,%edx
c01090e2:	a1 20 90 12 c0       	mov    0xc0129020,%eax
c01090e7:	39 c2                	cmp    %eax,%edx
c01090e9:	74 0a                	je     c01090f5 <schedule+0x3a>
c01090eb:	a1 28 90 12 c0       	mov    0xc0129028,%eax
c01090f0:	83 c0 58             	add    $0x58,%eax
c01090f3:	eb 05                	jmp    c01090fa <schedule+0x3f>
c01090f5:	b8 50 b1 12 c0       	mov    $0xc012b150,%eax
c01090fa:	89 45 e8             	mov    %eax,-0x18(%ebp)
        le = last; 
c01090fd:	8b 45 e8             	mov    -0x18(%ebp),%eax
c0109100:	89 45 f4             	mov    %eax,-0xc(%ebp)
c0109103:	8b 45 f4             	mov    -0xc(%ebp),%eax
c0109106:	89 45 e4             	mov    %eax,-0x1c(%ebp)
    return listelm->next;
c0109109:	8b 45 e4             	mov    -0x1c(%ebp),%eax
c010910c:	8b 40 04             	mov    0x4(%eax),%eax
        //循环找到可调度的进程
        do 
        { 
            if ((le = list_next(le)) != &proc_list) 
c010910f:	89 45 f4             	mov    %eax,-0xc(%ebp)
c0109112:	81 7d f4 50 b1 12 c0 	cmpl   $0xc012b150,-0xc(%ebp)
c0109119:	74 13                	je     c010912e <schedule+0x73>
            {
                //获取下一进程
                next = le2proc(le, list_link);
c010911b:	8b 45 f4             	mov    -0xc(%ebp),%eax
c010911e:	83 e8 58             	sub    $0x58,%eax
c0109121:	89 45 f0             	mov    %eax,-0x10(%ebp)
                //找到一个可以调度的进程，break
                if (next->state == PROC_RUNNABLE) 
c0109124:	8b 45 f0             	mov    -0x10(%ebp),%eax
c0109127:	8b 00                	mov    (%eax),%eax
c0109129:	83 f8 02             	cmp    $0x2,%eax
c010912c:	74 0a                	je     c0109138 <schedule+0x7d>
					break;
            }
        } while (le != last);
c010912e:	8b 45 f4             	mov    -0xc(%ebp),%eax
c0109131:	3b 45 e8             	cmp    -0x18(%ebp),%eax
c0109134:	75 cd                	jne    c0109103 <schedule+0x48>
c0109136:	eb 01                	jmp    c0109139 <schedule+0x7e>
					break;
c0109138:	90                   	nop
        //如果没有找到可调度的进程
        if (next == NULL || next->state != PROC_RUNNABLE) 
c0109139:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
c010913d:	74 0a                	je     c0109149 <schedule+0x8e>
c010913f:	8b 45 f0             	mov    -0x10(%ebp),%eax
c0109142:	8b 00                	mov    (%eax),%eax
c0109144:	83 f8 02             	cmp    $0x2,%eax
c0109147:	74 08                	je     c0109151 <schedule+0x96>
        {
            next = idleproc; 
c0109149:	a1 20 90 12 c0       	mov    0xc0129020,%eax
c010914e:	89 45 f0             	mov    %eax,-0x10(%ebp)
        }
        next->runs ++; //运行次数加一
c0109151:	8b 45 f0             	mov    -0x10(%ebp),%eax
c0109154:	8b 40 08             	mov    0x8(%eax),%eax
c0109157:	8d 50 01             	lea    0x1(%eax),%edx
c010915a:	8b 45 f0             	mov    -0x10(%ebp),%eax
c010915d:	89 50 08             	mov    %edx,0x8(%eax)
        //##########运行新进程,调用proc_run函数###########
        if (next != current)
c0109160:	a1 28 90 12 c0       	mov    0xc0129028,%eax
c0109165:	39 45 f0             	cmp    %eax,-0x10(%ebp)
c0109168:	74 0b                	je     c0109175 <schedule+0xba>
        {
            proc_run(next); 
c010916a:	8b 45 f0             	mov    -0x10(%ebp),%eax
c010916d:	89 04 24             	mov    %eax,(%esp)
c0109170:	e8 a7 f7 ff ff       	call   c010891c <proc_run>
        }
    }
    //恢复中断
    local_intr_restore(intr_flag); 
c0109175:	8b 45 ec             	mov    -0x14(%ebp),%eax
c0109178:	89 04 24             	mov    %eax,(%esp)
c010917b:	e8 dd fe ff ff       	call   c010905d <__intr_restore>
}
c0109180:	90                   	nop
c0109181:	c9                   	leave  
c0109182:	c3                   	ret    

c0109183 <strlen>:
 * @s:      the input string
 *
 * The strlen() function returns the length of string @s.
 * */
size_t
strlen(const char *s) {
c0109183:	55                   	push   %ebp
c0109184:	89 e5                	mov    %esp,%ebp
c0109186:	83 ec 10             	sub    $0x10,%esp
    size_t cnt = 0;
c0109189:	c7 45 fc 00 00 00 00 	movl   $0x0,-0x4(%ebp)
    while (*s ++ != '\0') {
c0109190:	eb 03                	jmp    c0109195 <strlen+0x12>
        cnt ++;
c0109192:	ff 45 fc             	incl   -0x4(%ebp)
    while (*s ++ != '\0') {
c0109195:	8b 45 08             	mov    0x8(%ebp),%eax
c0109198:	8d 50 01             	lea    0x1(%eax),%edx
c010919b:	89 55 08             	mov    %edx,0x8(%ebp)
c010919e:	0f b6 00             	movzbl (%eax),%eax
c01091a1:	84 c0                	test   %al,%al
c01091a3:	75 ed                	jne    c0109192 <strlen+0xf>
    }
    return cnt;
c01091a5:	8b 45 fc             	mov    -0x4(%ebp),%eax
}
c01091a8:	c9                   	leave  
c01091a9:	c3                   	ret    

c01091aa <strnlen>:
 * The return value is strlen(s), if that is less than @len, or
 * @len if there is no '\0' character among the first @len characters
 * pointed by @s.
 * */
size_t
strnlen(const char *s, size_t len) {
c01091aa:	55                   	push   %ebp
c01091ab:	89 e5                	mov    %esp,%ebp
c01091ad:	83 ec 10             	sub    $0x10,%esp
    size_t cnt = 0;
c01091b0:	c7 45 fc 00 00 00 00 	movl   $0x0,-0x4(%ebp)
    while (cnt < len && *s ++ != '\0') {
c01091b7:	eb 03                	jmp    c01091bc <strnlen+0x12>
        cnt ++;
c01091b9:	ff 45 fc             	incl   -0x4(%ebp)
    while (cnt < len && *s ++ != '\0') {
c01091bc:	8b 45 fc             	mov    -0x4(%ebp),%eax
c01091bf:	3b 45 0c             	cmp    0xc(%ebp),%eax
c01091c2:	73 10                	jae    c01091d4 <strnlen+0x2a>
c01091c4:	8b 45 08             	mov    0x8(%ebp),%eax
c01091c7:	8d 50 01             	lea    0x1(%eax),%edx
c01091ca:	89 55 08             	mov    %edx,0x8(%ebp)
c01091cd:	0f b6 00             	movzbl (%eax),%eax
c01091d0:	84 c0                	test   %al,%al
c01091d2:	75 e5                	jne    c01091b9 <strnlen+0xf>
    }
    return cnt;
c01091d4:	8b 45 fc             	mov    -0x4(%ebp),%eax
}
c01091d7:	c9                   	leave  
c01091d8:	c3                   	ret    

c01091d9 <strcpy>:
 * To avoid overflows, the size of array pointed by @dst should be long enough to
 * contain the same string as @src (including the terminating null character), and
 * should not overlap in memory with @src.
 * */
char *
strcpy(char *dst, const char *src) {
c01091d9:	55                   	push   %ebp
c01091da:	89 e5                	mov    %esp,%ebp
c01091dc:	57                   	push   %edi
c01091dd:	56                   	push   %esi
c01091de:	83 ec 20             	sub    $0x20,%esp
c01091e1:	8b 45 08             	mov    0x8(%ebp),%eax
c01091e4:	89 45 f4             	mov    %eax,-0xc(%ebp)
c01091e7:	8b 45 0c             	mov    0xc(%ebp),%eax
c01091ea:	89 45 f0             	mov    %eax,-0x10(%ebp)
#ifndef __HAVE_ARCH_STRCPY
#define __HAVE_ARCH_STRCPY
static inline char *
__strcpy(char *dst, const char *src) {
    int d0, d1, d2;
    asm volatile (
c01091ed:	8b 55 f0             	mov    -0x10(%ebp),%edx
c01091f0:	8b 45 f4             	mov    -0xc(%ebp),%eax
c01091f3:	89 d1                	mov    %edx,%ecx
c01091f5:	89 c2                	mov    %eax,%edx
c01091f7:	89 ce                	mov    %ecx,%esi
c01091f9:	89 d7                	mov    %edx,%edi
c01091fb:	ac                   	lods   %ds:(%esi),%al
c01091fc:	aa                   	stos   %al,%es:(%edi)
c01091fd:	84 c0                	test   %al,%al
c01091ff:	75 fa                	jne    c01091fb <strcpy+0x22>
c0109201:	89 fa                	mov    %edi,%edx
c0109203:	89 f1                	mov    %esi,%ecx
c0109205:	89 4d ec             	mov    %ecx,-0x14(%ebp)
c0109208:	89 55 e8             	mov    %edx,-0x18(%ebp)
c010920b:	89 45 e4             	mov    %eax,-0x1c(%ebp)
        "stosb;"
        "testb %%al, %%al;"
        "jne 1b;"
        : "=&S" (d0), "=&D" (d1), "=&a" (d2)
        : "0" (src), "1" (dst) : "memory");
    return dst;
c010920e:	8b 45 f4             	mov    -0xc(%ebp),%eax
#ifdef __HAVE_ARCH_STRCPY
    return __strcpy(dst, src);
c0109211:	90                   	nop
    char *p = dst;
    while ((*p ++ = *src ++) != '\0')
        /* nothing */;
    return dst;
#endif /* __HAVE_ARCH_STRCPY */
}
c0109212:	83 c4 20             	add    $0x20,%esp
c0109215:	5e                   	pop    %esi
c0109216:	5f                   	pop    %edi
c0109217:	5d                   	pop    %ebp
c0109218:	c3                   	ret    

c0109219 <strncpy>:
 * @len:    maximum number of characters to be copied from @src
 *
 * The return value is @dst
 * */
char *
strncpy(char *dst, const char *src, size_t len) {
c0109219:	55                   	push   %ebp
c010921a:	89 e5                	mov    %esp,%ebp
c010921c:	83 ec 10             	sub    $0x10,%esp
    char *p = dst;
c010921f:	8b 45 08             	mov    0x8(%ebp),%eax
c0109222:	89 45 fc             	mov    %eax,-0x4(%ebp)
    while (len > 0) {
c0109225:	eb 1e                	jmp    c0109245 <strncpy+0x2c>
        if ((*p = *src) != '\0') {
c0109227:	8b 45 0c             	mov    0xc(%ebp),%eax
c010922a:	0f b6 10             	movzbl (%eax),%edx
c010922d:	8b 45 fc             	mov    -0x4(%ebp),%eax
c0109230:	88 10                	mov    %dl,(%eax)
c0109232:	8b 45 fc             	mov    -0x4(%ebp),%eax
c0109235:	0f b6 00             	movzbl (%eax),%eax
c0109238:	84 c0                	test   %al,%al
c010923a:	74 03                	je     c010923f <strncpy+0x26>
            src ++;
c010923c:	ff 45 0c             	incl   0xc(%ebp)
        }
        p ++, len --;
c010923f:	ff 45 fc             	incl   -0x4(%ebp)
c0109242:	ff 4d 10             	decl   0x10(%ebp)
    while (len > 0) {
c0109245:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
c0109249:	75 dc                	jne    c0109227 <strncpy+0xe>
    }
    return dst;
c010924b:	8b 45 08             	mov    0x8(%ebp),%eax
}
c010924e:	c9                   	leave  
c010924f:	c3                   	ret    

c0109250 <strcmp>:
 * - A value greater than zero indicates that the first character that does
 *   not match has a greater value in @s1 than in @s2;
 * - And a value less than zero indicates the opposite.
 * */
int
strcmp(const char *s1, const char *s2) {
c0109250:	55                   	push   %ebp
c0109251:	89 e5                	mov    %esp,%ebp
c0109253:	57                   	push   %edi
c0109254:	56                   	push   %esi
c0109255:	83 ec 20             	sub    $0x20,%esp
c0109258:	8b 45 08             	mov    0x8(%ebp),%eax
c010925b:	89 45 f4             	mov    %eax,-0xc(%ebp)
c010925e:	8b 45 0c             	mov    0xc(%ebp),%eax
c0109261:	89 45 f0             	mov    %eax,-0x10(%ebp)
    asm volatile (
c0109264:	8b 55 f4             	mov    -0xc(%ebp),%edx
c0109267:	8b 45 f0             	mov    -0x10(%ebp),%eax
c010926a:	89 d1                	mov    %edx,%ecx
c010926c:	89 c2                	mov    %eax,%edx
c010926e:	89 ce                	mov    %ecx,%esi
c0109270:	89 d7                	mov    %edx,%edi
c0109272:	ac                   	lods   %ds:(%esi),%al
c0109273:	ae                   	scas   %es:(%edi),%al
c0109274:	75 08                	jne    c010927e <strcmp+0x2e>
c0109276:	84 c0                	test   %al,%al
c0109278:	75 f8                	jne    c0109272 <strcmp+0x22>
c010927a:	31 c0                	xor    %eax,%eax
c010927c:	eb 04                	jmp    c0109282 <strcmp+0x32>
c010927e:	19 c0                	sbb    %eax,%eax
c0109280:	0c 01                	or     $0x1,%al
c0109282:	89 fa                	mov    %edi,%edx
c0109284:	89 f1                	mov    %esi,%ecx
c0109286:	89 45 ec             	mov    %eax,-0x14(%ebp)
c0109289:	89 4d e8             	mov    %ecx,-0x18(%ebp)
c010928c:	89 55 e4             	mov    %edx,-0x1c(%ebp)
    return ret;
c010928f:	8b 45 ec             	mov    -0x14(%ebp),%eax
#ifdef __HAVE_ARCH_STRCMP
    return __strcmp(s1, s2);
c0109292:	90                   	nop
    while (*s1 != '\0' && *s1 == *s2) {
        s1 ++, s2 ++;
    }
    return (int)((unsigned char)*s1 - (unsigned char)*s2);
#endif /* __HAVE_ARCH_STRCMP */
}
c0109293:	83 c4 20             	add    $0x20,%esp
c0109296:	5e                   	pop    %esi
c0109297:	5f                   	pop    %edi
c0109298:	5d                   	pop    %ebp
c0109299:	c3                   	ret    

c010929a <strncmp>:
 * they are equal to each other, it continues with the following pairs until
 * the characters differ, until a terminating null-character is reached, or
 * until @n characters match in both strings, whichever happens first.
 * */
int
strncmp(const char *s1, const char *s2, size_t n) {
c010929a:	55                   	push   %ebp
c010929b:	89 e5                	mov    %esp,%ebp
    while (n > 0 && *s1 != '\0' && *s1 == *s2) {
c010929d:	eb 09                	jmp    c01092a8 <strncmp+0xe>
        n --, s1 ++, s2 ++;
c010929f:	ff 4d 10             	decl   0x10(%ebp)
c01092a2:	ff 45 08             	incl   0x8(%ebp)
c01092a5:	ff 45 0c             	incl   0xc(%ebp)
    while (n > 0 && *s1 != '\0' && *s1 == *s2) {
c01092a8:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
c01092ac:	74 1a                	je     c01092c8 <strncmp+0x2e>
c01092ae:	8b 45 08             	mov    0x8(%ebp),%eax
c01092b1:	0f b6 00             	movzbl (%eax),%eax
c01092b4:	84 c0                	test   %al,%al
c01092b6:	74 10                	je     c01092c8 <strncmp+0x2e>
c01092b8:	8b 45 08             	mov    0x8(%ebp),%eax
c01092bb:	0f b6 10             	movzbl (%eax),%edx
c01092be:	8b 45 0c             	mov    0xc(%ebp),%eax
c01092c1:	0f b6 00             	movzbl (%eax),%eax
c01092c4:	38 c2                	cmp    %al,%dl
c01092c6:	74 d7                	je     c010929f <strncmp+0x5>
    }
    return (n == 0) ? 0 : (int)((unsigned char)*s1 - (unsigned char)*s2);
c01092c8:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
c01092cc:	74 18                	je     c01092e6 <strncmp+0x4c>
c01092ce:	8b 45 08             	mov    0x8(%ebp),%eax
c01092d1:	0f b6 00             	movzbl (%eax),%eax
c01092d4:	0f b6 d0             	movzbl %al,%edx
c01092d7:	8b 45 0c             	mov    0xc(%ebp),%eax
c01092da:	0f b6 00             	movzbl (%eax),%eax
c01092dd:	0f b6 c0             	movzbl %al,%eax
c01092e0:	29 c2                	sub    %eax,%edx
c01092e2:	89 d0                	mov    %edx,%eax
c01092e4:	eb 05                	jmp    c01092eb <strncmp+0x51>
c01092e6:	b8 00 00 00 00       	mov    $0x0,%eax
}
c01092eb:	5d                   	pop    %ebp
c01092ec:	c3                   	ret    

c01092ed <strchr>:
 *
 * The strchr() function returns a pointer to the first occurrence of
 * character in @s. If the value is not found, the function returns 'NULL'.
 * */
char *
strchr(const char *s, char c) {
c01092ed:	55                   	push   %ebp
c01092ee:	89 e5                	mov    %esp,%ebp
c01092f0:	83 ec 04             	sub    $0x4,%esp
c01092f3:	8b 45 0c             	mov    0xc(%ebp),%eax
c01092f6:	88 45 fc             	mov    %al,-0x4(%ebp)
    while (*s != '\0') {
c01092f9:	eb 13                	jmp    c010930e <strchr+0x21>
        if (*s == c) {
c01092fb:	8b 45 08             	mov    0x8(%ebp),%eax
c01092fe:	0f b6 00             	movzbl (%eax),%eax
c0109301:	38 45 fc             	cmp    %al,-0x4(%ebp)
c0109304:	75 05                	jne    c010930b <strchr+0x1e>
            return (char *)s;
c0109306:	8b 45 08             	mov    0x8(%ebp),%eax
c0109309:	eb 12                	jmp    c010931d <strchr+0x30>
        }
        s ++;
c010930b:	ff 45 08             	incl   0x8(%ebp)
    while (*s != '\0') {
c010930e:	8b 45 08             	mov    0x8(%ebp),%eax
c0109311:	0f b6 00             	movzbl (%eax),%eax
c0109314:	84 c0                	test   %al,%al
c0109316:	75 e3                	jne    c01092fb <strchr+0xe>
    }
    return NULL;
c0109318:	b8 00 00 00 00       	mov    $0x0,%eax
}
c010931d:	c9                   	leave  
c010931e:	c3                   	ret    

c010931f <strfind>:
 * The strfind() function is like strchr() except that if @c is
 * not found in @s, then it returns a pointer to the null byte at the
 * end of @s, rather than 'NULL'.
 * */
char *
strfind(const char *s, char c) {
c010931f:	55                   	push   %ebp
c0109320:	89 e5                	mov    %esp,%ebp
c0109322:	83 ec 04             	sub    $0x4,%esp
c0109325:	8b 45 0c             	mov    0xc(%ebp),%eax
c0109328:	88 45 fc             	mov    %al,-0x4(%ebp)
    while (*s != '\0') {
c010932b:	eb 0e                	jmp    c010933b <strfind+0x1c>
        if (*s == c) {
c010932d:	8b 45 08             	mov    0x8(%ebp),%eax
c0109330:	0f b6 00             	movzbl (%eax),%eax
c0109333:	38 45 fc             	cmp    %al,-0x4(%ebp)
c0109336:	74 0f                	je     c0109347 <strfind+0x28>
            break;
        }
        s ++;
c0109338:	ff 45 08             	incl   0x8(%ebp)
    while (*s != '\0') {
c010933b:	8b 45 08             	mov    0x8(%ebp),%eax
c010933e:	0f b6 00             	movzbl (%eax),%eax
c0109341:	84 c0                	test   %al,%al
c0109343:	75 e8                	jne    c010932d <strfind+0xe>
c0109345:	eb 01                	jmp    c0109348 <strfind+0x29>
            break;
c0109347:	90                   	nop
    }
    return (char *)s;
c0109348:	8b 45 08             	mov    0x8(%ebp),%eax
}
c010934b:	c9                   	leave  
c010934c:	c3                   	ret    

c010934d <strtol>:
 * an optional "0x" or "0X" prefix.
 *
 * The strtol() function returns the converted integral number as a long int value.
 * */
long
strtol(const char *s, char **endptr, int base) {
c010934d:	55                   	push   %ebp
c010934e:	89 e5                	mov    %esp,%ebp
c0109350:	83 ec 10             	sub    $0x10,%esp
    int neg = 0;
c0109353:	c7 45 fc 00 00 00 00 	movl   $0x0,-0x4(%ebp)
    long val = 0;
c010935a:	c7 45 f8 00 00 00 00 	movl   $0x0,-0x8(%ebp)

    // gobble initial whitespace
    while (*s == ' ' || *s == '\t') {
c0109361:	eb 03                	jmp    c0109366 <strtol+0x19>
        s ++;
c0109363:	ff 45 08             	incl   0x8(%ebp)
    while (*s == ' ' || *s == '\t') {
c0109366:	8b 45 08             	mov    0x8(%ebp),%eax
c0109369:	0f b6 00             	movzbl (%eax),%eax
c010936c:	3c 20                	cmp    $0x20,%al
c010936e:	74 f3                	je     c0109363 <strtol+0x16>
c0109370:	8b 45 08             	mov    0x8(%ebp),%eax
c0109373:	0f b6 00             	movzbl (%eax),%eax
c0109376:	3c 09                	cmp    $0x9,%al
c0109378:	74 e9                	je     c0109363 <strtol+0x16>
    }

    // plus/minus sign
    if (*s == '+') {
c010937a:	8b 45 08             	mov    0x8(%ebp),%eax
c010937d:	0f b6 00             	movzbl (%eax),%eax
c0109380:	3c 2b                	cmp    $0x2b,%al
c0109382:	75 05                	jne    c0109389 <strtol+0x3c>
        s ++;
c0109384:	ff 45 08             	incl   0x8(%ebp)
c0109387:	eb 14                	jmp    c010939d <strtol+0x50>
    }
    else if (*s == '-') {
c0109389:	8b 45 08             	mov    0x8(%ebp),%eax
c010938c:	0f b6 00             	movzbl (%eax),%eax
c010938f:	3c 2d                	cmp    $0x2d,%al
c0109391:	75 0a                	jne    c010939d <strtol+0x50>
        s ++, neg = 1;
c0109393:	ff 45 08             	incl   0x8(%ebp)
c0109396:	c7 45 fc 01 00 00 00 	movl   $0x1,-0x4(%ebp)
    }

    // hex or octal base prefix
    if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x')) {
c010939d:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
c01093a1:	74 06                	je     c01093a9 <strtol+0x5c>
c01093a3:	83 7d 10 10          	cmpl   $0x10,0x10(%ebp)
c01093a7:	75 22                	jne    c01093cb <strtol+0x7e>
c01093a9:	8b 45 08             	mov    0x8(%ebp),%eax
c01093ac:	0f b6 00             	movzbl (%eax),%eax
c01093af:	3c 30                	cmp    $0x30,%al
c01093b1:	75 18                	jne    c01093cb <strtol+0x7e>
c01093b3:	8b 45 08             	mov    0x8(%ebp),%eax
c01093b6:	40                   	inc    %eax
c01093b7:	0f b6 00             	movzbl (%eax),%eax
c01093ba:	3c 78                	cmp    $0x78,%al
c01093bc:	75 0d                	jne    c01093cb <strtol+0x7e>
        s += 2, base = 16;
c01093be:	83 45 08 02          	addl   $0x2,0x8(%ebp)
c01093c2:	c7 45 10 10 00 00 00 	movl   $0x10,0x10(%ebp)
c01093c9:	eb 29                	jmp    c01093f4 <strtol+0xa7>
    }
    else if (base == 0 && s[0] == '0') {
c01093cb:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
c01093cf:	75 16                	jne    c01093e7 <strtol+0x9a>
c01093d1:	8b 45 08             	mov    0x8(%ebp),%eax
c01093d4:	0f b6 00             	movzbl (%eax),%eax
c01093d7:	3c 30                	cmp    $0x30,%al
c01093d9:	75 0c                	jne    c01093e7 <strtol+0x9a>
        s ++, base = 8;
c01093db:	ff 45 08             	incl   0x8(%ebp)
c01093de:	c7 45 10 08 00 00 00 	movl   $0x8,0x10(%ebp)
c01093e5:	eb 0d                	jmp    c01093f4 <strtol+0xa7>
    }
    else if (base == 0) {
c01093e7:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
c01093eb:	75 07                	jne    c01093f4 <strtol+0xa7>
        base = 10;
c01093ed:	c7 45 10 0a 00 00 00 	movl   $0xa,0x10(%ebp)

    // digits
    while (1) {
        int dig;

        if (*s >= '0' && *s <= '9') {
c01093f4:	8b 45 08             	mov    0x8(%ebp),%eax
c01093f7:	0f b6 00             	movzbl (%eax),%eax
c01093fa:	3c 2f                	cmp    $0x2f,%al
c01093fc:	7e 1b                	jle    c0109419 <strtol+0xcc>
c01093fe:	8b 45 08             	mov    0x8(%ebp),%eax
c0109401:	0f b6 00             	movzbl (%eax),%eax
c0109404:	3c 39                	cmp    $0x39,%al
c0109406:	7f 11                	jg     c0109419 <strtol+0xcc>
            dig = *s - '0';
c0109408:	8b 45 08             	mov    0x8(%ebp),%eax
c010940b:	0f b6 00             	movzbl (%eax),%eax
c010940e:	0f be c0             	movsbl %al,%eax
c0109411:	83 e8 30             	sub    $0x30,%eax
c0109414:	89 45 f4             	mov    %eax,-0xc(%ebp)
c0109417:	eb 48                	jmp    c0109461 <strtol+0x114>
        }
        else if (*s >= 'a' && *s <= 'z') {
c0109419:	8b 45 08             	mov    0x8(%ebp),%eax
c010941c:	0f b6 00             	movzbl (%eax),%eax
c010941f:	3c 60                	cmp    $0x60,%al
c0109421:	7e 1b                	jle    c010943e <strtol+0xf1>
c0109423:	8b 45 08             	mov    0x8(%ebp),%eax
c0109426:	0f b6 00             	movzbl (%eax),%eax
c0109429:	3c 7a                	cmp    $0x7a,%al
c010942b:	7f 11                	jg     c010943e <strtol+0xf1>
            dig = *s - 'a' + 10;
c010942d:	8b 45 08             	mov    0x8(%ebp),%eax
c0109430:	0f b6 00             	movzbl (%eax),%eax
c0109433:	0f be c0             	movsbl %al,%eax
c0109436:	83 e8 57             	sub    $0x57,%eax
c0109439:	89 45 f4             	mov    %eax,-0xc(%ebp)
c010943c:	eb 23                	jmp    c0109461 <strtol+0x114>
        }
        else if (*s >= 'A' && *s <= 'Z') {
c010943e:	8b 45 08             	mov    0x8(%ebp),%eax
c0109441:	0f b6 00             	movzbl (%eax),%eax
c0109444:	3c 40                	cmp    $0x40,%al
c0109446:	7e 3b                	jle    c0109483 <strtol+0x136>
c0109448:	8b 45 08             	mov    0x8(%ebp),%eax
c010944b:	0f b6 00             	movzbl (%eax),%eax
c010944e:	3c 5a                	cmp    $0x5a,%al
c0109450:	7f 31                	jg     c0109483 <strtol+0x136>
            dig = *s - 'A' + 10;
c0109452:	8b 45 08             	mov    0x8(%ebp),%eax
c0109455:	0f b6 00             	movzbl (%eax),%eax
c0109458:	0f be c0             	movsbl %al,%eax
c010945b:	83 e8 37             	sub    $0x37,%eax
c010945e:	89 45 f4             	mov    %eax,-0xc(%ebp)
        }
        else {
            break;
        }
        if (dig >= base) {
c0109461:	8b 45 f4             	mov    -0xc(%ebp),%eax
c0109464:	3b 45 10             	cmp    0x10(%ebp),%eax
c0109467:	7d 19                	jge    c0109482 <strtol+0x135>
            break;
        }
        s ++, val = (val * base) + dig;
c0109469:	ff 45 08             	incl   0x8(%ebp)
c010946c:	8b 45 f8             	mov    -0x8(%ebp),%eax
c010946f:	0f af 45 10          	imul   0x10(%ebp),%eax
c0109473:	89 c2                	mov    %eax,%edx
c0109475:	8b 45 f4             	mov    -0xc(%ebp),%eax
c0109478:	01 d0                	add    %edx,%eax
c010947a:	89 45 f8             	mov    %eax,-0x8(%ebp)
    while (1) {
c010947d:	e9 72 ff ff ff       	jmp    c01093f4 <strtol+0xa7>
            break;
c0109482:	90                   	nop
        // we don't properly detect overflow!
    }

    if (endptr) {
c0109483:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
c0109487:	74 08                	je     c0109491 <strtol+0x144>
        *endptr = (char *) s;
c0109489:	8b 45 0c             	mov    0xc(%ebp),%eax
c010948c:	8b 55 08             	mov    0x8(%ebp),%edx
c010948f:	89 10                	mov    %edx,(%eax)
    }
    return (neg ? -val : val);
c0109491:	83 7d fc 00          	cmpl   $0x0,-0x4(%ebp)
c0109495:	74 07                	je     c010949e <strtol+0x151>
c0109497:	8b 45 f8             	mov    -0x8(%ebp),%eax
c010949a:	f7 d8                	neg    %eax
c010949c:	eb 03                	jmp    c01094a1 <strtol+0x154>
c010949e:	8b 45 f8             	mov    -0x8(%ebp),%eax
}
c01094a1:	c9                   	leave  
c01094a2:	c3                   	ret    

c01094a3 <memset>:
 * @n:      number of bytes to be set to the value
 *
 * The memset() function returns @s.
 * */
void *
memset(void *s, char c, size_t n) {
c01094a3:	55                   	push   %ebp
c01094a4:	89 e5                	mov    %esp,%ebp
c01094a6:	57                   	push   %edi
c01094a7:	83 ec 24             	sub    $0x24,%esp
c01094aa:	8b 45 0c             	mov    0xc(%ebp),%eax
c01094ad:	88 45 d8             	mov    %al,-0x28(%ebp)
#ifdef __HAVE_ARCH_MEMSET
    return __memset(s, c, n);
c01094b0:	0f be 45 d8          	movsbl -0x28(%ebp),%eax
c01094b4:	8b 55 08             	mov    0x8(%ebp),%edx
c01094b7:	89 55 f8             	mov    %edx,-0x8(%ebp)
c01094ba:	88 45 f7             	mov    %al,-0x9(%ebp)
c01094bd:	8b 45 10             	mov    0x10(%ebp),%eax
c01094c0:	89 45 f0             	mov    %eax,-0x10(%ebp)
#ifndef __HAVE_ARCH_MEMSET
#define __HAVE_ARCH_MEMSET
static inline void *
__memset(void *s, char c, size_t n) {
    int d0, d1;
    asm volatile (
c01094c3:	8b 4d f0             	mov    -0x10(%ebp),%ecx
c01094c6:	0f b6 45 f7          	movzbl -0x9(%ebp),%eax
c01094ca:	8b 55 f8             	mov    -0x8(%ebp),%edx
c01094cd:	89 d7                	mov    %edx,%edi
c01094cf:	f3 aa                	rep stos %al,%es:(%edi)
c01094d1:	89 fa                	mov    %edi,%edx
c01094d3:	89 4d ec             	mov    %ecx,-0x14(%ebp)
c01094d6:	89 55 e8             	mov    %edx,-0x18(%ebp)
        "rep; stosb;"
        : "=&c" (d0), "=&D" (d1)
        : "0" (n), "a" (c), "1" (s)
        : "memory");
    return s;
c01094d9:	8b 45 f8             	mov    -0x8(%ebp),%eax
c01094dc:	90                   	nop
    while (n -- > 0) {
        *p ++ = c;
    }
    return s;
#endif /* __HAVE_ARCH_MEMSET */
}
c01094dd:	83 c4 24             	add    $0x24,%esp
c01094e0:	5f                   	pop    %edi
c01094e1:	5d                   	pop    %ebp
c01094e2:	c3                   	ret    

c01094e3 <memmove>:
 * @n:      number of bytes to copy
 *
 * The memmove() function returns @dst.
 * */
void *
memmove(void *dst, const void *src, size_t n) {
c01094e3:	55                   	push   %ebp
c01094e4:	89 e5                	mov    %esp,%ebp
c01094e6:	57                   	push   %edi
c01094e7:	56                   	push   %esi
c01094e8:	53                   	push   %ebx
c01094e9:	83 ec 30             	sub    $0x30,%esp
c01094ec:	8b 45 08             	mov    0x8(%ebp),%eax
c01094ef:	89 45 f0             	mov    %eax,-0x10(%ebp)
c01094f2:	8b 45 0c             	mov    0xc(%ebp),%eax
c01094f5:	89 45 ec             	mov    %eax,-0x14(%ebp)
c01094f8:	8b 45 10             	mov    0x10(%ebp),%eax
c01094fb:	89 45 e8             	mov    %eax,-0x18(%ebp)

#ifndef __HAVE_ARCH_MEMMOVE
#define __HAVE_ARCH_MEMMOVE
static inline void *
__memmove(void *dst, const void *src, size_t n) {
    if (dst < src) {
c01094fe:	8b 45 f0             	mov    -0x10(%ebp),%eax
c0109501:	3b 45 ec             	cmp    -0x14(%ebp),%eax
c0109504:	73 42                	jae    c0109548 <memmove+0x65>
c0109506:	8b 45 f0             	mov    -0x10(%ebp),%eax
c0109509:	89 45 e4             	mov    %eax,-0x1c(%ebp)
c010950c:	8b 45 ec             	mov    -0x14(%ebp),%eax
c010950f:	89 45 e0             	mov    %eax,-0x20(%ebp)
c0109512:	8b 45 e8             	mov    -0x18(%ebp),%eax
c0109515:	89 45 dc             	mov    %eax,-0x24(%ebp)
        "andl $3, %%ecx;"
        "jz 1f;"
        "rep; movsb;"
        "1:"
        : "=&c" (d0), "=&D" (d1), "=&S" (d2)
        : "0" (n / 4), "g" (n), "1" (dst), "2" (src)
c0109518:	8b 45 dc             	mov    -0x24(%ebp),%eax
c010951b:	c1 e8 02             	shr    $0x2,%eax
c010951e:	89 c1                	mov    %eax,%ecx
    asm volatile (
c0109520:	8b 55 e4             	mov    -0x1c(%ebp),%edx
c0109523:	8b 45 e0             	mov    -0x20(%ebp),%eax
c0109526:	89 d7                	mov    %edx,%edi
c0109528:	89 c6                	mov    %eax,%esi
c010952a:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
c010952c:	8b 4d dc             	mov    -0x24(%ebp),%ecx
c010952f:	83 e1 03             	and    $0x3,%ecx
c0109532:	74 02                	je     c0109536 <memmove+0x53>
c0109534:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
c0109536:	89 f0                	mov    %esi,%eax
c0109538:	89 fa                	mov    %edi,%edx
c010953a:	89 4d d8             	mov    %ecx,-0x28(%ebp)
c010953d:	89 55 d4             	mov    %edx,-0x2c(%ebp)
c0109540:	89 45 d0             	mov    %eax,-0x30(%ebp)
        : "memory");
    return dst;
c0109543:	8b 45 e4             	mov    -0x1c(%ebp),%eax
#ifdef __HAVE_ARCH_MEMMOVE
    return __memmove(dst, src, n);
c0109546:	eb 36                	jmp    c010957e <memmove+0x9b>
        : "0" (n), "1" (n - 1 + src), "2" (n - 1 + dst)
c0109548:	8b 45 e8             	mov    -0x18(%ebp),%eax
c010954b:	8d 50 ff             	lea    -0x1(%eax),%edx
c010954e:	8b 45 ec             	mov    -0x14(%ebp),%eax
c0109551:	01 c2                	add    %eax,%edx
c0109553:	8b 45 e8             	mov    -0x18(%ebp),%eax
c0109556:	8d 48 ff             	lea    -0x1(%eax),%ecx
c0109559:	8b 45 f0             	mov    -0x10(%ebp),%eax
c010955c:	8d 1c 01             	lea    (%ecx,%eax,1),%ebx
    asm volatile (
c010955f:	8b 45 e8             	mov    -0x18(%ebp),%eax
c0109562:	89 c1                	mov    %eax,%ecx
c0109564:	89 d8                	mov    %ebx,%eax
c0109566:	89 d6                	mov    %edx,%esi
c0109568:	89 c7                	mov    %eax,%edi
c010956a:	fd                   	std    
c010956b:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
c010956d:	fc                   	cld    
c010956e:	89 f8                	mov    %edi,%eax
c0109570:	89 f2                	mov    %esi,%edx
c0109572:	89 4d cc             	mov    %ecx,-0x34(%ebp)
c0109575:	89 55 c8             	mov    %edx,-0x38(%ebp)
c0109578:	89 45 c4             	mov    %eax,-0x3c(%ebp)
    return dst;
c010957b:	8b 45 f0             	mov    -0x10(%ebp),%eax
            *d ++ = *s ++;
        }
    }
    return dst;
#endif /* __HAVE_ARCH_MEMMOVE */
}
c010957e:	83 c4 30             	add    $0x30,%esp
c0109581:	5b                   	pop    %ebx
c0109582:	5e                   	pop    %esi
c0109583:	5f                   	pop    %edi
c0109584:	5d                   	pop    %ebp
c0109585:	c3                   	ret    

c0109586 <memcpy>:
 * it always copies exactly @n bytes. To avoid overflows, the size of arrays pointed
 * by both @src and @dst, should be at least @n bytes, and should not overlap
 * (for overlapping memory area, memmove is a safer approach).
 * */
void *
memcpy(void *dst, const void *src, size_t n) {
c0109586:	55                   	push   %ebp
c0109587:	89 e5                	mov    %esp,%ebp
c0109589:	57                   	push   %edi
c010958a:	56                   	push   %esi
c010958b:	83 ec 20             	sub    $0x20,%esp
c010958e:	8b 45 08             	mov    0x8(%ebp),%eax
c0109591:	89 45 f4             	mov    %eax,-0xc(%ebp)
c0109594:	8b 45 0c             	mov    0xc(%ebp),%eax
c0109597:	89 45 f0             	mov    %eax,-0x10(%ebp)
c010959a:	8b 45 10             	mov    0x10(%ebp),%eax
c010959d:	89 45 ec             	mov    %eax,-0x14(%ebp)
        : "0" (n / 4), "g" (n), "1" (dst), "2" (src)
c01095a0:	8b 45 ec             	mov    -0x14(%ebp),%eax
c01095a3:	c1 e8 02             	shr    $0x2,%eax
c01095a6:	89 c1                	mov    %eax,%ecx
    asm volatile (
c01095a8:	8b 55 f4             	mov    -0xc(%ebp),%edx
c01095ab:	8b 45 f0             	mov    -0x10(%ebp),%eax
c01095ae:	89 d7                	mov    %edx,%edi
c01095b0:	89 c6                	mov    %eax,%esi
c01095b2:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
c01095b4:	8b 4d ec             	mov    -0x14(%ebp),%ecx
c01095b7:	83 e1 03             	and    $0x3,%ecx
c01095ba:	74 02                	je     c01095be <memcpy+0x38>
c01095bc:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
c01095be:	89 f0                	mov    %esi,%eax
c01095c0:	89 fa                	mov    %edi,%edx
c01095c2:	89 4d e8             	mov    %ecx,-0x18(%ebp)
c01095c5:	89 55 e4             	mov    %edx,-0x1c(%ebp)
c01095c8:	89 45 e0             	mov    %eax,-0x20(%ebp)
    return dst;
c01095cb:	8b 45 f4             	mov    -0xc(%ebp),%eax
#ifdef __HAVE_ARCH_MEMCPY
    return __memcpy(dst, src, n);
c01095ce:	90                   	nop
    while (n -- > 0) {
        *d ++ = *s ++;
    }
    return dst;
#endif /* __HAVE_ARCH_MEMCPY */
}
c01095cf:	83 c4 20             	add    $0x20,%esp
c01095d2:	5e                   	pop    %esi
c01095d3:	5f                   	pop    %edi
c01095d4:	5d                   	pop    %ebp
c01095d5:	c3                   	ret    

c01095d6 <memcmp>:
 *   match in both memory blocks has a greater value in @v1 than in @v2
 *   as if evaluated as unsigned char values;
 * - And a value less than zero indicates the opposite.
 * */
int
memcmp(const void *v1, const void *v2, size_t n) {
c01095d6:	55                   	push   %ebp
c01095d7:	89 e5                	mov    %esp,%ebp
c01095d9:	83 ec 10             	sub    $0x10,%esp
    const char *s1 = (const char *)v1;
c01095dc:	8b 45 08             	mov    0x8(%ebp),%eax
c01095df:	89 45 fc             	mov    %eax,-0x4(%ebp)
    const char *s2 = (const char *)v2;
c01095e2:	8b 45 0c             	mov    0xc(%ebp),%eax
c01095e5:	89 45 f8             	mov    %eax,-0x8(%ebp)
    while (n -- > 0) {
c01095e8:	eb 2e                	jmp    c0109618 <memcmp+0x42>
        if (*s1 != *s2) {
c01095ea:	8b 45 fc             	mov    -0x4(%ebp),%eax
c01095ed:	0f b6 10             	movzbl (%eax),%edx
c01095f0:	8b 45 f8             	mov    -0x8(%ebp),%eax
c01095f3:	0f b6 00             	movzbl (%eax),%eax
c01095f6:	38 c2                	cmp    %al,%dl
c01095f8:	74 18                	je     c0109612 <memcmp+0x3c>
            return (int)((unsigned char)*s1 - (unsigned char)*s2);
c01095fa:	8b 45 fc             	mov    -0x4(%ebp),%eax
c01095fd:	0f b6 00             	movzbl (%eax),%eax
c0109600:	0f b6 d0             	movzbl %al,%edx
c0109603:	8b 45 f8             	mov    -0x8(%ebp),%eax
c0109606:	0f b6 00             	movzbl (%eax),%eax
c0109609:	0f b6 c0             	movzbl %al,%eax
c010960c:	29 c2                	sub    %eax,%edx
c010960e:	89 d0                	mov    %edx,%eax
c0109610:	eb 18                	jmp    c010962a <memcmp+0x54>
        }
        s1 ++, s2 ++;
c0109612:	ff 45 fc             	incl   -0x4(%ebp)
c0109615:	ff 45 f8             	incl   -0x8(%ebp)
    while (n -- > 0) {
c0109618:	8b 45 10             	mov    0x10(%ebp),%eax
c010961b:	8d 50 ff             	lea    -0x1(%eax),%edx
c010961e:	89 55 10             	mov    %edx,0x10(%ebp)
c0109621:	85 c0                	test   %eax,%eax
c0109623:	75 c5                	jne    c01095ea <memcmp+0x14>
    }
    return 0;
c0109625:	b8 00 00 00 00       	mov    $0x0,%eax
}
c010962a:	c9                   	leave  
c010962b:	c3                   	ret    

c010962c <printnum>:
 * @width:      maximum number of digits, if the actual width is less than @width, use @padc instead
 * @padc:       character that padded on the left if the actual width is less than @width
 * */
static void
printnum(void (*putch)(int, void*), void *putdat,
        unsigned long long num, unsigned base, int width, int padc) {
c010962c:	55                   	push   %ebp
c010962d:	89 e5                	mov    %esp,%ebp
c010962f:	83 ec 58             	sub    $0x58,%esp
c0109632:	8b 45 10             	mov    0x10(%ebp),%eax
c0109635:	89 45 d0             	mov    %eax,-0x30(%ebp)
c0109638:	8b 45 14             	mov    0x14(%ebp),%eax
c010963b:	89 45 d4             	mov    %eax,-0x2c(%ebp)
    unsigned long long result = num;
c010963e:	8b 45 d0             	mov    -0x30(%ebp),%eax
c0109641:	8b 55 d4             	mov    -0x2c(%ebp),%edx
c0109644:	89 45 e8             	mov    %eax,-0x18(%ebp)
c0109647:	89 55 ec             	mov    %edx,-0x14(%ebp)
    unsigned mod = do_div(result, base);
c010964a:	8b 45 18             	mov    0x18(%ebp),%eax
c010964d:	89 45 e4             	mov    %eax,-0x1c(%ebp)
c0109650:	8b 45 e8             	mov    -0x18(%ebp),%eax
c0109653:	8b 55 ec             	mov    -0x14(%ebp),%edx
c0109656:	89 45 e0             	mov    %eax,-0x20(%ebp)
c0109659:	89 55 f0             	mov    %edx,-0x10(%ebp)
c010965c:	8b 45 f0             	mov    -0x10(%ebp),%eax
c010965f:	89 45 f4             	mov    %eax,-0xc(%ebp)
c0109662:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
c0109666:	74 1c                	je     c0109684 <printnum+0x58>
c0109668:	8b 45 f0             	mov    -0x10(%ebp),%eax
c010966b:	ba 00 00 00 00       	mov    $0x0,%edx
c0109670:	f7 75 e4             	divl   -0x1c(%ebp)
c0109673:	89 55 f4             	mov    %edx,-0xc(%ebp)
c0109676:	8b 45 f0             	mov    -0x10(%ebp),%eax
c0109679:	ba 00 00 00 00       	mov    $0x0,%edx
c010967e:	f7 75 e4             	divl   -0x1c(%ebp)
c0109681:	89 45 f0             	mov    %eax,-0x10(%ebp)
c0109684:	8b 45 e0             	mov    -0x20(%ebp),%eax
c0109687:	8b 55 f4             	mov    -0xc(%ebp),%edx
c010968a:	f7 75 e4             	divl   -0x1c(%ebp)
c010968d:	89 45 e0             	mov    %eax,-0x20(%ebp)
c0109690:	89 55 dc             	mov    %edx,-0x24(%ebp)
c0109693:	8b 45 e0             	mov    -0x20(%ebp),%eax
c0109696:	8b 55 f0             	mov    -0x10(%ebp),%edx
c0109699:	89 45 e8             	mov    %eax,-0x18(%ebp)
c010969c:	89 55 ec             	mov    %edx,-0x14(%ebp)
c010969f:	8b 45 dc             	mov    -0x24(%ebp),%eax
c01096a2:	89 45 d8             	mov    %eax,-0x28(%ebp)

    // first recursively print all preceding (more significant) digits
    if (num >= base) {
c01096a5:	8b 45 18             	mov    0x18(%ebp),%eax
c01096a8:	ba 00 00 00 00       	mov    $0x0,%edx
c01096ad:	39 55 d4             	cmp    %edx,-0x2c(%ebp)
c01096b0:	72 56                	jb     c0109708 <printnum+0xdc>
c01096b2:	39 55 d4             	cmp    %edx,-0x2c(%ebp)
c01096b5:	77 05                	ja     c01096bc <printnum+0x90>
c01096b7:	39 45 d0             	cmp    %eax,-0x30(%ebp)
c01096ba:	72 4c                	jb     c0109708 <printnum+0xdc>
        printnum(putch, putdat, result, base, width - 1, padc);
c01096bc:	8b 45 1c             	mov    0x1c(%ebp),%eax
c01096bf:	8d 50 ff             	lea    -0x1(%eax),%edx
c01096c2:	8b 45 20             	mov    0x20(%ebp),%eax
c01096c5:	89 44 24 18          	mov    %eax,0x18(%esp)
c01096c9:	89 54 24 14          	mov    %edx,0x14(%esp)
c01096cd:	8b 45 18             	mov    0x18(%ebp),%eax
c01096d0:	89 44 24 10          	mov    %eax,0x10(%esp)
c01096d4:	8b 45 e8             	mov    -0x18(%ebp),%eax
c01096d7:	8b 55 ec             	mov    -0x14(%ebp),%edx
c01096da:	89 44 24 08          	mov    %eax,0x8(%esp)
c01096de:	89 54 24 0c          	mov    %edx,0xc(%esp)
c01096e2:	8b 45 0c             	mov    0xc(%ebp),%eax
c01096e5:	89 44 24 04          	mov    %eax,0x4(%esp)
c01096e9:	8b 45 08             	mov    0x8(%ebp),%eax
c01096ec:	89 04 24             	mov    %eax,(%esp)
c01096ef:	e8 38 ff ff ff       	call   c010962c <printnum>
c01096f4:	eb 1b                	jmp    c0109711 <printnum+0xe5>
    } else {
        // print any needed pad characters before first digit
        while (-- width > 0)
            putch(padc, putdat);
c01096f6:	8b 45 0c             	mov    0xc(%ebp),%eax
c01096f9:	89 44 24 04          	mov    %eax,0x4(%esp)
c01096fd:	8b 45 20             	mov    0x20(%ebp),%eax
c0109700:	89 04 24             	mov    %eax,(%esp)
c0109703:	8b 45 08             	mov    0x8(%ebp),%eax
c0109706:	ff d0                	call   *%eax
        while (-- width > 0)
c0109708:	ff 4d 1c             	decl   0x1c(%ebp)
c010970b:	83 7d 1c 00          	cmpl   $0x0,0x1c(%ebp)
c010970f:	7f e5                	jg     c01096f6 <printnum+0xca>
    }
    // then print this (the least significant) digit
    putch("0123456789abcdef"[mod], putdat);
c0109711:	8b 45 d8             	mov    -0x28(%ebp),%eax
c0109714:	05 fc be 10 c0       	add    $0xc010befc,%eax
c0109719:	0f b6 00             	movzbl (%eax),%eax
c010971c:	0f be c0             	movsbl %al,%eax
c010971f:	8b 55 0c             	mov    0xc(%ebp),%edx
c0109722:	89 54 24 04          	mov    %edx,0x4(%esp)
c0109726:	89 04 24             	mov    %eax,(%esp)
c0109729:	8b 45 08             	mov    0x8(%ebp),%eax
c010972c:	ff d0                	call   *%eax
}
c010972e:	90                   	nop
c010972f:	c9                   	leave  
c0109730:	c3                   	ret    

c0109731 <getuint>:
 * getuint - get an unsigned int of various possible sizes from a varargs list
 * @ap:         a varargs list pointer
 * @lflag:      determines the size of the vararg that @ap points to
 * */
static unsigned long long
getuint(va_list *ap, int lflag) {
c0109731:	55                   	push   %ebp
c0109732:	89 e5                	mov    %esp,%ebp
    if (lflag >= 2) {
c0109734:	83 7d 0c 01          	cmpl   $0x1,0xc(%ebp)
c0109738:	7e 14                	jle    c010974e <getuint+0x1d>
        return va_arg(*ap, unsigned long long);
c010973a:	8b 45 08             	mov    0x8(%ebp),%eax
c010973d:	8b 00                	mov    (%eax),%eax
c010973f:	8d 48 08             	lea    0x8(%eax),%ecx
c0109742:	8b 55 08             	mov    0x8(%ebp),%edx
c0109745:	89 0a                	mov    %ecx,(%edx)
c0109747:	8b 50 04             	mov    0x4(%eax),%edx
c010974a:	8b 00                	mov    (%eax),%eax
c010974c:	eb 30                	jmp    c010977e <getuint+0x4d>
    }
    else if (lflag) {
c010974e:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
c0109752:	74 16                	je     c010976a <getuint+0x39>
        return va_arg(*ap, unsigned long);
c0109754:	8b 45 08             	mov    0x8(%ebp),%eax
c0109757:	8b 00                	mov    (%eax),%eax
c0109759:	8d 48 04             	lea    0x4(%eax),%ecx
c010975c:	8b 55 08             	mov    0x8(%ebp),%edx
c010975f:	89 0a                	mov    %ecx,(%edx)
c0109761:	8b 00                	mov    (%eax),%eax
c0109763:	ba 00 00 00 00       	mov    $0x0,%edx
c0109768:	eb 14                	jmp    c010977e <getuint+0x4d>
    }
    else {
        return va_arg(*ap, unsigned int);
c010976a:	8b 45 08             	mov    0x8(%ebp),%eax
c010976d:	8b 00                	mov    (%eax),%eax
c010976f:	8d 48 04             	lea    0x4(%eax),%ecx
c0109772:	8b 55 08             	mov    0x8(%ebp),%edx
c0109775:	89 0a                	mov    %ecx,(%edx)
c0109777:	8b 00                	mov    (%eax),%eax
c0109779:	ba 00 00 00 00       	mov    $0x0,%edx
    }
}
c010977e:	5d                   	pop    %ebp
c010977f:	c3                   	ret    

c0109780 <getint>:
 * getint - same as getuint but signed, we can't use getuint because of sign extension
 * @ap:         a varargs list pointer
 * @lflag:      determines the size of the vararg that @ap points to
 * */
static long long
getint(va_list *ap, int lflag) {
c0109780:	55                   	push   %ebp
c0109781:	89 e5                	mov    %esp,%ebp
    if (lflag >= 2) {
c0109783:	83 7d 0c 01          	cmpl   $0x1,0xc(%ebp)
c0109787:	7e 14                	jle    c010979d <getint+0x1d>
        return va_arg(*ap, long long);
c0109789:	8b 45 08             	mov    0x8(%ebp),%eax
c010978c:	8b 00                	mov    (%eax),%eax
c010978e:	8d 48 08             	lea    0x8(%eax),%ecx
c0109791:	8b 55 08             	mov    0x8(%ebp),%edx
c0109794:	89 0a                	mov    %ecx,(%edx)
c0109796:	8b 50 04             	mov    0x4(%eax),%edx
c0109799:	8b 00                	mov    (%eax),%eax
c010979b:	eb 28                	jmp    c01097c5 <getint+0x45>
    }
    else if (lflag) {
c010979d:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
c01097a1:	74 12                	je     c01097b5 <getint+0x35>
        return va_arg(*ap, long);
c01097a3:	8b 45 08             	mov    0x8(%ebp),%eax
c01097a6:	8b 00                	mov    (%eax),%eax
c01097a8:	8d 48 04             	lea    0x4(%eax),%ecx
c01097ab:	8b 55 08             	mov    0x8(%ebp),%edx
c01097ae:	89 0a                	mov    %ecx,(%edx)
c01097b0:	8b 00                	mov    (%eax),%eax
c01097b2:	99                   	cltd   
c01097b3:	eb 10                	jmp    c01097c5 <getint+0x45>
    }
    else {
        return va_arg(*ap, int);
c01097b5:	8b 45 08             	mov    0x8(%ebp),%eax
c01097b8:	8b 00                	mov    (%eax),%eax
c01097ba:	8d 48 04             	lea    0x4(%eax),%ecx
c01097bd:	8b 55 08             	mov    0x8(%ebp),%edx
c01097c0:	89 0a                	mov    %ecx,(%edx)
c01097c2:	8b 00                	mov    (%eax),%eax
c01097c4:	99                   	cltd   
    }
}
c01097c5:	5d                   	pop    %ebp
c01097c6:	c3                   	ret    

c01097c7 <printfmt>:
 * @putch:      specified putch function, print a single character
 * @putdat:     used by @putch function
 * @fmt:        the format string to use
 * */
void
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...) {
c01097c7:	55                   	push   %ebp
c01097c8:	89 e5                	mov    %esp,%ebp
c01097ca:	83 ec 28             	sub    $0x28,%esp
    va_list ap;

    va_start(ap, fmt);
c01097cd:	8d 45 14             	lea    0x14(%ebp),%eax
c01097d0:	89 45 f4             	mov    %eax,-0xc(%ebp)
    vprintfmt(putch, putdat, fmt, ap);
c01097d3:	8b 45 f4             	mov    -0xc(%ebp),%eax
c01097d6:	89 44 24 0c          	mov    %eax,0xc(%esp)
c01097da:	8b 45 10             	mov    0x10(%ebp),%eax
c01097dd:	89 44 24 08          	mov    %eax,0x8(%esp)
c01097e1:	8b 45 0c             	mov    0xc(%ebp),%eax
c01097e4:	89 44 24 04          	mov    %eax,0x4(%esp)
c01097e8:	8b 45 08             	mov    0x8(%ebp),%eax
c01097eb:	89 04 24             	mov    %eax,(%esp)
c01097ee:	e8 03 00 00 00       	call   c01097f6 <vprintfmt>
    va_end(ap);
}
c01097f3:	90                   	nop
c01097f4:	c9                   	leave  
c01097f5:	c3                   	ret    

c01097f6 <vprintfmt>:
 *
 * Call this function if you are already dealing with a va_list.
 * Or you probably want printfmt() instead.
 * */
void
vprintfmt(void (*putch)(int, void*), void *putdat, const char *fmt, va_list ap) {
c01097f6:	55                   	push   %ebp
c01097f7:	89 e5                	mov    %esp,%ebp
c01097f9:	56                   	push   %esi
c01097fa:	53                   	push   %ebx
c01097fb:	83 ec 40             	sub    $0x40,%esp
    register int ch, err;
    unsigned long long num;
    int base, width, precision, lflag, altflag;

    while (1) {
        while ((ch = *(unsigned char *)fmt ++) != '%') {
c01097fe:	eb 17                	jmp    c0109817 <vprintfmt+0x21>
            if (ch == '\0') {
c0109800:	85 db                	test   %ebx,%ebx
c0109802:	0f 84 bf 03 00 00    	je     c0109bc7 <vprintfmt+0x3d1>
                return;
            }
            putch(ch, putdat);
c0109808:	8b 45 0c             	mov    0xc(%ebp),%eax
c010980b:	89 44 24 04          	mov    %eax,0x4(%esp)
c010980f:	89 1c 24             	mov    %ebx,(%esp)
c0109812:	8b 45 08             	mov    0x8(%ebp),%eax
c0109815:	ff d0                	call   *%eax
        while ((ch = *(unsigned char *)fmt ++) != '%') {
c0109817:	8b 45 10             	mov    0x10(%ebp),%eax
c010981a:	8d 50 01             	lea    0x1(%eax),%edx
c010981d:	89 55 10             	mov    %edx,0x10(%ebp)
c0109820:	0f b6 00             	movzbl (%eax),%eax
c0109823:	0f b6 d8             	movzbl %al,%ebx
c0109826:	83 fb 25             	cmp    $0x25,%ebx
c0109829:	75 d5                	jne    c0109800 <vprintfmt+0xa>
        }

        // Process a %-escape sequence
        char padc = ' ';
c010982b:	c6 45 db 20          	movb   $0x20,-0x25(%ebp)
        width = precision = -1;
c010982f:	c7 45 e4 ff ff ff ff 	movl   $0xffffffff,-0x1c(%ebp)
c0109836:	8b 45 e4             	mov    -0x1c(%ebp),%eax
c0109839:	89 45 e8             	mov    %eax,-0x18(%ebp)
        lflag = altflag = 0;
c010983c:	c7 45 dc 00 00 00 00 	movl   $0x0,-0x24(%ebp)
c0109843:	8b 45 dc             	mov    -0x24(%ebp),%eax
c0109846:	89 45 e0             	mov    %eax,-0x20(%ebp)

    reswitch:
        switch (ch = *(unsigned char *)fmt ++) {
c0109849:	8b 45 10             	mov    0x10(%ebp),%eax
c010984c:	8d 50 01             	lea    0x1(%eax),%edx
c010984f:	89 55 10             	mov    %edx,0x10(%ebp)
c0109852:	0f b6 00             	movzbl (%eax),%eax
c0109855:	0f b6 d8             	movzbl %al,%ebx
c0109858:	8d 43 dd             	lea    -0x23(%ebx),%eax
c010985b:	83 f8 55             	cmp    $0x55,%eax
c010985e:	0f 87 37 03 00 00    	ja     c0109b9b <vprintfmt+0x3a5>
c0109864:	8b 04 85 20 bf 10 c0 	mov    -0x3fef40e0(,%eax,4),%eax
c010986b:	ff e0                	jmp    *%eax

        // flag to pad on the right
        case '-':
            padc = '-';
c010986d:	c6 45 db 2d          	movb   $0x2d,-0x25(%ebp)
            goto reswitch;
c0109871:	eb d6                	jmp    c0109849 <vprintfmt+0x53>

        // flag to pad with 0's instead of spaces
        case '0':
            padc = '0';
c0109873:	c6 45 db 30          	movb   $0x30,-0x25(%ebp)
            goto reswitch;
c0109877:	eb d0                	jmp    c0109849 <vprintfmt+0x53>

        // width field
        case '1' ... '9':
            for (precision = 0; ; ++ fmt) {
c0109879:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
                precision = precision * 10 + ch - '0';
c0109880:	8b 55 e4             	mov    -0x1c(%ebp),%edx
c0109883:	89 d0                	mov    %edx,%eax
c0109885:	c1 e0 02             	shl    $0x2,%eax
c0109888:	01 d0                	add    %edx,%eax
c010988a:	01 c0                	add    %eax,%eax
c010988c:	01 d8                	add    %ebx,%eax
c010988e:	83 e8 30             	sub    $0x30,%eax
c0109891:	89 45 e4             	mov    %eax,-0x1c(%ebp)
                ch = *fmt;
c0109894:	8b 45 10             	mov    0x10(%ebp),%eax
c0109897:	0f b6 00             	movzbl (%eax),%eax
c010989a:	0f be d8             	movsbl %al,%ebx
                if (ch < '0' || ch > '9') {
c010989d:	83 fb 2f             	cmp    $0x2f,%ebx
c01098a0:	7e 38                	jle    c01098da <vprintfmt+0xe4>
c01098a2:	83 fb 39             	cmp    $0x39,%ebx
c01098a5:	7f 33                	jg     c01098da <vprintfmt+0xe4>
            for (precision = 0; ; ++ fmt) {
c01098a7:	ff 45 10             	incl   0x10(%ebp)
                precision = precision * 10 + ch - '0';
c01098aa:	eb d4                	jmp    c0109880 <vprintfmt+0x8a>
                }
            }
            goto process_precision;

        case '*':
            precision = va_arg(ap, int);
c01098ac:	8b 45 14             	mov    0x14(%ebp),%eax
c01098af:	8d 50 04             	lea    0x4(%eax),%edx
c01098b2:	89 55 14             	mov    %edx,0x14(%ebp)
c01098b5:	8b 00                	mov    (%eax),%eax
c01098b7:	89 45 e4             	mov    %eax,-0x1c(%ebp)
            goto process_precision;
c01098ba:	eb 1f                	jmp    c01098db <vprintfmt+0xe5>

        case '.':
            if (width < 0)
c01098bc:	83 7d e8 00          	cmpl   $0x0,-0x18(%ebp)
c01098c0:	79 87                	jns    c0109849 <vprintfmt+0x53>
                width = 0;
c01098c2:	c7 45 e8 00 00 00 00 	movl   $0x0,-0x18(%ebp)
            goto reswitch;
c01098c9:	e9 7b ff ff ff       	jmp    c0109849 <vprintfmt+0x53>

        case '#':
            altflag = 1;
c01098ce:	c7 45 dc 01 00 00 00 	movl   $0x1,-0x24(%ebp)
            goto reswitch;
c01098d5:	e9 6f ff ff ff       	jmp    c0109849 <vprintfmt+0x53>
            goto process_precision;
c01098da:	90                   	nop

        process_precision:
            if (width < 0)
c01098db:	83 7d e8 00          	cmpl   $0x0,-0x18(%ebp)
c01098df:	0f 89 64 ff ff ff    	jns    c0109849 <vprintfmt+0x53>
                width = precision, precision = -1;
c01098e5:	8b 45 e4             	mov    -0x1c(%ebp),%eax
c01098e8:	89 45 e8             	mov    %eax,-0x18(%ebp)
c01098eb:	c7 45 e4 ff ff ff ff 	movl   $0xffffffff,-0x1c(%ebp)
            goto reswitch;
c01098f2:	e9 52 ff ff ff       	jmp    c0109849 <vprintfmt+0x53>

        // long flag (doubled for long long)
        case 'l':
            lflag ++;
c01098f7:	ff 45 e0             	incl   -0x20(%ebp)
            goto reswitch;
c01098fa:	e9 4a ff ff ff       	jmp    c0109849 <vprintfmt+0x53>

        // character
        case 'c':
            putch(va_arg(ap, int), putdat);
c01098ff:	8b 45 14             	mov    0x14(%ebp),%eax
c0109902:	8d 50 04             	lea    0x4(%eax),%edx
c0109905:	89 55 14             	mov    %edx,0x14(%ebp)
c0109908:	8b 00                	mov    (%eax),%eax
c010990a:	8b 55 0c             	mov    0xc(%ebp),%edx
c010990d:	89 54 24 04          	mov    %edx,0x4(%esp)
c0109911:	89 04 24             	mov    %eax,(%esp)
c0109914:	8b 45 08             	mov    0x8(%ebp),%eax
c0109917:	ff d0                	call   *%eax
            break;
c0109919:	e9 a4 02 00 00       	jmp    c0109bc2 <vprintfmt+0x3cc>

        // error message
        case 'e':
            err = va_arg(ap, int);
c010991e:	8b 45 14             	mov    0x14(%ebp),%eax
c0109921:	8d 50 04             	lea    0x4(%eax),%edx
c0109924:	89 55 14             	mov    %edx,0x14(%ebp)
c0109927:	8b 18                	mov    (%eax),%ebx
            if (err < 0) {
c0109929:	85 db                	test   %ebx,%ebx
c010992b:	79 02                	jns    c010992f <vprintfmt+0x139>
                err = -err;
c010992d:	f7 db                	neg    %ebx
            }
            if (err > MAXERROR || (p = error_string[err]) == NULL) {
c010992f:	83 fb 06             	cmp    $0x6,%ebx
c0109932:	7f 0b                	jg     c010993f <vprintfmt+0x149>
c0109934:	8b 34 9d e0 be 10 c0 	mov    -0x3fef4120(,%ebx,4),%esi
c010993b:	85 f6                	test   %esi,%esi
c010993d:	75 23                	jne    c0109962 <vprintfmt+0x16c>
                printfmt(putch, putdat, "error %d", err);
c010993f:	89 5c 24 0c          	mov    %ebx,0xc(%esp)
c0109943:	c7 44 24 08 0d bf 10 	movl   $0xc010bf0d,0x8(%esp)
c010994a:	c0 
c010994b:	8b 45 0c             	mov    0xc(%ebp),%eax
c010994e:	89 44 24 04          	mov    %eax,0x4(%esp)
c0109952:	8b 45 08             	mov    0x8(%ebp),%eax
c0109955:	89 04 24             	mov    %eax,(%esp)
c0109958:	e8 6a fe ff ff       	call   c01097c7 <printfmt>
            }
            else {
                printfmt(putch, putdat, "%s", p);
            }
            break;
c010995d:	e9 60 02 00 00       	jmp    c0109bc2 <vprintfmt+0x3cc>
                printfmt(putch, putdat, "%s", p);
c0109962:	89 74 24 0c          	mov    %esi,0xc(%esp)
c0109966:	c7 44 24 08 16 bf 10 	movl   $0xc010bf16,0x8(%esp)
c010996d:	c0 
c010996e:	8b 45 0c             	mov    0xc(%ebp),%eax
c0109971:	89 44 24 04          	mov    %eax,0x4(%esp)
c0109975:	8b 45 08             	mov    0x8(%ebp),%eax
c0109978:	89 04 24             	mov    %eax,(%esp)
c010997b:	e8 47 fe ff ff       	call   c01097c7 <printfmt>
            break;
c0109980:	e9 3d 02 00 00       	jmp    c0109bc2 <vprintfmt+0x3cc>

        // string
        case 's':
            if ((p = va_arg(ap, char *)) == NULL) {
c0109985:	8b 45 14             	mov    0x14(%ebp),%eax
c0109988:	8d 50 04             	lea    0x4(%eax),%edx
c010998b:	89 55 14             	mov    %edx,0x14(%ebp)
c010998e:	8b 30                	mov    (%eax),%esi
c0109990:	85 f6                	test   %esi,%esi
c0109992:	75 05                	jne    c0109999 <vprintfmt+0x1a3>
                p = "(null)";
c0109994:	be 19 bf 10 c0       	mov    $0xc010bf19,%esi
            }
            if (width > 0 && padc != '-') {
c0109999:	83 7d e8 00          	cmpl   $0x0,-0x18(%ebp)
c010999d:	7e 76                	jle    c0109a15 <vprintfmt+0x21f>
c010999f:	80 7d db 2d          	cmpb   $0x2d,-0x25(%ebp)
c01099a3:	74 70                	je     c0109a15 <vprintfmt+0x21f>
                for (width -= strnlen(p, precision); width > 0; width --) {
c01099a5:	8b 45 e4             	mov    -0x1c(%ebp),%eax
c01099a8:	89 44 24 04          	mov    %eax,0x4(%esp)
c01099ac:	89 34 24             	mov    %esi,(%esp)
c01099af:	e8 f6 f7 ff ff       	call   c01091aa <strnlen>
c01099b4:	8b 55 e8             	mov    -0x18(%ebp),%edx
c01099b7:	29 c2                	sub    %eax,%edx
c01099b9:	89 d0                	mov    %edx,%eax
c01099bb:	89 45 e8             	mov    %eax,-0x18(%ebp)
c01099be:	eb 16                	jmp    c01099d6 <vprintfmt+0x1e0>
                    putch(padc, putdat);
c01099c0:	0f be 45 db          	movsbl -0x25(%ebp),%eax
c01099c4:	8b 55 0c             	mov    0xc(%ebp),%edx
c01099c7:	89 54 24 04          	mov    %edx,0x4(%esp)
c01099cb:	89 04 24             	mov    %eax,(%esp)
c01099ce:	8b 45 08             	mov    0x8(%ebp),%eax
c01099d1:	ff d0                	call   *%eax
                for (width -= strnlen(p, precision); width > 0; width --) {
c01099d3:	ff 4d e8             	decl   -0x18(%ebp)
c01099d6:	83 7d e8 00          	cmpl   $0x0,-0x18(%ebp)
c01099da:	7f e4                	jg     c01099c0 <vprintfmt+0x1ca>
                }
            }
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
c01099dc:	eb 37                	jmp    c0109a15 <vprintfmt+0x21f>
                if (altflag && (ch < ' ' || ch > '~')) {
c01099de:	83 7d dc 00          	cmpl   $0x0,-0x24(%ebp)
c01099e2:	74 1f                	je     c0109a03 <vprintfmt+0x20d>
c01099e4:	83 fb 1f             	cmp    $0x1f,%ebx
c01099e7:	7e 05                	jle    c01099ee <vprintfmt+0x1f8>
c01099e9:	83 fb 7e             	cmp    $0x7e,%ebx
c01099ec:	7e 15                	jle    c0109a03 <vprintfmt+0x20d>
                    putch('?', putdat);
c01099ee:	8b 45 0c             	mov    0xc(%ebp),%eax
c01099f1:	89 44 24 04          	mov    %eax,0x4(%esp)
c01099f5:	c7 04 24 3f 00 00 00 	movl   $0x3f,(%esp)
c01099fc:	8b 45 08             	mov    0x8(%ebp),%eax
c01099ff:	ff d0                	call   *%eax
c0109a01:	eb 0f                	jmp    c0109a12 <vprintfmt+0x21c>
                }
                else {
                    putch(ch, putdat);
c0109a03:	8b 45 0c             	mov    0xc(%ebp),%eax
c0109a06:	89 44 24 04          	mov    %eax,0x4(%esp)
c0109a0a:	89 1c 24             	mov    %ebx,(%esp)
c0109a0d:	8b 45 08             	mov    0x8(%ebp),%eax
c0109a10:	ff d0                	call   *%eax
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
c0109a12:	ff 4d e8             	decl   -0x18(%ebp)
c0109a15:	89 f0                	mov    %esi,%eax
c0109a17:	8d 70 01             	lea    0x1(%eax),%esi
c0109a1a:	0f b6 00             	movzbl (%eax),%eax
c0109a1d:	0f be d8             	movsbl %al,%ebx
c0109a20:	85 db                	test   %ebx,%ebx
c0109a22:	74 27                	je     c0109a4b <vprintfmt+0x255>
c0109a24:	83 7d e4 00          	cmpl   $0x0,-0x1c(%ebp)
c0109a28:	78 b4                	js     c01099de <vprintfmt+0x1e8>
c0109a2a:	ff 4d e4             	decl   -0x1c(%ebp)
c0109a2d:	83 7d e4 00          	cmpl   $0x0,-0x1c(%ebp)
c0109a31:	79 ab                	jns    c01099de <vprintfmt+0x1e8>
                }
            }
            for (; width > 0; width --) {
c0109a33:	eb 16                	jmp    c0109a4b <vprintfmt+0x255>
                putch(' ', putdat);
c0109a35:	8b 45 0c             	mov    0xc(%ebp),%eax
c0109a38:	89 44 24 04          	mov    %eax,0x4(%esp)
c0109a3c:	c7 04 24 20 00 00 00 	movl   $0x20,(%esp)
c0109a43:	8b 45 08             	mov    0x8(%ebp),%eax
c0109a46:	ff d0                	call   *%eax
            for (; width > 0; width --) {
c0109a48:	ff 4d e8             	decl   -0x18(%ebp)
c0109a4b:	83 7d e8 00          	cmpl   $0x0,-0x18(%ebp)
c0109a4f:	7f e4                	jg     c0109a35 <vprintfmt+0x23f>
            }
            break;
c0109a51:	e9 6c 01 00 00       	jmp    c0109bc2 <vprintfmt+0x3cc>

        // (signed) decimal
        case 'd':
            num = getint(&ap, lflag);
c0109a56:	8b 45 e0             	mov    -0x20(%ebp),%eax
c0109a59:	89 44 24 04          	mov    %eax,0x4(%esp)
c0109a5d:	8d 45 14             	lea    0x14(%ebp),%eax
c0109a60:	89 04 24             	mov    %eax,(%esp)
c0109a63:	e8 18 fd ff ff       	call   c0109780 <getint>
c0109a68:	89 45 f0             	mov    %eax,-0x10(%ebp)
c0109a6b:	89 55 f4             	mov    %edx,-0xc(%ebp)
            if ((long long)num < 0) {
c0109a6e:	8b 45 f0             	mov    -0x10(%ebp),%eax
c0109a71:	8b 55 f4             	mov    -0xc(%ebp),%edx
c0109a74:	85 d2                	test   %edx,%edx
c0109a76:	79 26                	jns    c0109a9e <vprintfmt+0x2a8>
                putch('-', putdat);
c0109a78:	8b 45 0c             	mov    0xc(%ebp),%eax
c0109a7b:	89 44 24 04          	mov    %eax,0x4(%esp)
c0109a7f:	c7 04 24 2d 00 00 00 	movl   $0x2d,(%esp)
c0109a86:	8b 45 08             	mov    0x8(%ebp),%eax
c0109a89:	ff d0                	call   *%eax
                num = -(long long)num;
c0109a8b:	8b 45 f0             	mov    -0x10(%ebp),%eax
c0109a8e:	8b 55 f4             	mov    -0xc(%ebp),%edx
c0109a91:	f7 d8                	neg    %eax
c0109a93:	83 d2 00             	adc    $0x0,%edx
c0109a96:	f7 da                	neg    %edx
c0109a98:	89 45 f0             	mov    %eax,-0x10(%ebp)
c0109a9b:	89 55 f4             	mov    %edx,-0xc(%ebp)
            }
            base = 10;
c0109a9e:	c7 45 ec 0a 00 00 00 	movl   $0xa,-0x14(%ebp)
            goto number;
c0109aa5:	e9 a8 00 00 00       	jmp    c0109b52 <vprintfmt+0x35c>

        // unsigned decimal
        case 'u':
            num = getuint(&ap, lflag);
c0109aaa:	8b 45 e0             	mov    -0x20(%ebp),%eax
c0109aad:	89 44 24 04          	mov    %eax,0x4(%esp)
c0109ab1:	8d 45 14             	lea    0x14(%ebp),%eax
c0109ab4:	89 04 24             	mov    %eax,(%esp)
c0109ab7:	e8 75 fc ff ff       	call   c0109731 <getuint>
c0109abc:	89 45 f0             	mov    %eax,-0x10(%ebp)
c0109abf:	89 55 f4             	mov    %edx,-0xc(%ebp)
            base = 10;
c0109ac2:	c7 45 ec 0a 00 00 00 	movl   $0xa,-0x14(%ebp)
            goto number;
c0109ac9:	e9 84 00 00 00       	jmp    c0109b52 <vprintfmt+0x35c>

        // (unsigned) octal
        case 'o':
            num = getuint(&ap, lflag);
c0109ace:	8b 45 e0             	mov    -0x20(%ebp),%eax
c0109ad1:	89 44 24 04          	mov    %eax,0x4(%esp)
c0109ad5:	8d 45 14             	lea    0x14(%ebp),%eax
c0109ad8:	89 04 24             	mov    %eax,(%esp)
c0109adb:	e8 51 fc ff ff       	call   c0109731 <getuint>
c0109ae0:	89 45 f0             	mov    %eax,-0x10(%ebp)
c0109ae3:	89 55 f4             	mov    %edx,-0xc(%ebp)
            base = 8;
c0109ae6:	c7 45 ec 08 00 00 00 	movl   $0x8,-0x14(%ebp)
            goto number;
c0109aed:	eb 63                	jmp    c0109b52 <vprintfmt+0x35c>

        // pointer
        case 'p':
            putch('0', putdat);
c0109aef:	8b 45 0c             	mov    0xc(%ebp),%eax
c0109af2:	89 44 24 04          	mov    %eax,0x4(%esp)
c0109af6:	c7 04 24 30 00 00 00 	movl   $0x30,(%esp)
c0109afd:	8b 45 08             	mov    0x8(%ebp),%eax
c0109b00:	ff d0                	call   *%eax
            putch('x', putdat);
c0109b02:	8b 45 0c             	mov    0xc(%ebp),%eax
c0109b05:	89 44 24 04          	mov    %eax,0x4(%esp)
c0109b09:	c7 04 24 78 00 00 00 	movl   $0x78,(%esp)
c0109b10:	8b 45 08             	mov    0x8(%ebp),%eax
c0109b13:	ff d0                	call   *%eax
            num = (unsigned long long)(uintptr_t)va_arg(ap, void *);
c0109b15:	8b 45 14             	mov    0x14(%ebp),%eax
c0109b18:	8d 50 04             	lea    0x4(%eax),%edx
c0109b1b:	89 55 14             	mov    %edx,0x14(%ebp)
c0109b1e:	8b 00                	mov    (%eax),%eax
c0109b20:	89 45 f0             	mov    %eax,-0x10(%ebp)
c0109b23:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
            base = 16;
c0109b2a:	c7 45 ec 10 00 00 00 	movl   $0x10,-0x14(%ebp)
            goto number;
c0109b31:	eb 1f                	jmp    c0109b52 <vprintfmt+0x35c>

        // (unsigned) hexadecimal
        case 'x':
            num = getuint(&ap, lflag);
c0109b33:	8b 45 e0             	mov    -0x20(%ebp),%eax
c0109b36:	89 44 24 04          	mov    %eax,0x4(%esp)
c0109b3a:	8d 45 14             	lea    0x14(%ebp),%eax
c0109b3d:	89 04 24             	mov    %eax,(%esp)
c0109b40:	e8 ec fb ff ff       	call   c0109731 <getuint>
c0109b45:	89 45 f0             	mov    %eax,-0x10(%ebp)
c0109b48:	89 55 f4             	mov    %edx,-0xc(%ebp)
            base = 16;
c0109b4b:	c7 45 ec 10 00 00 00 	movl   $0x10,-0x14(%ebp)
        number:
            printnum(putch, putdat, num, base, width, padc);
c0109b52:	0f be 55 db          	movsbl -0x25(%ebp),%edx
c0109b56:	8b 45 ec             	mov    -0x14(%ebp),%eax
c0109b59:	89 54 24 18          	mov    %edx,0x18(%esp)
c0109b5d:	8b 55 e8             	mov    -0x18(%ebp),%edx
c0109b60:	89 54 24 14          	mov    %edx,0x14(%esp)
c0109b64:	89 44 24 10          	mov    %eax,0x10(%esp)
c0109b68:	8b 45 f0             	mov    -0x10(%ebp),%eax
c0109b6b:	8b 55 f4             	mov    -0xc(%ebp),%edx
c0109b6e:	89 44 24 08          	mov    %eax,0x8(%esp)
c0109b72:	89 54 24 0c          	mov    %edx,0xc(%esp)
c0109b76:	8b 45 0c             	mov    0xc(%ebp),%eax
c0109b79:	89 44 24 04          	mov    %eax,0x4(%esp)
c0109b7d:	8b 45 08             	mov    0x8(%ebp),%eax
c0109b80:	89 04 24             	mov    %eax,(%esp)
c0109b83:	e8 a4 fa ff ff       	call   c010962c <printnum>
            break;
c0109b88:	eb 38                	jmp    c0109bc2 <vprintfmt+0x3cc>

        // escaped '%' character
        case '%':
            putch(ch, putdat);
c0109b8a:	8b 45 0c             	mov    0xc(%ebp),%eax
c0109b8d:	89 44 24 04          	mov    %eax,0x4(%esp)
c0109b91:	89 1c 24             	mov    %ebx,(%esp)
c0109b94:	8b 45 08             	mov    0x8(%ebp),%eax
c0109b97:	ff d0                	call   *%eax
            break;
c0109b99:	eb 27                	jmp    c0109bc2 <vprintfmt+0x3cc>

        // unrecognized escape sequence - just print it literally
        default:
            putch('%', putdat);
c0109b9b:	8b 45 0c             	mov    0xc(%ebp),%eax
c0109b9e:	89 44 24 04          	mov    %eax,0x4(%esp)
c0109ba2:	c7 04 24 25 00 00 00 	movl   $0x25,(%esp)
c0109ba9:	8b 45 08             	mov    0x8(%ebp),%eax
c0109bac:	ff d0                	call   *%eax
            for (fmt --; fmt[-1] != '%'; fmt --)
c0109bae:	ff 4d 10             	decl   0x10(%ebp)
c0109bb1:	eb 03                	jmp    c0109bb6 <vprintfmt+0x3c0>
c0109bb3:	ff 4d 10             	decl   0x10(%ebp)
c0109bb6:	8b 45 10             	mov    0x10(%ebp),%eax
c0109bb9:	48                   	dec    %eax
c0109bba:	0f b6 00             	movzbl (%eax),%eax
c0109bbd:	3c 25                	cmp    $0x25,%al
c0109bbf:	75 f2                	jne    c0109bb3 <vprintfmt+0x3bd>
                /* do nothing */;
            break;
c0109bc1:	90                   	nop
    while (1) {
c0109bc2:	e9 37 fc ff ff       	jmp    c01097fe <vprintfmt+0x8>
                return;
c0109bc7:	90                   	nop
        }
    }
}
c0109bc8:	83 c4 40             	add    $0x40,%esp
c0109bcb:	5b                   	pop    %ebx
c0109bcc:	5e                   	pop    %esi
c0109bcd:	5d                   	pop    %ebp
c0109bce:	c3                   	ret    

c0109bcf <sprintputch>:
 * sprintputch - 'print' a single character in a buffer
 * @ch:         the character will be printed
 * @b:          the buffer to place the character @ch
 * */
static void
sprintputch(int ch, struct sprintbuf *b) {
c0109bcf:	55                   	push   %ebp
c0109bd0:	89 e5                	mov    %esp,%ebp
    b->cnt ++;
c0109bd2:	8b 45 0c             	mov    0xc(%ebp),%eax
c0109bd5:	8b 40 08             	mov    0x8(%eax),%eax
c0109bd8:	8d 50 01             	lea    0x1(%eax),%edx
c0109bdb:	8b 45 0c             	mov    0xc(%ebp),%eax
c0109bde:	89 50 08             	mov    %edx,0x8(%eax)
    if (b->buf < b->ebuf) {
c0109be1:	8b 45 0c             	mov    0xc(%ebp),%eax
c0109be4:	8b 10                	mov    (%eax),%edx
c0109be6:	8b 45 0c             	mov    0xc(%ebp),%eax
c0109be9:	8b 40 04             	mov    0x4(%eax),%eax
c0109bec:	39 c2                	cmp    %eax,%edx
c0109bee:	73 12                	jae    c0109c02 <sprintputch+0x33>
        *b->buf ++ = ch;
c0109bf0:	8b 45 0c             	mov    0xc(%ebp),%eax
c0109bf3:	8b 00                	mov    (%eax),%eax
c0109bf5:	8d 48 01             	lea    0x1(%eax),%ecx
c0109bf8:	8b 55 0c             	mov    0xc(%ebp),%edx
c0109bfb:	89 0a                	mov    %ecx,(%edx)
c0109bfd:	8b 55 08             	mov    0x8(%ebp),%edx
c0109c00:	88 10                	mov    %dl,(%eax)
    }
}
c0109c02:	90                   	nop
c0109c03:	5d                   	pop    %ebp
c0109c04:	c3                   	ret    

c0109c05 <snprintf>:
 * @str:        the buffer to place the result into
 * @size:       the size of buffer, including the trailing null space
 * @fmt:        the format string to use
 * */
int
snprintf(char *str, size_t size, const char *fmt, ...) {
c0109c05:	55                   	push   %ebp
c0109c06:	89 e5                	mov    %esp,%ebp
c0109c08:	83 ec 28             	sub    $0x28,%esp
    va_list ap;
    int cnt;
    va_start(ap, fmt);
c0109c0b:	8d 45 14             	lea    0x14(%ebp),%eax
c0109c0e:	89 45 f0             	mov    %eax,-0x10(%ebp)
    cnt = vsnprintf(str, size, fmt, ap);
c0109c11:	8b 45 f0             	mov    -0x10(%ebp),%eax
c0109c14:	89 44 24 0c          	mov    %eax,0xc(%esp)
c0109c18:	8b 45 10             	mov    0x10(%ebp),%eax
c0109c1b:	89 44 24 08          	mov    %eax,0x8(%esp)
c0109c1f:	8b 45 0c             	mov    0xc(%ebp),%eax
c0109c22:	89 44 24 04          	mov    %eax,0x4(%esp)
c0109c26:	8b 45 08             	mov    0x8(%ebp),%eax
c0109c29:	89 04 24             	mov    %eax,(%esp)
c0109c2c:	e8 08 00 00 00       	call   c0109c39 <vsnprintf>
c0109c31:	89 45 f4             	mov    %eax,-0xc(%ebp)
    va_end(ap);
    return cnt;
c0109c34:	8b 45 f4             	mov    -0xc(%ebp),%eax
}
c0109c37:	c9                   	leave  
c0109c38:	c3                   	ret    

c0109c39 <vsnprintf>:
 *
 * Call this function if you are already dealing with a va_list.
 * Or you probably want snprintf() instead.
 * */
int
vsnprintf(char *str, size_t size, const char *fmt, va_list ap) {
c0109c39:	55                   	push   %ebp
c0109c3a:	89 e5                	mov    %esp,%ebp
c0109c3c:	83 ec 28             	sub    $0x28,%esp
    struct sprintbuf b = {str, str + size - 1, 0};
c0109c3f:	8b 45 08             	mov    0x8(%ebp),%eax
c0109c42:	89 45 ec             	mov    %eax,-0x14(%ebp)
c0109c45:	8b 45 0c             	mov    0xc(%ebp),%eax
c0109c48:	8d 50 ff             	lea    -0x1(%eax),%edx
c0109c4b:	8b 45 08             	mov    0x8(%ebp),%eax
c0109c4e:	01 d0                	add    %edx,%eax
c0109c50:	89 45 f0             	mov    %eax,-0x10(%ebp)
c0109c53:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
    if (str == NULL || b.buf > b.ebuf) {
c0109c5a:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
c0109c5e:	74 0a                	je     c0109c6a <vsnprintf+0x31>
c0109c60:	8b 55 ec             	mov    -0x14(%ebp),%edx
c0109c63:	8b 45 f0             	mov    -0x10(%ebp),%eax
c0109c66:	39 c2                	cmp    %eax,%edx
c0109c68:	76 07                	jbe    c0109c71 <vsnprintf+0x38>
        return -E_INVAL;
c0109c6a:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax
c0109c6f:	eb 2a                	jmp    c0109c9b <vsnprintf+0x62>
    }
    // print the string to the buffer
    vprintfmt((void*)sprintputch, &b, fmt, ap);
c0109c71:	8b 45 14             	mov    0x14(%ebp),%eax
c0109c74:	89 44 24 0c          	mov    %eax,0xc(%esp)
c0109c78:	8b 45 10             	mov    0x10(%ebp),%eax
c0109c7b:	89 44 24 08          	mov    %eax,0x8(%esp)
c0109c7f:	8d 45 ec             	lea    -0x14(%ebp),%eax
c0109c82:	89 44 24 04          	mov    %eax,0x4(%esp)
c0109c86:	c7 04 24 cf 9b 10 c0 	movl   $0xc0109bcf,(%esp)
c0109c8d:	e8 64 fb ff ff       	call   c01097f6 <vprintfmt>
    // null terminate the buffer
    *b.buf = '\0';
c0109c92:	8b 45 ec             	mov    -0x14(%ebp),%eax
c0109c95:	c6 00 00             	movb   $0x0,(%eax)
    return b.cnt;
c0109c98:	8b 45 f4             	mov    -0xc(%ebp),%eax
}
c0109c9b:	c9                   	leave  
c0109c9c:	c3                   	ret    

c0109c9d <hash32>:
 * @bits:   the number of bits in a return value
 *
 * High bits are more random, so we use them.
 * */
uint32_t
hash32(uint32_t val, unsigned int bits) {
c0109c9d:	55                   	push   %ebp
c0109c9e:	89 e5                	mov    %esp,%ebp
c0109ca0:	83 ec 10             	sub    $0x10,%esp
    uint32_t hash = val * GOLDEN_RATIO_PRIME_32;
c0109ca3:	8b 45 08             	mov    0x8(%ebp),%eax
c0109ca6:	69 c0 01 00 37 9e    	imul   $0x9e370001,%eax,%eax
c0109cac:	89 45 fc             	mov    %eax,-0x4(%ebp)
    return (hash >> (32 - bits));
c0109caf:	b8 20 00 00 00       	mov    $0x20,%eax
c0109cb4:	2b 45 0c             	sub    0xc(%ebp),%eax
c0109cb7:	8b 55 fc             	mov    -0x4(%ebp),%edx
c0109cba:	88 c1                	mov    %al,%cl
c0109cbc:	d3 ea                	shr    %cl,%edx
c0109cbe:	89 d0                	mov    %edx,%eax
}
c0109cc0:	c9                   	leave  
c0109cc1:	c3                   	ret    

c0109cc2 <rand>:
 * rand - returns a pseudo-random integer
 *
 * The rand() function return a value in the range [0, RAND_MAX].
 * */
int
rand(void) {
c0109cc2:	55                   	push   %ebp
c0109cc3:	89 e5                	mov    %esp,%ebp
c0109cc5:	57                   	push   %edi
c0109cc6:	56                   	push   %esi
c0109cc7:	53                   	push   %ebx
c0109cc8:	83 ec 24             	sub    $0x24,%esp
    next = (next * 0x5DEECE66DLL + 0xBLL) & ((1LL << 48) - 1);
c0109ccb:	a1 78 5a 12 c0       	mov    0xc0125a78,%eax
c0109cd0:	8b 15 7c 5a 12 c0    	mov    0xc0125a7c,%edx
c0109cd6:	69 fa 6d e6 ec de    	imul   $0xdeece66d,%edx,%edi
c0109cdc:	6b f0 05             	imul   $0x5,%eax,%esi
c0109cdf:	01 fe                	add    %edi,%esi
c0109ce1:	bf 6d e6 ec de       	mov    $0xdeece66d,%edi
c0109ce6:	f7 e7                	mul    %edi
c0109ce8:	01 d6                	add    %edx,%esi
c0109cea:	89 f2                	mov    %esi,%edx
c0109cec:	83 c0 0b             	add    $0xb,%eax
c0109cef:	83 d2 00             	adc    $0x0,%edx
c0109cf2:	89 c7                	mov    %eax,%edi
c0109cf4:	83 e7 ff             	and    $0xffffffff,%edi
c0109cf7:	89 f9                	mov    %edi,%ecx
c0109cf9:	0f b7 da             	movzwl %dx,%ebx
c0109cfc:	89 0d 78 5a 12 c0    	mov    %ecx,0xc0125a78
c0109d02:	89 1d 7c 5a 12 c0    	mov    %ebx,0xc0125a7c
    unsigned long long result = (next >> 12);
c0109d08:	8b 1d 78 5a 12 c0    	mov    0xc0125a78,%ebx
c0109d0e:	8b 35 7c 5a 12 c0    	mov    0xc0125a7c,%esi
c0109d14:	89 d8                	mov    %ebx,%eax
c0109d16:	89 f2                	mov    %esi,%edx
c0109d18:	0f ac d0 0c          	shrd   $0xc,%edx,%eax
c0109d1c:	c1 ea 0c             	shr    $0xc,%edx
c0109d1f:	89 45 e0             	mov    %eax,-0x20(%ebp)
c0109d22:	89 55 e4             	mov    %edx,-0x1c(%ebp)
    return (int)do_div(result, RAND_MAX + 1);
c0109d25:	c7 45 dc 00 00 00 80 	movl   $0x80000000,-0x24(%ebp)
c0109d2c:	8b 45 e0             	mov    -0x20(%ebp),%eax
c0109d2f:	8b 55 e4             	mov    -0x1c(%ebp),%edx
c0109d32:	89 45 d8             	mov    %eax,-0x28(%ebp)
c0109d35:	89 55 e8             	mov    %edx,-0x18(%ebp)
c0109d38:	8b 45 e8             	mov    -0x18(%ebp),%eax
c0109d3b:	89 45 ec             	mov    %eax,-0x14(%ebp)
c0109d3e:	83 7d e8 00          	cmpl   $0x0,-0x18(%ebp)
c0109d42:	74 1c                	je     c0109d60 <rand+0x9e>
c0109d44:	8b 45 e8             	mov    -0x18(%ebp),%eax
c0109d47:	ba 00 00 00 00       	mov    $0x0,%edx
c0109d4c:	f7 75 dc             	divl   -0x24(%ebp)
c0109d4f:	89 55 ec             	mov    %edx,-0x14(%ebp)
c0109d52:	8b 45 e8             	mov    -0x18(%ebp),%eax
c0109d55:	ba 00 00 00 00       	mov    $0x0,%edx
c0109d5a:	f7 75 dc             	divl   -0x24(%ebp)
c0109d5d:	89 45 e8             	mov    %eax,-0x18(%ebp)
c0109d60:	8b 45 d8             	mov    -0x28(%ebp),%eax
c0109d63:	8b 55 ec             	mov    -0x14(%ebp),%edx
c0109d66:	f7 75 dc             	divl   -0x24(%ebp)
c0109d69:	89 45 d8             	mov    %eax,-0x28(%ebp)
c0109d6c:	89 55 d4             	mov    %edx,-0x2c(%ebp)
c0109d6f:	8b 45 d8             	mov    -0x28(%ebp),%eax
c0109d72:	8b 55 e8             	mov    -0x18(%ebp),%edx
c0109d75:	89 45 e0             	mov    %eax,-0x20(%ebp)
c0109d78:	89 55 e4             	mov    %edx,-0x1c(%ebp)
c0109d7b:	8b 45 d4             	mov    -0x2c(%ebp),%eax
}
c0109d7e:	83 c4 24             	add    $0x24,%esp
c0109d81:	5b                   	pop    %ebx
c0109d82:	5e                   	pop    %esi
c0109d83:	5f                   	pop    %edi
c0109d84:	5d                   	pop    %ebp
c0109d85:	c3                   	ret    

c0109d86 <srand>:
/* *
 * srand - seed the random number generator with the given number
 * @seed:   the required seed number
 * */
void
srand(unsigned int seed) {
c0109d86:	55                   	push   %ebp
c0109d87:	89 e5                	mov    %esp,%ebp
    next = seed;
c0109d89:	8b 45 08             	mov    0x8(%ebp),%eax
c0109d8c:	ba 00 00 00 00       	mov    $0x0,%edx
c0109d91:	a3 78 5a 12 c0       	mov    %eax,0xc0125a78
c0109d96:	89 15 7c 5a 12 c0    	mov    %edx,0xc0125a7c
}
c0109d9c:	90                   	nop
c0109d9d:	5d                   	pop    %ebp
c0109d9e:	c3                   	ret    
