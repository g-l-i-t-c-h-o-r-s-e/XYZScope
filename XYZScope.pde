import android.content.Context;
import android.os.PowerManager;
import controlP5.*;
import ketai.ui.*;

ControlP5 cp5;
KetaiKeyboard ketaiKeyboard; // Ketai keyboard for text input
PowerManager.WakeLock wakeLock; // WakeLock to keep the screen on

String xFunctionStr = "sin(2 * pi * freq1 * t + time)";
String yFunctionStr = "cos(2 * pi * freq2 * t + time)";
String zFunctionStr = "sin(2 * pi * freq3 * t + time)";

int decimalPlaces = 5; // Default to 2 decimal places
String formatNumber(double value, int decimalPlaces) {
  return String.format("%." + decimalPlaces + "f", value);
}

boolean keyboardVisible = false; // Tracks whether the keyboard is open
String activeTextField = ""; // Tracks which text field is active
float uiScale = 2.0; // Global scaling factor for UI elements
boolean customFieldsVisible = true; // Tracks visibility of custom text fields


// Cursor variables
int cursorPosition = 0; // Current cursor position
int cursorBlinkRate = 30; // Cursor blink rate (frames)
boolean cursorVisible = true; // Tracks cursor visibility
int cursorX = 0;

// Handle touch events for pinch-to-zoom and rotation
int touchInteractionMode = 0; // 0 = none, 1 = pinch-to-zoom, 2 = rotation, 3 = GUI toggle
boolean isInteractingWithSlider = false; // Tracks whether the user is interacting with a slider

// References to the sliders
Slider freq1Slider, freq2Slider, freq3Slider, sampleSlider, timeMultiplierSlider, enlargedTimeMultiplierSlider; 
Slider activeSlider = null; // Track the currently active slider

// Variables to store original slider sizes
float originalSliderWidth = 200 * uiScale;
float originalSliderHeight = 20 * uiScale;
float enlargedSliderWidth = 400 * uiScale; // Double the original width
float enlargedSliderHeight = 40 * uiScale; // Double the original height

// Expression variables for exp4j
Expression xExpression, yExpression, zExpression;
Function squareFunc, sawFunc, triangleFunc, absSinFunc; // Custom functions for exp4j
double phi = 1.61803398875; // Define the golden ratio phi

// Visualization parameters
int pixelsPerSample = 1;          // Controls the number of pixels per sample (zoom level)
float timeScale = 1.0;            // Controls the scaling factor applied to axes
boolean adjustTimeScale = true;   // Toggle for adjusting timeScale with mouse wheel
float zoom = 1.0;                 // Controls the zoom level of the geometry
boolean smoothLines = true;       // Toggle for smooth lines

// Number of samples variables
int baseNumSamples = 256;        // Base number of samples set via text field
int numSamples = baseNumSamples;   // Actual number of samples used in drawing

// Arrays to store waveform vertices
float[] xVertices = new float[0];
float[] yVertices = new float[0];
float[] zVertices = new float[0];

// PGraphics object for rendering
PGraphics pg;

// Base frequency variables (unchanged by sliders)
double baseFreq1 = 72.0D;
double baseFreq2 = 43.2D;
double baseFreq3 = 43.2D;

//Default Frequency variables
double freq1 = 0;
double freq2 = 0;
double freq3 = 0;

// Frequency strings (displayed in text fields)
String freq1Str = formatNumber(baseFreq1, decimalPlaces);
String freq2Str = formatNumber(baseFreq2, decimalPlaces);
String freq3Str = formatNumber(baseFreq3, decimalPlaces);

// TimeScale toggles for each axis
boolean applyTimeScaleX = false;
boolean applyTimeScaleY = false;
boolean applyTimeScaleZ = true;    // Default to true for Z axis as in old code

// Flag to indicate if controllers have been initialized
boolean controllersInitialized = false;

// Time multiplier for controlling animation speed
float timeMultiplier = 1.0;

// Freeze time variables
boolean freezeTime = false;
double frozenTime = 0.0;

// Variables for controlling rotation with touch controls
float rotationX = 0;
float rotationY = 0;
int lastMouseX;
int lastMouseY;

// Variable to track GUI visibility
boolean guiVisible = true;

// Variables for pinch-to-zoom
float initialPinchDistance = 0; // Initial distance between two touch points
float initialZoom = 1.0; // Initial zoom level when pinch starts

