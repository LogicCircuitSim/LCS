package engine.events;

import imgui.ImVec2;

import java.util.HashMap;
import java.util.Map;

import static engine.KeyList.*;
import static org.lwjgl.glfw.GLFW.*;
import static org.lwjgl.system.APIUtil.apiClassTokens;

public class InputController {
	// -==========[ Key Variables ]==========-
	private static final Map<Integer, String> KEY_CODES = apiClassTokens((field, value) -> field.getName().startsWith("GLFW_KEY_"), null, org.lwjgl.glfw.GLFW.class);
	private static boolean[] keyMods = new boolean[5];
	private static int keyState = 0;
	private static int keyCode = 0;
	private static Map<Integer, String> keys = new HashMap<>();
	
	// -==========[ Mouse Variables ]==========-
	private static boolean mousePressed;
	private static int mouseButton;
	private static ImVec2 mousePosition = new ImVec2();
	private static ImVec2 lastMousePosition = new ImVec2();
	private static int mouseX, mouseY;
	private static int mouseScrollAmount;
	
	public static void updateKeys(int key, int action, int mods) {
		keyCode = key;
		keyState = action;
		
		if (action == GLFW_PRESS)
			keys.put(key, KEY_CODES.get(key));
		else if (action == GLFW_RELEASE)
			keys.remove(key);
		
		keyMods[GLFW_MOD_SHIFT] = ((mods & GLFW_MOD_SHIFT) != 0);     // 001
		keyMods[GLFW_MOD_CONTROL] = ((mods & GLFW_MOD_CONTROL) != 0); // 010
		keyMods[GLFW_MOD_ALT] = ((mods & GLFW_MOD_ALT) != 0);         // 100
	}
	
	public static void updateMouseButtons(int button, int action) {
		mousePressed = (action == GLFW_PRESS);
		mouseButton = button;
	}
	
	public static void updateMousePos(double x, double y) {
		lastMousePosition.set(mousePosition);
		mousePosition.set((int) x, (int) y);
		mouseX = (int) x;
		mouseY = (int) y;
	}
	
	public static void updateMouseWheel(double x, double y) {
		mouseScrollAmount += (int) y;
	}
	
	// ========================[ Key Get Methods ]============================
	/** Get last Key an action was performed with */
	public static int getKeyCode() {
		return keyCode;
	}
	/** Get last Key State */
	public static int getKeyState() {
		return keyState;
	}
	
	public static void resetKey() {
		keyCode = keyState = -1;
	}
	
	/** Reset Code and State if success */
	public static boolean wasKeyPressed(int key) {
		boolean result = (getKeyCode() == key && getKeyState() == PRESSED);
		if (result) resetKey();
		return result;
	}
	
	/** Reset Code and State if success */
	public static boolean wasKeyReleased(int key) {
		boolean result = (getKeyCode() == key && getKeyState() == RELEASED);
		if (result) resetKey();
		return result;
	}
	
	/** Reset Code and State if success */
	public static boolean wasKeyRepeated(int key) {
		boolean result = (getKeyCode() == key && getKeyState() == REPEATED);
		if (result) resetKey();
		return result;
	}
	
	/** Reset Code and State if success */
	public static boolean wasKeyTyped(int key) {
		boolean result = (getKeyCode() == key && (getKeyState() == PRESSED || getKeyState() == REPEATED));
		if (result) resetKey();
		return result;
	}
	
	/** Check if Key is pressed down */
	public static boolean isKeyDown(final int key) {
		return keys.containsKey(key);
	}
	public static boolean isShiftDown() {
		return keyMods[GLFW_MOD_SHIFT];
	}
	public static boolean isControlDown() {
		return keyMods[GLFW_MOD_CONTROL];
	}
	public static boolean isAltDown() {
		return keyMods[GLFW_MOD_ALT];
	}
	
	public static int mouseX() {
		return mouseX;
	}
	public static int mouseY() {
		return mouseY;
	}
	
	/** get sum of scrolls since last call of this function */
	public static int getScrollAmount() {
		int tmp = mouseScrollAmount;
		mouseScrollAmount = 0;
		return tmp;
	}
	
}
