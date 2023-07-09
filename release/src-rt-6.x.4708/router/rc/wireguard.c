#include "rc.h"

/* needed by logmsg() */
#define LOGMSG_DISABLE	DISABLE_SYSLOG_OSM
#define LOGMSG_NVDEBUG	"wireguard_debug"

#define BUF_SIZE		256
#define IF_SIZE			8


void start_wireguard(int unit)
{
    char iface[IF_SIZE];
    char buffer[BUF_SIZE];

    /* Determine interface */
	memset(iface, 0, IF_SIZE);
	snprintf(iface, IF_SIZE, "wg%d", unit);

    /* create interface */
	if (wg_create_iface(iface)) {
		stop_wireguard(unit);
		return;
	}

	/* generate wireguard device address/subnet */
	memset(buffer, 0, BUF_SIZE);
	snprintf(buffer, BUF_SIZE, "%s/%s", nvram_get("wg_server_localip"), nvram_get("wg_server_nm"));

    /* set interface address and netmask */
	if (wg_set_iface(iface, buffer)) {
		stop_wireguard(unit);
		return;
	}
}

void stop_wireguard(int unit)
{
	char iface[IF_SIZE];
    char buffer[BUF_SIZE];

    /* Determine interface */
	memset(iface, 0, IF_SIZE);
	snprintf(iface, IF_SIZE, "wg%d", unit);

	/* Remove interface */
    wg_remove_iface(iface);
}

int wg_create_iface(char *iface)
{
    /* Make sure module is loaded */
    modprobe("wireguard");
	f_wait_exists("/sys/module/wireguard", 5);
    
    /* Create wireguard interface */
	if (eval("/usr/sbin/ip", "link", "add", "dev", iface, "type", "wireguard")) {
		logmsg(LOG_WARNING, "unable to create wireguard interface %s!", iface);
		return -1;
	}
	else {
		logmsg(LOG_DEBUG, "wireguard interface %s has been created", iface);

	}

    return 0;
}

int wg_set_iface(char *iface, char *addr)
{
    /* Create wireguard interface */
	if (eval("/usr/sbin/ip", "addr", "flush", "dev", iface)) {
		logmsg(LOG_WARNING, "unable to flush wireguard interface %s!", iface);
		return -1;
	}
	else {
		logmsg(LOG_DEBUG, "successfully flushed wireguard interface %s!", iface);
	}

    /* Set wireguard interface address/netmask */
	if (eval("/usr/sbin/ip", "addr", "add", addr, "dev", iface)) {
		logmsg(LOG_WARNING, "unable to set wireguard interface %s address to %s!", iface, addr);
		return -1;
	}
	else {
		logmsg(LOG_DEBUG, "wireguard interface %s has had it's address set to %s", iface, addr);
	}

    return 0;
}

int wg_remove_iface(char *iface)
{
    /* Create wireguard interface */
	if (eval("/usr/sbin/ip", "link", "delete", iface)) {
		logmsg(LOG_WARNING, "unable to delete wireguard interface %s!", iface);
		return -1;
	}
	else {
		logmsg(LOG_DEBUG, "wireguard interface %s has been deleted", iface);
	}

    return 0;
}