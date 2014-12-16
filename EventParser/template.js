

var DATA = {{data}};

var OUTPUT = {
	email: [],
	sms:[],
	control:{
	}
}

function setOutlet (num, on) {
	OUTPUT.control['outlet'+num.valueOf()] = on;
}
function getTemp (cf, sensor) {
	if (cf = 'C') {
		if (sensor == 1)
			return DATA.tempc_1;
		return DATA.tempc_2;
	} else {
		if (sensor == 1)
			return DATA.tempc_1 * 9 / 5 + 32;
		return DATA.tempc_2 * 9 / 5 + 32;
	}
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

function sendEmail (addy, message) {
	var em = {
		address:addy,
		subject:"Message from H.O.U.N.D.",
		message:message
	};
	OUTPUT.email.push(em)
}

{{code}}

// console.log(JSON.stringify(OUTPUT));
OUTPUT;