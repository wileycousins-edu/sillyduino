// sillyduino arduino sketch
// a silly little oscilliscope to learn stuff
// copyright 2014 by Wiley Cousins
// shared under the terms of the MIT license
// last updated april 12, 2014

// use built in avr delay functions because i'm gonna use the timers
#include <util/delay.h>

// define some pins
// analog inputs will be called A and B
#define INPUT_A  0
#define INPUT_B  1

// setup function
void setup(void) {
  // we talk serial and we talk fast
  Serial.begin(19200);
}

// inifinite loop
void loop(void) {
  // the analog reading will range from 0 to (2^10)-1, so make it unsigned
  // (unsigned means non-negative)
  unsigned int reading = analogRead(INPUT_A);
  // use Serial.write to send the value
  // we use write instead of print because print would send the character
  // representation of the number rather than the number
  Serial.write(reading);
}
