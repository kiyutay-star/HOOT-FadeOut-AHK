#Requires AutoHotkey v2.0
#SingleInstance Force


;========================
; F11 フェードアウト開始
;========================

F11::
{
    pid := ProcessExist("hoot.exe")

    if !pid
    {
        MsgBox "HOOTが起動していません"
        return
    }


    volume := GetHootVolume(pid)


    if (volume = -1)
    {
        MsgBox "HOOTの音量セッションが見つかりません"
        return
    }



    ;------------------------
    ; 約7秒フェード設定
    ;------------------------

    time1 := 2500     ; 100→40
    time2 := 2000     ; 40→20
    time3 := 2500     ; 20→0

    step1 := 25
    step2 := 20
    step3 := 25



    ;------------------------
    ; 100→40％
    ;------------------------

    Loop step1
    {
        volume -= 60 / step1

        if volume < 40
            volume := 40


        SetHootVolume(pid, volume)

        Sleep time1 / step1
    }



    ;------------------------
    ; 40→20％
    ;------------------------

    Loop step2
    {
        volume -= 20 / step2

        if volume < 20
            volume := 20


        SetHootVolume(pid, volume)

        Sleep time2 / step2
    }



    ;------------------------
    ; 20→0％
    ;------------------------

    Loop step3
    {
        volume -= 20 / step3

        if volume < 0
            volume := 0


        SetHootVolume(pid, volume)

        Sleep time3 / step3
    }



    ;------------------------
    ; HOOTへPキー送信
    ;------------------------

    Sleep 200


    ; 通常送信
    Send "{p}"



    ; HOOTへ直接送信
    hwnd := WinExist("ahk_exe hoot.exe")


    if hwnd
    {
        PostMessage(
            0x100,
            0x50,
            0,
            ,
            hwnd
        )


        Sleep 50


        PostMessage(
            0x101,
            0x50,
            0,
            ,
            hwnd
        )
    }



    ;------------------------
    ; 1.5秒後 音量100％
    ;------------------------

    Sleep 1500


    SetHootVolume(pid,100)
}




;========================
; F12 AHK終了
;========================

F12::
{
    ExitApp
}





GetHootVolume(pid)
{
    audio := FindHootSession(pid)

    if !audio
        return -1


    ComCall(
        4,
        audio,
        "float*",
        &vol := 0
    )


    return vol * 100
}





SetHootVolume(pid, vol)
{
    audio := FindHootSession(pid)

    if !audio
        return


    ComCall(
        3,
        audio,
        "float",
        vol / 100,
        "ptr",
        0
    )
}





FindHootSession(pid)
{
    enum :=
    ComObject(
        "{BCDE0395-E52F-467C-8E3D-C4579291692E}",
        "{A95664D2-9614-4F35-A746-DE8DB63617E6}"
    )



    device := 0


    ComCall(
        4,
        enum,
        "int",
        0,
        "int",
        1,
        "ptr*",
        &device
    )



    manager := 0


    ComCall(
        3,
        device,
        "ptr",
        Guid("{77AA99A0-1BD6-484F-8BC7-2C654C9A9B6F}"),
        "uint",
        23,
        "ptr",
        0,
        "ptr*",
        &manager
    )



    sessions := 0


    ComCall(
        5,
        manager,
        "ptr*",
        &sessions
    )



    count := 0


    ComCall(
        3,
        sessions,
        "int*",
        &count
    )



    Loop count
    {
        session := 0


        ComCall(
            4,
            sessions,
            "int",
            A_Index-1,
            "ptr*",
            &session
        )



        control :=
        ComObjQuery(
            session,
            "{bfb7ff88-7239-4fc9-8fa2-07c950be9c6d}"
        )



        if control
        {
            thisPid := 0


            ComCall(
                14,
                control,
                "uint*",
                &thisPid
            )



            if (thisPid = pid)
            {
                return ComObjQuery(
                    session,
                    "{87ce5498-68d6-44e5-9215-6da47ef883d8}"
                )
            }
        }
    }



    return 0
}





Guid(str)
{
    buf := Buffer(16)


    DllCall(
        "ole32\CLSIDFromString",
        "wstr",
        str,
        "ptr",
        buf
    )


    return buf
}