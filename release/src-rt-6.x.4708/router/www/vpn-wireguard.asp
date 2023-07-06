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
<script src="isup.jsz"></script>
<script src="isup.js"></script>
<script src="tomato.js"></script>

<script>

//	<% nvram("_http_id"); %>

var changed = 0;
var serviceType = 'wireguard';

function verifyFields(focused, quiet) {
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

	form.submit(fom, 1);

	changed = 0;
}

function earlyInit() {
	//show();
	//verifyFields(null, 1);
}

function init() {
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

<div class="section-title">Wireguard</div>
<div class="section">
	<script>
		createFieldTable('', [
			{ title: 'Enable on Start', name: 'f_wg_server_eas', type: 'checkbox', value: nvram.wg_server_eas == '1' },
			{ title: 'Local IP', name: 'f_wg_server_localip', type: 'text', maxlen: 15, size: 17, value: nvram.wg_server_localip },
			{ title: 'Subnet/Netmask', multi: [
				{ name: 'f_wg_server_sn', type: 'text', maxlen: 15, size: 17, value: nvram.wg_server_sn },
				{ name: 'f_wg_server_nm', type: 'text', maxlen: 15, size: 17, value: nvram.wg_server_nm }
			] },
		]);
	</script>
	<div class="vpn-start-stop"><input type="button" value="" onclick="" id="_wg_server_button">&nbsp; <img src="spin.gif" alt="" id="spin"></div>
</div>

<!-- / / / -->

<div class="section-title">Notes <small><i><a href='javascript:toggleVisibility(cprefix,"notes");'><span id="sesdiv_notes_showhide">(Show)</span></a></i></small></div>
<div class="section" id="sesdiv_notes" style="display:none">
	<ul>
		<li><b>Local IP Address/Netmask</b> - Address to be used at the local end of the tunnelled PPP links between the server and the VPN clients.</li>
		<li><b>Remote IP Address Range</b> - Remote IP addresses to be used on the tunnelled PPP links (max 6).</li>
		<li><b>Broadcast Relay Mode</b> - Turns on broadcast relay between VPN clients and LAN interface.</li>
		<li><b>Enable Encryption</b> - Enabling this option will turn on VPN channel encryption, but it might lead to reduced channel bandwidth.</li>
		<li><b>DNS Servers</b> - Allows defining DNS servers manually (if none are set, the router/local IP address should be used by VPN clients).</li>
		<li><b>WINS Servers</b> - Allows configuring extra WINS servers for VPN clients, in addition to the WINS server defined on <a href="advanced-dhcpdns.asp">Advanced: DHCP / DNS</a>.</li>
		<li><b>MTU</b> - Maximum Transmission Unit. Max packet size the PPTP interface will be able to send without packet fragmentation.</li>
		<li><b>MRU</b> - Maximum Receive Unit. Max packet size the PPTP interface will be able to receive without packet fragmentation.</li>
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
