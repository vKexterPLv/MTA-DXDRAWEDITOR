local ContextMenu = {}
ContextMenu.__index = ContextMenu

function ContextMenu:new()
	local instance = {}
	setmetatable(instance,ContextMenu)
	if instance:constructor() then
		return instance
	end
	return false
end

function ContextMenu:constructor()
	self.clickedOn = false
	self.contextMenuRevealed = false
	self.x,self.y = 0,0
	
	self.contextMenuElements = {}
	self.contextMenuSegments = {}
	
	self.origColor = tocolor(36,36,36,255)
	self.hoverColor = tocolor(100,100,100,255)
	self.segmentW = scaleImage(200)
	self.segmentH = scaleImage(50)
	
	self.colorPickerCreated = false

	self.func = {}
	self.func.onClick = function(...) self:onClick(...) end
	self.func.onClickContextSegment = function(...) self:onClickContextSegment(...) end
	self.func.onHover = function() self:onHover() end
	self.func.render = function() self:render() end
	self.func.scrollUP = function() self:scrollUP() end
	self.func.scrollDOWN = function() self:scrollDOWN() end
	
	bindKey("mouse_wheel_down", "both", self.func.scrollUP)
	bindKey("mouse_wheel_up", "both", self.func.scrollDOWN)
	
	self.row = 1
	self.maxRows = 7
	
	addEventHandler("onClientRender",root,self.func.render)
	addEventHandler("onClientClick",root,self.func.onClick)
	addEventHandler("onClientClick",root,self.func.onClickContextSegment)
	addEventHandler("onClientCursorMove",root,self.func.onHover)
	return true
end

function ContextMenu:scrollUP()
	if not self.contextMenuRevealed then return end
	if self.row < #self.contextMenuElements-self.maxRows+1 then 
		self.row=self.row + 1
	end
end

function ContextMenu:scrollDOWN()
	if not self.contextMenuRevealed then return end
	if self.row > 1 then
		self.row = self.row-1
	end
end

function ContextMenu:onClickContextSegment(btn,state,x,y)
	if state ~= "down" then return end
	if btn ~= "left" then return end
	if not self.contextMenuRevealed then return end
	local clickedOnSegment = false
	
	local k = 1
	for i=self.row,self.row+(self.maxRows-1) do
		local segmentV = self.contextMenuSegments[k]
		if segmentV then
			local w = segmentV.w
			local h = segmentV.h
			local x = segmentV.x
			local y = segmentV.y
			if isMouseInPosition(x,y,w,h) then
				local element = self.contextMenuElements[i]
				clickedOnSegment = true
				
				if element.action then
					element.action(self.clickedOn)
					clickedOnSegment = false
				end		
				
				break
			end			
			k = k + 1
		end
	end
	
	self.contextMenuRevealed = clickedOnSegment
end

function ContextMenu:bundleSegments()
	for i=1,self.maxRows do
		local w = self.segmentW
		local h = self.segmentH
		local x = self.x
		local y = self.y+((i-1)*h)
		self.contextMenuSegments[i] = {x=x,y=y,w=w,h=h,color=self.origColor}
	end
end

