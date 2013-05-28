---
layout: post
title: 五分钟玩转UnQLite
date: 2013-05-26
categories:
  - 技术
tags:
  - UnQLite
---

这就是上手UnQLite数据库引擎指南，不需要做大量乏味的阅读和配置：


## 下载代码

获取最新开放版本的UnQLite（一个1.8MB的C文件）。访问[下载](http://unqlite.org/downloads.html)页面，获取更多信息。

## 编写应用UnQLite的程序

一个数据库引擎的主要任务就是存储和遍历记录。UnQLite，同时支持`结构化`和`原始数据`记录存储。

UnQLite的`结构化数据存储`是通过`文档存储接口`表达给客户端的。文档存储本身是用来存储JSOB文档（如，对象、数组、字符串等）在数据库中，而且由Jx9编程语言支撑。Jx9是一种嵌入式的脚本语言，也叫扩展语言，被设计用于通用过程化编程，具备数据表述的特性。Jx9是一个图灵完备（Turing-Complete），基于JSON的，动态类型编程语言，作为UnQLite内核的一个库而存在。可以通过[Jx9](http://unqlite.org/jx9.html)页面获取更多信息。

`原始数据存储`是通过`Key/Value存储接口`表达给客户端的。UnQLite是一个标准的key/value存储，类似于Berkeley DB、Tokyo Cabinet和LevelDB等，但拥有更加丰富的特性，包括支持`事务`（ACID），并发读取等。在KV存储下，键和值都被视为简单的字节数组，所以内容可以是任何东西，包括ASCII字符串、二进制对象和磁盘文件等。

## Key/Value存储C/C++接口

到目前为止，UnQLite的Key/Value存储层是最简单的，却是最灵活的，因为它不会强加任何结构或schema（数据库表结构）于数据库记录。Key/Value存储层是通过一组接口函数表达给客户端的。这包括：

    unqlite_kv_store()
    unqlite_kv_append()
    unqlite_kv_fetch_callback()
    unqlite_kv_append_fmt()

等等。

下面是一个简单的C程序，用于演示如何使用UnQLite的Key/Value存储C/C++接口：

<pre class="prettyprint linenums">
  #include &lt;unqlite.h&gt;
  int i,rc;
  unqlite *pDb;
  
  // Open our database;
  rc = unqlite_open(&pDb,"test.db",UNQLITE_OPEN_CREATE);
  if( rc != UNQLITE_OK ){ return; }
  
  // Store some records
  rc = unqlite_kv_store(pDb,"test",-1,"Hello World",11); //test => 'Hello World'
  if( rc != UNQLITE_OK ){
   //Insertion fail, Hande error (See below)
    return;
  }
  // A small formatted string
  rc = unqlite_kv_store_fmt(pDb,"date",-1,"Current date: %d:%d:%d",2013,06,07);
  if( rc != UNQLITE_OK ){
    //Insertion fail, Hande error (See below)
    return;
  }

  //Switch to the append interface
  rc = unqlite_kv_append(pDb,"msg",-1,"Hello, ",7); //msg => 'Hello, '
  if( rc == UNQLITE_OK ){
    //The second chunk
    rc = unqlite_kv_append(pDb,"msg",-1,"Current time is: ",17); //msg => 'Hello, Current time is: '
    if( rc == UNQLITE_OK ){
      //The last formatted chunk
      rc = unqlite_kv_append_fmt(pDb,"msg",-1,"%d:%d:%d",10,16,53); //msg => 'Hello, Current time is: 10:16:53'
    }
  }

  //Delete a record
  unqlite_kv_delete(pDb,"test",-1);

  //Store 20 random records.
  for(i = 0 ; i < 20 ; ++i ){
    char zKey[12]; //Random generated key
    char zData[34]; //Dummy data
 
    // generate the random key
    unqlite_util_random_string(pDb,zKey,sizeof(zKey));
  
    // Perform the insertion
    rc = unqlite_kv_store(pDb,zKey,sizeof(zKey),zData,sizeof(zData));
    if( rc != UNQLITE_OK ){
      break;
     }
  }
  
  if( rc != UNQLITE_OK ){
    //Insertion fail, Handle error
    const char *zBuf;
    int iLen;
    /* Something goes wrong, extract the database error log */
    unqlite_config(pDb,UNQLITE_CONFIG_ERR_LOG,&zBuf,&iLen);
    if( iLen > 0 ){
      puts(zBuf);
     }
    if( rc != UNQLITE_BUSY && rc != UNQLITE_NOTIMPLEMENTED ){
      /* Rollback */
      unqlite_rollback(pDb);
     }
  }
  
  //Auto-commit the transaction and close our handle.
  unqlite_close(pDb);
</pre>

[获取一份C代码](http://unqlite.org/db/unqlite_kv_intro.c)

在第6行通过调用unqlite_open()函数打开数据库。这通常是应用开发中，第一个UnQLite API调用，也是确保正常使用UnQLite程序库的条件。

基于Key/Value层的`原始数据存储`，是从第10行执行到29行，通过各个UnQLite接口函数，如unqlite\_kv\_store(), unqlite\_kv\_append(), unqlite\_kv\_store\_fmt(), unqlite\_kv\_append\_fmt()等。

在34行，我们通过unqlite\_kv_\delete()接口，从数据库中移除一条记录。
从36行到48行，我们执行了一个20条随机记录的`插入`操作。其中的`随机健`是通过`unqlite_util_random_string()`函数生成的。

错误处理是在53到62行完成。

最终，事务被自动的提交，而数据库是在66行通过unqlite_close()函数关闭的。

在KV存储下，键和值都被视为简单的字节数组，你甚至可以插入外部文件，如XML或任何你需要的文件，到你的UnQLite数据库，然后通过一个 O(1)查询，将其（如UnQLite数据库）放到一个Tar存档中。以下是一个示例代码片段：

<pre class="prettyprint linenums">
  #include <unqlite.h>
  // Usage example: ./unqlite_tar config.xml license.txt audio.wav splash.jpeg,...
  void *pMap;
  unqlite_int64 iSize;
  int rc,i;
  unqlite *pDb;

  // Open our database;
  rc = unqlite_open(&pDb,"test.db",UNQLITE_OPEN_CREATE);

  if( rc != UNQLITE_OK ){ /* Handle error */ return; }
   
  // Store the given files in our database
  for( i = 1 ; i < argc ; ++i ){
    const char *zName = argv[i]; //Name of the target file
    
    // Obtain a read-only memory view of the target file;
    rc = unqlite_util_load_mmaped_file(zName,&pMap,&iSize);
    if( rc != UNQLITE_OK ){ /* Handle error */ return; }
       
    // Store the whole file in our database;
    rc = unqlite_kv_store(pDb,zName,-1,pMap,iSize);
    if( rc != UNQLITE_OK ){ /* Handle error */ return; }
    
    // Discard the memory view;
    unqlite_util_release_mmaped_file(pMap,iSize);
  }
     
    
  //Auto-commit the transaction and close our handle
  unqlite_close(pDb);
</pre>

[获取一份C代码](http://unqlite.org/db/unqlite_tar.c)

这里需要注意的函数调用是，18行的unqlite\_util\_load\_mmaped\_file()，用于获得`整个文件的一个只读内存视图`。经过这样操作之后，通过调用unqlite\_kv\_store()函数完成一个标准的KV插入操作。

从KV存储中获取数据是非常简单的，只需要一个函数调用：unqlite\_kv\_fetch\_callback() 或 unqlite\_kv\_fetch()。其中，unqlite\_kv\_fetch\_callback()是推荐使用的函数，此时需要调用者提供一个简单的回调函数，负责消耗掉记录数据，也许重定向（如记录数据）到标准输出或连接上来的客户端（可以参考接口文档中可运行的示例）。至于`unqlite_kv_fetch()`函数，大家应该并不陌生，它需要一个用户提供的`缓冲区`（静态的或动态分配的都可以），将记录数据拷贝进去。


## 使用数据库游标

`游标`提供了一种机制，通过它，你可以`遍历`整个数据库的记录。使用游标，你可以定位，提取，移动和删除数据库记录。

点击[这里]()的API文档，可以了解游标接口相关内容。

下面是一个简单的C程序，演示了如何使用游标。这个程序，将从最后一条记录到第一条，遍历整个数据库。

<pre class="prettyprint linenums">
  #include <unqlite.h>
  
  int rc;
  unqlite *pDb;
  unqlite_kv_cursor *pCursor;
  unqlite_int64 iData;
  
  // Open our database;
  rc = unqlite_open(&pDb,"test.db",UNQLITE_OPEN_CREATE);
  if( rc != UNQLITE_OK ){ return; }
  
  //Store some records unqlite_kv_store(), unqlite_kv_append()...

  /* Allocate a new cursor instance */
  rc = unqlite_kv_cursor_init(pDb,&pCursor);
  if( rc != UNQLITE_OK ){ return; }
  
  /* Point to the last record */
  rc = unqlite_kv_cursor_last_entry(pCursor);
  if( rc != UNQLITE_OK ){ return; }
  
  /* Iterate over the records */
  while( unqlite_kv_cursor_valid_entry(pCursor) ){
    /* Consume the key */
    printf("\nKey ==>\n\t");
    unqlite_kv_cursor_key_callback(pCursor,DataConsumerCallback,0);

    /* Extract data length */
    unqlite_kv_cursor_data(pCursor,NULL,&iData);
    printf("\nData length ==> %lld\n\t",iData);
       
    /* Consume the data */
    unqlite_kv_cursor_data_callback(pCursor,DataConsumerCallback,0);
     
    /* Point to the previous record */
  	 unqlite_kv_cursor_prev_entry(pCursor);
  }
  
  /* Finally, Release our cursor */
  unqlite_kv_cursor_release(pDb,pCursor);
  
  //Auto-commit the transaction and close our handle
  unqlite_close(pDb);
</pre>

[获取一份C代码](http://unqlite.org/db/unqlite_csr_intro.c)


## 文档存储 C/C++接口介绍

UnQLite结构化数据存储，是通过文档存储接口表达给客户端的。文档存储是用来在数据库中存储JSON文档（如，对象、数组、字符串等）的，是通过`Jx9`编程语言支撑/实现的。下面是一个Jx9脚本，通过后面的C程序编译，演示如何使用UnQLite的文档存储接口。

<pre class="prettyprint linenums">
/* Create the collection 'users'  */
if( !db_exists('users') ){
    /* Try to create it */
   $rc = db_create('users');
   if ( !$rc ){
     //Handle error
      print db_errlog();
   return;
   }
}
//The following is the JSON objects to be stored shortly in our 'users' collection
$zRec = [
{
   name : 'james',
   age  : 27,
   mail : 'dude@example.com'
},
{
   name : 'robert',
   age  : 35,
   mail : 'rob@example.com'
},
{
   name : 'monji',
   age  : 47,
   mail : 'monji@example.com'
},
{
  name : 'barzini',
  age  : 52,
  mail : 'barz@mobster.com'
}
];
//Store our records
$rc = db_store('users',$zRec);
if( !$rc ){
 //Handle error
    print db_errlog();
  return;
}
//One more record
$rc = db_store('users',{ name : 'alex', age : 19, mail : 'alex@example.com'  });
if( !$rc ){
 //Handle error
    print db_errlog();
  return;
}
print "Total number of stored records: ",db_total_records('users'),JX9_EOL;

//Fetch data using db_fetch_all(), db_fetch_by_id() and db_fetch().
</pre>

现在，编译和执行以上定义的这个Jx9脚本的C程序，如下：

<pre class="prettyprint linenums">
#include <unqlite.h>

int rc;
unqlite *pDb;
unqlite_vm *pDb;

// Open our database;
rc = unqlite_open(&pDb,"test.db",UNQLITE_OPEN_CREATE);
if( rc != UNQLITE_OK ){ /* Handle error */ return;

/* Compile the Jx9 script defined above */
rc = unqlite_compile(pDb,JX9_PROG,sizeof(JX9_PROG)-1,&pVm);
if( rc != UNQLITE_OK ){
  if( rc == UNQLITE_COMPILE_ERR ){
     const char *zBuf;
     int iLen;
     /* Compile-time error, extract the compiler error log */
    	 unqlite_config(pDb,UNQLITE_CONFIG_JX9_ERR_LOG,&zBuf,&iLen);
     if( iLen > 0 ){
      	 puts(zBuf);
     }
 	 }
 return;
}

/* Install a VM output consumer callback */
rc = unqlite_vm_config(pVm,UNQLITE_VM_CONFIG_OUTPUT,OutputConsumer,0);
if( rc != UNQLITE_OK ){
 return;
}

/* Execute our script */
rc = unqlite_vm_exec(pVm);
if( rc != UNQLITE_OK ){
 return;
}

/* Finally, release our VM */
unqlite_vm_release(pVm);

unqlite_close(pDb);
</pre>

[获取一份C代码](http://unqlite.org/db/unqlite_doc_intro.c)

UnQLite文档存储接口原理，如下：

1. 通过unqlite_open()函数获得一个新的数据库句柄（示例中第8行）。
2. 通过一个接口函数unqlite\_compile()或unqlite\_compile\_file()编译你的Jx9脚本（示例中第12行）。一旦编译成功，引擎会自动创建一个unqlite_vm结构实例，同时为调用这备好一个指向该结构的指针。
3. 当由于一个编译时错误，导致目标Jx9脚本编译出错时，调用者必须丢弃掉这个指针，并修正错误的Jx9代码。编译时的错误是可以提取的（示例中第18行），通过调用UNQLITE\_CONFIG\_JX9\_ERR\_LOG配置的unqlite\_config()。
4. 可以通过unqlite\_vm\_config()函数配置虚拟机。这是一个可选的操作。
5. 可以通过unqlite\_create\_function()或 unqlite\_create\_constant()函数，注册一个或多个外部函数或常量。
6. 通过调用unqlite\_vm\_exec()函数，来执行编译之后的Jx9程序。
7. 可以通过unqlite\_vm\_extract_variable()函数，提取Jx9脚本中声明的一个或多个变量的内容。这是可选的操作。
8. 通过unqlite_\vm\_reset()重置虚拟机，回到第6步。这是可选的操作。操作操作0或多次。
9. 最后，通过unqlite_vm_release()销毁虚拟机（示例中第39行）。


## 其他有用的上手链接

点击[UnQLite C/C++接口介绍](http://unqlite.org/api_intro.html)，了解几十个UnQLite接口函数概要和路线图介绍。一个独立的文档，[UnQLite C/C++接口](http://unqlite.org/c_api.html)，提供了所有UnQLite函数的详细的规范。一旦读者了解了UnQLite的基础操作原则，[此文档](http://unqlite.org/c_api.html)将是必备的参考指南。

如有任何问题，访问[支持页面](http://unqlite.org/support.html)了解更多信息。

## 扩展阅读


## 祝大家玩的开心

