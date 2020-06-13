#if DEBUG
import UIKit

final class TestsService {
  private let formatter = ISO8601DateFormatter()

  private let environment: [String: String]
  private let debugService: DebugService
  private let favoritesService: FavoritesService

  init(favoritesService: FavoritesService, debugService: DebugService, environment: [String: String] = ProcessInfo.processInfo.environment) {
    self.favoritesService = favoritesService
    self.debugService = debugService
    self.environment = environment
  }

  func configureEnvironment() {
    DispatchQueue.main.async {
      UIApplication.shared.keyWindow?.layer.speed = 100
    }

    if environment["RESET_FAVORITES"] != nil {
      for identifier in favoritesService.eventsIdentifiers {
        favoritesService.removeEvent(withIdentifier: identifier)
      }

      for identifier in favoritesService.tracksIdentifiers {
        favoritesService.removeTrack(withIdentifier: identifier)
      }
    }

    if let tracks = environment["FAVORITE_EVENTS"] {
      for identifier in favoritesService.eventsIdentifiers {
        favoritesService.removeEvent(withIdentifier: identifier)
      }

      let identifiers = tracks.components(separatedBy: ",")
      for identifier in identifiers {
        if let identifier = Int(identifier) {
          favoritesService.addEvent(withIdentifier: identifier)
        }
      }
    }

    if let string = environment["SOON_DATE"] {
      if let date = formatter.date(from: string) {
        debugService.override(date)
      }
    }
  }
}
#endif
