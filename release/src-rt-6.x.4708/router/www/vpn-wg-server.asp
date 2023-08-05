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
<title>[<% ident(); %>] Wireguard</title>
<link rel="stylesheet" type="text/css" href="tomato.css">
<% css(); %>
<style>
.co2, .co3, .co4 {
	max-width: 150px;
	white-space: nowrap;
	overflow: hidden;
	text-overflow: ellipsis;
}

.co6, .co7 {
	width: 24px;
  	white-space: nowrap;
  	overflow: hidden;
  	text-overflow: ellipsis;
}

.qrcode {
	display: grid;
	width: 100%;
	justify-items: center;
	text-align: center;
	font-size: large;
	padding: 10px;
}

</style>
<script src="isup.jsz"></script>
<script src="tomato.js"></script>
<script src="wireguard.js"></script>
<script src="interfaces.js"></script>
<script src="qrcode.js"></script>
<script src="html5-qrcode.js"></script>
<script>

//	<% nvram("wan_ipaddr,lan_ifname,lan_ipaddr,lan_netmask,lan1_ifname,lan1_ipaddr,lan1_netmask,lan2_ifname,lan2_ipaddr,lan2_netmask,lan3_ifname,lan3_ipaddr,lan3_netmask,wg_server1_eas,wg_server1_file,wg_server1_ip,wg_server1_nm,wg_server1_ka,wg_server1_port,wg_server1_key,wg_server1_endpoint,wg_server1_lan,wg_server1_lan0,wg_server1_lan1,wg_server1_lan2,wg_server1_lan3,wg_server1_rgw,wg_server1_peers,wg_server2_eas,wg_server2_file,wg_server2_ip,wg_server2_nm,wg_server2_ka,wg_server2_port,wg_server2_key,wg_server2_endpoint,wg_server2_lan,wg_server2_lan0,wg_server2_lan1,wg_server2_lan2,wg_server2_lan3,wg_server2_rgw,wg_server2_peers,wg_server3_eas,wg_server3_file,wg_server3_ip,wg_server3_nm,wg_server3_ka,wg_server3_port,wg_server3_key,wg_server3_endpoint,wg_server3_lan,wg_server3_lan0,wg_server3_lan1,wg_server3_lan2,wg_server3_lan3,wg_server3_rgw,wg_server3_peers"); %>

var cprefix = 'vpn_wg_server';
var changed = 0;
var serviceType = 'wgserver';

var tabs =  [];
for (i = 1; i <= WG_SERVER_COUNT; ++i)
	tabs.push(['server'+i,'Server '+i]);
var sections = [['interface','Interface Configuration'],['peers','Peers'],['gen','Client Generation']];

function PeerGrid() {return this;}
PeerGrid.prototype = new TomatoGrid;

var peerTables = [];
for (i = 0; i < tabs.length; ++i) {
	peerTables.push(new PeerGrid());
	peerTables[i].servername = tabs[i][0];
}

function show() {
	countButton += 1;
	for (var i = 1; i <= WG_SERVER_COUNT; ++i) {
		var e = E('_'+serviceType+i+'_button');
		var d = eval('isup.'+serviceType+i);

		e.value = (d ? 'Stop' : 'Start')+' Now';
		e.setAttribute('onclick', 'javascript:toggle(\''+serviceType+''+i+'\','+d+');');
		if (serviceLastUp[i - 1] != d || countButton > 6) {
			serviceLastUp[i - 1] = d;
			countButton = 0;
			e.disabled = 0;
			E('spin'+i).style.display = 'none';
		}
	}
}

function toggle(service, isup) {
	if (changed && !confirm('There are unsaved changes. Continue anyway?'))
		return;

	serviceLastUp[id - 1] = isup;
	countButton = 0;

	var id = service.substr(service.length - 1);
	E('_'+service+'_button').disabled = 1;
	E('spin'+id).style.display = 'inline';

	var fom = E('t_fom');
	var bup = fom._service.value;
	fom._service.value = service+(isup ? '-stop' : '-start');

	form.submit(fom, 1, 'service.cgi');
	fom._service.value = bup;
}

