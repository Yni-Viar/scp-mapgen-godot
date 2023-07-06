using Godot;
using System;

public partial class MapGenerator : Node
{
    RandomNumberGenerator rng = new RandomNumberGenerator();
    int width = 16; //use bigger value to fix map generation can bump into the end of map.
    int height = 16;
    int room1Amount, room2Amount, room2cAmount, room3Amount, room4Amount;
    enum RoomTypes : int { 
        empty = -1,
        room1 = 0,
        room2 = 1,
        room2c = 2,
        room3 = 3,
        room4 = 4
    }
    struct Room
    {
        //north, east, west and south check the connection between rooms.
        internal bool exist, north, east, south, west;
        internal RoomTypes type;
        internal float angle;
    }
    void Generate(int numberOfRooms)
    {
        Room[,] mapGen = new Room[width, height];
        //fill with zeros
        for (int x = 0; x < width; x++)
        {
            for (int y = 0; y < height; y++)
            {
                mapGen[x, y].exist = false;
                mapGen[x, y].north = false;
                mapGen[x, y].east = false;
                mapGen[x, y].south = false;
                mapGen[x, y].west = false;
                mapGen[x, y].type = RoomTypes.empty;
                mapGen[x, y].angle = 0;
            }
        }
        //center of map is ALWAYS exist.
        mapGen[8, 8].exist = true;
        int tempX = 8;
        int tempY = 8;

        /*
         * The map generator works in this way:
         * 1.Randomize direction
         * 2.Move in the right direction.
         * That's all :)
         */
        
        for (int i = 0; i <= numberOfRooms; i++)
        {
            int dir = rng.RandiRange(0, 4);

            if (dir < 1 && tempX < 15)
            {
                tempX += 1;
                mapGen[tempX, tempY].exist = true;
                if (mapGen[tempX - 1, tempY].exist)
                {
                    mapGen[tempX - 1, tempY].east = true;
                    mapGen[tempX, tempY].west = true;
                }
            }
            else if (dir < 2 && tempX > 0)
            {
                tempX -= 1;
                mapGen[tempX, tempY].exist = true;
                if (mapGen[tempX + 1, tempY].exist)
                {
                    mapGen[tempX + 1, tempY].west = true;
                    mapGen[tempX, tempY].east = true;
                }
            }
            else if (dir < 3 && tempY < 15)
            {
                tempY += 1;
                mapGen[tempX, tempY].exist = true;
                if (mapGen[tempX, tempY - 1].exist)
                {
                    mapGen[tempX, tempY - 1].north = true;
                    mapGen[tempX, tempY].south = true;
                }
            }
            else if (dir < 4 && tempY > 0)
            {
                tempY -= 1;
                mapGen[tempX, tempY].exist = true;
                if (mapGen[tempX, tempY + 1].exist)
                {
                    mapGen[tempX, tempY + 1].south = true;
                    mapGen[tempX, tempY].north = true;
                }
            }
        }
        /*
        for (int x = 0; x < width; x++)
        {
            for (int y = 0; y < height; y++)
            {
                GD.Print(mapGen[y, x]);
            }
            GD.Print();
        }*/
        
        room1Amount = room2Amount = room2cAmount = room3Amount = room4Amount = 0;
        for (int x = 0; x < width; x++)
        {
            for (int y = 0; y < height; y++)
            {
                bool north, south, east, west;
                north = south = east = west = false;
                if (mapGen[x, y].exist) //if it is a temporary room
                {
                    if (x > 0)
                    {
                        west = mapGen[x, y].west;
                    }
                    if (x < width - 1)
                    {
                        east = mapGen[x, y].east;
                    }
                    if (y < height - 1)
                    {
                        north = mapGen[x, y].north;
                    }
                    if (y > 0)
                    {
                        south = mapGen[x, y].south;
                    }
                    if (north && south)
                    {
                        if (east && west) //Room4
                        {
                            float[] avAngle = new float[] {0, 90, 180, 270};
                            mapGen[x, y].type = RoomTypes.room4;
                            mapGen[x, y].angle = avAngle[rng.RandiRange(0, 3)];
                            room4Amount++;
                        }
                        else if (east && !west) //Room3, pointing east
                        {
                            mapGen[x, y].type = RoomTypes.room3;
                            mapGen[x, y].angle = 90;
                            room3Amount++;
                        }
                        else if (!east && west) //Room3, pointing west
                        {
                            mapGen[x, y].type = RoomTypes.room3;
                            mapGen[x, y].angle = 270;
                            room3Amount++;
                        }
                        else //vertical Room2
                        {
                            float[] avAngle = new float[] {0, 180};
                            mapGen[x, y].type = RoomTypes.room2;
                            mapGen[x, y].angle = avAngle[rng.RandiRange(0, 1)];
                            room2Amount++;
                        }
                    }
                    else if (east && west)
                    {
                        if (north && !south) //Room3, pointing north
                        {
                            mapGen[x, y].type = RoomTypes.room3;
                            mapGen[x, y].angle = 0;
                            room3Amount++;
                        }
                        else if (!north && south) //Room3, pointing south
                        {
                            mapGen[x, y].type = RoomTypes.room3;
                            mapGen[x, y].angle = 180;
                            room3Amount++;
                        }
                        else //horizontal Room2
                        {
                            float[] avAngle = new float[] {90, 270};
                            mapGen[x, y].type = RoomTypes.room2;
                            mapGen[x, y].angle = avAngle[rng.RandiRange(0, 1)];
                            room2Amount++;
                        }
                    }
                    else if (north)
                    {
                        if (east) //Room2c, north-east
                        {
                            mapGen[x, y].type = RoomTypes.room2c;
                            mapGen[x, y].angle = 0;
                            room2cAmount++;
                        }
                        else if (west) //Room2c, north-west
                        {
                            mapGen[x, y].type = RoomTypes.room2c;
                            mapGen[x, y].angle = 270;
                            room2cAmount++;
                        }
                        else //Room1, north
                        {
                            mapGen[x, y].type = RoomTypes.room1;
                            mapGen[x, y].angle = 0;
                            room1Amount++;
                        }
                    }
                    else if (south)
                    {
                        if (east) //Room2c, south-east
                        {
                            mapGen[x, y].type = RoomTypes.room2c;
                            mapGen[x, y].angle = 90;
                            room2cAmount++;
                        }
                        else if (west) //Room2c, south-west
                        {
                            mapGen[x, y].type = RoomTypes.room2c;
                            mapGen[x, y].angle = 180;
                            room2cAmount++;
                        }
                        else //Room1, south
                        {
                            mapGen[x, y].type = RoomTypes.room1;
                            mapGen[x, y].angle = 180;
                            room1Amount++;
                        }
                    }
                    else if (east) //Room1, east
                    {
                        mapGen[x, y].type = RoomTypes.room1;
                        mapGen[x, y].angle = 90;
                        room1Amount++;
                    }
                    else if (west) //Room1, west
                    {
                        mapGen[x, y].type = RoomTypes.room1;
                        mapGen[x, y].angle = 270;
                        room1Amount++;
                    }
                }
            }
        }

        int currRoom1 = 0;
        int currRoom2 = 0;
        int currRoom2c = 0;
        
        for (int x = 0; x < width; x++)
        {
            for (int y = 0; y < height; y++)
            {
                StaticBody3D rm;
                switch (mapGen[x, y].type)
                {
                    case RoomTypes.room1:
                        
                        switch (currRoom1)
                        {
                            case 0:
                                rm = (StaticBody3D)ResourceLoader.Load<PackedScene>("res://Assets/Rooms/room1/rz_exit_1_gatea.tscn").Instantiate();
                                rm.Position = new Vector3(x * 20.48f, 0, y*20.48f);
                                rm.RotationDegrees = new Vector3(0, mapGen[x, y].angle, 0);
                                AddChild(rm);
                                currRoom1++;
                                break;
                            case 1:
                                rm = (StaticBody3D)ResourceLoader.Load<PackedScene>("res://Assets/Rooms/room1/rz_exit_1_gateb.tscn").Instantiate();
                                rm.Position = new Vector3(x * 20.48f, 0, y*20.48f);
                                rm.RotationDegrees = new Vector3(0, mapGen[x, y].angle, 0);
                                AddChild(rm);
                                currRoom1++;
                                break;
                            default:
                                rm = (StaticBody3D)ResourceLoader.Load<PackedScene>("res://Assets/Rooms/room1/rz_room_1_endroom.tscn").Instantiate();
                                rm.Position = new Vector3(x * 20.48f, 0, y*20.48f);
                                rm.RotationDegrees = new Vector3(0, mapGen[x, y].angle, 0);
                                AddChild(rm);
                                break;
                        }
                        break;
                    case RoomTypes.room2:
                        
                        switch (currRoom2)
                        {
                            case 0:
                                rm = (StaticBody3D)ResourceLoader.Load<PackedScene>("res://Assets/Rooms/room2/rz_room_2_offices.tscn").Instantiate();
                                rm.Position = new Vector3(x * 20.48f, 0, y*20.48f);
                                rm.RotationDegrees = new Vector3(0, mapGen[x, y].angle, 0);
                                AddChild(rm);
                                currRoom2++;
                                break;
                            case 1:
                                rm = (StaticBody3D)ResourceLoader.Load<PackedScene>("res://Assets/Rooms/room2/rz_room_2_offices_2.tscn").Instantiate();
                                rm.Position = new Vector3(x * 20.48f, 0, y*20.48f);
                                rm.RotationDegrees = new Vector3(0, mapGen[x, y].angle, 0);
                                AddChild(rm);
                                currRoom2++;
                                break;
                            case 2:
                                rm = (StaticBody3D)ResourceLoader.Load<PackedScene>("res://Assets/Rooms/room2/rz_room_2_poffices.tscn").Instantiate();
                                rm.Position = new Vector3(x * 20.48f, 0, y*20.48f);
                                rm.RotationDegrees = new Vector3(0, mapGen[x, y].angle, 0);
                                AddChild(rm);
                                currRoom2++;
                                break;
                            case 3:
                                rm = (StaticBody3D)ResourceLoader.Load<PackedScene>("res://Assets/Rooms/room2/rz_room_2_toilets.tscn").Instantiate();
                                rm.Position = new Vector3(x * 20.48f, 0, y*20.48f);
                                rm.RotationDegrees = new Vector3(0, mapGen[x, y].angle, 0);
                                AddChild(rm);
                                currRoom2++;
                                break;
                            case 4:
                                rm = (StaticBody3D)ResourceLoader.Load<PackedScene>("res://Assets/Rooms/room2/rz_room_2_medibay.tscn").Instantiate();
                                rm.Position = new Vector3(x * 20.48f, 0, y*20.48f);
                                rm.RotationDegrees = new Vector3(0, mapGen[x, y].angle, 0);
                                AddChild(rm);
                                currRoom2++;
                                break;
                            default:
                                rm = (StaticBody3D)ResourceLoader.Load<PackedScene>("res://Assets/Rooms/room2/rz_room_2.tscn").Instantiate();
                                rm.Position = new Vector3(x * 20.48f, 0, y*20.48f);
                                rm.RotationDegrees = new Vector3(0, mapGen[x, y].angle, 0);
                                AddChild(rm);
                                break;
                        }
                        break;
                    case RoomTypes.room2c:
                        switch (currRoom2c)
                        {
                            case 0:
                                rm = (StaticBody3D)ResourceLoader.Load<PackedScene>("res://Assets/Rooms/room2c/rz_room_2c_ec.tscn").Instantiate();
                                rm.Position = new Vector3(x * 20.48f, 0, y*20.48f);
                                rm.RotationDegrees = new Vector3(0, mapGen[x, y].angle, 0);
                                AddChild(rm);
                                currRoom2c++;
                                break;
                            default:
                                rm = (StaticBody3D)ResourceLoader.Load<PackedScene>("res://Assets/Rooms/room2c/rz_room_2c.tscn").Instantiate();
                                rm.Position = new Vector3(x * 20.48f, 0, y*20.48f);
                                rm.RotationDegrees = new Vector3(0, mapGen[x, y].angle, 0);
                                AddChild(rm);
                                break;
                        }
                        break;
                    case RoomTypes.room3:
                        rm = (StaticBody3D)ResourceLoader.Load<PackedScene>("res://Assets/Rooms/room3/rz_room_3.tscn").Instantiate();
                        rm.Position = new Vector3(x * 20.48f, 0, y*20.48f);
                        rm.RotationDegrees = new Vector3(0, mapGen[x, y].angle, 0);
                        AddChild(rm);
                        break;
                    case RoomTypes.room4:
                        rm = (StaticBody3D)ResourceLoader.Load<PackedScene>("res://Assets/Rooms/room4/rz_room_4.tscn").Instantiate();
                        rm.Position = new Vector3(x * 20.48f, 0, y*20.48f);
                        rm.RotationDegrees = new Vector3(0, mapGen[x, y].angle, 0);
                        AddChild(rm);
                        break;
                }
            }
        }

        for (int x = 0; x < width; x++)
        {
            for (int y = 0; y < height; y++)
            {
                Node3D d; //doors
                if (mapGen[x, y].east && mapGen[x + 1, y].west)
                {
                    d = (Node3D)ResourceLoader.Load<PackedScene>("res://Assets/Doors/door.tscn").Instantiate();
                    d.Position = new Vector3(x * 20.48f + 10.24f, 0, y*20.48f);
                    d.RotationDegrees = new Vector3(0, 90, 0);
                    AddChild(d);
                }
                if (mapGen[x, y].north && mapGen[x, y + 1].south)
                {
                    d = (Node3D)ResourceLoader.Load<PackedScene>("res://Assets/Doors/door.tscn").Instantiate();
                    d.Position = new Vector3(x * 20.48f, 0, y*20.48f + 10.24f);
                    d.RotationDegrees = new Vector3(0, 0, 0);
                    AddChild(d);
                }
            }
        }
    }
	// Called when the node enters the scene tree for the first time.
	public override void _Ready()
	{
        do
        {
            Generate(24);
        }
        while(room1Amount < 2);
	}

	// Called every frame. 'delta' is the elapsed time since the previous frame.
	public override void _Process(double delta)
	{
	}
}
