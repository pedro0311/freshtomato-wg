#include "rc.h"

/* needed by logmsg() */
#define LOGMSG_DISABLE	DISABLE_SYSLOG_OSM
#define LOGMSG_NVDEBUG	"wireguard_debug"

#define BUF_SIZE		256
#define IF_SIZE			8
#define PEER_COUNT		3


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
	if (wg_set_iface_addr(iface, buffer)) {
		stop_wireguard(unit);
		return;
	}

	/* set interface port */
	if (wg_set_iface_port(iface, nvram_get("wg_server_port"))) {
		stop_wireguard(unit);
		return;
	}

	/* set interface private key */
	if (wg_set_iface_privkey(iface, nvram_get("wg_server_privkey"))) {
		stop_wireguard(unit);
		return;
	}

	/* add stored peers */
	int i = 1;
	while(i <= PEER_COUNT)
	{
		if (getNVRAMVar("wg_server_peer%d_key", i)[0] != '\0' &&
			getNVRAMVar("wg_server_peer%d_ip", i)[0] != '\0' &&
			getNVRAMVar("wg_server_peer%d_nm", i)[0] != '\0')
		{
			memset(buffer, 0, BUF_SIZE);
			snprintf(buffer, BUF_SIZE, "%s/%s", getNVRAMVar("wg_server_peer%d_ip", i), getNVRAMVar("wg_server_peer%d_nm", i));
			wg_add_peer_privkey(iface, getNVRAMVar("wg_server_peer%d_key", i), buffer);
		}
		
		i += 1;
	}

	/* bring up interface */
	if (wg_set_iface_up(iface)) {
		stop_wireguard(unit);
		return;
	}

	/* set iptables rules */
	if (wg_set_iptables(iface, nvram_get("wg_server_port"))) {
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

	/* remove iptables rules */
	wg_remove_iptables(iface, nvram_get("wg_server_port"));
}

