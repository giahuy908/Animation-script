-- FULL AIM + ESP + MISC SCRIPT (Rayfield UI)
-- Paste vào executor Roblox Mobile / PC

--// Rayfield UI
local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

--// Services
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Camera = workspace.CurrentCamera
local LP = Players.LocalPlayer

--// AIM VARS
local AimEnabled=false
local FOVRadius=150
local Smooth=0.45
local AimPart="Head"
local ShowLine=true
local TeamCheck=false
local TargetMode="Distance"
local WallCheck=false

-- Anti Shake
local AntiShake=true
local LockRadius=12
local HoldTargetTime=0.18
local lastTarget=nil
local lastSwitch=tick()

-- ESP VARS
local ESPEnabled=false
local ESPTeam=false
local ESPLineEnabled=false
local ESPBoxEnabled=false
local RainbowESP=false
local ESPColor=Color3.fromRGB(255,0,0)

-- HITBOX
local Hitbox=false
local HitboxSize=10
local HitboxDistance=30

-- MISC
local Spin=false
local SpinSpeed=10
local Speed99=false

-- UI
local Window=Rayfield:CreateWindow({Name="AIM MOBILE FULL",LoadingTitle="Loading...",LoadingSubtitle="By ChatGPT",ConfigurationSaving={Enabled=false}})
local AimTab=Window:CreateTab("Aim",4483362458)
local EspTab=Window:CreateTab("ESP",4483362458)
local MiscTab=Window:CreateTab("Linh tinh",4483362458)

-- AIM UI
AimTab:CreateToggle({Name="Enable Aim",CurrentValue=false,Callback=function(v)AimEnabled=v end})
AimTab:CreateDropdown({Name="Aim Part",Options={"Head","HumanoidRootPart"},CurrentOption="Head",Callback=function(v)AimPart=v end})
AimTab:CreateSlider({Name="Smooth",Range={1,100},Increment=1,CurrentValue=45,Callback=function(v)Smooth=v/100 end})
AimTab:CreateSlider({Name="FOV Radius",Range={50,400},Increment=5,CurrentValue=150,Callback=function(v)FOVRadius=v end})
AimTab:CreateToggle({Name="Team Check",CurrentValue=false,Callback=function(v)TeamCheck=v end})
AimTab:CreateToggle({Name="Wall Check",CurrentValue=false,Callback=function(v)WallCheck=v end})
AimTab:CreateDropdown({Name="Target Mode",Options={"Distance","Screen"},CurrentOption="Distance",Callback=function(v)TargetMode=v end})
AimTab:CreateToggle({Name="Anti Shake",CurrentValue=true,Callback=function(v)AntiShake=v end})
AimTab:CreateSlider({Name="Lock Radius",Range={5,40},Increment=1,CurrentValue=12,Callback=function(v)LockRadius=v end})
AimTab:CreateSlider({Name="Hold Time",Range={0,1},Increment=0.05,CurrentValue=0.18,Callback=function(v)HoldTargetTime=v end})

-- ESP UI
EspTab:CreateToggle({Name="Enable ESP",CurrentValue=false,Callback=function(v)ESPEnabled=v end})
EspTab:CreateToggle({Name="ESP Team",CurrentValue=false,Callback=function(v)ESPTeam=v end})
EspTab:CreateToggle({Name="ESP Line",CurrentValue=false,Callback=function(v)ESPLineEnabled=v end})
EspTab:CreateToggle({Name="ESP Box",CurrentValue=false,Callback=function(v)ESPBoxEnabled=v end})
EspTab:CreateToggle({Name="Rainbow ESP",CurrentValue=false,Callback=function(v)RainbowESP=v end})
EspTab:CreateDropdown({
 Name="ESP Color",
 Options={"Red","Green","Blue","Yellow","Purple","White","Cyan"},
 CurrentOption="Red",
 Callback=function(v)
  if v=="Red" then ESPColor=Color3.fromRGB(255,0,0)
  elseif v=="Green" then ESPColor=Color3.fromRGB(0,255,0)
  elseif v=="Blue" then ESPColor=Color3.fromRGB(0,120,255)
  elseif v=="Yellow" then ESPColor=Color3.fromRGB(255,255,0)
  elseif v=="Purple" then ESPColor=Color3.fromRGB(180,0,255)
  elseif v=="White" then ESPColor=Color3.fromRGB(255,255,255)
  elseif v=="Cyan" then ESPColor=Color3.fromRGB(0,255,255) end
 end
})

