pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

// Central state machine for the 4-step install wizard. Owns the settings
// gathered from the UI, tracks per-step status/progress/log, and launches
// backend/abinstall-gui-runner for whichever step is currently running.
//
// Steps, by index: 0 partition, 1 user, 2 copy, 3 bootloader.
QtObject {
    id: root

    readonly property int stepPartition: 0
    readonly property int stepUser: 1
    readonly property int stepCopy: 2
    readonly property int stepBootloader: 3
    readonly property int stepCount: 4

    readonly property int statusIdle: 0
    readonly property int statusRunning: 1
    readonly property int statusSuccess: 2
    readonly property int statusError: 3

    readonly property var stepNames: ["partition", "user", "copy", "bootloader"]
    readonly property var stepLabels: ["Partition Disk", "Create User", "Copy System Files", "Install Bootloader"]

    property int currentStep: 0
    property var stepStatus: [0, 0, 0, 0]
    property var stepProgress: [0, 0, 0, 0]
    property var stepMessage: ["", "", "", ""]
    property var stepLog: ["", "", "", ""]

    // Gathered from the UI before each step runs.
    property string selectedDevice: ""
    property string username: ""
    property string password: ""

    readonly property string runnerPath: Qt.resolvedUrl("../backend/abinstall-gui-runner").toString().replace("file://", "")

    function canGoNext() {
        return stepStatus[currentStep] === statusSuccess;
    }

    function canGoBack() {
        return currentStep > 0 && stepStatus[currentStep] !== statusRunning;
    }

    function goNext() {
        if (!canGoNext() || currentStep >= stepCount - 1) return;
        currentStep += 1;
    }

    function goBack() {
        if (!canGoBack()) return;
        currentStep -= 1;
    }

    function _setStatus(step, status) {
        var arr = stepStatus.slice();
        arr[step] = status;
        stepStatus = arr;
    }
    function _setProgress(step, pct) {
        var arr = stepProgress.slice();
        arr[step] = pct;
        stepProgress = arr;
    }
    function _setMessage(step, msg) {
        var arr = stepMessage.slice();
        arr[step] = msg;
        stepMessage = arr;
    }
    function _appendLog(step, line) {
        var arr = stepLog.slice();
        arr[step] = arr[step] + line + "\n";
        stepLog = arr;
    }

    // Unquotes the printf %q-style output emitted by common.sh's emit_* helpers.
    function _unquote(s) {
        return s.replace(/^"|"$/g, "").replace(/\\(.)/g, "$1");
    }

    function _parseLine(step, line) {
        if (line.length === 0) return;
        _appendLog(step, line);

        var pctMatch = line.match(/^PROGRESS pct=(\d+) message=(.*)$/);
        if (pctMatch) {
            _setProgress(step, parseInt(pctMatch[1], 10));
            _setMessage(step, _unquote(pctMatch[2]));
            return;
        }
        var errMatch = line.match(/^ERROR code=(\S+) message=(.*)$/);
        if (errMatch) {
            _setMessage(step, _unquote(errMatch[2]));
            return;
        }
        var resMatch = line.match(/^RESULT status=(success|error) step=(\S+)$/);
        if (resMatch) {
            _setStatus(step, resMatch[1] === "success" ? statusSuccess : statusError);
            if (resMatch[1] === "success") _setProgress(step, 100);
            return;
        }
        // Unrecognised line (e.g. raw stderr) — keep in the log, no state change.
    }

    // One Process per step, created on demand so failed runs can be retried
    // cleanly without leftover process state.
    property Process _proc: null

    function runStep(step) {
        if (stepStatus[step] === statusRunning) return;
        _setStatus(step, statusRunning);
        _setProgress(step, 0);
        _setMessage(step, "Starting...");
        stepLog[step] = "";

        // The Quickshell process itself runs as the unprivileged live user
        // (mango session), not root — every step needs privileged disk/
        // chroot access, so it's launched via passwordless wheel sudo
        // (already configured on the live ISO). -n means "fail fast" if
        // that's ever not the case, instead of sudo silently blocking on a
        // password prompt that has nowhere to be typed into.
        var args = ["sudo", "-n", runnerPath, stepNames[step]];
        var stdinData = null;

        if (step === stepPartition) {
            args.push(selectedDevice);
        } else if (step === stepUser) {
            args.push(username);
            stdinData = password + "\n";
        } else if (step === stepCopy || step === stepBootloader) {
            // no extra args — reads state persisted by earlier steps
        }

        var p = procComponent.createObject(root, {"command": args, "boundStep": step});
        _proc = p;
        p.running = true;
        if (stdinData !== null) {
            p.write(stdinData);
        }
    }

    property Component procComponent: Component {
        Process {
            id: proc
            stdinEnabled: true

            property int boundStep: 0

            stdout: SplitParser {
                onRead: data => root._parseLine(proc.boundStep, data)
            }
            stderr: SplitParser {
                onRead: data => root._appendLog(proc.boundStep, data)
            }

            onExited: (exitCode, exitStatus) => {
                // If the script crashed without emitting a RESULT line
                // (e.g. killed, or a bug), don't leave the UI stuck on
                // "running" forever.
                if (root.stepStatus[boundStep] === root.statusRunning) {
                    root._setStatus(boundStep, exitCode === 0 ? root.statusSuccess : root.statusError);
                    if (exitCode !== 0) {
                        root._setMessage(boundStep, "Step exited unexpectedly (code " + exitCode + ")");
                    }
                }
                proc.destroy();
            }
        }
    }

    function retryStep(step) {
        _setStatus(step, statusIdle);
        runStep(step);
    }
}
