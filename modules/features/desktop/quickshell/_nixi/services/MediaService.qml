pragma Singleton
import QtQuick
import Quickshell.Services.Mpris
import ".."

// One selection and control policy for every media presentation. Consumers
// choose `player` when paused media is useful or `playingPlayer` when it is not.
QtObject {
    id: root

    readonly property var players: Mpris.players.values
    readonly property var playingPlayer: {
        for (let i = 0; i < players.length; ++i) {
            if (players[i].playbackState === MprisPlaybackState.Playing)
                return players[i];
        }
        return null;
    }
    readonly property var player: {
        if (playingPlayer !== null)
            return playingPlayer;
        for (let i = 0; i < players.length; ++i) {
            if (players[i].trackTitle !== "")
                return players[i];
        }
        return players.length > 0 ? players[0] : null;
    }
    readonly property bool available: player !== null
    readonly property bool loopTrack: available && player.loopState === MprisLoopState.Track
    readonly property bool loopActive: available && player.loopState !== MprisLoopState.None

    function formatTime(seconds: real): string {
        if (!isFinite(seconds) || seconds < 0)
            return "0:00";
        const value = Math.floor(seconds);
        return Math.floor(value / 60) + ":" + String(value % 60).padStart(2, "0");
    }

    function cycleLoop(): void {
        if (!player || !player.loopSupported || !player.canControl)
            return;
        if (player.loopState === MprisLoopState.None)
            player.loopState = MprisLoopState.Playlist;
        else if (player.loopState === MprisLoopState.Playlist)
            player.loopState = MprisLoopState.Track;
        else
            player.loopState = MprisLoopState.None;
    }
}
