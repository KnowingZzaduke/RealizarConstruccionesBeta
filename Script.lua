local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local HttpService = game:GetService("HttpService")
local CoreGui = game:GetService("CoreGui")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local LocalPlayer = Players.LocalPlayer
local Mouse = LocalPlayer:GetMouse()

-- ==========================================
-- 🔗 CONEXIÓN CON EL JUEGO
-- ==========================================
local PlotSystem = ReplicatedStorage:WaitForChild("Connections"):WaitForChild("Remotes"):WaitForChild("PlotSystem")

-- Intentamos localizar dónde se guardan los muebles para "vigilar" cuando aparecen
local MueblesFolder = nil
-- Buscamos dinámicamente la carpeta
if workspace:FindFirstChild("Terrenos") then
    -- Buscamos una carpeta dentro de terrenos que tenga muebles
    for _, t in pairs(workspace.Terrenos:GetChildren()) do
        if t:FindFirstChild("FurnitureContainer") then
            MueblesFolder = t.FurnitureContainer
            break
        elseif t:FindFirstChild("Folder") and t.Folder:FindFirstChild("FurnitureContainer") then
            MueblesFolder = t.Folder.FurnitureContainer
            break
        end
    end
end

-- ==========================================
-- ⚙️ CONFIGURACIÓN
-- ==========================================
local CARPETA_PRINCIPAL = "MisConstruccionesRoblox" 
local RADIO_COPIA = 40 -- Vuelto a 40
local BLOQUE_POR_DEFECTO = "part_cube" -- FORZAMOS QUE TODO SEA ESTE BLOQUE
local ESPERA_SERVIDOR = 0.5

if not isfolder(CARPETA_PRINCIPAL) then makefolder(CARPETA_PRINCIPAL) end

local datosGuardados = {} 
local fantasmasCreados = {} 
local bloqueSeleccionado = nil 
local esferaVisual = nil

-- Herramienta
local tool = Instance.new("Tool")
tool.RequiresHandle = false
tool.Name = "📐 Constructor V7 (Solo Cubos)"
tool.Parent = LocalPlayer.Backpack

-- Selección Visual
local highlightBox = Instance.new("SelectionBox")
highlightBox.Color3 = Color3.fromRGB(255, 0, 0)
highlightBox.LineThickness = 0.05
highlightBox.Parent = workspace
highlightBox.Adornee = nil

-- ==========================================
-- 🖥️ GUI (Panel)
-- ==========================================
if CoreGui:FindFirstChild("ClonadorProGUI") then CoreGui.ClonadorProGUI:Destroy() end
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "ClonadorProGUI"
if syn and syn.protect_gui then syn.protect_gui(screenGui) elseif gethui then screenGui.Parent = gethui() else screenGui.Parent = CoreGui end

local mainFrame = Instance.new("Frame")
mainFrame.Size = UDim2.new(0, 200, 0, 300)
mainFrame.Position = UDim2.new(0.05, 0, 0.3, 0)
mainFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
mainFrame.Parent = screenGui
Instance.new("UICorner", mainFrame)

local titulo = Instance.new("TextLabel")
titulo.Text = "Status: Esperando..."
titulo.Size = UDim2.new(1,0,0.1,0)
titulo.TextColor3 = Color3.fromRGB(255,255,0)
titulo.BackgroundTransparency = 1
titulo.Parent = mainFrame

local console = Instance.new("ScrollingFrame")
console.Size = UDim2.new(0.9,0,0.8,0)
console.Position = UDim2.new(0.05,0,0.15,0)
console.BackgroundTransparency = 1
console.Parent = mainFrame
local uiList = Instance.new("UIListLayout")
uiList.Parent = console

function log(txt)
    local l = Instance.new("TextLabel")
    l.Text = txt
    l.Size = UDim2.new(1,0,0,20)
    l.TextColor3 = Color3.new(1,1,1)
    l.BackgroundTransparency = 1
    l.Parent = console
    console.CanvasPosition = Vector2.new(0,9999)
    titulo.Text = txt
end

-- ==========================================
-- 🧠 FUNCIONES NUCLEARES
-- ==========================================

-- Función para dibujar la esfera del radio de copia
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
    log("Radio visible: " .. RADIO_COPIA .. " studs")
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

function copiarEstructura()
    if not bloqueSeleccionado then return log("❌ Selecciona un bloque centro primero") end
    
    mostrarRadio(bloqueSeleccionado)
    datosGuardados = {}
    local origenCFrame = bloqueSeleccionado.CFrame
    local count = 0
    
    for _, part in pairs(workspace:GetDescendants()) do
        if part:IsA("BasePart") and part.Transparency < 1 and part ~= esferaVisual and part.Name ~= "Baseplate" then
            local dist = (part.Position - origenCFrame.Position).Magnitude
            
            -- Filtro estricto de distancia
            if dist <= RADIO_COPIA then
                local cframeRelativo = origenCFrame:Inverse() * part.CFrame
                
                -- AQUÍ FORZAMOS EL NOMBRE:
                -- No importa cómo se llame en el juego, lo guardamos como el bloque por defecto
                -- pero guardamos SU TAMAÑO original.
                table.insert(datosGuardados, {
                    Name = BLOQUE_POR_DEFECTO,  -- <--- FORZADO "part_cube"
                    Size = {part.Size.X, part.Size.Y, part.Size.Z}, 
                    CF = {cframeRelativo:GetComponents()},
                    Color = {part.Color.R, part.Color.G, part.Color.B}
                })
                count = count + 1
            end
        end
    end
    log("✅ Copiados: " .. count .. " (Todo convertido a cubos)")
    if esferaVisual then esferaVisual:Destroy() esferaVisual = nil end
