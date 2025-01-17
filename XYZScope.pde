// Import the ControlP5 library for GUI components
import controlP5.*;

// Import exp4j classes
import net.objecthunter.exp4j.Expression;
import net.objecthunter.exp4j.ExpressionBuilder;
import net.objecthunter.exp4j.function.Function;

// Import File class for file operations
import java.io.File;
import java.io.PrintWriter;
import java.util.ArrayList;

// Import KeyEvent for key code constants
import java.awt.event.KeyEvent;

// Import the Spout library for video output
import spout.*; // Ensure you have the correct Spout library imported

// ControlP5 object for the GUI
ControlP5 cp5;

// Expression variables for exp4j
Expression xExpression, yExpression, zExpression;

// Function strings input by the user
String xFunctionStr, yFunctionStr, zFunctionStr;

// Visualization parameters
int pixelsPerSample = 1;          // Controls the number of pixels per sample (zoom level)
float timeScale = 1.0;            // Controls the scaling factor applied to axes
boolean adjustTimeScale = true;   // Toggle for adjusting timeScale with mouse wheel
float zoom = 1.0;                 // Controls the zoom level of the geometry
boolean smoothLines = true;       // Toggle for smooth lines

// Number of samples variables
int baseNumSamples = 1024;        // Base number of samples set via text field
int numSamples = baseNumSamples;   // Actual number of samples used in drawing

// Arrays to store waveform vertices
float[] xVertices = new float[0];
float[] yVertices = new float[0];
float[] zVertices = new float[0];

// PGraphics object for rendering
PGraphics pg;

// Frequency variables
double freq1 = 1.0;
double freq2 = 1.0;
double freq3 = 1.0;               // Frequency for z-axis
boolean independentFreqs = false; // Toggle for independent frequencies

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

// Variables for controlling rotation with Shift key
float rotationX = 0;
float rotationY = 0;
int lastMouseX;
int lastMouseY;
boolean isShiftDown = false;

// Variable to track GUI visibility
boolean guiVisible = true;

// Custom functions for exp4j
Function squareFunc, sawFunc, triangleFunc, absSinFunc;

// Spout variables
boolean spoutOutput = false; // Toggle for Spout output
Spout spout;                 // Spout object for main visualization

// Consolidated PGraphics and Spout sender for additional information
PGraphics pgInfo;
Spout spoutInfo;

// Dimensions for the additional stream
int infoStreamWidth = 400;
int infoStreamHeight = 200;

// Define the golden ratio phi
double phi = 1.61803398875;

