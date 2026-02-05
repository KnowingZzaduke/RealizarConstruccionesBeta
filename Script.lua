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
local BLOQUE_GENERICO = "part_cube" -- Nombre del modelo que colocamos

if not isfolder(CARPETA_PRINCIPAL) then makefolder(CARPETA_PRINCIPAL) end

local datosGuardados = {} 
local fantasmasCreados = {} 
local bloqueSeleccionado = nil 
local menuAbierto = true
local procesoActivo = false

-- Herramienta
local tool = Instance.new("Tool")
tool.RequiresHandle = false
tool.Name = "📐 Gestor v15 (Fixed ID)"
tool.Parent = LocalPlayer.Backpack

-- Selección Visual
local highlightBox = Instance.new("SelectionBox")
highlightBox.Color3 = Color3.fromRGB(0, 255, 100)
highlightBox.LineThickness = 0.05
highlightBox.Parent = workspace
highlightBox.Adornee = nil

-- ==========================================
-- 🖥️ GUI (INTOCABLE)
-- ==========================================
if CoreGui:FindFirstChild("ClonadorProGUI") then CoreGui.ClonadorProGUI:Destroy() end

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "ClonadorProGUI"
if syn and syn.protect_gui then syn.protect_gui(screenGui) elseif gethui then screenGui.Parent = gethui() else screenGui.Parent = CoreGui end

local mainFrame = Instance.new("Frame")
mainFrame.Name = "MainFrame"
mainFrame.Size = UDim2.new(0, 230, 0, 420) 
mainFrame.Position = UDim2.new(0.15, 0, 0.25, 0) 
mainFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
mainFrame.Parent = screenGui
Instance.new("UICorner", mainFrame).CornerRadius = UDim.new(0, 10)

local topBar = Instance.new("Frame")
topBar.Size = UDim2.new(1, 0, 0, 35)
topBar.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
topBar.Parent = mainFrame
Instance.new("UICorner", topBar).CornerRadius = UDim.new(0, 10)

local title = Instance.new("TextLabel")
title.Text = "🏗️ FIXED v15"
title.Size = UDim2.new(0.8, 0, 1, 0)
title.Position = UDim2.new(0.05, 0, 0, 0)
title.BackgroundTransparency = 1
title.TextColor3 = Color3.fromRGB(0, 255, 100)
title.Font = Enum.Font.GothamBold
title.TextSize = 14
title.TextXAlignment = Enum.TextXAlignment.Left
title.Parent = topBar

local nameInput = Instance.new("TextBox")
nameInput.PlaceholderText = "Nombre archivo..."
nameInput.Size = UDim2.new(0.65, 0, 0, 30)
nameInput.Position = UDim2.new(0.05, 0, 0.12, 0)
nameInput.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
nameInput.TextColor3 = Color3.new(1,1,1)
nameInput.Parent = mainFrame
Instance.new("UICorner", nameInput)

local btnSave = Instance.new("TextButton")
btnSave.Text = "💾"
btnSave.Size = UDim2.new(0.2, 0, 0, 30)
btnSave.Position = UDim2.new(0.75, 0, 0.12, 0)
btnSave.BackgroundColor3 = Color3.fromRGB(0, 120, 200)
btnSave.TextColor3 = Color3.new(1,1,1)
btnSave.Parent = mainFrame
Instance.new("UICorner", btnSave)

local scrollList = Instance.new("ScrollingFrame")
scrollList.Size = UDim2.new(0.9, 0, 0.25, 0) 
scrollList.Position = UDim2.new(0.05, 0, 0.22, 0)
scrollList.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
scrollList.BorderSizePixel = 0
scrollList.Parent = mainFrame
local layoutFiles = Instance.new("UIListLayout")
layoutFiles.Padding = UDim.new(0, 4)
layoutFiles.Parent = scrollList

local actionsFrame = Instance.new("Frame")
actionsFrame.Name = "ActionsFrame"
actionsFrame.Size = UDim2.new(0.9, 0, 0.48, 0) 
actionsFrame.Position = UDim2.new(0.05, 0, 0.50, 0) 
actionsFrame.BackgroundTransparency = 1
actionsFrame.Parent = mainFrame
local layoutActions = Instance.new("UIListLayout")
layoutActions.Padding = UDim.new(0, 6)
layoutActions.Parent = actionsFrame

-- UI Helpers
local function hacerArrastrable(frameDrag, frameMover)
    local dragging, dragInput, dragStart, startPos
    frameDrag.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true; dragStart = input.Position; startPos = frameMover.Position
        end
    end)
    frameDrag.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement then dragInput = input end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if input == dragInput and dragging then
            local delta = input.Position - dragStart
            frameMover.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        end
    end)
    UserInputService.InputEnded:Connect(function(input) if input.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end end)
end
hacerArrastrable(topBar, mainFrame)

function notificar(texto)
    game:GetService("StarterGui"):SetCore("SendNotification", {Title="Script v15", Text=texto, Duration=2})
