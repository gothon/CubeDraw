'/////////////////////////////////////
'|| CubeDraw.bas - CubeDraw core message loop module
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

#Include "File.bi"
#Include "SDL/SDL.bi"
#Include "GL/gl.bi"
'#Include "GL/glu.bi"
#Include "GL/glext.bi"

#Include Once "modModel.bi"
#Include Once "modGUI.bi"

Dim Shared KeyDown(SDLK_LAST) As Integer, KeyMod As SDLmod
Dim Shared As UInteger MouseX, MouseY, MouseState

Dim Shared As Integer ScreenW, ScreenH, IsFullScreen, ItIsQuitTime

Type VoxelEditor
    Dim As Vec3I HovV, PrevHovV(3), PPrevHovV, PanPosn, PanClick, CutPosn = Vec3I(-1,-1,-1)
    Dim As Vec3I V1, V2, ModelSize, ScCenter = Vec3I(16,16,16)*&H10000&
    Dim As UInteger HovCol, PanPlane, CutPlane
    Dim As Integer Focus = -1, BuildMode = -1, ClickIndex, CutSide
    Dim As Double ScDist
    Dim HitP As HitPlanes
    Dim ColSel As ColorSelectorRGB
    Dim BtnBar As ButtonBar
    Dim As Vox_Volume VolCopy, VolVoxBox
    
    Const FocusNone = -1
    Const FocusHovBox = 0
    Const FocusHitP = 1
    Const FocusButton = 2
    
    Declare Constructor()
    Declare Sub Render()
    Declare Function HitTest(X As Integer, Y As Integer, Dist As Double = -1) As Integer
    Declare Sub Hover(X As Integer, Y As Integer)
    
    Declare Sub LeftClick(X As Integer, Y As Integer)
    Declare Sub PushButton(BtnNum As Integer)
    
    Declare Sub ClearArtifacts
End Type

Sub DoBasicEvents(Event As SDL_Event)
    Select Case Event.Type
    Case SDL_KEYDOWN
        KeyDown(Event.key.keysym.sym) = -1
        KeyMod = Event.key.keysym.mod_
        If KeyDown(SDLK_LALT) Or KeyDown(SDLK_RALT) Then KeyMod Or= KMOD_ALT
        If KeyDown(SDLK_LCTRL) Or KeyDown(SDLK_RCTRL) Then KeyMod Or= KMOD_CTRL
        If KeyDown(SDLK_LSHIFT) Or KeyDown(SDLK_RSHIFT) Then KeyMod Or= KMOD_SHIFT
        Select Case Event.key.keysym.sym
        Case SDLK_RETURN
            If KeyMod And KMOD_ALT Then
                IsFullScreen = Not IsFullScreen
                Dim I As Integer
                For I = 0 To SDLK_LAST
                    KeyDown(I) = 0
                Next I
                KeyMod = 0
                SDL_QuitSubSystem SDL_INIT_VIDEO
                SDL_InitSubSystem SDL_INIT_VIDEO
                Dim As SDL_Surface Ptr Surf
                If IsFullScreen Then
                    Surf = SDL_SetVideoMode(ScreenW, ScreenH, 0, SDL_FULLSCREEN Or SDL_OPENGL)
                    If Surf = NULL Then Surf = SDL_SetVideoMode(ScreenW, ScreenH, 0, SDL_RESIZABLE Or SDL_OPENGL): IsFullScreen = Not IsFullScreen
                   Else
                    Surf = SDL_SetVideoMode(ScreenW, ScreenH, 0, SDL_RESIZABLE Or SDL_OPENGL)
                    If Surf = NULL Then Surf = SDL_SetVideoMode(ScreenW, ScreenH, 0, SDL_FULLSCREEN Or SDL_OPENGL): IsFullScreen = Not IsFullScreen
                End If
                If Surf = NULL Then
                    SDL_Quit
                    End 1
                End If
                ScreenW = Surf->w
                ScreenH = Surf->h
                VoxReloadVolumes
                VoxGlRenderState ScreenW, ScreenH, VOXEL_VIEWPORT_ONLY
            End If
        Case SDLK_ESCAPE
            ItIsQuitTime = -1
        End Select
    Case SDL_KEYUP
        KeyDown(Event.key.keysym.sym) = 0
        KeyMod = Event.key.keysym.mod_
        If KeyDown(SDLK_LALT) Or KeyDown(SDLK_RALT) Then KeyMod Or= KMOD_ALT
        If KeyDown(SDLK_LCTRL) Or KeyDown(SDLK_RCTRL) Then KeyMod Or= KMOD_CTRL
        If KeyDown(SDLK_LSHIFT) Or KeyDown(SDLK_RSHIFT) Then KeyMod Or= KMOD_SHIFT
    Case SDL_MOUSEMOTION
        MouseX = Event.motion.x
        MouseY = Event.motion.y
        'MouseState = Event.motion.state
    Case SDL_MOUSEBUTTONDOWN
        MouseState = SDL_GetMouseState(NULL, NULL)
    Case SDL_MOUSEBUTTONUP
        MouseState = SDL_GetMouseState(NULL, NULL)
    Case SDL_VIDEORESIZE
        ScreenW = Event.resize.w
        ScreenH = Event.resize.h
        VoxGlRenderState ScreenW, ScreenH, VOXEL_VIEWPORT_ONLY
    Case SDL_QUIT_
        ItIsQuitTime = -1
    End Select
