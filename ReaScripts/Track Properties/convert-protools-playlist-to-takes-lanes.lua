-- @description Convert Protools Playlist tracks as exported from AATranslator to Reaper take lanes
-- @author alexhayes
-- @version 1.0
-- @link https://github.com/alexhayes/ReaScripts
-- @about
--   # AATranslator does not convert Protools Playlists to Take Lanes in Reaper
--   rather it will export a muted track and append .01 to the track name. This
--   script will sort those tracks into take lanes.
--   How to use:  > Select tracks that you want to reorganise > Run the script
-- @changelog
--    # Initial version

--[[ * Licence: GPL v3
 * REAPER: 5.70
 * Extensions: SWS 2.8.0
--]]

debug = true

function Msg(value)
    if debug then
        reaper.ShowConsoleMsg(tostring(value) .. "\n")
    end
end

function getTrackName(track)
    return ({reaper.GetSetMediaTrackInfo_String(track, 'P_NAME', '', 0 )})[2]
end


function main()
    parent_found = false

    for i = 0, reaper.CountTracks(0) - 1 do
        if not parent_found then
            parent_track = reaper.GetTrack(0, i)
            parent_track_name = getTrackName(parent_track)
        end

        current_track = reaper.GetTrack(0, i)
        current_track_name = getTrackName(current_track)
        next_track = reaper.GetTrack(0, i + 1)

        if next_track == nil then
            break
        end

        next_track_name = getTrackName(next_track)

        if string.match(next_track_name, parent_track_name .. '.%d+') then
            Msg(tostring(i) .. "\t"  .. parent_track_name .. "\t" .. current_track_name .. "\t" .. next_track_name .. "\t1")

            if not parent_found then
                reaper.SetMediaTrackInfo_Value(current_track, "I_FOLDERDEPTH", 1)
                reaper.SetMediaTrackInfo_Value(next_track, "B_MUTE", 1)
                parent_found = true
            else
                reaper.SetMediaTrackInfo_Value(current_track, "B_MUTE", 1)
            end
        else
            Msg(tostring(i) .. "\t"  .. parent_track_name .. "\t"  .. current_track_name .. "\t" .. next_track_name .. "\t0")
            parent_found = false

            -- This is the last child
            reaper.SetMediaTrackInfo_Value(current_track, "I_FOLDERDEPTH", -1)
            reaper.SetMediaTrackInfo_Value(current_track, "B_MUTE", 1)


            -- Now collapse the parent

        end
    end
end

reaper.ClearConsole()

-- RUN
count_tracks = reaper.CountTracks(0)

if count_tracks > 0 then
    reaper.PreventUIRefresh(1)
    reaper.Undo_BeginBlock()
    main()
    reaper.Undo_EndBlock('Convert Protools Playlist tracks', -1)
    reaper.TrackList_AdjustWindows(false)
    reaper.PreventUIRefresh(-1)
end
