#include "squid_parser.h"



int main(int argc, char *argv[])
{
    SquidParser parser("/etc/squid/squid.conf");
    parser.parse();
    return 0;
}
