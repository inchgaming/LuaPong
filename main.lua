local menu = require("menu")
local gameState = "menu"
local player1Score = 0
local player2Score = 0
local roundCooldown = 0
local scoreFont
local winnerFont
local labelFont
local winnerText = ""
local scoreMessage = ""
local winTimer = 0
local startTimer = 0
local hitSound
local scoreSound
local winnerSound
local menuMusic
local gameMusic
local aiDifficulty
local aiTargetY
local aiThinkTimer = 0
local pauseSound

local aiProfiles = {
    easy = { speed = 215, reactionTime = 0.38, aimError = 85, prediction = 0.28, centerBias = 0.45 },
    normal = { speed = 260, reactionTime = 0.18, aimError = 34, prediction = 0.56, centerBias = 0.35 },
    hard = { speed = 360, reactionTime = 0.08, aimError = 10, prediction = 0.9, centerBias = 0.15 },
}

function love.load()
    math.randomseed(os.time())

    -- paddle and ball constants
    local PADDLE_WIDTH = 20
    local PADDLE_HEIGHT = 100
    local BALL_SIZE = 20

    -- left paddle
    player1 = {
        x = 50,
        y = 240,
        width = PADDLE_WIDTH,
        height = PADDLE_HEIGHT,
    }

    -- right paddle
    player2 = {
        x = 800 - 50 - PADDLE_WIDTH,
        y = 250,
        width = PADDLE_WIDTH,
        height = PADDLE_HEIGHT,
    }

    -- ball

    ball = {
        x = 400 - BALL_SIZE /2,
        y = 300 - BALL_SIZE /2,
        size = BALL_SIZE,
    }

    -- initial speed for ball
    ball.dx = 200  -- horizontal speed
    ball.dy = 200  -- vertical speed

    scoreFont = love.graphics.newFont(36)
    winnerFont = love.graphics.newFont(56)
    labelFont = love.graphics.newFont(18)
    hitSound = love.audio.newSource("assets/freesound_community-tennis-smash-100733.wav", "static")
    hitSound:setVolume(0.25)
    scoreSound = love.audio.newSource("assets/freesound_community-decidemp3-14575.wav", "static")
    scoreSound:setVolume(0.6)
    winnerSound = love.audio.newSource("assets/vadim_makes_sound-retro-arcade-level-up-552982.wav", "static")
    winnerSound:setVolume(0.5)
    pauseSound = love.audio.newSource("assets/blip.wav", "static")
    menuMusic = love.audio.newSource("assets/15. Rbcloading.ogg", "stream")
    menuMusic:setLooping(true)
    menuMusic:setVolume(1)
    gameMusic = love.audio.newSource("assets/14. Digitize.ogg", "stream")
    gameMusic:setLooping(true)
    gameMusic:setVolume(0.25)
    menu.load()
    menuMusic:play()
end

function love.draw()
    if gameState == "menu" then
        menu.draw()
        return
    end

    if gameState == "empty" then
        love.graphics.clear(0.03, 0.04, 0.08)
        love.graphics.setColor(0.2, 0.8, 0.95)
        love.graphics.setFont(winnerFont)
        love.graphics.printf("EMPTY SPACE", 0, 180, 800, "center")
        love.graphics.setColor(1, 1, 1)
        love.graphics.setFont(labelFont)
        love.graphics.printf("PRESS ESC TO RETURN", 0, 320, 800, "center")
        return
    end

    if gameState == "winner" then
        love.graphics.clear(0.03, 0.04, 0.08)
        love.graphics.setColor(0.2, 0.8, 0.95)
        love.graphics.setFont(winnerFont)
        love.graphics.printf(winnerText, 0, 190, 800, "center")
        love.graphics.setColor(1, 1, 1)
        love.graphics.setFont(scoreFont)
        love.graphics.printf("Final score: " .. player1Score .. " - " .. player2Score, 0, 290, 800, "center")
        return
    end

    -- set background color
    love.graphics.clear(0, 0, 0)  -- black background

    -- draw the dashed line at center
    love.graphics.setColor(1, 1, 1)  -- white color
    for i = 0, 600, 30 do
        love.graphics.rectangle("fill", 395, i, 10, 15)
    end

    -- draw paddles
    love.graphics.rectangle("fill", player1.x, player1.y, player1.width, player1.height)
    love.graphics.rectangle("fill", player2.x, player2.y, player2.width, player2.height)

    love.graphics.setFont(labelFont)
    love.graphics.printf("P1", player1.x - 25, player1.y - 50, player1.width + 50, "center")
    love.graphics.printf(aiDifficulty and "CPU" or "P2", player2.x - 25, player2.y - 50, player2.width + 50, "center")

    -- draw ball
    love.graphics.rectangle("fill", ball.x, ball.y, ball.size, ball.size)

    love.graphics.setFont(scoreFont)
    love.graphics.printf(player1Score .. "     " .. player2Score, 0, 20, 800, "center")

    if roundCooldown > 0 then
        love.graphics.setColor(1, 1, 1)
        love.graphics.printf(scoreMessage, 0, 500, 800, "center")
        love.graphics.printf(string.format("Next round in %.1f", roundCooldown), 0, 560, 800, "center")
    elseif startTimer > 0 then
        love.graphics.setColor(1, 1, 1)
        love.graphics.printf(string.format("Starting in %.1f", startTimer), 0, 560, 800, "center")
    end
    