end

-- ==========================================
-- 🕵️‍♂️ LÓGICA DE BÚSQUEDA CORREGIDA (SOLUCIÓN)
-- ==========================================

function encontrarBloqueYSuID(posicionCFrame)
    -- 1. Buscamos cualquier parte física en el punto de construcción
    local partesCercanas = workspace:GetPartBoundsInRadius(posicionCFrame.Position, 0.5)
    
    for _, parte in pairs(partesCercanas) do
        if parte:IsA("BasePart") and parte.Name ~= "Baseplate" and not parte.Parent:FindFirstChild("Humanoid") then
            
            -- Según tu imagen, el ID está en el PADRE (el Modelo)
            local modeloPadre = parte.Parent
            
            if modeloPadre then
                -- Buscamos EXACTAMENTE el atributo "Id" (Case Sensitive)
                local id = modeloPadre:GetAttribute("Id")
                
                if id then
                    return parte, id -- ¡ÉXITO!
                end
            end
        end
    end
    return nil, nil
end

function redondearCFrame(cf)
    local x, y, z = cf.X, cf.Y, cf.Z
    local rX, rY, rZ = math.round(x*100)/100, math.round(y*100)/100, math.round(z*100)/100
    return CFrame.new(rX, rY, rZ) * (cf - cf.Position)
end

function construirReal()
    if not bloqueSeleccionado then return notificar("⚠️ Selecciona el suelo base") end
    if #datosGuardados == 0 then return notificar("⚠️ Carga datos primero") end
    if procesoActivo then return end

    local character = LocalPlayer.Character
    local hrp = character and character:FindFirstChild("HumanoidRootPart")
    if not hrp then return end

    procesoActivo = true
    notificar("🔨 Construyendo v15...")
    
    local rotacionDeseada = CFrame.Angles(0, 0, 0) 
    local nuevoCentroCFrame = CFrame.new(bloqueSeleccionado.Position + Vector3.new(0,1,0)) * rotacionDeseada
    
    local posOriginal = hrp.CFrame 
    hrp.Anchored = true 

    for i, data in pairs(datosGuardados) do
        if not procesoActivo then break end 

        -- 1. Calcular Datos
        local relCF = CFrame.new(unpack(data.CF))
        local cframeFinal = nuevoCentroCFrame * relCF
        cframeFinal = redondearCFrame(cframeFinal)
        local sizeObjetivo = Vector3.new(unpack(data.Size))
        
        -- 2. Teleport
        hrp.CFrame = cframeFinal * CFrame.new(0, 5, 0)
        RunService.Heartbeat:Wait()

        -- 3. PONER BLOQUE (Ignoramos retorno)
        PlotSystem:InvokeServer("placeFurniture", BLOQUE_GENERICO, cframeFinal)
        
        -- 4. 🕵️‍♂️ CAZAR EL ID (LOOP DE ESPERA)
        local bloqueFisico = nil
        local idEncontrado = nil
        local intentos = 0
        
        -- Intentamos durante 1.5 segundos encontrar el bloque Y que tenga el ID cargado
        while not idEncontrado and intentos < 15 do
            task.wait(0.1) 
            bloqueFisico, idEncontrado = encontrarBloqueYSuID(cframeFinal)
            intentos = intentos + 1
        end
        
        -- 5. ESCALAR
        if idEncontrado then
            print("✅ Bloque " .. i .. " | ID: " .. idEncontrado .. " | Scaling...")
            
            -- Feedback Visual (Caja Verde)
            if bloqueFisico then
                local box = Instance.new("SelectionBox", bloqueFisico)
                box.Color3 = Color3.new(0,1,0); box.Adornee = bloqueFisico; Debris:AddItem(box, 0.5)
            end

            -- ENVIAR ORDEN DE ESCALA
            PlotSystem:InvokeServer("scaleFurniture", idEncontrado, cframeFinal, sizeObjetivo)
            
        else
            warn("❌ Bloque " .. i .. ": No se encontró el atributo 'Id' en el modelo padre.")
            -- Feedback Visual (Caja Roja)
            if bloqueFisico then
                 local box = Instance.new("SelectionBox", bloqueFisico)
                 box.Color3 = Color3.new(1,0,0); box.Adornee = bloqueFisico; Debris:AddItem(box, 1)
            end
        end
        
        task.wait(0.1)
    end
    
    hrp.Anchored = false
    hrp.CFrame = posOriginal
    procesoActivo = false
    notificar("✅ Terminado")
end

