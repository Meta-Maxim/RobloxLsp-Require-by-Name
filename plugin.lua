local vm = require("vm.vm")
local await = require("await")
local guide = require("core.guide")
local proto = require("proto.proto")
local fs = require("bee.filesystem")

local function findExePath()
	local n = 0
	while arg[n - 1] do
		n = n - 1
	end
	return arg[n]
end

local exePath = findExePath()
local exeDir = exePath:match("(.+)[/\\][%w_.-]+$")
local dll = package.cpath:match("[/\\]%?%.([a-z]+)")

local currentPath = debug.getinfo(1, "S").source:sub(2)
local rootPath = fs.path(currentPath):remove_filename():string()

local function getPathDelimiter()
	return dll == "dll" and "\\" or "/"
end

local function formatPath(path)
	path = path:gsub(dll == "dll" and "/" or "\\", getPathDelimiter())
	path = path:gsub(dll == "dll" and "%\\+" or "%/+", getPathDelimiter())
	return path
end

rootPath = formatPath(rootPath)

local function getRelativePath(str)
	return rootPath .. getPathDelimiter() .. str
end

local searchRefs = dofile(getRelativePath("reference-search.lua"))

do
	local guideInterface = dofile(getRelativePath("guide-interface.lua"))
	guideInterface.searchRefs = searchRefs
	local superCall = vm.interface.call
	vm.interface.call = function(status, func, args, index)
		local results = superCall(status, func, args, index)
		if results and #results > 0 then
			return results
		end
		if func[1] == "require" and index == 1 then
			await.delay()
			return guideInterface.require(status, args, index)
		end
	end
end

do
	local superSearch = guide.searchRefs
	guide.searchRefs = function(status, obj, mode)
		searchRefs(status, obj, mode, true)
		superSearch(status, obj, mode)
	end
end

local nameDocumentLink = dofile(getRelativePath("name-document-link.lua"))
proto.on("textDocument/documentLink", function(params)
	return nameDocumentLink(params.textDocument.uri)
end)

log.debug("Require-by-Name Plugin loaded!")
