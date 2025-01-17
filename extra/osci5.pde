// Import the Minim library
import ddf.minim.*;
import ddf.minim.analysis.*;

// Import Java Sound libraries
import javax.sound.sampled.AudioSystem;
import javax.sound.sampled.Mixer;
import javax.sound.sampled.Mixer.Info;

// Import Spout library
import spout.*;

Minim minim;
AudioInput in;

int pixelsPerSample = 1;    // Controls the number of pixels per sample (zoom level)
float timeScale = 1.0;      // Controls the speed of the waveform animation
boolean adjustTimeScale = false; // Toggle for adjusting timeScale with mouse wheel

float zoom = 1.0;           // Controls the zoom level of the geometry

boolean smoothLines = false; // Toggle for smooth lines

// Spout variables
Spout spout;
boolean useSpout = false; // Set to true to enable Spout output

PGraphics pg; // PGraphics object for rendering

void setup() {
  size(1800, 1600, P3D);
  background(0);
  
  // Initialize Minim and set up audio input
  minim = new Minim(this);
  setupAudioInput();
  
  // Initialize Spout if enabled
  if (useSpout) {
    spout = new Spout(this);
    spout.createSender("ProcessingSpoutSender");
  }
  
  // Create PGraphics object
  pg = createGraphics(width, height, P3D);
  
  // Set up smooth lines
  smooth();
}

void draw() {
  background(0);
  
  pg.beginDraw();
  pg.background(0);
  
  // Set up 3D camera with zoom in pg
  pg.translate(pg.width/2, pg.height/2, -200 * zoom);
  pg.scale(zoom);
  pg.rotateX(map(mouseY, 0, height, -PI, PI));
  pg.rotateY(map(mouseX, 0, width, -PI, PI));
  
  pg.stroke(0, 255, 0);
  pg.noFill();
  
  // Determine the number of samples to draw based on pixelsPerSample
  int numSamples = in.bufferSize() / pixelsPerSample;
  numSamples = max(1, numSamples);
  
  if (smoothLines) {
    pg.beginShape();
    // Use curveVertex for smoother lines
    for (int i = 0; i < numSamples; i++) {
      int index = i * pixelsPerSample;
      if (index >= in.bufferSize()) break;
      float x = in.left.get(index) * 300;
      float y = in.right.get(index) * 300;
      float z = map(i, 0, numSamples, -200 * timeScale, 200 * timeScale);
      if (i == 0) {
        pg.curveVertex(x, y, z);
        pg.curveVertex(x, y, z);
      } else {
        pg.curveVertex(x, y, z);
      }
      if (i == numSamples - 1) {
        pg.curveVertex(x, y, z);
      }
    }
    pg.endShape();
  } else {
    pg.beginShape();
    // Use vertex for normal lines
    for (int i = 0; i < numSamples; i++) {
      int index = i * pixelsPerSample;
      if (index >= in.bufferSize()) break;
      float x = in.left.get(index) * 300;
      float y = in.right.get(index) * 300;
      float z = map(i, 0, numSamples, -200 * timeScale, 200 * timeScale);
      pg.vertex(x, y, z);
    }
    pg.endShape();
  }
  
  pg.endDraw();
  
  // Display the PGraphics on screen
  image(pg, 0, 0);
  
  // Send the texture via Spout if enabled
  if (useSpout) {
    spout.sendTexture(pg);
  }
}

void stop() {
  // Close the audio input and Minim on exit
  in.close();
  minim.stop();
  
  // Close Spout sender if enabled
  if (useSpout) {
    spout.closeSender();
  }
  super.stop();
}

void setupAudioInput() {
  // Replace with your actual mixer name
  String mixerName = "Line 1-1 (Virtual Audio Cable)";
  
  // Get mixer index by name
  int mixerIndex = getMixerIndexByName(mixerName);
  
  if (mixerIndex == -1) {
    println("Mixer '" + mixerName + "' not found. Using default input.");
    in = minim.getLineIn(Minim.STEREO, 512);
    return;
  }
  
  // Get mixer info array
  Info[] mixerInfo = AudioSystem.getMixerInfo();
  
  // List all mixers
  println("Available Mixers:");
  for (int i = 0; i < mixerInfo.length; i++) {
    println(i + ": " + mixerInfo[i].getName());
  }
  
  // Get the mixer
  Mixer mixer = AudioSystem.getMixer(mixerInfo[mixerIndex]);
  
  // Set input mixer in Minim
  minim.setInputMixer(mixer);
  
  // Get audio input
  in = minim.getLineIn(Minim.STEREO, 512, 44100, 16);
  
  println("Using mixer: " + mixerInfo[mixerIndex].getName());
}

// Function to get mixer index by name
int getMixerIndexByName(String name) {
  Info[] mixerInfo = AudioSystem.getMixerInfo();
  for (int i = 0; i < mixerInfo.length; i++) {
    if (mixerInfo[i].getName().equals(name)) {
      return i;
    }
  }
  return -1; // Not found
}

// Handle key presses
void keyPressed() {
  if (key == '+') {
    pixelsPerSample = max(1, pixelsPerSample - 1); // Zoom in
    println("Pixels Per Sample: " + pixelsPerSample);
  } else if (key == '-') {
    pixelsPerSample++; // Zoom out
    println("Pixels Per Sample: " + pixelsPerSample);
  } else if (key == 't' || key == 'T') {
    adjustTimeScale = !adjustTimeScale;
    println("Adjust Time Scale: " + adjustTimeScale);
  } else if (keyCode == UP) {
    zoom *= 1.1; // Zoom in
    println("Zoom: " + zoom);
  } else if (keyCode == DOWN) {
    zoom /= 1.1; // Zoom out
    println("Zoom: " + zoom);
  } else if (key == 's' || key == 'S') {
    smoothLines = !smoothLines; // Toggle smooth lines
    println("Smooth Lines: " + smoothLines);
  }
}

// Handle mouse wheel events
void mouseWheel(MouseEvent event) {
  if (adjustTimeScale) {
    float e = event.getCount();
    timeScale += e * 0.1;
    timeScale = max(0.1, timeScale);
    println("Time Scale: " + timeScale);
  }
}
