#!/usr/bin/env -S uv run --script
#
# /// script
# requires-python = ">=3.12"
# dependencies = [
#   "airportsdata",
#   "click",
#   "geopandas",
#   "geopy",
#   "numpy",
#   "plotly",
#   "beautifulsoup4",
# ]
# ///

import airportsdata
import click
import geopandas as gpd
import numpy as np
import xml.etree.ElementTree as ET
import plotly.graph_objects as go
from bs4 import BeautifulSoup
from pathlib import Path
from geopy.distance import distance
from geopy.point import Point


@click.command("visualize-flights")
@click.option(
    "--output",
    type=click.File(
        mode="w",
        atomic=True,
    ),
)
@click.argument(
    "directory",
    type=click.Path(
        exists=True,
        file_okay=False,
        dir_okay=True,
        path_type=Path,
    ),
)
def visualize_flights(directory, output):
    fig = go.Figure()

    icao = airportsdata.load()
    iata = airportsdata.load("IATA")

    for filename in directory.rglob("*.kml"):
        tree = ET.parse(filename)
        root = tree.getroot()
        ns = {
            "kml": "http://www.opengis.net/kml/2.2",
            "gx": "http://www.google.com/kml/ext/2.2",
        }

        lat = []
        lon = []

        if filename.name.startswith("FlightAware"):
            placemark = root.findall(".//kml:Document/kml:Placemark", ns)[2]
            name = placemark.find(".//kml:name", ns).text.strip()
            src, dst = placemark.find(".//kml:description", ns).text.split(" - ")

            src = icao[src]
            dst = icao[dst]

            track = placemark.find(".//gx:Track", ns).findall(".//gx:coord", ns)
            for point in track:
                x, y, _z = point.text.split(" ")
                lat = np.append(lat, y)
                lon = np.append(lon, x)
        else:
            name = root.find(".//kml:Document/kml:name", ns).text.split("/")[0].strip()
            desc = root.find(".//kml:Document/kml:description", ns).text

            soup = BeautifulSoup(desc, "html.parser")
            src, dst = (h3.get_text() for h3 in soup.css.select("a h3"))

            src = iata[src]
            dst = iata[dst]

            df = gpd.read_file(filename, layer="Trail")
            for feature in df.geometry:
                for linestring in feature.geoms:
                    for coord in linestring.coords:
                        x, y, _z = coord
                        lat = np.append(lat, y)
                        lon = np.append(lon, x)

        if (
            distance(
                Point(latitude=src["lat"], longitude=src["lon"]),
                Point(latitude=lat[0], longitude=lon[0]),
            ).km
            > 5.0
        ):
            lat = np.concatenate(([src["lat"]], lat))
            lon = np.concatenate(([src["lon"]], lon))

        if (
            distance(
                Point(latitude=dst["lat"], longitude=dst["lon"]),
                Point(latitude=lat[-1], longitude=lon[-1]),
            ).km
            > 5.0
        ):
            lat = np.append(lat, dst["lat"])
            lon = np.append(lon, dst["lon"])

        print(f"{name}: {src['iata']} -> {dst['iata']}")

        fig.add_trace(
            go.Scattermap(
                mode="lines",
                name=name,
                hovertemplate=f"<b>{name}</b><extra><i style='color: black;'>{src['iata']} -> {dst['iata']}</i></extra>",
                lon=lon,
                lat=lat,
                line=go.scattermap.Line(width=3),
            )
        )

    fig.update_layout(
        showlegend=False,
        margin=dict(l=0, r=0, b=0, t=0, pad=0),
        map=dict(
            center=dict(lat=42.363056, lon=-71.006389),  # BOS
            style="carto-darkmatter",
            zoom=3,
        ),
    )

    if output:
        fig.write_html(output, include_plotlyjs="cdn")
    else:
        fig.show()


if __name__ == "__main__":
    visualize_flights()
