/*
 * Copyright (c) 2019 HELIOS Software GmbH
 * 30827 Garbsen (Hannover) Germany
 * Licensed under the Apache License, Version 2.0
 */

if (typeof MQTT === 'undefined') {
	MQTT = new Object();
}

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