void setup() {
  fullScreen(P3D);
  background(0);
  lastMouseX = mouseX;
  lastMouseY = mouseY;

  // Initialize ControlP5 for the GUI
  cp5 = new ControlP5(this);

  // Enable auto-draw for ControlP5
  cp5.setAutoDraw(true);
  println(freq3Str); // here is where 


  // Add a button to apply the functions
  cp5.addButton("applyFunctions")
     .setLabel("Apply Functions")
     .setPosition((int)(140 * uiScale), (int)(140 * uiScale)) // Cast to int
     .setLock(true)
     .setSize((int)(100 * uiScale), (int)(30 * uiScale)); // Cast to int
  
  // Add the toggle for curved or straight lines
  cp5.addToggle("smoothLines")
     .setLabel("Curved/Straight Lines")
     .setPosition((int)(20 * uiScale), (int)(270 * uiScale)) // Cast to int
     .setSize((int)(20 * uiScale), (int)(20 * uiScale)) // Cast to int
     .setLock(true)
     .setValue(true);
     
  // Add a toggle button for freezeTime
  cp5.addToggle("freezeTimeToggle")
     .setLabel("Freeze Time")
     .setPosition((int)(20 * uiScale), (int)(440 * uiScale)) // Position below the sampleSlider
     .setSize((int)(20 * uiScale), (int)(20 * uiScale)) // Same size as the smoothLines toggle
     .setLock(true)
     .setValue(freezeTime); // Set the initial value to match the freezeTime variable
     
  // Add a toggle for enlarging sliders during interaction
  cp5.addToggle("enlargeSlidersToggle")
     .setLabel("Enlarge Sliders")
     .setPosition((int)(20 * uiScale), (int)(470 * uiScale)) // Position below the freezeTime toggle
     .setSize((int)(20 * uiScale), (int)(20 * uiScale)) // Same size as other toggles
     .setLock(true)
     .setValue(false); // Default to off
  
  // Add text field for "Pixels Per Sample"
  cp5.addTextfield("Pixels Per Sample")
     .setPosition((int)(150 * uiScale), (int)(290 * uiScale)) // Cast to int
     .setSize((int)(60 * uiScale), (int)(20 * uiScale)) // Cast to int
     .setText(str(baseNumSamples))
     .setAutoClear(false);
  
  // Add sliders for frequency multipliers
  freq1Slider = cp5.addSlider("freq1Multiplier")
     .setPosition((int)(20 * uiScale), (int)(320 * uiScale))
     .setSize((int)(200 * uiScale), (int)(20 * uiScale))
     .setRange(0.1, 10)
     .setValue(1.0)
     .setLock(true)
     .setLabel("Freq1 Multiplier");

  freq2Slider = cp5.addSlider("freq2Multiplier")
     .setPosition((int)(20 * uiScale), (int)(350 * uiScale))
     .setSize((int)(200 * uiScale), (int)(20 * uiScale))
     .setRange(0.1, 10)
     .setValue(1.0)
     .setLock(true)
     .setLabel("Freq2 Multiplier");

  freq3Slider = cp5.addSlider("freq3Multiplier")
     .setPosition((int)(20 * uiScale), (int)(380 * uiScale))
     .setSize((int)(200 * uiScale), (int)(20 * uiScale))
     .setRange(0.1, 10)
     .setValue(1.0)
     .setLock(true)
     .setLabel("Freq3 Multiplier");
     
  sampleSlider = cp5.addSlider("numSamplesMultiplier")
     .setPosition((int)(20 * uiScale), (int)(410 * uiScale)) // Position below the frequency sliders
     .setSize((int)(200 * uiScale), (int)(20 * uiScale))
     .setRange(0.1, 10) // Set the range of the multiplier
     .setValue(1.0) // Default value
     .setLock(true)
     .setLabel("Samples Multiplier");
     
  timeMultiplierSlider = cp5.addSlider("timeMultiplier")
       .setPosition((int)(250 * uiScale), (int)(200 * uiScale)) // Position to the right of other sliders
       .setSize((int)(20 * uiScale), (int)(200 * uiScale)) // Vertical slider (width, height)
       .setRange(0.1, 10.0) // Range from -500 to 500
       .setValue(1.0) // Start in the middle
       .setLock(true)
       .setLabel("Time Multiplier")
       .setSliderMode(Slider.FLEXIBLE); // Make it vertical
       
  // Enlarged timeMultiplierSlider (hidden initially)
  enlargedTimeMultiplierSlider = cp5.addSlider("enlargedTimeMultiplier")
       .setPosition((int)(250 * uiScale), (int)(200 * uiScale - (enlargedSliderHeight - originalSliderHeight))) // Adjust y position to grow upwards
       .setSize((int)(40 * uiScale), (int)(400 * uiScale)) // Larger size
       .setRange(0.1, 10.0)
       .setValue(1.0)
       .setLock(true)
       .setLabel("Time Multiplier (Enlarged)")
       .setSliderMode(Slider.FLEXIBLE) // Make it vertical
       .setVisible(false); // Hide initially


  // Initialize default functions
  xFunctionStr = "sin(2 * pi * freq1 * t + time)";
  yFunctionStr = "cos(2 * pi * freq2 * t + time)";
  zFunctionStr = "sin(2 * pi * freq3 * t + time)";

  // Define custom functions
  squareFunc = new Function("square", 1) {
    @Override
    public double apply(double... args) {
      return Math.signum(Math.sin(args[0]));
    }
  };

  sawFunc = new Function("saw", 1) {
    @Override
    public double apply(double... args) {
      double t = args[0] % (2 * Math.PI);
      return 2 * (t / (2 * Math.PI)) - 1;
    }
  };

  triangleFunc = new Function("triangle", 1) {
    @Override
    public double apply(double... args) {
      double t = args[0] % (2 * Math.PI);
      double val = 2 * Math.abs(2 * (t / (2 * Math.PI) - Math.floor(t / (2 * Math.PI) + 0.5))) - 1;
      return val;
    }
  };

  absSinFunc = new Function("abs_sin", 1) {
    @Override
    public double apply(double... args) {
      return Math.abs(Math.sin(args[0]));
    }
  };

  // Build expressions including 'time', 'freq3', and 'phi' variables
  try {
    xExpression = new ExpressionBuilder(xFunctionStr)
                    .variables("t", "time", "freq1", "freq2", "freq3", "pi", "e", "phi")
                    .function(squareFunc)
                    .function(sawFunc)
                    .function(triangleFunc)
                    .function(absSinFunc)
                    .build();
    yExpression = new ExpressionBuilder(yFunctionStr)
                    .variables("t", "time", "freq1", "freq2", "freq3", "pi", "e", "phi")
                    .function(squareFunc)
                    .function(sawFunc)
                    .function(triangleFunc)
                    .function(absSinFunc)
                    .build();
    zExpression = new ExpressionBuilder(zFunctionStr)
                    .variables("t", "time", "freq1", "freq2", "freq3", "pi", "e", "phi")
                    .function(squareFunc)
                    .function(sawFunc)
                    .function(triangleFunc)
                    .function(absSinFunc)
                    .build();
  } catch (Exception e) {
    println("Error compiling functions: " + e.getMessage());
  }

  // Create PGraphics object with the same resolution as the window
  pg = createGraphics(width, height, P3D);

  // Set up smooth lines
  smooth();

  // All controllers are now initialized
  controllersInitialized = true;
  
  // Keep the screen on
  Context context = getContext(); // Get the Android context
  PowerManager powerManager = (PowerManager) context.getSystemService(Context.POWER_SERVICE);
  wakeLock = powerManager.newWakeLock(PowerManager.SCREEN_BRIGHT_WAKE_LOCK, "Processing:ScreenOn");
  wakeLock.acquire();
}


