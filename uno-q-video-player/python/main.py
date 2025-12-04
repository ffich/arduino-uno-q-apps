# SPDX-FileCopyrightText: Copyright (C) ARDUINO SRL (http://www.arduino.cc)
#
# SPDX-License-Identifier: MPL-2.0

from arduino.app_bricks.streamlit_ui import st
import subprocess

#subprocess.run(["ls", "-l"]) 
#st.title("Arduino Video Player example")


# Video URL (You can use a YouTube URL or a video file path)
video_url = "https://www.youtube.com/watch?v=QxPBCBX8ac8?autoplay=1"  # Replace with your video URL
local = "/app/assets/video/test.mp4"
# Play the video


if st.button("Video from Youtube"):
  st.video(video_url)
  st.success("video from Youtube")
  
if st.button("MP4 locally"):
  st.video(local)
  st.success("video from MP4")