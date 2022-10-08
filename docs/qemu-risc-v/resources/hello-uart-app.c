#define VIRT_UART0 0x10000000

volatile unsigned int *const UART_PTR = (unsigned int *)VIRT_UART0;

void print(const char *str)
{
    while (*str != '\0')
    {
        *UART_PTR = (unsigned int)(*str);
        str++;
    }
}

void main()
{
    print("Hello, World!\n");
    print("Press <Ctrl+a> then <x> to exit.\n");
}