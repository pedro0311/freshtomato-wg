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
<script src="isup.jsz"></script>
<script src="isup.js"></script>
<script src="tomato.js"></script>
<script src="wireguard.js"></script>

<script>

//	<% nvram("wan_ipaddr,lan_ifname,lan_ipaddr,lan_netmask,lan1_ifname,lan1_ipaddr,lan1_netmask,lan2_ifname,lan2_ipaddr,lan2_netmask,lan3_ifname,lan3_ipaddr,lan3_netmask,wg_server1_eas,wg_server1_file,wg_server1_ip,wg_server1_nm,wg_server1_ka,wg_server1_port,wg_server1_key,wg_server1_endpoint,wg_server1_lan,wg_server1_lan0,wg_server1_lan1,wg_server1_lan2,wg_server1_lan3,wg_server1_rgw,wg_server1_peer1_name,wg_server1_peer1_key,wg_server1_peer1_psk,wg_server1_peer1_ip,wg_server1_peer1_nm,wg_server1_peer1_ka,wg_server1_peer1_ep,wg_server1_peer2_name,wg_server1_peer2_key,wg_server1_peer2_psk,wg_server1_peer2_ip,wg_server1_peer2_nm,wg_server1_peer2_ka,wg_server1_peer2_ep,wg_server1_peer3_name,wg_server1_peer3_key,wg_server1_peer3_psk,wg_server1_peer3_ip,wg_server1_peer3_nm,wg_server1_peer3_ka,wg_server1_peer3_ep"); %>

var cprefix = 'vpn_wg_server1';
var changed = 0;
var serviceType = 'wgserver1';
var peer_count = 3;

function updatePeerKey(num) {
	var keys = window.wireguard.generateKeypair();
	E('_wg_server1_peer'+num+'_key').value = keys.privateKey;
	E('_wg_server1_peer'+num+'_pubkey').value = keys.publicKey;
}

function updateServerKey() {
	var keys = window.wireguard.generateKeypair();
	E('_wg_server1_key').value = keys.privateKey;
	E('_wg_server1_pubkey').value = keys.publicKey;
}

function updatePeerPSK(num) {
	E('_wg_server1_peer'+num+'_psk').value = window.wireguard.generatePresharedKey();
}

function generatePeerConfig(num) {
	var privatekey_peer = eval(`nvram.wg_server1_peer${num}_key`);
	var publickey_server = window.wireguard.generatePublicKey(nvram.wg_server1_key);
	var presharedkey = eval(`nvram.wg_server1_peer${num}_psk`);
	var name = eval(`nvram.wg_server1_peer${num}_name`);

	var address = eval(`nvram.wg_server1_peer${num}_ip`) + '/' + eval(`nvram.wg_server1_peer${num}_nm`);
	var port = nvram.wg_server1_port;
	var endpoint;
	var keepalive_server = nvram.wg_server1_ka;

	if (changed) {
		alert('Changes have been made. You need to save before continue!');
		return;
	}

	/* build endpoint */
	if (nvram.wg_server1_endpoint != "") {
		endpoint = nvram.wg_server1_endpoint + ":" + port;
	}
	else {
		endpoint = nvram.wan_ipaddr + ":" + port;
	}

	/* build allowed ips for router peer */
	var allowed_ips;
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
		for(let i = 0; i <= 3; ++i){
			if (eval(`nvram.wg_server1_lan${i}` != "")) {
				t = (i == 0 ? '' : i);
				allowed_ips += ', ';
				allowed_ips += eval(`nvram.lan${t}_ipaddr`);
				allowed_ips += '/';
				allowed_ips += netmaskToCIDR(eval(`nvram.lan${t}_netmask`));
			}
		}
	}

	var content = [];
	content.push("[Interface]\n");

	if (name != "") {
		content.push(`#Name = ${name}\n`);
	}

	content.push(
		`Address = ${address}\n`,
		`ListenPort = ${port}\n`,
		`PrivateKey = ${privatekey_peer}\n`,
		"\n",
		"[Peer]\n",
		"#Name = Router\n",
		`PublicKey = ${publickey_server}\n`
	);
	if (presharedkey != "") {
		content.push(`PresharedKey = ${presharedkey}\n`);
	}
	PresharedKey = 
	content.push(
		`AllowedIPs = ${allowed_ips}\n`,
		`Endpoint = ${endpoint}\n`
	);
	if (keepalive_server != "0") {
		content.push(`PersistentKeepalive = ${keepalive_server}\n`);
	}

	/* add other peers if applicable */
	for(let i = 1; i <= peer_count; ++i) {
		var peer_key = eval(`nvram.wg_server1_peer${i}_key`);
		if (peer_key != "" && privatekey_peer != peer_key) {

			content.push(
				"\n",
				"[Peer]\n",
			);

			var peer_name = eval(`nvram.wg_server1_peer${i}_name`)
			if (peer_name != "") {
				content.push(`#Name = ${peer_name}\n`,);
			}

			var peer_pubkey = window.wireguard.generatePublicKey(peer_key);
			content.push(`PublicKey = ${peer_pubkey}\n`,);

			var peer_psk = eval(`nvram.wg_server1_peer${i}_psk`);
			if (peer_psk != "") {
				content.push(`PresharedKey = ${peer_psk}\n`,);
			}

			var peer_allowed_ips = eval(`nvram.wg_server1_peer${i}_ip`) + '/' + eval(`nvram.wg_server1_peer${i}_nm`);
			content.push(`AllowedIPs = ${peer_allowed_ips}\n`,);

			var peer_keepalive = eval(`nvram.wg_server1_peer${i}_ka`);
			if (peer_keepalive != "0") {
				content.push(`PersistentKeepalive = ${peer_keepalive}\n`,);
			}

			var peer_endpoint = eval(`nvram.wg_server1_peer${i}_ep`);
			if (peer_endpoint != "0") {
				content.push(`Endpoint = ${peer_endpoint}\n`);
			}
		}
	}


	const link = document.createElement("a");
	const file = new Blob(content, { type: 'text/plain' });
	link.href = URL.createObjectURL(file);
	link.download = `client${num}.conf`;
	link.click();
	URL.revokeObjectURL(link.href);
}

