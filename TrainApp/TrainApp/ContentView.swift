import SwiftUI
import MapKit
import CoreLocation
import PassKit
import UniformTypeIdentifiers
import MessageUI

struct ContentView: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.colorScheme) private var systemColorScheme
    @AppStorage("preferredAppearance") private var preferredAppearance = "dark"
    @AppStorage("appLanguage") private var appLanguageRawValue = AppLanguage.en.rawValue
    @AppStorage("selectedCurrency") private var selectedCurrencyRawValue = AppCurrency.gbp.rawValue
    @AppStorage("fontScale") private var fontScale: Double = 1.0
    @AppStorage("isLoggedIn") private var isLoggedIn = false
    @AppStorage("lastLoginTimestamp") private var lastLoginTimestamp: Double = 0
    @AppStorage("username") private var username = "alextraveller"
    @AppStorage("password") private var storedPassword = "Password123"
    @StateObject private var locationManager = UserLocationManager()
    @State private var selectedTab: AppTab = .home
    @State private var originId: Int?
    @State private var destinationId: Int?
    @State private var transportMode: TransportMode = .train
    @State private var useBFS = false
    @State private var lastResult: RouteResult?
    @State private var lastResultError: String?
    @State private var searchText = ""
    @State private var taxiPulse = false
    @State private var plannedRoute: PlannedRoute?
    @State private var showPlannedRoute = false
    @State private var savedTrips: [SavedTrip] = []
    @State private var savedStops: [SavedStop] = []
    @State private var notifications: [AccountNotification] = []
    @AppStorage("fullName") private var fullName = "Alex Traveller"
    @AppStorage("email") private var email = "alex.traveller@example.com"
    @AppStorage("phone") private var phone = "+44 7700 900000"
    @State private var showWelcomeSplash = true
    @State private var splashTrainOffset: CGFloat = -220
    @State private var splashBusOffset: CGFloat = 220
    @State private var splashTrainTilt: Double = -24
    @State private var splashBusTilt: Double = 24
    @State private var splashVehiclesOpacity: Double = 0.0
    @State private var splashVehiclesScale: CGFloat = 1.0
    @State private var splashNexoOpacity: Double = 0.0
    @State private var splashNexoScale: CGFloat = 0.88
    @State private var splashImpactOpacity: Double = 0.0
    @State private var splashOverlayOpacity: Double = 1.0
    @State private var showSMSComposer = false
    @State private var smsAlertMessage: String?
    @State private var smsBody = ""
    @State private var smsButtonOffset: CGSize = .zero
    @State private var smsButtonDrag: CGSize = .zero
    @State private var showRegister = false
    @State private var showForgotPasswordFlow = false
    @State private var loginIdentifier = ""
    @State private var loginPassword = ""
    @State private var registerEmail = ""
    @State private var registerPassword = ""
    @State private var registerPasswordConfirm = ""
    @State private var registerUsername = ""
    @State private var registerPhonePrefix = "+44"
    @State private var registerPhoneNumber = ""
    @State private var authErrorMessage: String?
    @State private var showLoginPassword = false
    @State private var showRegisterPassword = false
    @State private var showRegisterPasswordConfirm = false
    @State private var recoveryStep: RecoveryStep = .email
    @State private var recoveryEmail = ""
    @State private var recoverySentCode = ""
    @State private var recoveryCodeInput = ""
    @State private var recoveryNewPassword = ""
    @State private var recoveryRepeatPassword = ""
    @State private var recoveryMessage: String?
    @State private var showPassImporter = false
    @State private var walletPresentation: WalletPassPresentation?
    @State private var walletMessage: String?
    @State private var departuresMessage: String?
    @State private var selectedMapStationId: Int?
    @State private var mapDepartureMode: TransportMode = .train
    @State private var mapPanelExpanded = false
    @State private var mapLiveTrackContext: MapLiveTrackContext?
    @State private var showDirectionsSheet = false
    @State private var directionsStation: Station?
    @State private var directionsMode: TransportMode = .train
    @State private var showTrackSheet = false
    @State private var walkFromQuery = ""
    @State private var walkToQuery = ""
    @State private var walkRoute: MKRoute?
    @State private var walkRouteError: String?
    @State private var walkMapPosition: MapCameraPosition = .automatic
    @FocusState private var walkFocusedField: WalkField?
    @State private var ticketReference = "TR-8829"
    @State private var ticketTravelDate = Date()
    @State private var ticketDurationMins = 42
    @State private var ticketRailcardUsed = true
    @State private var selectedTicketIndex = 0
    @State private var mapCurrentRegion = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 53.90, longitude: -2.95),
        span: MKCoordinateSpan(latitudeDelta: 0.85, longitudeDelta: 1.0)
    )
    @State private var mapPosition: MapCameraPosition = .region(
        MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: 53.90, longitude: -2.95),
            span: MKCoordinateSpan(latitudeDelta: 0.85, longitudeDelta: 1.0)
        )
    )
    private let placesService = PlacesService()
    @State private var placesResults: [Place] = []
    @State private var placesCategories: [PlaceCategory] = []
    @State private var selectedPlaceCategory: String = "all"
    @State private var placesQuery = ""
    @State private var placesMode: PlacesSearchMode = .keyword
    @State private var placesLoading = false
    @State private var placesErrorMessage: String?
    @State private var selectedPlaceForDetail: Place?
    @State private var hasBootstrappedPlaces = false

    var filteredStations: [Station] {
        guard !searchText.isEmpty else { return appState.stations }
        return appState.stations.filter {
            $0.name.localizedCaseInsensitiveContains(searchText) ||
            $0.code.localizedCaseInsensitiveContains(searchText)
        }
    }

    private var preferredColorScheme: ColorScheme? {
        switch preferredAppearance {
        case "light": return .light
        case "dark": return .dark
        default: return nil
        }
    }

    private var selectedMapStation: Station? {
        guard let selectedMapStationId else { return nil }
        return appState.mapStations.first(where: { $0.id == selectedMapStationId })
    }

    private var appLanguage: AppLanguage {
        AppLanguage(rawValue: appLanguageRawValue) ?? .en
    }

    private var usesLightPalette: Bool {
        switch preferredAppearance {
        case "light":
            return true
        case "dark":
            return false
        default:
            return systemColorScheme == .light
        }
    }

    private var primaryTextColor: Color {
        usesLightPalette ? Color.black : Color.white
    }

    private var secondaryTextColor: Color {
        usesLightPalette ? Color.black.opacity(0.62) : Color.secondary
    }

    private var cardFillColor: Color {
        usesLightPalette ? Color.white.opacity(0.96) : Color.white.opacity(0.08)
    }

    private var cardStrokeColor: Color {
        usesLightPalette ? Color.black.opacity(0.10) : Color.white.opacity(0.06)
    }

    private var innerFillColor: Color {
        usesLightPalette ? Color.black.opacity(0.05) : Color.white.opacity(0.05)
    }

    private var contentSizeCategory: ContentSizeCategory {
        switch fontScale {
        case ..<0.95: return .medium
        case ..<1.05: return .large
        case ..<1.15: return .extraLarge
        case ..<1.25: return .extraExtraLarge
        default: return .extraExtraExtraLarge
        }
    }

    private func t(_ key: L.Key) -> String {
        L.text(key, lang: appLanguage)
    }

    private var defaultMapRegion: MKCoordinateRegion {
        MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: 53.90, longitude: -2.95),
            span: MKCoordinateSpan(latitudeDelta: 0.85, longitudeDelta: 1.0)
        )
    }

    private var shouldShowLogin: Bool {
        let gracePeriod: TimeInterval = 60 * 60 * 24 * 7
        guard isLoggedIn else { return true }
        guard lastLoginTimestamp > 0 else { return true }
        let elapsed = Date().timeIntervalSince1970 - lastLoginTimestamp
        return elapsed > gracePeriod
    }

    var body: some View {
        ZStack {
            if !showWelcomeSplash {
                if shouldShowLogin {
                    loginScreen
                } else {
                    TabView(selection: $selectedTab) {
                        homeScreen
                            .tabItem {
                                Label(t(.home), systemImage: "house.fill")
                            }
                            .tag(AppTab.home)

                        mapScreen
                            .tabItem {
                                Label(t(.map), systemImage: "map.fill")
                            }
                            .tag(AppTab.map)

                        ticketsScreen
                            .tabItem {
                                Label(t(.tickets), systemImage: "ticket.fill")
                            }
                            .tag(AppTab.tickets)

                        accountScreen
                            .tabItem {
                                Label(t(.account), systemImage: "person.fill")
                            }
                            .tag(AppTab.account)
                    }
                }
            }

            if showWelcomeSplash {
                splashOverlay
                    .transition(.opacity)
                    .zIndex(10)
            }
        }
        .tint(.blue)
        .toolbarBackground(.visible, for: .tabBar)
        .toolbarBackground(usesLightPalette ? Color.white : Color(red: 0.02, green: 0.07, blue: 0.14), for: .tabBar)
        .toolbarColorScheme(usesLightPalette ? .light : .dark, for: .tabBar)
        .environment(\.sizeCategory, contentSizeCategory)
        .toolbarColorScheme(usesLightPalette ? .light : .dark, for: .navigationBar)
        .preferredColorScheme(preferredColorScheme)
        .onAppear {
            locationManager.requestPermissionIfNeeded()
            startSplashAnimation()
            Task { await bootstrapPlacesIfNeeded() }
        }
        .fileImporter(
            isPresented: $showPassImporter,
            allowedContentTypes: [UTType(filenameExtension: "pkpass") ?? .data]
        ) { result in
            handlePassImport(result: result)
        }
        .sheet(item: $walletPresentation) { presentation in
            AddPassesSheet(passes: presentation.passes) {
                walletMessage = t(.walletSuccess)
                notifications.insert(
                    AccountNotification(
                        title: t(.appleWallet),
                        subtitle: t(.walletSuccess)
                    ),
                    at: 0
                )
                walletPresentation = nil
            }
        }
        .alert(t(.appleWallet), isPresented: Binding(
            get: { walletMessage != nil },
            set: { if !$0 { walletMessage = nil } }
        )) {
            Button(t(.ok), role: .cancel) {}
        } message: {
            Text(walletMessage ?? "")
        }
        .alert(t(.departures), isPresented: Binding(
            get: { departuresMessage != nil },
            set: { if !$0 { departuresMessage = nil } }
        )) {
            Button(t(.ok), role: .cancel) {}
        } message: {
            Text(departuresMessage ?? "")
        }
        .alert("SMS", isPresented: Binding(
            get: { smsAlertMessage != nil },
            set: { if !$0 { smsAlertMessage = nil } }
        )) {
            Button(t(.ok), role: .cancel) {}
        } message: {
            Text(smsAlertMessage ?? "")
        }
        .sheet(isPresented: $showDirectionsSheet) {
            if let station = directionsStation {
                DirectionsSheet(
                    station: station,
                    mode: $directionsMode,
                    userLocation: locationManager.location?.coordinate
                )
            }
        }
        .sheet(isPresented: $showTrackSheet) {
            TrackSheet(
                stations: appState.stations,
                mapping: appState.mapping,
                ticket: selectedTicket,
                forcedStationIds: nil,
                serviceTitle: nil,
                serviceOperator: nil,
                showFavoriteButton: false,
                isFavorite: false,
                onToggleFavorite: nil
            )
        }
        .sheet(item: $mapLiveTrackContext) { context in
            let trip = savedTrip(for: context)
            TrackSheet(
                stations: appState.stations,
                mapping: appState.mapping,
                ticket: nil,
                forcedStationIds: context.stationIds,
                serviceTitle: context.title,
                serviceOperator: context.operatorName,
                showFavoriteButton: true,
                isFavorite: savedTrips.contains(where: { $0.key == trip.key }),
                onToggleFavorite: {
                    toggleSavedMapLiveTrip(trip)
                }
            )
        }
        .sheet(item: $selectedPlaceForDetail) { place in
            PlaceDetailSheet(
                place: place,
                usesLightPalette: usesLightPalette,
                isAlreadySaved: isPlaceSavedAsStop(place),
                onDirections: {
                    openDirections(to: place)
                },
                onAddStop: {
                    toggleSavedStopFromPlace(place)
                },
                onPlanViaHere: {
                    planViaPlace(place)
                }
            )
        }
        .sheet(isPresented: $showSMSComposer) {
            MessageComposeView(recipients: nil, body: smsBody) { _ in
                showSMSComposer = false
            }
            .ignoresSafeArea()
        }
        .sheet(isPresented: $showForgotPasswordFlow) {
            forgotPasswordScreen
        }
    }

    private var splashOverlay: some View {
        ZStack {
            LinearGradient(
                colors: [Color(red: 0.03, green: 0.11, blue: 0.28), Color.black],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            GeometryReader { geo in
                ZStack {
                    Circle()
                        .fill(Color.white.opacity(0.28))
                        .frame(width: 120, height: 120)
                        .blur(radius: 14)
                        .scaleEffect(splashImpactOpacity > 0 ? 1.15 : 0.72)
                        .opacity(splashImpactOpacity)

                    Capsule()
                        .fill(Color.blue.opacity(0.18))
                        .frame(width: 220, height: 20)
                        .blur(radius: 10)
                        .opacity(splashVehiclesOpacity)

                    HStack(spacing: 52) {
                        splashVehicle(symbol: "tram.fill", tint: .cyan, tilt: splashTrainTilt)
                            .offset(x: splashTrainOffset)

                        splashVehicle(symbol: "bus.fill", tint: .blue, tilt: splashBusTilt)
                            .offset(x: splashBusOffset)
                    }
                    .opacity(splashVehiclesOpacity)
                    .scaleEffect(splashVehiclesScale)

                    Text("Nexo")
                        .font(.system(size: 56, weight: .heavy, design: .rounded))
                        .foregroundStyle(.white)
                        .shadow(color: .blue.opacity(0.4), radius: 14)
                        .opacity(splashNexoOpacity)
                        .scaleEffect(splashNexoScale)
                }
                .frame(width: geo.size.width, height: geo.size.height)
            }
        }
        .opacity(splashOverlayOpacity)
    }

    private func startSplashAnimation() {
        guard showWelcomeSplash else { return }

        splashTrainOffset = -220
        splashBusOffset = 220
        splashTrainTilt = -24
        splashBusTilt = 24
        splashVehiclesOpacity = 0.0
        splashVehiclesScale = 1.0
        splashNexoOpacity = 0.0
        splashNexoScale = 0.88
        splashImpactOpacity = 0.0
        splashOverlayOpacity = 1.0

        withAnimation(.easeOut(duration: 0.35)) {
            splashVehiclesOpacity = 1.0
        }

        withAnimation(.interpolatingSpring(stiffness: 90, damping: 12).delay(0.1)) {
            splashTrainOffset = -10
            splashBusOffset = 10
            splashTrainTilt = -6
            splashBusTilt = 6
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.82) {
            withAnimation(.easeOut(duration: 0.16)) {
                splashImpactOpacity = 1.0
            }
            withAnimation(.easeIn(duration: 0.20).delay(0.10)) {
                splashImpactOpacity = 0.0
            }

            withAnimation(.easeInOut(duration: 0.28)) {
                splashVehiclesScale = 0.72
                splashVehiclesOpacity = 0.0
            }
            withAnimation(.spring(response: 0.42, dampingFraction: 0.72).delay(0.06)) {
                splashNexoOpacity = 1.0
                splashNexoScale = 1.0
            }
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.8) {
            withAnimation(.easeInOut(duration: 0.35)) {
                splashOverlayOpacity = 0.0
            }
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 2.15) {
            withAnimation(.easeOut(duration: 0.2)) {
                showWelcomeSplash = false
            }
        }
    }

    private func splashVehicle(symbol: String, tint: Color, tilt: Double) -> some View {
        ZStack {
            Image(systemName: symbol)
                .font(.system(size: 42, weight: .bold))
                .foregroundStyle(Color.black.opacity(0.40))
                .offset(x: 8, y: 8)
                .blur(radius: 2)

            Image(systemName: symbol)
                .font(.system(size: 42, weight: .bold))
                .foregroundStyle(tint)
                .symbolRenderingMode(.palette)
                .rotation3DEffect(.degrees(tilt), axis: (x: 0, y: 1, z: 0), perspective: 0.6)
                .shadow(color: tint.opacity(0.35), radius: 12, x: 0, y: 8)
        }
    }

    private var homeScreen: some View {
        return NavigationStack {
            ZStack(alignment: .bottomLeading) {
                screenGradient
                ScrollView {
                    VStack(spacing: 14) {
                        homeBrandLogo
                        welcomeCard
                        searchAllTrainsCard
                        transportModeCard
                        if transportMode == .taxi {
                            taxiCard
                        } else if transportMode == .train || transportMode == .bus {
                            nearbyStopMapCard
                        } else if transportMode == .walk {
                            walkPlannerCard
                        }
                        if let err = lastResultError {
                            messageCard(text: err, color: .red)
                        }
                        if let appError = appState.errorMessage {
                            messageCard(text: appError, color: .red)
                        }
                        experiencesCard
                    }
                    .padding(.horizontal, 14)
                    .padding(.bottom, 24)
                }
                .scrollIndicators(.hidden)

                smsQuickButton
            }
            .toolbar(.hidden, for: .navigationBar)
            .navigationDestination(isPresented: $showPlannedRoute) {
                if let plan = plannedRoute {
                    PlannedRouteScreen(plan: plan, mapping: appState.mapping, language: appLanguage)
                } else {
                    EmptyView()
                }
            }
        }
    }

    private var loginScreen: some View {
        ZStack {
            screenGradient
            ScrollView {
                VStack(spacing: 18) {
                    homeBrandLogo

                    VStack(alignment: .leading, spacing: 6) {
                        Text("Nexo")
                            .font(.largeTitle.weight(.bold))
                            .foregroundStyle(primaryTextColor)
                        Text(showRegister ? t(.registerSubtitle) : t(.loginSubtitle))
                            .font(.subheadline)
                            .foregroundStyle(secondaryTextColor)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)

                    VStack(spacing: 16) {
                        if showRegister {
                            authField(title: t(.username), text: $registerUsername, icon: "person.fill")
                            authField(title: t(.email), text: $registerEmail, icon: "envelope.fill", keyboard: .emailAddress)
                                .textInputAutocapitalization(.never)
                                .autocorrectionDisabled(true)
                            HStack(spacing: 12) {
                                Picker("", selection: $registerPhonePrefix) {
                                    ForEach(phonePrefixes, id: \.code) { item in
                                        Text("\(item.flag) \(item.code) \(item.label)")
                                            .tag(item.code)
                                    }
                                }
                                .pickerStyle(.menu)
                                .frame(width: 140)
                                .padding(.vertical, 12)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(innerFillColor)
                                )

                                authField(title: t(.phoneNumber), text: $registerPhoneNumber, icon: "phone.fill", keyboard: .phonePad)
                            }
                            authPasswordField(title: t(.password), text: $registerPassword, icon: "lock.fill", isVisible: $showRegisterPassword)
                                .padding(.top, 4)
                            authPasswordField(title: t(.repeatPassword), text: $registerPasswordConfirm, icon: "lock.fill", isVisible: $showRegisterPasswordConfirm)
                        } else {
                            authField(title: t(.usernameOrEmail), text: $loginIdentifier, icon: "person.crop.circle")
                                .textInputAutocapitalization(.never)
                                .autocorrectionDisabled(true)
                            authPasswordField(title: t(.password), text: $loginPassword, icon: "lock.fill", isVisible: $showLoginPassword)
                        }

                        if let authErrorMessage {
                            Text(authErrorMessage)
                                .font(.caption)
                                .foregroundStyle(.red)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                    }
                    .padding(16)
                    .background(cardBackground)

                    Button {
                        if showRegister {
                            performRegister()
                        } else {
                            performLogin()
                        }
                    } label: {
                        Text(showRegister ? t(.createAccount) : t(.logIn))
                            .font(.headline.weight(.semibold))
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(
                                RoundedRectangle(cornerRadius: 14)
                                    .fill(Color.blue)
                            )
                    }
                    .padding(.horizontal, 14)

                    VStack(spacing: 8) {
                        Button {
                            withAnimation(.easeInOut) {
                                showRegister.toggle()
                                authErrorMessage = nil
                            }
                        } label: {
                            Text(showRegister ? t(.alreadyHaveAccount) : t(.newHereRegister))
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(.blue)
                        }
                        if !showRegister {
                            Button {
                                resetRecoveryFlow()
                                showForgotPasswordFlow = true
                            } label: {
                                Label("Forgot password?", systemImage: "key.fill")
                                    .font(.subheadline.weight(.semibold))
                                    .foregroundStyle(.cyan)
                            }
                        }
                    }
                    .padding(.bottom, 24)
                }
                .padding(.horizontal, 18)
                .padding(.top, 8)
            }
        }
        .toolbar(.hidden, for: .navigationBar)
    }

    private var welcomeCard: some View {
        HStack {
            Circle()
                .fill(usesLightPalette ? Color.black.opacity(0.08) : Color.white.opacity(0.12))
                .frame(width: 40, height: 40)
                .overlay {
                    Image(systemName: "person.fill")
                        .foregroundStyle(usesLightPalette ? .black : .white)
                }

            VStack(alignment: .leading, spacing: 2) {
                Text(t(.welcomeBack))
                    .font(.caption)
                    .foregroundStyle(secondaryTextColor)
                Text(fullName)
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(primaryTextColor)
            }

            Spacer()
            NavigationLink {
                SettingsScreen(
                    preferredAppearance: $preferredAppearance,
                    appLanguageRawValue: $appLanguageRawValue,
                    selectedCurrencyRawValue: $selectedCurrencyRawValue,
                    fullName: $fullName,
                    username: $username,
                    email: $email,
                    phone: $phone,
                    fontScale: $fontScale
                )
            } label: {
                Image(systemName: "gearshape.fill")
                    .font(.title2)
                    .foregroundStyle(secondaryTextColor)
                    .frame(width: 36, height: 36)
                    .background(
                        Circle().fill(usesLightPalette ? Color.black.opacity(0.06) : Color.white.opacity(0.06))
                    )
            }
            .buttonStyle(.plain)
        }
        .padding()
        .background(cardBackground)
    }

    private var homeBrandLogo: some View {
        Image("nexoLogo")
            .resizable()
            .renderingMode(.original)
            .interpolation(.high)
            .scaledToFit()
            .frame(maxWidth: .infinity)
            .frame(height: 120)
            .padding(.top, 6)
            .padding(.bottom, 2)
    }

    private var searchAllTrainsCard: some View {
        NavigationLink {
            SearchTrainsScreen(
                stations: appState.stations,
                language: appLanguage,
                selectedCurrencyRawValue: selectedCurrencyRawValue,
                savedTrips: $savedTrips
            )
        } label: {
            HStack(spacing: 10) {
                Image(systemName: "magnifyingglass")
                    .font(.headline)
                    .foregroundStyle(.blue)
                    .frame(width: 24)

                Text(t(.searchAllTrains))
                    .font(.headline)
                    .foregroundStyle(primaryTextColor)

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(secondaryTextColor)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(innerFillColor)
            )
        }
        .buttonStyle(.plain)
        .padding()
        .background(cardBackground)
    }

    private var smsQuickButton: some View {
        Button {
            triggerSMSNotification()
        } label: {
            HStack(spacing: 8) {
                Image(systemName: "bubble.left.and.bubble.right.fill")
                    .font(.headline)
                Text("SMS")
                    .font(.subheadline.weight(.semibold))
            }
            .foregroundStyle(.white)
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .background(
                Capsule()
                    .fill(Color.blue.opacity(0.95))
                    .shadow(color: Color.blue.opacity(0.35), radius: 10, x: 0, y: 6)
            )
        }
        .buttonStyle(.plain)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
        .padding(.top, 16)
        .padding(.trailing, 18)
        .offset(x: smsButtonOffset.width + smsButtonDrag.width, y: smsButtonOffset.height + smsButtonDrag.height)
        .gesture(
            DragGesture()
                .onChanged { value in
                    smsButtonDrag = value.translation
                }
                .onEnded { value in
                    smsButtonOffset.width += value.translation.width
                    smsButtonOffset.height += value.translation.height
                    smsButtonDrag = .zero
                }
        )
    }

    private func authField(title: String, text: Binding<String>, icon: String, keyboard: UIKeyboardType = .default) -> some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .foregroundStyle(.blue)
                .frame(width: 24)
            TextField(title, text: text)
                .keyboardType(keyboard)
                .foregroundStyle(primaryTextColor)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(innerFillColor)
        )
    }

    private func authSecureField(title: String, text: Binding<String>, icon: String) -> some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .foregroundStyle(.blue)
                .frame(width: 24)
            SecureField(title, text: text)
                .foregroundStyle(primaryTextColor)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(innerFillColor)
        )
    }

    private func authPasswordField(title: String, text: Binding<String>, icon: String, isVisible: Binding<Bool>) -> some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .foregroundStyle(.blue)
                .frame(width: 24)
            if isVisible.wrappedValue {
                TextField(title, text: text)
                    .foregroundStyle(primaryTextColor)
            } else {
                SecureField(title, text: text)
                    .foregroundStyle(primaryTextColor)
            }
            Button {
                isVisible.wrappedValue.toggle()
            } label: {
                Image(systemName: isVisible.wrappedValue ? "eye.slash.fill" : "eye.fill")
                    .foregroundStyle(.blue)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(innerFillColor)
        )
    }

    private func performLogin() {
        let identifier = loginIdentifier.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        let emailMatch = identifier == email.lowercased()
        let userMatch = identifier == username.lowercased()

        guard emailMatch || userMatch else {
            authErrorMessage = t(.userNotFound)
            return
        }
        guard loginPassword == storedPassword else {
            authErrorMessage = t(.incorrectPassword)
            return
        }

        authErrorMessage = nil
        isLoggedIn = true
        lastLoginTimestamp = Date().timeIntervalSince1970
        loginPassword = ""
    }

    private func performRegister() {
        let trimmedEmail = registerEmail.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedUser = registerUsername.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedPhone = registerPhoneNumber.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !trimmedEmail.isEmpty, !trimmedUser.isEmpty, !trimmedPhone.isEmpty else {
            authErrorMessage = t(.completeAllFields)
            return
        }
        guard trimmedEmail.contains("@") else {
            authErrorMessage = t(.invalidEmail)
            return
        }
        guard isValidPhoneNumber(trimmedPhone, prefix: registerPhonePrefix) else {
            authErrorMessage = t(.invalidPhone)
            return
        }
        guard registerPassword == registerPasswordConfirm, !registerPassword.isEmpty else {
            authErrorMessage = t(.passwordsNoMatch)
            return
        }

        email = trimmedEmail
        username = trimmedUser
        if fullName.isEmpty || fullName == "Alex Traveller" {
            fullName = trimmedUser
        }
        phone = "\(registerPhonePrefix) \(trimmedPhone)"
        storedPassword = registerPassword

        authErrorMessage = nil
        isLoggedIn = false
        lastLoginTimestamp = 0
        showRegister = false
        loginIdentifier = trimmedEmail
        loginPassword = ""
        registerPassword = ""
        registerPasswordConfirm = ""
    }

    private var forgotPasswordScreen: some View {
        NavigationStack {
            ZStack {
                screenGradient
                ScrollView {
                    VStack(spacing: 16) {
                        homeBrandLogo
                        Text("Recover password")
                            .font(.title2.weight(.bold))
                            .foregroundStyle(primaryTextColor)
                            .frame(maxWidth: .infinity, alignment: .leading)

                        VStack(spacing: 12) {
                            switch recoveryStep {
                            case .email:
                                authField(title: t(.email), text: $recoveryEmail, icon: "envelope.fill", keyboard: .emailAddress)
                                    .textInputAutocapitalization(.never)
                                    .autocorrectionDisabled(true)
                                Button {
                                    sendRecoveryCode()
                                } label: {
                                    Text("Send code")
                                        .font(.headline.weight(.semibold))
                                        .foregroundStyle(.white)
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 12)
                                        .background(RoundedRectangle(cornerRadius: 12).fill(Color.blue))
                                }

                            case .code:
                                authField(title: "Code", text: $recoveryCodeInput, icon: "number.square.fill", keyboard: .numberPad)
                                Button {
                                    verifyRecoveryCode()
                                } label: {
                                    Text("Verify code")
                                        .font(.headline.weight(.semibold))
                                        .foregroundStyle(.white)
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 12)
                                        .background(RoundedRectangle(cornerRadius: 12).fill(Color.blue))
                                }

                            case .newPassword:
                                authPasswordField(title: t(.password), text: $recoveryNewPassword, icon: "lock.fill", isVisible: $showRegisterPassword)
                                authPasswordField(title: t(.repeatPassword), text: $recoveryRepeatPassword, icon: "lock.fill", isVisible: $showRegisterPasswordConfirm)
                                Button {
                                    updateRecoveredPassword()
                                } label: {
                                    Text("Update password")
                                        .font(.headline.weight(.semibold))
                                        .foregroundStyle(.white)
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 12)
                                        .background(RoundedRectangle(cornerRadius: 12).fill(Color.blue))
                                }
                            }

                            if let recoveryMessage {
                                Text(recoveryMessage)
                                    .font(.caption)
                                    .foregroundStyle(.orange)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                            }
                        }
                        .padding(16)
                        .background(cardBackground)
                    }
                    .padding(.horizontal, 18)
                    .padding(.top, 8)
                }
            }
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button(t(.back)) {
                        showForgotPasswordFlow = false
                    }
                }
            }
        }
    }

    private func sendRecoveryCode() {
        let normalized = recoveryEmail.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard normalized.contains("@") else {
            recoveryMessage = t(.invalidEmail)
            return
        }
        guard normalized == email.lowercased() else {
            recoveryMessage = t(.userNotFound)
            return
        }
        recoverySentCode = String(format: "%06d", Int.random(in: 100000...999999))
        recoveryStep = .code
        recoveryMessage = "This is your code. Check your email. (Demo code: \(recoverySentCode))"
        notifications.insert(
            AccountNotification(
                title: "Password recovery",
                subtitle: "Code sent to \(recoveryEmail)"
            ),
            at: 0
        )
    }

    private func verifyRecoveryCode() {
        let input = recoveryCodeInput.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !input.isEmpty else {
            recoveryMessage = "Enter the code."
            return
        }
        guard input == recoverySentCode else {
            recoveryMessage = "Incorrect code."
            return
        }
        recoveryStep = .newPassword
        recoveryMessage = nil
    }

    private func updateRecoveredPassword() {
        guard !recoveryNewPassword.isEmpty else {
            recoveryMessage = t(.completeAllFields)
            return
        }
        guard recoveryNewPassword == recoveryRepeatPassword else {
            recoveryMessage = t(.passwordsNoMatch)
            return
        }
        storedPassword = recoveryNewPassword
        recoveryMessage = nil
        showForgotPasswordFlow = false
        resetRecoveryFlow()
        notifications.insert(
            AccountNotification(
                title: "Password updated",
                subtitle: "Your password was changed successfully."
            ),
            at: 0
        )
    }

    private func resetRecoveryFlow() {
        recoveryStep = .email
        recoveryEmail = ""
        recoverySentCode = ""
        recoveryCodeInput = ""
        recoveryNewPassword = ""
        recoveryRepeatPassword = ""
        recoveryMessage = nil
    }

    private struct PhonePrefix: Identifiable {
        let id = UUID()
        let code: String
        let flag: String
        let label: String
        let minDigits: Int
        let maxDigits: Int
    }

    private var phonePrefixes: [PhonePrefix] {
        [
            PhonePrefix(code: "+1", flag: "🇺🇸", label: "US", minDigits: 10, maxDigits: 10),
            PhonePrefix(code: "+34", flag: "🇪🇸", label: "ES", minDigits: 9, maxDigits: 9),
            PhonePrefix(code: "+39", flag: "🇮🇹", label: "IT", minDigits: 9, maxDigits: 10),
            PhonePrefix(code: "+351", flag: "🇵🇹", label: "PT", minDigits: 9, maxDigits: 9),
            PhonePrefix(code: "+44", flag: "🇬🇧", label: "UK", minDigits: 9, maxDigits: 10),
            PhonePrefix(code: "+33", flag: "🇫🇷", label: "FR", minDigits: 9, maxDigits: 9),
            PhonePrefix(code: "+49", flag: "🇩🇪", label: "DE", minDigits: 10, maxDigits: 11),
            PhonePrefix(code: "+54", flag: "🇦🇷", label: "AR", minDigits: 10, maxDigits: 11),
            PhonePrefix(code: "+57", flag: "🇨🇴", label: "CO", minDigits: 10, maxDigits: 10),
            PhonePrefix(code: "+86", flag: "🇨🇳", label: "CN", minDigits: 11, maxDigits: 11)
        ]
    }

    private func isValidPhoneNumber(_ input: String, prefix: String) -> Bool {
        let digits = input.filter { $0.isNumber }
        guard let rule = phonePrefixes.first(where: { $0.code == prefix }) else { return false }
        return digits.count >= rule.minDigits && digits.count <= rule.maxDigits
    }

    private var experiencesCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(t(.recommended))
                    .font(.headline)
                    .foregroundStyle(primaryTextColor)
                Spacer()
                HStack(spacing: 6) {
                    Image(systemName: "mappin.circle.fill")
                    Text("TripAdvisor API")
                }
                .font(.caption.weight(.semibold))
                .foregroundStyle(.green)
            }

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(HomeExperience.mock) { item in
                        VStack(alignment: .leading, spacing: 0) {
                            AsyncImage(url: item.imageURL) { phase in
                                switch phase {
                                case .success(let image):
                                    image
                                        .resizable()
                                        .scaledToFill()
                                default:
                                    LinearGradient(
                                        colors: [Color.blue.opacity(0.35), Color.black.opacity(0.55)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                    .overlay(
                                        Image(systemName: "photo")
                                            .font(.title2)
                                            .foregroundStyle(.white.opacity(0.7))
                                    )
                                }
                            }
                            .frame(height: 112)
                            .clipped()

                            VStack(alignment: .leading, spacing: 6) {
                                Text(item.title)
                                    .font(.subheadline.weight(.semibold))
                                    .foregroundStyle(primaryTextColor)
                                    .lineLimit(1)
                                Text(item.location)
                                    .font(.caption)
                                    .foregroundStyle(secondaryTextColor)
                                HStack {
                                    Text(item.price)
                                        .font(.caption.weight(.semibold))
                                        .foregroundStyle(.cyan)
                                    Spacer()
                                    Text(t(.book))
                                        .font(.caption.weight(.bold))
                                        .foregroundStyle(.white)
                                        .padding(.horizontal, 10)
                                        .padding(.vertical, 5)
                                        .background(
                                            RoundedRectangle(cornerRadius: 8)
                                                .fill(Color.blue)
                                        )
                                }
                            }
                            .padding(10)
                            .background(usesLightPalette ? Color.black.opacity(0.04) : Color.white.opacity(0.05))
                        }
                        .frame(width: 205)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                        .overlay(
                            RoundedRectangle(cornerRadius: 14)
                                .stroke(usesLightPalette ? Color.black.opacity(0.10) : Color.white.opacity(0.08), lineWidth: 1)
                        )
                    }
                }
            }
        }
        .padding()
        .background(cardBackground)
    }

    private var searchCard: some View {
        VStack(spacing: 10) {
            HStack(spacing: 8) {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(.blue)
                TextField("Search stop or code...", text: $searchText)
                    .foregroundStyle(.white)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled(true)
            }
            .padding(12)
            .background(innerBackground)

            if !searchText.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    ForEach(filteredStations.prefix(6), id: \.id) { station in
                        HStack {
                            Text(station.name)
                                .foregroundStyle(.white)
                            Spacer()
                            Text(station.code)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    if filteredStations.isEmpty {
                        Text("No matching stops")
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(12)
                .background(innerBackground)
            }
        }
        .padding()
        .background(cardBackground)
    }

    private var stationPickerCard: some View {
        VStack(spacing: 12) {
            Text("Route")
                .font(.headline)
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity, alignment: .leading)

            Picker("From", selection: Binding(
                get: { originId ?? 0 },
                set: { originId = $0 == 0 ? nil : $0 }
            )) {
                Text("From station").tag(0)
                ForEach(appState.stations, id: \.id) { station in
                    Text("\(station.name) (\(station.code))").tag(station.id)
                }
            }
            .pickerStyle(.menu)
            .tint(.white)

            Picker("To", selection: Binding(
                get: { destinationId ?? 0 },
                set: { destinationId = $0 == 0 ? nil : $0 }
            )) {
                Text("To station").tag(0)
                ForEach(appState.stations, id: \.id) { station in
                    Text("\(station.name) (\(station.code))").tag(station.id)
                }
            }
            .pickerStyle(.menu)
            .tint(.white)
        }
        .padding()
        .background(cardBackground)
    }

    private var transportModeCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Mode")
                .font(.headline)
                .foregroundStyle(primaryTextColor)

            HStack(spacing: 10) {
                ForEach([TransportMode.train, .bus, .taxi, .walk], id: \.self) { mode in
                    transportModePill(mode)
                }
            }
        }
        .padding()
        .background(cardBackground)
    }

    private func transportModePill(_ mode: TransportMode) -> some View {
        let selected = transportMode == mode
        let fg: Color = selected ? .white : (usesLightPalette ? Color.black.opacity(0.7) : .secondary)
        let bg: Color = selected ? Color.blue.opacity(0.95) : (usesLightPalette ? Color.black.opacity(0.05) : Color.white.opacity(0.06))
        let border: Color = selected ? .blue : (usesLightPalette ? Color.black.opacity(0.10) : Color.white.opacity(0.08))

        return VStack(spacing: 8) {
            Image(systemName: mode.icon)
                .font(.headline)
            Text(mode.title(in: appLanguage))
                .font(.caption.weight(.semibold))
        }
        .foregroundStyle(fg)
        .frame(maxWidth: .infinity)
        .frame(height: 74)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(bg)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(border, lineWidth: 1)
        )
        .contentShape(RoundedRectangle(cornerRadius: 12))
        .onTapGesture {
            transportMode = mode
        }
    }

    private var algorithmCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("\(t(.route))")
                .font(.headline)
                .foregroundStyle(.white)

            Picker("Pathfinding", selection: $useBFS) {
                Text("Fastest").tag(false)
                Text("Fewest Stops").tag(true)
            }
            .pickerStyle(.segmented)
        }
        .padding()
        .background(cardBackground)
    }

    private var actionCard: some View {
        Button(action: openPlannedRoute) {
            Text("\(t(.find)) \(transportMode.title(in: appLanguage)) \(t(.route))")
                .font(.headline)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
        }
        .buttonStyle(.borderedProminent)
        .disabled(originId == nil || destinationId == nil || originId == destinationId)
        .padding()
        .background(cardBackground)
    }

    private func openPlannedRoute() {
        lastResultError = nil
        lastResult = nil

        guard !appState.stations.isEmpty else {
            lastResultError = "Still loading stations. Try again in a second."
            return
        }

        guard let origin = originId, let destination = destinationId, origin != destination else {
            lastResultError = "Select different origin and destination stations."
            return
        }

        guard let route = appState.findRoute(originId: origin, destinationId: destination, useBFS: useBFS) else {
            lastResultError = "No route found with current data."
            return
        }

        lastResult = route
        plannedRoute = PlannedRoute(
            mode: transportMode,
            stationIds: route.stationIds,
            durationMins: route.totalDurationMins ?? transportMode.defaultDurationMins
        )
        showPlannedRoute = true
    }

    private var taxiCard: some View {
        VStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.white.opacity(0.06))
                    .frame(height: 190)
                    .overlay(
                        gridOverlay
                    )

                Circle()
                    .fill(Color.blue.opacity(0.35))
                    .frame(width: 72, height: 72)
                    .scaleEffect(taxiPulse ? 1.1 : 0.9)
                    .opacity(taxiPulse ? 0.7 : 0.35)
                    .animation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true), value: taxiPulse)

                Circle()
                    .fill(Color.blue)
                    .frame(width: 18, height: 18)
                    .overlay(
                        Circle().stroke(Color.white.opacity(0.8), lineWidth: 1)
                    )

                Circle()
                    .fill(Color.yellow.opacity(0.9))
                    .frame(width: 30, height: 30)
                    .overlay {
                        Image(systemName: "car.fill")
                            .font(.caption.weight(.bold))
                            .foregroundStyle(.black.opacity(0.8))
                    }
                    .offset(x: 88, y: -44)
            }
            .onAppear { taxiPulse = true }

            Button {
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "person.fill")
                    Text("\(t(.find)) \(t(.taxi))")
                        .font(.headline.weight(.semibold))
                }
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.blue)
                )
            }
            .buttonStyle(.plain)
        }
        .padding()
        .background(cardBackground)
    }

    private var nearbyStopMapCard: some View {
        VStack(spacing: 12) {
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.06))
                .frame(height: 340)
                .overlay {
                    if let stop = nearestStopInfo {
                        Map(position: .constant(nearestStopCamera(for: stop.station))) {
                            if let lat = stop.station.latitude, let lon = stop.station.longitude {
                                Marker(stop.station.name, coordinate: CLLocationCoordinate2D(latitude: lat, longitude: lon))
                                    .tint(.blue)
                            }
                            UserAnnotation()
                        }
                        .mapStyle(.standard(elevation: .realistic))
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                    } else {
                        ProgressView(t(.locatingNearestStop))
                            .tint(.white)
                    }
                }

            if let stop = nearestStopInfo {
                nearbyStopInfoBox(stop)
            }
        }
        .padding()
        .background(cardBackground)
    }

    private func nearbyStopInfoBox(_ stop: NearbyStopInfo) -> some View {
        let saved = isStopSaved(stop.station.id)
        return VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .center) {
                HStack(spacing: 7) {
                    Text(transportMode == .train ? t(.station) : t(.stop))
                        .font(.caption2.weight(.bold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 7)
                        .padding(.vertical, 4)
                        .background(
                            RoundedRectangle(cornerRadius: 6)
                                .fill(transportMode == .train ? .blue : .green)
                        )
                    Text(stop.station.name)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(primaryTextColor)
                }

                Spacer()

                Button {
                    toggleSavedStop(stop)
                } label: {
                    Image(systemName: saved ? "star.fill" : "star")
                        .font(.headline)
                        .foregroundStyle(saved ? .yellow : (usesLightPalette ? Color.black.opacity(0.7) : .white))
                }
                .buttonStyle(.plain)
            }

            Text("\(distanceText(for: stop.distanceMeters)) \(t(.away))")
                .font(.caption)
                .foregroundStyle(secondaryTextColor)

            HStack(spacing: 8) {
                Button {
                    directionsStation = stop.station
                    directionsMode = transportMode
                    showDirectionsSheet = true
                } label: {
                    Label(t(.directions), systemImage: "arrow.triangle.turn.up.right.diamond.fill")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .fill(Color.blue)
                        )
                }
                .buttonStyle(.plain)

                Button {
                    showDepartures(for: stop.station)
                } label: {
                    Label(t(.departures), systemImage: "clock.fill")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(usesLightPalette ? Color.black : Color.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .fill(usesLightPalette ? Color.black.opacity(0.08) : Color.white.opacity(0.12))
                        )
                }
                .buttonStyle(.plain)
            }
        }
        .padding(10)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(usesLightPalette ? Color.white.opacity(0.90) : Color.black.opacity(0.45))
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(usesLightPalette ? Color.black.opacity(0.10) : Color.white.opacity(0.08), lineWidth: 1)
                )
        )
    }

    private var gridOverlay: some View {
        GeometryReader { geo in
            ZStack {
                Path { path in
                    path.move(to: CGPoint(x: 0, y: geo.size.height * 0.45))
                    path.addLine(to: CGPoint(x: geo.size.width, y: geo.size.height * 0.45))
                    path.move(to: CGPoint(x: geo.size.width * 0.5, y: 0))
                    path.addLine(to: CGPoint(x: geo.size.width * 0.5, y: geo.size.height))
                }
                .stroke(Color.white.opacity(0.08), lineWidth: 14)

                RoundedRectangle(cornerRadius: 10)
                    .fill(Color.white.opacity(0.04))
                    .frame(width: 90, height: 50)
                    .offset(x: -100, y: 46)
            }
        }
        .clipped()
    }

    private var walkPlannerCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Walk Route")
                .font(.headline)
                .foregroundStyle(primaryTextColor)

            VStack(spacing: 6) {
                HStack(spacing: 8) {
                    Image(systemName: "location.fill")
                        .foregroundStyle(.blue)
                    TextField("From (current location or stop)", text: $walkFromQuery)
                        .focused($walkFocusedField, equals: .from)
                        .textInputAutocapitalization(.words)
                        .autocorrectionDisabled(true)
                        .foregroundStyle(primaryTextColor)
                        .submitLabel(.done)
                        .onSubmit { walkFocusedField = nil }
                }
                .padding(12)
                .background(innerFillColor)

                if walkFocusedField == .from && !walkFromSuggestions.isEmpty {
                    walkSuggestionsList(walkFromSuggestions) { station in
                        walkFromQuery = station.name
                        walkFocusedField = nil
                    }
                }
            }

            VStack(spacing: 6) {
                HStack(spacing: 8) {
                    Image(systemName: "mappin.and.ellipse")
                        .foregroundStyle(.blue)
                    TextField("To (destination)", text: $walkToQuery)
                        .focused($walkFocusedField, equals: .to)
                        .textInputAutocapitalization(.words)
                        .autocorrectionDisabled(true)
                        .foregroundStyle(primaryTextColor)
                        .submitLabel(.done)
                        .onSubmit { walkFocusedField = nil }
                }
                .padding(12)
                .background(innerFillColor)

                if walkFocusedField == .to && !walkToSuggestions.isEmpty {
                    walkSuggestionsList(walkToSuggestions) { station in
                        walkToQuery = station.name
                        walkFocusedField = nil
                    }
                }
            }

            Button {
                Task { await calculateWalkRoute() }
            } label: {
                Text("Find Walk Route")
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.blue)
                    )
            }
            .buttonStyle(.plain)

            if let route = walkRoute {
                ZStack(alignment: .bottomLeading) {
                    Map(position: $walkMapPosition) {
                        MapPolyline(route.polyline)
                            .stroke(Color.blue, lineWidth: 4)
                    }
                    .frame(height: 220)
                    .clipShape(RoundedRectangle(cornerRadius: 14))

                    VStack(alignment: .leading, spacing: 4) {
                        Text("Estimated time")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text("\(Int(route.expectedTravelTime / 60)) min")
                            .font(.headline.weight(.semibold))
                            .foregroundStyle(.white)
                    }
                    .padding(10)
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color.black.opacity(0.65))
                    )
                    .padding(12)
                }
            } else if let error = walkRouteError {
                Text(error)
                    .font(.caption)
                    .foregroundStyle(.red)
            }
        }
        .padding()
        .background(cardBackground)
        .onTapGesture {
            walkFocusedField = nil
        }
    }

    private var routeStageCard: some View {
        let stationIds = displayStationIds

        return VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text(transportMode.stageTitle(in: appLanguage))
                    .font(.headline)
                    .foregroundStyle(.white)
                Spacer()
                Image(systemName: "chevron.up")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
            }

            if transportMode == .train {
                HStack(spacing: 8) {
                    Text("AVANTI")
                        .font(.caption2.weight(.bold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 7)
                        .padding(.vertical, 4)
                        .background(Color.red, in: RoundedRectangle(cornerRadius: 4))
                    Text("Avanti West Coast")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }

            modeRoutePreview

            ForEach(Array(stationIds.enumerated()), id: \.offset) { index, stationId in
                HStack(alignment: .top, spacing: 10) {
                    Circle()
                        .fill(index == 0 ? transportMode.accentColor : (index == stationIds.count - 1 ? Color.orange : Color.blue))
                        .frame(width: 10, height: 10)
                        .padding(.top, 5)

                    VStack(alignment: .leading, spacing: 2) {
                        Text(appState.mapping.name(for: stationId))
                            .foregroundStyle(.white)
                        Text(appState.mapping.code(for: stationId))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }

            Divider().overlay(.white.opacity(0.1))

            HStack {
                Text("\(t(.segments)): \(max(stationIds.count - 1, 0))")
                Spacer()
                Text("ETA: \(displayDurationMins) \(t(.min))")
            }
            .font(.subheadline)
            .foregroundStyle(.secondary)
        }
        .padding()
        .background(cardBackground)
    }

    private var modeRoutePreview: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white.opacity(0.04))
                .frame(height: 116)

            switch transportMode {
            case .train:
                trainPreview
            case .bus:
                busPreview
            case .walk:
                walkPreview
            case .taxi:
                EmptyView()
            }
        }
    }

    private var trainPreview: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height
            Path { path in
                path.move(to: CGPoint(x: 20, y: h * 0.78))
                path.addCurve(
                    to: CGPoint(x: w - 20, y: h * 0.25),
                    control1: CGPoint(x: w * 0.30, y: h * 0.55),
                    control2: CGPoint(x: w * 0.62, y: h * 0.18)
                )
            }
            .stroke(style: StrokeStyle(lineWidth: 3, lineCap: .round, dash: [3, 8]))
            .foregroundStyle(.blue)

            Circle().fill(Color.blue).frame(width: 8, height: 8).position(x: 20, y: h * 0.78)
            Circle().fill(Color.blue).frame(width: 8, height: 8).position(x: w * 0.42, y: h * 0.50)
            Circle().fill(Color.blue).frame(width: 8, height: 8).position(x: w - 20, y: h * 0.25)
        }
        .padding(.horizontal, 8)
    }

    private var busPreview: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height
            Path { path in
                path.move(to: CGPoint(x: 0, y: h * 0.32))
                path.addLine(to: CGPoint(x: w, y: h * 0.32))
                path.move(to: CGPoint(x: 0, y: h * 0.68))
                path.addLine(to: CGPoint(x: w, y: h * 0.68))
                path.move(to: CGPoint(x: w * 0.45, y: 0))
                path.addLine(to: CGPoint(x: w * 0.45, y: h))
            }
            .stroke(Color.white.opacity(0.14), lineWidth: 12)

            Path { path in
                path.move(to: CGPoint(x: 24, y: h * 0.68))
                path.addCurve(
                    to: CGPoint(x: w - 24, y: h * 0.32),
                    control1: CGPoint(x: w * 0.32, y: h * 0.70),
                    control2: CGPoint(x: w * 0.64, y: h * 0.34)
                )
            }
            .stroke(style: StrokeStyle(lineWidth: 3, lineCap: .round, dash: [5, 7]))
            .foregroundStyle(.green)

            Image(systemName: "bus.fill")
                .font(.headline)
                .foregroundStyle(.yellow)
                .position(x: w * 0.70, y: h * 0.42)
        }
        .padding(.horizontal, 8)
    }

    private var walkPreview: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height

            RoundedRectangle(cornerRadius: 10)
                .fill(Color.white.opacity(0.03))
                .frame(width: w * 0.92, height: h * 0.80)
                .position(x: w * 0.5, y: h * 0.5)

            Path { path in
                path.move(to: CGPoint(x: 22, y: h * 0.76))
                path.addCurve(
                    to: CGPoint(x: w - 24, y: h * 0.22),
                    control1: CGPoint(x: w * 0.28, y: h * 0.30),
                    control2: CGPoint(x: w * 0.65, y: h * 0.90)
                )
            }
            .stroke(style: StrokeStyle(lineWidth: 4, lineCap: .round, lineJoin: .round))
            .foregroundStyle(Color(red: 0.17, green: 0.56, blue: 1.0))

            Circle().fill(Color.green).frame(width: 9, height: 9).position(x: 22, y: h * 0.76)
            Circle().fill(Color.red).frame(width: 9, height: 9).position(x: w - 24, y: h * 0.22)
            Image(systemName: "figure.walk")
                .foregroundStyle(.white)
                .position(x: w * 0.52, y: h * 0.52)
        }
        .padding(.horizontal, 8)
    }

    private var displayStationIds: [Int] {
        if let result = lastResult, !result.stationIds.isEmpty {
            return result.stationIds
        }
        if let pre = stationId(code: "PRE"), let lan = stationId(code: "LAN") {
            return [pre, lan]
        }
        return Array(appState.stations.prefix(2).map(\.id))
    }

    private var displayDurationMins: Int {
        if let mins = lastResult?.totalDurationMins {
            return mins
        }
        return transportMode.defaultDurationMins
    }

    private func stationId(code: String) -> Int? {
        appState.stations.first(where: { $0.code == code })?.id
    }

    private func messageCard(text: String, color: Color) -> some View {
        Text(text)
            .foregroundStyle(color)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding()
            .background(cardBackground)
    }

    private func ticketCard(_ ticket: TicketItem) -> some View {
        VStack(spacing: 0) {
            RoundedRectangle(cornerRadius: 18)
                .fill(Color(red: 0.86, green: 0.65, blue: 0.49))
                .frame(height: 170)
                .overlay {
                    VStack(spacing: 8) {
                        Image(systemName: "qrcode")
                            .font(.system(size: 48))
                            .foregroundStyle(.black.opacity(0.85))
                        Text(t(.readyToScan))
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.black.opacity(0.75))
                    }
                }
                .padding(.horizontal, 28)
                .padding(.top, 24)

            Divider()
                .overlay(Color.white.opacity(0.08))
                .padding(.horizontal, 18)
                .padding(.vertical, 18)

            VStack(alignment: .leading, spacing: 16) {
                Text(ticket.routeTitle)
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(.white)

                HStack(spacing: 16) {
                    ticketInfoCell(
                        label: "REFERENCE",
                        value: ticket.reference
                    )
                    ticketInfoCell(
                        label: "DATE",
                        value: ticketDateText(ticket.travelDate)
                    )
                }

                HStack(spacing: 16) {
                    ticketInfoCell(
                        label: "DURATION",
                        value: "\(ticket.durationMins) \(t(.min))"
                    )
                    ticketInfoCell(
                        label: "RAILCARD",
                        value: ticket.railcardUsed ? "Used" : "Not used"
                    )
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 22)
        }
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(Color.black.opacity(0.65))
                .overlay(
                    RoundedRectangle(cornerRadius: 24)
                        .stroke(Color.white.opacity(0.08), lineWidth: 1)
                )
        )
        .padding(.horizontal, 4)
    }

    private var ticketItems: [TicketItem] {
        [
            TicketItem(
                routeTitle: "Preston → Lancaster",
                originCode: "PRE",
                destinationCode: "LAN",
                stationIds: ticketStationIds(originCode: "PRE", destinationCode: "LAN"),
                reference: ticketReference,
                travelDate: ticketTravelDate,
                durationMins: ticketDurationMins,
                railcardUsed: ticketRailcardUsed
            ),
            TicketItem(
                routeTitle: "Lancaster → Blackpool North",
                originCode: "LAN",
                destinationCode: "BPN",
                stationIds: ticketStationIds(originCode: "LAN", destinationCode: "BPN"),
                reference: "TR-9012",
                travelDate: Calendar.current.date(byAdding: .day, value: 1, to: ticketTravelDate) ?? ticketTravelDate,
                durationMins: 58,
                railcardUsed: false
            ),
            TicketItem(
                routeTitle: "Preston → Barrow-in-Furness",
                originCode: "PRE",
                destinationCode: "BAR",
                stationIds: ticketStationIds(originCode: "PRE", destinationCode: "BAR"),
                reference: "TR-7744",
                travelDate: Calendar.current.date(byAdding: .day, value: 3, to: ticketTravelDate) ?? ticketTravelDate,
                durationMins: 86,
                railcardUsed: true
            )
        ]
    }

    private func ticketStationIds(originCode: String, destinationCode: String) -> [Int] {
        guard
            let origin = appState.stations.first(where: { $0.code == originCode }),
            let destination = appState.stations.first(where: { $0.code == destinationCode })
        else {
            return []
        }
        if let route = appState.findRoute(originId: origin.id, destinationId: destination.id, useBFS: false),
           !route.stationIds.isEmpty {
            return route.stationIds
        }
        return [origin.id, destination.id]
    }

    private var selectedTicket: TicketItem? {
        guard !ticketItems.isEmpty else { return nil }
        let idx = min(max(selectedTicketIndex, 0), ticketItems.count - 1)
        return ticketItems[idx]
    }

    private var ticketsScreen: some View {
        NavigationStack {
            ZStack {
                screenGradient
                VStack(spacing: 0) {
                    ScrollView {
                        VStack(spacing: 14) {
                            VStack(alignment: .leading, spacing: 10) {
                                Text(t(.yourTicket))
                                    .font(.title3.weight(.semibold))
                                    .foregroundStyle(primaryTextColor)

                                TabView(selection: $selectedTicketIndex) {
                                    ForEach(Array(ticketItems.enumerated()), id: \.offset) { index, ticket in
                                        ticketCard(ticket)
                                            .tag(index)
                                    }
                                }
                                .tabViewStyle(.page(indexDisplayMode: .automatic))
                                .frame(height: 430)
                            }
                            .padding()
                            .background(cardBackground)

                            Spacer(minLength: 120)
                        }
                        .padding(.horizontal, 14)
                        .padding(.top, 12)
                    }

                    VStack(spacing: 10) {
                        Button {
                            showTrackSheet = true
                        } label: {
                            HStack(spacing: 8) {
                                Image(systemName: "location.north.circle.fill")
                                    .font(.headline)
                                Text("Track")
                                    .font(.headline.weight(.semibold))
                            }
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(
                                RoundedRectangle(cornerRadius: 14)
                                    .fill(Color.blue)
                            )
                        }

                        Button {
                            addToWalletTapped()
                        } label: {
                            HStack(spacing: 8) {
                                Image(systemName: "wallet.pass.fill")
                                    .font(.headline)
                                Text(t(.addToAppleWallet))
                                    .font(.headline.weight(.semibold))
                            }
                            .foregroundStyle(.black)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(
                                RoundedRectangle(cornerRadius: 14)
                                    .fill(Color.white)
                            )
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(.horizontal, 14)
                    .padding(.top, 10)
                    .padding(.bottom, 12)
                    .background(
                        LinearGradient(
                            colors: [Color.black.opacity(0.0), Color.black.opacity(0.45)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                        .ignoresSafeArea(edges: .bottom)
                    )
                }
            }
            .navigationTitle(t(.tickets))
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    private var mapScreen: some View {
        NavigationStack {
            ZStack(alignment: .bottomTrailing) {
                Map(position: $mapPosition, selection: $selectedMapStationId) {
                    ForEach(appState.mapStations, id: \.id) { station in
                        if let lat = station.latitude, let lon = station.longitude {
                            Marker(station.name, coordinate: CLLocationCoordinate2D(latitude: lat, longitude: lon))
                                .tint(.blue)
                                .tag(station.id)
                        }
                    }
                }
                .mapStyle(.standard(elevation: .realistic))
                .ignoresSafeArea()
                .onMapCameraChange(frequency: .continuous) { context in
                    mapCurrentRegion = context.region
                }

                VStack(spacing: 12) {
                    Button {
                        applyMapZoom(scale: 0.6)
                    } label: {
                        Image(systemName: "plus")
                            .font(.headline.weight(.bold))
                            .foregroundStyle(.white)
                            .frame(width: 42, height: 42)
                            .background(Circle().fill(Color.black.opacity(0.65)))
                    }

                    Button {
                        applyMapZoom(scale: 1.6)
                    } label: {
                        Image(systemName: "minus")
                            .font(.headline.weight(.bold))
                            .foregroundStyle(.white)
                            .frame(width: 42, height: 42)
                            .background(Circle().fill(Color.black.opacity(0.65)))
                    }

                    Button {
                        mapPosition = .region(
                            MKCoordinateRegion(
                                center: CLLocationCoordinate2D(latitude: 53.90, longitude: -2.95),
                                span: MKCoordinateSpan(latitudeDelta: 0.85, longitudeDelta: 1.0)
                            )
                        )
                        mapCurrentRegion = MKCoordinateRegion(
                            center: CLLocationCoordinate2D(latitude: 53.90, longitude: -2.95),
                            span: MKCoordinateSpan(latitudeDelta: 0.85, longitudeDelta: 1.0)
                        )
                    } label: {
                        Image(systemName: "scope")
                            .font(.headline)
                            .foregroundStyle(.white)
                            .frame(width: 42, height: 42)
                            .background(Circle().fill(Color.black.opacity(0.65)))
                    }
                }
                .padding(.trailing, 16)
                .padding(.bottom, 18)
            }
            .safeAreaInset(edge: .bottom) {
                if let station = selectedMapStation {
                    mapStationArrivalsCard(for: station)
                        .padding(.horizontal, 12)
                        .padding(.bottom, 8)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
            .animation(.easeInOut(duration: 0.25), value: selectedMapStationId)
            .onChange(of: selectedMapStationId) { _, newValue in
                if newValue != nil {
                    mapDepartureMode = .train
                    mapPanelExpanded = false
                }
            }
            .navigationTitle(t(.map))
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    private func mapStationArrivalsCard(for station: Station) -> some View {
        let arrivals = upcomingMapArrivals(for: station)
            .filter { $0.mode == mapDepartureMode }
        let displayedArrivals = mapPanelExpanded ? arrivals : Array(arrivals.prefix(4))
        let isSaved = isStopSaved(station.id)

        return VStack(alignment: .leading, spacing: 12) {
            Capsule()
                .fill(Color.white.opacity(0.35))
                .frame(width: 36, height: 4)
                .frame(maxWidth: .infinity)

            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(station.name)
                        .font(.headline)
                        .foregroundStyle(primaryTextColor)
                    Text("\(t(.departures)) • \(displayedArrivals.count)")
                        .font(.caption)
                        .foregroundStyle(secondaryTextColor)
                }
                Spacer()
                Button {
                    selectedMapStationId = nil
                } label: {
                    Image(systemName: "xmark")
                        .font(.subheadline.weight(.bold))
                        .foregroundStyle(usesLightPalette ? Color.black.opacity(0.8) : Color.white.opacity(0.9))
                        .frame(width: 28, height: 28)
                        .background(Circle().fill(usesLightPalette ? Color.black.opacity(0.08) : Color.white.opacity(0.12)))
                }
                .buttonStyle(.plain)
            }

            HStack(spacing: 14) {
                Spacer()
                mapDepartureModeButton(mode: .train)
                mapDepartureModeButton(mode: .bus)
                Button {
                    toggleSavedStopFromMap(station)
                } label: {
                    Image(systemName: isSaved ? "star.fill" : "star")
                        .font(.title3.weight(.semibold))
                        .foregroundStyle(isSaved ? .yellow : (usesLightPalette ? Color.black.opacity(0.7) : .white))
                        .frame(width: 40, height: 40)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(usesLightPalette ? Color.black.opacity(0.06) : Color.white.opacity(0.08))
                        )
                }
                .buttonStyle(.plain)
                Spacer()
            }

            VStack(spacing: 8) {
                ForEach(displayedArrivals) { item in
                    Button {
                        openMapLiveTrack(for: item, from: station)
                    } label: {
                        HStack(spacing: 10) {
                            Text(item.service)
                                .font(.subheadline.weight(.bold))
                                .foregroundStyle(.white)
                                .frame(width: 42, height: 30)
                                .background(
                                    RoundedRectangle(cornerRadius: 8)
                                        .fill(item.color.opacity(0.8))
                                )

                            VStack(alignment: .leading, spacing: 2) {
                                Text(item.destination)
                                    .font(.subheadline.weight(.semibold))
                                    .foregroundStyle(primaryTextColor)
                                Text(item.operatorName)
                                    .font(.caption)
                                    .foregroundStyle(secondaryTextColor)
                            }

                            Spacer()

                            Text(mapEtaText(for: item))
                                .font(.subheadline.weight(.bold))
                                .foregroundStyle(.cyan)
                                .multilineTextAlignment(.trailing)
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 10)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(usesLightPalette ? Color.black.opacity(0.04) : Color.white.opacity(0.06))
                        )
                    }
                    .buttonStyle(.plain)
                }
            }

            if mapPanelExpanded {
                Button {
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "clock.arrow.circlepath")
                        Text(t(.viewLaterDepartures))
                    }
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.blue)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color.white.opacity(0.08))
                    )
                }
                .buttonStyle(.plain)
            }
        }
        .padding(12)
        .frame(maxHeight: mapPanelExpanded ? UIScreen.main.bounds.height * 0.78 : 320, alignment: .top)
        .background(
            RoundedRectangle(cornerRadius: 18)
                .fill(usesLightPalette ? Color.white : Color(red: 0.06, green: 0.11, blue: 0.20))
                .overlay(
                    RoundedRectangle(cornerRadius: 18)
                        .stroke(usesLightPalette ? Color.black.opacity(0.10) : Color.white.opacity(0.08), lineWidth: 1)
                )
        )
        .gesture(
            DragGesture(minimumDistance: 15)
                .onEnded { value in
                    if value.translation.height < -40 {
                        mapPanelExpanded = true
                    } else if value.translation.height > 40 {
                        mapPanelExpanded = false
                    }
                }
        )
    }

    private func mapDepartureModeButton(mode: TransportMode) -> some View {
        let selected = mapDepartureMode == mode
        return Button {
            mapDepartureMode = mode
        } label: {
            Image(systemName: mode == .train ? "tram.fill" : "bus.fill")
                .font(.title3.weight(.semibold))
                .foregroundStyle(selected ? .white : (usesLightPalette ? Color.black.opacity(0.65) : .secondary))
                .frame(width: 40, height: 40)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(selected ? Color.blue : (usesLightPalette ? Color.black.opacity(0.06) : Color.white.opacity(0.08)))
                )
        }
        .buttonStyle(.plain)
    }

    private func applyMapZoom(scale: Double) {
        let minDelta = 0.002
        let maxDelta = 160.0
        let latitudeDelta = min(max(mapCurrentRegion.span.latitudeDelta * scale, minDelta), maxDelta)
        let longitudeDelta = min(max(mapCurrentRegion.span.longitudeDelta * scale, minDelta), maxDelta)
        let updatedRegion = MKCoordinateRegion(
            center: mapCurrentRegion.center,
            span: MKCoordinateSpan(latitudeDelta: latitudeDelta, longitudeDelta: longitudeDelta)
        )
        mapCurrentRegion = updatedRegion
        mapPosition = .region(updatedRegion)
    }

    private var accountScreen: some View {
        NavigationStack {
            ZStack {
                screenGradient
                VStack(alignment: .leading, spacing: 14) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(t(.studentAccount))
                            .font(.title3.weight(.semibold))
                            .foregroundStyle(primaryTextColor)
                        Text("Your Account")
                            .foregroundStyle(secondaryTextColor)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
                    .background(cardBackground)

                    VStack(alignment: .leading, spacing: 12) {
                        Text(t(.quickActions))
                            .font(.headline)
                            .foregroundStyle(primaryTextColor)

                        NavigationLink {
                            SavedTripsScreen(
                                trips: savedTrips,
                                language: appLanguage,
                                preferredAppearance: preferredAppearance
                            ) { trip in
                                notifications.insert(
                                    AccountNotification(
                                        title: t(.book),
                                        subtitle: "\(trip.title) • Booking started"
                                    ),
                                    at: 0
                                )
                            }
                        } label: {
                            accountActionRow(title: t(.savedTrips), icon: "bookmark.fill")
                        }

                        NavigationLink {
                            SavedStopsScreen(stops: savedStops, language: appLanguage, preferredAppearance: preferredAppearance)
                        } label: {
                            accountActionRow(title: t(.savedStops), icon: "star.fill")
                        }

                        NavigationLink {
                            NotificationsScreen(notifications: notifications, language: appLanguage, preferredAppearance: preferredAppearance)
                        } label: {
                            accountActionRow(title: t(.notifications), icon: "bell.fill")
                        }

                        NavigationLink {
                            SettingsScreen(
                                preferredAppearance: $preferredAppearance,
                                appLanguageRawValue: $appLanguageRawValue,
                                selectedCurrencyRawValue: $selectedCurrencyRawValue,
                                fullName: $fullName,
                                username: $username,
                                email: $email,
                                phone: $phone,
                                fontScale: $fontScale
                            )
                        } label: {
                            accountActionRow(title: t(.settings), icon: "gearshape.fill")
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
                    .background(cardBackground)

                    Spacer()
                }
                .padding(.horizontal, 14)
                .padding(.top, 12)
            }
            .navigationTitle(t(.account))
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    private func accountActionRow(title: String, icon: String) -> some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(.blue)
                .frame(width: 26)
            Text(title)
                .font(.title3.weight(.semibold))
                .foregroundStyle(primaryTextColor)
            Spacer()
            Image(systemName: "chevron.right")
                .font(.headline)
                .foregroundStyle(secondaryTextColor)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 16)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(innerFillColor)
        )
    }

    private var cardBackground: some View {
        RoundedRectangle(cornerRadius: 18)
            .fill(usesLightPalette ? cardFillColor : Color.white.opacity(0.08))
            .overlay(
                RoundedRectangle(cornerRadius: 18)
                    .stroke(usesLightPalette ? cardStrokeColor : Color.white.opacity(0.06), lineWidth: 1)
            )
    }

    private var innerBackground: some View {
        RoundedRectangle(cornerRadius: 12)
            .fill(innerFillColor)
    }

    private var screenGradient: some View {
        LinearGradient(
            colors: usesLightPalette
                ? [Color.white, Color(red: 0.94, green: 0.95, blue: 0.97)]
                : [Color(red: 0.03, green: 0.11, blue: 0.28), Color.black],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()
    }

    private func ticketInfoCell(label: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(.caption.weight(.bold))
                .foregroundStyle(Color.white.opacity(0.82))
            Text(value)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.white)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func ticketDateText(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "d MMM yyyy"
        return formatter.string(from: date)
    }

    private func calculateWalkRoute() async {
        walkRouteError = nil
        walkRoute = nil

        let fromQuery = walkFromQuery.trimmingCharacters(in: .whitespacesAndNewlines)
        let toQuery = walkToQuery.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !toQuery.isEmpty else {
            walkRouteError = "Enter a destination."
            return
        }

        let sourceItem: MKMapItem?
        if fromQuery.isEmpty || fromQuery.lowercased().contains("current") {
            if let loc = locationManager.location?.coordinate {
                sourceItem = MKMapItem(placemark: MKPlacemark(coordinate: loc))
            } else {
                sourceItem = nil
            }
        } else {
            sourceItem = await mapItem(for: fromQuery)
        }

        guard let source = sourceItem else {
            walkRouteError = "Could not find the starting location."
            return
        }

        guard let destination = await mapItem(for: toQuery) else {
            walkRouteError = "Could not find the destination."
            return
        }

        let request = MKDirections.Request()
        request.source = source
        request.destination = destination
        request.transportType = .walking

        do {
            let response = try await MKDirections(request: request).calculate()
            if let route = response.routes.first {
                walkRoute = route
                walkMapPosition = .rect(route.polyline.boundingMapRect)
            } else {
                walkRouteError = "No walking route found."
            }
        } catch {
            walkRouteError = "Route calculation failed."
        }
    }

    private func mapItem(for query: String) async -> MKMapItem? {
        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = query
        do {
            let response = try await MKLocalSearch(request: request).start()
            return response.mapItems.first
        } catch {
            return nil
        }
    }

    private var walkFromSuggestions: [Station] {
        stationMatches(for: walkFromQuery)
    }

    private var walkToSuggestions: [Station] {
        stationMatches(for: walkToQuery)
    }

    private func stationMatches(for query: String) -> [Station] {
        let q = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !q.isEmpty else { return [] }
        return appState.stations.filter {
            $0.name.localizedCaseInsensitiveContains(q) ||
            $0.code.localizedCaseInsensitiveContains(q)
        }
    }

    private func walkSuggestionsList(_ items: [Station], onSelect: @escaping (Station) -> Void) -> some View {
        VStack(spacing: 0) {
            ForEach(items.prefix(6), id: \.id) { station in
                Button {
                    onSelect(station)
                } label: {
                    HStack {
                        Text(station.name)
                            .foregroundStyle(primaryTextColor)
                        Spacer()
                        Text(station.code)
                            .font(.caption)
                            .foregroundStyle(secondaryTextColor)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 10)
                }
                .buttonStyle(.plain)

                if station.id != items.prefix(6).last?.id {
                    Divider().overlay(usesLightPalette ? Color.black.opacity(0.08) : Color.white.opacity(0.08))
                }
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(usesLightPalette ? Color.white : Color.black.opacity(0.28))
        )
    }

    private var nearestStopInfo: NearbyStopInfo? {
        guard transportMode == .train || transportMode == .bus else { return nil }
        let stationsWithCoords = appState.mapStations
        guard !stationsWithCoords.isEmpty else { return nil }

        let referenceCoordinate = locationManager.location?.coordinate
            ?? CLLocationCoordinate2D(latitude: 54.0466, longitude: -2.8007)
        let referenceLocation = CLLocation(latitude: referenceCoordinate.latitude, longitude: referenceCoordinate.longitude)

        return stationsWithCoords
            .compactMap { station -> NearbyStopInfo? in
                guard let lat = station.latitude, let lon = station.longitude else { return nil }
                let stationLocation = CLLocation(latitude: lat, longitude: lon)
                let distance = referenceLocation.distance(from: stationLocation)
                return NearbyStopInfo(station: station, distanceMeters: distance)
            }
            .min(by: { $0.distanceMeters < $1.distanceMeters })
    }

    private func nearestStopCamera(for station: Station) -> MapCameraPosition {
        guard let lat = station.latitude, let lon = station.longitude else {
            return .region(
                MKCoordinateRegion(
                    center: CLLocationCoordinate2D(latitude: 54.0466, longitude: -2.8007),
                    span: MKCoordinateSpan(latitudeDelta: 0.04, longitudeDelta: 0.04)
                )
            )
        }

        return .region(
            MKCoordinateRegion(
                center: CLLocationCoordinate2D(latitude: lat, longitude: lon),
                span: MKCoordinateSpan(latitudeDelta: 0.02, longitudeDelta: 0.02)
            )
        )
    }

    private func distanceText(for meters: CLLocationDistance) -> String {
        if meters < 1000 {
            return "\(Int(meters.rounded()))m"
        }
        return String(format: "%.1fkm", meters / 1000)
    }

    private func isStopSaved(_ stationId: Int) -> Bool {
        savedStops.contains(where: { $0.stationId == stationId })
    }

    private func toggleSavedStop(_ stop: NearbyStopInfo) {
        if let idx = savedStops.firstIndex(where: { $0.stationId == stop.station.id }) {
            savedStops.remove(at: idx)
        } else {
            savedStops.insert(
                SavedStop(
                    stationId: stop.station.id,
                    name: stop.station.name,
                    code: stop.station.code,
                    mode: transportMode,
                    distanceText: distanceText(for: stop.distanceMeters)
                ),
                at: 0
            )
        }
    }

    private func toggleSavedStopFromMap(_ station: Station) {
        if let idx = savedStops.firstIndex(where: { $0.stationId == station.id }) {
            savedStops.remove(at: idx)
        } else {
            savedStops.insert(
                SavedStop(
                    stationId: station.id,
                    name: station.name,
                    code: station.code,
                    mode: mapDepartureMode,
                    distanceText: "--"
                ),
                at: 0
            )
        }
    }

    private func bootstrapPlacesIfNeeded() async {
        guard !hasBootstrappedPlaces else { return }
        hasBootstrappedPlaces = true
        let categories = await placesService.fetchCategories()
        placesCategories = categories
    }

    private func isPlaceSavedAsStop(_ place: Place) -> Bool {
        savedStops.contains(where: { $0.name == place.name })
    }

    private func toggleSavedStopFromPlace(_ place: Place) {
        if let idx = savedStops.firstIndex(where: { $0.name == place.name }) {
            savedStops.remove(at: idx)
        } else {
            savedStops.insert(
                SavedStop(
                    stationId: -1,
                    name: place.name,
                    code: "--",
                    mode: transportMode,
                    distanceText: ""
                ),
                at: 0
            )
        }
    }

    private func planViaPlace(_ place: Place) {
        selectedTab = .home
        let nearest = appState.stations.min(by: {
            let d0 = pow($0.latitude ?? 0 - place.latitude, 2) + pow($0.longitude ?? 0 - place.longitude, 2)
            let d1 = pow($1.latitude ?? 0 - place.latitude, 2) + pow($1.longitude ?? 0 - place.longitude, 2)
            return d0 < d1
        })
        if let station = nearest {
            destinationId = station.id
        }
    }

    private func openDirections(to place: Place) {
        let destination = MKMapItem(placemark: MKPlacemark(coordinate: place.coordinate))
        destination.name = place.name
        var items: [MKMapItem] = []
        if let location = locationManager.location {
            let source = MKMapItem(placemark: MKPlacemark(coordinate: location.coordinate))
            source.name = t(.currentLocation)
            items.append(source)
        }
        items.append(destination)
        MKMapItem.openMaps(with: items, launchOptions: [MKLaunchOptionsDirectionsModeKey: MKLaunchOptionsDirectionsModeTransit])
    }

    private func showDepartures(for station: Station) {
        selectedTab = .map
        selectedMapStationId = station.id
        mapDepartureMode = transportMode == .bus ? .bus : .train
        mapPanelExpanded = true
        if let lat = station.latitude, let lon = station.longitude {
            mapPosition = .region(
                MKCoordinateRegion(
                    center: CLLocationCoordinate2D(latitude: lat, longitude: lon),
                    span: MKCoordinateSpan(latitudeDelta: 0.08, longitudeDelta: 0.08)
                )
            )
        }
    }

    private func openMapLiveTrack(for arrival: MapArrival, from station: Station) {
        let normalizedDestination = arrival.destination.lowercased()
        let destination = appState.stations.first { candidate in
            candidate.name.lowercased() == normalizedDestination
                || candidate.name.lowercased().contains(normalizedDestination)
                || normalizedDestination.contains(candidate.name.lowercased())
        }

        var ids: [Int] = [station.id]
        if let destination, destination.id != station.id {
            if let route = appState.findRoute(originId: station.id, destinationId: destination.id, useBFS: false),
               !route.stationIds.isEmpty {
                ids = route.stationIds
            } else {
                ids = [station.id, destination.id]
            }
        }

        let serviceTitle = "\(arrival.mode.title(in: appLanguage)) \(arrival.service) • \(station.name) -> \(arrival.destination)"
        mapLiveTrackContext = MapLiveTrackContext(
            title: serviceTitle,
            operatorName: arrival.operatorName,
            stationIds: ids
        )
    }

    private func savedTrip(for context: MapLiveTrackContext) -> SavedTrip {
        let key = "map-live-\(context.stationIds.map(String.init).joined(separator: "-"))-\(context.title.lowercased())"
        return SavedTrip(
            key: key,
            title: context.title,
            subtitle: "Live tracking route",
            canBook: true
        )
    }

    private func toggleSavedMapLiveTrip(_ trip: SavedTrip) {
        if let idx = savedTrips.firstIndex(where: { $0.key == trip.key }) {
            savedTrips.remove(at: idx)
        } else {
            savedTrips.insert(trip, at: 0)
        }
    }

    private func openDirections(to station: Station) {
        guard let lat = station.latitude, let lon = station.longitude else { return }
        let destination = MKMapItem(placemark: MKPlacemark(coordinate: CLLocationCoordinate2D(latitude: lat, longitude: lon)))
        destination.name = station.name

        var items: [MKMapItem] = []
        if let location = locationManager.location {
            let source = MKMapItem(placemark: MKPlacemark(coordinate: location.coordinate))
            source.name = t(.currentLocation)
            items.append(source)
        }
        items.append(destination)

        MKMapItem.openMaps(with: items, launchOptions: [MKLaunchOptionsDirectionsModeKey: MKLaunchOptionsDirectionsModeTransit])
    }

    private func triggerSMSNotification() {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        let timeStamp = formatter.string(from: Date())
        let message = "Nexo alert: Your route update is ready (\(timeStamp))."
        smsBody = message
        notifications.insert(
            AccountNotification(title: "SMS notification", subtitle: message),
            at: 0
        )
        if MFMessageComposeViewController.canSendText() {
            showSMSComposer = true
        } else {
            smsAlertMessage = "SMS is not available on this device."
        }
    }

    private func openDirectionsForTicket() {
        if let lancaster = appState.stations.first(where: { $0.code == "LAN" }) {
            openDirections(to: lancaster)
        } else if let firstStation = appState.stations.first {
            openDirections(to: firstStation)
        }
    }

    private func addToWalletTapped() {
        guard PKAddPassesViewController.canAddPasses() else {
            walletMessage = t(.walletUnavailable)
            return
        }

        if let bundledPass = loadBundledPass() {
            walletPresentation = WalletPassPresentation(passes: [bundledPass])
            return
        }
        showPassImporter = true
    }

    private func loadBundledPass() -> PKPass? {
        guard
            let url = Bundle.main.url(forResource: "TrainTicket", withExtension: "pkpass"),
            let data = try? Data(contentsOf: url),
            let pass = try? PKPass(data: data)
        else {
            return nil
        }
        return pass
    }

    private func handlePassImport(result: Result<URL, Error>) {
        switch result {
        case .success(let url):
            do {
                let didAccess = url.startAccessingSecurityScopedResource()
                defer {
                    if didAccess {
                        url.stopAccessingSecurityScopedResource()
                    }
                }
                let data = try Data(contentsOf: url)
                let pass = try PKPass(data: data)
                walletPresentation = WalletPassPresentation(passes: [pass])
                walletMessage = t(.walletReadyToAdd)
                notifications.insert(
                    AccountNotification(
                        title: t(.appleWallet),
                        subtitle: t(.walletReadyToAdd)
                    ),
                    at: 0
                )
            } catch {
                walletMessage = t(.walletInvalidPass)
                notifications.insert(
                    AccountNotification(
                        title: t(.appleWallet),
                        subtitle: t(.walletInvalidPass)
                    ),
                    at: 0
                )
            }
        case .failure:
            walletMessage = t(.walletNoPass)
            notifications.insert(
                AccountNotification(
                    title: t(.appleWallet),
                    subtitle: t(.walletNoPass)
                ),
                at: 0
            )
        }
    }

    private func upcomingMapArrivals(for station: Station) -> [MapArrival] {
        let trainServices = ["A1", "N4", "T2", "W8", "R6"]
        let busServices = ["38", "14", "22", "19", "46"]
        let destinations = ["Lancaster", "Preston", "Blackpool North", "Penrith", "Warrington"]
        let trainOperators = ["Avanti West Coast", "Northern", "TransPennine", "West Midlands", "Regional Rail"]
        let busOperators = ["Stagecoach", "Stagecoach", "National Express", "Local Bus", "Metroline"]
        let colors: [Color] = [.red, .blue, .purple, .orange, .green]
        let baseOffset = station.id % 4
        let etaPattern: [Double] = [0.0, 0.6, 3.0, 7.0, 12.0, 18.0]

        let trainItems = (0..<6).map { idx in
            let i = (idx + baseOffset) % trainServices.count
            return MapArrival(
                service: trainServices[i],
                destination: destinations[i],
                operatorName: trainOperators[i],
                etaMinutes: etaPattern[idx],
                color: colors[i],
                mode: .train
            )
        }

        let busItems = (0..<6).map { idx in
            let i = (idx + baseOffset) % busServices.count
            return MapArrival(
                service: busServices[i],
                destination: destinations[i],
                operatorName: busOperators[i],
                etaMinutes: etaPattern[idx],
                color: colors[i],
                mode: .bus
            )
        }

        return trainItems + busItems
    }

    private func mapEtaText(for item: MapArrival) -> String {
        if item.etaMinutes <= 0.0 {
            return "\(item.mode.title(in: appLanguage)) \(t(.atTheStation))"
        }
        if item.etaMinutes < 1.0 {
            return t(.due)
        }
        return "\(Int(ceil(item.etaMinutes))) \(t(.min))"
    }

}

private enum AppTab: Hashable {
    case home
    case map
    case tickets
    case account
}

private enum AppLanguage: String, CaseIterable {
    case en
    case es
    case fr
    case de
    case zh

    var displayName: String {
        switch self {
        case .en: return "English"
        case .es: return "Español"
        case .fr: return "Français"
        case .de: return "Deutsch"
        case .zh: return "中文"
        }
    }
}

private enum AppCurrency: String, CaseIterable {
    case eur = "EUR"
    case gbp = "GBP"
    case usd = "USD"
    case cny = "CNY"

    var code: String { rawValue }

    var symbol: String {
        switch self {
        case .eur: return "€"
        case .gbp: return "£"
        case .usd: return "$"
        case .cny: return "¥"
        }
    }

    var displayName: String {
        switch self {
        case .eur: return "Euro (€)"
        case .gbp: return "Pounds (£)"
        case .usd: return "US Dollar ($)"
        case .cny: return "Chinese Yuan (¥)"
        }
    }

    // Fixed conversion rates from EUR requested for this app demo.
    // 1 EUR = 0.865 GBP, 1.165 USD, 7.95 CNY
    var rateFromEUR: Double {
        switch self {
        case .eur: return 1.0
        case .gbp: return 0.865
        case .usd: return 1.165
        case .cny: return 7.95
        }
    }
}

private enum L {
    enum Key: String {
        case home, map, tickets, account
        case welcomeSplash, welcomeBack
        case searchAllTrains, recommended, book
        case station, stop, away, directions, departures
        case find, route, segments, min
        case yourTicket, readyToScan, getDirections, addToAppleWallet
        case studentAccount, quickActions, savedTrips, savedStops, notifications, settings
        case back, estimatedTime
        case planJourneyTitle, planJourneySubtitle, searchTrains, `where`, origin, destination
        case typeDeparture, typeArrival, when, single, returnLabel, openReturn
        case travelDates, outbound, notRequired, outboundDate, returnDate, returnDateOptional
        case localOperators, passengers, railcard, currency
        case timesAndPrices, findTimesAndPrices, departure, arrival, duration, changes, direct, changeSingular, changesPlural, services
        case railcardApplied, noRailcardApplied
        case personalData, fullName, email, phone, appearance, theme, dark, light, system, language
        case accessibility, fontSize, screenReader, voiceOverHelpTitle, voiceOverHelpBody
        case loginSubtitle, registerSubtitle, username, phoneNumber, password, repeatPassword
        case usernameOrEmail, createAccount, logIn, alreadyHaveAccount, newHereRegister
        case userNotFound, incorrectPassword, completeAllFields, passwordsNoMatch, logOut
        case invalidEmail, invalidPhone
        case noTrips, noNotifications, noStops
        case locatingNearestStop, appleWallet, ok
        case currentLocation, walletUnavailable, walletInvalidPass, walletNoPass
        case walletSuccess, walletReadyToAdd
        case viewLaterDepartures, due, atTheStation
        case train, bus, taxi, walk, trainStage, busStage, taxiStage, walkStage
    }

    static func text(_ key: Key, lang: AppLanguage) -> String {
        table[lang]?[key.rawValue] ?? table[.en]?[key.rawValue] ?? key.rawValue
    }

    static func passengerCount(_ count: Int, lang: AppLanguage) -> String {
        switch lang {
        case .en:
            return "\(count) passenger" + (count == 1 ? "" : "s")
        case .es:
            return "\(count) pasajero" + (count == 1 ? "" : "s")
        case .fr:
            return "\(count) passager" + (count == 1 ? "" : "s")
        case .de:
            return "\(count) Fahrgast" + (count == 1 ? "" : "e")
        case .zh:
            return "\(count) 位乘客"
        }
    }

    private static let table: [AppLanguage: [String: String]] = [
        .en: [
            "home": "Home", "map": "Map", "tickets": "Tickets", "account": "Account",
            "welcomeSplash": "Welcome to the Transport App", "welcomeBack": "Welcome back",
            "searchAllTrains": "Search all trains", "recommended": "Recommended", "book": "Book",
            "station": "STATION", "stop": "STOP", "away": "away", "directions": "Directions", "departures": "Departures",
            "find": "Find", "route": "Route", "segments": "Segments", "min": "min",
            "yourTicket": "Your Ticket", "readyToScan": "Ready to scan", "getDirections": "Get Directions", "addToAppleWallet": "Add to Apple Wallet",
            "studentAccount": "Student Account", "quickActions": "Quick Actions", "savedTrips": "Saved Trips", "savedStops": "Saved Stops", "notifications": "Notifications", "settings": "Settings",
            "back": "Back", "estimatedTime": "Estimated time",
            "planJourneyTitle": "Plan Your Rail Journey", "planJourneySubtitle": "Enter where you are going and customise your trip", "searchTrains": "Search Trains", "where": "Where", "origin": "Origin", "destination": "Destination",
            "typeDeparture": "Type departure station", "typeArrival": "Type arrival station", "when": "When", "single": "Single", "returnLabel": "Return", "openReturn": "Open Return",
            "travelDates": "Travel Dates", "outbound": "Outbound", "notRequired": "Not required", "outboundDate": "Outbound Date", "returnDate": "Return Date", "returnDateOptional": "Return Date (optional guidance)",
            "localOperators": "Local Operators (NOC)", "passengers": "Passengers", "railcard": "Railcard", "currency": "Currency",
            "timesAndPrices": "Times & Prices", "findTimesAndPrices": "Find times & prices", "departure": "Departure", "arrival": "Arrival", "duration": "Duration", "changes": "Changes", "direct": "Direct", "changeSingular": "1 change", "changesPlural": "changes", "services": "Services",
            "railcardApplied": "Railcard applied", "noRailcardApplied": "No railcard",
            "personalData": "Personal Data", "fullName": "Full Name", "email": "Email", "phone": "Phone", "appearance": "Appearance", "theme": "Theme", "dark": "Dark", "light": "Light", "system": "System", "language": "Language",
            "accessibility": "Accessibility", "fontSize": "Font Size", "screenReader": "Screen Reader",
            "voiceOverHelpTitle": "How to enable VoiceOver",
            "voiceOverHelpBody": "Open Settings > Accessibility > VoiceOver and turn it on. You can also add VoiceOver to Control Center, or set the Accessibility Shortcut to toggle it with a triple‑click on the Side button.",
            "loginSubtitle": "Sign in to continue",
            "registerSubtitle": "Create your account to continue",
            "username": "Username",
            "phoneNumber": "Phone number",
            "password": "Password",
            "repeatPassword": "Repeat password",
            "usernameOrEmail": "Username or email",
            "createAccount": "Create account",
            "logIn": "Log In",
            "alreadyHaveAccount": "Already have an account? Log in",
            "newHereRegister": "New here? Register",
            "userNotFound": "User not found.",
            "incorrectPassword": "Incorrect password.",
            "completeAllFields": "Please complete all fields.",
            "passwordsNoMatch": "Passwords do not match.",
            "logOut": "Log Out",
            "invalidEmail": "Please enter a valid email.",
            "invalidPhone": "Please enter a valid phone number.",
            "noTrips": "No trips to show", "noNotifications": "No notifications to show", "noStops": "No stops to show",
            "locatingNearestStop": "Locating nearest stop...", "appleWallet": "Apple Wallet", "ok": "OK",
            "currentLocation": "Current Location", "walletUnavailable": "This device cannot add passes to Apple Wallet.", "walletInvalidPass": "Could not read this pass. Please choose a valid signed .pkpass file.", "walletNoPass": "No pass selected.",
            "walletSuccess": "Ticket added to Apple Wallet successfully.",
            "walletReadyToAdd": "Pass loaded. Confirm Add in Apple Wallet.",
            "viewLaterDepartures": "View later departures", "due": "Due", "atTheStation": "at the station",
            "train": "Train", "bus": "Bus", "taxi": "Taxi", "walk": "Walk", "trainStage": "Train Stage", "busStage": "Bus Stage", "taxiStage": "Taxi Stage", "walkStage": "Walk Stage"
        ],
        .es: [
            "home": "Inicio", "map": "Mapa", "tickets": "Billetes", "account": "Cuenta",
            "welcomeSplash": "Bienvenido a la aplicación de transporte", "welcomeBack": "Bienvenido de nuevo",
            "searchAllTrains": "Buscar todos los trenes", "recommended": "Recomendado", "book": "Reservar",
            "station": "ESTACIÓN", "stop": "PARADA", "away": "de distancia", "directions": "Direcciones", "departures": "Salidas",
            "find": "Buscar", "route": "ruta", "segments": "Tramos", "min": "min",
            "yourTicket": "Tu billete", "readyToScan": "Listo para escanear", "getDirections": "Obtener direcciones", "addToAppleWallet": "Añadir a Apple Wallet",
            "studentAccount": "Cuenta de estudiante", "quickActions": "Acciones rápidas", "savedTrips": "Viajes guardados", "savedStops": "Paradas guardadas", "notifications": "Notificaciones", "settings": "Ajustes",
            "back": "Volver", "estimatedTime": "Tiempo estimado",
            "planJourneyTitle": "Planifica tu viaje en tren", "planJourneySubtitle": "Indica a dónde vas y personaliza tu viaje", "searchTrains": "Buscar trenes", "where": "Dónde", "origin": "Origen", "destination": "Destino",
            "typeDeparture": "Escribe estación de salida", "typeArrival": "Escribe estación de llegada", "when": "Cuándo", "single": "Solo ida", "returnLabel": "Ida y vuelta", "openReturn": "Vuelta abierta",
            "travelDates": "Fechas de viaje", "outbound": "Ida", "notRequired": "No requerido", "outboundDate": "Fecha de ida", "returnDate": "Fecha de vuelta", "returnDateOptional": "Fecha de vuelta (opcional)",
            "localOperators": "Operadores locales (NOC)", "passengers": "Pasajeros", "railcard": "Railcard", "currency": "Moneda",
            "timesAndPrices": "Horarios y precios", "findTimesAndPrices": "Ver horarios y precios", "departure": "Salida", "arrival": "Llegada", "duration": "Duración", "changes": "Cambios", "direct": "Directo", "changeSingular": "1 cambio", "changesPlural": "cambios", "services": "Servicios",
            "railcardApplied": "Railcard aplicada", "noRailcardApplied": "Sin railcard",
            "personalData": "Datos personales", "fullName": "Nombre completo", "email": "Correo", "phone": "Teléfono", "appearance": "Apariencia", "theme": "Tema", "dark": "Oscuro", "light": "Claro", "system": "Sistema", "language": "Idioma",
            "accessibility": "Accesibilidad", "fontSize": "Tamaño de letra", "screenReader": "Narrador de pantalla",
            "voiceOverHelpTitle": "Cómo activar VoiceOver",
            "voiceOverHelpBody": "Abre Ajustes > Accesibilidad > VoiceOver y actívalo. También puedes añadir VoiceOver al Centro de control o configurar el Atajo de accesibilidad para activarlo con triple pulsación del botón lateral.",
            "loginSubtitle": "Inicia sesión para continuar",
            "registerSubtitle": "Crea tu cuenta para continuar",
            "username": "Nombre de usuario",
            "phoneNumber": "Número de teléfono",
            "password": "Contraseña",
            "repeatPassword": "Repite la contraseña",
            "usernameOrEmail": "Usuario o correo",
            "createAccount": "Crear cuenta",
            "logIn": "Entrar",
            "alreadyHaveAccount": "¿Ya tienes cuenta? Inicia sesión",
            "newHereRegister": "¿Nuevo por aquí? Regístrate",
            "userNotFound": "Usuario no encontrado.",
            "incorrectPassword": "Contraseña incorrecta.",
            "completeAllFields": "Completa todos los campos.",
            "passwordsNoMatch": "Las contraseñas no coinciden.",
            "logOut": "Cerrar sesión",
            "invalidEmail": "Introduce un email válido.",
            "invalidPhone": "Introduce un teléfono válido.",
            "noTrips": "No hay viajes para mostrar", "noNotifications": "No hay notificaciones para mostrar", "noStops": "No hay paradas para mostrar",
            "locatingNearestStop": "Buscando parada más cercana...", "appleWallet": "Apple Wallet", "ok": "OK",
            "currentLocation": "Ubicación actual", "walletUnavailable": "Este dispositivo no puede añadir pases a Apple Wallet.", "walletInvalidPass": "No se pudo leer el pase. Selecciona un .pkpass válido y firmado.", "walletNoPass": "No se ha seleccionado ningún pase.",
            "walletSuccess": "Billete añadido a Apple Wallet correctamente.",
            "walletReadyToAdd": "Pase cargado. Confirma Anadir en Apple Wallet.",
            "viewLaterDepartures": "Ver salidas posteriores", "due": "Inminente", "atTheStation": "en la estación",
            "train": "Tren", "bus": "Bus", "taxi": "Taxi", "walk": "Andando", "trainStage": "Etapa de tren", "busStage": "Etapa de bus", "taxiStage": "Etapa de taxi", "walkStage": "Etapa a pie"
        ],
        .fr: [
            "home": "Accueil", "map": "Carte", "tickets": "Billets", "account": "Compte",
            "welcomeSplash": "Bienvenue dans l'application de transport", "welcomeBack": "Bon retour",
            "searchAllTrains": "Rechercher tous les trains", "recommended": "Recommandé", "book": "Réserver",
            "station": "GARE", "stop": "ARRÊT", "away": "de distance", "directions": "Itinéraire", "departures": "Départs",
            "find": "Trouver", "route": "trajet", "segments": "Segments", "min": "min",
            "yourTicket": "Votre billet", "readyToScan": "Prêt à scanner", "getDirections": "Obtenir l'itinéraire", "addToAppleWallet": "Ajouter à Apple Wallet",
            "studentAccount": "Compte étudiant", "quickActions": "Actions rapides", "savedTrips": "Trajets enregistrés", "savedStops": "Arrêts enregistrés", "notifications": "Notifications", "settings": "Paramètres",
            "back": "Retour", "estimatedTime": "Temps estimé",
            "planJourneyTitle": "Planifiez votre voyage en train", "planJourneySubtitle": "Entrez votre destination et personnalisez votre trajet", "searchTrains": "Rechercher des trains", "where": "Où", "origin": "Origine", "destination": "Destination",
            "typeDeparture": "Saisir la gare de départ", "typeArrival": "Saisir la gare d'arrivée", "when": "Quand", "single": "Aller simple", "returnLabel": "Aller-retour", "openReturn": "Retour ouvert",
            "travelDates": "Dates de voyage", "outbound": "Aller", "notRequired": "Non requis", "outboundDate": "Date aller", "returnDate": "Date retour", "returnDateOptional": "Date retour (optionnelle)",
            "localOperators": "Opérateurs locaux (NOC)", "passengers": "Passagers", "railcard": "Railcard", "currency": "Devise",
            "timesAndPrices": "Horaires et prix", "findTimesAndPrices": "Voir horaires et prix", "departure": "Départ", "arrival": "Arrivée", "duration": "Durée", "changes": "Correspondances", "direct": "Direct", "changeSingular": "1 correspondance", "changesPlural": "correspondances", "services": "Services",
            "railcardApplied": "Railcard appliquée", "noRailcardApplied": "Sans railcard",
            "personalData": "Données personnelles", "fullName": "Nom complet", "email": "E-mail", "phone": "Téléphone", "appearance": "Apparence", "theme": "Thème", "dark": "Sombre", "light": "Clair", "system": "Système", "language": "Langue",
            "accessibility": "Accessibilité", "fontSize": "Taille du texte", "screenReader": "Lecteur d’écran",
            "voiceOverHelpTitle": "Activer VoiceOver",
            "voiceOverHelpBody": "Ouvrez Réglages > Accessibilité > VoiceOver et activez‑le. Vous pouvez aussi l’ajouter au Centre de contrôle ou définir le raccourci d’accessibilité (triple‑clic sur le bouton latéral).",
            "loginSubtitle": "Connectez-vous pour continuer",
            "registerSubtitle": "Créez votre compte pour continuer",
            "username": "Nom d’utilisateur",
            "phoneNumber": "Numéro de téléphone",
            "password": "Mot de passe",
            "repeatPassword": "Répéter le mot de passe",
            "usernameOrEmail": "Utilisateur ou e‑mail",
            "createAccount": "Créer un compte",
            "logIn": "Se connecter",
            "alreadyHaveAccount": "Déjà un compte ? Se connecter",
            "newHereRegister": "Nouveau ? S’inscrire",
            "userNotFound": "Utilisateur introuvable.",
            "incorrectPassword": "Mot de passe incorrect.",
            "completeAllFields": "Veuillez compléter tous les champs.",
            "passwordsNoMatch": "Les mots de passe ne correspondent pas.",
            "logOut": "Se déconnecter",
            "invalidEmail": "Veuillez saisir un e‑mail valide.",
            "invalidPhone": "Veuillez saisir un numéro valide.",
            "noTrips": "Aucun trajet à afficher", "noNotifications": "Aucune notification à afficher", "noStops": "Aucun arrêt à afficher",
            "locatingNearestStop": "Recherche de l'arrêt le plus proche...", "appleWallet": "Apple Wallet", "ok": "OK",
            "currentLocation": "Position actuelle", "walletUnavailable": "Cet appareil ne peut pas ajouter de pass à Apple Wallet.", "walletInvalidPass": "Impossible de lire ce pass. Veuillez choisir un fichier .pkpass signé valide.", "walletNoPass": "Aucun pass sélectionné.",
            "walletSuccess": "Billet ajoute a Apple Wallet avec succes.",
            "walletReadyToAdd": "Pass charge. Confirmez l'ajout dans Apple Wallet.",
            "viewLaterDepartures": "Voir les départs suivants", "due": "Imminent", "atTheStation": "à la station",
            "train": "Train", "bus": "Bus", "taxi": "Taxi", "walk": "Marche", "trainStage": "Étape train", "busStage": "Étape bus", "taxiStage": "Étape taxi", "walkStage": "Étape à pied"
        ],
        .de: [
            "home": "Start", "map": "Karte", "tickets": "Tickets", "account": "Konto",
            "welcomeSplash": "Willkommen in der Transport-App", "welcomeBack": "Willkommen zurück",
            "searchAllTrains": "Alle Züge suchen", "recommended": "Empfohlen", "book": "Buchen",
            "station": "BAHNHOF", "stop": "HALTESTELLE", "away": "entfernt", "directions": "Route", "departures": "Abfahrten",
            "find": "Finde", "route": "Route", "segments": "Abschnitte", "min": "Min",
            "yourTicket": "Ihr Ticket", "readyToScan": "Scanbereit", "getDirections": "Route anzeigen", "addToAppleWallet": "Zu Apple Wallet hinzufügen",
            "studentAccount": "Studentenkonto", "quickActions": "Schnellaktionen", "savedTrips": "Gespeicherte Reisen", "savedStops": "Gespeicherte Halte", "notifications": "Benachrichtigungen", "settings": "Einstellungen",
            "back": "Zurück", "estimatedTime": "Geschätzte Zeit",
            "planJourneyTitle": "Plane deine Zugreise", "planJourneySubtitle": "Gib dein Ziel ein und passe die Reise an", "searchTrains": "Züge suchen", "where": "Wohin", "origin": "Start", "destination": "Ziel",
            "typeDeparture": "Abfahrtsbahnhof eingeben", "typeArrival": "Ankunftsbahnhof eingeben", "when": "Wann", "single": "Einfach", "returnLabel": "Hin und zurück", "openReturn": "Offene Rückfahrt",
            "travelDates": "Reisedaten", "outbound": "Hin", "notRequired": "Nicht erforderlich", "outboundDate": "Hinreisedatum", "returnDate": "Rückreisedatum", "returnDateOptional": "Rückreisedatum (optional)",
            "localOperators": "Lokale Betreiber (NOC)", "passengers": "Passagiere", "railcard": "Railcard", "currency": "Währung",
            "timesAndPrices": "Zeiten und Preise", "findTimesAndPrices": "Zeiten und Preise anzeigen", "departure": "Abfahrt", "arrival": "Ankunft", "duration": "Dauer", "changes": "Umstiege", "direct": "Direkt", "changeSingular": "1 Umstieg", "changesPlural": "Umstiege", "services": "Verbindungen",
            "railcardApplied": "Railcard angewendet", "noRailcardApplied": "Keine railcard",
            "personalData": "Persönliche Daten", "fullName": "Vollständiger Name", "email": "E-Mail", "phone": "Telefon", "appearance": "Darstellung", "theme": "Design", "dark": "Dunkel", "light": "Hell", "system": "System", "language": "Sprache",
            "accessibility": "Barrierefreiheit", "fontSize": "Schriftgröße", "screenReader": "Bildschirmleser",
            "voiceOverHelpTitle": "VoiceOver aktivieren",
            "voiceOverHelpBody": "Öffne Einstellungen > Bedienungshilfen > VoiceOver und aktiviere es. Du kannst VoiceOver auch zum Kontrollzentrum hinzufügen oder den Bedienungshilfen‑Kurzbefehl (dreifach die Seitentaste) nutzen.",
            "loginSubtitle": "Zum Fortfahren anmelden",
            "registerSubtitle": "Konto erstellen, um fortzufahren",
            "username": "Benutzername",
            "phoneNumber": "Telefonnummer",
            "password": "Passwort",
            "repeatPassword": "Passwort wiederholen",
            "usernameOrEmail": "Benutzername oder E‑Mail",
            "createAccount": "Konto erstellen",
            "logIn": "Anmelden",
            "alreadyHaveAccount": "Schon ein Konto? Anmelden",
            "newHereRegister": "Neu hier? Registrieren",
            "userNotFound": "Benutzer nicht gefunden.",
            "incorrectPassword": "Falsches Passwort.",
            "completeAllFields": "Bitte alle Felder ausfüllen.",
            "passwordsNoMatch": "Passwörter stimmen nicht überein.",
            "logOut": "Abmelden",
            "invalidEmail": "Bitte eine gültige E‑Mail eingeben.",
            "invalidPhone": "Bitte eine gültige Telefonnummer eingeben.",
            "noTrips": "Keine Reisen vorhanden", "noNotifications": "Keine Benachrichtigungen vorhanden", "noStops": "Keine Haltestellen vorhanden",
            "locatingNearestStop": "Nächste Haltestelle wird gesucht...", "appleWallet": "Apple Wallet", "ok": "OK",
            "currentLocation": "Aktueller Standort", "walletUnavailable": "Dieses Gerät kann keine Pässe zu Apple Wallet hinzufügen.", "walletInvalidPass": "Dieser Pass konnte nicht gelesen werden. Bitte eine gültige signierte .pkpass-Datei wählen.", "walletNoPass": "Kein Pass ausgewählt.",
            "walletSuccess": "Ticket erfolgreich zu Apple Wallet hinzugefugt.",
            "walletReadyToAdd": "Pass geladen. Bitte Hinzufugen in Apple Wallet bestatigen.",
            "viewLaterDepartures": "Spätere Abfahrten anzeigen", "due": "Sofort", "atTheStation": "an der Station",
            "train": "Zug", "bus": "Bus", "taxi": "Taxi", "walk": "Zu Fuß", "trainStage": "Zugabschnitt", "busStage": "Busabschnitt", "taxiStage": "Taxiabschnitt", "walkStage": "Fußweg"
        ],
        .zh: [
            "home": "首页", "map": "地图", "tickets": "车票", "account": "账户",
            "welcomeSplash": "欢迎使用交通应用", "welcomeBack": "欢迎回来",
            "searchAllTrains": "搜索所有火车", "recommended": "推荐", "book": "预订",
            "station": "车站", "stop": "站点", "away": "距离", "directions": "路线", "departures": "发车",
            "find": "查找", "route": "路线", "segments": "路段", "min": "分钟",
            "yourTicket": "您的车票", "readyToScan": "准备扫码", "getDirections": "获取路线", "addToAppleWallet": "添加到 Apple Wallet",
            "studentAccount": "学生账户", "quickActions": "快捷操作", "savedTrips": "已保存行程", "savedStops": "已保存站点", "notifications": "通知", "settings": "设置",
            "back": "返回", "estimatedTime": "预计时间",
            "planJourneyTitle": "规划你的火车行程", "planJourneySubtitle": "输入目的地并自定义行程", "searchTrains": "搜索火车", "where": "出行地点", "origin": "出发地", "destination": "目的地",
            "typeDeparture": "输入出发站", "typeArrival": "输入到达站", "when": "时间", "single": "单程", "returnLabel": "往返", "openReturn": "开放返程",
            "travelDates": "出行日期", "outbound": "去程", "notRequired": "不需要", "outboundDate": "去程日期", "returnDate": "返程日期", "returnDateOptional": "返程日期（可选）",
            "localOperators": "本地运营商 (NOC)", "passengers": "乘客", "railcard": "Railcard", "currency": "货币",
            "timesAndPrices": "时刻与票价", "findTimesAndPrices": "查看时刻与票价", "departure": "出发", "arrival": "到达", "duration": "耗时", "changes": "换乘", "direct": "直达", "changeSingular": "1 次换乘", "changesPlural": "次换乘", "services": "班次",
            "railcardApplied": "已应用 Railcard", "noRailcardApplied": "未使用 Railcard",
            "personalData": "个人资料", "fullName": "姓名", "email": "邮箱", "phone": "电话", "appearance": "外观", "theme": "主题", "dark": "深色", "light": "浅色", "system": "系统", "language": "语言",
            "accessibility": "辅助功能", "fontSize": "字体大小", "screenReader": "屏幕朗读",
            "voiceOverHelpTitle": "如何开启 VoiceOver",
            "voiceOverHelpBody": "打开“设置”>“辅助功能”>“VoiceOver”，并开启。也可以添加到“控制中心”，或设置辅助功能快捷键（侧边按钮三击）切换。",
            "loginSubtitle": "登录以继续",
            "registerSubtitle": "创建账户以继续",
            "username": "用户名",
            "phoneNumber": "电话号码",
            "password": "密码",
            "repeatPassword": "重复密码",
            "usernameOrEmail": "用户名或邮箱",
            "createAccount": "创建账户",
            "logIn": "登录",
            "alreadyHaveAccount": "已有账户？登录",
            "newHereRegister": "新用户？注册",
            "userNotFound": "未找到用户。",
            "incorrectPassword": "密码错误。",
            "completeAllFields": "请填写所有字段。",
            "passwordsNoMatch": "两次密码不一致。",
            "logOut": "退出登录",
            "invalidEmail": "请输入有效邮箱。",
            "invalidPhone": "请输入有效手机号。",
            "noTrips": "没有可显示的行程", "noNotifications": "没有可显示的通知", "noStops": "没有可显示的站点",
            "locatingNearestStop": "正在定位最近站点...", "appleWallet": "Apple Wallet", "ok": "确定",
            "currentLocation": "当前位置", "walletUnavailable": "此设备无法将票券添加到 Apple Wallet。", "walletInvalidPass": "无法读取该票券，请选择有效且已签名的 .pkpass 文件。", "walletNoPass": "未选择票券。",
            "walletSuccess": "车票已成功添加到 Apple Wallet。",
            "walletReadyToAdd": "票券已加载，请在 Apple Wallet 中确认添加。",
            "viewLaterDepartures": "查看稍后班次", "due": "即将到达", "atTheStation": "已到站",
            "train": "火车", "bus": "公交", "taxi": "出租车", "walk": "步行", "trainStage": "火车阶段", "busStage": "公交阶段", "taxiStage": "出租车阶段", "walkStage": "步行阶段"
        ]
    ]
}

private struct PlannedRoute {
    let mode: TransportMode
    let stationIds: [Int]
    let durationMins: Int
}

private struct PlannedRouteScreen: View {
    @Environment(\.dismiss) private var dismiss
    let plan: PlannedRoute
    let mapping: StationMapping
    let language: AppLanguage

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color(red: 0.03, green: 0.11, blue: 0.28), Color.black],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    Button {
                        dismiss()
                    } label: {
                        Text(L.text(.back, lang: language))
                            .font(.headline)
                            .foregroundStyle(.white)
                    }
                    Spacer()
                }

                Text(plan.mode.stageTitle(in: language))
                    .font(.title2.weight(.semibold))
                    .foregroundStyle(.white)

                VStack(alignment: .leading, spacing: 12) {
                    ForEach(Array(plan.stationIds.enumerated()), id: \.offset) { index, stationId in
                        HStack(spacing: 10) {
                            Circle()
                                .fill(index == 0 ? plan.mode.accentColor : Color.white.opacity(0.4))
                                .frame(width: 10, height: 10)
                            Text(mapping.name(for: stationId))
                                .foregroundStyle(.white)
                            Spacer()
                            Text(mapping.code(for: stationId))
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color.white.opacity(0.08))
                )

                HStack {
                    Text(L.text(.estimatedTime, lang: language))
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text("\(plan.durationMins) \(L.text(.min, lang: language))")
                        .font(.headline)
                        .foregroundStyle(.white)
                }

                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.top, 16)
        }
        .navigationBarBackButtonHidden(true)
            .toolbar(.hidden, for: .navigationBar)
        }

    }

