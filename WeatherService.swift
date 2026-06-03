import Foundation

class WeatherService: ObservableObject {
    @Published var current: CurrentWeather?
    @Published var forecast: [DayForecast] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var cityName: String = "New York"

    func fetchWeather(lat: Double = 40.7128, lon: Double = -74.0060, city: String = "New York") {
        self.cityName = city
        isLoading = true
        errorMessage = nil

        let urlString = "https://api.open-meteo.com/v1/forecast?latitude=\(lat)&longitude=\(lon)&current=temperature_2m,wind_speed_10m,weather_code&daily=temperature_2m_max,temperature_2m_min,weather_code&temperature_unit=fahrenheit&wind_speed_unit=mph&forecast_days=7"

        guard let url = URL(string: urlString) else { return }

        URLSession.shared.dataTask(with: url) { [weak self] data, _, error in
            DispatchQueue.main.async {
                self?.isLoading = false
                if let error = error {
                    self?.errorMessage = error.localizedDescription
                    return
                }
                guard let data = data else { return }
                do {
                    let decoded = try JSONDecoder().decode(WeatherResponse.self, from: data)
                    self?.current = decoded.current
                    self?.forecast = Self.buildForecast(from: decoded.daily)
                } catch {
                    self?.errorMessage = "Failed to decode weather data."
                }
            }
        }.resume()
    }

    private static func buildForecast(from daily: DailyWeather) -> [DayForecast] {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let dayFormatter = DateFormatter()
        dayFormatter.dateFormat = "EEE"

        return daily.time.indices.map { i in
            let label: String
            if i == 0 {
                label = "Today"
            } else if let date = formatter.date(from: daily.time[i]) {
                label = dayFormatter.string(from: date)
            } else {
                label = daily.time[i]
            }
            return DayForecast(
                day: label,
                high: Int(daily.temperatureMax[i].rounded()),
                low: Int(daily.temperatureMin[i].rounded()),
                weathercode: daily.weathercode[i]
            )
        }
    }
}