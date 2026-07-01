local ResizeAndDragModule = {}
ResizeAndDragModule.__index = ResizeAndDragModule

function ResizeAndDragModule:new()
	local instance = {}
	setmetatable(instance,ResizeAndDragModule)
	if instance:constructor() then
		return instance
	end
	return false
end

function ResizeAndDragModule:constructor()
	self.resizing = {id=0,bool=false,corner=""}
	self.moving = {id=0,bool=false}
	
	self.dragX = 0
	self.dragY = 0

	self.func = {}
	self.func.onClick = function(...) self:onClick(...) end
	self.func.renderResizeHandling = function() self:renderResizeHandling() end
	
	addEventHandler("onClientRender",root,self.func.renderResizeHandling)
	addEventHandler("onClientClick",root,self.func.onClick)
	return true
end

function ResizeAndDragModule:renderResizeHandling()
	if guied.resizeMode then
		if isCursorShowing() and self.resizing.bool and elementsID:count() >= 1 then
			local v = elementsID.tbl[self.resizing.id]
			local cx,cy = getCursorPosition()
			cx,cy = cx*scr.x,cy*scr.y
			
			if v and v.type == "LINE" then
				v:repositionLine(self.resizing.corner,cx,cy)
			end
			
			if v and v.type ~= "CIRCLE" and v.type ~= "LINE" then
				
				if self.resizing.corner == "top-center" then
					local newH = v.h + (v.y - cy)
					
					if newH >= v.defSizeH then
						v.h = newH
						v.y = cy
					end
				end
				
				if self.resizing.corner == "left-center" then
					local newW = v.w + (v.x - cx)
					
					if newW >= v.defSizeW then
						v.w = newW
						v.x = cx
					end
				end
				
				if self.resizing.corner == "right-center" then
					v.w = math.max(v.defSizeW, cx - v.x)
				end
				
				
				
				---------- NORMAL
				
				
				
				if self.resizing.corner == "down-center" then
					v.h = math.max(v.defSizeH, cy - v.y)
				end	
				
				if self.resizing.corner == "down-right" then
					v.w = math.max(v.defSizeW, cx - v.x)
					v.h = math.max(v.defSizeH, cy - v.y)
				end
			
				if self.resizing.corner == "down-left" then
					local newW = v.w + (v.x - cx)
					v.h = math.max(v.defSizeH, cy - v.y)
					
					if newW >= v.defSizeW then
						v.w = newW
						v.x = cx
					end
				end
			
				if self.resizing.corner == "top-right" then
					local newH = v.h + (v.y - cy)
					v.w = math.max(v.defSizeW, cx - v.x)
					
					if newH >= v.defSizeH then
						v.h = newH
						v.y = cy
					end
				end		
				if self.resizing.corner == "top-left" then
					local newW = v.w + (v.x - cx)
					local newH = v.h + (v.y - cy)
					
					if newW >= v.defSizeW then
						v.w = newW
						v.x = cx
					end
					if newH >= v.defSizeH then
						v.h = newH
						v.y = cy
					end
				end
				
				v:setUpResizePoints()
			end
		end
	end

	if isCursorShowing() and self.moving.bool and elementsID:count() >= 1 then
		local v = elementsID.tbl[self.moving.id]
		if v then
			local cx,cy = getCursorPosition()
			cx,cy = cx*scr.x,cy*scr.y
			if v.type == "LINE" then
				v.catchAreaX = cx-self.dragX
				v.catchAreaY = cy-self.dragY
			else
				v.x = cx-self.dragX
				v.y = cy-self.dragY
			end
			
			if v.type ~= "CIRCLE" then
				v:setUpResizePoints()
			end
			if v.type == "LINE" then
				local width = v.x2-v.x
				local height = v.y2-v.y
				local isHeightNegative = height < 0
				local isWidthNegative = width < 0
				
				v.x = isWidthNegative and v.catchAreaX+v.w or v.catchAreaX
				v.y = isHeightNegative and v.catchAreaY+v.h or v.catchAreaY
				v.x2 = isWidthNegative and v.x-v.w or v.x+v.w
				v.y2 = isHeightNegative and v.y-v.h or v.y+v.h
			end
		end
	end
end

function ResizeAndDragModule:onClick(btn,state,x,y)
	if guied.customizing then return end
	if btn ~= "left" then return end
	if state == "down" then 
		if LayersPanel and LayersPanel:isMouseOver() then return end
		
		-- Top-most visible, unlocked layer under the cursor wins.
		elementsID:forEachHitOrder(function(v)
			if not v.visible or v.locked then return false end
			
			if v.type ~= "CIRCLE" and guied.resizeMode then
				for _,v1 in pairs(v.resizePoints) do
					if isMouseInPosition(v1.x,v1.y,v1.w,v1.h) then
						self.resizing.id = v.id
						self.resizing.bool = true
						self.resizing.corner = v1.corner
						return true
					end
				end
			else
				local isMouseIn = v.type == "CIRCLE" and isMouseInCircle(v.x,v.y,v.attributes[3].value) or ( v.type == "LINE" and isMouseInPosition(v.catchAreaX,v.catchAreaY,v.w,v.h) or isMouseInPosition(v.x,v.y,v.w,v.h))	
				if isMouseIn then
					self.dragX = v.type == "LINE" and x-v.catchAreaX or x-v.x
					self.dragY = v.type == "LINE" and y-v.catchAreaY or y-v.y
					self.moving.id = v.id
					self.moving.bool = true
					return true
				end
			end
			
			return false
		end)
	else
		self.resizing.id = 0
		self.resizing.bool = false
		self.resizing.corner = ""
		
		self.moving.id = 0
		self.bool = false
	end	
end

ResizeAndDragModule:new()