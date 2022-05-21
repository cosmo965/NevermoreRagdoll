--[=[
	This represents a list of key bindings for a specific mode. While this is a useful object to query
	for showing icons and input hints to the user, in general, it is recommended that binding occur
	at the list level instead of at the input mode level. That way, if the user switches to another input
	mode then input is immediately processed.

	@class InputKeyMap
]=]

local require = require(script.Parent.loader).load(script)

local BaseObject = require("BaseObject")
local ValueObject = require("ValueObject")
local InputMode = require("InputMode")

local InputKeyMap = setmetatable({}, BaseObject)
InputKeyMap.ClassName = "InputKeyMap"
InputKeyMap.__index = InputKeyMap

function InputKeyMap.new(inputMode, inputTypes)
	assert(InputMode.isInputMode(inputMode), "Bad inputMode")
	assert(type(inputTypes) == "table" or inputTypes == nil, "Bad inputTypes")

	local self = setmetatable(BaseObject.new(), InputKeyMap)

	self._inputMode = assert(inputMode, "No inputMode")

	self._inputType = ValueObject.new(inputTypes or {})
	self._maid:GiveTask(self._inputType)

	return self
end

--[=[
	Gets the input mode for this keymap. This will not change.
]=]
function InputKeyMap:GetInputMode()
	return self._inputMode
end

function InputKeyMap:SetInputTypesList(inputTypes)
	assert(type(inputTypes) == "table", "Bad inputTypes")

	self._inputType.Value = inputTypes
end

function InputKeyMap:ObserveInputTypesList()
	return self._inputType:Observe()
end

function InputKeyMap:GetInputTypesList()
	return self._inputType.Value
end

return InputKeyMap