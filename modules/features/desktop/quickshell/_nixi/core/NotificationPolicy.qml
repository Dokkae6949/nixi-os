pragma Singleton
import QtQuick
import ".."

// Central privacy policy for notification consumers. Adding a new surface or
// trusted channel is a policy change, not a rendering change.
QtObject {
    readonly property string batteryChannel: "battery"
    readonly property string generalChannel: "general"
    readonly property string desktopContext: "desktop"
    readonly property string lockContext: "lock"

    function channel(notification: var): string {
        if (notification === null || notification === undefined)
            return generalChannel;
        const icon = String(notification.image || notification.appIcon || "").toLowerCase();
        const summary = String(notification.summary || "").toLowerCase();
        return icon.includes("battery") || summary.includes("low battery") ? batteryChannel : generalChannel;
    }

    function allows(channelName: string, context: string): bool {
        if (context === lockContext)
            return channelName === batteryChannel;
        if (context === desktopContext)
            return !LockService.locked;
        return false;
    }
}
