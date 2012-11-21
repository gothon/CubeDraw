'/////////////////////////////////////
'|| modGUI.bas - GUI Objects module
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
#Include "modGUI.bi"
#Include "GL/gl.bi"
#Include "GL/glext.bi"

#Define RGBA_R(C) (CUInt(C) Shr 16 And 255)
#Define RGBA_G(C) (CUInt(C) Shr  8 And 255)
#Define RGBA_B(C) (CUInt(C)        And 255)
#Define RGBA_A(C) (CUInt(C) Shr 24        )

Constructor ColorSelectorRGB
    VC = VoxNewContext(VoxNewVolume(32, 32, 32))
    
    VoxVolumeLock
    Dim As Integer X, Y, Z, I
    Dim As UInteger Ptr P = VoxVolumePtr
    For X = 0 To 31
        For Y = 0 To 31
            For Z = 0 To 31
                P[I] = RGB(X*8+7, Y*8+7, Z*8+7)
                I += 1
            Next Z
        Next Y
    Next X
    VoxVolumeUnlock
    
    VoxScreenDistance 96
    VoxScreenTurnRight -1
    VoxScreenTurnDown .5
    
    RedBar = VoxNewVolume(32, 1, 1)
    VoxVolumeLock
    P = VoxVolumePtr
    For I = 0 To 31
        P[I] = RGB(32-I, 32-I, 32+I*7)
    Next I
    VoxVolumeUnlock
    
    GreenBar = VoxNewVolume(1, 32, 1)
    VoxVolumeLock
    P = VoxVolumePtr
    For I = 0 To 31
        P[I] = RGB(32-I, 32+I*7, 32-I)
    Next I
    VoxVolumeUnlock
    
    BlueBar = VoxNewVolume(1, 1, 32)
    VoxVolumeLock
    P = VoxVolumePtr
    For I = 0 To 31
        P[I] = RGB(32+I*7, 32-I, 32-I)
    Next I
    VoxVolumeUnlock
    
    GreyBox = VoxNewVolume(8, 8, 8)
    VoxSetColor RGB(128, 128, 128)
    DrawCubeEdges Vec3I(0, 0, 0), Vec3I(7, 7, 7)
    
    VoxSetVolume
    VoxSetContext
End Constructor

Sub ColorSelectorRGB.Render(ScreenW As Integer, ScreenH As Integer)
    If NoHov Then HitArea = -1
    VoxGlRenderState ScreenW, ScreenH
    VoxRenderSubVolume VOXEL_SCREEN, Vec3I(0,0,0), SelV
    
    glEnable GL_NORMALIZE'GL_RESCALE_NORMAL
    glPushMatrix
    glTranslated 0, -1, -1
    glScaled 1, 2, 2
    glTranslated 0, -1, -1
    VoxRenderVolume RedBar
    glTranslated 0, 18, 0
    VoxRenderVolume RedBar
    glTranslated 0, 0, 18
    VoxRenderVolume RedBar
    glTranslated 0, -18, 0
    VoxRenderVolume RedBar
    glScaled 1, .5, .5
    glTranslated 0, 1, 1
    
    glTranslated -2, 2, -36
    glTranslated -1, 0, -1
    glScaled 2, 1, 2
    VoxRenderVolume GreenBar
    glTranslated 18, 0, 0
    VoxRenderVolume GreenBar
    glTranslated 0, 0, 18
    VoxRenderVolume GreenBar
    glTranslated -18, 0, 0
    VoxRenderVolume GreenBar
    glScaled .5, 1, .5
    glTranslated 1, 0, 1
    
    glTranslated 0, -2, -34
    glTranslated -1, -1, 0
    glScaled 2, 2, 1
    VoxRenderVolume BlueBar
    glTranslated 18, 0, 0
    VoxRenderVolume BlueBar
    glTranslated 0, 18, 0
    VoxRenderVolume BlueBar
    glTranslated -18, 0, 0
    VoxRenderVolume BlueBar
    glScaled .5, .5, 1
    glTranslated 1, 1, 0
    
    glTranslated 2, -34, 0
    
    glScaled 0.5, 0.5, 0.5
    glTranslated -8, -8, -8
    VoxRenderVolume GreyBox
    glTranslated 72, 0, 0
    VoxRenderVolume GreyBox
    glTranslated 0, 72, 0
    VoxRenderVolume GreyBox
    glTranslated -72, 0, 0
    VoxRenderVolume GreyBox
    glTranslated 0, 0, 72
    VoxRenderVolume GreyBox
    glTranslated 72, 0, 0
    VoxRenderVolume GreyBox
    glTranslated 0, -72, 0
    VoxRenderVolume GreyBox
    glTranslated -72, 0, 0
    VoxRenderVolume GreyBox
    
    glTranslated 8, 8, -64
    
    glScaled 1/3, 1/3, 1/3
    glTranslated (RGBA_R(SelColor)-7)*3/4-1, (RGBA_G(SelColor)-7)*3/4-1, (RGBA_B(SelColor)-7)*3/4-1
    VoxRenderVolume GreyBox
    glDisable GL_NORMALIZE'GL_RESCALE_NORMAL
    glPopMatrix
