# rtmp-streaming service
## Start service
`sudo docker-compose -f docker-compose.yaml up -d`
## Add an online stream
* `rtmp://<server ip>:1935/live/<stream_key>`
* Default stream key is `test`. e.g. `rtmp://<server ip>:1935/live/test`
## View stream
### With VLC
* Go to Media > Open Network Stream.
* Enter the streaming URL: `rtmp://<server ip>:1935/live/<stream-key>` Replace <server ip> with the IP of where the server is running, and <stream-key> with the stream key you used when setting up the stream.
* For HLS and DASH, the URLs are of the forms: `http://<server ip>:9080/hls/<stream-key>.m3u8` and `http://<server ip>:9080/dash/<stream-key>_src.mpd`respectively. If necessary use default stream key as `test`.
* Click Play.
### Browser
* To play RTMP content (requires Flash): `http://localhost:9080/players/rtmp.html`
* To play HLS content: `http://localhost:9080/players/hls.html`
* To play HLS content using hls.js library: `http://localhost:9080/players/hls_hlsjs.html`
* To play DASH content: `http://localhost:9080/players/dash.html`
* To play RTMP and HLS contents on the same page: `http://localhost:9080/players/rtmp_hls.html`
