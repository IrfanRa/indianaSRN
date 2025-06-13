' ********** Copyright 2020 Roku Corp.  All Rights Reserved. **********

' Note that we need to import this file in MainLoaderTask.xml using relative path.
sub Init()
    ' set the name of the function in the Task node component to be executed when the state field changes to RUN
    ' in our case this method executed after the following cmd: m.contentTask.control = "run"(see Init method in MainScene)
    m.top.functionName = "GetContent"
end sub

sub GetContent()
    rootChildren = []
    xfer = CreateObject("roURLTransfer")
    xfer.SetCertificatesFile("common:/certs/ca-bundle.crt")
    xfer.SetURL("https://apps.blueframetech.com/api/v1/bft/indianasrn/config.json")
    configRsp = xfer.GetToString()
    configJson = ParseJson(configRsp)
    if configJson = invalid return

    siteIds = configJson.vCloud.siteIds
    layoutRows = configJson.layout.rows
    rowIndex = 0
    for each r in layoutRows
        if r.type = "broadcast"
            row = {}
            row.title = r.title
            row.children = []
            params = {
                site_id: siteIds[0],
                sort_by: r.broadcastSearchParams.sortBy,
                sort_dir: r.broadcastSearchParams.sortDir,
                viewer_status: r.broadcastSearchParams.viewerStatus
            }
            url = BuildSignedUrl(configJson.vCloud.domain, "api/client/broadcast", params, "OmeM0oQjSP2p8XCQZFfCAEstODF5mWZh", "ZXy58xgBecG{sV<~(yV<1N{?Ne#4Hqt?")
            xfer2 = CreateObject("roURLTransfer")
            xfer2.SetCertificatesFile("common:/certs/ca-bundle.crt")
            xfer2.SetURL(url)
            rsp = xfer2.GetToString()
            data = ParseJson(rsp)
            if data <> invalid and data.broadcasts <> invalid
                itemIndex = 0
                for each b in data.broadcasts
                    itemData = GetBroadcastItemData(b)
                    itemData.homeRowIndex = rowIndex
                    itemData.homeItemIndex = itemIndex
                    row.children.Push(itemData)
                    itemIndex++
                end for
            end if
            rootChildren.Push(row)
            rowIndex++
        end if
    end for

    contentNode = CreateObject("roSGNode", "ContentNode")
    contentNode.Update({children: rootChildren}, true)
    m.top.content = contentNode
end sub

function GetBroadcastItemData(b as object) as object
    item = {}
    item.title = b.title
    item.description = b.description
    item.hdPosterURL = b.large_image
    item.id = b.id
    item.releaseDate = b.date
    item.categories = [b.section_title]
    item.url = ExtractUrlFromEmbed(b.embed_code)
    item.streamFormat = "hls"
    return item
end function

function ExtractUrlFromEmbed(embed as String) as String
    if embed = invalid return ""
    start = Instr(embed, "src=")
    if start <= 0 return ""
    quote = Mid(embed, start+5, 1)
    rest = Mid(embed, start+6)
    finish = Instr(rest, quote)
    if finish > 0
        return Left(rest, finish-1)
    end if
    return ""
end function

function GetItemData(video as object) as object
    item = {}
    ' populate some standard content metadata fields to be displayed on the GridScreen
    ' https://developer.roku.com/docs/developer-program/getting-started/architecture/content-metadata.md
    if video.longDescription <> invalid
        item.description = video.longDescription
    else
        item.description = video.shortDescription
    end if
    item.hdPosterURL = video.thumbnail
    item.title = video.title
    item.releaseDate = video.releaseDate
    item.categories = video.genres
    item.id = video.id
    if video.episodeNumber <> invalid
        item.episodePosition = video.episodeNumber.ToStr()
    end if
    ' populate length of content to be displayed on the GridScreen
    if video.content <> invalid
        item.length = video.content.duration
        item.url = video.content.videos[0].url
        item.streamFormat = video.content.videos[0].videoType
    end if
    ' Include backgroundImageURL if present
    if video.backgroundImageURL <> invalid
        item.backgroundImageURL = video.backgroundImageURL
    end if
    return item
end function

function GetSeasonData(seasons as object, homeRowIndex as integer, homeItemIndex as integer, seriesId as string) as object
    seasonsArray = []
    if seasons <> invalid
        episodeCounter = 0
        for each season in seasons
            if season.episodes <> invalid
                episodes = []
                for each episode in season.episodes
                    episodeData = GetItemData(episode)
                    ' save season title for element to represent it on the episodes screen
                    episodeData.titleSeason = season.title
                    episodeData.numEpisodes = episodeCounter
                    episodeData.mediaType = "episode"
                    episodeData.homeRowIndex = homeRowIndex
                    episodeData.homeItemIndex = homeItemIndex
                    episodeData.seriesId = seriesId
                    episodes.Push(episodeData)
                    episodeCounter++
                end for
                seasonData = GetItemData(season)
                ' populate season's children field with its episodes
                ' as a result season's ContentNode will contain episode's nodes
                seasonData.children = episodes
                ' set content type for season object to represent it on the screen as section with episodes
                seasonData.contentType = "section"
                seasonsArray.Push(seasonData)
            end if
        end for
    end if
    return seasonsArray
end function
