--[[
	magicloader v1.0 by Rebmiami
	A simple script designed to improve the workflow of large scripts by allowing code to be split between several files.
	
	FEATURES:
	- Loads and concatenates several .lua files and runs them as if they were a single script.
	- Release mode compiles all .lua files into a single file which can be uploaded to the script manager.
	- Custom error handling that tells you which file the error occured in

	magicloader is public domain, meaning you can:
	- Use it in your own scripts without providing any credit
	- Make modifications to the script and release your own versions of it

	The full license can be found below:

		This is free and unencumbered software released into the public domain.
	
		Anyone is free to copy, modify, publish, use, compile, sell, or
		distribute this software, either in source code form or as a compiled
		binary, for any purpose, commercial or non-commercial, and by any
		means.
	
		In jurisdictions that recognize copyright laws, the author or authors
		of this software dedicate any and all copyright interest in the
		software to the public domain. We make this dedication for the benefit
		of the public at large and to the detriment of our heirs and
		successors. We intend this dedication to be an overt act of
		relinquishment in perpetuity of all present and future rights to this
		software under copyright law.
	
		THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
		EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
		MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
		IN NO EVENT SHALL THE AUTHORS BE LIABLE FOR ANY CLAIM, DAMAGES OR
		OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE,
		ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
		OTHER DEALINGS IN THE SOFTWARE.
	
		For more information, please refer to <https://unlicense.org>
--]]

-- The folder that lua files will be loaded from.
local prefix = "./scripts/Alchemagica"

-- The file that the release will be written to.
local outputFolder = "./scripts/Alchemagica/output/"
local outputFilename = "Alchemagica.lua"
local release = true

-- The files will be run in the order shown here.
-- Place more important files like those containing important functions or variables at the top.
local luaFiles = {
	"defs",
	"brewdata",
	"elementsdef",
	"elementsbehavior",
}

local luaFileContents = {

}

-- Prints text to the screen and the manager's console
local function print2(text, r, g, b)
	print(text)
	MANAGER.print(text, r or 255, g or 255, b or 255)
end

local function readFile(name)
	local f = io.open(prefix .. "/" .. name .. ".lua", "r")
	local text = f:read("*all")
	f:close()
	return text
end

local script = ""
for i=1,#luaFiles do
	local text = readFile(luaFiles[i])
	luaFileContents[i] = text
	script = script .. text .. "\n"
end

if release then
	if not fs.exists(outputFolder) then
		fs.makeDirectory(outputFolder)
	end
	local f = io.open(outputFolder .. outputFilename, "w")
	f:write(script)
	f:close()
end


-- Custom error handling
local function handleError(err)
	-- print(err)
	local finalMessage = ""
	local _, _, line, message = string.find(err, "^%[string.-]:(%d+):(.-)$")
	if not line then
		print2(err, 255, 0, 0)
	else
		local lineNo = tonumber(line)
	
		local luaFileLines = {}
	
		for i,j in pairs(luaFileContents) do
			luaFileLines[i] = {}
			for line in string.gmatch(j, ".-\n") do
				table.insert(luaFileLines[i], line)
			end
			if lineNo <= #luaFileLines[i] then
				print2("[magicloader " .. prefix .. "/" .. luaFiles[i] .. "]:" .. lineNo .. ":" .. message, 255, 0, 0)
				break
			else
				lineNo = lineNo - #luaFileLines[i] - 1
				if lineNo < 1 then
					print2("magicloader error location unknown '" .. err .. "'", 255, 0, 0)
					break
				end
			end
		end
		-- print(debug.traceback())
	end
end

-- Run the script
local func, readErr = loadstring(script)
if readErr then
	handleError(readErr)
	return
end
local status, runErr = pcall(func)
if runErr then
	handleError(runErr)
	return
end

print2("[magicloader] Successfully loaded script")