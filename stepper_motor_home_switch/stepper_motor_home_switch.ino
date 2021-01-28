//control stepper motor using a steper motor driver
//by sending position over serial
//at the start the stepper motor returned to home
//untill a switch is triggered

//define used pins
#define HOME_SWITCH 2
#define MOTOR_DRIVER 3
#define MOTOR_DIRECTION 4

//speed
//D=28mm => U=88mm
//200 steps/revolution => 2.25 steps/mm
//4x microstepping => 11 steps/mm
//speed 10mm/s => 110steps/s => 9090us/step
#define steps_mm 9 //11
#define us 4500/5

void process(void);
void steps(long int s);
void return_home(void);
void set_start(void);

long int last_interrupt = 0;
String inputString = "";
bool homing = false;
long int pos = 0;
long int distance = 0;

void setup() {
  // initialize serial:
  Serial.begin(115200);
  while (!Serial) {
  //wait for serial connection
  }
  Serial.println("command can be written directly into serial monitor.");
  Serial.println("but before that please enable NL and CR characters");
  Serial.println("to go to home type: h");
  Serial.println("and to go to a position type the value in mm");
  inputString.reserve(20);
  pinMode(MOTOR_DRIVER, OUTPUT);
  digitalWrite(MOTOR_DRIVER, LOW);
  pinMode(MOTOR_DIRECTION, OUTPUT);
  digitalWrite(MOTOR_DIRECTION, HIGH);
  attachInterrupt(digitalPinToInterrupt(HOME_SWITCH), set_start, LOW);
  return_home();
}

void loop() {
}

void serialEvent() {
  while (Serial.available() > 0) {
    int inChar = Serial.read();
    if (inChar == '\n') {
      Serial.print("input: ");
      Serial.println(inputString);
      Serial.flush();
      process();
      break;
    }
    inputString += (char)inChar;
  }
}

void process(void){
  if (inputString == "h"){
    Serial.println("### homing ###");
    return_home();
  }
  else if(inputString.length()>0){
    inputString = inputString.toInt();
    if(isdigit(inputString[0])){
      Serial.println("### moving ###");
      Serial.print("to: ");
      Serial.println(inputString);
      distance = inputString.toInt() - pos;
      steps(distance*steps_mm);
      pos += distance;
    }
  }
  Serial.print("current position: ");
  Serial.println(pos);
  inputString = "";
}

void steps(long int s){
  //direction
  if(s>0){
    digitalWrite(MOTOR_DIRECTION, HIGH);
  }
  else{
    digitalWrite(MOTOR_DIRECTION, LOW);
  }
  //stepping
  s = abs(s);
  for(long long unsigned int i=0; i<s; i++){
    digitalWrite(MOTOR_DRIVER, HIGH);
    delayMicroseconds(us);
    digitalWrite(MOTOR_DRIVER, LOW);
    delayMicroseconds(us);
  }
}

void return_home(void){
  homing = true;
  Serial.println("move to home");
  while(homing){
    steps(-1);
  }
}

void set_start(void){
  long int current_interrupt = millis();
  if(abs(last_interrupt-current_interrupt)>800){
    homing = false;
    Serial.println("switch triggered");
    steps(5*steps_mm);
    pos = 5;
    last_interrupt = current_interrupt;
  }
}