End Sub

Function ColorSelectorRGB.HitTest(X As Integer, Y As Integer, Dist As Double = -1) As Integer
    NoHov = -1
    HitArea = -1
    VoxGlRenderState 0, 0, VOXEL_MODELVIEW
    VoxSetVolume
    If VoxSubCursorTest(V1, V2, Vec3I(0,0,0), SelV, X, Y, Dist) Then HitArea = 0
    
    VoxSetVolume RedBar
    glTranslated 0, -1, -1
    glScaled 1, 2, 2
    glTranslated 0, -1, -1
    If VoxCursorTest(V1, V2, X, Y, Dist) Then HitArea = 1
    glTranslated 0, 18, 0
    If VoxCursorTest(V1, V2, X, Y, Dist) Then HitArea = 1
    glTranslated 0, 0, 18
    If VoxCursorTest(V1, V2, X, Y, Dist) Then HitArea = 1
    glTranslated 0, -18, 0
    If VoxCursorTest(V1, V2, X, Y, Dist) Then HitArea = 1
    glScaled 1, .5, .5
    glTranslated 0, 1, 1
    
    VoxSetVolume GreenBar
    glTranslated -2, 2, -36
    glTranslated -1, 0, -1
    glScaled 2, 1, 2
    If VoxCursorTest(V1, V2, X, Y, Dist) Then HitArea = 2
    glTranslated 18, 0, 0
    If VoxCursorTest(V1, V2, X, Y, Dist) Then HitArea = 2
    glTranslated 0, 0, 18
    If VoxCursorTest(V1, V2, X, Y, Dist) Then HitArea = 2
    glTranslated -18, 0, 0
    If VoxCursorTest(V1, V2, X, Y, Dist) Then HitArea = 2
    glScaled .5, 1, .5
    glTranslated 1, 0, 1
    
    VoxSetVolume BlueBar
    glTranslated 0, -2, -34
    glTranslated -1, -1, 0
    glScaled 2, 2, 1
    If VoxCursorTest(V1, V2, X, Y, Dist) Then HitArea = 3
    glTranslated 18, 0, 0
    If VoxCursorTest(V1, V2, X, Y, Dist) Then HitArea = 3
    glTranslated 0, 18, 0
    If VoxCursorTest(V1, V2, X, Y, Dist) Then HitArea = 3
    glTranslated -18, 0, 0
    If VoxCursorTest(V1, V2, X, Y, Dist) Then HitArea = 3
    glScaled .5, .5, 1
    glTranslated 1, 1, 0
    
    VoxSetVolume GreyBox
    glTranslated 2, -34, 0
    glScaled 0.5, 0.5, 0.5
    glTranslated -8, -8, -8
    If VoxCursorTest(V1, V2, X, Y, Dist) Then HitArea = 4
    glTranslated 72, 0, 0
    If VoxCursorTest(V1, V2, X, Y, Dist) Then HitArea = 4
    glTranslated 0, 72, 0
    If VoxCursorTest(V1, V2, X, Y, Dist) Then HitArea = 4
    glTranslated -72, 0, 0
    If VoxCursorTest(V1, V2, X, Y, Dist) Then HitArea = 4
    glTranslated 0, 0, 72
    If VoxCursorTest(V1, V2, X, Y, Dist) Then HitArea = 4
    glTranslated 72, 0, 0
    If VoxCursorTest(V1, V2, X, Y, Dist) Then HitArea = 4
    glTranslated 0, -72, 0
    If VoxCursorTest(V1, V2, X, Y, Dist) Then HitArea = 4
    glTranslated -72, 0, 0
    
    VoxSetVolume
    Return (HitArea > -1)
End Function

Sub ColorSelectorRGB.Hover(X As Integer, Y As Integer)
    NoHov = 0
End Sub

Sub ColorSelectorRGB.Click(X As Integer, Y As Integer)
    NoHov = 0
    Select Case HitArea
    Case 0, 4
        If HitArea = 4 Then
            SetColor 0
            HitArea = -1
           Else
            SetColor VoxPoint(V1)
        End If
    Case 1
        SelV = Vec3I(V1.X, 31, 31)
        SetColor RGB(V1.X*8+7, RGBA_G(SelColor), RGBA_B(SelColor))
    Case 2
        SelV = Vec3I(31, V1.Y, 31)
        SetColor RGB(RGBA_R(SelColor), V1.Y*8+7, RGBA_B(SelColor))
    Case 3
        SelV = Vec3I(31, 31, V1.Z)
        SetColor RGB(RGBA_R(SelColor), RGBA_G(SelColor), V1.Z*8+7)
    End Select
