# twitch-adfree-stream-downloader
This script uses the dynamic VOD hls playlist to download the ongoing livestream producing a clean media file without any kind of commercial screens.

Notes:
- The streamer must have VODs active in the channel settings and the current stream's VOD must be public.
- Some streamers configure their streaming software to not send certain audio tracks to VOD, usually to avoid receiving DMCA for listening to copyrighted music and this will cause that type of audio to be silent when downloading the stream through VOD.

<b>Installation</b>
- Download the script through this [link](https://github.com/KaMyKaSii/twitch-adfree-stream-downloader/archive/refs/heads/main.zip).
- Extract it.
- Open your terminal in the extracted folder and then give the script executable permission with ```chmod +x twitch-adfree-stream-downloader.sh```

<b>Usage</b>

Go to the streamer's "Videos" page (https://www.twitch.tv/STREAMER/videos?filter=archives&sort=time) and grab the latest VOD link (it won't have a thumbnail yet), then:

```
./twitch-adfree-stream-downloader [VodLink]
```


e.g:
'./twitch-adfree-stream-downloader https://www.twitch.tv/videos/1759176844'

The script will then ask for the name of the output file (no need to add the extension) and if the user wants to change the destination folder, the default is in the "livestream-from-start" folder inside your HOME directory.

After starting, the script will download all available VOD segments, wait for 5 minutes, download the new segments and repeat the process until the stream has no more new segments available indicating that it has reached the end.

Note that the script is not limited to just Twitch, any other stream platform that also offers a dynamic hls playlist for a stream's VOD can be used. In this case, depending on how long the site takes to update the playlist, you may need to change the sleep time:

```
./twitch-adfree-stream-downloader [VodLink] [WaitTimeSeconds]
```

<b>Support</b>

The script only works on Linux systems. If you don't use Linux on your computer, you can use other alternatives like running it inside the [Windows Subsystem for Linux (WSL)](https://learn.microsoft.com/windows/wsl/install) on Windows or [Termux](https://github.com/termux/termux-app) on an Android device (as long as it has enough free storage and a writable directory is defined for the download).
