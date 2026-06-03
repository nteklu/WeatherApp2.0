import SwiftUI

struct ContentView: View {
    @StateObject private var service = WeatherService()
    @State private var showSearch = false

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color("skyBlueTop"), Color("skyBlueBottom")],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            if service.isLoading {
                LoadingView()
            } else if let error = service.errorMessage {
                ErrorView(message: error) { service.fetchWeather() }
            } else {
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 0) {
                        HeaderView(city: service.cityName) {
                            showSearch.toggle()
                        }
                        if let current = service.current {
                            CurrentWeatherView(weather: current)
                        }
                        if !service.forecast.isEmpty {
                            ForecastView(days: service.forecast)
                        }
                        Spacer(minLength: 40)
                    }
                }
            }
        }
        .onAppear { service.fetchWeather() }
        .sheet(isPresented: $showSearch) {
            SearchView(isPresented: $showSearch) { city, lat, lon in
                service.fetchWeather(lat: lat, lon: lon, city: city)
            }
        }
    }
}

// MARK: - Header
struct HeaderView: View {
    let city: String
    let onSearchTap: () -> Void

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(city)
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                Text(Date(), style: .date)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(.white.opacity(0.8))
            }
            Spacer()
            Button(action: onSearchTap) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(.white)
                    .padding(12)
                    .background(.white.opacity(0.2))
                    .clipShape(Circle())
            }
        }
        .padding(.horizontal, 24)
        .padding(.top, 60)
        .padding(.bottom, 16)
    }
}

// MARK: - Current Weather
struct CurrentWeatherView: View {
    let weather: CurrentWeather

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: weatherIcon(for: weather.weathercode))
                .font(.system(size: 90))
                .foregroundStyle(.white, .white.opacity(0.6))
                .shadow(color: .black.opacity(0.15), radius: 10)
                .padding(.top, 20)

            Text("\(Int(weather.temperature.rounded()))°")
                .font(.system(size: 100, weight: .thin, design: .rounded))
                .foregroundColor(.white)

            Text(weatherDescription(for: weather.weathercode))
                .font(.system(size: 22, weight: .medium, design: .rounded))
                .foregroundColor(.white.opacity(0.9))

            HStack(spacing: 16) {
                WeatherChip(icon: "wind", label: "Wind", value: "\(Int(weather.windspeed.rounded())) mph")
                WeatherChip(icon: "thermometer.medium", label: "Temp", value: "\(Int(weather.temperature.rounded()))°F")
                WeatherChip(icon: "clock", label: "Updated", value: shortTime(from: weather.time))
            }
            .padding(.top, 8)
        }
        .padding(.horizontal, 16)
        .padding(.bottom, 32)
    }

    func shortTime(from isoString: String) -> String {
        let f = ISO8601DateFormatter()
        f.formatOptions = [.withFullDate, .withTime, .withDashSeparatorInDate, .withColonSeparatorInTime]
        if let date = f.date(from: isoString) {
            let out = DateFormatter()
            out.dateFormat = "h:mm a"
            return out.string(from: date)
        }
        return "--"
    }
}

struct WeatherChip: View {
    let icon: String
    let label: String
    let value: String

    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 18))
                .foregroundColor(.white.opacity(0.8))
            Text(value)
                .font(.system(size: 14, weight: .semibold, design: .rounded))
                .foregroundColor(.white)
            Text(label)
                .font(.system(size: 11))
                .foregroundColor(.white.opacity(0.6))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .background(.white.opacity(0.15))
        .cornerRadius(16)
    }
}

// MARK: - Forecast
struct ForecastView: View {
    let days: [DayForecast]

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("7-Day Forecast")
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(.white.opacity(0.7))
                .tracking(1)
                .textCase(.uppercase)
                .padding(.horizontal, 24)

            VStack(spacing: 0) {
                ForEach(Array(days.enumerated()), id: \.element.id) { index, day in
                    ForecastRow(day: day)
                    if index < days.count - 1 {
                        Divider()
                            .background(.white.opacity(0.15))
                            .padding(.horizontal, 16)
                    }
                }
            }
            .background(.white.opacity(0.15))
            .cornerRadius(20)
            .padding(.horizontal, 16)
        }
    }
}

