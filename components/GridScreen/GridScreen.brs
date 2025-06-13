' ********** Copyright 2020 Roku Corp.  All Rights Reserved. **********

' entry point of GridScreen
' Note that we need to import this file in GridScreen.xml using relative path.
sub Init()
    '-- main carousel
    m.rowList = m.top.FindNode("rowList")
    m.rowList.SetFocus(true)

    '-- text labels
    m.descriptionLabel = m.top.FindNode("descriptionLabel")
    m.titleLabel       = m.top.FindNode("titleLabel")

    '-- big preview poster
    m.previewPoster    = m.top.FindNode("previewPoster")
    m.previewPoster.observeField("loadStatus", "OnPreviewLoadStatus")

    '-- visibility / focus observers
    m.top.ObserveField("visible", "OnVisibleChange")
    m.rowList.ObserveField("rowItemFocused", "OnItemFocused")
end sub

sub OnVisibleChange() ' invoked when GridScreen change visibility
    if m.top.visible = true
        m.rowList.SetFocus(true) ' set focus to rowList if GridScreen visible
    end if
end sub

sub OnItemFocused() ' invoked when another item is focused
    focusedIndex = m.rowList.rowItemFocused ' get position of focused item
    row = m.rowList.content.GetChild(focusedIndex[0]) ' get all items of row
    item = row.GetChild(focusedIndex[1]) ' get focused item
    ' update description label with description of focused item
    m.descriptionLabel.text = item.description
    ' update title label with title of focused item
    m.titleLabel.text = item.title
    ' adding length of playback to the title if item length field was populated
    if item.length <> invalid and item.length <> 0
        m.titleLabel.text += " | " + GetTime(item.length)
    end if

    '-- update preview poster
    if item.hdPosterUrl <> invalid and item.hdPosterUrl <> ""
        m.previewPoster.uri     = item.hdPosterUrl
        m.previewPoster.visible = true
    else
        m.previewPoster.uri     = "pkg:/images/feed_too_large.jpg"  ' fallback image
        m.previewPoster.visible = true
    end if
end sub

sub OnPreviewLoadStatus(event as Object)
    if event.getData() = "failed"
        m.previewPoster.uri = "pkg:/images/feed_too_large.jpg"
    end if
end sub