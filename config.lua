Config = {}

Config.Debug = true

Config.Language = "en" -- Language to use.

Config.RenderDistance = 100.0 -- Scenario display Radius.

Config.InteractDistance = 2.0 -- Interact Radius

Config.UseTarget = true -- When set to true, it'll use targeting instead of key-presses to interact.

Config.NoModelTargeting = true -- When set to true and using Target, it'll spawn a small invisible prop so you can third-eye when no entity is defined.

Config.Marker = { -- This will only be used if enabled, not using target, and no model is defined in the interaction.
    enabled = true,
    id = 2,
    scale = 0.25, 
    color = {255, 255, 255, 127}
}

Config.Effects = {
    ["high"] = {
        canOverlap = false, -- If the effect can be started on-top of others (recommended: false)
        process = function(data)
            local time = data.time or 5000
            local intensity = data.intensity or 1.0
            local player = PlayerId()
            local ped = PlayerPedId()
            RequestAnimSet("MOVE_M@DRUNK@VERYDRUNK") 
            while not HasAnimSetLoaded("MOVE_M@DRUNK@VERYDRUNK") do
                Wait(0)
            end    
            SetPedMovementClipset(ped, "MOVE_M@DRUNK@VERYDRUNK", 1.0)
            SetPedMotionBlur(ped, true)
            SetPedIsDrunk(ped, true)
            SetTimecycleModifier("spectator6")
            for i=1, 100 do 
                SetTimecycleModifierStrength(i * 0.01)
                ShakeGameplayCam("DRUNK_SHAKE", i * 0.01)
                Wait(10)
            end
            Wait(time)
            for i=1, 100 do 
                SetTimecycleModifierStrength(1.0 - (i * 0.01))
                ShakeGameplayCam("DRUNK_SHAKE", (1.0 - (i * 0.01)))
                Wait(10)
            end
            SetPedMoveRateOverride(player, 1.0)
            SetRunSprintMultiplierForPlayer(player, 1.0)
            SetPedIsDrunk(ped, false)
            SetPedMotionBlur(ped, false)
            ResetPedMovementClipset(ped, 1.0)
        end
    },
    ["drunk"] = {
        canOverlap = false, -- If the effect can be started on-top of others (recommended: false)
        process = function(data)
            local time = data.time or 5000
            local intensity = data.intensity or 1.0
            local player = PlayerId()
            local ped = PlayerPedId()
            RequestAnimSet("MOVE_M@DRUNK@VERYDRUNK") 
            while not HasAnimSetLoaded("MOVE_M@DRUNK@VERYDRUNK") do
                Wait(0)
            end    
            SetPedMovementClipset(ped, "MOVE_M@DRUNK@VERYDRUNK", 1.0)
            SetPedMotionBlur(ped, true)
            SetPedIsDrunk(ped, true)
            SetTimecycleModifier("drug_wobbly")
            for i=1, 100 do 
                SetTimecycleModifierStrength(i * 0.01)
                ShakeGameplayCam("DRUNK_SHAKE", i * 0.01)
                Wait(10)
            end
            Wait(time)
            for i=1, 100 do 
                SetTimecycleModifierStrength(1.0 - (i * 0.01))
                ShakeGameplayCam("DRUNK_SHAKE", (1.0 - (i * 0.01)))
                Wait(10)
            end
            SetPedMoveRateOverride(player, 1.0)
            SetRunSprintMultiplierForPlayer(player,1.0)
            SetPedIsDrunk(ped, false)		
            SetPedMotionBlur(ped, false)
            ResetPedMovementClipset(ped, 1.0)
        end
    },
}

Config.ExternalStatus = function(source, name, amount) -- (Server-Sided) Implement custom exports and events for external status resources.
    if amount == 0 then return end
    if amount > 0 then -- Add Status
        if amount > 200 then
            TriggerEvent("evidence:client:SetStatus", "heavyalcohol", amount)
        else
            TriggerEvent("evidence:client:SetStatus", "alcohol", amount)
        end
        if GetResourceState("ps_buffs") == "started" then
            local amount = math.abs(amount)
            exports.ps_buffs:AddBuff(source, GetIdentifier(source), name, amount)
        end
    else -- Remove Status
        if GetResourceState("ps_buffs") == "started" then
            local amount = math.abs(amount)
            exports.ps_buffs:RemoveBuff(source, GetIdentifier(source), name)
        end
    end