struct ForecastRow: View {
    let day: DayForecast

    var body: some View {
        HStack(spacing: 16) {
            Text(day.day)
                .font(.system(size: 16, weight: .medium, design: .rounded))
                .foregroundColor(.white)
                .frame(width: 52, alignment: .leading)

            Image(systemName: day.icon)
                .font(.system(size: 22))
                .foregroundStyle(.white, .white.opacity(0.5))
                .frame(width: 28)

            Spacer()

            Text("L: \(day.low)°")
                .font(.system(size: 14))
                .foregroundColor(.white.opacity(0.6))

            Text("H: \(day.high)°")
                .font(.system(size: 16, weight: .semibold, design: .rounded))
                .foregroundColor(.white)
                .frame(width: 52, alignment: .trailing)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 14)
    }
}

// MARK: - Search
struct SearchView: View {
    @Binding var isPresented: Bool
    let onSearch: (String, Double, Double) -> Void
    @State private var text = ""
    @State private var selectedCity: String? = nil

    let cities: [(name: String, lat: Double, lon: Double)] = [
        ("New York", 40.7128, -74.0060),
        ("Los Angeles", 34.0522, -118.2437),
        ("Chicago", 41.8781, -87.6298),
        ("Houston", 29.7604, -95.3698),
        ("Miami", 25.7617, -80.1918),
        ("Seattle", 47.6062, -122.3321),
        ("London", 51.5074, -0.1278),
        ("Tokyo", 35.6762, 139.6503),
        ("Paris", 48.8566, 2.3522),
        ("Sydney", -33.8688, 151.2093),
        ("Dubai", 25.2048, 55.2708),
        ("Toronto", 43.6532, -79.3832),
    ]

    var filtered: [(name: String, lat: Double, lon: Double)] {
        text.isEmpty ? cities : cities.filter {
            $0.name.localizedCaseInsensitiveContains(text)
        }
    }

    var body: some View {
        NavigationView {
            ZStack {
                List(filtered, id: \.name) { city in
                    Button(action: {
                        selectedCity = city.name
                        onSearch(city.name, city.lat, city.lon)
                        // Small delay so spinner shows, then dismiss
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                            isPresented = false
                        }
                    }) {
                        HStack {
                            Image(systemName: "location.fill")
                                .foregroundColor(.blue)
                            Text(city.name)
                                .foregroundColor(.primary)
                            Spacer()
                            if selectedCity == city.name {
                                ProgressView()
                                    .scaleEffect(0.8)
                            }
                        }
                    }
                    .disabled(selectedCity != nil)
                }
                .searchable(text: $text, prompt: "Search cities")
                .navigationTitle("Choose City")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Cancel") { isPresented = false }
                    }
                }

                // Full overlay spinner while loading
                if selectedCity != nil {
                    Color.black.opacity(0.3)
                        .ignoresSafeArea()
                    VStack(spacing: 12) {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .scaleEffect(1.4)
                        Text("Loading \(selectedCity ?? "")...")
                            .foregroundColor(.white)
                            .font(.system(size: 15, weight: .medium))
                    }
                    .padding(28)
                    .background(.ultraThinMaterial)
                    .cornerRadius(16)
                }
            }
        }
    }
}

// MARK: - Loading & Error
struct LoadingView: View {
    var body: some View {
        VStack(spacing: 16) {
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                .scaleEffect(1.5)
            Text("Loading weather...")
                .foregroundColor(.white.opacity(0.8))
                .font(.system(size: 16, weight: .medium))
        }
    }
}

struct ErrorView: View {
    let message: String
    let retry: () -> Void

    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 48))
                .foregroundColor(.white.opacity(0.8))
            Text("Something went wrong")
                .font(.title2.bold())
                .foregroundColor(.white)
            Text(message)
                .foregroundColor(.white.opacity(0.7))
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            Button("Try Again", action: retry)
                .padding(.horizontal, 32)
                .padding(.vertical, 12)
                .background(.white)
                .foregroundColor(.blue)
                .cornerRadius(24)
        }
        .padding(40)
    }
}