end

local function checkCollision(ball, paddle)
    return ball.x < paddle.x + paddle.width and
           ball.x + ball.size > paddle.x and
           ball.y < paddle.y + paddle.height and
           ball.y + ball.size > paddle.y
end

local function resetRound(direction)
    player1.x = 50
    player1.y = 240
    player2.x = 800 - 50 - player2.width
    player2.y = 250

    ball.x = 400 - ball.size / 2
    ball.y = 300 - ball.size / 2
    ball.dx = direction * (200 + math.random(0, 80))
    ball.dy = math.random(-180, 180)
    if ball.dy == 0 then
        ball.dy = 100
    end

    aiTargetY = 300 - player2.height / 2
    aiThinkTimer = 0
    roundCooldown = 5
end

local function updateAI(dt)
    local profile = aiProfiles[aiDifficulty]
    if not profile then
        return
    end

    aiThinkTimer = aiThinkTimer - dt
    if aiThinkTimer <= 0 then
        aiThinkTimer = profile.reactionTime

        if ball.dx > 0 then
            local timeToReachPaddle = (player2.x - ball.x - ball.size) / math.max(math.abs(ball.dx), 1)
            local predictedY = ball.y + ball.dy * timeToReachPaddle + (ball.size / 2)
            local wallBounceCompensation = 0

            local height = 600
            local bounceCount = math.floor((predictedY + ball.size) / height)
            local wrappedY = predictedY % height
            if wrappedY < 0 then
                wrappedY = wrappedY + height
            end

            if wrappedY > height - ball.size then
                local reflected = height - wrappedY
                wallBounceCompensation = reflected - ball.size / 2
                wrappedY = reflected
            end

            local offset = math.random(-profile.aimError, profile.aimError)
            local centerTarget = (height - player2.height) / 2
            aiTargetY = wrappedY + wallBounceCompensation + offset * profile.prediction + (centerTarget - wrappedY) * profile.centerBias
        else
            aiTargetY = (600 - player2.height) / 2
        end
    end

    local paddleCenter = player2.y + player2.height / 2
    local distance = aiTargetY - paddleCenter
    local movement = math.min(math.abs(distance), profile.speed * dt)

    if distance < 0 then
        player2.y = player2.y - movement
    elseif distance > 0 then
        player2.y = player2.y + movement
    end

    player2.y = math.max(0, math.min(600 - player2.height, player2.y))
end

