local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local HttpService = game:GetService("HttpService")
local CoreGui = game:GetService("CoreGui")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local LocalPlayer = Players.LocalPlayer
local Mouse = LocalPlayer:GetMouse()

-- ==========================================
-- 🔗 CONEXIÓN EXACTA (Basada en tus logs)
-- ==========================================
local Connections = ReplicatedStorage:WaitForChild("Connections")
local Remotes = Connections:WaitForChild("Remotes")
local PlotSystem = Remotes:WaitForChild("PlotSystem")

-- ==========================================
-- ⚙️ CONFIGURACIÓN
-- ==========================================
local CARPETA_PRINCIPAL = "MisConstruccionesRoblox" 
local RADIO_HORIZONTAL = 45 
local TRANSPARENCIA_MOLDE = 0.5 
local TIEMPO_ENTRE_ACCIONES = 0.2 -- Tiempo prudente para que el server devuelva el ID
local BLOQUE_GENERICO = "part_cube" -- Usaremos siempre este bloque base

if not isfolder(CARPETA_PRINCIPAL) then makefolder(CARPETA_PRINCIPAL) end

local datosGuardados = {} 
local fantasmasCreados = {} 
local bloqueSeleccionado = nil 
local menuAbierto = true
local procesoActivo = false 

-- Herramienta
local tool = Instance.new("Tool")
tool.RequiresHandle = false
tool.Name = "📐 Gestor (Click para abrir)"
tool.Parent = LocalPlayer.Backpack

-- Selección Visual
local highlightBox = Instance.new("SelectionBox")
highlightBox.Color3 = Color3.fromRGB(0, 255, 255)
highlightBox.LineThickness = 0.05
highlightBox.Parent = workspace
highlightBox.Adornee = nil

-- ==========================================
-- 🖥️ GUI (TU DISEÑO EXACTO)
-- ==========================================
if CoreGui:FindFirstChild("ClonadorProGUI") then CoreGui.ClonadorProGUI:Destroy() end

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "ClonadorProGUI"
if syn and syn.protect_gui then syn.protect_gui(screenGui) 
elseif gethui then screenGui.Parent = gethui()
else screenGui.Parent = CoreGui end

local toggleBtn = Instance.new("TextButton")
toggleBtn.Name = "ToggleMenu"
toggleBtn.Size = UDim2.new(0, 45, 0, 45)
toggleBtn.Position = UDim2.new(0.02, 0, 0.4, 0) 
toggleBtn.BackgroundColor3 = Color3.fromRGB(0, 120, 200)
toggleBtn.Text = "📐"
toggleBtn.TextSize = 25
toggleBtn.TextColor3 = Color3.new(1,1,1)
toggleBtn.Parent = screenGui
Instance.new("UICorner", toggleBtn).CornerRadius = UDim.new(0, 10)

local mainFrame = Instance.new("Frame")
mainFrame.Name = "MainFrame"
mainFrame.Size = UDim2.new(0, 230, 0, 380) 
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
title.Text = "🏗️ CONSTRUCTOR PRO"
title.Size = UDim2.new(0.8, 0, 1, 0)
title.Position = UDim2.new(0.05, 0, 0, 0)
title.BackgroundTransparency = 1
title.TextColor3 = Color3.fromRGB(0, 255, 255)
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

-- Funciones GUI
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
    UserInputService.InputEnded:Connect(function(input)
         if input.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end
    end)
end
hacerArrastrable(topBar, mainFrame)

local function toggleGUI()
    menuAbierto = not menuAbierto
    mainFrame.Visible = menuAbierto
end
toggleBtn.MouseButton1Click:Connect(toggleGUI)

function notificar(texto)
    game:GetService("StarterGui"):SetCore("SendNotification", {Title="Constructor", Text=texto, Duration=2})
end

-- ==========================================
-- 🧠 LÓGICA & FUNCIONES
-- ==========================================

function redondearCFrame(cf)
    local x, y, z = cf.X, cf.Y, cf.Z
    local rX, rY, rZ = math.round(x*100)/100, math.round(y*100)/100, math.round(z*100)/100
    return CFrame.new(rX, rY, rZ) * (cf - cf.Position)
end

