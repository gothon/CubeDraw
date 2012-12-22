'/////////////////////////////////////
'|| modModel.bas - Voxel Model module
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
#Include "modModel.bi"

Sub Vox_Model.Render
    Dim NomalEnabled As GLboolean
    If Scaled Then
        NomalEnabled = glIsEnabled(GL_NORMALIZE)
        If NomalEnabled Then glEnable GL_NORMALIZE
    End If
    glPushMatrix
    glMultMatrixd @Matrix(0)
    If VA.X = -1 Then
        VoxRenderVolume Volume
       Else
        VoxRenderSubVolume Volume, VA, VB
    End If
    glPopMatrix
    If Scaled And NomalEnabled = GL_FALSE Then glDisable GL_NORMALIZE
End Sub

Sub Vox_Model.SetModelMatrix
    VoxGlRenderState 0, 0, VOXEL_MODELVIEW
    glMultMatrixd @Matrix(0)
End Sub

Function Vox_Model.HitTest(ByRef V1 As Vec3I, ByRef V2 As Vec3I, X As Integer, Y As Integer, Dist As Double = -1) As Integer
    glPushMatrix
    glMultMatrixd @Matrix(0)
    VoxSetVolume Volume
    If VA.X = -1 Then
        Function = VoxCursorTest(V1, V2, X, Y, Dist) 
       Else
        Function = VoxSubCursorTest(V1, V2, VA, VB, X, Y, Dist)
    End If
    glPopMatrix
End Function

Sub Vox_Model.Identity
    Erase Matrix
    Matrix(0) = 1: Matrix(5) = 1: Matrix(10) = 1: Matrix(15) = 1
    Scaled = 0
End Sub

Sub Vox_Model.Translate(X As Double, Y As Double, Z As Double)
    'Dim M(15) As GLdouble = {1, 0, 0, 0, _
    '                         0, 1, 0, 0, _
    '                         0, 0, 1, 0, _
    '                         X, Y, Z, 1}
    'Matrix *= M
    Matrix(12) = X*Matrix(0) + Y*Matrix(4) + Z*Matrix(8) + Matrix(12)
    Matrix(13) = X*Matrix(1) + Y*Matrix(5) + Z*Matrix(9) + Matrix(13)
    Matrix(14) = X*Matrix(2) + Y*Matrix(6) + Z*Matrix(10) + Matrix(14)
    Matrix(15) = X*Matrix(3) + Y*Matrix(7) + Z*Matrix(11) + Matrix(15)
End Sub

Sub Vox_Model.Translate(V As Vec3I)
    Translate V.X, V.Y, V.Z
End Sub

Sub Vox_Model.Scale(S As Double)
    Matrix(0) = S*Matrix(0): Matrix(1) = S*Matrix(1): Matrix(2) = S*Matrix(2)
    Matrix(4) = S*Matrix(4): Matrix(5) = S*Matrix(5): Matrix(6) = S*Matrix(6)
    Matrix(8) = S*Matrix(8): Matrix(9) = S*Matrix(9): Matrix(10) = S*Matrix(10)
    Scaled = -1
End Sub

Sub Vox_Model.Scale(X As Double, Y As Double, Z As Double)
    'Dim M(15) As GLdouble = {X, 0, 0, 0, _
    '                         0, Y, 0, 0, _
    '                         0, 0, Z, 0, _
    '                         0, 0, 0, 1}
    'Matrix *= M
    Matrix(0) = X*Matrix(0): Matrix(1) = Y*Matrix(1): Matrix(2) = Z*Matrix(2)
    Matrix(4) = X*Matrix(4): Matrix(5) = Y*Matrix(5): Matrix(6) = Z*Matrix(6)
    Matrix(8) = X*Matrix(8): Matrix(9) = Y*Matrix(9): Matrix(10) = Z*Matrix(10)
    Scaled = -1
End Sub

Sub Vox_Model.Scale(V As Vec3I)
    Scale V.X, V.Y, V.Z
End Sub

'PrintMatrix:
    '? Matrix(0) & " " & Matrix(1) & " " & Matrix(2) & " " & Matrix(3)
    '? Matrix(4) & " " & Matrix(5) & " " & Matrix(6) & " " & Matrix(7)
    '? Matrix(8) & " " & Matrix(9) & " " & Matrix(10) & " " & Matrix(11)
    '? Matrix(12) & " " & Matrix(13) & " " & Matrix(14) & " " & Matrix(15)