// Method to handle the freezeTime toggle event
public void freezeTimeToggle(boolean theValue) {
  freezeTime = theValue; // Update the freezeTime variable
  if (freezeTime) {
    frozenTime = millis() / 1000.0 * timeMultiplier; // Store the current time when freezing
  }
}

void draw() {
  background(0);

  pg.beginDraw();
  // Clear with transparency for alpha support
  pg.clear();

  // Set up 3D camera with zoom in pg
  pg.translate(pg.width / 2, pg.height / 2, -200 * zoom);
  pg.scale(zoom);

  pg.rotateX(rotationX);
  pg.rotateY(rotationY);

  pg.stroke(0, 255, 0);
  pg.noFill();

  // Determine the number of samples to draw based on pixelsPerSample and the multiplier
  int numSamplesToDraw = max(1, (int)(baseNumSamples / pixelsPerSample * cp5.getController("numSamplesMultiplier").getValue()));

  // Update vertices
  xVertices = new float[numSamplesToDraw];
  yVertices = new float[numSamplesToDraw];
  zVertices = new float[numSamplesToDraw];

  // Calculate the time variable
  double currentTime;
  if (freezeTime) {
    currentTime = frozenTime;
  } else {
    currentTime = millis() / 1000.0 * timeMultiplier;
  }


  // "t" is a normalized parameter that ranges from 0 to 1
  // Its used to parameterize mathematical functions for generating coordinates.
  // Its progression ensures smooth transitions and animations in the visualization.
  // "t" is calculated as i / (double) numSamplesToDraw, where i is the current iteration index in the loop, 
  // and numSamplesToDraw is the total number of samples to be drawn. 
  // This ensures that t ranges from 0 (at the start of the loop) to 1 (at the end of the loop).
  // "t" acts as a parameter that progresses uniformly through the range of samples. 
  // Its often used in mathematical functions to generate smooth transitions or animations.
  for (int i = 0; i < numSamplesToDraw; i++) {
    double t = i / (double) numSamplesToDraw; // t from 0 to 1

    // Set variables and evaluate expressions
    xExpression.setVariable("t", t)
               .setVariable("time", currentTime)
               .setVariable("freq1", freq1)
               .setVariable("freq2", freq2)
               .setVariable("freq3", freq3)
               .setVariable("pi", Math.PI)
               .setVariable("e", Math.E)
               .setVariable("phi", phi);

    yExpression.setVariable("t", t)
               .setVariable("time", currentTime)
               .setVariable("freq1", freq1)
               .setVariable("freq2", freq2)
               .setVariable("freq3", freq3)
               .setVariable("pi", Math.PI)
               .setVariable("e", Math.E)
               .setVariable("phi", phi);

    zExpression.setVariable("t", t)
               .setVariable("time", currentTime)
               .setVariable("freq1", freq1)
               .setVariable("freq2", freq2)
               .setVariable("freq3", freq3)
               .setVariable("pi", Math.PI)
               .setVariable("e", Math.E)
               .setVariable("phi", phi);

    double x = 0, y = 0, z = 0;
    try {
      x = xExpression.evaluate();
      y = yExpression.evaluate();
      z = zExpression.evaluate();
    } catch (Exception e) {
      println("Error evaluating functions: " + e.getMessage());
    }

    // Apply timeScale if the toggle is enabled for each axis
    xVertices[i] = applyTimeScaleX ? (float) (x * 300 * timeScale) : (float) (x * 300);
    yVertices[i] = applyTimeScaleY ? (float) (y * 300 * timeScale) : (float) (y * 300);
    zVertices[i] = applyTimeScaleZ ? (float) (z * 300 * timeScale) : (float) (z * 300);
  }

  // Draw the shape using stored vertices
  if (smoothLines && xVertices.length >= 4) {
    // Create arrays for control points
    float[] xCtrl = new float[xVertices.length + 2];
    float[] yCtrl = new float[yVertices.length + 2];
    float[] zCtrl = new float[zVertices.length + 2];

    // Set control points
    if (xVertices.length >= 2) {
      xCtrl[0] = xVertices[0] - (xVertices[1] - xVertices[0]);
      yCtrl[0] = yVertices[0] - (yVertices[1] - yVertices[0]);
      zCtrl[0] = zVertices[0] - (zVertices[1] - zVertices[0]);

      for (int i = 0; i < xVertices.length; i++) {
        xCtrl[i + 1] = xVertices[i];
        yCtrl[i + 1] = yVertices[i];
        zCtrl[i + 1] = zVertices[i];
      }

      int last = xVertices.length - 1;
      xCtrl[xCtrl.length - 1] = xVertices[last] + (xVertices[last] - xVertices[last - 1]);
      yCtrl[yCtrl.length - 1] = yVertices[last] + (yVertices[last] - yVertices[last - 1]);
      zCtrl[zCtrl.length - 1] = zVertices[last] + (zVertices[last] - zVertices[last - 1]);
    } else {
      // Not enough points for curve; duplicate points
      xCtrl[0] = xCtrl[1] = xCtrl[2] = xVertices[0];
      yCtrl[0] = yCtrl[1] = yCtrl[2] = yVertices[0];
      zCtrl[0] = zCtrl[1] = zCtrl[2] = zVertices[0];
    }

    // Now draw the curve
    pg.beginShape();
    for (int i = 1; i < xCtrl.length - 2; i++) {
      pg.curveVertex(xCtrl[i], yCtrl[i], zCtrl[i]);
    }
    pg.endShape();
  } else {
    pg.beginShape();
    for (int i = 0; i < xVertices.length; i++) {
      pg.vertex(xVertices[i], yVertices[i], zVertices[i]);
    }
    pg.endShape();
  }

  pg.endDraw();

  // Display the main PGraphics on screen
  image(pg, 0, 0);

  // Update last mouse positions
  lastMouseX = mouseX;
  lastMouseY = mouseY;

  // Draw the GUI if it's visible
  if (guiVisible) {
    cp5.draw();
  }

  // Draw custom text fields for x, y, z functions and frequencies if visible
  if (customFieldsVisible) {
    fill(255);
    textSize(16 * uiScale);
    text("x(t): " + xFunctionStr, 20 * uiScale, 40 * uiScale);
    text("y(t): " + yFunctionStr, 20 * uiScale, 80 * uiScale);
    text("z(t): " + zFunctionStr, 20 * uiScale, 120 * uiScale);

    text("freq1: " + freq1Str, 20 * uiScale, 160 * uiScale);
    text("freq2: " + freq2Str, 20 * uiScale, 200 * uiScale);
    text("freq3: " + freq3Str, 20 * uiScale, 240 * uiScale);
  }

  // Draw the cursor
  if (keyboardVisible && cursorVisible) {
    int cursorX = (int)(20 * uiScale);
    int cursorY = (int)(40 * uiScale); // Default y position for xFunction
    String activeText = "";
    String staticPrefix = ""; // Static text prefix for each field
    if (activeTextField.equals("xFunction")) {
      activeText = xFunctionStr;
      staticPrefix = "x(t): ";
      cursorY = (int)(40 * uiScale); // y position for xFunction
    } else if (activeTextField.equals("yFunction")) {
      activeText = yFunctionStr;
      staticPrefix = "y(t): ";
      cursorY = (int)(80 * uiScale); // y position for yFunction
    } else if (activeTextField.equals("zFunction")) {
      activeText = zFunctionStr;
      staticPrefix = "z(t): ";
      cursorY = (int)(120 * uiScale); // y position for zFunction
    } else if (activeTextField.equals("freq1")) {
      activeText = freq1Str;
      staticPrefix = "freq1: ";
      cursorY = (int)(160 * uiScale); // y position for freq1
    } else if (activeTextField.equals("freq2")) {
      activeText = freq2Str;
      staticPrefix = "freq2: ";
      cursorY = (int)(200 * uiScale); // y position for freq2
    } else if (activeTextField.equals("freq3")) {
      activeText = freq3Str;
      staticPrefix = "freq3: ";
      cursorY = (int)(240 * uiScale); // y position for freq3
    }
  
    // Calculate the cursor's horizontal position
    textSize(16 * uiScale); // Set the text size to match the scaled UI
    float prefixWidth = textWidth(staticPrefix); // Width of the static prefix
    cursorX = (int)(20 * uiScale + prefixWidth + textWidth(activeText.substring(0, cursorPosition)));
  
    // Ensure the cursor stays within the text field bounds
    int textFieldWidth = (int)(300 * uiScale); // Width of the text field
    if (cursorX > (int)(20 * uiScale + textFieldWidth)) {
      cursorX = (int)(20 * uiScale + textFieldWidth); // Constrain cursor to the right edge of the text field
    }
  
    // Draw the cursor
    stroke(255);
    line(cursorX, cursorY, cursorX, cursorY - (int)(20 * uiScale)); // Draw cursor at the correct y position
  }

  // Blink the cursor
  if (frameCount % cursorBlinkRate == 0) {
    cursorVisible = !cursorVisible;
  }
}

