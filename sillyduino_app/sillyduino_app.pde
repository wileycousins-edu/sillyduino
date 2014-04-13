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
  arduino = new Serial(this, Serial.list()[serialPort], serialBaud);
  // wait for the alive signal
  println("waiting for arduino response");
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
  // 0 coresponds to 1000 ms
  // 1 coresponds to 500 ms
  // 2 coresponds to 200 ms
  // 3 coresponds to 100 ms
  // 4 coresponds to 50 ms
  // 5 coresponds to 10 ms
  // 6 coresponds to 5 ms
  // 7 coresponds to 1 ms
  byte[] params = { (byte)(timeDivs), (byte)(timeDivWidth), 0 };
  arduino.write(params);
}

// draw function
void draw() {
  // set stroke to white and background to white
  background(bgColor);

  // get a new reading and add it to the array
  //int read = getReading();
  //if (read != -1) {
  //  readings[sweep] = scopeHeight-(int)(map(read, 0, 255, 1, scopeHeight));
  //}
  getReading();

  // draw the time divs
  drawTimeDivs();

  // draw the trace
  drawTrace();

  // draw and move the sweeper
  drawSweep();

  // draw the control panel
  if (true) {
    drawControlPanel();
  }
}

// draw the trace
void drawTrace() {
  stroke(tColor);
  for (int i=1; i<scopeWidth; i++) {
    //point(i, readings[i]);
    line(i-1, readings[i-1], i, readings[i]);
  }
}

// draw the sweep
void drawSweep() {
  // draw a vertical line at the sweep position
  stroke(sColor);
  line(sweep, 0, sweep, scopeHeight-1);
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
}

// get a reading from the sillyduino
// int getReading() {
//   int r = -1;
//   // a complete package will be a start byte and a data bytes
//   while (arduino.available() > 1) {
//     // check for the start bit
//     if (arduino.read() == 0xFF) {
//       // build the data
//       r = arduino.read();
//     }
//   }
//   // return the data
//   return r;
// }

// put a reading in the array
void getReading() {
  while(arduino.available() >= 4) {
    if (arduino.read() == 0xFF) {
      int tick = arduino.read();
      int div = arduino.read();
      int r = arduino.read();

      // move the sweeper
      sweep = div * timeDivWidth + tick;
      readings[sweep] = scopeHeight-(int)(map(r, 0, 255, 1, scopeHeight));
    }
  }
}
