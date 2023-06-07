
function oldKeyThing()
	if love.keyboard.isDown("lctrl", "rctrl") then
		if key == "s" then     saveBoard()
		elseif key == "l" then loadBoard()
		elseif key == "r" then resetBoard()
		elseif key == "d" then addDefaults()
		elseif key == "p" then showPlotter = not showPlotter
		elseif key == "g" then graphicSettings.betterGraphics = not graphicSettings.betterGraphics
		elseif key == "t" then graphicSettings.gateUseAltBorderColor = not graphicSettings.gateUseAltBorderColor
		elseif key == "c" then
			love.system.setClipboardText(json.encode({ gates=gates, peripherals=peripherals, connections=connections }))
			messages.add("Board Data copied to Clipboard!")
		elseif key == "v" then
			local text = love.system.getClipboardText()
			if text:match("gates") and text:match("peripherals") and text:match("connections") then
				local data = json.decode(text)
				if data then
					resetBoard()
					for i, gatedata in ipairs(data.gates) do			
						addGate(loadGATE(gatedata))
					end
					for i, peripheraldata in ipairs(data.peripherals) do
						addPeripheral(loadPERIPHERAL(peripheraldata))
					end
					for i, connection in ipairs(data.connections) do
						connections:append(connection)
					end
					messages.add("Board Data loaded from Clipboard!")
				end
			end
		elseif key == "q" then
			love.event.quit()
		end
	else
		if key == "d" then showDebug = not showDebug
		elseif key == "t" then showTelemetry = not showTelemetry
		elseif key == "g" then
			addGroup()
			selection = {x1=0, y1=0, x2=0, y2=0, ids={}}
		end
	end
	if key == "delete" then
		if selectedPinID ~= 0 then -- First Pin of new Connection selected
			local pin = getPinByID(selectedPinID)
			if pin then pin.isConnected = false end
			selectedPinID = 0
		else  -- no Pin selected
			local pinID = getPinIDByPos(x, y)
			if pinID then
				removeConnectionWithPinID(pinID)
			else
				-- local groupID = getGroupIDByPos(love.mouse.getX(), love.mouse.getY())
				-- if groupID then
				-- 	removeGroupByID(groupID, love.keyboard.isDown("lshift"))
				-- else
				-- 	if getBobjects():count() > 0 then
				-- 		local bobID = getBobIDByPos(love.mouse.getX(), love.mouse.getY())
				-- 		if bobID then
				-- 			removeBobByID(bobID)
				-- 		end
				-- 	end
				-- end

				local bobID = getBobIDByPos(love.mouse.getX(), love.mouse.getY())
				if bobID then
					removeBobByID(bobID)
				else
					local groupID = getGroupIDByPos(love.mouse.getX(), love.mouse.getY())
					if groupID then
						removeGroupByID(groupID, love.keyboard.isDown("lshift"))
					end
				end

			end
		end
	end
	if key == "h" then
		showHelp = not showHelp
	end
	if love.keyboard.isDown("lalt") then
		if key == "1" then
			save()
			currentBoard = 1
			load()
		elseif key == "2" then
			save()
			currentBoard = 2
			load()
		elseif key == "3" then
			save()
			currentBoard = 3
			load()
		elseif key == "4" then
			save()
			currentBoard = 4
			load()
		elseif key == "5" then
			save()
			currentBoard = 5
			load()
		elseif key == "6" then
			save()
			currentBoard = 6
			load()
		elseif key == "7" then
			save()
			currentBoard = 7
			load()
		elseif key == "8" then
			save()
			currentBoard = 8
			load()
		elseif key == "9" then
			save()
			currentBoard = 9
			load()
		elseif key == "0" then
			save()
			currentBoard = 10
			load()
		end							
	elseif not love.keyboard.isDown("lgui") then
		if key == "1" then
			addGate(constructAND(love.mouse.getX() - GATEgetWidth()/2, love.mouse.getY() - GATEgetHeight()/2))
		elseif key == "2" then
			addGate(constructOR(love.mouse.getX() - GATEgetWidth()/2, love.mouse.getY() - GATEgetHeight()/2))
		elseif key == "3" then
			addGate(constructNOT(love.mouse.getX() - GATEgetWidth()/2, love.mouse.getY() - GATEgetHeight()/2))
		elseif key == "4" then
			addGate(constructNAND(love.mouse.getX() - GATEgetWidth()/2, love.mouse.getY() - GATEgetHeight()/2))
		elseif key == "5" then
			addGate(constructNOR(love.mouse.getX() - GATEgetWidth()/2, love.mouse.getY() - GATEgetHeight()/2))
		elseif key == "6" then
			addGate(constructXOR(love.mouse.getX() - GATEgetWidth()/2, love.mouse.getY() - GATEgetHeight()/2))
		elseif key == "7" then
			addGate(constructXNOR(love.mouse.getX() - GATEgetWidth()/2, love.mouse.getY() - GATEgetHeight()/2))
		elseif key == "8" then
			addPeripheral(constructINPUT(love.mouse.getX() - PERIPHERALgetWidth()/2, love.mouse.getY() - PERIPHERALgetHeight()/2))
		elseif key == "9" then
			addPeripheral(constructCLOCK(love.mouse.getX() - PERIPHERALgetWidth()/2, love.mouse.getY()- PERIPHERALgetHeight()/2))
		elseif key == "0" then
			addPeripheral(constructOUTPUT(love.mouse.getX() - PERIPHERALgetWidth()/2, love.mouse.getY()- PERIPHERALgetHeight()/2))
		elseif key == "b" then
			addPeripheral(constructBUFFER(love.mouse.getX() - PERIPHERALgetWidth()/2, love.mouse.getY()- PERIPHERALgetHeight()/2))
		end
	end
end