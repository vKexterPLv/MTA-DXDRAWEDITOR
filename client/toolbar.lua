local Toolbar = {}
Toolbar.__index = Toolbar

function Toolbar:new()
	local instance = {}
	setmetatable(instance,Toolbar)
	if instance:constructor() then
		return instance
	end
	return false
end

function Toolbar:constructor()
	self.elements = {}

	self.toolbarSize = scaleImage(120)
	self.toolbarX = scaleX(-1920)
	self.toolbarY = scaleY(1080)-self.toolbarSize
	self.toolbarOptions = {}
	
	self.func = {}
	self.func.draw = function() self:draw() end
	self.func.onClick = function(...) self:onClick(...) end
	self.func.onHover = function() self:onHover() end
	
	self:addOption("RECT",Rectangle)
	self:addOption("TEXT",TextShape)
	self:addOption("IMAGE",Image)
	self:addOption("ROUNDED RECT",RoundedRectangle)
	self:addOption("CIRCLE",Circle)
	self:addOption("LINE",Line)
	
	self.outputX = scaleX(1920)-self.toolbarSize
	self.outputY = self.toolbarY
	self.outputW = self.toolbarSize
	self.outputH = self.toolbarSize
	self.outputAlpha = 160
	
	self.layersBtnGap = scaleImage(10)
	self.layersBtnX = self.outputX - self.toolbarSize - self.layersBtnGap
	self.layersBtnY = self.toolbarY
	self.layersBtnW = self.toolbarSize
	self.layersBtnH = self.toolbarSize
	self.layersBtnAlpha = 160
	
	addEventHandler("onClientRender",root,self.func.draw)
	addEventHandler("onClientClick",root,self.func.onClick)
	addEventHandler("onClientCursorMove",root,self.func.onHover)
	return true
end

function Toolbar:addOption(shape,shapeClass)
	local id = #self.toolbarOptions + 1
	self.toolbarOptions[id] = {alpha=160,shapeType=shape,shapeClass=shapeClass}
	
	for i=1,#self.toolbarOptions do
		local x = self.toolbarX+((i-1)*self.toolbarSize)
		self.toolbarOptions[id].x = x
	end
end

function Toolbar:onHover()
	self.outputAlpha = 160
	if isMouseInPosition(self.outputX,self.outputY,self.outputW,self.outputH) then
		self.outputAlpha = 200
	end
	
	self.layersBtnAlpha = 160
	if isMouseInPosition(self.layersBtnX,self.layersBtnY,self.layersBtnW,self.layersBtnH) then
		self.layersBtnAlpha = 200
	end

	for k,v in pairs(self.toolbarOptions) do
		v.alpha = 160
		if isMouseInPosition(v.x,self.toolbarY,self.toolbarSize,self.toolbarSize) then
			v.alpha = 200
		end
	end
end

function readFile(path)
    local file = fileOpen(path) -- attempt to open the file
    if not file then
        return false -- stop function on failure
    end
    local count = fileGetSize(file) -- get file's total size
    local data = fileRead(file, count) -- read whole file
    fileClose(file) -- close the file once we're done with it
    return data
end

function saveToFile(data)
	local fileHandle = fileCreate("filesForSave/test.txt")             -- attempt to create a new file
	if fileHandle then                                    -- check if the creation succeeded
		fileWrite(fileHandle, data)     -- write a text line
		fileClose(fileHandle)                             -- close the file once you're done with it
	end
end

function saveRawGUI(data)
	saveToFile(readFile("filesForSave/baseplate.txt"))
	local file = fileOpen("filesForSave/test.txt")
	if file then
		fileSetPos(file,fileGetSize(file))
		for k,v in pairs(data) do
			fileWrite(file,v)
		end
		fileClose(file)
	end
end

function Toolbar:onClick(btn,state)
	if btn ~= "left" then return end
	if state ~= "down" then return end
	
	if isMouseInPosition(self.outputX,self.outputY,self.outputW,self.outputH) then
		local lines = {}
		local fontsIDTable = fontsID.tbl
		
		if #fontsIDTable >= 1 then
			table.insert(lines,"local fonts = {}\r\n")
			for k,v in pairs(fontsIDTable) do
				table.insert(lines,"fonts["..v.id.."] = dxCreateFont('"..v.path.."',100,false,'cleartype_natural')\r\n")				
			end
		end
		
		table.insert(lines,"\r\n")

		table.insert(lines,"addEventHandler('onClientRender',root,function()\r\n")
		-- Output is generated bottom-to-top, matching the in-editor render
		-- order. Hidden layers are skipped entirely.
		elementsID:forEachRenderOrder(function(v)
			if v.visible then
				table.insert(lines,"\t"..v:output().."\r\n")
			end
		end)
		table.insert(lines,"end)")
		triggerServerEvent("guieditor:server_saveFile",root,lines)
		return
	end
	
	if isMouseInPosition(self.layersBtnX,self.layersBtnY,self.layersBtnW,self.layersBtnH) then
		LayersPanel:toggle()
		return
	end
	
	for k,v in pairs(self.toolbarOptions) do
		if isMouseInPosition(v.x,self.toolbarY,self.toolbarSize,self.toolbarSize) then
			local element = v.shapeClass:new()
			elementsID:assignID(element)
			
			-- Newly created shapes land on top and get selected straight
			-- away so you can jump right into editing them.
			guiSelector.selected = element
			break
		end
	end
end

function Toolbar:draw()
	local i = 0
	for k,v in pairs(self.toolbarOptions) do
		dxDrawRectangle(v.x,self.toolbarY,self.toolbarSize,self.toolbarSize,tocolor(0,0,0,v.alpha))
		dxDrawText(v.shapeType,v.x,self.toolbarY,v.x+self.toolbarSize,self.toolbarY+self.toolbarSize,white,1.5,"default-bold","center","center",false,true)
		i = i + 1
	end
	
	dxDrawRectangle(self.outputX,self.outputY,self.outputW,self.outputH,tocolor(0,0,0,self.outputAlpha))
	dxDrawText("OUTPUT",self.outputX,self.outputY,self.outputX+self.outputW,self.outputY+self.outputH,white,1.5,"default-bold","center","center")
	
	-- Highlight the LAYERS button while the panel is open so it's obvious
	-- it's a toggle.
	local layersAlpha = self.layersBtnAlpha
	if LayersPanel and LayersPanel.visible then
		layersAlpha = 230
	end
	
	dxDrawRectangle(self.layersBtnX,self.layersBtnY,self.layersBtnW,self.layersBtnH,tocolor(0,0,0,layersAlpha))
	dxDrawText("LAYERS",self.layersBtnX,self.layersBtnY,self.layersBtnX+self.layersBtnW,self.layersBtnY+self.layersBtnH,white,1.5,"default-bold","center","center",false,true)
end

Toolbar:new()