void applyFunctions() {
  try {
    // Rebuild expressions with updated functions
    xExpression = new ExpressionBuilder(xFunctionStr)
                    .variables("t", "time", "freq1", "freq2", "freq3", "pi", "e", "phi")
                    .function(squareFunc)
                    .function(sawFunc)
                    .function(triangleFunc)
                    .function(absSinFunc)
                    .build();
    yExpression = new ExpressionBuilder(yFunctionStr)
                    .variables("t", "time", "freq1", "freq2", "freq3", "pi", "e", "phi")
                    .function(squareFunc)
                    .function(sawFunc)
                    .function(triangleFunc)
                    .function(absSinFunc)
                    .build();
    zExpression = new ExpressionBuilder(zFunctionStr)
                    .variables("t", "time", "freq1", "freq2", "freq3", "pi", "e", "phi")
                    .function(squareFunc)
                    .function(sawFunc)
                    .function(triangleFunc)
                    .function(absSinFunc)
                    .build();
  } catch (Exception e) {
    println("Error compiling functions: " + e.getMessage());
  }
  println(xFunctionStr);

  // Update base frequencies from the text fields
  baseFreq1 = parseFrequency(freq1Str, baseFreq1); // Get the base frequency from the text field
  baseFreq2 = parseFrequency(freq2Str, baseFreq2); // Get the base frequency from the text field
  baseFreq3 = parseFrequency(freq3Str, baseFreq3); // Get the base frequency from the text field

  // Apply the frequency multipliers from the sliders and truncate the result
  freq1 = truncate(baseFreq1 * cp5.getController("freq1Multiplier").getValue(), decimalPlaces);
  freq2 = truncate(baseFreq2 * cp5.getController("freq2Multiplier").getValue(), decimalPlaces);
  freq3 = truncate(baseFreq3 * cp5.getController("freq3Multiplier").getValue(), decimalPlaces);

  // Format the frequency strings to the desired number of decimal places
  // freq1Str = formatNumber(baseFreq1, decimalPlaces); // Display base frequency
  // freq2Str = formatNumber(baseFreq2, decimalPlaces); // Display base frequency
  // freq3Str = formatNumber(baseFreq3, decimalPlaces); // Display base frequency

  println("Functions updated:");
  println("x(t) = " + xFunctionStr);
  println("y(t) = " + yFunctionStr);
  println("z(t) = " + zFunctionStr);
  println("freq1 = " + freq1);
  println("freq2 = " + freq2);
  println("freq3 = " + freq3);
}