Sub Vox_Model.Rotate(Angle As Double, NX As Double, NY As Double, NZ As Double)
    'Dim M(15) As GLdouble = {...
    'Matrix *= M
    'ToDo: Rewrite this without gl calls
    glPushMatrix
    glLoadMatrixd @Matrix(0)
    glRotated Angle / DEG, NX, NY, NZ
    glGetDoublev GL_MODELVIEW_MATRIX, @Matrix(0)
    glPopMatrix
End Sub

Sub Vox_Model.Rotate(Angle As Double, N As Vec3I)
    Rotate Angle, N.X, N.Y, N.Z
End Sub

Sub VoxFont.SetFont(Vol As Vox_Volume)
    VolFont = Vol
    SrcCharSize = VoxGetVolumeSize(Vol)
    SrcCharSize.X \= 16
    SrcCharSize.Y \= 16
    DestCharSize = SrcCharSize
End Sub

Sub VoxFont.SetForeColor(ByVal Col As UInteger)
    ForeColor = SwapRB(ForeColor)
    Col = SwapRB(Col)
    VoxSetVolume VolFont
    VoxVolumeLock
    Var P = VoxVolumePtr
    For I As Integer = 0 To SrcCharSize.X*SrcCharSize.Y*SrcCharSize.Z*256-1
        If *P = ForeColor Then *P = Col
        P += 1
    Next I
    VoxVolumeUnlock
    ForeColor = SwapRB(Col)
End Sub

Sub VoxFont.Bold
    ForeColor = SwapRB(ForeColor)
    VoxSetVolume VolFont
    VoxVolumeLock
    Var P = VoxVolumePtr
    For I As Integer = 0 To SrcCharSize.X*SrcCharSize.Y*SrcCharSize.Z*256-1
        If *P <> 0 Then *P = ForeColor
        P += 1
    Next I
    VoxVolumeUnlock
    ForeColor = SwapRB(ForeColor)
End Sub

Sub VoxFont.Italize
    Var Temp = VoxNewVolume((3*SrcCharSize.X\2)*16, SrcCharSize.Y*16, SrcCharSize.Z)
    VoxSetSource VolFont
    
    'For Y = 0 To SrcCharSize.Y*16
    'Next Y
    VoxSizeVolume 0, 0, 0
End Sub

Sub VoxFont.Underline
    VoxSetVolume VolFont
    VoxSetColor ForeColor
    VoxVolumeLock
    For Y As Integer = 0 To 15
        VoxTriangle Vec3I(0, Y*SrcCharSize.Y, 0), Vec3I(16*SrcCharSize.X-1, Y*SrcCharSize.Y, 0), Vec3I(0, Y*SrcCharSize.Y, SrcCharSize.Z-1)
        VoxTriangleFanTo Vec3I(16*SrcCharSize.X-1, Y*SrcCharSize.Y, SrcCharSize.Z-1)
    Next Y
    VoxVolumeUnlock
End Sub

Sub VoxFont.StrikeThrough
    VoxSetVolume VolFont
    VoxSetColor ForeColor
    VoxVolumeLock
    For Y As Integer = 0 To 15
        VoxTriangle Vec3I(0, Y*SrcCharSize.Y+SrcCharSize.Y\2, 0), Vec3I(16*SrcCharSize.X-1, Y*SrcCharSize.Y+SrcCharSize.Y\2, 0), Vec3I(0, Y*SrcCharSize.Y+SrcCharSize.Y\2, SrcCharSize.Z-1)
        VoxTriangleFanTo Vec3I(16*SrcCharSize.X-1, Y*SrcCharSize.Y+SrcCharSize.Y\2, SrcCharSize.Z-1)
    Next Y
    VoxVolumeUnlock
End Sub

Sub VoxFont.RenderText(St As String)
    Dim As Vec3I A, B
    For I As Integer = 0 To Len(St)-1
        If I < Len(St) - 1 AndAlso (St[I] = 13 And St[I+1] = 10) Then
            B.X = 0
            B.Y -= DestCharSize.Y
            I += 1
            Continue For
        End If
        If St[I] = 13 Then
            B.X = 0
            B.Y -= DestCharSize.Y
            Continue For
        End If
        A = Vec3I((St[I] Mod 16)*SrcCharSize.X, (15 - St[I] \ 16)*SrcCharSize.Y, 0)
        glTranslatef B.X-A.X, B.Y-A.Y, B.Z-A.Z
        VoxRenderSubVolume VolFont, A, A + SrcCharSize-Vec3I(1,1,1)
        glTranslatef A.X-B.X, A.Y-B.Y, A.Z-B.Z
        B.X += DestCharSize.X
    Next I
