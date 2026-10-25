pragma Singleton
import QtQuick
import Quickshell.Io
import ".."

QtObject {
    id: root
    property bool started: false
    property real cpuLoad: 0
    property real memoryUsed: 0
    property real memoryTotal: 0
    property real storageUsed: 0
    property real storageTotal: 0
    property real temperature: -1
    property string temperatureSource: ""
    property double previousCpuIdle: 0
    property double previousCpuTotal: 0
    property double updatedAt: 0

    readonly property real memoryLoad: memoryTotal > 0 ? memoryUsed / memoryTotal : 0
    readonly property real storageLoad: storageTotal > 0 ? storageUsed / storageTotal : 0

    function start(): void {
        if (started)
            return;
        started = true;
        sample();
    }

    function sample(): void {
        if (!collector.running)
            collector.running = true;
    }

    function consume(output: string): void {
        const fields = output.trim().split("\t");
        if (fields.length < 14)
            return;

        const idle = Number(fields[3]) + Number(fields[4]);
        let total = 0;
        for (let index = 0; index < 8; ++index)
            total += Number(fields[index]);
        if (previousCpuTotal > 0 && total > previousCpuTotal)
            cpuLoad = Math.max(0, Math.min(1, 1 - (idle - previousCpuIdle)
                                          / (total - previousCpuTotal)));
        previousCpuIdle = idle;
        previousCpuTotal = total;

        memoryTotal = Number(fields[8]) * 1024;
        memoryUsed = Math.max(0, memoryTotal - Number(fields[9]) * 1024);
        storageTotal = Number(fields[10]) * 1024;
        storageUsed = Number(fields[11]) * 1024;
        const rawTemperature = Number(fields[12]);
        temperature = rawTemperature > 0 ? rawTemperature / 1000 : -1;
        temperatureSource = fields[13] || "Unknown sensor";
        updatedAt = Date.now();
    }

    property Process collector: Process {
        command: ["bash", "-c", "read _ user nice system idle iowait irq softirq steal _ < /proc/stat; read mem_total mem_available < <(awk '/MemTotal:/ {t=$2} /MemAvailable:/ {a=$2} END {print t, a}' /proc/meminfo); read disk_total disk_used < <(df -Pk / | awk 'END {print $2, $3}'); max_temp=0; max_sensor=''; for sensor in /sys/class/thermal/thermal_zone*/temp /sys/class/hwmon/hwmon*/temp*_input; do [ -r \"$sensor\" ] || continue; read value < \"$sensor\" 2>/dev/null || continue; if [[ $value =~ ^[0-9]+$ ]] && (( value > max_temp && value < 150000 )); then max_temp=$value; max_sensor=$sensor; fi; done; temp_name='Unavailable'; if [[ $max_sensor == */thermal_zone*/* ]]; then read temp_name < \"${max_sensor%/temp}/type\" 2>/dev/null || temp_name='Thermal zone'; elif [ -n \"$max_sensor\" ]; then base=${max_sensor%_input}; hwmon=${max_sensor%/temp*}; read chip < \"$hwmon/name\" 2>/dev/null || chip='Hardware sensor'; if read sensor_label < \"${base}_label\" 2>/dev/null; then temp_name=\"$chip · $sensor_label\"; else temp_name=$chip; fi; fi; printf '%s\\t%s\\t%s\\t%s\\t%s\\t%s\\t%s\\t%s\\t%s\\t%s\\t%s\\t%s\\t%s\\t%s\\n' \"$user\" \"$nice\" \"$system\" \"$idle\" \"$iowait\" \"$irq\" \"$softirq\" \"$steal\" \"$mem_total\" \"$mem_available\" \"$disk_total\" \"$disk_used\" \"$max_temp\" \"$temp_name\""]
        stdout: StdioCollector { onStreamFinished: root.consume(text) }
    }

    property Timer refresh: Timer {
        running: root.started
        repeat: true
        interval: 2000
        onTriggered: root.sample()
    }
}
