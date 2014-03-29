if (typeof console == 'undefined')
{
	console = {};
};

$(document).ready(function()
{
	$("img.tex").on('click', function(e)
	{
		console.log("Clicked",e.target);
		$body = $('body');

		$body.append('<div>');
	});
});