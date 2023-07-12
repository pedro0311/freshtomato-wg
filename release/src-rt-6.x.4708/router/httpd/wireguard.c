#include "tomato.h"

#define LOGMSG_DISABLE	DISABLE_SYSLOG_OSM
#define LOGMSG_NVDEBUG	"wg_debug"

#define BUF_SIZE		64
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
			logmsg(LOG_INFO, "***WG*** opening wireguard operstate at %s", buffer);
			fp = fopen(buffer, "r");
			fgets(buffer, BUF_SIZE, fp);
			logmsg(LOG_INFO, "***WG*** found wireguard operstate: %s", buffer);
			if(strncmp_ex(buffer, 'unknown') == 0 || strncmp_ex(buffer, 'up') == 0)
			{
				return_code = 1;
			}
			logmsg(LOG_INFO, "***WG*** closing wireguard operstate at %s", buffer);
			fclose(fp);

		}

		web_printf("%d", return_code);
	}
}