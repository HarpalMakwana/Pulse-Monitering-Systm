import processing.serial.*;

Serial myPort;
String data;
int sensorValue = 0;

int bufferSize = 600; // Number of points in the ECG graph
float[] ecgBuffer = new float[bufferSize];
int index = 0;

PFont font;

float bpm = 0;
int bpmSum = 0;
int bpmTimer = 0;
boolean pulseDetected = false;

// For animated header color
float hueValue = 0;

void setup() {
  size(1500, 700);  // Window size
  background(0);
  frameRate(60);

  println(Serial.list());
  myPort = new Serial(this, Serial.list()[0], 9600);
  myPort.bufferUntil('\n');

  font = createFont("Consolas", 24);
  textFont(font);
}

void draw() {
  background(0);

  // Animate hue for header text
  hueValue += 0.5;
  if (hueValue > 255) {
    hueValue = 0;
  }

  // Use HSB color mode for smooth color animation
  colorMode(HSB, 255);
  textAlign(CENTER, TOP);
  textSize(36);
  fill(hueValue, 255, 255);
  text("Create By Harpal Makwana", width / 2, 10);

  // Reset to default RGB mode for other drawings
  colorMode(RGB, 255);

  // Shift origin to center for ECG drawing
  translate(width/2, height/2);

  // Draw ECG grid lines (dark green)
  stroke(0, 80, 0);
  int gridStep = 30;
  for (int x = -width/2; x < width/2; x += gridStep) {
    line(x, -height/2, x, height/2);
  }
  for (int y = -height/2; y < height/2; y += gridStep) {
    line(-width/2, y, width/2, y);
  }

  // Map sensor value to vertical position centered vertically
  float mappedY = map(sensorValue, 500, 1023, height/2 - 50, -height/2 + 50);
  ecgBuffer[index] = mappedY;
  index = (index + 1) % bufferSize;

  // Draw ECG waveform - bright green
  stroke(0, 255, 0);
  strokeWeight(2);
  noFill();
  beginShape();
  for (int i = 0; i < bufferSize; i++) {
    int pos = (index + i) % bufferSize;
    float xPos = map(i, 0, bufferSize, -width/2, width/2);
    vertex(xPos, ecgBuffer[pos]);
  }
  endShape();

  // Reset transform to draw UI elements normally
  resetMatrix();

  // Draw BPM on top-left below header text
  fill(0, 255, 0);
  textAlign(LEFT, TOP);
  textSize(32);
  text("Heart Rate (BPM): " + bpm, 10, 60);

  // Blinking heart icon top-right
  if ((frameCount / 15) % 2 == 0) {
    fill(255, 0, 0);
    textSize(48);
    textAlign(RIGHT, TOP);
    text("♥", width - 70, 10);
  }
}

void serialEvent(Serial p) {
  data = trim(p.readStringUntil('\n'));
  if (data != null && data.length() > 0) {
    try {
      sensorValue = int(data);

      int threshold = 800;
      bpmTimer++;
      if (sensorValue > threshold && !pulseDetected) {
        pulseDetected = true;
        bpmSum++;
      } else if (sensorValue < threshold) {
        pulseDetected = false;
      }

      if (bpmTimer >= 100) {
        bpm = bpmSum * 30;
        bpmSum = 0;
        bpmTimer = 0;
      }
    } catch (Exception e) {
      println("Parsing error: " + data);
    }
  }
}
