local vm = require("vm.vm")
local guide = require("core.guide")
local rojo = require("library.rojo")
local rbxlibs = require("library.rbxlibs")
local rbximports = require("library.rbximports")

local SHARED_CONTEXT = 0
local SERVER_CONTEXT = 1
local CLIENT_CONTEXT = 2

local function getAncestorServiceContext(obj)
	while obj.child and obj.child.Parent do
		obj = obj.child.Parent
		obj = guide.getObjectValue(obj) or obj
		if obj.type == "type.name" then
			local serviceContext = rbxlibs.RELEVANT_SERVICES[obj[1]]
			if serviceContext then
				return serviceContext
			end
		end
	end
end

local function inferSourceContext(obj)
	local uri = guide.getUri(obj)

	-- Infer context from the script type
	if uri:match("%.server%.lua[u]?$") then
		return SERVER_CONTEXT
	elseif uri:match("%.client%.lua[u]?$") then
		return CLIENT_CONTEXT
	end

	-- Infer context from server/shared/client folder
	if string.find(string.lower(uri), "/client/", 1, true) then
		return CLIENT_CONTEXT
	elseif string.find(string.lower(uri), "/shared/", 1, true) then
		return SHARED_CONTEXT
	elseif string.find(string.lower(uri), "/server/", 1, true) then
		return SERVER_CONTEXT
	end

	-- Infer context from the object's root ancestor
	local context = getAncestorServiceContext(obj)
	if context then
		return context
	end

	return SHARED_CONTEXT
end

local function findLibrary(libraryName, context)
	local candidates = rbximports.findMatchingScripts(libraryName)
	local candidateContexts = {}

	-- Try returning the correct context first
	for _, candidate in ipairs(candidates) do
		local candidateContext = inferSourceContext(candidate.object)
		candidateContexts[candidate] = candidateContext
		if candidateContext == context then
			return candidate.object
		end
	end

	-- If in a shared context, try returning a client context
	-- If in a client or server context, try returning a shared context
	for _, candidate in ipairs(candidates) do
		local candidateContext = candidateContexts[candidate]
		if candidateContext == (context == SHARED_CONTEXT and CLIENT_CONTEXT or SHARED_CONTEXT) then
			return candidate.object
		end
	end

	-- Try returning any context
	if #candidates > 0 then
		return candidates[1].object
	end
end

return function(status, obj, mode, noCache)
	if not obj then
		return
	end
	local cache, makeCache
	if not noCache then
		cache, makeCache = guide.getRefCache(status, obj, mode)
		if cache then
			for i = 1, #cache do
				status.results[#status.results + 1] = cache[i]
			end
			return
		end
	end

	if obj.type == "string" then
		local call = obj
		local requireSearchDepth = 5
		while requireSearchDepth > 0 do
			requireSearchDepth = requireSearchDepth - 1
			call = call.parent
			if call then
				if call.type == "call" then
					if call.node[1] == "require" then
						local libraryName = obj[1]
						local scriptCache = vm.getCache("scriptCache")
						local uri = guide.getUri(obj)
						local src = scriptCache[uri]
						if not src then
							src = rojo.Scripts[uri]
						end
						if not src then
							return
						end
						src = guide.getObjectValue(src)
						local module = findLibrary(libraryName, inferSourceContext(src))
						if module then
							status.results[#status.results + 1] = module
						end
						break
					end
				end
			else
				break
			end
		end
	end

	guide.cleanResults(status.results)
	if makeCache then
		makeCache(status.results)
	end
end