// Handle touch events to open/close the keyboard
void mousePressed() {
  // Check if the user tapped on the x(t) field
  if (mouseX > 20 * uiScale && mouseX < 320 * uiScale && mouseY > 20 * uiScale && mouseY < 40 * uiScale) {
    if (!activeTextField.equals("xFunction")) {
      activeTextField = "xFunction";
      ketaiKeyboard.show(this);
      keyboardVisible = true;
    }
    cursorPosition = getCursorPosition(xFunctionStr, (int)(mouseX - 20 * uiScale), xFunctionStr);
  }
  // Check if the user tapped on the y(t) field
  else if (mouseX > 20 * uiScale && mouseX < 320 * uiScale && mouseY > 60 * uiScale && mouseY < 80 * uiScale) {
    if (!activeTextField.equals("yFunction")) {
      activeTextField = "yFunction";
      ketaiKeyboard.show(this);
      keyboardVisible = true;
    }
    cursorPosition = getCursorPosition(yFunctionStr, (int)(mouseX - 20 * uiScale), yFunctionStr);
  }
  // Check if the user tapped on the z(t) field
  else if (mouseX > 20 * uiScale && mouseX < 320 * uiScale && mouseY > 100 * uiScale && mouseY < 120 * uiScale) {
    if (!activeTextField.equals("zFunction")) {
      activeTextField = "zFunction";
      ketaiKeyboard.show(this);
      keyboardVisible = true;
    }
    cursorPosition = getCursorPosition(zFunctionStr, (int)(mouseX - 20 * uiScale), zFunctionStr);
  }
  // Check if the user tapped on the freq1 field
  else if (mouseX > 20 * uiScale && mouseX < 320 * uiScale && mouseY > 140 * uiScale && mouseY < 160 * uiScale) {
    if (!activeTextField.equals("freq1")) {
      activeTextField = "freq1";
      ketaiKeyboard.show(this);
      keyboardVisible = true;
    }
    cursorPosition = getCursorPosition(freq1Str, (int)(mouseX - 20 * uiScale), freq1Str);
  }
  // Check if the user tapped on the freq2 field
  else if (mouseX > 20 * uiScale && mouseX < 320 * uiScale && mouseY > 180 * uiScale && mouseY < 200 * uiScale) {
    if (!activeTextField.equals("freq2")) {
      activeTextField = "freq2";
      ketaiKeyboard.show(this);
      keyboardVisible = true;
    }
    cursorPosition = getCursorPosition(freq2Str, (int)(mouseX - 20 * uiScale), freq2Str);
  }
  // Check if the user tapped on the freq3 field
  else if (mouseX > 20 * uiScale && mouseX < 320 * uiScale && mouseY > 220 * uiScale && mouseY < 240 * uiScale) {
    if (!activeTextField.equals("freq3")) {
      activeTextField = "freq3";
      ketaiKeyboard.show(this);
      keyboardVisible = true;
    }
    cursorPosition = getCursorPosition(freq3Str, (int)(mouseX - 20 * uiScale), freq3Str);
  }
}

