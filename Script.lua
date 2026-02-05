local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local HttpService = game:GetService("HttpService")
local CoreGui = game:GetService("CoreGui")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local LocalPlayer = Players.LocalPlayer

-- ==========================================
-- 🔗 CONEXIÓN CON EL JUEGO (REMOTES)
-- ==========================================
local PlotSystem = ReplicatedStorage:WaitForChild("Connections"):WaitForChild("Remotes"):WaitForChild("PlotSystem")

-- ==========================================
-- ⚙️ CONFIGURACIÓN
-- ==========================================
local CARPETA_PRINCIPAL = "MisConstruccionesRoblox" 
local RADIO_COPIA = 45
local BLOQUE_USAR = "part_cube" -- El nombre interno del bloque a usar
local VELOCIDAD_CONSTRUCCION = 0.15 -- Segundos por bloque (0.1 es muy rápido, 0.2 es seguro)

if not isfolder(CARPETA_PRINCIPAL) then makefolder(CARPETA_PRINCIPAL) end

local datosGuardados = {} 
local bloqueSeleccionado = nil 
local construyendo = false
local esferaVisual = nil

-- Herramienta
local tool = Instance.new("Tool")
tool.RequiresHandle = false
tool.Name = "🚀 Builder Bot V8"
tool.Parent = LocalPlayer.Backpack

-- Selección Visual
local highlightBox = Instance.new("SelectionBox")
highlightBox.Color3 = Color3.fromRGB(255, 0, 0)
highlightBox.LineThickness = 0.05
highlightBox.Parent = workspace
highlightBox.Adornee = nil

-- ==========================================
-- 🖥️ GUI
-- ==========================================
if CoreGui:FindFirstChild("ClonadorProGUI") then CoreGui.ClonadorProGUI:Destroy() end
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "ClonadorProGUI"
if syn and syn.protect_gui then syn.protect_gui(screenGui) elseif gethui then screenGui.Parent = gethui() else screenGui.Parent = CoreGui end

local mainFrame = Instance.new("Frame")
mainFrame.Size = UDim2.new(0, 220, 0, 150)
mainFrame.Position = UDim2.new(0.02, 0, 0.6, 0)
mainFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
mainFrame.Parent = screenGui
Instance.new("UICorner", mainFrame)

local statusLbl = Instance.new("TextLabel")
statusLbl.Text = "ESTADO: EN ESPERA"
statusLbl.Size = UDim2.new(1,0,0.3,0)
statusLbl.TextColor3 = Color3.fromRGB(255, 255, 0)
statusLbl.BackgroundTransparency = 1
statusLbl.Parent = mainFrame

local infoLbl = Instance.new("TextLabel")
infoLbl.Text = "Usa 'K' para Copiar\nUsa 'V' para Construir (Teleport)"
infoLbl.Size = UDim2.new(1,0,0.7,0)
infoLbl.Position = UDim2.new(0,0,0.3,0)
infoLbl.TextColor3 = Color3.fromRGB(200, 200, 200)
infoLbl.BackgroundTransparency = 1
infoLbl.Parent = mainFrame

-- ==========================================
-- 🧠 FUNCIONES
-- ==========================================

function mostrarRadio(centro)
    if esferaVisual then esferaVisual:Destroy() end
    esferaVisual = Instance.new("Part")
    esferaVisual.Shape = Enum.PartType.Ball
    esferaVisual.Size = Vector3.new(RADIO_COPIA*2, RADIO_COPIA*2, RADIO_COPIA*2)
    esferaVisual.CFrame = centro.CFrame
    esferaVisual.Transparency = 0.8
    esferaVisual.Color = Color3.fromRGB(255, 0, 0)
    esferaVisual.Anchored = true
    esferaVisual.CanCollide = false
    esferaVisual.Parent = workspace
    task.delay(2, function() if esferaVisual then esferaVisual:Destroy() end end)
end

function obtenerRotacionJugador()
    if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
        local hrp = LocalPlayer.Character.HumanoidRootPart
        local x, y, z = hrp.CFrame:ToEulerAnglesYXZ()
        local rotacionSnap = math.round(y / (math.pi/2)) * (math.pi/2)
        return CFrame.Angles(0, rotacionSnap, 0)
    end
    return CFrame.new()
end

