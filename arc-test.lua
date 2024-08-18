--   . . . . . . . . 
--   . . . . . . . .  ARC 
--   . . . . . . . .  TEST





-- ARC TEST 0.0.1
-- @okyeron
-- 
-- 

local dp = 0
local cp = 0
local rp = 0
local ripp = 0
local down_time = 0
local glevel = 15
local devicepos = 1
local brightness = {0,0,0,0}
local arcdelta = {0,0,0,0}
local accum = {0,0,0,0}
local selectedring = 1

local focus = { x = 0, y = 0, z = 0 }
local start = 0
local tiltvals = { x = 0, y = 0, z = 0 }

local pixels = {{},{},{},{}}
local patterns = {"fade", "chase", "random", 'ripple'}
local selectedpattern = 1
local arc_device

local tiltEnable = false

function clearpixels()
  for j = 1, 4 do
	  for i = 1, 64 do
		pixels[j][i] = 0
	  end
  end
  print("cleared pixels")
end

-- init function
function init()
  local grds = {}

  connect()
  print ("arc " .. arc.vports[devicepos].name)

--  arc_device:tilt_enable(0,tiltEnable and 1 or 0) -- sensor number	0-7, 1 = on , 


  -- Get a list of arc devices
  for id,device in pairs(arc.vports) do
    grds[id] = device.name
  end
  
  -- setup params
  
  params:add{type = "option", id = "arc_device", name = "arc", options = grds , default = 1,
    action = function(value)
		arc_device:all(0)
		arc_device:refresh()
		arc_device.key = nil
		arc_device = arc.connect(value)
		arc_device.key = arc_key
		arc_dirty = true
		devicepos = value

		clearpixels()
		print ("arc selected " .. arc.vports[devicepos].name)
    end}
    
--  params:add{type = "option", id = "tilt", name = "Tilt Enable", options = {"off","on"}, default = 1,
--    action = function(value) 
--        arc_device:tilt_enable(0,value-1)
--        if (value == 2) then tiltEnable = true else tiltEnable = false end
--    end}

  -- setup pixel array for oled
  -- for i = 1, arc_w*arc_h do
  --   pixels[i] = 0;
  -- end
    
  setup_metros()
  buildarctable()

end

function connect()
	arc_device = arc.connect(devicepos)
	arc_device.key = arc_key
	arc_device.add = on_arc_add
	arc_device.remove = on_arc_remove
	clearpixels()
end

function setup_metros()

 -- ripple pattern metro
 rippattern = metro.init()
 rippattern.count = (256) + 1
 rippattern.time = 0.01
 rippattern.event = function(stage)
--	print("ripple start")
	ripp = ripp + 1
	ripplepattern()
	arcfrompixels()
	redraw()
 end

 -- chase pattern metro
 cpattern = metro.init()
 cpattern.count = (256) + 1
 cpattern.time = 0.01
 cpattern.event = function(stage)
	cp = cp + 1
	chasepattern()
	if cp == cpattern.count then
		allledsoff()
	end
	redraw()
 end

 -- random pattern metro
 randpattern = metro.init()
-- rpattern.count = 10
 randpattern.time = 0.5
 randpattern.event = function(stage)
   rp = rp + 1
   randompattern()
   redraw()
 end
 
end

function on_arc_add(g)
	print('on_add')
end

function on_arc_remove(g)
	print('on_remove')
end


function allledson()
	arc_device:all(15)
end

function allledsval(ring,value)
    for y = 1, 64 do
      pixels[ring][y]=value
    end

end

function allledsoff()
	arc_device:all(0)
	clearpixels()
end

function buildarctable()
  arctable = {}
  cnt = 1
  for x = 1, 4 do
    for y = 1, 64 do
        table.insert (arctable, cnt)
        cnt = cnt +1
    end
  end
end 


function chasepattern()
 for x = 1, 4 do
   for y = 1, 64 do
     yoffset = x-1
     pidx = y + (yoffset * 64)
     if cp == pidx then
       arc_device:led(x, y, 15)
       pixels[x][y]=15
       --draw_pixel(x,y,15)
     else
       arc_device:led(x, y, 1)
       pixels[x][y]=0
       --draw_pixel(x,y,0)

     end
   end
 end 
 
end

function randompattern()
 for x = 1, 4 do
   for y = 1, 64 do
       bright = math.random(0,15)
       pixels[x][y] = bright
       arc_device:led(x, y, bright)
   end
 end 
end
--
--
function fadepattern()
	bright = 0
	for x = 1, 4 do
		for y = 1, 64 do
			bright = util.clamp(util.round( (y/64) * 16, 1), 0, 15)
			pixels[x][y] = bright
			arc_device:led(x, y, bright)
		end
	end 
end


