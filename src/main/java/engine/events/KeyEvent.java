package engine.events;

import static org.lwjgl.glfw.GLFW.*;

public record KeyEvent(int keyCode, int keyState, int keyMods) {
	
	public final boolean isShiftDown() {
		return ((this.keyMods & GLFW_MOD_SHIFT) != 0);
	}
	
	public final boolean isControlDown() {
		return ((this.keyMods & GLFW_MOD_CONTROL) != 0);
	}
	
	public final boolean isAltDown() {
		return ((this.keyMods & GLFW_MOD_ALT) != 0);
	}
	
}