-- ==========================================
-- 💾 SISTEMA DE ARCHIVOS (IGUAL)
-- ==========================================
function actualizarListaArchivos()
    for _, child in pairs(scrollList:GetChildren()) do if child:IsA("Frame") then child:Destroy() end end
    local success, archivos = pcall(function() return listfiles(CARPETA_PRINCIPAL) end)
    if not success then return end
    for _, rutaCompleta in pairs(archivos) do
        local nombreArchivo = rutaCompleta:match("([^/]+)$")
        if nombreArchivo:sub(-5) == ".json" then
            local itemFrame = Instance.new("Frame")
            itemFrame.Size = UDim2.new(1, 0, 0, 25); itemFrame.BackgroundTransparency = 1; itemFrame.Parent = scrollList
            
            local btnLoad = Instance.new("TextButton")
            btnLoad.Text = nombreArchivo:sub(1, -6); btnLoad.Size = UDim2.new(0.75, 0, 1, 0); btnLoad.BackgroundColor3 = Color3.fromRGB(60, 60, 60); btnLoad.TextColor3 = Color3.new(1,1,1); btnLoad.Parent = itemFrame
            btnLoad.MouseButton1Click:Connect(function()
                local contenido = readfile(rutaCompleta)
                datosGuardados = HttpService:JSONDecode(contenido)
                notificar("📂 Cargado: " .. #datosGuardados)
            end)
            
            local btnDel = Instance.new("TextButton")
            btnDel.Text = "X"; btnDel.Size = UDim2.new(0.2, 0, 1, 0); btnDel.Position = UDim2.new(0.8, 0, 0, 0); btnDel.BackgroundColor3 = Color3.fromRGB(150, 0, 0); btnDel.TextColor3 = Color3.new(1,1,1); btnDel.Parent = itemFrame
            btnDel.MouseButton1Click:Connect(function() delfile(rutaCompleta) actualizarListaArchivos() end)
        end
    end
    scrollList.CanvasSize = UDim2.new(0, 0, 0, layoutFiles.AbsoluteContentSize.Y)
end

btnSave.MouseButton1Click:Connect(function()
    if #datosGuardados == 0 then return notificar("⚠️ Vacío") end
    local nombre = nameInput.Text
    if nombre == "" then return notificar("⚠️ Falta nombre") end
    writefile(CARPETA_PRINCIPAL .. "/" .. nombre .. ".json", HttpService:JSONEncode(datosGuardados))
    notificar("💾 Guardado"); nameInput.Text = ""; actualizarListaArchivos()
end)

function esBloqueValido(part)
    return part:IsA("BasePart") and part.Name ~= "Baseplate" and part.Transparency < 1 and not part.Name:find("Ghost_") and part.Parent.Name ~= "Terrenos"
end

function copiarEstructura()
    if not bloqueSeleccionado then return notificar("⚠️ Selecciona centro") end
    datosGuardados = {}
    local origen = bloqueSeleccionado.CFrame
    local count = 0
    
    local e = Instance.new("Part"); e.Shape="Ball"; e.Size=Vector3.new(RADIO_HORIZONTAL*2, RADIO_HORIZONTAL*2, RADIO_HORIZONTAL*2); e.CFrame=origen; e.Transparency=0.8; e.Color=Color3.fromRGB(255,0,0); e.Anchored=true; e.CanCollide=false; e.Parent=workspace; Debris:AddItem(e, 1)

    for _, p in pairs(workspace:GetDescendants()) do
        if esBloqueValido(p) and (p.Position - origen.Position).Magnitude < RADIO_HORIZONTAL and p ~= e then
            local rel = origen:Inverse() * p.CFrame
            table.insert(datosGuardados, {
                Name = BLOQUE_GENERICO, Size = {p.Size.X, p.Size.Y, p.Size.Z}, CF = {rel:GetComponents()}
            })
            count = count + 1
        end
    end
    notificar("✅ Copiados: " .. count)
end

function detenerTodo() procesoActivo = false; notificar("🛑 Detenido") end

-- Botones
local function btn(txt, col, ord, func)
    local b = Instance.new("TextButton"); b.Text=txt; b.Size=UDim2.new(1,0,0,32); b.BackgroundColor3=col; b.TextColor3=Color3.new(1,1,1); b.Font=Enum.Font.GothamBold; b.LayoutOrder=ord; b.Parent=actionsFrame; Instance.new("UICorner", b); b.MouseButton1Click:Connect(func)
end

btn("🎯 1. COPIAR (K)", Color3.fromRGB(0, 150, 100), 1, copiarEstructura)
btn("🔨 2. CONSTRUIR (B)", Color3.fromRGB(200, 120, 0), 3, construirReal)
btn("🛑 PARAR (X)", Color3.fromRGB(150, 0, 0), 4, detenerTodo)

tool.Equipped:Connect(function(m)
    actualizarListaArchivos()
    m.Button1Down:Connect(function() if m.Target then bloqueSeleccionado=m.Target; highlightBox.Adornee=m.Target; notificar("🎯 " .. m.Target.Name) end end)
    m.KeyDown:Connect(function(k) if k=="k" then copiarEstructura() elseif k=="b" then construirReal() elseif k=="x" then detenerTodo() end end)
end)
tool.Unequipped:Connect(function() highlightBox.Adornee=nil end)
actualizarListaArchivos()
notificar("✅ v15 Listo (Parent.Id)")
