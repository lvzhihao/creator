Package.describe({
	name: 'steedos:app-admin',
	version: '0.0.1',
	summary: 'Creator admin',
	git: '',
	documentation: null
});

Package.onUse(function(api) {

	api.use('steedos:creator@0.0.3');
	api.use('coffeescript@1.11.1_4');
	api.addFiles('admin.app.coffee');
});