End Sub

Sub ColorSelectorRGB.CursorMove(X As Integer, Y As Integer)
    Dim As Vec3I V1, V2
    Dim As Double Dist = -1
    Dim As Integer Hit
    
    VoxGlRenderState 0, 0, VOXEL_MODELVIEW
    
    Select Case HitArea
    Case 0
        VoxSetVolume
        If VoxSubCursorTest(V1, V2, Vec3I(0,0,0), SelV, X, Y, Dist) Then Hit = -1
    Case 1
        VoxSetVolume RedBar
        glTranslated 0, -1, -1
        glScaled 1, 2, 2
        glTranslated 0, -1, -1
        If VoxCursorTest(V1, V2, X, Y, Dist) Then Hit = -1
        glTranslated 0, 18, 0
        If VoxCursorTest(V1, V2, X, Y, Dist) Then Hit = -1
        glTranslated 0, 0, 18
        If VoxCursorTest(V1, V2, X, Y, Dist) Then Hit = -1
        glTranslated 0, -18, 0
        If VoxCursorTest(V1, V2, X, Y, Dist) Then Hit = -1
        'glScaled 1, .5, .5
        'glTranslated 0, 1, 1
    Case 2
        VoxSetVolume GreenBar
        glTranslated -2, 0, -2
        glTranslated -1, 0, -1
        glScaled 2, 1, 2
        If VoxCursorTest(V1, V2, X, Y, Dist) Then Hit = -1
        glTranslated 18, 0, 0
        If VoxCursorTest(V1, V2, X, Y, Dist) Then Hit = -1
        glTranslated 0, 0, 18
        If VoxCursorTest(V1, V2, X, Y, Dist) Then Hit = -1
        glTranslated -18, 0, 0
        If VoxCursorTest(V1, V2, X, Y, Dist) Then Hit = -1
        'glScaled .5, 1, .5
        'glTranslated 1, 0, 1
    Case 3
        VoxSetVolume BlueBar
        glTranslated -2, -2, 0
        glTranslated -1, -1, 0
        glScaled 2, 2, 1
        If VoxCursorTest(V1, V2, X, Y, Dist) Then Hit = -1
        glTranslated 18, 0, 0
        If VoxCursorTest(V1, V2, X, Y, Dist) Then Hit = -1
        glTranslated 0, 18, 0
        If VoxCursorTest(V1, V2, X, Y, Dist) Then Hit = -1
        glTranslated -18, 0, 0
        If VoxCursorTest(V1, V2, X, Y, Dist) Then Hit = -1
        'glScaled .5, .5, 1
        'glTranslated 1, 1, 0
    End Select
    
    VoxSetVolume
    If Hit Then
        Select Case HitArea
        Case 0: SetColor VoxPoint(V1)
        Case 1
            SelV = Vec3I(V1.X, 31, 31)
            SetColor RGB(V1.X*8+7, RGBA_G(SelColor), RGBA_B(SelColor))
        Case 2
            SelV = Vec3I(31, V1.Y, 31)
            SetColor RGB(RGBA_R(SelColor), V1.Y*8+7, RGBA_B(SelColor))
        Case 3
            SelV = Vec3I(31, 31, V1.Z)
            SetColor RGB(RGBA_R(SelColor), RGBA_G(SelColor), V1.Z*8+7)
        End Select
    End If
End Sub

Sub ColorSelectorRGB.SetColor(C As UInteger)
    SelColor = C
    If SelColor <> 0 Then
        SelColor Or= &HFF000000
        If RGBA_R(SelColor) = 0 Then SelColor Or= &H070000
        If RGBA_G(SelColor) = 0 Then SelColor Or= &H0700
        If RGBA_B(SelColor) = 0 Then SelColor Or= &H07
    End If
    
    VoxSetVolume GreyBox
    VoxSetColor SelColor
    DrawGrid Vec3I(1, 1, 1), Vec3I(6, 6, 6), 1
    VoxSetVolume
End Sub

Constructor HitPlanes
    Size = VoxGetVolumeSize(VOXEL_SCREEN)
    VolGrid(0) = VoxNewVolume(1, 1, 1)
    VolGrid(1) = VoxNewVolume(1, 1, 1)
    VolGrid(2) = VoxNewVolume(1, 1, 1)
    
    SetSize
    
    VolArrow = VoxNewVolume(4, 4, 8)
    VoxSetColor RGB(128, 128, 192)
    VoxLine Vec3I(3, 3, 0), Vec3I(3, 3, 7)
    VoxLine Vec3I(1, 3, 5), Vec3I(3, 3, 7)
    VoxLine Vec3I(3, 1, 5), Vec3I(3, 3, 7)
    VoxLine Vec3I(1, 3, 4), Vec3I(2, 3, 5)
    VoxLine Vec3I(3, 1, 4), Vec3I(3, 2, 5)
    
    VolCorner = VoxNewVolume(4, 4, 4)
    VoxSetColor RGB(128, 192, 128)
    VoxLine Vec3I(0, 3, 0), Vec3I(3, 3, 0)
    VoxLine Vec3I(3, 0, 0), Vec3I(3, 3, 0)
    
    Arrows(0).Volume = VolArrow
    Arrows(1).Volume = VolArrow
    Arrows(2).Volume = VolArrow
    
    Corners(0).Volume = VolCorner
    Corners(1).Volume = VolCorner
    Corners(2).Volume = VolCorner
