-- a wise man once said: "i will rewrite this someday"

local Root = script.Parent.Parent
local Flipper = require(Root.Packages.Flipper)
local Creator = require(Root.Modules.Creator)
local Acrylic = require(Root.Modules.Acrylic)
local Signal = require(Root.Packages.Signal)
local Assets = require(script.Parent.Assets)
local Components = script.Parent

local Library = require(Root)

local UserInputService = Library.Utilities:Clone(game:GetService("UserInputService"))
local Mouse = Library.Utilities:Clone(game:GetService("Players")).LocalPlayer:GetMouse()
local Camera = Library.Utilities:Clone(game:GetService("Workspace")).CurrentCamera
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")

local Spring = Flipper.Spring.new
local Instant = Flipper.Instant.new
local New = Creator.New

return function(Config)
	assert(typeof(Config.Mobile) == "table", "Config key 'Mobile' must be a table!")
	assert(typeof(Config.Mobile.GetIcon) == "function", "Mobile Config key 'GetIcon' must be a function!")
	assert(typeof(Config.Mobile.Size) == "UDim2", "Mobile Config key 'Size' must be a UDim2!")
	
	local Window = {
		Minimized = false,
		OnMinimized = Signal.new(),
		PostMinimized = Signal.new(),
		Maximized = false,
		OnMaximized = Signal.new(),
		PostMaximized = Signal.new(),
		Size = Config.Size,
		MinSize = Config.MinSize,
		CurrentPos = 0,
		TabWidth = 0,
		Position = UDim2.fromOffset(
			Camera.ViewportSize.X / 2 - Config.Size.X.Offset / 2,
			Camera.ViewportSize.Y / 2 - Config.Size.Y.Offset / 2
		),
	}

	local Dragging, DragInput, MousePos, StartPos = false
	local Resizing, ResizePos = false
	local MinimizeNotif = false
	local IsDraggingHideButton, DragInputHideButton, DragStart, DragStartPos = false

	Window.AcrylicPaint = Acrylic.AcrylicPaint()
	Window.TabWidth = Config.TabWidth

	local Selector = New("Frame", {
		Size = UDim2.fromOffset(4, 0),
		BackgroundColor3 = Color3.fromRGB(76, 194, 255),
		Position = UDim2.fromOffset(0, 17),
		AnchorPoint = Vector2.new(0, 0.5),
		ThemeTag = {
			BackgroundColor3 = "Accent",
		},
	}, {
		New("UICorner", {
			CornerRadius = UDim.new(0, 2),
		}),
	})

	local ResizeStartFrame = New("Frame", {
		Size = UDim2.fromOffset(20, 20),
		BackgroundTransparency = 1,
		Position = UDim2.new(1, -20, 1, -20),
	})

	Window.TabHolder = New("ScrollingFrame", {
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		ScrollBarImageTransparency = 1,
		ScrollBarThickness = 0,
		BorderSizePixel = 0,
		CanvasSize = UDim2.fromScale(0, 0),
		ScrollingDirection = Enum.ScrollingDirection.Y,
	}, {
		New("UIListLayout", {
			Padding = UDim.new(0, 4),
		}),
	})

	local TabFrame = New("Frame", {
		Size = UDim2.new(0, Window.TabWidth, 1, -66),
		Position = UDim2.new(0, 12, 0, 54),
		BackgroundTransparency = 1,
		ClipsDescendants = true,
	}, {
		Window.TabHolder,
		Selector,
	})

	Window.TabDisplay = New("TextLabel", {
		RichText = true,
		Text = "Tab",
		TextTransparency = 0,
		FontFace = Font.new("rbxassetid://12187365364", Enum.FontWeight.SemiBold, Enum.FontStyle.Normal),
		TextSize = 28,
		TextXAlignment = "Left",
		TextYAlignment = "Center",
		Size = UDim2.new(1, -16, 0, 28),
		Position = UDim2.fromOffset(Window.TabWidth + 26, 56),
		BackgroundTransparency = 1,
		ThemeTag = {
			TextColor3 = "Text",
		},
	})

	Window.ContainerHolder = New("Frame", {
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
	})

	Window.ContainerAnim = New("CanvasGroup", {
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
	})

	Window.ContainerCanvas = New("Frame", {
		Size = UDim2.new(1, -Window.TabWidth - 32, 1, -102),
		Position = UDim2.fromOffset(Window.TabWidth + 26, 90),
		BackgroundTransparency = 1,
	}, {
		Window.ContainerAnim,
		Window.ContainerHolder
	})
	
	Window.CanvasGroup = New("CanvasGroup", {
		BackgroundTransparency = 1,
		Size                   = UDim2.new(1, 0, 1, 0),
		Parent                 = Config.Parent,
	})

	Window.Root = New("Frame", {
		BackgroundTransparency = 1,
		Size                   = Window.Size,
		AnchorPoint			   = Vector2.new(0.5, 0.5),
		Position               = UDim2.new(0.5, 0, 0.5, 0),
		Parent                 = Window.CanvasGroup,
	}, {
		Window.AcrylicPaint.Frame,
		Window.TabDisplay,
		Window.ContainerCanvas,
		TabFrame,
		ResizeStartFrame,
	})

	Window.UIScale = New("UIScale", {
		Scale  = 1,
		Parent = Window.Root,
	})

	Window.HideButton = New("ImageButton", {
		Visible = Library.Utilities:GetOS() == "Mobile",
		Size = Config.Mobile.Size,
		BackgroundTransparency = 1,
		Position = UDim2.new(1, -Config.Mobile.Size.X.Offset - 25, 0.5, -Config.Mobile.Size.Y.Offset / 2),
		Parent = Config.Parent,
		Image = Config.Mobile.GetIcon(false).Image,
		ImageRectOffset = Config.Mobile.GetIcon(false).ImageRectOffset,
		ImageRectSize = Config.Mobile.GetIcon(false).ImageRectSize
	})

	Window.TitleBar = require(script.Parent.TitleBar)({
		Logo = Config.Logo,
		SubTitle = Config.SubTitle,
		Parent = Window.Root,
		Window = Window,
	})

	if Library.UseAcrylic then
		Window.AcrylicPaint.AddParent(Window.CanvasGroup)
	end

	local SizeMotor = Flipper.GroupMotor.new({
		X = Window.Size.X.Offset,
		Y = Window.Size.Y.Offset,
	})

	local PosMotor = Flipper.GroupMotor.new({
		X = Window.Position.X.Offset,
		Y = Window.Position.Y.Offset,
	})

	Window.SelectorPosMotor = Flipper.SingleMotor.new(17)
	Window.SelectorSizeMotor = Flipper.SingleMotor.new(0)
	Window.ContainerBackMotor = Flipper.SingleMotor.new(0)
	Window.ContainerPosMotor = Flipper.SingleMotor.new(94)

	SizeMotor:onStep(function(values)
		Window.Root.Size = UDim2.new(0, values.X, 0, values.Y)
	end)

	PosMotor:onStep(function(values)
		Window.Root.Position = UDim2.new(0, values.X, 0, values.Y)
	end)

	local LastValue = 0
	local LastTime = 0
	Window.SelectorPosMotor:onStep(function(Value)
		Selector.Position = UDim2.new(0, 0, 0, Value + 17)
		local Now = tick()
		local DeltaTime = Now - LastTime

		if LastValue ~= nil then
			Window.SelectorSizeMotor:setGoal(Spring((math.abs(Value - LastValue) / (DeltaTime * 60)) + 16))
			LastValue = Value
		end
		LastTime = Now
	end)

	Window.SelectorSizeMotor:onStep(function(Value)
		Selector.Size = UDim2.new(0, 4, 0, Value)
	end)

	Window.ContainerBackMotor:onStep(function(Value)
		Window.ContainerAnim.GroupTransparency = Value
	end)

	Window.ContainerPosMotor:onStep(function(Value)
		Window.ContainerAnim.Position = UDim2.fromOffset(0, Value)
	end)

	local oldSize, oldPosition

	Window.Maximize = function(isMaximized, noPos, instant)
		Window.OnMaximized:Fire(tick())
		Window.Maximized = isMaximized
		Window.TitleBar.MaxButton.Frame.Icon.Image = isMaximized and Assets.Restore or Assets.Max

		-- on maximize: stash current size & pos
		if isMaximized then
			oldSize     = Window.Root.Size
			oldPosition = Window.Root.Position
		end

		-- decide our targets
		local targetSize     = isMaximized and UDim2.new(1, 0, 1, 0) or oldSize
		local targetPosition = isMaximized and UDim2.fromScale(0.5, 0.5) or oldPosition

		if instant then
			-- jump immediately
			Window.Root.Size     = targetSize
			if not noPos then
				Window.Root.Position = targetPosition
			end
		else
			-- tween size
			TweenService:Create(
				Window.Root,
				TweenInfo.new(0.25, Enum.EasingStyle.Quart, Enum.EasingDirection.Out),
				{ Size = targetSize }
			):Play()

			-- tween position (unless NoPos is true)
			if not noPos then
				TweenService:Create(
					Window.Root,
					TweenInfo.new(0.25, Enum.EasingStyle.Quart, Enum.EasingDirection.Out),
					{ Position = targetPosition }
				):Play()
			end
		end

		Window.PostMaximized:Fire(tick())
	end

	Creator.AddSignal(Window.TitleBar.Frame.InputBegan, function(Input)
		if Input.UserInputType == Enum.UserInputType.MouseButton1
			or Input.UserInputType == Enum.UserInputType.Touch then
			Dragging   = true
			MousePos   = Input.Position
			-- ← grab whatever the window’s current position is (preserves your .Scale)
			StartPos   = Window.Root.Position

			if Window.Maximized then
				-- your existing maximized logic
				StartPos = UDim2.fromOffset(
					Mouse.X - (Mouse.X * ((OldSizeX - 100) / Window.Root.AbsoluteSize.X)),
					Mouse.Y - (Mouse.Y * (OldSizeY / Window.Root.AbsoluteSize.Y))
				)
			end

			Input.Changed:Connect(function()
				if Input.UserInputState == Enum.UserInputState.End then
					Dragging = false
				end
			end)
		end
	end)


	Creator.AddSignal(Window.TitleBar.Frame.InputChanged, function(Input)
		if
			Input.UserInputType == Enum.UserInputType.MouseMovement
			or Input.UserInputType == Enum.UserInputType.Touch
		then
			DragInput = Input
		end
	end)

	local UserInputService = game:GetService("UserInputService")

	-- your globals
	local Resizing   = false
	local ResizePos  = Vector2.new()
	local StartSize  = Vector2.new()
	-- optional: enforce a minimum size
	local MIN_SIZE   = Vector2.new(200, 100)

	-- when you press the resize handle…
	Creator.AddSignal(ResizeStartFrame.InputBegan, function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1
			or input.UserInputType == Enum.UserInputType.Touch then
			Resizing  = true
			ResizePos = input.Position
			-- grab the window’s current pixel size
			StartSize = Vector2.new(
				Window.Root.AbsoluteSize.X,
				Window.Root.AbsoluteSize.Y
			)

			-- end resize when the user releases
			input.Changed:Connect(function()
				if input.UserInputState == Enum.UserInputState.End then
					Resizing = false
				end
			end)
		end
	end)

	-- track every mouse‐move globally
	UserInputService.InputChanged:Connect(function(input)
		if Resizing and input.UserInputType == Enum.UserInputType.MouseMovement then
			local delta = input.Position - ResizePos

			-- compute new size, clamped to a minimum
			local newW = math.max(StartSize.X + delta.X, MIN_SIZE.X)
			local newH = math.max(StartSize.Y + delta.Y, MIN_SIZE.Y)

			-- apply it (0 scale = pure-pixel sizing)
			Window.Root.Size = UDim2.new(0, newW, 0, newH)
		end
	end)



	local Dragging   = false
	local MousePos   = Vector2.new()
	local StartPos   = UDim2.new()

	Creator.AddSignal(Window.TitleBar.Frame.InputBegan, function(Input)
		if Input.UserInputType == Enum.UserInputType.MouseButton1
			or Input.UserInputType == Enum.UserInputType.Touch then
			Dragging = true
			MousePos = Input.Position
			StartPos = Window.Root.Position

			if Window.Maximized then
				StartPos = UDim2.fromOffset(
					Mouse.X - (Mouse.X * ((OldSizeX - 100) / Window.Root.AbsoluteSize.X)),
					Mouse.Y - (Mouse.Y * (OldSizeY / Window.Root.AbsoluteSize.Y))
				)
			end

			Input.Changed:Connect(function()
				if Input.UserInputState == Enum.UserInputState.End then
					Dragging = false
				end
			end)
		end
	end)

	UserInputService.InputChanged:Connect(function(Input)
		if Dragging and Input.UserInputType == Enum.UserInputType.MouseMovement then
			local delta = Input.Position - MousePos
			Window.Root.Position = UDim2.new(
				StartPos.X.Scale, StartPos.X.Offset + delta.X,
				StartPos.Y.Scale, StartPos.Y.Offset + delta.Y
			)
		end
	end)


	Creator.AddSignal(UserInputService.InputEnded, function(Input)
		if Resizing == true or Input.UserInputType == Enum.UserInputType.Touch then
			Resizing = false
			Window.Size = UDim2.fromOffset(SizeMotor:getValue().X, SizeMotor:getValue().Y)
		end
	end)

	Creator.AddSignal(Window.TabHolder.UIListLayout:GetPropertyChangedSignal("AbsoluteContentSize"), function()
		if Window.TabHolder.CanvasSize ~= UDim2.fromOffset(0, Window.TabHolder.UIListLayout.AbsoluteContentSize.Y) then
			Window.TabHolder.CanvasSize = UDim2.fromOffset(0, Window.TabHolder.UIListLayout.AbsoluteContentSize.Y)
		end
	end)
	
	function Window:Minimize()
		Window.Minimized = not Window.Minimized

		local targetScale        = Window.Minimized and 0.96 or 1
		local targetTransparency = Window.Minimized and 1    or 0

		local TweenService = game:GetService("TweenService")
		local tweenInfo   = TweenInfo.new(0.25, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)

		local scaleTween = TweenService:Create(
			Window.UIScale,
			tweenInfo,
			{ Scale = targetScale }
		)
		scaleTween:Play()

		if targetTransparency == 0 then
			Window.CanvasGroup.Visible = true
		end

		local fadeTween = TweenService:Create(
			Window.CanvasGroup,
			tweenInfo,
			{ GroupTransparency = targetTransparency }
		)
		fadeTween:Play()

		if targetTransparency == 1 then
			fadeTween.Completed:Connect(function()
				Window.CanvasGroup.Visible = false
			end)
		end

		Window.OnMinimized:Fire(tick(), Window.Root.Visible)

		if not MinimizeNotif then
			local Key = Library.MinimizeKeybind and Library.MinimizeKeybind.Value
				or type(Library.MinimizeKey) == "string" and Library.MinimizeKey
				or Library.MinimizeKey.Name

			MinimizeNotif = true
			Library:Notify({
				Title    = "Interface",
				Content  = `Press {Library.Utilities:Prettify(Key)} to toggle the interface.`,
				Duration = 6
			})
		end

		-- update mobile icon if needed
		if Library.Utilities:GetOS() == "Mobile" then
			local Icon = Config.Mobile.GetIcon(Window.Minimized)
			Window.HideButton.Image           = Icon.Image
			Window.HideButton.ImageRectOffset = Icon.ImageRectOffset
			Window.HideButton.ImageRectSize   = Icon.ImageRectSize
		end

		Window.PostMinimized:Fire(tick(), Window.Root.Visible)
	end



	Creator.AddSignal(UserInputService.InputBegan, function(Input)
		if
			type(Library.MinimizeKeybind) == "table"
			and Library.MinimizeKeybind.Type == "Keybind"
			and not UserInputService:GetFocusedTextBox()
		then
			if Input.KeyCode.Name == Library.MinimizeKeybind.Value or Input.KeyCode.Name == Library.MinimizeKeybind.Value.Name then
				Window:Minimize()
			end
		elseif (Input.KeyCode == Library.MinimizeKey or Input.KeyCode.Name == Library.MinimizeKey) and not UserInputService:GetFocusedTextBox() then
			Window:Minimize()
		end
	end)

	Creator.AddSignal(Window.HideButton.InputBegan, function(Input)
		if
			Input.UserInputType == Enum.UserInputType.MouseButton1
			or Input.UserInputType == Enum.UserInputType.Touch
		then
			IsDraggingHideButton = true
			DragStart = Input.Position
			DragStartPos = Window.HideButton.Position

			Input.Changed:Connect(function()
				if Input.UserInputState == Enum.UserInputState.End then
					IsDraggingHideButton = false
				end
			end)
		end
	end)

	Creator.AddSignal(Window.HideButton.InputChanged, function(Input)
		if
			Input.UserInputType == Enum.UserInputType.MouseMovement
			or Input.UserInputType == Enum.UserInputType.Touch
		then
			DragInputHideButton = Input
		end
	end)

	Creator.AddSignal(UserInputService.InputChanged, function(Input)
		if Input == DragInputHideButton and IsDraggingHideButton then
		        local delta = Input.Position - DragStart
			Window.HideButton.Position = UDim2.new(DragStartPos.X.Scale, DragStartPos.X.Offset + delta.X, DragStartPos.Y.Scale, DragStartPos.Y.Offset + delta.Y)
		end
	end)

	if Library.Utilities:GetOS() == "Mobile" then
		Creator.AddSignal(Window.HideButton.TouchTap, function()
			Window.Minimized = not Window.Minimized
       			Window.Root.Visible = not Window.Minimized
			local Icon = Config.Mobile.GetIcon(Window.Minimized)
			Window.HideButton.Image = Icon.Image
			Window.HideButton.ImageRectOffset = Icon.ImageRectOffset
			Window.HideButton.ImageRectSize = Icon.ImageRectSize
		end)
	else
		Creator.AddSignal(Window.HideButton.MouseButton1Click, function()
			Window.Minimized = not Window.Minimized
       			Window.Root.Visible = not Window.Minimized
		end)	
	end

	function Window:Destroy()
		if Library.UseAcrylic then
			Window.AcrylicPaint.Model:Destroy()
		end
		Window.Root:Destroy()
	end

	local DialogModule = require(Components.Dialog):Init(Window)
	function Window:Dialog(Config)
		local Dialog = DialogModule:Create()

		local Content = New("TextLabel", {
			FontFace = Font.new("rbxassetid://12187365364"),
			Text = Config.Content,
			TextColor3 = Color3.fromRGB(240, 240, 240),
			TextSize = 14,
			TextXAlignment = Enum.TextXAlignment.Left,
			TextYAlignment = Enum.TextYAlignment.Top,
			Size = UDim2.new(1, -40, 1, 0),
			Position = UDim2.fromOffset(20, 60),
			BackgroundTransparency = 1,
			Parent = Dialog.Root,
			ClipsDescendants = false,
			ThemeTag = {
				TextColor3 = "Text",
			},
		})

		New("UISizeConstraint", {
			MinSize = Vector2.new(300, 165),
			MaxSize = Vector2.new(620, math.huge),
			Parent = Dialog.Root,
		})

		Dialog.Root.Size = UDim2.fromOffset(Content.TextBounds.X + 40, 165)
		if Content.TextBounds.X + 40 > Window.Size.X.Offset - 120 then
			Dialog.Root.Size = UDim2.fromOffset(Window.Size.X.Offset - 120, 165)
			Content.TextWrapped = true
			Dialog.Root.Size = UDim2.fromOffset(Window.Size.X.Offset - 120, Content.TextBounds.Y + 150)
		end

		for _, Button in next, Config.Buttons do
			Dialog:Button(Button.Title, Button.Callback)
		end

		Dialog:Open()

		if Config.Yield then
			Dialog.Closed:Wait()
		end

		return Dialog
	end

	local TabModule = require(Components.Tab):Init(Window)

	function Window:Tab(TabConfig)
		return TabModule:New(TabConfig.Title, TabConfig.Icon, Window.TabHolder)
	end

	function Window:AddTab(TabConfig)
		return Window:Tab(TabConfig)
	end

	function Window:CreateTab(TabConfig)
		return Window:Tab(TabConfig)
	end

	function Window:SelectTab(Tab)
		TabModule:SelectTab(Tab)
	end

	Creator.AddSignal(Window.TabHolder:GetPropertyChangedSignal("CanvasPosition"), function()
		LastValue = TabModule:GetCurrentTabPos() + 16
		LastTime = 0
		Window.SelectorPosMotor:setGoal(Instant(TabModule:GetCurrentTabPos()))
	end)

	return Window
end
