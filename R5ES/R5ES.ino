/*

 PIN ASSIGNMENT
 
 21(it_2): Remote Signal In
 11(h), 12(v), 13(r): Horizontal, Vertical and Rotational Servos (Fixed Pin number for Timer1)
 22: Trigger Out
 24: Field Illumination LED
 25: Reset Hall Sensor
 26, 27, 28, 29: Loader Stepper IN1, IN2, IN3, IN4
 30: Buzzer(sourceless)
 31: Bad Pin, Never Use It
 32(pul), 33(dir): Rail Stepper
 34: Grab Counter
 35: Food Counter
 36: Door Servo
 38, 39, 40, 41: Four Channels of Remote
 42(+), 43(+), 44(-), 45(-): Shutter
 
 A8: Drop Piezo

*/

// TESTING
byte ledPin = 13;
unsigned long toggleRefracPeriod = 1000;
int ledState = LOW;
unsigned long lastToggleTime;

// FOOD LOADER
const byte loaderPins[] = { 26, 27, 28, 29 };
byte thisStep = 3; // An arbitrary start point (0-3) for stepper initiation
int loaderStepTime = 5; // ms; Determining the speed of rotation

// DROP DETECTION
const byte dropItIdx = 5; // Pin #18

// RUNTIME VARIABLES


void setup()
{
  Serial.begin(115200);
  pinMode(ledPin, OUTPUT);
  LoaderSetup();
  attachInterrupt(dropItIdx, Dropping, RISING);
}


void loop()
{
  ReadSerialCommand();
}


void TriggerHandler(byte trigIdx)
{
  switch (trigIdx)
  {
    case 1:
      ToggleLed();
      break;
    case 2:
      TurnOnLed();
      break;
    case 3:
      TurnOffLed();
      break;
    default:
      break;
  }
}

void TurnOnLed()
{
  ledState = HIGH;
  digitalWrite(ledPin, ledState);
}

void TurnOffLed()
{
  ledState = LOW;
  digitalWrite(ledPin, ledState);
}

void ToggleLed()
{
  if (millis() - lastToggleTime > toggleRefracPeriod)
  {
    ledState = !ledState;
    digitalWrite(ledPin, ledState);
    lastToggleTime = millis();
  }
}


void Dropping()
{
  Serial.println("d");
  delay(100);
}
