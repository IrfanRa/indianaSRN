
' ********** Copyright 2020 Roku Corp.  All Rights Reserved. **********

' entry point of  MainScene
' Note that we need to import this file in MainScene.xml using relative path.
sub Init()
    ' Set background color for scene. Applied only if backgroundUri has empty value
    m.top.backgroundColor = "0x800020"
    m.top.backgroundUri = "pkg:/images/background_image.png"

    m.loadingIndicator = m.top.FindNode("loadingIndicator") ' Store loadingIndicator node to m

    ' Access the custom global node
    m.global = m.top.FindNode("globalNode")

    ' Now m.global is a Node where we can add fields
    ' To handle Roku Pay we need to create channelStore object in the global node
    m.global.AddField("channelStore", "node", false)
    m.global.channelStore = CreateObject("roSGNode", "ChannelStore")

    ' Initialize Segment Analytics
    task = m.top.FindNode("segmentAnalyticsTask")
    m.library = SegmentAnalyticsConnector(task)

    config = GetSegmentConfig()
    m.library.init(config)

    ' Play the splash video before showing the main content
    playSplashVideo()
end sub

function playSplashVideo() as Void
    videoPlayer = CreateObject("roSGNode", "Video")
    videoContent = CreateObject("roSGNode", "ContentNode")

    videoContent.url = "pkg:/images/splash.mp4" ' Path to your splash video
    videoContent.streamFormat = "mp4"

    videoPlayer.content = videoContent
    videoPlayer.control = "play"
    videoPlayer.observeField("state", "onVideoStateChange")
    m.top.appendChild(videoPlayer)
end function

sub onVideoStateChange(event as Object)
    state = event.getData()
    if state = "finished" or state = "error"
        m.top.removeChild(event.getRoSGNode())
        ' Continue with app initialization here if needed
        showMainContent()
    end if
end sub

sub showMainContent()
    ' Now that the splash video has finished, display the main content
    m.loadingIndicator.visible = true
    InitScreenStack()
    ShowGridScreen()
    RunContentTask()
    m.top.SignalBeacon("AppDialogInitiate")
    m.top.SignalBeacon("AppDialogComplete")
    m.top.SignalBeacon("AppLaunchComplete")
end sub

' The OnKeyEvent() function receives remote control key events
function OnkeyEvent(key as String, press as Boolean) as Boolean
    result = false
    if press
        ' handle "back" key press
        if key = "back"
            numberOfScreens = m.screenStack.Count()
            ' close top screen if there are two or more screens in the screen stack
            if numberOfScreens > 1
                CloseScreen(invalid)
                result = true
            end if
        end if
    end if
    ' The OnKeyEvent() function must return true if the component handled the event,
    ' or false if it did not handle the event.
    return result
end function
