--[[--------------------------------------------------
	GUI Editor
	client/layerspanel.lua

	A Photoshop-style layers panel for the editor.

	- Lists every element currently on the canvas, top-most layer first.
	- Click a row to select that element (same as clicking it on canvas).
	- "V"/"H" toggles per-layer visibility.
	- "U"/"L" toggles whether a layer is locked (can't be selected for
	  dragging/resizing, and ignores the rotate/resize-via-key shortcuts).
	- "^" / "v" buttons move a layer one step towards the front/back.
	- "X" deletes the layer.

	The panel is opened/closed via the LAYERS button on the toolbar, or
	by pressing L (while not typing into another editor window).
--]]--------------------------------------------------

LayersPanel = {}
LayersPanel.__index = LayersPanel

local white = tocolor(255,255,255,255)
local black = tocolor(0,0,0,255)

function LayersPanel:new()
	local instance = {}
	setmetatable(instance,LayersPanel)
	if instance:constructor() then
		return instance
	end
	return false
end

function LayersPanel:constructor()
	self.visible = false
	self.scroll = 0
	self.maxRows = 9
	
	self.panelW = scaleImage(340)
	self.rowH = scaleImage(38)
	self.headerH = scaleImage(42)
	
	self.bgColor = tocolor(28,28,28,235)
	self.headerColor = tocolor(15,15,15,245)
	self.rowColor = tocolor(45,45,45,200)
	self.hoverColor = tocolor(75,75,75,220)
	self.selectedColor = tocolor(0,110,170,230)
	
	self.func = {}
	self.func.render = function() self:render() end
	self.func.onClick = function(...) self:onClick(...) end
	self.func.onKey = function(...) self:onKey(...) end
	self.func.scrollUp = function() self:scroll1(-1) end
	self.func.scrollDown = function() self:scroll1(1) end
	
	addEventHandler("onClientRender",root,self.func.render)
	addEventHandler("onClientClick",root,self.func.onClick)
	addEventHandler("onClientKey",root,self.func.onKey)
	
	bindKey("mouse_wheel_up","down",self.func.scrollUp)
	bindKey("mouse_wheel_down","down",self.func.scrollDown)
	
	return true
end

function LayersPanel:toggle()
	self.visible = not self.visible
	self.scroll = 0
end

-- Position/size -------------------------------------------------------------

function LayersPanel:getPosition()
	local margin = scaleImage(20)
	return scr.x - self.panelW - margin, margin
end

function LayersPanel:getVisibleRowCount()
	local total = elementsID:count()
	if total == 0 then return 1 end -- room for the "no layers" message
	return math.min(self.maxRows,total)
end

function LayersPanel:getHeight()
	return self.headerH + self:getVisibleRowCount()*self.rowH
end

function LayersPanel:isMouseOver()
	if not self.visible then return false end
	local x,y = self:getPosition()
	return isMouseInPosition(x,y,self.panelW,self:getHeight())
end

function LayersPanel:getMaxScroll()
	return math.max(0,elementsID:count()-self.maxRows)
end

-- Returns the layout rectangles for the buttons/labels of a single row.
function LayersPanel:getRowLayout(rowX,rowY)
	local pad = scaleImage(6)
	local btn = self.rowH-(pad*2)
	
	local visX = rowX+pad
	local lockX = visX+btn+pad
	
	local delX = (rowX+self.panelW)-pad-btn
	local downX = delX-pad-btn
	local upX = downX-pad-btn
	
	local nameX = lockX+btn+pad
	local nameW = upX-pad-nameX
	
	return {
		vis  = {x=visX,  y=rowY+pad, w=btn,   h=btn},
		lock = {x=lockX, y=rowY+pad, w=btn,   h=btn},
		name = {x=nameX, y=rowY,     w=nameW, h=self.rowH},
		up   = {x=upX,   y=rowY+pad, w=btn,   h=btn},
		down = {x=downX, y=rowY+pad, w=btn,   h=btn},
		del  = {x=delX,  y=rowY+pad, w=btn,   h=btn},
	}
end