function netmaskToCIDR(mask) {
	var maskNodes = mask.match(/(\d+)/g);
	var cidr = 0;
	for(var i in maskNodes) {
		cidr += (((maskNodes[i] >>> 0).toString(2)).match(/1/g) || []).length;
	}
	return cidr;
}

function verifyFields(focused, quiet) {
	var ok = 1;

	E('_wg_server1_pubkey').disabled = true;
	var pubkey = window.wireguard.generatePublicKey(E('_wg_server1_key').value);
	if(pubkey == false) {
		pubkey = "";
	}
	E(`_wg_server1_pubkey`).value = pubkey;

	for (let i = 1; i <= peer_count; i++) {
		E(`_wg_server1_peer${i}_pubkey`).disabled = true;
		pubkey = window.wireguard.generatePublicKey(E(`_wg_server1_peer${i}_key`).value);
		if(pubkey == false) {
			pubkey = "";
		}
		E(`_wg_server1_peer${i}_pubkey`).value = pubkey;
	}

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

	var fom = E('t_fom');

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
	<script>
		for (let i = 1; i <= peer_count; i++) {
			createFieldTable('', [
				{ title: `Peer ${i} Name`, name: `wg_server1_peer${i}_name`, type: 'text', maxlen: 32, size: 32, value: eval(`nvram.wg_server1_peer${i}_name`)},
				{ title: `Peer ${i} Private Key`, multi: [
					{ title: '', name: `wg_server1_peer${i}_key`, type: 'text', maxlen: 44, size: 44, value: eval(`nvram.wg_server1_peer${i}_key`) },
					{ title: '', custom: '<input type="button" value="Generate" onclick="updatePeerKey('+(i)+')" id="wg_keygen_peer'+i+'_button">' },
				] },
				{ title: `Peer ${i} Public Key`, name: `wg_server1_peer${i}_pubkey`, type: 'text', maxlen: 44, size: 44, disabled: ""},
				{ title: `Peer ${i} Preshared Key`, multi: [
					{ title: '', name: `wg_server1_peer${i}_psk`, type: 'text', maxlen: 44, size: 44, value: eval(`nvram.wg_server1_peer${i}_psk`) },
					{ title: '', custom: '<input type="button" value="Generate" onclick="updatePeerPSK('+(i)+')" id="wg_keygen_peer'+i+'_psk_button">' },
				] },
				{ title: 'IP/Netmask', multi: [
					{ name: `wg_server1_peer${i}_ip`, type: 'text', maxlen: 15, size: 17, value: eval(`nvram.wg_server1_peer${i}_ip`) },
					{ name: `wg_server1_peer${i}_nm`, type: 'text', maxlen: 2, size: 4, value: eval(`nvram.wg_server1_peer${i}_nm`) }
				] },
				{ title: `Keepalive to Peer ${i}`, name: `wg_server1_peer${i}_ka`, type: 'text', maxlen: 2, size: 4, value: eval(`nvram.wg_server1_peer${i}_ka`)},
				{ title: `Peer ${i} Custom Endpoint`, name: `wg_server1_peer${i}_ep`, type: 'text', maxlen: 64, size: 64, value: eval(`nvram.wg_server1_peer${i}_ep`)},
				{ title: '', custom: '<input type="button" value="Download Config" onclick="generatePeerConfig('+i+')" id="wg_config_peer'+i+'_button">' }
			]);
		}
	</script>
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