function ContextMenu:addSegment(name,value,callback)
	self.contextMenuElements[#self.contextMenuElements + 1] = {name=name,value=value,action=callback or false}
end

function ContextMenu:onClick(btn,state,x,y)
	if state ~= "down" then return end
	if btn ~= "right" then return end
	
	self.contextMenuRevealed = false
	self.x,self.y = 0,0
	
	self.contextMenuElements = {}
	self.contextMenuSegments = {}
	
	self.row = 1
	
	if LayersPanel and LayersPanel:isMouseOver() then return end
	
	-- Top-most visible layer under the cursor gets the context menu.
	elementsID:forEachHitOrder(function(v)
		local isMouseIn = v.visible and (v.type == "CIRCLE" and isMouseInCircle(v.x,v.y,v.attributes[3].value) or ( v.type == "LINE" and isMouseInPosition(v.catchAreaX,v.catchAreaY,v.w,v.h) or isMouseInPosition(v.x,v.y,v.w,v.h)))	
		if not isMouseIn then return false end
		
		self.clickedOn = v
		self.x,self.y = x,y
		self:addSegment("OPTIONS AVAIBLE: "..v.type,0)
		
		for k,v1 in pairs(v.attributes) do
			self:addSegment(v1.name,v1.value,v1.action or false)
		end
		
		self:addSegment("Rename layer",0,function(self)
			local function setValue(value)
				self.layerName = value
			end
			cgui:createCGUI(1,setValue)
		end)
		
		self:addSegment("Visible",v.visible,function(self)
			self.visible = not self.visible
			if not self.visible and guiSelector.selected == self then
				guiSelector.selected = false
			end
		end)
		
		self:addSegment("Locked",v.locked,function(self)
			self.locked = not self.locked
		end)
		
		self:addSegment("Bring to front",0,function(self)
			elementsID:moveLayerToTop(self)
		end)
		
		self:addSegment("Send to back",0,function(self)
			elementsID:moveLayerToBottom(self)
		end)
		
		self:addSegment("Move forward",0,function(self)
			elementsID:moveLayerUp(self)
		end)
		
		self:addSegment("Move backward",0,function(self)
			elementsID:moveLayerDown(self)
		end)
		
		self:addSegment("Center X",0,function(self)
			self.x = scr.x/2-self.w/2
			if self.type ~= "CIRCLE" then
				self:setUpResizePoints()
			end
		end)
		
		self:addSegment("Center Y",0,function(self)
			self.y = scr.y/2-self.h/2
			if self.type ~= "CIRCLE" then
				self:setUpResizePoints()
			end
		end)
		
		self:addSegment("Snap to left",0,function(self)
			self.x = 0
			if self.type ~= "CIRCLE" then
				self:setUpResizePoints()
			end
		end)

		self:addSegment("Snap to right",0,function(self)
			self.x = scr.x-self.w
			if self.type ~= "CIRCLE" then
				self:setUpResizePoints()
			end
		end)
		
		self:addSegment("Snap to top",0,function(self)
			self.y = 0
			if self.type ~= "CIRCLE" then
				self:setUpResizePoints()
			end
		end)
		
		self:addSegment("Snap to bottom",0,function(self)
			self.y = scr.y-self.h
			if self.type ~= "CIRCLE" then
				self:setUpResizePoints()
			end
		end)
		
		self:addSegment("DELETE",0,function(self)
			deleteElement(self)
		end)
		
		local totalHeight = 0
		for i=1,self.maxRows do
			totalHeight = totalHeight + self.segmentH
		end
		
		self:bundleSegments()
		
		if self.y+totalHeight > scr.y then
			self.y = scr.y-totalHeight
			self:bundleSegments()
		end
		
		self.contextMenuRevealed = true
		return true
	end)
end

function ContextMenu:render()
	if not self.contextMenuRevealed then return end
	
	local k = 1
	for i=self.row,self.row+(self.maxRows-1) do
		local segmentV = self.contextMenuSegments[k]
		if segmentV then
			local w = segmentV.w
			local h = segmentV.h
			local x = segmentV.x
			local y = segmentV.y
			local v = self.contextMenuElements[i]
			dxDrawRectangle(x,y,w,h,segmentV.color,true)
			
			if type(v.value) == "boolean" then
				dxDrawText(v.name..": "..(v.value and "YES" or "NO"),x+scaleImage(10),y,x+w,y+h,white,1,"default-bold","left","center",false,false,true)
			else
				dxDrawText(v.name,x+scaleImage(10),y,x+w,y+h,white,1,"default-bold","left","center",false,false,true)
			end
			
			if string.find(string.lower(v.name), "color") and type(v.value) ~= "boolean" then
				local colorRectSize = scaleImage(25)
				dxDrawRectangle((x+w)-colorRectSize-scaleImage(10),y+(h/2)-(colorRectSize/2),colorRectSize,colorRectSize,v.value,true)
			end
			
			k = k + 1
		end
	end
end

function ContextMenu:onHover()
	if not self.contextMenuRevealed then return end
	local k = 1
	for i=self.row,self.row+(self.maxRows-1) do
		local segmentV = self.contextMenuSegments[k]
		if segmentV then
			segmentV.color = self.origColor
			local w = segmentV.w
			local h = segmentV.h
			local x = segmentV.x
			local y = segmentV.y
			
			if isMouseInPosition(x,y,w,h) then
				segmentV.color = self.hoverColor
			end
			
			k = k + 1
		end
	end
end

menuKontekstowe = ContextMenu:new()