function love.update(dt)
    if gameState == "menu" or gameState == "empty" then
        return
    end

    if gameState == "winner" then
        winTimer = winTimer - dt
        if winTimer <= 0 then
            player1Score = 0
            player2Score = 0
            roundCooldown = 0
            gameState = "menu"
            gameMusic:stop()
            menuMusic:play()
        end
        return
    end

    if gameState == "countdown" then
        startTimer = startTimer - dt
        if startTimer <= 0 then
            startTimer = 0
            gameState = "game"
        end
        return
    end

    if roundCooldown > 0 then
        roundCooldown = math.max(0, roundCooldown - dt)
        return
    end

    local speed = 300  -- pixels per second

    if love.keyboard.isDown("w") then
        player1.y = player1.y - speed * dt
    elseif love.keyboard.isDown("s") then
        player1.y = player1.y + speed * dt
    end

    if aiDifficulty then
        updateAI(dt)
    elseif love.keyboard.isDown("up") then
        player2.y = player2.y - speed * dt
    elseif love.keyboard.isDown("down") then
        player2.y = player2.y + speed * dt
    end

    player1.y = math.max(0, math.min(600 - player1.height, player1.y))
    player2.y = math.max(0, math.min(600 - player2.height, player2.y))

    -- move ball
    ball.x = ball.x + ball.dx * dt
    ball.y = ball.y + ball.dy * dt

    if ball.y <= 0 then
        ball.y = 0
        ball.dy = -ball.dy
        hitSound:stop()
        hitSound:play()
    elseif ball.y + ball.size >= 600 then
        ball.y = 600 - ball.size
        ball.dy = -ball.dy
        hitSound:stop()
        hitSound:play()
    end

    if ball.x + ball.size < 0 then
        player2Score = player2Score + 1
        scoreSound:stop()
        scoreSound:play()
        if player2Score >= 5 then
            winnerText = "PLAYER 2 WINS!"
            winTimer = 5
            gameState = "winner"
            winnerSound:stop()
            winnerSound:play()
            return
        end
        scoreMessage = "P2 SCORED!"
        resetRound(1)
        return
    elseif ball.x > 800 then
        player1Score = player1Score + 1
        scoreSound:stop()
        scoreSound:play()
        if player1Score >= 5 then
            winnerText = "PLAYER 1 WINS!"
            winTimer = 5
            gameState = "winner"
            winnerSound:stop()
            winnerSound:play()
            return
        end
        scoreMessage = "P1 SCORED!"
        resetRound(-1)
        return
    end

    if ball.dx < 0 and checkCollision(ball, player1) then
        ball.x = player1.x + player1.width
        ball.dx = math.abs(ball.dx) * 1.05
        hitSound:stop()
        hitSound:play()
    elseif ball.dx > 0 and checkCollision(ball, player2) then
        ball.x = player2.x - ball.size
        ball.dx = -math.abs(ball.dx) * 1.05
        hitSound:stop()
        hitSound:play()
    end
end

function love.mousepressed(x, y, button)
    if button ~= 1 then
        return
    end

    if gameState == "menu" then
        local action = menu.mousepressed(x, y)

        if action == "play" then
            aiDifficulty = nil
            player1Score = 0
            player2Score = 0
            resetRound(math.random(0, 1) == 0 and -1 or 1)
            roundCooldown = 0
            startTimer = 3
            gameState = "countdown"
            menuMusic:stop()
            gameMusic:play()
        elseif action == "empty" then
            menu.state = "difficulty"
        elseif action == "quit" then
            love.event.quit()
        elseif action == "easy" or action == "normal" or action == "hard" then
            aiDifficulty = action
            player1Score = 0
            player2Score = 0
            resetRound(math.random(0, 1) == 0 and -1 or 1)
            roundCooldown = 0
            startTimer = 3
            menu.state = "main"
            gameState = "countdown"
            menuMusic:stop()
            gameMusic:play()
        end
    end
end

function love.keypressed(key)
    if key == "space" then
        pauseSound:stop()
        pauseSound:play()

        local music = (gameState == "menu" or gameState == "empty") and menuMusic or gameMusic
        if music:isPlaying() then
            music:pause()
        else
            music:play()
        end
        return
    end

    if gameState == "menu" then
        if key == "escape" and menu.state == "difficulty" then
            menu.state = "main"
        end
        return
    end

    if gameState == "empty" then
        if key == "escape" then
            gameState = "menu"
        end
        return
    end
end

local menu_music_was_playing_before_focus_loss = false
local game_music_was_playing_before_focus_loss = false

function love.focus(has_focus)
    if not has_focus then
        menu_music_was_playing_before_focus_loss = menuMusic:isPlaying()
        game_music_was_playing_before_focus_loss = gameMusic:isPlaying()

        if menu_music_was_playing_before_focus_loss then
            menuMusic:pause()
        end
        if game_music_was_playing_before_focus_loss then
            gameMusic:pause()
        end
    else
        if menu_music_was_playing_before_focus_loss then
            menuMusic:play()
            menu_music_was_playing_before_focus_loss = false
        end
        if game_music_was_playing_before_focus_loss then
            gameMusic:play()
            game_music_was_playing_before_focus_loss = false
        end
    end
end