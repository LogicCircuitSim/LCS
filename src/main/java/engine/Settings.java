package engine;

import imgui.type.ImBoolean;
import imgui.type.ImInt;

public class Settings {
	// Setting Option could be:
	//- UI Scale
	//- (Other graphical settings)
	//- Clearing Cache
	//- Animations on/off
	//- Debug Info
	
	public static ImBoolean brightMode = new ImBoolean(false);
	
	public static ImBoolean fullscreen = new ImBoolean(false);
	
	public static ImBoolean vsync = new ImBoolean(true);
	
	public static ImInt fontSize = new ImInt(16);
	
	// dont know if we want fixed resolutions, or free scaling
	// -> probably fixed resolutions
	public static ImInt resolution = new ImInt(0);
	public static int[][] resolutions = new int[][]{
			{ 1280, 720 },
			{ 1920, 1080 },
			{ 2560, 1440 }
	};
	public static int[] getResolution() {
		return resolutions[resolution.get()];
	}
	
}
