#include "tomato.h"

#define LOGMSG_DISABLE	DISABLE_SYSLOG_OSM
#define LOGMSG_NVDEBUG	"wg_debug"

#define BUF_SIZE		64


void asp_wgstat(int argc, char **argv)
{
	if (argc == 1)
		web_printf("%d", wg_status(argv[0]));
}

int wg_status(char *iface)
{
	FILE *fp;
	char buffer[BUF_SIZE];
	struct stat *st;

	memset(buffer, 0, BUF_SIZE);
	snprintf(buffer, BUF_SIZE, "/sys/class/net/%s/operstate", iface);

	int status = 0;

	int err = stat(buffer, &st);

	if(err != -1) {
		logmsg(LOG_INFO, "***WG*** opening wireguard operstate at %s", buffer);
		fp = fopen(buffer, "r");
		fgets(buffer, BUF_SIZE, fp);
		buffer[strcspn(buffer, "\n")] = 0;
		logmsg(LOG_INFO, "***WG*** found wireguard operstate: %s", buffer);
		if(strcmp(&buffer, "unknown") == 0 || strcmp(&buffer, "up") == 0)
		{
			status = 1;
		}
		fclose(fp);
	}
	logmsg(LOG_INFO, "***WG*** return code is %d", status);
	return status;
	logmsg(LOG_INFO, "***WG*** We got to the end!");
}