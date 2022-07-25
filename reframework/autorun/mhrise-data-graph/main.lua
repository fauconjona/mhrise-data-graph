local HUNTERS = require('mhrise-data-graph/modules/hunters/module')
local UTIL = require('mhrise-data-graph/util')

local this = {}

-- Private

local quest_manager
local lastSecond = 0
local results_done = false

local function handle_start()
	log.info('Data Graph: starting')
	results_done = false
	UTIL.init_local_player_id()
	HUNTERS.start()
end

local function handle_results()
	if results_done then
		return
	end
	results_done = true
	local date = os.date("%Y-%m-%d-%H-%M")
	local result = {
		date = date
	}
	local hunters = HUNTERS.results()

	if hunters == nil then
		log.error('Data Graph: No hunters results')
	else 
		result.hunters = hunters
	end

	local filename = 'records/' .. os.date("%Y-%m-%d-%H-%M") .. '.json'

	json.dump_file(filename, result)

	log.info('Data Graph: Added damage data to ' .. filename)
end

local function handle_stop()
	HUNTERS.stop()
end

local function handle_changed_game_status(args)
	local status = sdk.to_int64(args[3])
	-- 1 = Village
	-- 2 = Quest
	-- 3 = Results
	log.info("Game status changed to " .. status)

	if status == 1 then 
		handle_stop()
	elseif status == 2 then
		handle_start()
	elseif status == 3 then
		--handle_results()
	end
end

local function init_singletons()
	if not quest_manager then
		quest_manager = sdk.get_managed_singleton('snow.QuestManager')
		sdk.hook(
			sdk.find_type_definition('snow.QuestManager'):get_method('onChangedGameStatus'),
			handle_changed_game_status,
			function(retval) return retval; end
		)
	end
end

local function handle_frame()
	if not quest_manager then
		quest_manager = sdk.get_managed_singleton('snow.QuestManager')
		return
	end
	local questStatus = quest_manager:get_field('_QuestStatus')
  	local is_in_quest = questStatus == 2
  	local is_in_post_quest = questStatus > 2

	if is_in_quest then
		if math.floor(UTIL.get_time()) ~= lastSecond then
			HUNTERS.update()
			lastSecond = math.floor(UTIL.get_time())
		end
	elseif is_in_post_quest then
		handle_results()
	end
end

-- Public

this.log = function(text)
	log.info('Data Graph: ' .. text)
end

this.init = function()
	init_singletons()
	HUNTERS.init()
	re.on_frame(function()
		handle_frame()
    end)
	log.info('Data Graph: Initialized')
end

-- DEBUG
DEBUG_UTIL = UTIL
DEBUG_DATA_GRAPH = this
DEBUG_HUNTERS = HUNTERS
DEBUG_DATA_START = handle_start

return this