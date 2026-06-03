import Foundation

struct WeatherResponse: Codable {
    let current: CurrentWeather
    let daily: DailyWeather
}

struct CurrentWeather: Codable {
    let temperature: Double
    let windspeed: Double
    let weathercode: Int
    let time: String

    enum CodingKeys: String, CodingKey {
        case temperature = "temperature_2m"
        case windspeed = "wind_speed_10m"
        case weathercode = "weather_code"
        case time
    }
}

struct DailyWeather: Codable {
    let time: [String]
    let temperatureMax: [Double]
    let temperatureMin: [Double]
    let weathercode: [Int]

    enum CodingKeys: String, CodingKey {
        case time
        case temperatureMax = "temperature_2m_max"
        case temperatureMin = "temperature_2m_min"
        case weathercode = "weather_code"
    }
}

struct DayForecast: Identifiable {
    let id = UUID()
    let day: String
    let high: Int
    let low: Int
    let weathercode: Int
    var icon: String { weatherIcon(for: weathercode) }
}

func weatherIcon(for code: Int) -> String {
    switch code {
    case 0:           return "sun.max.fill"
    case 1, 2:        return "cloud.sun.fill"
    case 3:           return "cloud.fill"
    case 45, 48:      return "cloud.fog.fill"
    case 51...65:     return "cloud.rain.fill"
    case 71...77:     return "cloud.snow.fill"
    case 80...82:     return "cloud.heavyrain.fill"
    case 95, 96, 99:  return "cloud.bolt.rain.fill"
    default:          return "cloud.fill"
    }
}

func weatherDescription(for code: Int) -> String {
    switch code {
    case 0:       return "Clear Sky"
    case 1:       return "Mostly Clear"
    case 2:       return "Partly Cloudy"
    case 3:       return "Overcast"
    case 45, 48:  return "Foggy"
    case 51...55: return "Drizzle"
    case 61...65: return "Rain"
    case 71...75: return "Snow"
    case 80...82: return "Rain Showers"
    case 95:      return "Thunderstorm"
    default:      return "Cloudy"
    }
}