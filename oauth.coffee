oauthserver = Npm.require('oauth2-server')
express = Npm.require('express')

# WebApp.rawConnectHandlers.use app
# JsonRoutes.Middleware.use app


class OAuth2Server
	constructor: (@config={}) ->
		@app = express()

		@routes = express()

		@model = new Model(@config)

		@oauth = oauthserver
			model: @model
			grants: ['authorization_code', 'refresh_token']
			debug: @config.debug

		@publishAuhorizedClients()
		@initRoutes()

		return @


	publishAuhorizedClients: ->
		Meteor.publish 'authorizedOAuth', ->
				if not @userId?
					return @ready()

				return Meteor.users.find
					_id: @userId
				,
					fields:
						'oauth.athorizedClients': 1

				return user?


	initRoutes: ->
		@app.all '/oauth/token', @oauth.grant()


		@app.post '/oauth/authorize', Meteor.bindEnvironment (req, res, next) ->
			if not req.body.token?
				return res.sendStatus(401).send('No token')

			user = Meteor.users.findOne
				'services.resume.loginTokens.hashedToken': Accounts._hashLoginToken req.body.token

			if not user?
				return res.sendStatus(401).send('Invalid token')

			req.user =
				id: user._id

			next()


		@app.post '/oauth/authorize', @oauth.authCodeGrant (req, next) ->
			if req.body.allow is 'yes'
				Meteor.users.update req.user.id, {$addToSet: {'oauth.athorizedClients': @clientId}}

			next(null, req.body.allow is 'yes', req.user)

		@app.use @routes

		@app.use @oauth.errorHandler()