-- HITBOX UI
EspTab:CreateToggle({Name="Hitbox",CurrentValue=false,Callback=function(v)Hitbox=v end})
EspTab:CreateSlider({Name="Hitbox Size",Range={5,40},Increment=1,CurrentValue=10,Callback=function(v)HitboxSize=v end})
EspTab:CreateSlider({Name="Hitbox Distance",Range={10,150},Increment=5,CurrentValue=30,Callback=function(v)HitboxDistance=v end})

-- MISC UI
MiscTab:CreateToggle({Name="Spin",CurrentValue=false,Callback=function(v)Spin=v end})
MiscTab:CreateSlider({Name="Spin Speed",Range={1,50},Increment=1,CurrentValue=10,Callback=function(v)SpinSpeed=v end})
MiscTab:CreateToggle({Name="Speed 99",CurrentValue=false,Callback=function(v)Speed99=v end})

MiscTab:CreateButton({Name="Fix Lag",Callback=function()
 for _,v in ipairs(workspace:GetDescendants()) do
  if v:IsA("ParticleEmitter") or v:IsA("Trail") or v:IsA("Smoke") or v:IsA("Fire") then v.Enabled=false end
 end
end})

MiscTab:CreateButton({Name="Boost FPS",Callback=function()
 settings().Rendering.QualityLevel=Enum.QualityLevel.Level01
 for _,v in ipairs(workspace:GetDescendants()) do
  if v:IsA("BasePart") then v.Material=Enum.Material.Plastic; v.Reflectance=0 end
 end
end})

-- DRAWING
local circle=Drawing.new("Circle")
circle.Thickness=2; circle.NumSides=100; circle.Filled=false
local line=Drawing.new("Line"); line.Thickness=1.5

-- ESP STORAGE
local ESP_LINES={}
local ESP_BOXES={}
local hue=0

local function CanSee(part)
 if not WallCheck then return true end
 local origin=Camera.CFrame.Position
 local dir=(part.Position-origin)
 local params=RaycastParams.new()
 params.FilterDescendantsInstances={LP.Character}
 params.FilterType=Enum.RaycastFilterType.Blacklist
 local res=workspace:Raycast(origin,dir,params)
 if res then return res.Instance:IsDescendantOf(part.Parent) end
 return true
end

local function GetClosest()
 local center=Vector2.new(Camera.ViewportSize.X/2,Camera.ViewportSize.Y/2)
 local best,bestVal=nil,(TargetMode=="Screen" and FOVRadius or math.huge)
 for _,p in ipairs(Players:GetPlayers()) do
  if p~=LP and p.Character and p.Character:FindFirstChild(AimPart) then
   if TeamCheck and p.Team==LP.Team then continue end
   local part=p.Character[AimPart]
   if not CanSee(part) then continue end
   local worldDist=(part.Position-Camera.CFrame.Position).Magnitude
   local pos,vis=Camera:WorldToViewportPoint(part.Position)
   if TargetMode=="Screen" and vis then
    local screenDist=(Vector2.new(pos.X,pos.Y)-center).Magnitude
    if screenDist<bestVal then bestVal=screenDist;best=p end
   elseif TargetMode=="Distance" then
    if worldDist<bestVal then bestVal=worldDist;best=p end
   end
  end
 end
 return best
end

local function StableTarget(t)
 if not AntiShake then lastTarget=t return t end
 if lastTarget and lastTarget.Character and lastTarget.Character:FindFirstChild(AimPart) then
  local part=lastTarget.Character[AimPart]
  local pos,vis=Camera:WorldToViewportPoint(part.Position)
  if vis then
   local center=Vector2.new(Camera.ViewportSize.X/2,Camera.ViewportSize.Y/2)
   local dist=(Vector2.new(pos.X,pos.Y)-center).Magnitude
   if dist<=LockRadius and (tick()-lastSwitch)<=HoldTargetTime then
    return lastTarget
   end
  end
 end
 lastTarget=t;lastSwitch=tick()
 return t