// Setup function
void setup() {
  size(1280, 800, P3D);
  background(0);
  lastMouseX = mouseX;
  lastMouseY = mouseY;

  // Initialize ControlP5 for the GUI
  cp5 = new ControlP5(this);

  // Enable auto-draw for ControlP5
  cp5.setAutoDraw(true);

  // Create text fields for x(t), y(t), z(t) functions
  cp5.addTextfield("xFunction")
     .setPosition(20, 20)
     .setSize(300, 30)
     .align(0,0,0,0)
     .setLabel("x Function")
     .setText("sin(2 * pi * freq1 * t + time)");

  cp5.addTextfield("yFunction")
     .setPosition(20, 60)
     .setSize(300, 30)
     .align(0,0,0,0)
     .setLabel("y Function")
     .setText("cos(2 * pi * freq2 * t + time)");

  cp5.addTextfield("zFunction")
     .setPosition(20, 100)
     .setSize(300, 30)
     .align(0,0,0,0)
     .setLabel("z Function")
     .setText("sin(2 * pi * freq3 * t + time)");

  // Add a button to apply the functions
  cp5.addButton("applyFunctions")
     .setLabel("Apply Functions")
     .setPosition(140, 140)
     .setSize(100, 30);

  // Add labels, textfields, sliders, and toggles for freq1, freq2, and freq3
  cp5.addTextlabel("labelFreq1")
     .setText("Frequency X:")
     .setPosition(20, 180);

  cp5.addTextfield("freq1Field")
     .setPosition(110, 180)
     .setSize(100, 20)
     .setText("1.0000000000")
     .setLabel("")
     .setAutoClear(false);

  cp5.addSlider("freq1Slider")
     .setPosition(220, 180)
     .setSize(140, 20)
     .setRange(0.1, 10)
     .setLabel("")
     .setValue((float) freq1);

  cp5.addToggle("applyTimeScaleX")
     .setPosition(370, 180)
     .setSize(20, 20)
     .setValue(applyTimeScaleX)
     .align(LEFT, LEFT,LEFT,BOTTOM)
     .setLabel("TimeScale X");
     

  cp5.addTextlabel("labelFreq2")
     .setText("Frequency Y:")
     .setPosition(20, 210);

  cp5.addTextfield("freq2Field")
     .setPosition(110, 210)
     .setSize(100, 20)
     .setText("1.0000000000")
     .setLabel("")
     .setAutoClear(false);

  cp5.addSlider("freq2Slider")
     .setPosition(220, 210)
     .setSize(140, 20)
     .setRange(0.1, 10)
     .setLabel("")
     .setValue((float) freq2);

  cp5.addToggle("applyTimeScaleY")
     .setPosition(370, 210)
     .setSize(20, 20)
     .setValue(applyTimeScaleY)
     .align(LEFT, LEFT,LEFT,BOTTOM)
     .setLabel("TimeScale Y");

  cp5.addTextlabel("labelFreq3")
     .setText("Frequency Z:")
     .setPosition(20, 240);

  cp5.addTextfield("freq3Field")
     .setPosition(110, 240)
     .setSize(100, 20)
     .setText("1.0000000000")
     .setLabel("")
     .setAutoClear(false);

  cp5.addSlider("freq3Slider")
     .setPosition(220, 240)
     .setSize(140, 20)
     .setRange(0.1, 10)
     .setLabel("")
     .setValue((float) freq3);

  cp5.addToggle("applyTimeScaleZ")
     .setPosition(370, 240)
     .setSize(20, 20)
     .setValue(applyTimeScaleZ)
     .align(LEFT, LEFT,LEFT,BOTTOM)
     .setLabel("TimeScale Z");

  // Add the toggle for independent frequencies
  cp5.addToggle("independentFreqs")
     .setLabel("Independent Frequencies")
     .setPosition(20, 270)
     .setSize(20, 20)
     .setValue(false);

  cp5.addTextfield("Pixels Per Sample")
     .setPosition(150, 290)
     .setSize(60, 20)
     .setText(str(baseNumSamples))
     .setAutoClear(false);

  // Add toggle for Spout output
  cp5.addToggle("spoutOutput")
     .setLabel("Enable Spout Output")
     .setPosition(20, 320)
     .setSize(20, 20)
     .setValue(spoutOutput);

  // Initialize default functions
  xFunctionStr = cp5.get(Textfield.class, "xFunction").getText();
  yFunctionStr = cp5.get(Textfield.class, "yFunction").getText();
  zFunctionStr = cp5.get(Textfield.class, "zFunction").getText();

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
  pg = createGraphics(1280, 800, P3D);

  // Initialize Spout for main visualization
  spout = new Spout(this);
  spout.createSender("ProcessingSpoutMainSender", 1280, 800);

  // Initialize consolidated PGraphics for additional information
  pgInfo = createGraphics(infoStreamWidth, infoStreamHeight, P2D);

  // Initialize consolidated Spout sender for additional information
  spoutInfo = new Spout(this);
  spoutInfo.createSender("InfoStream", infoStreamWidth, infoStreamHeight);

  // Set up smooth lines
  smooth();

  // All controllers are now initialized
  controllersInitialized = true;
}