-- The layer currently shown in visual row `row` (1 = top of the list).
function LayersPanel:getElementForRow(row)
	local order = elementsID.order
	local layerIndex = (#order-(row-1))-self.scroll
	return order[layerIndex]
end

-- Input -----------------------------------------------------------------------

function LayersPanel:scroll1(direction)
	if not self.visible then return end
	if not self:isMouseOver() then return end
	
	self.scroll = math.max(0,math.min(self:getMaxScroll(),self.scroll+direction))
end

function LayersPanel:onKey(btn,state)
	if not state then return end
	if btn ~= "l" then return end
	if guied.customizing then return end
	
	self:toggle()
end

function LayersPanel:onClick(btn,state,x,y)
	if not self.visible then return end
	if btn ~= "left" then return end
	if state ~= "down" then return end
	if not self:isMouseOver() then return end
	
	local px,py = self:getPosition()
	local visibleRows = self:getVisibleRowCount()
	
	if elementsID:count() == 0 then return end
	
	for row=1,visibleRows do
		local element = self:getElementForRow(row)
		if element then
			local rowY = py+self.headerH+((row-1)*self.rowH)
			local layout = self:getRowLayout(px,rowY)
			
			if isMouseInPosition(layout.vis.x,layout.vis.y,layout.vis.w,layout.vis.h) then
				element.visible = not element.visible
				if not element.visible and guiSelector.selected == element then
					guiSelector.selected = false
				end
				return
			end
			
			if isMouseInPosition(layout.lock.x,layout.lock.y,layout.lock.w,layout.lock.h) then
				element.locked = not element.locked
				return
			end
			
			if isMouseInPosition(layout.up.x,layout.up.y,layout.up.w,layout.up.h) then
				elementsID:moveLayerUp(element)
				return
			end
			
			if isMouseInPosition(layout.down.x,layout.down.y,layout.down.w,layout.down.h) then
				elementsID:moveLayerDown(element)
				return
			end
			
			if isMouseInPosition(layout.del.x,layout.del.y,layout.del.w,layout.del.h) then
				deleteElement(element)
				self.scroll = math.min(self.scroll,self:getMaxScroll())
				return
			end
			
			if isMouseInPosition(layout.name.x,layout.name.y,layout.name.w,layout.name.h) then
				guiSelector.selected = element
				return
			end
		end
	end
end

-- Rendering -------------------------------------------------------------------

function LayersPanel:render()
	if not self.visible then return end
	
	local x,y = self:getPosition()
	local h = self:getHeight()
	local total = elementsID:count()
	
	dxDrawRectangle(x,y,self.panelW,h,self.bgColor)
	
	dxDrawRectangle(x,y,self.panelW,self.headerH,self.headerColor)
	dxDrawText("LAYERS ("..total..")",x+scaleImage(10),y,x+self.panelW-scaleImage(10),y+self.headerH,white,1,"default-bold","left","center")
	
	if total == 0 then
		local rowY = y+self.headerH
		dxDrawText("Add a shape from the toolbar\nto create your first layer.",x+scaleImage(10),rowY,x+self.panelW-scaleImage(10),rowY+self.rowH,tocolor(190,190,190,255),0.8,"default","left","center",true,true)
		return
	end
	
	local visibleRows = self:getVisibleRowCount()
	
	for row=1,visibleRows do
		local element = self:getElementForRow(row)
		if element then
			local rowY = y+self.headerH+((row-1)*self.rowH)
			local layout = self:getRowLayout(x,rowY)
			
			local rowColor = self.rowColor
			if guiSelector.selected == element then
				rowColor = self.selectedColor
			elseif isMouseInPosition(x,rowY,self.panelW,self.rowH) then
				rowColor = self.hoverColor
			end
			dxDrawRectangle(x,rowY,self.panelW,self.rowH,rowColor)
			
			-- Visibility toggle
			dxDrawRectangle(layout.vis.x,layout.vis.y,layout.vis.w,layout.vis.h,element.visible and tocolor(90,200,90,255) or tocolor(110,110,110,255))
			dxDrawText(element.visible and "V" or "H",layout.vis.x,layout.vis.y,layout.vis.x+layout.vis.w,layout.vis.y+layout.vis.h,black,0.8,"default-bold","center","center")
			
			-- Lock toggle
			dxDrawRectangle(layout.lock.x,layout.lock.y,layout.lock.w,layout.lock.h,element.locked and tocolor(230,160,40,255) or tocolor(100,100,100,255))
			dxDrawText(element.locked and "L" or "U",layout.lock.x,layout.lock.y,layout.lock.x+layout.lock.w,layout.lock.y+layout.lock.h,black,0.8,"default-bold","center","center")
			
			-- Name + type
			local nameColor = element.visible and white or tocolor(160,160,160,255)
			dxDrawText((element.layerName or element.type).." ["..element.type.."]",layout.name.x,layout.name.y,layout.name.x+layout.name.w,layout.name.y+layout.name.h,nameColor,0.85,"default-bold","left","center",true,false,true)
			
			-- Reorder buttons
			dxDrawRectangle(layout.up.x,layout.up.y,layout.up.w,layout.up.h,tocolor(95,95,95,255))
			dxDrawText("^",layout.up.x,layout.up.y,layout.up.x+layout.up.w,layout.up.y+layout.up.h,white,1,"default-bold","center","center")
			
			dxDrawRectangle(layout.down.x,layout.down.y,layout.down.w,layout.down.h,tocolor(95,95,95,255))
			dxDrawText("v",layout.down.x,layout.down.y,layout.down.x+layout.down.w,layout.down.y+layout.down.h,white,1,"default-bold","center","center")
			
			-- Delete button
			dxDrawRectangle(layout.del.x,layout.del.y,layout.del.w,layout.del.h,tocolor(190,60,60,255))
			dxDrawText("X",layout.del.x,layout.del.y,layout.del.x+layout.del.w,layout.del.y+layout.del.h,white,1,"default-bold","center","center")
		end
	end
	
	if self:getMaxScroll() > 0 then
		local hintY = y+h
		local hint = string.format("Scroll: %d/%d",self.scroll+1,self:getMaxScroll()+1)
		dxDrawText(hint,x,hintY,x+self.panelW,hintY+scaleImage(20),tocolor(200,200,200,200),0.7,"default","center","top")
	end
end

LayersPanel = LayersPanel:new()
