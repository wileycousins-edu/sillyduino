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
int currentRead;

// time divs
// twenty horizontal divs
int timeDivs = 16;
int timeDivWidth = scopeWidth/timeDivs;
int ticksPerDiv = timeDivWidth;
int tickRatio = (timeDivWidth/ticksPerDiv);
// default mode is 1000 ms per div
int msMode = 0;

// voltage divs
int voltDivs = 12;
int voltDivHeight = scopeHeight/voltDivs;
int scopeMid = scopeHeight/2;
// dc offset in millivolts
int dcOffset = 2500;
// millivolts per div
int mvPerDiv = 500;
int mvMode = 0;
// adc parameters
int maxAdc = 255;
int maxMV = 5000;


// display lines or dots
boolean lines = true;

// color stuff
// background
color bgColor = color(0);
// control panel
color cpColor = color(128);
// division grid
color divColor = color(64);
// trace
color tColor = color(255);
// sweeper
color sColor = color(255, 0, 0);
// dc offset
color dcColor = color(0, 255, 0);

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
  arduino.write(0xFF);
  while ((arduino.available() == 0) || (arduino.read() != 127)) {
    println("waiting");
    //arduino.write(0xFF);
  }
  println("success!");

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

  // draw the divs
  drawTimeDivs();
  drawVoltDivs();

  // draw the sweeper and DC offset
  drawSweep();
  drawDCOffset();

  // draw the trace
  drawTrace();

  // draw the control panel
  drawControlPanel();
}

int mvToY(int mv) {
  float m = (mv - dcOffset)/((float)(mvPerDiv));
  m *= voltDivHeight;
  return (scopeMid - (int)(m));
}

// draw the trace
void drawTrace() {
  stroke(tColor);
  for (int i=1; i<timeDivs*ticksPerDiv; i++) {
    if (lines) {
      // take map mv readings to window
      line((i-1)*tickRatio, mvToY(readings[i-1]), i*tickRatio, mvToY(readings[i]));
    }
    else {
      point(i*tickRatio, mvToY(readings[i]));
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
  stroke(divColor);
  for (int i=timeDivWidth; i<scopeWidth; i+=timeDivWidth) {
    line(i, 0, i, scopeHeight);
  }
}

// draw the dcOffset line
void drawDCOffset() {
  stroke(dcColor);
  strokeWeight(3);
  line(0, scopeMid, scopeWidth-1, scopeMid);
  strokeWeight(1);
}

// draw the volt divs
void drawVoltDivs() {
  stroke(divColor);
  for (int i=voltDivHeight; i<scopeHeight; i+=voltDivHeight) {
    line(0, i, scopeWidth-1, i);
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

  // control the millivolts per div
  text("mV per div: "+str(mvPerDiv), scopeWidth, 100, controlWidth, 20);
  text("press '[' or ']' to change", scopeWidth, 120, controlWidth, 20);

  // control the dc offset
  text("dc offset (mV): "+str(dcOffset), scopeWidth, 160, controlWidth, 20);
  text("press 'q' or 'a' to change", scopeWidth, 180, controlWidth, 20);

  // current measurement
  text("current reading (mV): " + str(currentRead), scopeWidth, 220, controlWidth, 20);
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
      // map readings to millivolts
      currentRead = (int)(map(r, 0, 255, 0, maxMV));
      readings[sweep] = currentRead;
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

void setZoom(int m) {
  println("setting new zoom");
  switch (m) {
    case 1 :
      mvMode = 1;
      mvPerDiv = 300;
      break;
    case 2 :
      mvMode = 2;
      mvPerDiv = 100;
      break;
    case 3 :
      mvMode = 3;
      mvPerDiv = 50;
      break;
    case 4 :
      mvMode = 4;
      mvPerDiv = 20;
      break;
    case 5 :
      mvMode = 5;
      mvPerDiv = 10;
      break;
    default:
      mvMode = 0;
      mvPerDiv = 500;
      break;
  }
}

// keyboard input
void keyPressed() {
  // if it's a plus or a minus, decrement or increment the ms mode
  // if it's a [ or a ], decrement or increment the zoom
  // higher ms mode means less ms per div, so keys are backwards
  if (key == '-') {
    if (msMode < 5) {
      setMode(msMode+1);
    }
  }
  else if (key == '+') {
    if (msMode > 0) {
      setMode(msMode-1);
    }
  }
  else if (key == '[') {
    if (mvMode < 5) {
      setZoom(mvMode+1);
    }
  }
  else if (key == ']') {
    if (mvMode > 0) {
      setZoom(mvMode-1);
    }
  }
  else if (key == 'q') {
    if (dcOffset < maxMV) {
      dcOffset += 100;
    }
  }
  else if (key == 'a') {
    if (dcOffset > 0) {
      dcOffset -= 100;
    }
  }
}