End Sub

Sub SelectColor(CS As ColorSelectorRGB, BB As ButtonBar)
    Dim Event As SDL_Event
    Dim As Double T, dT, PrevT
    VoxSetContext CS.VC
    Do Until ItIsQuitTime
        
        CS.Render ScreenW, ScreenH
        BB.Render
        VoxSetContext CS.VC
        
        SDL_GL_SwapBuffers
        
        Do While SDL_PollEvent(@Event) <> 0
            Dim As Double Dist = -1
            Select Case Event.Type
            Case SDL_KEYDOWN
                Select Case Event.key.keysym.sym
                Case SDLK_2: BB.Down = 1: Exit Do, Do
                Case SDLK_3: BB.Down = 2: Exit Do, Do
                Case SDLK_4: BB.Down = 3: Exit Do, Do
                Case SDLK_5: BB.Down = 4: Exit Do, Do
                Case SDLK_6: BB.Down = 5: Exit Do, Do
                Case SDLK_7: BB.Down = 6: Exit Do, Do
                End Select
            Case SDL_MOUSEMOTION
                If Event.motion.state And SDL_BUTTON(3) Then
                    VoxScreenTurnRight (CInt(Event.motion.x) - MouseX) * 3/IIf(ScreenW<ScreenH, ScreenW, ScreenH) '/ 200.0
                    VoxScreenTurnDown (CInt(Event.motion.y) - MouseY) * 3/IIf(ScreenW<ScreenH, ScreenW, ScreenH) '/ 200.0
                End If
                If Event.motion.state And SDL_BUTTON(1) Then
                    CS.CursorMove CInt(Event.motion.x), CInt(Event.motion.y)
                End If
                If BB.HitTest(CInt(Event.motion.x), CInt(Event.motion.y), Dist) Then BB.Hover CInt(Event.motion.x), CInt(Event.motion.y)
                VoxSetContext CS.VC
            Case SDL_MOUSEBUTTONDOWN
                Select Case Event.button.button
                Case SDL_BUTTON_LEFT, SDL_BUTTON_MIDDLE
                    If BB.HitTest(CInt(Event.motion.x), CInt(Event.motion.y), Dist) Then BB.Click CInt(Event.motion.x), CInt(Event.motion.y)
                    VoxSetContext CS.VC
                    If BB.Down = 2 Then BB.Down = 0
                    If BB.Down <> 0 Then Exit Do, Do
                    If CS.HitTest(CInt(Event.motion.x), CInt(Event.motion.y), Dist) Then CS.Click CInt(Event.motion.x), CInt(Event.motion.y)
                End Select
            Case SDL_MOUSEBUTTONUP
                If CS.HitTest(CInt(Event.motion.x), CInt(Event.motion.y)) Then CS.Hover CInt(Event.motion.x), CInt(Event.motion.y)
            End Select
            DoBasicEvents Event
        Loop
        
        T = Timer
        dT = T - PrevT
        PrevT = T
        If KeyDown(SDLK_RIGHT) Then VoxScreenTurnRight dT
        If KeyDown(SDLK_LEFT) Then VoxScreenTurnRight -dT
        If KeyDown(SDLK_DOWN) Then VoxScreenTurnDown dT
        If KeyDown(SDLK_UP) Then VoxScreenTurnDown -dT
    Loop
    VoxSetContext
End Sub

