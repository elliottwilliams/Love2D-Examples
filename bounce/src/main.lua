function love.load()
	-- create structures
	canvas = love.graphics.newCanvas()
	unstretched = love.graphics.newCanvas(151*2, 90*2)
	objects = {}
	world  = love.physics.newWorld(0, 0, true)

	-- load graphics
	image = love.graphics.newImage("resource/dvd.png")

	-- set defaults
	love.graphics.setBackgroundColor(60, 60, 60)
	love.physics.setMeter(64)
	world:setCallbacks(edgeCollide)

	-- create ball
	objects.ball = {}
	objects.ball.body 		= love.physics.newBody(world, 650/2, 650/2, "dynamic")
	objects.ball.shape 		= love.physics.newRectangleShape(151, 90)
	objects.ball.fixture 	= love.physics.newFixture(objects.ball.body, objects.ball.shape, 1)

	-- set ball defaults
	ballSpeed = 300
	objects.ball.body:setMass(0)
	objects.ball.body:applyLinearImpulse(ballSpeed, 0)
	selectColor()

	-- init everything dependant on window size
	windowWidth, windowHeight = 650, 650
	love.graphics.setCaption("STARE AT IT")
	windowSize(windowWidth, windowHeight)
	
end

function love.update(dt)
	world:update(dt)

	local kb = love.keyboard

	if kb.isDown("f") then
		modes = love.graphics.getModes()
		-- sort from largest to smallest
		table.sort(modes, function(a, b) return a.width*a.height > b.width*b.height end)
		if not fullscreen then
			windowSize(modes[1]["width"], modes[1]["height"], true)
			fullscreen = true
		else
			windowSize()
			fullscreen = false
		end

	elseif kb.isDown("up") then
		windowWidth, windowHeight = windowWidth+50, windowHeight+50
		windowSize(windowWidth, windowHeight)
	elseif kb.isDown("down") then
		windowWidth, windowHeight = windowWidth-50, windowHeight-50
		windowSize(windowWidth, windowHeight)
	end
end

function love.draw()
	local bb = objects.ball.body

	-- draw on unstretched canvas
	love.graphics.setCanvas(unstretched)
	love.graphics.circle("fill", 151, 90, 90)

	-- draw everything to the screen
	love.graphics.setCanvas()
	love.graphics.draw(unstretched, bb:getX()-(151*0.8),
		bb:getY()-(90*0.5), 0, 0.8, 0.5)
	love.graphics.draw(image, bb:getX()-75+36, bb:getY()-45+20)
end

function windowSize(w, h, becomeFullscreen)
	 -- defaults arguments
	w = w or 650
	h = h or 650
	becomeFullscreen = becomeFullscreen or false

	-- if edges already present, destroy them (resizing window)
	if objects.edges then
		for name, edge in pairs(objects.edges) do
			edge.fixture:destroy()
			edge.body:destroy()
		end
	end

	-- create edge shapes
	objects.edges = {}
	objects.edges.top 			= {shape= love.physics.newEdgeShape(0, 0, w, 0)}
	objects.edges.right 		= {shape= love.physics.newEdgeShape(w, 0, w, h)}
	objects.edges.left 			= {shape= love.physics.newEdgeShape(0, 0, 0, h)}
	objects.edges.bottom		= {shape= love.physics.newEdgeShape(0, h, w, h)}

	-- loop and create the common properties
	for i, v in ipairs({"top", "right", "bottom", "left"}) do
		objects.edges[v].body 	 = love.physics.newBody(world, 0, 0, "static")
		objects.edges[v].fixture = love.physics.newFixture(objects.edges[v].body, objects.edges[v].shape, 1)
		objects.edges[v].fixture:setUserData(v)
	end

	love.graphics.setMode(w, h, becomeFullscreen, true, 2)

	-- replace ball if needed
	local bb = objects.ball.body
	if bb:getX() > w or bb:getY() > h then
		bb:setX(w/2)
		bb:setY(h/2)
	end
end

function edgeCollide(wall)
	side = wall:getUserData()
	ball = objects.ball.body

	selectColor()

	ball:setLinearVelocity(0, 0)

	local x = 150 + math.random() * (ballSpeed-150)
	local y = ballSpeed - x

	if side == "top" then
		x, y = randomNeg(x), y
	elseif side == "right" then
		x, y = -x, randomNeg(y)
	elseif side == "bottom" then
		x, y = randomNeg(x), -y
	elseif side == "left" then
		x, y = x, randomNeg(y)
	end

	ball:setLinearVelocity(x, y)
end

function selectColor()
	colors = {
		{55, 255, 0},
		{222, 0, 224},
		{0, 84, 224},
		{249, 0, 106},
		{255, 255, 37},
		{0, 255, 255}
	}

	last_selection  = selection
	selection 		= math.ceil(math.random() * #colors)

	if selection == last_selection then
		if selection == #colors then
			selection = 1
		else
			selection = selection + 1
		end
	end

	thisColor = colors[selection]

	love.graphics.setColor(thisColor[1], thisColor[2], thisColor[3])
end

function randomNeg(n)
	if math.random() >= 0.5 then
		return n * -1
	else
		return n
	end
end