// Reading Command
double incomingVal = 0;
boolean decimal = false;
double factor = 1;
double valence = 1;
String incomingCmd = String();

void ResetSerialRead()
{
  incomingVal = 0;
  factor = 1;
  decimal = false;
  valence = 1;
  incomingCmd = String();
  
  while (Serial.available())
    char ch = Serial.read();
}

void ReadSerialCommand()
{
  if(Serial.available())
  {
    char ch = Serial.read();
    
    if(isDigit(ch))
    {
      if (!decimal)
        incomingVal = incomingVal * 10 + ch - '0'; 
      else
      {
        factor *= 0.1;
        incomingVal = incomingVal + (ch - '0') * factor; 
      }
    }
    else if(ch == '-')
      valence = -1;
    else if(ch == '.')
      decimal = true;
    else if(islower(ch))
    {
      switch(ch)
      {
        case 't': 
          TriggerHandler(incomingVal);
          break;
        case 'f':
          Refill(incomingVal * valence);
          break;
        default:
          break;
      }
      ResetSerialRead();
    }
    else if(isalpha(ch))
    {
      incomingCmd += ch;
    }
    
    if(incomingCmd.length() == 3)
    {
      if(incomingCmd.equals("R^5"))
      {
        Serial.println("YES");
      }
      ResetSerialRead();
    }
  }
}
