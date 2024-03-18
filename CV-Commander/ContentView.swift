import Cocoa
import Speech

class AppDelegate: NSObject, NSApplicationDelegate {
    var statusBarItem: NSStatusItem!
    var speechRecognizer = SpeechRecognizer()

    func applicationDidFinishLaunching(_ notification: Notification) {
        self.statusBarItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        
        if let button = self.statusBarItem.button {
            button.image = NSImage(systemSymbolName: "mic.fill", accessibilityDescription: "Spracherkennung")
        }
        
        let menu = NSMenu()
        
        menu.addItem(NSMenuItem(title: "Restart AnyDesk", action: #selector(restartAnyDesk), keyEquivalent: ""))
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "Quit", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q"))
        
        self.statusBarItem.menu = menu

        speechRecognizer.requestPermissions()
    }
    
    @objc func restartAnyDesk() {
        speechRecognizer.restartAnyDesk()
    }
}

class SpeechRecognizer: NSObject, ObservableObject {
    private let speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "de-DE"))!
    private var audioEngine = AVAudioEngine()
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private var isWaitingForCommand = false
    private var aiTriggerName = "nexus"

    override init() {
        super.init()
    }

    func requestPermissions() {
        SFSpeechRecognizer.requestAuthorization { authStatus in
            DispatchQueue.main.async {
                if authStatus == .authorized {
                    print("Berechtigung für Spracherkennung erteilt.")
                    self.startListening()
                } else {
                    print("Berechtigung für Spracherkennung verweigert.")
                }
            }
        }
    }

    func startListening() {

        do {
            setupRecognition()
            
            let recordingFormat = audioEngine.inputNode.outputFormat(forBus: 0)
            audioEngine.inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { buffer, _ in
                self.recognitionRequest?.append(buffer)
            }

            audioEngine.prepare()
            try audioEngine.start()
        } catch {
            print("There was a problem starting the audio engine: \(error.localizedDescription)")
        }
    }

    private var lastCommandEndIndex: String.Index?

    private func setupRecognition() {
        recognitionTask?.cancel()
        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        
        guard let recognitionRequest = self.recognitionRequest else {
            fatalError("Unable to create a SFSpeechAudioBufferRecognitionRequest object")
        }
        
        recognitionRequest.shouldReportPartialResults = true

        recognitionTask = speechRecognizer.recognitionTask(with: recognitionRequest) { [weak self] result, error in
            guard let self = self else { return }

            if let result = result {
                let recognizedText = result.bestTranscription.formattedString.lowercased()
                let startIndex = self.lastCommandEndIndex ?? recognizedText.startIndex
                let newRecognizedText = String(recognizedText[startIndex...])

                print("Gesamter erkannter Text: \(recognizedText)")

                if newRecognizedText.contains(aiTriggerName), let range = newRecognizedText.range(of: aiTriggerName, options: .backwards) {
                    let commandText = String(newRecognizedText[range.upperBound...])
                    print("Befehlstext nach '",aiTriggerName,"': \(commandText)")

                    if commandText.contains("aufräumen") {
                        self.restartAnyDesk()
                        self.lastCommandEndIndex = recognizedText.endIndex
                    }
                    
                    if commandText.contains("mac neustarten") {
                        self.restartMac()
                        self.lastCommandEndIndex = recognizedText.endIndex
                    }
                    
                    if commandText.contains("meeting 427") {
                        self.runShortcut(named: "Star Wars")
                        self.lastCommandEndIndex = recognizedText.endIndex
                    }
                }
            }

            if error != nil || result?.isFinal ?? false {
                self.isWaitingForCommand = false
                self.lastCommandEndIndex = nil
            }
        }
    }

    func restartAnyDesk() {
        print("Restarting AnyDesk...")
        let quitScript = "tell application \"AnyDesk\" to quit"
        let launchScript = "delay 2\n tell application \"AnyDesk\" to activate"
        runAppleScript(script: quitScript)
        runAppleScript(script: launchScript)
    }

    func restartMac() {
        print("Restarting Mac...")
        let restartScript = "tell application \"System Events\" to restart"
        runAppleScript(script: restartScript)
    }
    
    func runShortcut(named shortcutName: String) {
        print("Running Shortcut: \(shortcutName)...")
        let appleScriptString = """
                                tell application "Shortcuts Events"
                                    run shortcut "\(shortcutName)"
                                end tell
                                """
        runAppleScript(script: appleScriptString)
    }

    private func runAppleScript(script: String) {
        var error: NSDictionary?
        if let scriptObject = NSAppleScript(source: script) {
            scriptObject.executeAndReturnError(&error)
            if let error = error {
                print(error)
            }
        }
    }
}
