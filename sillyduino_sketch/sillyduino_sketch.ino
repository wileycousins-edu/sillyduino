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

// volatile adc readings
volatile uint8_t read;

// ADC interrupt
// read the new data in whenever there's a reading ready
ISR(ADC_vect) {
  read = ADCH;
}

// setup function
void setup(void) {
  // we talk serial and we talk fast
  Serial.begin(9600);

  // setup the analog reading
  // we're gonna do 8-bit mode as fast as we can
  // set aref to AVCC and left adjust to true
  ADMUX = ( (1<<REFS0) | (1<<ADLAR) );
  // set analog prescaler to divide by 8 (2MHz speed)
  ADCSRA = ( (1<<ADPS1) | (1<<ADPS0) );
  // enable the ADC autotrigger and ADC interrupt
  ADCSRA |= ( (1<<ADATE) | (1<<ADIE) );
  // set the ADC to freerunning mode
  ADCSRB = 0;
  // if it exists, put the ADC into high-speed mode
  #ifdef ADHSM
  ADCSRB |= (1<<ADHSM);
  #endif
  // enable the ADC and start the first conversion
  ADCSRA |= ( (1<<ADEN) | (1<<ADSC) );
}

// inifinite loop
void loop(void) {
  //int reading = analogRead(INPUT_A);
  // use Serial.write to send the value
  // we use write instead of print because print would send the character
  // representation of the number rather than the number
  sendReading();
  _delay_us(7);
}

void sendReading() {
  Serial.write(0xFF);
  Serial.write(read);
}
