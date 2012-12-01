
// ======= Copyright (c) 2003-2011, Unknown Worlds Entertainment, Inc. All rights reserved. =======    
//
// lua\TrainMixin.lua    
//
// Created by: Mats Olsson (mats.olsson@matsotech.se)
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================    

Script.Load("lua/FunctionContracts.lua")
Script.Load("lua/PathingUtility.lua")
Script.Load("lua/PathingMixin.lua")

TrainMixin = CreateMixin( TrainMixin )
TrainMixin.type = "Train"

local pi2 = math.pi * 2

kDefaultTurnSpeed = math.pi // 180 degrees per second
kDefaultMaxSpeedAngle = math.pi / 18 // 10 degrees
kDefaultNoSpeedAngle = math.pi / 4 // 45 degrees

TrainMixin.expectedMixins =
{
    Pathing = "Needed for calls to MoveToTarget().",
}

TrainMixin.expectedCallbacks =
{
}

TrainMixin.networkVars =  
{
    driving = "boolean",
    waiting = "boolean",
}

function TrainMixin:__initmixin() 
    self.driving = false
    self.waiting = false
end


function TrainMixin:OnUpdate(deltaTime)   
    
    if Server then         
        if self.driving then
            self:UpdatePosition(deltaTime)
            self:SetOldAngles(self:GetAngles())
            if not self.waiting then
                self:MovePlayersInTrigger(deltaTime)
                self:MoveTrigger()
            end
        end  
    end
    
end

function TrainMixin:MovePlayersInTrigger(deltaTime)
    for _, entity in ipairs(self:GetEntitiesInTrigger()) do 
        if self.driving then
            if entity:GetIsOnGround() then
                // change position when the train is driving
                local entOrigin = entity:GetOrigin()
                local trainOrigin = self:GetOrigin()
                local newOrigin = entOrigin
                
                local selfDeltaAngles = self:GetDeltaAngles()              
                local degrees = selfDeltaAngles.yaw
                
                // 2d rotation , I don't think I need 3d here, will get the correct position after rotating the train
                newOrigin.z = trainOrigin.z + (math.cos(degrees) * (entOrigin.z - trainOrigin.z) -  math.sin(degrees) * (entOrigin.x - trainOrigin.x))                
                newOrigin.x = trainOrigin.x + (math.sin(degrees) * (entOrigin.z - trainOrigin.z) +  math.cos(degrees) * (entOrigin.x - trainOrigin.x))                                
               
                // TODO: Also change Angles
                /*test = entity:GetAngles()
                test.yaw = test.yaw + degrees

                entity:SetAngles(test)
                entity:SetViewAngles(test)
                */
                entity:SetOrigin(newOrigin  + self:GetMovementVector())

            end
        end
    end
end

    
function TrainMixin:MoveTrigger()
    if self.scaleTrigger then
        self:SetBox(self.scaleTrigger)
    // scale1 wath the old name for this, dunno why but sometimes its still in there
    elseif self.scale1 then
        self:SetBox(self.scale1)
    else
        self:SetBox(self:GetExtents())
    end
end


function TrainMixin:TrainMoveToTarget(physicsGroupMask, endPoint, movespeed, time)

    PROFILE("TrainMixin:MoveToTarget")
    if not self:CheckTrainTarget(endPoint) then
        return true
    end
   
    // save the cursor in case we need to slow down
    local origCursor = PathCursor():Clone(self.cursor)
    
    // remove double points
    if self.points then
        for i, point in ipairs(self.points) do
            if i < #self.points then
                if point == self.points[i+1] then
                    table.remove(self.points, i)
                end
            end
        end
    end
    
    
    self.cursor:Advance(movespeed, time)    
    local maxSpeed = moveSpeed
    
    maxSpeed = self:SmoothTurn(time, self.cursor:GetDirection(), movespeed)
    // Don't move during repositioning
    if HasMixin(self, "Repositioning") and self:GetIsRepositioning() then
    
        maxSpeed = 0
        return false
        
    end
    
    if maxSpeed < movespeed then
        // use the copied cursor and discard the current cursor
        self.cursor = origCursor
        self.cursor:Advance(maxSpeed, time)
    
    end
    
    // update our position to the cursors position, after adjusting for ground or hover
    local newLocation = self.cursor:GetPosition()          
    if self:GetIsFlying() then        
        newLocation = GetHoverAt(self, newLocation, EntityFilterMixinAndSelf(self, "Repositioning"))
    else
        newLocation = GetGroundAt(self, newLocation, PhysicsMask.Movement, EntityFilterMixinAndSelf(self, "Repositioning"))
    end
    newLocation.y = self:GetOrigin().y
    self:SetOrigin(newLocation)
         
    // we are done if we have reached the last point in the path or we have a close-enough condition
    local done = self.cursor:TargetReached()
    return done
    
