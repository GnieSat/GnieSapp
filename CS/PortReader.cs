using Godot;
using Godot.Collections;
using Godot.NativeInterop;
using System;
using System.IO.Ports;
using System.Linq;

public partial class PortReader : Node2D
{
	SerialPort[] Port;
	Timer Counter;
	RichTextLabel Sign;
	TextureButton CopyButton;

	string[] Names = { "A", "B", "C"};

	[Export]
	string[] PortName = { "COM3", "COM3", "COM3" };

	[Export]
	int MessagesLenght = 31;

	bool Found = false;
	int FoundMessage = 0;
	byte[][] BitMessage;

	

	[Signal]
	public delegate void OnUpdateEventHandler(byte[] message, String sender);

	[Signal]
	public delegate void OnErrorEventHandler(bool really);

	[Signal]
	public delegate void OnLackDataEventHandler();

	// Called when the node enters the scene tree for the first time.
	public override void _Ready()
	{
		BitMessage = new byte[3][];
		Port = new SerialPort[3];
		Sign = GetNode<RichTextLabel>("RichTextLabel");
		Counter = GetNode<Timer>("Timer");
		CopyButton = GetNode<TextureButton>("TextureButton");

		Counter.Connect(Timer.SignalName.Timeout, Callable.From(on_Timeout));
		//CopyButton.Connect(TextureButton.SignalName.ButtonDown, Callable.From(on_Click));
		
	}

	// Called every frame. 'delta' is the elapsed time since the previous frame.
	public override void _Process(double delta)
	{

	}
	
	public void port_change(int index, string port)
	{
		PortName[index] = port;
	}

	public void start() 
	{
		bool any_open = false;
		foreach (int i in Enumerable.Range(0, 3)) 
		{
			GD.Print(PortName[i]);

			Port[i] = new SerialPort();
			Port[i].PortName = PortName[i];
			Port[i].BaudRate = 9600;
			Port[i].Parity = Parity.None;
			Port[i].StopBits = StopBits.One;
			Port[i].DtrEnable = true;

			try { Port[i].Open(); }
			catch { GD.Print("Port" + PortName[i] + " is not connected to antenna"); }

			if (Port[i].IsOpen) 
			{ 
				Counter.Start();
				any_open = true;
				GD.Print("Port " + PortName[i] + " is open");
			}

		}
		if (any_open) { Counter.Start(); GD.Print("Comunication opened"); }
		else { GD.Print("None of ports is open"); }
	}

	public void stop() 
	{
		foreach (int i in Enumerable.Range(0, 3)) { Port[i].Close(); }
		Counter.Stop();
	}


	public void on_Timeout()
	{
		foreach (int i in Enumerable.Range(0, 3))
		{
			if (Port[i].IsOpen)
			{
				BitMessage[i] = new byte[Port[i].BytesToRead];
				Port[i].Read(BitMessage[i], 0, MessagesLenght);

				if (BitMessage != null)
				{
					Found = true;
					FoundMessage = i;
				}
			}
		}
		GD.Print(FoundMessage);
		if (Found)
		{
			EmitSignal(SignalName.OnError, false);
			EmitSignal(SignalName.OnUpdate, BitMessage[FoundMessage], Names[FoundMessage]);
		}
		else 
		{
			EmitSignal(SignalName.OnError, true);
			EmitSignal(SignalName.OnLackData);
		}
		Found = false;
		FoundMessage = 0;

	}

	/*public void on_Click()
	{
		DisplayServer.ClipboardGet();
		DisplayServer.ClipboardSet(Message);
	}*/

}
