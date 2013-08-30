$().ready(function () {
	// KO
	var userId = $('.user').val();
	var vm = new ViewModel();
	ko.applyBindings(vm);
	$.get('/messages', function (result) {
		result.forEach(function (item) {
			vm.messages.push(item);	
		});
	});

	//Page Setup
	$('.dropdown-toggle').click(function () {
		var link = $(this);
		var ddContainer = link.parent();
		if (ddContainer.hasClass('open')) {
			$.post('/mark-read', vm.markRead());
			ddContainer.removeClass('open');
		} else {
			ddContainer.addClass('open');
		}
	});

	// Pusher
	Pusher.log = function(message) {
		if (window.console && window.console.log) {
			window.console.log(message);
		}
	}
	
	var pusher = new Pusher('5b163daa1581a4ffad4f');

	var channel = pusher.subscribe('private-user-'+userId);
	channel.bind('my_event', function(data) {
		vm.messages.push(data);
	});
});

function ViewModel () {
	var messages = ko.observableArray();

	var messageCount = ko.computed(function () {
		return messages().length;
	});

	var dismiss = function (item) {
		$.post('/dismiss-message/' + item._id, function (result) {
			messages.remove(item);
		});
	};

	var markRead = function () {
		//Should probably use underscore or filter or something here but I am too lazy
		messages().forEach(function (item) {
			item.read = false;
		});
	};

	return {
		messages: messages,
		messageCount: messageCount,
		markRead: markRead,
		dismiss: dismiss
	};
}