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

//	<% nvram("wan_ipaddr,wg_server_eas,wg_server_localip,wg_server_sn,wg_server_nm,wg_server_port,wg_server_privkey,wg_server_peer1_key,wg_server_peer1_ip,wg_server_peer1_nm,wg_server_peer2_key,wg_server_peer2_ip,wg_server_peer2_nm,wg_server_peer3_key,wg_server_peer3_ip,wg_server_peer3_nm"); %>

var cprefix = 'vpn_wireguard';
var changed = 0;
var serviceType = 'wireguard';
var peer_count = 3;

function updatePeerKey(num) {
	var keys = window.wireguard.generateKeypair();
	E('_wg_server_peer'+num+'_key').value = keys.privateKey;
	E('_wg_server_peer'+num+'_pubkey').value = keys.publicKey;
}

function generatePeerConfig(num) {
	var privatekey_peer = E('_wg_server_peer'+num+'_key').value;
	var publickey_server = window.wireguard.generatePublicKey(E(`_wg_server_privkey`).value);

	var address = E('_wg_server_peer'+num+'_ip').value + '/' + E('_wg_server_peer'+num+'_nm').value;
	var port = E('_wg_server_port').value;
	var endpoint = nvram.wan_ipaddr + ":" + port;
	var allowed_ips = E('_wg_server_localip').value + "/32";

	const link = document.createElement("a");
	const file = new Blob([
		"[Interface]\n",
		`Address = ${address}\n`,
		`ListenPort = ${port}\n`,
		`PrivateKey = ${privatekey_peer}\n`,
		"\n",
		"[Peer]\n",
		`PublicKey = ${publickey_server}\n`,
		`AllowedIPs = ${allowed_ips}\n`,
		`Endpoint = ${endpoint}\n`,
	], { type: 'text/plain' });
	link.href = URL.createObjectURL(file);
	link.download = `client${num}.conf`;
	link.click();
	URL.revokeObjectURL(link.href);
}

function verifyFields(focused, quiet) {
	var ok = 1;
	var wireguard = wireguard;
	for (let i = 1; i <= peer_count; i++) {
		E(`_wg_server_peer${i}_pubkey`).disabled = true;
		var pubkey = window.wireguard.generatePublicKey(E(`_wg_server_peer${i}_key`).value);
		if(pubkey == false) {
			pubkey = "";
		}
		E(`_wg_server_peer${i}_pubkey`).value = pubkey;
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

	fom.wg_server_eas.value = fom._f_wg_server_eas.checked ? 1 : 0;

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
<input type="hidden" name="wg_server_eas">

<!-- / / / -->

<div class="section-title">Wireguard Server</div>
<div class="section">
	<script>
		createFieldTable('', [
			{ title: 'Enable on Start', name: 'f_wg_server_eas', type: 'checkbox', value: nvram.wg_server_eas == '1' },
			{ title: 'Port', name: 'wg_server_port', type: 'text', maxlen: 5, size: 10, value: nvram.wg_server_port },
			{ title: 'Private Key', name: 'wg_server_privkey', type: 'text', maxlen: 44, size: 44, value: nvram.wg_server_privkey },
			{ title: 'Local IP', name: 'wg_server_localip', type: 'text', maxlen: 15, size: 17, value: nvram.wg_server_localip },
			{ title: 'Subnet/Netmask', multi: [
				{ name: 'wg_server_sn', type: 'text', maxlen: 15, size: 17, value: nvram.wg_server_sn },
				{ name: 'wg_server_nm', type: 'text', maxlen: 2, size: 4, value: nvram.wg_server_nm }
			] },
		]);
	</script>
	<div class="vpn-start-stop"><input type="button" value="" onclick="" id="_wireguard_button">&nbsp; <img src="spin.gif" alt="" id="spin"></div>
</div>
<div class="section-title">Wireguard Peers</div>
<div class="section">
	<script>
		for (let i = 1; i <= peer_count; i++) {
			createFieldTable('', [
				{ title: `Peer ${i} Private Key`, name: `wg_server_peer${i}_key`, type: 'text', maxlen: 44, size: 44, value: eval(`nvram.wg_server_peer${i}_key`) },
				{ title: `Peer ${i} Public Key`, name: `wg_server_peer${i}_pubkey`, type: 'text', maxlen: 44, size: 44, disabled: ""},
				{ title: 'IP/Netmask', multi: [
					{ name: 'wg_server_peer'+i+'_ip', type: 'text', maxlen: 15, size: 17, value: eval('nvram.wg_server_peer'+i+'_ip') },
					{ name: 'wg_server_peer'+i+'_nm', type: 'text', maxlen: 2, size: 4, value: eval('nvram.wg_server_peer'+i+'_nm') }
				] },
				{ title: 'Subnet/Netmask', multi: [
					{ title: '', custom: '<input type="button" value="Generate Key" onclick="updatePeerKey('+(i)+')" id="wg_keygen_peer'+i+'_button">' },
					{ title: '', custom: '<input type="button" value="Download Config" onclick="generatePeerConfig('+(i)+')" id="wg_config_peer'+i+'_button">' }
				] },
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