function actualizarListaArchivos()
    for _, child in pairs(scrollList:GetChildren()) do if child:IsA("Frame") then child:Destroy() end end
    local success, archivos = pcall(function() return listfiles(CARPETA_PRINCIPAL) end)
    if not success then return end
    for _, rutaCompleta in pairs(archivos) do
        local nombreArchivo = rutaCompleta:match("([^/]+)$")
        if nombreArchivo:sub(-5) == ".json" then
            local itemFrame = Instance.new("Frame")
            itemFrame.Size = UDim2.new(1, 0, 0, 25)
            itemFrame.BackgroundTransparency = 1
            itemFrame.Parent = scrollList
            
            local btnLoad = Instance.new("TextButton")
            btnLoad.Text = nombreArchivo:sub(1, -6)
            btnLoad.Size = UDim2.new(0.75, 0, 1, 0)
            btnLoad.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
            btnLoad.TextColor3 = Color3.new(1,1,1)
            btnLoad.Parent = itemFrame
            
            btnLoad.MouseButton1Click:Connect(function()
                local contenido = readfile(rutaCompleta)
                datosGuardados = HttpService:JSONDecode(contenido)
                notificar("📂 Cargado: " .. #datosGuardados .. " objetos")
            end)
            
            local btnDel = Instance.new("TextButton")
            btnDel.Text = "X"
            btnDel.Size = UDim2.new(0.2, 0, 1, 0)
            btnDel.Position = UDim2.new(0.8, 0, 0, 0)
            btnDel.BackgroundColor3 = Color3.fromRGB(150, 0, 0)
            btnDel.TextColor3 = Color3.new(1,1,1)
            btnDel.Parent = itemFrame
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
    notificar("💾 Guardado")
    nameInput.Text = ""
    actualizarListaArchivos()
end)

function esBloqueValido(part)
    return part:IsA("BasePart") 
           and part.Name ~= "Baseplate" 
           and part.Transparency < 1 
           and not part.Parent:FindFirstChild("Humanoid") 
           and not part.Name:find("Ghost_")
           and part.Parent.Name ~= "Terrenos"
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

-- ==========================================
-- 🛠️ FUNCIONES DE COPIAR Y CONSTRUIR
-- ==========================================

function copiarEstructura()
    if not bloqueSeleccionado then return notificar("⚠️ Selecciona un bloque central") end
    local centroPart = bloqueSeleccionado
    datosGuardados = {}
    local origenCFrame = centroPart.CFrame
    local count = 0
    
    -- Visual temporal
    local esfera = Instance.new("Part")
    esfera.Shape = "Ball"
    esfera.Size = Vector3.new(RADIO_HORIZONTAL*2, RADIO_HORIZONTAL*2, RADIO_HORIZONTAL*2)
    esfera.CFrame = origenCFrame
    esfera.Transparency = 0.8
    esfera.Color = Color3.fromRGB(255, 0, 0)
    esfera.Anchored = true
    esfera.CanCollide = false
    esfera.Parent = workspace
    game:GetService("Debris"):AddItem(esfera, 1)

    for _, part in pairs(workspace:GetDescendants()) do
        if esBloqueValido(part) and part ~= esfera then
            local dist = (Vector3.new(part.Position.X, 0, part.Position.Z) - Vector3.new(origenCFrame.Position.X, 0, origenCFrame.Position.Z)).Magnitude
            if dist <= RADIO_HORIZONTAL then
                local cframeRelativo = origenCFrame:Inverse() * part.CFrame
                
                -- Guardamos siempre como "part_cube" para estandarizar, ya que tus logs usan eso
                table.insert(datosGuardados, {
                    Name = BLOQUE_GENERICO, 
                    Color = {part.Color.R, part.Color.G, part.Color.B}, 
                    Mat = part.Material.Name, 
                    Size = {part.Size.X, part.Size.Y, part.Size.Z}, 
                    CF = {cframeRelativo:GetComponents()}
                })
                count = count + 1
            end
        end
    end
    notificar("✅ Copiados: " .. count)
end

function pegarEstructuraVisual()
    if not bloqueSeleccionado then return notificar("⚠️ Selecciona destino") end
    if #datosGuardados == 0 then return notificar("⚠️ Archivo vacío") end
    
    limpiarFantasmas()
    
    local rotacionDeseada = obtenerRotacionJugador()
    local nuevoCentroCFrame = CFrame.new(bloqueSeleccionado.Position + Vector3.new(0,1,0)) * rotacionDeseada
    
    notificar("👁️ Mostrando Molde...")
    for _, data in pairs(datosGuardados) do
        local relCF = CFrame.new(unpack(data.CF))
        local cframeFinal = nuevoCentroCFrame * relCF
        cframeFinal = redondearCFrame(cframeFinal)
        
        local ghost = Instance.new("Part")
        ghost.Name = "Ghost_View"
        ghost.Size = Vector3.new(unpack(data.Size))
        ghost.CFrame = cframeFinal
        ghost.Color = Color3.fromRGB(0, 255, 255)
        ghost.Material = Enum.Material.ForceField
        ghost.Transparency = 0.6
        ghost.Anchored = true
        ghost.CanCollide = false
        ghost.Parent = workspace
        table.insert(fantasmasCreados, ghost)
    end
end

