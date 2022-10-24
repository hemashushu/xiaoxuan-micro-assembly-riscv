#define VIRT_UART0 0x10000000

volatile unsigned int *const UART_PTR = (unsigned int *)VIRT_UART0;

void print_string(const char *str)
{
    while (*str != '\0')
    {
        *UART_PTR = (unsigned int)(*str);
        str++;
    }
}

void mymain()
{
    print_string("Hello world!\n");
    print_string("Press <Ctrl+a> then <x> to exit.\n");
}