var b = new Uint8Array(msg.raw);
var width = 8;
content = '';
var hexStr, lineHex, lineAsc, offset;
for(var i = 0; i < b.length; i += width) {
 lineHex = ''; lineAsc = '';
 for(var j = 0; j < width && j + i < b.length; j++) {
  hexStr = b[i + j].toString(16);
  if (hexStr.length % 2) {
   hexStr = '0' + hexStr;
  }
  lineHex += hexStr + ' ';
  if (b[i + j] >= 32 && b[i + j] <= 126) {
   lineAsc += String.fromCharCode(b[i + j]);
  } else {
   lineAsc += '.';
  }
 }
 for(var z = 0; z < width - j; z++) {
  lineHex += ' ';
 }
 offset = i.toString(16);
 if (offset.length % 2) {
  offset = '0' + offset;
 }
 content += offset + ': ' + lineHex + lineAsc + '\n';
}
