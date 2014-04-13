// sillyduino arduino sketch
// a silly little oscilliscope to learn stuff
// copyright 2014 by Wiley Cousins
// shared under the terms of the MIT license
// last updated april 12, 2014

// use built in avr delay functions because i'm gonna use the timers
#include <util/delay.h>

// timer 1 prescaled value
#define TIMER_MHz 2

// allowed ms per div values
#define MS_500  0
#define MS_200  1
#define MS_50   2
#define MS_20   3
#define MS_5    4
#define MS_2    5

// define some pins
// analog inputs will be called A and B
#define INPUT_A  0
#define INPUT_B  1

// volatile adc readings
volatile uint8_t read;
// keep track of the div and the tick
volatile uint8_t divis;
volatile uint8_t tick;

// variables for settings
uint16_t msPerDiv;
uint8_t nDivs;
uint8_t ticksPerDiv;
uint8_t divsPer1000Ticks;

// ADC interrupt
// read the new data in whenever there's a reading ready
ISR(ADC_vect) {
  // since we're in 8-bit mode, we can just read the high register
  read = ADCH;
}

// 16-bit timer interrupt
// keep track of where we are
ISR(TIMER1_COMPA_vect) {
  if (++tick >= ticksPerDiv) {
    tick = 0;
    if (++divis >= nDivs) {
      divis = 0;
    }
  }
}

// setup function
void setup(void) {
  // we talk serial
  Serial.begin(19200);
  // check for builtin USB and act accordingly
  #if defined(__AVR_ATmega32U4__)
  while(!Serial.available());
  Serial.read();
  #endif
  // we're alive!
  Serial.write(127);

  // wait for setup information
  // first byte is the number of divs on the screen
  // the second byte is the number of ticks per div
  // third byte is the milliseconds per tick
  while (Serial.available() < 3);
  nDivs = Serial.read();
  ticksPerDiv = Serial.read();
  msPerDiv = setMsPerDiv(Serial.read());

  // set the divsPer1000Ticks variable
  divsPer1000Ticks = (uint8_t)(1.0/ticksPerDiv * 1000);

  // disable interrupts
  cli();
  // initialize the ADC
  initADC();
  // initialize the timer
  initTimer();
  // set the timer (enables interrupts)
  setTimer();
}

// inifinite loop
void loop(void) {
  // send the reading
  sendReading();
  // check if the app wants us to do anything
  if (Serial.available()>3) {
    uint8_t r = Serial.read();
    if (r == 'm') {
      setParams();
    }
  }
}

void sendReading() {
  uint8_t r[4] = {0xFF, tick, divis, read};
  Serial.write(r, 4);
  //Serial.write(tick);
  //Serial.write(divis)
  //Serial.write(read);
  //Serial.write('\n');
}

// initialize the timer to send data to the app
// use CTC mode to set frequency
// set prescaler to 8
void initTimer() {
  TCCR1A = 0;
  TCCR1B = ( (1<<WGM12) | (1<<CS11) );
  TCCR1C = 0;
}

// set the overflow count according to parameters
void setTimer() {
  // disable interrupts
  cli();
  // reset vairables
  tick = 0;
  divis = 0;
  // reset the counter
  TCNT1 = 0;
  // get the new overflow
  uint16_t c = (uint16_t)(msPerDiv * divsPer1000Ticks * TIMER_MHz);
  OCR1A = (c-1);
  // enable the interrupt
  TIMSK1 = (1<<OCIE1A);
  // enable global interrupts
  sei();
}

uint16_t setMsPerDiv(uint8_t m) {
  uint16_t ret;
  switch (m) {
    case MS_200 :
      ret = 200;
      break;
    case MS_50  :
      ret = 50;
      break;
    case MS_20  :
      ret = 20;
      break;
    case MS_5   :
      ret = 5;
      break;
    case MS_2   :
      ret = 2;
      break;
    default:
      ret = 500;
      break;
  }
  return ret;
}

// setup the analog reading
void initADC() {
  // we're gonna do 8-bit (as opposed to 10-bit) mode as fast as we can
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
  // set the channel
  setADCChannel(INPUT_A);
  // enable the ADC and start the first conversion
  ADCSRA |= ( (1<<ADEN) | (1<<ADSC) );
}

void setADCChannel(uint8_t pin) {
  #if defined(analogPinToChannel)
  pin = analogPinToChannel(pin);
  #endif
  ADMUX = (ADMUX & ~0x1F) | (pin & 0x07);
}

void setParams() {
  nDivs = Serial.read();
  ticksPerDiv = Serial.read();
  msPerDiv = setMsPerDiv(Serial.read());
  // set the divsPer1000Ticks variable
  divsPer1000Ticks = (uint8_t)(1.0/ticksPerDiv * 1000);
  setTimer();
}