End Constructor

Sub HitPlanes.Render(ScreenW As Integer, ScreenH As Integer)
    If NoHov Then HitArea = -1
    VoxGlRenderState ScreenW, ScreenH, VOXEL_NOCLEAR Or VOXEL_NOLIGHT
    glColor4ub 255, 255, 255, 255
    glEnable GL_RESCALE_NORMAL
    glScaled 0.5, 0.5, 0.5
    glTranslated 0.5, 0.5, 0.5
    glTranslated 2*Posn.X, 0, 0
    VoxRenderVolume VolGrid(0)
    glTranslated -2*Posn.X, 2*Posn.Y, 0
    VoxRenderVolume VolGrid(1)
    glTranslated 0, -2*Posn.Y, 2*Posn.Z
    VoxRenderVolume VolGrid(2)
    glTranslated -0.5, -0.5, -0.5-2*Posn.Z
    glScaled 2, 2, 2
    
    If HitArea = 0 Then glColor4ub 0, 128, 255, 255
    Arrows(0).Render
    glColor4ub 255, 255, 255, 255
    If HitArea = 1 Then glColor4ub 0, 128, 255, 255
    Arrows(1).Render
    glColor4ub 255, 255, 255, 255
    If HitArea = 2 Then glColor4ub 0, 128, 255, 255
    Arrows(2).Render
    glColor4ub 255, 255, 255, 255
    
    If HitArea = 3 Then glColor4ub 0, 128, 255, 255
    Corners(0).Render
    glColor4ub 255, 255, 255, 255
    If HitArea = 4 Then glColor4ub 0, 128, 255, 255
    Corners(1).Render
    glColor4ub 255, 255, 255, 255
    If HitArea = 5 Then glColor4ub 0, 128, 255, 255
    Corners(2).Render
    glColor4ub 255, 255, 255, 255
    
    glDisable GL_RESCALE_NORMAL
End Sub

Function HitPlanes.HitTest(X As Integer, Y As Integer, Dist As Double = -1) As Integer
    Dim As Vec3I V1, V2
    HitArea = -1
    NoHov = -1
    VoxGlRenderState 0, 0, VOXEL_MODELVIEW
    
    If Arrows(0).HitTest(V1, V2, X, Y, Dist) Then HitArea = 0
    If Arrows(1).HitTest(V1, V2, X, Y, Dist) Then HitArea = 1
    If Arrows(2).HitTest(V1, V2, X, Y, Dist) Then HitArea = 2
    
    If Corners(0).HitTest(V1, V2, X, Y, Dist) Then HitArea = 3
    If Corners(1).HitTest(V1, V2, X, Y, Dist) Then HitArea = 4
    If Corners(2).HitTest(V1, V2, X, Y, Dist) Then HitArea = 5
    
    If HitArea > -1 Then
        If HitArea < 3 Then
            Dim As Vec3I V = V2-V1
            If V*Vec3I(1,1,1) = 1 Then V1 -= V
            If V.X <> 0 Then
                HitX = V1.X
                HitAxis = VOXEL_AXIS_X
            End If
            If V.Y <> 0 Then
                HitY = V1.Y
                HitAxis = VOXEL_AXIS_Y
            End If
            If V.Z <> 0 Then
                HitZ = V1.Z
                HitAxis = VOXEL_AXIS_Z
            End If
            Arrows(HitArea).SetModelMatrix
            glTranslated 0, 0, -4*Posn.V(2-HitArea)
            VoxWallTest HitX, HitY, HitZ, HitAxis, X, Y
           Else
            HitX = Posn.X
            HitY = Posn.Y
            HitZ = Posn.Z
            VoxGlRenderState 0, 0, VOXEL_MODELVIEW
            VoxWallTest HitX, HitY, HitZ, (6-HitArea), X, Y
        End If
    End If
    Return (HitArea > -1)
End Function

Sub HitPlanes.Hover(X As Integer, Y As Integer)
    NoHov = 0
End Sub

Sub HitPlanes.Click(X As Integer, Y As Integer)
    NoHov = 0
End Sub

