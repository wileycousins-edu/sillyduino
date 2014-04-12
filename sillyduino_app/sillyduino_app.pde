// sillyduino processing app
// a silly little oscilliscope to learn stuff
// copyright 2014 by Wiley Cousins
// shared under the terms of the MIT license
// last updated april 12, 2014

// we're gonna need some serial communication
import processing.serial.*;
Serial arduino;

// scope window
int scopeWidth = 680;
int scopeHeight = 480;

// serial port to use
// get this from looking at your port list in the Arduino IDE
int serialPort = 5;
int serialBaud = 9600;

// global variables
// array of readings from the arduino
int[] readings;
int sweep = 0;

// setup function
void setup() {
  // set our window size to w: 640, h: 480
  size(scopeWidth, scopeHeight);

  // get our data array ready
  readings = new int[scopeWidth];

  // connect to our arduino
  arduino = new Serial(this, Serial.list()[serialPort], serialBaud);
}

// draw function
void draw() {
  // set stroke to white and background to white
  background(0);

  // get a new reading and add it to the array
  int read = getReading();
  if (read != -1) {
    readings[sweep] = (int)(map(read, 0, 1023, 0, scopeHeight-1));
  }
    println(readings[sweep]);

  // draw the trace
  stroke(255);
  for (int i=1; i<scopeWidth; i++) {
    //point(i, readings[i]);
    line(i-1, readings[i-1], i, readings[i]);
  }

  // draw the sweeper
  stroke(255, 0, 0);
  line(sweep, 0, sweep, scopeHeight-1);

  // move the sweeper
  sweep++;
  if (sweep >= scopeWidth) {
    sweep = 0;
  }
}

// get a reading from the sillyduino
int getReading() {
  int r = -1;
  // a complete package will be a start byte, two data bytes, and an end byte
  while (arduino.available() > 2) {
    // check for the start bit
    if (arduino.read() == 0xFF) {
      // build the data (two-bytes)
      r = (arduino.read() << 8) | (arduino.read());
    }
  }
  // return no new data if there's not at least 4 bytes in the buffer
  return r;
}
