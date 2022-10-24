#include <stdlib.h>
#include <unistd.h>

int main(){
    char *buf = "Hello world!\n";
    write(1, buf, 13);
    exit(10);
}