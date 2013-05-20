-- Load the audio management [library](https://github.com/vrld/slam).
require "resource/slam"

-- Good morning!
function love.load()
    -- Establish constants. These can be configured to fine-tune Raindrops.
    MIN_RADIUS          = 2
    INCREMENT_SIZE      = 0.7
    DEFAULT_LINE_WIDTH  = 4
    MODES = {
        {background={0,0,0}, color={255,255,255}, sound=loadSound("resource/pongblip.wav")},
        {background={201,233,237}, color={173,174,214}, sound=loadSound("resource/chime.wav")},
        {background={223,218,213}, color={109,98,94}, sound=loadSound("resource/marimba.wav")}
    }

    -- Create a physics world for the objects to live in.
    world = love.physics.newWorld(0, 0)

    -- `setCallbacks` accepts multiple functions.
    -- The first argument is a function called when two objects collide.
    world:setCallbacks(onCollision)

    -- Create tables to hold physics objects.
    objects = {}
    walls = {}
    makeWalls()

    -- Set the visual and audio "theme" default (corresponds to an index of `MODES`).
    mode = 1

    -- Set engine paramaters.
    love.graphics.setNewFont(14)
    love.graphics.setMode(800, 800)
    love.graphics.setCaption("...")
end

-- Runs once every frame.
function love.draw()
    drawText()
    
    for i, circle in ipairs(objects) do
        drawCircle(circle)
    end
end


-- Runs before each frame.
function love.update(dt) 
    world:update(dt)
    
    -- Grow/shrink the circles:
    -- `circle` becomes the fixture of each circle.
    for i, circle in ipairs(objects) do
        local data = circle:getUserData()
        local r = circle:getShape():getRadius()
        -- By multiplying `d`, we make the circle either grow or shrink.
        local d = 1

        -- Make `d` negative if the circle is shrinking.
        if data.state == "shrinking" then
            d = -1
        end

        -- Don't let circle shrink below the minimum size (negative radius = weird shit happening).
        if r < MIN_RADIUS then
            data:flipState()
            d = 1
        end

        -- Update the shape's radius
        circle:getShape():setRadius(r + d * INCREMENT_SIZE)
    end
end

-- Called when any key is pressed. `key` is the [KeyConstant](http://love2d.org/wiki/KeyConstant) string,
-- and `code` is the base-10 [Unicode number](http://unicode-table.com/) for the key pressed.
function love.keypressed(key, code)
    if code > 48 and code < 58 then
        local n = tonumber(key)
        if MODES[n] then
            mode = n
            love.graphics.setBackgroundColor(unpack(MODES[n].background))
            love.graphics.setColor(unpack(MODES[n].color))
        end
    end

    -- Clear screen when `c` pressed.
    if key == "c" then
        for k, obj in pairs(objects) do
            obj:destroy()
        end
        objects = {}
    end

end

-- When the user leftclicks the screen, create a new circle at that point.
function love.mousereleased(x, y, button)
    if button == "l" then
        createCircle(x, y)
    end
end

-- Helper functions begin here.

-- Define the 4 edges of the window as edges to the physics world. Loops through the
-- respective coordinates to be less repetitive.
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

-- Draw a circle based on a given fixture.
function drawCircle(fixture)
    local body, shape, data = fixture:getBody(), fixture:getShape(), fixture:getUserData()
    local x, y, r = body:getX(), body:getY(), shape:getRadius()
    local xOffset, yOffset = shape:computeAABB(r, r, 0)

    love.graphics.setLineWidth(data.lineWidth)
    love.graphics.circle("fill", x + xOffset, y + yOffset, r)
end

-- Create and initialize the physics bodies for a new circle.
function createCircle(x, y, lineWidth)
    lineWidth = lineWidth or DEFAULT_LINE_WIDTH

    local body          = love.physics.newBody(world, x, y, "dynamic")
    local shape         = love.physics.newCircleShape(MIN_RADIUS)
    local fixture       = love.physics.newFixture(body, shape)

    -- Disable sleeping, which forces the objects to respond to collisions without having to apply
    -- a force or doing anything else that'd wake up the physbody.
    fixture:getBody():setSleepingAllowed(false)

    -- This table of data gets stored with the fixture, using `:setUserData()`.
    local data = {
        lineWidth = lineWidth,
        state = "growing",
        -- `flipState()` changes the state attribute. The argument `self` will be the data table for
        -- this fixture and will be automatically passed `data:flipState()` is called.
        flipState = function(self)
            if self.state == "growing" then
                self.state = "shrinking"
            else
                self.state = "growing"
            end
        end
    }

    -- Insert the above custom data into the fixture.
    fixture:setUserData(data)

    -- Add this completed fixture to the `objects` table.
    table.insert(objects, fixture)
end

-- Called when any two objects collide. `thisCircle` and `thatCircle` are the objects that collided, if any.
function onCollision(thisCircle, thatCircle)
    local largest = 0

    -- Of the circles that collided, find the largest radius (the largest circle). This size will be
    -- used to determine the audio pitch.
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

    -- Play the sound for this collision. Uses `getCollisionSound()` to return the appropriate collision
    -- for this theme. Beep boop.
    local sound = getCollisionSound()
    sound:setVolume(0.4 + (largest * .02))
    sound:setPitch(determinePitch(largest))
    sound:play()  
end

-- A exponential-decline equation to determine the pitch. Small widths should be a high pitch, large widths
-- should be low. The equation is roughly adjusted for an 800px-wide window.
function determinePitch(width)
    return 1.488 * 0.99601^width
end

-- Returns the radius of the window (thanks Pythagorus). I can't remember if I use this anywhere.
function getWindowRadius()
    local w, h = love.graphics.getWidth(), love.graphics.getHeight()
    return math.sqrt(math.pow(w, 2) + math.pow(h, 2))
end

-- Load a sound from the game's resources. Called once for each defined mode at startup.
function loadSound(file)
    return love.audio.newSource(love.sound.newSoundData(file), "static")
end

-- Returns a sound object for the current theme. Called by `onCollision()`.
function getCollisionSound()
    return MODES[mode].sound
end

-- Draws the "click" text on the screen when there are no circles, and the control key text when there are circles.
function drawText()
    if #objects < 1 then
        love.graphics.print("[  c l i c k  ]", 370, 390)
    else
        love.graphics.print("[ 1-"..#MODES.." ]  change mode", 10, love.graphics.getHeight() - 24)
        love.graphics.print("[ c ] clear", love.graphics.getWidth()-75, love.graphics.getHeight() - 24)
    end
end