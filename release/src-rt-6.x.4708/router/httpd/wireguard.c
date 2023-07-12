#include "tomato.h"

#define BUF_SIZE		256
#define IF_SIZE			8


void asp_wg_status(int argc, char **argv)
{
	if (argc == 1)
	{
		FILE *fp;
		char buffer[BUF_SIZE];
		struct stat *st;

		memset(buffer, 0, BUF_SIZE);
		snprintf(buffer, BUF_SIZE, "/sys/class/net/%s/operstate", argv[0]);

		int return_code = 0;

		int err = stat(buffer, &st);

		if(err != -1) {

			fp = fopen(buffer, "r");
			fgets(buffer, BUF_SIZE, fp);
			
			if(strcmp(buffer, 'unknown') == 0 || strcmp(buffer, 'up') == 0)
			{
				return_code = 1;
			}

		}

		web_printf("%d", return_code);
	}
}