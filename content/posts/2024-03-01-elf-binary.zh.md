---
title: ELF文件结构
ZHtags: 
  - binary
key: elf-file
date: '2024-03-01'
lastmod: '2024-03-01'
---
# ELF（Executable and Linkable Format）文件
- 可重定位文件（Relocatable File），包含由编译器生成的代码以及数据。链接器会将它与其它目标文件链接起来从而创建可执行文件或者共享目标文件。在 Linux 系统中，这种文件的后缀一般为 .o 。

- 可执行文件（Executable File），就是通常在 Linux 中执行的程序。

- 共享目标文件（Shared Object File），包含代码和数据，这种文件称为库文件，一般以 .so 结尾。一般情况下，它有以下两种使用情景：
    - 链接器（ld）可能会处理它和其它可重定位文件以及共享目标文件，生成另外一个目标文件。
    - 动态链接器（Dynamic Linker）将它与可执行文件以及其它共享目标组合在一起生成进程镜像。

## ELF文件结构

- ELF header（ELF头部）：包含有关文件结构的基本信息，如文件编译的体系结构、文件类型（可执行文件、共享对象等）、可执行文件的入口点等。

- Program header table（程序头表）:描述了在加载和执行可执行文件时，操作系统如何处理文件的各个段（segments）的信息，包括段类型、段偏移、虚拟地址、物理地址、段大小、文件大小、段权限等。只有可执行文件和共享目标文件包含程序头表.

- Section header table（节头表）：描述了ELF文件中每个分区的具体位置，包括节名称、节类型、标志、文件偏移、节区大小、链接信息、对齐信息、附加信息等。

- 段内容：一个段可能包括一到多个节区，这并不会影响程序的加载。通常包含代码段和数据段。



## 数据结构
### 文件头
*include/elf.h*
```c
#define EI_NIDENT (16)

typedef struct elf32_hdr{
  unsigned char e_ident[EI_NIDENT];
  Elf32_Half e_type;
  Elf32_Half e_machine;
  Elf32_Word e_version;
  Elf32_Addr e_entry;  /* Entry point */
  Elf32_Off e_phoff;
  Elf32_Off e_shoff;
  Elf32_Word e_flags;
  Elf32_Half e_ehsize;
  Elf32_Half e_phentsize;
  Elf32_Half e_phnum;
  Elf32_Half e_shentsize;
  Elf32_Half e_shnum;
  Elf32_Half e_shstrndx;
} Elf32_Ehdr;
```

- Program header table（程序头表）:e_phoff、e_phentsize、e_phnum、e_entry
- Section header table（节头表）: e_shoff、e_shentsize、e_shnum、e_shstrndx（字符串表相关的表项的索引
值）
- e_ident: 0x00~0x03为 Magic Number（魔数）， 0x04指定格式为32位/64位，0x05指定大端/小端模式，0x06为
elf文件版本，0x07为OSABI，0x08为ABI版本,0x09~0x0f为保留位。
- e_type（目标文件类型，ET_NONE ET_REL ET_EXEC ET_DYN ET_CORE ET_LOPROC ET_HIPROC）
- e_machine(机器架构) 
- e_version（文件版本）
- e_flags（处理器相关标志）
- e_ehsize（ELF文件头长度）

### 程序头表
```c
#define PF_R 0x4
#define PF_W 0x2
#define PF_X 0x1

typedef struct elf32_phdr{
  Elf32_Word p_type;
  Elf32_Off p_offset;
  Elf32_Addr p_vaddr;
  Elf32_Addr p_paddr;
  Elf32_Word p_filesz;
  Elf32_Word p_memsz;
  Elf32_Word p_flags;
  Elf32_Word p_align;
} Elf32_Phdr;
```
- p_offset（偏移地址）
- p_vaddr（虚拟地址）
- p_paddr（物理地址）
- p_filez（文件中的大小）
- p_memsz（内存中的大小）
- p_align（对齐方式）
- p_type（段类型）
    - PT_NULL:未使用
    - PT_LOAD:可加载段
    - PT_DYNAMIC:动态链接信息
    - PT_INTERP:此类型段给出了一个以 NULL 结尾的字符串的位置和长度，该字符串将被当作解释器调用。这种段类型仅对可执行文件有意义（也可能出现在共享目标文件中）。这种段在一个文件中最多出现一次。而且这种类型的段若存在，它必须在所有可加载段项的前面。
    - PT_NOTE:附加信息的位置和长度。
    - PT_SHLIB:保留
    - PT_PHDR:给出程序头表自身的大小和位置
    - PT_TLS:Thread-Local Storage Template（一种基于模板的通用方法，用于创建线程局部存储变量）
    - PT_LOOS:保留范围（依赖操作系统）
    - PT_HIOS:保留范围（依赖操作系统）
    - PT_LOPROC:保留范围（依赖处理器）
    - PT_HIPROC:保留范围（依赖处理器）
