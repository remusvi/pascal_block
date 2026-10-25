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
    Blocks: array[0..CHUNK_SIZE-1, 0..CHUNK_SIZE * 16, 0..CHUNK_SIZE-1] of TBlockType;
    Position: TVec3;
  end;

var
  Camera: TCamera3D;
  MyChunk: TChunk;
  ScreenCenter: TVec2;
  cx, cy, cz: Integer;
  BlockPos: TVec3;
  BlockColor: TColor;

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

begin
  Writeln('DEBUG: Starting application...');

  Writeln('DEBUG: Attempting to call InitWindow...');
  InitWindow(ScreenWidth, ScreenHeight, 'Voxel Engine - First Person');
  Writeln('DEBUG: InitWindow succeeded!');

  SetTargetFPS(200);

  Camera.position := Vec(8.0, 10.0, 20.0);
  Camera.target   := Vec(8.0, 10.0, 19.0);
  Camera.up       := Vec(0.0, 1.0, 0.0);
  Camera.fovy     := 70.0;
  Camera.projection := CAMERA_PERSPECTIVE;

  DisableCursor();

  { Initialize chunk world data }
  InitChunk(MyChunk, 0.0, 0.0);

  while not WindowShouldClose() do
  begin
    UpdateCamera(Camera);

    BeginDrawing();
      ClearBackground(SKYBLUE);

      BeginMode3D(Camera);
        { Render Chunk Blocks }
        for cx := 0 to CHUNK_SIZE - 1 do
          for cy := 0 to CHUNK_SIZE - 1 do
            for cz := 0 to CHUNK_SIZE - 1 do
            begin
              if MyChunk.Blocks[cx, cy, cz] <> btAir then
              begin
                BlockPos := Vec(
                  MyChunk.Position.x + cx + 0.5,
                  MyChunk.Position.y + cy + 0.5,
                  MyChunk.Position.z + cz + 0.5
                );

                case MyChunk.Blocks[cx, cy, cz] of
                  btStone: BlockColor := GRAY;
                  btDirt:  BlockColor := DARKBROWN;
                  btGrass: BlockColor := GREEN;
                else
                  BlockColor := WHITE;
                end;

                DrawCube(BlockPos, 1.0, 1.0, 1.0, BlockColor);
                DrawCubeWires(BlockPos, 1.0, 1.0, 1.0, DARKGRAY);
              end;
            end;

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
