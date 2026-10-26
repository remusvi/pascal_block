program Main;

{$mode objfpc}{$H+}
{$APPTYPE CONSOLE}

uses
  Raylib, Math;

const
  ScreenWidth = 1280;
  ScreenHeight = 720;
  CHUNK_SIZE = 16;

type
  TRaycastResult = record
    Hit: Boolean;
    ChunkIndex: Integer;
    BlockX, BlockY, BlockZ: Integer;
    Distance: Single;
  end;

  TBlockType = (btAir = 0, btStone = 1, btDirt = 2, btGrass = 3);

  TChunk = record
    Blocks: array[0..CHUNK_SIZE-1, 0..CHUNK_SIZE-1, 0..CHUNK_SIZE-1] of TBlockType;
    Position: TVec3;
  end;

  TWorld = array of TChunk;

var
  Camera: TCamera3D;
  MouseRay: TRay;
  BoundingBox: TBoundingBox;
  Collision: TRayCollision;
  MyChunk: TChunk;
  World: TWorld;
  i: Integer;
  TargetBlock: TRaycastResult;
  SelectionBox: TBoundingBox;
  TargetPos: TVec3;

function RaycastWorld(const Ray: TRay; const W: TWorld; MaxDistance: Single): TRaycastResult;
var
  c, cx, cy, cz: Integer;
  Box: TBoundingBox;
  Coll: TRayCollision;
  BlockPos: TVec3;
begin
  Result.Hit := False;
  Result.Distance := MaxDistance;

  for c := Low(W) to High(W) do
  begin
    for cx := 0 to CHUNK_SIZE - 1 do
      for cy := 0 to CHUNK_SIZE - 1 do
        for cz := 0 to CHUNK_SIZE - 1 do
        begin
          if W[c].Blocks[cx, cy, cz] <> btAir then
          begin
            BlockPos := Vec(
              W[c].Position.x + cx,
              W[c].Position.y + cy,
              W[c].Position.z + cz
            );

            Box.min := BlockPos;
            Box.max := Vec(BlockPos.x + 1.0, BlockPos.y + 1.0, BlockPos.z + 1.0);

            Coll := GetRayCollisionBox(Ray, Box);

            if Coll.Hit and (Coll.Distance < Result.Distance) then
            begin
              Result.Hit := True;
              Result.Distance := Coll.Distance;
              Result.ChunkIndex := c;
              Result.BlockX := cx;
              Result.BlockY := cy;
              Result.BlockZ := cz;
            end;
          end;
        end;
  end;
end;

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

function GetCameraForwardRay(Cam: TCamera3D): TRay;
var
  Dx, Dy, Dz, Len: Single;
begin
  Result.position := Cam.position;

  Dx := Cam.target.x - Cam.position.x;
  Dy := Cam.target.y - Cam.position.y;
  Dz := Cam.target.z - Cam.position.z;

  Len := Sqrt(Dx*Dx + Dy*Dy + Dz*Dz);
  if Len > 0 then
  begin
    Result.direction.x := Dx / Len;
    Result.direction.y := Dy / Len;
    Result.direction.z := Dz / Len;
  end
  else
  begin
    Result.direction.x := 0.0;
    Result.direction.y := 0.0;
    Result.direction.z := -1.0;
  end;
end;

begin
  // Disable FPU exceptions so C-based libraries like Raylib don't crash on division by zero
  SetExceptionMask([exInvalidOp, exDenormalized, exZeroDivide, exOverflow, exUnderflow, exPrecision]);

  Writeln('DEBUG: Starting Voxel Application...');

  InitWindow(ScreenWidth, ScreenHeight, 'Voxel Engine - First Person');
  SetTargetFPS(60);

  Camera.position := Vec(8.0, 10.0, 20.0);
  Camera.target   := Vec(8.0, 10.0, 19.0);
  Camera.up       := Vec(0.0, 1.0, 0.0);
  Camera.fovy     := 70.0;
  Camera.projection := CAMERA_PERSPECTIVE;

  BoundingBox.min := Vec(-1.0, 3.0, -1.0);
  BoundingBox.max := Vec(1.0, 5.0, 1.0);

  { Initialize chunk world data first }
  SetLength(World, 21);
  for i := 0 to 20 do
  begin
    InitChunk(MyChunk, i * 16, 0);
    World[i] := MyChunk;
  end;

  DisableCursor();

  while not WindowShouldClose() do
  begin
    UpdateCamera(Camera);

    MouseRay := GetCameraForwardRay(Camera);
    TargetBlock := RaycastWorld(MouseRay, World, 4.0);

    if TargetBlock.Hit and IsMouseButtonPressed(MOUSE_BUTTON_LEFT) then
    begin
       World[TargetBlock.ChunkIndex].Blocks[TargetBlock.BlockX, TargetBlock.BlockY, TargetBlock.BlockZ] := btAir;
       Writeln('Mined block at: ', TargetBlock.BlockX, ', ', TargetBlock.BlockY, ', ', TargetBlock.BlockZ);
    end;

    if TargetBlock.Hit and IsMouseButtonPressed(MOUSE_BUTTON_RIGHT) then
    begin
      Writeln('I WANNA PLACE A BLOCK BUT IDK HOW');
    end;

    BeginDrawing();
      ClearBackground(SKYBLUE);

      BeginMode3D(Camera);
        RenderWorld(World);
        DrawGrid(32, 1.0);

        if TargetBlock.Hit then
        begin
          TargetPos := Vec(
            World[TargetBlock.ChunkIndex].Position.x + TargetBlock.BlockX,
            World[TargetBlock.ChunkIndex].Position.y + TargetBlock.BlockY,
            World[TargetBlock.ChunkIndex].Position.z + TargetBlock.BlockZ
          );
          SelectionBox.min := TargetPos;
          SelectionBox.max := Vec(TargetPos.x + 1.0, TargetPos.y + 1.0, TargetPos.z + 1.0);
          DrawBoundingBox(SelectionBox, RED);
        end;

      EndMode3D();

      DrawCircle(ScreenWidth div 2, ScreenHeight div 2, 4, RED);

      DrawText('WASD: Move | Mouse: Look', 10, 10, 20, DARKGRAY);
      DrawText('ESC: Release Mouse', 10, 35, 18, DARKGRAY);
    EndDrawing();
  end;

  EnableCursor();
  CloseWindow();
  Writeln('DEBUG: Closed cleanly.');
end.
