#include <stdio.h>

int add(int, int);
int dbl(int);

int main()
{
    int a = 3;
    int b = 5;
    int m = add(a, b);
    int n = dbl(a);
    printf("m=%d, n=%d", m, n);
    return 0;
}