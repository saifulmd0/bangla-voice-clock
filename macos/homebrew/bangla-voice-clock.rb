# The Homebrew cask, published to github.com/saifulmd0/homebrew-tap. Edit it in
# bangla-voice-clock (macos/homebrew/); the release job fills in version and
# sha256 for each tag and pushes it to the tap.
cask "bangla-voice-clock" do
  version "0.0.0"
  sha256 "0000000000000000000000000000000000000000000000000000000000000000"

  url "https://github.com/saifulmd0/bangla-voice-clock/releases/download/v#{version}/BanglaVoiceClock-v#{version}-macos.dmg"
  name "Bangla Voice Clock"
  name "বাংলা ভয়েস ক্লক"
  desc "Menu bar clock that announces the time aloud in Bangla"
  homepage "https://github.com/saifulmd0/bangla-voice-clock"

  depends_on macos: :monterey

  app "Bangla Voice Clock.app"

  # The app isn't signed by a developer ID yet, so Gatekeeper would block the
  # quarantined copy; installing from this tap is the user's go-ahead.
  postflight_steps do
    run "/usr/bin/xattr",
        args:           ["-dr", "com.apple.quarantine", "{{appdir}}/Bangla Voice Clock.app"],
        writable_paths: ["Bangla Voice Clock.app"],
        writable_base:  :appdir
  end

  uninstall quit: "com.projuktiteam.banglaVoiceClock"

  zap trash: [
    "~/Library/Application Scripts/com.projuktiteam.banglaVoiceClock",
    "~/Library/Containers/com.projuktiteam.banglaVoiceClock",
  ]
end
