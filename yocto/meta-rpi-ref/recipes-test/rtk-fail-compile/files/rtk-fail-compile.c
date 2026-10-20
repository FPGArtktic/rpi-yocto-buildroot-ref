/* Does not compile on purpose: `count` is never declared. */
#include <stdio.h>

int main(void)
{
    for (int i = 0; i < 3; i++)
        count += i;
    printf("%d\n", count);
    return 0;
}
