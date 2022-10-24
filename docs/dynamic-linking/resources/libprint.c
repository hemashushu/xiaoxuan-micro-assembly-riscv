#include "put_char.h"

void print_char(char c)
{
    put_char((unsigned int)c);
}

void print_string(const char *str)
{
    while (*str != '\0')
    {
        print_char(*str);
        str++;
    }
}

void itoa(int num, char *buf, int len)
{
    for (int i = 0; i < len; i++)
    {
        int mod = num % 10;
        buf[i] = mod + '0';
        num = num / 10;
        if (num == 0)
            break;
    }

    int count = 1;
    while (buf[count] != '\0')
    {
        count++;
    }

    // reverse
    for (int i = 0; i < count / 2; i++)
    {
        int j = count - i - 1;
        char t = buf[i];
        buf[i] = buf[j];
        buf[j] = t;
    }
}

void print_int(int i)
{
    char s[21];
    itoa(i, s, 21);
    print_string(s);
}
