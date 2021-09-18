#ifndef H_HYDRAQUILL_HANDY
#define H_HYDRAQUILL_HANDY

#include <stddef.h>

size_t min(size_t x, size_t y);
size_t max(size_t x, size_t y);

#define MIN(x, y) min(x, y)
#define MAX(x, y) max(x, y)

#endif