void mouseReleased() {
  isInteractingWithSlider = false; // Reset the flag when the mouse is released
}

// Handle keyboard input
void keyPressed() {
  if (keyboardVisible) {
    if (key == '\n' || key == ENTER) { // Enter key
      ketaiKeyboard.hide(this);
      keyboardVisible = false;
      applyFunctions();
    } else if (keyCode == DELETE || keyCode == BACKSPACE || keyCode == BACK) { // BACK for Android BACKSPACE key
      if (activeTextField.equals("xFunction") && xFunctionStr.length() > 0 && cursorPosition > 0) {
        xFunctionStr = xFunctionStr.substring(0, cursorPosition - 1) + xFunctionStr.substring(cursorPosition);
        cursorPosition--;
      } else if (activeTextField.equals("yFunction") && yFunctionStr.length() > 0 && cursorPosition > 0) {
        yFunctionStr = yFunctionStr.substring(0, cursorPosition - 1) + yFunctionStr.substring(cursorPosition);
        cursorPosition--;
      } else if (activeTextField.equals("zFunction") && zFunctionStr.length() > 0 && cursorPosition > 0) {
        zFunctionStr = zFunctionStr.substring(0, cursorPosition - 1) + zFunctionStr.substring(cursorPosition);
        cursorPosition--;
      } else if (activeTextField.equals("freq1") && freq1Str.length() > 0 && cursorPosition > 0) {
        freq1Str = freq1Str.substring(0, cursorPosition - 1) + freq1Str.substring(cursorPosition);
        cursorPosition--;
      } else if (activeTextField.equals("freq2") && freq2Str.length() > 0 && cursorPosition > 0) {
        freq2Str = freq2Str.substring(0, cursorPosition - 1) + freq2Str.substring(cursorPosition);
        cursorPosition--;
      } else if (activeTextField.equals("freq3") && freq3Str.length() > 0 && cursorPosition > 0) {
        freq3Str = freq3Str.substring(0, cursorPosition - 1) + freq3Str.substring(cursorPosition);
        cursorPosition--;
      }
    } else if (key != CODED) {
      if (activeTextField.equals("xFunction")) {
        xFunctionStr = xFunctionStr.substring(0, cursorPosition) + key + xFunctionStr.substring(cursorPosition);
        cursorPosition++;
      } else if (activeTextField.equals("yFunction")) {
        yFunctionStr = yFunctionStr.substring(0, cursorPosition) + key + yFunctionStr.substring(cursorPosition);
        cursorPosition++;
      } else if (activeTextField.equals("zFunction")) {
        zFunctionStr = zFunctionStr.substring(0, cursorPosition) + key + zFunctionStr.substring(cursorPosition);
        cursorPosition++;
      } else if (activeTextField.equals("freq1")) {
        freq1Str = freq1Str.substring(0, cursorPosition) + key + freq1Str.substring(cursorPosition);
        cursorPosition++;
      } else if (activeTextField.equals("freq2")) {
        freq2Str = freq2Str.substring(0, cursorPosition) + key + freq2Str.substring(cursorPosition);
        cursorPosition++;
      } else if (activeTextField.equals("freq3")) {
        freq3Str = freq3Str.substring(0, cursorPosition) + key + freq3Str.substring(cursorPosition);
        cursorPosition++;
      }
    }
  }
}

double truncate(double value, int decimalPlaces) {
  double scale = Math.pow(10, decimalPlaces);
  return Math.floor(value * scale) / scale;
}

// Helper function to get cursor position based on mouse click
int getCursorPosition(String text, int mouseX, String activeText) {
  int pos = 0;
  float textWidth = 0;
  String staticPrefix = ""; // Static text prefix for each field

  // Set the static prefix based on the active text field
  if (activeTextField.equals("xFunction")) {
    staticPrefix = "x(t): ";
  } else if (activeTextField.equals("yFunction")) {
    staticPrefix = "y(t): ";
  } else if (activeTextField.equals("zFunction")) {
    staticPrefix = "z(t): ";
  } else if (activeTextField.equals("freq1")) {
    staticPrefix = "freq1: ";
  } else if (activeTextField.equals("freq2")) {
    staticPrefix = "freq2: ";
  } else if (activeTextField.equals("freq3")) {
    staticPrefix = "freq3: ";
  }

  // Calculate the width of the static prefix, scaled by uiScale
  textSize(16 * uiScale); // Set the text size to match the scaled UI
  float prefixWidth = textWidth(staticPrefix); // Width of the static prefix

  // Adjust mouseX to account for the static prefix and scaling
  mouseX -= (int)(20 * uiScale + prefixWidth); // 20 * uiScale is the starting x position of the text field

  // Apply the cursor offset (e.g., 60 pixels)
  int cursorOffset = 60; // Adjust this value as needed
  mouseX += cursorOffset;

  // Debug: Print touch coordinates and prefix width
  println("Touch X: " + mouseX + ", Prefix Width: " + prefixWidth);

  // Iterate through the text to find the cursor position
  for (int i = 0; i < text.length(); i++) {
    float charWidth = textWidth(text.charAt(i)); // Width of the current character
    if (mouseX < textWidth + charWidth / 2) { // Check if the click is within the character's width
      return i;
    }
    textWidth += charWidth; // Add the character's width to the total width
  }
  return text.length(); // If the click is beyond the text, return the end position
}

