' GridScreen.brs

sub Init()
    m.rowList = m.top.FindNode("rowList")
    m.rowList.SetFocus(true)
    ' label with item description
    m.descriptionLabel = m.top.FindNode("descriptionLabel")
    m.top.ObserveField("visible", "OnVisibleChange")
    ' label with item title
    m.titleLabel = m.top.FindNode("titleLabel")
    ' observe rowItemFocused so we can know when another item of rowList will be focused
    m.rowList.ObserveField("rowItemFocused", "OnItemFocused")
    ' find the backgroundImage node
    m.backgroundImage = m.top.FindNode("backgroundImage")
    ' Observe loadStatus to handle image loading errors
    m.backgroundImage.ObserveField("loadStatus", "OnBackgroundImageLoadStatusChanged")
    ' Observe when content is set on rowList
    m.rowList.ObserveField("content", "OnRowListContentSet")
    ' Remove the call to OnItemFocused() here
end sub

sub OnRowListContentSet()
    ' Now that content is set, we can initialize the background image
    OnItemFocused()
end sub

sub OnItemFocused() ' invoked when another item is focused
    if m.rowList.content = invalid or m.rowList.content.GetChildCount() = 0
        ' content not yet loaded or empty, do nothing
        return
    end if
    focusedIndex = m.rowList.rowItemFocused ' get position of focused item
    if focusedIndex = invalid or focusedIndex.Count() <> 2
        ' invalid focused index
        return
    end if
    row = m.rowList.content.GetChild(focusedIndex[0]) ' get all items of row
    if row = invalid
        return
    end if
    item = row.GetChild(focusedIndex[1]) ' get focused item
    if item = invalid
        return
    end if
    ' update description label with description of focused item
    m.descriptionLabel.text = item.description
    ' update title label with title of focused item
    m.titleLabel.text = item.title
    ' adding length of playback to the title if item length field was populated
    if item.length <> invalid and item.length <> 0
        m.titleLabel.text += " | " + GetTime(item.length)
    end if
    ' update background image
    if item.backgroundImageURL <> invalid and item.backgroundImageURL <> ""
        m.backgroundImage.uri = item.backgroundImageURL
    else
        ' set to default background image or clear the background
        m.backgroundImage.uri = ""  ' or set to a default image
    end if
end sub

sub OnVisibleChange() ' invoked when GridScreen change visibility
    if m.top.visible = true
        m.rowList.SetFocus(true) ' set focus to rowList if GridScreen visible
    end if
end sub

sub OnBackgroundImageLoadStatusChanged()
    status = m.backgroundImage.loadStatus
    if status = "failed"
        ' handle image load failure
        ' Optionally, set a default background image or clear the uri
        m.backgroundImage.uri = ""  ' clear the image
    end if
end sub