private struct SearchTrainsScreen: View {
    @Environment(\.colorScheme) private var colorScheme
    let stations: [Station]
    let language: AppLanguage
    let selectedCurrencyRawValue: String
    @Binding var savedTrips: [SavedTrip]
    @State private var originId: Int?
    @State private var destinationId: Int?
    @State private var originQuery = ""
    @State private var destinationQuery = ""
    @State private var tripType: TripType = .single
    @State private var outboundDate: Date = .now
    @State private var returnDate: Date = Calendar.current.date(byAdding: .day, value: 1, to: .now) ?? .now
    @State private var passengerCount: Int = 1
    @State private var selectedRailcard: String
    @State private var showTimesAndPrices = false
    @FocusState private var focusedField: SearchField?

    init(stations: [Station], language: AppLanguage, selectedCurrencyRawValue: String, savedTrips: Binding<[SavedTrip]>) {
        self.stations = stations
        self.language = language
        self.selectedCurrencyRawValue = selectedCurrencyRawValue
        self._savedTrips = savedTrips
        _selectedRailcard = State(initialValue: RailcardOption.options(for: language).first ?? "No Railcard")
    }

    private var usesLightPalette: Bool {
        colorScheme == .light
    }

    private var primaryTextColor: Color {
        usesLightPalette ? .black : .white
    }

