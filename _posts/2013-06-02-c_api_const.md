---
layout: post
title: UnQLite C/C++ API——常量列表
date: 2013-06-02
categories:
  - 技术
tags:
  - UnQLite
  - C/C++
---

[![UnQLite](/img/logo.jpg)](http://www.symisc.net/)

这个列表包括了UnQLite使用的，在`unqlite.h`头文件中用`#defines`定义的所有数字常量。这些常量包括了，比如各种接口函数返回参数。

## 返回码

绝大多数UnQLite开放接口返回一个整数作为结果码，用于表示成功或失败。以下就是这些结果码。新的错误码可能在未来的版本中增加。

<pre class="prettyprint linenums">
/* 标准UnQLite返回值 */
#define UNQLITE_OK               /* Successful result */
/* 以下的都是错误码 */
#define UNQLITE_NOMEM            /* Out of memory */
#define UNQLITE_ABORT            /* Another thread have released this instance */
#define UNQLITE_IOERR            /* IO error */
#define UNQLITE_CORRUPT          /* Corrupt pointer */
#define UNQLITE_LOCKED           /* Forbidden Operation */
#define UNQLITE_BUSY            	 /* The database file is locked */
#define UNQLITE_DONE            	 /* Operation done */
#define UNQLITE_PERM             /* Permission error */
#define UNQLITE_NOTIMPLEMENTED   /* Method not implemented by the underlying Key/Value storage engine */
#define UNQLITE_NOTFOUND         /* No such record */
#define UNQLITE_NOOP             /* No such method */
#define UNQLITE_INVALID          /* Invalid parameter */
#define UNQLITE_EOF              /* End Of Input */
#define UNQLITE_UNKNOWN          /* Unknown configuration option */
#define UNQLITE_LIMIT            /* Database limit reached */
#define UNQLITE_EXISTS           /* Records exists */
#define UNQLITE_EMPTY            /* Empty record */
#define UNQLITE_COMPILE_ERR      /* Compilation error */
#define UNQLITE_VM_ERR           /* Virtual machine error */
#define UNQLITE_FULL             /* Full database (unlikely) */
#define UNQLITE_CANTOPEN         /* Unable to open the database file */
#define UNQLITE_READ_ONLY        /* Read only Key/Value storage engine */
#define UNQLITE_LOCKERR          /* Locking protocol error */
</pre>

`UNQLITE_OK`表示操作成功。任何其他的值，表示操作失败，需要调用者进行错误处理。为了获得便于阅读的错误消息，客户端可以通过`unqlite_config()`函数，设置`UNQLITE_CONFIG_ERR_LOG`，来提取数据库日志。

`UNQLITE_COMPILE_ERR`和`UNQLITE_VM_ERR`错误仅在调用一个编译接口，比如`unqlite_compile()`或`unqlite_compile_file()`时返回。

如果编译目标Jx9脚本过程中，发生了编译错误，将返回`UNQLITE_COMPILE_ERR`。在这种情况下，调用者必须修复Jx9错误，然后再次调用编译接口。注意编译错误日志，可以通过调用`unqlite_config()`，设置`UNQLITE_CONFIG_JX9_ERR_LOG`，来提取。

当成功编译Jx9脚本之后，如果初始化UnQLite虚拟机(unqlite\_vm)时出现问题，将返回`UNQLITE_VM_ERR`错误。这个问题，经常因内存错误引发，但是请记住`内存耗尽`几乎是不可能出现的场景，在现代硬件，即使是现代嵌入式系统。

在Key/Value引擎或数据库以`只读`权限打开的情况下，会返回UNQLITE\_READ\_ONLY。

当其他线程或进程对当前数据库持有一个`保留或独占锁`时，会返回`UNQLITE_BUSY`错误。在这种情况下，调用着需要等待，直到锁的持有者放弃锁。很多开放接口也会返回这个错误码，如：
    
    unqlite_kv_store()、
    unqlite_kv_append()、
    unqlite_kv_delete()、
    unqlite_vm_exec()、等等。

当KV存储没有实现这个目标方法时，会返回`UNQLITE_NOTIMPLEMENTED`错误。如针对 `unqlite_kv_append()`的`xAppend()`，针对`unqlite_kv_store()`的`xStore()`，针对`unqlite_kv_delete()`的`xDelete()`，等等。

当UnQLite运行时，内存耗尽，会返回`UNQLITE_NOMEM`错误。

当安装外部函数模拟Jx9挂掉时，可以返回`UNQLITE_ABORT`错误码。这个错误也可能从一个开放接口中返回，当且仅当unqlite库被编译为支持`多线程`，而且给unqlite或unqlite_vm的指针被另一个线程释放掉了。


## UnQLite库编译时选项

出于很多目的，使用默认选项编译UnQLite已经足够好了。但是，如果需要，可以使用以下汇编的编译选项放弃UnQLite的特性（产生一个更小的库）或修改某些参数的默认值。

尽一切努力，确保不同编译选项的组合都和谐地运行，并产生一个有效的库。

### UNQLITE_ENABLE_THREADS

这个选项控制是否，包括到UnQLite中的代码，支持多线程环境的操作安全。默认不是线程安全的，所有互斥代码被放弃，所以在多线程中使用UnQLite是不安全的。当打开UNQLITE_ENABLE_THREADS编译选项开关时，才是线程安全的。UnQLite可以在多线程程序中使用，此时在两个或多个线程之间共享相同的虚拟机和数据库句柄是安全的。

`UNQLITE_ENABLE_THREADS`的值，可以在运行时，通过`unqlite_lib_is_threadsafe()`接口检测得到。当UnQLite是采用支持线程的方式编译，那么可以在运行时通过`unqlite_lib_config()`和以下的一个动词修改线程模式：
    
    UNQLITE_LIB_CONFIG_THREAD_LEVEL_SINGLE
    UNQLITE_LIB_CONFIG_THREAD_LEVEL_MULTI
     
非`Windows`和`UNIX`系统平台，需要通过`unqlite_lib_config()`，设置`UNQLITE_LIB_CONFIG_USER_MUTEX`，来安装自己的`mutex系统`。否则这个库是线程不安全的。

注意在`Unix`系统下，你必须使用`POSIX`线程库（如`-lpthread`）链接UnQLite。


## 忽略/启用特性选项

以下的选项可以用来减小编译后的unqlite库的尺寸，通过忽略可选的特性。

也许这仅对空间尤其紧缺的嵌入式系统有用，即使包含所有特性UnQLite库相对小。别忘了告诉你的编译器优化二进制文件尺寸（如果使用GCC编译器，`-Os`选项）。告诉你的编译器优化尺寸，对库的footprint影响比采用任何下面的编译选项还要大：

### JX9_DISABLE_BUILTIN_FUNC

Jx9内建了312个函数，可以满足绝大部分目的，如字符串和INI处理，ZIP提取，Base64编/解码，JSON编/解码等等。如果启用了`JX9_DISABLE_BUILTIN_FUNC`编译选项，编译时Jx9所有内建函数都将被忽略。注意特殊的函数，如 db\_create()、db\_store()和db\_fetch()等，在编译构建时，不会被忽略，而且不受此指示的影响。

### JX9_ENABLE_MATH_FUNC

如果启用了此指示，内建的数学计算函数，如sqrt()、abs()、log()和ceil()等，将被包含到编译中。注意在Linux/BSD,你应该需要使用math库（如，`-lm`）链接UnQLite。

### JX9_DISABLE_DISK_IO

如果启用了此指示，内建的VFS函数，如chdir()、mkdir()、chroot()、unlink()和sleep()等，将从编译构建中被忽略掉。

### UNQLITE_ENABLE_JX9_HASH_IO

如果启用了此指示，内建的hash函数，如md5()、sha1()、md5_file()和crc32()等，将被包括在编译构建中。

## 扩展阅读


## 祝大家玩的开心