End Sub

Sub VoxFont.BlitText(St As String)
    Dim As Vec3I A, B
    VoxSetSource VolFont
    For I As Integer = 0 To Len(St)-1
        If I < Len(St) - 1 AndAlso (St[I] = 13 And St[I+1] = 10) Then
            B.X = 0
            B.Y -= DestCharSize.Y
            I += 1
            Continue For
        End If
        If St[I] = 13 Then
            B.X = 0
            B.Y -= DestCharSize.Y
            Continue For
        End If
        A = Vec3I((St[I] Mod 16)*SrcCharSize.X, (15 - St[I] \ 16)*SrcCharSize.Y, 0)
        VoxBlit B, A, SrcCharSize
        B.X += DestCharSize.X
    Next I
End Sub

Constructor Vec3L16()
    X = 0
    Y = 0
    Z = 0
End Constructor

Constructor Vec3L16(V As Vec3L16)
    X = V.X
    Y = V.Y
    Z = V.Z
End Constructor

Constructor Vec3L16(X As LongInt, Y As LongInt, Z As LongInt)
    This.X = X
    This.Y = Y
    This.Z = Z
End Constructor

Constructor Vec3L16(V As Vec3I)
    X = V.X
    Y = V.Y
    Z = V.Z
End Constructor

Operator + (ByRef Lhs As Vec3L16, ByRef Rhs As Vec3L16) As Vec3L16
    Return Type(Lhs.X + Rhs.X, Lhs.Y + Rhs.Y, Lhs.Z + Rhs.Z)
End Operator
Operator - (ByRef Lhs As Vec3L16, ByRef Rhs As Vec3L16) As Vec3L16
    Return Type(Lhs.X - Rhs.X, Lhs.Y - Rhs.Y, Lhs.Z - Rhs.Z)
End Operator

'Scalar Products
Operator * (ByRef Lhs As Vec3L16, ByRef Rhs As LongInt) As Vec3L16
    Return Type((Lhs.X * Rhs)\&H10000, (Lhs.Y * Rhs)\&H10000, (Lhs.Z * Rhs)\&H10000)
End Operator
Operator * (ByRef Lhs As LongInt, ByRef Rhs As Vec3L16) As Vec3L16
    Return Type((Lhs * Rhs.X)\&H10000, (Lhs * Rhs.Y)\&H10000, (Lhs * Rhs.Z)\&H10000)
End Operator
Operator / (ByRef Lhs As Vec3L16, ByRef Rhs As LongInt) As Vec3L16
    Return Type((Lhs.X*&H10000) \ Rhs, (Lhs.Y*&H10000) \ Rhs, (Lhs.Z*&H10000) \ Rhs)
End Operator
Operator \ (ByRef Lhs As Vec3L16, ByRef Rhs As LongInt) As Vec3L16
    Return Type((Lhs.X \ Rhs) * &H10000, (Lhs.Y \ Rhs) * &H10000, (Lhs.Z \ Rhs) * &H10000)
End Operator
'Dot Product
Operator * (ByRef Lhs As Vec3L16, ByRef Rhs As Vec3L16) As LongInt
    Return (Lhs.X*Rhs.X + Lhs.Y*Rhs.Y + Lhs.Z*Rhs.Z)\&H10000
End Operator
'Cross Product
Function Cross (ByRef Lhs As Vec3L16, ByRef Rhs As Vec3L16) As Vec3L16
    Return Type((Lhs.Y*Rhs.Z - Lhs.Z*Rhs.Y)\&H10000, (Lhs.Z*Rhs.X - Lhs.X*Rhs.Z)\&H10000, (Lhs.X*Rhs.Y - Lhs.Y*Rhs.X)\&H10000)
End Function

' Assuming Axis is a unit vector, Inputs are 48:16 fixed point Vectors and numbers
Sub AxisRotate3D(ByRef V As Vec3L16, ByRef MidP As Vec3L16, ByRef Axis As Vec3L16, CosA As LongInt, SinA As LongInt)
    Dim As Vec3L16 X, Y, Z
    
    V -= MidP
    
    Z = (V*Axis)*Axis
    X = V - Z
    Y = Cross(X, Axis)
    
    V = Z + X*CosA + Y*SinA
    
    V += MidP
End Sub