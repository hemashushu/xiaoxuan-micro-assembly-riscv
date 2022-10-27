#define VIRT_UART0 0x10000000

volatile unsigned int *const VIRT_UART0_PTR = (unsigned int *)VIRT_UART0;

void put_char(int c)
{
    *VIRT_UART0_PTR = c;
}