    private var secondaryTextColor: Color {
        usesLightPalette ? Color.black.opacity(0.60) : .secondary
    }

    private var cardFillColor: Color {
        usesLightPalette ? Color.white : Color.white.opacity(0.08)
    }

    private var cardStrokeColor: Color {
        usesLightPalette ? Color.black.opacity(0.10) : Color.white.opacity(0.06)
    }

    private var fieldFillColor: Color {
        usesLightPalette ? Color.black.opacity(0.06) : Color.white.opacity(0.06)
    }

    private var hasValidWhere: Bool {
        guard let originId, let destinationId else { return false }
        return originId != destinationId
    }

    var body: some View {
        ZStack {
            LinearGradient(
                colors: usesLightPalette
                    ? [Color.white, Color(red: 0.95, green: 0.96, blue: 0.98)]
                    : [Color(red: 0.02, green: 0.09, blue: 0.20), Color.black],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 16) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(L.text(.planJourneyTitle, lang: language))
                            .font(.custom("AvenirNext-Bold", size: 28))
                            .foregroundStyle(primaryTextColor)
                        Text(L.text(.planJourneySubtitle, lang: language))
                            .font(.custom("AvenirNext-Regular", size: 14))
                            .foregroundStyle(secondaryTextColor)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)

                    whereCard
                    localOperatorsCard

                    if hasValidWhere {
                        savedRouteCard
                        whenCard
                        travelDatesCard
                        passengersCard
                        findTimesAndPricesButton
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 12)
                .padding(.bottom, 26)
            }

