### Game Launcher with Audio Switching

## For games that don't allow (or respect) using other audio devices besides the default Windows device

This is still a little rough, just sharing for others in case they want to do the same. Made mostly with Rocket League in mind. 
Rocket League seems to do better with respecting the non-default audio device set since Windows 11, but it also checks if the game did not launch and relaunch it. 
Rocket League takes a handful of seconds to fully close out and if you are trying to close and restart, you may relaunch too early. 
This script will try up to 3 times to launch and verify the game is running.
