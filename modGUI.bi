'/////////////////////////////////////
'|| modGUI.bi - GUI Objects header
'||
'|| CubeDraw - Volume Painting Program
'||   Copyright (C) 2012 Alex Thomson
'||
'|| This file is part of CubeDraw.
'||
'|| CubeDraw is free software: you can redistribute it and/or modify
'|| it under the terms of the GNU General Public License as published by
'|| the Free Software Foundation, either version 3 of the License, or
'|| (at your option) any later version.
'||
'|| CubeDraw is distributed in the hope that it will be useful,
'|| but WITHOUT ANY WARRANTY; without even the implied warranty of
'|| MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
'|| GNU General Public License for more details.
'||
'|| You should have received a copy of the GNU General Public License
'|| along with VoxelGFX.  If not, see <http://www.gnu.org/licenses/>.
'\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
#Include "VoxelGFX.bi"
#Include Once "modModel.bi"

Type ColorSelectorRGB
    SelColor As UInteger
    As Vec3I SelV = Vec3I(255, 255, 255), V1, V2
    VC As Vox_Context
    As Integer HitArea = -1, NoHov = -1
    As Vox_Volume RedBar, GreenBar, BlueBar, GreyBox
    
    Declare Constructor()
    Declare Sub Render(ScreenW As Integer, ScreenH As Integer)
    Declare Function HitTest(X As Integer, Y As Integer, Dist As Double = -1) As Integer
    Declare Sub Hover(X As Integer, Y As Integer)
    Declare Sub Click(X As Integer, Y As Integer)
    Declare Sub CursorMove(X As Integer, Y As Integer)
    
    Declare Sub SetColor(C As UInteger)
End Type

Type ColorSelectorHSV
    SelColor As UInteger
    'ToDo: ...
End Type

Type HitPlanes
    As Vec3I Posn = Vec3I(-1,-1,-1), Size, Cursor
    As Vox_Volume VolArrow, VolCorner, VolGrid(2)
    As Vox_Model Arrows(2), Corners(2)
    As Integer HitArea = -1, NoHov = -1, HitAxis
    As Double HitX, HitY, HitZ
    
    Declare Constructor()
    Declare Sub Render(ScreenW As Integer, ScreenH As Integer)
    Declare Function HitTest(X As Integer, Y As Integer, Dist As Double = -1) As Integer
    Declare Sub Hover(X As Integer, Y As Integer)
    Declare Sub Click(X As Integer, Y As Integer)
    Declare Sub CursorMove(X As Integer, Y As Integer)
    
    Declare Sub SetSize()
    Declare Function HitTestPlanes(ByRef V1 As Vec3I, ByRef V2 As Vec3I, X As Integer, Y As Integer, ByRef Dist As Double = -1) As UInteger
    Declare Function HitTestPlaneEdges(ByRef V1 As Vec3I, X As Integer, Y As Integer, ByRef Dist As Double = -1) As UInteger
End Type

Type ButtonBar
    VC As Vox_Context
    As Vox_Volume VolButtons
    As Integer HitButton = -1, NoHov = -1, Down = -1, NumButtons
    As Vec3I ButtonSize
    
    Declare Constructor()
    Declare Sub Render()
    Declare Function HitTest(X As Integer, Y As Integer, Dist As Double = -1) As Integer
    Declare Sub Hover(X As Integer, Y As Integer)
    Declare Sub Click(X As Integer, Y As Integer)
    Declare Sub CursorMove(X As Integer, Y As Integer)
End Type

Declare Sub DrawCubeEdges(V1 As Vec3I, V2 As Vec3I)
Declare Sub DrawGrid(V1 As Vec3I, V2 As Vec3I, S As Integer)