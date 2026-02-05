local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local HttpService = game:GetService("HttpService")
local CoreGui = game:GetService("CoreGui")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local LocalPlayer = Players.LocalPlayer
local Mouse = LocalPlayer:GetMouse()

-- ==========================================
-- 🔗 CONEXIÓN CON EL JUEGO (REMOTES)
-- ==========================================
-- Buscamos la ruta exacta que mostraste en los logs
local PlotSystem = ReplicatedStorage:WaitForChild("Connections"):WaitForChild("Remotes"):WaitForChild("PlotSystem")

-- ==========================================
-- ⚙️ CONFIGURACIÓN
-- ==========================================
local CARPETA_PRINCIPAL = "MisConstruccionesRoblox" 
local RADIO_HORIZONTAL = 40 
local TRANSPARENCIA_MOLDE = 0.5 
local TIEMPO_ESPERA_ENTRE_BLOQUES = 0.2 -- Aumentado ligeramente para dar tiempo al servidor

if not isfolder(CARPETA_PRINCIPAL) then makefolder(CARPETA_PRINCIPAL) end

local datosGuardados = {} 
local fantasmasCreados = {} 
local bloqueSeleccionado = nil 
local menuAbierto = true

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
-- 🖥️ GUI (DISEÑO MEJORADO)
-- ==========================================
if CoreGui:FindFirstChild("ClonadorProGUI") then CoreGui.ClonadorProGUI:Destroy() end

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "ClonadorProGUI"
if syn and syn.protect_gui then syn.protect_gui(screenGui) 
elseif gethui then screenGui.Parent = gethui()
else screenGui.Parent = CoreGui end

-- [ ... SECCIÓN GUI IDÉNTICA A TU SCRIPT ORIGINAL ... ]
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

-- Funciones GUI básicas
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
    -- Redondear rotación es complejo, lo mantenemos simple por ahora
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
    -- Intenta filtrar solo las partes que parecen muebles
    -- Ajusta esto según el juego. Aquí evitamos el Terreno y el Baseplate.
    return part:IsA("BasePart") 
           and part.Name ~= "Baseplate" 
           and part.Transparency < 1 
           and not part.Parent:FindFirstChild("Humanoid") 
           and not part.Name:find("Ghost_")
           and part.Parent.Name ~= "Terrenos" -- Evita copiar el suelo del juego
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
-- 🏗️ LÓGICA DE CONSTRUCCIÓN REAL (MODIFICADA)
-- ==========================================
function colocarBloqueReal(nombreItem, cframePosicion, sizeObjetivo)
    -- Aquí ocurre la magia con los datos que me diste
    
    -- 1. Argumentos para colocar (placeFurniture)
    local argsPlace = {
        [1] = "placeFurniture",
        [2] = nombreItem, -- Ej: "part_cube"
        [3] = cframePosicion
    }
    
    -- Usamos InvokeServer porque esperamos que devuelva el ID del mueble
    -- Envuelve en pcall para que no crashee si falla
    local exito, furnitureID = pcall(function() 
        return PlotSystem:InvokeServer(unpack(argsPlace))
    end)
    
    if exito and furnitureID then
        -- Si obtuvimos un ID válido, procedemos a escalarlo
        
        -- Verificamos si realmente necesitamos escalar (evitar llamadas innecesarias si es tamaño 1,1,1)
        -- Aunque en este juego parece que "part_cube" siempre necesita escalar.
        
        local argsScale = {
            [1] = "scaleFurniture",
            [2] = furnitureID, -- El UUID que nos devolvió el servidor
            [3] = cframePosicion,
            [4] = sizeObjetivo -- El Vector3 del tamaño guardado
        }
        
        PlotSystem:InvokeServer(unpack(argsScale))
        print("✅ Colocado y Escalado:", nombreItem, furnitureID)
    else
        warn("❌ Fallo al colocar:", nombreItem)
    end
end