function ripplepattern()
	local tt = 1
	local dimval = 0

	for x = 1, 4 do
		for z = 1, 64 do
			yoffset = x-1
			pidx = z + (yoffset * 64)
			bright = util.clamp(util.round( (z/64) * 16, 1), 0, 15)
			if ripp > pidx then
				pixels[x][z]=bright	
			end
		end
		
		for y = 1, 64 do
			yoffset = x-1
			pidx = y + (yoffset * 64)

			if ripp == pidx then
	--		arc_device:led(x, y, 15)
				pixels[x][y]=15
			else
	--       arc_device:led(x, y, 0)
			end
		 tt = tt+1
		end 
	end 
end       

function stopallpatterns()
   cpattern:stop()
   randpattern:stop()
   rippattern:stop()
end


function arcfrompixels()
  for x = 1, 4 do
    for y = 1, 64 do
      arc_device:led(x, y, pixels[x][y])
    end
  end 
end

function arcredraw()
	arcfrompixels()
	arc_device:refresh()
end 

function arc.delta(n, delta)
	arcdelta[n]=delta
	accum[n] = accum[n] + delta
	redraw()
--	arcDirty = true
end

function arc_key(x, z)
  focus.x = x
  focus.z = z
  
  if z > 0 then
  end
  redraw()
end


-- encoder function
function enc(n, delta)
  if n == 1 then
    selectedring = util.clamp (selectedring + delta, 1, 4)
  end

  if n == 3 then
    selectedpattern = util.clamp (selectedpattern + delta, 1, #patterns)
  end
  if n==2 then
  	brightness[selectedring] = brightness[selectedring] + delta 
  	ledval = util.clamp(brightness[selectedring], 0, 15)
--  	print(ledval)
	allledsval(selectedring,ledval)
  end
  
  -- redraw screen
  redraw()
end

-- key function
function key(n, z)
  if n==1 then

  end
  
  if n==2 then
    if z == 1 then
      down_time = util.time()
    else
      stopallpatterns()
      hold_time = util.time() - down_time
      if hold_time < 1 then
        allledsoff()
        print("all leds off")
      elseif hold_time > 1 then
        allledson()
        print("all leds on")
      end
    end
  end 
  if n==3 and z==1 then
    stopallpatterns()
    dp = 0
    cp = 0
    rp = 0
    ripp = 0
    
    if selectedpattern == 1 then
		fadepattern()
    elseif selectedpattern == 2 then
    	clearpixels()
		cpattern:start()
    elseif selectedpattern == 3 then
    	clearpixels()
		randpattern:start()
    elseif selectedpattern == 4 then
    	clearpixels()
		rippattern:start()
--    elseif selectedpattern == 5 then
    end
  end 
  
  -- redraw screen
  redraw()
end


--function draw_pixel(x,y,b)
--  yoffset = y-1
--  pidx = x + (yoffset * arc_w)
--  if pixels[x][y] > 0 then
--  --if focus.x == x and focus.y == y then
--    screen.stroke()
--    screen.level(b)
--  end
--  screen.pixel((x*offset.spacing) + offset.x, (y*offset.spacing) + offset.y)
--  if pixels[x][y] > 0 then
--    screen.stroke()
--    screen.level(1)
--  end
--end

--function draw_arc()
--  screen.level(1)
--  offset = { x = 76, y = 2, spacing = 3 }
--  for x=1,arc_w,1 do 
--    for y=1,arc_h,1 do 
--      yoffset = y-1
--      pidx = x + (yoffset * arc_w)
--      
--      draw_pixel(x,y,pixels[x][y])
--    end
--  end
--  screen.stroke()
--end



-- screen redraw function
function redraw()
  local rdeg
 
   arcredraw()

 -- screen: turn on anti-alias
  --screen.aa(1)
  screen.line_width(1.0)
  -- clear screen
  screen.clear()
  
  
  -- set pixel brightness (0-15)
  screen.level(15)
  screen.move(0, 8)
  screen.text("ARC TEST")

  screen.move(0, 24)
  screen.text("Ring: ".. selectedring)

	screen.move(66, 8)
	screen.text("Delta:")
	
	screen.move(80, 16)
	screen.text("1: ".. arcdelta[1])
	screen.move(80, 24)
	screen.text("2: ".. arcdelta[2])
	screen.move(80, 32)
	screen.text("3: ".. arcdelta[3])
	screen.move(80, 40)
	screen.text("4: ".. arcdelta[4])

	screen.move(100, 8)
	screen.text("Accum:")
	
	screen.move(110, 16)
	screen.text(accum[1])
	screen.move(110, 24)
	screen.text(accum[2])
	screen.move(110, 32)
	screen.text(accum[3])
	screen.move(110, 40)
	screen.text(accum[4])

  screen.move(0, 33)
  screen.text("Pattern: ".. patterns[selectedpattern])

  
  screen.move(0, 51)
  screen.text("arc Key: "..focus.x..", "..focus.z)


  screen.move(0, 60)
  screen.text(devicepos .. ": "..arc.vports[devicepos].name )

--  draw_arc()
  
  -- refresh screen
  screen.update()
end

-- called on script quit, release memory
function cleanup ()
end
