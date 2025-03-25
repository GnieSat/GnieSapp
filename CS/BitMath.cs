using Godot;
using System;

public partial class BitMath : Node
{
	public int bits_to_sint8(String array) { return Convert.ToSByte(array, 2); }
	public int bits_to_uint8(String array) { return Convert.ToByte(array, 2); }
	public int bits_to_sint16(String array) { return Convert.ToInt16(array, 2); }
	public int bits_to_uint16(String array) { return Convert.ToUInt16(array, 2); }
	public int bits_to_sint32(String array) { return Convert.ToInt32(array, 2); }
	public uint bits_to_uint32(String array) { return Convert.ToUInt32(array, 2); }
	public float bits_to_float32(String array)
	{
		int integer = Convert.ToInt32(array, 2);
		byte[] result = BitConverter.GetBytes(integer);
		return BitConverter.ToSingle(result, 0);
	}
}