end

-- ==========================================
-- 🏗️ EL CONSTRUCTOR (INTELIGENCIA MEJORADA)
-- ==========================================

function intentarEscalar(uuid, size, cframe)
    local argsScale = {
        [1] = "scaleFurniture",
        [2] = uuid,
        [3] = cframe,
        [4] = size
    }
    PlotSystem:InvokeServer(unpack(argsScale))
    log("📏 Escalando ID: " .. string.sub(tostring(uuid), 1, 5).."...")
end

function construirPieza(data, centroCF)
    local relCF = CFrame.new(unpack(data.CF))
    local cframeFinal = centroCF * relCF
    -- Redondeo ligero para evitar decimales locos
    cframeFinal = CFrame.new(math.round(cframeFinal.X*10)/10, math.round(cframeFinal.Y*10)/10, math.round(cframeFinal.Z*10)/10) * (cframeFinal - cframeFinal.Position)
    
    local sizeFinal = Vector3.new(unpack(data.Size))
    
    -- 1. PONER EL MUEBLE
    -- Usamos pcall por si el servidor retorna nil o falla
    local furnitureID = nil
    
    -- OPCIÓN A: El servidor devuelve el ID (Ideal)
    local success, result = pcall(function()
        return PlotSystem:InvokeServer("placeFurniture", data.Name, cframeFinal)
    end)
    
    if success and result and type(result) == "string" then
        furnitureID = result
        log("🔹 ID Directo recibido")
    end
    
    -- OPCIÓN B: El servidor NO devuelve ID, buscamos el bloque nuevo
    if not furnitureID and MueblesFolder then
        -- Esperamos un momento a que aparezca algo nuevo en la carpeta
        log("⚠️ Buscando ID manualmente...")
        local tiempoInicio = tick()
        local piezaEncontrada = nil
        
        -- Escaneamos la carpeta buscando una parte MUY cerca de donde construimos
        -- Le damos 1 segundo al servidor para spawnear la parte
        local intentos = 0
        while intentos < 10 do
            for _, child in pairs(MueblesFolder:GetDescendants()) do
                if child:IsA("BasePart") then
                    if (child.Position - cframeFinal.Position).Magnitude < 0.5 then
                        -- Encontrado algo en la posición exacta!
                        -- Normalmente el ID está en un Atributo o es el nombre del modelo
                        -- En este juego, por tus logs, el scaling usa un UUID.
                        -- A veces el UUID es el nombre del objeto padre.
                        if child.Parent:GetAttribute("FurnitureId") then
                            furnitureID = child.Parent:GetAttribute("FurnitureId")
                            piezaEncontrada = child
                            break
                        elseif child.Parent.Name:match("%w+-%w+-%w+") then -- Parece un UUID
                            furnitureID = child.Parent.Name
                            piezaEncontrada = child
                            break
                        end
                    end
                end
            end
            if furnitureID then break end
            intentos = intentos + 1
            task.wait(0.1)
        end
    end
    
    -- 2. ESCALAR (Si conseguimos el ID)
    if furnitureID then
        task.wait(0.2) -- Pequeña pausa dramática
        intentarEscalar(furnitureID, sizeFinal, cframeFinal)
    else
        -- ÚLTIMO RECURSO: Probar escalar asumiendo que el ID es desconocido (A veces funciona reenviar el evento de place)
        log("❌ No se encontró ID para escalar")
    end
end

function pegarEstructura()
    if not bloqueSeleccionado then return log("❌ Click en el suelo base primero") end
    if #datosGuardados == 0 then return log("❌ Nada copiado") end
    
    local rotacion = obtenerRotacionJugador()
    local nuevoCentro = CFrame.new(bloqueSeleccionado.Position + Vector3.new(0,2,0)) * rotacion
    
    log("🏗️ Iniciando construcción...")
    
    for i, data in ipairs(datosGuardados) do
        task.spawn(function()
            construirPieza(data, nuevoCentro)
        end)
        task.wait(0.3) -- Velocidad moderada para no saturar
    end
    log("🏁 Terminado")
end

-- ==========================================
-- 🎮 CONTROLES
-- ==========================================
tool.Equipped:Connect(function(mouse)
    log("✅ Herramienta equipada")
    mouse.Button1Down:Connect(function()
        if mouse.Target then
            bloqueSeleccionado = mouse.Target
            highlightBox.Adornee = bloqueSeleccionado
            log("🎯 Seleccionado: " .. mouse.Target.Name)
        end
    end)
    
    mouse.KeyDown:Connect(function(key)
        if key == "k" then copiarEstructura() end
        if key == "v" then pegarEstructura() end
    end)
end)

tool.Unequipped:Connect(function()
    highlightBox.Adornee = nil
    if esferaVisual then esferaVisual:Destroy() esferaVisual = nil end
end)
