local ESX = exports['es_extended']:getSharedObject()
local lastTackleTime = 0
local cachedJobName = nil

local function updateJobCache()
    local pd = ESX.PlayerData
    if pd and pd.job and pd.job.name then
        cachedJobName = pd.job.name
    else
        cachedJobName = nil
    end
end

local function canTackle()
    if not cachedJobName then return false end
    for i = 1, #Config.AllowedJobs do
        if Config.AllowedJobs[i] == cachedJobName then return true end
    end
    return false
end

local function isSprinting()
    return IsControlPressed(0, Config.SprintControl)
end

local function isPlayerPed(ped)
    local active = GetActivePlayers()
    for i = 1, #active do
        if GetPlayerPed(active[i]) == ped then return true end
    end
    return false
end

local function getTargetInFront()
    local myPed = PlayerPedId()
    local myCoords = GetEntityCoords(myPed)
    local myHeading = GetEntityHeading(myPed)
    local rad = math.rad(myHeading)
    local forward = vector3(-math.sin(rad), math.cos(rad), 0.0)
    local range = Config.TackleContactRange
    local coneDot = Config.TackleConeDot

    local closestDist = range + 0.05
    local closestPlayer = nil
    local closestNpc = nil

    local active = GetActivePlayers()
    for i = 1, #active do
        local playerId = active[i]
        if playerId ~= PlayerId() then
            local targetPed = GetPlayerPed(playerId)
            if targetPed and targetPed ~= myPed and DoesEntityExist(targetPed) and not IsEntityDead(targetPed) then
                local targetCoords = GetEntityCoords(targetPed)
                local toTarget = targetCoords - myCoords
                toTarget = vector3(toTarget.x, toTarget.y, 0.0)
                local len = #toTarget
                if len >= 0.1 then
                    local dir = toTarget / len
                    local dot = forward.x * dir.x + forward.y * dir.y
                    if dot >= coneDot and len <= closestDist then
                        closestDist = len
                        closestPlayer = GetPlayerServerId(playerId)
                        closestNpc = nil
                    end
                end
            end
        end
    end

    if closestPlayer then return 'player', closestPlayer end

    closestDist = range + 0.05
    local peds = GetGamePool('CPed')
    for j = 1, #peds do
        local ped = peds[j]
        if ped ~= myPed and DoesEntityExist(ped) and not IsEntityDead(ped) and not IsPedInAnyVehicle(ped, false) and not isPlayerPed(ped) then
            local targetCoords = GetEntityCoords(ped)
            local toTarget = targetCoords - myCoords
            toTarget = vector3(toTarget.x, toTarget.y, 0.0)
            local len = #toTarget
            if len >= 0.1 then
                local dir = toTarget / len
                local dot = forward.x * dir.x + forward.y * dir.y
                if dot >= coneDot and len <= closestDist then
                    closestDist = len
                    closestNpc = ped
                end
            end
        end
    end

    if closestNpc then return 'ped', closestNpc end
    return nil
end

local function doRagdoll(ped, durationMs)
    if not ped or not DoesEntityExist(ped) then return end
    if IsPedInAnyVehicle(ped, false) then return end
    local t = math.max(100, math.min(10000, durationMs))
    SetPedToRagdoll(ped, t, t, 0, false, false, false)
end

RegisterNetEvent('crash_tackle:client:doRagdoll', function(durationMs)
    doRagdoll(PlayerPedId(), durationMs or Config.VictimRagdollTime)
end)

RegisterNetEvent('esx:playerLoaded', function(_, xPlayer)
    if xPlayer and xPlayer.job and xPlayer.job.name then
        cachedJobName = xPlayer.job.name
    else
        updateJobCache()
    end
end)

RegisterNetEvent('esx:setJob', function(job)
    if job and job.name then
        cachedJobName = job.name
    else
        cachedJobName = nil
    end
end)

CreateThread(function()
    while not ESX.PlayerData or not ESX.PlayerData.job do
        Wait(100)
    end
    updateJobCache()
end)

RegisterCommand('crash', function()
    if not isSprinting() or not canTackle() then return end
    local ped = PlayerPedId()
    if IsPedRagdoll(ped) or IsPedInAnyVehicle(ped, false) or IsEntityDead(ped) then return end
    local now = GetGameTimer()
    if now - lastTackleTime < Config.TackleCooldown then return end

    lastTackleTime = now
    local targetType, target = getTargetInFront()

    if targetType == 'player' then
        doRagdoll(ped, Config.TacklerRagdollOnHit)
        TriggerServerEvent('crash_tackle:server:ragdollTarget', target)
    elseif targetType == 'ped' then
        doRagdoll(ped, Config.TacklerRagdollOnHit)
        doRagdoll(target, Config.VictimRagdollTime)
    else
        doRagdoll(ped, Config.TacklerRagdollOnMiss)
    end
end, false)

RegisterKeyMapping('crash', 'Tackle (sprint + E)', 'keyboard', 'e')