            NavigationLink(isActive: $showTimesAndPrices) {
                JourneyTimesPricesScreen(
                    language: language,
                    originName: originStation?.name ?? L.text(.origin, lang: language),
                    destinationName: destinationStation?.name ?? L.text(.destination, lang: language),
                    outboundDate: outboundDate,
                    tripType: tripType,
                    passengerCount: passengerCount,
                    selectedRailcard: selectedRailcard,
                    selectedCurrencyRawValue: selectedCurrencyRawValue
                )
            } label: {
                EmptyView()
            }
            .hidden()
        }
        .navigationTitle(L.text(.searchTrains, lang: language))
        .navigationBarTitleDisplayMode(.inline)
    }

    private var findTimesAndPricesButton: some View {
        Button {
            focusedField = nil
            showTimesAndPrices = true
        } label: {
            Text(L.text(.findTimesAndPrices, lang: language))
                .font(.custom("AvenirNext-DemiBold", size: 18))
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 13)
                .background(
                    RoundedRectangle(cornerRadius: 14)
                        .fill(Color.blue)
                )
        }
        .buttonStyle(.plain)
    }

    private var whereCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(L.text(.where, lang: language))
                .font(.custom("AvenirNext-DemiBold", size: 20))
                .foregroundStyle(primaryTextColor)

            stationSearchField(
                title: L.text(.origin, lang: language),
                placeholder: L.text(.typeDeparture, lang: language),
                text: $originQuery,
                field: .origin
            )

            if focusedField == .origin && !originSuggestions.isEmpty {
                suggestionsList(originSuggestions) { station in
                    originQuery = station.name
                    originId = station.id
                    focusedField = nil
                }
            }

            stationSearchField(
                title: L.text(.destination, lang: language),
                placeholder: L.text(.typeArrival, lang: language),
                text: $destinationQuery,
                field: .destination
            )

            if focusedField == .destination && !destinationSuggestions.isEmpty {
                suggestionsList(destinationSuggestions) { station in
                    destinationQuery = station.name
                    destinationId = station.id
                    focusedField = nil
                }
            }
        }
        .padding(14)
        .background(sectionCard)
        .onChange(of: originQuery) { _, newValue in
            originId = exactMatch(for: newValue)?.id
        }
        .onChange(of: destinationQuery) { _, newValue in
            destinationId = exactMatch(for: newValue)?.id
        }
    }

    private var whenCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(L.text(.when, lang: language))
                .font(.custom("AvenirNext-DemiBold", size: 20))
                .foregroundStyle(primaryTextColor)

            HStack(spacing: 8) {
                ForEach(TripType.allCases, id: \.self) { type in
                    Button {
                        tripType = type
                    } label: {
                        Text(type.shortTitle(in: language))
                            .font(.custom("AvenirNext-DemiBold", size: 13))
                            .foregroundStyle(tripType == type ? .white : secondaryTextColor)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                            .background(
                                RoundedRectangle(cornerRadius: 10)
                                    .fill(tripType == type ? Color.blue : fieldFillColor)
                            )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(14)
        .background(sectionCard)
    }

    private var savedRouteCard: some View {
        let saved = isRouteSaved
        return HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(routeTitle)
                    .font(.custom("AvenirNext-DemiBold", size: 16))
                    .foregroundStyle(primaryTextColor)
                Text(routeSubtitle)
                    .font(.custom("AvenirNext-Medium", size: 12))
                    .foregroundStyle(secondaryTextColor)
            }

            Spacer()

            Button {
                toggleSavedRoute()
            } label: {
                Image(systemName: saved ? "star.fill" : "star")
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(saved ? .yellow : primaryTextColor)
                    .frame(width: 34, height: 34)
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(fieldFillColor)
                    )
            }
            .buttonStyle(.plain)
        }
        .padding(14)
        .background(sectionCard)
    }

    private var travelDatesCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(L.text(.travelDates, lang: language))
                .font(.custom("AvenirNext-DemiBold", size: 20))
                .foregroundStyle(primaryTextColor)

            HStack(spacing: 8) {
                dateSelectionBox(title: L.text(.outbound, lang: language), value: formattedDate(outboundDate))
                dateSelectionBox(
                    title: L.text(.returnLabel, lang: language),
                    value: tripType == .single ? L.text(.notRequired, lang: language) : formattedDate(returnDate)
                )
            }

            DatePicker(
                L.text(.outboundDate, lang: language),
                selection: $outboundDate,
                in: Date()...,
                displayedComponents: .date
            )
            .datePickerStyle(.graphical)
            .tint(.blue)
            .onChange(of: outboundDate) { _, newDate in
                if returnDate < newDate {
                    returnDate = Calendar.current.date(byAdding: .day, value: 1, to: newDate) ?? newDate
                }
            }

            if tripType != .single {
                DatePicker(
                    tripType == .openReturn ? L.text(.returnDateOptional, lang: language) : L.text(.returnDate, lang: language),
                    selection: $returnDate,
                    in: outboundDate...,
                    displayedComponents: .date
                )
                .datePickerStyle(.graphical)
                .tint(.blue)
            }
        }
        .padding(14)
        .background(sectionCard)
    }

    private var localOperatorsCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(L.text(.localOperators, lang: language))
                .font(.custom("AvenirNext-DemiBold", size: 18))
                .foregroundStyle(primaryTextColor)
            Text("ARCT, BLAC, KLCO, SCCU, SCMY, NUTT")
                .font(.custom("AvenirNext-Medium", size: 14))
                .foregroundStyle(secondaryTextColor)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(sectionCard)
    }

    private var passengersCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(L.text(.passengers, lang: language))
                .font(.custom("AvenirNext-DemiBold", size: 20))
                .foregroundStyle(primaryTextColor)

            HStack {
                Text(L.passengerCount(passengerCount, lang: language))
                    .font(.custom("AvenirNext-Medium", size: 16))
                    .foregroundStyle(primaryTextColor)
                Spacer()
                Stepper("", value: $passengerCount, in: 1...12)
                    .labelsHidden()
            }
            .padding(12)
            .background(fieldCard)

            VStack(alignment: .leading, spacing: 8) {
                Text(L.text(.railcard, lang: language))
                    .font(.custom("AvenirNext-Medium", size: 14))
                    .foregroundStyle(secondaryTextColor)

                Picker(L.text(.railcard, lang: language), selection: $selectedRailcard) {
                    ForEach(RailcardOption.options(for: language), id: \.self) { railcard in
                        Text(railcard).tag(railcard)
                    }
                }
                .pickerStyle(.menu)
                .tint(primaryTextColor)
                .padding(12)
                .background(fieldCard)
            }
        }
        .padding(14)
        .background(sectionCard)
    }

    private func stationSearchField(
        title: String,
        placeholder: String,
        text: Binding<String>,
        field: SearchField
    ) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.custom("AvenirNext-Medium", size: 14))
                .foregroundStyle(secondaryTextColor)

            HStack(spacing: 10) {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(.blue)
                TextField(placeholder, text: text)
                    .focused($focusedField, equals: field)
                    .textInputAutocapitalization(.words)
                    .autocorrectionDisabled(true)
                    .foregroundStyle(primaryTextColor)
            }
            .padding(12)
            .background(fieldCard)
        }
    }

    private var originStation: Station? {
        stations.first(where: { $0.id == originId })
    }

    private var destinationStation: Station? {
        stations.first(where: { $0.id == destinationId })
    }

    private var routeTitle: String {
        let origin = originStation?.name ?? L.text(.origin, lang: language)
        let destination = destinationStation?.name ?? L.text(.destination, lang: language)
        return "\(origin) → \(destination)"
    }

    private var routeSubtitle: String {
        "\(formattedDate(outboundDate)) • \(L.passengerCount(passengerCount, lang: language))"
    }

    private var isRouteSaved: Bool {
        savedTrips.contains(where: { $0.key == routeTitle.lowercased() })
    }

    private func toggleSavedRoute() {
        let key = routeTitle.lowercased()
        if let idx = savedTrips.firstIndex(where: { $0.key == key }) {
            savedTrips.remove(at: idx)
        } else {
            savedTrips.insert(
                SavedTrip(key: key, title: routeTitle, subtitle: routeSubtitle, canBook: true),
                at: 0
            )
        }
    }

    private func dateSelectionBox(title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.custom("AvenirNext-Medium", size: 13))
                .foregroundStyle(secondaryTextColor)
            Text(value)
                .font(.custom("AvenirNext-DemiBold", size: 15))
                .foregroundStyle(primaryTextColor)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(10)
        .background(fieldCard)
    }

    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE, d MMM yyyy"
        return formatter.string(from: date)
    }

    private func suggestionsList(_ items: [Station], onSelect: @escaping (Station) -> Void) -> some View {
        VStack(spacing: 0) {
            ForEach(items.prefix(6), id: \.id) { station in
                Button {
                    onSelect(station)
                } label: {
                    HStack {
                        Text(station.name)
                            .foregroundStyle(primaryTextColor)
                        Spacer()
                        Text(station.code)
                            .font(.caption)
                            .foregroundStyle(secondaryTextColor)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 10)
                }
                .buttonStyle(.plain)

                if station.id != items.prefix(6).last?.id {
                    Divider().overlay(Color.white.opacity(0.08))
                }
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(usesLightPalette ? Color.white : Color.black.opacity(0.28))
        )
    }

    private func exactMatch(for text: String) -> Station? {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }
        return stations.first {
            $0.name.caseInsensitiveCompare(trimmed) == .orderedSame ||
            $0.code.caseInsensitiveCompare(trimmed) == .orderedSame
        }
    }

    private var originSuggestions: [Station] {
        stationMatches(for: originQuery)
    }

    private var destinationSuggestions: [Station] {
        stationMatches(for: destinationQuery)
    }

    private func stationMatches(for query: String) -> [Station] {
        let q = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !q.isEmpty else { return [] }
        return stations.filter {
            $0.name.localizedCaseInsensitiveContains(q) ||
            $0.code.localizedCaseInsensitiveContains(q)
        }
    }

    private var sectionCard: some View {
        RoundedRectangle(cornerRadius: 18)
            .fill(cardFillColor)
            .overlay(
                RoundedRectangle(cornerRadius: 18)
                    .stroke(cardStrokeColor, lineWidth: 1)
            )
    }

    private var fieldCard: some View {
        RoundedRectangle(cornerRadius: 12)
            .fill(fieldFillColor)
    }
}

