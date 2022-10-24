extern int e_number;
int e_add(int);

int test_get_number()
{
    return e_number;
}

int test_set_number()
{
    e_number++;
    return e_number;
}

int test_add(int a)
{
    return e_add(a);
}

int test_add_twice(int a)
{
    return e_add(a) + e_add(a);
}

int main()
{
    int m = test_get_number();
    int n = test_set_number();
    int x = test_add(10);
    int y = test_add_twice(30);
    return m + n + x + y;
}