Sub HitPlanes.CursorMove(X As Integer, Y As Integer)
    Dim As Double VX = HitX, VY = HitY, VZ = HitZ
    
    If HitArea > -1 Then
        If HitArea < 3 Then
            Arrows(HitArea).SetModelMatrix
            glTranslated 0, 0, -4*Posn.V(2-HitArea)
            VoxWallTest VX, VY, VZ, HitAxis, X, Y
            If Abs(VZ - HitZ) >= 4 Then
                Posn.V(2-HitArea) += Int((VZ - HitZ)/4+0.5) ' = VZ / 4 '
                HitZ += Int((VZ - HitZ)/4+0.5)*4
                If Posn.V(2-HitArea) < -3 Then HitZ += (-3 - Posn.V(2-HitArea))*4: Posn.V(2-HitArea) = -3
                If Posn.V(2-HitArea) >= Size.V(2-HitArea) + 3 Then HitZ += (Size.V(2-HitArea) + 2 - Posn.V(2-HitArea))*4: Posn.V(2-HitArea) = Size.V(2-HitArea) + 2
                SetSize
            End If
           Else
            VoxGlRenderState 0, 0, VOXEL_MODELVIEW
            VoxWallTest VX, VY, VZ, (6-HitArea), X, Y
            VoxSetVolume VolCorner
            If Abs(VX - HitX) >= 1 Or Abs(VY - HitY) >= 1 Or Abs(VZ - HitZ) >= 1 Then
                If HitArea <> 5 Then
                    Size.X += Int((VX - HitX)+0.5)
                    HitX += Int((VX - HitX)+0.5)
                    If Size.X < 1 Then HitX += 1-Size.X: Size.X = 1
                End If
                If HitArea <> 4 Then
                    Size.Y += Int((VY - HitY)+0.5)
                    HitY += Int((VY - HitY)+0.5)
                    If Size.Y < 1 Then HitY += 1-Size.Y: Size.Y = 1
                End If
                If HitArea <> 3 Then
                    Size.Z += Int((VZ - HitZ)+0.5)
                    HitZ += Int((VZ - HitZ)+0.5)
                    If Size.Z < 1 Then HitZ += 1-Size.Z: Size.Z = 1
                End If
                SetSize
            End If
        End If
    End If
End Sub

Function HitPlanes.HitTestPlanes(ByRef V1 As Vec3I, ByRef V2 As Vec3I, X As Integer, Y As Integer, ByRef Dist As Double = -1) As UInteger
    Dim As Double VX, VY, VZ, Dist2 = Dist
    
    If Posn.X >= -1 And Posn.X < Size.X+1 Then
        VX = Posn.X
        If VoxWallTest(VX, VY, VZ, VOXEL_AXIS_X, X, Y, Dist) Then
            If Int(VY) >= 0 And Int(VY) < Size.Y And Int(VZ) >= 0 And Int(VZ) < Size.Z Then
                V1 = Vec3I(Posn.X, Int(VY), Int(VZ))
                V2 = Vec3I(V1.X + IIf(VX = V1.X, -1, 1), V1.Y, V1.Z)
                Function = VOXEL_AXIS_X
                Dist2 = Dist
               Else
                Dist = Dist2
            End If
        End If
    End If
    If Posn.Y >= -1 And Posn.Y < Size.Y+1 Then
        VY = Posn.Y
        If VoxWallTest(VX, VY, VZ, VOXEL_AXIS_Y, X, Y, Dist) Then
            If Int(VX) >= 0 And Int(VX) < Size.X And Int(VZ) >= 0 And Int(VZ) < Size.Z Then
                V1 = Vec3I(Int(VX), Posn.Y, Int(VZ))
                V2 = Vec3I(V1.X, V1.Y + IIf(VY = V1.Y, -1, 1), V1.Z)
                Function = VOXEL_AXIS_Y
                Dist2 = Dist
               Else
                Dist = Dist2
            End If
        End If
    End If
    If Posn.Z >= -1 And Posn.Z < Size.Z+1 Then
        VZ = Posn.Z
        If VoxWallTest(VX, VY, VZ, VOXEL_AXIS_Z, X, Y, Dist) Then
            If Int(VX) >= 0 And Int(VX) < Size.X And Int(VY) >= 0 And Int(VY) < Size.Y Then
                V1 = Vec3I(Int(VX), Int(VY), Posn.Z)
                V2 = Vec3I(V1.X, V1.Y, V1.Z + IIf(VZ = V1.Z, -1, 1))
                Function = VOXEL_AXIS_Z
                Dist2 = Dist
               Else
                Dist = Dist2
            End If
        End If
    End If
End Function