-- ==========================================
-- 🚀 FUNCIÓN CRÍTICA CORREGIDA (CON TUS LOGS)
-- ==========================================
function comenzarConstruccionReal()
    if not bloqueSeleccionado then return notificar("⚠️ Selecciona el suelo base") end
    if #datosGuardados == 0 then return notificar("⚠️ No hay datos cargados") end
    if procesoActivo then return notificar("⚠️ Ya construyendo...") end
    
    local character = LocalPlayer.Character
    local hrp = character and character:FindFirstChild("HumanoidRootPart")
    if not hrp then return end

    procesoActivo = true
    notificar("🔨 Construyendo (" .. #datosGuardados .. " bloques)...")
    
    local rotacionDeseada = obtenerRotacionJugador()
    local nuevoCentroCFrame = CFrame.new(bloqueSeleccionado.Position + Vector3.new(0,1,0)) * rotacionDeseada
    
    local posOriginal = hrp.CFrame 
    hrp.Anchored = true 

    for i, data in pairs(datosGuardados) do
        if not procesoActivo then break end 

        -- 1. Calcular dónde va el bloque FINAL
        local relCF = CFrame.new(unpack(data.CF))
        local cframeFinal = nuevoCentroCFrame * relCF
        cframeFinal = redondearCFrame(cframeFinal)
        local sizeObjetivo = Vector3.new(unpack(data.Size))
        
        -- 2. Teletransportarse al sitio (Crítico para que el server acepte la petición)
        hrp.CFrame = cframeFinal * CFrame.new(0, 5, 0)
        RunService.Heartbeat:Wait()

        -- 3. COLOCAR EL MUEBLE y CAPTURAR EL ID (UUID)
        -- Usamos pcall para evitar que un fallo detenga todo el script
        local exito, resultado = pcall(function()
            -- Esto imita tu primer log: placeFurniture, part_cube, CFrame
            return PlotSystem:InvokeServer("placeFurniture", BLOQUE_GENERICO, cframeFinal)
        end)
        
        -- Verificar si obtuvimos el ID (Ej: "fbec14c9-...")
        if exito and resultado and type(resultado) == "string" then
            local nuevoID = resultado
            
            -- Pequeña espera técnica
            RunService.Heartbeat:Wait()
            
            -- 4. ESCALAR EL MUEBLE (Usando el ID que acabamos de recibir)
            -- Esto imita tus logs de escala: scaleFurniture, ID, CFrame, Vector3
            pcall(function()
                PlotSystem:InvokeServer("scaleFurniture", nuevoID, cframeFinal, sizeObjetivo)
            end)
            
            -- Debug opcional en consola (F9)
            print("✅ Bloque " .. i .. " OK. ID: " .. nuevoID)
        else
            warn("❌ Fallo al colocar bloque " .. i)
        end
        
        task.wait(TIEMPO_ENTRE_ACCIONES)
    end
    
    hrp.Anchored = false
    hrp.CFrame = posOriginal
    procesoActivo = false
    notificar("✅ Construcción Terminada")
end

function detenerTodo()
    procesoActivo = false
    if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
        LocalPlayer.Character.HumanoidRootPart.Anchored = false
    end
    limpiarFantasmas()
    notificar("🛑 DETENIDO")
end

function limpiarFantasmas()
    for _, p in pairs(fantasmasCreados) do if p then p:Destroy() end end
    fantasmasCreados = {}
end

function vaciarMemoria()
    datosGuardados = {}
    notificar("♻️ Memoria vacía")
end

-- Botones
local function crearBoton(texto, color, orden, func)
    local btn = Instance.new("TextButton")
    btn.Text = texto
    btn.Size = UDim2.new(1, 0, 0, 32)
    btn.BackgroundColor3 = color
    btn.TextColor3 = Color3.new(1,1,1)
    btn.Font = Enum.Font.GothamBold
    btn.LayoutOrder = orden
    btn.Parent = actionsFrame
    Instance.new("UICorner", btn)
    btn.MouseButton1Click:Connect(func)
end

crearBoton("🎯 1. COPIAR (K)", Color3.fromRGB(0, 150, 100), 1, copiarEstructura)
crearBoton("👁️ 2. VER MOLDE (V)", Color3.fromRGB(0, 100, 200), 2, pegarEstructuraVisual)
crearBoton("🔨 3. CONSTRUIR (B)", Color3.fromRGB(200, 120, 0), 3, comenzarConstruccionReal)
crearBoton("🛑 PARAR (X)", Color3.fromRGB(150, 0, 0), 4, detenerTodo)
crearBoton("♻️ VACIAR MEM (Z)", Color3.fromRGB(80, 80, 80), 5, vaciarMemoria)

tool.Equipped:Connect(function(mouse)
    actualizarListaArchivos()
    mouse.Button1Down:Connect(function()
        if mouse.Target then
            bloqueSeleccionado = mouse.Target
            highlightBox.Adornee = bloqueSeleccionado
            notificar("🎯 Base: " .. bloqueSeleccionado.Name)
        end
    end)
    mouse.KeyDown:Connect(function(key)
        key = key:lower()
        if key == "k" then copiarEstructura()
        elseif key == "v" then pegarEstructuraVisual()
        elseif key == "b" then comenzarConstruccionReal()
        elseif key == "x" then detenerTodo()
        end
    end)
end)

tool.Unequipped:Connect(function() highlightBox.Adornee = nil bloqueSeleccionado = nil end)
actualizarListaArchivos()
notificar("✅ Script V6 (Fix Remotes)")
