import UIKit

typealias Track = String

final class ApplicationController {
    typealias Dependencies = HasFavoritesService

    private weak var tracksViewController: TracksViewController?

    private var indices: TracksIndices?
    private var selectedTrack: Track?

    private let schedule: Schedule
    private let dependencies: Dependencies

    init(schedule: Schedule, dependencies: Dependencies) {
        self.schedule = schedule
        self.dependencies = dependencies

        DispatchQueue.global().async { [weak self] in
            self?.indices = .init(schedule: schedule)

            // The Schedule API does not model tracks with an explicit model.
            // Tracks information is stored within the event model itself. This
            // means that in order to be able to get the list of all tracks you
            // need to traverse all events, collect all tracks identifiers and
            // sort them. Given that most recent conferences had 400+ events,
            // this takes a while.
            DispatchQueue.main.async {
                self?.tracksViewController?.reloadData()
            }
        }
    }

    func makeRootViewController() -> UIViewController {
        let tracksViewController = makeTracksViewController()
        let navigationController = UINavigationController(rootViewController: tracksViewController)

        if #available(iOS 11.0, *) {
            navigationController.navigationBar.prefersLargeTitles = true
        }

        let tabBarController = UITabBarController()
        tabBarController.setViewControllers([navigationController], animated: true)
        return tabBarController
    }

    private func makeTracksViewController() -> TracksViewController {
        let tracksViewController = TracksViewController()
        tracksViewController.delegate = self
        tracksViewController.dataSource = self
        tracksViewController.title = NSLocalizedString("Tracks", comment: "")
        self.tracksViewController = tracksViewController

        if #available(iOS 11.0, *) {
            tracksViewController.navigationItem.largeTitleDisplayMode = .always
        }

        return tracksViewController
    }

    private func makeEventsViewController(for track: Track) -> EventsViewController {
        let eventsViewController = EventsViewController()
        eventsViewController.title = track
        eventsViewController.delegate = self
        eventsViewController.dataSource = self
        eventsViewController.hidesBottomBarWhenPushed = true

        if #available(iOS 11.0, *) {
            eventsViewController.navigationItem.largeTitleDisplayMode = .always
        }

        return eventsViewController
    }

    private func makeEventViewController(for event: Event) -> EventViewController {
        let eventViewController = EventViewController()
        eventViewController.dataSource = self
        eventViewController.delegate = self
        eventViewController.event = event

        if #available(iOS 11.0, *) {
            eventViewController.navigationItem.largeTitleDisplayMode = .never
        }

        return eventViewController
    }
}

extension ApplicationController: TracksViewControllerDataSource, TracksViewControllerDelegate {
    private var favoritesService: FavoritesService {
        dependencies.favoritesService
    }

    var tracks: [Track] {
        indices?.tracks ?? []
    }

    var tracksForDay: [[Track]] {
        indices?.tracksForDay ?? []
    }

    var favoriteTracks: [Track] {
        favoritesService.tracks
    }

    func tracksViewController(_: TracksViewController, didFavorite track: Track) {
        favoritesService.addTrack(track)
        tracksViewController?.reloadFavorites()
    }

    func tracksViewController(_: TracksViewController, didUnfavorite track: Track) {
        favoritesService.removeTrack(track)
        tracksViewController?.reloadFavorites()
    }

    func tracksViewController(_ tracksViewController: TracksViewController, didSelect track: Track) {
        selectedTrack = tracksViewController.selectedTrack
        tracksViewController.show(makeEventsViewController(for: track), sender: nil)
    }
}

extension ApplicationController: EventsViewControllerDataSource, EventsViewControllerDelegate {
    var events: [Event] {
        guard let selectedTrack = selectedTrack, let eventsForTrack = indices?.eventsForTrack else { return [] }
        return eventsForTrack[selectedTrack] ?? []
    }

    func eventsViewController(_ eventsViewController: EventsViewController, didSelect event: Event) {
        eventsViewController.show(makeEventViewController(for: event), sender: nil)
    }
}

extension ApplicationController: EventViewControllerDataSource, EventViewControllerDelegate {
    func isEventFavorite(for eventViewController: EventViewController) -> Bool {
        guard let _ = eventViewController.event else { return false }
        return false
    }

    func eventViewControllerDidTapFavorite(_ eventViewController: EventViewController) {
        eventViewController.reloadFavoriteState()
    }
}
