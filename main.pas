program Main;

{$mode objfpc}{$H+}

uses
  Raylib, Math;

const
  ScreenWidth = 1280;
  ScreenHeight = 720;
  CHUNK_SIZE = 16;

type
  TBlockType = (btAir = 0, btStone = 1, btDirt = 2, btGrass = 3);

  TChunk = record
    Blocks: array[0..CHUNK_SIZE-1, 0..CHUNK_SIZE-1, 0..CHUNK_SIZE-1] of TBlockType;
    Position: TVec3;
  end;

  TWorld = array of TChunk;

var
  Camera: TCamera3D;
  MyChunk: TChunk;
  World: TWorld;
  i: Integer;

procedure InitChunk(var Chunk: TChunk; WorldX, WorldZ: Single);
var
  ix, iy, iz: Integer;
begin
  Chunk.Position := Vec(WorldX, 0.0, WorldZ);
  for ix := 0 to CHUNK_SIZE - 1 do
    for iz := 0 to CHUNK_SIZE - 1 do
      for iy := 0 to CHUNK_SIZE - 1 do
      begin
        if iy < 4 then
          Chunk.Blocks[ix, iy, iz] := btStone
        else if iy < 7 then
          Chunk.Blocks[ix, iy, iz] := btDirt
        else if iy = 7 then
          Chunk.Blocks[ix, iy, iz] := btGrass
        else
          Chunk.Blocks[ix, iy, iz] := btAir;
      end;
end;

procedure RenderWorld(const W: TWorld);
var
  c, cx, cy, cz: Integer;
  IsExposed: Boolean;
  BlockPos: TVec3;
  BlockColor: TColor;
begin
  for c := Low(W) to High(W) do
  begin
    for cx := 0 to CHUNK_SIZE - 1 do
      for cy := 0 to CHUNK_SIZE - 1 do
        for cz := 0 to CHUNK_SIZE - 1 do
        begin
          if W[c].Blocks[cx, cy, cz] <> btAir then
          begin
            IsExposed :=
              (cx = 0) or (W[c].Blocks[cx - 1, cy, cz] = btAir) or
              (cx = CHUNK_SIZE - 1) or (W[c].Blocks[cx + 1, cy, cz] = btAir) or
              (cy = 0) or (W[c].Blocks[cx, cy - 1, cz] = btAir) or
              (cy = CHUNK_SIZE - 1) or (W[c].Blocks[cx, cy + 1, cz] = btAir) or
              (cz = 0) or (W[c].Blocks[cx, cy, cz - 1] = btAir) or
              (cz = CHUNK_SIZE - 1) or (W[c].Blocks[cx, cy, cz + 1] = btAir);

            if IsExposed then
            begin
              BlockPos := Vec(
                W[c].Position.x + cx,
                W[c].Position.y + cy,
                W[c].Position.z + cz
              );

              case W[c].Blocks[cx, cy, cz] of
                btStone: BlockColor := GRAY;
                btDirt:  BlockColor := DARKBROWN;
                btGrass: BlockColor := GREEN;
              else
                BlockColor := WHITE;
              end;

              DrawCube(BlockPos, 1.0, 1.0, 1.0, BlockColor);
              DrawCubeWires(BlockPos, 1.002, 1.002, 1.002, DARKGRAY);
            end;
          end;
        end;
  end;
end;

begin
  Writeln('DEBUG: Starting Voxel Application...');

  InitWindow(ScreenWidth, ScreenHeight, 'Voxel Engine - First Person');
  SetTargetFPS(60);

  Camera.position := Vec(8.0, 10.0, 20.0);
  Camera.target   := Vec(8.0, 10.0, 19.0);
  Camera.up       := Vec(0.0, 1.0, 0.0);
  Camera.fovy     := 70.0;
  Camera.projection := CAMERA_PERSPECTIVE;

  DisableCursor();

  { Initialize chunk world data }
  SetLength(World, 40);
  for i := 0 to 2 do
  begin
    InitChunk(MyChunk, i * 15, i * 15);
    World[i] := MyChunk;
  end;

  while not WindowShouldClose() do
  begin
    UpdateCamera(Camera);

    BeginDrawing();
      ClearBackground(SKYBLUE);

      BeginMode3D(Camera);
        RenderWorld(World);
        DrawGrid(32, 1.0);
      EndMode3D();

      DrawText('WASD: Move | Mouse: Look', 10, 10, 20, DARKGRAY);
      DrawText('ESC: Release Mouse', 10, 35, 18, DARKGRAY);
    EndDrawing();
  end;

  EnableCursor();
  CloseWindow();
  Writeln('DEBUG: Closed cleanly.');
end.
