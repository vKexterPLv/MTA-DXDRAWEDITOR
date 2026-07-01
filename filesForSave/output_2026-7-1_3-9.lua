local scr = Vector2(guiGetScreenSize())
local zoom = scr.x < 2048 and math.min(2, 2048/scr.x) or 0.9;

function dxDrawRoundedRectangle(x, y, width, height, radius, color, postGUI, subPixelPositioning)
    dxDrawRectangle(x+radius, y+radius, width-(radius*2), height-(radius*2), color, postGUI, subPixelPositioning)
    dxDrawCircle(x+radius, y+radius, radius, 180, 270, color, color, 16, 1, postGUI)
    dxDrawCircle(x+radius, (y+height)-radius, radius, 90, 180, color, color, 16, 1, postGUI)
    dxDrawCircle((x+width)-radius, (y+height)-radius, radius, 0, 90, color, color, 16, 1, postGUI)
    dxDrawCircle((x+width)-radius, y+radius, radius, 270, 360, color, color, 16, 1, postGUI)
    dxDrawRectangle(x, y+radius, radius, height-(radius*2), color, postGUI, subPixelPositioning)
    dxDrawRectangle(x+radius, y+height-radius, width-(radius*2), radius, color, postGUI, subPixelPositioning)
    dxDrawRectangle(x+width-radius, y+radius, radius, height-(radius*2), color, postGUI, subPixelPositioning)
    dxDrawRectangle(x+radius, y, width-(radius*2), radius, color, postGUI, subPixelPositioning)
end


addEventHandler('onClientRender',root,function()
	dxDrawRectangle(scr.x/2 - (79.668849588895)/zoom,scr.y/2 - (79.668849588895)/zoom,159/zoom,159/zoom,-16776291,false)
	dxDrawRectangle(568.92002685547/zoom,scr.y/2 - (202.92000564575)/zoom,50/zoom,50/zoom,-1,false)
end)