--[=[
	@class GameProductServiceHelper
]=]

local require = require(script.Parent.loader).load(script)

local BaseObject = require("BaseObject")
local promiseBoundClass = require("promiseBoundClass")
local RxBinderUtils = require("RxBinderUtils")
local RxBrioUtils = require("RxBrioUtils")
local GameConfigAssetTypeUtils = require("GameConfigAssetTypeUtils")
local RxStateStackUtils = require("RxStateStackUtils")

local GameProductServiceHelper = setmetatable({}, BaseObject)
GameProductServiceHelper.ClassName = "GameProductServiceHelper"
GameProductServiceHelper.__index = GameProductServiceHelper

function GameProductServiceHelper.new(playerProductManagerBinder)
	local self = setmetatable(BaseObject.new(), GameProductServiceHelper)

	self._playerProductManagerBinder = assert(playerProductManagerBinder, "Bad playerProductManagerBinder")

	return self
end

--[=[
	Returns true if item has been purchased this session

	@param player Player
	@param assetType GameConfigAssetType
	@param idOrKey string | number
	@return boolean
]=]
function GameProductServiceHelper:HasPlayerPurchasedThisSession(player, assetType, idOrKey)
	assert(typeof(player) == "Instance" and player:IsA("Player"), "Bad player")
	assert(GameConfigAssetTypeUtils.isAssetType(assetType), "Bad assetType")
	assert(type(idOrKey) == "number" or type(idOrKey) == "string", "Bad idOrKey")

	local marketeer = self:_getPlayerMarketeer(player)
	if not marketeer then
		return false
	end

	local assetTracker = marketeer:GetAssetTrackerOrError(assetType)
	return assetTracker:HasPurchasedThisSession(idOrKey)
end

--[=[
	Prompts the user to purchase the asset, and returns true if purchased

	@param player Player
	@param assetType GameConfigAssetType
	@param idOrKey string | number
	@return Promise<boolean>
]=]
function GameProductServiceHelper:PromisePromptPurchase(player, assetType, idOrKey)
	assert(typeof(player) == "Instance" and player:IsA("Player"), "Bad player")
	assert(GameConfigAssetTypeUtils.isAssetType(assetType), "Bad assetType")
	assert(type(idOrKey) == "number" or type(idOrKey) == "string", "Bad idOrKey")

	return self:_promisePlayerMarketeer(player)
		:Then(function(marketeer)
			local assetTracker = marketeer:GetAssetTrackerOrError(assetType)
			return assetTracker:PromisePromptPurchase(idOrKey)
		end)
end

--[=[
	Returns true if item has been purchased this session

	@param player Player
	@param assetType GameConfigAssetType
	@param idOrKey string | number
	@return Promise<boolean>
]=]
function GameProductServiceHelper:PromisePlayerOwnership(player, assetType, idOrKey)
	assert(typeof(player) == "Instance" and player:IsA("Player"), "Bad player")
	assert(GameConfigAssetTypeUtils.isAssetType(assetType), "Bad assetType")
	assert(type(idOrKey) == "number" or type(idOrKey) == "string", "Bad idOrKey")

	return self:_promisePlayerMarketeer(player)
		:Then(function(marketeer)
			local ownershipTracker = marketeer:GetOwnershipTrackerOrError(assetType)
			return ownershipTracker:PromiseOwnsAsset(idOrKey)
		end)
end

--[=[
	Returns true if item has been purchased this session

	@param player Player
	@param assetType GameConfigAssetType
	@return Promise<boolean>
]=]
function GameProductServiceHelper:PromiseIsOwnable(player, assetType)
	assert(typeof(player) == "Instance" and player:IsA("Player"), "Bad player")
	assert(GameConfigAssetTypeUtils.isAssetType(assetType), "Bad assetType")

	return self:_promisePlayerMarketeer(player)
		:Then(function(marketeer)
			return marketeer:IsOwnable(assetType)
		end)
end

--[=[
	Observes player ownership

	@param player Player
	@param assetType GameConfigAssetType
	@param idOrKey string | number
	@return Promise<boolean>
]=]
function GameProductServiceHelper:ObservePlayerOwnership(player, assetType, idOrKey)
	assert(typeof(player) == "Instance" and player:IsA("Player"), "Bad player")
	assert(GameConfigAssetTypeUtils.isAssetType(assetType), "Bad assetType")
	assert(type(idOrKey) == "number" or type(idOrKey) == "string", "Bad idOrKey")

	-- TODO: Maybe make this more light weight and cache
	return self:_observePlayerProductManagerBrio(player):Pipe({
		RxBrioUtils.switchMapBrio(function(playerProductManager)
			local marketeer = playerProductManager:GetMarketeer()
			local ownershipTracker = marketeer:GetOwnershipTrackerOrError(assetType)
			return ownershipTracker:ObserveOwnsAsset(idOrKey)
		end);
		RxStateStackUtils.topOfStack(false);
	})
end

function GameProductServiceHelper:_observePlayerProductManagerBrio(player)
	assert(typeof(player) == "Instance" and player:IsA("Player"), "Bad player")

	return RxBinderUtils.observeBoundClassBrio(self._playerProductManagerBinder, player)
end

function GameProductServiceHelper:_promisePlayerProductManager(player)
	assert(typeof(player) == "Instance" and player:IsA("Player"), "Bad player")

	return promiseBoundClass(self._playerProductManagerBinder, player)
end

function GameProductServiceHelper:_promisePlayerMarketeer(player)
	assert(typeof(player) == "Instance" and player:IsA("Player"), "Bad player")

	return self:_promisePlayerProductManager(player)
		:Then(function(productManager)
			return productManager:GetMarketeer()
		end)
end

function GameProductServiceHelper:_getPlayerProductManager(player)
	assert(typeof(player) == "Instance" and player:IsA("Player"), "Bad player")

	return self._playerProductManagerBinder:Get(player)
end

function GameProductServiceHelper:_getPlayerMarketeer(player)
	local productManager = self:_getPlayerProductManager(player)
	if productManager then
		return productManager:GetMarketeer()
	else
		return nil
	end
end

return GameProductServiceHelper