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

--PASTE_AS_TAKES_IN_ITEMS = 40603
TAKE_IMPLODE_ITEMS_ACROSS_TRACKS_INTO_TAKES = 40438
--ITEM_REMOVE_ALL_EMPTY_TAKE_LANES = 41348
ITEM_SELECT_ALL_ITEMS_IN_TRACK = 40421
ITEM_UNSELECT_ALL_ITEMS = 40289
TRACK_UNSELECT_ALL_TRACKS = 40297

debug = false

function Msg(value)
    if debug then
        reaper.ShowConsoleMsg(tostring(value) .. "\n")
    end
end

function getTrackName(track)
    return ({reaper.GetSetMediaTrackInfo_String(track, 'P_NAME', '', 0 )})[2]
end


function selectTrackMediaItems(track)
    -- Select all media items in a track
    reaper.SetTrackSelected(track, 1)
    reaper.Main_OnCommandEx(ITEM_SELECT_ALL_ITEMS_IN_TRACK, 0, 0)
    Msg("    Select track: " .. getTrackName(track))
end

function createTakeLanes()
    Msg("    Create take lanes...")
    -- Now move the item into a take lane
    reaper.Main_OnCommandEx(TAKE_IMPLODE_ITEMS_ACROSS_TRACKS_INTO_TAKES, 0, 0)

    unselectAll()
end

function processLastTrack(current_track)
    -- Last track in the folder
    reaper.SetMediaTrackInfo_Value(current_track, "I_FOLDERDEPTH", -1)
    reaper.SetMediaTrackInfo_Value(current_track, "B_MUTE", 1)
    selectTrackMediaItems(current_track)

    createTakeLanes()
end

function unselectAll()
    reaper.Main_OnCommandEx(TRACK_UNSELECT_ALL_TRACKS, 0, 0)
    reaper.Main_OnCommandEx(ITEM_UNSELECT_ALL_ITEMS, 0, 0)
end

function main()
    parent_found = false

    unselectAll()

    for i = 0, reaper.CountTracks(0) - 1 do
        if not parent_found then
            parent_track = reaper.GetTrack(0, i)
            parent_track_name = getTrackName(parent_track)
        end

        current_track = reaper.GetTrack(0, i)
        current_track_name = getTrackName(current_track)
        next_track = reaper.GetTrack(0, i + 1)

        if next_track == nil then
            -- current_track is the last track
            if parent_found then
                processLastTrack(current_track)
            end
            break
        end

        next_track_name = getTrackName(next_track)

        if string.match(next_track_name, parent_track_name .. '.%d+') then
            Msg(tostring(i) .. "\t"  .. parent_track_name .. "\t" .. current_track_name .. "\t" .. next_track_name .. "\t1")

            if not parent_found then
                reaper.SetMediaTrackInfo_Value(current_track, "I_FOLDERDEPTH", 1)
                reaper.SetMediaTrackInfo_Value(next_track, "B_MUTE", 1)
                parent_found = true

                selectTrackMediaItems(current_track)
                selectTrackMediaItems(next_track)
            else
                reaper.SetMediaTrackInfo_Value(current_track, "B_MUTE", 1)
                selectTrackMediaItems(current_track)
                --reaper.SetMediaTrackInfo_Value(next_track, "B_MUTE", 1)
            end

        else
            Msg(tostring(i) .. "\t"  .. parent_track_name .. "\t"  .. current_track_name .. "\t" .. next_track_name .. "\t0")

            if parent_found then
                parent_found = false
                processLastTrack(current_track)
            end
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