private enum JourneyResultsMode: String, CaseIterable {
    case train
    case bus

    var icon: String {
        switch self {
        case .train: return "tram.fill"
        case .bus: return "bus.fill"
        }
    }

    func title(in language: AppLanguage) -> String {
        switch self {
        case .train: return L.text(.train, lang: language)
        case .bus: return L.text(.bus, lang: language)
        }
    }
}

private struct JourneyOption: Identifiable {
    struct ChangeDetail: Identifiable {
        let id: String
        let at: String
        let layoverMins: Int
    }

    let id: String
    let mode: JourneyResultsMode
    let departure: Date
    let arrival: Date
    let price: Double
    let route: String
    let durationMins: Int
    let changes: Int
    let changeDetails: [ChangeDetail]
}

private struct JourneyTimesPricesScreen: View {
    @Environment(\.colorScheme) private var colorScheme
    let language: AppLanguage
    let originName: String
    let destinationName: String
    let outboundDate: Date
    let tripType: TripType
    let passengerCount: Int
    let selectedRailcard: String
    let selectedCurrencyRawValue: String
    @State private var mode: JourneyResultsMode = .train
    @State private var expandedChangeCards: Set<String> = []

    private var usesLightPalette: Bool {
        colorScheme == .light
    }

    private var primaryTextColor: Color {
        usesLightPalette ? .black : .white
    }

