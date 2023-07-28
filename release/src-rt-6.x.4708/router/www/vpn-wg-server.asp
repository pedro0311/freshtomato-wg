<!DOCTYPE html>
<!--
	FreshTomato GUI
	Copyright (C) 2023 pedro
	https://freshtomato.org/

	For use with FreshTomato Firmware only.
	No part of this file may be used without permission.
-->
<html lang="en-GB">
<head>
<meta http-equiv="content-type" content="text/html;charset=utf-8">
<meta name="robots" content="noindex,nofollow">
<title>[<% ident(); %>] Wireguard Server</title>
<link rel="stylesheet" type="text/css" href="tomato.css">
<% css(); %>
<style>
.co2, .co3, .co7 {
	max-width: 150px;
	white-space: nowrap;
	overflow: hidden;
	text-overflow: ellipsis;
}

.co5, .co6 {
	width: 24px;
  	white-space: nowrap;
  	overflow: hidden;
  	text-overflow: ellipsis;
}
</style>
<script src="isup.jsz"></script>
<script src="isup.js"></script>
<script src="tomato.js"></script>
<script src="wireguard.js"></script>
<script src="interfaces.js"></script>
<script>

//	<% nvram("wan_ipaddr,lan_ifname,lan_ipaddr,lan_netmask,lan1_ifname,lan1_ipaddr,lan1_netmask,lan2_ifname,lan2_ipaddr,lan2_netmask,lan3_ifname,lan3_ipaddr,lan3_netmask,wg_server1_eas,wg_server1_file,wg_server1_ip,wg_server1_nm,wg_server1_ka,wg_server1_port,wg_server1_key,wg_server1_endpoint,wg_server1_lan,wg_server1_lan0,wg_server1_lan1,wg_server1_lan2,wg_server1_lan3,wg_server1_rgw,wg_server1_peers"); %>

var cprefix = 'vpn_wg_server1';
var changed = 0;
var serviceType = 'wgserver1';

var peers = new TomatoGrid();

peers.resetNewEditor = function() {
	var f = fields.getAll(this.newEditor);
	f[0].value = '';
	f[1].value = '';
	f[2].value = '';
	f[3].value = '';
	f[4].value = '';
	f[5].value = '';
	f[6].value = '';
	ferror.clearAll(fields.getAll(this.newEditor));
}

peers.setup = function() {
	this.init('peers-grid', '', 50, [
		{ type: 'text', maxlen: 32 },
		{ type: 'text', maxlen: 44 },
		{ type: 'text', maxlen: 44 },
		{ type: 'text', maxlen: 100 },
		{ type: 'text', maxlen: 3 },
		{ type: 'text', maxlen: 3 },
		{ type: 'text', maxlen: 64 },
	]);
	this.headerSet(['Name','Public Key','Preshared Key','IP','NM','KA','Endpoint']);
	var nv = nvram.wg_server1_peers.split('>');
	for (var i = 0; i < nv.length; ++i) {
		var t = nv[i].split('<');
		if (t.length == 7) {
			this.insertData(-1, t);
		}
	}
	peers.showNewEditor();
}

peers.rpDel = function(e) {
	changed = 1;
	e = PR(e);
	TGO(e).moving = null;
	e.parentNode.removeChild(e);
	this.recolor();
	this.resort();
	this.rpHide();
}

peers.verifyFields = function(row, quiet) {
	var f;
	if (row.nodeType != null)
		f = fields.getAll(row);
	else
		f = row;
	changed = 1;
	var ok = 1;

	if (!window.wireguard.validateBase64Key(f[1].value)) {
		ferror.set(f[1], 'A valid public key is required', quiet || !ok);
		ok = 0;
	}
	else
		ferror.clear(f[1]);

	if (f[2].value != '' && !window.wireguard.validateBase64Key(f[2].value)) {
		ferror.set(f[2], 'Preshared key is invalid', quiet || !ok);
		ok = 0;
	}
	else
		ferror.clear(f[2]);

	if (!v_ip(f[3], quiet || !ok))
		ok = 0;
	else
		ferror.clear(f[3]);

	if (!v_range(f[4], quiet || !ok, 0, 32))
		ok = 0;
	else 
		ferror.clear(f[4]);

	if (!v_range(f[5], quiet || !ok, 0, 128))
		ok = 0;
	else 
		ferror.clear(f[5]);

	return ok;
}