// Draw function
void draw() {
  background(0);

  pg.beginDraw();
  // Clear with transparency for alpha support
  pg.clear();

  // Set up 3D camera with zoom in pg
  pg.translate(pg.width / 2, pg.height / 2, -200 * zoom);
  pg.scale(zoom);

  if (isShiftDown) {
    float deltaX = mouseX - lastMouseX;
    float deltaY = mouseY - lastMouseY;
    rotationY += deltaX * 0.01; // Adjust sensitivity as needed
    rotationX += deltaY * 0.01;
  }

  pg.rotateX(rotationX);
  pg.rotateY(rotationY);

  pg.stroke(0, 255, 0);
  pg.noFill();

  // Determine the number of samples to draw based on pixelsPerSample
  int numSamplesToDraw = max(1, baseNumSamples / pixelsPerSample);

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

  // Send the main PGraphics via Spout if enabled
  if (spoutOutput) {
    spout.sendTexture(pg);
  }

  // Update last mouse positions
  lastMouseX = mouseX;
  lastMouseY = mouseY;

  // Draw the GUI if it's visible
  if (guiVisible) {
    cp5.draw();
  }

  // Render Consolidated Info Stream
  pgInfo.beginDraw();
  pgInfo.background(0);
  pgInfo.fill(255);
  pgInfo.textSize(13);
  pgInfo.textAlign(LEFT, TOP);

  // Prepare formatted frequency strings with leading zeros
  String freq1Str = String.format("%.10f", freq1);
  String freq2Str = String.format("%.10f", freq2);
  String freq3Str = String.format("%.10f", freq3);

  // Prepare formatted time string with leading zeros
  String timeStr = String.format("%.10f", currentTime);

  // Prepare formatted timeScale strings with leading zeros
  String timeScaleXStr = applyTimeScaleX ? String.format("%.10f", timeScale) : "1.0000000000";
  String timeScaleYStr = applyTimeScaleY ? String.format("%.10f", timeScale) : "1.0000000000";
  String timeScaleZStr = applyTimeScaleZ ? String.format("%.10f", timeScale) : "1.0000000000";

  // Prepare applied pixelsPerSample value
  String appliedPixelsPerSampleStr = String.format("%d", numSamplesToDraw);

  // Combine left information (expressions and frequencies)
  String leftInfoText = "x(t) = " + xFunctionStr + "\n" +
                        "y(t) = " + yFunctionStr + "\n" +
                        "z(t) = " + zFunctionStr + "\n\n" +
                        "Frequency X: " + freq1Str + "\n" +
                        "Frequency Y: " + freq2Str + "\n" +
                        "Frequency Z: " + freq3Str;

  // Combine right information (time, timescales, and applied pixelsPerSample)
  String rightInfoText = "Current Time: " + timeStr + "\n" +
                         "TimeScale X: " + timeScaleXStr + "\n" +
                         "TimeScale Y: " + timeScaleYStr + "\n" +
                         "TimeScale Z: " + timeScaleZStr + "\n\n" +
                         "Pixels Per Sample: " + appliedPixelsPerSampleStr;

  // Render left info
  pgInfo.textAlign(LEFT, TOP);
  pgInfo.text(leftInfoText, 10, 10);

  // Render right info
  pgInfo.textAlign(RIGHT, TOP);
  pgInfo.text(rightInfoText, infoStreamWidth - 10, 70);

  pgInfo.endDraw();

  if (spoutOutput) {
  // Send Consolidated Info Stream via Spout
  spoutInfo.sendTexture(pgInfo);
}
}

// Function to apply the mathematical functions input by the user
void applyFunctions() {
  xFunctionStr = cp5.get(Textfield.class, "xFunction").getText();
  yFunctionStr = cp5.get(Textfield.class, "yFunction").getText();
  zFunctionStr = cp5.get(Textfield.class, "zFunction").getText();

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


  println("Functions updated:");
  println("x(t) = " + xFunctionStr);
  println("y(t) = " + yFunctionStr);
  println("z(t) = " + zFunctionStr);
}

