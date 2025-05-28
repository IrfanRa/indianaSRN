' ********** PlayerTask.brs **********

' Include necessary libraries
Library "Roku_Ads.brs"

sub init()
    m.top.functionName = "PlayContentWithAds"   ' Function to run by task
    m.top.id = "PlayerTask"

    ' Initialize Segment Analytics
    config = GetSegmentConfig()

    if config = invalid
        print "Error: segmentConfig not found in global node."
        return
    end if

    ' Initialize SegmentAnalytics with config
    m.segmentAnalytics = SegmentAnalytics(config)
    ' Removed m.segmentAnalytics.init(config) to prevent the error
end sub

' Function to play content with ads
sub PlayContentWithAds()
    ' Get parent node for rendering
    parentNode = m.top.GetParent()
    content = m.top.content
    m.top.lastIndex = m.top.startIndex
    items = []

    if content.getChildCount() > 0
        items = content.getChildren(-1, 0)
    else
        items = [content]
    end if

    ' Initialize Roku Ads Framework (RAF)
    RAF = Roku_Ads()
    RAF.enableAdMeasurements(true)
    RAF.SetAdUrl("https://pubads.g.doubleclick.net/gampad/ads?iu=/22681234872/test_video_1&description_url=[placeholder]&tfcd=0&npa=0&sz=640x480&ciu_szs=1x1&gdfp_req=1&output=vast&unviewed_position_start=1&env=vp&impl=s&correlator=")
    
    bookmarks = MasterChannelBookmarks()
    smartBookmarks = MasterChannelSmartBookmarks()
    keepPlay = true
    index = m.top.startIndex - 1
    itemsCount = items.Count()

    ' Get device ID for tracking using roDeviceInfo
    deviceInfo = CreateObject("roDeviceInfo")
    uniqueId = deviceInfo.GetChannelClientId()

    if uniqueId = invalid or uniqueId = ""
        print "Error: Failed to retrieve Channel Client ID."
        uniqueId = "unknown_channel_client_id"
    end if

    while keepPlay
        ' Check if playlist isn't complete
        if itemsCount - 1 > index
            ' Give parentNode focus to handle "back" button key press during ads retrieving
            parentNode.SetFocus(true)
            index ++
            item = items[index] ' contentNode of the video which should be played next

            if index > m.top.startIndex
                item.bookmarkPosition = 0
            end if

            ' Content details used by RAF for ad targeting
            RAF.SetContentId(item.id)
            if item.categories <> invalid
                RAF.SetContentGenre(item.categories)
            end if
            RAF.SetContentLength(int(item.length)) ' in seconds

            adPods = RAF.GetAds() ' ads retrieving
            m.top.lastIndex = index ' save the index of last played item to navigate to appropriate detailsScreen

            ' Combine video and ads into a single playlist
            csasStream = RAF.constructStitchedStream(item, adPods)
            if m.top.isSeries = true
                smartBookmarks.UpdateSmartBookmarkForSeries(content.id, item.id)
            end if

            ' Make track call indicating video playback started
            eventName = "Video Playback Started"
            properties = {
                "title": item.title
                "contentId": item.id
                "mediaType": item.mediaType
                "position": csasStream.position
            }
            options = {
                "userId": uniqueId
            }
            m.segmentAnalytics.track(eventName, properties, options)

            ' Render the stitched stream
            keepPlay = RAF.renderStitchedStream(csasStream, parentNode)

            ' Make track call indicating video playback completed
            eventName = "Video Playback Completed"
            properties = {
                "title": item.title
                "contentId": item.id
                "mediaType": item.mediaType
                "position": csasStream.position
            }
            options = {
                "userId": uniqueId
            }
            m.segmentAnalytics.track(eventName, properties, options)
            
            if keepPlay = false
                bookmarks.UpdateBookmarkForVideo(item, csasStream.position)
            else
                bookmarks.RemoveBookmarkForVideo(item.id)
            end if
        else
            if m.top.isSeries = true
                smartBookmarks.RemoveSmartBookmarkForSeries(content.id)
            end if
            keepPlay = false
        end if
    end while
end sub