function updateServerKey() {
	var keys = window.wireguard.generateKeypair();
	E('_wg_server1_key').value = keys.privateKey;
	E('_wg_server1_pubkey').value = keys.publicKey;
}

function generateClient() {

	if (changed) {
		alert('Changes have been made. You need to save before continue!');
		return;
	}
	
	var psk = "";
	if (E('_f_wg_server1_peer_psk').checked)
		psk = window.wireguard.generatePresharedKey();

	/* retrieve existing IPs of server/clients to calculate new ip */
	var existing_ips = parsePeers(nvram.wg_server1_peers);
	existing_ips = existing_ips.map(x => x.ip);
	existing_ips.push(nvram.wg_server1_ip)

	/* calculate ip of new peer */
	var nm = CIDRToNetmask(nvram.wg_server1_nm);
	var network = getNetworkAddress(nvram.wg_server1_ip, nm);
	var ip = E('_f_wg_server1_peer_ip').value;

	if (ip == "") {

		var limit = 2 ** (32 - parseInt(nvram.wg_server1_nm, 10));
		for (var i = 1; i < limit; i++) {

			var temp_ip = getAddress(ntoa(i) , network);
			var end = temp_ip.split('.').slice(0, -1);

			if (end == '255' || end == '0')
				continue;

			if (existing_ips.includes(temp_ip))
				continue;

			ip = temp_ip;
			break;
		}

		if (ip == "") {
			alert('Could not generate an IP for the client');
			return;
		}
	}

	/* generate peer */
	var keys = window.wireguard.generateKeypair();
	var data = [
		E('_f_wg_server1_peer_name').value,
		keys.publicKey,
		psk,
		ip,
		E('_f_wg_server1_peer_nm').value,
		E('_f_wg_server1_peer_ka').value,
		E('_f_wg_server1_peer_ep').value
	];
	
	/* add peer to grid */
	changed = 1;
	peers.insertData(-1, data);
	peers.disableNewEditor(false);
	peers.resetNewEditor();

	/* generate config */
	data[1] = keys.privateKey;
	var content = generatePeerConfig(data);
	downloadConfig(content);

}