    private var secondaryTextColor: Color {
        usesLightPalette ? Color.black.opacity(0.62) : .secondary
    }

    private var selectedCurrency: AppCurrency {
        AppCurrency(rawValue: selectedCurrencyRawValue) ?? .gbp
    }

    private var visibleOptions: [JourneyOption] {
        sampleOptions.filter { $0.mode == mode }
    }

    private var sampleOptions: [JourneyOption] {
        let base = Calendar.current.date(bySettingHour: 6, minute: 45, second: 0, of: outboundDate) ?? outboundDate
        let route = "\(originName) → \(destinationName)"
        let routeFactor = max(1, ((originName.count + destinationName.count) % 6) + 1)

        let multiplier: Double
        switch tripType {
        case .single:
            multiplier = 1.0
        case .return:
            multiplier = 1.75
        case .openReturn:
            multiplier = 2.0
        }

        func makeOptions(mode: JourneyResultsMode) -> [JourneyOption] {
            (0..<5).map { idx in
                let departOffset = idx * (mode == .train ? 38 : 42)
                let dep = Calendar.current.date(byAdding: .minute, value: departOffset, to: base) ?? base
                let duration = (mode == .train ? 28 : 42) + routeFactor * (mode == .train ? 3 : 4) + idx * (mode == .train ? 2 : 3)
                let arr = Calendar.current.date(byAdding: .minute, value: duration, to: dep) ?? dep
                // Price model is computed in EUR, then converted for display using selected currency.
                let basePriceEUR = (mode == .train ? 12.5 : 7.5) + Double(routeFactor) * (mode == .train ? 2.7 : 1.8) + Double(idx) * (mode == .train ? 1.2 : 0.9)
                let perPassenger = basePriceEUR * multiplier
                let price = totalPriceApplyingRailcard(basePerPassenger: perPassenger)
                let changes = mode == .train ? (idx % 3 == 0 ? 0 : 1) : (idx % 2 == 0 ? 0 : 1)

                let changeStations = ["Preston", "Lancaster", "Blackpool North", "Barrow-in-Furness", "Windermere"]
                let changeDetails: [JourneyOption.ChangeDetail]
                if changes == 0 {
                    changeDetails = []
                } else {
                    let stationName = changeStations[(idx + routeFactor) % changeStations.count]
                    let layover = (mode == .train ? 6 : 8) + (idx * 2)
                    changeDetails = [
                        JourneyOption.ChangeDetail(
                            id: "\(mode.rawValue)-\(idx)-change-0",
                            at: stationName,
                            layoverMins: layover
                        )
                    ]
                }

                return JourneyOption(
                    id: "\(mode.rawValue)-\(idx)-\(routeFactor)",
                    mode: mode,
                    departure: dep,
                    arrival: arr,
                    price: price,
                    route: route,
                    durationMins: duration,
                    changes: changes,
                    changeDetails: changeDetails
                )
            }
        }

        return makeOptions(mode: .train) + makeOptions(mode: .bus)
    }

    var body: some View {
        ZStack {
            LinearGradient(
                colors: usesLightPalette
                    ? [Color.white, Color(red: 0.95, green: 0.96, blue: 0.98)]
                    : [Color(red: 0.02, green: 0.09, blue: 0.20), Color.black],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 14) {
                    modeTabs
                    ForEach(visibleOptions) { option in
                        optionCard(option)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 12)
                .padding(.bottom, 20)
            }
        }
        .navigationTitle(L.text(.timesAndPrices, lang: language))
        .navigationBarTitleDisplayMode(.inline)
    }

    private var modeTabs: some View {
        HStack(spacing: 8) {
            ForEach(JourneyResultsMode.allCases, id: \.self) { item in
                Button {
                    mode = item
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: item.icon)
                        Text(item.title(in: language))
                    }
                    .font(.custom("AvenirNext-DemiBold", size: 15))
                    .foregroundStyle(mode == item ? .white : secondaryTextColor)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 11)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(mode == item ? Color.blue : (usesLightPalette ? Color.black.opacity(0.08) : Color.white.opacity(0.08)))
                    )
                }
                .buttonStyle(.plain)
            }
        }
        .padding(10)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(usesLightPalette ? Color.white : Color.white.opacity(0.06))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(usesLightPalette ? Color.black.opacity(0.08) : Color.white.opacity(0.07), lineWidth: 1)
                )
        )
    }

    private func optionCard(_ option: JourneyOption) -> some View {
        let cardFill = usesLightPalette ? Color.white : Color.white.opacity(0.08)
        let cardStroke = usesLightPalette ? Color.black.opacity(0.10) : Color.white.opacity(0.08)
        return VStack(alignment: .leading, spacing: 10) {
            optionHeader(option)
            railcardStatusRow
            HStack(spacing: 10) {
                infoPill(title: L.text(.departure, lang: language), value: time(option.departure))
                infoPill(title: L.text(.arrival, lang: language), value: time(option.arrival))
            }
            HStack(spacing: 10) {
                infoPill(title: L.text(.duration, lang: language), value: "\(option.durationMins) \(L.text(.min, lang: language))")
                changesCard(option)
            }
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(cardFill)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(cardStroke, lineWidth: 1)
                )
        )
    }

    private func optionHeader(_ option: JourneyOption) -> some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 2) {
                Text(option.route)
                    .font(.custom("AvenirNext-DemiBold", size: 17))
                    .foregroundStyle(primaryTextColor)
                Text(L.text(.services, lang: language))
                    .font(.custom("AvenirNext-Medium", size: 12))
                    .foregroundStyle(secondaryTextColor)
            }
            Spacer()
            Text(currency(option.price))
                .font(.custom("AvenirNext-Bold", size: 24))
                .foregroundStyle(.blue)
        }
    }

    private var railcardStatusRow: some View {
        let railcardApplied = railcardDiscountCategory != .none
        let iconName = railcardApplied ? "checkmark.seal.fill" : "xmark.seal.fill"
        let statusText = railcardApplied
            ? L.text(.railcardApplied, lang: language)
            : L.text(.noRailcardApplied, lang: language)
        let statusColor: Color = railcardApplied ? .green : .secondary

        return HStack(spacing: 8) {
            Image(systemName: iconName)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(statusColor)
            Text(statusText)
                .font(.custom("AvenirNext-Medium", size: 13))
                .foregroundStyle(secondaryTextColor)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(usesLightPalette ? Color.black.opacity(0.05) : Color.white.opacity(0.05))
        )
    }

    private func infoPill(title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .font(.custom("AvenirNext-Medium", size: 12))
                .foregroundStyle(secondaryTextColor)
            Text(value)
                .font(.custom("AvenirNext-DemiBold", size: 16))
                .foregroundStyle(primaryTextColor)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(10)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(usesLightPalette ? Color.black.opacity(0.06) : Color.white.opacity(0.06))
        )
    }

    private func changesCard(_ option: JourneyOption) -> some View {
        let expanded = expandedChangeCards.contains(option.id)
        return VStack(alignment: .leading, spacing: 6) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(L.text(.changes, lang: language))
                        .font(.custom("AvenirNext-Medium", size: 12))
                        .foregroundStyle(secondaryTextColor)
                    Text(changesText(option.changes))
                        .font(.custom("AvenirNext-DemiBold", size: 16))
                        .foregroundStyle(primaryTextColor)
                }
                Spacer()
                if option.changes > 0 {
                    Image(systemName: expanded ? "chevron.up" : "chevron.down")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.blue)
                }
            }

            if expanded && option.changes > 0 {
                Divider()
                    .overlay(usesLightPalette ? Color.black.opacity(0.12) : Color.white.opacity(0.12))
                VStack(alignment: .leading, spacing: 4) {
                    ForEach(option.changeDetails) { detail in
                        Text("• \(detail.at) • \(detail.layoverMins) \(L.text(.min, lang: language))")
                            .font(.custom("AvenirNext-Medium", size: 13))
                            .foregroundStyle(secondaryTextColor)
                    }
                }
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(10)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(usesLightPalette ? Color.black.opacity(0.06) : Color.white.opacity(0.06))
        )
        .contentShape(Rectangle())
        .onTapGesture {
            guard option.changes > 0 else { return }
            withAnimation(.easeInOut(duration: 0.22)) {
                if expanded {
                    expandedChangeCards.remove(option.id)
                } else {
                    expandedChangeCards.insert(option.id)
                }
            }
        }
    }

    private func time(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: date)
    }

    private func currency(_ value: Double) -> String {
        let convertedValue = value * selectedCurrency.rateFromEUR
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = selectedCurrency.code
        formatter.locale = Locale(identifier: "en_GB")
        formatter.maximumFractionDigits = 2
        return formatter.string(from: NSNumber(value: convertedValue)) ?? "\(selectedCurrency.symbol)\(String(format: "%.2f", convertedValue))"
    }

    private enum RailcardDiscountCategory {
        case none
        case standardThird
        case familyFriends
        case saver1617
    }

    private var railcardDiscountCategory: RailcardDiscountCategory {
        let lower = selectedRailcard.lowercased()
        if lower.contains("no railcard") || lower.contains("sin railcard") || lower.contains("sans railcard") || lower.contains("keine railcard") || lower.contains("无 railcard") {
            return .none
        }
        if lower.contains("16-17") {
            return .saver1617
        }
        if lower.contains("family") {
            return .familyFriends
        }
        return .standardThird
    }

    private func totalPriceApplyingRailcard(basePerPassenger: Double) -> Double {
        let adults = max(passengerCount, 1)
        switch railcardDiscountCategory {
        case .none:
            return basePerPassenger * Double(adults)
        case .standardThird:
            return basePerPassenger * 0.67 * Double(adults)
        case .familyFriends:
            // Current search form only captures total passengers (adults), so 33% is applied here.
            return basePerPassenger * 0.67 * Double(adults)
        case .saver1617:
            return basePerPassenger * 0.50 * Double(adults)
        }
    }

    private func changesText(_ count: Int) -> String {
        switch count {
        case 0:
            return L.text(.direct, lang: language)
        case 1:
            return L.text(.changeSingular, lang: language)
        default:
            return "\(count) \(L.text(.changesPlural, lang: language))"
        }
    }
}

