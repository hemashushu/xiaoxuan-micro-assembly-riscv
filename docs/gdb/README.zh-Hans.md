# GDB 程序调试器

GDB 全称 GNU Debugger，是一个 CLI 界面的程序调试器。通过调试器可以逐步运行程序，设置断点，查看内存和局部变量的值等，是开发程序过程中必不可少的工具。

虽然现在有图形化的程序调试器，也有轻量级的调试器（比如在 VS Code 当中给程序设置断点再运行就会进入调试状态），不过有时只能通过 GDB 来调试，比如通过虚拟机调试内核时；另外有些场合下使用 GDB 调试效率更高或者更灵活，比如通过 OpenOCD 来调试微控制器时。

> GDB 的详细手册请参阅 [Debugging with GDB](https://sourceware.org/gdb/onlinedocs/gdb/index.html)

<!-- @import "[TOC]" {cmd="toc" depthFrom=2 depthTo=6 orderedList=false} -->

<!-- code_chunk_output -->

- [TODO](#todo)
  - [`start`](#start)
  - [`list`](#list)
  - [`info`](#info)
  - [`next`](#next)
  - [`print`](#print)
  - [`finish`](#finish)

<!-- /code_chunk_output -->

## TODO

`$ gdb app.ext.static.out`

因为我们在编译时添加了 `-g` 参数，而且源代码和可执行文件的路径都没有更改，所以 GDB 能够正确加载调试信息以及定位到我们的源代码。

如无意外，应该能看到如下信息：

```text
GNU gdb (Debian 12.1-3) 12.1
...
Reading symbols from app.ext.static.out...
(gdb)
```

此时会进入 GDB 命令界面，我们是通过命令来控制 GDB 的。

### `start`

运行 `start` 命令将会启动程序然后停留在 `main` 函数的第一行代码，显示的信息大致如下：

```text
(gdb) start
Temporary breakpoint 1 at 0x106da: file app.ext.c, line 27.
Starting program: /home/yang/.../app.ext.static.out

Temporary breakpoint 1, main () at app.ext.c:27
27          int m = test_get_number();
```

> 也可以使用 `run` 命令（或者简写为 `r`）启动程序，不过需要提前设置断点，否则它会直接运行程序直到结束。`run` 命令也用于 _重新开始_ 运行程序。如果想启动程序并在第一条指令（即入口）中断，可以使用 `starti` 命令。

### `list`

此时输入 `list` 命令（或者简写为 `l`），GDB 会依次列出源代码，`list` 命令后面也可以添加行号或者函数名称，用于列出指定行或者函数的源代码：

```text
(gdb) list main
25      int main()
26      {
27          int m = test_get_number();
28          int n = test_set_number();
29          int x = test_add(10);
30          int y = test_add_twice(30);
(gdb)
```

`list` 命令一次只显示有限几条语句，对于剩下来的可以重复使用不加参数的 `list` 命令列出，也可以使用 `list -` 和 `list +` 控制滚动的方向。

有时调试一段时间之后，可能不清楚当前的位置，可以使用 `frame` 命令显示当前停留的位置：

```text
(gdb) frame
#0  main () at app.ext.c:27
27          int m = test_get_number();
(gdb)
```

> 使用 `where` 和 `bt` 命令也有相同的作用。

当然也可以直接查看 `PC` 寄存器的值，`PC` 寄存器的值是当前程序执行的位置：

```text
(gdb) i r $pc
pc             0x106da  0x106da <main+8>
(gdb)
```

### `info`

输入 `info`（或者简写为 `i`）可以查看局部变量或者寄存器等信息，例如 `i locals` 能列出当前栈帧的所有局部变量的值：

```text
(gdb) i locals
m = 0
n = 345440
x = 0
y = 466312
(gdb)
```

因为这 4 个变量还未赋值，所以初始值是不确定的（可认为是随机的）。

### `next`

然后输入 `next`（或者简写为 `n`）命令执行下一条语句（其实就是当前显示的语句）：

> 也可以使用 `step`（或者简写为 `s`）命令，当遇到函数调用时，`s` 命令会进入函数内部，而 `n` 命令则不会。

```text
(gdb) n
28          int n = test_set_number();
(gdb)
```

执行完一条语句之后，立即会显示下一条语句的内容，如上所示，下一条即将被执行的是第 28 行

> 注意这行信息表示将要执行的语句，而不是刚刚执行完的语句。

### `print`

使用 `print`（或者简写为 `p`）命令可以显示一个变量或者表达式的值：

```text
(gdb) p m
$1 = 11
(gdb) p m+100
$2 = 111
(gdb)
```

### `finish`

此时调试器停留在第 28 行，也就是调用 `test_set_number` 函数这样，此时 GDB 显示如下：

```text
28          int n = test_set_number()
```

如果不确定当前位置，可以使用 `frame` 命令显示，确定当前位置为 28 行，这次我们跟踪进入函数 `test_set_number` 内部，所以输入 `s` 命令，结果如下：

```text
(gdb) s
test_set_number () at app.ext.c:11
11          e_number++;
(gdb)
```

连续输入 3 次 `n` 命令，函数 `test_set_number` 会执行完毕，并且返回到 `main` 函数的第 29 行：

```text
(gdb) n
12          return e_number;
(gdb) n
13      }
(gdb) n
main () at app.ext.c:29
29          int x = test_add(10);
(gdb) p n
$1 = 12
(gdb)
```

如果想直接执行完当前函数，并返回到调用者那里，可以使用 `finish`（或者简写为 `fin`） 命令。比如当程序运行到 11 行 `e_number++;` 时，输入 `fin` 命令的结果如下：

```text
(gdb) fin
Run till exit from #0  test_set_number () at app.ext.c:11
0x00000000000106e8 in main () at app.ext.c:28
28          int n = test_set_number();
Value returned is $1 = 12
(gdb) where
#0  0x00000000000106e8 in main () at app.ext.c:28
(gdb)
```