function tabSelect(name) {
	tgHideIcons();

	tabHigh(name);

	for (var i = 0; i < tabs.length; ++i)
		elem.display(tabs[i][0]+'-tab', (name == tabs[i][0]));

	cookie.set('wg_server_tab', name);
}

function sectSelect(tab, section) {
	tgHideIcons();

	for (var i = 0; i < sections.length; ++i) {
		if (section == sections[i][0]) {
			elem.addClass(tabs[tab][0]+'-'+sections[i][0]+'-tab', 'active');
			elem.display(tabs[tab][0]+'-'+sections[i][0], true);
		}
		else {
			elem.removeClass(tabs[tab][0]+'-'+sections[i][0]+'-tab', 'active');
			elem.display(tabs[tab][0]+'-'+sections[i][0], false);
		}
	}

	cookie.set('vpn_server'+tab+'_section', section);
}

function updateForm(num) {
	var fom = E('t_fom');

	if (eval('isup.vpnserver'+num) && fom._service.value.indexOf('server'+num) < 0) {
		if (fom._service.value != '')
			fom._service.value += ',';

		fom._service.value += 'vpnserver'+num+'-restart';
	}
}

PeerGrid.prototype.resetNewEditor = function() {
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

PeerGrid.prototype.setup = function() {
	this.init(this.servername+'-peers-grid', '', 50, [
		{ type: 'text', maxlen: 32 },
		{ type: 'text', maxlen: 64 },
		{ type: 'text', maxlen: 44 },
		{ type: 'text', maxlen: 44 },
		{ type: 'text', maxlen: 100 },
		{ type: 'text', maxlen: 3 },
		{ type: 'text', maxlen: 3 },
	]);
	this.headerSet(['Alias','Endpoint','Public Key','Preshared Key','IP','NM','KA']);
	var nv = eval("nvram.wg_"+this.servername+"_peers.split('>')");
	for (var i = 0; i < nv.length; ++i) {
		var t = nv[i].split('<');
		if (t.length == 7) {
			this.insertData(-1, t);
		}
	}
	this.showNewEditor();
}

PeerGrid.prototype.rpDel = function(e) {
	changed = 1;
	e = PR(e);
	TGO(e).moving = null;
	e.parentNode.removeChild(e);
	this.recolor();
	this.resort();
	this.rpHide();
}

PeerGrid.prototype.verifyFields = function(row, quiet) {

	changed = 1;
	var ok = 1;

	var f = fields.getAll(row);
	var data = this.fieldValuesToData(row)
	var results = verifyPeerFieldData(data);
	
	if (!results[2]) {
		ferror.set(f[2], 'A valid public key is required', quiet || !ok);
		ok = 0;
	}
	else
		ferror.clear(f[2]);

	if (!results[3]) {
		ferror.set(f[3], 'Preshared key is invalid', quiet || !ok);
		ok = 0;
	}
	else
		ferror.clear(f[3]);

	if (!results[4]) {
		ferror.set(f[4], 'IP is invalid', quiet || !ok);
		ok = 0;
	}
	else
		ferror.clear(f[4]);

	if (!results[5]) {
		ferror.set(f[5], 'Netmask is not within range 0-32', quiet || !ok);
		ok = 0;
	}
	else 
		ferror.clear(f[5]);

	if (!results[6]) {
		ferror.set(f[6], 'Keepalive is not within range 0-128', quiet || !ok);
		ok = 0;
	}
	else 
		ferror.clear(f[6]);

	return ok;
}

function verifyPeerFieldData(data) {

	var results = [];
	for (var i = 0; i < data.length; i++) {
		results.push(true);
	}

	if (!window.wireguard.validateBase64Key(data[2]))
		results[2] = false;

	if (data[3] != '' && !window.wireguard.validateBase64Key(data[3])) 
		results[3] = false;

	if (!fixIP(f[4]))
		results[4] = false;

	if ((!f[5].match(/^ *[-\+]?\d+ *$/)) || (f[5] < 0) || (f[5] > 32)) 
		results[5] = false;
	
	if ((!f[6].match(/^ *[-\+]?\d+ *$/)) || (f[6] < 0) || (f[6] > 128)) 
		results[6] = false;

	return results;
}

function copyServerPubKey(unit) {
	
	const textArea = document.createElement("textarea");
	textArea.value = E('_wg_server'+unit+'_pubkey').value;
		
	// Move textarea out of the viewport so it's not visible
	textArea.style.position = "absolute";
	textArea.style.left = "-999999px";
		
	document.body.prepend(textArea);
	textArea.select();

	try {
		document.execCommand('copy');
	} catch (error) {
		console.error(error);
	} finally {
		textArea.remove();
	}
}

function updateServerKey(unit) {
	var response = false;
	if (E('_wg_server'+unit+'_key').value == '')
		response = true;
	else
		response = confirm('Regenerating the interface private key will\ncause any generated peers to stop working!\nDo you want to continue?');
	if (response) {
		var keys = window.wireguard.generateKeypair();
		E('_wg_server'+unit+'_key').value = keys.privateKey;
		E('_wg_server'+unit+'_pubkey').value = keys.publicKey;
	}
}

function addPeer(unit) {

	var ok = 1;

	var alias = E('_f_wg_server'+unit+'_peer_alias');
	var endpoint = E('_f_wg_server'+unit+'_peer_ep').value;
	var pubkey = E('_f_wg_server'+unit+'_peer_pubkey').value;
	var psk = E('_f_wg_server'+unit+'_peer_psk').value;
	var ip = E('_f_wg_server'+unit+'_peer_ip').value;
	var netmask = E('_f_wg_server'+unit+'_peer_nm').value;
	var keepalive = E('_f_wg_server'+unit+'_peer_ka').value;

	var data = [
		alias.value,
		endpoint.value,
		pubkey.value,
		psk.value,
		ip.value,
		netmask.value,
		keepalive.value
	];

	var results = verifyPeerFieldData(data);

	if (!results[2]) {
		ferror.set(pubkey, 'A valid public key is required', quiet || !ok);
		ok = 0;
	}
	else
		ferror.clear(pubkey);

	if (!results[3]) {
		ferror.set(psk, 'Preshared key is invalid', quiet || !ok);
		ok = 0;
	}
	else
		ferror.clear(psk);

	if (!results[4]) {
		ferror.set(ip, 'IP is invalid', quiet || !ok);
		ok = 0;
	}
	else
		ferror.clear(ip);

	if (!results[5]) {
		ferror.set(netmask, 'Netmask is not within range 0-32', quiet || !ok);
		ok = 0;
	}
	else 
		ferror.clear(netmask);

	if (!results[6]) {
		ferror.set(keepalive, 'Keepalive is not within range 0-128', quiet || !ok);
		ok = 0;
	}
	else 
		ferror.clear(keepalive);

	return ok;

	changed = 1;
	peerTables[unit-1].insertData(-1, data);
	peerTables[unit-1].disableNewEditor(false);
	peerTables[unit-1].resetNewEditor();

	save();
}

function generateClient(unit) {

	/* check if changes have been made */
	if (changed) {
		alert('Changes have been made. You need to save before continue!');
		return;
	}

	/* Generate keys */
	var keys = window.wireguard.generateKeypair();
	
	/* Generate PSK (if checked) */
	var psk = "";
	if (E('_f_wg_server'+unit+'_peer_psk_gen').checked)
		psk = window.wireguard.generatePresharedKey();

	/* retrieve existing IPs of server/clients to calculate new ip */
	var existing_ips = parsePeers(eval('nvram.wg_server'+unit+'_peers'));
	existing_ips = existing_ips.map(x => x.ip);
	existing_ips.push(eval('nvram.wg_server'+unit+'_ip'))

	/* calculate ip of new peer */
	var ip = "";
	var nm = CIDRToNetmask(eval('nvram.wg_server'+unit+'_nm'));
	var network = getNetworkAddress(eval('nvram.wg_server'+unit+'_ip'), nm);
	var limit = 2 ** (32 - parseInt(eval('nvram.wg_server'+unit+'_nm'), 10));
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

	/* return if we could not generate an IP */
	if (ip == "") {
		alert('Could not generate an IP for the client');
		return;
	}

	/* set keepalive (if checked) */
	var keepalive = 0;
	if (E('_f_wg_server'+unit+'_peer_ka_enable').checked)
		keepalive = 25;

	/* set fields with generated data */
	E('_f_wg_server'+unit+'_peer_pubkey').value = keys.publicKey;
	E('_f_wg_server'+unit+'_peer_psk').value = psk;
	E('_f_wg_server'+unit+'_peer_ip').value = ip;
	E('_f_wg_server'+unit+'_peer_nm').value = '32';
	E('_f_wg_server'+unit+'_peer_ka').value = keepalive;

	/* generate config */
	var alias = E('_f_wg_server'+unit+'_peer_alias').value;
	var content = generatePeerConfig(
		unit,
		alias,
		keys.privateKey,
		psk,
		ip
	);

	/* download config file (if checked) */
	if (E('_f_wg_server'+unit+'_peer_save').checked) {
		var filename = "client.conf";
		if (alias != "")
			filename = `${alias}.conf`;
		downloadConfig(content, filename);
	}

	/* display config QR code (if checked) */
	if (E('_f_wg_server'+unit+'_peer_qr_enable').checked) {
		var qrcode = E('wg_server'+unit+'_qrcode');
		var qrcode_content = content.join('');
		if (qrcode_content.length*8+20 < 4184) {
			qrcode.replaceChild(showQRCode(qrcode_content), qrcode.firstChild);
			elem.display('wg_server'+unit+'_qrcode', true);
		}
	}
	
}

function generatePeerConfig(unit, name, privkey, psk, ip) {
	
	var netmask = eval('nvram.wg_server'+unit+'_nm');
	var port = eval('nvram.wg_server'+unit+'_port');
	var content = [];

	/* build interface section */
	content.push("[Interface]\n");

	if (name != "") {
		content.push(`#Alias = ${name}\n`);
	}

	content.push(
		`Address = ${ip}/${netmask}\n`,
		`ListenPort = ${port}\n`,
		`PrivateKey = ${privkey}\n`,
	);

	/* build router peer */
	var publickey_server = window.wireguard.generatePublicKey(eval('nvram.wg_server'+unit+'_key'));
	var keepalive_server = eval('nvram.wg_server'+unit+'_ka');
	var endpoint;
	var allowed_ips;

	/* build endpoint */
	if (eval('nvram.wg_server'+unit+'_endpoint') != "") {
		endpoint = eval('nvram.wg_server'+unit+'_endpoint') + ":" + eval('nvram.wg_server'+unit+'_port');
	}
	else {
		endpoint = nvram.wan_ipaddr + ":" + eval('nvram.wg_server'+unit+'_port');
	}

	/* build allowed ips for router peer */
	if (eval('nvram.wg_server'+unit+'_rgw') == "1") {
		allowed_ips = "0.0.0.0/0"
	}
	else {
		var netmask;
		if (eval('nvram.wg_server'+unit+'_lan') == "1") {
			netmask = '/' + eval('nvram.wg_server'+unit+'_nm');
		}
		else {
			netmask = "/32";
		}
		allowed_ips = eval('nvram.wg_server'+unit+'_ip') + netmask;
		for(let i = 0; i <= 3; i++){
			if (eval('nvram.wg_server'+unit+'_lan'+i) == "1") {
				let t = (i == 0 ? '' : i);
				var nm = eval(`nvram.lan${t}_netmask`);
				var network_ip = getNetworkAddress(eval(`nvram.lan${t}_ipaddr`), nm);
				allowed_ips += ', ';
				allowed_ips += network_ip;
				allowed_ips += '/';
				allowed_ips += netmaskToCIDR(nm);
			}
		}
	}

	/* populate router peer */
	content.push(
		"\n",
		"[Peer]\n",
		"#Alias = Router\n",
		`PublicKey = ${publickey_server}\n`
	);

	if (psk != "") {
		content.push(`PresharedKey = ${psk}\n`);
	}

	content.push(
		`AllowedIPs = ${allowed_ips}\n`,
		`Endpoint = ${endpoint}\n`
	);

	if (keepalive_server != "0") {
		content.push(`PersistentKeepalive = ${keepalive_server}\n`);
	}

	/* add remaining peers to config */
	if (eval('nvram.wg_server'+unit+'_lan') == "1") {
		var server_peers = parsePeers(eval('nvram.wg_server'+unit+'_peers'))
		
		for (var i = 0; i < server_peers.length; ++i) {
			var peer = server_peers[i]

			if (peer.key == window.wireguard.generatePublicKey(privkey)) {
				continue;
			}

			content.push(
				"\n",
				"[Peer]\n",
			);

			if (peer.name != "") {
				content.push(`#Alias = ${peer.name}\n`,);
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

function downloadConfig(content, name) {
	const link = document.createElement("a");
	const file = new Blob(content, { type: 'text/plain' });
	link.href = URL.createObjectURL(file);
	link.download = name;
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
				peer.endpoint = t[1];
				peer.key = t[2];
				peer.psk = t[3];
				peer.ip = t[4];
				peer.netmask = t[5];
				peer.keepalive = t[6];
				
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

	for (var i = 1; i <= WG_SERVER_COUNT; i++) {

		E('_wg_server'+i+'_pubkey').disabled = true;
		var pubkey = window.wireguard.generatePublicKey(E('_wg_server'+i+'_key').value);
		if(pubkey == false) {
			pubkey = "";
		}
		E('_wg_server'+i+'_pubkey').value = pubkey;

		for (let j = 0; j <= 3; ++j) {
			t = (j == 0 ? '' : j);

			if (eval('nvram.lan'+t+'_ifname.length') < 1) {
				E('_f_wg_server'+i+'_lan'+t).checked = 0;
				E('_f_wg_server'+i+'_lan'+t).disabled = 1;
			}
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
	for (var i = 1; i <= WG_SERVER_COUNT; i++) {

		var data = peerTables[i-1].getAllData();
		var s = '';
		for (var j = 0; j < data.length; ++j)
			s += data[j].join('<')+'>';

		eval('fom.wg_server'+i+'_peers.value = s');
		eval('nvram.wg_server'+i+'_peers = s');

		eval('fom.wg_server'+i+'_eas.value = fom._f_wg_server'+i+'_eas.checked ? 1 : 0');
		eval('fom.wg_server'+i+'_lan.value = fom._f_wg_server'+i+'_lan.checked ? 1 : 0');
		eval('fom.wg_server'+i+'_lan0.value = fom._f_wg_server'+i+'_lan0.checked ? 1 : 0');
		eval('fom.wg_server'+i+'_lan1.value = fom._f_wg_server'+i+'_lan1.checked ? 1 : 0');
		eval('fom.wg_server'+i+'_lan2.value = fom._f_wg_server'+i+'_lan2.checked ? 1 : 0');
		eval('fom.wg_server'+i+'_lan3.value = fom._f_wg_server'+i+'_lan3.checked ? 1 : 0');
		eval('fom.wg_server'+i+'_rgw.value = fom._f_wg_server'+i+'_rgw.checked ? 1 : 0');
		
	}

	form.submit(fom, 1);

	changed = 0;
}

function earlyInit() {
	show();
	tabSelect(cookie.get('wg_server_tab') || tabs[0][0]);
	for (var i = 0; i < tabs.length; ++i) {
		sectSelect(i, cookie.get('wg_server'+i+'_section') || sections[0][0]);
	}
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

<!-- / / / -->

<div class="section-title">Wireguard Interface Configuration</div>
<div class="section">
	<script>
		tabCreate.apply(this, tabs);

		for (i = 0; i < tabs.length; ++i) {
			t = tabs[i][0];
			W('<div id="'+t+'-tab">');
			W('<input type="hidden" name="wg_'+t+'_eas">');
			W('<input type="hidden" name="wg_'+t+'_lan">');
			W('<input type="hidden" name="wg_'+t+'_lan0">');
			W('<input type="hidden" name="wg_'+t+'_lan1">');
			W('<input type="hidden" name="wg_'+t+'_lan2">');
			W('<input type="hidden" name="wg_'+t+'_lan3">');
			W('<input type="hidden" name="wg_'+t+'_rgw">');
			W('<input type="hidden" name="wg_'+t+'_peers">');

			W('<ul class="tabs">');
			for (j = 0; j < sections.length; j++) {
				W('<li><a href="javascript:sectSelect('+i+',\''+sections[j][0]+'\')" id="'+t+'-'+sections[j][0]+'-tab">'+sections[j][1]+'<\/a><\/li>');
			}
			W('<\/ul><div class="tabs-bottom"><\/div>');

			W('<div id="'+t+'-interface">');
			W('<div class="section-title">Server Configuration</div>');
			createFieldTable('', [
				{ title: 'Enable on Start', name: 'f_wg_'+t+'_eas', type: 'checkbox', value: eval('nvram.wg_'+t+'_eas') == '1' },
				{ title: 'File to load interface from', name: 'wg_'+t+'_file', type: 'text', maxlen: 64, size: 64, value: eval('nvram.wg_'+t+'_file') },
				{ title: 'Port', name: 'wg_'+t+'_port', type: 'text', maxlen: 5, size: 10, value: eval('nvram.wg_'+t+'_port') },
				{ title: 'Private Key', multi: [
					{ title: '', name: 'wg_'+t+'_key', type: 'password', maxlen: 44, size: 44, value: eval('nvram.wg_'+t+'_key'), peekaboo: 1 },
					{ title: '', custom: '<input type="button" value="Generate" onclick="updateServerKey('+(i+1)+')" id="wg_'+t+'_keygen">' },
				] },
				{ title: 'Public Key', multi: [
					{ title: '', name: 'wg_'+t+'_pubkey', type: 'text', maxlen: 44, size: 44, disabled: ""},
					{ title: '', custom: '<input type="button" value="Copy" onclick="copyServerPubKey('+(i+1)+')" id="wg_'+t+'_pubkey_copy">' },
				] },
				{ title: 'IP/Netmask', multi: [
					{ name: 'wg_'+t+'_ip', type: 'text', maxlen: 15, size: 17, value: eval('nvram.wg_'+t+'_ip') },
					{ name: 'wg_'+t+'_nm', type: 'text', maxlen: 2, size: 4, value: eval('nvram.wg_'+t+'_nm') }
				] },
				{ title: 'Keepalive to Server', name: 'wg_'+t+'_ka', type: 'text', maxlen: 2, size: 4, value: eval('nvram.wg_'+t+'_ka') },
				{ title: 'Custom Endpoint', name: 'wg_'+t+'_endpoint', type: 'text', maxlen: 64, size: 64, value: eval('nvram.wg_'+t+'_endpoint') },
				{ title: 'Allow peers to communicate', name: 'f_wg_'+t+'_lan', type: 'checkbox', value: eval('nvram.wg_'+t+'_lan') == '1'},
				{ title: 'Push LAN0 (br0) to peers', name: 'f_wg_'+t+'_lan0', type: 'checkbox', value: eval('nvram.wg_'+t+'_lan0') == '1' },
				{ title: 'Push LAN1 (br1) to peers', name: 'f_wg_'+t+'_lan1', type: 'checkbox', value: eval('nvram.wg_'+t+'_lan1') == '1' },
				{ title: 'Push LAN2 (br2) to peers', name: 'f_wg_'+t+'_lan2', type: 'checkbox', value: eval('nvram.wg_'+t+'_lan2') == '1' },
				{ title: 'Push LAN3 (br3) to peers', name: 'f_wg_'+t+'_lan3', type: 'checkbox', value: eval('nvram.wg_'+t+'_lan3') == '1' },
				{ title: 'Forward all peer traffic', name: 'f_wg_'+t+'_rgw', type: 'checkbox', value: eval('nvram.wg_'+t+'_rgw') == '1' },
			]);
			W('</div>');
			W('<div id="'+t+'-peers">');
			W('<div class="section-title">Peers</div>');
			W('<div class="tomato-grid" id="'+t+'-peers-grid"><\/div>');
			peerTables[i].setup();
			W('</div>');
			W('<div id="'+t+'-gen">');
			W('<div class="section-title">Client Generation</div>');
			createFieldTable('', [
				{ title: 'Generate PSK', name: 'f_wg_'+t+'_peer_psk_gen', type: 'checkbox', value: true },
				{ title: 'Send Keepalive to Client', name: 'f_wg_'+t+'_peer_ka_enable', type: 'checkbox', value: true},
				{ title: 'Generate Config QR Code', name: 'f_wg_'+t+'_peer_qr_enable', type: 'checkbox', value: true },
				{ title: 'Save Config to File', name: 'f_wg_'+t+'_peer_save', type: 'checkbox', value: true },
			]);
			W('<input type="button" value="Generate Client Config" onclick="generateClient('+(i+1)+')" id="wg_'+t+'_peer_gen">');
			W('<div id="wg_'+t+'_qrcode" class="qrcode" style="display:none">');
			W('<img alt="wg_'+t+'_qrcode_img">');
			W('<div id="wg_'+t+'_qrcode_labels" class="qrcode-labels" title="Message">');
			W('Point your mobile phone camera<br>');
			W('here above to connect automatically');
			W('</div>');
			W('</div>');
			W('<div class="section-title">Peer Addition</div>');
			createFieldTable('', [
				{ title: 'Alias', name: 'f_wg_'+t+'_peer_alias', type: 'text', maxlen: 32, size: 32},
				{ title: 'Endpoint', name: 'f_wg_'+t+'_peer_ep', type: 'text', maxlen: 64, size: 64},
				{ title: 'Public Key', name: 'f_wg_'+t+'_peer_pubkey', type: 'text', maxlen: 44, size: 44},
				{ title: 'Preshared Key', name: 'f_wg_'+t+'_peer_psk', type: 'text', maxlen: 44, size: 44},
				{ title: 'IP (optional)', name: 'f_wg_'+t+'_peer_ip', type: 'text', maxlen: 64, size: 64},
				{ title: 'Netmask', name: 'f_wg_'+t+'_peer_nm', type: 'text', maxlen: 2, size: 4, value: "32"},
				{ title: 'Keepalive', name: 'f_wg_'+t+'_peer_ka', type: 'text', maxlen: 2, size: 4, value: "0"},
			]);
			W('<input type="button" value="Add to Peers" onclick="addPeer('+(i+1)+')" id="wg_'+t+'_peer_gen">');
			W('</div>');
			W('<div class="vpn-start-stop"><input type="button" value="" onclick="" id="_wg'+t+'_button">&nbsp; <img src="spin.gif" alt="" id="spin'+(i+1)+'"></div>')
			W('</div>');
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
