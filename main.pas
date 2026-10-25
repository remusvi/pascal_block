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

var
  Camera: TCamera3D;
  MyChunk: TChunk;
  x, y, z: Integer;
  BlockPos: TVec3;
  BlockColor: TColor;

  { Raycast / Target tracking }
  Ray: TRay;
  TargetX, TargetY, TargetZ: Integer;
  HasTarget: Boolean;
  ScreenCenter: TVec2;

procedure InitChunk(var Chunk: TChunk; WorldX, WorldZ: Single);
var
  cx, cy, cz: Integer;
begin
  Chunk.Position := Vec(WorldX, 0.0, WorldZ);
  for cx := 0 to CHUNK_SIZE - 1 do
    for cz := 0 to CHUNK_SIZE - 1 do
      for cy := 0 to CHUNK_SIZE - 1 do
      begin
        if cy < 4 then Chunk.Blocks[cx, cy, cz] := btStone
        else if cy < 7 then Chunk.Blocks[cx, cy, cz] := btDirt
        else if cy = 7 then Chunk.Blocks[cx, cy, cz] := btGrass
        else Chunk.Blocks[cx, cy, cz] := btAir;
      end;
end;

{ Helper: Convert World Coordinates to Chunk Grid Indices }
function WorldToChunkIdx(WorldPos: TVec3; ChunkPos: TVec3; var OutX, OutY, OutZ: Integer): Boolean;
begin
  OutX := Floor(WorldPos.x - ChunkPos.x);
  OutY := Floor(WorldPos.y - ChunkPos.y);
  OutZ := Floor(WorldPos.z - ChunkPos.z);

  Result := (OutX >= 0) and (OutX < CHUNK_SIZE) and
            (OutY >= 0) and (OutY < CHUNK_SIZE) and
            (OutZ >= 0) and (OutZ < CHUNK_SIZE);
end;

begin
  InitWindow(ScreenWidth, ScreenHeight, 'Voxel Engine - First Person');
  SetTargetFPS(60);

  { Setup First-Person Camera }
  Camera.position := Vec(8.0, 10.0, 20.0);
  Camera.target   := Vec(8.0, 10.0, 19.0);
  Camera.up       := Vec(0.0, 1.0, 0.0);
  Camera.fovy     := 70.0;
  Camera.projection := CAMERA_PERSPECTIVE;

  { Lock cursor to window for first-person freelook }
  DisableCursor();

  InitChunk(MyChunk, 0.0, 0.0);

  { Setup center vector for crosshair raycasting }
  ScreenCenter.x := ScreenWidth / 2.0;
  ScreenCenter.y := ScreenHeight / 2.0;

  while not WindowShouldClose() do
  begin
    { Update First Person Camera position and rotation }
    UpdateCamera(Camera);

    { Raycast from crosshair to detect targeted block }
    Ray := GetMouseRay(ScreenCenter, Camera);
    HasTarget := False;

    { Simple voxel raycast test (marching along view vector) }
    for z := 1 to 50 do
    begin
      BlockPos := Vec(
        Ray.position.x + Ray.direction.x * (z * 0.1),
        Ray.position.y + Ray.direction.y * (z * 0.1),
        Ray.position.z + Ray.direction.z * (z * 0.1)
      );

      if WorldToChunkIdx(BlockPos, MyChunk.Position, TargetX, TargetY, TargetZ) then
      begin
        if MyChunk.Blocks[TargetX, TargetY, TargetZ] <> btAir then
        begin
          HasTarget := True;
          Break;
        end;
      end;
    end;

    { Mouse Interaction: Left Click = Mine }
    if HasTarget then
    begin
      if IsMouseButtonPressed(MOUSE_BUTTON_LEFT) then
      begin
        MyChunk.Blocks[TargetX, TargetY, TargetZ] := btAir;
      end;
    end;

    BeginDrawing();
      ClearBackground(SKYBLUE);

      BeginMode3D(Camera);
        { Render Chunk Blocks }
        for x := 0 to CHUNK_SIZE - 1 do
          for y := 0 to CHUNK_SIZE - 1 do
            for z := 0 to CHUNK_SIZE - 1 do
            begin
              if MyChunk.Blocks[x, y, z] <> btAir then
              begin
                BlockPos := Vec(MyChunk.Position.x + x + 0.5, MyChunk.Position.y + y + 0.5, MyChunk.Position.z + z + 0.5);

                case MyChunk.Blocks[x, y, z] of
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

        { Highlight targeted block if looking at one }
        if HasTarget then
        begin
          BlockPos := Vec(
            MyChunk.Position.x + TargetX + 0.5,
            MyChunk.Position.y + TargetY + 0.5,
            MyChunk.Position.z + TargetZ + 0.5
          );
          DrawCubeWires(BlockPos, 1.02, 1.02, 1.02, RED);
        end;

        DrawGrid(32, 1.0);
      EndMode3D();

      { Draw HUD / Crosshair }
      DrawCircle(ScreenWidth div 2, ScreenHeight div 2, 3.0, WHITE);
      DrawText('WASD: Move | Mouse: Look | Left Click: Break Block', 10, 10, 20, DARKGRAY);
      DrawText('ESC: Release Mouse', 10, 35, 18, DARKGRAY);

    EndDrawing();
  end;

  EnableCursor();
  CloseWindow();
end.