Function HitPlanes.HitTestPlaneEdges(ByRef V1 As Vec3I, X As Integer, Y As Integer, ByRef Dist As Double = -1) As UInteger
    Dim As Double VX, VY, VZ, Dist2 = Dist
    
    If Posn.X >= 0 And Posn.X < Size.X Then
        If VoxWallTest(CDbl(Posn.X), VY, VZ, VOXEL_AXIS_X, X, Y, Dist) Then
            If Int(VY) >= -2 And Int(VY) < Size.Y+2 And Int(VZ) >= -2 And Int(VZ) < Size.Z+2 And _
               (Int(VY) >= 0 And Int(VY) < Size.Y XOr Int(VZ) >= 0 And Int(VZ) < Size.Z) Then
                V1 = Vec3I(Posn.X, Int(VY), Int(VZ))
                Function = VOXEL_AXIS_X
                Dist2 = Dist
               Else
                Dist = Dist2
            End If
        End If
    End If
    If Posn.Y >= 0 And Posn.Y < Size.Y Then
        If VoxWallTest(VX, CDbl(Posn.Y), VZ, VOXEL_AXIS_Y, X, Y, Dist) Then
            If Int(VX) >= -2 And Int(VX) < Size.X+2 And Int(VZ) >= -2 And Int(VZ) < Size.Z+2 And _
               (Int(VX) >= 0 And Int(VX) < Size.X XOr Int(VZ) >= 0 And Int(VZ) < Size.Z) Then
                V1 = Vec3I(Int(VX), Posn.Y, Int(VZ))
                Function = VOXEL_AXIS_Y
                Dist2 = Dist
               Else
                Dist = Dist2
            End If
        End If
    End If
    If Posn.Z >= 0 And Posn.Z < Size.Z Then
        If VoxWallTest(VX, VY, CDbl(Posn.Z), VOXEL_AXIS_Z, X, Y, Dist) Then
            If Int(VY) >= -2 And Int(VY) < Size.Y+2 And Int(VX) >= -2 And Int(VX) < Size.X+2 And _
               (Int(VY) >= 0 And Int(VY) < Size.Y XOr Int(VX) >= 0 And Int(VX) < Size.X) Then
                V1 = Vec3I(Int(VX), Int(VY), Posn.Z)
                Function = VOXEL_AXIS_Z
                Dist2 = Dist
               Else
                Dist = Dist2
            End If
        End If
    End If
End Function

Sub HitPlanes.SetSize()
    VoxSetVolume VolGrid(0)
    VoxSizeVolume(1, Size.Y*2-1, Size.Z*2-1)
    VoxVolumeLock
    If Posn.X >= -1 And Posn.X < Size.X+1 Then
        VoxSetColor RGB(32, 32, 32)
        DrawGrid Vec3I(0,0,0), Vec3I(0, Size.Y*2-2, Size.Z*2-2), 4
        VoxSetColor RGB(64, 64, 64)
        DrawGrid Vec3I(0,0,0), Vec3I(0, Size.Y*2-2, Size.Z*2-2), 20
    End If
    VoxSetColor RGB(196, 196, 196)
    DrawCubeEdges Vec3I(0,0,0), Vec3I(0, Size.Y*2-2, Size.Z*2-2)
    VoxVolumeUnlock
    
    VoxSetVolume VolGrid(1)
    VoxSizeVolume(Size.X*2-1, 1, Size.Z*2-1)
    VoxVolumeLock
    If Posn.Y >= -1 And Posn.Y < Size.Y+1 Then
        VoxSetColor RGB(32, 32, 32)
        DrawGrid Vec3I(0,0,0), Vec3I(Size.X*2-2, 0, Size.Z*2-2), 4
        VoxSetColor RGB(64, 64, 64)
        DrawGrid Vec3I(0,0,0), Vec3I(Size.X*2-2, 0, Size.Z*2-2), 20
    End If
    VoxSetColor RGB(196, 196, 196)
    DrawCubeEdges Vec3I(0,0,0), Vec3I(Size.X*2-2, 0, Size.Z*2-2)
    VoxVolumeUnlock
    
    VoxSetVolume VolGrid(2)
    VoxSizeVolume(Size.X*2-1, Size.Y*2-1, 1)
    VoxVolumeLock
    If Posn.Z >= -1 And Posn.Z < Size.Z+1 Then
        VoxSetColor RGB(32, 32, 32) 'RGB(128, 128, 128)
        DrawGrid Vec3I(0,0,0), Vec3I(Size.X*2-2, Size.Y*2-2, 0), 4
        VoxSetColor RGB(64, 64, 64) 'RGB(196, 196, 196)
        DrawGrid Vec3I(0,0,0), Vec3I(Size.X*2-2, Size.Y*2-2, 0), 20
    End If
    VoxSetColor RGB(196, 196, 196) 'RGB(255, 255, 255)
    DrawCubeEdges Vec3I(0,0,0), Vec3I(Size.X*2-2, Size.Y*2-2, 0)
    VoxVolumeUnlock
    
    Arrows(0).Identity
    Arrows(0).Scale 0.25
    Arrows(0).Translate Size.X*4-2, Size.Y*4-2, 4+4*Posn.Z
    
    Arrows(1).Identity
    Arrows(1).Scale 0.25
    Arrows(1).Translate Size.X*4-2, 4+4*Posn.Y, Size.Z*4-2
    Arrows(1).Rotate 90*DEG, 0, -1, 0
    Arrows(1).Rotate 90*DEG, -1, 0, 0
    
    Arrows(2).Identity
    Arrows(2).Scale 0.25
    Arrows(2).Translate 4+4*Posn.X, Size.Y*4-2, Size.Z*4-2
    Arrows(2).Rotate 90*DEG, 0, 1, 0
    Arrows(2).Rotate 90*DEG, 0, 0, 1
    
    Corners(0).Identity
    Corners(0).Scale 0.25
    Corners(0).Translate Size.X*4, Size.Y*4, 1.5+4*Posn.Z
    
    Corners(1).Identity
    Corners(1).Scale 0.25
    Corners(1).Translate Size.X*4, 1.5+4*Posn.Y, Size.Z*4
    Corners(1).Rotate 90*DEG, 0, -1, 0
    Corners(1).Rotate 90*DEG, -1, 0, 0
    
    Corners(2).Identity
    Corners(2).Scale 0.25
    Corners(2).Translate 1.5+4*Posn.X, Size.Y*4, Size.Z*4
    Corners(2).Rotate 90*DEG, 0, 1, 0
    Corners(2).Rotate 90*DEG, 0, 0, 1