// Handle key presses for interactivity
void keyPressed() {
  if (keyCode == SHIFT) {
    isShiftDown = true;
  } else if (keyCode == LEFT) {
    if (keyEvent.isControlDown()) {
      pixelsPerSample = max(1, pixelsPerSample - 1); // Decrease pixels per sample
      println("Pixels Per Sample: " + pixelsPerSample + " | Applied Pixels Per Sample: " + (baseNumSamples / pixelsPerSample));
    }
  } else if (keyCode == RIGHT) {
    if (keyEvent.isControlDown()) {
      pixelsPerSample++; // Increase pixels per sample
      println("Pixels Per Sample: " + pixelsPerSample + " | Applied Pixels Per Sample: " + (baseNumSamples / pixelsPerSample));
    }
  } else if (key == 't' || key == 'T') {
    adjustTimeScale = !adjustTimeScale;
    println("Adjust Time Scale: " + adjustTimeScale);
  } else if (keyCode == UP) {
    if (keyEvent.isControlDown()) {
      zoom *= 1.1; // Zoom in
      println("Zoom: " + zoom);
    }
  } else if (keyCode == DOWN) {
    if (keyEvent.isControlDown()) {
      zoom /= 1.1; // Zoom out
      println("Zoom: " + zoom);
    }
  } else if (keyEvent.isControlDown() && keyEvent.getKeyCode() == KeyEvent.VK_S) {
    // Ctrl + S pressed
    smoothLines = !smoothLines; // Toggle smooth lines
    println("Smooth Lines: " + smoothLines);
  } else if (keyEvent.isControlDown() && keyEvent.getKeyCode() == KeyEvent.VK_E) {
    // Ctrl + E pressed
    exportOBJ(); // Call export function
  } else if (key == '+' || key == '=') {
    timeMultiplier *= 1.1; // Increase animation speed
    println("Time Multiplier: " + timeMultiplier);
  } else if (key == '-' || key == '_') {
    timeMultiplier /= 1.1; // Decrease animation speed
    println("Time Multiplier: " + timeMultiplier);
  } else if (keyEvent.isControlDown() && keyEvent.getKeyCode() == KeyEvent.VK_P) {
    // Ctrl + P pressed
    freezeTime = !freezeTime;
    if (freezeTime) {
      // Store the current time when freezing
      frozenTime = millis() / 1000.0 * timeMultiplier;
    }
    println("Freeze Time: " + freezeTime);
  } else if (key == TAB) {
    // Toggle GUI visibility
    guiVisible = !guiVisible;
    if (guiVisible) {
      cp5.show();
    } else {
      cp5.hide();
    }
  }
}

void keyReleased() {
  if (keyCode == SHIFT) {
    isShiftDown = false;
  }
}

// Handle mouse wheel events to adjust time scale
void mouseWheel(MouseEvent event) {
  if (adjustTimeScale) {
    float e = event.getCount();
    timeScale += e * 0.1;
    timeScale = max(0.0, timeScale);
    println("Time Scale: " + timeScale);
  }
}

// Function to export the waveform as an OBJ file
void exportOBJ() {
  // Open a save dialog to choose file location
  selectOutput("Select location to save OBJ file:", "outputFileSelected");
}

// Callback function called when a file is selected
void outputFileSelected(File selection) {
  if (selection == null) {
    // User canceled
    println("Export canceled.");
    return;
  }

  String savePath = selection.getAbsolutePath();

  PrintWriter output = createWriter(savePath);

  // Write OBJ header
  output.println("# OBJ file exported from Processing");

  // Check if smoothLines is true
  if (smoothLines && xVertices.length >= 4) {
    // Use higher resolution to approximate the smooth curve
    int resolution = 10; // Increase for smoother curves
    PVector[] interpolatedPoints = getInterpolatedCurvePoints(xVertices, yVertices, zVertices, resolution);

    // Write interpolated vertices
    for (int i = 0; i < interpolatedPoints.length; i++) {
      PVector v = interpolatedPoints[i];
      output.println("v " + v.x + " " + v.y + " " + v.z);
    }

    // Write lines connecting the interpolated vertices
    for (int i = 1; i < interpolatedPoints.length; i++) {
      output.println("l " + i + " " + (i + 1));
    }
  } else {
    // Write original vertices
    for (int i = 0; i < xVertices.length; i++) {
      output.println("v " + xVertices[i] + " " + yVertices[i] + " " + zVertices[i]);
    }

    // Write lines connecting the vertices
    for (int i = 1; i < xVertices.length; i++) {
      output.println("l " + i + " " + (i + 1));
    }
  }

  output.flush();
  output.close();

  println("Waveform exported to OBJ file: " + savePath);
}

