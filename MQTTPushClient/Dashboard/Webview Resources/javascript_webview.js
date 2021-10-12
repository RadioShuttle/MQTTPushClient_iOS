/*
 * Copyright (c) 2019 HELIOS Software GmbH
 * 30827 Garbsen (Hannover) Germany
 * Licensed under the Apache License, Version 2.0
 */

window.addEventListener('error', function (e) {
  var message = {
    message: e.message,
    url: e.filename,
    line: e.lineno,
    column: e.colno,
    error: JSON.stringify(e.error)
  }
  window.webkit.messageHandlers.error.postMessage(message);
});

if (typeof MQTT === 'undefined') {
	MQTT = new Object();
}

MQTT.log = function(msg) {
	window.webkit.messageHandlers.log.postMessage(msg);
};

MQTT.buf2hex = function (buffer) {
	var byteArray = new Uint8Array(buffer);
	var hexStr = '';
	for(var i = 0; i < byteArray.length; i++) {
		var hex = byteArray[i].toString(16);
		var paddedHex = ('00' + hex).slice(-2);
		hexStr += paddedHex;
	}
	return hexStr;
};

MQTT.hex2buf = function (hex) {
	if (!hex) {
		hex = '';
	}
	if (hex.length % 2 == 1) {
		hex = '0' + hex;
	}
	var buf = new ArrayBuffer(hex.length / 2);
	var dv = new DataView(buf);
	var j = 0;
	for(var i = 0; i < hex.length; i += 2) {
		dv.setUint8(j, parseInt(hex.substring(i, i + 2), 16));
		j++;
	}
	return buf;
};

MQTT.publish = function (topic, msg, retain) {
	var requestStarted = false;
	//TODO:
	/*
	if (typeof msg === 'string') {
		requestStarted = MQTT._publishStr(topic, msg, retain === true);
	} else if (msg instanceof ArrayBuffer) {
		requestStarted = MQTT._publishHex(topic, MQTT.buf2hex(msg), retain === true);
	} else {
		throw "MQTT.publish(): arg msg must be of type String or ArrayBuffer";
	}
	 */
	return requestStarted;
};

function _onMqttMessage(receivedDateMillis, topic, payloadStr, payloadHEX) {
	var msg = new Object();
	if (!payloadHEX) payloadHEX = '';
	if (!payloadStr) payloadStr = '';
	msg.receivedDate = new Date(Number(receivedDateMillis));
	msg.topic = topic;
	msg.text = payloadStr;
	msg.raw = MQTT.hex2buf(payloadHEX);
	onMqttMessage(msg);
}

MQTT.view = new Object();
MQTT.view._parameters = [];
MQTT.view.getParameters = function() {
	return MQTT.view._parameters;
};
