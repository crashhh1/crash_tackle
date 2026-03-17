ESX = exports['es_extended']:getSharedObject()

local function canTackleJob(jobName)
    if not jobName then return false end
    for i = 1, #Config.AllowedJobs do
        if Config.AllowedJobs[i] == jobName then return true end
    end
    return false
end

RegisterNetEvent('crash_tackle:server:ragdollTarget', function(targetServerId)
    local src = source
    if not targetServerId or type(targetServerId) ~= 'number' then return end
    local xPlayer = ESX.GetPlayerFromId(src)
    if not xPlayer or not canTackleJob(xPlayer.getJob().name) then return end
    TriggerClientEvent('crash_tackle:client:doRagdoll', targetServerId, Config.VictimRagdollTime)
end)
