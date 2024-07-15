using Godot;
using System;

public partial class Menu : Control
{
	// Called when the node enters the scene tree for the first time.
	public override void _Ready()
	{
	}

	// Called every frame. 'delta' is the elapsed time since the previous frame.
	public override void _Process(double delta)
	{
	}

    private void OnGenerateButtonPressed()
    {
        this.QueueFree();
        GetTree().ChangeSceneToFile("res://Scenes/Site19.tscn");
    }


    private void OnCreditsButtonPressed()
    {
        GetNode<Panel>("Credits").Visible = !(GetNode<Panel>("Credits").Visible);
    }
}



