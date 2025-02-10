using Godot;
using System;

public partial class MapTileCalculator : Node
{

	public int long2tilex(double lon, int z)
	{
		return (int)(Math.Floor((lon + 180.0) / 360.0 * (1 << z)));
	}

	public int lat2tiley(double lat, int z)
	{
		var latRad = lat / 180 * Math.PI;
		return (int)Math.Floor((1 - Math.Log(Math.Tan(latRad) + 1 / Math.Cos(latRad)) / Math.PI) / 2 * (1 << z));
	}

	public double tilex2long(int x, int z)
	{
		return x / (double)(1 << z) * 360.0 - 180;
	}

	public double tiley2lat(int y, int z)
	{
		double n = Math.PI - 2.0 * Math.PI * y / (double)(1 << z);
		return 180.0 / Math.PI * Math.Atan(0.5 * (Math.Exp(n) - Math.Exp(-n)));
	}
}
