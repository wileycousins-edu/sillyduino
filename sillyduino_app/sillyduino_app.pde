// sillyduino processing app
// a silly little oscilliscope to learn stuff
// copyright 2014 by Wiley Cousins
// shared under the terms of the MIT license
// last updated april 12, 2014

// we're gonna need some serial communication
import processing.serial.*;
Serial arduino;

// scope window
int scopeWidth = 640;
int scopeHeight = 480;

// control panel
PFont f;
int controlWidth = 200;

// serial port to use
// get this from looking at your port list in the Arduino IDE
int serialPort = 5;
int serialBaud = 19200;

// array of readings from the arduino
int[] readings;
int sweep = 0;

// graph divs
// twenty horizontal divs
int timeDivs = 16;
int timeDivWidth = scopeWidth/timeDivs;
int ticksPerDiv = timeDivWidth;
int tickRatio = (timeDivWidth/ticksPerDiv);
// default mode is 1000 ms per div
int msMode = 0;
// display lines or dots
boolean lines = true;

// color stuff
color bgColor = color(0);
color cpColor = color(128);
color divColor = color(64);
color tColor = color(255);
color sColor = color(255, 0, 0);

// setup function
void setup() {
  // set our window size to w: 640, h: 480
  size(scopeWidth + controlWidth, scopeHeight);

  // get our font ready
  f = createFont("Arial", 16);

  // get our data array ready
  readings = new int[scopeWidth];

  // connect to our arduino
  println("connecting to arduino");
  arduino = new Serial(this, Serial.list()[serialPort], serialBaud);
  // wait for the alive signal
  while (arduino.available() == 0) {
    println("waiting");
  }
  if (arduino.read() == 127) {
    println("success!");
  }
  else {
    println("failure");
  }
  // send parameter data in bytes
  // first byte is the number of divs on the screen
  // the second byte is the number of ticks per div
  // third byte is the milliseconds per tick:
  byte[] params = { (byte)(timeDivs), (byte)(ticksPerDiv), (byte)(msMode) };
  arduino.write(params);
}

// draw function
void draw() {
  // set stroke to white and background to white
  background(bgColor);

  // get a new reading and add it to the array
  getReading();

  // draw the time divs
  drawTimeDivs();

  // draw the trace
  drawTrace();

  // draw and move the sweeper
  drawSweep();

  drawControlPanel();
}

// draw the trace
void drawTrace() {
  stroke(tColor);
  for (int i=1; i<timeDivs*ticksPerDiv; i++) {
    if (lines) {
      line((i-1)*tickRatio, readings[i-1], i*tickRatio, readings[i]);
    }
    else {
      point(i*tickRatio, readings[i]);
    }
  }
}

// draw the sweep
void drawSweep() {
  // draw a vertical line at the sweep position
  stroke(sColor);
  line(sweep*tickRatio, 0, sweep*tickRatio, scopeHeight-1);
}

// draw the time divs
void drawTimeDivs() {
  for (int i=timeDivWidth; i<scopeWidth; i+=timeDivWidth) {
    stroke(divColor);
    line(i, 0, i, scopeHeight);
  }
}

// draw the control panel
void drawControlPanel() {
  // draw the control panel box in exciting colors
  fill(cpColor);
  noStroke();
  rect(scopeWidth, 0, controlWidth, scopeHeight);

  // draw the title
  textFont(f);
  textAlign(CENTER, CENTER);
  fill(255);
  // text box is 20 tall and at the top of the control panel
  text("Control your stuff here", scopeWidth, 0, controlWidth, 20);

  // control the milliseconds per div
  text("ms per div: "+str(getMs(msMode)), scopeWidth, 40, controlWidth, 20);
  text("press '+' or '-' to change", scopeWidth, 60, controlWidth, 20);

}

// put a reading in the array
void getReading() {
  while(arduino.available() >= 4) {
    if (arduino.read() == 0xFF) {
      // get the data from the arduino
      int tick = arduino.read();
      int div = arduino.read();
      int r = arduino.read();

      // move the sweeper
      sweep = div * ticksPerDiv + tick;
      readings[sweep] = scopeHeight-(int)(map(r, 0, 255, 1, scopeHeight));
    }
  }
}

int getMs(int m) {
  int ret = 1000;
  switch (m) {
    case 0 :
      ret = 500;
      break;
    case 1 :
      ret = 200;
      break;
    case 2  :
      ret = 50;
      break;
    case 3  :
      ret = 20;
      break;
    case 4   :
      ret = 5;
      break;
    case 5   :
      ret = 2;
      break;
  }
  return ret;
}

void setMode(int m) {
  println("setting new mode");
  switch (m) {
    case 1 :
      ticksPerDiv = timeDivWidth;
      msMode = 1;
      lines = true;
      break;
    case 2 :
      ticksPerDiv = timeDivWidth/2;
      msMode = 2;
      lines = true;
      break;
    case 3 :
      ticksPerDiv = timeDivWidth/5;
      msMode = 3;
      lines = true;
      break;
    case 4 :
      ticksPerDiv = timeDivWidth/8;
      lines = false;
      msMode = 4;
      break;
    case 5 :
      ticksPerDiv = timeDivWidth/10;
      lines = false;
      msMode = 5;
      break;
    default:
      ticksPerDiv = timeDivWidth;
      lines = true;
      msMode = 0;
      break;
  }
  tickRatio = (timeDivWidth/ticksPerDiv);
  byte[] p = {'m', (byte)(timeDivs), (byte)(ticksPerDiv), (byte)(msMode) };
  arduino.clear();
  arduino.write(p);
}

// keyboard input
void keyPressed() {
  // if it's a plus or a minus, decrement or increment the ms mode
  // higher ms mode means less ms per div, so keys are backwards
  if (key == '-') {
    if (msMode < 7) {
      setMode(msMode+1);
    }
  }
  else if (key == '+') {
    if (msMode > 0) {
      setMode(msMode-1);
    }
  }
}
