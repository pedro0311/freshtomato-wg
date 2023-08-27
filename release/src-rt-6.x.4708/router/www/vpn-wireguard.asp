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
.co1, .co2, .co3, .co4, .co5, .co6, .co7 {
	max-width: 120px;
	white-space: nowrap;
	overflow: hidden;
	text-overflow: ellipsis;
}

.co8 {
	width: 32px;
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

//	<% nvram("wan_ipaddr,lan_ifname,lan_ipaddr,lan_netmask,lan1_ifname,lan1_ipaddr,lan1_netmask,lan2_ifname,lan2_ipaddr,lan2_netmask,lan3_ifname,lan3_ipaddr,lan3_netmask,wg_iface_dns,wg_iface1_eas,wg_iface1_file,wg_iface1_ip,wg_iface1_fwmark,wg_iface1_mtu,wg_iface1_preup,wg_iface1_postup,wg_iface1_predown,wg_iface1_postdown,wg_iface1_aip,wg_iface1_dns,wg_iface1_ka,wg_iface1_port,wg_iface1_key,wg_iface1_endpoint,wg_iface1_lan,wg_iface1_lan0,wg_iface1_lan1,wg_iface1_lan2,wg_iface1_lan3,wg_iface1_rgw,wg_iface1_peers,wg_iface2_eas,wg_iface2_file,wg_iface2_ip,wg_iface2_fwmark,wg_iface2_mtu,wg_iface2_preup,wg_iface2_postup,wg_iface2_predown,wg_iface2_postdown,wg_iface2_aip,wg_iface2_dns,wg_iface2_ka,wg_iface2_port,wg_iface2_key,wg_iface2_endpoint,wg_iface2_lan,wg_iface2_lan0,wg_iface2_lan1,wg_iface2_lan2,wg_iface2_lan3,wg_iface2_rgw,wg_iface2_peers,wg_iface3_eas,wg_iface3_file,wg_iface3_ip,wg_iface3_fwmark,wg_iface3_mtu,wg_iface3_preup,wg_iface3_postup,wg_iface3_predown,wg_iface3_postdown,wg_iface3_aip,wg_iface3_dns,wg_iface3_ka,wg_iface3_port,wg_iface3_key,wg_iface3_endpoint,wg_iface3_lan,wg_iface3_lan0,wg_iface3_lan1,wg_iface3_lan2,wg_iface3_lan3,wg_iface3_rgw,wg_iface3_peers"); %>

var cprefix = 'vpn_wireguard';
var changed = 0;
var serviceType = 'wireguard';

var tabs =  [];
for (i = 1; i <= WG_INTERFACE_COUNT; ++i)
	tabs.push(['iface'+i,'wg'+i]);
var sections = [['interface','Interface'],['scripts','Scripts'],['peers','Peers']];

function PeerGrid() {return this;}
PeerGrid.prototype = new TomatoGrid;

var peerTables = [];
for (i = 0; i < tabs.length; ++i) {
	peerTables.push(new PeerGrid());
	peerTables[i].interface_name = tabs[i][0];
	peerTables[i].unit = i+1;
}

ferror.show = function(e) {
	if ((e = E(e)) == null) return;
	if (!e._error_msg) return;
	elem.addClass(e, 'error-focused');
	var [tab, section] = locateElement(e);
	tabSelect(tab);
	sectSelect(tab.substr(5)-1, section);
	e.focus();
	alert(e._error_msg);
	elem.removeClass(e, 'error-focused');
}

function locateElement(e) {
	do {
		e = e.parentElement;
	} while(e.id.indexOf('iface') < 0);
	return e.id.split('-', 2);
}

function show() {
	countButton += 1;
	for (var i = 1; i <= WG_INTERFACE_COUNT; ++i) {
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

	cookie.set('wg_iface_tab', name);
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

	cookie.set('wg_iface'+tab+'_section', section);
}

function updateForm(num) {
	var fom = E('t_fom');

	if (eval('isup.wireguard'+num) && fom._service.value.indexOf('iface'+num) < 0) {
		if (fom._service.value != '')
			fom._service.value += ',';

		fom._service.value += 'wireguard'+num+'-restart';
	}
}

PeerGrid.prototype.setup = function() {
	this.init(this.interface_name+'-peers-grid', '', 50, [
		{ type: 'text', maxlen: 32 },
		{ type: 'text', maxlen: 128 },
		{ type: 'password', maxlen: 44 },
		{ type: 'text', maxlen: 44 },
		{ type: 'text', maxlen: 44 },
		{ type: 'text', maxlen: 100 },
		{ type: 'text', maxlen: 128 },
		{ type: 'text', maxlen: 3 },
	]);
	this.headerSet(['Alias','Endpoint','Private Key','Public Key','Preshared Key','Interface IP','Allowed IPs','KA']);
	this.disableNewEditor(true);
	var nv = eval("nvram.wg_"+this.interface_name+"_peers.split('>')");
	for (var i = 0; i < nv.length; ++i) {
		var t = nv[i].split('<');
		if (t.length == 8) {
			var data, pubkey, privkey;

			if (t[0] == 1) {
				privkey = t[3];
				pubkey = window.wireguard.generatePublicKey(privkey);
			}
			else {
				privkey = "";
				pubkey = t[3];
			}

			data = [
				t[1],
				t[2],
				privkey,
				pubkey,
				t[4],
				t[5],
				t[6],
				t[7],
			]

			this.insertData(-1, data);
		}
	}
}

PeerGrid.prototype.edit = function(cell) {
	
	var row = PR(cell);
	var data = row.getRowData();

	var alias = E('_f_wg_iface'+this.unit+'_peer_alias');
	var endpoint = E('_f_wg_iface'+this.unit+'_peer_ep');
	var port = E('_f_wg_iface'+this.unit+'_peer_port');
	var privkey = E('_f_wg_iface'+this.unit+'_peer_privkey');
	var pubkey = E('_f_wg_iface'+this.unit+'_peer_pubkey');
	var psk = E('_f_wg_iface'+this.unit+'_peer_psk');
	var ip = E('_f_wg_iface'+this.unit+'_peer_ip');
	var allowedips = E('_f_wg_iface'+this.unit+'_peer_aip');
	var keepalive = E('_f_wg_iface'+this.unit+'_peer_ka');
	var fwmark = E('_f_wg_iface'+this.unit+'_peer_fwmark');
	
	alias.value = data[0];
	endpoint.value = data[1];
	port.value = eval('nvram.wg_'+this.interface_name+'_port');
	privkey.value = data[2];
	pubkey.value = data[3];
	psk.value = data[4];
	ip.value = data[5];
	allowedips.value = data[6];
	keepalive.value = data[7];
	fwmark.value = 0;

	var button = E('wg_'+this.interface_name+'_peer_add');
	button.value = 'Save to Peers';
	button.setAttribute('onclick', 'editPeer('+this.unit+', '+row.rowIndex+')');

}

PeerGrid.prototype.rowDel = function(e) {
	changed = 1;
	TGO(e).moving = null;
	e.parentNode.removeChild(e);
	this.recolor();
	this.resort();
	this.rpHide();
}

PeerGrid.prototype.rpDel = function(e) {
	e = PR(e);
	this.rowDel(e);
}

PeerGrid.prototype.verifyFields = function(row, quiet) {

	changed = 1;
	var ok = 1;

	/* When settings change, make sure we restart the right server */
	for (var i = 0; i < tabs.length; ++i) {
		if (peerTables[i] == this)
			updateForm(i + 1);
	}

	var f = fields.getAll(row);
	var data = this.fieldValuesToData(row)
	var results = verifyPeerFieldData(data);

	if (!results[2]) {
		ferror.set(f[2], 'A valid private key is required', quiet || !ok);
		ok = 0;
	}
	else
		ferror.clear(f[2]);
	
	if (!results[3]) {
		ferror.set(f[3], 'A valid public key is required', quiet || !ok);
		ok = 0;
	}
	else
		ferror.clear(f[3]);

	if (!results[4]) {
		ferror.set(f[4], 'Preshared key is invalid', quiet || !ok);
		ok = 0;
	}
	else
		ferror.clear(f[4]);

	if (!results[5]) {
		ferror.set(f[5], 'IP must be in CIDR notation', quiet || !ok);
		ok = 0;
	}
	else
		ferror.clear(f[5]);
	
	if (!results[6]) {
		ferror.set(f[6], 'Allowed IPs must be a comma separated list of CIDRs', quiet || !ok);
		ok = 0;
	}
	else 
		ferror.clear(f[6]);

	if (!results[7]) {
		ferror.set(f[7], 'Keepalive is not within range 0-128', quiet || !ok);
		ok = 0;
	}
	else 
		ferror.clear(f[7]);

	return ok;
}

PeerGrid.prototype.getAllData = function() {
	var i, max, data, r, type;

	data = [];
	max = this.footer ? this.footer.rowIndex : this.tb.rows.length;
	for (i = this.header ? this.header.rowIndex + 1 : 0; i < max; ++i) {
		r = this.tb.rows[i];
		if ((r.style.display != 'none') && (r._data)) data.push(r._data);
	}

	/* reformat the data to include one key and a flag specifying which type */
	for (i = 0; i < data.length; ++i) {
		data[i] = formatDataForNVRAM(data[i]);
	}

	return data;
}

function formatDataForNVRAM(data) {
	var key, type;

	if(data[2]) {
		type = 1;
		key = data[2];
	}
	else {
		type = 0;
		key = data[3];
	}

	data = [
		type,
		data[0],
		data[1],
		key,
		data[4],
		data[5],
		data[6],
		data[7],
	]

	return data;
}

function verifyPeerFieldData(data) {

	var results = [];
	for (var i = 0; i < data.length; i++) {
		results.push(true);
	}

	if (data[2] && !window.wireguard.validateBase64Key(data[2]))
		results[2] = false;

	if (!window.wireguard.validateBase64Key(data[3]))
		results[3] = false;

	if (data[4] != '' && !window.wireguard.validateBase64Key(data[4])) 
		results[4] = false;

	if (!verifyCIDR(data[5]))
		results[5] = false;
	
	if (data[6] != '') {
		var cidrs = data[6].split(',')
		for(var i = 0; i < cidrs.length; i++) {
			var cidr = cidrs[i].trim();
			if (!verifyCIDR(cidr)) {
				results[6] = false;
				break;
			}
		}
	}
	
	if ((!data[7].match(/^ *[-\+]?\d+ *$/)) || (data[7] < 0) || (data[7] > 128)) 
		results[7] = false;

	return results;
}

function copyInterfacePubKey(unit) {
	
	const textArea = document.createElement("textarea");
	textArea.value = E('_wg_iface'+unit+'_pubkey').value;
		
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

function generateInterfaceKey(unit) {
	var response = false;
	if (E('_wg_iface'+unit+'_key').value == '')
		response = true;
	else
		response = confirm('Regenerating the interface private key will\ncause any generated peers to stop working!\nDo you want to continue?');
	if (response) {
		var keys = window.wireguard.generateKeypair();
		E('_wg_iface'+unit+'_key').value = keys.privateKey;
		E('_wg_iface'+unit+'_pubkey').value = keys.publicKey;
		updateForm(unit)
	}
}

function addPeer(unit, quiet) {

	var ok = 1;

	var alias = E('_f_wg_iface'+unit+'_peer_alias');
	var endpoint = E('_f_wg_iface'+unit+'_peer_ep');
	var port = E('_f_wg_iface'+unit+'_peer_port');
	var privkey = E('_f_wg_iface'+unit+'_peer_privkey');
	var pubkey = E('_f_wg_iface'+unit+'_peer_pubkey');
	var psk = E('_f_wg_iface'+unit+'_peer_psk');
	var ip = E('_f_wg_iface'+unit+'_peer_ip');
	var allowedips = E('_f_wg_iface'+unit+'_peer_aip');
	var keepalive = E('_f_wg_iface'+unit+'_peer_ka');
	var fwmark = E('_f_wg_iface'+unit+'_peer_fwmark');

	var data = [
		alias.value,
		endpoint.value,
		privkey.value,
		pubkey.value,
		psk.value,
		ip.value,
		allowedips.value,
		keepalive.value
	];

	var results = verifyPeerFieldData(data);

	if (!results[2]) {
		ferror.set(privkey, 'A valid private key is required', quiet || !ok);	
		ok = 0;
	}
	else
		ferror.clear(privkey);

	if (!results[3]) {
		ferror.set(pubkey, 'A valid public key is required', quiet || !ok);	
		ok = 0;
	}
	else
		ferror.clear(pubkey);
		

	if (!results[4]) {
		ferror.set(psk, 'Preshared key is invalid', quiet || !ok);
		ok = 0;
	}
	else
		ferror.clear(psk);

	if (!results[5]) {
		ferror.set(ip, 'IP is invalid', quiet || !ok);
		ok = 0;
	}
	else
		ferror.clear(ip);

	if (!results[6]) {
		ferror.set(allowedips, 'Allowed IPs must be a comma separated list of CIDRs', quiet || !ok);
		ok = 0;
	}
	else 
		ferror.clear(keepalive);

	if (!results[7]) {
		ferror.set(keepalive, 'Keepalive is not within range 0-128', quiet || !ok);
		ok = 0;
	}
	else 
		ferror.clear(keepalive);

	if(ok) {
		changed = 1;
		peerTables[unit-1].insertData(-1, data);
		peerTables[unit-1].disableNewEditor(true);

		alias.value = '';
		endpoint.value = '';
		port.value = eval('nvram.wg_iface'+unit+'_port');
		privkey.value = '';
		pubkey.value = '';
		psk.value = '';
		ip.value = '';
		allowedips.value = '';
		keepalive.value = 0;
		fwmark.value = 0;
	}

}

function editPeer(unit, rowIndex, quiet) {

	var ok = 1;

	var alias = E('_f_wg_iface'+unit+'_peer_alias');
	var endpoint = E('_f_wg_iface'+unit+'_peer_ep');
	var port = E('_f_wg_iface'+unit+'_peer_port');
	var privkey = E('_f_wg_iface'+unit+'_peer_privkey');
	var pubkey = E('_f_wg_iface'+unit+'_peer_pubkey');
	var psk = E('_f_wg_iface'+unit+'_peer_psk');
	var ip = E('_f_wg_iface'+unit+'_peer_ip');
	var allowedips = E('_f_wg_iface'+unit+'_peer_aip');
	var keepalive = E('_f_wg_iface'+unit+'_peer_ka');
	var fwmark = E('_f_wg_iface'+unit+'_peer_fwmark');

	var data = [
		alias.value,
		endpoint.value,
		privkey.value,
		pubkey.value,
		psk.value,
		ip.value,
		allowedips.value,
		keepalive.value
	];

	var results = verifyPeerFieldData(data);

	if (!results[2]) {
		ferror.set(privkey, 'A valid private key is required', quiet || !ok);	
		ok = 0;
	}
	else
		ferror.clear(privkey);

	if (!results[3]) {
		ferror.set(pubkey, 'A valid public key is required', quiet || !ok);	
		ok = 0;
	}
	else
		ferror.clear(pubkey);
		

	if (!results[4]) {
		ferror.set(psk, 'Preshared key is invalid', quiet || !ok);
		ok = 0;
	}
	else
		ferror.clear(psk);

	if (!results[5]) {
		ferror.set(ip, 'IP is invalid', quiet || !ok);
		ok = 0;
	}
	else
		ferror.clear(ip);

	if (!results[6]) {
		ferror.set(allowedips, 'Allowed IPs must be a comma separated list of CIDRs', quiet || !ok);
		ok = 0;
	}
	else 
		ferror.clear(keepalive);

	if (!results[7]) {
		ferror.set(keepalive, 'Keepalive is not within range 0-128', quiet || !ok);
		ok = 0;
	}
	else 
		ferror.clear(keepalive);

	if(ok) {
		changed = 1;
		var table = peerTables[unit-1];
		var row = peerTables[unit-1].tb.firstChild.rows[rowIndex];
		table.rowDel(row);
		table.insertData(rowIndex, data);
		table.disableNewEditor(true);

		alias.value = '';
		endpoint.value = '';
		port.value = eval('nvram.wg_iface'+unit+'_port');
		privkey.value = '';
		pubkey.value = '';
		psk.value = '';
		ip.value = '';
		allowedips.value = '';
		keepalive.value = 0;
		fwmark.value = 0;

		var button = E('wg_iface'+unit+'_peer_add');
		button.value = 'Add to Peers';
		button.setAttribute('onclick', 'addPeer('+unit+')');
	}

	}

function verifyPeerGenFields(unit) {

	/* verify interface has a valid private key */
	if (!window.wireguard.validateBase64Key(eval('nvram.wg_iface'+unit+'_key'))) {
		alert('The interface must have a valid private key before peers can be generated')
		return false;
	}

	/* verify peer fwmark*/
	var fwmark = E('_f_wg_iface'+unit+'_peer_fwmark').value;
	if (!verifyFWMark(fwmark)) {
		alert('The peer FWMark must be a hexadecimal string of 8 characters')
		return false;
	}

	return true;
}

function generatePeer(unit) {

	/* verify peer gen fields have valid data */
	if (!verifyPeerGenFields(unit))
		return;

	/* Generate keys */
	var keys = window.wireguard.generateKeypair();
	
	/* Generate PSK (if checked) */
	var psk = "";
	if (E('_f_wg_iface'+unit+'_peer_psk_gen').checked)
		psk = window.wireguard.generatePresharedKey();

	/* retrieve existing IPs of interface/peers to calculate new ip */
	var [interface_ip, interface_nm] = eval('nvram.wg_iface'+unit+'_ip.split("/", 2)');
	var existing_ips = peerTables[unit-1].getAllData();
	existing_ips = existing_ips.map(x => x[5].split('/',1)[0]);
	existing_ips.push(interface_ip);

	/* calculate ip of new peer */
	var ip = "";
	var network = getNetworkAddress(eval('nvram.wg_iface'+unit+'_ip'), CIDRToNetmask(interface_nm));
	var limit = 2 ** (32 - parseInt(interface_nm, 10));
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
		alert('Could not generate an IP for the peer');
		return;
	}

	/* set keepalive (if checked) */
	var keepalive = 0;
	if (E('_f_wg_iface'+unit+'_peer_ka_enable').checked)
		keepalive = 25;

	/* set fields with generated data */
	E('_f_wg_iface'+unit+'_peer_privkey').value = keys.privateKey;
	E('_f_wg_iface'+unit+'_peer_pubkey').value = keys.publicKey;
	E('_f_wg_iface'+unit+'_peer_pubkey').disabled = true;
	E('_f_wg_iface'+unit+'_peer_psk').value = psk;
	E('_f_wg_iface'+unit+'_peer_ip').value = `${ip}/32`;
	E('_f_wg_iface'+unit+'_peer_ka').value = keepalive;
	
}

function generatePeerConfig(unit) {
	
	var alias = E('_f_wg_iface'+unit+'_peer_alias');
	var endpoint = E('_f_wg_iface'+unit+'_peer_ep');
	var port = E('_f_wg_iface'+unit+'_peer_port');
	var privkey = E('_f_wg_iface'+unit+'_peer_privkey');
	var psk = E('_f_wg_iface'+unit+'_peer_psk');
	var ip = E('_f_wg_iface'+unit+'_peer_ip');
	var allowedips = E('_f_wg_iface'+unit+'_peer_aip');
	var keepalive = E('_f_wg_iface'+unit+'_peer_ka');

	var data = [
		true,
		alias.value,
		endpoint.value,
		privkey.value,
		psk.value,
		ip.value,
		allowedips.value,
		keepalive.value
	];

	/* verify fields before generating config */
	var ok = 1;
	var results = verifyPeerFieldData(data);

	if ((!port.value.match(/^ *[-\+]?\d+ *$/)) || (port.value < 1) || (port.value > 65535)) {
		ferror.set(port, 'A valid port must be provided to generate the configuration file', !ok);
		ok = 0;
	}
	else
		ferror.clear(port);

	if (!results[3]) {
		ferror.set(privkey, 'A valid private key must be provided to generate a configuration file', !ok);
		ok = 0;
	}
	else
		ferror.clear(privkey);

	if (!results[4]) {
		ferror.set(psk, 'A valid PSK must be provided or left blank to generate a configuration file', !ok);
		ok = 0;
	}
	else
		ferror.clear(psk);

	if (!results[5]) {
		ferror.set(psk, 'A valid IP CIDR must be provided to generate a configuration file', !ok);
		ok = 0;
	}
	else
		ferror.clear(psk);

	if (!ok)
		return;
	

	/* generate config */
	var alias = E('_f_wg_iface'+unit+'_peer_alias').value;
	var content = generateWGConfig(
		unit,
		data[1],
		data[3],
		data[4],
		data[5].split('/', 1)[0],
		port.value
	);

	/* download config file (if checked) */
	if (E('_f_wg_iface'+unit+'_peer_save').checked) {
		var filename = "peer.conf";
		if (alias != "")
			filename = `${alias}.conf`;
		downloadConfig(content, filename);
	}

	/* display config QR code (if checked) */
	if (E('_f_wg_iface'+unit+'_peer_qr_enable').checked) {
		var qrcode = E('wg_iface'+unit+'_qrcode');
		var qrcode_content = content.join('');
		var image = showQRCode(qrcode_content, 40);
		image.style.maxWidth = "700px";
		qrcode.replaceChild(image, qrcode.firstChild);
		elem.display('wg_iface'+unit+'_qrcode', true);
	}

}

function generateWGConfig(unit, name, privkey, psk, ip, port) {
	
	var [interface_ip, interface_nm] = eval('nvram.wg_iface'+unit+'_ip.split("/", 2)');
	var content = [];
	var dns = eval('nvram.wg_iface'+unit+'_dns');
	var fwmark = E('_f_wg_iface'+unit+'_peer_fwmark').value;

	/* build interface section */
	content.push("[Interface]\n");

	if (name != "")
		content.push(`#Alias = ${name}\n`);

	content.push(
		`Address = ${ip}/${interface_nm}\n`,
		`ListenPort = ${port}\n`,
		`PrivateKey = ${privkey}\n`,
	);

	if (dns != "")
		content.push(`DNS = 0x${dns}\n`)

	if (fwmark != "0")
		content.push (`FwMark = ${fwmark}\n`);

	/* build router peer */
	var publickey_interface = window.wireguard.generatePublicKey(eval('nvram.wg_iface'+unit+'_key'));
	var keepalive_interface = eval('nvram.wg_iface'+unit+'_ka');
	var endpoint = eval('nvram.wg_iface'+unit+'_endpoint');
	if (!endpoint)
		endpoint = nvram.wan_ipaddr;
	endpoint += ":" + eval('nvram.wg_iface'+unit+'_port');
	var allowed_ips;

	/* build allowed ips for router peer */
	if (eval('nvram.wg_iface'+unit+'_rgw') == "1") {
		allowed_ips = "0.0.0.0/0"
	}
	else {
		var netmask;
		if (eval('nvram.wg_iface'+unit+'_lan') == "1") {
			netmask = '/' + interface_nm;
		}
		else {
			netmask = "/32";
		}
		allowed_ips = interface_ip + netmask;
		for(let i = 0; i <= 3; i++){
			if (eval('nvram.wg_iface'+unit+'_lan'+i) == "1") {
				let t = (i == 0 ? '' : i);
				var nm = eval(`nvram.lan${t}_netmask`);
				var network_ip = getNetworkAddress(eval(`nvram.lan${t}_ipaddr`), nm);
				allowed_ips += ',';
				allowed_ips += network_ip;
				allowed_ips += '/';
				allowed_ips += netmaskToCIDR(nm);
			}
		}
		var interface_allowed_ips = eval('nvram.wg_iface'+unit+'_aip');
		if (interface_allowed_ips != '')
			allowed_ips += ',' + interface_allowed_ips;
	}

	/* populate router peer */
	content.push(
		"\n",
		"[Peer]\n",
		"#Alias = Router\n",
		`PublicKey = ${publickey_interface}\n`
	);

	if (psk != "") {
		content.push(`PresharedKey = ${psk}\n`);
	}

	content.push(
		`AllowedIPs = ${allowed_ips}\n`,
		`Endpoint = ${endpoint}\n`
	);

	if (keepalive_interface != "0") {
		content.push(`PersistentKeepalive = ${keepalive_interface}\n`);
	}

	/* add remaining peers to config */
	if (eval('nvram.wg_iface'+unit+'_lan') == "1") {
		var interface_peers = peerTables[unit-1].getAllData();
		
		for (var i = 0; i < interface_peers.length; ++i) {
			var peer = interface_peers[i]

			if (peer[3] == window.wireguard.generatePublicKey(privkey)) {
				continue;
			}

			content.push(
				"\n",
				"[Peer]\n",
			);

			if (peer[1] != "")
				content.push(`#Alias = ${peer[1]}\n`,);

			if (peer[0] == 1)
				content.push(`PublicKey = ${window.wireguard.generatePublicKey(peer[3])}\n`,);
			else
				content.push(`PublicKey = ${peer[3]}\n`,);

			if (peer[4] != "")
				content.push(`PresharedKey = ${peer[4]}\n`,);

			content.push(`AllowedIPs = ${peer[5]}`,);
			if (peer[6] != "")
				content.push(`,${peer[6]}`,);
			content.push('\n');

			if (peer[7] != "0")
				content.push(`PersistentKeepalive = ${peer[7]}\n`,);

			if (peer[1] != "")
				content.push(`Endpoint = ${peer[1]}\n`);
			
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

function verifyCIDR(cidr) {
	return cidr.match(/(([1-9]{0,1}[0-9]{0,2}|2[0-4][0-9]|25[0-5])\.){3}([1-9]{0,1}[0-9]{0,2}|2[0-4][0-9]|25[0-5])\/([1-2][0-9]|3[0-2])/)
}

function verifyFWMark(fwmark) {
	return fwmark == '0' || fwmark.match(/[0-9A-Fa-f]{8}/);
}

function verifyFields(focused, quiet) {
	var ok = 1;

	/* When settings change, make sure we restart the right services */
	if (focused) {
		changed = 1;

		var fom = E('t_fom');
		var serveridx = focused.name.indexOf('iface');
		if (serveridx >= 0) {
			var num = focused.name.substring(serveridx + 5, serveridx + 6);

			updateForm(num);

			if (focused.name.indexOf('_dns') >= 0 && fom._service.value.indexOf('dnsmasq') < 0) {
				if (fom._service.value != '')
					fom._service.value += ',';

				fom._service.value += 'dnsmasq-restart';
			}

		}
	}

	for (var i = 1; i <= WG_INTERFACE_COUNT; i++) {

		/* autopopulate port if it's empty */
		var port = E('_wg_iface'+i+'_port')
		if (port.value == '') {
			port.value = 51819+i;
			ferror.clear(port);
		}
		/* otherwise verify valid port */
		else {
			if (!port.value.match(/^ *[-\+]?\d+ *$/) || (port.value < 1) || (port.value > 65535)) {
				ferror.set(port, 'The interface port must be a valid port', quiet || !ok);
				ok = 0;
			}
			else
				ferror.clear(port);
		}

		/* disable lan checkbox if lan is not in use */
		for (let j = 0; j <= 3; ++j) {
			t = (j == 0 ? '' : j);

			if (eval('nvram.lan'+t+'_ifname.length') < 1) {
				E('_f_wg_iface'+i+'_lan'+t).checked = 0;
				E('_f_wg_iface'+i+'_lan'+t).disabled = 1;
			}
		}

		/* verify interface private key */
		var privkey = E('_wg_iface'+i+'_key');
		if (privkey.value != '' && !window.wireguard.validateBase64Key(privkey.value)) {
			ferror.set(privkey, 'A valid private key is required for the interface', quiet || !ok);
			ok = 0;
		}
		else
			ferror.clear(privkey);

		/* calculate interface pubkey */
		E('_wg_iface'+i+'_pubkey').disabled = true;
		var pubkey = window.wireguard.generatePublicKey(privkey.value);
		if(pubkey == false) {
			pubkey = "";
		}
		E('_wg_iface'+i+'_pubkey').value = pubkey;

		/* autopopulate IP if it's empty */
		var ip = E('_wg_iface'+i+'_ip')
		if (ip.value == '') {
			ip.value = '10.'+(10+i)+'.0.1/24';
			ferror.clear(ip);
		}
		/* otherwise verify interface CIDR address */
		else {
			if (!verifyCIDR(ip.value)) {
				ferror.set(ip, 'A valid CIDR address is required for the interface', quiet || !ok);
				ok = 0;
			}
			else
				ferror.clear(ip);
		}

		/* autopopulate fwmark if it's empty */
		var fwmark = E('_wg_iface'+i+'_fwmark');
		if (fwmark.value == '') {
			fwmark.value = '0';
			ferror.clear(fwmark);
		}
		/* otherwise verify interface fwmark */
		else {
			if (!verifyFWMark(fwmark.value)) {
				ferror.set(fwmark, 'The interface FWMark must be a hexadecimal string of 8 characters', quiet || !ok);
				ok = 0;
			}
			else
				ferror.clear(fwmark);
		}

		/* autopopulate mtu if it's empty */
		var mtu = E('_wg_iface'+i+'_mtu');
		if (mtu.value == '') {
			mtu.value = '1420';
			ferror.clear(mtu);
		}
		/* otherwise verify interface mtu */
		else {
			if ((!mtu.value.match(/^ *[-\+]?\d+ *$/)) || (mtu.value < 0) || (mtu.value > 1500)) {
				ferror.set(mtu, 'The interface MTU must be a integer between 0 and 1500', quiet || !ok);
				ok = 0;
			}
			else
				ferror.clear(mtu);
		}

		/* autopopulate keepalive if it's empty */
		var keepalive = E('_wg_iface'+i+'_ka');
		if (keepalive.value == '') {
			keepalive.value = '0';
			ferror.clear(keepalive);
		}
		/* otherwise verify interface keepalive */
		else {
			if ((!keepalive.value.match(/^ *[-\+]?\d+ *$/)) || (keepalive.value < 0) || (keepalive.value > 128)) {
				ferror.set(keepalive, 'The keepalive value to the interface must be a number between 0 and 128', quiet || !ok);
				ok = 0;
			}
			else
				ferror.clear(keepalive);
		}

		/* verify interface allowed ips */
		var allowed_ips = E('_wg_iface'+i+'_aip')
		var aip_valid = true;
		if(allowed_ips.value != '') {
			var cidrs = allowed_ips.value.split(',')
			for(var i = 0; i < cidrs.length; i++) {
				var cidr = cidrs[i].trim();
				if (!cidr.match(/^([0-9]{1,3}\.){3}[0-9]{1,3}(\/([0-9]|[1-2][0-9]|3[0-2]))?$/)) {
					aip_valid = false;
					break;
				}
			}
		}
		if (!aip_valid) {
			ferror.set(allowed_ips, 'The interface allowed ips must be a comma separated list of valid CIDRs', quiet || !ok);
			ok = 0;
		}
		else
			ferror.clear(allowed_ips);

		/*** peer key checking stuff ***/
		var peer_privkey = E('_f_wg_iface'+i+'_peer_privkey');
		var peer_pubkey = E('_f_wg_iface'+i+'_peer_pubkey');

		/* if both private and public key fields are empty, make sure they're enabled */
		if (! (window.wireguard.validateBase64Key(peer_privkey.value) || window.wireguard.validateBase64Key(peer_pubkey.value))) {
			peer_privkey.disabled = false;
			peer_pubkey.disabled = false;
		}

		/* if only private key is populated, generate the public key and lock it (only if privkey is valid) */
		else if (peer_privkey.value && !peer_pubkey.value) {
			var pubkey_temp = window.wireguard.generatePublicKey(peer_privkey.value);
			if(pubkey_temp == false) {
				peer_pubkey.value = "";
				peer_pubkey.disabled = false;
			}
			else {
				peer_pubkey.value = pubkey_temp;
				peer_pubkey.disabled = true;
			}
		}

		/* if only public key is populated with a valid key, lock the private key */
		else if (!peer_privkey.value && window.wireguard.validateBase64Key(peer_pubkey.value)) {
			peer_pubkey.disabled = false;
			peer_privkey.disabled = true;
		}

	}

	return ok;
}

function save(nomsg) {
	
	if (!verifyFields(null, 0))
		return;
		
	if (!nomsg) show(); /* update '_service' field first */

	var fom = E('t_fom');
	for (var i = 1; i <= WG_INTERFACE_COUNT; i++) {

		var privkey = E('_wg_iface'+i+'_key').value;
		eval('nvram.wg_iface'+i+'_key = privkey');

		var data = peerTables[i-1].getAllData();
		var s = '';
		for (var j = 0; j < data.length; ++j)
			s += data[j].join('<')+'>';

		eval('fom.wg_iface'+i+'_peers.value = s');
		eval('nvram.wg_iface'+i+'_peers = s');

		eval('fom.wg_iface'+i+'_eas.value = fom._f_wg_iface'+i+'_eas.checked ? 1 : 0');
		eval('fom.wg_iface'+i+'_lan.value = fom._f_wg_iface'+i+'_lan.checked ? 1 : 0');
		eval('fom.wg_iface'+i+'_lan0.value = fom._f_wg_iface'+i+'_lan0.checked ? 1 : 0');
		eval('fom.wg_iface'+i+'_lan1.value = fom._f_wg_iface'+i+'_lan1.checked ? 1 : 0');
		eval('fom.wg_iface'+i+'_lan2.value = fom._f_wg_iface'+i+'_lan2.checked ? 1 : 0');
		eval('fom.wg_iface'+i+'_lan3.value = fom._f_wg_iface'+i+'_lan3.checked ? 1 : 0');
		eval('fom.wg_iface'+i+'_rgw.value = fom._f_wg_iface'+i+'_rgw.checked ? 1 : 0');

		if (E('_f_wg_iface'+i+'_dns').checked)
			E('wg_iface_dns').value += ''+i+',';
		
	}

	form.submit(fom, 1);

	changed = 0;
}

function earlyInit() {
	show();
	tabSelect(cookie.get('wg_iface_tab') || tabs[0][0]);
	for (var i = 0; i < tabs.length; ++i) {
		sectSelect(i, cookie.get('wg_iface'+i+'_section') || sections[0][0]);
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
<input type="hidden" name="wg_iface_dns" id="wg_iface_dns">

<!-- / / / -->

<div class="section-title">Wireguard Configuration</div>
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
			W('<div class="section-title">Interface Configuration</div>');
			createFieldTable('', [
				{ title: 'Enable on Start', name: 'f_wg_'+t+'_eas', type: 'checkbox', value: eval('nvram.wg_'+t+'_eas') == '1' },
				{ title: 'Config file', name: 'wg_'+t+'_file', type: 'text', placeholder: '(optional)', maxlen: 64, size: 64, value: eval('nvram.wg_'+t+'_file') },
				{ title: 'Port', name: 'wg_'+t+'_port', type: 'text', maxlen: 5, size: 10, value: eval('nvram.wg_'+t+'_port') },
				{ title: 'Private Key', multi: [
					{ title: '', name: 'wg_'+t+'_key', type: 'password', maxlen: 44, size: 44, value: eval('nvram.wg_'+t+'_key'), peekaboo: 1 },
					{ title: '', custom: '<input type="button" value="Generate" onclick="generateInterfaceKey('+(i+1)+')" id="wg_'+t+'_keygen">' },
				] },
				{ title: 'Public Key', multi: [
					{ title: '', name: 'wg_'+t+'_pubkey', type: 'text', maxlen: 44, size: 44, disabled: ""},
					{ title: '', custom: '<input type="button" value="Copy" onclick="copyInterfacePubKey('+(i+1)+')" id="wg_'+t+'_pubkey_copy">' },
				] },
				{ title: 'Interface IP', name: 'wg_'+t+'_ip', type: 'text', maxlen: 32, size: 17, value: eval('nvram.wg_'+t+'_ip'), placeholder },
				{ title: 'FWMark', name: 'wg_'+t+'_fwmark', type: 'text', maxlen: 8, size: 8, value: eval('nvram.wg_'+t+'_fwmark') },
				{ title: 'MTU', name: 'wg_'+t+'_mtu', type: 'text', maxlen: 4, size: 4, value: eval('nvram.wg_'+t+'_mtu') },
				{ title: 'Respond to DNS', name: 'f_wg_'+t+'_dns', type: 'checkbox', value: nvram.wg_iface_dns.indexOf(''+(i+1)) >= 0 },
			]);
			W('<br>');
			W('<div class="section-title">Peer Configuration</div>');
			createFieldTable('', [
				{ title: 'Keepalive to Router', name: 'wg_'+t+'_ka', type: 'text', maxlen: 2, size: 4, value: eval('nvram.wg_'+t+'_ka') },
				{ title: 'Endpoint', name: 'wg_'+t+'_endpoint', type: 'text', maxlen: 64, size: 64, placeholder: '(leave blank to use WAN IP)', value: eval('nvram.wg_'+t+'_endpoint') },
				{ title: 'Allowed IPs', name: 'wg_'+t+'_aip', type: 'text', placeholder: "(CIDR format)", maxlen: 128, size: 64, value: eval('nvram.wg_'+t+'_aip') },
				{ title: 'DNS Servers', name: 'wg_'+t+'_dns', type: 'text', maxlen: 128, size: 64, value: eval('nvram.wg_'+t+'_dns') },
				{ title: 'Allow peers to communicate', name: 'f_wg_'+t+'_lan', type: 'checkbox', value: eval('nvram.wg_'+t+'_lan') == '1'},
				{ title: 'Push LAN0 (br0) to peers', name: 'f_wg_'+t+'_lan0', type: 'checkbox', value: eval('nvram.wg_'+t+'_lan0') == '1' },
				{ title: 'Push LAN1 (br1) to peers', name: 'f_wg_'+t+'_lan1', type: 'checkbox', value: eval('nvram.wg_'+t+'_lan1') == '1' },
				{ title: 'Push LAN2 (br2) to peers', name: 'f_wg_'+t+'_lan2', type: 'checkbox', value: eval('nvram.wg_'+t+'_lan2') == '1' },
				{ title: 'Push LAN3 (br3) to peers', name: 'f_wg_'+t+'_lan3', type: 'checkbox', value: eval('nvram.wg_'+t+'_lan3') == '1' },
				{ title: 'Forward all peer traffic', name: 'f_wg_'+t+'_rgw', type: 'checkbox', value: eval('nvram.wg_'+t+'_rgw') == '1' },
			]);
			W('</div>');
			W('<div id="'+t+'-scripts">');
			W('<div class="section-title">Custom Interface Scripts</div>');
			createFieldTable('', [
				{ title: 'Pre-Up Script', name: 'wg_'+t+'_preup', type: 'textarea', value: eval('nvram.wg_'+t+'_preup') },
				{ title: 'Post-Up Script', name: 'wg_'+t+'_postup', type: 'textarea', value: eval('nvram.wg_'+t+'_postup') },
				{ title: 'Pre-Down Script', name: 'wg_'+t+'_predown', type: 'textarea', value: eval('nvram.wg_'+t+'_predown') },
				{ title: 'Post-Down Script', name: 'wg_'+t+'_postdown', type: 'textarea', value: eval('nvram.wg_'+t+'_postdown') },
			]);
			W('</div>');
			W('<div id="'+t+'-peers">');
			W('<div class="section-title">Peers</div>');
			W('<div class="tomato-grid" id="'+t+'-peers-grid"><\/div>');
			peerTables[i].setup();
			W('<br>');
			W('<div class="section-title">Peer Generation</div>');
			createFieldTable('', [
				{ title: 'Generate PSK', name: 'f_wg_'+t+'_peer_psk_gen', type: 'checkbox', value: true },
				{ title: 'Send Keepalive to this peer', name: 'f_wg_'+t+'_peer_ka_enable', type: 'checkbox', value: false},
			]);
			W('<input type="button" value="Generate Peer" onclick="generatePeer('+(i+1)+')" id="wg_'+t+'_peer_gen">');
			W('<br>');
			W('<br>');
			W('<div class="section-title">Peer Parameters</div>');
			createFieldTable('', [
				{ title: 'Alias', name: 'f_wg_'+t+'_peer_alias', type: 'text', maxlen: 32, size: 32},
				{ title: 'Endpoint', name: 'f_wg_'+t+'_peer_ep', type: 'text', maxlen: 64, size: 64},
				{ title: 'Port', name: 'f_wg_'+t+'_peer_port', type: 'text', maxlen: 5, size: 10, value: eval('nvram.wg_'+t+'_port')},
				{ title: 'Private Key', name: 'f_wg_'+t+'_peer_privkey', type: 'text', maxlen: 44, size: 44},
				{ title: 'Public Key', name: 'f_wg_'+t+'_peer_pubkey', type: 'text', maxlen: 44, size: 44},
				{ title: 'Preshared Key', name: 'f_wg_'+t+'_peer_psk', type: 'text', maxlen: 44, size: 44},
				{ title: 'Interface IP', name: 'f_wg_'+t+'_peer_ip', type: 'text', placeholder: "(CIDR format)", maxlen: 64, size: 64},
				{ title: 'Allowed IPs', name: 'f_wg_'+t+'_peer_aip', type: 'text', placeholder: "(CIDR format)", maxlen: 128, size: 64},
				{ title: 'Keepalive to this peer', name: 'f_wg_'+t+'_peer_ka', type: 'text', maxlen: 2, size: 4, value: "0"},
				{ title: 'FWMark for this peer', name: 'f_wg_'+t+'_peer_fwmark', type: 'text', maxlen: 8, size: 8, value: '0'},
				{ title: 'Generate Config QR Code', name: 'f_wg_'+t+'_peer_qr_enable', type: 'checkbox', value: true },
				{ title: 'Save Config to File', name: 'f_wg_'+t+'_peer_save', type: 'checkbox', value: true },
			]);
			W('<div>');
			W('<input type="button" value="Add to Peers" onclick="addPeer('+(i+1)+')" id="wg_'+t+'_peer_add">');
			W('<input type="button" value="Generate Config" onclick="generatePeerConfig('+(i+1)+')" id="wg_'+t+'_peer_config">');
			W('</div>');
			W('<div id="wg_'+t+'_qrcode" class="qrcode" style="display:none">');
			W('<img alt="wg_'+t+'_qrcode_img" style="max-width: 100px;">');
			W('<div id="wg_'+t+'_qrcode_labels" class="qrcode-labels" title="Message">');
			W('Point your mobile phone camera<br>');
			W('here above to connect automatically');
			W('</div>');
			W('</div>');
			W('</div>');
			W('<div class="vpn-start-stop"><input type="button" value="" onclick="" id="_wireguard'+(i+1)+'_button">&nbsp; <img src="spin.gif" alt="" id="spin'+(i+1)+'"></div>');
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
