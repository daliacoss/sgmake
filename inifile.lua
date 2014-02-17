-- Copyright 2011 Bart van Strien. All rights reserved.
-- 
-- Redistribution and use in source and binary forms, with or without modification, are
-- permitted provided that the following conditions are met:
-- 
--    1. Redistributions of source code must retain the above copyright notice, this list of
--       conditions and the following disclaimer.
-- 
--    2. Redistributions in binary form must reproduce the above copyright notice, this list
--       of conditions and the following disclaimer in the documentation and/or other materials
--       provided with the distribution.
-- 
-- THIS SOFTWARE IS PROVIDED BY BART VAN STRIEN ''AS IS'' AND ANY EXPRESS OR IMPLIED
-- WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND
-- FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL BART VAN STRIEN OR
-- CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
-- CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
-- SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON
-- ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING
-- NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF
-- ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
-- 
-- The views and conclusions contained in the software and documentation are those of the
-- authors and should not be interpreted as representing official policies, either expressed
-- or implied, of Bart van Strien.
--
-- The above license is known as the Simplified BSD license.

inifile = {}

local lines
local write

if love then
	lines = love.filesystem.lines
	write = love.filesystem.write
else
	--modified to remove asserts
	lines = function(name)
		local f = io.open(name)
		if f then return f:lines() else return nil end
	end
	write = function(name, contents)
		local f = io.open(name, "w")
		if f then return f:write(contents) else return nil end
	end
end

function inifile.parse(name)
	local t = {}
	local section
	if lines(name) then
		for line in lines(name) do
			local s = line:match("^%[([^%]]+)%]$")
			if s then
				section = s
				t[section] = t[section] or {}
			end
			--modified to allow underscores in key - [%w_] instead of %w
			local key, value = line:match("^([%w_]+)%s-=%s-(.+)$")
			if key and value then
				if tonumber(value) then value = tonumber(value) end
				if value == "true" then value = true end
				if value == "false" then value = false end
				t[section][key] = value
			end
		end
		io.close()
		return t
	else
		return nil
	end

end

function inifile.save(name, t, sort, sortf)
	local contents = ""

	for section, s in pairs(t) do
		contents = contents .. ("[%s]\n"):format(section)

		--modified to allow sorting keys
		local sorted_keys = {}
		if sort then
			for key in pairs(s) do
				table.insert(sorted_keys, key)
			end
			table.sort(sorted_keys,sortf) --sortf can be nil
			for key,value in pairs(sorted_keys) do
				if type(value) == "string" then
					contents = contents..("%s=%s\n"):format(value,tostring(s[value]))
				end
			end
		else
			for key, value in pairs(s) do
				contents = contents .. ("%s=%s\n"):format(key, tostring(value))
			end
		end

		contents = contents .. "\n"
	end
	write(name, contents)
	io.close()
end

return inifile
