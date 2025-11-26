#!/usr/bin/env -S uv run --script
#
# /// script
# requires-python = ">=3.12"
# dependencies = [
#   "click",
#   "geopandas",
#   "numpy",
#   "plotly",
#   "beautifulsoup4",
# ]
# ///

import click
import geopandas as gpd
import numpy as np
import xml.etree.ElementTree as ET
import plotly.graph_objects as go
from bs4 import BeautifulSoup
from pathlib import Path


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

    for filename in directory.rglob("*.kml"):
        tree = ET.parse(filename)
        root = tree.getroot()
        ns = {"kml": "http://www.opengis.net/kml/2.2"}

        if filename.name.startswith("FlightAware"):
            pass
        else:
            name = root.find(".//kml:Document/kml:name", ns).text.split("/")[0].strip()
            desc = root.find(".//kml:Document/kml:description", ns).text

            lat = []
            lon = []

            df = gpd.read_file(filename, layer="Trail")
            for feature in df.geometry:
                for linestring in feature.geoms:
                    for coord in linestring.coords:
                        x, y, _z = coord
                        lat = np.append(lat, y)
                        lon = np.append(lon, x)

            soup = BeautifulSoup(desc, "html.parser")
            src, dst = (h3.get_text() for h3 in soup.css.select("a h3"))

            fig.add_trace(
                go.Scattermap(
                    mode="lines",
                    name=name,
                    hovertemplate=f"<b>{name}</b><extra><i style='color: black;'>{src} -> {dst}</i></extra>",
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
