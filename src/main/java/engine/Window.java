package engine;

import engine.events.*;
import imgui.*;
import imgui.app.Color;
import imgui.flag.ImGuiConfigFlags;
import imgui.gl3.ImGuiImplGl3;
import imgui.glfw.ImGuiImplGlfw;
import org.lwjgl.glfw.*;
import org.lwjgl.opengl.GL;
import org.lwjgl.opengl.GL32;
import org.lwjgl.system.MemoryStack;
import org.lwjgl.system.MemoryUtil;

import java.nio.IntBuffer;
import java.util.Objects;

/**
 * Low-level abstraction, which creates application window and starts the main loop.
 * When extended, life-cycle methods should be called manually.
 */
public abstract class Window extends KeyList {
	
	// -==========[ ImGui Bridges for GLFW ]==========-
	private final ImGuiImplGlfw imGuiGlfw = new ImGuiImplGlfw();
	private final ImGuiImplGl3 imGuiGl3 = new ImGuiImplGl3();
	
	/** Pointer to the native GLFW window. */
	protected long handle;
	
	private String glslVersion = null;
	protected final Color colorBg = new Color(.11f, .12f, .15f, 1);
	
	public ImFont normalFont;
	public ImFont titleFont;
	
	// -==========[ Delta Time Variables ]==========-
	private double deltaTimeFactor;
	private int refreshRate;
	private int millisPerTick;
	private long lastMillis;
	
	public boolean shouldUpdateSettings = false;
	
	protected void init() {
		initWindow();
		initImGui();
		imGuiGlfw.init(handle, true);
		imGuiGl3.init(glslVersion);
	}
	
	/**
	 * Method to create and initialize GLFW window.
	 */
	protected void initWindow() {
		GLFWErrorCallback.createPrint(System.err).set();
		
		if (!GLFW.glfwInit())
			throw new IllegalStateException("Unable to initialize GLFW");
		
		final boolean isMac = System.getProperty("os.name").toLowerCase().contains("mac");
		if (isMac) {
			glslVersion = "#version 150";
			GLFW.glfwWindowHint(GLFW.GLFW_CONTEXT_VERSION_MAJOR, 3);
			GLFW.glfwWindowHint(GLFW.GLFW_CONTEXT_VERSION_MINOR, 2);
			GLFW.glfwWindowHint(GLFW.GLFW_OPENGL_PROFILE, GLFW.GLFW_OPENGL_CORE_PROFILE);  // 3.2+ only
			GLFW.glfwWindowHint(GLFW.GLFW_OPENGL_FORWARD_COMPAT, GLFW.GLFW_TRUE);          // Required on Mac
		} else {
			glslVersion = "#version 130";
			GLFW.glfwWindowHint(GLFW.GLFW_CONTEXT_VERSION_MAJOR, 3);
			GLFW.glfwWindowHint(GLFW.GLFW_CONTEXT_VERSION_MINOR, 0);
		}
		
		GLFW.glfwWindowHint(GLFW.GLFW_VISIBLE, GLFW.GLFW_FALSE);
		GLFW.glfwWindowHint(GLFW.GLFW_RESIZABLE, GLFW.GLFW_FALSE);
		handle = GLFW.glfwCreateWindow(Settings.getResolution()[0], Settings.getResolution()[1], "Logic Circuit Simulator", MemoryUtil.NULL, MemoryUtil.NULL);
		
		if (handle == MemoryUtil.NULL)
			throw new RuntimeException("Failed to create the GLFW window");
		
		try (MemoryStack stack = MemoryStack.stackPush()) {
			final IntBuffer pWidth = stack.mallocInt(1); // int*
			final IntBuffer pHeight = stack.mallocInt(1); // int*
			
			final GLFWVidMode vidMode = Objects.requireNonNull(GLFW.glfwGetVideoMode(GLFW.glfwGetPrimaryMonitor()));
			GLFW.glfwGetWindowSize(handle, pWidth, pHeight);
			GLFW.glfwSetWindowPos(handle, (vidMode.width() - pWidth.get(0)) / 2, (vidMode.height() - pHeight.get(0)) / 2);
			refreshRate = vidMode.refreshRate();
		}
		
		GLFW.glfwSetKeyCallback(handle, (windowHnd, key, scancode, action, mods) -> {
			if (!shouldUpdateSettings && action == GLFW.GLFW_PRESS) {
				if (key == GLFW.GLFW_KEY_F11) {
					Settings.fullscreen.set(!Settings.fullscreen.get());
					shouldUpdateSettings = true;
				} else if (key == GLFW.GLFW_KEY_F12) {
					Settings.brightMode.set(!Settings.brightMode.get());
					shouldUpdateSettings = true;
				}
			}
			
			InputController.updateKeys(key, action, mods);
			keyEvent(new KeyEvent(key, action, mods));
		});
		
		GLFW.glfwSetMouseButtonCallback(handle, (windowHnd, button, action, mods) -> {
			InputController.updateMouseButtons(button, action);
			mouseButtonEvent(new MouseButtonEvent(button, action));
		});
		GLFW.glfwSetCursorPosCallback(handle, (windowHnd, x, y) -> {
			InputController.updateMousePos(x, y);
			mouseMoveEvent(new MouseMoveEvent((int) x, (int) y));
		});
		GLFW.glfwSetScrollCallback(handle, (windowHnd, x, y) -> {
			InputController.updateMouseWheel(x, y);
			mouseWheelEvent(new MouseWheelEvent((int) x, (int) y));
		});
		
		/*case GLFW_KEY_ESCAPE -> glfwSetWindowShouldClose(windowHnd, true);
		case GLFW_KEY_A -> glfwRequestWindowAttention(windowHnd);
		case GLFW_KEY_F -> {
			if (glfwGetWindowMonitor(windowHnd) == NULL) {
				try (MemoryStack s = stackPush()) {
					IntBuffer a = s.ints(0);
					IntBuffer b = s.ints(0);
					
					glfwGetWindowPos(windowHnd, a, b);
					xpos = a.get(0);
					ypos = b.get(0);
					
					glfwGetWindowSize(windowHnd, a, b);
					width = a.get(0);
					height = b.get(0);
				}
				glfwSetWindowMonitor(windowHnd, monitor, 0, 0, vidmode.width(), vidmode.height(), vidmode.refreshRate());
				glfwSwapInterval(1);
			}
		}
		case GLFW_KEY_G ->
				glfwSetInputMode(windowHnd, GLFW_CURSOR, glfwGetInputMode(windowHnd, GLFW_CURSOR) == GLFW_CURSOR_NORMAL
						? GLFW_CURSOR_DISABLED
						: GLFW_CURSOR_NORMAL
				);
		case GLFW_KEY_O -> glfwSetWindowOpacity(window, glfwGetWindowOpacity(window) == 1.0f ? 0.5f : 1.0f);
		case GLFW_KEY_R -> glfwSetWindowAttrib(windowHnd, GLFW_RESIZABLE, 1 - glfwGetWindowAttrib(windowHnd, GLFW_RESIZABLE));
		case GLFW_KEY_U -> glfwSetWindowAttrib(windowHnd, GLFW_DECORATED, 1 - glfwGetWindowAttrib(windowHnd, GLFW_DECORATED));
		case GLFW_KEY_W -> {
			if (glfwGetWindowMonitor(windowHnd) != NULL) {
				glfwSetWindowMonitor(windowHnd, NULL, xpos, ypos, width, height, 0);
			}*/
			
		// Some Stuff
		GLFW.glfwMakeContextCurrent(handle);
		GL.createCapabilities();
		
		// V-SYNC
		GLFW.glfwSwapInterval(GLFW.GLFW_TRUE);
		
		GLFW.glfwShowWindow(handle);
		
		// Screen Clear and Render
		clearBuffer();
		renderBuffer();
		
		// Code to run when Window gets resized
//		GLFW.glfwSetWindowSizeCallback(handle, (window, width, height) -> {
//				runFrame();
//		});
	}
	
