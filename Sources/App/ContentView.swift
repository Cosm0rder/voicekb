import SwiftUI

struct ContentView: View {
    @StateObject private var speech = SpeechRecognizer()
    @State private var copied = false

    var body: some View {
        VStack(spacing: 24) {
            Text("ボイス入力")
                .font(.title2).bold()

            if !speech.authorized {
                Text("最初に音声認識とマイクの許可が要ります。")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                Button("許可する") { speech.requestAuthorization() }
                    .buttonStyle(.borderedProminent)
            }

            ZStack {
                Circle()
                    .fill(speech.isRecording ? Color.red : Color.blue)
                    .frame(width: 110, height: 110)
                Image(systemName: speech.isRecording ? "stop.fill" : "mic.fill")
                    .font(.system(size: 44))
                    .foregroundStyle(.white)
            }
            .onTapGesture {
                if speech.isRecording {
                    speech.stop()
                    finish()
                } else {
                    copied = false
                    speech.transcript = ""
                    speech.start()
                }
            }

            Text(speech.isRecording ? "聞き取り中… もう一度タップで終了" : "マイクをタップして話す")
                .font(.footnote)
                .foregroundStyle(.secondary)

            ScrollView {
                Text(speech.transcript.isEmpty ? "（ここに文字が出ます）" : speech.transcript)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
            }
            .background(Color(.secondarySystemBackground))
            .cornerRadius(12)
            .padding(.horizontal)

            if copied {
                Text("コピーしました。元のアプリに戻って、キーボードの「貼り付け」を押してください。")
                    .font(.footnote)
                    .foregroundStyle(.green)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }

            Spacer()
        }
        .padding(.top, 32)
        .onAppear { speech.requestAuthorization() }
        .onOpenURL { url in
            // キーボードから voicekb://record で呼ばれたら自動で録音開始
            if url.scheme == "voicekb" && speech.authorized && !speech.isRecording {
                copied = false
                speech.transcript = ""
                speech.start()
            }
        }
    }

    private func finish() {
        let text = speech.cleanedText()
        if !text.isEmpty {
            UIPasteboard.general.string = text
            copied = true
        }
    }
}
