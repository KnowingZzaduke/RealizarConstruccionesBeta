local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local HttpService = game:GetService("HttpService")
local CoreGui = game:GetService("CoreGui")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Debris = game:GetService("Debris")

local LocalPlayer = Players.LocalPlayer
local Mouse = LocalPlayer:GetMouse()

-- ==========================================
-- 🔗 CONEXIÓN
-- ==========================================
local Connections = ReplicatedStorage:WaitForChild("Connections")
local Remotes = Connections:WaitForChild("Remotes")
local PlotSystem = Remotes:WaitForChild("PlotSystem")

-- ==========================================
-- ⚙️ CONFIGURACIÓN
-- ==========================================
local CARPETA_PRINCIPAL = "MisConstruccionesRoblox" 
local RADIO_HORIZONTAL = 40 
local BLOQUE_GENERICO = "part_cube" 

-- INTENTAREMOS DETECTAR LA CARPETA AUTOMÁTICAMENTE
-- Basado en tus fotos, suele ser Workspace.Terrenos.Folder.FurnitureContainer o similar
local CARPETA_RAIZ = workspace:WaitForChild("Terrenos")

if not isfolder(CARPETA_PRINCIPAL) then makefolder(CARPETA_PRINCIPAL) end

local datosGuardados = {} 
local fantasmasCreados = {} 
local bloqueSeleccionado = nil 
local menuAbierto = true
local procesoActivo = false
local carpetaMueblesDetectada = nil -- Aquí guardaremos la carpeta correcta

-- Herramienta
local tool = Instance.new("Tool")
tool.RequiresHandle = false
tool.Name = "📐 Gestor v10 (Interceptor)"
tool.Parent = LocalPlayer.Backpack

-- Selección Visual
local highlightBox = Instance.new("SelectionBox")
highlightBox.Color3 = Color3.fromRGB(0, 255, 0) -- Verde esperanza
highlightBox.LineThickness = 0.05
highlightBox.Parent = workspace
highlightBox.Adornee = nil

-- ==========================================
-- 🖥️ GUI (VISUAL)
-- ==========================================
if CoreGui:FindFirstChild("ClonadorProGUI") then CoreGui.ClonadorProGUI:Destroy() end
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "ClonadorProGUI"
if syn and syn.protect_gui then syn.protect_gui(screenGui) elseif gethui then screenGui.Parent = gethui() else screenGui.Parent = CoreGui end

local mainFrame = Instance.new("Frame")
mainFrame.Size = UDim2.new(0, 230, 0, 350)
mainFrame.Position = UDim2.new(0.15, 0, 0.25, 0) 
mainFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
mainFrame.Parent = screenGui
Instance.new("UICorner", mainFrame)

local title = Instance.new("TextLabel")
title.Text = "⚡ INTERCEPTOR v10"
title.Size = UDim2.new(1, 0, 0, 30)
title.BackgroundTransparency = 1
title.TextColor3 = Color3.fromRGB(0, 255, 100)
title.Font = Enum.Font.GothamBold
title.Parent = mainFrame

local statusLabel = Instance.new("TextLabel")
statusLabel.Text = "Esperando..."
statusLabel.Size = UDim2.new(1, 0, 0, 20)
statusLabel.Position = UDim2.new(0, 0, 0.9, 0)
statusLabel.BackgroundTransparency = 1
statusLabel.TextColor3 = Color3.new(1,1,1)
statusLabel.Parent = mainFrame

-- Funciones GUI Helper
function notificar(texto)
    statusLabel.Text = texto
    game:GetService("StarterGui"):SetCore("SendNotification", {Title="Constructor v10", Text=texto, Duration=2})
end

-- ==========================================
-- 🧠 LÓGICA INTELIGENTE (EL CEREBRO)
-- ==========================================

