local menu = {}

menu.state = "main"

local titleFont
local menuFont

function menu.load()
	titleFont = love.graphics.newFont(72)
	menuFont = love.graphics.newFont(24)
end

local function mainButtonRects()
	local width = love.graphics.getWidth()
	local height = love.graphics.getHeight()
	local buttonWidth = 260
	local buttonHeight = 52
	local centerX = (width - buttonWidth) / 2

	return {
		play = { x = centerX, y = height * 0.48, w = buttonWidth, h = buttonHeight },
		empty = { x = centerX, y = height * 0.58, w = buttonWidth, h = buttonHeight },
		quit = { x = centerX, y = height * 0.72, w = buttonWidth, h = buttonHeight },
	}
end

local function difficultyRects()
	local width = love.graphics.getWidth()
	local height = love.graphics.getHeight()
	local buttonWidth = 180
	local buttonHeight = 52
	local startX = (width - (buttonWidth * 3 + 30)) / 2

	return {
		easy = { x = startX, y = height * 0.58, w = buttonWidth, h = buttonHeight },
		normal = { x = startX + buttonWidth + 15, y = height * 0.58, w = buttonWidth, h = buttonHeight },
		hard = { x = startX + (buttonWidth + 15) * 2, y = height * 0.58, w = buttonWidth, h = buttonHeight },
	}
end

function menu.draw()
	local width = love.graphics.getWidth()
	local height = love.graphics.getHeight()
	local mouseX, mouseY = love.mouse.getPosition()

	love.graphics.clear(0.03, 0.04, 0.08)

	love.graphics.setColor(0.2, 0.8, 0.95)
	love.graphics.setFont(titleFont)
	love.graphics.printf("LUAPONG", 0, height * 0.25, width, "center")

	if menu.state == "main" then
		for name, rect in pairs(mainButtonRects()) do
			local hovered = mouseX >= rect.x and mouseX <= rect.x + rect.w and
				mouseY >= rect.y and mouseY <= rect.y + rect.h
			if hovered then
				love.graphics.setColor(0.15, 0.75, 0.9)
			else
				love.graphics.setColor(0.22, 0.26, 0.34)
			end
			love.graphics.rectangle("fill", rect.x, rect.y, rect.w, rect.h)
			love.graphics.setColor(1, 1, 1)
			love.graphics.setFont(menuFont)
			local text = name == "play" and "2 PLAYER" or name == "empty" and "1 PLAYER" or "EXIT"
			love.graphics.printf(text, rect.x, rect.y + 12, rect.w, "center")
		end
		return
	end

	local difficultyTextY = height * 0.42
	love.graphics.setColor(1, 1, 1)
	love.graphics.setFont(menuFont)
	love.graphics.printf("SELECT DIFFICULTY", 0, difficultyTextY, width, "center")

	for name, rect in pairs(difficultyRects()) do
		local hovered = mouseX >= rect.x and mouseX <= rect.x + rect.w and
			mouseY >= rect.y and mouseY <= rect.y + rect.h
		if hovered then
			love.graphics.setColor(0.15, 0.75, 0.9)
		else
			love.graphics.setColor(0.22, 0.26, 0.34)
		end
		love.graphics.rectangle("fill", rect.x, rect.y, rect.w, rect.h)
		if name == "easy" then
			love.graphics.setColor(0.2, 0.9, 0.4)
		elseif name == "normal" then
			love.graphics.setColor(1, 0.85, 0.2)
		else
			love.graphics.setColor(1, 0.25, 0.25)
		end
		love.graphics.setFont(menuFont)
		love.graphics.printf(name:upper(), rect.x, rect.y + 12, rect.w, "center")
	end
end

function menu.mousepressed(x, y)
	if menu.state == "main" then
		for name, rect in pairs(mainButtonRects()) do
			if x >= rect.x and x <= rect.x + rect.w and y >= rect.y and y <= rect.y + rect.h then
				if name == "empty" then
					menu.state = "difficulty"
				end
				return name
			end
		end
		return nil
	end

	for name, rect in pairs(difficultyRects()) do
		if x >= rect.x and x <= rect.x + rect.w and y >= rect.y and y <= rect.y + rect.h then
			return name
		end
	end
	return nil
end

return menu