// Helper function to parse frequency from text field
double parseFrequency(String text, double defaultValue) {
  try {
    return Double.parseDouble(text);
  } catch (NumberFormatException e) {
    println("Invalid frequency input: " + text);
    return defaultValue;
  }
}

void touchStarted() {
  if (touches.length == 1) {
    // Check if the touch is within the bounds of any slider
    for (Slider slider : new Slider[] { freq1Slider, freq2Slider, freq3Slider, sampleSlider, timeMultiplierSlider }) {
      if (isInsideSlider(slider, touches[0].x, touches[0].y)) {
        activeSlider = slider;
        isInteractingWithSlider = true; // Set the interaction flag

        // Enlarge the slider if the toggle is on
        if (cp5.getController("enlargeSlidersToggle").getValue() == 1) {
          if (slider == timeMultiplierSlider) {
            // Hide the original slider and show the enlarged one
            timeMultiplierSlider.setVisible(false);
            enlargedTimeMultiplierSlider.setPosition(
              (int)(250 * uiScale), // x position remains the same
              (int)(200 * uiScale + originalSliderHeight - enlargedSliderHeight - 280) // y position adjusted to align bottom edges
            );
            enlargedTimeMultiplierSlider.setVisible(true);
            activeSlider = enlargedTimeMultiplierSlider; // Set the active slider to the enlarged one
          } else {
            // For other sliders, just resize them
            slider.setSize((int)enlargedSliderWidth, (int)enlargedSliderHeight);
          }
        }
        break;
      }
    }

    // Explicitly check for buttons and toggles
    checkButtonOrToggle("applyFunctions", touches[0].x, touches[0].y);
    checkButtonOrToggle("smoothLines", touches[0].x, touches[0].y);
    checkButtonOrToggle("freezeTimeToggle", touches[0].x, touches[0].y);
    checkButtonOrToggle("enlargeSlidersToggle", touches[0].x, touches[0].y);
  }

  // Handle other touch interactions (e.g., pinch-to-zoom, rotation)
  if (touches.length == 3) {
    // Toggle GUI visibility and custom fields visibility
    touchInteractionMode = 3;
    guiVisible = !guiVisible;
    customFieldsVisible = !customFieldsVisible;
    if (guiVisible) {
      cp5.show();
    } else {
      cp5.hide();
    }
  } else if (touches.length == 2 && touchInteractionMode != 3) {
    // Start pinch-to-zoom
    touchInteractionMode = 1;
    initialPinchDistance = dist(touches[0].x, touches[0].y, touches[1].x, touches[1].y);
    initialZoom = zoom; // Store the initial zoom level
  } else if (touches.length == 1 && touchInteractionMode != 1 && touchInteractionMode != 3) {
    // Start rotation
    touchInteractionMode = 2;
    lastMouseX = (int) touches[0].x;
    lastMouseY = (int) touches[0].y;
  }
}

// Helper function to check if a touch is inside a button or toggle
void checkButtonOrToggle(String name, float x, float y) {
  Controller<?> controller = cp5.getController(name);
  if (controller != null) {
    if (controller instanceof Button || controller instanceof Toggle) {
      float controllerX = controller.getPosition()[0];
      float controllerY = controller.getPosition()[1];
      float controllerWidth = controller.getWidth();
      float controllerHeight = controller.getHeight();

      // Debug: Print controller bounds
      //println("Controller: " + name + " at (" + controllerX + ", " + controllerY + ") with size (" + controllerWidth + ", " + controllerHeight + ")");

      if (x >= controllerX && x <= controllerX + controllerWidth && y >= controllerY && y <= controllerY + controllerHeight) {
        // Debug: Print controller names
        //println("Controller pressed: " + name);
        if (controller instanceof Button) {
          ((Button) controller).setValue(1); // Simulate a button press
        } else if (controller instanceof Toggle) {
          // Toggle the value of the specific toggle
          Toggle toggle = (Toggle) controller;
          toggle.setValue(!toggle.getBooleanValue()); // Toggle the state
        }
      }
    }
  }
}