private enum SearchField {
    case origin
    case destination
}

private enum TripType: CaseIterable {
    case single
    case `return`
    case openReturn

    var title: String {
        switch self {
        case .single: return "Single Trip"
        case .return: return "Return Trip"
        case .openReturn: return "Open Return Trip"
        }
    }

    var shortTitle: String {
        switch self {
        case .single: return "Single"
        case .return: return "Return"
        case .openReturn: return "Open Return"
        }
    }

    func shortTitle(in language: AppLanguage) -> String {
        switch self {
        case .single: return L.text(.single, lang: language)
        case .return: return L.text(.returnLabel, lang: language)
        case .openReturn: return L.text(.openReturn, lang: language)
        }
    }
}

private enum RailcardOption {
    static let all: [String] = [
        "No Railcard",
        "16-25 Railcard",
        "26-30 Railcard",
        "Senior Railcard",
        "Two Together Railcard",
        "Family & Friends Railcard",
        "Disabled Persons Railcard",
        "16-17 Saver",
        "Veterans Railcard",
        "Network Railcard"
    ]

    static func options(for language: AppLanguage) -> [String] {
        switch language {
        case .en:
            return [
                "No Railcard",
                "16-25 Railcard",
                "26-30 Railcard",
                "Senior Railcard",
                "Two Together Railcard",
                "Family & Friends Railcard",
                "Disabled Persons Railcard",
                "16-17 Saver",
                "Veterans Railcard",
                "Network Railcard"
            ]
        case .es:
            return [
                "Sin Railcard",
                "Railcard 16-25",
                "Railcard 26-30",
                "Railcard Senior",
                "Railcard Two Together",
                "Railcard Family & Friends",
                "Railcard Personas con Discapacidad",
                "16-17 Saver",
                "Railcard Veterans",
                "Railcard Network"
            ]
        case .fr:
            return [
                "Sans Railcard",
                "Railcard 16-25",
                "Railcard 26-30",
                "Railcard Senior",
                "Railcard Two Together",
                "Railcard Family & Friends",
                "Railcard Personnes handicapées",
                "16-17 Saver",
                "Railcard Veterans",
                "Railcard Network"
            ]
        case .de:
            return [
                "Keine Railcard",
                "Railcard 16-25",
                "Railcard 26-30",
                "Senior Railcard",
                "Two Together Railcard",
                "Family & Friends Railcard",
                "Railcard für Menschen mit Behinderung",
                "16-17 Saver",
                "Veterans Railcard",
                "Network Railcard"
            ]
        case .zh:
            return [
                "无 Railcard",
                "16-25 Railcard",
                "26-30 Railcard",
                "Senior Railcard",
                "Two Together Railcard",
                "Family & Friends Railcard",
                "Disabled Persons Railcard",
                "16-17 Saver",
                "Veterans Railcard",
                "Network Railcard"
            ]
        }
    }
}

private enum TransportMode: String, CaseIterable {
    case train
    case bus
    case taxi
    case walk

    var title: String {
        switch self {
        case .train: return "Train"
        case .bus: return "Bus"
        case .taxi: return "Taxi"
        case .walk: return "Walk"
        }
    }

    var icon: String {
        switch self {
        case .train: return "tram.fill"
        case .bus: return "bus.fill"
        case .taxi: return "car.fill"
        case .walk: return "figure.walk"
        }
    }

    var stageTitle: String {
        switch self {
        case .train: return "Train Stage"
        case .bus: return "Bus Stage"
        case .taxi: return "Taxi Stage"
        case .walk: return "Walk Stage"
        }
    }

    var accentColor: Color {
        switch self {
        case .train: return .blue
        case .bus: return .green
        case .taxi: return .yellow
        case .walk: return .orange
        }
    }

    var defaultDurationMins: Int {
        switch self {
        case .train: return 18
        case .bus: return 45
        case .taxi: return 22
        case .walk: return 32
        }
    }

    func title(in language: AppLanguage) -> String {
        switch self {
        case .train: return L.text(.train, lang: language)
        case .bus: return L.text(.bus, lang: language)
        case .taxi: return L.text(.taxi, lang: language)
        case .walk: return L.text(.walk, lang: language)
        }
    }

    func stageTitle(in language: AppLanguage) -> String {
        switch self {
        case .train: return L.text(.trainStage, lang: language)
        case .bus: return L.text(.busStage, lang: language)
        case .taxi: return L.text(.taxiStage, lang: language)
        case .walk: return L.text(.walkStage, lang: language)
        }
    }
}

private enum WalkField {
    case from
    case to
}

private enum RecoveryStep {
    case email
    case code
    case newPassword
}

private struct SavedTrip: Identifiable {
    let id = UUID()
    let key: String
    let title: String
    let subtitle: String
    let canBook: Bool
}

private struct SavedStop: Identifiable {
    let id = UUID()
    let stationId: Int
    let name: String
    let code: String
    let mode: TransportMode
    let distanceText: String
}

private struct AccountNotification: Identifiable {
    let id = UUID()
    let title: String
    let subtitle: String
}

private struct TicketItem: Identifiable {
    let id = UUID()
    let routeTitle: String
    let originCode: String
    let destinationCode: String
    let stationIds: [Int]
    let reference: String
    let travelDate: Date
    let durationMins: Int
    let railcardUsed: Bool
}

private struct MapLiveTrackContext: Identifiable {
    let id = UUID()
    let title: String
    let operatorName: String
    let stationIds: [Int]
}

private struct NearbyStopInfo {
    let station: Station
    let distanceMeters: CLLocationDistance
}

private struct WalletPassPresentation: Identifiable {
    let id = UUID()
    let passes: [PKPass]
}

private struct MapArrival: Identifiable {
    let id = UUID()
    let service: String
    let destination: String
    let operatorName: String
    let etaMinutes: Double
    let color: Color
    let mode: TransportMode
}

private struct HomeExperience: Identifiable {
    let id = UUID()
    let title: String
    let location: String
    let price: String
    let imageURL: URL?

    static let mock: [HomeExperience] = [
        HomeExperience(
            title: "Lake District Cruise",
            location: "Windermere",
            price: "£45/person",
            imageURL: URL(string: "https://images.unsplash.com/photo-1501785888041-af3ef285b470?w=1200")
        ),
        HomeExperience(
            title: "Historic Lancaster Walk",
            location: "Lancaster",
            price: "£18/person",
            imageURL: URL(string: "https://images.unsplash.com/photo-1469474968028-56623f02e42e?w=1200")
        ),
        HomeExperience(
            title: "Blackpool Tower Day",
            location: "Blackpool",
            price: "£29/person",
            imageURL: URL(string: "https://images.unsplash.com/photo-1449824913935-59a10b8d2000?w=1200")
        )
    ]
}

private struct SavedTripsScreen: View {
    @Environment(\.colorScheme) private var systemColorScheme
    let trips: [SavedTrip]
    let language: AppLanguage
    let preferredAppearance: String
    let onBook: (SavedTrip) -> Void

    private var usesLightPalette: Bool {
        switch preferredAppearance {
        case "light": return true
        case "dark": return false
        default: return systemColorScheme == .light
        }
    }

    var body: some View {
        List {
            if trips.isEmpty {
                Text(L.text(.noTrips, lang: language))
                    .foregroundStyle(.secondary)
                    .listRowBackground(Color.clear)
            } else {
                ForEach(trips) { trip in
                    VStack(alignment: .leading, spacing: 6) {
                        Text(trip.title)
                            .font(.headline.weight(.semibold))
                            .foregroundStyle(.blue)
                        Text(trip.subtitle)
                            .font(.subheadline)
                            .foregroundStyle(usesLightPalette ? Color.black.opacity(0.75) : .white)
                        if trip.canBook {
                            Button {
                                onBook(trip)
                            } label: {
                                Text(L.text(.book, lang: language))
                                    .font(.caption.weight(.bold))
                                    .foregroundStyle(.white)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .background(
                                        RoundedRectangle(cornerRadius: 10)
                                            .fill(Color.blue)
                                    )
                            }
                            .buttonStyle(.plain)
                            .padding(.top, 2)
                        }
                    }
                    .padding(.vertical, 10)
                    .listRowBackground(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(usesLightPalette ? Color.white.opacity(0.9) : Color.white.opacity(0.08))
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(usesLightPalette ? Color.black.opacity(0.08) : Color.white.opacity(0.06), lineWidth: 1)
                            )
                            .padding(.vertical, 4)
                    )
                    .listRowSeparator(.hidden)
                }
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .background(
            usesLightPalette
                ? Color(red: 0.95, green: 0.96, blue: 0.98)
                : Color.black
        )
        .navigationTitle(L.text(.savedTrips, lang: language))
        .navigationBarTitleDisplayMode(.inline)
    }
}

private struct NotificationsScreen: View {
    @Environment(\.colorScheme) private var systemColorScheme
    let notifications: [AccountNotification]
    let language: AppLanguage
    let preferredAppearance: String

    private var usesLightPalette: Bool {
        switch preferredAppearance {
        case "light": return true
        case "dark": return false
        default: return systemColorScheme == .light
        }
    }

    var body: some View {
        List {
            if notifications.isEmpty {
                Text(L.text(.noNotifications, lang: language))
                    .foregroundStyle(.secondary)
                    .listRowBackground(Color.clear)
            } else {
                ForEach(notifications) { notification in
                    VStack(alignment: .leading, spacing: 6) {
                        Text(notification.title)
                            .font(.headline.weight(.semibold))
                            .foregroundStyle(.blue)
                        Text(notification.subtitle)
                            .font(.subheadline)
                            .foregroundStyle(usesLightPalette ? Color.black.opacity(0.75) : .white)
                    }
                    .padding(.vertical, 10)
                    .listRowBackground(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(usesLightPalette ? Color.white.opacity(0.9) : Color.white.opacity(0.08))
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(usesLightPalette ? Color.black.opacity(0.08) : Color.white.opacity(0.06), lineWidth: 1)
                            )
                            .padding(.vertical, 4)
                    )
                    .listRowSeparator(.hidden)
                }
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .background(
            usesLightPalette
                ? Color(red: 0.95, green: 0.96, blue: 0.98)
                : Color.black
        )
        .navigationTitle(L.text(.notifications, lang: language))
        .navigationBarTitleDisplayMode(.inline)
    }
}

private struct SavedStopsScreen: View {
    @Environment(\.colorScheme) private var systemColorScheme
    let stops: [SavedStop]
    let language: AppLanguage
    let preferredAppearance: String

    private var usesLightPalette: Bool {
        switch preferredAppearance {
        case "light": return true
        case "dark": return false
        default: return systemColorScheme == .light
        }
    }

    var body: some View {
        List {
            if stops.isEmpty {
                Text(L.text(.noStops, lang: language))
                    .foregroundStyle(.secondary)
                    .listRowBackground(Color.clear)
            } else {
                ForEach(stops) { stop in
                    VStack(alignment: .leading, spacing: 6) {
                        Text(stop.name)
                            .font(.headline.weight(.semibold))
                            .foregroundStyle(.blue)
                        Text("\(stop.code) • \(stop.mode.title(in: language)) • \(stop.distanceText)")
                            .font(.subheadline)
                            .foregroundStyle(usesLightPalette ? Color.black.opacity(0.75) : .white)
                    }
                    .padding(.vertical, 10)
                    .listRowBackground(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(usesLightPalette ? Color.white.opacity(0.9) : Color.white.opacity(0.08))
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(usesLightPalette ? Color.black.opacity(0.08) : Color.white.opacity(0.06), lineWidth: 1)
                            )
                            .padding(.vertical, 4)
                    )
                    .listRowSeparator(.hidden)
                }
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .background(
            usesLightPalette
                ? Color(red: 0.95, green: 0.96, blue: 0.98)
                : Color.black
        )
        .navigationTitle(L.text(.savedStops, lang: language))
        .navigationBarTitleDisplayMode(.inline)
    }
}

private struct SettingsScreen: View {
    @Environment(\.colorScheme) private var systemColorScheme
    @Binding var preferredAppearance: String
    @Binding var appLanguageRawValue: String
    @Binding var selectedCurrencyRawValue: String
    @Binding var fullName: String
    @Binding var username: String
    @Binding var email: String
    @Binding var phone: String
    @Binding var fontScale: Double

    private var language: AppLanguage { AppLanguage(rawValue: appLanguageRawValue) ?? .en }

    private var usesLightPalette: Bool {
        switch preferredAppearance {
        case "light": return true
        case "dark": return false
        default: return systemColorScheme == .light
        }
    }

    private var primaryTextColor: Color { usesLightPalette ? .black : .white }
    private var secondaryTextColor: Color { usesLightPalette ? Color.black.opacity(0.6) : .secondary }

    var body: some View {
        ZStack {
            LinearGradient(
                colors: usesLightPalette
                    ? [Color.white, Color(red: 0.95, green: 0.96, blue: 0.98)]
                    : [Color(red: 0.03, green: 0.11, blue: 0.28), Color.black],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 14) {
                    NavigationLink {
                        PersonalDataSettingsScreen(
                            preferredAppearance: $preferredAppearance,
                            appLanguageRawValue: $appLanguageRawValue,
                            fullName: $fullName,
                            username: $username,
                            email: $email,
                            phone: $phone
                        )
                    } label: {
                        settingsMenuRow(title: L.text(.personalData, lang: language), icon: "person.text.rectangle.fill")
                    }

                    NavigationLink {
                        LanguageSettingsScreen(
                            preferredAppearance: $preferredAppearance,
                            appLanguageRawValue: $appLanguageRawValue
                        )
                    } label: {
                        settingsMenuRow(title: L.text(.language, lang: language), icon: "globe")
                    }

                    NavigationLink {
                        CurrencySettingsScreen(
                            preferredAppearance: $preferredAppearance,
                            appLanguageRawValue: $appLanguageRawValue,
                            selectedCurrencyRawValue: $selectedCurrencyRawValue
                        )
                    } label: {
                        settingsMenuRow(title: L.text(.currency, lang: language), icon: "sterlingsign.circle.fill")
                    }

                    NavigationLink {
                        AppearanceSettingsScreen(
                            preferredAppearance: $preferredAppearance,
                            appLanguageRawValue: $appLanguageRawValue
                        )
                    } label: {
                        settingsMenuRow(title: L.text(.appearance, lang: language), icon: "paintbrush.pointed.fill")
                    }

                    NavigationLink {
                        AccessibilitySettingsScreen(
                            preferredAppearance: $preferredAppearance,
                            appLanguageRawValue: $appLanguageRawValue,
                            fontScale: $fontScale
                        )
                    } label: {
                        settingsMenuRow(title: L.text(.accessibility, lang: language), icon: "figure.wave")
                    }
                }
                .padding(.horizontal, 14)
                .padding(.top, 12)
                .padding(.bottom, 24)
            }
        }
        .navigationTitle(L.text(.settings, lang: language))
        .navigationBarTitleDisplayMode(.inline)
    }

    private func settingsMenuRow(title: String, icon: String) -> some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(.blue)
                .frame(width: 26)
            Text(title)
                .font(.title3.weight(.semibold))
                .foregroundStyle(primaryTextColor)
            Spacer()
            Image(systemName: "chevron.right")
                .font(.headline)
                .foregroundStyle(secondaryTextColor)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 16)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(usesLightPalette ? Color.white.opacity(0.95) : Color.white.opacity(0.08))
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(usesLightPalette ? Color.black.opacity(0.10) : Color.white.opacity(0.06), lineWidth: 1)
                )
        )
    }
}

private struct PersonalDataSettingsScreen: View {
    @Environment(\.colorScheme) private var systemColorScheme
    @Binding var preferredAppearance: String
    @Binding var appLanguageRawValue: String
    @Binding var fullName: String
    @Binding var username: String
    @Binding var email: String
    @Binding var phone: String
    @AppStorage("isLoggedIn") private var isLoggedIn = false
    @AppStorage("lastLoginTimestamp") private var lastLoginTimestamp: Double = 0

    private var language: AppLanguage { AppLanguage(rawValue: appLanguageRawValue) ?? .en }

    private var usesLightPalette: Bool {
        switch preferredAppearance {
        case "light": return true
        case "dark": return false
        default: return systemColorScheme == .light
        }
    }

    private var primaryTextColor: Color { usesLightPalette ? .black : .white }

    var body: some View {
        settingsBase {
            settingsCard(title: L.text(.personalData, lang: language), icon: "person.text.rectangle.fill") {
                labeledField(title: L.text(.fullName, lang: language), text: $fullName)
                labeledField(title: L.text(.username, lang: language), text: $username)
                labeledField(title: L.text(.email, lang: language), text: $email)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled(true)
                labeledField(title: L.text(.phone, lang: language), text: $phone)
            }

            Button {
                isLoggedIn = false
                lastLoginTimestamp = 0
            } label: {
                Text(L.text(.logOut, lang: language))
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(
                        RoundedRectangle(cornerRadius: 14)
                            .fill(Color.red.opacity(0.9))
                    )
            }
        }
        .navigationTitle(L.text(.personalData, lang: language))
        .navigationBarTitleDisplayMode(.inline)
    }

    private func settingsBase<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        ZStack {
            LinearGradient(
                colors: usesLightPalette
                    ? [Color.white, Color(red: 0.95, green: 0.96, blue: 0.98)]
                    : [Color(red: 0.03, green: 0.11, blue: 0.28), Color.black],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 14) {
                    content()
                }
                .padding(.horizontal, 14)
                .padding(.top, 12)
                .padding(.bottom, 24)
            }
        }
    }

    private func settingsCard<Content: View>(title: String, icon: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 10) {
                Image(systemName: icon)
                    .font(.headline)
                    .foregroundStyle(.blue)
                    .frame(width: 26, height: 26)
                    .background(Circle().fill(Color.white.opacity(0.08)))
                Text(title)
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(primaryTextColor)
            }
            content()
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(usesLightPalette ? Color.white.opacity(0.95) : Color.white.opacity(0.08))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(usesLightPalette ? Color.black.opacity(0.10) : Color.white.opacity(0.06), lineWidth: 1)
                )
        )
    }

    private func settingsField(_ title: String, text: Binding<String>) -> some View {
        TextField(title, text: text)
            .foregroundStyle(primaryTextColor)
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(usesLightPalette ? Color.black.opacity(0.06) : Color.white.opacity(0.06))
            )
    }

    private func labeledField(title: String, text: Binding<String>) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.caption.weight(.semibold))
                .foregroundStyle(.blue)
            settingsField(title, text: text)
        }
    }
}

private struct LanguageSettingsScreen: View {
    @Environment(\.colorScheme) private var systemColorScheme
    @Binding var preferredAppearance: String
    @Binding var appLanguageRawValue: String

    private var language: AppLanguage { AppLanguage(rawValue: appLanguageRawValue) ?? .en }

    private var usesLightPalette: Bool {
        switch preferredAppearance {
        case "light": return true
        case "dark": return false
        default: return systemColorScheme == .light
        }
    }

    private var primaryTextColor: Color { usesLightPalette ? .black : .white }

    var body: some View {
        settingsBase {
            settingsCard(title: L.text(.language, lang: language), icon: "globe") {
                Picker(L.text(.language, lang: language), selection: $appLanguageRawValue) {
                    ForEach(AppLanguage.allCases, id: \.rawValue) { option in
                        Text(option.displayName).tag(option.rawValue)
                    }
                }
                .tint(primaryTextColor)
                .padding(12)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(usesLightPalette ? Color.black.opacity(0.06) : Color.white.opacity(0.06))
                )
            }
        }
        .navigationTitle(L.text(.language, lang: language))
        .navigationBarTitleDisplayMode(.inline)
    }

    private func settingsBase<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        ZStack {
            LinearGradient(
                colors: usesLightPalette
                    ? [Color.white, Color(red: 0.95, green: 0.96, blue: 0.98)]
                    : [Color(red: 0.03, green: 0.11, blue: 0.28), Color.black],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 14) {
                    content()
                }
                .padding(.horizontal, 14)
                .padding(.top, 12)
                .padding(.bottom, 24)
            }
        }
    }

    private func settingsCard<Content: View>(title: String, icon: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 10) {
                Image(systemName: icon)
                    .font(.headline)
                    .foregroundStyle(.blue)
                    .frame(width: 26, height: 26)
                    .background(Circle().fill(Color.white.opacity(0.08)))
                Text(title)
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(primaryTextColor)
            }
            content()
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(usesLightPalette ? Color.white.opacity(0.95) : Color.white.opacity(0.08))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(usesLightPalette ? Color.black.opacity(0.10) : Color.white.opacity(0.06), lineWidth: 1)
                )
        )
    }
}

private struct AppearanceSettingsScreen: View {
    @Environment(\.colorScheme) private var systemColorScheme
    @Binding var preferredAppearance: String
    @Binding var appLanguageRawValue: String

    private var language: AppLanguage { AppLanguage(rawValue: appLanguageRawValue) ?? .en }

    private var usesLightPalette: Bool {
        switch preferredAppearance {
        case "light": return true
        case "dark": return false
        default: return systemColorScheme == .light
        }
    }

    private var primaryTextColor: Color { usesLightPalette ? .black : .white }