	/**
	 * Method to initialize Dear ImGui context. Could be overridden to do custom Dear ImGui setup before application start.
	 */
	protected void initImGui() {
		ImGui.createContext();
		
		final ImGuiIO io = ImGui.getIO();
		// io.setIniFilename(null);
		io.addConfigFlags(ImGuiConfigFlags.NavEnableKeyboard);
		io.addConfigFlags(ImGuiConfigFlags.DockingEnable);
		io.addConfigFlags(ImGuiConfigFlags.ViewportsEnable);
		io.setConfigViewportsNoTaskBarIcon(true);
		
		ImGuiStyle style = ImGui.getStyle();
		
		style.setColors(Theme.getTheme());
		
		style.setWindowPadding(8.00f, 8.00f);
		style.setFramePadding(5.00f, 2.00f);
		style.setCellPadding(2.00f, 2.00f);
		style.setItemSpacing(6.00f, 6.00f);
		style.setItemInnerSpacing(2.00f, 6.00f);
		style.setTouchExtraPadding(0.00f, 0.00f);
		style.setIndentSpacing(25);
		style.setScrollbarSize(15);
		style.setGrabMinSize(10);
		style.setWindowBorderSize(1);
		style.setChildBorderSize(1);
		style.setPopupBorderSize(1);
		style.setFrameBorderSize(1);
		style.setTabBorderSize(1);
		style.setWindowRounding(0);
		style.setChildRounding(4);
		style.setFrameRounding(3);
		style.setPopupRounding(4);
		style.setScrollbarRounding(9);
		style.setGrabRounding(3);
		style.setLogSliderDeadzone(4);
		style.setTabRounding(4);
		
		final ImFontConfig fontConfig = new ImFontConfig();
		normalFont = io.getFonts().addFontFromFileTTF("src/main/resources/CascadiaCode.ttf", 16, fontConfig);
		titleFont = io.getFonts().addFontFromFileTTF("src/main/resources/CascadiaCode.ttf", 100, fontConfig);
		io.getFonts().build();
		io.setFontDefault(normalFont);
		
		fontConfig.destroy();
	}
	
