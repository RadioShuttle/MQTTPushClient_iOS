/* 24.2 30 */
var res = content.match(/[+-]?\d+(\.\d+)?/g);
if (res && res.length >= 2) {
 content = "Temperature: " + res[0] + "°, Humidity: " + res[1] + "%";
}
