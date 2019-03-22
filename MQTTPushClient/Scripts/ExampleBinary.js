/* 12 bytes: uint16, uint16, float32, float32 (little endian) */
if (msg.raw.byteLength >= 12) {
	var dv = new DataView(msg.raw);
	if (dv.getUint16(0, true) == 33841) {
		var t = dv.getFloat32(4, true);
		var h = dv.getFloat32(8, true);
		content = 'Temperature: ' + t.toFixed(1) + '° , Humidity: ' + h.toFixed(1) + '%';
	}
}
