#include "rc.h"

/* needed by logmsg() */
#define LOGMSG_DISABLE	DISABLE_SYSLOG_OSM
#define LOGMSG_NVDEBUG	"wireguard_debug"

#define WG_DIR		"/var/lib/wg"

#define BUF_SIZE		256
#define IF_SIZE			8
#define PEER_COUNT		3

#define WG_INTERFACE_MAX	3

void start_wg_eas()
{
	int unit;

	for (unit = 1; unit <= WG_INTERFACE_MAX; unit ++) {
		if (atoi(getNVRAMVar("wg_iface%d_eas", unit)) == 1) {
			start_wireguard(unit);
		}
	}
	
}

void start_wireguard(int unit)
{
	char *nv, *nvp, *b;
	char *name, *key, *psk, *ip, *ka, *aip, *ep;
    char iface[IF_SIZE];
    char buffer[BUF_SIZE];

	/* set up directories for later use */
	wg_setup_dirs();

    /* Determine interface */
	memset(iface, 0, IF_SIZE);
	snprintf(iface, IF_SIZE, "wg%d", unit);

	/* check if file is specified */
	if(getNVRAMVar("wg_iface%d_file", unit)[0] != '\0') {
		wg_load_iface(iface, getNVRAMVar("wg_iface%d_file", unit));
	}
	else {

		/* create interface */
		if (wg_create_iface(iface)) {
			stop_wireguard(unit);
			return;
		}

		/* set interface address */
		if (wg_set_iface_addr(iface, getNVRAMVar("wg_iface%d_ip", unit))) {
			stop_wireguard(unit);
			return;
		}

		/* set interface port */
		if (wg_set_iface_port(iface, getNVRAMVar("wg_iface%d_port", unit))) {
			stop_wireguard(unit);
			return;
		}

		/* set interface private key */
		if (wg_set_iface_privkey(iface, getNVRAMVar("wg_iface%d_key", unit))) {
			stop_wireguard(unit);
			return;
		}

		if (wg_set_iface_fwmark(iface, getNVRAMVar("wg_iface%d_fwmark", unit))) {
			stop_wireguard(unit);
			return;
		}

		/* add stored peers */
		nvp = nv = strdup(getNVRAMVar("wg_iface%d_peers", unit));
		if (nv){
			while ((b = strsep(&nvp, ">")) != NULL) {

				if (vstrsep(b, "<", &name, &ep, &key, &psk, &ip, &aip, &ka) < 7)
					continue;
				
				/* build peer allowed ips */
				memset(buffer, 0, BUF_SIZE);
				if (aip[0] == '\0') {
					snprintf(buffer, BUF_SIZE, "%s", ip);
				}
				else {
					snprintf(buffer, BUF_SIZE, "%s,%s", ip, aip);
				}

				/* add peer to interface */
				wg_add_peer(iface, key, buffer, psk, ka, ep);

			}
		}
	}

	/* bring up interface */
	if (wg_set_iface_up(iface)) {
		stop_wireguard(unit);
		return;
	}

	/* set iptables rules */
	if (wg_set_iptables(iface, getNVRAMVar("wg_iface%d_port", unit))) {
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
	wg_remove_iptables(iface, getNVRAMVar("wg_iface%d_port", unit));
}

void wg_setup_dirs() {

	FILE *fp;
	char buffer[64];

	/* main dir */
	if(mkdir_if_none(WG_DIR)) {
		chmod(WG_DIR, (S_IRUSR | S_IWUSR | S_IXUSR));
	}

	/* script dir */
	if(mkdir_if_none(WG_DIR"/scripts")) {
		chmod(WG_DIR"/scripts", (S_IRUSR | S_IWUSR | S_IXUSR));
	}

	/* keys dir */
	if(mkdir_if_none(WG_DIR"/keys")) {
		chmod(WG_DIR"/keys", (S_IRUSR | S_IWUSR | S_IXUSR));
	}

	/* script to enable IPv6 forwarding */
	if(!(f_exists(WG_DIR"/scripts/ipv6-forward.sh"))){
		if((fp = fopen(WG_DIR"/scripts/ipv6-forward.sh", "w"))) {
			fprintf(fp, "#!/bin/sh\n"
						"/bin/echo 1 > /proc/sys/net/ipv6/conf/all/forwarding\n");
			fclose(fp);
			chmod(WG_DIR"/scripts/ipv6-forward.sh", (S_IRUSR | S_IWUSR | S_IXUSR));
		}
	}
	
	/* script to generate public keys from private keys */
	if(!(f_exists(WG_DIR"/scripts/pubkey.sh"))){
		if((fp = fopen(WG_DIR"/scripts/pubkey.sh", "w"))) {
			fprintf(fp, "#!/bin/sh\n"
						"/bin/echo \"$1\" | /usr/sbin/wg pubkey > \"$2\"\n");
			fclose(fp);
			chmod(WG_DIR"/scripts/pubkey.sh", (S_IRUSR | S_IWUSR | S_IXUSR));
		}
	}

	/* script to add iptable rules for wireguard device */
	if(!(f_exists(WG_DIR"/scripts/fw-add.sh"))){
		if((fp = fopen(WG_DIR"/scripts/fw-add.sh", "w"))) {
			fprintf(fp, "#!/bin/sh\n"
						"if [ $(nvram get ctf_disable) -eq 0 ]; then\n"
						"    iptables -t mangle -nvL PREROUTING | grep -q '.*MARK.*all.*$2.*0x1/0x7' || iptables -t mangle -A PREROUTING -i $2 -j MARK --set-mark 0x01/0x7\n"
						"fi\n"
						"/usr/sbin/iptables -nvL INPUT | grep -q \".*ACCEPT.*udp.dpt.$1$\" || /usr/sbin/iptables -A INPUT -p udp --dport \"$1\" -j ACCEPT\n"
						"/usr/sbin/iptables -nvL INPUT | grep -q \".*ACCEPT.*all.*$2\" || /usr/sbin/iptables -A INPUT -i \"$2\" -j ACCEPT\n"
						"/usr/sbin/iptables -nvL FORWARD | grep -q \".*ACCEPT.*all.*$2\" || /usr/sbin/iptables -A FORWARD -i \"$2\" -j ACCEPT\n");
			fclose(fp);
			chmod(WG_DIR"/scripts/fw-add.sh", (S_IRUSR | S_IWUSR | S_IXUSR));
		}
	}

	/* script to remove iptable rules for wireguard device */
	if(!(f_exists(WG_DIR"/scripts/fw-del.sh"))){
		if((fp = fopen(WG_DIR"/scripts/fw-del.sh", "w"))) {
			fprintf(fp, "#!/bin/sh\n"
						"/usr/sbin/iptables -t mangle -nvL PREROUTING | grep -q '.*MARK.*all.*$2.*0x1/0x7' && iptables -t mangle -D PREROUTING -i $2 -j MARK --set-mark 0x01/0x7\n"
						"fi\n"
						"/usr/sbin/iptables -nvL INPUT | grep -q \".*ACCEPT.*udp.dpt.$1$\" && /usr/sbin/iptables -D INPUT -p udp --dport \"$1\" -j ACCEPT\n"
						"/usr/sbin/iptables -nvL INPUT | grep -q \".*ACCEPT.*all.*$2\" && /usr/sbin/iptables -D INPUT -i \"$2\" -j ACCEPT\n"
						"/usr/sbin/iptables -nvL FORWARD | grep -q \".*ACCEPT.*all.*$2\" && /usr/sbin/iptables -D FORWARD -i \"$2\" -j ACCEPT\n");
			fclose(fp);
			chmod(WG_DIR"/scripts/fw-del.sh", (S_IRUSR | S_IWUSR | S_IXUSR));
		}
	}

	/* script to dump wireguard interface to file */
	if(!(f_exists(WG_DIR"/scripts/wg-save.sh"))){
		if((fp = fopen(WG_DIR"/scripts/wg-save.sh", "w"))) {
			fprintf(fp, "#!/bin/sh\n"
						"/usr/sbin/wg showconf $1 > $2\n"
						"IPandNM=$(/usr/sbin/ip addr show $1 | grep inet | awk '{ print $2 }')\n"
						"sed -i \"2i Address = $IPandNM\" $2\n");
			fclose(fp);
			chmod(WG_DIR"/scripts/wg-save.sh", (S_IRUSR | S_IWUSR | S_IXUSR));
		}
	}

	/* script to load wireguard interface from file */
	if(!(f_exists(WG_DIR"/scripts/wg-load.sh"))){
		if((fp = fopen(WG_DIR"/scripts/wg-load.sh", "w"))) {
			fprintf(fp, "#!/bin/sh\n"
						"TEMPFILE="WG_DIR"/$1-temp.conf\n"
						"IPandNM=$(/bin/grep \"Address = \" \"$2\" | awk '{ print $3 }')\n"
						"ip link add $1 type wireguard\n"
                        "ip addr add $IPandNM dev $1\n"
                        "/bin/sed '/Address = .*/d' $2 > $TEMPFILE\n"
                        "/usr/sbin/wg setconf $1 $TEMPFILE\n"
                        "rm $TEMPFILE\n");
			fclose(fp);
			chmod(WG_DIR"/scripts/wg-load.sh", (S_IRUSR | S_IWUSR | S_IXUSR));
		}
	}

}

void wg_cleanup_dirs() {
	eval("rm", "-rf", WG_DIR);
}

int wg_create_iface(char *iface)
{
	FILE *fp;

	/* enable IPv6 forwarding */
	if(eval("/bin/sh", WG_DIR"/scripts/ipv6-forward.sh")) {
		logmsg(LOG_WARNING, "Unable to enable forwarding for IPv6!");
	}

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

int wg_flush_iface_addr(char *iface)
{
	if (eval("/usr/sbin/ip", "addr", "flush", "dev", iface)) {
		logmsg(LOG_WARNING, "unable to flush wireguard interface %s!", iface);
		return -1;
	}
	else {
		logmsg(LOG_DEBUG, "successfully flushed wireguard interface %s!", iface);
	}

	return 0;
}

int wg_set_iface_addr(char *iface, char *addr)
{
    /* Flush all addresses from interface */
	// wg_flush_iface_addr(iface)

    /* Set wireguard interface address */
	if(wg_add_iface_addr(iface, addr)) {
		return -1;
	}

    return 0;
}

int wg_add_iface_addr(char *iface, char *addr)
{
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
	snprintf(buffer, BUF_SIZE, WG_DIR"/keys/%s", iface);

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

int wg_set_iface_fwmark(char *iface, char* fwmark)
{
	int buffer_size = 10;
	char buffer[buffer_size];
	memset(buffer, 0, buffer_size);

	if (fwmark[0] == '0' && fwmark[1] == '\0') {
		snprintf(buffer, buffer_size, "%s", fwmark);
	}
	else {
		snprintf(buffer, buffer_size, "0x%s", fwmark);
	}


	if (eval("/usr/sbin/wg", "set", iface, "fwmark", fwmark)){
		logmsg(LOG_WARNING, "unable to set wireguard interface %s fwmark to %s!", iface, fwmark);
		return -1;
	}
	else {
		logmsg(LOG_DEBUG, "wireguard interface %s has had its private key set", iface, fwmark);
	}

	return 0;
}

int wg_set_iface_up(char *iface)
{
	int retry = 0;

	while (retry < 5) {
		if (!(eval("/sbin/ifconfig", iface, "up"))) {
			logmsg(LOG_DEBUG, "wireguard interface %s has been brought up", iface);
			return 0;
		}
		else if (retry < 4) {
			logmsg(LOG_WARNING, "unable to bring up wireguard interface %s, retrying...", iface);
			sleep(3);
		}
		retry += 1;
	}

	logmsg(LOG_WARNING, "unable to bring up wireguard interface %s!", iface);
	return -1;
}

int wg_add_peer(char *iface, char *pubkey, char *allowed_ips, char *presharedkey, char *keepalive, char *endpoint)
{
	/* set allowed ips / create peer */
	wg_set_peer_allowed_ips(iface, pubkey, allowed_ips);

	/* set peer psk */
	if (presharedkey[0] != '\0') {
		wg_set_peer_psk(iface, pubkey, presharedkey);
	}

	/* set peer keepalive */
	if (atoi(keepalive) > 0) {
		wg_set_peer_keepalive(iface, pubkey, keepalive);
	}

	/* set peer endpoint */
	if (endpoint[0] != '\0') {
		wg_set_peer_endpoint(iface, pubkey, endpoint);
	}

	return 0;
}

int wg_set_peer_allowed_ips(char *iface, char *pubkey, char *allowed_ips)
{
	if (eval("/usr/sbin/wg", "set", iface, "peer", pubkey, "allowed-ips", allowed_ips)){
		logmsg(LOG_WARNING, "unable to add peer %s to wireguard interface %s!", pubkey, iface);
		return -1;
	}
	else {
		logmsg(LOG_DEBUG, "peer %s for wireguard interface %s has had its allowed ips set to %s", pubkey, iface, allowed_ips);
	}

	return 0;
}

int wg_set_peer_psk(char *iface, char *pubkey, char *presharedkey)
{
	FILE *fp;
	char buffer[BUF_SIZE];
	int err = 0;

	/* write preshared key to file */
	memset(buffer, 0, BUF_SIZE);
	snprintf(buffer, BUF_SIZE, WG_DIR"/keys/%s.psk", iface);

	fp = fopen(buffer, "w");
	fprintf(fp, presharedkey);
	fclose(fp);

	if (eval("/usr/sbin/wg", "set", iface, "peer", pubkey, "preshared-key", buffer)){
		logmsg(LOG_WARNING, "unable to add preshared key to peer %s on wireguard interface %s!", pubkey, iface);
		err = -1;
	}
	else {
		logmsg(LOG_DEBUG, "preshared key has been added to peer %s on wireguard interface %s", pubkey, iface);
	}

	/* remove file for security */
	remove(buffer);
	return err;
}

int wg_set_peer_keepalive(char *iface, char *pubkey, char *keepalive)
{
	if (eval("/usr/sbin/wg", "set", iface, "peer", pubkey, "persistent-keepalive", keepalive)){
		logmsg(LOG_WARNING, "unable to add persistent-keepalive of %s to peer %s on wireguard interface %s!", keepalive, pubkey, iface);
		return -1;
	}
	else {
		logmsg(LOG_DEBUG, "persistent-keepalive of %s has been added to peer %s on wireguard interface %s", keepalive, pubkey, iface);
	}

	return 0;
}

int wg_set_peer_endpoint(char *iface, char *pubkey, char *endpoint)
{
	if (eval("/usr/sbin/wg", "set", iface, "peer", pubkey, "endpoint", endpoint)){
		logmsg(LOG_WARNING, "unable to add endpoint of %s to peer %s on wireguard interface %s!", endpoint, pubkey, iface);
		return -1;
	}
	else {
		logmsg(LOG_DEBUG, "endpoint of %s has been added to peer %s on wireguard interface %s", endpoint, pubkey, iface);
	}

	return 0;
}

int wg_add_peer_privkey(char *iface, char *privkey, char *allowed_ips, char *presharedkey, char *keepalive, char *endpoint)
{
	char pubkey[64];

	memset(pubkey, 0, sizeof(pubkey));
	wg_pubkey(privkey, pubkey);

	return wg_add_peer(iface, pubkey, allowed_ips, presharedkey, keepalive, endpoint);
}

int wg_set_iptables(char *iface, char *port)
{
	if(eval("/bin/sh", WG_DIR"/scripts/fw-add.sh", port, iface)){
		logmsg(LOG_WARNING, "Unable to add iptable rules for wireguard interface %s on port %s!", iface, port);
	}
	else{
		logmsg(LOG_DEBUG, "Iptable rules have been added for wireguard interface %s on port %s", iface, port);
	}

	return 0;
}

int wg_remove_iptables(char *iface, char *port)
{
	eval("/bin/sh", WG_DIR"/scripts/fw-del.sh", port, iface);
	logmsg(LOG_DEBUG, "Iptable rules have been removed for wireguard interface %s on port %s", iface, port);

	return 0;
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
	char pubkey[64];
	memset(pubkey, 0, sizeof(pubkey));

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

int wg_pubkey(char *privkey, char *pubkey)
{
	FILE *fp;

	if(eval("/bin/sh", WG_DIR"/scripts/pubkey.sh", privkey, WG_DIR"/keys/wgclient.pub")) {
		logmsg(LOG_WARNING, "Unable to generate public key for wireguard!");
	}
	
	if((fp = fopen(WG_DIR"/keys/wgclient.pub", "r")) != NULL) {
		fgets(pubkey, 64, fp);
		pubkey[strcspn(pubkey, "\n")] = 0;
		fclose(fp);
	}
	else{
		logmsg(LOG_WARNING, "Could not open public key file!");
	}

	remove(WG_DIR"/keys/wgclient.pub");
}

int wg_save_iface(char *iface, char *file)
{
	/* write wg config to file */
	if(eval("/bin/sh", WG_DIR"/scripts/wg-save.sh", iface, file)) {
		logmsg(LOG_WARNING, "Unable to save wireguard interface %s to file %s!", iface, file);
		return -1;
	}
	else {
		logmsg(LOG_DEBUG, "Saved wireguard interface %s to file %s", iface, file);
	}

	return 0;
}

int wg_load_iface(char *iface, char *file)
{
	/* write wg config to file */
	if(eval("/bin/sh", WG_DIR"/scripts/wg-load.sh", iface, file)) {
		logmsg(LOG_WARNING, "Unable to load wireguard interface %s from file %s!", iface, file);
		return -1;
	}
	else {
		logmsg(LOG_DEBUG, "Loaded wireguard interface %s from file %s", iface, file);
	}

	return 0;
}