End Sub

Constructor ButtonBar
    VC = VoxNewContext()
    VoxScreenCenter 16, 16, 16
    VoxScreenDistance 64
    VoxSetContext
    
End Constructor

Sub ButtonBar.Render
    If NoHov Then HitButton = -1
    VoxSetContext VC
    VoxGlRenderState 0, 0, VOXEL_MODELVIEW And VOXEL_LIGHT
    glTranslated 0,30,40
    glScaled 0.25, 0.25, 0.25
    glEnable GL_RESCALE_NORMAL
    VoxSetVolume VolButtons
    
    glDepthFunc GL_ALWAYS
    glCullFace GL_FRONT
    For I As Integer = 0 To NumButtons-1
        If HitButton = I Then glColor4ub 0, 196, 255, 255
        If Down <> I Then
            glTranslated 0,-I*(ButtonSize.Y+2),0
            VoxRenderSubVolume VolButtons, Vec3I(0,0,0), ButtonSize - Vec3I(1,1,1)
            glTranslated -ButtonSize.X*(I+2),0,0
            VoxRenderSubVolume VolButtons, Vec3I(ButtonSize.X*(I+2),0,0), ButtonSize + Vec3I(ButtonSize.X*(I+2)-1,-1,-1)
            glTranslated ButtonSize.X*(I+2),I*(ButtonSize.Y+2),0
           Else
            glTranslated -ButtonSize.X,-I*(ButtonSize.Y+2),0
            VoxRenderSubVolume VolButtons, Vec3I(ButtonSize.X,0,0), ButtonSize + Vec3I(ButtonSize.X-1,-1,-1)
            glTranslated -ButtonSize.X*(I+1),0,-4
            VoxRenderSubVolume VolButtons, Vec3I(ButtonSize.X*(I+2),0,0), ButtonSize + Vec3I(ButtonSize.X*(I+2)-1,-1,-1)
            glTranslated ButtonSize.X*(I+2),I*(ButtonSize.Y+2),4
        End If
        glColor4ub 255, 255, 255, 255
    Next I
    glCullFace GL_BACK
    glDepthFunc GL_LESS
    For I As Integer = 0 To NumButtons-1
        If HitButton = I Then glColor4ub 0, 196, 255, 255
        If Down <> I Then
            glTranslated 0,-I*(ButtonSize.Y+2),0
            VoxRenderSubVolume VolButtons, Vec3I(0,0,0), ButtonSize - Vec3I(1,1,1)
            glTranslated -ButtonSize.X*(I+2),0,0
            VoxRenderSubVolume VolButtons, Vec3I(ButtonSize.X*(I+2),0,0), ButtonSize + Vec3I(ButtonSize.X*(I+2)-1,-1,-1)
            glTranslated ButtonSize.X*(I+2),I*(ButtonSize.Y+2),0
           Else
            glTranslated -ButtonSize.X,-I*(ButtonSize.Y+2),0
            VoxRenderSubVolume VolButtons, Vec3I(ButtonSize.X,0,0), ButtonSize + Vec3I(ButtonSize.X-1,-1,-1)
            glTranslated -ButtonSize.X*(I+1),0,-4
            VoxRenderSubVolume VolButtons, Vec3I(ButtonSize.X*(I+2),0,0), ButtonSize + Vec3I(ButtonSize.X*(I+2)-1,-1,-1)
            glTranslated ButtonSize.X*(I+2),I*(ButtonSize.Y+2),4
        End If
        glColor4ub 255, 255, 255, 255
    Next I
    
    glDisable GL_RESCALE_NORMAL
    VoxSetContext
    'VoxGlRenderState 0, 0, VOXEL_MODELVIEW And VOXEL_LIGHT