end


//
// make sure we have a path to the target
// returns false if no path found.
//
function TrainMixin:CheckTrainTarget(endPoint)

    // if we don't have a cursor, or the targetPoint differs, create a new path
    if self.cursor == nil or (self.targetPoint - endPoint):GetLengthXZ() > 0.1 then
    
        // our current cursor is invalid or pointing to another endpoint, so build a new one
        self.points = self:GenerateTrainPath(self:GetOrigin(), endPoint, false, 0.5, 2, self:GetIsFlying())
        if self.points == nil then
        
            // Can't reach the endPoint.
            return false
            
        end
        self.targetPoint = endPoint
        // the list of points does not include our current origin. Simplify the remaining code
        // by adding our origin to the list of points
        table.insert(self.points, 1, self:GetOrigin())        
        self.cursor = PathCursor():Init(self.points)
        
    end
    
    return true
    
end

// also allow flying waypoints
function TrainMixin:GenerateTrainPath(src, dst, doSmooth, smoothDist, maxSplitPoints, allowFlying) 
    
    if not smoothDist then
        smoothDist = 0.5
    end

    if not maxSplitPoints then
        maxSplitPoints = 2
    end
    
    local mask = CreateMaskExcludingGroups(PhysicsGroup.SmallStructuresGroup, PhysicsGroup.PlayerControllersGroup, PhysicsGroup.PlayerGroup)    
    local climbAmount   = ConditionalValue(allowFlying, 0.4, 0.0)   // Distance to "climb" over obstacles each iteration
    local climbOffset   = Vector(0, climbAmount, 0)
    local maxIterations = 10    // Maximum number of attempts to trace to the dst
    
    local points = { }    
    
    // Query the pathing system for the path to the dst
    // if fails then fallback to the old system
    
    local isReachable = Pathing.GetPathPoints(src, dst, points)     
    
    if #points ~= 0 and isReachable then      
        if (doSmooth) then
           SmoothPathPoints( points, smoothDist, maxSplitPoints) 
        end
        return points
    else
    
        // TODO:the engine cant generate points, lets generate our own points
        table.insert(points, dst)
    end
            
    return points

end



// function to get a smooth path between 3 points
// TODO: dont create a point when the next point is on the line
local function Interpolate(point1, point2, point3)

    local smoothWaypoint = {}
    smoothWaypoint.delay = 0
    smoothWaypoint.origin = Vector(0,0,0)
    local pushFactor = 1
    
    local z1 = point1.origin.z
    local z2 = point2.origin.z
    local z3 = point3.origin.z
    
    local x1 = point1.origin.x
    local x2 = point2.origin.x
    local x3 = point3.origin.x
    
    local m = ((x2 -x1) / (z2 - z1))
    
   // push it a bit right or left
    newZ = (m * (x3-x2)) + z1
    local diff = newZ - z3 
    if math.abs(diff) ~= 0.1 then
        // get the position of the new wayPoint (at first, just inside the 2 points)
        smoothWaypoint.origin.y = (point1.origin.y + point2.origin.y) / 2
        smoothWaypoint.origin.z = (point1.origin.z + point2.origin.z) / 2
        smoothWaypoint.origin.x = (point1.origin.x + point2.origin.x) / 2
        if diff > 0 then
            // right
            smoothWaypoint.origin.z = smoothWaypoint.origin.z + pushFactor
        else
            // left
            smoothWaypoint.origin.z = smoothWaypoint.origin.z - pushFactor
        end
        
        return smoothWaypoint
    else
        return nil
    end
    
end

function TrainMixin:CreateSmoothPath(wayPoints, smoothness)
    
    local smoothWaypoints ={}
    if #wayPoints > 0 then
        for i = 1, smoothness+1, 1 do        
            local maxIterations = #wayPoints - 2
            
            for l = 1, maxIterations, 1 do
                newWaypoint = Interpolate(wayPoints[l], wayPoints[l+1], wayPoints[l+2])
                
                table.insert(smoothWaypoints, wayPoints[l])
                if newWaypoint then                    
                    table.insert(smoothWaypoints, newWaypoint)
                end
                
            end
            
            // insert also the last 2 wayPoints
            table.insert(smoothWaypoints, wayPoints[#wayPoints-1]) 
            table.insert(smoothWaypoints, wayPoints[#wayPoints])      


            wayPoints = smoothWaypoints
        end
    end
    
    return smoothWaypoints  

end
	