-- Función para encontrar dónde demonios se guardan los muebles
function buscarCarpetaDeMuebles()
    -- Buscamos recursivamente cualquier cosa que parezca un contenedor de muebles
    for _, obj in pairs(CARPETA_RAIZ:GetDescendants()) do
        if obj.Name == "FurnitureContainer" or obj.Name == "Muebles" or obj.Name == "Items" then
            carpetaMueblesDetectada = obj
            return obj
        end
    end
    return CARPETA_RAIZ -- Si falla, usamos la raíz
end

function redondearCFrame(cf)
    local x, y, z = cf.X, cf.Y, cf.Z
    local rX, rY, rZ = math.round(x*100)/100, math.round(y*100)/100, math.round(z*100)/100
    return CFrame.new(rX, rY, rZ) * (cf - cf.Position)
end

function obtenerIDDeBloque(bloque)
    -- Intenta sacar el ID de todas las formas posibles
    if bloque:GetAttribute("ID") then return bloque:GetAttribute("ID") end
    if bloque:GetAttribute("UUID") then return bloque:GetAttribute("UUID") end
    if bloque:GetAttribute("ItemId") then return bloque:GetAttribute("ItemId") end
    -- Si no tiene atributos, a veces el propio objeto sirve como ID en ciertos scripts
    return bloque 
end

-- ==========================================
-- 🚀 LA FUNCIÓN MAESTRA: PONER Y ESCALAR
-- ==========================================
function construirReal()
    if not bloqueSeleccionado then return notificar("⚠️ Selecciona el suelo base") end
    if #datosGuardados == 0 then return notificar("⚠️ Carga o Copia datos") end
    if procesoActivo then return end

    -- Aseguramos tener la carpeta donde caen los items
    local container = carpetaMueblesDetectada or buscarCarpetaDeMuebles()
    print("📂 Carpeta detectada para escuchar: " .. container:GetFullName())

    local character = LocalPlayer.Character
    local hrp = character and character:FindFirstChild("HumanoidRootPart")
    if not hrp then return end

    procesoActivo = true
    notificar("⚡ Iniciando Construcción Rápida...")
    
    local rotacionDeseada = CFrame.Angles(0, 0, 0) -- Ajustar si necesitas rotación del jugador
    local nuevoCentroCFrame = CFrame.new(bloqueSeleccionado.Position + Vector3.new(0,1,0)) * rotacionDeseada
    
    local posOriginal = hrp.CFrame 
    hrp.Anchored = true 

    for i, data in pairs(datosGuardados) do
        if not procesoActivo then break end 

        -- 1. Preparar datos
        local relCF = CFrame.new(unpack(data.CF))
        local cframeFinal = nuevoCentroCFrame * relCF
        cframeFinal = redondearCFrame(cframeFinal)
        local sizeObjetivo = Vector3.new(unpack(data.Size))
        
        -- 2. Teleport (necesario en este juego)
        hrp.CFrame = cframeFinal * CFrame.new(0, 5, 0)
        RunService.Heartbeat:Wait()

        -- 3. ⚠️ LA TRAMPA: Escuchar antes de disparar
        local bloqueCapturado = nil
        local listener
        
        -- Activamos el radar en la carpeta del contenedor
        listener = container.ChildAdded:Connect(function(child)
            -- Verificamos si es un bloque nuevo (esperamos que sea el nuestro)
            -- A veces el juego crea un "Model" y luego mete el "Part" dentro.
            bloqueCapturado = child
        end)

        -- 4. DISPARAR: Poner el mueble
        PlotSystem:InvokeServer("placeFurniture", BLOQUE_GENERICO, cframeFinal)
        
        -- 5. ESPERAR LA CAPTURA (Máximo 1 segundo)
        local tiempoInicio = tick()
        while not bloqueCapturado and (tick() - tiempoInicio) < 1 do
            RunService.Heartbeat:Wait()
        end
        
        -- Desactivamos el radar para no consumir memoria
        if listener then listener:Disconnect() end

        -- 6. EJECUTAR EL ESCALADO
        if bloqueCapturado then
            -- Pequeña espera técnica para que se carguen los atributos del bloque nuevo
            RunService.Heartbeat:Wait() 
            
            local idReal = obtenerIDDeBloque(bloqueCapturado)
            print("🎯 Bloque detectado: " .. bloqueCapturado.Name .. " | ID/Obj: " .. tostring(idReal))
            
            -- Enviamos el cambio de tamaño INMEDIATAMENTE
            PlotSystem:InvokeServer("scaleFurniture", idReal, cframeFinal, sizeObjetivo)
        else
            warn("❌ Bloque " .. i .. " no apareció en la carpeta detectada.")
        end
        
        task.wait(0.15) -- Velocidad rápida pero segura
    end
    
    hrp.Anchored = false
    hrp.CFrame = posOriginal
    procesoActivo = false
    notificar("✅ Terminado")
