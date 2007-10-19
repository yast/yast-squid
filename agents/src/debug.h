#ifndef _DEBUG_H_
#define _DEBUG_H_

#ifndef NDEBUG
#include <iostream>
#define DBG(exp) \
    std::cerr << exp << std::endl; \
    std::cerr.flush()
#define DBG2(exp) \
    std::cerr << exp; \
    std::cerr.flush()
#else
#define DBG(exp)
#endif

#endif
