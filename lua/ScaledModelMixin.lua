
//________________________________
//
//   	NS2 Combat Mod     
//	Made by JimWest and MCMLXXXIV, 2012
//
//________________________________

Script.Load("lua/FunctionContracts.lua")
Script.Load("lua/PathingUtility.lua")

ScaledModelMixin = CreateMixin( ScaledModelMixin )
ScaledModelMixin.type = "ScaledModel"

ScaledModelMixin.expectedMixins =
{
}

ScaledModelMixin.expectedCallbacks =
{
}


ScaledModelMixin.optionalCallbacks =
{
}


ScaledModelMixin.networkVars =  
{
}

// create a model if theres a model value
function ScaledModelMixin:__initmixin() 
    if self.model ~= nil then    
        Shared.PrecacheModel(self.model)    
        local graphName = string.gsub(self.model, ".model", ".animation_graph")
        if graphName then
            Shared.PrecacheAnimationGraph(graphName)        
        end
        self:SetModel(self.model, graphName)  
    end
end

// only way to scale the model
function ScaledModelMixin:OnAdjustModelCoords(modelCoords)

    local coords = modelCoords
    coords.xAxis = coords.xAxis * self.scale.x
    coords.yAxis = coords.yAxis * self.scale.y
    coords.zAxis = coords.zAxis * self.scale.z
      
    return coords
    
end