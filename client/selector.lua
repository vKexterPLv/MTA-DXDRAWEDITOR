local Selector = {}
Selector.__index = Selector

function Selector:new()
	local instance = {}
	setmetatable(instance,Selector)
	if instance:constructor() then
		return instance
	end
	return false
end

function Selector:constructor()
	self.func = {}
	self.func.onClick = function(...) self:onClick(...) end
	self.func.onKey = function(...) self:onKey(...) end
	
	self.selected = false
	self.axisAddValue = 2

	addEventHandler("onClientClick",root,self.func.onClick)
	addEventHandler("onClientKey",root,self.func.onKey)
	return true
end

function Selector:onKey(btn,state)
	if not self.selected then return end
	if self.selected.locked then return end
	if state then return end
	
	if getKeyState("lshift") then
		self.axisAddValue = 50
	else
		self.axisAddValue = 2
	end
	
	local element = self.selected
	local x = element.type == "LINE" and element.catchAreaX or element.x
	local y = element.type == "LINE" and element.catchAreaY or element.y
	if btn == "arrow_l" then 
		if element.type == "LINE" then
			element.catchAreaX = x - self.axisAddValue
			element:repositionLineV2()
		else
			element.x = x - self.axisAddValue
		end
	end
	if btn == "arrow_r" then 
		if element.type == "LINE" then
			element.catchAreaX = x + self.axisAddValue
			element:repositionLineV2()
		else
			element.x = x + self.axisAddValue
		end
	end
	if btn == "arrow_d" then 
		if element.type == "LINE" then
			element.catchAreaY = y + self.axisAddValue
			element:repositionLineV2()
		else
			element.y = y + self.axisAddValue
		end
	end
	if btn == "arrow_u" then 
		if element.type == "LINE" then
			element.catchAreaY = y - self.axisAddValue
			element:repositionLineV2()
		else
			element.y = y - self.axisAddValue
		end
	end
	
	if btn == "delete" then
		deleteElement(self.selected)
	end

	-- if element.type == "LINE" then element:setUpResizePoints() end
end

function Selector:onClick(btn,state,x,y)
	if guied.customizing then return end
	if btn ~= "left" then return end
	if state ~= "down" then return end
	if LayersPanel and LayersPanel:isMouseOver() then return end
	
	self.selected = false
	
	-- Top-most visible layer under the cursor wins.
	elementsID:forEachHitOrder(function(v)
		if not v.visible then return false end
		
		local isMouseIn = v.type == "CIRCLE" and isMouseInCircle(v.x,v.y,v.attributes[3].value) or ( v.type == "LINE" and isMouseInPosition(v.catchAreaX,v.catchAreaY,v.w,v.h) or isMouseInPosition(v.x,v.y,v.w,v.h))
		if isMouseIn then
			self.selected = v
			return true
		end
		
		return false
	end)
end

guiSelector = Selector:new()