Sub RenderWireCube(V1 As Vec3I, V2 As Vec3I)
    'glEnable GL_LINE_SMOOTH
    'glHint GL_LINE_SMOOTH, GL_NICEST
    'glBlendFunc GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA
    'glEnable GL_BLEND
    glBegin GL_LINES
    glVertex3f V1.X, V1.Y, V1.Z: glVertex3f V1.X, V1.Y, V2.Z
    
    glVertex3f V1.X, V1.Y, V1.Z: glVertex3f V1.X, V1.Y, V1.Z
    glVertex3f V2.X, V1.Y, V1.Z: glVertex3f V2.X, V1.Y, V2.Z
    glVertex3f V1.X, V2.Y, V1.Z: glVertex3f V1.X, V2.Y, V2.Z
    glVertex3f V2.X, V2.Y, V1.Z: glVertex3f V2.X, V2.Y, V2.Z
    
    glVertex3f V1.X, V1.Y, V1.Z: glVertex3f V1.X, V2.Y, V1.Z
    glVertex3f V2.X, V1.Y, V1.Z: glVertex3f V2.X, V2.Y, V1.Z
    glVertex3f V1.X, V1.Y, V2.Z: glVertex3f V1.X, V2.Y, V2.Z
    glVertex3f V2.X, V1.Y, V2.Z: glVertex3f V2.X, V2.Y, V2.Z
    
    glVertex3f V1.X, V1.Y, V1.Z: glVertex3f V2.X, V1.Y, V1.Z
    glVertex3f V1.X, V2.Y, V1.Z: glVertex3f V2.X, V2.Y, V1.Z
    glVertex3f V1.X, V1.Y, V2.Z: glVertex3f V2.X, V1.Y, V2.Z
    glVertex3f V1.X, V2.Y, V2.Z: glVertex3f V2.X, V2.Y, V2.Z
    glEnd
    'glDisable GL_BLEND
    'glDisable GL_LINE_SMOOTH
End Sub

Sub CopyVolume(Src As Vox_Volume, Dest As Vox_Volume)
    VoxSetVolume Dest
    VoxSetSource Src
    VoxSetBlitDefault
    VoxBlit Vec3I(0,0,0), Vec3I(0,0,0), VoxGetVolumeSize(Src)
End Sub

Constructor VoxelEditor
    ModelSize = VoxGetVolumeSize(VOXEL_SCREEN)
    VolCopy = VoxNewVolume(ModelSize, Volume_Offscreen)
    ColSel.SetColor RGB(255, 7, 7)
    
    VolVoxBox = VoxNewVolume(4, 4, 4)
    VoxSetColor ColSel.SelColor
    DrawCubeEdges Vec3I(0, 0, 0), Vec3I(3, 3, 3)
    
    ChDir ExePath
    BtnBar.VolButtons = VoxLoadFile("Buttons.png", Volume_Dynamic)
    BtnBar.ButtonSize = Vec3I(8,8,8)
    BtnBar.NumButtons = 7
    BtnBar.Down = 3
    
    Dim Max As Integer = ModelSize.X
    If ModelSize.Y > Max Then Max = ModelSize.Y
    If ModelSize.Z > Max Then Max = ModelSize.Z
    ScDist = (ModelSize.X+ModelSize.Y+ModelSize.Z+Max)/2
    ScCenter = ModelSize*&H10000&\2
End Constructor

Sub VoxelEditor.Render()
    VoxGlRenderState 0, 0, VOXEL_NOCLEAR
    If CutPlane = 0 Or BtnBar.Down = 6 Then
        VoxRenderVolume VOXEL_SCREEN
       Else
        If CutSide = 1 Then
            VoxRenderSubVolume VOXEL_SCREEN, Vec3I(0,0,0), CutPosn-Vec3I(1,1,1)
           Else
            VoxRenderSubVolume VOXEL_SCREEN, CutPosn, ModelSize-Vec3I(1,1,1)
        End If
    End If
    
    If Focus = FocusHovBox And HovV <> Vec3I(-1,-1,-1) Then
        glEnable GL_RESCALE_NORMAL
        glScaled 0.25, 0.25, 0.25
        glTranslated HovV.X*4, HovV.Y*4, HovV.Z*4
        VoxRenderVolume VolVoxBox
        glTranslated -HovV.X*4, -HovV.Y*4, -HovV.Z*4
        glDisable GL_RESCALE_NORMAL
    End If
    
    HitP.Render ScreenW, ScreenH
    
    glDisable GL_LIGHTING
    glColor4ub 255, 255, 0, 255
    If CutPlane <> 0 Then
        If CutSide = 1 Then
            RenderWireCube Vec3I(0,0,0), CutPosn
           Else
            RenderWireCube CutPosn, ModelSize
        End If
    End If
    
    glColor4ub 255, 255, 255, 255
    RenderWireCube Vec3I(0,0,0), ModelSize
    
    BtnBar.Render
End Sub