void touchMoved() {
  if (activeSlider != null && touches.length == 1) {
    // Update the slider value based on touch position
    float newValue = getSliderValueFromPosition(activeSlider, touches[0].x, touches[0].y);
    activeSlider.setValue(newValue);
  }

  // Handle other touch interactions (e.g., pinch-to-zoom, rotation)
  if (touchInteractionMode == 1 && touches.length == 2) {
    // Pinch-to-zoom
    float currentPinchDistance = dist(touches[0].x, touches[0].y, touches[1].x, touches[1].y);
    zoom = initialZoom * (currentPinchDistance / initialPinchDistance);
    zoom = constrain(zoom, 0.1, 10); // Constrain zoom to a reasonable range
  } else if (touchInteractionMode == 2 && touches.length == 1 && !isInteractingWithSlider) {
    // Rotation (only if not interacting with a slider)
    int currentMouseX = (int) touches[0].x;
    int currentMouseY = (int) touches[0].y;

    float deltaX = currentMouseX - lastMouseX;
    float deltaY = currentMouseY - lastMouseY;

    if (deltaX != 0 || deltaY != 0) {
      rotationY += deltaX * 0.01; // Adjust sensitivity as needed
      rotationX += deltaY * 0.01;
    }

    lastMouseX = currentMouseX;
    lastMouseY = currentMouseY;
  }
}

void touchEnded() {
  if (activeSlider != null) {
    // Restore the slider to its original size if the toggle is on
    if (cp5.getController("enlargeSlidersToggle").getValue() == 1) {
      if (activeSlider == enlargedTimeMultiplierSlider) {
        // Copy the value from the enlarged slider to the original slider
        timeMultiplierSlider.setValue(enlargedTimeMultiplierSlider.getValue());
        
        // Hide the enlarged slider and show the original one
        enlargedTimeMultiplierSlider.setVisible(false);
        timeMultiplierSlider.setVisible(true);
      } else {
        // For other sliders, restore their original size
        activeSlider.setSize((int)originalSliderWidth, (int)originalSliderHeight);
      }
    }
    activeSlider = null; // Reset the active slider
    isInteractingWithSlider = false; // Reset the interaction flag
  }

  // Reset the touch interaction mode when all touches are released
  if (touches.length == 0) {
    touchInteractionMode = 0;
  }
}

boolean isInsideSlider(Slider slider, float x, float y) {
  float sliderX = slider.getPosition()[0];
  float sliderY = slider.getPosition()[1];
  float sliderWidth = slider.getWidth();
  float sliderHeight = slider.getHeight();
  return x >= sliderX && x <= sliderX + sliderWidth && y >= sliderY && y <= sliderY + sliderHeight;
}

float getSliderValueFromPosition(Slider slider, float x, float y) {
  float sliderX = slider.getPosition()[0];
  float sliderY = slider.getPosition()[1];
  float sliderWidth = slider.getWidth();
  float sliderHeight = slider.getHeight();
  float minValue = slider.getMin();
  float maxValue = slider.getMax();

  if (slider.getSliderMode() == Slider.FLEXIBLE) {
    // Vertical slider: use y-coordinate (inverted)
    float normalizedValue = 1.0 - ((y - sliderY) / sliderHeight);
    return minValue + normalizedValue * (maxValue - minValue);
  } else {
    // Horizontal slider: use x-coordinate
    float normalizedValue = (x - sliderX) / sliderWidth;
    return minValue + normalizedValue * (maxValue - minValue);
  }
}

boolean isInsideButton(Button button, float x, float y) {
  float buttonX = button.getPosition()[0];
  float buttonY = button.getPosition()[1];
  float buttonWidth = button.getWidth();
  float buttonHeight = button.getHeight();
  return x >= buttonX && x <= buttonX + buttonWidth && y >= buttonY && y <= buttonY + buttonHeight;
}

// ControlP5 event handler
void controlEvent(ControlEvent theEvent) {
  // Do not process events until controllers are fully initialized
  if (!controllersInitialized) return;

  String name = theEvent.getName();

  if (name.equals("freq1Multiplier") || name.equals("freq2Multiplier") || name.equals("freq3Multiplier") || name.equals("numSamplesMultiplier") || name.equals("timeMultiplier") || name.equals("enlargedTimeMultiplier")) {
    isInteractingWithSlider = true; // Set the flag when interacting with a slider

    if (name.equals("freq1Multiplier")) {
      freq1 = truncate(baseFreq1 * theEvent.getController().getValue(), decimalPlaces); // Multiply base frequency by slider value and truncate
    } else if (name.equals("freq2Multiplier")) {
      freq2 = truncate(baseFreq2 * theEvent.getController().getValue(), decimalPlaces); // Multiply base frequency by slider value and truncate
    } else if (name.equals("freq3Multiplier")) {
      freq3 = truncate(baseFreq3 * theEvent.getController().getValue(), decimalPlaces); // Multiply base frequency by slider value and truncate
    } else if (name.equals("numSamplesMultiplier")) {
      // Update the number of samples to draw based on the multiplier
      int numSamplesToDraw = max(1, (int)(baseNumSamples / pixelsPerSample * theEvent.getController().getValue()));
    } else if (name.equals("timeMultiplier") || name.equals("enlargedTimeMultiplier")) {
      // Update the timeMultiplier based on the slider's value
      timeMultiplier = map(theEvent.getController().getValue(), 0.1, 10.0, 0.1, 10.0);
    }
  }
}

void onDestroy() {
  // Release the WakeLock
  if (wakeLock != null && wakeLock.isHeld()) {
    wakeLock.release();
  }
}
