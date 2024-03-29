/*
 * Copyright (c) 2019 HELIOS Software GmbH
 * 30827 Garbsen (Hannover) Germany
 * Licensed under the Apache License, Version 2.0
 */

if (typeof MQTT === 'undefined') {
	MQTT = new Object();
}

MQTT._versionID = '0';
MQTT._requestRunning = false;

window.addEventListener('error', function (e) {
  var message = {
    message: e.message,
    url: e.filename,
    line: e.lineno,
    column: e.colno,
    versionID: MQTT._versionID,
    error: JSON.stringify(e.error)
  };
  window.webkit.messageHandlers.error.postMessage(message);
});

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
	if (!MQTT._requestRunning && topic && topic.length > 0) {
		if (typeof msg === 'string') {
			var message = {retain: retain === true, topic: topic, msg_str: msg, versionID: MQTT._versionID};
			window.webkit.messageHandlers.publish.postMessage(message);
			MQTT._requestRunning = true;
			requestStarted = true;
		} else if (msg instanceof ArrayBuffer) {
			var message = {retain: retain === true, topic: topic, msg: MQTT.buf2hex(msg), versionID: MQTT._versionID};
			window.webkit.messageHandlers.publish.postMessage(message);
			MQTT._requestRunning = true;
			requestStarted = true;
		} else {
			throw "MQTT.publish(): arg msg must be of type String or ArrayBuffer";
		}
	}
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

MQTT.view._historicalData = [];
function _addHistDataMsg(receivedDateMillis, topic, payloadStr, payloadHEX) {
	var msg = new Object();
	if (!payloadHEX) payloadHEX = '';
	if (!payloadStr) payloadStr = '';
	msg.receivedDate = new Date(Number(receivedDateMillis));
	msg.topic = topic;
	msg.text = payloadStr;
	msg.raw = MQTT.hex2buf(payloadHEX);
	MQTT.view._historicalData.push(msg);
	while(MQTT.view._historicalData.length > 1000) {
		MQTT.view._historicalData.shift();
	}
}

MQTT.view.getHistoricalData = function() {
	return MQTT.view._historicalData;
};

MQTT.view._background = MQTT.Color.OS_DEFAULT;
MQTT.view.getBackgroundColor = function() {
	return MQTT.view._background;
};

MQTT.view.setBackgroundColor = function(color) {
	MQTT.view._background = color;
	window.webkit.messageHandlers.setBackgroundColor.postMessage({versionID: MQTT._versionID, color: color});
};

MQTT.view._subscribedTopic = '';
MQTT.view.getSubscribedTopic = function() {
	return MQTT.view._subscribedTopic;
};

MQTT.view._userData = null;
MQTT.view.setUserData = function(data) {
	var jsonStr = JSON.stringify(data);
	if (jsonStr.length > 1048576) {
		throw "User data is limited to 1 MB.";
	}
	window.webkit.messageHandlers.setUserData.postMessage({versionID: MQTT._versionID, jsonStr: jsonStr});
}
MQTT.view.getUserData = function() {
	return MQTT.view._userData;
}