End Sub

Function ButtonBar.HitTest(X As Integer, Y As Integer, Dist As Double = -1) As Integer
    Dim As Vec3I V1, V2
    HitButton = -1
    NoHov = -1
    VoxSetContext VC
    VoxGlRenderState 0, 0, VOXEL_MODELVIEW
    glTranslated 0,30,40
    glScaled 0.25, 0.25, 0.25
    VoxSetVolume VolButtons
    For I As Integer = 0 To NumButtons-1
        If Down <> I Then
            glTranslated 0,-I*(ButtonSize.Y+2),0
            If VoxSubCursorTest(V1, V2, Vec3I(0,0,0), ButtonSize - Vec3I(1,1,1), X, Y, Dist) Then HitButton = I
            glTranslated -ButtonSize.X*(I+2),0,0
            If VoxSubCursorTest(V1, V2, Vec3I(ButtonSize.X*(I+2),0,0), ButtonSize + Vec3I(ButtonSize.X*(I+2)-1,-1,-1), X, Y, Dist) Then HitButton = I
            glTranslated ButtonSize.X*(I+2),I*(ButtonSize.Y+2),0
           Else
            glTranslated -ButtonSize.X,-I*(ButtonSize.Y+2),0
            If VoxSubCursorTest(V1, V2, Vec3I(ButtonSize.X,0,0), ButtonSize + Vec3I(ButtonSize.X-1,-1,-1), X, Y, Dist) Then HitButton = I
            glTranslated -ButtonSize.X*(I+1),0,-4
            If VoxSubCursorTest(V1, V2, Vec3I(ButtonSize.X*(I+2),0,0), ButtonSize + Vec3I(ButtonSize.X*(I+2)-1,-1,-1), X, Y, Dist) Then HitButton = I
            glTranslated ButtonSize.X*(I+2),I*(ButtonSize.Y+2),4
        End If
    Next I
    VoxSetContext
    Return (HitButton > -1)
End Function

Sub ButtonBar.Hover(X As Integer, Y As Integer)
    NoHov = 0
End Sub

Sub ButtonBar.Click(X As Integer, Y As Integer)
    NoHov = 0
    Down = HitButton
End Sub

Sub ButtonBar.CursorMove(X As Integer, Y As Integer)
    '...
End Sub

Sub DrawCubeEdges(V1 As Vec3I, V2 As Vec3I)
    VoxVolumeLock
    VoxLine Vec3I(V1.X, V1.Y, V1.Z), Vec3I(V1.X, V1.Y, V2.Z)
    VoxLine Vec3I(V1.X, V2.Y, V1.Z), Vec3I(V1.X, V2.Y, V2.Z)
    VoxLine Vec3I(V2.X, V1.Y, V1.Z), Vec3I(V2.X, V1.Y, V2.Z)
    VoxLine Vec3I(V2.X, V2.Y, V1.Z), Vec3I(V2.X, V2.Y, V2.Z)
    
    VoxLine Vec3I(V1.X, V1.Y, V1.Z), Vec3I(V1.X, V2.Y, V1.Z)
    VoxLine Vec3I(V1.X, V1.Y, V2.Z), Vec3I(V1.X, V2.Y, V2.Z)
    VoxLine Vec3I(V2.X, V1.Y, V1.Z), Vec3I(V2.X, V2.Y, V1.Z)
    VoxLine Vec3I(V2.X, V1.Y, V2.Z), Vec3I(V2.X, V2.Y, V2.Z)
    
    VoxLine Vec3I(V1.X, V1.Y, V1.Z), Vec3I(V2.X, V1.Y, V1.Z)
    VoxLine Vec3I(V1.X, V1.Y, V2.Z), Vec3I(V2.X, V1.Y, V2.Z)
    VoxLine Vec3I(V1.X, V2.Y, V1.Z), Vec3I(V2.X, V2.Y, V1.Z)
    VoxLine Vec3I(V1.X, V2.Y, V2.Z), Vec3I(V2.X, V2.Y, V2.Z)
    VoxVolumeUnlock
End Sub

Sub DrawGrid(V1 As Vec3I, V2 As Vec3I, S As Integer)
    VoxVolumeLock
    Dim As Integer I, J
    For I = V1.X To V2.X Step S
        For J = V1.Y To V2.Y Step S
            VoxLine Vec3I(I, J, V1.Z), Vec3I(I, J, V2.Z)
        Next J
    Next I
    For I = V1.X To V2.X Step S
        For J = V1.Z To V2.Z Step S
            VoxLine Vec3I(I, V1.Y, J), Vec3I(I, V2.Y, J)
        Next J
    Next I
    For I = V1.Y To V2.Y Step S
        For J = V1.Z To V2.Z Step S
            VoxLine Vec3I(V1.X, I, J), Vec3I(V2.X, I, J)
        Next J
    Next I
    VoxVolumeUnlock
End Sub