require "slam"

-- good morning!
function love.load()
	MIN_RADIUS 			= 2
	INCREMENT_SIZE 		= 0.7
	DEFAULT_LINE_WIDTH 	= 4

	MODES = {
		{background={0,0,0}, color={255,255,255}, sound=loadSound("pongblip.wav")},
		{background={201,233,237}, color={173,174,214}, sound=loadSound("chime.wav")},
		{background={223,218,213}, color={109,98,94}, sound=loadSound("marimba.wav")}
	}

	objects = {}

	world = love.physics.newWorld(0, 0)
	world:setCallbacks(onCollision)						-- first callback = a function called when two objects collide

	walls = {}
	makeWalls()

	mode = 1 											-- visual and audio theme

	-- set engine paramaters
	love.graphics.setNewFont(14)
	love.graphics.setMode(800, 800)
	love.graphics.setCaption("...")
end

-- runs once every frame
function love.draw()
	drawText()
	
	for i, circle in ipairs(objects) do
		drawCircle(circle)
	end
end


-- runs before each frame
function love.update(dt) 
	world:update(dt)
	
	-- grow/shrink the circles
	for i, circle in ipairs(objects) do 				-- `circle` becomes the fixture of each circle
		local data = circle:getUserData()
		local r = circle:getShape():getRadius()
		local d = 1 									-- will make the circle either grow or shrink

		-- make d negative if shrinking
		if data.state == "shrinking" then
			d = -1
		end

		-- don't let circle shrink below the minimum size
		if r < MIN_RADIUS then
			data:flipState()
			d = 1
		end

		-- update the radius
		circle:getShape():setRadius(r + d * INCREMENT_SIZE)
	end
end

function love.keypressed(key, code)
	if code > 48 and code < 58 then
		local n = tonumber(key)
		if MODES[n] then
			mode = n
			love.graphics.setBackgroundColor(unpack(MODES[n].background))
			love.graphics.setColor(unpack(MODES[n].color))
		end
	end

	if key == "c" then									-- clear screen
		for k, obj in pairs(objects) do
			obj:destroy()
		end
		objects = {}
	end

end

-- when leftclick happens, create a new circle at this point
function love.mousereleased(x, y, button)
	if button == "l" then
		-- INCOMPLETE, NOT USED (yet)
		-- for k, circle in pairs(objects) do				-- don't create if click we clicked on an active circle
		-- 	if coordsInShape(circle, x, y) then
		-- 		return nil
		-- 	end
		-- end
		createCircle(x, y)
	end
end

-- HELPERS --

function makeWalls()
	local wallCoords = {
		{0, 0, 800, 0},
		{800, 0, 800, 800},
		{0, 0, 0, 800},
		{0, 800, 800, 800}
	}
	
	for i, coords in ipairs(wallCoords) do
		local shape   = love.physics.newEdgeShape(unpack(coords))
		local body    = love.physics.newBody(world, 0, 0, "static")
		local fixture = love.physics.newFixture(body, shape)

		table.insert(walls, fixture)
	end
end

function drawCircle(fixture) 							-- draw a circle based on this fixture
	local body, shape, data = fixture:getBody(), fixture:getShape(), fixture:getUserData()
	local x, y, r = body:getX(), body:getY(), shape:getRadius()
	local xOffset, yOffset = shape:computeAABB(r, r, 0)

	love.graphics.setLineWidth(data.lineWidth)
	love.graphics.circle("fill", x + xOffset, y + yOffset, r)
end

function createCircle(x, y, lineWidth)		 			-- create and initialize the physics bodies for a new circle
	lineWidth = lineWidth or DEFAULT_LINE_WIDTH

	local body    		= love.physics.newBody(world, x, y, "dynamic")
	local shape   		= love.physics.newCircleShape(MIN_RADIUS)
	local fixture 		= love.physics.newFixture(body, shape)

	-- get objects responding to collisions w/o applying a force
	fixture:getBody():setSleepingAllowed(false)

	-- this table of data gets stored with the fixture
	local data = {
		lineWidth = lineWidth,
		state = "growing",
		flipState = function(self) 						-- a function that changes the state attribute
			if self.state == "growing" then
				self.state = "shrinking"
			else
				self.state = "growing"
			end
		end
	}

	fixture:setUserData(data) 							-- put our custom data into the fixture

	table.insert(objects, fixture) 						-- add this fixture to the `objects` table
end

-- INCOMPLETE, NOT USED (yet)
function coordsInShape(fixture, x, y)
	local topLeftX, topLeftY, bottomRightX, bottomRightY = fixture:getShape():computeAABB(0, 0, 0)
	print(topLeftX, topLeftY, bottomRightX, bottomRightY, x, y)
	if x >= topLeftX and x <= bottomRightX and y <= topRightY and y >= bottomRightY then
		return true
	else
		return false
	end
end

function onCollision(thisCircle, thatCircle)
	local largest = 0									-- will contain the larger of the circle radii

	if thisCircle:getShape():typeOf("CircleShape") then
		if thisCircle:getShape():getRadius() > largest then
			largest = thisCircle:getShape():getRadius()
		end
		thisCircle:getUserData():flipState()
	end

	if thatCircle:getShape():typeOf("CircleShape") then
		if thatCircle:getShape():getRadius() > largest then
			largest = thatCircle:getShape():getRadius()
		end
		thatCircle:getUserData():flipState()
	end

	-- beep boop
	getCollisionSound():setVolume(0.4 + (largest * .02))
	getCollisionSound():setPitch(determinePitch(largest))
	getCollisionSound():play()	
end

function determinePitch(width)
	return 1.488 * 0.99601^width
end

function getWindowRadius()
	local w, h = love.graphics.getWidth(), love.graphics.getHeight()
	return math.sqrt(math.pow(w, 2) + math.pow(h, 2))
end

function loadSound(file)
	return love.audio.newSource(love.sound.newSoundData(file), "static")
end

function getCollisionSound()
	return MODES[mode].sound
end

function drawText()
	if #objects < 1 then
		love.graphics.print("[  c l i c k  ]", 370, 390)
	else
		love.graphics.print("[ 1-"..#MODES.." ]  change mode", 10, love.graphics.getHeight() - 24)
		love.graphics.print("[ c ] clear", love.graphics.getWidth()-75, love.graphics.getHeight() - 24)
	end
end