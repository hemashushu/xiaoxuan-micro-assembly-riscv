#include "libmath.h"
#include "libprint.h"

void bare_main()
{
    int a = 3;
    int b = 5;
    int m = add(a, b);
    int n = add10(a);

    print_string("Hello world!\n");
    print_int(m);
    print_char('\n');
    print_int(n);
    print_char('\n');
}