function generatePeerConfig(data) {
	
	var netmask = nvram.wg_server1_nm;
	var port = nvram.wg_server1_port;
	var content = [];

	/* build interface section */
	content.push("[Interface]\n");

	if (data[0] != "") {
		content.push(`#Name = ${name}\n`);
	}

	content.push(
		`Address = ${data[3]}/${netmask}\n`,
		`ListenPort = ${port}\n`,
		`PrivateKey = ${data[1]}\n`,
	);

	/* build router peer */
	var publickey_server = window.wireguard.generatePublicKey(nvram.wg_server1_key);
	var keepalive_server = nvram.wg_server1_ka;
	var endpoint;
	var allowed_ips;

	/* build endpoint */
	if (nvram.wg_server1_endpoint != "") {
		endpoint = nvram.wg_server1_endpoint + ":" + nvram.wg_server1_port;
	}
	else {
		endpoint = nvram.wan_ipaddr + ":" + nvram.wg_server1_port;
	}

	/* build allowed ips for router peer */
	if (nvram.wg_server1_rgw == "1") {
		allowed_ips = "0.0.0.0/0"
	}
	else {
		var netmask;
		if (nvram.wg_server1_lan == "1") {
			netmask = `/${nvram.wg_server1_nm}`;
		}
		else {
			netmask = "/32";
		}
		allowed_ips = nvram.wg_server1_ip + netmask;
		for(let i = 0; i <= 3; i++){
			if (eval(`nvram.wg_server1_lan${i}` == "1")) {
				let t = (i == 0 ? '' : i);
				allowed_ips += ', ';
				allowed_ips += eval(`nvram.lan${t}_ipaddr`);
				allowed_ips += '/';
				allowed_ips += netmaskToCIDR(eval(`nvram.lan${t}_netmask`));
			}
		}
	}

	/* populate router peer */
	content.push(
		"\n",
		"[Peer]\n",
		"#Name = Router\n",
		`PublicKey = ${publickey_server}\n`
	);

	if (data[2] != "") {
		content.push(`PresharedKey = ${data[2]}\n`);
	}

	content.push(
		`AllowedIPs = ${allowed_ips}\n`,
		`Endpoint = ${endpoint}\n`
	);

	if (keepalive_server != "0") {
		content.push(`PersistentKeepalive = ${keepalive_server}\n`);
	}

	/* add remaining peers to config */
	if (nvram.wg_server1_lan == "1") {
		var server_peers = parsePeers(nvram.wg_server1_peers)
		
		for (var i = 0; i < server_peers.length; ++i) {
			var peer = server_peers[i]

			if (peer.key == window.wireguard.generatePublicKey(data[1])) {
				continue;
			}

			content.push(
				"\n",
				"[Peer]\n",
			);

			if (peer.name != "") {
				content.push(`#Name = ${peer.name}\n`,);
			}

			content.push(`PublicKey = ${peer.key}\n`,);

			if (peer.psk != "") {
				content.push(`PresharedKey = ${peer.psk}\n`,);
			}

			content.push(`AllowedIPs = ${peer.ip}/${peer.netmask}\n`,);

			if (peer.keepalive != "0") {
				content.push(`PersistentKeepalive = ${peer.keepalive}\n`,);
			}

			
			if (peer.endpoint != "") {
					content.push(`Endpoint = ${peer.endpoint}\n`);
				}
		}
	}

	return content;
}

function downloadConfig(content) {
	const link = document.createElement("a");
	const file = new Blob(content, { type: 'text/plain' });
	link.href = URL.createObjectURL(file);
	link.download = 'client.conf';
	link.click();
	URL.revokeObjectURL(link.href);
}

function parsePeers(peers_string) {
	var nv = peers_string.split('>');
	var output = [];
	for (var i = 0; i < nv.length; ++i) {
		if (nv[i] != "") {
			var t = nv[i].split('<');
			if (t.length == 7) {
				var peer = {};
				peer.name = t[0];
				peer.key = t[1];
				peer.psk = t[2];
				peer.ip = t[3];
				peer.netmask = t[4];
				peer.keepalive = t[5];
				peer.endpoint = t[6];
				output.push(peer);
			}
		}
	}
	return output;
}

function netmaskToCIDR(mask) {
	var maskNodes = mask.match(/(\d+)/g);
	var cidr = 0;
	for(var i in maskNodes) {
		cidr += (((maskNodes[i] >>> 0).toString(2)).match(/1/g) || []).length;
	}
	return cidr;
}

function CIDRToNetmask(bitCount) {
  var mask=[];
  for(var i=0;i<4;i++) {
    var n = Math.min(bitCount, 8);
    mask.push(256 - Math.pow(2, 8-n));
    bitCount -= n;
  }
  return mask.join('.');
}

function verifyFields(focused, quiet) {
	var ok = 1;

	E('_wg_server1_pubkey').disabled = true;
	var pubkey = window.wireguard.generatePublicKey(E('_wg_server1_key').value);
	if(pubkey == false) {
		pubkey = "";
	}
	E(`_wg_server1_pubkey`).value = pubkey;

	for (let i = 0; i <= 3; ++i) {
		t = (i == 0 ? '' : i);

		if (eval('nvram.lan'+t+'_ifname.length') < 1) {
			E('_f_wg_server1_lan'+t).checked = 0;
			E('_f_wg_server1_lan'+t).disabled = 1;
		}
	}

	return ok;
}

function save_pre() {
	if (!verifyFields(null, 0))
		return 0;
	return 1;
}