end

-- LOOP
RunService.RenderStepped:Connect(function()
 hue=(hue+0.01)%1
 local center=Vector2.new(Camera.ViewportSize.X/2,Camera.ViewportSize.Y/2)
 circle.Visible=AimEnabled
 circle.Position=center
 circle.Radius=FOVRadius
 circle.Color=RainbowESP and Color3.fromHSV(hue,1,1) or ESPColor

 local raw=AimEnabled and GetClosest()
 local target=StableTarget(raw)
 if target and target.Character and target.Character:FindFirstChild(AimPart) then
  local part=target.Character[AimPart]
  Camera.CFrame=Camera.CFrame:Lerp(CFrame.new(Camera.CFrame.Position,part.Position),Smooth)
  local pos=Camera:WorldToViewportPoint(part.Position)
  if ShowLine then
   line.Visible=true
   line.From=center
   line.To=Vector2.new(pos.X,pos.Y)
   line.Color=RainbowESP and Color3.fromHSV(hue,1,1) or ESPColor
  end
 else line.Visible=false end

 -- ESP
 if ESPEnabled then
  for _,p in ipairs(Players:GetPlayers()) do
   if p~=LP and p.Character and p.Character:FindFirstChild("HumanoidRootPart") then
    if ESPTeam and p.Team==LP.Team then
     if ESP_LINES[p] then ESP_LINES[p]:Remove();ESP_LINES[p]=nil end
     if ESP_BOXES[p] then ESP_BOXES[p]:Remove();ESP_BOXES[p]=nil end
     continue
    end
    local part=p.Character.HumanoidRootPart
    local pos,vis=Camera:WorldToViewportPoint(part.Position)
    if ESPLineEnabled and vis then
     if not ESP_LINES[p] then ESP_LINES[p]=Drawing.new("Line");ESP_LINES[p].Thickness=1.5 end
     ESP_LINES[p].From=Vector2.new(Camera.ViewportSize.X/2,Camera.ViewportSize.Y)
     ESP_LINES[p].To=Vector2.new(pos.X,pos.Y)
     ESP_LINES[p].Color=RainbowESP and Color3.fromHSV(hue,1,1) or ESPColor
     ESP_LINES[p].Visible=true
    end
    if ESPBoxEnabled and vis then
     if not ESP_BOXES[p] then ESP_BOXES[p]=Drawing.new("Square");ESP_BOXES[p].Filled=false;ESP_BOXES[p].Thickness=2 end
     local dist=(Camera.CFrame.Position-part.Position).Magnitude
     local size=math.clamp(2000/dist,30,120)
     ESP_BOXES[p].Size=Vector2.new(size,size)
     ESP_BOXES[p].Position=Vector2.new(pos.X-size/2,pos.Y-size/2)
     ESP_BOXES[p].Color=RainbowESP and Color3.fromHSV(hue,1,1) or ESPColor
     ESP_BOXES[p].Visible=true
    end
    -- HITBOX
    if Hitbox and (Camera.CFrame.Position-part.Position).Magnitude<=HitboxDistance then
     part.Size=Vector3.new(HitboxSize,HitboxSize,HitboxSize)
     part.Transparency=0.5
     part.Material=Enum.Material.Neon
    end
   end
  end
 end

 -- SPIN
 if Spin and LP.Character and LP.Character:FindFirstChild("HumanoidRootPart") then
  LP.Character.HumanoidRootPart.CFrame*=CFrame.Angles(0,math.rad(SpinSpeed),0)
 end
 -- SPEED
 if LP.Character and LP.Character:FindFirstChildOfClass("Humanoid") then
  LP.Character:FindFirstChildOfClass("Humanoid").WalkSpeed=Speed99 and 99 or 16
 end
end)