	public void updateSettings() {
		Theme.selected = Settings.brightMode.get() ? 1:0;
		ImGui.getStyle().setColors(Theme.getTheme());
		
		if (Settings.fullscreen.get()) {
			GLFW.glfwSetWindowAttrib(handle, GLFW.GLFW_DECORATED, 0);
			GLFW.glfwMaximizeWindow(handle);
		} else {
			GLFW.glfwSetWindowAttrib(handle, GLFW.GLFW_DECORATED, 1);
			final GLFWVidMode vidMode = Objects.requireNonNull(GLFW.glfwGetVideoMode(GLFW.glfwGetPrimaryMonitor()));
			GLFW.glfwSetWindowPos(handle, (vidMode.width() - Settings.getResolution()[0]) / 2, (vidMode.height() - Settings.getResolution()[1]) / 2);
			GLFW.glfwSetWindowSize(handle, Settings.getResolution()[0], Settings.getResolution()[1]);
		}
		
		GLFW.glfwSwapInterval(Settings.vsync.get() ? GLFW.GLFW_TRUE:GLFW.GLFW_FALSE);
	}
	
	public void keyEvent(final KeyEvent event) { }
	public void mouseButtonEvent(final MouseButtonEvent event) { }
	public void mouseMoveEvent(final MouseMoveEvent event) { }
	public void mouseWheelEvent(final MouseWheelEvent event) { }
	
	
	public void launch() {
		init();
		preRun();
		run();
		postRun();
		dispose();
	}
	
	/**
	 * Method called once, before application run loop.
	 */
	protected void preRun() {
	}
	
	/**
	 * Method called once, after application run loop.
	 */
	protected void postRun() {
	}
	
	
	/**
	 * Main application loop.
	 */
	protected void run() {
		while (!GLFW.glfwWindowShouldClose(handle))
			runFrame();
	}
	
	/**
	 * Method used to run the next frame.
	 */
	protected void runFrame() {
		startFrame();
		preProcess();
		process();
		postProcess();
		endFrame();
	}
	
	/**
	 * Method called at the beginning of the main cycle.
	 * It clears OpenGL buffer and starts an ImGui frame.
	 */
	protected void startFrame() {
		clearBuffer();
		imGuiGlfw.newFrame();
		ImGui.newFrame();
	}
	
	/**
	 * Method called every frame, before calling {@link #process()} method.
	 */
	protected void preProcess() {
//		millisPerTick = (int) (System.currentTimeMillis() - lastMillis);
//		deltaTimeFactor = (1000f / refreshRate) / millisPerTick;
//		lastMillis = System.currentTimeMillis();
	}
	
	/**
	 * Method to be overridden by user to provide main application logic.
	 */
	public abstract void process();
	
	/**
	 * Method called every frame, after calling {@link #process()} method.
	 */
	protected void postProcess() { }
	
	/**
	 * Method called in the end of the main cycle.
	 * It renders ImGui and swaps GLFW buffers to show an updated frame.
	 */
	protected void endFrame() {
		ImGui.render();
		imGuiGl3.renderDrawData(ImGui.getDrawData());
		
		if (ImGui.getIO().hasConfigFlags(ImGuiConfigFlags.ViewportsEnable)) {
			final long backupWindowPtr = GLFW.glfwGetCurrentContext();
			ImGui.updatePlatformWindows();
			ImGui.renderPlatformWindowsDefault();
			GLFW.glfwMakeContextCurrent(backupWindowPtr);
		}
		
		renderBuffer();
		
		if (shouldUpdateSettings) {
			updateSettings();
			shouldUpdateSettings = false;
		}
	}
	
	/**
	 * Method used to clear the OpenGL buffer.
	 */
	private void clearBuffer() {
		GL32.glClearColor(colorBg.getRed(), colorBg.getGreen(), colorBg.getBlue(), colorBg.getAlpha());
		GL32.glClear(GL32.GL_COLOR_BUFFER_BIT | GL32.GL_DEPTH_BUFFER_BIT);
	}
	
	/**
	 * Method to render the OpenGL buffer and poll window events.
	 */
	private void renderBuffer() {
		GLFW.glfwSwapBuffers(handle);
		GLFW.glfwPollEvents();
	}
	
	/**
	 * Method to dispose all used application resources and destroy its window.
	 */
	protected void dispose() {
		imGuiGl3.dispose();
		imGuiGlfw.dispose();
		ImGui.destroyContext();
		Callbacks.glfwFreeCallbacks(handle);
		GLFW.glfwDestroyWindow(handle);
		GLFW.glfwTerminate();
		Objects.requireNonNull(GLFW.glfwSetErrorCallback(null)).free();
	}
	
	public void quit() {
		GLFW.glfwSetWindowShouldClose(handle, true);
	}
}