function save(nomsg) {
	save_pre();
	if (!nomsg) show(); /* update '_service' field first */

	var data = peers.getAllData();
	var s = '';
	for (var i = 0; i < data.length; ++i)
		s += data[i].join('<')+'>';

	var fom = E('t_fom');
	fom.wg_server1_peers.value = s;
	nvram.wg_server1_peers = s;

	fom.wg_server1_eas.value = fom._f_wg_server1_eas.checked ? 1 : 0;
	fom.wg_server1_lan.value = fom._f_wg_server1_lan.checked ? 1 : 0;
	fom.wg_server1_lan0.value = fom._f_wg_server1_lan0.checked ? 1 : 0;
	fom.wg_server1_lan1.value = fom._f_wg_server1_lan1.checked ? 1 : 0;
	fom.wg_server1_lan2.value = fom._f_wg_server1_lan2.checked ? 1 : 0;
	fom.wg_server1_lan3.value = fom._f_wg_server1_lan3.checked ? 1 : 0;
	fom.wg_server1_rgw.value = fom._f_wg_server1_rgw.checked ? 1 : 0;

	form.submit(fom, 1);

	changed = 0;
}

function earlyInit() {
	show();
	verifyFields(null, 1);
}

function init() {
	eventHandler();
	var c;
	if (((c = cookie.get(cprefix+'_notes_vis')) != null) && (c == '1'))
		toggleVisibility(cprefix, 'notes');
	eventHandler();
	up.initPage(250, 5);
}
</script>
</head>

<body onload="init()">
<form id="t_fom" method="post" action="tomato.cgi">
<table id="container">
<tr><td colspan="2" id="header">
	<div class="title">FreshTomato</div>
	<div class="version">Version <% version(); %> on <% nv("t_model_name"); %></div>
</td></tr>
<tr id="body"><td id="navi"><script>navi()</script></td>
<td id="content">
<div id="ident"><% ident(); %> | <script>wikiLink();</script></div>

<!-- / / / -->

<input type="hidden" name="_service" value="">
<input type="hidden" name="wg_server1_eas">
<input type="hidden" name="wg_server1_lan">
<input type="hidden" name="wg_server1_lan0">
<input type="hidden" name="wg_server1_lan1">
<input type="hidden" name="wg_server1_lan2">
<input type="hidden" name="wg_server1_lan3">
<input type="hidden" name="wg_server1_rgw">
<input type="hidden" name="wg_server1_peers">

<!-- / / / -->

<div class="section-title">Wireguard Server</div>
<div class="section">
	<script>
		createFieldTable('', [
			{ title: 'Enable on Start', name: 'f_wg_server1_eas', type: 'checkbox', value: nvram.wg_server1_eas == '1' },
			{ title: 'File to load interface from', name: 'wg_server1_file', type: 'text', maxlen: 64, size: 64, value: nvram.wg_server1_file },
			{ title: 'Port', name: 'wg_server1_port', type: 'text', maxlen: 5, size: 10, value: nvram.wg_server1_port },
			{ title: 'Private Key', multi: [
				{ title: '', name: 'wg_server1_key', type: 'text', maxlen: 44, size: 44, value: nvram.wg_server1_key },
				{ title: '', custom: '<input type="button" value="Generate" onclick="updateServerKey()" id="wg_server1_keygen">' },
			] },
			{ title: 'Public Key', name: 'wg_server1_pubkey', type: 'text', maxlen: 44, size: 44, disabled: ""},
			{ title: 'IP/Netmask', multi: [
				{ name: 'wg_server1_ip', type: 'text', maxlen: 15, size: 17, value: nvram.wg_server1_ip },
				{ name: 'wg_server1_nm', type: 'text', maxlen: 2, size: 4, value: nvram.wg_server1_nm }
			] },
			{ title: 'Keepalive to Server', name: 'wg_server1_ka', type: 'text', maxlen: 2, size: 4, value: nvram.wg_server1_ka},
			{ title: 'Custom Endpoint', name: 'wg_server1_endpoint', type: 'text', maxlen: 64, size: 64, value: nvram.wg_server1_endpoint},
			{ title: 'Allow peers to communicate', name: 'f_wg_server1_lan', type: 'checkbox', value: nvram.wg_server1_lan == '1'},
			{ title: 'Push LAN0 (br0) to peers', name: 'f_wg_server1_lan0', type: 'checkbox', value: nvram.wg_server1_lan0 == '1' },
			{ title: 'Push LAN1 (br1) to peers', name: 'f_wg_server1_lan1', type: 'checkbox', value: nvram.wg_server1_lan1 == '1' },
			{ title: 'Push LAN2 (br2) to peers', name: 'f_wg_server1_lan2', type: 'checkbox', value: nvram.wg_server1_lan2 == '1' },
			{ title: 'Push LAN3 (br3) to peers', name: 'f_wg_server1_lan3', type: 'checkbox', value: nvram.wg_server1_lan3 == '1' },
			{ title: 'Forward all peer traffic', name: 'f_wg_server1_rgw', type: 'checkbox', value: nvram.wg_server1_rgw == '1' },
		]);
	</script>
	<div class="vpn-start-stop"><input type="button" value="" onclick="" id="_wgserver1_button">&nbsp; <img src="spin.gif" alt="" id="spin"></div>