- p_flags（段权限）
    - 代码段：包含只读的数据以及指令。通常包含.text节、.rodata节（只读数据）、.hash节（动态符号表的哈希表）、.dynsym节（动态符号表中的符号条目）、.dynstr节（动态字符串表）、.plt节（不同处理器会变动）、.rel.got（全局偏移表的可重定位信息）节等。
    - 数据段：包含可写的数据以及指令，通常包含.data节、.dynamic节（PT_DYNAMIC 类型的元素指向 .dynamic 节）、.got节、.bss节（SHT_NOBITS，在ELF文件中不占用空间，但是它占用其内存镜像的空间）等。

### 节头表
```c
typedef struct elf32_shdr {
  Elf32_Word sh_name;
  Elf32_Word sh_type;
  Elf32_Word sh_flags;
  Elf32_Addr sh_addr;
  Elf32_Off sh_offset;
  Elf32_Word sh_size;
  Elf32_Word sh_link;
  Elf32_Word sh_info;
  Elf32_Word sh_addralign;
  Elf32_Word sh_entsize;
} Elf32_Shdr;
```
- sh_name（节名称） 
- sh_type（节类型） 
- sh_flags（标志） 
- sh_addr（节区位置） 
- sh_offset（节区偏移） 
- sh_size（节区大小） 
- sh_link（节头表索引链接） 
- sh_info（附加信息） 
- sh_addralign（节区地址对齐） 
- sh_entsize（固定大小的表项的表）

## ELF文件分析
### 例子
*文件头*  
![](/images/elf-ehdr.png) 
- EI_NIDENT: 16
- e_ident: 7F 45 4C 46 01 01 01 00 00 00 00 00 00 00 00 00 魔数，32位，小端模式，System V
- e_type: 00 02 可执行文件
- e_machine: 00 F3 RISCV 
- e_version: 00 01 版本为1
- e_entry: 00 01 00 8C 入口地址为0x1008ch
- e_phoff: 00 00 00 34 程序头表偏移地址0x0034h
- e_shoff: 00 00 54 A0 节头表偏移地址0x54A0h
- e_flags: 00 00 00 00
- e_ehsize: 00 34 文件头大小为52 
- e_phentsize: 00 20 程序头表大小为32
- e_phnum: 00 02 程序头表的项数
- e_shentsize: 00 28 节头的长度为40
- e_shnum: 00 15 节头表项数为21
- e_shstrndx: 00 14 字符串表相关的表项的索引值为20  
*程序头表*  
*代码段*  
![](/images/elf-phdr-code.png)
- p_type: 00 00 00 01 PT_LOAD 可加载段
- p_offset: 00 00 00 00 从文件开始到该段开头的第一个字节的偏移地址为0x00000000
- p_vaddr: 00 01 00 00 该段第一个字节在内存中的虚拟地址为0x00010000
- p_paddr: 00 01 00 00 仅用于物理地址寻址相关的系统，“System V”忽略了应用程序的物理寻址
- p_filesz: 00 00 36 6A 文件镜像中该段的大小为0x0366A
- p_memsz: 00 00 36 6A 内存镜像中该段的大小为0x0366A
- p_flags:  00 00 00 05 段标记为PF_R、PF_X
- p_align: 00 00 10 00 对齐方式  
*数据段*  
![](/images/elf-phdr-data.png)
- p_type: 00 00 00 01 PT_LOAD 可加载段
- p_offset: 36 6C 从文件开始到该段开头的第一个字节的偏移地址为0x0000366C
- p_vaddr: 00 01 46 6C 该段第一个字节在内存中的虚拟地址为0x0001466C
- p_paddr: 00 01 46 6C 仅用于物理地址寻址相关的系统，“System V”忽略了应用程序的物理寻址
- p_filesz: 00 00 08 58 文件镜像中该段的大小为0x00858
- p_memsz: 00 00 08 B0 内存镜像中该段的大小为0x008B0
- p_flags: 00 00 06 00 段标记为PF_R、PF_W
- p_align: 00 00 00 10 对齐方式  
*节头表*  
![](/images/elf-shdr.png)
*起始地址为0x000054A0H，结束地址为0x000057E0H，字符串表的节区头（计算节区头地址为0x000054A0H + 20 &times; 40H = 20x000057B0H）*
- sh_name: 00 00 00 11
- sh_type: 00 00 00 03 SHT_STRTAB 字符串表
- sh_flags: 00 00 00 00 标志
- sh_addr: 00 00 00 00 虚拟地址为0x0000H
- sh_offset: 00 00 53 D1 偏移地址为0x53D1H
- sh_size: 00 00 00 CE 节区字节大小为0x00CEH
- sh_link: 00 00 00 00 索引链接
- sh_info: 00 00 00 00 附加信息
- sh_addralign: 00 00 00 01 没有对齐约束
- sh_entsize: 00 00 00 00 无固定大小条目部分  
*找到字符串表偏移地址（0x53D1H）后即可找到节区名及其对应的偏移地址*
![](/images/elf-string-table.png)



