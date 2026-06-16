import SwiftUI

struct ContentView: View {
    @StateObject private var store = ChatStore()
    @State private var inputText = ""
    @State private var showModelPicker = false
    @State private var showSettings = false
    @State private var showPersonalization = false
    @State private var showSidebar = false
    @State private var customizationEnabled = true
    @State private var instructions = ""
    @State private var temperature = 0.5

    var body: some View {
        GeometryReader { proxy in
            let width = proxy.size.width
            let height = proxy.size.height

            ZStack {
                LoopingVideoBackground()
                    .opacity(0.95)

                LinearGradient(
                    colors: [
                        Color(red: 0.43, green: 0.43, blue: 0.92).opacity(0.34),
                        Color(red: 0.23, green: 0.11, blue: 0.49).opacity(0.18),
                        Color.black.opacity(0.94)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()

                VStack(spacing: 0) {
                    topBar
                        .padding(.horizontal, 14)
                        .padding(.top, 8)

                    Spacer(minLength: 0)

                    chatArea
                        .padding(.horizontal, 18)
                        .padding(.top, 10)

                    Spacer(minLength: 0)

                    bottomDock(width: width)
                        .padding(.bottom, 12)
                }
                .ignoresSafeArea(edges: .bottom)

                if showSidebar {
                    sidebarOverlay
                        .transition(.move(edge: .leading).combined(with: .opacity))
                }

                if showModelPicker {
                    blurShield
                    modelPickerCard(width: min(width - 32, 560))
                        .transition(.scale.combined(with: .opacity))
                }

                if showSettings {
                    settingsSheet
                        .transition(.move(edge: .top).combined(with: .opacity))
                }

                if showPersonalization {
                    personalizationSheet
                        .transition(.move(edge: .trailing).combined(with: .opacity))
                }
            }
            .animation(.spring(response: 0.30, dampingFraction: 0.88), value: showSidebar)
            .animation(.spring(response: 0.30, dampingFraction: 0.88), value: showModelPicker)
            .animation(.spring(response: 0.30, dampingFraction: 0.88), value: showSettings)
            .animation(.spring(response: 0.30, dampingFraction: 0.88), value: showPersonalization)
            .onAppear {
                if store.currentConversation.messages.isEmpty {
                    store.sendHello()
                }
            }
        }
    }

    private var blurShield: some View {
        Color.black.opacity(0.38)
            .ignoresSafeArea()
            .onTapGesture { showModelPicker = false }
    }

    private var topBar: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 12) {
                HStack(spacing: 12) {
                    iconPill(systemName: "gearshape.fill") { showSettings = true }
                    iconPill(systemName: "message.fill") { showSidebar.toggle() }
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 8)
                .background(
                    Capsule()
                        .fill(Color(red: 0.18, green: 0.26, blue: 0.84).opacity(0.72))
                        .overlay(Capsule().stroke(Color.white.opacity(0.10), lineWidth: 1))
                )
                .modifier(LiquidGlass())

                Button {
                    showModelPicker = true
                } label: {
                    HStack(spacing: 5) {
                        Text(store.currentModel)
                            .font(.system(size: 23, weight: .heavy, design: .rounded))
                        Image(systemName: "chevron.right")
                            .font(.system(size: 15, weight: .bold))
                            .opacity(0.46)
                    }
                    .foregroundStyle(.white)
                }
                .buttonStyle(.plain)

                Spacer(minLength: 8)

                iconPill(systemName: "square.and.pencil") {
                    store.newChat()
                    showSidebar = false
                }
            }

            HStack(spacing: 8) {
                ForEach(store.providers) { provider in
                    Button {
                        store.setProvider(provider.kind)
                    } label: {
                        Text(provider.name)
                            .font(.system(size: 12, weight: .bold, design: .rounded))
                            .foregroundStyle(store.currentProvider == provider.kind ? .white : .white.opacity(0.58))
                            .padding(.horizontal, 12)
                            .padding(.vertical, 7)
                            .background(
                                Capsule()
                                    .fill(store.currentProvider == provider.kind ? Color.white.opacity(0.16) : Color.white.opacity(0.08))
                            )
                    }
                    .buttonStyle(.plain)
                    .modifier(LiquidGlass())
                }
            }
        }
    }

    private var chatArea: some View {
        VStack(spacing: 14) {
            if store.currentConversation.messages.count > 1 {
                ScrollViewReader { reader in
                    ScrollView(showsIndicators: false) {
                        LazyVStack(spacing: 12) {
                            ForEach(store.currentConversation.messages) { message in
                                messageBubble(message)
                                    .id(message.id)
                            }
                            if store.isThinking {
                                thinkingBubble
                            }
                        }
                        .padding(.vertical, 8)
                    }
                    .onChange(of: store.currentConversation.messages.count) { _, _ in
                        if let last = store.currentConversation.messages.last?.id {
                            withAnimation(.easeOut(duration: 0.25)) {
                                reader.scrollTo(last, anchor: .bottom)
                            }
                        }
                    }
                }
                .frame(maxHeight: heightForMessages(height: UIScreen.main.bounds.height))
            } else {
                Spacer(minLength: 0)
                hero
                Spacer(minLength: 0)
            }
        }
    }

    private var hero: some View {
        VStack(spacing: 20) {
            Text("Use models from your computer")
                .font(.system(size: 30, weight: .black, design: .rounded))
                .foregroundStyle(.white)
                .multilineTextAlignment(.center)
                .frame(maxWidth: 620)

            Text("Link to LM Studio and run larger models remotely from your computer. End-to-end encrypted.")
                .font(.system(size: 23, weight: .bold, design: .rounded))
                .foregroundStyle(.white.opacity(0.42))
                .multilineTextAlignment(.center)
                .lineSpacing(3)
                .frame(maxWidth: 620)

            roundedButton("Try it", width: 220)
                .padding(.top, 6)
        }
        .padding(.top, 52)
    }

    private func bottomDock(width: CGFloat) -> some View {
        VStack(spacing: 12) {
            if store.isThinking {
                Text("Loading model...")
                    .font(.system(size: 17, weight: .bold, design: .rounded))
                    .foregroundStyle(.white.opacity(0.70))
                    .padding(.horizontal, 18)
                    .padding(.vertical, 9)
                    .background(Capsule().fill(Color.white.opacity(0.08)))
                    .modifier(LiquidGlass())
            }

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 14) {
                    ForEach(store.suggestionCards) { card in
                        suggestionCard(card)
                            .onTapGesture {
                                inputText = card.title + " " + card.subtitle
                            }
                    }
                }
                .padding(.horizontal, 12)
            }
            .frame(height: 118)
            .padding(.leading, 8)

            HStack(spacing: 12) {
                roundAction(systemName: "plus") {
                    showSidebar = true
                }

                TextField("", text: $inputText, prompt: Text("Ask anything").foregroundStyle(.white.opacity(0.34)))
                    .font(.system(size: 22, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 22)
                    .frame(height: 64)
                    .background(Capsule().fill(Color.white.opacity(0.12)))
                    .modifier(LiquidGlass())

                roundAction(systemName: "arrow.up") {
                    sendMessage()
                }
            }
            .padding(.horizontal, 10)
        }
        .padding(.bottom, 8)
    }

    private func sendMessage() {
        let trimmed = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        store.send(trimmed)
        inputText = ""
    }

    private func messageBubble(_ message: ChatMessage) -> some View {
        HStack {
            if message.role == .assistant {
                VStack(alignment: .leading, spacing: 8) {
                    Text(message.text)
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                        .foregroundStyle(.white.opacity(0.92))
                        .fixedSize(horizontal: false, vertical: true)
                    HStack(spacing: 18) {
                        iconTextButton(systemName: "hand.thumbsup") {}
                        iconTextButton(systemName: "hand.thumbsdown") {}
                        iconTextButton(systemName: "arrow.clockwise") { store.regenerateLastAnswer() }
                        iconTextButton(systemName: "doc.on.doc") {}
                        iconTextButton(systemName: "ellipsis") {}
                        Spacer()
                        iconTextButton(systemName: "speaker.wave.2") {}
                    }
                    .foregroundStyle(.white.opacity(0.84))
                    Text("Gemini - это ИИ. Он может ошибаться.")
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                        .foregroundStyle(.white.opacity(0.42))
                        .padding(.top, 4)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.leading, 12)
            } else {
                Spacer(minLength: 0)
                Text(message.text)
                    .font(.system(size: 21, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 14)
                    .background(Capsule().fill(Color.white.opacity(0.10)))
                    .modifier(LiquidGlass())
            }
        }
        .padding(.vertical, 4)
    }

    private var thinkingBubble: some View {
        HStack {
            Spacer(minLength: 0)
            HStack(spacing: 8) {
                ProgressView()
                    .tint(.white)
                Text(store.providerName() + " is thinking")
                    .font(.system(size: 15, weight: .bold, design: .rounded))
                    .foregroundStyle(.white.opacity(0.72))
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(Capsule().fill(Color.white.opacity(0.10)))
                .modifier(LiquidGlass())
        }
    }

    private func suggestionCard(_ card: SuggestionCard) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(card.title)
                .font(.system(size: 24, weight: .heavy, design: .rounded))
                .foregroundStyle(.white)
            Text(card.subtitle)
                .font(.system(size: 20, weight: .bold, design: .rounded))
                .foregroundStyle(.white.opacity(0.56))
        }
        .frame(width: 228, height: 108, alignment: .leading)
        .padding(.horizontal, 22)
        .padding(.vertical, 18)
        .background(RoundedRectangle(cornerRadius: 28, style: .continuous).fill(Color.white.opacity(0.14)))
        .modifier(LiquidGlass())
    }

    private func modelPickerCard(width: CGFloat) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("Select model")
                .font(.system(size: 24, weight: .bold, design: .rounded))
                .foregroundStyle(.white.opacity(0.48))
                .padding(.bottom, 28)

            ForEach(store.availableModels) { model in
                Button {
                    store.currentModel = model.name
                    showModelPicker = false
                } label: {
                    HStack {
                        if store.currentModel == model.name {
                            Image(systemName: "checkmark")
                                .font(.system(size: 22, weight: .bold))
                                .frame(width: 28)
                        } else {
                            Spacer().frame(width: 28)
                        }
                        VStack(alignment: .leading, spacing: 4) {
                            Text(model.name)
                                .font(.system(size: 27, weight: .heavy, design: .rounded))
                            if let subtitle = model.subtitle {
                                Text(subtitle)
                                    .font(.system(size: 18, weight: .bold, design: .rounded))
                                    .foregroundStyle(.white.opacity(0.42))
                            }
                        }
                        Spacer()
                    }
                    .foregroundStyle(.white)
                    .padding(.vertical, 22)
                }
                .buttonStyle(.plain)

                if model.id != store.availableModels.last?.id {
                    Rectangle()
                        .fill(Color.white.opacity(0.08))
                        .frame(height: 1)
                }
            }

            Divider()
                .background(Color.white.opacity(0.08))
                .padding(.vertical, 22)

            Button {
            } label: {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("LM Link")
                            .font(.system(size: 26, weight: .heavy, design: .rounded))
                        Text("Login required")
                            .font(.system(size: 18, weight: .bold, design: .rounded))
                            .foregroundStyle(.white.opacity(0.42))
                    }
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.system(size: 16, weight: .bold))
                        .opacity(0.55)
                }
                .foregroundStyle(.white)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 28)
        .padding(.vertical, 26)
        .frame(width: width)
        .background(
            RoundedRectangle(cornerRadius: 42, style: .continuous)
                .fill(Color(red: 0.15, green: 0.15, blue: 0.32).opacity(0.95))
                .overlay(
                    RoundedRectangle(cornerRadius: 42, style: .continuous)
                        .stroke(Color.white.opacity(0.20), lineWidth: 1)
                )
        )
        .modifier(LiquidGlass())
    }

    private var sidebarOverlay: some View {
        ZStack(alignment: .leading) {
            Color.black.opacity(0.44)
                .ignoresSafeArea()
                .onTapGesture { showSidebar = false }

            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    Text("Chats")
                        .font(.system(size: 30, weight: .heavy, design: .rounded))
                        .foregroundStyle(.white)
                    Spacer()
                    Button {
                        store.newChat()
                    } label: {
                        Image(systemName: "square.and.pencil")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundStyle(.white)
                            .frame(width: 42, height: 42)
                            .background(Circle().fill(Color.white.opacity(0.10)))
                            .modifier(LiquidGlass())
                    }
                    .buttonStyle(.plain)
                }

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 10) {
                        ForEach(store.conversations) { conversation in
                            Button {
                                store.select(conversation.id)
                                showSidebar = false
                            } label: {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(conversation.title)
                                        .font(.system(size: 22, weight: .bold, design: .rounded))
                                        .foregroundStyle(.white)
                                        .lineLimit(1)
                                    Text(conversation.preview)
                                        .font(.system(size: 16, weight: .bold, design: .rounded))
                                        .foregroundStyle(.white.opacity(0.42))
                                        .lineLimit(1)
                                }
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 16)
                                .background(
                                    RoundedRectangle(cornerRadius: 22, style: .continuous)
                                        .fill(conversation.id == store.currentConversation.id ? Color.white.opacity(0.14) : Color.white.opacity(0.08))
                                )
                                .modifier(LiquidGlass())
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
            .padding(.top, 20)
            .padding(.horizontal, 16)
            .padding(.bottom, 18)
            .frame(width: min(UIScreen.main.bounds.width * 0.84, 340))
            .frame(maxHeight: .infinity, alignment: .top)
            .background(
                RoundedRectangle(cornerRadius: 34, style: .continuous)
                    .fill(Color(red: 0.10, green: 0.10, blue: 0.11).opacity(0.99))
            )
            .padding(.leading, 8)
            .padding(.top, 44)
        }
    }

    private var settingsSheet: some View {
        ZStack {
            Color.black.opacity(0.40)
                .ignoresSafeArea()
                .onTapGesture { showSettings = false }
            ScrollView(showsIndicators: false) {
                VStack(spacing: 16) {
                    sheetHeader(title: "Settings") {
                        showSettings = false
                    }

                    sheetSection(title: "App") {
                        settingsRow(icon: "shippingbox.fill", title: "Manage models")
                        settingsRow(icon: "link", title: "LM Link", badge: "New")
                        settingsRow(icon: "person.crop.circle.fill", title: "Personalization") { showPersonalization = true }
                        toggleRow(icon: "keyboard", title: "Show keyboard on launch", isOn: .constant(true))
                        dangerRow(icon: "trash.fill", title: "Delete conversation history")
                    }

                    sheetSection(title: "Providers") {
                        providerRow(kind: .openAI, title: "OpenAI", subtitle: "Best quality")
                        providerRow(kind: .openRouter, title: "OpenRouter", subtitle: "Many free models")
                        providerRow(kind: .ollama, title: "Ollama", subtitle: "Local models")
                        providerRow(kind: .localMock, title: "Local demo", subtitle: "No key needed")
                    }

                    sheetSection(title: "About") {
                        settingsRow(icon: "doc.text.fill", title: "Term & Conditions")
                        settingsRow(icon: "lock.fill", title: "Privacy Policy")
                        settingsRow(icon: "text.book.closed.fill", title: "Licenses")
                        settingsRow(icon: "info.circle.fill", title: "Version 1.57.0")
                    }

                    sheetSection(title: "More") {
                        settingsRow(icon: "square.and.arrow.up.fill", title: "Share the app (support us)")
                        settingsRow(icon: "xmark", title: "Follow us on X")
                    }

                    Text("Made with love in France")
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                        .foregroundStyle(.white.opacity(0.88))
                        .padding(.top, 14)
                }
                .padding(.horizontal, 18)
                .padding(.top, 10)
                .padding(.bottom, 26)
            }
            .background(
                RoundedRectangle(cornerRadius: 46, style: .continuous)
                    .fill(Color(red: 0.12, green: 0.12, blue: 0.13).opacity(0.99))
            )
            .padding(.top, 44)
        }
    }

    private var personalizationSheet: some View {
        ZStack {
            Color.black.opacity(0.44)
                .ignoresSafeArea()
                .onTapGesture { showPersonalization = false }
            ScrollView(showsIndicators: false) {
                VStack(spacing: 18) {
                    sheetHeader(title: "Personalization", leadingSymbol: "chevron.left", trailingTitle: "Save", trailingEnabled: false) {
                        showPersonalization = false
                    }

                    HStack {
                        Text("Enable customization")
                            .font(.system(size: 26, weight: .bold, design: .rounded))
                            .foregroundStyle(.white)
                        Spacer()
                        Toggle("", isOn: $customizationEnabled)
                            .labelsHidden()
                            .tint(.green)
                    }
                    .padding(.horizontal, 24)
                    .padding(.vertical, 20)
                    .background(
                        RoundedRectangle(cornerRadius: 34, style: .continuous)
                            .fill(Color.white.opacity(0.09))
                    )

                    VStack(alignment: .leading, spacing: 16) {
                        Text("Custom Instructions")
                            .font(.system(size: 28, weight: .bold, design: .rounded))
                            .foregroundStyle(.white.opacity(0.72))
                        TextEditor(text: $instructions)
                            .scrollContentBackground(.hidden)
                            .foregroundStyle(.white)
                            .font(.system(size: 22, weight: .semibold, design: .rounded))
                            .padding(16)
                            .frame(height: 210)
                            .background(
                                RoundedRectangle(cornerRadius: 28, style: .continuous)
                                    .fill(Color.white.opacity(0.08))
                            )
                        HStack {
                            Spacer()
                            Text("0/1 000")
                                .font(.system(size: 18, weight: .bold))
                                .foregroundStyle(.white.opacity(0.45))
                        }
                    }

                    VStack(alignment: .leading, spacing: 14) {
                        HStack {
                            Text("Temperature")
                                .font(.system(size: 28, weight: .bold, design: .rounded))
                            Spacer()
                            Text("Default")
                                .font(.system(size: 24, weight: .bold, design: .rounded))
                                .foregroundStyle(.white.opacity(0.52))
                        }
                        Text("Controls randomness in responses. Lower values make the AI more focused and deterministic, while higher values make it more creative and unpredictable.")
                            .font(.system(size: 20, weight: .semibold, design: .rounded))
                            .foregroundStyle(.white.opacity(0.46))
                            .lineSpacing(4)
                    }
                    .padding(18)
                    .background(
                        RoundedRectangle(cornerRadius: 30, style: .continuous)
                            .fill(Color.white.opacity(0.08))
                    )
                }
                .padding(.horizontal, 18)
                .padding(.top, 10)
                .padding(.bottom, 24)
            }
            .background(
                RoundedRectangle(cornerRadius: 46, style: .continuous)
                    .fill(Color(red: 0.12, green: 0.12, blue: 0.13).opacity(0.99))
            )
            .padding(.top, 44)
        }
    }

    private func sheetHeader(title: String, leadingSymbol: String = "xmark", trailingTitle: String? = nil, trailingEnabled: Bool = true, leadingAction: @escaping () -> Void) -> some View {
        HStack {
            Button(action: leadingAction) {
                Image(systemName: leadingSymbol)
                    .font(.system(size: 22, weight: .bold))
                    .foregroundStyle(.white)
                    .frame(width: 54, height: 54)
                    .background(Circle().fill(Color.white.opacity(0.08)))
                    .modifier(LiquidGlass())
            }
            .buttonStyle(.plain)

            Spacer()

            Text(title)
                .font(.system(size: 28, weight: .heavy, design: .rounded))
                .foregroundStyle(.white)

            Spacer()

            if let trailingTitle {
                Text(trailingTitle)
                    .font(.system(size: 22, weight: .bold, design: .rounded))
                    .foregroundStyle(trailingEnabled ? .white : .white.opacity(0.30))
                    .frame(width: 116, height: 54)
                    .background(Capsule().fill(Color.white.opacity(0.08)))
                    .modifier(LiquidGlass())
            } else {
                Color.clear.frame(width: 54, height: 54)
            }
        }
        .padding(.bottom, 18)
    }

    private func sheetSection<Content: View>(title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.system(size: 26, weight: .heavy, design: .rounded))
                .foregroundStyle(.white.opacity(0.50))
                .padding(.leading, 18)
            VStack(spacing: 0) {
                content()
            }
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 34, style: .continuous)
                    .fill(Color.white.opacity(0.08))
            )
        }
    }

    private func settingsRow(icon: String, title: String, badge: String? = nil, action: (() -> Void)? = nil) -> some View {
        VStack(spacing: 0) {
            Button {
                action?()
            } label: {
                HStack(spacing: 14) {
                    Image(systemName: icon)
                        .font(.system(size: 23, weight: .bold))
                        .frame(width: 30)
                    Text(title)
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                    if let badge {
                        Text(badge)
                            .font(.system(size: 16, weight: .bold, design: .rounded))
                            .foregroundStyle(.green)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 5)
                            .background(Capsule().fill(Color.green.opacity(0.18)))
                    }
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(.white.opacity(0.32))
                }
                .foregroundStyle(.white)
                .padding(.horizontal, 18)
                .padding(.vertical, 18)
            }
            .buttonStyle(.plain)
            Divider().overlay(Color.white.opacity(0.08)).padding(.leading, 56)
        }
    }

    private func toggleRow(icon: String, title: String, isOn: Binding<Bool>) -> some View {
        VStack(spacing: 0) {
            HStack(spacing: 14) {
                Image(systemName: icon)
                    .font(.system(size: 23, weight: .bold))
                    .frame(width: 30)
                Text(title)
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                Spacer()
                Toggle("", isOn: isOn)
                    .labelsHidden()
                    .tint(.green)
            }
            .foregroundStyle(.white)
            .padding(.horizontal, 18)
            .padding(.vertical, 18)
            Divider().overlay(Color.white.opacity(0.08)).padding(.leading, 56)
        }
    }

    private func dangerRow(icon: String, title: String) -> some View {
        Button {} label: {
            HStack(spacing: 14) {
                Image(systemName: icon)
                    .font(.system(size: 23, weight: .bold))
                    .frame(width: 30)
                Text(title)
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                Spacer()
            }
            .foregroundStyle(.red)
            .padding(.horizontal, 18)
            .padding(.vertical, 18)
        }
        .buttonStyle(.plain)
    }

    private func providerRow(kind: ProviderKind, title: String, subtitle: String) -> some View {
        VStack(spacing: 0) {
            Button {
                store.setProvider(kind)
            } label: {
                HStack(spacing: 14) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(title)
                            .font(.system(size: 24, weight: .bold, design: .rounded))
                        Text(subtitle)
                            .font(.system(size: 16, weight: .bold, design: .rounded))
                            .foregroundStyle(.white.opacity(0.42))
                    }
                    Spacer()
                    if store.currentProvider == kind {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 22, weight: .bold))
                            .foregroundStyle(.green)
                    }
                }
                .foregroundStyle(.white)
                .padding(.horizontal, 18)
                .padding(.vertical, 18)
            }
            .buttonStyle(.plain)
            Divider().overlay(Color.white.opacity(0.08)).padding(.leading, 56)
        }
    }

    private func iconPill(systemName: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.system(size: 22, weight: .heavy))
                .foregroundStyle(.white)
                .frame(width: 82, height: 58)
                .background(Capsule().fill(Color.white.opacity(0.08)))
                .modifier(LiquidGlass())
        }
        .buttonStyle(.plain)
    }

    private func roundAction(systemName: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.system(size: 21, weight: .black))
                .foregroundStyle(.white.opacity(0.90))
                .frame(width: 62, height: 62)
                .background(Circle().fill(Color.white.opacity(0.12)))
                .modifier(LiquidGlass())
        }
        .buttonStyle(.plain)
    }

    private func roundedButton(_ title: String, width: CGFloat) -> some View {
        Text(title)
            .font(.system(size: 30, weight: .heavy, design: .rounded))
            .foregroundStyle(.white)
            .frame(width: width, height: 54)
            .background(Capsule().fill(Color.white.opacity(0.08)))
            .modifier(LiquidGlass())
    }

    private func iconTextButton(systemName: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.system(size: 20, weight: .semibold))
        }
        .buttonStyle(.plain)
    }

    private func heightForMessages(height: CGFloat) -> CGFloat {
        max(220, min(420, height * 0.44))
    }
}

struct LiquidGlass: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background(.ultraThinMaterial)
            .overlay(
                RoundedRectangle(cornerRadius: 28, style: .continuous)
                    .stroke(Color.white.opacity(0.18), lineWidth: 1)
            )
            .shadow(color: Color.black.opacity(0.22), radius: 24, x: 0, y: 14)
    }
}