</div>
<div class="section-title">Wireguard Peers</div>
<div class="section">
<div class="tomato-grid" id="peers-grid"></div>
	<script>
		peers.setup();
	</script>
</div>
<div class="section-title">Client Generation</div>
<div class="section">
	<script>
		createFieldTable('', [
			{ title: 'Peer Name', name: 'f_wg_server1_peer_name', type: 'text', maxlen: 32, size: 32, value: 0},
			{ title: 'Generate PSK', name: 'f_wg_server1_peer_psk', type: 'checkbox', value: true },
			{ title: 'IP (optional)', name: 'f_wg_server1_peer_ip', type: 'text', maxlen: 64, size: 64},
			{ title: 'Netmask', name: 'f_wg_server1_peer_nm', type: 'text', maxlen: 2, size: 4, value: "32"},
			{ title: 'Keepalive to peer', name: 'f_wg_server1_peer_ka', type: 'text', maxlen: 2, size: 4, value: "0"},
			{ title: 'Custom Endpoint', name: 'f_wg_server1_peer_ep', type: 'text', maxlen: 64, size: 64},
		]);
	</script>
	<input type="button" value="Generate Client Config" onclick="generateClient()" id="wg_server1_peer_gen">
</div>

<!-- / / / -->

<div class="section-title">Notes <small><i><a href='javascript:toggleVisibility(cprefix,"notes");'><span id="sesdiv_notes_showhide">(Show)</span></a></i></small></div>
<div class="section" id="sesdiv_notes" style="display:none">
	<ul>
		<li><b>Enable on Start</b> - Enabling this will start the wireguard device when the router starts up.</li>
		<li><b>Local IP Address</b> - Address to be used for the local wireguard device.</li>
		<li><b>Subnet/Netmask</b> - Remote IP addresses to be used on the tunnelled PPP links (max 6).</li>
	</ul>
	<br>
	<ul>
		<li><b>Other relevant notes/hints:</b></li>
		<li style="list-style:none">
			<ul>
				<li>Try to avoid any conflicts and/or overlaps between the address ranges configured/available for DHCP and VPN clients on your local networks.</li>
				<li>You can add your own ip-up/ip-down scripts which are executed after those built by GUI - relevant NVRAM variables are "pptpd_ipup_script" / "pptpd_ipdown_script".</li>
			</ul>
		</li>
	</ul>
</div>

<!-- / / / -->

<div id="footer">
    <span id="footer-msg"></span>
	<input type="button" value="Save" id="save-button" onclick="save()">
	<input type="button" value="Cancel" id="cancel-button" onclick="reloadPage();">
</div>

</td></tr>
</table>
</form>
<script>earlyInit();</script>
</body>
</html>
