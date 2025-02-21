
# Code is from: https://github.com/st-howard/blog-notebooks
#found in: https://colab.research.google.com/github/st-howard/blog-notebooks/blob/main/Google_Earth_Engine/Satellite%20Imagery%20with%20Google%20Earth%20Engine.ipynb

import ee  # Google Earth Engine
import eemont  # Extension to Google Earth Engine

from PIL import Image
import requests
import rasterio
import numpy as np
import datetime
import geopy
import geopy.distance
import matplotlib.pyplot as plt
import sys
import time


Cords = [sys.argv[1], sys.argv[2]]

ee.Authenticate()
ee.Initialize(project='gniesat')

def BBoxFromPoint(bbox_size, lat_point, lon_point):
    """
    bbox_size - either square in km (one value) or two values in NS km, then EW km
    lat_point - lat center of bounding box
    lon_point - lon center of bounding box

    returns ee.Geometry object of bounding box
    """
    if type(bbox_size) == int or type(bbox_size) == float:
        bbox_size = np.array([bbox_size])

    if len(bbox_size) == 1:
        lat_km = bbox_size[0]
        lon_km = bbox_size[0]
    elif len(bbox_size) == 2:
        lat_km, lon_km = bbox_size
    else:
        raise ValueError("bbox_size must be either length 1 or 2")

    origin = geopy.Point(lat_point, lon_point)
    lat_min = (
        geopy.distance.geodesic(kilometers=lat_km / 2).destination(origin, bearing=180)
    )[0]
    lat_max = (
        geopy.distance.geodesic(kilometers=lat_km / 2).destination(origin, bearing=0)
    )[0]
    lon_min = (
        geopy.distance.geodesic(kilometers=lat_km / 2).destination(origin, bearing=270)
    )[1]
    lon_max = (
        geopy.distance.geodesic(kilometers=lat_km / 2).destination(origin, bearing=90)
    )[1]

    return ee.Geometry.BBox(lon_min, lat_min, lon_max, lat_max)

lon, lat = (float(Cords[0]), float(Cords[1]))
Map = BBoxFromPoint(10, lat, lon)

collection = (
    ee.ImageCollection("COPERNICUS/S2_SR_HARMONIZED")
    .filterBounds(Map)
    .filterDate("2020-01-01", "2021-01-01")
    .filter(ee.Filter.lte("CLOUDY_PIXEL_PERCENTAGE", 5))
)

image = ee.Image(collection.first())

try:
    url = image.getThumbURL(
        {
            "format": "png",
            "bands": ["B4", "B3", "B2"],
            "dimensions": [2800, 2800],
            "region": Map,
            "min": 0,
            "max": 4000,
        }
    )

    print(f"Download URL: {url}")
except Exception as e:
    print(f"Error generating URL: {e}")
    sys.exit(1)

# Download the image
try:
    response = requests.get(url, stream=True)
    response.raise_for_status()  # Check for HTTP errors

    # Save the image properly
    with open("NewMap.png", "wb") as f:
        for chunk in response.iter_content(chunk_size=8192):
            if chunk:
                f.write(chunk)
    print("Download complete!")


except requests.exceptions.RequestException as e:
    print(f"Error downloading image: {e}")
    sys.exit(1)
