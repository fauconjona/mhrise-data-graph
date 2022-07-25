-- Privates

local monsters = nil

-- Publics

local this = {}
this.started = false

this.init = function()    
    log.info('Monsters module initialized')
end

this.start = function()
    this.started = true
    log.info('Monsters module started')
end

this.results = function()
    return monsters
end

this.stop = function()
    this.started = false
    log.info('Monsters module stopped')
end

return this