#include "tomato.h"

#define BUF_SIZE		256
#define IF_SIZE			8


void asp_wg_status(int argc, char **argv)
{
	if (argc == 1)
	{
		char buffer[BUF_SIZE];

		memset(buffer, 0, BUF_SIZE);
		snprintf(buffer, BUF_SIZE, "/sys/class/net/%s/operstate", argv[0]);

		web_printf("%d", eval("/bin/grep", "-Fxq", "'down'", buffer) != 0);
	}
}