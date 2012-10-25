'/////////////////////////////////////
'|| modModel.bi - Voxel Model header
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
#Include "GL/glu.bi"

#Define DEG (Atn(1)/45.0)

Type Vox_Model
    Volume As Vox_Volume = VOXEL_SCREEN
    As Vec3I VA = Vec3I(-1, -1, -1), VB = Vec3I(-1, -1, -1)
    Matrix(15) As GLdouble = {1, 0, 0, 0, _
                              0, 1, 0, 0, _
                              0, 0, 1, 0, _
                              0, 0, 0, 1}
    As Integer Scaled = 0
    
    Declare Sub Render
    Declare Sub SetModelMatrix
    Declare Function HitTest(ByRef V1 As Vec3I, ByRef V2 As Vec3I, X As Integer, Y As Integer, Dist As Double = -1) As Integer
    
    Declare Sub Identity
    Declare Sub Translate(X As Double, Y As Double, Z As Double)
    Declare Sub Translate(V As Vec3I)
    Declare Sub Scale(S As Double)
    Declare Sub Scale(X As Double, Y As Double, Z As Double)
    Declare Sub Scale(V As Vec3I)
    Declare Sub Rotate(Angle As Double, NX As Double, NY As Double, NZ As Double)
    Declare Sub Rotate(Angle As Double, N As Vec3I)
End Type

' 3D vector of 64 bit integers representing 48:16 fixed point numbers
Type Vec3L16
    As LongInt X, Y, Z
    
    Declare Constructor ()
    Declare Constructor (V As Vec3L16)
    Declare Constructor (X As LongInt, Y As LongInt, Z As LongInt)
    Declare Constructor (V As Vec3I)
End Type

Declare Operator + (ByRef Lhs As Vec3L16, ByRef Rhs As Vec3L16) As Vec3L16
Declare Operator - (ByRef Lhs As Vec3L16, ByRef Rhs As Vec3L16) As Vec3L16

'Scalar Products
Declare Operator * (ByRef Lhs As Vec3L16, ByRef Rhs As LongInt) As Vec3L16
Declare Operator * (ByRef Lhs As LongInt, ByRef Rhs As Vec3L16) As Vec3L16
Declare Operator / (ByRef Lhs As Vec3L16, ByRef Rhs As LongInt) As Vec3L16
Declare Operator \ (ByRef Lhs As Vec3L16, ByRef Rhs As LongInt) As Vec3L16
'Dot Product
Declare Operator * (ByRef Lhs As Vec3L16, ByRef Rhs As Vec3L16) As LongInt
'Cross Product
Declare Function Cross (ByRef Lhs As Vec3L16, ByRef Rhs As Vec3L16) As Vec3L16

' Assuming Axis is a unit vector, Inputs are 48:16 fixed point Vectors and numbers
Declare Sub AxisRotate3D(ByRef V As Vec3L16, ByRef MidP As Vec3L16, ByRef Axis As Vec3L16, CosA As LongInt, SinA As LongInt)