function copiarEstructura()
    if not bloqueSeleccionado then return notificar("⚠️ Selecciona un bloque central") end
    local centroPart = bloqueSeleccionado
    datosGuardados = {}
    local origenCFrame = centroPart.CFrame
    local count = 0
    
    -- Escaneamos workspace. SUGERENCIA: Si puedes, cambia workspace:GetDescendants()
    -- por la carpeta específica de muebles si la conoces (ej. workspace.Terrenos.Folder...)
    for _, part in pairs(workspace:GetDescendants()) do
        if esBloqueValido(part) then
            local dist = (Vector3.new(part.Position.X, 0, part.Position.Z) - Vector3.new(origenCFrame.Position.X, 0, origenCFrame.Position.Z)).Magnitude
            if dist <= RADIO_HORIZONTAL then
                local cframeRelativo = origenCFrame:Inverse() * part.CFrame
                
                -- Guardamos el nombre real del item (ej. "part_cube")
                -- A veces el nombre de la Part no es el nombre del Item.
                -- Si falla, revisa si part.Parent.Name es el correcto.
                local nombreGuardar = part.Name
                if part.Parent:IsA("Model") then
                     -- Ajuste por si la parte está dentro de un modelo llamado "part_cube"
                     if part.Parent.Name:find("part_") or part.Parent.Name:find("Furniture") then
                         nombreGuardar = part.Parent.Name 
                     end
                end

                table.insert(datosGuardados, {
                    Name = nombreGuardar, 
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

function pegarEstructura()
    if not bloqueSeleccionado then return notificar("⚠️ Selecciona dónde pegar (click)") end
    if #datosGuardados == 0 then return notificar("⚠️ Archivo vacío") end
    
    local rotacionDeseada = obtenerRotacionJugador()
    -- Ajustamos la altura para que no quede enterrado (opcional)
    local nuevoCentroCFrame = CFrame.new(bloqueSeleccionado.Position + Vector3.new(0, 1, 0)) * rotacionDeseada
    
    notificar("🏗️ Construyendo...")
    
    for i, data in pairs(datosGuardados) do
        local relCF = CFrame.new(unpack(data.CF))
        local cframeFinal = nuevoCentroCFrame * relCF
        cframeFinal = redondearCFrame(cframeFinal)
        local sizeVector = Vector3.new(unpack(data.Size))
        
        -- 1. Crear fantasma visual (Cliente)
        local ghost = Instance.new("Part")
        ghost.Name = "Ghost_" .. data.Name
        ghost.Size = sizeVector
        ghost.CFrame = cframeFinal
        ghost.Color = Color3.new(unpack(data.Color))
        ghost.Material = Enum.Material[data.Mat] or Enum.Material.Plastic
        ghost.Transparency = TRANSPARENCIA_MOLDE
        ghost.Anchored = true
        ghost.CanCollide = false
        ghost.Parent = workspace
        table.insert(fantasmasCreados, ghost)
        
        -- 2. Llamar al servidor para construir de verdad
        task.spawn(function() 
            colocarBloqueReal(data.Name, cframeFinal, sizeVector) 
        end)
        
        if TIEMPO_ESPERA_ENTRE_BLOQUES > 0 then task.wait(TIEMPO_ESPERA_ENTRE_BLOQUES) end
    end
    notificar("✅ Proceso terminado")
end

function limpiarFantasmas()
    for _, p in pairs(fantasmasCreados) do if p then p:Destroy() end end
    fantasmasCreados = {}
    bloqueSeleccionado = nil
    highlightBox.Adornee = nil
    notificar("🗑️ Visual limpiado")
end

function vaciarMemoria()
    datosGuardados = {}
    notificar("♻️ Memoria vacía")
end

-- Generador de botones
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

crearBoton("🎯 COPIAR (K)", Color3.fromRGB(0, 150, 100), 1, copiarEstructura)
crearBoton("🏗️ PEGAR (V)", Color3.fromRGB(0, 100, 200), 2, pegarEstructura)
crearBoton("🧹 LIMPIAR VISUAL (X)", Color3.fromRGB(200, 120, 0), 3, limpiarFantasmas)
crearBoton("♻️ VACIAR MEMORIA (Z)", Color3.fromRGB(150, 0, 0), 4, vaciarMemoria)

tool.Equipped:Connect(function(mouse)
    actualizarListaArchivos()
    mouse.Button1Down:Connect(function()
        if mouse.Target and esBloqueValido(mouse.Target) then
            bloqueSeleccionado = mouse.Target
            highlightBox.Adornee = bloqueSeleccionado
            notificar("🎯 " .. bloqueSeleccionado.Name)
        elseif mouse.Target then
            -- Permitir seleccionar el suelo para pegar, aunque no sea un mueble
            bloqueSeleccionado = mouse.Target
            highlightBox.Adornee = bloqueSeleccionado
            notificar("🎯 Punto Base: " .. bloqueSeleccionado.Name)
        end
    end)
    mouse.KeyDown:Connect(function(key)
        key = key:lower()
        if key == "k" then copiarEstructura()
        elseif key == "v" then pegarEstructura()
        elseif key == "x" then limpiarFantasmas()
        elseif key == "z" then vaciarMemoria()
        end
    end)
end)

tool.Unequipped:Connect(function() highlightBox.Adornee = nil bloqueSeleccionado = nil end)
actualizarListaArchivos()
notificar("✅ Script v5.0 (Auto-Build Activado)")
