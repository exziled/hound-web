

var DATA = {
	tempc: 55,
	vrms_1: 120.5,
	irms_1: 1.25,
	vrms_2: 120.5,
	irms_2: 1.25,
};

var OUTPUT = {
	email: [],
	sms:[],
	control:{
	}
}

function setOutlet (num, on) {
	OUTPUT.control['outlet'+num.valueOf()] = on;
}
function getTemp () {
	return DATA.tempc;
}
function getIrms (socket) {
	if (socket == 1)
		return DATA.irms_1;
	return DATA.irms_2;
}
function getVrms (socket) {
	if (socket == 1)
		return DATA.vrms_1;
	return DATA.vrms_2;
}

{{code}}

console.log(JSON.stringify(OUTPUT));