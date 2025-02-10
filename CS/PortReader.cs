using Godot;
using Godot.Collections;
using System;
using System.IO.Ports;

public partial class PortReader : Node2D
{
	SerialPort Port;
	Timer Counter;
	RichTextLabel Sign;
	TextureButton CopyButton;


	[Export]
	string PortName = "COM3";


	string Message;

	[Signal]
	public delegate void OnUpdateEventHandler(string message);

	// Called when the node enters the scene tree for the first time.
	public override void _Ready()
	{
		Sign = GetNode<RichTextLabel>("RichTextLabel");
		Counter = GetNode<Timer>("Timer");
		CopyButton = GetNode<TextureButton>("TextureButton");

		Counter.Connect(Timer.SignalName.Timeout, Callable.From(on_Timeout));
		CopyButton.Connect(TextureButton.SignalName.ButtonDown, Callable.From(on_Click));

		Port = new SerialPort();
		Port.PortName = PortName;
		Port.BaudRate = 9600;
		Port.Parity = Parity.None;
		Port.StopBits = StopBits.One;
		Port.DtrEnable = true;
		
	}

	// Called every frame. 'delta' is the elapsed time since the previous frame.
	public override void _Process(double delta)
	{

	}

	public void start() 
	{
		Port.Open();
		if (Port.IsOpen) { Counter.Start(); }
	}

	public void stop() 
	{ 
		Port.Close();
		Counter.Stop();
	}


	public void on_Timeout()
	{
		if (!Port.IsOpen) { return; }
		Message = Port.ReadExisting();

		Sign.Text = "Arduino data: " + Message;

		EmitSignal(SignalName.OnUpdate, Message);
	}

	public void on_Click()
	{
		DisplayServer.ClipboardGet();
		DisplayServer.ClipboardSet(Message);
	}

	public int bits_to_sint8(String array) { return Convert.ToSByte(array, 2); }
	public int bits_to_uint8(String array) { return Convert.ToByte(array, 2); }
	public int bits_to_sint16(String array) { return Convert.ToInt16(array, 2); }
	public int bits_to_uint16(String array) { return Convert.ToUInt16(array, 2); }
	public int bits_to_sint32(String array) { return Convert.ToInt32(array, 2); }
	public uint bits_to_uint32(String array) { return Convert.ToUInt32(array, 2); }

}