Function VoxelEditor.HitTest(X As Integer, Y As Integer, Dist As Double = -1) As Integer
    ClearArtifacts
    VoxSetVolume VOXEL_SCREEN
    Focus = FocusNone
    VoxGlRenderState 0, 0, VOXEL_MODELVIEW
    If CutPlane = 0 Or BtnBar.Down = 6 Then
        If VoxCursorTest(V1, V2, X, Y, Dist) Then Focus = FocusHovBox
       Else
        If CutSide = 1 Then
            If VoxSubCursorTest(V1, V2, Vec3I(0,0,0), CutPosn-Vec3I(1,1,1), X, Y, Dist) Then Focus = FocusHovBox
           Else
            If VoxSubCursorTest(V1, V2, CutPosn, ModelSize-Vec3I(1,1,1), X, Y, Dist) Then Focus = FocusHovBox
        End If
    End If
    If HitP.HitTestPlanes(V1, V2, X, Y, Dist) <> 0 Then Focus = FocusHovBox
    If HitP.HitTest(X, Y, Dist) Then Focus = FocusHitP
    If BtnBar.HitTest(X, Y) Then Focus = FocusButton
    Return Focus <> FocusNone
End Function

Sub VoxelEditor.Hover(X As Integer, Y As Integer)
    If Focus = FocusHitP Then HitP.Hover X, Y
    If Focus = FocusButton Then BtnBar.Hover X, Y
    
    If Focus = FocusHovBox Then
        If BuildMode And BtnBar.Down <> 1 And BtnBar.Down <> 6  And ColSel.SelColor <> 0 Then
            HovV = V2
           Else
            HovV = V1
        End If
        VoxSetVolume VOXEL_SCREEN
        HovCol = VoxPoint(HovV)
        If ClickIndex > 0 Then
            VoxSetColor ColSel.SelColor
            Select Case BtnBar.Down
            Case 4 'Line
                VoxLine HovV, PrevHovV(0)
            Case 5 'Triangle
                If ClickIndex = 1 Then
                    VoxLine HovV, PrevHovV(0)
                   Else
                    VoxTriangle HovV, PrevHovV(0), PrevHovV(1)
                End If
            End Select
        End If
        VSet HovV, 0
        
        VoxSetVolume VolVoxBox
        VoxSetColor HovCol
        DrawCubeEdges Vec3I(1, 1, 1), Vec3I(2, 2, 2)
    End If
End Sub

Sub VoxelEditor.LeftClick(X As Integer, Y As Integer)
    If Focus = FocusHovBox Then
        Select Case BtnBar.Down
        Case 1 'Pick Color
            ColSel.SetColor HovCol
            VoxSetVolume VolVoxBox
            VoxSetColor HovCol
            DrawCubeEdges Vec3I(0, 0, 0), Vec3I(3, 3, 3)
        Case 3 'VSet
            HovCol = ColSel.SelColor
            'VSet HovV, ColSel.SelColor
            If HitTest(X, Y) Then Hover X, Y
        Case 4 'Line
            If ClickIndex = 0 Then
                ClearArtifacts
                CopyVolume VOXEL_SCREEN, VolCopy
            End If
            PrevHovV(ClickIndex) = HovV
            ClickIndex += 1
            If ClickIndex = 2 Then
                ClickIndex = 0
                HovCol = ColSel.SelColor
                VoxSetVolume VOXEL_SCREEN
                VoxSetColor HovCol
                VoxLine HovV, PrevHovV(0)
                VSet HovV, 0
                If HitTest(X, Y) Then Hover X, Y
            End If
        Case 5 'Triangle
            If ClickIndex = 0 Then
                ClearArtifacts
                CopyVolume VOXEL_SCREEN, VolCopy
            End If
            PrevHovV(ClickIndex) = HovV
            PrevHovV(ClickIndex+1) = HovV
            ClickIndex += 1
            If ClickIndex = 3 Then
                ClickIndex = 0
                HovCol = ColSel.SelColor
                VoxSetVolume VOXEL_SCREEN
                VoxSetColor HovCol
                VoxTriangle HovV, PrevHovV(0), PrevHovV(1)
                VSet HovV, 0
                If HitTest(X, Y) Then Hover X, Y
            End If
        Case 6 'CutPlane
            Dim As Vec3I OldPosn = CutPosn
            CutSide = (V2-V1)* Vec3I(1,1,1)
            If CutSide < 0 Then
                CutPosn = Vec3I(0,0,0)
               Else
                CutPosn = HitP.Size
            End If
            If V2.X-V1.X <> 0 Then CutPlane = VOXEL_AXIS_X: CutPosn.X = V1.X+IIf(CutSide = 1, 1, 0)
            If V2.Y-V1.Y <> 0 Then CutPlane = VOXEL_AXIS_Y: CutPosn.Y = V1.Y+IIf(CutSide = 1, 1, 0)
            If V2.Z-V1.Z <> 0 Then CutPlane = VOXEL_AXIS_Z: CutPosn.Z = V1.Z+IIf(CutSide = 1, 1, 0)
            If OldPosn = CutPosn Then CutPlane = 0: CutPosn = Vec3I(-1,-1,-1)
        End Select
    End If
    
    If Focus = FocusButton Then
        Dim As Integer PrvDown = BtnBar.Down
        BtnBar.Click X, Y
        PushButton BtnBar.Down
        If BtnBar.Down = 2 Then BtnBar.Down = PrvDown
    End If
    
    If Focus = FocusHitP Then HitP.Click X, Y