end

Config.Options = { -- Item Options
    drop = {
        despawnTime = 120, -- Seconds until it deletes the entity after dropping it.
    },
    throwing = { 
        despawnTime = 5, -- Seconds until it deletes the entity after throwing it.
        power = 20, -- The amount of power to use when throwing the entity.
    }
}

Config.MaxValues = { -- If you want a custom maximum for a value, change -1 to the number. This is already handled in the bridge.
    hunger  = -1,
    thirst  = -1,
    stress  = -1,
    armor   = -1,
    stamina = -1,
}

Config.Items = {
    ['water'] = {
        uses=3,
        prop={model=`prop_ld_flow_bottle`,boneId=28422,offset=vec3(0.0,0.0,0.0),rotation=vec3(0.0,0.0,0.0)},
        animation={dict='mp_player_intdrink',anim='loop_bottle',time=2000,params={1.0,-1.0,-1,49}},
        status={thirst=20},
    },
    ["cigarette"] = {
        uses = 3,
        prop = { model = `prop_cigar_03`, boneId = 28422, offset = vec3(-0.05, 0.0, 0.0), rotation = vec3(0.0, 0.0, 0.0) },
        idle = { dict = "amb@world_human_aa_smoke@male@base", anim = "base", time = 2000, params = { nil, nil, nil, 49 } },
        animation = { dict = "amb@world_human_aa_smoke@male@idle_a", anim = "idle_b", time = 2000, params = { nil, nil, nil, 49 } },
        effect = { name = "high", time = 5000, intensity = 1.0 },
        status = { -- Per use. Values are based on percentage of the max value of the status. If below zero, it will remove the status percentage.
            hunger  = 0,
            thirst  = 20,
            stress  = 0,
            armor   = 0,
            alcohol = 0,
            stamina = 0,
        }
    },
    ["cigbox"] = {
        uses = 3,
        prop = { model = `v_res_tt_cigs01`, boneId = 28422, offset = vec3(0.0476, 0.02817, -0.0104), rotation = vec3(0.0, 0.0, 0.0) },
        animation = { dict = "mp_arresting", anim = "a_uncuff", time = 2000, params = { nil, nil, nil, 49 } },
        rewards = { -- Per use. Types include: "item", "money"
            {type = "item", name = "cigarette", amount = 1},
        },
    },
    ["hamburger"] = {
        uses = 3,
        prop = { model = `prop_cs_burger_01`, boneId = 18905, offset = vec3(0.1114, 0.0389, 0.0497), rotation = vec3(160.2057, 77.8283, -7.5425) },
        animation = { dict = "mp_player_inteat@burger", anim = "mp_player_int_eat_burger_fp", time = 2000, params = { nil, nil, nil, 49 } },
        status = { -- Per use. Values are based on percentage of the max value of the status. If below zero, it will remove the status percentage.
            hunger  = 20,
            thirst  = 0,
            stress  = 0,
            armor   = 0,
            alcohol = 0,
            stamina = 0,
        }
    },
    ["beer"] = {
        uses = 3,
        prop = { model = `prop_cs_beer_bot_01`, boneId = 18905, offset = vec3(0.1, 0.01, 0.01), rotation = vec3(100.0, 0.0, -180.0) },
        animation = { dict = "mp_player_intdrink", anim = "loop_bottle", time = 2000, params = { nil, nil, nil, 49 } },
        effect = { name = "drunk", time = 5000, intensity = 1.0 },
        status = { -- Per use. Values are based on percentage of the max value of the status. If below zero, it will remove the status percentage.
            hunger  = 0,
            thirst  = 20,
            stress  = 0,
            armor   = 0,
            alcohol = 0,
            stamina = 0,
        }
    },
    ["soda"] = {
        uses = 3,
        prop = { model = `prop_ecola_can`, boneId = 18905, offset = vec3(0.1, 0.01, 0.01), rotation = vec3(100.0, 0.0, -180.0) },
        animation = { dict = "mp_player_intdrink", anim = "loop_bottle", time = 2000, params = { nil, nil, nil, 49 } },
        status = { -- Per use. Values are based on percentage of the max value of the status. If below zero, it will remove the status percentage.
            hunger  = 0,
            thirst  = 20,
            stress  = 0,
            armor   = 0,
            alcohol = 0,
            stamina = 0,
        }
    },
    ["coffee"] = {
        uses = 1,
        prop = { model = `p_amb_coffeecup_01`, boneId = 28422, offset = vec3(0.0, 0.0, 0.0), rotation = vec3(0.0, 0.0, 0.0) },
        idle = { dict = "amb@world_human_drinking@coffee@male@idle_a", anim = "idle_c", time = 2000, params = { nil, nil, nil, 49 } },
        animation = { dict = "amb@world_human_drinking@coffee@male@idle_a", anim = "idle_c", time = 2000, params = { nil, nil, nil, 49 } },
        effect = { name = "caffeine_boost", time = 360000, intensity = 1.0 },
        status = {
            hunger  = 0,
            thirst  = 10,
            stress  = 0,
            armor   = 0,
            alcohol = 0,
            stamina = 0,
        }
    },
    ["egobar"] = {
        uses = 1,
        prop = { model = `prop_choc_ego`, boneId = 60309, offset = vec3(0.0, 0.0, 0.0), rotation = vec3(0.0, 0.0, 0.0) },
        idle = { dict = "mp_player_inteat@burger", anim = "mp_player_int_eat_burger", time = 2000, params = { nil, nil, nil, 49 } },
        animation = { dict = "mp_player_inteat@burger", anim = "mp_player_int_eat_burger", time = 2000, params = { nil, nil, nil, 49 } },
        effect = { name = "satisfaction", time = 5000, intensity = 1.0 },
        status = {
            hunger  = 20,
            thirst  = 0,
            stress  = 0,
            armor   = 0,
            alcohol = 0,
            stamina = 0,
        }
    },
    ["sandwich"] = {
        uses = 1,
        prop = { model = `prop_sandwich_01`, boneId = 18905, offset = vec3(0.13, 0.05, 0.02), rotation = vec3(-50.0, 16.0, 60.0) },
        idle = { dict = "mp_player_inteat@burger", anim = "mp_player_int_eat_burger", time = 2000, params = { nil, nil, nil, 49 } },
        animation = { dict = "mp_player_inteat@burger", anim = "mp_player_int_eat_burger", time = 2000, params = { nil, nil, nil, 49 } },
        effect = { name = "satisfaction", time = 5000, intensity = 1.0 },
        status = {
            hunger  = 20,
            thirst  = 0,
            stress  = 0,
            armor   = 0,
            alcohol = 0,
            stamina = 0,
        }
    },
    ["crisps"] = {
        uses = 1,
        prop = { model = `v_ret_ml_chips2`, boneId = 28422, offset = vec3(0.01, -0.05, -0.1), rotation = vec3(0.0, 0.0, 90.0) },
        idle = { dict = "amb@world_human_drinking@coffee@male@idle_a", anim = "idle_c", time = 2000, params = { nil, nil, nil, 49 } },
        animation = { dict = "amb@world_human_drinking@coffee@male@idle_a", anim = "idle_c", time = 2000, params = { nil, nil, nil, 49 } },
        effect = { name = "satisfaction", time = 5000, intensity = 1.0 },
        status = {
            hunger  = 10,
            thirst  = 0,
            stress  = 0,
            armor   = 0,
            alcohol = 0,
            stamina = 0,
        }
    },
    ["gin_shot"] = {
        uses = 5,
        prop = { model = `p_cs_shot_glass_s`, boneId = 28422, offset = vec3(-0.0, 0.0, 0.0), rotation = vec3(0.0, 0.0, 0.0) },
        idle = { dict = "amb@world_human_drinking@beer@male@base", anim = "base", time = 2000, params = { nil, nil, nil, 49 } },
        animation = { dict = "amb@world_human_drinking@beer@male@idle_a", anim = "idle_b", time = 2000, params = { nil, nil, nil, 49 } },
        effect = { name = "drunk", time = 5000, intensity = 1.0 },
        status = {
            hunger  = 0,
            thirst  = 20,  -- Adjusted for a gin_shot
            stress  = 0,
            armor   = 0,
            alcohol = 20,  -- Adjusted for a gin_shot
            stamina = 0,
        },
    },
    ["vodka_shot"] = {
        uses = 5,
        prop = { model = `p_cs_shot_glass_s`, boneId = 28422, offset = vec3(-0.0, 0.0, 0.0), rotation = vec3(0.0, 0.0, 0.0) },
        idle = { dict = "amb@world_human_drinking@beer@male@base", anim = "base", time = 2000, params = { nil, nil, nil, 49 } },
        animation = { dict = "amb@world_human_drinking@beer@male@idle_a", anim = "idle_b", time = 2000, params = { nil, nil, nil, 49 } },
        effect = { name = "drunk", time = 5000, intensity = 1.0 },
        status = {
            hunger  = 0,
            thirst  = 20,  -- Adjusted for a vodka_shot
            stress  = 0,
            armor   = 0,
            alcohol = 20,  -- Adjusted for a vodka_shot
            stamina = 0,
        },
    },
    ["whiskey_bottle"] = {
        uses = 5,
        prop = { model = `prop_vodka_bottle`, boneId = 28422, offset = vec3(-0.0, 0.0, -0.2), rotation = vec3(0.0, 0.0, 0.0) },
        idle = { dict = "amb@world_human_drinking@beer@male@base", anim = "base", time = 2000, params = { nil, nil, nil, 49 } },
        animation = { dict = "amb@world_human_drinking@beer@male@idle_a", anim = "idle_b", time = 2000, params = { nil, nil, nil, 49 } },
        effect = { name = "drunk", time = 5000, intensity = 1.0 },
        status = {
            hunger  = 0,
            thirst  = 20,
            stress  = 0,
            armor   = 0,
            alcohol = 20,  -- Adjusted for whiskey_bottle
            stamina = 0,
        },
    },
    ["tequila_bottle"] = {
        uses = 5,
        prop = { model = `prop_vodka_bottle`, boneId = 28422, offset = vec3(-0.0, 0.0, -0.2), rotation = vec3(0.0, 0.0, 0.0) },
        idle = { dict = "amb@world_human_drinking@beer@male@base", anim = "base", time = 2000, params = { nil, nil, nil, 49 } },
        animation = { dict = "amb@world_human_drinking@beer@male@idle_a", anim = "idle_b", time = 2000, params = { nil, nil, nil, 49 } },
        effect = { name = "drunk", time = 5000, intensity = 1.0 },
        status = {
            hunger  = 0,
            thirst  = 20,
            stress  = 0,
            armor   = 0,
            alcohol = 20,  -- Adjusted for tequila_bottle
            stamina = 0,
        },
    },
    ["vodka_bottle"] = {
        uses = 5,
        prop = { model = `prop_vodka_bottle`, boneId = 28422, offset = vec3(-0.0, 0.0, -0.2), rotation = vec3(0.0, 0.0, 0.0) },
        idle = { dict = "amb@world_human_drinking@beer@male@base", anim = "base", time = 2000, params = { nil, nil, nil, 49 } },
        animation = { dict = "amb@world_human_drinking@beer@male@idle_a", anim = "idle_b", time = 2000, params = { nil, nil, nil, 49 } },
        effect = { name = "drunk", time = 5000, intensity = 1.0 },
        status = {
            hunger  = 0,
            thirst  = 20,
            stress  = 0,
            armor   = 0,
            alcohol = 20,  -- Adjusted for vodka_bottle
            stamina = 0,
        },
    },
}
