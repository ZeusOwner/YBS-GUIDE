import json
import math
from pathlib import Path


YANGON_MIN_LAT = 16.6
YANGON_MAX_LAT = 17.1
YANGON_MIN_LNG = 96.0
YANGON_MAX_LNG = 96.4

PRIORITY_ROUTES = {
    "1",
    "2",
    "3",
    "6",
    "9",
    "12",
    "33",
    "36",
    "37",
    "38",
    "43",
    "46",
    "53",
    "56",
    "60",
    "63",
    "65",
    "66",
    "69",
    "72",
}


def haversine(lat1, lon1, lat2, lon2):
    radius = 6371000
    phi1, phi2 = math.radians(lat1), math.radians(lat2)
    dphi = math.radians(lat2 - lat1)
    dlambda = math.radians(lon2 - lon1)
    a = (
        math.sin(dphi / 2) ** 2
        + math.cos(phi1) * math.cos(phi2) * math.sin(dlambda / 2) ** 2
    )
    return radius * 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a))


def in_yangon_bounds(stop):
    return (
        YANGON_MIN_LAT <= float(stop["lat"]) <= YANGON_MAX_LAT
        and YANGON_MIN_LNG <= float(stop["lng"]) <= YANGON_MAX_LNG
    )


def route_number(route):
    return str(route.get("routeNumber", "")).replace("YBS-", "")


def load_json(path):
    with path.open(encoding="utf-8") as file:
        return json.load(file)


def best_osm_routes(osm_routes):
    best = {}
    for route in osm_routes:
        ref = str(route.get("ref", ""))
        stops = route.get("stops", [])
        if not ref or len(stops) < 3:
            continue
        if ref not in PRIORITY_ROUTES:
            continue
        if not all(in_yangon_bounds(stop) for stop in stops):
            continue
        current = best.get(ref)
        if current is None or len(stops) > len(current.get("stops", [])):
            best[ref] = route
    return best


def build_stop(stop, index, total):
    name = str(stop.get("name") or f"Stop {index + 1}").strip()
    return {
        "id": f"stop-osm-{stop['osmId']}",
        "nameEn": name,
        "nameMm": name,
        "latitude": float(stop["lat"]),
        "longitude": float(stop["lng"]),
        "isTerminal": index == 0 or index == total - 1,
        "sequence": index + 1,
        "source": "osm",
    }


def main():
    project_root = Path(__file__).resolve().parents[1]
    production_path = project_root / "assets" / "data" / "ybs_routes_production.json"
    osm_path = (
        project_root.parent
        / "ybs-data"
        / "osm_source"
        / "osm_routes_summary.json"
    )

    production = load_json(production_path)
    osm = load_json(osm_path)
    production_routes = production["routes"]
    osm_by_ref = best_osm_routes(osm["routes"])

    updated = []
    skipped = []
    for prod_route in production_routes:
        number = route_number(prod_route)
        if number not in PRIORITY_ROUTES:
            continue

        osm_route = osm_by_ref.get(number)
        if osm_route is None:
            skipped.append(f"YBS-{number}: no eligible OSM route")
            continue

        stops = osm_route["stops"]
        prod_route["stops"] = [
            build_stop(stop, index, len(stops)) for index, stop in enumerate(stops)
        ]
        prod_route["dataConfidence"] = "estimated"
        updated.append(f"YBS-{number}: {len(stops)} stops")

    with production_path.open("w", encoding="utf-8") as file:
        json.dump(production, file, ensure_ascii=False, indent=2)
        file.write("\n")

    print(f"Updated {len(updated)} routes with OSM stop data")
    for item in updated:
        print(f"  {item}")
    if skipped:
        print("Skipped:")
        for item in skipped:
            print(f"  {item}")


if __name__ == "__main__":
    main()