End Sub

Sub VoxelEditor.PushButton(BtnNum As Integer)
    Select Case BtnNum
    Case 0
        ClearArtifacts
        ClickIndex = 0
        BtnBar.Down = 0
        SelectColor ColSel, BtnBar
        VoxSetVolume VolVoxBox
        VoxSetColor ColSel.SelColor
        DrawCubeEdges Vec3I(0, 0, 0), Vec3I(3, 3, 3)
        Focus = FocusNone
        BtnBar.NoHov = -1
    Case 2
        BuildMode = Not BuildMode
        VoxSetVolume BtnBar.VolButtons
        If BuildMode Then
            VoxSetColor RGB(255, 0, 0)
            DrawCubeEdges Vec3I(34,2,4), Vec3I(37,5,7)
            VoxSetColor RGB(255, 255, 0)
            DrawGrid Vec3I(34,2,0), Vec3I(37,5,3),1
           Else
            VoxSetColor 0
            DrawCubeEdges Vec3I(34,2,4), Vec3I(37,5,7)
            DrawGrid Vec3I(34,2,0), Vec3I(37,5,3), 1
            VoxSetColor RGB(255, 0, 0)
            DrawCubeEdges Vec3I(34,2,0), Vec3I(37,5,3)
            VoxSetColor RGB(255, 255, 0)
            DrawCubeEdges Vec3I(35,3,1), Vec3I(36,4,2)
        End If
    Case Else
        BtnBar.Down = BtnNum
        ClearArtifacts
        ClickIndex = 0
    End Select
End Sub

Sub VoxelEditor.ClearArtifacts
    VoxSetVolume VOXEL_SCREEN
    If Focus = FocusHovBox Then VSet HovV, HovCol
    If ClickIndex > 0 Then
        If BtnBar.Down=4 Or (BtnBar.Down=5 And ClickIndex = 1) Then
            'Redraw the line using Data from VolCopy
            '(eventually this will be doable via a textured line)
            Dim As Vec3I V = HovV - PrevHovV(0)
            Dim Max As Integer = Abs(V.X)
            If Abs(V.Y) > Max Then Max = Abs(V.Y)
            If Abs(V.Z) > Max Then Max = Abs(V.Z)
            For T As Integer = 0 To 2*Max - 2
                V = (HovV*T + PrevHovV(0)*(2*Max-T) + 3*Vec3I(Max, Max, Max))\(2*Max) - Vec3I(1, 1, 1)
                VoxSetVolume VolCopy: VoxSetColor VoxPoint(V)
                VoxSetVolume VOXEL_SCREEN: VSet V
            Next T
            VoxSetVolume VolCopy: VoxSetColor VoxPoint(HovV)
            VoxSetVolume VOXEL_SCREEN: VSet HovV
           Else
            If BtnBar.Down=5 Then CopyVolume VolCopy, VOXEL_SCREEN 'Erase the Triangle the slow way
        End If
    End If
End Sub




