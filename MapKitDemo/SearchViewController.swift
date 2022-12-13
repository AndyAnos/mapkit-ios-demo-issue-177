import UIKit
import YandexMapsMobile

/**
 * This example shows how to add and interact with a layer that displays search results on the map.
 * Note: search API calls count towards MapKit daily usage limits. Learn more at
 * https://tech.yandex.ru/mapkit/doc/3.x/concepts/conditions-docpage/#conditions__limits
 */
class SearchViewController: BaseMapViewController, YMKMapCameraListener {

    var searchManager: YMKSearchManager?
    var searchSession: YMKSearchSession?

    override func viewDidLoad() {
        super.viewDidLoad()

        searchManager = YMKSearch.sharedInstance().createSearchManager(with: .combined)

        mapView.mapWindow.map.addCameraListener(with: self)

        mapView.mapWindow.map.move(with: YMKCameraPosition(
            target: YMKPoint(latitude: 59.945933, longitude: 30.320045),
            zoom: 14,
            azimuth: 0,
            tilt: 0))
    }

    func onCameraPositionChanged(with map: YMKMap,
                                 cameraPosition: YMKCameraPosition,
                                 cameraUpdateReason: YMKCameraUpdateReason,
                                 finished: Bool) {
        if finished {
            let responseHandler = {(searchResponse: YMKSearchResponse?, error: Error?) -> Void in
                if let response = searchResponse {
                    self.onSearchResponse(response)
                } else {
                    self.onSearchError(error!)
                }
            }

            searchSession = searchManager!.submit(
//                withText: "Россия, Москва, Мосфильмовская улица", // returns true in getAddressMapModelIsEmptyHouse()
                withText: "Россия, Москва, Центральный административный округ, Пресненский район, Московский международный деловой центр Москва-Сити", // returns false in getAddressMapModelIsEmptyHouse()
                geometry: YMKVisibleRegionUtils.toPolygon(with: map.visibleRegion),
                searchOptions: YMKSearchOptions(),
                responseHandler: responseHandler)
        }
    }

    func onSearchResponse(_ response: YMKSearchResponse) {
        let mapObjects = mapView.mapWindow.map.mapObjects
        mapObjects.clear()
        debugPrint("TEST METADATA:", response.collection.children.getAddressMapModelIsEmptyHouse())
    }

    func onSearchError(_ error: Error) {
        let searchError = (error as NSError).userInfo[YRTUnderlyingErrorKey] as! YRTError
        var errorMessage = "Unknown error"
        if searchError.isKind(of: YRTNetworkError.self) {
            errorMessage = "Network error"
        } else if searchError.isKind(of: YRTRemoteError.self) {
            errorMessage = "Remote server error"
        }

        let alert = UIAlertController(title: "Error", message: errorMessage, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))

        present(alert, animated: true, completion: nil)
    }
}

extension Array where Element == YMKGeoObjectCollectionItem {
    func getAddressMapModelIsEmptyHouse() -> Bool {
        for item in self {
            if let _ = item.obj?.metadataContainer
                .getItemOf(YMKSearchToponymObjectMetadata.self) as? YMKSearchToponymObjectMetadata {
                return true
            }
        }
        return false
    }
}
