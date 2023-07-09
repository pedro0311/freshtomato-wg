#include "tomato.h"
#include "httpd.h"

#define BUF_SIZE		256
#define IF_SIZE			8

int wg_status(char *iface)
{
	char buffer[BUF_SIZE];

	memset(buffer, 0, BUF_SIZE);
	snprintf(buffer, BUF_SIZE, "grep -Fxq 'up' /sys/class/net/%s/operstate", iface);
	
	return eval(buffer);
}

int asp_wg_status(int argc, char **argv)
{
	if (argc == 1)
	{
		return wg_status(argv[0]);
	}
}