-- COPIAR (Guardando tamaños reales)
function copiarEstructura()
    if not bloqueSeleccionado then return end
    mostrarRadio(bloqueSeleccionado)
    
    datosGuardados = {}
    local origenCFrame = bloqueSeleccionado.CFrame
    local count = 0
    
    statusLbl.Text = "Escaneando..."
    
    for _, part in pairs(workspace:GetDescendants()) do
        if part:IsA("BasePart") and part.Transparency < 1 and part ~= esferaVisual and part.Name ~= "Baseplate" and not part.Name:find("Ghost") then
            -- Excluimos el suelo (Terrenos)
            if part.Parent.Name ~= "Terrenos" then
                local dist = (part.Position - origenCFrame.Position).Magnitude
                if dist <= RADIO_COPIA then
                    local cframeRelativo = origenCFrame:Inverse() * part.CFrame
                    
                    table.insert(datosGuardados, {
                        Name = BLOQUE_USAR, -- Forzamos part_cube
                        Size = {part.Size.X, part.Size.Y, part.Size.Z}, -- GUARDAMOS TAMAÑO
                        CF = {cframeRelativo:GetComponents()},
                        Color = {part.Color.R, part.Color.G, part.Color.B}
                    })
                    count = count + 1
                end
            end
        end
    end
    statusLbl.Text = "COPIADO: " .. count .. " BLOQUES"
    wait(2)
    statusLbl.Text = "LISTO PARA PEGAR (V)"
end

-- ==========================================
-- 🏗️ TELEPORT BUILDER LOOP
-- ==========================================
function iniciarConstruccion()
    if #datosGuardados == 0 then return end
    if not bloqueSeleccionado then return end
    if construyendo then return end
    
    construyendo = true
    statusLbl.Text = "CONSTRUYENDO..."
    
    local character = LocalPlayer.Character
    local hrp = character and character:FindFirstChild("HumanoidRootPart")
    if not hrp then return end
    
    -- Guardamos posición original para volver al final
    local posicionOriginal = hrp.CFrame
    
    -- Calculamos el centro nuevo
    local rotacion = obtenerRotacionJugador()
    local nuevoCentro = CFrame.new(bloqueSeleccionado.Position + Vector3.new(0,2,0)) * rotacion
    
    -- Anclamos al personaje para que no se caiga mientras se teletransporta rápido
    hrp.Anchored = true 
    
    for i, data in ipairs(datosGuardados) do
        if not construyendo then break end -- Freno de emergencia
        
        -- 1. Calcular dónde va el bloque
        local relCF = CFrame.new(unpack(data.CF))
        local cframeObjetivo = nuevoCentro * relCF
        cframeObjetivo = CFrame.new(math.round(cframeObjetivo.X*10)/10, math.round(cframeObjetivo.Y*10)/10, math.round(cframeObjetivo.Z*10)/10) * (cframeObjetivo - cframeObjetivo.Position)
        local sizeObjetivo = Vector3.new(unpack(data.Size))
        
        -- 2. TELETRANSPORTAR AL JUGADOR AHI
        -- Nos movemos un poco arriba del bloque para no quedar atrapados dentro
        hrp.CFrame = cframeObjetivo * CFrame.new(0, 4, 0)
        
        statusLbl.Text = "Bloque: " .. i .. " / " .. #datosGuardados
        
        -- Espera técnica (Ping)
        RunService.Heartbeat:Wait() 
        
        -- 3. INVOCAR COLOCACIÓN
        -- Como estamos "ahí", el server debería darnos el ID
        local exito, idMueble = pcall(function()
            return PlotSystem:InvokeServer("placeFurniture", data.Name, cframeObjetivo)
        end)
        
        if exito and idMueble then
            -- 4. INVOCAR ESCALADO INMEDIATO
            -- Ya tenemos el ID, mandamos el tamaño
            pcall(function()
                PlotSystem:InvokeServer("scaleFurniture", idMueble, cframeObjetivo, sizeObjetivo)
            end)
        end
        
        task.wait(VELOCIDAD_CONSTRUCCION)
    end
    
    -- Finalizar
    hrp.Anchored = false
    hrp.CFrame = posicionOriginal
    construyendo = false
    statusLbl.Text = "TERMINADO"
end

-- ==========================================
-- 🎮 CONTROLES
-- ==========================================
tool.Equipped:Connect(function(mouse)
    mouse.Button1Down:Connect(function()
        if mouse.Target then
            bloqueSeleccionado = mouse.Target
            highlightBox.Adornee = bloqueSeleccionado
        end
    end)
    
    mouse.KeyDown:Connect(function(key)
        if key == "k" then copiarEstructura() end
        if key == "v" then iniciarConstruccion() end
        if key == "x" then -- Freno de emergencia
            construyendo = false 
            if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
                LocalPlayer.Character.HumanoidRootPart.Anchored = false
            end
            statusLbl.Text = "CANCELADO"
        end
    end)
end)

tool.Unequipped:Connect(function()
    highlightBox.Adornee = nil
    construyendo = false
end)
