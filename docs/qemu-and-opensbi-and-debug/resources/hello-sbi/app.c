#include "sbi-base.h"
#include "libprint.h"

void bare_main()
{
    print_string("Hello SBI!\n");

    int version = sbi_get_spec_version();
    int minor = version & 0xffffff;       // get low 24-bits
    int major = version >> 24;            // get high 7-bits (bit 31 is 0)

    print_string("SBI specification version, major: ");
    print_int(major);
    print_string(", minor: ");
    print_int(minor);
    print_string(".\n");

    int id = sbi_get_impl_id();
    print_string("SBI implementation ID: ");
    print_int(id);
    print_string(".\n");
}