end

-- ==========================================
-- 💾 FUNCIONES BÁSICAS (COPIAR, GUARDAR...)
-- ==========================================
function copiarEstructura()
    if not bloqueSeleccionado then return notificar("⚠️ Selecciona centro") end
    datosGuardados = {}
    local origen = bloqueSeleccionado.CFrame
    local count = 0
    
    -- Esfera visual
    local e = Instance.new("Part"); e.Shape="Ball"; e.Size=Vector3.new(RADIO_HORIZONTAL*2, RADIO_HORIZONTAL*2, RADIO_HORIZONTAL*2)
    e.CFrame=origen; e.Transparency=0.8; e.Color=Color3.fromRGB(255,0,0); e.Anchored=true; e.CanCollide=false; e.Parent=workspace
    Debris:AddItem(e, 1)

    for _, p in pairs(workspace:GetDescendants()) do
        if p:IsA("BasePart") and p.Transparency < 1 and (p.Position - origen.Position).Magnitude < RADIO_HORIZONTAL and p ~= e and p.Name ~= "Baseplate" then
            local rel = origen:Inverse() * p.CFrame
            table.insert(datosGuardados, {
                Name = BLOQUE_GENERICO,
                Size = {p.Size.X, p.Size.Y, p.Size.Z},
                CF = {rel:GetComponents()}
            })
            count = count + 1
        end
    end
    notificar("✅ Copiados: " .. count)
end

function detenerTodo() procesoActivo = false; notificar("🛑 Detenido") end

-- Botones GUI (Simplificado)
local layout = Instance.new("UIListLayout", mainFrame); layout.Padding = UDim.new(0,5); layout.HorizontalAlignment = Enum.HorizontalAlignment.Center

local function btn(txt, col, func)
    local b = Instance.new("TextButton"); b.Text=txt; b.Size=UDim2.new(0.9,0,0,35); b.BackgroundColor3=col; b.Parent=mainFrame; Instance.new("UICorner",b)
    b.MouseButton1Click:Connect(func)
end

-- Título spacer
local sp = Instance.new("Frame", mainFrame); sp.Size=UDim2.new(1,0,0,30); sp.BackgroundTransparency=1

btn("1. COPIAR (K)", Color3.fromRGB(0, 100, 200), copiarEstructura)
btn("2. CONSTRUIR (B)", Color3.fromRGB(200, 100, 0), construirReal)
btn("3. DETENER (X)", Color3.fromRGB(150, 0, 0), detenerTodo)

tool.Equipped:Connect(function(m)
    m.Button1Down:Connect(function() if m.Target then bloqueSeleccionado = m.Target; highlightBox.Adornee=m.Target; notificar("🎯 " .. m.Target.Name) end end)
    m.KeyDown:Connect(function(k) if k=="k" then copiarEstructura() elseif k=="b" then construirReal() elseif k=="x" then detenerTodo() end end)
end)
tool.Unequipped:Connect(function() highlightBox.Adornee=nil end)

notificar("✅ V10 Cargado: Listener Activo")
