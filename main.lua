love.graphics.setDefaultFilter("nearest", "nearest")

screen_width = love.graphics.getWidth()
screen_height = love.graphics.getHeight()

-- Obstacle tables for air, ground, and coins
air_obstacles = {}  
coin_obstacles = {}

coin_timer_init = 100
coin_timer = coin_timer_init
highscore = 0
counter = 0

hit_SND = nil

jump = 600/5
gravity = 2000/5
isGameOver = false
init_ground_height = (screen_height - 100)/5
ground_height = init_ground_height
ground_timer = 1000
ground_speed = 0.5

 
function love.load()
  -- Draw bg, blue sky
  love.graphics.setBackgroundColor(122, 195, 255)
  
  -- Load player
  player = {} 
  player.x = screen_width/10
  player.y = ground_height
  player.width = 10
  player.height = 10
  player.speed = 100
  player.y_vel = 0
  player.state = 1
  player.left1 = love.graphics.newImage("triangle_left.png")
  player.right1 = love.graphics.newImage("triangle_right.png")
  player.left2 = love.graphics.newImage("balloon_left.png")
  player.right2 = love.graphics.newImage("balloon_right.png")
  player.special = false
  player.jumpSND = love.audio.newSource("jump.wav")
  player.powerupSND = love.audio.newSource("powerup.wav")  
  player.down = nil
  
  -- Starting image
  player.image = player.right1
  ground_image = love.graphics.newImage("ground.png")
  
  coin_image = love.graphics.newImage("coin.png")
  coin_SND = love.audio.newSource("coin.wav")
  ground_SND = love.audio.newSource("ground.wav")
  
  counter = 0
end


function love.update(dt)  
  -- Player loses
  if game_lose == true then -- player loses
    love.graphics.print("Game Over!", 0, 0)
  end
  -- Close game on pressing escape
  if love.keyboard.isDown('escape') then 
    love.event.push('quit')
  end
  
  -- Player state manager
  if love.keyboard.isDown('1') or love.keyboard.isDown('down') or love.keyboard.isDown('s') then 
    player.state = 1 -- Square    
    player.image = player.right1
  elseif love.keyboard.isDown('2') or love.keyboard.isDown('up') or love.keyboard.isDown('w') then
    player.state = 2 -- Circle
    player.image = player.right2
  end
  
  -- Player movement
  if love.keyboard.isDown('left') or love.keyboard.isDown('a') then 
    if player.state == 1 then -- move player at base speed
      player.x = player.x - player.speed * dt
      player.image = player.left1
    elseif player.state == 2 then -- move player at decreased speed
      player.x = player.x - (player.speed - 5) * dt
      player.image = player.left2
    end
  end 
  
  if love.keyboard.isDown('right') or love.keyboard.isDown('d') then 
    if player.state == 1 then -- move player at base speed
      player.x = player.x + player.speed * dt
      player.image = player.right1
    elseif player.state == 2 then -- move player at decreased speed
      player.x = player.x + (player.speed - 5) * dt
      player.image = player.right2
    end
  end 

  if player.state == 2 then -- move player up since player is balloon
    player.y_vel = 20
    player.y = player.y - player.y_vel * dt
  end  
  
  
  if love.keyboard.isDown('space') and isGameOver == false then
    if player.state == 1 and player.y_vel == 0 then -- player not jumping
      love.audio.play(player.jumpSND)
      player.y_vel = jump
    elseif player.state == 2 then 
      love.audio.play(player.jumpSND)
      player.y = player.y - 50 * dt
    end
  end
  
  
  if player.y_vel ~= 0 or player.state == 1 then -- player is in air, so apply gravity
    player.y = player.y - player.y_vel * dt
    player.y_vel = player.y_vel - gravity * dt
  end  
  
  if player.y > ground_height - player.image:getHeight() then 
    player.y = ground_height - player.image:getHeight()
    player.y_vel = 0
  end
  
  if table.size(coin_obstacles) == 0 and isGameOver == false then -- Spawn coin
    newCoin = { 
      x = math.random(0, screen_width/5 - coin_image:getWidth()),
      y = math.random(0, ground_height - coin_image:getHeight()),
      width = coin_image:getWidth(), 
      height = coin_image:getHeight(),
      counted = false
    }
    table.insert(coin_obstacles, newCoin)
  end
      
  -- Tally coins
  for i, obstacle in ipairs(coin_obstacles) do 
    if checkCollision(player.x, player.y, player.image:getWidth(), player.image:getHeight(), obstacle.x, obstacle.y, obstacle.width, obstacle.height) then -- Remove obstacle off screen                    
      -- Add to score 
      if obstacle.counted == false  then 
        obstacle.counted = true
        love.audio.play(coin_SND)
        counter = counter + 1
        if counter % 10 == 0 then 
          love.audio.play(player.powerupSND)
          -- Lower ground
          ground_height = ground_height + 15
          if ground_height > init_ground_height then
            ground_height = init_ground_height
          end
        end
      end    
      -- Remove coin      
      table.remove(coin_obstacles, i)
    elseif obstacle.y > ground_height then
      table.remove(coin_obstacles, i)
    end        
  end
  
  mapCollision()   
  ground_timer = ground_timer - 1
  if ground_timer <= 0 then -- increase ground speed
    ground_timer = 600
    love.audio.play(ground_SND)
    ground_speed = ground_speed + 0.5
  end
  ground_height = ground_height - ground_speed * dt  
  
  if highscore < counter then -- adjust highscore
    highscore = counter
  end
end

function table.size(table) 
  local s = 0
  for i, v in pairs(table) do 
    s = s + 1 
  end 
  return s
end

function mapCollision() 
  if player.x < 0 then 
    player.x = 0
  elseif player.x > screen_width/5 - player.image:getWidth() then 
    player.x = screen_width/5 - player.image:getWidth()
  end 
  
  if player.y < 0 then     
    player.y = 0
    if ground_height - player.image:getHeight() <= 0 then
      isGameOver = true
    end
  end
end

function checkCollision(x1,y1,w1,h1, x2,y2,w2,h2)
  return  x1 < x2+w2 and 
          x2 < x1+w1 and 
          y1 < y2+h2 and
          y2 < y1+h1
end

function love.draw()  
  love.graphics.scale(5)
  
  -- Draw gameover
  if isGameOver == true then 
    love.graphics.setBackgroundColor(0, 0, 0)  
    love.graphics.print("Game Over!", screen_width/10 - 35, screen_height/10 - 10)
    love.graphics.print("High Score:" .. highscore, screen_width/10 - 35, screen_height/10 + 10)
    return
  end
  
  -- Draw ground
  love.graphics.setColor(255, 255, 255)
  love.graphics.draw(ground_image, 0, ground_height)
  
  -- Draw player
  love.graphics.setColor(255, 255, 255)
  love.graphics.draw(player.image, player.x, player.y)  
    
  -- Draw coins
  love.graphics.setColor(255, 255, 255)
  for i, coin in ipairs(coin_obstacles) do 
    love.graphics.draw(coin_image, coin.x, coin.y)
  end
  
  -- Draw scoreboard 
  love.graphics.setColor(255, 255, 255)
  love.graphics.print(counter, 0, 0)
  
end