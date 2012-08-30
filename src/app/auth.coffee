

define ['lib/crypto', 'lib/promises', 'lib/s3'], (crypto, promises, s3) ->
	
	{sha1, aes} = crypto
	
	siteName = location.hash.replace(/^#\/([^\/]+).*/, '$1')
	path = "/#{siteName}/admin/auth/"
	
	
	siteName: siteName
	
	login: (username, password, remember) ->
		deferred = new promises.Deferred()
		usernameSha = sha1(username)
		passwordSha = sha1(password)
		
		
		$.get(path + usernameSha).then (cypher) ->
			try
				[key, secret] = aes.decrypt(cypher, passwordSha).split(':')
			catch e
			
			unless key and secret
				return deferred.fail new Error('Incorrect Password')
			
			s3.auth key, secret
			creds = username + ':' + key + ':' + secret
			
			sessionStorage.setItem 'creds', creds
			localStorage.setItem 'creds', creds if remember
			deferred.fulfill()
		, ->
			deferred.fail new Error('Incorrect Username')

		deferred.promise
	
	
	authorize: ->
		creds = sessionStorage.getItem 'creds'
		unless creds
			creds = localStorage.getItem 'creds'
			sessionStorage.setItem 'creds', creds if creds
			
		return false unless creds
		
		[username, key, secret] = creds.split(':')
		
		s3.auth key, secret
		
		username
	
	
	
	register: (key, secret, username, password) ->
		s3.auth key, secret
		bucket = s3.bucket(siteName)
		
		usernameSha = sha1(username)
		passwordSha = sha1(password)
		
		cypher = aes.encrypt([ key, secret ].join(':'), passwordSha)
		bucket.put 'admin/auth/' + usernameSha, cypher, acl: 'public-read'
