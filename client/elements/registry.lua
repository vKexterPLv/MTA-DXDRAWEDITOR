--[[--------------------------------------------------
	GUI Editor
	client/elements/registry.lua

	Central bookkeeping for editor objects.

	IDSystem
		A minimal ID <-> object lookup table. Used as-is for
		fonts (fontsID), where ordering doesn't matter.

	ElementRegistry
		Everything IDSystem does, plus an ordered "layer stack"
		(self.order) that drives:
			- rendering order (main.lua draw loop)
			- hit-testing order for selection / resize / context menu
			- code generation order (toolbar output)
			- the Layers panel UI

	Layer order convention:
		order[1]        = bottom-most layer, drawn FIRST
		order[#order]   = top-most layer, drawn LAST (visually on top)

	Newly created elements are appended to the end of `order`, so
	they appear above everything else - matching what users expect
	when adding a new shape from the toolbar.
--]]--------------------------------------------------

-- ===========================================================================
-- IDSystem - plain ID <-> object table (used for fonts)
-- ===========================================================================

IDSystem = {}
IDSystem.__index = IDSystem

function IDSystem:new()
	local instance = {}
	setmetatable(instance,IDSystem)
	if instance:constructor() then
		return instance
	end
	return false
end

function IDSystem:constructor()
	self.tbl = {}
	return true
end

function IDSystem:findFreeIndex()
	local i = 1
	while self.tbl[i] do
		i = i + 1
	end
	return i
end

function IDSystem:assignID(element)
	local index = self:findFreeIndex()
	self.tbl[index] = element
	return index
end

function IDSystem:separateID(index)
	if self.tbl[index] then
		self.tbl[index] = nil
		return true
	else
		return false
	end
end

function IDSystem:getID(index)
	if self.tbl[index] then
		return self.tbl[index]
	else
		return false
	end
end

-- ===========================================================================
-- ElementRegistry - IDSystem + ordered layer stack
-- ===========================================================================

ElementRegistry = {}
ElementRegistry.__index = ElementRegistry

function ElementRegistry:new()
	local instance = {}
	setmetatable(instance,ElementRegistry)
	if instance:constructor() then
		return instance
	end
	return false
end

function ElementRegistry:constructor()
	self.tbl = {}   -- id -> element (sparse, kept for direct ID lookups)
	self.order = {} -- ordered layer stack, see header for convention
	return true
end

-- ID handling ---------------------------------------------------------------

function ElementRegistry:findFreeIndex()
	local i = 1
	while self.tbl[i] do
		i = i + 1
	end
	return i
end

-- Assigns an ID, registers the element for ID-based lookups and pushes it
-- onto the top of the layer stack. Also fills in sensible layer defaults
-- (name/visible/locked) if the element doesn't already define them.
function ElementRegistry:assignID(element)
	local index = self:findFreeIndex()
	self.tbl[index] = element
	element.id = index

	if element.layerName == nil then
		element.layerName = string.format("%s %d",element.type or "ELEMENT",index)
	end
	if element.visible == nil then
		element.visible = true
	end
	if element.locked == nil then
		element.locked = false
	end

	table.insert(self.order,element)
	return index
end

-- Removes an element from both the ID table and the layer stack.
function ElementRegistry:separateID(index)
	local element = self.tbl[index]
	if not element then return false end

	self.tbl[index] = nil

	for i=1,#self.order do
		if self.order[i] == element then
			table.remove(self.order,i)
			break
		end
	end

	return true
end

function ElementRegistry:getID(index)
	if self.tbl[index] then
		return self.tbl[index]
	else
		return false
	end
end

function ElementRegistry:count()
	return #self.order
end

-- Layer / render order --------------------------------------------------------

function ElementRegistry:getLayerIndex(element)
	for i=1,#self.order do
		if self.order[i] == element then
			return i
		end
	end
	return nil
end

-- bottom -> top, i.e. the order elements should be drawn in.
function ElementRegistry:forEachRenderOrder(callback)
	for i=1,#self.order do
		callback(self.order[i],i)
	end
end

-- top -> bottom, i.e. the order clicks should be tested against
-- (whatever is drawn on top should be hit first).
-- If the callback returns true, iteration stops early.
function ElementRegistry:forEachHitOrder(callback)
	for i=#self.order,1,-1 do
		if callback(self.order[i],i) then
			return true
		end
	end
	return false
end

-- Moves the element one step towards the front (drawn later / on top).
function ElementRegistry:moveLayerUp(element)
	local i = self:getLayerIndex(element)
	if i and i < #self.order then
		self.order[i],self.order[i+1] = self.order[i+1],self.order[i]
		return true
	end
	return false
end

-- Moves the element one step towards the back (drawn earlier / below).
function ElementRegistry:moveLayerDown(element)
	local i = self:getLayerIndex(element)
	if i and i > 1 then
		self.order[i],self.order[i-1] = self.order[i-1],self.order[i]
		return true
	end
	return false
end

-- Brings the element to the very front (top-most layer).
function ElementRegistry:moveLayerToTop(element)
	local i = self:getLayerIndex(element)
	if i and i < #self.order then
		table.remove(self.order,i)
		table.insert(self.order,element)
		return true
	end
	return false
end

-- Sends the element to the very back (bottom-most layer).
function ElementRegistry:moveLayerToBottom(element)
	local i = self:getLayerIndex(element)
	if i and i > 1 then
		table.remove(self.order,i)
		table.insert(self.order,1,element)
		return true
	end
	return false
end

-- ===========================================================================
-- Shared helpers
-- ===========================================================================

-- Cleanly removes an element from the editor: clears the selection if needed,
-- removes it from the registry/layer stack and runs its destructor.
function deleteElement(element)
	if not element then return end

	if guiSelector.selected == element then
		guiSelector.selected = false
	end

	elementsID:separateID(element.id)
	element:delete()
end

fontsID = IDSystem:new()
elementsID = ElementRegistry:new()