// Function to generate interpolated points for the curve
PVector[] getInterpolatedCurvePoints(float[] x, float[] y, float[] z, int resolution) {
  ArrayList<PVector> points = new ArrayList<PVector>();

  // Create control points arrays with two extra points
  int n = x.length + 2;
  float[] xCtrl = new float[n];
  float[] yCtrl = new float[n];
  float[] zCtrl = new float[n];

  // Calculate first control point
  if (x.length >= 2) {
    xCtrl[0] = x[0] - (x[1] - x[0]);
    yCtrl[0] = y[0] - (y[1] - y[0]);
    zCtrl[0] = z[0] - (z[1] - z[0]);

    // Copy original vertices
    for (int i = 0; i < x.length; i++) {
      xCtrl[i + 1] = x[i];
      yCtrl[i + 1] = y[i];
      zCtrl[i + 1] = z[i];
    }

    // Calculate last control point
    int last = x.length - 1;
    xCtrl[n - 1] = x[last] + (x[last] - x[last - 1]);
    yCtrl[n - 1] = y[last] + (y[last] - y[last - 1]);
    zCtrl[n - 1] = z[last] + (z[last] - z[last - 1]);
  } else {
    // Not enough points; duplicate
    xCtrl[0] = xCtrl[1] = xCtrl[2] = x[0];
    yCtrl[0] = yCtrl[1] = yCtrl[2] = y[0];
    zCtrl[0] = zCtrl[1] = zCtrl[2] = z[0];
  }

  // Generate interpolated points
  for (int i = 1; i < n - 2; i++) {
    for (int j = 0; j <= resolution; j++) {
      float t = j / (float) resolution;
      float interpolatedX = curvePoint(xCtrl[i - 1], xCtrl[i], xCtrl[i + 1], xCtrl[i + 2], t);
      float interpolatedY = curvePoint(yCtrl[i - 1], yCtrl[i], yCtrl[i + 1], yCtrl[i + 2], t);
      float interpolatedZ = curvePoint(zCtrl[i - 1], zCtrl[i], zCtrl[i + 1], zCtrl[i + 2], t);
      points.add(new PVector(interpolatedX, interpolatedY, interpolatedZ));
    }
  }

  return points.toArray(new PVector[points.size()]);
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

// ControlP5 event handler
void controlEvent(ControlEvent theEvent) {
  // Do not process events until controllers are fully initialized
  if (!controllersInitialized) return;

  String name = theEvent.getName();

  if (name.equals("freq1Field")) {
    freq1 = parseFrequency(cp5.get(Textfield.class, "freq1Field").getText(), freq1);

    // Update freq1Slider without triggering controlEvent
    cp5.getController("freq1Slider").setBroadcast(false);
    cp5.getController("freq1Slider").setValue((float) freq1);
    cp5.getController("freq1Slider").setBroadcast(true);

    // Update freq1Field to ensure it displays the correct value
    cp5.get(Textfield.class, "freq1Field").setText(String.format("%.10f", freq1));

    if (!independentFreqs) {
      freq2 = freq1;
      freq3 = freq1;
      cp5.get(Textfield.class, "freq2Field").setText(String.format("%.10f", freq2));
      cp5.get(Textfield.class, "freq3Field").setText(String.format("%.10f", freq3));

      // Update freq2Slider and freq3Slider without triggering controlEvent
      cp5.getController("freq2Slider").setBroadcast(false);
      cp5.getController("freq2Slider").setValue((float) freq2);
      cp5.getController("freq2Slider").setBroadcast(true);

      cp5.getController("freq3Slider").setBroadcast(false);
      cp5.getController("freq3Slider").setValue((float) freq3);
      cp5.getController("freq3Slider").setBroadcast(true);
    }
  } else if (name.equals("freq2Field")) {
    if (independentFreqs) {
      freq2 = parseFrequency(cp5.get(Textfield.class, "freq2Field").getText(), freq2);

      // Update freq2Slider without triggering controlEvent
      cp5.getController("freq2Slider").setBroadcast(false);
      cp5.getController("freq2Slider").setValue((float) freq2);
      cp5.getController("freq2Slider").setBroadcast(true);

      // Update freq2Field to ensure it displays the correct value
      cp5.get(Textfield.class, "freq2Field").setText(String.format("%.10f", freq2));
    } else {
      // Reset freq2 to match freq1
      freq2 = freq1;
      cp5.get(Textfield.class, "freq2Field").setText(String.format("%.10f", freq2));
    }
  } else if (name.equals("freq3Field")) {
    if (independentFreqs) {
      freq3 = parseFrequency(cp5.get(Textfield.class, "freq3Field").getText(), freq3);

      // Update freq3Slider without triggering controlEvent
      cp5.getController("freq3Slider").setBroadcast(false);
      cp5.getController("freq3Slider").setValue((float) freq3);
      cp5.getController("freq3Slider").setBroadcast(true);

      // Update freq3Field to ensure it displays the correct value
      cp5.get(Textfield.class, "freq3Field").setText(String.format("%.10f", freq3));
    } else {
      // Reset freq3 to match freq1
      freq3 = freq1;
      cp5.get(Textfield.class, "freq3Field").setText(String.format("%.10f", freq3));
    }
  } else if (name.equals("freq1Slider")) {
    freq1 = theEvent.getController().getValue();

    // Update freq1Field to ensure it displays the correct value
    cp5.get(Textfield.class, "freq1Field").setText(String.format("%.10f", freq1));

    if (!independentFreqs) {
      freq2 = freq1;
      freq3 = freq1;
      cp5.get(Textfield.class, "freq2Field").setText(String.format("%.10f", freq2));
      cp5.get(Textfield.class, "freq3Field").setText(String.format("%.10f", freq3));

      // Update freq2Slider and freq3Slider without triggering controlEvent
      cp5.getController("freq2Slider").setBroadcast(false);
      cp5.getController("freq2Slider").setValue((float) freq2);
      cp5.getController("freq2Slider").setBroadcast(true);

      cp5.getController("freq3Slider").setBroadcast(false);
      cp5.getController("freq3Slider").setValue((float) freq3);
      cp5.getController("freq3Slider").setBroadcast(true);
    }
  } else if (name.equals("freq2Slider")) {
    if (independentFreqs) {
      freq2 = theEvent.getController().getValue();
      cp5.get(Textfield.class, "freq2Field").setText(String.format("%.10f", freq2));
    } else {
      // Reset freq2 to match freq1
      freq2 = freq1;
      cp5.get(Textfield.class, "freq2Field").setText(String.format("%.10f", freq2));
    }
  } else if (name.equals("freq3Slider")) {
    if (independentFreqs) {
      freq3 = theEvent.getController().getValue();
      cp5.get(Textfield.class, "freq3Field").setText(String.format("%.10f", freq3));
    } else {
      // Reset freq3 to match freq1
      freq3 = freq1;
      cp5.get(Textfield.class, "freq3Field").setText(String.format("%.10f", freq3));
    }
  } else if (name.equals("independentFreqs")) {
    independentFreqs = cp5.get(Toggle.class, "independentFreqs").getState();

    // Enable or disable freq2 and freq3 fields and sliders
    cp5.get(Textfield.class, "freq2Field").setLock(!independentFreqs);
    cp5.get(Textfield.class, "freq3Field").setLock(!independentFreqs);
    cp5.getController("freq2Slider").setLock(!independentFreqs);
    cp5.getController("freq3Slider").setLock(!independentFreqs);

    if (!independentFreqs) {
      // Synchronize frequencies
      freq2 = freq1;
      freq3 = freq1;
      cp5.get(Textfield.class, "freq2Field").setText(String.format("%.10f", freq2));
      cp5.get(Textfield.class, "freq3Field").setText(String.format("%.10f", freq3));

      // Update freq2Slider and freq3Slider without triggering controlEvent
      cp5.getController("freq2Slider").setBroadcast(false);
      cp5.getController("freq2Slider").setValue((float) freq2);
      cp5.getController("freq2Slider").setBroadcast(true);

      cp5.getController("freq3Slider").setBroadcast(false);
      cp5.getController("freq3Slider").setValue((float) freq3);
      cp5.getController("freq3Slider").setBroadcast(true);
    }
  } else if (name.equals("applyTimeScaleX")) {
    applyTimeScaleX = cp5.get(Toggle.class, "applyTimeScaleX").getState();
  } else if (name.equals("applyTimeScaleY")) {
    applyTimeScaleY = cp5.get(Toggle.class, "applyTimeScaleY").getState();
  } else if (name.equals("applyTimeScaleZ")) {
    applyTimeScaleZ = cp5.get(Toggle.class, "applyTimeScaleZ").getState();
  } else if (name.equals("Pixels Per Sample")) {
    baseNumSamples = parseInt(cp5.get(Textfield.class, "Pixels Per Sample").getText(), baseNumSamples);
    baseNumSamples = max(1, baseNumSamples);
    cp5.get(Textfield.class, "Pixels Per Sample").setText(str(baseNumSamples));
  } else if (name.equals("spoutOutput")) {
    spoutOutput = cp5.get(Toggle.class, "spoutOutput").getState();
  }
}

// Override the stop function to release Spout senders
void stop() {
  if (spout != null) {
    spout.closeSender(); // Close main Spout sender
  }
  if (spoutInfo != null) {
    spoutInfo.closeSender(); // Close consolidated Info Spout sender
  }
  super.stop();
}
