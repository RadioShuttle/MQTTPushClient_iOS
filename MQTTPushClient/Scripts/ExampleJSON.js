/* {"t" : 24, "h" : 30} */
var j = JSON.parse(content);
if (j.t && j.h) {
 content = "Temperature: " + j.t + "°, Humidity: " + j.h + "%";
}
