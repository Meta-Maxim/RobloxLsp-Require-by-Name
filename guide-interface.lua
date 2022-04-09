local vm = require("vm.vm")
local files = require("files")
local ws = require("workspace")
local guide = require("core.guide")
local rojo = require("library.rojo")

local m = {}

function m.searchFileReturn(results, ast, index)
	local returns = ast.returns
	if not returns then
		return
	end
	for _, ret in ipairs(returns) do
		local exp = ret[index]
		if exp then
			vm.mergeResults(results, { exp })
		end
	end
end

function m.require(status, args, index)
	local reqScript = args and args[1]
	if not reqScript then
		return nil
	end
	local results = {}
	local newStatus = guide.status(status)
	m.searchRefs(newStatus, reqScript, "def")
	for _, def in ipairs(newStatus.results) do
		if def.uri then
			local lib = rojo:matchLibrary(def.uri)
			if lib then
				return { lib }
			end
			if not files.eq(guide.getUri(args[1]), def.uri) then
				if not files.exists(def.uri) then
					ws.load(def.uri)
				end
				local ast = files.getAst(def.uri)
				if ast then
					m.searchFileReturn(results, ast.ast, index)
					break
				end
			end
		end
	end
	return results
end

return m