' >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
' Entry Point
' <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
Scope
    Dim Event As SDL_Event
    Dim As String FileName
    
    ScreenW = 800: ScreenH = 600
    
    If SDL_Init(SDL_INIT_VIDEO Or SDL_INIT_TIMER) <> 0 Then End 1
    
    SDL_SetVideoMode(ScreenW, ScreenH, 0, SDL_RESIZABLE Or SDL_OPENGL)
    
    VoxInit @SDL_GL_GetProcAddress
    
    If FileExists(Command) Then
        FileName = Command 'Load file specified by the command line
        Var Temp = VoxLoadFile(Command)
        VoxScreenRes VoxGetVolumeSize
        VoxSetVolume VOXEL_SCREEN
        VoxSetSource Temp
        VoxBlit Vec3I(0,0,0), Vec3I(0,0,0), VoxGetVolumeSize
        VoxSetVolume Temp
        VoxSizeVolume Vec3I(0,0,0)
        VoxSetVolume VOXEL_SCREEN
       Else
        FileName = "Untitled.png"
        VoxScreenRes 32, 32, 32
    End If
    
    Dim VE As VoxelEditor
    
    SDL_WM_SetCaption VE.ModelSize & " " & FileName, ""
    
    'Main message loop
    Dim As Double PrevT = Timer, dT = 0.1, T = Timer
    Do Until ItIsQuitTime
        
        VoxGlRenderState ScreenW, ScreenH, VOXEL_CLEAR
        VE.Render
        
        If MouseState And (SDL_BUTTON(3) Or SDL_BUTTON(2)) Then
            VoxGlRenderState 0, 0, VOXEL_MODELVIEW 'Draw rotation axies
            glDisable GL_LIGHTING
            glColor4ub 255, 255, 0, 255
            glBegin GL_LINES
            glVertex3f VE.ScCenter.X/&H10000-1, VE.ScCenter.Y/&H10000, VE.ScCenter.Z/&H10000: glVertex3f VE.ScCenter.X/&H10000+1, VE.ScCenter.Y/&H10000, VE.ScCenter.Z/&H10000
            glVertex3f VE.ScCenter.X/&H10000, VE.ScCenter.Y/&H10000-1, VE.ScCenter.Z/&H10000: glVertex3f VE.ScCenter.X/&H10000, VE.ScCenter.Y/&H10000+1, VE.ScCenter.Z/&H10000
            glVertex3f VE.ScCenter.X/&H10000, VE.ScCenter.Y/&H10000, VE.ScCenter.Z/&H10000-1: glVertex3f VE.ScCenter.X/&H10000, VE.ScCenter.Y/&H10000, VE.ScCenter.Z/&H10000+1
            glEnd
            If VE.Focus = VE.FocusHovBox Then
                glColor4ub 0, 255, 255, 255
                glBegin GL_LINES
                glVertex3f VE.HovV.X+0.5-1, VE.HovV.Y+0.5, VE.HovV.Z+0.5: glVertex3f VE.HovV.X+0.5+1, VE.HovV.Y+0.5, VE.HovV.Z+0.5
                glVertex3f VE.HovV.X+0.5, VE.HovV.Y+0.5-1, VE.HovV.Z+0.5: glVertex3f VE.HovV.X+0.5, VE.HovV.Y+0.5+1, VE.HovV.Z+0.5
                glVertex3f VE.HovV.X+0.5, VE.HovV.Y+0.5, VE.HovV.Z+0.5-1: glVertex3f VE.HovV.X+0.5, VE.HovV.Y+0.5, VE.HovV.Z+0.5+1
                glEnd
            End If
        End If
        
        If VE.Focus = VE.FocusHovBox And VE.HovV <> Vec3I(-1,-1,-1) Then
            SDL_WM_SetCaption VE.ModelSize & " " & FileName & " " & VE.HovV, ""
           Else
            SDL_WM_SetCaption VE.ModelSize & " " & FileName, ""
        End If
        
        SDL_GL_SwapBuffers
        
        Do While SDL_PollEvent(@Event) <> 0
            Select Case Event.Type
            Case SDL_KEYDOWN
                Select Case Event.key.keysym.sym
                Case SDLK_1: VE.PushButton 0
                Case SDLK_2: VE.PushButton 1
                Case SDLK_3: VE.PushButton 2
                Case SDLK_4: VE.PushButton 3
                Case SDLK_5: VE.PushButton 4
                Case SDLK_6: VE.PushButton 5
                Case SDLK_7: VE.PushButton 6
                Case SDLK_RETURN  'Resize the volume
                    If KeyMod = 0 And VE.HitP.Size <> VE.ModelSize Then
                        CopyVolume VOXEL_SCREEN, VE.VolCopy
                        VoxScreenRes VE.HitP.Size
                        CopyVolume VE.VolCopy, VOXEL_SCREEN 
                        VE.ModelSize = VE.HitP.Size
                        VoxSetVolume VE.VolCopy
                        VoxSizeVolume VE.ModelSize
                        SDL_WM_SetCaption VE.ModelSize & " " & FileName, ""
                        Dim Max As Integer = VE.ModelSize.X
                        If VE.ModelSize.Y > Max Then Max = VE.ModelSize.Y
                        If VE.ModelSize.Z > Max Then Max = VE.ModelSize.Z
                        VE.ScDist = (VE.ModelSize.X+VE.ModelSize.Y+VE.ModelSize.Z+Max)/2
                        VE.ScCenter = VE.ModelSize*&H10000&\2
                    End If
                End Select
            Case SDL_MOUSEMOTION
                If Event.motion.state And SDL_BUTTON(3) Then
                    If VE.Focus = VE.FocusHovBox Then
                        Dim As Vec3I L, U, F 'Rotate about the selected voxel
                        VoxGetScreenCamera L, U, F
                        Dim As Vec3L16 V=VE.ScCenter, MidP = (VE.HovV*&H10000+Vec3I(&H10000,&H10000,&H10000)\2)
                        Dim As Double Angle = (CInt(Event.motion.x) - MouseX) * 4/IIf(ScreenW<ScreenH, ScreenW, ScreenH)
                        AxisRotate3D V, MidP, U, Cos(Angle)*&H10000, Sin(Angle)*&H10000
                        VoxScreenTurnRight Angle
                        Angle = (CInt(Event.motion.y) - MouseY) * 4/IIf(ScreenW<ScreenH, ScreenW, ScreenH)
                        AxisRotate3D V, MidP, L, Cos(Angle)*&H10000, Sin(Angle)*&H10000
                        VoxScreenTurnDown Angle
                        
                        VE.ScCenter = Vec3I(V.X, V.Y, V.Z)
                        VoxScreenCenter VE.ScCenter.X/&H10000, VE.ScCenter.Y/&H10000, VE.ScCenter.Z/&H10000
                       Else 'Rotate about the perspective center point
                        VoxScreenTurnRight (CInt(Event.motion.x) - MouseX) * 3/IIf(ScreenW<ScreenH, ScreenW, ScreenH)
                        VoxScreenTurnDown (CInt(Event.motion.y) - MouseY) * 3/IIf(ScreenW<ScreenH, ScreenW, ScreenH)
                    End If
                   Else
                    If Event.motion.state And SDL_BUTTON(2) Then
                        If VE.Focus = VE.FocusHovBox And VE.PanPlane <> 0 Then  'Calculate the panning translation
                            Dim As Double VX = VE.PanClick.X/&H10000, VY = VE.PanClick.Y/&H10000, VZ = VE.PanClick.Z/&H10000
                            VoxGlRenderState 0, 0, VOXEL_MODELVIEW
                            glTranslated -VE.PanPosn.X/&H10000, -VE.PanPosn.Y/&H10000, -VE.PanPosn.Z/&H10000
                            glTranslated VE.ScCenter.X/&H10000, VE.ScCenter.Y/&H10000, VE.ScCenter.Z/&H10000
                            If VoxWallTest(VX, VY, VZ, VE.PanPlane, CInt(Event.motion.x), CInt(Event.motion.y)) Then
                                Select Case VE.PanPlane
                                Case VOXEL_AXIS_X: VX = VE.HovV.X
                                Case VOXEL_AXIS_Y: VY = VE.HovV.Y
                                Case VOXEL_AXIS_Z: VZ = VE.HovV.Z
                                End Select
                                VE.ScCenter = VE.PanPosn + (VE.PanClick-Vec3I(VX*&H10000&, VY*&H10000&, VZ*&H10000&))
                                VoxScreenCenter VE.ScCenter.X/&H10000, VE.ScCenter.Y/&H10000, VE.ScCenter.Z/&H10000
                            End If
                        End If
                       Else
                        If Event.motion.state And SDL_BUTTON(1) Then
                            If VE.Focus = VE.FocusHitP Then
                                VE.HitP.CursorMove CInt(Event.motion.x), CInt(Event.motion.y)
                            End If
                            If VE.Focus = VE.FocusHovBox And VE.BtnBar.Down = 3 Then 'And (VE.BuildMode = 0 Or VE.ColSel.SelColor = 0) Then
                                Dim As Double Dist = -1 'Draw on surface when left button is down
                                Dim As Vec3I V1 = Vec3I(-1,-1,-1), V2 = Vec3I(-1,-1,-1)
                                VoxSetVolume VOXEL_SCREEN
                                VSet VE.HovV, VE.HovCol
                                VoxGlRenderState 0, 0, VOXEL_MODELVIEW
                                If VE.CutPlane = 0 Or VE.BtnBar.Down = 6 Then
                                    VoxCursorTest V1, V2, CInt(Event.motion.x), CInt(Event.motion.y), Dist
                                   Else
                                    If VE.CutSide = 1 Then
                                        VoxSubCursorTest V1, V2, Vec3I(0,0,0), VE.CutPosn-Vec3I(1,1,1), CInt(Event.motion.x), CInt(Event.motion.y), Dist
                                       Else
                                        VoxSubCursorTest V1, V2, VE.CutPosn, VE.ModelSize-Vec3I(1,1,1), CInt(Event.motion.x), CInt(Event.motion.y), Dist
                                    End If
                                End If
                                VE.HitP.HitTestPlanes V1, V2, CInt(Event.motion.x), CInt(Event.motion.y), Dist
                                VoxSetVolume VOXEL_SCREEN
                                If VE.BuildMode = 0 Or VE.ColSel.SelColor = 0 Then
                                    VE.HovV = V1
                                    VE.HovCol = VE.ColSel.SelColor
                                   Else
                                    VE.HovV = V2
                                    VE.HovCol = VoxPoint(VE.HovV)
                                End If
                                VSet VE.HovV, 0
                            End If
                           Else
                            If VE.HitTest(CInt(Event.motion.x), CInt(Event.motion.y)) Then VE.Hover CInt(Event.motion.x), CInt(Event.motion.y)
                        End If
                    End If
                End If
            Case SDL_MOUSEBUTTONDOWN
                Select Case Event.button.button
                Case SDL_BUTTON_LEFT
                    VE.LeftClick CInt(Event.button.x), CInt(Event.button.y)
                Case SDL_BUTTON_MIDDLE
                    If VE.Focus = VE.FocusHovBox Then
                        Dim As Double Dist 'Initialize Panning, by fixing position and determining axis
                        Dist = -1
                        
                        If VE.V2.X-VE.V1.X <> 0 Then VE.PanPlane = VOXEL_AXIS_X
                        If VE.V2.Y-VE.V1.Y <> 0 Then VE.PanPlane = VOXEL_AXIS_Y
                        If VE.V2.Z-VE.V1.Z <> 0 Then VE.PanPlane = VOXEL_AXIS_Z
                        
                        VE.PanPosn = VE.ScCenter
                        Dim As Double VX = VE.HovV.X, VY = VE.HovV.Y, VZ = VE.HovV.Z
                        VoxGlRenderState 0, 0, VOXEL_MODELVIEW
                        VoxWallTest VX, VY, VZ, VE.PanPlane, CInt(Event.button.x), CInt(Event.button.y)
                        Select Case VE.PanPlane
                        Case VOXEL_AXIS_X: VX = VE.HovV.X
                        Case VOXEL_AXIS_Y: VY = VE.HovV.Y
                        Case VOXEL_AXIS_Z: VZ = VE.HovV.Z
                        End Select
                        VE.PanClick = Vec3I(VX*&H10000&, VY*&H10000&, VZ*&H10000&)
                    End If
                Case SDL_BUTTON_RIGHT
                Case SDL_BUTTON_WHEELUP 'Zoom in/out
                    If VE.Focus = VE.FocusHovBox Then
                        Dim V As Vec3I = (VE.HovV*&H10000 - VE.ScCenter) \ (VE.ScDist*&H100)
                        VE.ScDist /= 1.1
                        VE.ScCenter = VE.HovV*&H10000 - V*(VE.ScDist*&H100)
                        VoxScreenDistance VE.ScDist
                        VoxScreenCenter VE.ScCenter.X/&H10000, VE.ScCenter.Y/&H10000, VE.ScCenter.Z/&H10000
                    End If
                Case SDL_BUTTON_WHEELDOWN
                    If VE.Focus = VE.FocusHovBox Then
                        Dim V As Vec3I = (VE.HovV*&H10000 - VE.ScCenter) \ (VE.ScDist*&H100)
                        VE.ScDist *= 1.1
                        VE.ScCenter = VE.HovV*&H10000 - V*(VE.ScDist*&H100)
                        VoxScreenDistance VE.ScDist
                        VoxScreenCenter VE.ScCenter.X/&H10000, VE.ScCenter.Y/&H10000, VE.ScCenter.Z/&H10000
                    End If
                End Select
            Case SDL_MOUSEBUTTONUP
                Select Case Event.button.button
                Case SDL_BUTTON_LEFT
                Case SDL_BUTTON_MIDDLE
                    VE.PanPlane = 0
                End Select
                If VE.HitTest(CInt(Event.motion.x), CInt(Event.motion.y)) Then VE.Hover CInt(Event.motion.x), CInt(Event.motion.y)
            End Select
            DoBasicEvents Event
        Loop
        
        T = Timer
        dT = T - PrevT
        PrevT = T
        If KeyDown(SDLK_RIGHT) Then VoxScreenTurnRight dT
        If KeyDown(SDLK_LEFT) Then VoxScreenTurnRight -dT
        If KeyDown(SDLK_DOWN) Then VoxScreenTurnDown dT
        If KeyDown(SDLK_UP) Then VoxScreenTurnDown -dT
    Loop
    SDL_Quit
    VoxSaveFile FileName, VOXEL_SCREEN
End Scope