    var body: some View {
        settingsBase {
            settingsCard(title: L.text(.appearance, lang: language), icon: "paintbrush.pointed.fill") {
                Picker(L.text(.theme, lang: language), selection: $preferredAppearance) {
                    Text(L.text(.dark, lang: language)).tag("dark")
                    Text(L.text(.light, lang: language)).tag("light")
                    Text(L.text(.system, lang: language)).tag("system")
                }
                .pickerStyle(.segmented)
                .tint(.blue)
            }
        }
        .navigationTitle(L.text(.appearance, lang: language))
        .navigationBarTitleDisplayMode(.inline)
    }

    private func settingsBase<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        ZStack {
            LinearGradient(
                colors: usesLightPalette
                    ? [Color.white, Color(red: 0.95, green: 0.96, blue: 0.98)]
                    : [Color(red: 0.03, green: 0.11, blue: 0.28), Color.black],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 14) {
                    content()
                }
                .padding(.horizontal, 14)
                .padding(.top, 12)
                .padding(.bottom, 24)
            }
        }
    }

    private func settingsCard<Content: View>(title: String, icon: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 10) {
                Image(systemName: icon)
                    .font(.headline)
                    .foregroundStyle(.blue)
                    .frame(width: 26, height: 26)
                    .background(Circle().fill(Color.white.opacity(0.08)))
                Text(title)
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(primaryTextColor)
            }
            content()
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(usesLightPalette ? Color.white.opacity(0.95) : Color.white.opacity(0.08))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(usesLightPalette ? Color.black.opacity(0.10) : Color.white.opacity(0.06), lineWidth: 1)
                )
        )
    }
}

private struct CurrencySettingsScreen: View {
    @Environment(\.colorScheme) private var systemColorScheme
    @Binding var preferredAppearance: String
    @Binding var appLanguageRawValue: String
    @Binding var selectedCurrencyRawValue: String

    private var language: AppLanguage { AppLanguage(rawValue: appLanguageRawValue) ?? .en }

    private var usesLightPalette: Bool {
        switch preferredAppearance {
        case "light": return true
        case "dark": return false
        default: return systemColorScheme == .light
        }
    }

    private var primaryTextColor: Color { usesLightPalette ? .black : .white }

    var body: some View {
        settingsBase {
            settingsCard(title: L.text(.currency, lang: language), icon: "sterlingsign.circle.fill") {
                Picker(L.text(.currency, lang: language), selection: $selectedCurrencyRawValue) {
                    ForEach(AppCurrency.allCases, id: \.rawValue) { option in
                        Text(option.displayName).tag(option.rawValue)
                    }
                }
                .tint(primaryTextColor)
                .padding(12)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(usesLightPalette ? Color.black.opacity(0.06) : Color.white.opacity(0.06))
                )
            }
        }
        .navigationTitle(L.text(.currency, lang: language))
        .navigationBarTitleDisplayMode(.inline)
    }

    private func settingsBase<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        ZStack {
            LinearGradient(
                colors: usesLightPalette
                    ? [Color.white, Color(red: 0.95, green: 0.96, blue: 0.98)]
                    : [Color(red: 0.03, green: 0.11, blue: 0.28), Color.black],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 14) {
                    content()
                }
                .padding(.horizontal, 14)
                .padding(.top, 12)
                .padding(.bottom, 24)
            }
        }
    }

    private func settingsCard<Content: View>(title: String, icon: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 10) {
                Image(systemName: icon)
                    .font(.headline)
                    .foregroundStyle(.blue)
                    .frame(width: 26, height: 26)
                    .background(Circle().fill(Color.white.opacity(0.08)))
                Text(title)
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(primaryTextColor)
            }
            content()
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(usesLightPalette ? Color.white.opacity(0.95) : Color.white.opacity(0.08))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(usesLightPalette ? Color.black.opacity(0.10) : Color.white.opacity(0.06), lineWidth: 1)
                )
        )
    }
}

private struct AccessibilitySettingsScreen: View {
    @Environment(\.colorScheme) private var systemColorScheme
    @Binding var preferredAppearance: String
    @Binding var appLanguageRawValue: String
    @Binding var fontScale: Double

    private var language: AppLanguage { AppLanguage(rawValue: appLanguageRawValue) ?? .en }

    private var usesLightPalette: Bool {
        switch preferredAppearance {
        case "light": return true
        case "dark": return false
        default: return systemColorScheme == .light
        }
    }

    private var primaryTextColor: Color { usesLightPalette ? .black : .white }

    var body: some View {
        settingsBase {
            settingsCard(title: L.text(.accessibility, lang: language), icon: "figure.wave") {
                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        Text(L.text(.fontSize, lang: language))
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(primaryTextColor)
                        Spacer()
                        Text("\(Int(fontScale * 100))%")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.secondary)
                    }

                    Slider(value: $fontScale, in: 0.9...1.3, step: 0.05)
                        .tint(.blue)

                    DisclosureGroup(L.text(.voiceOverHelpTitle, lang: language)) {
                        Text(L.text(.voiceOverHelpBody, lang: language))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .padding(.top, 4)
                    }
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(primaryTextColor)
                    .padding(.top, 6)
                }
            }
        }
        .navigationTitle(L.text(.accessibility, lang: language))
        .navigationBarTitleDisplayMode(.inline)
    }

    private func settingsBase<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        ZStack {
            LinearGradient(
                colors: usesLightPalette
                    ? [Color.white, Color(red: 0.95, green: 0.96, blue: 0.98)]
                    : [Color(red: 0.03, green: 0.11, blue: 0.28), Color.black],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 14) {
                    content()
                }
                .padding(.horizontal, 14)
                .padding(.top, 12)
                .padding(.bottom, 24)
            }
        }
    }

    private func settingsCard<Content: View>(title: String, icon: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 10) {
                Image(systemName: icon)
                    .font(.headline)
                    .foregroundStyle(.blue)
                    .frame(width: 26, height: 26)
                    .background(Circle().fill(Color.white.opacity(0.08)))
                Text(title)
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(primaryTextColor)
            }
            content()
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(usesLightPalette ? Color.white.opacity(0.95) : Color.white.opacity(0.08))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(usesLightPalette ? Color.black.opacity(0.10) : Color.white.opacity(0.06), lineWidth: 1)
                )
        )
    }
}

private struct AddPassesSheet: UIViewControllerRepresentable {
    let passes: [PKPass]
    let onFinish: () -> Void

    func makeUIViewController(context: Context) -> UIViewController {
        if let controller = PKAddPassesViewController(passes: passes) {
            controller.delegate = context.coordinator
            return controller
        }
        return UIViewController()
    }

    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(onFinish: onFinish)
    }

    final class Coordinator: NSObject, PKAddPassesViewControllerDelegate {
        private let onFinish: () -> Void

        init(onFinish: @escaping () -> Void) {
            self.onFinish = onFinish
        }

        func addPassesViewControllerDidFinish(_ controller: PKAddPassesViewController) {
            controller.dismiss(animated: true)
            onFinish()
        }
    }
}

private struct MessageComposeView: UIViewControllerRepresentable {
    let recipients: [String]?
    let body: String
    let onResult: (MessageComposeResult) -> Void

    func makeUIViewController(context: Context) -> MFMessageComposeViewController {
        let controller = MFMessageComposeViewController()
        controller.messageComposeDelegate = context.coordinator
        controller.recipients = recipients
        controller.body = body
        return controller
    }

    func updateUIViewController(_ uiViewController: MFMessageComposeViewController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(onResult: onResult)
    }

    final class Coordinator: NSObject, MFMessageComposeViewControllerDelegate {
        private let onResult: (MessageComposeResult) -> Void

        init(onResult: @escaping (MessageComposeResult) -> Void) {
            self.onResult = onResult
        }

        func messageComposeViewController(_ controller: MFMessageComposeViewController, didFinishWith result: MessageComposeResult) {
            controller.dismiss(animated: true)
            onResult(result)
        }
    }
}

private final class UserLocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    @Published var location: CLLocation?

    private let manager = CLLocationManager()
    private var didRequestPermission = false

    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyHundredMeters
    }

    func requestPermissionIfNeeded() {
        guard !didRequestPermission else { return }
        didRequestPermission = true

        switch manager.authorizationStatus {
        case .authorizedAlways, .authorizedWhenInUse:
            manager.startUpdatingLocation()
        case .notDetermined:
            manager.requestWhenInUseAuthorization()
        case .denied, .restricted:
            break
        @unknown default:
            break
        }
    }

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        switch manager.authorizationStatus {
        case .authorizedAlways, .authorizedWhenInUse:
            manager.startUpdatingLocation()
        default:
            break
        }
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        location = locations.last
    }
}

private struct DirectionsSheet: View {
    @Environment(\.dismiss) private var dismiss
    let station: Station
    @Binding var mode: TransportMode
    let userLocation: CLLocationCoordinate2D?
    @State private var route: MKRoute?
    @State private var fallbackLine: MKPolyline?
    @State private var mapPosition: MapCameraPosition = .automatic

    var body: some View {
        ZStack(alignment: .top) {
            Map(position: $mapPosition) {
                if let route {
                    MapPolyline(route.polyline)
                        .stroke(.blue, lineWidth: 5)
                }
                if route == nil, let fallbackLine {
                    MapPolyline(fallbackLine)
                        .stroke(.blue.opacity(0.7), style: StrokeStyle(lineWidth: 4, lineCap: .round, dash: [8, 6]))
                }
                if let lat = station.latitude, let lon = station.longitude {
                    Marker(station.name, coordinate: CLLocationCoordinate2D(latitude: lat, longitude: lon))
                }
                if userLocation != nil {
                    UserAnnotation()
                }
            }
            .mapStyle(.standard(elevation: .realistic))
            .ignoresSafeArea()

            VStack(spacing: 12) {
                HStack {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.headline)
                            .foregroundStyle(.white)
                            .frame(width: 36, height: 36)
                            .background(Circle().fill(Color.black.opacity(0.6)))
                    }
                    Spacer()
                }

                HStack(spacing: 10) {
                    directionsModeButton(mode: .train)
                    directionsModeButton(mode: .bus)
                }
                .padding(10)
                .background(
                    RoundedRectangle(cornerRadius: 14)
                        .fill(Color.black.opacity(0.55))
                )

                Spacer()
            }
            .padding(.top, 10)
            .padding(.horizontal, 16)
        }
        .safeAreaInset(edge: .bottom) {
            directionsBottomCard
                .padding(.horizontal, 14)
                .padding(.bottom, 10)
        }
        .onAppear {
            Task { await calculateRoute() }
        }
        .onChange(of: mode) { _, _ in
            Task { await calculateRoute() }
        }
    }

    private func directionsModeButton(mode: TransportMode) -> some View {
        let selected = self.mode == mode
        return Button {
            self.mode = mode
        } label: {
            HStack(spacing: 8) {
                Image(systemName: mode == .train ? "tram.fill" : "bus.fill")
                Text(mode == .train ? "Train" : "Bus")
                    .font(.subheadline.weight(.semibold))
            }
            .foregroundStyle(selected ? .white : .white.opacity(0.7))
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(selected ? Color.blue.opacity(0.9) : Color.white.opacity(0.12))
            )
        }
        .buttonStyle(.plain)
    }

    private func calculateRoute() async {
        guard let lat = station.latitude, let lon = station.longitude else { return }

        let request = MKDirections.Request()
        if let userLocation {
            request.source = MKMapItem(placemark: MKPlacemark(coordinate: userLocation))
        }
        request.destination = MKMapItem(placemark: MKPlacemark(coordinate: CLLocationCoordinate2D(latitude: lat, longitude: lon)))
        request.transportType = mode == .walk ? .walking : .transit

        do {
            let response = try await MKDirections(request: request).calculate()
            route = response.routes.first
            if let route {
                mapPosition = .rect(route.polyline.boundingMapRect)
                fallbackLine = nil
            }
        } catch {
            route = nil
            fallbackLine = fallbackPolyline(to: CLLocationCoordinate2D(latitude: lat, longitude: lon))
            if let fallbackLine {
                mapPosition = .rect(fallbackLine.boundingMapRect)
            }
        }
    }

    private func fallbackPolyline(to destination: CLLocationCoordinate2D) -> MKPolyline? {
        if let userLocation {
            return MKPolyline(coordinates: [userLocation, destination], count: 2)
        }
        let offset = CLLocationCoordinate2D(latitude: destination.latitude + 0.01, longitude: destination.longitude - 0.01)
        return MKPolyline(coordinates: [offset, destination], count: 2)
    }

    private var directionsBottomCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(station.name)
                .font(.headline.weight(.semibold))
                .foregroundStyle(.white)
            if let route {
                HStack {
                    Text(timeString(route.expectedTravelTime))
                    Spacer()
                    Text(distanceString(route.distance))
                }
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.white.opacity(0.9))
                Text(mode == .train ? "Transit (Train)" : "Transit (Bus)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } else {
                Text("Calculating route…")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.black.opacity(0.75))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.white.opacity(0.08), lineWidth: 1)
                )
        )
    }

    private func timeString(_ seconds: TimeInterval) -> String {
        let mins = Int(round(seconds / 60))
        if mins < 60 { return "\(mins) min" }
        let hrs = mins / 60
        let rem = mins % 60
        return "\(hrs) hr \(rem) min"
    }

    private func distanceString(_ meters: CLLocationDistance) -> String {
        if meters < 1000 { return "\(Int(meters)) m" }
        return String(format: "%.1f km", meters / 1000)
    }
}

private struct TrackSheet: View {
    @Environment(\.dismiss) private var dismiss
    let stations: [Station]
    let mapping: StationMapping
    let ticket: TicketItem?
    let forcedStationIds: [Int]?
    let serviceTitle: String?
    let serviceOperator: String?
    let showFavoriteButton: Bool
    let isFavorite: Bool
    let onToggleFavorite: (() -> Void)?
    @State private var mapPosition: MapCameraPosition = .automatic
    @State private var routePolyline: MKPolyline?
    @State private var trainCoordinate: CLLocationCoordinate2D?
    @State private var progress: Double = 0.0
    @State private var timer: Timer?
    @State private var pulse = false

    var body: some View {
        ZStack(alignment: .topTrailing) {
            Map(position: $mapPosition) {
                if let routePolyline {
                    MapPolyline(routePolyline)
                        .stroke(Color.blue, lineWidth: 5)
                }
                ForEach(trackingStations, id: \.id) { station in
                    if let lat = station.latitude, let lon = station.longitude {
                        Annotation("", coordinate: CLLocationCoordinate2D(latitude: lat, longitude: lon)) {
                            Circle()
                                .fill(Color.white)
                                .frame(width: 8, height: 8)
                                .overlay(
                                    Circle()
                                        .stroke(Color.blue.opacity(0.85), lineWidth: 2)
                                )
                        }
                    }
                }
                if let trainCoordinate {
                    Annotation("", coordinate: trainCoordinate) {
                        ZStack {
                            Circle()
                                .fill(Color.blue.opacity(0.25))
                                .frame(width: 44, height: 44)
                            Circle()
                                .fill(Color.blue)
                                .frame(width: 18, height: 18)
                                .overlay(
                                    Image(systemName: "tram.fill")
                                        .font(.caption2)
                                        .foregroundStyle(.white)
                                )
                        }
                    }
                }
            }
            .mapStyle(.standard(elevation: .realistic))
            .ignoresSafeArea()

            HStack(spacing: 12) {
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "xmark")
                        .font(.headline)
                        .foregroundStyle(.white)
                        .frame(width: 36, height: 36)
                        .background(Circle().fill(Color.black.opacity(0.6)))
                }
                Spacer()
            }
            .padding(.top, 10)
            .padding(.horizontal, 16)

            trackSidebar
        }
        .onAppear {
            buildRoute()
            startTimer()
            withAnimation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true)) {
                pulse = true
            }
        }
        .onDisappear {
            timer?.invalidate()
        }
    }

    private var trackingStops: [TrackStop] {
        let stops = trackingStations
        guard !stops.isEmpty else { return [] }
        let times = ["Now", "6 min", "14 min", "22 min", "35 min", "48 min"]
        let startIndex = max(min(currentStopIndex, stops.count - 1), 0)
        return Array(stops[startIndex...]).enumerated().map { idx, station in
            TrackStop(id: station.id, name: station.name, eta: times[min(idx, times.count - 1)])
        }
    }

    private var trackingStations: [Station] {
        if let forcedStationIds, forcedStationIds.count >= 2 {
            let matched = forcedStationIds.compactMap { id in
                stations.first(where: { $0.id == id && $0.latitude != nil && $0.longitude != nil })
            }
            if matched.count >= 2 { return matched }
        }

        if let ticket {
            let byPath = ticket.stationIds.compactMap { id in
                stations.first(where: { $0.id == id && $0.latitude != nil && $0.longitude != nil })
            }
            if byPath.count >= 2 { return byPath }

            let codes = [ticket.originCode, ticket.destinationCode]
            let byCodes = codes.compactMap { code in
                stations.first(where: { $0.code == code && $0.latitude != nil && $0.longitude != nil })
            }
            if byCodes.count >= 2 { return byCodes }
        }
        let preferred = ["PRE", "LAN", "BPN", "BAR"]
        let byCode = preferred.compactMap { code in
            stations.first(where: { $0.code == code && $0.latitude != nil && $0.longitude != nil })
        }
        if byCode.count >= 2 { return byCode }
        return stations.filter { $0.latitude != nil && $0.longitude != nil }.prefix(4).map { $0 }
    }

    private var currentStopIndex: Int {
        let count = trackingStations.count
        guard count > 1 else { return 0 }
        let idx = Int(floor(progress * Double(count - 1)))
        return min(max(idx, 0), count - 2)
    }

    private var currentStation: Station? {
        let stations = trackingStations
        guard currentStopIndex < stations.count else { return nil }
        return stations[currentStopIndex]
    }

    private var nextStation: Station? {
        let stations = trackingStations
        let idx = currentStopIndex + 1
        guard idx < stations.count else { return nil }
        return stations[idx]
    }

    private var destinationStation: Station? {
        trackingStations.last
    }

    private func buildRoute() {
        let coords = trackingStations.compactMap { station -> CLLocationCoordinate2D? in
            guard let lat = station.latitude, let lon = station.longitude else { return nil }
            return CLLocationCoordinate2D(latitude: lat, longitude: lon)
        }
        guard coords.count >= 2 else { return }
        routePolyline = MKPolyline(coordinates: coords, count: coords.count)
        trainCoordinate = coords.first
        mapPosition = .rect(routePolyline?.boundingMapRect ?? MKMapRect.world)
    }

    private func startTimer() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 0.06, repeats: true) { _ in
            progress += 0.0018
            if progress > 1.0 { progress = 0.0 }
            if let routePolyline {
                trainCoordinate = coordinate(on: routePolyline, fraction: progress)
            }
        }
    }

    private func coordinate(on polyline: MKPolyline, fraction: Double) -> CLLocationCoordinate2D {
        let points = polyline.points()
        let count = polyline.pointCount
        guard count > 1 else { return polyline.coordinate }

        var distances: [CLLocationDistance] = []
        distances.reserveCapacity(count)
        distances.append(0)
        for i in 1..<count {
            let p0 = points[i - 1]
            let p1 = points[i]
            let d = p0.distance(to: p1)
            distances.append(distances[i - 1] + d)
        }
        let total = distances.last ?? 1
        let target = total * fraction
        for i in 1..<count {
            if distances[i] >= target {
                let prev = distances[i - 1]
                let seg = max(distances[i] - prev, 0.001)
                let t = (target - prev) / seg
                let p0 = points[i - 1]
                let p1 = points[i]
                let x = p0.x + (p1.x - p0.x) * t
                let y = p0.y + (p1.y - p0.y) * t
                return MKMapPoint(x: x, y: y).coordinate
            }
        }
        return points[count - 1].coordinate
    }

    private var trackSidebar: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack(spacing: 8) {
                Circle()
                    .fill(Color.green)
                    .frame(width: 8, height: 8)
                    .overlay(
                        Circle()
                            .stroke(Color.green.opacity(0.6), lineWidth: 6)
                            .scaleEffect(pulse ? 1.2 : 0.6)
                            .opacity(pulse ? 0.0 : 0.8)
                    )
                Text("LIVE")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.green)
            }

            HStack(alignment: .top, spacing: 8) {
                VStack(alignment: .leading, spacing: 6) {
                    Text(serviceTitle ?? ticket?.routeTitle ?? "Train 38")
                        .font(.headline.weight(.semibold))
                        .foregroundStyle(.white)
                    Text(serviceOperator ?? "Avanti West Coast")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer(minLength: 0)
                if showFavoriteButton {
                    Button {
                        onToggleFavorite?()
                    } label: {
                        Image(systemName: isFavorite ? "star.fill" : "star")
                            .font(.subheadline.weight(.bold))
                            .foregroundStyle(isFavorite ? .yellow : .white)
                            .frame(width: 28, height: 28)
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(Color.white.opacity(0.10))
                            )
                    }
                    .buttonStyle(.plain)
                }
            }

            VStack(alignment: .leading, spacing: 10) {
                if let currentStation {
                    HStack(spacing: 8) {
                        Image(systemName: "location.fill")
                            .font(.caption)
                            .foregroundStyle(.blue)
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Current")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                            Text(currentStation.name)
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(.white)
                        }
                    }
                }
                if let nextStation {
                    HStack(spacing: 8) {
                        Image(systemName: "arrowtriangle.right.fill")
                            .font(.caption)
                            .foregroundStyle(.cyan)
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Next")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                            Text(nextStation.name)
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(.white)
                        }
                    }
                }
                if let destinationStation {
                    HStack(spacing: 8) {
                        Image(systemName: "flag.checkered")
                            .font(.caption)
                            .foregroundStyle(.orange)
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Destination")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                            Text(destinationStation.name)
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(.white)
                        }
                    }
                }
            }

            Divider()
                .background(Color.white.opacity(0.12))

            Text("Upcoming stops")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)

            ForEach(trackingStops, id: \.id) { stop in
                HStack {
                    Text(stop.name)
                        .foregroundStyle(.white)
                        .font(.subheadline)
                    Spacer()
                    Text(stop.eta)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.cyan)
                }
            }

            Spacer(minLength: 8)
        }
        .padding(.vertical, 20)
        .padding(.horizontal, 14)
        .frame(width: 160, alignment: .topLeading)
        .frame(maxHeight: .infinity, alignment: .topLeading)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.black.opacity(0.78))
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(Color.white.opacity(0.08), lineWidth: 1)
                )
        )
        .padding(.top, 70)
        .padding(.trailing, 12)
    }
}

private struct TrackStop: Identifiable {
    let id: Int
    let name: String
    let eta: String
}

#Preview {
    ContentView()
        .environmentObject(AppState())
}