int wg_create_iface(char *iface)
{
	FILE *fp;

    /* Make sure module is loaded */
    modprobe("wireguard");
	f_wait_exists("/sys/module/wireguard", 5);
	
	/* enable IPv6 forwarding */
	if(fp = fopen("/proc/sys/net/ipv6/conf/all/forwarding", "w"))
	{
		fprintf(fp, "1");
		logmsg(LOG_DEBUG, "Enabled forwarding for IPv6");
	}
	else
	{
		logmsg(LOG_WARNING, "Unable to enable forwarding for IPv6!");
	}
    
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

int wg_set_iface_addr(char *iface, char *addr)
{
    /* Flush wireguard interface */
	/*
	if (eval("/usr/sbin/ip", "addr", "flush", "dev", iface)) {
		logmsg(LOG_WARNING, "unable to flush wireguard interface %s!", iface);
		return -1;
	}
	else {
		logmsg(LOG_DEBUG, "successfully flushed wireguard interface %s!", iface);
	} */

    /* Set wireguard interface address/netmask */
	if (eval("/usr/sbin/ip", "addr", "add", addr, "dev", iface)) {
		logmsg(LOG_WARNING, "unable to set wireguard interface %s address to %s!", iface, addr);
		return -1;
	}
	else {
		logmsg(LOG_DEBUG, "wireguard interface %s has had its address set to %s", iface, addr);
	}

    return 0;
}

int wg_set_iface_port(char *iface, char *port)
{
	if (eval("/usr/sbin/wg", "set", iface, "listen-port", port)){
		logmsg(LOG_WARNING, "unable to set wireguard interface %s port to %s!", iface, port);
		return -1;
	}
	else {
		logmsg(LOG_DEBUG, "wireguard interface %s has had its port set to %s", iface, port);
	}

	return 0;
}

int wg_set_iface_privkey(char *iface, char* privkey)
{
	FILE *fp;
	char buffer[BUF_SIZE];

	/* write private key to file */
	memset(buffer, 0, BUF_SIZE);
	snprintf(buffer, BUF_SIZE, "/tmp/%s.privkey", iface);

	fp = fopen(buffer, "w");
	fprintf(fp, privkey);
	fclose(fp);

	chmod(buffer, (S_IRUSR | S_IWUSR));
	
	/* set interface private key */
	if (eval("/usr/sbin/wg", "set", iface, "private-key", buffer)){
		logmsg(LOG_WARNING, "unable to set wireguard interface %s private key!", iface);
		return -1;
	}
	else {
		logmsg(LOG_DEBUG, "wireguard interface %s has had its private key set", iface);
	}

	/* remove file for security */
	remove(buffer);

	return 0;
}

int wg_set_iface_up(char *iface)
{
	if (eval("/usr/sbin/ip", "link", "set", "up", "dev", iface)){
		logmsg(LOG_WARNING, "unable to bring up wireguard interface %s!", iface);
		return -1;
	}
	else {
		logmsg(LOG_DEBUG, "wireguard interface %s has been brought up", iface);
	}

	return 0;
}

int wg_add_peer(char *iface, char *pubkey, char *allowed_ips)
{

	if (eval("/usr/sbin/wg", "set", iface, "peer", pubkey, "allowed-ips", allowed_ips)){
		logmsg(LOG_WARNING, "unable to add peer %s to wireguard interface %s!", iface, pubkey);
		return -1;
	}
	else {
		logmsg(LOG_DEBUG, "peer %s has been added to wireguard interface %s", iface, pubkey);
	}

	return 0;
}

int wg_add_peer_privkey(char *iface, char *privkey, char *allowed_ips)
{
	char pubkey[WG_KEY_LEN_BASE64];
	memset(pubkey, 0, WG_KEY_LEN_BASE64);

	wg_pubkey(privkey, pubkey);

	return wg_add_peer(iface, pubkey, allowed_ips);
}

int wg_set_iptables(char *iface, char *port)
{
	char buffer[64];

	/* open specified port for device */
	memset(buffer, 0, sizeof(buffer));
	snprintf(buffer, sizeof(buffer), "\".*ACCEPT.*udp.dpt.%s$\"", port);

	if (eval("/usr/sbin/iptables", "-nvL", "INPUT", "|", "grep", "-q", buffer)){
		if(eval("/usr/sbin/iptables", "-A", "INPUT", "-p", "udp", "--dport", port, "-j", "ACCEPT")) {
			logmsg(LOG_WARNING, "unable to open port %s for wireguard interface %s using iptables!", port, iface);
			return -1;
		}
	}

	/* accept incoming traffic on device */
	memset(buffer, 0, sizeof(buffer));
	snprintf(buffer, sizeof(buffer), "\".*ACCEPT.*all.*%s\"", port);

	if (eval("/usr/sbin/iptables", "-nvL", "INPUT", "|", "grep", "-q", buffer)){
		if(eval("/usr/sbin/iptables", "-A", "INPUT", "-i", iface, "-j", "ACCEPT")) {
			logmsg(LOG_WARNING, "unable to accept incoming traffic on wireguard interface %s!", iface);
			return -1;
		}
	}

	/* accept forward traffic on device */
	memset(buffer, 0, sizeof(buffer));
	snprintf(buffer, sizeof(buffer), "\".*ACCEPT.*all.*%s\"", port);

	if (eval("/usr/sbin/iptables", "-nvL", "FORWARD", "|", "grep", "-q", buffer)){
		if(eval("/usr/sbin/iptables", "-A", "FORWARD", "-i", iface, "-j", "ACCEPT")) {
			logmsg(LOG_WARNING, "unable to accept forward traffic on wireguard interface %s!", iface);
			return -1;
		}
	}

	return 0;
}

int wg_remove_iptables(char *iface, char *port)
{
	char buffer[64];

	/* drop rule for specified port for device */
	memset(buffer, 0, sizeof(buffer));
	snprintf(buffer, sizeof(buffer), "\".*ACCEPT.*udp.dpt.%s$\"", port);

	if (eval("/usr/sbin/iptables", "-nvL", "INPUT", "|", "grep", "-q", buffer)){
		if(eval("/usr/sbin/iptables", "-D", "INPUT", "-p", "udp", "--dport", port, "-j", "ACCEPT")) {
			logmsg(LOG_WARNING, "unable to drop rule for port %s for wireguard interface %s using iptables!", port, iface);
			return -1;
		}
	}

	/* drop rule for incoming traffic on device */
	memset(buffer, 0, sizeof(buffer));
	snprintf(buffer, sizeof(buffer), "\".*ACCEPT.*all.*%s\"", port);

	if (eval("/usr/sbin/iptables", "-nvL", "INPUT", "|", "grep", "-q", buffer)){
		if(eval("/usr/sbin/iptables", "-D", "INPUT", "-i", iface, "-j", "ACCEPT")) {
			logmsg(LOG_WARNING, "unable to drop rule for incoming traffic on wireguard interface %s!", iface);
			return -1;
		}
	}

	/* Accept forward traffic on device */
	memset(buffer, 0, sizeof(buffer));
	snprintf(buffer, sizeof(buffer), "\".*ACCEPT.*all.*%s\"", port);

	if (eval("/usr/sbin/iptables", "-nvL", "FORWARD", "|", "grep", "-q", buffer)){
		if(eval("/usr/sbin/iptables", "-D", "FORWARD", "-i", iface, "-j", "ACCEPT")) {
			logmsg(LOG_WARNING, "unable to drop rule for forward traffic on wireguard interface %s!", iface);
			return -1;
		}
	}
}

int wg_remove_peer(char *iface, char *pubkey)
{
	if (eval("/usr/sbin/wg", "set", iface, "peer", pubkey, "remove")){
		logmsg(LOG_WARNING, "unable to remove peer %s from wireguard interface %s!", iface, pubkey);
		return -1;
	}
	else {
		logmsg(LOG_DEBUG, "peer %s has been removed from wireguard interface %s", iface, pubkey);
	}

	return 0;
}

int wg_remove_peer_privkey(char *iface, char *privkey)
{
	char pubkey[WG_KEY_LEN_BASE64];
	memset(pubkey, 0, WG_KEY_LEN_BASE64);

	wg_pubkey(privkey, pubkey);

	return wg_remove_peer(iface, pubkey);
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

void start_wg_eas()
{
	if (nvram_get_int("wg_server_eas"))
	{
		start_wireguard(1);
	}
}

int wg_pubkey(char *privkey, char *pubkey)
{
	uint8_t pubkey_raw[WG_KEY_LEN] __attribute__((aligned(sizeof(uintptr_t))));

	curve25519_generate_public(pubkey_raw, privkey);
	key_to_base64(pubkey, pubkey_raw);

	return 0
}